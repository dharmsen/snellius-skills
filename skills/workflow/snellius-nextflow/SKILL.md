---
name: snellius-nextflow
description: Use when running Nextflow workflows on Snellius with SLURM executor, or need Snellius-specific Nextflow configuration.
when_to_use: Running Nextflow pipelines, nf-core workflows, SLURM integration, container configuration, workDir setup.
---

# Snellius Nextflow Support

Nextflow workflow execution on Snellius with SLURM executor and container support.

**Prerequisites:** Load `snellius-core`, `snellius-slurm`, `snellius-storage`, and `snellius-containers` skills.

---

## Installation and Modules

### Load Nextflow Module

```bash
module purge
module spider nextflow  # Check available versions
module load Nextflow   # Load latest or specific version
```

### Java Requirement

Nextflow requires Java. Check available:

```bash
module spider Java
module load Java/17    # Nextflow typically needs Java 11+
```

---

## Nextflow Configuration

### Basic Snellius Config

```groovy
// nextflow.config
profiles {
    snellius {
        process {
            executor = 'slurm'
            queue = 'thin'
        }
    }
}
```

### Complete Snellius Config

```groovy
// nextflow.config
profiles {
    snellius {
        // Process configuration
        process {
            executor = 'slurm'

            // Resource requests
            cpus = 4
            memory = '16 GB'
            time = '2 h'

            // Error handling - retry on transient errors
            errorStrategy = 'retry'
            maxRetries = 2

            // Cluster options
            clusterOptions = '--account=<your-account>'

            // Queue for job
            queue = 'thin'
        }

        // Singularity configuration
        singularity {
            enabled = true
            autoMounts = true
            cacheDir = '/scratch/${System.getenv("USER")}/singularity_cache'
            runOptions = '--bind /scratch,/data,/home'
        }

        // Disable Docker
        docker {
            enabled = false
        }

        // Work directory - use scratch
        workDir = '/scratch/${System.getenv("USER")}/nf-work'

        // Output directory
        params {
            outdir = '/home/${System.getenv("USER")}/results'
        }
    }

    // GPU profile
    snellius_gpu {
        includeConfig 'snellius'
        process {
            queue = 'gpu'
            clusterOptions = '--partition=gpu'
        }
    }
}
```

---

## Running Pipelines

### Basic nf-core Run

```bash
module purge
module load Java/17 Nextflow

# Pull nf-core pipeline
nextflow pull nf-core/rnaseq

# Run with Snellius profile
nextflow run nf-core/rnaseq \
    -profile singularity \
    -c nextflow.config \
    -profile snellius \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir /home/$USER/results/rnaseq \
    -resume
```

### Custom Pipeline

```bash
# Run custom pipeline
nextflow run main.nf \
    -profile snellius \
    -c nextflow.config \
    --input /data/project/samples/*.fastq.gz \
    --outdir /home/$USER/results \
    -resume
```

### GPU Pipeline

```bash
# Run with GPU profile
nextflow run training_pipeline.nf \
    -profile snellius_gpu \
    --epochs 100 \
    --batch_size 32 \
    -resume
```

---

## Process Configuration

### Different Process Types

```groovy
process {
    // Default resources
    cpus = 4
    memory = '16 GB'
    time = '2 h'

    // High-memory process
    withName: BIG_MEMORY {
        memory = '128 GB'
        queue = 'fat'
        time = '8 h'
    }

    // GPU process
    withName: GPU_TASK {
        queue = 'gpu'
        cpus = 8
        memory = '32 GB'
        clusterOptions = '--gpus-per-node=1'
        time = '4 h'
    }

    // Long-running process
    withName: LONG_TASK {
        time = '24 h'
        memory = '32 GB'
    }
}
```

### Container Configuration

```groovy
process {
    // Container for all processes
    container = 'docker://biocontainers/fastqc:v0.11.9'

    // Process-specific containers
    withName: ALIGNMENT {
        container = 'docker://biocontainers/star:v2.7.10a'
    }

    withName: QUANTIFICATION {
        container = 'docker://biocontainers/salmon:v1.9.0'
    }
}

singularity {
    enabled = true
    cacheDir = '/scratch/${System.getenv("USER")}/singularity_cache'
}
```

---

## Directives and Resources

### Process with Directives

