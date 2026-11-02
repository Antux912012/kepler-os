#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

REPO_DIR="/workspace/profile/config/includes.chroot/ostree-repo"
STAGE_DIR="/workspace/rootfs_staging"
OSTREE_BRANCH="${OSTREE_BRANCH:-kepler/testing/x86_64-v3/gnome}"

echo "=== [Kepler OS] Building Immutable OSTree Commit ($OSTREE_BRANCH) ==="

mkdir -p "$REPO_DIR"
if [ ! -f "$REPO_DIR/config" ]; then
    ostree --repo="$REPO_DIR" init --mode=archive-z2
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

# Collect packages from profile/config/package-lists/*.list.chroot if present
PKG_LIST="systemd,systemd-sysv,ostree,dracut,zram-tools,sudo,curl,ca-certificates,btrfs-progs"
if compgen -G "/workspace/profile/config/package-lists/*.list.chroot" > /dev/null; then
    EXTRA_PKGS=$(grep -h -vE '^(#|$)' /workspace/profile/config/package-lists/*.list.chroot | tr '\n' ',' | sed 's/,$//')
    if [ -n "$EXTRA_PKGS" ]; then
        PKG_LIST="$PKG_LIST,$EXTRA_PKGS"
    fi
fi

mmdebstrap --variant=minbase \
    --components="main,contrib,non-free,non-free-firmware" \
    --include="$PKG_LIST" \
    testing "$STAGE_DIR" http://deb.debian.org/debian

# Copy immutable overlays into staging rootfs
if [ -d "/workspace/ostree-recipe/overlays" ]; then
    cp -a /workspace/ostree-recipe/overlays/. "$STAGE_DIR/"
fi

# Sign kernel with MOK key if signing script and keys exist
if [ -x "/workspace/ostree-recipe/scripts/sign-ostree-kernel.sh" ] && [ -f "/workspace/keys/mok/MOK.priv" ]; then
    /workspace/ostree-recipe/scripts/sign-ostree-kernel.sh "$STAGE_DIR"
fi

# Convert Debian rootfs to OSTree layout (/usr/etc, /var symlinks, /usr/lib/modules/$KVER)
/workspace/ostree-recipe/scripts/prepare-ostree-layout.sh "$STAGE_DIR"

# Commit staging rootfs to local OSTree repository
ostree --repo="$REPO_DIR" commit \
    --branch="$OSTREE_BRANCH" \
    --subject="Kepler OS x86-64-v3 Atomic Build $(date -u +%Y%m%d.%H%M)" \
    "$STAGE_DIR"

ostree --repo="$REPO_DIR" summary -u
echo "OK: OSTree commit sealed on branch $OSTREE_BRANCH."
