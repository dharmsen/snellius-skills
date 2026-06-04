# Snellius HPC Skills

A comprehensive collection of modular Claude Code skills for the [Snellius Dutch national supercomputer](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660184/Snellius) hosted at SURF.

These skills help you interact with Snellius efficiently, covering job submission, file management, workflow orchestration, and domain-specific tasks.

## Skills Overview

### Core Skills (Essential)

| Skill | Description |
|-------|-------------|
| `snellius-core` | Core reference skill with system overview, partitions, storage, SLURM basics, modules |
| `snellius-slurm` | Detailed SLURM job management, job templates, monitoring, debugging |
| `snellius-storage` | Storage and file management, quotas, data lifecycle strategies |
| `snellius-containers` | Apptainer/Singularity container management and execution |

### Workflow Skills

| Skill | Description |
|-------|-------------|
| `snellius-nextflow` | Nextflow workflow support with SLURM executor and container integration |
| `snellius-snakemake` | Snakemake workflow support with SLURM cluster configuration |

### Domain-Specific Skills (Optional)

| Skill | Description |
|-------|-------------|
| `snellius-ml` | ML/AI workflows on GPU partitions (PyTorch, TensorFlow, JAX) |
| `snellius-bioinformatics` | Bioinformatics workflows, nf-core pipelines, sequencing data |

## Installation

**New to Snellius?** Start with the [Quick Start Guide](docs/quick-start.md) for examples.

### Using Claude Code

Add skills to your Claude Code installation:

```bash
# Add all skills
npx skills add ./snellius-skills/

# Or add specific skills
npx skills add ./snellius-skills/skills/core/snellius-core/
npx skills add ./snellius-skills/skills/core/snellius-slurm/
npx skills add ./snellius-skills/skills/workflow/snellius-nextflow/
npx skills add ./snellius-skills/skills/domain-specific/snellius-ml/
```

### Using Symbolic Links (Development)

For development or frequent updates:

```bash
# Link core skills to your Claude skills directory
ln -s ~/snellius-skills/skills/core/snellius-core ~/.claude/skills/
ln -s ~/snellius-skills/skills/core/snellius-slurm ~/.claude/skills/
ln -s ~/snellius-skills/skills/core/snellius-storage ~/.claude/skills/
ln -s ~/snellius-skills/skills/core/snellius-containers ~/.claude/skills/

# Link workflow skills
ln -s ~/snellius-skills/skills/workflow/snellius-nextflow ~/.claude/skills/
ln -s ~/snellius-skills/skills/workflow/snellius-snakemake ~/.claude/skills/

# Link domain-specific skills
ln -s ~/snellius-skills/skills/domain-specific/snellius-ml ~/.claude/skills/
ln -s ~/snellius-skills/skills/domain-specific/snellius-bioinformatics ~/.claude/skills/
```

## Quick Start

**For detailed examples with Claude Code conversations, see the [Quick Start Guide](docs/quick-start.md).**

### 1. Connection Setup

Configure SSH for Snellius access in `~/.ssh/config`:

```ssh
Host snellius
  User <your-username>
  HostName snellius.surf.nl
  ForwardX11 yes
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 4h
```

**Note:** VPN connection is required for SSH access.

### 2. Basic Job Submission

Load the core skill and submit a simple job:

```
User: Help me submit a basic CPU job to Snellius
```

The agent will use the `snellius-core` and `snellius-slurm` skills to guide you through:
- Selecting the appropriate partition
- Writing a SLURM job script
- Submitting with `sbatch`
- Monitoring with `squeue`

### 3. Workflow Execution

For workflow tools, load the appropriate skill:

```
User: Set up a Nextflow pipeline on Snellius with Singularity containers
```

The agent will use `snellius-core`, `snellius-nextflow`, and `snellius-containers` skills.

## Skill Structure

Skills are organized by category and each skill follows the [science-skills](https://github.com/google-deepmind/science-skills) pattern:

```
skills/
├── core/                 # Essential HPC operations
│   ├── snellius-core/
│   ├── snellius-slurm/
│   ├── snellius-storage/
│   └── snellius-containers/
├── workflow/             # Workflow orchestration tools
│   ├── snellius-nextflow/
│   └── snellius-snakemake/
└── domain-specific/      # Domain-specific optimizations
    ├── snellius-ml/
    └── snellius-bioinformatics/

Each skill contains:
├── SKILL.md              # Main instruction file with YAML frontmatter
├── scripts/              # Helper shell scripts
└── references/           # Additional documentation and templates
```

## Key Features

- **Modular Design:** Use only the skills you need
- **Composable:** Combine multiple skills for complex workflows
- **Snellius-Specific:** Tailored for Snellius's SLURM scheduler, partitions, and storage
- **Workflow-Ready:** Pre-configured patterns for Nextflow, Snakemake, and common tools
- **Domain Skills:** Optional specialized skills for ML/AI and bioinformatics

## Snellius Quick Reference

### Partitions

| Partition | Description | Use Case |
|-----------|-------------|----------|
| `thin` | Standard CPU nodes | General HPC workloads |
| `gpu` | GPU nodes (NVIDIA A100) | Machine learning, GPU computing |
| `fat` | High-memory nodes | Memory-intensive applications |
| `visual` | Visualization nodes | Interactive visualization |
| `accelerator` | Specialized accelerators | Domain-specific acceleration |

### Storage

| Path | Type | Quota | Purpose |
|------|------|-------|---------|
| `/home` | Home | ~200 GiB | Permanent files, backed up daily |
| `/data` | Data | Per-group | Project data, shared |
| `/scratch` | Scratch | ~8 TiB | Temporary work files, NOT backed up |
| `/archive` | Archive | Per-group | Long-term cold storage |

### SLURM Basics

```bash
# Submit job
sbatch job.sh

# Check queue
squeue -u $USER

# Cancel job
scancel <job_id>

# Node info
sinfo
```

## Documentation

- [Snellius Main Documentation](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660184/Snellius)
- [SLURM Batch System](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660221/SLURM+batch+system)
- [Example Job Scripts](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660234/Example+job+scripts)
- [Snellius Partitions](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660209/Snellius+partitions)
- [Snellius Filesystems](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/85295828/Snellius+filesystems)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is provided as-is for use with Snellius HPC. Individual skills may reference specific documentation licenses from SURF.

## Acknowledgments

- Based on patterns from [claude-imperial-hpc-skill](https://github.com/NathanSkene/claude-imperial-hpc-skill)
- Structure inspired by [google-deepmind/science-skills](https://github.com/google-deepmind/science-skills)
- Documentation from [SURF User Knowledge Base](https://servicedesk.surf.nl/wiki/)
