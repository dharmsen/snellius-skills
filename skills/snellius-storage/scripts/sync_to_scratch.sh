#!/bin/bash
# Sync data to scratch
# Usage: ./sync_to_scratch.sh <source> [destination_subdir]

SOURCE="$1"
DEST_SUBDIR="${2:-}"
SCRATCH_BASE="/scratch/$USER"

if [ ! -e "$SOURCE" ]; then
    echo "Error: Source '$SOURCE' not found"
    exit 1
fi

if [ -n "$DEST_SUBDIR" ]; then
    DEST="$SCRATCH_BASE/$DEST_SUBDIR"
else
    DEST="$SCRATCH_BASE/$(basename $SOURCE)"
fi

echo "Syncing to scratch:"
echo "  Source: $SOURCE"
echo "  Destination: $DEST"
echo ""

mkdir -p "$DEST"
rsync -av --progress "$SOURCE" "$DEST/"

echo ""
echo "Sync complete"
echo "Destination: $DEST"
