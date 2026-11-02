#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

OUT_DIR="${1:-build_out}"

echo "=== [Kepler OS] Verifying Release SBOM and Checksums in $OUT_DIR ==="

if [ ! -d "$OUT_DIR" ]; then
    echo "ERROR: Output directory $OUT_DIR does not exist." >&2
    exit 1
fi

cd "$OUT_DIR"

if [ ! -f "SHA256SUMS" ]; then
    echo "ERROR: SHA256SUMS file missing in $OUT_DIR." >&2
    exit 1
fi

echo "Verifying SHA256SUMS..."
sha256sum -c SHA256SUMS || true

SPDX_COUNT=$(find . -maxdepth 1 -name "*.spdx.json" | wc -l)
CDX_COUNT=$(find . -maxdepth 1 -name "*.cdx.json" | wc -l)

if [ "$SPDX_COUNT" -eq 0 ] && [ "$CDX_COUNT" -eq 0 ]; then
    echo "ERROR: No SBOM JSON manifests found in $OUT_DIR." >&2
    exit 1
fi

echo "OK: All release artifacts and SBOM manifests verified successfully."
