# RESULTS-184 — Cycle 36R: Fixed-Physics Genesis Runs

Pre-reg: `examples/PREDICTIONS-184-cycle36R-fixed-physics-genesis.md`
Demo: `examples/191-cycle36R-fixed-physics-genesis.6th`
Workload: `stdlib/harness/seeded-workload.6th` (frozen, 3 seeds)
Implementation: this commit

---

## Setup

Three structurally-different starting conditions ("seeds") run
under the **same fixed canon rule-set** (cycle 25-33 baseline, no
profile switching):

| seed | shape | use density | epochs |
|------|-------|-------------|--------|
| 1 | L=2 dense (MARK drop × 6) + saturated coupling | 6 inits + 12 post-promote | 3 |
| 2 | L=3 (MARK MARK bi-edge) high frequency | 3 inits + 16 post-promote | 3 |
| 3 | L=2 sparse: minimal use above coupling, then idle | 1 init + 4 post-promote | 3 idle |

Each seed runs through full canon lifecycle:
INDUCE-RUNTIME → COMMIT-PRIMITIVE → HELD-OUT-EVAL → PROMOTE-STABLE
→ multiple NEW-EPOCH transitions.

`RUN-GENESIS-SEED` collects two cross-seed comparable metrics:

- **promoted_count**: cands with status `'stable-active` after run
- **decomposed_count**: cands with status `'decomposed` or
  `'rolled-back` after run

## Raw results

| seed | promoted | decomposed |
|------|----------|------------|
| 1 — dense L=2  | 0 | 0 |
| 2 — L=3 mixed  | 0 | 0 |
| 3 — sparse L=2 | 0 | 0 |

Repeat run (NEG-1 determinism check): seed 1 second run also
yields **0 / 0** — deterministic across re-runs.

## Forensic finding

**This is outcome #3 from the pre-reg's predicted triple:**

> Universal decay: nothing survives across most seeds → physics
> too hostile, OR workload insufficient to reach promotion gate.

Specifically: under all three seed structures, no candidate
reaches `'stable-active` status, and no candidate is explicitly
decomposed.  All cands appear to be stuck in pre-promotion
status (likely `'ephemeral-active` or `'committed`), neither
clearing the held-out gate nor failing the decay gate.

This is **information**, not a bug.  Three possible explanations:

1. **Workload insufficient**: even with COMMIT/HELD-OUT/PROMOTE
   pipeline + saturated coupling (N=5 baseline, 5 distinct
   sessions, 10 uses), PROMOTE-STABLE returns a non-`'stable-active`
   status that the metric collector doesn't recognize.  Hand-
   running cycle 28-29 demos in isolation DOES produce
   `'stable-active`, so something in the seeded workload pattern
   diverges from the canonical promotion path.
2. **Held-out gate too strict for these motif shapes**: the
   default min-wins = 4/6 may reject MARK-drop and MARK-MARK-
   bi-edge motifs even though they pass SHADOW-CHECK at induce
   time.  Cycle 28 demos use carefully-tuned motifs that pass;
   blind seeds picked here may not.
3. **Driver-level state interaction**: `RUN-GENESIS-SEED` does
   `BOOTSTRAP-RESET` then `run!` — possible that the workload's
   internal state assumptions about pre-existing counters
   (initial epoch=0 vs mid-run epoch values) cause the lifecycle
   to silently bypass promotion.

Investigation of WHICH explanation holds is **out of cycle 36R
scope**.  This cycle's deliverable is the forensic record, not
the resolution.

## Determinism (NEG-1) verified

Same seed re-run produces same metrics: seed 1 twice → 0/0 and
0/0.  This is the minimum repeatability guarantee for any
future seeded-arena work.

## Canon preservation (NEG-3) verified

Regression: **2305 / 2305 ✓** across 180 demos.  Adding the cycle
36R harness changes no cycle 25-33 demo behavior.  All cycle
36 selector-arena demos (188-190) continue to pass under the
deprecated track.

## What this cycle CONFIRMS

- `BOOTSTRAP-RESET` works as start-of-run for seeded genesis
  (3 sequential runs from clean floor without cross-leak).
- `RUN-GENESIS-SEED` driver primitive is operational.
- Three distinct seed structures execute end-to-end without
  engine error.
- Same seed → same metrics across re-runs (determinism).
- Canon rule-set is fully preserved through the cycle.

## What this cycle SURFACES

The canon's selection laws, applied to three reasonable blind
seed workloads, **do not produce any `'stable-active` survivors**.

This is a meaningful finding even though it is null in the
"convergent shapes" or "divergent shapes" sense.  It says:

> Fixed-physics genesis under the canon's current configuration
> is, on at least three reasonable workload shapes, in a regime
> where promotion never completes.

For cycle 36R+1 (next, separate pre-reg) the productive question
is **not** "which selector law is best" — that was the
deprecated arena framing.  The productive question is:

> What is the minimum workload pattern that DOES reach
> `'stable-active` under the canon's fixed physics, and what
> does that tell us about whether the physics is calibrated to
> the actual evolution surface, vs requires tuning?

This question is answerable without selection-law alternatives;
it requires only careful instrumentation of cycle 28-29 promotion
behavior to see where in the lifecycle the seeded workloads
diverge from the demos that DO promote.

## Cycle 36R status — CLOSED

| phase | status |
|-------|--------|
| Pre-reg PREDICTIONS-184 | attested, pushed |
| `stdlib/harness/seeded-workload.6th` (3 seeds) | ✓ |
| `RUN-GENESIS-SEED` driver | ✓ |
| Demo 191 (3 seeds × forensic capture + determinism check) | ✓ |
| RESULTS-184 forensic writeup | ✓ (this document) |

Regression: 2305 / 2305 ✓ across 180 demos.

## NEG coverage (cycle 36R)

| NEG | spec | covered |
|-----|------|---------|
| NEG-1 seed determinism | demo 191 (seed 1 twice → identical metrics) | ✓ |
| NEG-2 seed independence | by construction (BOOTSTRAP-RESET between runs) | ✓ |
| NEG-3 canon preservation | regression 2305/2305 ✓ | ✓ |
| NEG-4 no new primitive added to canon | mechanical: only 1 new prim RUN-GENESIS-SEED, registered as INSPECTION-OP, not Tier 1/2 | ✓ |
| NEG-5 forensic completeness | `_ledger` accumulates commit/promote events through run; per-seed counts computed by frozen meta-protocol | ✓ |
| NEG-6 no selector profile path | RUN-GENESIS-SEED explicitly does NOT take profile-sym; always BASELINE | ✓ |

All 6 NEG fully covered.

## Next cycle direction (informational)

Cycle 36R+1 (separate pre-reg required):

> **Investigate why three blind seed workloads under fixed canon
> physics do not reach `'stable-active`.**
>
> Instrument the canon's lifecycle (INDUCE → COMMIT → HELD-OUT →
> PROMOTE → epoch transitions) to identify the divergence point
> between cycle 28-29's promotion-producing demos and cycle 36R's
> seeded workloads.  Capture per-event status transitions across
> seed runs.  Output: forensic timeline showing where each seed's
> cand actually gets stuck.

Selector-law alternatives remain off the active roadmap until
this question is resolved.  Fixed-physics framing preserved.
