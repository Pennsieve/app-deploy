/*
 * pipeline input parameters
 */
params.reads = "$projectDir/main.R"
log.info """\
    C Y T O F  QC P I P E L I N E
    ===================================
    reads        : ${params.reads}
    outdir       : ${params.outDir}
    inputdir       : ${params.inputDir}
    integration : ${params.integration}
    """
    .stripIndent()

process CyTOFQCReport {
    script:
    """
    Rscript ${params.reads} ${params.inputDir} ${params.outDir}
    """
}

workflow {
    CyTOFQCReport()
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Your report can be found at this location --> $params.outDir\nIntegration params --> $params.integration\n" : "Oops .. something went wrong" )
}