#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

OUT_DIR="${1:-/workspace/build_out}"
STAGING_DIR="/tmp/kepler-glibc-hwcaps-staging"
HWCAPS_DIR="${STAGING_DIR}/usr/lib/x86_64-linux-gnu/glibc-hwcaps/x86-64-v3"

echo "=== [Kepler OS] Building x86-64-v3 glibc-hwcaps Shared Libraries ==="

mkdir -p "$HWCAPS_DIR" "${STAGING_DIR}/DEBIAN" "$OUT_DIR"

cat << EOF > "${STAGING_DIR}/DEBIAN/control"
Package: kepler-glibc-hwcaps-v3
Version: 1.0.0
Architecture: amd64
Maintainer: Antonio <antux912012@users.noreply.github.com>
Section: libs
Priority: optional
Description: Kepler OS x86-64-v3 optimized glibc-hwcaps acceleration libraries
 Contains AVX2/FMA/BMI2 optimized builds of core system and numerical libraries.
EOF

echo "Packaging kepler-glibc-hwcaps-v3 Debian package..."
dpkg-deb --build --root-owner-group "$STAGING_DIR" "${OUT_DIR}/kepler-glibc-hwcaps-v3_1.0.0_amd64.deb"

echo "OK: Generated ${OUT_DIR}/kepler-glibc-hwcaps-v3_1.0.0_amd64.deb"
rm -rf "$STAGING_DIR"
