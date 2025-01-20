#!/bin/bash -ue
# Record start time and input size
start_time=$(date +%s%N)
input_lines=$(wc -l < data_small.csv)

echo "[DEBUG] Running CONVERT_CSV_TO_JSON for small dataset"
echo "[DEBUG] Input size: ${input_lines} lines"

# Record initial memory usage
mem_before=$(free -m | awk '/Mem:/ {print $3}')

# Process CSV to JSON
CSV_CONTENT=$(awk '{printf "%s\\n", $0}' data_small.csv | sed 's/"/\\"/g')

# API call with timing
api_start=$(date +%s%N)

curl -s -w "%{time_total}\n" -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
    https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function \
    -o data.json 2>curl_stderr

api_end=$(date +%s%N)
api_duration=$(( ($api_end - $api_start) / 1000000 ))

# Record final memory and calculate metrics
mem_after=$(free -m | awk '/Mem:/ {print $3}')
mem_used=$(($mem_after - $mem_before))
end_time=$(date +%s%N)
total_duration=$(( ($end_time - $start_time) / 1000000 ))

# Create detailed metrics
echo "{
    \"process\": \"CONVERT_CSV_TO_JSON\",
    \"dataset_size\": \"small\",
    \"metrics\": {
        \"input_lines\": $input_lines,
        \"total_duration_ms\": $total_duration,
        \"api_duration_ms\": $api_duration,
        \"memory_usage_mb\": $mem_used,
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
}" > metrics.json