```groovy
process HIGH_MEMORY_TASK {
    tag "${sample_id}"
    cpus 16
    memory '128 GB'
    time '8 h'

    queue 'fat'
    clusterOptions '--account=your-account'

    input:
    tuple val(sample_id), path(file)

    output:
    path "${sample_id}.result"

    """
    process_command --input ${file} --output ${sample_id}.result
    """
}
```

### Dynamic Resources

```groovy
process DYNAMIC_RESOURCES {
    cpus = { 4 * task.attempt }
    memory = { 16.GB * task.attempt }
    time = { 2.h * task.attempt }

    errorStrategy = 'retry'
    maxRetries = 3
}
```

---

## Work Directory Management

### Work Directory on Scratch

```groovy
workDir = '/scratch/${System.getenv("USER")}/nf-work'
```

### Cleanup

```bash
# Clean work directory (after successful run)
rm -rf /scratch/$USER/nf-work

# Clean specific pipeline work
rm -rf /scratch/$USER/nf-work/<pipeline_id>
```

### Work Directory Monitoring

```bash
# Check work directory size
du -sh /scratch/$USER/nf-work

# Find large work directories
du -sh /scratch/$USER/nf-work/* | sort -hr | head -10
```

---

## Common Patterns

### nf-core Pattern

```bash
# 1. Install required modules
module purge
module load Java/17 Nextflow

# 2. Create singularity cache directory
mkdir -p /scratch/$USER/singularity_cache

# 3. Run nf-core pipeline
nextflow run nf-core/<pipeline> \
    -profile singularity \
    -c /path/to/nextflow.config \
    -profile snellius \
    --input samplesheet.csv \
    --outdir /home/$USER/results \
    -resume

# 4. Monitor jobs
watch -n 5 squeue -u $USER
```

### Custom Pipeline Pattern

```groovy
// nextflow.config
profiles {
    snellius {
        process.executor = 'slurm'
        workDir = '/scratch/$USER/nf-work'
        singularity.enabled = true
        singularity.cacheDir = '/scratch/$USER/singularity_cache'
    }
}
```

### Multi-profile Pattern

```bash
# Test locally first
nextflow run main.nf -profile test

# Run on Snellius
nextflow run main.nf -profile snellius -c nextflow.config -resume
```

---

## Troubleshooting

### Job Submission Fails

**Problem:** Nextflow can't submit SLURM jobs

**Check:**
```bash
# Verify sbatch works
sbatch --test-only

# Check Nextflow can access sbatch
which sbatch

# Verify config
nextflow config -profile snellius
```

### Container Pull Fails

**Problem:** Can't pull Singularity images

**Check:**
```bash
# Verify cache directory exists
ls -la /scratch/$USER/singularity_cache

# Check available space
df -h /scratch

# Test manual pull
singularity pull docker://alpine:latest
```

### Work Directory Issues

**Problem:** Jobs fail with work directory errors

**Check:**
```bash
# Verify work directory
ls -la /scratch/$USER/nf-work

# Check permissions
chmod 755 /scratch/$USER/nf-work

# Verify mount points
singularity exec --bind /scratch ubuntu.sif ls /scratch
```

### Out of Memory

**Problem:** Jobs killed with OOM

**Solution:** Increase memory request

```groovy
process {
    memory = '32 GB'  // Increase
    memory = { 64.GB * task.attempt }  // Or dynamic
}
```

---

## Tips and Best Practices

1. **Use `-resume`** - Allows resuming from failures
2. **Monitor queue** - `watch -n 5 squeue -u $USER`
3. **Clean work** - Remove work directories after successful runs
4. **Use scratch** - Set workDir to `/scratch`
5. **Container cache** - Use `/scratch` for singularity cache
6. **Resource requests** - Start small, increase as needed
7. **Test locally** - Use `-profile test` before full run

---

## Quick Reference

```bash
# Load modules
module purge
module load Java/17 Nextflow

# Run pipeline
nextflow run main.nf -profile snellius -c nextflow.config -resume

# nf-core pipeline
nextflow run nf-core/<pipeline> -profile singularity -profile snellius -resume

# Monitor
watch -n 5 squeue -u $USER
nextflow log

# Clean up
rm -rf /scratch/$USER/nf-work

# Config check
nextflow config -profile snellius
```
