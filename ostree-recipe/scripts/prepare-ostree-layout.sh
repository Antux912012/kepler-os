#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

ROOTFS="${1:?ERROR: Specify staging rootfs path as first argument.}"

echo "=== [Kepler OS] Converting $ROOTFS to Immutable OSTree Layout ==="

# 1. Move /etc to /usr/etc (OSTree 3-way merge template directory)
if [ -d "$ROOTFS/etc" ] && [ ! -d "$ROOTFS/usr/etc" ]; then
    mv "$ROOTFS/etc" "$ROOTFS/usr/etc"
fi

# 2. Convert mutable top-level directories to /var and /run symlinks
rm -rf "$ROOTFS/home" "$ROOTFS/opt" "$ROOTFS/srv" "$ROOTFS/mnt" "$ROOTFS/root" "$ROOTFS/media"
ln -s var/home "$ROOTFS/home"
ln -s var/opt "$ROOTFS/opt"
ln -s var/srv "$ROOTFS/srv"
ln -s var/mnt "$ROOTFS/mnt"
ln -s var/roothome "$ROOTFS/root"
ln -s run/media "$ROOTFS/media"

# 3. Ensure OSTree mount targets exist
mkdir -p "$ROOTFS/sysroot" "$ROOTFS/ostree" "$ROOTFS/var" "$ROOTFS/run" "$ROOTFS/boot"

# 4. Relocate kernel and initramfs into /usr/lib/modules/${KVER}/ for atomic updates
for VMLINUZ in "$ROOTFS"/boot/vmlinuz-*; do
    [ -e "$VMLINUZ" ] || continue
    KVER="${VMLINUZ##*/vmlinuz-}"
    MOD_DIR="$ROOTFS/usr/lib/modules/$KVER"
    mkdir -p "$MOD_DIR"
    mv "$VMLINUZ" "$MOD_DIR/vmlinuz"
    if [ -f "$ROOTFS/boot/initrd.img-$KVER" ]; then
        mv "$ROOTFS/boot/initrd.img-$KVER" "$MOD_DIR/initramfs.img"
    elif [ -f "$ROOTFS/boot/initramfs-$KVER.img" ]; then
        mv "$ROOTFS/boot/initramfs-$KVER.img" "$MOD_DIR/initramfs.img"
    elif [ ! -f "$MOD_DIR/initramfs.img" ]; then
        echo "Generating dracut initramfs for $KVER..."
        dracut --sysroot "$ROOTFS" --kver "$KVER" --add ostree --force "$MOD_DIR/initramfs.img" 2>/dev/null || true
    fi
done

rm -rf "$ROOTFS"/boot/*
echo "OK: OSTree filesystem layout prepared in $ROOTFS."
