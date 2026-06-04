---
name: snellius-bioinformatics
description: Use when running bioinformatics workflows on Snellius, processing sequencing data, or using nf-core pipelines.
when_to_use: RNA-seq, DNA-seq, ChIP-seq, variant calling, bioinformatics tools, nf-core pipelines, containerized tools.
---

# Snellius Bioinformatics Workflows

Bioinformatics workflows and tools on Snellius for sequencing data analysis.

**Prerequisites:** Load `snellius-core`, `snellius-slurm`, `snellius-storage`, `snellius-containers`, and `snellius-nextflow` skills.

---

## Common Tools

### Available Bioinformatics Tools

Check available modules:

```bash
module spider bioinf
module avail | grep -i bio
module spider samtools
module spider bcftools
module spider bedtools
```

### Common Tools via Modules

```bash
# Sequence manipulation
module load SAMtools       # BAM/CRAM processing
module load BCFtools       # VCF processing
module load BEDTools       # Interval operations

# Alignment
module load BWA           # Short-read alignment
module load Bowtie2       # Short-read alignment
module load STAR          # RNA-seq alignment
module load Minimap2      # Long-read alignment

# Variant calling
module load GATK          # Variant calling
module load FreeBayes     # Variant calling
module load DeepVariant   # Deep learning variant calling

# Quantification
module load featureCounts # Gene quantification
module load HTSeq         # Gene quantification
module load Salmon        # Transcript quantification
module load Kallisto      # Transcript quantification
```

### Container-based Tools

```bash
# Pull biocontainers
singularity pull docker://biocontainers/samtools:v1.20.0_cv2
singularity pull docker://biocontainers/bcftools:v1.20.0_cv2
singularity pull docker://biocontainers/bwa:v0.7.17_cv1

# Run with container
singularity exec samtools.sif samtools view input.bam
```

---

## Workflow Tools

### nf-core Pipelines

#### Install Nextflow

```bash
module purge
module load Java/17 Nextflow
```

#### Run nf-core Pipeline

```bash
# RNA-seq example
nextflow run nf-core/rnaseq \
    -profile singularity \
    -c nextflow.config \
    -profile snellius \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir /home/$USER/results/rnaseq \
    -resume

# ChIP-seq example
nextflow run nf-core/chipseq \
    -profile singularity \
    -c nextflow.config \
    -profile snellius \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir /home/$USER/results/chipseq \
    -resume

# Sarek (variant calling)
nextflow run nf-core/sarek \
    -profile singularity \
    -c nextflow.config \
    -profile snellius \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir /home/$USER/results/sarek \
    -resume
```

### Nextflow Config for Bioinformatics

```groovy
// nextflow.config
profiles {
    snellius {
        process {
            executor = 'slurm'
            queue = 'thin'

            // Resource requests for bioinformatics
            cpus = 8
            memory = '32 GB'
            time = '4 h'

            // Memory-intensive tasks
            withName: ALIGNMENT {
                memory = '64 GB'
                cpus = 16
                time = '8 h'
            }

            withName: VARIANT_CALLING {
                memory = '64 GB'
                cpus = 8
                time = '12 h'
            }

            errorStrategy = 'retry'
            maxRetries = 2
        }

        singularity {
            enabled = true
            cacheDir = '/scratch/${System.getenv("USER")}/singularity_cache'
            runOptions = '--bind /scratch --bind /data'
        }

        workDir = '/scratch/${System.getenv("USER")}/nf-work'
    }
}
```

---

## Common Workflows

### RNA-seq Workflow

#### Using STAR + featureCounts

```bash
#!/bin/bash
#SBATCH --job-name=rnaseq
#SBATCH --partition=thin
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --array=1-20

module purge
module load STAR featureCounts SAMtools

# Set directories
SAMPLE=$(sed "${SLURM_ARRAY_TASK_ID}p" samples.txt)
DATA_DIR="/data/project/rnaseq"
OUT_DIR="/scratch/$USER/rnaseq/${SLURM_ARRAY_TASK_ID}"
FINAL_DIR="/home/$USER/results/rnaseq"

mkdir -p $OUT_DIR $FINAL_DIR

# Align reads
STAR \
    --runThreadN 16 \
    --genomeDir /data/reference/GRCh38_STAR \
    --readFilesIn ${DATA_DIR}/${SAMPLE}_R1.fastq.gz ${DATA_DIR}/${SAMPLE}_R2.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix ${OUT_DIR}/ \
    --outSAMtype BAM SortedByCoordinate

# Count reads
featureCounts \
    -T 16 \
    -p \
    -a /data/reference/GRCh38.gtf \
    -o ${OUT_DIR}/counts.txt \
    ${OUT_DIR}/Aligned.sortedByCoord.out.bam

# Copy results
cp ${OUT_DIR}/counts.txt $FINAL_DIR/${SAMPLE}_counts.txt
```

#### Using Salmon (alignment-free)

