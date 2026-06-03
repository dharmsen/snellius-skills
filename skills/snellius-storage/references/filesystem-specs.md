# Snellius Filesystem Specifications

> Source: [Snellius Filesystems - SURF User Knowledge Base](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/85295828/Snellius+filesystems)

## Overview

Snellius provides several filesystem types with different characteristics. Understanding these is critical for effective workflow design.

**Important Notes:**
- **Only home and archive are backed up** - All other filesystems have NO backup
- **Automatic cleanup policies** are in effect on scratch filesystems
- **No notification prior to deletion** on scratch filesystems

## Filesystem Comparison

| File system | Space Quota | File Quota | Speed | Shared | Mount point | Expiration | Backup |
|-------------|-------------|------------|-------|---------|------------|------------|--------|
| Home | 200 GiB | 1,000,000 | Moderate | Yes | `/home/<username>` | 15 weeks after project expiration | Nightly incremental |
| Scratch-local | 8 TiB* | 3,000,000 (soft) | Fast | No | `/scratch-local/<username>` | Files >6 days removed auto | No |
| Scratch-shared | 8 TiB* | 3,000,000 (soft) | Fast | Yes | `/scratch-shared/<username>` | Files >14 days removed auto | No |
| Scratch-node | none | none | Very fast | No | `/scratch-node/<user-specific>` | Deleted when job ends | No |
| Project | Based on request | Based on size | Fast | Yes | `/projects/<project_name>` | Project duration | No |
| Archive | Based on request | Based on request | Very slow | Yes | `/archive/<username>` | Project duration | Nightly |

*Scratch quota is counted over all scratch-* space combined

## Home Filesystem

### Specifications
- **Default capacity:** 200 GiB
- **Default inode quota:** 1,000,000 files
- **Access:** `/home/<login_name>`
- **Backup:** Nightly incremental (3-week retention)
- **Expiration:** 15 weeks after project expiration

### Usage Guidelines
- **DO use for:** Source code, scripts, configuration files, small results
- **DO NOT use for:** Long-term storage of large datasets, fast/large-scale I/O

### Backup Details
**What gets backed up:**
- Files that exist when backup runs
- Files that are closed (not in use)
- Files with pathnames ≤4095 bytes

**What does NOT get backed up:**
- Files being modified during backup
- Files with very long pathnames (>4095 bytes)

**Restore window:** 3 weeks after deletion

### Home Directory Permissions

**NEVER:**
- Give other logins write permission to your home directory
- Give any permissions to 'other' at the root level

**USE ACLs for:**
- Specific group/user read access
- Specific group/user execute/search access

## Scratch Filesystems

### Scratch-local (`/scratch-local`)

- **Purpose:** Fast temporary storage, unique per node
- **Quota:** 8 TiB (combined with scratch-shared), 3M files (soft limit)
- **Expiration:** Files older than 6 days are automatically deleted
- **Access:** `/scratch-local/<username>`
- **Shared:** NO - each node has unique content

**Special behavior:**
- `$TMPDIR` defaults to `/scratch-local/<username>`
- Symbolically linked to underlying GPFS: `/gpfs/scratch1/nodespecific/<nodename>/<username>`

### Scratch-shared (`/scratch-shared`)

- **Purpose:** Fast temporary storage shared across all nodes
- **Quota:** 8 TiB (combined with scratch-local), 3M files (soft limit)
- **Expiration:** Files older than 14 days are automatically deleted
- **Access:** `/scratch-shared/<username>`
- **Shared:** YES - same content on all nodes

**Usage pattern:**
```bash
# Create unique subdirectory
mktemp -d -p /scratch-shared
```

### Scratch-node (`/scratch-node`) - Node-Local NVMe

- **Available on:** All fcn nodes, subset of tcn (72) and gcn (36) nodes
- **Purpose:** Very fast temporary storage, truly node-local
- **Quota:** None
- **Expiration:** Deleted when job ends
- **Access:** Request with `#SBATCH --constraint=scratch-node`
- **Environment:** `$TMPDIR` points to user-specific directory

**Critical:**
- Data in `/scratch-node` is inaccessible after job completion
- MUST copy data to permanent location before job ends
- No quota limits, but limited by NVMe size (~6-7TB per node)

**Example usage:**
```bash
#!/bin/bash
#SBATCH --constraint=scratch-node

# $TMPDIR will be set to /scratch-node/<user>.<jobid>
echo "Using $TMPDIR"
ls -l $TMPDIR
```

