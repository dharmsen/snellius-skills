#!/bin/bash
# Sync data from scratch to home
# Usage: ./sync_from_scratch.sh <scratch_subdir> [home_destination]

SCRATCH_DIR="$1"
DEST="${2:-/home/$USER/results/}"

if [ -z "$SCRATCH_DIR" ]; then
    echo "Error: Scratch directory required"
    echo "Usage: $0 <scratch_subdir> [home_destination]"
    exit 1
fi

SCRATCH_PATH="/scratch/$USER/$SCRATCH_DIR"

if [ ! -d "$SCRATCH_PATH" ]; then
    echo "Error: Scratch directory '$SCRATCH_PATH' not found"
    exit 1
fi

echo "Syncing from scratch:"
echo "  Source: $SCRATCH_PATH"
echo "  Destination: $DEST"
echo ""

mkdir -p "$DEST"
rsync -av --progress "$SCRATCH_PATH" "$DEST/"

echo ""
echo "Sync complete"
