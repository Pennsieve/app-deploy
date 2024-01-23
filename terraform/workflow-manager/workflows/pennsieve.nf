/*
 * Workflow Manager
 */
log.info """\
    WORKFLOW MANAGER
    ===================================
    """
    .stripIndent(true)

params.inputDir = "$BASE_DIR/input/$INTEGRATION_ID"
params.outputDir = "$BASE_DIR/output/$INTEGRATION_ID"

process PreProcessor {
    debug true
    
    input:
        val x
        val y
    output:
        stdout

    script:
    if ("$ENVIRONMENT" != 'LOCAL')
        """
        echo "NOT_LOCAL"
        """
    else
        """
        echo "running pre-processor\n"
        echo "Running pre-processor: using input $x, and output $y"
        """
}

process Pipeline {
    debug true
    
    input:
        val pre_output
    output: stdout

    script:
    if ("$ENVIRONMENT" != 'LOCAL')
        """
        python3.9 /service/taskRunner/main.py $INTEGRATION_ID
        """
    else
        """
        echo "running pipeline\n"
        echo "pre-output is: $pre_output"
        """
}

process PostProcessor {
    debug true

    input:
        val pipeline_output
    output: stdout

    script:
        if ("$ENVIRONMENT" != 'LOCAL')
        """
        python3.9 /service/taskRunner/post_processor.py $INTEGRATION_ID
        """
    else
        """
        echo "running post-processor\n"
        echo "pipeline_output is: $pipeline_output"
        """
}

workflow {
    input_ch = Channel.of(params.inputDir)
    output_ch = Channel.of(params.outputDir)

    pre_ch = PreProcessor(input_ch, output_ch)
    pipeline_ch = Pipeline(pre_ch)
    PostProcessor(pipeline_ch)
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}