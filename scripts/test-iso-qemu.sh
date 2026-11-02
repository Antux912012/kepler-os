#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

LEGACY_CPU=false
BOOT_INSTALLED=false

HEADLESS=false
TIMEOUT_SEC=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --legacy-cpu)
            LEGACY_CPU=true
            shift
            ;;
        --boot-installed)
            BOOT_INSTALLED=true
            shift
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --timeout)
            TIMEOUT_SEC="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

ISO_FILE=$(find build_out -maxdepth 1 -name "*.iso" | head -n 1 || true)
NVME_DISK="build_out/test-nvme.qcow2"
mkdir -p build_out

if [ "$BOOT_INSTALLED" = false ] && [ -z "$ISO_FILE" ]; then
    echo "ERROR: No ISO file found in build_out/*.iso. Run 'make iso' first." >&2
    exit 1
fi

if [ ! -f "$NVME_DISK" ]; then
    echo "Creating 25GB virtual NVMe drive at $NVME_DISK..."
    qemu-img create -f qcow2 "$NVME_DISK" 25G
fi

# CPU selection: x86-64-v3 (Haswell) or legacy SandyBridge
if [ "$LEGACY_CPU" = true ]; then
    CPU_FLAGS="-cpu SandyBridge -smp 2"
    echo "Emulating legacy pre-Haswell CPU (AVX2 absent)..."
else
    CPU_FLAGS="-cpu Haswell-v4 -smp 4"
    echo "Emulating Intel Haswell x86-64-v3 CPU..."
fi

QEMU_CMD=(
    qemu-system-x86_64
    $CPU_FLAGS
    -m 4096M
)

if [ -w /dev/kvm ]; then
    QEMU_CMD+=( -enable-kvm )
fi

QEMU_CMD+=(
    -drive "file=$NVME_DISK,if=none,id=nvme0,format=qcow2"
    -device nvme,drive=nvme0,serial=KEPLER01
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0
)

# Display configuration (support headless / VNC and GUI)
if [ "$HEADLESS" = true ] || [ -z "${DISPLAY:-}" ]; then
    echo "Running QEMU in headless mode (VNC on 127.0.0.1:5900, SSH on 2222)..."
    QEMU_CMD+=(
        -device virtio-vga
        -display none
        -vnc 127.0.0.1:0
    )
else
    QEMU_CMD+=(
        -device virtio-vga-gl
        -display gtk,gl=on
    )
fi

# OVMF UEFI Firmware check (Secure Boot via pflash or unified bios)
if [ -f "/usr/share/OVMF/OVMF_CODE_4M.secboot.fd" ] && [ -f "/usr/share/OVMF/OVMF_VARS_4M.ms.fd" ]; then
    if [ ! -f "build_out/OVMF_VARS_4M.fd" ]; then
        cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd build_out/OVMF_VARS_4M.fd
        chmod 644 build_out/OVMF_VARS_4M.fd
    fi
    QEMU_CMD+=(
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd
        -drive if=pflash,format=raw,file=build_out/OVMF_VARS_4M.fd
    )
elif [ -f "/usr/share/ovmf/OVMF.fd" ]; then
    QEMU_CMD+=( -bios "/usr/share/ovmf/OVMF.fd" )
fi

if [ "$BOOT_INSTALLED" = true ]; then
    echo "Booting deployed OSTree stateroot from virtual NVMe..."
else
    echo "Booting Kepler OS Live ISO: $ISO_FILE..."
    QEMU_CMD+=( -cdrom "$ISO_FILE" -boot d )
fi

if [ "$TIMEOUT_SEC" -gt 0 ]; then
    echo "Running QEMU with timeout of ${TIMEOUT_SEC}s..."
    timeout "$TIMEOUT_SEC" "${QEMU_CMD[@]}" || true
else
    "${QEMU_CMD[@]}"
fi
