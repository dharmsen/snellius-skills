---
name: snellius-slurm
description: Use when submitting SLURM jobs on Snellius, monitoring job status, debugging job failures, or optimizing resource requests.
when_to_use: Submitting jobs, checking queue, job arrays, job dependencies, resource optimization, debugging failed jobs.
---

# Snellius SLURM Job Management

Detailed SLURM functionality for Snellius job submission, monitoring, and optimization.

**Prerequisite:** Load `snellius-core` for basic SLURM commands and connection info.

**Sources:**
- [SLURM Batch System](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660221/SLURM+batch+system)
- [Example Job Scripts](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660234/Example+job+scripts)

---

## Job Script Templates

### Thin Partition (Standard CPU)

```bash
#!/bin/bash
#SBATCH --job-name=analysis
#SBATCH --partition=thin
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --mem=240G
#SBATCH --time=04:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

# Load modules
module purge
module load GCC
module load OpenMPI
module load YourApp

# Set OMP threads
export OMP_NUM_THREADS=1

# Run MPI application
mpirun -np 128 ./my_app
```

### GPU Partition

```bash
#!/bin/bash
#SBATCH --job-name=gpu-train
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --gpus-per-node=4
#SBATCH --gpu-bind=closest
#SBATCH --time=08:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

module purge
module load CUDA
module load Python

# Set GPU variables
export CUDA_VISIBLE_DEVICES=0,1,2,3

# Run GPU application
python train_model.py
```

### Fat Partition (High Memory)

```bash
#!/bin/bash
#SBATCH --job-name=bigdata
#SBATCH --partition=fat
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=1800G
#SBATCH --time=12:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

module purge
module load Python
module load R

# High-memory processing
Rscript big_data_analysis.R
```

### Job Array

```bash
#!/bin/bash
#SBATCH --job-name=array-job
#SBATCH --partition=thin
#SBATCH --array=0-99%10    # 100 jobs, max 10 concurrent
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=array_%A_%a.out
#SBATCH --error=array_%A_%a.err

module purge
module load Python

# Use array task ID
python process.py --input file_$SLURM_ARRAY_TASK_ID.dat
```

### Multi-Node Job

```bash
#!/bin/bash
#SBATCH --job-name=multi-node
#SBATCH --partition=thin
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1800M
#SBATCH --time=08:00:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

module purge
module load GCC
module load OpenMPI

# Calculate total tasks
TOTAL_TASKS=$((SLURM_JOB_NUM_NODES * SLURM_TASKS_PER_NODE))

# Run across all nodes
mpirun -np $TOTAL_TASKS ./distributed_app
```

---

## Resource Specification Patterns

### CPU Allocation

```bash
# Single core
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

# Multi-threaded (OpenMP)
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
export OMP_NUM_THREADS=16

# MPI tasks
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1800M

# Hybrid MPI+OpenMP
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=4500M
export OMP_NUM_THREADS=32
```

### Memory Allocation

```bash
# Simple memory request
#SBATCH --mem=64G                    # Total memory

# Per-CPU memory
#SBATCH --mem-per-cpu=2000M         # 2GB per CPU

# Per-GPU memory (GPU partition)
#SBATCH --mem=120G                   # For 4 GPU node
```

### Time Allocation

```bash
# Format: DD-HH:MM:SS
#SBATCH --time=01:00:00             # 1 hour
#SBATCH --time=08:00:00             # 8 hours
#SBATCH --time=1-12:00:00           # 1 day 12 hours
#SBATCH --time=7-00:00:00           # 7 days (max on many partitions)
```

### GPU Allocation

```bash
# Single GPU
#SBATCH --gpus-per-node=1

# Multiple GPUs
#SBATCH --gpus-per-node=4

# Specific GPU type
#SBATCH --constraint=gpu-a100

# GPU binding
#SBATCH --gpu-bind=closest          # Bind to closest CPUs
#SBATCH --gpu-bind=single:1         # Single thread per GPU
```

---

## Job Submission

### Basic Submission

```bash
# Submit script
sbatch job.sh

# Submit with command line overrides
sbatch --partition=gpu --time=02:00:00 job.sh

# Submit with environment variables
sbatch --export=INPUT_FILE=data.txt,OUTPUT_DIR=/scratch/$USER job.sh
```

### Advanced Submission

```bash
# Submit with dependency
sbatch --dependency=afterany:12345 job.sh  # Run after job 12345

# Submit array job
sbatch --array=0-999 job.sh

# Submit with hold (release later)
sbatch --hold job.sh
srelease <job_id>                     # Release held job

# Submit with priority
sbatch --priority=1000 job.sh

# Submit to specific queue
sbatch --qos=premium job.sh
```

---

## Job Monitoring

### Status Commands

```bash
# Your jobs
squeue -u $USER

# Detailed view
squeue -u $USER -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"

# All jobs in partition
squeue -p thin

# Job efficiency (after completion)
seff <job_id>

# Job accounting details
sacct -j <job_id> --format=JobID,JobName,State,ExitCode,Elapsed,AllocCPUS,AllocGRES,AllocTRES%50
```

### Real-Time Monitoring

```bash
# Watch your jobs
watch -n 5 squeue -u $USER

# Check node status
sinfo -N -l

# Check specific job details
scontrol show job <job_id>

# Show job environment
scontrol show job <job_id> | grep -E "WorkDir|StdOut|StdErr"
```

### Output Files

```bash
# Watch output in real-time
tail -f <job_id>.out

# Check for errors
grep -i error <job_id>.err

# View job completion time
grep "slurm" *.out | grep "completed"
```

---

## Job Control

### Cancel Jobs

