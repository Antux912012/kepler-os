#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

if [ ! -f "/workspace/profile/config/includes.chroot/ostree-repo/config" ]; then
    echo "ERROR: Embedded OSTree repository not found. Run 'make ostree-commit' first." >&2
    exit 1
fi

# Ensure previous mounts (if any) are cleaned up before removing work
umount -lf /workspace/work/chroot/proc /workspace/work/chroot/sys /workspace/work/chroot/dev/pts /workspace/work/chroot/dev 2>/dev/null || true
rm -rf /workspace/work
mkdir -p /workspace/work /workspace/build_out
cp -a /workspace/profile/. /workspace/work/

cd /workspace/work

# Patch live-build to divert aspell-autobuildhash during package installation,
# bypassing the Debian testing Perl debconf subst syntax error in dictionaries-common
if [ -f /usr/lib/live/build/chroot_dpkg ] && ! grep -q "aspell-autobuildhash" /usr/lib/live/build/chroot_dpkg; then
    sed -i '/Chroot chroot dpkg-divert --rename --quiet --add \/usr\/sbin\/flash-kernel/a \\t\tChroot chroot dpkg-divert --rename --quiet --add /usr/sbin/aspell-autobuildhash || true\n\t\tln -fs /bin/true chroot/usr/sbin/aspell-autobuildhash || true' /usr/lib/live/build/chroot_dpkg
    sed -i '/rm -f chroot\/usr\/sbin\/flash-kernel/a \\t\trm -f chroot/usr/sbin/aspell-autobuildhash || true\n\t\tChroot chroot dpkg-divert --rename --quiet --remove /usr/sbin/aspell-autobuildhash || true' /usr/lib/live/build/chroot_dpkg
fi

# Prepare clean, dedicated package list for the Live Installer ISO.
# The deployed OS (science stack, desktop apps, etc.) is fully encapsulated in /ostree-repo.
# The Live ISO only needs the installer, minimal Wayland/GNOME session, and filesystem/partition tools.
rm -f config/package-lists/*.list.chroot
cat << 'EOF' > config/package-lists/kepler-live-installer.list.chroot
live-boot
live-config
live-config-systemd
systemd-sysv
linux-image-amd64
calamares
calamares-settings-debian
gnome-session
gnome-shell
gdm3
network-manager-applet
zenity
ostree
btrfs-progs
cryptsetup
dosfstools
e2fsprogs
parted
sudo
curl
ca-certificates
fonts-inter
fonts-jetbrains-mono
mesa-vulkan-drivers
EOF

# Ensure auto/config is executable
chmod +x auto/config 2>/dev/null || true

echo "=== [Kepler OS] Configuring Live-Build for Hybrid Live ISO ==="
lb config

echo "=== [Kepler OS] Building Hybrid Live ISO ==="
lb build

ISO_FOUND=$(find . -maxdepth 1 -name "*.iso" | head -n 1 || true)
if [ -n "$ISO_FOUND" ]; then
    ISO_OUT="/workspace/build_out/kepler-os-immutable-x86_64-v3-$(date -u +%Y%m%d).iso"
    mv "$ISO_FOUND" "$ISO_OUT"
    echo "OK: Live Installer ISO created at $ISO_OUT"
    cd /workspace/build_out
    sha256sum "$(basename "$ISO_OUT")" >> SHA256SUMS
    echo "OK: Appended ISO checksum to SHA256SUMS."
else
    echo "ERROR: No ISO image produced by live-build." >&2
    exit 1
fi
