FROM ubuntu:20.04

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    default-jdk \
    bash \
    locales \
    jq \
    bc \
    procps \
    coreutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Generate and set the locale
RUN locale-gen en_US.UTF-8

# Set the working directory
WORKDIR /workspace

# Install Nextflow
RUN curl -s https://get.nextflow.io | bash && \
    mv nextflow /usr/local/bin/ && \
    chmod +x /usr/local/bin/nextflow

# Create directory for data
RUN mkdir -p /workspace/data

# Default command
CMD ["/bin/bash"]