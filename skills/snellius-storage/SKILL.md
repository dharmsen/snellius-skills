---
name: snellius-storage
description: Storage and file management for Snellius - filesystems, quotas, data lifecycle, transfer strategies
dependencies: [snellius-core]
---

# Snellius Storage Management

Storage and data lifecycle management for Snellius filesystems.

**Prerequisite:** Load `snellius-core` for basic storage overview.

**Sources:**
- [Snellius Filesystems](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/85295828/Snellius+filesystems)
- [Storage on Snellius](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30861108/Storage+on+Snellius)

**Detailed Specifications:**
- [Filesystem Specifications](references/filesystem-specs.md) - Complete filesystem details, quotas, expiration policies, backup information

---

## Filesystem Overview

| Path | Type | Quota | Backup | Performance | Use Case |
|------|------|-------|--------|-------------|----------|
| `/home/<user>` | Home | ~200 GiB | Daily | Medium | Scripts, configs, small results |
| `/data/<project>` | Project | Per-group | No | High | Shared project data |
| `/scratch/<user>` | Scratch | ~8 TiB | No | Very High | Temporary work files |
| `/archive/<project>` | Archive | Per-group | No | Low | Long-term cold storage |

### Accessing Your Storage

```bash
# Your home directory
cd /home/$USER

# Your scratch directory
cd /scratch/$USER

# Project directories (check group membership)
groups
ls /data/

# Archive access
ls /archive/
```

---

## Quota Management

### Checking Quotas

```bash
# Home directory quota
quota -s

# Detailed home quota
quota -v

# Scratch usage
df -h /scratch
df -h /scratch/$USER

# Project quota (if applicable)
lfs quota -u $USER /data/<project>
```

### Quota Output Interpretation

```
Disk quotas for user user123 (uid 12345):
     Filesystem  blocks   quota   limit   grace   files   quota   limit   grace
     /home/home  50G     200G    220G             50k     3M      3.3M
```

- `blocks`: Current usage (50 GB)
- `quota`: Soft limit (200 GB)
- `limit`: Hard limit (220 GB)
- `grace`: Time remaining if over soft limit

### Exceeding Quota

**Soft limit exceeded:** Warning email, grace period begins
**Hard limit exceeded:** Writes blocked, jobs may fail

**Actions:**
1. Check usage: `du -sh /home/$USER/* | sort -hr | head -20`
2. Clean up: Remove old files
3. Archive: Move to `/archive` if applicable
4. Use scratch: Move large files to `/scratch`

---

## Data Lifecycle Strategy

### Recommended Workflow

```
1. Input Data → /data/<project>/ (shared, stable)
2. Work Directory → /scratch/$USER/work/ (fast, temporary)
3. Output Results → /home/$USER/results/ (backed up, permanent)
4. Large/Infrequent → /archive/<project>/ (cold storage)
```

### Job Script Pattern

```bash
#!/bin/bash
#SBATCH --job-name=data-processing
#SBATCH --partition=thin
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00

# Set up directories
WORKDIR="/scratch/$USER/work/job_${SLURM_JOB_ID}"
OUTDIR="/home/$USER/results/${SLURM_JOB_ID}"
DATADIR="/data/<project>/input"

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

---

## File Transfer Strategies

### From Local Machine

```bash
# Single file
scp local_file.txt snellius:/home/$USER/

# Directory
scp -r local_dir/ snellius:/home/$USER/

# Large files (use rsync)
rsync -avz --progress large_file.dat snellius:/scratch/$USER/
```

### Between Snellius Systems

```bash
# Within Snellius
cp /data/<project>/file.dat /scratch/$USER/

# With progress indicator
rsync -av --progress /data/<project>/large.dat /scratch/$USER/
```

### Bulk Transfers

```bash
# Transfer directory with exclude patterns
rsync -avz \
  --exclude='*.tmp' \
  --exclude='work/' \
  --progress \
  /data/<project>/dataset/ \
  /scratch/$USER/dataset/
```

### Archive Transfers

```bash
# To archive
rsync -av /data/<project>/old_data/ /archive/<project>/old_data/

# From archive
rsync -av /archive/<project>/old_data/ /data/<project>/old_data/
```

---

## Storage Optimization

### Cleanup Strategies

```bash
# Find large files
find /home/$USER -type f -size +1G -ls

# Find old files
find /scratch/$USER -type f -mtime +30 -ls

# Clean old work directories
find /scratch/$USER/work -type d -mtime +7 -exec rm -rf {} +

# Remove temporary files
find /scratch/$USER -name "*.tmp" -delete
find /scratch/$USER -name "*.cache" -delete
```

### Compression

```bash
# Compress large text files
gzip large_file.txt

# Compress directory
tar -czf archive.tar.gz directory/

# Compress with progress
tar -czf - directory/ | pigz > archive.tar.gz
```

### Deduplication

```bash
# Find duplicate files
fdupes /scratch/$USER/data

