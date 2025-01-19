#!/bin/bash -ue
echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
    echo "[DEBUG] csv_file -> 'data.csv'"

    CSV_CONTENT=$(sed ':a;N;$!ba;s/
/\n/g' data.csv)

    echo "[DEBUG] Making request to GCF.."
    echo "[DEBUG] CSV_CONTENT -> $CSV_CONTENT"

    curl -v -X POST         -H "Content-Type: application/json"         -d "{ "csv_data": "$CSV_CONTENT" }"     https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function     | tee data.json

    echo "[DEBUG] curl exit code: $?"

    echo "[DEBUG] data.json content after curl:"
    cat data.json

    echo "[DEBUG] Finished request, wrote GCF response to data.json"
