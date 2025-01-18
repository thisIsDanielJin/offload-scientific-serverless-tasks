#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
 * main.nf
 *
 * This workflow takes a local CSV file (data.csv)
 * and sends its content as 'csv_data' in the JSON body to the Cloud Function.
 * The returned JSON is written to a file data.json.
 */

def GCF_URL = "https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function"

process CONVERT_CSV_TO_JSON {
    input:
    path csv_file

    output:
    path 'data.json', emit: converted_json

    script:
    """
    echo "Reading CSV file..."
    CSV_CONTENT=\$(cat \${csv_file} | sed ':a;N;\$!ba;s/\\n/\\\\n/g')

    echo "Sending HTTP request to the Cloud Function..."
    curl -X POST \\
        -H "Content-Type: application/json" \\
        -d "{ \\"csv_data\\": \\"\$CSV_CONTENT\\" }" \\
        -o data.json \\
        ${GCF_URL}

    echo "Saving response as data.json"
    """
}

process PRINT_JSON_CONTENT {
    input:
    path json_file

    script:
    """
    echo "Content of \${json_file}:"
    cat \${json_file}
    """
}

workflow {
    csv_channel = Channel.fromPath("$projectDir/data/data.csv")

    CONVERT_CSV_TO_JSON(csv_channel)
    PRINT_JSON_CONTENT(CONVERT_CSV_TO_JSON.out.converted_json)
}
