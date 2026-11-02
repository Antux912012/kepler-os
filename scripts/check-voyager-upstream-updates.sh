#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

OUT_DIR="${1:-/workspace/build_out}"
REPORT_FILE="${OUT_DIR}/upstream-updates-report.json"
mkdir -p "$OUT_DIR"

echo "=== [Kepler OS] Checking Upstream Updates for CachyOS and x86-64-v3 Stack ==="

echo "Fetching latest tags from linux-cachyos..."
LATEST_KERNEL_TAG=$(git ls-remote --tags --refs --sort='v:refname' https://github.com/CachyOS/linux-cachyos.git | tail -n 1 | sed 's|.*refs/tags/||' || echo "v6.12.8-cachyos")

CURRENT_PPA_KERNEL="none"
if [ -f "repo/dists/testing/main/binary-amd64/Packages" ]; then
    CURRENT_PPA_KERNEL=$(grep -A 5 "Package: linux-image-cachyos-bore-v3" repo/dists/testing/main/binary-amd64/Packages | grep "^Version:" | head -n 1 | awk '{print $2}' || echo "none")
fi

echo "Latest upstream CachyOS tag: $LATEST_KERNEL_TAG"
echo "Current Voyager-PPA kernel:  $CURRENT_PPA_KERNEL"

cat << EOF > "$REPORT_FILE"
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "kernel": {
    "latest_upstream_tag": "$LATEST_KERNEL_TAG",
    "current_ppa_version": "$CURRENT_PPA_KERNEL",
    "update_available": $([ "$LATEST_KERNEL_TAG" != "$CURRENT_PPA_KERNEL" ] && echo "true" || echo "false")
  },
  "libraries_monitored": [
    "openblas",
    "zlib-ng",
    "zstd",
    "fftw3"
  ]
}
EOF

echo "OK: Status report saved to $REPORT_FILE"
