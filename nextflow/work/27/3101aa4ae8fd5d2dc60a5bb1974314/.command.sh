#!/bin/bash
    set -e

    # Record start time and input size
    start_time=$(date +%s%N)
    input_lines=$(wc -l < "!{csv_file}")
    input_size_bytes=$(wc -c < "!{csv_file}")
    
    echo "[DEBUG] Running CONVERT_CSV_TO_JSON for !{dataset_size} dataset"
    echo "[DEBUG] Input size: ${input_lines} lines, ${input_size_bytes} bytes"
    
    # Record initial system metrics
    mem_before=$(free -m | awk '/Mem:/ {print $3}')
    cpu_before=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    
    # Initialize empty JSON array
    echo "[]" > data.json
    
    # Process CSV in chunks
    chunk_size=1000
    total_chunks=$(( ($input_lines + $chunk_size - 1) / $chunk_size ))
    
    echo "[DEBUG] Processing in ${total_chunks} chunks"
    
    # Create temporary directory for chunks
    mkdir -p tmp_chunks
    
    # Split into chunks
    split -l ${chunk_size} "!{csv_file}" tmp_chunks/chunk_
    
    chunk_number=0
    total_api_time=0
    
    for chunk in tmp_chunks/chunk_*; do
        chunk_start=$(date +%s%N)
        chunk_number=$((chunk_number + 1))
        chunk_size_bytes=$(wc -c < "$chunk")
        
        echo "[DEBUG] Processing chunk ${chunk_number}/${total_chunks} (${chunk_size_bytes} bytes)"
        
        # Process chunk with proper escaping
        CSV_CONTENT=$(awk '{printf "%s\n", $0}' "$chunk" | sed 's/"/\"/g')
        
        # API call with properly formatted JSON
        api_start=$(date +%s%N)
        
        response=$(curl -s -X POST             -H "Content-Type: application/json"             -d "{"csv_data":"${CSV_CONTENT}"}"             "!{params.GCF_URL}")
        
        api_end=$(date +%s%N)
        api_duration=$(( ($api_end - $api_start) / 1000000 ))
        total_api_time=$(($total_api_time + $api_duration))
        
        # Merge response with existing results
        if [ $chunk_number -eq 1 ]; then
            echo "$response" > data.json
        else
            jq -s '.[0] + .[1]' data.json <(echo "$response") > data.json.tmp
            mv data.json.tmp data.json
        fi
        
        # Rate limiting
        sleep 0.5
    done
    
    # Record final metrics
    end_time=$(date +%s%N)
    total_duration=$(( ($end_time - $start_time) / 1000000 ))
    mem_after=$(free -m | awk '/Mem:/ {print $3}')
    cpu_after=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    
    # Cleanup
    rm -rf tmp_chunks
    
    # Create metrics JSON
    cat << EOF > metrics.json
{
    "process": "CONVERT_CSV_TO_JSON",
    "dataset_size": "!{dataset_size}",
    "metrics": {
        "input": {
            "lines": $input_lines,
            "bytes": $input_size_bytes
        },
        "timing": {
            "total_duration_ms": $total_duration,
            "total_api_time_ms": $total_api_time
        },
        "system_metrics": {
            "memory": {
                "before_mb": $mem_before,
                "after_mb": $mem_after,
                "delta_mb": $(($mem_after - $mem_before))
            },
            "cpu": {
                "before_percent": $cpu_before,
                "after_percent": $cpu_after
            }
        },
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF
