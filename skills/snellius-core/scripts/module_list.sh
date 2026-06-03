#!/bin/bash
# Snellius module search
# Usage: ./module_list.sh [search_term]

if [ -n "$1" ]; then
    echo "=== Searching for modules matching: $1 ==="
    module spider "$1" 2>&1
else
    echo "=== Available Modules (first 50) ==="
    module avail 2>&1 | head -50
    echo ""
    echo "To search for specific modules:"
    echo "  module spider <name>"
fi
