#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// Pipeline parameters with defaults
params.GCF_URL = "https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function"
params.outdir = "${projectDir}/results"
params.metrics_file = "${params.outdir}/execution_metrics.json"
params.input = "${projectDir}/data/data_small.csv"

// Define dataset sizes for scalability testing
params.datasets = [
    'small': "${projectDir}/data/data_small.csv",
    'medium': "${projectDir}/data/data_medium.csv",
]

workflow {
    def workflow_start = new Date()

    // Create channel from multiple datasets
    datasets_ch = Channel
        .fromList(params.datasets.entrySet())
        .map { entry -> tuple(entry.key, file(entry.value)) }

    // Process each dataset size in parallel
    results = CONVERT_CSV_TO_JSON(datasets_ch)

    // Aggregate metrics from all runs
    AGGREGATE_METRICS(
        results.metrics.collect(),
        workflow_start,
    )
}

process CONVERT_CSV_TO_JSON {
    debug true
    publishDir "${params.outdir}/${dataset_size}", mode: 'copy', overwrite: true

    input:
    tuple val(dataset_size), path(csv_file)

    output:
    tuple val(dataset_size), path('data.json'), emit: results
    path ("metrics_${dataset_size}.json"), emit: metrics

    script:
    """
    #!/bin/bash
    set -e

    echo "[DEBUG] Processing ${dataset_size} dataset"
    echo "[DEBUG] Reading CSV file: ${csv_file}"
    echo "[DEBUG] File size: \$(wc -c < ${csv_file}) bytes"
    echo "[DEBUG] First few lines of CSV:"
    head -n 3 ${csv_file}

    start_time=\$(date +%s%N)

    # Read CSV content without escaping newlines
    csv_content=\$(cat ${csv_file})
    
    # Create proper JSON request body and make API call
    jq -n --arg csv "\$csv_content" '{csv_data: \$csv}' | \
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --data @- \
        ${params.GCF_URL} > data.json

    end_time=\$(date +%s%N)
    duration=\$(( (\$end_time - \$start_time) / 1000000 ))

    echo "[DEBUG] Response size: \$(wc -c < data.json) bytes"

    # Create metrics with unique filename
    cat << EOF > metrics_${dataset_size}.json
{
    "process": "CONVERT_CSV_TO_JSON",
    "dataset_size": "${dataset_size}",
    "metrics": {
        "input_size_bytes": \$(wc -c < ${csv_file}),
        "output_size_bytes": \$(wc -c < data.json),
        "duration_ms": \$duration,
        "timestamp": "\$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
}
EOF
    """
}

process AGGREGATE_METRICS {
    debug true
    publishDir params.outdir, mode: 'copy', overwrite: true

    input:
    path 'metrics_*.json'
    val workflow_start

    output:
    path 'scalability_metrics.json'

    script:
    """
    #!/bin/bash
    set -e
    
    echo "[DEBUG] Available metrics files:"
    ls -la metrics_*.json
    
    # Combine all metrics into a single report
    echo "{
        \\"timestamp\\": \\"\$(date -u +"%Y-%m-%dT%H:%M:%SZ")\\",
        \\"total_workflow_duration_ms\\": \$(( (\$(date +%s%N) - ${workflow_start.time}) / 1000000 )),
        \\"dataset_metrics\\": [" > scalability_metrics.json

    # Add all metrics files with proper JSON formatting
    first=true
    for f in metrics_*.json; do
        if [ "\$first" = true ]; then
            first=false
        else
            echo "," >> scalability_metrics.json
        fi
        cat \$f | tr -d '\\n' >> scalability_metrics.json
    done

    echo "]}" >> scalability_metrics.json
    
    echo "[DEBUG] Generated metrics content:"
    cat scalability_metrics.json
    """
}
