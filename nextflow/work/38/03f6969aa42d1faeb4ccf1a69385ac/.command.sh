#!/bin/bash -ue
echo '[DEBUG] Running CONVERT_CSV_TO_JSON'
echo '[DEBUG] csv_file -> data.csv'

# Replace newlines with \n
CSV_CONTENT=$(cat "data.csv" | tr '\n' '\\n')

echo '[DEBUG] Making request to GCF..'
curl -X POST \
    -H 'Content-Type: application/json' \
    -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
    -o data.json \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function

echo '[DEBUG] Saved data.json'
