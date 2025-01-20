#!/bin/bash
set -e

echo "[DEBUG] Available metrics files:"
ls -la metrics_*.json

# Combine all metrics into a single report
echo "{
    \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
    \"total_workflow_duration_ms\": $(( ($(date +%s%N) - 1737388426245) / 1000000 )),
    \"dataset_metrics\": [" > scalability_metrics.json

# Add all metrics files with proper JSON formatting
first=true
for f in metrics_*.json; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> scalability_metrics.json
    fi
    cat $f | tr -d '\n' >> scalability_metrics.json
done

echo "]}" >> scalability_metrics.json

echo "[DEBUG] Generated metrics content:"
cat scalability_metrics.json
