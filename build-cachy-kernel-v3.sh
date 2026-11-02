#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

echo "=== [Kepler OS] Compiling CachyOS-BORE-v3 Kernel for OSTree ==="

KERNEL_VER="${1:-6.12.8}"
BUILD_DIR="${2:-/workspace/build_cachy_kernel}"
OUT_DIR="${3:-/workspace/build_out}"

mkdir -p "$BUILD_DIR" "$OUT_DIR"
cd "$BUILD_DIR"

if [ ! -d "linux-cachyos" ]; then
    echo "Cloning CachyOS Linux kernel source..."
    git clone --depth 1 --branch "v${KERNEL_VER}-cachyos" https://github.com/CachyOS/linux-cachyos.git linux-cachyos || \
    git clone --depth 1 https://github.com/CachyOS/linux-cachyos.git linux-cachyos
fi

cd linux-cachyos

echo "Configuring microarchitecture and scheduler options..."
export KCFLAGS="-march=x86-64-v3 -mtune=generic -O3"
export KCPPFLAGS="-march=x86-64-v3 -mtune=generic -O3"

# Base configuration
if [ ! -f .config ]; then
    make defconfig
fi

./scripts/config --enable CONFIG_SCHED_BORE
./scripts/config --enable CONFIG_HZ_1000
./scripts/config --set-val CONFIG_HZ 1000
./scripts/config --enable CONFIG_PREEMPT
./scripts/config --enable CONFIG_SCHED_CLASS_EXT
./scripts/config --module CONFIG_ZRAM
./scripts/config --enable CONFIG_CRYPTO_ZSTD
./scripts/config --enable CONFIG_OVERLAY_FS
./scripts/config --enable CONFIG_SQUASHFS
./scripts/config --enable CONFIG_SQUASHFS_ZSTD
./scripts/config --enable CONFIG_X86_INTEL_PSTATE
./scripts/config --enable CONFIG_X86_AMD_PSTATE

# Ensure local version tag
./scripts/config --set-str CONFIG_LOCALVERSION "-cachyos-bore-v3"

echo "Building Debian kernel packages with $(nproc) threads..."
make -j"$(nproc)" bindeb-pkg LOCALVERSION="-cachyos-bore-v3"

echo "Packaging debian artifacts into $OUT_DIR..."
mv ../linux-image-*.deb "$OUT_DIR/"
mv ../linux-headers-*.deb "$OUT_DIR/" 2>/dev/null || true
mv ../linux-libc-dev_*.deb "$OUT_DIR/" 2>/dev/null || true

echo "OK: CachyOS BORE v3 kernel packages compiled successfully."
