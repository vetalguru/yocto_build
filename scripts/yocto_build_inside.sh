#!/bin/bash

set -e

# Load config
CONFIG_FILE="$(dirname "$(readlink -f "$0")")/config.cfg"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Missing config file: $CONFIG_FILE"
    exit 1
fi

cd "/home/$DOCKER_YOCTO_USER/poky"

# Initialize build environment
source oe-init-build-env "$YOCTO_BUILD_DIR"

# Build image
echo "🚧 Starting Yocto build: $YOCTO_IMAGE"
bitbake "$YOCTO_IMAGE"
if [ $? -eq 0 ]; then
    echo "✅ Bitbake finished successfully"
else
    echo "❌ Bitbake failed"
    exit 1
fi

exit 0
