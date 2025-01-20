#!/bin/bash
set -e

echo "[DEBUG] Merging chunks for dataset: large"
echo "[DEBUG] Found chunks:"
ls -la chunk_*.json

# Initialize the merged file with an opening bracket
echo "[" > data.json

# Concatenate all JSON files, removing the outer brackets and adding commas
first=true
for f in chunk_*.json; do
    content=$(cat $f | sed 's/^\[//g' | sed 's/\]$//g')
    if [ -n "$content" ]; then
        if [ "$first" = true ]; then
            first=false
            echo "$content" >> data.json
        else
            echo "," >> data.json
            echo "$content" >> data.json
        fi
    fi
done

# Close the JSON array
echo "]" >> data.json

echo "[DEBUG] Merged JSON file size: $(wc -c < data.json) bytes"
