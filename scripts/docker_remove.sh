#!/bin/bash

# Load configuration
source ./config.cfg


# Stop and remove all containers based on image
CONTAINERS=$(docker ps -a --filter ancestor="$DOCKER_IMAGE_NAME" -q)
if [ -n "$CONTAINERS" ]; then
    echo "🗑️ Stopping and removing containers based on image '$DOCKER_IMAGE_NAME'..."
    docker rm -f $CONTAINERS
fi

# Remove image if exists
if docker images "$DOCKER_IMAGE_NAME" | grep -q "$DOCKER_IMAGE_NAME"; then
    echo "🗑️ Removing Docker image '$DOCKER_IMAGE_NAME'..."
    docker rmi "$DOCKER_IMAGE_NAME"
else
    echo "ℹ️ No Docker image named '$DOCKER_IMAGE_NAME' found."
fi

# Optional: Prune dangling containers (interactive prompt)
read -p "⚠️ Do you want to prune **all stopped containers**? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    docker container prune -f
fi

echo "✅ Docker cleanup completed."

exit 0
