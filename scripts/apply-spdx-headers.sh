#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

echo "=== [Kepler OS] Applying SPDX-License-Identifier Headers ==="

SPDX_HASH="# SPDX-License-Identifier: GPL-3.0-or-later"
SPDX_SLASH="// SPDX-License-Identifier: GPL-3.0-or-later"

find . -type f \
    ! -path "*/.git/*" \
    ! -path "*/target/*" \
    ! -path "*/build_out/*" \
    ! -path "*/prompts_queue/*" \
    ! -path "*/work/*" \
    ! -path "*/rootfs_staging/*" \
    ! -path "*/.flatpak-data/*" | while read -r file; do

    case "$file" in
        *.sh|*.py|*.conf|*.chroot|*Makefile*|*Containerfile*)
            if ! head -n 3 "$file" | grep -q "SPDX-License-Identifier"; then
                if head -n 1 "$file" | grep -q "^#!"; then
                    SHEBANG=$(head -n 1 "$file")
                    REST=$(tail -n +2 "$file")
                    printf "%s\n%s\n%s\n" "$SHEBANG" "$SPDX_HASH" "$REST" > "$file"
                else
                    CONTENT=$(cat "$file")
                    printf "%s\n%s\n" "$SPDX_HASH" "$CONTENT" > "$file"
                fi
                echo "Added SPDX header to $file"
            fi
            ;;
        *.rs|*.js|*.c|*.h)
            if ! head -n 3 "$file" | grep -q "SPDX-License-Identifier"; then
                CONTENT=$(cat "$file")
                printf "%s\n%s\n" "$SPDX_SLASH" "$CONTENT" > "$file"
                echo "Added SPDX header to $file"
            fi
            ;;
    esac
done

echo "OK: SPDX headers verified across repository."
