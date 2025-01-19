#!/bin/bash -ue
echo '[DEBUG] Running CONVERT_CSV_TO_JSON'
echo '[DEBUG] csv_file -> data.csv'

# Replace each newline with literal '\n'
CSV_CONTENT=\$(tr '\n' '\\n' < "data.csv")

echo '[DEBUG] Making request to GCF..'

# Use tee so we see output in console & also write data.json
curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"\$CSV_CONTENT\" }" \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function \
    | tee data.json

echo '[DEBUG] data.json content after curl:'
cat data.json

echo '[DEBUG] Finished request, wrote GCF response to data.json'
