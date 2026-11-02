# Kepler OS Architecture and x86-64-v3 Specification

## 1. x86-64-v3 Microarchitecture Baseline
Kepler OS targets the `x86-64-v3` architecture level.
CPUs must support the following instructions:
- AVX and AVX2 (Advanced Vector Extensions)
- BMI1 and BMI2 (Bit Manipulation Instructions)
- FMA (Fused Multiply-Add)
- MOVBE and LZCNT

All packages in Voyager-PPA and glibc-hwcaps libraries compile with `-march=x86-64-v3 -O3`.
This increases performance for linear algebra and bioinformatics pipelines by up to 25%.

## 2. Immutable OSTree Core Architecture
The filesystem layout enforces system reliability through immutability:
- `/usr` is mounted strictly read-only using `ostree-prepare-root`.
- `/etc` is stateful and merges configuration files across updates using a 3-way merge.
- `/var` contains user data, containers, and Flatpaks on dedicated Btrfs subvolumes (`@var`, `@var_home`, `@snapshots`).
- Rollbacks happen instantly from the bootloader without file-by-file rewrites.

## 3. CachyOS BORE Kernel & Schedulers
The kernel runs at 1000Hz tickrate with Full Preemption (`CONFIG_PREEMPT=y`).
The BORE (Burst-Oriented Response Enhancer) scheduler optimizes interactive desktop tasks while sustaining high-throughput background compute.
Optional `sched-ext` user-space BPF schedulers (`scx_lavd`, `scx_bpfland`) can be selected via `kepler-tuner`.
