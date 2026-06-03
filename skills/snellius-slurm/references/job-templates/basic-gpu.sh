#!/bin/bash
#SBATCH --job-name=gpu-job
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --gpus-per-node=1
#SBATCH --gpu-bind=closest
#SBATCH --time=04:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

# Load modules
module purge
module load CUDA

# Optional: Load Python/ML frameworks
# module load PyTorch

# Set GPU variables
export CUDA_VISIBLE_DEVICES=0

echo "Job started at $(date)"
echo "Running on $(hostname)"

# Check GPU availability
nvidia-smi

# Your GPU computation
# Example: PyTorch training
# python train.py --data /data/project/dataset --output /home/$USER/results

echo "Job finished at $(date)"
