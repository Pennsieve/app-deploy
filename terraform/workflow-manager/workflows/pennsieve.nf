/*
 * Workflow Manager
 */
log.info """\
    WORKFLOW MANAGER
    ===================================
    """
    .stripIndent()

process PreProcessor {
    debug true
    
    output: stdout

    script:
    """
    echo "running pre-processor"
    """
}

process Pipeline {
    debug true
    
    output: stdout

    script:
    """
    echo "running pipeline\n"
    echo "integration ID: $INTEGRATION_ID\n"
    python3.9 /service/taskRunner/main.py Main
    """
}

process PostProcessor {
    debug true
    
    output: stdout

    script:
    """
    echo "running post-processor\n"
    python3.9 /service/taskRunner/post-processor.py Post-Processor
    """
}

workflow {
    PreProcessor()
    Pipeline()
    PostProcessor()
}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}