# Snellius Partition Specifications

> Source: [Snellius Partitions - SURF User Knowledge Base](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660209/Snellius+partitions)

## Quick Reference Table

| Partition name | Type | Nodes | CPU Cores/node | GPUs/node | Available GiB RAM/node | Smallest allocation | SBU weight |
|----------------|------|-------|----------------|-----------|------------------------|---------------------|------------|
| rome | CPU | 521 | 128 | - | 224 | 1/8 node: 16 cores + 28 GiB RAM | 1.0 |
| genoa | CPU | 737 | 192 | - | 336 | 1/8 node: 24 cores + 42 GiB RAM | 1.0 |
| fat_rome | CPU (FAT) | 72 | 128 | - | 960 | 1/8 node: 16 cores + 120 GiB RAM | 1.5 |
| fat_genoa | CPU (FAT) | 48 | 192 | - | 1440 | 1/8 node: 24 cores + 180 GiB RAM | 1.5 |
| himem_4tb | CPU (HIMEM) | 2 | 128 | - | 3840 | 1/8 node: 16 cores + 480 GiB RAM | 2.0 |
| himem_8tb | CPU (HIMEM) | 2 | 128 | - | 7680 | 1/8 node: 16 cores + 960 GiB RAM | 3.0 |
| gpu_a100 | GPU | 63 | 72 | 4× A100 (40GB) | 480 | 1/4 node: 18 cores + 1 GPU + 120 GiB RAM | 128 |
| gpu_h100 | GPU | 88 | 64 | 4× H100 (94GB) | 720 | 1/4 node: 16 cores + 1 GPU + 180 GiB RAM | 192 |
| gpu_mig | GPU (MIG) | 4 | 72 | 8× MIG | 480 | 1/8 node: 9 cores + 1 GPU (MIG) + 60 GiB RAM | 64 |
| gpu_vis | GPU (visualization) | 63 | 72 | 4× A100 | 480 | 1/4 node: 18 cores + 1 GPU + 120 GiB RAM | 128 |
| staging | service (SMT) | 10 | 16* | - | 224 | 1 thread + 7 GiB RAM | 2.0 |
| cbuild | service (SMT) | 10 | 16* | - | 224 | 1 thread + 7 GiB RAM | 2.0 |

## Partition Details

### CPU Partitions

#### rome (AMD Rome CPU)
- **Node count:** 521
- **Processor:** AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz 280W
- **Memory:** 256 GiB DRAM total, 224 GiB available to users
- **Network:** HDR100 InfiniBand
- **Best for:** General CPU workloads, parallel applications, MPI

#### genoa (AMD Genoa CPU)
- **Node count:** 737
- **Processor:** AMD Genoa 9654 (2x), 96 Cores/Socket 2.4GHz 360W
- **Memory:** 384 GiB DRAM total, 336 GiB available to users
- **Network:** NDR ConnectX-7 (200Gbps within rack, 100Gbps outside rack)
- **Best for:** General CPU workloads, higher core density than Rome

#### fat_rome (High Memory - Rome)
- **Node count:** 72
- **Processor:** AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz
- **Memory:** 1 TiB DRAM total, 960 GiB available to users
- **Local storage:** 6.4TB NVMe SSD Intel P5600 (scratch-node)
- **Best for:** Memory-intensive applications, large datasets

#### fat_genoa (High Memory - Genoa)
- **Node count:** 48
- **Processor:** AMD Genoa 9654 (2x), 96 Cores/Socket 2.4GHz
- **Memory:** 1.5 TiB DRAM total, 1440 GiB available to users
- **Local storage:** 6.4TB NVMe SSD (scratch-node)
- **Best for:** Memory-intensive applications with high CPU requirements

#### himem_4tb (Very High Memory)
- **Node count:** 2
- **Processor:** AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz
- **Memory:** 4 TiB DRAM total, 3840 GiB available to users
- **Best for:** Extremely memory-intensive workloads

#### himem_8tb (Very High Memory)
- **Node count:** 2
- **Processor:** AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz
- **Memory:** 8 TiB DRAM total, 7680 GiB available to users
- **Best for:** Largest in-memory datasets

### GPU Partitions

#### gpu_a100 (NVIDIA A100)
- **Node count:** 63
- **Processor:** Intel Xeon Platinum 8360Y (2x), 36 Cores/Socket 2.4 GHz
- **GPUs:** 4× NVIDIA A100 (40 GiB HBM2 per GPU)
- **Memory:** 512 GiB DRAM + 160 GiB HBM2
- **Network:** 2× HDR200 ConnectX-6
- **Local storage:** 7.68TB NVMe (on 36 nodes with scratch-node)
- **Best for:** Machine learning, GPU computing, CUDA workloads

#### gpu_h100 (NVIDIA H100)
- **Node count:** 88
- **Processor:** AMD EPYC 9334 (2x), 32 Cores/Socket 2.7 GHz
- **GPUs:** 4× NVIDIA H100 SXM5 (94 GiB HBM2e per GPU)
- **Memory:** 768 GiB DRAM + 376 GiB HBM2e
- **Network:** 4× NDR200 ConnectX-7
- **Local storage:** NVMe SSD (on 22 nodes with scratch-node)
- **Best for:** Large-scale ML/AI, HPC GPU workloads

#### gpu_mig (Multi-Instance GPU)
- **Node count:** 4
- **GPUs:** 8× NVIDIA A100 MIG instances per node
- **Best for:** Multiple smaller GPU workloads on shared node

#### gpu_vis (Visualization)
- **Node count:** 63
- **GPUs:** 4× NVIDIA A100 (40 GiB)
- **Best for:** Interactive visualization, remote desktop

### Service Partitions

#### staging
- **Node count:** 10
- **Type:** SMT (32 threads)
- **Best for:** Data staging, pre/post-processing

#### cbuild
- **Node count:** 10
- **Type:** SMT (32 threads)
- **Best for:** Compilation, build tasks

## Walltime Limits

- **Standard partitions:** 120 hours (5 days)
- **gpu_vis partition:** 24 hours

## Short Jobs (1 hour walltime)

Jobs with ≤1 hour walltime on thin, fat, or gpu partitions are scheduled on dedicated short-job nodes, reducing wait times. Useful for testing before production runs.

**Note:** Short-job nodes are limited in number - submitting many-node short jobs may fail.

## Node Names

Node names can be determined with the `sinfo` command:

```bash
sinfo -N -p <partition>
```

## SBU (System Billing Unit) Weights

SBU weights determine the cost of jobs in terms of allocation:

- **Standard CPU (rome/genoa):** 1.0 SBU/CPU hour
- **FAT nodes:** 1.5 SBU/CPU hour
- **High-memory (4TB):** 2.0 SBU/CPU hour
- **High-memory (8TB):** 3.0 SBU/CPU hour
- **GPU A100:** 128 SBU/GPU hour
- **GPU H100:** 192 SBU/GPU hour
- **GPU MIG:** 64 SBU/GPU hour
- **Service nodes:** 2.0 SBU/CPU hour

## Hardware Sources

Hardware information from [Snellius Hardware Documentation](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660208/Snellius+hardware).
