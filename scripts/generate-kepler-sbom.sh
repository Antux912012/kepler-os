#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

TARGET_ROOT="${1:-/workspace/rootfs_staging}"
OUT_DIR="${2:-/workspace/build_out}"
REPO_DIR="/workspace/profile/config/includes.chroot/ostree-repo"
BRANCH="kepler/testing/x86_64-v3/gnome"

mkdir -p "$OUT_DIR"

echo "=== [Kepler OS] Generating SPDX 2.3 and CycloneDX 1.5 SBOM Manifests ==="

OSTREE_COMMIT="unknown"
if [ -d "$REPO_DIR" ]; then
    OSTREE_COMMIT=$(ostree --repo="$REPO_DIR" rev-parse "$BRANCH" 2>/dev/null || echo "development")
fi
SHORT_COMMIT="${OSTREE_COMMIT:0:12}"

SPDX_OUT="${OUT_DIR}/kepler-os-immutable-${SHORT_COMMIT}.spdx.json"
CDX_OUT="${OUT_DIR}/kepler-os-immutable-${SHORT_COMMIT}.cdx.json"

if command -v syft >/dev/null 2>&1; then
    echo "Running syft to generate SPDX 2.3 JSON SBOM..."
    syft "dir:$TARGET_ROOT" -o spdx-json="$SPDX_OUT" || true
    echo "Running syft to generate CycloneDX 1.5 JSON SBOM..."
    syft "dir:$TARGET_ROOT" -o cyclonedx-json="$CDX_OUT" || true
fi

# Fallback generator if syft is unavailable or produced empty files
if [ ! -s "$SPDX_OUT" ] || [ ! -s "$CDX_OUT" ]; then
    echo "Using python SBOM manifest generator from dpkg status..."
    python3 -c "
import json, os, datetime
packages = []
status_file = os.path.join('${TARGET_ROOT}', 'var/lib/dpkg/status')
if os.path.exists(status_file):
    with open(status_file, encoding='utf-8', errors='ignore') as f:
        pkg = {}
        for line in f:
            line = line.strip()
            if line.startswith('Package: '): pkg['name'] = line.split(': ')[1]
            elif line.startswith('Version: '): pkg['version'] = line.split(': ')[1]
            elif line.startswith('Architecture: '): pkg['arch'] = line.split(': ')[1]
            elif line.startswith('Description: '): pkg['desc'] = line.split(': ')[1]
            elif not line and pkg.get('name'):
                packages.append(pkg)
                pkg = {}

spdx = {
    'spdxVersion': 'SPDX-2.3',
    'dataLicense': 'CC0-1.0',
    'SPDXID': 'SPDXRef-DOCUMENT',
    'name': 'kepler-os-immutable',
    'documentNamespace': f'https://spdx.voyager-project.org/kepler-os-${SHORT_COMMIT}',
    'creationInfo': {
        'creators': ['Tool: kepler-sbom-generator', 'Organization: Voyager Project'],
        'created': datetime.datetime.now(datetime.timezone.utc).isoformat()
    },
    'packages': [{
        'SPDXID': f'SPDXRef-Package-{p[\"name\"]}',
        'name': p['name'],
        'versionInfo': p.get('version', 'unknown'),
        'downloadLocation': 'NOASSERTION',
        'licenseConcluded': 'NOASSERTION'
    } for p in packages]
}
with open('${SPDX_OUT}', 'w') as f: json.dump(spdx, f, indent=2)

cdx = {
    'bomFormat': 'CycloneDX',
    'specVersion': '1.5',
    'version': 1,
    'metadata': {
        'timestamp': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'component': {
            'name': 'kepler-os-immutable',
            'version': '${SHORT_COMMIT}',
            'type': 'operating-system'
        }
    },
    'components': [{
        'name': p['name'],
        'version': p.get('version', 'unknown'),
        'type': 'library',
        'purl': f'pkg:deb/debian/{p[\"name\"]}@{p.get(\"version\", \"\")}'
    } for p in packages]
}
with open('${CDX_OUT}', 'w') as f: json.dump(cdx, f, indent=2)
"
fi

if [ -d "$TARGET_ROOT/usr/share" ]; then
    mkdir -p "$TARGET_ROOT/usr/share/doc/kepler-os/sbom"
    cp "$SPDX_OUT" "$CDX_OUT" "$TARGET_ROOT/usr/share/doc/kepler-os/sbom/"
fi

if [ -n "${VOYAGER_GPG_KEY_ID:-}" ]; then
    echo "Signing SBOM files with GPG key $VOYAGER_GPG_KEY_ID..."
    gpg --batch --yes --armor --detach-sign --default-key "$VOYAGER_GPG_KEY_ID" "$SPDX_OUT"
    gpg --batch --yes --armor --detach-sign --default-key "$VOYAGER_GPG_KEY_ID" "$CDX_OUT"
fi

cd "$OUT_DIR"
sha256sum "$(basename "$SPDX_OUT")" "$(basename "$CDX_OUT")" >> SHA256SUMS || true

echo "OK: SBOM manifests generated successfully."
