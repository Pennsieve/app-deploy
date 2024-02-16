


#' @title Parse HLA typing files
#' @description Read all fcs files in provided directory, apply
#' compensation and arcsinh transformation, and prepare for analysis.
#' @param dir_in A path to read fcs files from.
#' @param channels Fluorescence channels to be used in analysis.
#' @param cofactor Parameter for arcsinh transformation of fluorescence channels.
#' @param scale_scat Parameter for linear scaling of scattering channels.
#' @returns A container object of class HLA_data.
#' @export
read_HLA_data <- function(dir_in, channels=c("A2", "A3", "B7"),
                          cofactor=500, scale_scat=4e4) {
  files <- list.files(path=dir_in, recursive = TRUE, pattern = ".fcs")
  matlist <- lapply(paste0(dir_in, "/", files), read_single_file,
                    channels=channels, cofactor=cofactor, scal=scale_scat)
  counts <- lapply(matlist, nrow) %>% do.call(what=c)

  data <- do.call(what=rbind, args=matlist)
  data_scaled <- scale(data, center = FALSE)
  nice_names <- str_remove(files, ".fcs")
  samples <- rep(nice_names, counts) %>% as.factor()

  HLA_data <- list(data=data,
                   data_scaled=data_scaled,
                   samples=samples,
                   counts=counts,
                   nice_names=nice_names,
                   channels=channels)
  class(HLA_data) <- "HLA_data"
  return(HLA_data)
}



read_single_file <- function(path, channels, cofactor=500, scal=4e4) {
  ff <- read.FCS(path)
  compmat <- get_compmat(ff)

  ff <- flowCore::compensate(ff, compmat)
  mat <- ff@exprs

  pdata <- ff@parameters@data
  fluo <- unname(which(!is.na(pdata$desc) & !grepl("FSC|SSC|Time", pdata$name)))
  nice_names <- match_names(pdata$desc[fluo], channels)
  colnames(mat)[fluo] <- nice_names

  scat <- grep("SC-A|SC-W", colnames(mat))
  mat <- mat[,c(scat, fluo),drop=FALSE]

  mat[,seq(length(scat))] <- mat[,seq(length(scat))] / scal
  mat[,nice_names] <- asinh(mat[,nice_names] / cofactor)

  keep <- which(mat[,"FSC-A"] > 1e5/scal & mat[,"FSC-A"] < 2e5/scal &
                  mat[,"SSC-A"] > 0 & mat[,"SSC-A"] < 1e5/scal &
                  mat[,"FSC-W"] < 1e5/scal & mat[,"SSC-W"] < 1e5/scal)
  mat <- mat[keep,]

  return(mat)
}


get_compmat <- function(ff) {
  ### Hard-coding the spillover values.
  ### Look for better solution later?
  compmat <- ff@description$SPILL
  compmat[2,3] <- 0.058
  compmat[3,2] <- 0.04
  return(compmat)
}



#' @title A print method for the HLA_data class.
#' @export
print.HLA_data <- function(obj) {
  n <- length(obj$counts)
  cat("A container for HLA typing data with", n, "files",
      "and", length(obj$channels), "channels:",
      paste(obj$channels, collapse=", "), "\n")

  df <- tibble(file=obj$nice_names, count=obj$counts)
  print(df)
}


match_names <- function(x, vals) {
  for (val in vals) {
    x[grep(val, x)] <- val
  }
  return(x)
}


kde_single_mat <- function(data, channels, name, m, M) {
  lapply(channels, function(ch) {
    kde <- bkde(data[,ch], range.x = c(m[ch], M[ch]))
    tib <- tibble(intensity=kde$x,
                  density= kde$y / max(kde$y),
                  channel=ch,
                  file=name)
    return(tib)
  }) %>% do.call(what=rbind)
}


get_kdes_all <- function(HLA_data) {
  channels <- HLA_data$channels

  m <- apply(HLA_data$data_scaled, 2, function(col) quantile(col, 0.005))
  M <- apply(HLA_data$data_scaled, 2, function(col) quantile(col, 0.995))

  kdes <- lapply(HLA_data$nice_names, function(file) {
    cells <- which(HLA_data$samples==file)
    kde <- kde_single_mat(HLA_data$data_scaled[cells,], channels, file, m, M)
  }) %>% do.call(what=rbind)

  return(kdes)
}


#' @title Analyze HLA typing files
#' @description Use negative and positive control files to determine
#' thresholds for all HLA channels. Then classify cells from all samples.
#' @param HLA_data A container object of class HLA_data.
#' @returns A container object of class HLA_data, updated with analysis results.
#' @export
analyze_HLA_data <- function(HLA_data, count_cutoff=50, A2_cutoff=0.9,
                             A3_cutoff=0.9, B7_cutoff=0.7) {
  # HLA_data$thrs <- get_thrs(HLA_data)
  # labels <- classify_cells(HLA_data)
  #
  # HLA_data$results_df <- as_tibble(HLA_data$data_scaled) %>%
  #   mutate(labels=labels, file=HLA_data$samples)

  # HLA_data$detailed_df <- collect_sample_info(HLA_data)
  df_opt <- get_bhatt(HLA_data)
  HLA_data$call_df <- df_opt %>%
    select(-conf) %>%
    mutate(channel = paste0(channel, "_frac")) %>%
    pivot_wider(names_from=channel, values_from=pos) %>%
    inner_join(tibble(file=HLA_data$nice_names, count=HLA_data$counts)) %>%
    mutate(A2_call = case_when(count < count_cutoff ~ "Inconclusive: few cells",
                               A2_frac >= A2_cutoff ~ "Positive",
                               A2_frac <= 1-A2_cutoff ~ "Negative",
                               TRUE ~ "Inconclusive: mixed"),
           A3_call = case_when(count < count_cutoff ~ "Inconclusive: few cells",
                               A3_frac >= A3_cutoff ~ "Positive",
                               A3_frac <= 1-A3_cutoff ~ "Negative",
                               TRUE ~ "Inconclusive: mixed"),
           B7_call = case_when(count < count_cutoff ~ "Inconclusive: few cells",
                               B7_frac >= B7_cutoff ~ "Positive",
                               B7_frac <= 1-B7_cutoff ~ "Negative",
                               TRUE ~ "Inconclusive: mixed")) %>%
    relocate(file, count)

  return(HLA_data)
}


