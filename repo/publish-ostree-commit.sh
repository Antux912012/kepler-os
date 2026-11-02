#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

GPG_KEY_ID="${1:-}"
if [ -z "$GPG_KEY_ID" ]; then
    echo "Usage: $0 <GPG_KEY_ID>" >&2
    exit 1
fi

SOURCE_REPO="profile/config/includes.chroot/ostree-repo"
PROD_REPO="./ostree-prod-repo"
BRANCH="kepler/testing/x86_64-v3/gnome"

echo "=== [Kepler OS] Publishing OSTree Commit to Production Remote ==="

if [ ! -d "$PROD_REPO" ]; then
    echo "Initializing production OSTree archive repository..."
    ostree --repo="$PROD_REPO" init --mode=archive
fi

echo "Pulling branch $BRANCH from $SOURCE_REPO into $PROD_REPO..."
ostree --repo="$PROD_REPO" pull-local "$SOURCE_REPO" "$BRANCH"

echo "Signing OSTree commit with GPG key $GPG_KEY_ID..."
ostree --repo="$PROD_REPO" gpg-sign "$BRANCH" "$GPG_KEY_ID"

echo "Updating summary and signing repository index..."
ostree --repo="$PROD_REPO" summary -u --gpg-sign="$GPG_KEY_ID"

echo "OK: Production OSTree repository signed and updated successfully."
