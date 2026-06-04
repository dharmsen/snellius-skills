---
name: snellius-core
description: Use when connecting to Snellius, running jobs on Snellius, or need basic system reference (partitions, storage, SLURM commands, modules).
---

# Snellius HPC Core Reference

Reference skill for running jobs on Snellius, the Dutch national supercomputer hosted at SURF.

**Sources:**
- [Snellius Documentation](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660184/Snellius)
- [SLURM Batch System](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660221/SLURM+batch+system)
- [Example Job Scripts](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660234/Example+job+scripts)
- [Snellius Partitions](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660209/Snellius+partitions)
- [Snellius Hardware](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660208/Snellius+hardware)
- [Snellius Filesystems](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/85295828/Snellius+filesystems)

**Detailed Specifications:**
- [Partition Specifications](references/partition-specs.md) - Complete partition details, SBU weights, allocation units
- [Hardware Specifications](references/hardware-specs.md) - Node types, interconnect, GPU performance metrics

---

## Connection

### SSH Access

**Hostname:** `snellius.surf.nl`

**VPN Required:** Yes - You must connect via SURF VPN before SSH access.

### SSH Config

Add to `~/.ssh/config`:

```ssh
Host snellius
  User <your-username>
  HostName snellius.surf.nl
  CheckHostIP no
  ForwardX11Trusted yes
  ForwardX11 yes
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 4h
```

**Create socket directory:**

```bash
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets
```

### Authentication

SSH keys are required. Your public key must be registered with SURF.

---

## System Overview

Snellius is a heterogeneous supercomputer with:

- **Peak Performance:** 14 petaflop/s
- **Architecture:** AMD EPYC processors
- **Scheduler:** SLURM (Simple Linux Utility for Resource Management)
- **Module System:** Lmod
- **Container Runtime:** Apptainer (Singularity-compatible)

### Key Differences from Other HPC Systems

- **SLURM (not PBS Pro)** - Uses `sbatch`, `squeue`, `scancel` instead of `qsub`, `qstat`, `qdel`
- **AMD processors** - Different optimization flags than Intel systems
- **Lmod modules** - Similar to other systems but check specific module names

---

## Partitions

Compute nodes are grouped into partitions for different hardware types.

### Quick Reference

| Partition | Nodes | Cores/Node | Memory/Node | Features |
|-----------|-------|------------|-------------|----------|
| **thin** | ~200 | 128 | 256 GiB | General CPU workloads |
| **gpu** | ~32 | 64 | 512 GiB | 4x NVIDIA A100 (40GB) |
| **fat** | ~16 | 128 | 2 TiB | High-memory workloads |
| **visual** | ~4 | 64 | 512 GiB | Visualization, VDI |
| **accelerator** | ~2 | varies | varies | Specialized hardware |

### Partition Selection

```bash
# View partition information
sinfo -o "%P %a %l %D %N"

# View nodes in a partition
sinfo -N -p thin
```

**Choosing a partition:**
- **thin** - Most parallel applications, MPI workloads, general computing
- **gpu** - Machine learning, GPU-accelerated simulations, CUDA code
- **fat** - Large datasets, in-memory computing, databases
- **visual** - Interactive visualization, remote desktop
- **accelerator** - Specialized hardware (FPGA, other accelerators)

---

## Storage

### Filesystem Overview

| Path | Type | Quota | Backup | Purpose |
|------|------|-------|--------|---------|
| `/home` | Home | ~200 GiB | Daily | Personal files, scripts |
| `/data` | Project | Per-group | No | Shared project data |
| `/scratch` | Scratch | ~8 TiB | No | Temporary work files |
| `/archive` | Archive | Per-group | No | Long-term cold storage |

### Storage Paths

Your home directory is at: `/home/<username>/`

Project directories are at: `/data/<project-group>/`

### Quota Management

```bash
# Check home quota
quota -s

# Check scratch usage
df -h /scratch
```

### Storage Best Practices

