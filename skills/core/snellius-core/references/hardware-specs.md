# Snellius Hardware Specifications

> Source: [Snellius Hardware - SURF User Knowledge Base](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/30660208/Snellius+hardware)

## System Overview

Snellius is a general-purpose capability supercomputer designed to be well-balanced for tasks requiring:
- Many cores
- Large symmetric multi-processing nodes
- High memory
- Fast interconnect
- Large disk workspace
- Fast I/O subsystem

### Key Specifications
- **Peak Performance:** ~14 petaflop/s
- **Architecture:** AMD EPYC processors (with Intel Xeon for GPU nodes)
- **Interconnect:** InfiniBand HDR100/NDR
- **Scheduler:** SLURM
- **Container Runtime:** Apptainer (Singularity-compatible)

## Node Types

Snellius uses different node "flavors" for different purposes:

| Flavor | Description |
|--------|-------------|
| `(int)` | CPU-only interactive nodes |
| `(tcn)` | CPU-only "thin" compute nodes |
| `(fcn)` | CPU-only "fat" compute nodes with more memory and NVMe scratch |
| `(hcn)` | CPU-only "high-memory" compute nodes |
| `(gcn)` | GPU-enhanced compute nodes with NVIDIA GPUs |
| `(srv)` | CPU-only service nodes for data transfers |

## Detailed Node Specifications

### Interactive Nodes (int)

| Spec | Value |
|------|-------|
| Count | 3 |
| Lenovo Node Type | ThinkSystem SR665 |
| CPU | AMD EPYC 7F32 (2x), 8 Cores/Socket 3.7GHz 180W |
| CPU Cores per Node | 16 |
| Memory | 256 GiB DRAM (16 GiB per core) |
| Local Storage | 6.4TB NVMe SSD Intel P5600 (not user accessible) |
| Network | 1× HDR100, 100GbE ConnectX-6 VPI Dual port, 2× 25GbE SFP28 |

### Thin Compute Nodes - Rome (tcn)

| Spec | Value |
|------|-------|
| Count | 525 |
| Lenovo Node Type | ThinkSystem SR645 |
| CPU | AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz 280W |
| CPU Cores per Node | 128 |
| Memory | 256 GiB DRAM (2 GiB per core) |
| Local Storage | 21 nodes with 6.4TB NVMe SSD Intel P5600 |
| Network | 1× HDR100 ConnectX-6 single port, 2× 25GbE SFP28 OCP |

### Thin Compute Nodes - Genoa (tcn)

| Spec | Value |
|------|-------|
| Count | 738 |
| Lenovo Node Type | ThinkSystem SD665v3 |
| CPU | AMD Genoa 9654 (2x), 96 Cores/Socket 2.4GHz 360W |
| CPU Cores per Node | 192 |
| Memory | 384 GiB DRAM (2 GiB per core) |
| Local Storage | 72 nodes with 6.4TB NVMe SSD |
| Network | 1× NDR ConnectX-7 single port (200Gbps within rack, 100Gbps outside) |

### Fat Compute Nodes - Rome (fcn)

| Spec | Value |
|------|-------|
| Count | 72 |
| Lenovo Node Type | ThinkSystem SR645 |
| CPU | AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz 280W |
| CPU Cores per Node | 128 |
| Memory | 1 TiB DRAM (8 GiB per core) |
| Local Storage | 6.4TB NVMe SSD Intel P5600 |
| Network | 1× HDR100 ConnectX-6 single port, 2× 25GbE SFP28 OCP |

### Fat Compute Nodes - Genoa (fcn)

| Spec | Value |
|------|-------|
| Count | 48 |
| Lenovo Node Type | ThinkSystem SD665v3 |
| CPU | AMD Genoa 9654 (2x), 96 Cores/Socket 2.4GHz 360W |
| CPU Cores per Node | 192 |
| Memory | 1.5 TiB DRAM (8 GiB per core) |
| Local Storage | 6.4TB NVMe SSD Intel P5600 |
| Network | 1× NDR ConnectX-7 single port |

### High-Memory Nodes - 4TiB (hcn)

| Spec | Value |
|------|-------|
| Count | 2 |
| Lenovo Node Type | ThinkSystem SR665 |
| CPU | AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz 280W |
| CPU Cores per Node | 128 |
| Memory | 4 TiB DRAM (32 GiB per core) |
| Network | 1× HDR100 ConnectX-6 single port, 2× 25GbE SFP28 OCP |

