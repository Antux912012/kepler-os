#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

SNIPPET="docs/snippets/README_EU_COMPLIANCE_ATTESTATION.md"
TARGET="README.md"

if [ ! -f "$SNIPPET" ] || [ ! -f "$TARGET" ]; then
    echo "ERROR: Missing $SNIPPET or $TARGET" >&2
    exit 1
fi

python3 -c "
with open('$TARGET', 'r', encoding='utf-8') as f:
    readme = f.read()
with open('$SNIPPET', 'r', encoding='utf-8') as f:
    snippet = f.read().strip()

start_marker = '<!-- EU_COMPLIANCE_TABLE_START -->'
end_marker = '<!-- EU_COMPLIANCE_TABLE_END -->'

if start_marker in readme and end_marker in readme:
    before = readme[:readme.find(start_marker) + len(start_marker)]
    after = readme[readme.find(end_marker):]
    new_readme = f'{before}\n\n{snippet}\n\n{after}'
else:
    new_readme = f'{readme}\n\n{start_marker}\n\n{snippet}\n\n{end_marker}\n'

with open('$TARGET', 'w', encoding='utf-8') as f:
    f.write(new_readme)
"

echo "OK: EU AI Act and Cyber Resilience Act (CRA) attestation table updated in README.md."
