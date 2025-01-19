#!/bin/bash -ue
echo "[DEBUG] Running CONVERT_CSV_TO_JSON"
   echo "[DEBUG] csv_file -> ${csv_file}"

   # Read all lines into an array, splitting only on newlines
   IFS=$'\n'
   read -d '' -r -a lines < "${csv_file}"
   IFS=$' '

   # Join lines with literal 
in between
   CSV_CONTENT=""
   for line in "${lines[@]}"; do
     if [ -z "$CSV_CONTENT" ]; then
       # first line
       CSV_CONTENT="$line"
     else
       CSV_CONTENT="${CSV_CONTENT}\n${line}"
     fi
   done

   echo "[DEBUG] Posting CSV_CONTENT => $CSV_CONTENT"

   # Use --fail -v so that:
   #  1) Curl prints request/response details (verbose)
   #  2) Non-2xx status triggers an error exit code in Nextflow
   # Also 'tee data.json' so the response is in console and data.json
   curl --fail -v -X POST \
        -H "Content-Type: application/json" \
        -d "{ \"csv_data\": "$CSV_CONTENT" }" \
   | tee data.json

   echo "[DEBUG] Finished request, wrote GCF response to data.json"
