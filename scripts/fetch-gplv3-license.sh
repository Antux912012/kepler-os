#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu

echo "Fetching official GNU General Public License v3.0 text..."
curl -fsSL https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE
echo "OK: LICENSE file written."
