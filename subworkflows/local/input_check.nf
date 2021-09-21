//
// Check input samplesheet and get read channels
//

params.options = [:]

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check' addParams( options: params.options )

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .splitCsv ( header:true, sep:',' )
        .map { create_bam_channels(it) }
        .set { bams }

    emit:
    bams // channel: [ val(meta), [ bam ] ]
}

// Function to get list of [ meta, [ bam ] ]
def create_bam_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample

    def array = []
    if (!file(row.bam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> bam file does not exist!\n${row.bam}"
    }
        array = [ meta, [file(row.bam)] ]
    return array
}
