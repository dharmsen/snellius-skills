#!/bin/bash
# Snellius storage checker
# Usage: ./storage_check.sh

echo "=== Home Quota ==="
quota -s

echo ""
echo "=== Home Usage ==="
du -sh /home/$USER/* 2>/dev/null | sort -hr | head -10

echo ""
echo "=== Scratch Usage ==="
if [ -d /scratch/$USER ]; then
    du -sh /scratch/$USER 2>/dev/null
    echo ""
    echo "Top directories in scratch:"
    du -sh /scratch/$USER/* 2>/dev/null | sort -hr | head -5
else
    echo "No scratch directory found"
fi

echo ""
echo "=== Filesystem Status ==="
df -h /home /scratch /data 2>/dev/null | grep -v "Filesystem"
