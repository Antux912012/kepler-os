#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

REPO_DIR="/workspace/profile/config/includes.chroot/ostree-repo"
OSTREE_BRANCH="kepler/testing/x86_64-v3/gnome"
OCI_ARCHIVE="/workspace/build_out/kepler-os-immutable-x86_64-v3-oci.tar"
GHCR_IMAGE="${GHCR_IMAGE:-ghcr.io/antux912012/kepler-os-immutable:testing-x86_64-v3}"

echo "=== [Kepler OS] OCI Bootable Container Encapsulation ==="
echo "OSTree Repo   : $REPO_DIR"
echo "Target Branch : $OSTREE_BRANCH"
echo "OCI Archive   : $OCI_ARCHIVE"
echo "Image Target  : $GHCR_IMAGE"

mkdir -p "$(dirname "$OCI_ARCHIVE")"

if [ ! -f "$REPO_DIR/config" ]; then
    echo "ERROR: OSTree repository not found at $REPO_DIR/config" >&2
    exit 1
fi

COMMIT_HASH=$(ostree --repo="$REPO_DIR" rev-parse "$OSTREE_BRANCH" 2>/dev/null || true)
if [ -z "$COMMIT_HASH" ]; then
    echo "ERROR: Branch $OSTREE_BRANCH does not exist in repo $REPO_DIR" >&2
    exit 1
fi
echo "Verified commit: $COMMIT_HASH"

echo "Encapsulating OSTree commit into OCI bootable container archive..."
ostree container encapsulate \
    --repo="$REPO_DIR" \
    "$OSTREE_BRANCH" \
    --label="containers.bootc=1" \
    --label="ostree.bootable=true" \
    --label="org.opencontainers.image.licenses=GPL-3.0-or-later" \
    --label="org.opencontainers.image.title=Kepler OS Immutable (x86-64-v3)" \
    "oci-archive:${OCI_ARCHIVE}"

echo "OK: OCI archive created at $OCI_ARCHIVE"

if [ -n "${GHCR_TOKEN:-}" ] && [ -n "${GHCR_USER:-}" ]; then
    echo "Pushing OCI archive to GitHub Container Registry..."
    skopeo copy \
        --dest-creds "${GHCR_USER}:${GHCR_TOKEN}" \
        "oci-archive:${OCI_ARCHIVE}" \
        "docker://${GHCR_IMAGE}"

    DATE_TAG="$(date -u +%Y%m%d)"
    GHCR_DATE_IMAGE="${GHCR_IMAGE%:*}:${DATE_TAG}"
    echo "Pushing tagged image: $GHCR_DATE_IMAGE"
    skopeo copy \
        --dest-creds "${GHCR_USER}:${GHCR_TOKEN}" \
        "oci-archive:${OCI_ARCHIVE}" \
        "docker://${GHCR_DATE_IMAGE}"
    echo "OK: Published to $GHCR_IMAGE and $GHCR_DATE_IMAGE"
else
    echo "INFO: GHCR_TOKEN or GHCR_USER not set. Skipped remote push."
fi

echo "================================================================================"
echo "DEPLOYMENT INSTRUCTIONS (ASD-STE100):"
echo "To switch a deployed Kepler OS instance to this OCI container image, run:"
echo "  ostree container image deploy --sysroot=/ --stateroot=kepler --imgref=\"ostree-unverified-registry:${GHCR_IMAGE}\""
echo "Or using bootc:"
echo "  bootc switch ${GHCR_IMAGE}"
echo "================================================================================"
