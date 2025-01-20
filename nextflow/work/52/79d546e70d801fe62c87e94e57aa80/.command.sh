#!/bin/bash -ue
echo "[DEBUG] Printing JSON content for large dataset"
cat data.json

# Create metrics
echo "{
    \"process\": \"PRINT_JSON_CONTENT\",
    \"dataset_size\": \"large\",
    \"metrics\": {
        \"output_size_bytes\": $(wc -c < data.json),
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }
}" > metrics.json
