#!/bin/bash

# Load build configuration
source ./config.cfg

# Check input argument for Dockerfile output directory
if [ -z "$1" ]; then
    echo "❌ Enter working directory to generate Dockerfile:"
    echo "   Example: $0 ./build_dir"
    exit 1
fi

if [ ! -f "./config.cfg" ]; then
    echo "❌ config.cfg not found in current directory. Please run from the project root."
    exit 1
fi

TARGET_DIR="$1"

# Remove existing target directory if it exists
if [ -d "$TARGET_DIR" ]; then
    echo "📂 Directory exists: $TARGET_DIR. Rewriting..."
    rm -rf "$TARGET_DIR"
fi

# Create target directory
mkdir -p "$TARGET_DIR"
echo "✅ Directory created: $TARGET_DIR"

# Generate Dockerfile
DOCKERFILE_PATH="${TARGET_DIR}/${DOCKER_FILE_NAME}"

echo "🛠 Generating Dockerfile for Ubuntu $DOCKER_UBUNTU_VERSION with user '$DOCKER_YOCTO_USER'"
cat <<EOF > "$DOCKERFILE_PATH"
FROM ubuntu:${DOCKER_UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \\
    apt-get install -y --no-install-recommends \\
$(printf '    %s \\\n' "${DOCKER_PACKAGES[@]}" | sed '$ s/ \\$//') && \\
    locale-gen ${DOCKER_LOCALE} && \\
    update-locale LANG=${DOCKER_LOCALE} && \\
    rm -rf /var/lib/apt/lists/*

RUN useradd -m ${DOCKER_YOCTO_USER} && \\
    echo "${DOCKER_YOCTO_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${DOCKER_YOCTO_USER}

ENV LANG=${DOCKER_LOCALE} \\
    LANGUAGE=${DOCKER_LOCALE} \\
    LC_ALL=${DOCKER_LOCALE}
EOF

# Confirm Dockerfile creation
echo "✅ Dockerfile generated: $DOCKERFILE_PATH"

exit 0
