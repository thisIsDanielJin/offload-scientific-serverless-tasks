#!/bin/bash -ue
# Record start time
start_time=$(date +%s%N)

echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
echo "[DEBUG] csv_file -> 'data_medium.csv'"

# Read and escape the CSV content
CSV_CONTENT=$(awk '{printf "%s\\n", $0}' data_medium.csv | sed 's/"/\\"/g')

echo "[DEBUG] CSV_CONTENT -> ${CSV_CONTENT}"
echo "JSON body => { \"csv_data\": \"${CSV_CONTENT}\" }"

echo "[DEBUG] Making request to GCF.."

# Record API call start time
api_start_time=$(date +%s%N)

curl -v -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function \
| tee data.json

# Record API call end time and calculate duration
api_end_time=$(date +%s%N)
api_duration=$(( ($api_end_time - $api_start_time) / 1000000 ))

echo "[DEBUG] curl exit code: $?"
echo "[DEBUG] API call duration: ${api_duration}ms"

# Record end time and calculate total duration
end_time=$(date +%s%N)
total_duration=$(( ($end_time - $start_time) / 1000000 ))

# Save process metrics
echo "{
    \"process\": \"CONVERT_CSV_TO_JSON\",
    \"total_duration_ms\": $total_duration,
    \"api_call_duration_ms\": $api_duration,
    \"completed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
}" > process_metrics.json

echo "[DEBUG] Finished request, wrote GCF response to data.json"
echo "[DEBUG] Total process duration: ${total_duration}ms"
