#!/bin/bash
set -e

start_time=$(date +%s%N)
echo "[DEBUG] Processing small dataset"

# Process CSV and make API call
csv_content=$(awk '{printf "%s\n", $0}' data_small.csv | sed 's/"/\"/g')

curl -s -X POST         -H "Content-Type: application/json"         -d "{\"csv_data\":\"${csv_content}\"}"         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function > data.json

end_time=$(date +%s%N)
duration=$(( ($end_time - $start_time) / 1000000 ))

# Create metrics
echo "{
    \"process\": \"CONVERT_CSV_TO_JSON\",
    \"dataset_size\": \"small\",
    \"metrics\": {
        \"input_size\": $(wc -c < data_small.csv),
        \"output_size\": $(wc -c < data.json),
        \"duration_ms\": $duration,
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
}" > metrics.json