### /tmp, /var/tmp - System Directories

**DO NOT USE:**
- Too small and slow for job outputs
- Needed by operating system
- Emptied without notice at reboot/reinstall
- Filling these causes system-wide problems

**USE INSTEAD:**
- `$TMPDIR` (points to scratch-local or scratch-node)
- `/scratch-local/<username>`
- `/scratch-shared/<username>`

## Project Filesystem

### Specifications
- **Capacity:** Based on request
- **File quota:** Derived from capacity (non-linear formula)
- **Access:** `/projects/<project_name>`
- **Expiration:** Project duration
- **Backup:** NO
- **Shared:** YES (within project group)

### File Quota Formula

```
Y = 1,000,000 + 100,000 × sqrt(X) × ln(X)
```

Where:
- X = capacity in TiB
- Y = maximum number of files

### Reference Values

| Capacity (TiB) | Number of files | Avg. file size (MiB) |
|----------------|-----------------|-----------------------|
| 1 | 1,000,000 | 1.05 |
| 5 | 1,359,881 | 3.86 |
| 10 | 1,728,141 | 6.07 |
| 50 | 3,766,218 | 13.92 |
| 100 | 5,605,170 | 18.71 |
| 200 | 8,492,952 | 24.50 |
| 300 | 10,879,241 | 28.91 |

### Important Notes

- **Per-group quota:** Quota applies to group, not individual users
- **Group ownership:** Files must have correct group ownership
- **No backup:** User-managed backup required
- **Not for long-term storage:** Use archive instead

### Expiration Policy
- Files remain until project expires
- 4-week grace period after expiration
- Project spaces can be retained for follow-up projects with demonstrated need

## Archive Filesystem

### Specifications
- **Purpose:** Long-term storage of large amounts of data
- **Access:** `/archive/<username>`
- **Performance:** Very slow (tape-based)
- **Backup:** Nightly

### Usage Guidelines

**DO:**
- Compress many small files into single tar archive first
- Store large files efficiently

**DON'T:**
- Store many small files uncompressed (scattered across tapes)

## Quota Management

### Checking Quotas

```bash
# Home directory quota
myquota

# Scratch usage
myquota -s

# Project quota (if applicable)
lfs quota -u $USER /projects/<project>
```

### Quota Tools

Location: `/gpfs/admin/hpc/usertools`

Available commands include `myquota` and similar tools.

### Scratch Quota Details

- **Soft limit:** 3,000,000 files
- **Grace period:** 7 days after hitting soft limit
- **Hard limit:** Substantially higher than soft limit
- **Behavior:** New files blocked if hard limit reached

## Data Lifecycle Strategy

### Recommended Workflow

```
1. Input Data → /projects/<project>/ (shared, stable)
2. Work Directory → /scratch-local/$USER/ (fast, temporary)
3. Output Results → /home/$USER/results/ (backed up, permanent)
4. Large/Infrequent → /archive/$USER/ (cold storage)
```

### Example Job Script Pattern

```bash
#!/bin/bash
#SBATCH --job-name=data-processing
#SBATCH --partition=thin
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00

# Set up directories
WORKDIR="/scratch-local/$USER/work/job_${SLURM_JOB_ID}"
OUTDIR="/home/$USER/results/${SLURM_JOB_ID}"
DATADIR="/projects/<project>/input"

# Create work directory
mkdir -p $WORKDIR
mkdir -p $OUTDIR

# Copy input to scratch (fast)
cp $DATADIR/input.dat $WORKDIR/

# Process data in scratch
cd $WORKDIR
python process.py --input input.dat --output output.dat

# Copy results back (only what's needed)
cp output.dat $OUTDIR/
cp processing.log $OUTDIR/

# Clean up work directory
rm -rf $WORKDIR

echo "Results saved to $OUTDIR"
```

## Storage Best Practices

### DO
1. Use scratch for work files - Faster, more space
2. Keep only results in home - Scripts, configs, final outputs
3. Clean up regularly - Remove old scratch files
4. Archive old data - Move to `/archive` for long-term storage
5. Check quotas - Monitor usage before starting large jobs
6. Use $TMPDIR - Points to appropriate scratch location

### DON'T
1. Store large datasets in home - Limited space, affects login
2. Leave work files in scratch - May be purged automatically
3. Ignore quota warnings - Jobs may fail if quota exceeded
4. Store critical data only in scratch - Not backed up, auto-purged
5. Use /tmp or /var/tmp - Too small, needed by system
6. Grant write permissions to home directory - Security risk
