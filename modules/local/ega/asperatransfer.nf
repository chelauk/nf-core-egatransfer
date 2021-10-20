// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from '../functions'

params.options = [:]
options        = initOptions(params.options)

process EGA_ASPERATRANSFER {
    executor "slurm"
    queue "data-transfer"
	executor "slurm"
	memory '2 GB'
	clusterOptions  "--ntasks=1"
    time '24h'

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
    tuple val(meta), path(gpgs)
    val(pass)
    val(box)

    output:
    tuple val(meta), path("*.log"), emit: log
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    ASPERA_SCP_PASS=$pass \\
    ascp -P33001 -O33001 -k2 -QT -l300M -L- ./*{md5,gpg} \\
    ega-box-${box}@fasp.ega.ebi.ac.uk:/. 2>&1 > ${meta.id}.log

    echo \$(ascp --version 2>&1) | sed 's/^.*ascp version //; s/ Operating.*\$//' > ${software}.version.txt
    """

    stub:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    echo $pass > ${meta.id}.log
    echo $box >> ${meta.id}.log
    echo \$(ascp --version 2>&1) | sed 's/^.*ascp version //; s/ Operating.*\$//' > ${software}.version.txt
    """
}
