#!/usr/bin/env bash
# scripts/pre-commit-methodology.sh — git pre-commit hook
# enforcing METHODOLOGY.md rules on PREDICTIONS-N.md files.
#
# Install with:
#   ln -sf ../../scripts/pre-commit-methodology.sh .git/hooks/pre-commit
#
# Or via Makefile:
#   make install-hooks
#
# This hook fires before each commit.  If a PREDICTIONS-N.md
# file is in the staged changes, it verifies:
#
#   Rule 2 (lit-review):  file contains ≥1 citation marker
#   Rule 4 (no gap):      no "regime C — other" without justification
#   Rule 9 (attestation): file's SHA appears in attestations/ledger.txt
#
# Failure blocks the commit.  Override (rare, document why) with:
#   git commit --no-verify ... -m "... [bypassing methodology hook because <reason>]"
#
# Per METHODOLOGY.md, --no-verify usage must be flagged in commit
# message AND noted in RESULTS.md for the cycle.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
LEDGER="$ROOT/attestations/ledger.txt"

# Find staged PREDICTIONS-N.md files (Added or Modified).
STAGED_PREDS="$(git diff --cached --name-only --diff-filter=AM \
                 | grep -E '^examples/PREDICTIONS-[0-9]+\.md$' || true)"

if [[ -z "$STAGED_PREDS" ]]; then
    # Nothing to check.  Proceed with commit.
    exit 0
fi

EXIT_CODE=0
FAILURES=()

for FILE in $STAGED_PREDS; do
    FULL="$ROOT/$FILE"
    if [[ ! -f "$FULL" ]]; then
        # Deleted in tree but staged — skip.
        continue
    fi

    # --- Rule 2: lit-review ---
    # Heuristic: file should contain at least one of:
    #   - a year in parentheses like "(1999)" or "(2001, 2nd ed.)"
    #   - an author surname pattern "Author Name (Year)"
    #   - a book/paper title pattern "*italics*" or `code`
    if ! grep -E -q '\([12][0-9]{3}(,| [a-z])|cf\. [A-Z]|see [A-Z][a-z]+|, [A-Z][a-z]+ [12][0-9]{3}' "$FULL"; then
        FAILURES+=("$FILE: Rule 2 — no citation marker found (need year-in-parens or author-year reference)")
        EXIT_CODE=1
    fi

    # --- Rule 4: regime partition ---
    # Heuristic: if file mentions "regime", it should also mention
    # "partition" or "no gap" or specific bounds — flag if "other"
    # or "C — other" patterns appear without surrounding context.
    if grep -E -i -q 'regime.*other|regime [a-z].*other' "$FULL"; then
        if ! grep -E -i -q 'partition|no gap|without gap' "$FULL"; then
            FAILURES+=("$FILE: Rule 4 — 'regime ... other' present without 'partition' / 'no gap' clause")
            EXIT_CODE=1
        fi
    fi

    # --- Rule 9: attestation ---
    if [[ -f "$LEDGER" ]]; then
        SHA="$(shasum -a 256 "$FULL" | awk '{print $1}')"
        if ! grep -q "$SHA" "$LEDGER"; then
            FAILURES+=("$FILE: Rule 9 — SHA-256 $SHA not in attestations/ledger.txt; run scripts/attest_prediction.sh first")
            EXIT_CODE=1
        fi
    else
        FAILURES+=("$FILE: Rule 9 — attestations/ledger.txt does not exist; run scripts/attest_prediction.sh to initialize")
        EXIT_CODE=1
    fi
done

if [[ $EXIT_CODE -ne 0 ]]; then
    echo ""
    echo "METHODOLOGY.md pre-commit check FAILED:"
    echo ""
    for f in "${FAILURES[@]}"; do
        echo "  ✗ $f"
    done
    echo ""
    echo "To fix:"
    echo "  - Rule 2 failures: add a literature citation"
    echo "  - Rule 4 failures: rewrite to partition regime space without 'other' gap"
    echo "  - Rule 9 failures: run scripts/attest_prediction.sh <file> and stage ledger.txt"
    echo ""
    echo "To bypass (must justify in commit message AND RESULTS.md):"
    echo "  git commit --no-verify -m \"... [bypassing methodology hook because <reason>]\""
    echo ""
    exit 1
fi

exit 0
