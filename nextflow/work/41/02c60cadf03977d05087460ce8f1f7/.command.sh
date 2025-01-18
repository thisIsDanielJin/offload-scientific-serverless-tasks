#!/bin/bash -ue
echo "Reading CSV file..."
CSV_CONTENT=$(cat ${csv_file} | sed ':a;N;$!ba;s/\n/\\n/g')

echo "Sending HTTP request to the Cloud Function..."
curl -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"$CSV_CONTENT\" }" \
    -o data.json \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function

echo "Saving response as data.json"
