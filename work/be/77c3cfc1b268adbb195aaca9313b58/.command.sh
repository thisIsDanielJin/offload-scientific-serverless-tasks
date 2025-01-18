#!/bin/bash -ue
echo "Reading CSV file: data.csv"
    # Replace newlines with '
' so the Cloud Function sees this as a single line
    CSV_CONTENT=$(tr '\n' '\\n' < data.csv)

    echo "Invoking GCF with CSV content..."
    curl -X POST \
        -H "Content-Type: application/json" \
        -d "{ \"csv_data\": \"$CSV_CONTENT\" }" \
        -o data.json \
        https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function

    echo "Response saved to data.json"
