#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu

mkdir -p ostree-recipe/overlays/usr/lib/sysctl.d
mkdir -p ostree-recipe/overlays/usr/lib/udev/rules.d
mkdir -p ostree-recipe/overlays/usr/share/glib-2.0/schemas
mkdir -p ostree-recipe/overlays/usr/share/kepler-mok
mkdir -p ostree-recipe/overlays/usr/share/kepler-science
mkdir -p ostree-recipe/overlays/usr/share/plymouth/themes/kepler-nord
mkdir -p ostree-recipe/overlays/usr/local/bin
mkdir -p ostree-recipe/overlays/usr/bin
mkdir -p ostree-recipe/overlays/etc/default
mkdir -p ostree-recipe/overlays/etc/distrobox
mkdir -p ostree-recipe/overlays/etc/dracut.conf.d
mkdir -p ostree-recipe/overlays/etc/ostree/remotes.d
mkdir -p ostree-recipe/overlays/etc/plymouth
mkdir -p ostree-recipe/overlays/etc/dconf/db/gdm.d
mkdir -p ostree-recipe/overlays/etc/dconf/profile
mkdir -p ostree-recipe/overlays/etc/xdg/autostart
mkdir -p ostree-recipe/scripts
mkdir -p profile/auto
mkdir -p profile/config/archives
mkdir -p profile/config/package-lists
mkdir -p profile/config/hooks/normal
mkdir -p profile/config/includes.chroot/etc/calamares/modules
mkdir -p profile/config/includes.chroot/etc/calamares/branding/kepler
mkdir -p profile/config/includes.chroot/usr/local/bin
mkdir -p profile/config/includes.chroot/ostree-repo
mkdir -p scripts
mkdir -p docs/snippets
mkdir -p build_out

echo "OK: Immutable OSTree directory tree created."
