#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

NVME_DISK="build_out/test-nvme.qcow2"
SWTPM_DIR="build_out/swtpm-state"
SWTPM_SOCK="build_out/swtpm-sock"

mkdir -p "$SWTPM_DIR"

if ! command -v swtpm >/dev/null 2>&1; then
    echo "ERROR: swtpm is required for TPM 2.0 virtualization testing." >&2
    exit 1
fi

SWTPM_PID=""
QEMU_PID=""
cleanup() {
    [ -n "$QEMU_PID" ] && kill "$QEMU_PID" 2>/dev/null || true
    [ -n "$SWTPM_PID" ] && kill "$SWTPM_PID" 2>/dev/null || true
    rm -f "$SWTPM_SOCK"
}
trap cleanup EXIT

echo "Starting emulated Software TPM 2.0 socket daemon..."
swtpm socket \
    --tpm2 \
    --tpmstate dir="$SWTPM_DIR" \
    --ctrl type=unixio,path="$SWTPM_SOCK" \
    --daemon
SWTPM_PID=$(pgrep -f "swtpm socket" | head -n 1 || true)

echo "Launching QEMU/KVM with CRB TPM 2.0 device..."
qemu-system-x86_64 \
    -cpu Haswell-v4 \
    -smp 4 \
    -m 4096M \
    -enable-kvm \
    -chardev socket,id=chrtpm,path="$SWTPM_SOCK" \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-crb,tpmdev=tpm0 \
    -drive "file=$NVME_DISK,if=none,id=nvme0,format=qcow2" \
    -device nvme,drive=nvme0,serial=KEPLER01 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic &
QEMU_PID=$!

echo "Waiting for guest initialization..."
sleep 25

echo "Testing guest TPM 2.0 LUKS auto-unlock verification..."
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p 2222 live@localhost "sudo /usr/bin/kepler-verify-tpm2-luks"

echo "OK: swtpm LUKS2 unattended auto-unlock verified."
