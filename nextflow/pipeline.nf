#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// Pipeline parameters with defaults
params.GCF_URL = "https://europe-west10-neural-engine-448210-n5.cloudfunctions.net/poc-ssw-google-cloud-function"
params.outdir = "${projectDir}/results"
params.metrics_file = "${params.outdir}/execution_metrics.json"
params.input = "${projectDir}/data/data_small.csv"

// Number of lines per chunk for large files
params.chunk_size = 10000
// If file has more lines than this, it will be chunked
params.size_threshold = 30000


// Define dataset sizes for scalability testing
params.datasets = [
    'small': "${projectDir}/data/data_small.csv",
    'medium_1': "${projectDir}/data/data_medium_1.csv",
    'large': "${projectDir}/data/data_large.csv",
]

workflow {
    def workflow_start = new Date()

    // Create channel from multiple datasets
    datasets_ch = Channel
        .fromList(params.datasets.entrySet())
        .map { entry -> tuple(entry.key, file(entry.value)) }

    // Split datasets into chunks if needed
    split_datasets = SPLIT_IF_NEEDED(datasets_ch)

    // Flatten the results to process each chunk
    chunked_datasets = split_datasets
        .transpose()
        .map { dataset_id, csv_file ->
            def chunk_name = csv_file.name.replace('.csv', '')
            def final_id = chunk_name.startsWith('chunk_')
                ? "${dataset_id}_${chunk_name}"
                : dataset_id
            tuple(final_id, csv_file)
        }

    // Process each dataset/chunk in parallel
    results = CONVERT_CSV_TO_JSON(chunked_datasets)

    // Group results by base dataset ID (without chunk suffix) for merging
    merged_results = results.results
        .map { dataset_id, json_file ->
            def base_id = dataset_id.split('_chunk_')[0]
            tuple(base_id, json_file)
        }
        .groupTuple()
        .branch {
            chunked: it[1].size() > 1
            single: it[1].size() == 1
        }

    // Merge chunked results
    MERGE_JSON_CHUNKS(merged_results.chunked)

    // Combine single and merged results
    MERGE_JSON_CHUNKS.out.results.mix(merged_results.single)

    // Aggregate metrics from all runs
    AGGREGATE_METRICS(
        results.metrics.collect(),
        workflow_start,
    )
}

process SPLIT_IF_NEEDED {
    debug true

    input:
    tuple val(dataset_id), path(csv_file)

    output:
    tuple val(dataset_id), path('*.csv')

    script:
    """
    #!/bin/bash
    set -e

    # Count lines in the input file (excluding header)
    total_lines=\$(wc -l < "${csv_file}")
    total_lines=\$((total_lines - 1))
    
    if [ \$total_lines -gt ${params.size_threshold} ]; then
        echo "[DEBUG] Splitting ${dataset_id} into chunks of ${params.chunk_size} lines"
        
        # Save header
        head -n 1 "${csv_file}" > header.txt
        
        # Split the file (excluding header) into chunks with numeric suffixes
        tail -n +2 "${csv_file}" | split -d -l ${params.chunk_size} - "chunk_"
        
        # Add header to each chunk and rename to .csv
        for chunk in chunk_*; do
            cat header.txt "\$chunk" > "\${chunk}.csv"
            rm "\$chunk"
        done
    else
        echo "[DEBUG] File size below threshold, using as is"
        cp "${csv_file}" "original.csv"
    fi
    """
}

process CONVERT_CSV_TO_JSON {
    debug true
    publishDir "${params.outdir}/${dataset_size}", mode: 'copy', overwrite: true

    input:
    tuple val(dataset_size), path('input.csv')

    output:
    tuple val(dataset_size), path('data.json'), emit: results
    path ("metrics_${dataset_size}.json"), emit: metrics

    script:
    """
    #!/bin/bash
    set -e

    echo "[DEBUG] Processing ${dataset_size} dataset"
    echo "[DEBUG] Reading CSV file: input.csv"
    echo "[DEBUG] File size: \$(wc -c < input.csv) bytes"
    echo "[DEBUG] First few lines of CSV:"
    head -n 3 input.csv

    start_time=\$(date +%s%N)

    # Read CSV content without escaping newlines
    csv_content=\$(cat input.csv)
    
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
        "input_size_bytes": \$(wc -c < input.csv),
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

process MERGE_JSON_CHUNKS {
    debug true
    publishDir "${params.outdir}/${dataset_id}", mode: 'copy', overwrite: true

    input:
    tuple val(dataset_id), path('chunk_*.json')

    output:
    tuple val(dataset_id), path('data.json'), emit: results

    script:
    """
    #!/bin/bash
    set -e

    echo "[DEBUG] Merging chunks for dataset: ${dataset_id}"
    echo "[DEBUG] Found chunks:"
    ls -la chunk_*.json

    # Initialize the merged file with an opening bracket
    echo "[" > data.json

    # Concatenate all JSON files, removing the outer brackets and adding commas
    first=true
    for f in chunk_*.json; do
        content=\$(cat \$f | sed 's/^\\[//g' | sed 's/\\]\$//g')
        if [ -n "\$content" ]; then
            if [ "\$first" = true ]; then
                first=false
                echo "\$content" >> data.json
            else
                echo "," >> data.json
                echo "\$content" >> data.json
            fi
        fi
    done

    # Close the JSON array
    echo "]" >> data.json

    echo "[DEBUG] Merged JSON file size: \$(wc -c < data.json) bytes"
    """
}
