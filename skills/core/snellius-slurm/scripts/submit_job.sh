#!/bin/bash
# Snellius job submission helper
# Usage: ./submit_job.sh <job_script.sh> [partition] [cpus] [mem] [time]

JOB_SCRIPT="$1"
PARTITION="${2:-thin}"
CPUS="${3:-4}"
MEM="${4:-16G}"
TIME="${5:-01:00:00}"

if [ ! -f "$JOB_SCRIPT" ]; then
    echo "Error: Job script '$JOB_SCRIPT' not found"
    echo "Usage: $0 <job_script.sh> [partition] [cpus] [mem] [time]"
    exit 1
fi

echo "Submitting job with custom resources:"
echo "  Partition: $PARTITION"
echo "  CPUs: $CPUS"
echo "  Memory: $MEM"
echo "  Time: $TIME"
echo ""

sbatch --partition="$PARTITION" \
       --cpus-per-task="$CPUS" \
       --mem="$MEM" \
       --time="$TIME" \
       "$JOB_SCRIPT"
