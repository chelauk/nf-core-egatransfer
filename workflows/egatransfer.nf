/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowEgatransfer.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
if (!params.pass) { exit 1, 'ega password not specified'}
if (!params.ega_box)  { exit 1, 'ega box not specified'}
/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

//
// MODULE: Local to the pipeline
//
include { GET_SOFTWARE_VERSIONS } from '../modules/local/get_software_versions' addParams( options: [publish_files : ['tsv':'']] )

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check' addParams( options: [:] )

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

def multiqc_options     = modules['multiqc']
multiqc_options.args   += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''
def transfer_options    = modules['transfer']
def egacryptor_options  = modules['encrypt']
def aspera_options      = modules['aspera']
//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC } from '../modules/nf-core/modules/multiqc/main' addParams( options: multiqc_options   )
include { ALMA_TRANSFER } from '../modules/local/rsync/transfer'    addParams( options: transfer_options  )
include { EGA_ENCRYPTOR } from '../modules/local/ega/encryptor'     addParams( options: egacryptor_options )
include { EGA_ASPERATRANSFER } from '../modules/local/ega/asperatransfer.nf' addParams( options: aspera_options )

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow EGATRANSFER {

    ch_software_versions = Channel.empty()
    ch_encryptor         = Channel.empty()
    input_files          = Channel.empty()
    
	
	//
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (ch_input)
    input_files = input_files.mix(INPUT_CHECK.out.files)

	//
    // MODULE: Run ALMA_TRANSFER
    //

    if ( params.stage == "alma_transfer" ) {
        ALMA_TRANSFER (input_files)
        ch_software_versions = ch_software_versions.mix(ALMA_TRANSFER.out.version.first().ifEmpty(null))
        ch_encryptor = ch_encryptor.mix(ALMA_TRANSFER.out.files)
    }
    //
    // MODULE: Run EGA_ENCRYPTOR
    //
    
	if ( params.stage == "encrypt" ) {
		EGA_ENCRYPTOR (input_files)
        ch_software_versions = ch_software_versions.mix(EGA_ENCRYPTOR.out.version.first().ifEmpty(null))
    } else {
        EGA_ENCRYPTOR ( ALMA_TRANSFER.out.files )
        ch_software_versions = ch_software_versions.mix(EGA_ENCRYPTOR.out.version.first().ifEmpty(null))
    }
    //
    // MODULE: Run EGA_ASPERATRANSFER
    //
    EGA_ASPERATRANSFER (
        EGA_ENCRYPTOR.out.gpgs,
        params.pass,
        params.ega_box
    )
    ch_software_versions = ch_software_versions.mix(EGA_ASPERATRANSFER.out.version.first().ifEmpty(null))
    //
    // MODULE: Pipeline reporting
    //
    ch_software_versions
        .map { it -> if (it) [ it.baseName, it ] }
        .groupTuple()
        .map { it[1][0] }
        .flatten()
        .collect()
        .set { ch_software_versions }

    GET_SOFTWARE_VERSIONS (
        ch_software_versions.map { it }.collect()
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowEgatransfer.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())

    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report       = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
