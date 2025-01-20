#!/bin/bash
set -e

echo "[DEBUG] Processing medium dataset"
echo "[DEBUG] Reading CSV file: data_medium.csv"
echo "[DEBUG] File size: $(wc -c < data_medium.csv) bytes"
echo "[DEBUG] First few lines of CSV:"
head -n 3 data_medium.csv

# Read CSV content without escaping newlines
csv_content=$(cat data_medium.csv)

# Create proper JSON request body
jq -n --arg csv "$csv_content" '{csv_data: $csv}' > debug_request.json

echo "[DEBUG] Request payload size: $(wc -c < debug_request.json) bytes"
echo "[DEBUG] Request payload content:"
cat debug_request.json

# Make API call with detailed output
curl -v -X POST         -H "Content-Type: application/json"         -H "Accept: application/json"         --data @debug_request.json         https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function > data.json 2> debug_response.txt

echo "[DEBUG] Response size: $(wc -c < data.json) bytes"
echo "[DEBUG] Response content:"
cat data.json
