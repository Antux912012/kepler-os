#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

mkdir -p ostree-recipe/overlays/usr/share/kepler-mok keys/mok

if [ ! -f "keys/mok/MOK.priv" ]; then
    openssl req -new -x509 -newkey rsa:4096 -nodes -days 3650 \
        -subj "/CN=Kepler OS Immutable Secure Boot Signing Key/" \
        -keyout keys/mok/MOK.priv \
        -out keys/mok/MOK.pem
    openssl x509 -in keys/mok/MOK.pem -outform DER -out ostree-recipe/overlays/usr/share/kepler-mok/MOK.der
    chmod 600 keys/mok/MOK.priv
    echo "OK: Kepler OS Immutable MOK keys generated."
else
    echo "OK: Existing MOK keys found in keys/mok/."
fi
