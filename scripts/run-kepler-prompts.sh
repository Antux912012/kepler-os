#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

DOCS_DIR="${1:-./Project_Kepler_OS}"
OUT_DIR="${2:-./kepler-os-build}"
MODE="${3:-export}" # Options: export | batch-by-tier | sequential

echo "=== [Kepler OS] Automated ASD-STE100 Prompt Runner ==="
echo "Docs Directory  : $DOCS_DIR"
echo "Output Workspace: $OUT_DIR"
echo "Execution Mode  : $MODE"

if [ "$MODE" = "export" ]; then
    python3 scripts/run-kepler-prompts.py \
        --docs-dir "$DOCS_DIR" \
        --out-dir "$OUT_DIR" \
        --export-only
    echo "OK: Prompts exported to $OUT_DIR/prompts_queue/{LOW,MEDIUM,HIGH}/"
elif [ "$MODE" = "batch-by-tier" ]; then
    for TIER in LOW MEDIUM HIGH; do
        echo "--- Executing Batch Tier: Gemini 3.8 Flash [$TIER] ---"
        python3 scripts/run-kepler-prompts.py \
            --docs-dir "$DOCS_DIR" \
            --out-dir "$OUT_DIR" \
            --tier "$TIER"
    done
elif [ "$MODE" = "sequential" ]; then
    python3 scripts/run-kepler-prompts.py \
        --docs-dir "$DOCS_DIR" \
        --out-dir "$OUT_DIR" \
        --tier ALL
else
    echo "ERROR: Invalid mode '$MODE'. Use: export | batch-by-tier | sequential"
    exit 1
fi
