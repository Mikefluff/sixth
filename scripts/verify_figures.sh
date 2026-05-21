#!/usr/bin/env bash
# scripts/verify_figures.sh — assert that committed forensic JSONL
# traces match what the .6th demos produce *right now*.
#
# Drift detection: if a demo's source changed without regenerating
# the JSONL, this script catches it and fails non-zero.  Run from
# the repo root or via `make verify-figures`.
#
# JSONL is the canonical reproducibility evidence — deterministic
# text, sorted keys, no timestamps.  PNG/GIF carry matplotlib
# render-time metadata and are intentionally not checked here.

set -u
cd "$(dirname "$0")/.."

mkdir -p build/figures
FAIL=0

# (demo-file, slug) pairs.  Slug must match scripts/forensic.sh.
DEMOS=(
  "examples/55-trace-pilot-d.6th         pilot_d"
  "examples/56-trace-pilot-c.6th         pilot_c"
  "examples/57-trace-split-brain.6th     split_brain"
  "examples/54-long-epoch-growth.6th     long_epoch_growth_f"
  "examples/58-trace-conway-blinker.6th  conway_blinker_f"
  "examples/59-trace-conway-glider.6th   conway_glider_f"
  "examples/60-trace-rule110.6th         rule110_f"
  "examples/61-trace-rule90.6th          rule90_f"
  "examples/62-trace-glider-1d.6th       glider_1d_f"
  "examples/63-trace-atomic-pilot-d.6th  atomic_pilot_d_f"
  "examples/64-trace-atomic-hello.6th    atomic_hello_f"
  "examples/65-trace-pa-ontological-shell.6th  pa_ontological_shell_f"
  "examples/66-trace-pilot-e-phi-pa.6th        pilot_e"
  "examples/67-trace-pilot-f1-transformer.6th  pilot_f1"
  "examples/68-trace-pilot-f2-brain.6th        pilot_f2"
  "examples/69-trace-pilot-f4-colony.6th       pilot_f4"
  "examples/70-trace-composite-distinction.6th composite_distinction"
  "examples/71-trace-mutation-selection.6th    mutation_selection"
  "examples/72-trace-particle-families.6th     particle_families"
  "examples/73-trace-charge-conservation.6th   charge_conservation"
  "examples/74-trace-spontaneous-assembly.6th  spontaneous_assembly"
  "examples/76-trace-particle-interaction.6th  particle_interaction"
  "examples/78-trace-particle-decay.6th        particle_decay"
)

check_one () {
    local demo="$1" slug="$2"
    local committed="docs/figures/${slug}_forensic.jsonl"
    local fresh="build/figures/${slug}_forensic_check.jsonl"

    [ -f "$committed" ] || { printf "  %-32s MISSING committed JSONL\n" "$slug"; FAIL=1; return; }

    racket -l sixth/cli -- run "$demo" > "build/figures/${slug}_trace_check.dot" 2>/dev/null
    python3 code/render_trace.py "build/figures/${slug}_trace_check.dot" \
        --out "build/figures/${slug}_check_throwaway.png" \
        --jsonl "$fresh" >/dev/null 2>&1

    if diff -q "$committed" "$fresh" >/dev/null 2>&1; then
        printf "  %-32s ok\n" "$slug"
    else
        printf "  %-32s STALE (committed differs from fresh)\n" "$slug"
        FAIL=1
    fi
}

echo "verify-figures: comparing committed JSONL to fresh regen…"
for row in "${DEMOS[@]}"; do
    check_one $row
done

echo
if [ "$FAIL" -eq 0 ]; then
    printf "%-18s %s\n" "figures status:" "fresh (all JSONL match)"
    exit 0
else
    printf "%-18s %s\n" "figures status:" "STALE — run 'make forensic-all' and commit"
    exit 1
fi
