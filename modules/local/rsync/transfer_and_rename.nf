// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from '../functions'
params.options = [:]
options        = initOptions(params.options)
process TRANSFER_AND_RENAME {
    tag "$meta.id"
    memory '16 GB'
    clusterOptions  "--ntasks=1"
    time "8h"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::bwa=0.7.17 bioconda::samtools=1.15" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:c56a3aabc8d64e52d5b9da1e8ecec2031668596d-0' :
        'quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:c56a3aabc8d64e52d5b9da1e8ecec2031668596d-0' }"

    input:
    tuple val(meta), file('temp_file')
    path(idconvert)

    output:
    tuple val(meta), path("${meta.sample}*"), emit: files
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    _file=\$(readlink $temp_file | xargs basename)
    rsync -L $temp_file \$_file
    echo \$(rsync --version) | sed 's/^rsync version //; s/ protocol.*\$//' > ${software}.version.txt
    """
    stub:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    file=\$(readlink $temp_file | xargs basename)

    ​patient="\$(cut -d'_' -f1 <<< \$file)"
​
    while IFS=, read -r new old
        do if [ \$patient == \$old ]
    then new2=\$new
        fi
    done < \$ID_Conversion.csv
​
    newfilename=`echo \$file | sed "s/\$patient/\$new2/"`
​
    # on samtools view -h \$file | sed "s/\$patient/\$new2/g" | samtools view -hb - > "\$newfilename"
    touch \$newfilename
    echo \$(rsync --version) | sed 's/^rsync version //; s/ protocol.*\$//' > ${software}.version.txt
    """

}
