---
name: snellius-ml
description: ML/AI workflows on Snellius GPU partitions - PyTorch, TensorFlow, JAX, multi-GPU training
dependencies: [snellius-core, snellius-slurm, snellius-containers]
---

# Snellius ML/AI Workflows

Machine learning and AI workflows on Snellius GPU partitions.

**Prerequisites:** Load `snellius-core`, `snellius-slurm`, and `snellius-containers` skills.

---

## GPU Partition Overview

### GPU Nodes

- **Partition:** `gpu`
- **GPUs per node:** 4x NVIDIA A100 (40GB)
- **CPUs per node:** 64 AMD EPYC cores
- **Memory per node:** 512 GB
- **Interconnect:** NVSwitch for GPU-GPU communication

### Checking GPU Availability

```bash
# Check GPU partition status
sinfo -p gpu

# Check available GPUs
srun --partition=gpu --pty nvidia-smi

# Check specific GPU nodes
sinfo -N -p gpu
```

---

## Framework Setup

### PyTorch

#### Module Setup

```bash
module purge
module spider pytorch  # Check available versions
module load PyTorch   # Load latest
```

#### Singularity Container

```bash
# Pull PyTorch container with CUDA
singularity pull docker://pytorch/pytorch:2.0.0-cuda11.7-cudnn8-runtime

# Run with GPU support
singularity exec --nv pytorch.sif python -c "import torch; print(torch.cuda.is_available())"
```

#### Job Script

```bash
#!/bin/bash
#SBATCH --job-name=pytorch-train
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=04:00:00

module purge
module load CUDA

# Set PyTorch cache to scratch
export TORCH_HOME="/scratch/$USER/.torch"
export CUDA_CACHE_DIR="/scratch/$USER/.cuda_cache"

# Run training
python train.py \
    --data /data/project/dataset \
    --output /home/$USER/results \
    --epochs 100 \
    --batch-size 32
```

### TensorFlow

#### Module Setup

```bash
module purge
module spider tensorflow
module load TensorFlow
```

#### Singularity Container

```bash
# Pull TensorFlow container
singularity pull docker://tensorflow/tensorflow:2.13.0-gpu

# Run with GPU support
singularity exec --nv tensorflow.sif python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

#### Job Script

```bash
#!/bin/bash
#SBATCH --job-name=tf-train
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=04:00:00

module purge
module load CUDA

# Set TensorFlow cache
export TF_CACHE_DIR="/scratch/$USER/.tf_cache"

# Run training
singularity exec --nv tensorflow.sif python train.py
```

### JAX

#### Singularity Container

```bash
# Pull JAX container
singularity pull docker://python:3.10-slim

# Install JAX inside container
singularity exec --nv python.sif pip install "jax[cuda11_pip]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
```

#### Job Script

```bash
#!/bin/bash
#SBATCH --job-name=jax-train
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=04:00:00

module purge
module load CUDA

# Run JAX training
singularity exec --nv jax.sif python train_jax.py
```

---

## Multi-GPU Training

### Data Parallelism (PyTorch)

```bash
#!/bin/bash
#SBATCH --job-name=multi-gpu-train
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --mem=500G
#SBATCH --time=08:00:00

module purge
module load CUDA PyTorch

# Multi-GPU training
python -m torch.distributed.launch \
    --nproc_per_node=4 \
    train.py \
    --data /data/project/dataset \
    --output /home/$USER/results \
    --batch-size 128
```

### Distributed Training (TensorFlow)

```bash
#!/bin/bash
#SBATCH --job-name=tf-distributed
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --mem=500G
#SBATCH --time=08:00:00

module purge
module load CUDA TensorFlow

# Multi-GPU training
singularity exec --nv tensorflow.sif \
    python distributed_train.py \
    --data_dir /data/project/dataset \
    --output_dir /home/$USER/results \
    --num_gpus=4
```

---

## Optimization Tips

### Batch Size Tuning

```bash
# Start small, increase gradually
python train.py --batch-size 16   # Start
python train.py --batch-size 32   # Increase
python train.py --batch-size 64   # Maximize
```

### Mixed Precision Training

```python
# PyTorch
from torch.cuda.amp import autocast, GradScaler
scaler = GradScaler()

with autocast():
    loss = model(inputs)

# TensorFlow
import tensorflow as tf
policy = tf.keras.mixed_precision.Policy('mixed_float16')
tf.keras.mixed_precision.set_global_policy(policy)
```

### Gradient Accumulation

```python
# Simulate larger batch sizes
accumulation_steps = 4
for i, (inputs, labels) in enumerate(dataloader):
    outputs = model(inputs)
    loss = criterion(outputs, labels) / accumulation_steps
    loss.backward()

    if (i + 1) % accumulation_steps == 0:
        optimizer.step()
        optimizer.zero_grad()
