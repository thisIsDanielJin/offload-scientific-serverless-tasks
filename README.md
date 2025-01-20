# Serverless Scientific Workflow PoC

This project demonstrates a scalable scientific workflow using Nextflow and Google Cloud Functions.

## Prerequisites

-   Docker
-   Nextflow (24.10.3 or later)
-   curl

## Docker Setup

1. Build the Docker image:

```bash
cd nextflow
docker build -t nextflow_gfc_image .
```

2. Verify the image:

```bash
docker images | grep nextflow_gfc_image
```

## Running the Pipeline

The pipeline is configured to run scalability tests with different dataset sizes in parallel:

```bash
nextflow run pipeline.nf -with-docker nextflow_gfc_image
```

## Output Structure

The pipeline generates metrics for each dataset size:

```
results/
├── small/
│   ├── data.json
│   └── process_metrics.json
├── medium/
│   ├── data.json
│   └── process_metrics.json
├── large/
│   ├── data.json
│   └── process_metrics.json
├── execution_metrics.json
└── scalability_metrics.json
```

## Metrics Collected

-   **Process Level**:

    -   Input size (lines/bytes)
    -   Processing duration
    -   Memory usage
    -   API call timing
    -   CPU utilization

-   **Workflow Level**:
    -   Total execution time
    -   Success/failure status
    -   Resource utilization

## Docker Container Details

The `nextflow_gfc_image` container includes:

-   Base OS tools for system metrics (free, top)
-   curl for API requests
-   JSON processing utilities
-   Required system libraries

## Reproducibility Notes

To ensure consistent results:

1. Always use the Docker container
2. Run with the same resource constraints
3. Keep network conditions similar
4. Use the same dataset sizes

## Troubleshooting

If you encounter Docker-related issues:

```bash
# Remove old containers
docker rm $(docker ps -a -q)

# Clean up images
docker system prune -f

# Rebuild image
docker build -t nextflow_gfc_image .
```
