/*
 * Workflow Manager
 */
log.info """\
    WORKFLOW MANAGER
    ===================================
    """
    .stripIndent()

params.greeting = 'Main'
greeting_ch = Channel.of(params.greeting) 

process PreProcessor {
    debug true
    
    input:
    val x
    output: stdout

    script:
    """
    echo $x
    """
}

process Pipeline {
    debug true
    
    input: 
    val y
    output: stdout

    script:
    if ("$ENVIRONMENT" != 'LOCAL')
        """
        echo "running pipeline\n"
        echo "integration ID: $INTEGRATION_ID\n"
        python3.9 /service/taskRunner/main.py '$y'
        """
    else
        """
        echo "running pipeline\n"
        echo "integration ID: $INTEGRATION_ID\n"
        """
}

process PostProcessor {
    debug true
    input:
    val z
    output: stdout

    script:
        if ("$ENVIRONMENT" != 'LOCAL')
        """
        echo "running post-processor\n"
        python3.9 /service/taskRunner/post_processor.py Post-Processor
        """
    else
        """
        echo "running post-processor\n"
        """

}

workflow {
    pre_processor_ch = PreProcessor(greeting_ch)
    pipeline_ch = Pipeline(pre_processor_ch)
    PostProcessor(pipeline_ch)
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}