```bash
#!/bin/bash
#SBATCH --job-name=salmon
#SBATCH --partition=thin
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --array=1-20

module purge
module load Salmon

SAMPLE=$(sed "${SLURM_ARRAY_TASK_ID}p" samples.txt)

salmon quant \
    -i /data/reference/salmon_index \
    -l A \
    -1 /data/project/rnaseq/${SAMPLE}_R1.fastq.gz \
    -2 /data/project/rnaseq/${SAMPLE}_R2.fastq.gz \
    -p 8 \
    --validateMappings \
    -o /scratch/$USER/salmon/${SLURM_ARRAY_TASK_ID}

# Copy results
cp -r /scratch/$USER/salmon/${SLURM_ARRAY_TASK_ID} /home/$USER/results/
```

### DNA-seq Variant Calling

#### BWA + GATK Workflow

```bash
#!/bin/bash
#SBATCH --job-name=variant-call
#SBATCH --partition=thin
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00

module purge
module load BWA SAMtools GATK

SAMPLE=sample1
DATA_DIR="/data/project/dnaseq"
OUT_DIR="/scratch/$USER/gatk/${SAMPLE}"

mkdir -p $OUT_DIR

# Align reads
bwa mem -t 16 \
    /data/reference/GRCh38.fa \
    ${DATA_DIR}/${SAMPLE}_R1.fastq.gz \
    ${DATA_DIR}/${SAMPLE}_R2.fastq.gz | \
    samtools sort -@ 16 -o ${OUT_DIR}/aligned.bam

# Mark duplicates
gatk MarkDuplicates \
    -I ${OUT_DIR}/aligned.bam \
    -O ${OUT_DIR}/dedup.bam \
    -M ${OUT_DIR}/metrics.txt

# Call variants
gatk HaplotypeCaller \
    -R /data/reference/GRCh38.fa \
    -I ${OUT_DIR}/dedup.bam \
    -O ${OUT_DIR}/variants.vcf

# Copy results
cp ${OUT_DIR}/variants.vcf /home/$USER/results/
```

### ChIP-seq Workflow

```bash
#!/bin/bash
#SBATCH --job-name=chipseq
#SBATCH --partition=thin
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --array=1-10

module purge
module load BWA SAMtools MACS2

SAMPLE=$(sed "${SLURM_ARRAY_TASK_ID}p" samples.txt)
OUT_DIR="/scratch/$USER/chipseq/${SLURM_ARRAY_TASK_ID}"

mkdir -p $OUT_DIR

# Align
bwa mem -t 8 /data/reference/GRCh38.fa \
    /data/project/chipseq/${SAMPLE}_R1.fastq.gz \
    /data/project/chipseq/${SAMPLE}_R2.fastq.gz | \
    samtools sort -@ 8 -o ${OUT_DIR}/aligned.bam

# Call peaks
macs2 callpeak \
    -t ${OUT_DIR}/aligned.bam \
    -c /data/project/chipseq/control.bam \
    -f BAM \
    -g hs \
    -n ${SAMPLE} \
    --outdir $OUT_DIR

# Copy results
cp ${OUT_DIR}*.narrowPeak /home/$USER/results/
```

---

## Reference Data Management

### Reference Genomes

```bash
# Common reference locations
/data/reference/
├── GRCh38/
│   ├── GRCh38.fa
│   ├── GRCh38.fa.fai
│   ├── GRCh38.dict
│   └── GRCh38.gtf
├── GRCh37/
│   └── ...
└── mm10/
    └── ...
```

### Building Indices

```bash
# STAR index
STAR --runThreadN 16 \
    --runMode genomeGenerate \
    --genomeDir /data/reference/GRCh38_STAR \
    --genomeFastaFiles /data/reference/GRCh38.fa \
    --sjdbGTFfile /data/reference/GRCh38.gtf \
    --sjdbOverhang 100

# BWA index
bwa index /data/reference/GRCh38.fa

# Salmon index
salmon index -t /data/reference/transcripts.fa \
    -i /data/reference/salmon_index \
    -p 16
```

---

## Data Organization

### Input Data Structure

```
/data/project/
├── samplesheet.csv          # Sample metadata
├── raw_data/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   └── ...
└── reference/
    └── GRCh38/
```

### Output Structure

```
/home/$USER/results/
├── rnaseq/
│   ├── sample1_counts.txt
│   └── sample2_counts.txt
├── variant_calling/
│   └── sample1.vcf
└── chipseq/
    └── peaks/
```

---

## Tips and Best Practices

1. **Use job arrays** - Process multiple samples in parallel
2. **Use scratch for work** - Faster I/O, more space
3. **Copy only results** - Keep final outputs in home
4. **Use nf-core pipelines** - Community-maintained, reproducible
5. **Containerize tools** - Use Singularity for reproducibility
6. **Monitor quota** - Bioinformatics data is large
7. **Compress intermediate files** - Save space

---

## Quick Reference

```bash
# Load common tools
module load SAMtools BCFtools BEDtools STAR Salmon

# nf-core pipeline
nextflow run nf-core/rnaseq -profile singularity -profile snellius -resume

# Quick alignment
bwa mem ref.fa R1.fastq.gz R2.fastq.gz | samtools sort -o aligned.bam

# Quick quantification
featureCounts -a genes.gtf -o counts.txt aligned.bam

# Container tool
singularity exec samtools.sif samtools view input.bam
```
