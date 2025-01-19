#!/bin/bash -ue
echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
echo "[DEBUG] csv_file -> 'data.csv'"

def csv_content = new File(data.csv).text
def escaped_content = csv_content.split('\n').join('\\n')


echo "[DEBUG] CSV_CONTENT -> $escaped_content"
echo "JSON body => { \"csv_data\": \"$escaped_content\" }"

echo "[DEBUG] Making request to GCF.."

curl -v -X POST         -H "Content-Type: application/json"         -d "{ \"csv_data\": \"$escaped_content\" }"     https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function     | tee data.json


echo "[DEBUG] curl exit code: $?"

echo "[DEBUG] data.json content after curl:"
cat data.json

echo "[DEBUG] Finished request, wrote GCF response to data.json"
