#!/usr/bin/env bash
# scripts/verify_repro.sh — literal reproducibility check.
#
# Runs each forensic-trace demo twice, hashes the JSONL output, and
# asserts byte-identical results.  Substrate is fully deterministic
# (MARK ids are sequential, no PRNG anywhere), so any drift here
# indicates either a host-side bug or non-determinism leakage.
#
# Run via `make verify-repro`.  Not part of default `make verify`
# (adds ~30s to runtime; literal reproducibility is a stronger claim
# than freshness which is checked by verify_figures.sh).

set -u
cd "$(dirname "$0")/.."

mkdir -p build/figures
FAIL=0

DEMOS=(
  "examples/37-trace-pilot-d.6th         pilot_d"
  "examples/38-trace-pilot-c.6th         pilot_c"
  "examples/39-trace-split-brain.6th     split_brain"
  "examples/41-long-epoch-growth.6th     long_epoch_growth_f"
  "examples/42-trace-conway-blinker.6th  conway_blinker_f"
  "examples/43-trace-conway-glider.6th   conway_glider_f"
  "examples/44-trace-rule110.6th         rule110_f"
  "examples/45-trace-rule90.6th          rule90_f"
  "examples/46-trace-glider-1d.6th       glider_1d_f"
  "examples/47-trace-atomic-pilot-d.6th  atomic_pilot_d_f"
  "examples/48-trace-atomic-hello.6th    atomic_hello_f"
  "examples/49-trace-pa-ontological-shell.6th  pa_ontological_shell_f"
  "examples/50-trace-pilot-e-phi-pa.6th        pilot_e"
  "examples/51-trace-pilot-f1-transformer.6th  pilot_f1"
  "examples/52-trace-pilot-f2-brain.6th        pilot_f2"
  "examples/53-trace-pilot-f4-colony.6th       pilot_f4"
  "examples/55-trace-composite-distinction.6th composite_distinction"
  "examples/57-trace-mutation-selection.6th    mutation_selection"
  "examples/59-trace-particle-families.6th     particle_families"
)

hash_cmd() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

check_repro () {
    local demo="$1" slug="$2"
    local a="build/figures/${slug}_repro_a.jsonl"
    local b="build/figures/${slug}_repro_b.jsonl"

    for out in "$a" "$b"; do
        racket -l sixth/cli -- run "$demo" \
          | python3 code/render_trace.py /dev/stdin \
              --out /dev/null --jsonl "$out" >/dev/null 2>&1
    done

    # Guard: both JSONLs must exist and be non-empty.  Without this
    # check, a renderer crash on both runs leaves two empty files;
    # hash_cmd returns empty for both, and the equality test would
    # wrongly report "ok (…)" with an empty hash prefix.
    if [ ! -s "$a" ] || [ ! -s "$b" ]; then
        printf "  %-32s MISSING (renderer produced no JSONL)\n" "$slug"
        FAIL=1
        return
    fi

    local ha hb
    ha=$(hash_cmd "$a")
    hb=$(hash_cmd "$b")

    if [ "$ha" = "$hb" ]; then
        printf "  %-32s ok (%s)\n" "$slug" "${ha:0:12}…"
    else
        printf "  %-32s DRIFT\n      run1=%s\n      run2=%s\n" "$slug" "$ha" "$hb"
        FAIL=1
    fi
}

echo "verify-repro: re-running each forensic demo twice, comparing JSONL hash…"
for row in "${DEMOS[@]}"; do
    check_repro $row
done

echo
if [ "$FAIL" -eq 0 ]; then
    printf "%-18s %s\n" "repro status:" "deterministic (19 demos × 2 runs identical)"
    exit 0
else
    printf "%-18s %s\n" "repro status:" "NON-DETERMINISTIC"
    exit 1
fi
