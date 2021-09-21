// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from '../functions'

process EGA_EGACRYPTOR {
    tag "$meta.id"
    label 'process_high'
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
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.gpg"), path("*.md5") emit: gpg
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    java -jar  ~/apps/EGA-Cryptor-2.0.0/ega-cryptor-2.0.0.jar \\
    -i $bam \\
    -m \\
    -o ./

    echo "2.0.0" > ${software}.version.txt
    """
    
	stub:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    touch \$(basename $bam).md5
    touch \$(basename $bam).gpg
    touch \$(basename $bam).gpg.md5
	"""
}
