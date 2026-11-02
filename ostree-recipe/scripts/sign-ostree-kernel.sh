#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

ROOTFS="${1:-}"
if [ -z "$ROOTFS" ] || [ ! -d "$ROOTFS" ]; then
    echo "ERROR: Valid target ROOTFS path required." >&2
    exit 1
fi

MOK_PRIV="/workspace/keys/mok/MOK.priv"
MOK_PEM="/workspace/keys/mok/MOK.pem"

if [ ! -f "$MOK_PRIV" ] || [ ! -f "$MOK_PEM" ]; then
    echo "WARNING: MOK keys not found at $MOK_PRIV. Running key generation..."
    /workspace/scripts/generate-mok-keys.sh
fi

echo "Signing kernel images with MOK key..."
find "$ROOTFS/usr/lib/modules" "$ROOTFS/boot" -maxdepth 2 -name "vmlinuz*" -type f 2>/dev/null | while read -r kimg; do
    echo "Signing kernel image: $kimg"
    sbsign --key "$MOK_PRIV" --cert "$MOK_PEM" --output "${kimg}.signed" "$kimg"
    mv "${kimg}.signed" "$kimg"
done

mkdir -p "$ROOTFS/usr/bin"
cat << 'EOF' > "$ROOTFS/usr/bin/kepler-enroll-mok"
#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

echo "=== [Kepler OS] Enrolling UEFI Secure Boot MOK Certificate ==="
MOK_CERT="/usr/share/kepler-mok/MOK.der"

if [ ! -f "$MOK_CERT" ]; then
    echo "ERROR: Certificate not found at $MOK_CERT" >&2
    exit 1
fi

echo "Importing MOK certificate into UEFI NVRAM (requires root authorization)..."
pkexec mokutil --import "$MOK_CERT"

echo "OK: MOK certificate staged for enrollment. Reboot to confirm in MOKManager."
EOF

chmod +x "$ROOTFS/usr/bin/kepler-enroll-mok"
echo "OK: OSTree kernel signed and enrollment helper installed."