```bash
# Cancel specific job
scancel <job_id>

# Cancel all your jobs
scancel -u $USER

# Cancel job array
scancel <array_job_id>

# Cancel specific array task
scancel <array_job_id>_5
```

### Modify Pending Jobs

```bash
# Modify time (only if job hasn't started)
scontrol update job=<job_id> TimeLimit=4:00:00

# Modify partition
scontrol update job=<job_id> Partition=gpu

# Modify memory (may not work if job started)
scontrol update job=<job_id> Mem=64G
```

### Signal Running Jobs

```bash
# Send SIGUSR1
scancel -s SIGUSR1 <job_id>

# Send SIGTERM (graceful shutdown)
scancel -s SIGTERM <job_id>
```

---

## Common Exit Codes

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Job completed |
| 1 | General error | Check stderr |
| 125-127 | Job script errors | Fix script |
| 137 | SIGKILL (OOM) | Increase memory |
| 139 | SIGSEGV | Check code |
| 143 | SIGTERM | Normal cancel |

### Common Job States

| State | Meaning |
|-------|---------|
| `PD` | Pending |
| `R` | Running |
| `CG` | Completing |
| `CD` | Completed |
| `F` | Failed |
| `TO` | Timeout |
| `OOM` | Out of memory |

---

## Debugging Failed Jobs

### Check Job Details

```bash
# Full job information
sacct -j <job_id> --format=ALL

# Job logs
cat <job_id>.out
cat <job_id>.err

# Job environment variables
scontrol show job <job_id> | grep -i environment
```

### Common Issues

#### Out of Memory

**Symptoms:** Exit code 137, job killed with no obvious error

**Solution:** Increase memory request

```bash
#SBATCH --mem=128G  # Increase from 64G
```

#### Timeout

**Symptoms:** State `TO`, job killed at time limit

**Solution:** Increase time request

```bash
#SBATCH --time=12:00:00  # Increase from 8 hours
```

#### Module Not Found

**Symptoms:** Command not found errors

**Solution:** Check module availability

```bash
# Search for module
module spider <module-name>

# Show exact name
module spider <module-name> | grep -A5 "Versions:"

# Load with exact name
module load <exact-module-name>
```

#### GPU Not Accessible

**Symptoms:** CUDA errors, nvidia-smi fails

**Solution:** Check GPU allocation and binding

```bash
# Verify GPU request
#SBATCH --gpus-per-node=1

# Check GPU is available in job
nvidia-smi

# Check CUDA module
module spider cuda
```

---

## Job Optimization

### Requesting Resources

**Best Practices:**

1. **Be realistic** - Request what you need, not more
2. **Test small** - Start with small jobs, scale up
3. **Monitor efficiency** - Use `seff` to check resource usage

**Example:**

```bash
# Initial test
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00

# After test, scale based on seff output
# seff showed: CPU efficiency 85%, Memory used 12GB, Time used 45min
#SBATCH --cpus-per-task=8        # Scale up 2x
#SBATCH --mem=32G                # Scale up 2x
#SBATCH --time=02:00:00          # Scale up 2x
```

### Partition Selection

```bash
# Check queue times
sinfo -s

# Check node availability
sinfo -N -p thin

# Choose partition with shorter queue if flexible
#SBATCH --partition=fat           # May have shorter queue than thin
```

### Job Arrays for Parallel Work

**Instead of** one long job:
```bash
#SBATCH --time=100:00:00
#SBATCH --cpus-per-task=1
for i in {1..1000}; do
    process file_$i.dat
done
```

**Use job array:**
```bash
#SBATCH --array=0-999%20
#SBATCH --time=01:00:00
process file_$SLURM_ARRAY_TASK_ID.dat
```

Benefits:
- Better scheduling
- Can restart failed tasks individually
- More efficient resource usage

---

## Advanced Features

### Job Dependencies

```bash
# Submit multiple dependent jobs
JOB1=$(sbatch --parsable job1.sh)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 job2.sh)
JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 job3.sh)

# Multiple dependencies
sbatch --dependency=afterok:12345,12346:afterany:12347 job.sh

# Singleton (only one job of this name running)
sbatch --dependency=singleton job.sh
```

### Resource Sharing

```bash
# Oversubscribe CPUs
#SBATCH --cpus-per-task=4
#SBATCH --threads-per-core=2

# Share node (if partition allows)
#SBATCH --oversubscribe
```

### Exclusive Node Access

```bash
# Request exclusive node
#SBATCH --exclusive

# Request specific node (if available)
#SBATCH --nodelist=cn1234
```

---

## Quick Reference

```bash
# Submission
sbatch <script>                           # Submit job
sbatch --array=0-99 <script>             # Submit array
sbatch --dependency=afterok:123 <script> # With dependency

# Monitoring
squeue -u $USER                           # My jobs
scontrol show job <id>                    # Job details
seff <job_id>                            # Job efficiency
sacct -j <id> --format=ALL               # Full accounting

# Control
scancel <job_id>                         # Cancel job
scancel -u $USER                          # Cancel all my jobs
scontrol update job=<id> TimeLimit=4:00:00  # Update job

# Templates
#SBATCH --partition=thin                 # Partition
#SBATCH --nodes=1                        # Nodes
#SBATCH --cpus-per-task=4                # CPUs per task
#SBATCH --mem=32G                        # Memory
#SBATCH --time=04:00:00                  # Time limit
#SBATCH --output=%j.out                  # Output file
#SBATCH --error=%j.err                   # Error file
#SBATCH --array=0-99                     # Job array
#SBATCH --dependency=afterok:12345        # Dependency
#SBATCH --gpus-per-node=1                # GPU count
```
