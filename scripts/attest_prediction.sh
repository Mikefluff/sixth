#!/usr/bin/env bash
# scripts/attest_prediction.sh — append a tamper-evident record
# of a PREDICTIONS-N.md to attestations/ledger.txt.
#
# Per METHODOLOGY.md Rule 9: each pre-registration file must be
# recorded with (timestamp, file, sha256, git-commit) tuple.
# The ledger itself is hashed cumulatively; any attempt to
# rewrite history is detected by comparing the latest ledger
# hash to an externally-anchored copy (OpenTimestamps,
# public tweet, etc).
#
# Usage:
#   scripts/attest_prediction.sh examples/PREDICTIONS-NNN.md
#
# After running, the ledger entry must be:
#   1. committed alongside the PREDICTIONS file
#   2. anchored externally — see attestations/README.md for
#      current anchors and how to add a new one

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path-to-PREDICTIONS-N.md>" >&2
    exit 1
fi

PREDICTION_FILE="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$ROOT/attestations/ledger.txt"

if [[ ! -f "$PREDICTION_FILE" ]]; then
    echo "ERROR: not a file: $PREDICTION_FILE" >&2
    exit 1
fi

# Resolve to repo-relative path for ledger clarity.
REL_PATH="$(cd "$(dirname "$PREDICTION_FILE")" && pwd)/$(basename "$PREDICTION_FILE")"
REL_PATH="${REL_PATH#$ROOT/}"

# Timestamp in UTC, ISO 8601.
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# SHA-256 of the predictions file (this content is what gets
# committed; if anyone rewrites the predictions, hash changes).
SHA="$(shasum -a 256 "$PREDICTION_FILE" | awk '{print $1}')"

# Git commit currently at HEAD (or empty if not in repo).
GIT_COMMIT="$(cd "$ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "no-git")"

# Append the row to the ledger.
mkdir -p "$ROOT/attestations"
if [[ ! -f "$LEDGER" ]]; then
    printf "# Pre-registration attestation ledger\n" > "$LEDGER"
    printf "# format: <iso-timestamp>  <sha256>  <repo-path>  <git-head-when-attested>\n" >> "$LEDGER"
    printf "# rules: append-only; never edit existing rows; anchor cumulative hash externally\n" >> "$LEDGER"
    printf "# (METHODOLOGY.md Rule 9)\n\n" >> "$LEDGER"
fi

printf "%s  %s  %s  %s\n" "$TS" "$SHA" "$REL_PATH" "$GIT_COMMIT" >> "$LEDGER"

# Compute the cumulative ledger hash — this is the canonical
# "what to anchor externally" value.
LEDGER_HASH="$(shasum -a 256 "$LEDGER" | awk '{print $1}')"

echo "Attested: $REL_PATH"
echo "  predictions sha256:    $SHA"
echo "  ledger row appended:   $TS"
echo "  ledger cumulative sha: $LEDGER_HASH"
echo ""
echo "Next steps:"
echo "  1. git add $LEDGER $PREDICTION_FILE"
echo "  2. git commit"
echo "  3. ANCHOR the cumulative ledger hash externally before"
echo "     writing demo source.  Options:"
echo "     - opentimestamps:  ots stamp $LEDGER"
echo "     - public tweet/toot of the ledger sha"
echo "     - github release tag with sha in description"
echo ""
echo "  Record the anchor in attestations/README.md."
