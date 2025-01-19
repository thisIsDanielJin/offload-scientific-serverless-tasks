#!/bin/bash -ue
echo '[DEBUG] Running CONVERT_CSV_TO_JSON'
echo '[DEBUG] csv_file -> data.csv'

# Turn each REAL newline into literal '\n'
CSV_CONTENT=$(tr '\n' '\\n' < "data.csv")

echo '[DEBUG] Making request to GCF..'
#
# We pipe curl output to 'tee data.json' so the response is:
#   1) Shown in the console
#   2) Saved to data.json
#
curl -X POST \
     -H "Content-Type: application/json" \
     -d "{ \"csv_data\": "$CSV_CONTENT" }" \
| tee data.json

echo '[DEBUG] Finished request, wrote GCF response to data.json'
