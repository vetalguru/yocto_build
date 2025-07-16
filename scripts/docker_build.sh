#!/bin/bash

# Include config
source ./config.cfg

if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "❌ DOCKER_IMAGE_NAME is not set in config.cfg"
    exit 1
fi

# Check input argument (absolute path to Dockerfile)
if [ -z "$1" ]; then
    echo "❌ Please provide the full path to the Dockerfile."
    echo "Usage: $0 /full/path/to/Dockerfile"
    exit 1
fi

DOCKERFILE_PATH="$1"

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "❌ Dockerfile not found at: $DOCKERFILE_PATH"
    exit 1
fi

# Extract directory and filename
DOCKERFILE_DIR="$(dirname "$DOCKERFILE_PATH")"
DOCKERFILE_NAME="$(basename "$DOCKERFILE_PATH")"

# Build Docker image
docker build -t "$DOCKER_IMAGE_NAME" -f "$DOCKERFILE_PATH" "$DOCKERFILE_DIR"

# Check build result
if [ $? -eq 0 ]; then
    echo "✅ Docker image '$DOCKER_IMAGE_NAME' created successfully."
else
    echo "❌ Error occurred while building Docker image '$DOCKER_IMAGE_NAME'."
    exit 1
fi

exit 0