```

---

## Data Loading

### Efficient Data Loading

```bash
# Copy data to scratch first
cp -r /data/project/dataset /scratch/$USER/

# Train from scratch
python train.py --data /scratch/$USER/dataset
```

### Memory Mapping

```python
# Use memory-mapped files for large datasets
import numpy as np
data = np.memmap('large_array.dat', dtype='float32', mode='r', shape=(1000000, 1024))
```

### Data Augmentation

```python
# Pre-compute augmentations for small datasets
# Use on-the-fly augmentation for large datasets
from torchvision import transforms

# On-the-fly (recommended for large datasets)
transform = transforms.Compose([
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(10),
    transforms.ToTensor(),
])
```

---

## Monitoring and Debugging

### GPU Monitoring

```bash
# Monitor GPU usage during training
watch -n 1 nvidia-smi

# In job script
nvidia-smi dmon -s u -d 1 > gpu_usage.log &
```

### Profile Training

```python
# PyTorch profiler
import torch.profiler as profiler

with profiler.profile activities=[profiler.ProfilerActivity.CPU, profiler.ProfilerActivity.CUDA] as p:
    model(inputs)

print(p.key_averages().table(sort_by="cuda_time_total"))
```

### Checkpoint Management

```bash
# Save checkpoints to scratch, copy results later
CHECKPOINT_DIR="/scratch/$USER/checkpoints"
mkdir -p $CHECKPOINT_DIR

# In training script
python train.py --checkpoint_dir $CHECKPOINT_DIR

# Copy final checkpoints to home
cp -r $CHECKPOINT_DIR /home/$USER/results/
```

---

## Common Patterns

### Training with Validation

```bash
#!/bin/bash
#SBATCH --job-name=train-val
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=04:00:00

module purge
module load CUDA PyTorch

python train.py \
    --train-data /data/project/train \
    --val-data /data/project/val \
    --checkpoint-dir /scratch/$USER/checkpoints \
    --output-dir /home/$USER/results
```

### Hyperparameter Tuning

```bash
#!/bin/bash
#SBATCH --job-name=hyperparam-tune
#SBATCH --partition=gpu
#SBATCH --array=0-9
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=02:00:00

module purge
module load CUDA PyTorch

# Use array task ID for different hyperparameters
python tune.py \
    --lr ${LR[$SLURM_ARRAY_TASK_ID]} \
    --batch-size ${BS[$SLURM_ARRAY_TASK_ID]} \
    --output-dir /home/$USER/results/tuning_$SLURM_ARRAY_TASK_ID
```

### Inference Batch

```bash
#!/bin/bash
#SBATCH --job-name=inference
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=02:00:00

module purge
module load CUDA PyTorch

python inference.py \
    --model /home/$USER/models/checkpoint.pt \
    --input /data/project/test_data \
    --output /home/$USER/results/predictions
```

---

## Troubleshooting

### CUDA Out of Memory

**Symptoms:** `RuntimeError: CUDA out of memory`

**Solutions:**
```bash
# Reduce batch size
python train.py --batch-size 16  # Reduce from 32

# Enable gradient checkpointing
# In your code
from torch.utils.checkpoint import checkpoint
output = checkpoint(model, inputs)

# Clear cache
import torch
torch.cuda.empty_cache()
```

### GPU Not Utilized

**Symptoms:** Low GPU utilization in `nvidia-smi`

**Solutions:**
```python
# Increase batch size
# Use multiple workers for data loading
dataloader = DataLoader(dataset, batch_size=32, num_workers=4)

# Pin memory for faster transfer
dataloader = DataLoader(dataset, batch_size=32, pin_memory=True)
```

### Slow Training

**Symptoms:** Training slower than expected

**Solutions:**
```bash
# Use mixed precision
python train.py --amp

# Profile code
python -m cProfile -o profile.out train.py

# Check data loading bottleneck
# Use /scratch for data
```

---

## Quick Reference

```bash
# Load modules
module purge
module load CUDA PyTorch  # or TensorFlow

# Basic GPU job
sbatch --partition=gpu --gpus-per-node=1 gpu_job.sh

# Multi-GPU
#SBATCH --gpus-per-node=4

# Monitor GPUs
nvidia-smi
watch -n 1 nvidia-smi

# Check GPU in Python
import torch
print(torch.cuda.is_available())
print(torch.cuda.device_count())

# Container training
singularity exec --nv pytorch.sif python train.py
```
