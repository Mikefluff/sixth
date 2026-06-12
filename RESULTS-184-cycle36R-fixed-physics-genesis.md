# RESULTS-184 — Cycle 36R: Fixed-Physics Genesis Runs (CORRECTED)

Pre-reg: `examples/PREDICTIONS-184-cycle36R-fixed-physics-genesis.md`
Demo: `examples/191-cycle36R-fixed-physics-genesis.6th`
Workload: `stdlib/harness/seeded-workload.6th` (frozen, 3 seeds)

> **CORRECTION NOTICE (2026-06-12).** The first version of this
> document reported "universal no-promote" (0/0 on all seeds) and
> classified it as outcome #3 ("physics too hostile / insufficient
> stimulus").  An audit traced that result to a missing
> `use manifest` in demo 191: held-out substrate words were absent
> from the dictionary, HELD-OUT-EVAL silently absorbed the
> infrastructure error as 0/6 wins, PROMOTE-STABLE quietly returned
> a rejection symbol the workload dropped, and every cand stalled
> at `'committed` — a status invisible to both metrics AND to epoch
> metabolism.  **The finding was an infrastructure bug masquerading
> as a scientific null result.**  The engine has been hardened
> (heldout substrate pre-check now raises) and the demo fixed.
> Corrected results below.

---

## Setup

Three structurally-different starting conditions ("seeds") under
the **same fixed canon rule-set** (cycle 25-33 baseline, no
profile switching):

| seed | shape | use density | epochs |
|------|-------|-------------|--------|
| 1 | L=2 dense (MARK drop × 6) + saturated coupling | high | 3 productive |
| 2 | L=3 (MARK MARK bi-edge) high frequency | high | 3 productive |
| 3 | L=2 sparse: minimal use above coupling, then idle | low → zero | 3 idle |

Full canon lifecycle per seed: INDUCE-RUNTIME → COMMIT-PRIMITIVE →
HELD-OUT-EVAL → PROMOTE-STABLE → NEW-EPOCH metabolism.

## Corrected results

| seed | promoted | decomposed | outcome |
|------|----------|------------|---------|
| 1 — dense L=2  | **1** | 0 | survives |
| 2 — L=3 freq   | **1** | 0 | survives |
| 3 — sparse L=2 | 0 | **1** | decays |

Determinism (NEG-1): seed 1 re-run → identical 1/0.

## Forensic finding — outcome #1: CONVERGENT SHAPES

**The canon's fixed physics works.** Productive motifs survive
regardless of shape (L=2 and L=3 both promote when sustained);
the sparse-then-idle seed is correctly decomposed by the
inflation/carry/momentum metabolism.  The physics discriminates
on PRODUCTIVITY, not on shape — exactly the property a selection
environment should have.

This retroactively validates the cycle 36R pivot premise: base
criteria (equivalence, energy, time, transfer, decay, memory,
canon boundary) as fixed physics are sufficient to channel
evolution.  No hand-authored selection-profile alternatives are
needed at this stage — the deprecated cycle 36 selector-arena
question ("which selection law is best?") remains correctly
deferred.

## Methodological lesson (the real finding of this cycle)

The original false null-result was produced by **two stacked
silent-absorption layers**:

1. `HELD-OUT-EVAL` treated "substrate words not loaded"
   (infrastructure absence) identically to "cand failed on
   substrate" (scientific signal) — per-substrate exception
   handler returned 0 wins for both.
2. `'committed` is outside `ACTIVE-METAB-STATUSES`: a cand whose
   promotion silently failed neither survives nor decays — it
   becomes invisible to every downstream metric.

A pipeline that can fail silently at an infrastructure level
WILL eventually report an infrastructure failure as a scientific
finding.  Hardening applied:

- HELD-OUT-EVAL now pre-checks all six substrate words BEFORE the
  evaluation loop and raises with an explicit "infrastructure
  absence is not a cand failure" error (tier1.rkt).
- Demo 147 (cycle 26 era) was found to depend on the old silent
  behavior ("HELD-OUT stub returns 0") — updated to load the
  manifest and assert the real 6/6 result.
- `'rolled-back` removed from the decomposed metric in
  RUN-GENESIS-SEED (discovery-time rejection ≠ metabolism decay).

Open hardening candidate (deferred, would need pre-reg since it
touches canon semantics): make `'committed` visible to epoch
metabolism so that a stalled promotion pipeline decays instead of
persisting invisibly.

## NEG coverage (cycle 36R) — all 6 covered

| NEG | spec | covered |
|-----|------|---------|
| NEG-1 seed determinism | demo 191: seed 1 twice → identical 1/0 | ✓ |
| NEG-2 seed independence | BOOTSTRAP-RESET between runs | ✓ |
| NEG-3 canon preservation | regression 2305/2305 ✓ | ✓ |
| NEG-4 no new canon primitive | RUN-GENESIS-SEED is inspection-op only | ✓ |
| NEG-5 forensic completeness | `_ledger` event stream + frozen metric computation | ✓ |
| NEG-6 no selector profile path | RUN-GENESIS-SEED takes no profile-sym; always BASELINE | ✓ |

## Cycle 36R status — CLOSED (corrected)

Regression: 2305 / 2305 ✓ across 180 demos.

## Next cycle direction (informational)

With outcome #1 established, the productive next questions are
about ENRICHING the evolution surface, not about selection laws:

- Longer runs: do promoted cands COMPOSE (cand built from cand)?
  Cycle 32 observed-deps machinery exists; nothing yet exercises
  multi-generation composition under blind workloads.
- Wider motif space: seeds that mix several competing motifs in
  one run — does the metabolism arbitrate between them correctly?
- The `'committed` metabolism gap (above) as a pre-reg'd canon
  amendment.

Selector-law alternatives remain off the roadmap.
