#!/bin/bash
# Snellius job cancellation helper
# Usage: ./cancel_job.sh [job_id]

if [ -n "$1" ]; then
    # Cancel specific job
    echo "Cancelling job $1..."
    scancel "$1"
else
    # Cancel all user jobs with confirmation
    echo "=== Your Jobs ==="
    squeue -u $USER
    echo ""
    read -p "Cancel all your jobs? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        scancel -u $USER
        echo "All jobs cancelled"
    else
        echo "Cancelled"
    fi
fi
