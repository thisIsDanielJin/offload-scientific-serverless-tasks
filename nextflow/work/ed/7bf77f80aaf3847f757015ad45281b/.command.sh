#!/bin/bash
    set -e

    echo "[DEBUG] Processing small dataset"
    echo "[DEBUG] Reading CSV file: Users"
    echo "[DEBUG] File size: $(wc -c < Users) bytes"
    echo "[DEBUG] First few lines of CSV:"
    head -n 3 Users

    start_time=$(date +%s%N)

    # Read CSV content without escaping newlines
    csv_content=$(cat Users)
    
    # Create proper JSON request body and make API call
    jq -n --arg csv "$csv_content" '{csv_data: $csv}' |     curl -s -X POST         -H "Content-Type: application/json"         -H "Accept: application/json"         --data @-         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function > data.json

    end_time=$(date +%s%N)
    duration=$(( ($end_time - $start_time) / 1000000 ))

    echo "[DEBUG] Response size: $(wc -c < data.json) bytes"

    # Create metrics with unique filename
    cat << EOF > metrics_small.json
{
    "process": "CONVERT_CSV_TO_JSON",
    "dataset_size": "small",
    "metrics": {
        "input_size_bytes": $(wc -c < Users),
        "output_size_bytes": $(wc -c < data.json),
        "duration_ms": $duration,
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF
