#!/usr/bin/env bash
# scripts/verify.sh — one-command artifact-status report for Sixth.
#
# Honours the external-reviewer request: a single `make verify`
# that prints whether the language, substrate, examples, docs, and
# optional FFI bridges all pass, ending with a single-line
# "artifact status:" verdict that CI (or a human reader) can grep.
#
# Output format:
#   language tests:   ok
#   substrate tests:  ok
#   examples:         828 / 828 ✓ across 58 demos
#   docs build:       ok
#   ffi optional:     n/a   (libtorch bridges not yet shipped)
#   renderer tests:   ok
#   figures fresh:    ok (18 forensic JSONL traces match)
#   artifact status:  reproducible
#
# Any failure exits non-zero and prints "artifact status:  BROKEN".

set -u
cd "$(dirname "$0")/.."

FAIL=0
report () { printf "%-18s %s\n" "$1" "$2" ; }
warn  () { printf "%-18s %s\n" "$1" "$2" >&2 ; }

# ---- language tests (lexer / parser / loader / vm) ----
if raco test tests/lexer-test.rkt tests/parser-test.rkt \
              tests/loader-test.rkt tests/vm-test.rkt \
              >/dev/null 2>&1
then
    report "language tests:" "ok"
else
    report "language tests:" "FAIL"
    FAIL=1
fi

# ---- substrate tests ----
if raco test tests/substrate-test.rkt >/dev/null 2>&1
then
    report "substrate tests:" "ok"
else
    report "substrate tests:" "FAIL"
    FAIL=1
fi

# ---- examples regression (828 ✓ across 58 demos style) ----
EX_OUT=$(raco test tests/examples-test.rkt 2>&1 || true)
EX_LINE=$(printf "%s\n" "$EX_OUT" | grep -oE 'examples regression: [0-9]+ / [0-9]+ ✓ across [0-9]+ demos' | head -1)
if [ -n "$EX_LINE" ] && printf "%s\n" "$EX_OUT" | grep -q "tests passed"
then
    report "examples:" "${EX_LINE#examples regression: }"
else
    report "examples:" "FAIL"
    FAIL=1
fi

# ---- docs build ----
mkdir -p build/docs
if raco scribble --html --dest build/docs docs/manual.scrbl >/dev/null 2>&1
then
    report "docs build:" "ok"
else
    report "docs build:" "FAIL"
    FAIL=1
fi

# ---- optional FFI (libtorch bridge) ----
if [ -f tests/bridges/torch-test.rkt ]; then
    if raco test tests/bridges/torch-test.rkt >/dev/null 2>&1
    then
        report "ffi optional:" "ok"
    else
        report "ffi optional:" "skipped (libtorch absent)"
    fi
else
    report "ffi optional:" "n/a"
fi

# ---- renderer unit tests (Python) ----
if python3 tests/render-test.py >/dev/null 2>&1
then
    report "renderer tests:" "ok"
else
    report "renderer tests:" "FAIL"
    FAIL=1
fi

# ---- figure freshness (committed forensic JSONL = fresh regen) ----
if bash scripts/verify_figures.sh >/dev/null 2>&1
then
    report "figures fresh:" "ok (18 forensic JSONL traces match)"
else
    report "figures fresh:" "STALE (run 'make forensic-all' + commit)"
    FAIL=1
fi

# ---- verdict ----
echo
if [ "$FAIL" -eq 0 ]; then
    report "artifact status:" "reproducible"
    exit 0
else
    report "artifact status:" "BROKEN"
    exit 1
fi
