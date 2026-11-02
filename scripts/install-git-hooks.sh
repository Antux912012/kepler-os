#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || true)
if [ -z "$GIT_DIR" ]; then
    echo "ERROR: Not inside a Git repository." >&2
    exit 1
fi

HOOKS_DIR="${GIT_DIR}/hooks"
mkdir -p "$HOOKS_DIR"

echo "Installing local pre-commit hook (SPDX check)..."
cat << 'EOF' > "${HOOKS_DIR}/pre-commit"
#!/bin/bash
# Pre-commit hook: Verify SPDX license header on staged files
STAGED_FILES=$(git diff --cached --name-only)
for file in $STAGED_FILES; do
    [ -f "$file" ] || continue
    case "$file" in
        *.sh|*.py|*.rs|*.js|*.c|*.h|*.conf|Makefile|Containerfile)
            if ! head -n 5 "$file" | grep -q "SPDX-License-Identifier: GPL-3.0-or-later"; then
                echo "COMMIT BLOCKED: $file lacks SPDX-License-Identifier: GPL-3.0-or-later" >&2
                echo "Run 'make spdx-headers' and re-stage your changes." >&2
                exit 1
            fi
            ;;
    esac
done
EOF
chmod +x "${HOOKS_DIR}/pre-commit"

echo "Installing local commit-msg hook (DCO sign-off check)..."
cat << 'EOF' > "${HOOKS_DIR}/commit-msg"
#!/bin/bash
# Commit-msg hook: Enforce DCO Signed-off-by trailer
COMMIT_MSG_FILE="$1"
if ! grep -q "^Signed-off-by:" "$COMMIT_MSG_FILE"; then
    echo "COMMIT BLOCKED: Commit message missing Developer Certificate of Origin trailer." >&2
    echo "Use 'git commit -s' to automatically sign off your commits." >&2
    exit 1
fi
EOF
chmod +x "${HOOKS_DIR}/commit-msg"

echo "OK: Git pre-commit and commit-msg compliance hooks installed successfully."
