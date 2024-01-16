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
    echo "running pipeline"
    """
}

process PostProcessor {
    debug true
    
    output: stdout

    script:
    """
    echo "running post-processor"
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