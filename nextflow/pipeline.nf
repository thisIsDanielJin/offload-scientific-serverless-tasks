#!/usr/bin/env nextflow
nextflow.enable.dsl=2

def GCF_URL = "https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function"

process CONVERT_CSV_TO_JSON {
    debug true
    publishDir "${projectDir}/results", mode: 'copy'

    input:
    path csv_file

    output:
    path 'data.json'

    script:
    """
    echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
    echo "[DEBUG] csv_file -> '${csv_file}'"

    # Read and escape the CSV content
    CSV_CONTENT=\$(awk '{printf "%s\\\\n", \$0}' ${csv_file} | sed 's/"/\\\\"/g')

    echo "[DEBUG] CSV_CONTENT -> \${CSV_CONTENT}"
    echo "JSON body => { \\"csv_data\\": \\"\${CSV_CONTENT}\\" }"

    echo "[DEBUG] Making request to GCF.."

    curl -v -X POST \\
        -H "Content-Type: application/json" \\
        -d "{ \\"csv_data\\": \\"\${CSV_CONTENT}\\" }" \\
        ${GCF_URL} \\
    | tee data.json

    echo "[DEBUG] curl exit code: \$?"

    echo "[DEBUG] Finished request, wrote GCF response to data.json"
    """
}





process PRINT_JSON_CONTENT {
    debug true
    publishDir "${projectDir}/results", mode: 'copy'

    input:
    path 'data.json'

    script:
    """
    echo '[DEBUG] Printing data.json: '
    cat data.json
    """
}

workflow {
    csv_ch = Channel
        .fromPath("$projectDir/data/data.csv")
        .ifEmpty { error "Cannot find CSV at $projectDir/data/data.csv" }

    converted = CONVERT_CSV_TO_JSON(csv_ch)
    PRINT_JSON_CONTENT(converted)
}
