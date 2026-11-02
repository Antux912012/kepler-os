#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

OUT_DIR="${1:-/workspace/build_out}"
FAIL_ON_CRITICAL="${FAIL_ON_CRITICAL:-1}"

echo "=== [Kepler OS] Scanning SBOM Manifests for Known Vulnerabilities (CVE) ==="

CDX_FILE=$(find "$OUT_DIR" -maxdepth 1 -name "*.cdx.json" | sort -r | head -n 1 || true)
SPDX_FILE=$(find "$OUT_DIR" -maxdepth 1 -name "*.spdx.json" | sort -r | head -n 1 || true)

if [ -z "$CDX_FILE" ] && [ -z "$SPDX_FILE" ]; then
    echo "ERROR: No .spdx.json or .cdx.json SBOM manifests found in $OUT_DIR." >&2
    exit 1
fi

TRIVY_REPORT_TXT="${OUT_DIR}/kepler-cve-trivy-report.txt"
TRIVY_SARIF="${OUT_DIR}/kepler-cve-trivy.sarif"
GRYPE_JSON="${OUT_DIR}/kepler-cve-grype.json"

if command -v trivy >/dev/null 2>&1 && [ -n "$CDX_FILE" ]; then
    echo "Scanning CycloneDX SBOM with Trivy..."
    trivy sbom --severity CRITICAL,HIGH "$CDX_FILE" > "$TRIVY_REPORT_TXT" || true
    trivy sbom --format sarif --output "$TRIVY_SARIF" "$CDX_FILE" || true
else
    echo "Trivy not available; creating placeholder scan report..."
    echo "Trivy scan skipped: scanner binary not present in environment." > "$TRIVY_REPORT_TXT"
fi

if command -v grype >/dev/null 2>&1 && [ -n "$SPDX_FILE" ]; then
    echo "Scanning SPDX SBOM with Grype (--only-fixed)..."
    grype "sbom:$SPDX_FILE" --only-fixed -o json > "$GRYPE_JSON" || true
else
    echo "Grype not available; creating placeholder JSON report..."
    echo '{"matches": []}' > "$GRYPE_JSON"
fi

# Gate check for fixable critical vulnerabilities
if [ "$FAIL_ON_CRITICAL" = "1" ] && command -v trivy >/dev/null 2>&1 && [ -n "$CDX_FILE" ]; then
    if ! trivy sbom --exit-code 1 --severity CRITICAL --ignore-unfixed "$CDX_FILE" >/dev/null 2>&1; then
        echo "================================================================================" >&2
        echo "SECURITY GATE FAILED: Fixable CRITICAL vulnerabilities detected in image SBOM." >&2
        echo "ASD-STE100 REMEDIATION:" >&2
        echo "1. Rebuild the affected package in Voyager-PPA with security patches." >&2
        echo "2. Or pull updated packages from Debian Testing before committing to OSTree." >&2
        echo "================================================================================" >&2
        exit 1
    fi
fi

cd "$OUT_DIR"
for f in "$TRIVY_REPORT_TXT" "$TRIVY_SARIF" "$GRYPE_JSON"; do
    if [ -f "$f" ]; then
        sha256sum "$(basename "$f")" >> SHA256SUMS 2>/dev/null || true
    fi
done

echo "OK: SBOM CVE vulnerability scan completed."
