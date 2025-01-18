#!/bin/bash -ue
echo "Lese CSV-Datei..."
CSV_CONTENT=$(cat ${csv_file} | sed ':a;N;$!ba;s/\n/\\n/g')

echo "Sende HTTP-Request an die Cloud Function..."
curl -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"$CSV_CONTENT\" }" \
    -o data.json \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function

echo "Speichere Antwort als data.json"
