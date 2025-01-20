#!/bin/bash
    set -e

    start_time=$(date +%s%N)
    echo "[DEBUG] Processing medium dataset"

    # Process CSV and make API call
    csv_content=$(cat data_medium.csv | tr '
' '\n')
    
    curl -s -X POST         -H "Content-Type: application/json"         -d "{\"csv_data\":\"${csv_content}\"}"         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function > data.json

    end_time=$(date +%s%N)
    duration=$(( ($end_time - $start_time) / 1000000 ))

    # Create metrics
    echo "{
        \"process\": \"CONVERT_CSV_TO_JSON\",
        \"dataset_size\": \"medium\",
        \"metrics\": {
            \"input_size\": $(wc -c < data_medium.csv),
            \"output_size\": $(wc -c < data.json),
            \"duration_ms\": $duration,
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
        }
    }" > metrics.json
