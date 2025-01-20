#!/bin/bash
    set -e

    echo "[DEBUG] Running CONVERT_CSV_TO_JSON for !{dataset_size} dataset"
    echo "[DEBUG] Processing file: !{csv_file}"

    # Create data.json with initial empty array
    echo "[]" > data.json

    # Process the CSV file and make the API call
    CSV_CONTENT=$(cat "!{csv_file}" | tr '
' '\n' | sed 's/"/\"/g')
    
    echo "[DEBUG] Making API request..."
    
    curl -s -X POST         -H "Content-Type: application/json"         -d "{"csv_data":"$CSV_CONTENT"}"         "!{params.GCF_URL}" > data.json

    # Check if the API call was successful
    if [ $? -ne 0 ]; then
        echo "[ERROR] API call failed"
        exit 1
    fi

    # Create metrics JSON
    cat << EOF > metrics.json
{
    "process": "CONVERT_CSV_TO_JSON",
    "dataset_size": "!{dataset_size}",
    "metrics": {
        "input_size": $(wc -c < "!{csv_file}"),
        "output_size": $(wc -c < data.json),
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF
