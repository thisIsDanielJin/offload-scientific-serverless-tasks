#!/bin/bash -ue
echo '[DEBUG] Running CONVERT_CSV_TO_JSON'
echo '[DEBUG] csv_file -> data.csv'

# Replace each real newline with '\n' (two chars: backslash + n).
# Using 'sed' with a multi-line read approach:
CSV_CONTENT=$(sed ':a;N;$!ba;s/\n/\\n/g' "data.csv")

echo '[DEBUG] Making request to GCF..'
curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{ \"csv_data\": "$CSV_CONTENT" }" \
     -o data.json \
     https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function

echo '[DEBUG] Saved data.json'
