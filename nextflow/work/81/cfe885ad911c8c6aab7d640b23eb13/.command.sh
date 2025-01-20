#!/bin/bash -ue
echo "[DEBUG] Processing small dataset results"
    
    # Create metrics
    cat << EOF > metrics.json
{
    "process": "PRINT_JSON_CONTENT",
    "dataset_size": "small",
    "metrics": {
        "output_size_bytes": $(wc -c < data.json),
        "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF
