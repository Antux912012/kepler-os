#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

echo "=== [Kepler Science Box] Initializing r2u & Bioconductor Apt Binary Acceleration ==="

# Install prerequisites inside container
DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    python3-dbus \
    python3-gi \
    python3-apt \
    r-cran-bspm \
    r-cran-biocmanager

# Import r2u / Eddelbuettel GPG key
mkdir -p /usr/share/keyrings
curl -fsSL https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc | gpg --dearmor -o /usr/share/keyrings/r2u-cran.gpg

cat << 'EOF' > /etc/apt/sources.list.d/r2u-cran.list
deb [signed-by=/usr/share/keyrings/r2u-cran.gpg] https://r2u.stat.illinois.edu/ubuntu noble main
EOF

# Pinning configuration
mkdir -p /etc/apt/preferences.d
cat << 'EOF' > /etc/apt/preferences.d/99-r2u-pinning
Package: r-cran-* r-bioc-*
Pin: origin r2u.stat.illinois.edu
Pin-Priority: 700
EOF

# Passwordless apt for bspm
mkdir -p /etc/sudoers.d
echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt" > /etc/sudoers.d/90-kepler-bspm
chmod 0440 /etc/sudoers.d/90-kepler-bspm

# Copy Rprofile.site
mkdir -p /etc/R
if [ -f "/usr/share/kepler-science/Rprofile.site" ]; then
    cp "/usr/share/kepler-science/Rprofile.site" /etc/R/Rprofile.site
fi

echo "OK: r2u & Bioconductor binary environment ready."
