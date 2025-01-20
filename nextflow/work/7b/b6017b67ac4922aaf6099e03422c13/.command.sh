#!/bin/bash
    set -e

    start_time=$(date +%s%N)

    # Read CSV content without escaping newlines
    csv_content=$(cat data_small.csv)
    
    # Create proper JSON request body and make API call
    response_size=$(jq -n --arg csv "$csv_content" '{csv_data: $csv}' |     curl -s -X POST         -H "Content-Type: application/json"         -H "Accept: application/json"         --data @-         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function | wc -c)

    end_time=$(date +%s%N)
    duration=$(( ($end_time - $start_time) / 1000000 ))

    # Create metrics with unique filename
    cat << EOF > metrics_small.json
{
    "process": "CONVERT_CSV_TO_JSON",
    "dataset_size": "small",
    "metrics": {
        "input_size_bytes": $(wc -c < data_small.csv),
        "output_size_bytes": $response_size,
        "duration_ms": $duration,
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF
