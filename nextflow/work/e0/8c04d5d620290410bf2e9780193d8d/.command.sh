#!/bin/bash -ue
echo '[DEBUG] Running CONVERT_CSV_TO_JSON'

# Hard-coded CSV text:
CSV_CONTENT="name,age\nDaniel,24\nTom,42\nMaria,18"

echo '[DEBUG] Making request to GCF..'
curl -X POST \
     -H "Content-Type: application/json" \
     -d "{ \"csv_data\": "$CSV_CONTENT" }" \
| tee data.json

echo '[DEBUG] Finished request, wrote GCF response to data.json'
