---
name: snellius-containers
description: Apptainer/Singularity containers on Snellius - image management, bind mounts, GPU execution
dependencies: [snellius-core]
---

# Snellius Containers (Apptainer/Singularity)

Container management and execution using Apptainer (Singularity-compatible) on Snellius.

**Prerequisite:** Load `snellius-core` for basic system information.

---

## Apptainer Overview

Snellius uses **Apptainer** (formerly Singularity) for containers. The `singularity` command is available as a symlink to apptainer.

### Version

```bash
singularity --version
# Apptainer version 1.x.x
```

### Key Features

- **Singularity-compatible** - Most Singularity commands work
- **User-space** - No root privileges required
- **GPU support** - NVIDIA CUDA containers work on GPU partitions
- **Integration** - Works with SLURM job scripts

---

## Basic Commands

```bash
# Pull image from Docker Hub
singularity pull docker://ubuntu:22.04

# Pull from Singularity Library
singularity pull library://ubuntu:22.04

# Build from Dockerfile
singularity build ubuntu.sif docker://ubuntu:22.04

# Run container
singularity exec ubuntu.sif bash
singularity run ubuntu.sif

# Shell into container
singularity shell ubuntu.sif

# Convert Docker to Singularity
singularity pull myimage.sif docker://myuser/myimage:latest
```

---

## Image Cache Management

### Cache Directory

Set cache directory to scratch (images can be large):

```bash
export SINGULARITY_CACHEDIR="/scratch/$USER/singularity_cache"
export APPTAINER_CACHEDIR="/scratch/$USER/singularity_cache"
mkdir -p $SINGULARITY_CACHEDIR
```

### Cache in Job Scripts

```bash
#!/bin/bash
#SBATCH --job-name=container-job
#SBATCH --partition=thin
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00

# Set cache directory
export SINGULARITY_CACHEDIR="/scratch/$USER/singularity_cache"
mkdir -p $SINGULARITY_CACHEDIR

# Pull image (cached on subsequent runs)
singularity pull docker://ubuntu:22.04

# Run container
singularity exec ubuntu.sif python script.py
```

---

## Bind Mounts

### Default Mounts

By default, Apptainer mounts:
- `/home`
- `/tmp`
- Current working directory

### Custom Bind Mounts

**Syntax:** `--bind <source>:<destination>`

```bash
# Mount scratch into container
singularity exec --bind /scratch:/data ubuntu.sif python process.py

# Mount multiple directories
singularity exec \
  --bind /scratch:/data \
  --bind /data/project:/input \
  ubuntu.sif python process.py

# Mount with read-only
singularity exec --bind /scratch:/data:ro ubuntu.sif python script.py
```

### Job Script with Bind Mounts

```bash
#!/bin/bash
#SBATCH --job-name=container-workflow
#SBATCH --partition=thin
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00

WORK="/scratch/$USER/work/${SLURM_JOB_ID}"
IMAGE="/home/$USER/images/myapp.sif"

mkdir -p $WORK

# Mount work directory into container
singularity exec \
  --bind /scratch:/scratch \
  --bind $WORK:/work \
  $IMAGE \
  python /app/process.py --input /data/input --output /work/output

# Copy results back
cp $WORK/output /home/$USER/results/
```

---

## GPU Containers

### GPU Jobs with Containers

```bash
#!/bin/bash
#SBATCH --job-name=gpu-container
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00

module purge
module load CUDA

# Set CUDA library path
export SINGULARITYENV_CUDA_PATH=$CUDA_HOME

# Pull CUDA-enabled image
singularity pull docker://nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Run GPU application
singularity exec --nv cuda.sif nvidia-smi

# Run training script
singularity exec \
  --nv \
  --bind /scratch/$USER:/work \
  cuda.sif \
  python train.py --data /work/data
```

### GPU Container Options

- `--nv` - Enable NVIDIA GPU support
- `--nv-ccli` - Enable NVIDIA CUDA command-line tools
- GPU libraries are automatically mounted

---

## Environment Variables

### Passing Variables

**Syntax:** `--env VAR=value` or `SINGULARITYENV_VAR=value`

```bash
# Single variable
singularity exec --env MYVAR=value ubuntu.sif bash

# Multiple variables
singularity exec \
  --env VAR1=value1 \
  --env VAR2=value2 \
  ubuntu.sif bash

# Export from host
export SINGULARITYENV_MYVAR=value
singularity exec ubuntu.sif bash
```

### Common Environment Variables

