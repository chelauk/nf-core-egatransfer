// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from '../functions'
params.options = [:]
options        = initOptions(params.options)
process ALMA_TRANSFER {
    tag "$meta.id"
    queue "data-transfer"
	label 'transfer'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "YOUR-TOOL-HERE" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE"
    } else {
        container "quay.io/biocontainers/YOUR-TOOL-HERE"
    }

    input:
    tuple val(meta), file('temp_file')

    output:
    tuple val(meta), path("*.bam"), emit: bams
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    rsync $bam .
    echo \$(rsync --version) | sed 's/^rsync version //; s/ protocol.*\$//' > ${software}.version.txt
    """
    stub:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    bamfile=\$(readlink temp_file | xargs basename)
    rsync -L temp_file ./\$bamfile
    echo \$(rsync --version) | sed 's/^rsync version //; s/ protocol.*\$//' > ${software}.version.txt
    """

}
