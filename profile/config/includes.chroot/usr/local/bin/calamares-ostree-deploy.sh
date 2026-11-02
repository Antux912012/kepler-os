#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "ERROR: Target root mountpoint required." >&2
    exit 1
fi

echo "=== [Calamares] Deploying Kepler OS OSTree to $TARGET ==="

echo "Initializing modern OSTree layout on target filesystem..."
ostree admin init-fs --modern "$TARGET"
ostree admin os-init kepler --sysroot="$TARGET"

echo "Pulling local OSTree commit from Live environment into target repository..."
ostree --repo="$TARGET/ostree/repo" pull-local /ostree-repo kepler/testing/x86_64-v3/gnome

echo "Configuring upstream update remote..."
ostree --repo="$TARGET/ostree/repo" remote add --set=gpg-verify=true voyager-ostree https://ostree.voyager-project.org/repo

echo "Deploying stateroot with optimized kernel parameters..."
ostree admin deploy \
    --sysroot="$TARGET" \
    --os=kepler \
    --karg="root=LABEL=kepler_root rw quiet splash zswap.enabled=0" \
    voyager-ostree:kepler/testing/x86_64-v3/gnome

echo "Creating stateful var directories..."
mkdir -p "$TARGET/ostree/deploy/kepler/var/home"
mkdir -p "$TARGET/ostree/deploy/kepler/var/roothome"
mkdir -p "$TARGET/ostree/deploy/kepler/var/opt"
mkdir -p "$TARGET/ostree/deploy/kepler/var/lib/containers"

echo "OK: Kepler OS OSTree deployed successfully to $TARGET"
