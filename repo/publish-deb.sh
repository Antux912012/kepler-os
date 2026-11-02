#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

DEB_PKG="${1:-}"
if [ -z "$DEB_PKG" ] || [ ! -f "$DEB_PKG" ]; then
    echo "Usage: $0 <path-to-deb-package>" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Publishing $(basename "$DEB_PKG") into Voyager-PPA testing suite..."
reprepro -b "$REPO_DIR" includedeb testing "$DEB_PKG"
echo "OK: Published $DEB_PKG into Voyager-PPA."
