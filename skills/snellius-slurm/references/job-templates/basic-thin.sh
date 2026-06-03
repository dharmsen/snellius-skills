#!/bin/bash
#SBATCH --job-name=basic-job
#SBATCH --partition=thin
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

# Load modules
module purge
module load YourApp

# Your commands here
echo "Job started at $(date)"
echo "Running on $(hostname)"

# Your computation
# ...

echo "Job finished at $(date)"
