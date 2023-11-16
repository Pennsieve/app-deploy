/*
 * pipeline input and output parameters
 */
params.execution_script = "$projectDir/main.py"

log.info """\
    PYTHON ECHO PIPELINE
    ===================================
    execution_script        : ${params.execution_script}
    outputdir               : ${params.outputDir}
    inputdir                : ${params.inputDir}
    integrationID           : ${params.integrationID}
    """
    .stripIndent()

process PythonExample {
    output:
    stdout

    script:
    """
    python3.8 ${params.execution_script} ${params.inputDir} ${params.outputDir}
    """
}

workflow {
    PythonExample()
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Your output can be found at this location --> $params.outputDir\n" : "Oops .. something went wrong" )
}