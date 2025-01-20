#!/bin/bash
    set -e

    echo "[DEBUG] Reading CSV file: data_small.csv"
    echo "[DEBUG] File size: $(wc -c < data_small.csv) bytes"
    echo "[DEBUG] First few lines of CSV:"
    head -n 3 data_small.csv

    # Prepare request payload and save for debugging
    csv_content=$(cat data_small.csv | tr '
' '\n')
    echo "{\"csv_data\":\"${csv_content}\"}" > debug_request.json
    
    echo "[DEBUG] Request payload size: $(wc -c < debug_request.json) bytes"
    
    # Make API call with detailed output
    curl -v -X POST         -H "Content-Type: application/json"         --data-binary @debug_request.json         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function > data.json 2> debug_response.txt

    echo "[DEBUG] Response size: $(wc -c < data.json) bytes"
    echo "[DEBUG] Response content:"
    cat data.json
