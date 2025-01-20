#!/bin/bash -ue
start_time=$(date +%s%N)

echo '[DEBUG] Printing data.json: '
cat data.json

end_time=$(date +%s%N)
duration=$(( ($end_time - $start_time) / 1000000 ))

echo "{
    \"process\": \"PRINT_JSON_CONTENT\",
    \"duration_ms\": $duration,
    \"completed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
}" > process_metrics.json

echo "[DEBUG] Process duration: ${duration}ms"
