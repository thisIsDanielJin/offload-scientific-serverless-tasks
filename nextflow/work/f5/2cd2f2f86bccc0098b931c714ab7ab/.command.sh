#!/bin/bash
set -e

# Count lines in the input file (excluding header)
total_lines=$(wc -l < data_medium_1.csv)
total_lines=$((total_lines - 1))

if [ $total_lines -gt 30000 ]; then
    echo "[DEBUG] Splitting medium_1 into chunks of 10000 lines"

    # Save header
    head -n 1 data_medium_1.csv > header.txt

    # Split the file (excluding header) into chunks
    tail -n +2 data_medium_1.csv | split -l 10000 - "chunk_"

    # Add header to each chunk and rename to .csv
    for chunk in chunk_*; do
        cat header.txt $chunk > ${chunk}.csv
        rm $chunk
    done
else
    echo "[DEBUG] File size below threshold, using as is"
    cp data_medium_1.csv input.csv
fi
