#!/bin/bash

# Combine all metrics into a single report
echo "{
    \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
    \"total_workflow_duration_ms\": $(( ($(date +%s%N) - 1737386585115) / 1000000 )),
    \"dataset_metrics\": [" > scalability_metrics.json

# Add all metrics files
first=true
for f in metrics_*.json; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> scalability_metrics.json
    fi
    cat $f >> scalability_metrics.json
done

echo "]}" >> scalability_metrics.json
