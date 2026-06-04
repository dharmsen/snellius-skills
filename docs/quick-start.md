# Quick Start Guide

Get up and running with Snellius skills in Claude Code in under 5 minutes.

## Installation

Clone the repository and add the skills:

```bash
# Clone the repository
git clone https://github.com/[user]/snellius-skills.git
cd snellius-skills

# Add all skills to Claude Code
npx skills add ./snellius-skills/

# Or add specific skills
npx skills add ./snellius-skills/skills/core/snellius-core/
npx skills add ./snellius-skills/skills/core/snellius-slurm/
```

## What You're Getting

These skills help Claude Code interact with the Snellius supercomputer efficiently. They cover job submission, file management, workflow orchestration, and domain-specific tasks.

| Skill | Purpose |
|-------|---------|
| `snellius-core` | System overview, partitions, storage, SLURM basics, modules |
| `snellius-slurm` | Job submission, monitoring, debugging, templates |
| `snellius-storage` | File management, quotas, data lifecycle |
| `snellius-containers` | Apptainer/Singularity container management |
| `snellius-nextflow` | Nextflow workflows with SLURM executor |
| `snellius-snakemake` | Snakemake workflows with SLURM cluster |
| `snellius-ml` | ML/AI workflows on GPU partitions |
| `snellius-bioinformatics` | Bioinformatics workflows, nf-core pipelines |

## Example Workflows

### Example 1: Submit Your First SLURM Job

```
You: Help me submit a simple job that runs hostname on Snellius

Claude: I'll help you submit a basic SLURM job. Let me create a simple job script for the thin partition.

[Creates job.sh]
---
#!/bin/bash
#SBATCH --job-name=hostname-test
#SBATCH --partition=thin
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:05:00
#SBATCH --output=%j.out
#SBATCH --error=%j.err

hostname
---

Now submitting your job...
$ sbatch job.sh
Submitted batch job 12345

Your job is queued. Check its status with:
$ squeue -u $USER

View output when complete:
$ cat slurm-12345.out
```

### Example 2: Start an Interactive GPU Session

```
You: Start an interactive GPU session for me

Claude: I'll start an interactive session on a GPU node using the gpu partition.

$ salloc --partition=gpu --gpus=1 --cpus-per-task=16 --mem=120G --time=02:00:00

You're now on a GPU node (e.g., gcn123). You can run commands directly:

$ python train_model.py
$ nvidia-smi  # Check GPU status

Exit when done:
$ exit
```

### Example 3: Run a Nextflow Workflow

```
You: Set up this Nextflow workflow to run on Snellius

Claude: I'll configure Nextflow to use SLURM and containers for Snellius.

[Creates nextflow.config]
---
process {
  executor = 'slurm'
  queue = 'thin'
  cpus = 16
  memory = '64 GB'
  time = '4h'

  module = ['/path/to/nextflow']
}

docker {
  enabled = true
  runOptions = '--nv'  # For GPU support
}
---

$ nextflow run main.nf -profile slurm

Workflow submitted! Monitor execution:
$ nextflow log
$ tail -f .nextflow.log
```

### Example 4: Use a Container

```
You: Pull and run a Docker container for my analysis

Claude: I'll help you use Apptainer (Singularity) to pull and run the container.

$ apptainer pull docker://ubuntu:latest
$ apptainer pull docker://python:3.11-slim

Container ready. Run your analysis:
$ apptainer run ubuntu_latest.sif python script.py

Or with GPU support:
$ apptainer run --nv python_3.11.sif python train.py
```

### Example 5: Check Storage Quotas

```
You: Check my storage quota on Snellius

Claude: I'll check your current storage usage and quotas across filesystems.

[Checks quotas]
$ myquota
---
Filesystem    Used    Quot   Limit   Grace   Files   Quot   Limit   Grace
/home        45G     200G    220G              15K     50K      60K
/scratch     200G   8000G   8000G            150K    500K     600K
---

You're using 45GB of 200GB on /home, and 200GB of 8TB on /scratch.

Recommendations:
- Move large datasets to /scratch for better performance
- Archive old results to /archive to free up space
- /scratch is NOT backed up - copy important results to /home or /data
```

## Next Steps

- **Detailed skill documentation:** See `skills/*/SKILL.md` for comprehensive guides
- **Snellius documentation:** [SURF Knowledge Base](https://servicedesk.surf.nl/wiki/)
- **SLURM reference:** [Official SLURM documentation](https://slurm.schedmd.com/docs.html)

## Common Tasks

| Task | Command |
|------|---------|
| Check job status | `squeue -u $USER` |
| Cancel job | `scancel <job_id>` |
| Node information | `sinfo` |
| Available modules | `module avail` |
| Load module | `module load <name>` |

## Troubleshooting

Jobs failing immediately? Check the error file:
```bash
$ cat slurm-<jobid>.err
```

Jobs stuck in queue? Check why:
```bash
$ squeue -u $USER -o "%.18i %.9P %.8j %.8u %.2t %.10M %.6D %R"
```

Need help? Claude Code with Snellius skills can debug SLURM issues, optimize resource requests, and guide you through common workflows.
