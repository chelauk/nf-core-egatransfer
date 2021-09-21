#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/egatransfer
========================================================================================
    Github : https://github.com/nf-core/egatransfer
    Website: https://nf-co.re/egatransfer
    Slack  : https://nfcore.slack.com/channels/egatransfer
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

params.fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { EGATRANSFER } from './workflows/egatransfer'

//
// WORKFLOW: Run main nf-core/egatransfer analysis pipeline
//
workflow NFCORE_EGATRANSFER {
    EGATRANSFER ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_EGATRANSFER ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