bhattacharyya_coeff <- function(x,y) {
  xnorm <- x/sum(x)
  ynorm <- y/sum(y)

  return(sum(sqrt(xnorm*ynorm)))
}



get_bhatt <- function(HLA_data) {
  kdes <- get_kdes_all(HLA_data) %>%
    mutate(density=pmax(0,density))

  file_neg <- grep("negative", HLA_data$nice_names, ignore.case = TRUE, value=TRUE)
  file_pos <- grep("positive", HLA_data$nice_names, ignore.case = TRUE, value=TRUE)

  df_bhatt <- lapply(HLA_data$nice_names, function(f) {
    lapply(HLA_data$channels, function(ch) {
      dist_neg <- kdes %>% filter(file==file_neg & channel==ch) %>% pull(density)
      dist_pos <- kdes %>% filter(file==file_pos & channel==ch) %>% pull(density)
      dist_file <- kdes %>% filter(file==f & channel==ch) %>% pull(density)

      seq_a <- seq(0,1,by=0.01)
      seq_bc <- lapply(seq_a, function(a) {
        dist_ref <- (1-a)*dist_neg/sum(dist_neg) + a*dist_pos/sum(dist_pos)
        bc <- bhattacharyya_coeff(dist_file/sum(dist_file), dist_ref)
        return(bc)
      }) %>% do.call(what=c)

      return(tibble(file=f, channel=ch, a=seq_a, bc=seq_bc))
    }) %>% do.call(what=rbind)
  }) %>% do.call(what=rbind)

  df_opt <- df_bhatt %>%
    group_by(file, channel) %>%
    summarise(pos=a[which.max(bc)],
              conf=max(bc))

  return(df_opt)

  # df_bhatt %>% filter(file==file_pos & a==0)
}



#' @title Plot calls overlaid on data distribution for all files
#' @description Shows scaled distributions of all channels in all files,
#' with calls and number of events overlaid.
#' @param HLA_data A container object of class HLA_data.
#' @returns A ggplot2 object.
#' @export
make_output_plot <- function(HLA_data) {
  df_kde <- get_kdes_all(HLA_data)

  # ymax <- max(df_kde$density)
  ymax <- 2.5
  xmin <- min(df_kde$intensity)
  xmax <- max(df_kde$intensity)

  p <- ggplot(df_kde %>% mutate(file = str_replace_all(file, "_", " ")),
         aes(x=intensity, y=density)) +
    # geom_polygon(aes(fill=channel), alpha=0.4) +
    geom_ridgeline(aes(fill=channel, y=channel, height=density), alpha=0.4) +
    scale_fill_brewer(palette="Dark2") +
    xlab("Intensity (scaled)") +
    ylab("Density (scaled)") +
    geom_vline(linetype="dashed", xintercept=0) +
    facet_wrap(~file, labeller = label_wrap_gen(width=20)) +
    geom_text(data=HLA_data$call_df %>% mutate(file = str_replace_all(file, "_", " ")),
              # aes(label=paste0(call, "\ncount=", count),
              aes(label=paste0("A2=",A2_frac,"; A3=",A3_frac, "; B7=",B7_frac, "\nn=",count),
                  color=count>50),
              x=(xmin+xmax)/2, y=0.75*ymax) +
    scale_color_manual(values=c("TRUE"="black", "FALSE"="red")) +
    ggtitle("Distribution of all markers by file, with calls overlaid") +
    theme_bw(base_size=11) +
    theme(axis.text = element_blank(),
          axis.ticks = element_blank())
  return(p)
}


#' @title Plot heatmap of subject HLA types
#' @description Shows percentage of cells in each sample having each HLA type.
#' @param HLA_data A container object of class HLA_data.
#' @returns A heatmap ggplot2 object.
#' @export
plot_heatmap <- function(HLA_data) {
  call_df_tall <- HLA_data$call_df %>%
    select(matches("file|A2|A3|B7|none")) %>%
    pivot_longer(where(is.numeric), names_to="Type", values_to="Percent cells")
  ggplot(call_df_tall, aes(x=Type, y=file, fill=`Percent cells`)) +
    geom_tile(color="black") +
    geom_text(aes(label=round(`Percent cells`,2))) +
    scale_fill_gradient(low="white", high="red") +
    ggtitle("Heatmap of cell distribution by subject and HLA type") +
    theme_bw(base_size=11)
}



