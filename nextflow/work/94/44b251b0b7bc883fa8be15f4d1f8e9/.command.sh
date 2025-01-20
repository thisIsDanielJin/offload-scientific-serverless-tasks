#!/bin/bash
set -e

start_time=$(date +%s%N)
echo "[DEBUG] Processing medium dataset: data_medium.csv"
echo "[DEBUG] File content preview:"
head -n 3 data_medium.csv

# Process CSV and make API call
csv_content=$(cat data_medium.csv | sed 's/"/\"/g' | awk 'NR>1{print}' | paste -sd '\n' -)

echo "[DEBUG] Prepared CSV content (first 100 chars):"
echo "${csv_content}" | head -c 100

request_body="{\"csv_data\":\"${csv_content}\"}"
echo "[DEBUG] Request body preview (first 100 chars):"
echo "${request_body}" | head -c 100

echo "[DEBUG] Making API call to https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function"

response=$(curl -v -X POST         -H "Content-Type: application/json"         -d "${request_body}"         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function 2>curl_error.log)

echo "[DEBUG] API Response:"
echo "${response}" | tee data.json

if [ $? -ne 0 ]; then
    echo "[ERROR] Curl failed. Error log:"
    cat curl_error.log
    exit 1
fi

if ! jq empty data.json 2>/dev/null; then
    echo "[ERROR] Invalid JSON response received:"
    cat data.json
    exit 1
fi

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
