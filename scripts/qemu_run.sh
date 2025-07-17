#!/bin/bash

set -e

# Resolve script path
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.cfg"

# Check and load config
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ config.cfg not found at: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

DEPLOY_DIR="$1"

if [ -z "$DEPLOY_DIR" ]; then
    echo "❌ Usage: $0 <path_to_deploy_images>"
    exit 1
fi

if [ ! -d "$DEPLOY_DIR" ]; then
    echo "❌ Directory does not exist: $DEPLOY_DIR"
    exit 2
fi

# Find kernel image
KERNEL_IMAGE=$(find "$DEPLOY_DIR" -type f -name "$QEMU_KERNEL_PATTERN" | sort | head -n 1)

# Find rootfs image
ROOTFS_IMAGE=$(find "$DEPLOY_DIR" -type f -name "$QEMU_ROOTFS_PATTERN" | sort | tail -n 1)

if [ -z "$KERNEL_IMAGE" ] || [ -z "$ROOTFS_IMAGE" ]; then
    echo "❌ Required images not found in $DEPLOY_DIR"
    echo "    Kernel: $KERNEL_IMAGE"
    echo "    RootFS: $ROOTFS_IMAGE"
    exit 3
fi

echo "✅ Found Kernel:  $KERNEL_IMAGE"
echo "✅ Found RootFS:  $ROOTFS_IMAGE"
echo "🚀 Launching QEMU..."

QEMU_CMD=(
  "$QEMU_BIN"
  -m "$QEMU_MEMORY"
  -kernel "$KERNEL_IMAGE"
  -drive file="$ROOTFS_IMAGE",format=raw,if=virtio
  -append "$QEMU_KERNEL_APPEND"
)

# Optional KVM
if [ "$QEMU_ENABLE_KVM" = "true" ]; then
  QEMU_CMD+=("-enable-kvm")
fi

# Optional graphic mode
if [ "$QEMU_GRAPHIC_MODE" = "false" ]; then
  QEMU_CMD+=("-nographic")
fi

# Network options
QEMU_CMD+=($QEMU_NET_OPTS)

# Run
"${QEMU_CMD[@]}"

exit 0
