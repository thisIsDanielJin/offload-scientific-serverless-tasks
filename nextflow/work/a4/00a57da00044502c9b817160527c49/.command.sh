#!/bin/bash -ue
echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
echo "[DEBUG] csv_file -> 'data_medium.csv'"

# Read and escape the CSV content
CSV_CONTENT=$(awk '{printf "%s\\n", $0}' data_medium.csv | sed 's/"/\\"/g')

echo "[DEBUG] CSV_CONTENT -> ${CSV_CONTENT}"
echo "JSON body => { \"csv_data\": \"${CSV_CONTENT}\" }"

echo "[DEBUG] Making request to GCF.."

curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function \
| tee data.json

echo "[DEBUG] curl exit code: $?"

echo "[DEBUG] Finished request, wrote GCF response to data.json"
