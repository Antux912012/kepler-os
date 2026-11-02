#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

NVME_DISK="build_out/test-nvme.qcow2"
if [ ! -f "$NVME_DISK" ]; then
    echo "ERROR: Deployed NVMe image $NVME_DISK not found. Deploy via Calamares first." >&2
    exit 1
fi

echo "=== [Kepler OS] Launching Headless QEMU/KVM Rollback Test Instance ==="

QEMU_PID=""
cleanup() {
    if [ -n "$QEMU_PID" ]; then
        kill "$QEMU_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

qemu-system-x86_64 \
    -cpu Haswell-v4 \
    -smp 4 \
    -m 4096M \
    -enable-kvm \
    -drive "file=$NVME_DISK,if=none,id=nvme0,format=qcow2" \
    -device nvme,drive=nvme0,serial=KEPLER01 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic &
QEMU_PID=$!

echo "Waiting 25 seconds for guest systemd boot..."
sleep 25

echo "Executing inside-guest verification commands over SSH (port 2222)..."
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p 2222 live@localhost "/usr/bin/kepler-verify-immutability"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p 2222 live@localhost "sudo /usr/bin/kepler-test-ostree-rollback"

echo "OK: QEMU OSTree upgrade and rollback automated test passed."
