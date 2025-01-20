#!/bin/bash
set -e

# Record start time and input size
start_time=$(date +%s%N)
input_lines=$(wc -l < "data_medium.csv")
input_size_bytes=$(wc -c < "data_medium.csv")

echo "[DEBUG] Running CONVERT_CSV_TO_JSON for medium dataset"
echo "[DEBUG] Input size: ${input_lines} lines, ${input_size_bytes} bytes"

# Record initial system metrics
mem_before=$(free -m | awk '/Mem:/ {print $3}')
cpu_before=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
disk_before=$(df -B1 . | awk 'NR==2 {print $3}')
load_before=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

# Process CSV in chunks of 1000 lines
chunk_size=1000
total_chunks=$(( ($input_lines + $chunk_size - 1) / $chunk_size ))

echo "[DEBUG] Processing in ${total_chunks} chunks"

# Create temporary directory for chunks
mkdir -p tmp_chunks

# Initialize metrics arrays
declare -a chunk_times
declare -a api_times
declare -a chunk_sizes

# Initialize empty JSON array
echo "[]" > data.json

# Split and process in chunks
split -l ${chunk_size} "data_medium.csv" tmp_chunks/chunk_

chunk_number=0
total_api_time=0
max_chunk_time=0
min_chunk_time=999999999

for chunk in tmp_chunks/chunk_*; do
    chunk_start=$(date +%s%N)
    chunk_number=$((chunk_number + 1))
    chunk_size_bytes=$(wc -c < $chunk)
    chunk_sizes+=($chunk_size_bytes)

    echo "[DEBUG] Processing chunk ${chunk_number}/${total_chunks} (${chunk_size_bytes} bytes)"

    # Process chunk
    CSV_CONTENT=$(awk '{printf "%s\\n", $0}' $chunk | sed 's/"/\\"/g')

    # API call for chunk with detailed timing
    api_start=$(date +%s%N)

    response=$(curl -s -w "%{time_namelookup},%{time_connect},%{time_starttransfer},%{time_total}\n" -X POST \
        -H "Content-Type: application/json" \
        -d "{ \"csv_data\": \"${CSV_CONTENT}\" }" \
        https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function 2>&1)

    api_end=$(date +%s%N)
    api_duration=$(( ($api_end - $api_start) / 1000000 ))
    total_api_time=$(($total_api_time + $api_duration))
    api_times+=($api_duration)

    # Extract curl timing metrics
    timing_metrics=$(echo "$response" | tail -n1)
    response_content=$(echo "$response" | sed '$d')

    # Merge response with existing results
    if [ $chunk_number -eq 1 ]; then
        echo "$response_content" > data.json
    else
        jq -s '.[0] + .[1]' data.json <(echo "$response_content") > data.json.tmp
        mv data.json.tmp data.json
    fi

    # Calculate chunk processing time
    chunk_end=$(date +%s%N)
    chunk_duration=$(( ($chunk_end - $chunk_start) / 1000000 ))
    chunk_times+=($chunk_duration)

    # Update min/max times
    if [ $chunk_duration -lt $min_chunk_time ]; then
        min_chunk_time=$chunk_duration
    fi
    if [ $chunk_duration -gt $max_chunk_time ]; then
        max_chunk_time=$chunk_duration
    fi

    # Small delay between chunks to prevent rate limiting
    sleep 0.5
done

# Calculate average times
total_chunks_processed=${#chunk_times[@]}
avg_chunk_time=$(echo "${chunk_times[@]}" | tr ' ' '+' | bc -l)
avg_chunk_time=$(echo "scale=2; $avg_chunk_time/$total_chunks_processed" | bc -l)

avg_api_time=$(echo "${api_times[@]}" | tr ' ' '+' | bc -l)
avg_api_time=$(echo "scale=2; $avg_api_time/$total_chunks_processed" | bc -l)

# Calculate throughput
total_bytes_processed=$(echo "${chunk_sizes[@]}" | tr ' ' '+' | bc -l)
end_time=$(date +%s%N)
total_duration=$(( ($end_time - $start_time) / 1000000 ))
throughput_mbps=$(echo "scale=2; ($total_bytes_processed/1048576)/($total_duration/1000)" | bc -l)

# Record final system metrics
mem_after=$(free -m | awk '/Mem:/ {print $3}')
cpu_after=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
disk_after=$(df -B1 . | awk 'NR==2 {print $3}')
load_after=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

# Cleanup
rm -rf tmp_chunks

# Create detailed metrics
echo "{
    \"process\": \"CONVERT_CSV_TO_JSON\",
    \"dataset_size\": \"medium\",
    \"metrics\": {
        \"input\": {
            \"lines\": $input_lines,
            \"bytes\": $input_size_bytes
        },
        \"timing\": {
            \"total_duration_ms\": $total_duration,
            \"avg_chunk_time_ms\": $avg_chunk_time,
            \"min_chunk_time_ms\": $min_chunk_time,
            \"max_chunk_time_ms\": $max_chunk_time,
            \"avg_api_time_ms\": $avg_api_time,
            \"total_api_time_ms\": $total_api_time
        },
        \"throughput\": {
            \"mb_per_second\": $throughput_mbps,
            \"chunks_processed\": $total_chunks_processed,
            \"total_bytes_processed\": $total_bytes_processed
        },
        \"system_metrics\": {
            \"memory\": {
                \"before_mb\": $mem_before,
                \"after_mb\": $mem_after,
                \"delta_mb\": $(($mem_after - $mem_before))
            },
            \"cpu\": {
                \"before_percent\": $cpu_before,
                \"after_percent\": $cpu_after,
                \"delta_percent\": $(echo "$cpu_after - $cpu_before" | bc)
            },
            \"disk\": {
                \"before_bytes\": $disk_before,
                \"after_bytes\": $disk_after,
                \"delta_bytes\": $(($disk_after - $disk_before))
            },
            \"load\": {
                \"before\": $load_before,
                \"after\": $load_after,
                \"delta\": $(echo "$load_after - $load_before" | bc)
            }
        },
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
}" > metrics.json