# Interactive deletion
fdupes -d /scratch/$USER/data/
```

---

## Monitoring Storage Usage

### Quick Checks

```bash
# Disk usage by directory
du -sh /home/$USER/* | sort -hr | head -20

# Total usage
df -h /home
df -h /scratch
df -h /data

# Inode usage (file count)
df -i /home
```

### Monitoring Scripts

```bash
# Daily storage report
cat > storage_report.sh << 'EOF'
#!/bin/bash
echo "=== Storage Report ==="
echo "Home usage:"
du -sh /home/$USER
echo "Top 10 directories:"
du -sh /home/$USER/* | sort -hr | head -10
echo "Scratch usage:"
du -sh /scratch/$USER 2>/dev/null || echo "N/A"
EOF
```

---

## Best Practices

### DO

1. **Use scratch for work files** - Faster, more space
2. **Keep only results in home** - Scripts, configs, final outputs
3. **Clean up regularly** - Remove old scratch files
4. **Archive old data** - Move to `/archive` for long-term storage
5. **Check quotas** - Monitor usage before starting large jobs
6. **Use rsync for transfers** - Resumable, progress indication

### DON'T

1. **Store large datasets in home** - Limited space, affects login
2. **Leave work files in scratch** - May be purged after 30 days
3. **Ignore quota warnings** - Jobs may fail if quota exceeded
4. **Store critical data only in scratch** - Not backed up, may be purged
5. **Use home for high I/O operations** - Poor performance, affects others

---

## Job Script Storage Patterns

### Pattern 1: Scratch Work, Home Results

```bash
#!/bin/bash
#SBATCH --job-name=scratch-work
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00

WORK="/scratch/$USER/work/${SLURM_JOB_ID}"
OUT="/home/$USER/results/${SLURM_JOB_ID}"
DATA="/data/<project>/input"

mkdir -p $WORK $OUT

# Copy input to scratch
cp $DATA/* $WORK/

# Process in scratch
cd $WORK && python process.py

# Copy results back
cp results/* $OUT/

# Cleanup
rm -rf $WORK
```

### Pattern 2: Project Shared Data

```bash
#!/bin/bash
#SBATCH --job-name=shared-data
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=04:00:00

SHARED_IN="/data/<project>/shared_input"
SHARED_OUT="/data/<project>/shared_output"
WORK="/scratch/$USER/work/${SLURM_JOB_ID}"

mkdir -p $WORK

# Read from shared, write to scratch
cp $SHARED_IN/input.dat $WORK/
cd $WORK && python analyze.py

# Copy results to shared
cp output.dat $SHARED_OUT/

# Cleanup
rm -rf $WORK
```

### Pattern 3: Pipeline with Stages

```bash
#!/bin/bash
#SBATCH --job-name=pipeline
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00

WORK="/scratch/$USER/work/${SLURM_JOB_ID}"
FINAL="/home/$USER/results/${SLURM_JOB_ID}"

mkdir -p $WORK/stage1 $WORK/stage2 $WORK/stage3 $FINAL

# Stage 1: Data prep
cd $WORK/stage1
python prep.py --input /data/input.dat --output prep.dat

# Stage 2: Processing
cd $WORK/stage2
python process.py --input ../stage1/prep.dat --output processed.dat

# Stage 3: Analysis
cd $WORK/stage3
python analyze.py --input ../stage2/processed.dat --output results.csv

# Copy final results only
cp stage3/results.csv $FINAL/

# Cleanup entire work directory
rm -rf $WORK
```

---

## Common Issues

### Out of Space

**Symptoms:** "No space left on device", job failures

**Check:**
```bash
quota -s
df -h /scratch
```

**Fix:**
```bash
# Clean up old files
find /scratch/$USER -mtime +30 -delete
find /home/$USER -name "*.tmp" -delete
```

### Over Quota

**Symptoms:** "Disk quota exceeded", cannot write

**Check:**
```bash
quota -v
```

**Fix:**
```bash
# Find large files
du -sh /home/$USER/* | sort -hr | head -10

# Remove or move large files
mv /home/$USER/large_file.dat /scratch/$USER/
```

### Slow I/O

**Symptoms:** Jobs slow, filesystem errors

**Fix:**
```bash
# Move I/O to scratch
# Don't read/write many small files from home
# Use scratch for high I/O operations
```

---

## Quick Reference

```bash
# Check quotas
quota -s                    # Simple view
quota -v                    # Detailed view
df -h /scratch              # Scratch usage

# Directory sizes
du -sh <dir>                # Directory size
du -sh * | sort -hr         # Sort by size

# Transfers
scp file snellius:/path/    # Local to Snellius
rsync -avz src/ dst/        # Sync directories

# Cleanup
find /scratch/$USER -mtime +30 -delete    # Delete old files
rm -rf /scratch/$USER/work/*              # Clean work directory

# Compression
gzip file                   # Compress file
tar -czf archive.tar.gz dir/              # Archive directory
```