1. **Use `/scratch` for large temporary files** - Work directories, cache files, intermediate results
2. **Store results in `/home` or `/data`** - Only final outputs should go here
3. **Clean up scratch regularly** - Files may be purged after ~30 days of inactivity
4. **Use `/archive` for long-term storage** - Move infrequently accessed data here

### Recommended Layout

```
/home/<username>/
├── scripts/          # Your analysis scripts
├── results/          # Final outputs (small)
└── configs/          # Configuration files

/scratch/<username>/
├── work/             # Pipeline work directories
├── cache/            # Container images, downloads
└── temp/             # Temporary processing files
```

---

## SLURM Basics

### Key Commands

| Task | Command | Description |
|------|---------|-------------|
| Submit job | `sbatch job.sh` | Submit batch script |
| Submit array | `sbatch --array=0-99 job.sh` | Submit job array |
| Interactive | `srun --pty bash` | Interactive shell on compute node |
| Check queue | `squeue -u $USER` | Your jobs in queue |
| All jobs | `squeue` | All jobs in system |
| Cancel job | `scancel <job_id>` | Cancel a job |
| Job details | `scontrol show job <job_id>` | Detailed job info |
| Partition info | `sinfo` | View partition status |
| Node info | `sinfo -N` | View node status |

### Basic Job Script Template

```bash
#!/bin/bash
#SBATCH --job-name=my-job
#SBATCH --partition=thin
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

# Load modules
module purge
module load <your-module>

# Your commands here
echo "Job running on $(hostname)"
```

### Resource Specification

```bash
# Request specific resources
#SBATCH --nodes=2                    # 2 nodes
#SBATCH --ntasks-per-node=128       # 128 tasks per node
#SBATCH --cpus-per-task=1           # 1 CPU per task
#SBATCH --mem=64G                   # 64 GB memory
#SBATCH --time=04:00:00             # 4 hour runtime

# GPU resources
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=4           # 4 GPUs
#SBATCH --gpu-bind=closest          # CPU-GPU binding
```

### Interactive Jobs

```bash
# Get interactive shell on compute node
srun --pty bash

# Interactive with specific resources
srun --pty --partition=thin --cpus-per-task=4 --mem=16G --time=01:00:00 bash

# Interactive GPU session
srun --pty --partition=gpu --gpus-per-node=1 --mem=32G bash
```

---

## Module System: Lmod

### Module Commands

```bash
# List available modules
module avail

# Search for modules
module spider <name>

# Show module details
module show <module-name>

# Load module
module load <module-name>

# Unload module
module unload <module-name>

# Purge all modules
module purge

# List loaded modules
module list

# Save module collection
module save <name>

# Restore module collection
module restore <name>
```

### Module Best Practices

1. **Always `module purge` first** - Avoid conflicts from previous modules
2. **Use `module spider` to find modules** - Shows all versions and dependencies
3. **Save useful module combinations** - Use `module save` for common setups

### Common Modules

Check available modules with `module spider`. Common software includes:
- Compilers: GCC, Intel
- MPI: OpenMPI, IntelMPI
- Libraries: FFTW, HDF5, NetCDF
- Applications: Python, R, MATLAB, various scientific tools

---

## Quick Start Examples

### Example 1: Simple CPU Job

```bash
# Create job script
cat > simple_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=simple-test
#SBATCH --partition=thin
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=00:10:00
#SBATCH --output=%j.out

echo "Starting job at $(date)"
echo "Running on $(hostname)"
sleep 60
echo "Job completed at $(date)"
EOF

# Submit job
sbatch simple_job.sh

# Monitor job
squeue -u $USER
```

### Example 2: GPU Job

```bash
cat > gpu_job.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=gpu-test
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00

module load CUDA
nvidia-smi
EOF

sbatch gpu_job.sh
```

### Example 3: Interactive Development

