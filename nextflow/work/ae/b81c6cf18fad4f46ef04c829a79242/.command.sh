#!/bin/bash -ue
# Record start time
start_time=$(date +%s%N)

echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
echo "[DEBUG] csv_file -> 'data_medium.csv'"

# Read and escape the CSV content
CSV_CONTENT=$(awk '{printf "%s\\n", $0}' data_medium.csv | sed 's/"/\\"/g')

echo "[DEBUG] Making request to GCF.."

curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function \
| tee data.json

# Create metrics file
end_time=$(date +%s%N)
duration=$(( ($end_time - $start_time) / 1000000 ))

echo "{
    \"process\": \"CONVERT_CSV_TO_JSON\",
    \"duration_ms\": $duration,
    \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
}" > metrics.json
