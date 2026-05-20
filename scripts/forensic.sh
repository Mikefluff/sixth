#!/usr/bin/env bash
# scripts/forensic.sh — render forensic-trace artefacts for one demo.
#
# Usage:  scripts/forensic.sh <demo-file> <slug> <title>
#
# Produces three artefacts under build/figures/:
#   <slug>_trace.dot       intermediate DOT stream (for diff/jsonl reuse)
#   <slug>_forensic.png    multi-panel snapshots + Δ titles
#   <slug>_forensic.jsonl  one JSON object per snapshot (machine-readable)
#   <slug>_diff.png        per-step diff (green added, red removed)
set -euo pipefail

DEMO="$1"
SLUG="$2"
TITLE="$3"

mkdir -p build/figures
racket -l sixth/cli -- run "$DEMO" > "build/figures/${SLUG}_trace.dot"

python3 code/render_trace.py "build/figures/${SLUG}_trace.dot" \
    --out "build/figures/${SLUG}_forensic.png" \
    --jsonl "build/figures/${SLUG}_forensic.jsonl" \
    --title "$TITLE — forensic trace"

python3 code/render_trace.py "build/figures/${SLUG}_trace.dot" \
    --out "build/figures/${SLUG}_diff.png" --diff \
    --title "$TITLE"

echo "→ build/figures/${SLUG}_forensic.png  (snapshots + deltas)"
echo "→ build/figures/${SLUG}_forensic.jsonl (machine-readable trace)"
echo "→ build/figures/${SLUG}_diff.png      (per-step DIFF view)"