```bash
# Get interactive session
srun --pty --partition=thin --cpus-per-task=4 --mem=16G --time=02:00:00 bash

# Inside session, load modules
module load Python
python my_script.py
```

---

## Common Gotchas

### SLURM vs PBS Pro

| PBS Pro | SLURM |
|---------|-------|
| `qsub` | `sbatch` |
| `qstat` | `squeue` |
| `qdel` | `scancel` |
| `qsub -I` | `srun --pty bash` |
| `#PBS` | `#SBATCH` |
| `nodes=X:ppn=Y` | `--nodes=X --ntasks-per-node=Y` |

### Module Issues

**Problem:** Commands not found after `ssh snellius 'command'`

**Solution:** Lmod may not be initialized in non-interactive shells. Source it explicitly:

```bash
ssh snellius 'bash -c "source /etc/profile; module purge && module list"'
```

### Storage Issues

**Problem:** Job fails with "No space left on device"

**Solution:**
1. Check quotas: `quota -s`
2. Use `/scratch` for large files: `--export=ALL,SCRATCH=/scratch/$USER`
3. Clean up old files in scratch regularly

### Time Limits

**Problem:** Job killed before completion

**Solution:** Check job status and reason:

```bash
scontrol show job <job_id> | grep -E "State|Time|Reason"
```

Common reasons:
- `TIME_LIMIT` - Request more time with `#SBATCH --time=`
- `NODE_FAIL` - System issue, resubmit
- `OUT_OF_MEMORY` - Request more memory

### GPU Issues

**Problem:** CUDA errors on GPU jobs

**Solution:**
1. Check GPU availability: `sinfo -p gpu`
2. Verify GPU is accessible in job: `nvidia-smi`
3. Check CUDA module compatibility: `module spider cuda`

---

## SSH Command Patterns

### With Modules

```bash
ssh snellius 'bash -c "module purge && module load Python && python --version"'
```

### Pipe Script to Remote

```bash
cat script.sh | ssh snellius 'bash'
```

### File Transfer

```bash
# Uses ControlMaster socket - no re-auth needed
scp local_file.txt snellius:/home/$USER/path/
scp -r snellius:/home/$USER/results/ ./local_results/

# rsync for large transfers
rsync -avz --progress local_dir/ snellius:/home/$USER/remote_dir/
```

### Check Job Status

```bash
ssh snellius 'squeue -u $USER'
```

---

## Workflow Integration

When using workflow tools, load the appropriate specialized skills:

- **Nextflow:** Use `snellius-nextflow` skill
- **Snakemake:** Use `snellius-snakemake` skill
- **Containers:** Use `snellius-containers` skill
- **ML/AI:** Use `snellius-ml` skill
- **Bioinformatics:** Use `snellius-bioinformatics` skill

---

## Documentation Links

- [Snellius Main Page](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660184/Snellius)
- [Getting Started](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30859856/Getting+started)
- [SLURM Batch System](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660221/SLURM+batch+system)
- [Example Job Scripts](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660234/Example+job+scripts)
- [Snellius Partitions](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660209/Snellius+partitions)
- [Snellius Hardware](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660208/Snellius+hardware)
- [Snellius Filesystems](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/85295828/Snellius+filesystems)
- [Storage and Data Management](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30861108/Storage+on+Snellius)

---

## Quick Command Reference

```bash
# Job management
sbatch <script>              # Submit job
squeue -u $USER              # My jobs
scancel <job_id>             # Cancel job
scontrol show job <job_id>   # Job details

# System info
sinfo                        # Partition status
sinfo -N                     # Node status
sinfo -p thin                # Specific partition

# Modules
module avail                 # Available modules
module spider <name>         # Search modules
module load <name>           # Load module
module list                  # Show loaded
module purge                 # Unload all

# Storage
quota -s                     # Check quota
df -h /scratch               # Scratch usage
du -sh <dir>                 # Directory size

# Monitoring
seff <job_id>                # Job efficiency
sacct -j <job_id>            # Job accounting
```
