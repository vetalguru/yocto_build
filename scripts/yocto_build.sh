#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Include config
source ./config.cfg

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ROOT_PATH="$(readlink -f "$SCRIPT_DIR/..")"
WORKING_DIR="$ROOT_PATH/$WORKING_DIR_NAME"
WORKING_DOCKER_DIR="$WORKING_DIR/$WORKING_DOCKER_DIR_NAME"
WORKING_DOCKER_FILE="$WORKING_DOCKER_DIR/$DOCKER_FILE_NAME"
GIT_DIR="$WORKING_DIR/$GIT_YOCTO_DIR_NAME"
DEPLOY_DIR="$GIT_DIR/$YOCTO_BUILD_DIR/$YOCTO_DEPLOY_DIR/$YOCTO_MACHINE"

echo "📌 Root dir:      $ROOT_PATH"
echo "📁 Working dir:   $WORKING_DIR"
echo "🐳 Docker dir:    $WORKING_DOCKER_DIR"

#######################################
# Check requirements

REQUIRED_CMDS=(docker git qemu-system-x86_64)

for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" > /dev/null; then
    echo "❌ Missing required tool: $cmd"
    exit 1
  fi
done

echo "✅ All host dependencies are installed"


#######################################
# Create working directory

if [ -d "$WORKING_DIR" ]; then
    echo "📂 Folder exists: $WORKING_DIR"
    rm -rf "$WORKING_DIR"
    echo "🗑️ Removed: $WORKING_DIR"
fi

mkdir -p "$WORKING_DIR"
echo "✅ Created: $WORKING_DIR"

#######################################
# Generate Dockerfile

"$SCRIPT_DIR/dockerfile_generate.sh" "$WORKING_DOCKER_DIR"
echo "✅ Dockerfile generated"

#######################################
# Build Docker image

echo "🐳 Building Docker image: $DOCKER_IMAGE_NAME"
"$SCRIPT_DIR/docker_build.sh" "$WORKING_DOCKER_FILE"
echo "✅ Docker image '$DOCKER_IMAGE_NAME' built successfully."

#######################################
# Clone Yocto repo if not already present

if [ ! -d "$GIT_DIR/.git" ]; then
    echo "🌐 Cloning Yocto repository..."
    git clone "$GIT_YOCTO_URL" "$GIT_DIR"
    cd "$GIT_DIR"
    git checkout "$GIT_YOCTO_BRANCH"
    echo "✅ Repository is ready at $GIT_DIR"
else
    echo "🔁 Yocto repo already cloned. Skipping clone."
fi

#######################################
# Start Docker container with Yocto build

if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "❌ Docker image name not set. Check config.cfg"
    exit 1
fi

HOST_BUILD_SCRIPT="$SCRIPT_DIR/yocto_build_inside.sh"
if [ ! -f "$HOST_BUILD_SCRIPT" ]; then
    echo "❌ Missing build script: $HOST_BUILD_SCRIPT"
    exit 1
fi

if [ -z "$DOCKER_YOCTO_USER" ]; then
    echo "❌ Missing Docker user name: $DOCKER_YOCTO_USER"
    exit 1
fi

CONTAINER_BUILD_SCRIPT="/home/$DOCKER_YOCTO_USER/yocto_build_inside.sh"

DOCKER_RUN_FLAGS=""
if [ "$DOCKER_REMOVE_CONTAINER" = "true" ]; then
    DOCKER_RUN_FLAGS="--rm"
fi

echo "🚀 Starting Docker container from image: $DOCKER_IMAGE_NAME"
docker run $DOCKER_RUN_FLAGS -it \
    -v "$GIT_DIR":"/home/$DOCKER_YOCTO_USER/poky" \
    -v "$HOST_BUILD_SCRIPT":"$CONTAINER_BUILD_SCRIPT" \
    -v "$SCRIPT_DIR/config.cfg":"/home/$DOCKER_YOCTO_USER/config.cfg" \
    --workdir "/home/$DOCKER_YOCTO_USER" \
    -u "$DOCKER_YOCTO_USER" \
    --hostname yocto-builder \
    --name yocto_build_instance \
    "$DOCKER_IMAGE_NAME" \
    bash "$CONTAINER_BUILD_SCRIPT"

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Yocto build completed successfully"
    if [ "$RUN_QEMU_AFTER_BUILD" = "true" ]; then
        echo "🔍 Launching QEMU with images from: $DEPLOY_DIR"
        "$SCRIPT_DIR/qemu_run.sh" "$DEPLOY_DIR"
    fi
else
    echo "❌ Yocto build failed with exit code $BUILD_RESULT"
fi

exit $BUILD_RESULT

