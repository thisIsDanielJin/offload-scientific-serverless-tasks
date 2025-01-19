# CSV to JSON Conversion Pipeline with Nextflow

This project demonstrates a serverless workflow for converting CSV files to JSON format using Nextflow and a Google Cloud Function (GCF). The pipeline processes a CSV file, converts it to JSON, and displays the result.

## Prerequisites

Before running the pipeline, ensure you have the following installed:

-   [Nextflow](https://www.nextflow.io/)

## Pipeline Overview

The pipeline consists of two processes:

1. `CONVERT_CSV_TO_JSON`: Reads the CSV file, converts its content to a JSON payload, and sends it to the Google Cloud Function.
2. `PRINT_JSON_CONTENT`: Displays the response received from the Google Cloud Function.

## Folder Structure

```plaintext
.
├── pipeline.nf          # The main Nextflow script
├── data/
│   └── data.csv         # Input CSV file
├── results/             # Output directory for results
└── README.md            # Project documentation
```

## Usage

1. **Prepare the Input CSV File**:  
   Place your CSV file in the `data/` directory. Ensure the file is named `data.csv`.

    Example `data.csv`:

    ```csv
    name,age
    Daniel,24
    Tom,42
    Maria,18

    ```

2. **Run the Pipeline**:
   Execute the following command
    ```
    nextflow run pipeline.nf
    ```
3. **View the Output**:
   After succesful execution:

-   The JSON output will be saved in the `results/` directory as `data.json`.
-   The content will also be displayed in the terminal.
