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
        .map { create_file_channels(it) }
        .set { files }

    emit:
    files // channel: [ val(meta), [ bam ] ]
}

// Function to get list of [ meta, [ bam ] ]
def create_file_channels(LinkedHashMap row) {
    def meta = [:]
	meta.sample       = row.sample.toString()
	meta.type         = row.type.toString()
    meta.id           = row.sample.toString() + "_" + row.type.toString()

    def array = []
    array = [ meta, [file(row.file)] ]
    return array
}
