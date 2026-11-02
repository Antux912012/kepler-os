# SPDX-License-Identifier: GPL-3.0-or-later
FROM debian:testing-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    debos \
    mmdebstrap \
    ostree \
    dracut \
    dracut-core \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    sbsigntool \
    mokutil \
    mtools \
    dosfstools \
    curl \
    gnupg \
    ca-certificates \
    git \
    rsync \
    bubblewrap \
    skopeo \
    jq \
    openssl \
    python3 \
    btrfs-progs \
    qemu-utils \
    ovmf \
    swtpm \
    swtpm-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
ENTRYPOINT ["/workspace/build-iso.sh"]
