---
name: snellius-snakemake
description: Use when running Snakemake workflows on Snellius with SLURM cluster configuration, or need Snellius-specific cluster config.
when_to_use: Snakemake cluster execution, SLURM cluster config, container integration, resource directives.
---

# Snellius Snakemake Support

Snakemake workflow execution on Snellius with SLURM cluster configuration and container support.

**Prerequisites:** Load `snellius-core`, `snellius-slurm`, `snellius-storage`, and `snellius-containers` skills.

---

## Installation

### Load Snakemake Module

```bash
module purge
module spider snakemake  # Check available versions
module load Snakemake    # Load latest or specific version
```

### Python Alternative

```bash
# Install in virtual environment
module purge
module load Python
python -m venv snakemake_env
source snakemake_env/bin/activate
pip install snakemake
```

---

## SLURM Cluster Configuration

### Basic Cluster Config

```yaml
# cluster.yaml
__default__:
  account: ""
  partition: thin
  cpus-per-task: 1
  mem-per-cpu: 4000
  time: 01:00:00
```

### Complete Cluster Config

```yaml
# cluster.yaml
__default__:
  account: ""
  partition: thin
  nodes: 1
  ntasks: 1
  cpus-per-task: 4
  mem-per-cpu: 4000
  time: 02:00:00

# High-memory jobs
highmem:
  partition: fat
  cpus-per-task: 8
  mem-per-cpu: 32000
  time: 08:00:00

# GPU jobs
gpu:
  partition: gpu
  gpus-per-node: 1
  cpus-per-task: 8
  mem-per-cpu: 4000
  time: 04:00:00

# Long jobs
long:
  partition: thin
  cpus-per-task: 4
  mem-per-cpu: 4000
  time: 24:00:00
```

### Using Cluster Config

```bash
snakemake --cluster "sbatch --parsable {cluster}" \
          --cluster-config cluster.yaml \
          --jobs 100
```

---

## Workflow Execution

### Basic Run

```bash
module purge
module load Snakemake

# Dry run
snakemake -n

# Run with SLURM
snakemake --cluster "sbatch --parsable" --jobs 50

# With cluster config
snakemake --cluster "sbatch --parsable {cluster}" \
          --cluster-config cluster.yaml \
          --jobs 100
```

### With Container Support

```bash
# Use Singularity
snakemake --use-singularity \
          --singularity-args "--bind /scratch --bind /data" \
          --cluster "sbatch --parsable {cluster}" \
          --cluster-config cluster.yaml \
          --jobs 100

# With custom cache directory
export SINGULARITY_CACHEDIR="/scratch/$USER/singularity_cache"
snakemake --use-singularity \
          --singularity-args "--bind /scratch" \
          --cluster "sbatch --parsable {cluster}" \
          --jobs 50
```

### With Work Directory on Scratch

```bash
# Set work directory
export SNAKEMAKE_DIR="/scratch/$USER/snakemake_work"

# Run with scratch work directory
snakemake --directory $SNAKEMAKE_DIR \
          --cluster "sbatch --parsable {cluster}" \
          --cluster-config cluster.yaml \
          --jobs 100
```

---

## Resource Directives

### Rule with Resources

```python
rule benchmark:
    input:
        "data/input.txt"
    output:
        "results/output.txt"
    resources:
        mem_mb=16000,
        runtime=120,
        partition="thin",
        cpus_per_task=4
    threads: 4
    shell:
        """
        process_command {input} {output}
        """
```

### Resource Mapping in Cluster Config

```yaml
# cluster.yaml with resource mapping
__default__:
  account: ""
  partition: thin
  cpus-per-task: "{resources.cpus_per_task}"
  mem-per-cpu: "{resources.mem_mb_per_cpu}"
  time: "{resources.runtime_hours}:00:00"
```

### Special Partitions

```python
rule gpu_training:
    input:
        "data/train.csv"
    output:
        "model/checkpoint.pt"
    resources:
        partition="gpu",
        gpus=1,
        cpus_per_task=8,
        mem_mb=32000,
        runtime=240
    threads: 8
    shell:
        """
        python train.py --input {input} --output {output}
        """
```

---

## Container Integration

### Singularity in Rules

```python
rule process_bam:
    input:
        bam="alignment/{sample}.bam"
    output:
        "results/{sample}.txt"
    container:
        "docker://biocontainers/samtools:v1.20.0_cv2"
    singularity_args:
        "--bind /scratch --bind /data"
    resources:
        mem_mb=8000,
        cpus_per_task=4
    threads: 4
    shell:
        """
        samtools view -c {input.bam} > {output}
        """
```

### Global Container Settings