### High-Memory Nodes - 8TiB (hcn)

| Spec | Value |
|------|-------|
| Count | 2 |
| Lenovo Node Type | ThinkSystem SR665 |
| CPU | AMD Rome 7H12 (2x), 64 Cores/Socket 2.6GHz 280W |
| CPU Cores per Node | 128 |
| Memory | 8 TiB DRAM (64 GiB per core) |
| Network | 1× HDR100 ConnectX-6 single port, 2× 25GbE SFP28 OCP |

### GPU Nodes - A100 (gcn)

| Spec | Value |
|------|-------|
| Count | 72 |
| Lenovo Node Type | ThinkSystem SD650-N v2 |
| CPU | Intel Xeon Platinum 8360Y (2x), 36 Cores/Socket 2.4 GHz 250W |
| CPU Cores per Node | 72 |
| GPUs | 4× NVIDIA A100, 40 GiB HBM2 memory per GPU |
| Memory | 512 GiB DRAM + 160 GiB HBM2 |
| Local Storage | 36 nodes with 7.68TB NVMe SSD ThinkSystem PM983 |
| Network | 2× HDR200 ConnectX-6 single port, 2× 25GbE SFP28 LOM |

### GPU Nodes - H100 (gcn)

| Spec | Value |
|------|-------|
| Count | 88 |
| Lenovo Node Type | ThinkSystem SD665-N V3 |
| CPU | AMD EPYC 9334 (2x), 32 Cores/Socket 2.7 GHz 210W |
| CPU Cores per Node | 64 |
| GPUs | 4× NVIDIA H100 SXM5, 94 GiB HBM2e memory per GPU |
| Memory | 768 GiB DRAM + 376 GiB HBM2e |
| Local Storage | 22 nodes with NVMe SSD |
| Network | 4× NDR200 ConnectX-7, 2× 25GbE SFP28 LOM |

### Service Nodes (srv)

| Spec | Value |
|------|-------|
| Count | 7 |
| Lenovo Node Type | ThinkSystem SR665 |
| CPU | AMD EPYC 7F32 (2x), 8 Cores/Socket 3.7GHz 180W |
| CPU Cores per Node | 16 |
| Memory | 256 GiB DRAM (16 GiB per core) |
| Local Storage | 6.4TB NVMe SSD Intel P5600 |
| Network | 1× HDR100, 100GbE ConnectX-6 VPI Dual port |

## Interconnect

All compute nodes use InfiniBand interconnect in fat-tree topology:

- **Phase 1:** HDR100 (100Gbps)
- **Phase 2/3:** NDR (200Gbps within rack, 100Gbps outside rack)

A single fabric connects all phases with sufficient bandwidth between trees.

## Observed GPU Performance

### NVIDIA A100

| Metric | Value |
|--------|-------|
| Tensor FP16 FLOPS | 250 TFLOPS |
| DRAM Bandwidth | 1.3 TiB/s |
| PCIe Tx | 14.7 GiB/s |
| PCIe Rx | 14.5 GiB/s |
| NvLink Tx/Rx | 93.4/93.5 GiB/s |
| NvLink Bus BW (NCCL) | 213 GiB/s |
| IB Bus BW (NCCL) | 15.6 GiB/s |

### NVIDIA H100

| Metric | Value |
|--------|-------|
| Tensor FP16 FLOPS | 660 TFLOPS |
| DRAM Bandwidth | 2.1 TiB/s |
| PCIe Tx | 58.4 GiB/s |
| PCIe Rx | 59.5 GiB/s |
| NvLink Tx/Rx | 132 GiB/s |
| NvLink Bus BW (NCCL) | 355 GiB/s |
| IB Bus BW (NCCL) | 97.4 GiB/s |

## Expansion Phases

Snellius was built in three consecutive expansion phases:

### Phase 1 (Q3 2021)
- Initial deployment with Rome CPU nodes and A100 GPU nodes

### Phase 2 (Q3 2023)
- Added Genoa CPU nodes with higher core count

### Phase 3 (Q2 2024)
- Added H100 GPU nodes with latest NVIDIA architecture

All phases remain operational until end-of-life of the system.
