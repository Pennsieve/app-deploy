/*
 * pipeline input and output parameters
 */
params.execution_script = "$projectDir/main.R"

log.info """\
    R PIPELINE
    ===================================
    execution_script        : ${params.execution_script}
    outputdir               : ${params.outputDir}
    inputdir                : ${params.inputDir}
    integrationID           : ${params.integrationID}
    """
    .stripIndent()

process RPipeline {
    debug true

    output: stdout

    script:
    """
    Rscript ${params.execution_script} ${params.inputDir} ${params.outputDir}
    """
}

workflow {
    RPipeline()
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Your output can be found at this location --> $params.outputDir\n" : "Oops .. something went wrong" )
}