```bash
# Python path
export SINGULARITYENV_PYTHONPATH=/app/lib

# Data directories
export SINGULARITYENV_DATA_DIR=/data
export SINGULARITYENV_OUTPUT_DIR=/output

# GPU settings
export SINGULARITYENV_CUDA_VISIBLE_DEVICES=0
```

---

## Container Sources

### Docker Hub

```bash
# Pull from Docker Hub
singularity pull myimage.sif docker://ubuntu:22.04
singularity pull nginx.sif docker://nginx:latest
singularity pull pytorch.sif docker://pytorch/pytorch:2.0.0-cuda11.7-cudnn8-runtime
```

### Singularity Library

```bash
# Pull from Singularity Library
singularity pull library://ubuntu:22.04
singularity pull library://docker://alpine:latest
```

### Build from Definition File

```bash
# Create definition file
cat > ubuntu.def << 'EOF'
Bootstrap: docker
From: ubuntu:22.04

%post
    apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && pip3 install numpy pandas

%environment
    export LC_ALL=C
    export PATH=/usr/local/bin:$PATH
EOF

# Build image
singularity build ubuntu.sif ubuntu.def
```

---

## Common Patterns

### Python Environment

```bash
#!/bin/bash
#SBATCH --job-name=python-container
#SBATCH --partition=thin
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00

IMAGE="/home/$USER/images/python-env.sif"

# Run Python script with specific packages
singularity exec \
  --bind /scratch/$USER:/data \
  $IMAGE \
  python3 /data/script.py
```

### R Environment

```bash
# Pull R image
singularity pull docker://rocker/r-ver:4.3.0

# Run R script
singularity exec \
  --bind /data/project:/data \
  rocker-r-ver-4.3.0.sif \
  Rscript /data/analysis.R
```

### Bioinformatics Tools

```bash
# Pull bioinformatics container
singularity pull docker://biocontainers/samtools:v1.20.0_cv2

# Run samtools
singularity exec \
  --bind /data/seq:/data \
  samtools-v1.20.0_cv2.sif \
  samtools view /data/input.bam
```

---

## Image Management

### Organizing Images

```bash
# Create image directory
mkdir -p /home/$USER/images

# Store images
mv *.sif /home/$USER/images/

# List images
ls -lh /home/$USER/images/
```

### Image Information

```bash
# Inspect image
singularity inspect ubuntu.sif

# Run tests
singularity exec ubuntu.sif cat /etc/os-release

# Check size
du -h *.sif
```

### Image Cleanup

```bash
# Remove old images
find /home/$USER/images -name "*.sif" -mtime +90 -delete

# Clean cache
singularity cache clean
```

---

## Troubleshooting

### Permission Denied

**Problem:** Cannot write to mounted directory

**Solution:** Check bind mount permissions

```bash
# Ensure directory exists and is writable
mkdir -p /scratch/$USER/work
chmod 755 /scratch/$USER/work

# Use correct bind mount
singularity exec --bind /scratch/$USER/work:/work ubuntu.sif
```

### Library Not Found

**Problem:** Container missing system libraries

**Solution:** Use appropriate base image or install libraries

```bash
# Use image with more complete environment
singularity pull docker://ubuntu:22.04

# Or bind host libraries
singularity exec --bind /usr/lib:/usr/lib:ro ubuntu.sif
```

### GPU Not Accessible

**Problem:** CUDA errors in container

**Solution:** Ensure GPU partition and correct flags

```bash
# Must be on GPU partition
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1

# Use --nv flag
singularity exec --nv cuda.sif nvidia-smi
```

### Out of Space

**Problem:** Cannot pull images

**Solution:** Use scratch for cache

```bash
export SINGULARITY_CACHEDIR="/scratch/$USER/singularity_cache"
mkdir -p $SINGULARITY_CACHEDIR
```

---

## Quick Reference

```bash
# Pull images
singularity pull docker://image:tag              # From Docker Hub
singularity pull library://image:tag             # From Singularity Library
singularity build image.sif docker://image:tag  # Build from Docker

# Run containers
singularity exec image.sif command               # Execute command
singularity run image.sif                        # Run default
singularity shell image.sif                      # Interactive shell

# Bind mounts
singularity exec --bind /src:/dst image.sif      # Mount directory
singularity exec --bind /src:/dst:ro image.sif   # Read-only mount

# GPU support
singularity exec --nv image.sif                  # Enable NVIDIA

# Environment
singularity exec --env VAR=value image.sif        # Set variable
export SINGULARITYENV_VAR=value                  # Export variable

# Cache
export SINGULARITY_CACHEDIR=/path/to/cache       # Set cache location
singularity cache clean                          # Clean cache
```
