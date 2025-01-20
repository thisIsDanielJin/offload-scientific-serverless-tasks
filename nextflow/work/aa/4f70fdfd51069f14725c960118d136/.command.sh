#!/bin/bash
set -e

# Record start time and input size
start_time=$(date +%s%N)
input_lines=$(wc -l < "data_large.csv")

echo "[DEBUG] Running CONVERT_CSV_TO_JSON for large dataset"
echo "[DEBUG] Input size: ${input_lines} lines"

# Record initial memory usage
mem_before=$(free -m | awk '/Mem:/ {print $3}')

# Process CSV in chunks of 1000 lines
chunk_size=1000
total_chunks=$(( ($input_lines + $chunk_size - 1) / $chunk_size ))

echo "[DEBUG] Processing in ${total_chunks} chunks"

# Create temporary directory for chunks
mkdir -p tmp_chunks

# Initialize empty JSON array
echo "[]" > data.json

# Split and process in chunks
split -l ${chunk_size} "data_large.csv" tmp_chunks/chunk_

chunk_number=0
for chunk in tmp_chunks/chunk_*; do
    chunk_number=$((chunk_number + 1))
    echo "[DEBUG] Processing chunk ${chunk_number}/${total_chunks}"

    # Process chunk
    CSV_CONTENT=$(awk '{printf "%s\\n", $0}' $chunk | sed 's/"/\\"/g')

    # API call for chunk
    api_start=$(date +%s%N)

    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
        https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function)

    api_end=$(date +%s%N)

    # Merge response with existing results
    if [ $chunk_number -eq 1 ]; then
        echo "$response" > data.json
    else
        # Combine JSON arrays
        jq -s '.[0] + .[1]' data.json <(echo "$response") > data.json.tmp
        mv data.json.tmp data.json
    fi

    # Small delay between chunks to prevent rate limiting
    sleep 0.5
done

# Cleanup
rm -rf tmp_chunks

# Record final metrics
mem_after=$(free -m | awk '/Mem:/ {print $3}')
mem_used=$(($mem_after - $mem_before))
end_time=$(date +%s%N)
total_duration=$(( ($end_time - $start_time) / 1000000 ))

# Create detailed metrics
echo "{
    \"process\": \"CONVERT_CSV_TO_JSON\",
    \"dataset_size\": \"large\",
    \"metrics\": {
        \"input_lines\": $input_lines,
        \"total_duration_ms\": $total_duration,
        \"chunks_processed\": $total_chunks,
        \"memory_usage_mb\": $mem_used,
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
}" > metrics.json