```python
# Snakefile
configfile: "config.yaml"

# Enable containers globally
containerized: True
singularity_prefix: "/scratch/$USER/singularity_cache"

# Global bind mounts
singularity_args: "--bind /scratch --bind /data --bind /home"
```

---

## Configuration Patterns

### Config File

```yaml
# config.yaml
samples:
    - sample1
    - sample2
    - sample3

input_dir: /data/project/samples
output_dir: /home/$USER/results
reference: /data/project/reference/genome.fa

# Resources
default_threads: 4
default_mem: 16000
default_time: 120
```

### Using Config in Rules

```python
# Snakefile
configfile: "config.yaml"

rule all:
    input:
        expand("{output}/results/{sample}.txt", output=config["output_dir"], sample=config["samples"])

rule process:
    input:
        "{input_dir}/{sample}.fastq.gz"
    output:
        "{output_dir}/{sample}.txt"
    params:
        reference=config["reference"]
    resources:
        mem_mb=config["default_mem"],
        runtime=config["default_time"],
        cpus_per_task=config["default_threads"]
    threads: config["default_threads"]
    shell:
        """
        process_command --input {input} --output {output} --reference {params.reference}
        """
```

---

## Common Patterns

### Basic Pipeline

```bash
# 1. Load modules
module purge
module load Snakemake

# 2. Create directories
mkdir -p /scratch/$USER/snakemake_work
mkdir -p /home/$USER/results

# 3. Set cache directory
export SINGULARITY_CACHEDIR="/scratch/$USER/singularity_cache"

# 4. Run pipeline
snakemake \
  --directory /scratch/$USER/snakemake_work \
  --cluster "sbatch --parsable {cluster}" \
  --cluster-config cluster.yaml \
  --use-singularity \
  --singularity-args "--bind /scratch --bind /data" \
  --jobs 100 \
  --keep-going
```

### Dry Run and Planning

```bash
# Dry run
snakemake -n

# Plan with resource usage
snakemake --dry-run --print-compilation

# Show DAG
snakemake --dag | dot -Tsvg > dag.svg
```

### Resume After Failure

```bash
# Unlock directory (if previous run failed)
snakemake --unlock

# Resume from last successful step
snakemake --rerun-incomplete
```

### Monitoring

```bash
# In another terminal, monitor jobs
watch -n 5 squeue -u $USER

# Check Snakemake progress
snakemake --print-progress

# List pending rules
snakemake --list
```

---

## Troubleshooting

### Job Submission Fails

**Problem:** Snakemake can't submit SLURM jobs

**Check:**
```bash
# Verify sbatch works
echo "#!/bin/bash\nsleep 10" | sbatch

# Check cluster config syntax
cat cluster.yaml

# Test sbatch command
sbatch --parsable --partition=thin --time=01:00:00 --wrap="sleep 10"
```

### Container Issues

**Problem:** Singularity container fails

**Check:**
```bash
# Verify container exists
singularity pull docker://alpine:latest

# Check bind mounts
singularity exec --bind /scratch alpine.sif ls /scratch

# Check cache directory
ls -la /scratch/$USER/singularity_cache
```

### Work Directory Issues

**Problem:** Jobs can't access work directory

**Check:**
```bash
# Verify directory exists
ls -la /scratch/$USER/snakemake_work

# Check permissions
chmod 755 /scratch/$USER/snakemake_work

# Verify from compute node
srun --pty ls /scratch/$USER/snakemake_work
```

### Unlock After Failure

**Problem:** Directory locked after failed run

**Solution:**
```bash
snakemake --unlock
```

---

## Tips and Best Practices

1. **Use cluster config** - Centralize SLURM settings
2. **Dry run first** - `snakemake -n` to check workflow
3. **Use scratch for work** - Faster, more space
4. **Container cache** - Use `/scratch` for images
5. **Monitor jobs** - `watch -n 5 squeue -u $USER`
6. **Unlock if needed** - `snakemake --unlock` after failures
7. **Keep-going** - Use `--keep-going` for partial success
8. **Resource requests** - Be realistic with resources

---

## Quick Reference

```bash
# Load modules
module purge
module load Snakemake

# Basic run
snakemake --cluster "sbatch --parsable" --jobs 50

# With cluster config
snakemake --cluster "sbatch --parsable {cluster}" \
          --cluster-config cluster.yaml \
          --jobs 100

# With containers
snakemake --use-singularity \
          --singularity-args "--bind /scratch" \
          --cluster "sbatch --parsable {cluster}" \
          --jobs 50

# Dry run
snakemake -n

# Resume
snakemake --rerun-incomplete

# Unlock
snakemake --unlock

# Monitor
watch -n 5 squeue -u $USER
```
