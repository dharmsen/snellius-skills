#!/bin/bash
# Snellius job status checker
# Usage: ./job_status.sh [job_id]

if [ -n "$1" ]; then
    # Show specific job details
    scontrol show job "$1"
else
    # Show all user jobs
    echo "=== Your Jobs ==="
    squeue -u $USER -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"
    echo ""
    echo "=== Summary ==="
    squeue -u $USER | grep -v "JOBID" | wc -l | xargs echo "Total jobs:"
fi
