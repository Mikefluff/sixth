# PREDICTIONS-187 — Cycle 39A: Round-Robin Budget Probe

**Date pre-registered:** 2026-06-12
**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Cycle context

Cycle 38 (RESULTS-186) achieved evolved closure but its scaling
series revealed monoclone replication: ten thousand epochs of
perfectly linear `+16 nodes, +8 edges per epoch` because the
greedy WORLD-TICK budget allocation lets the first binding eat
the entire ration every tick.  The second discovered binding
fires zero times across the run.

Two candidate causes:

- (G) Greedy budget — engineering choice of cycle 37 that
  silently selects which binding gets to act.
- (B) Homogeneous law body — `MARK MARK bi-edge` creates fresh
  disconnected structure every firing, so firings never interfere
  even when many run.

Cycle 39A is a SMALL, FOCUSED PROBE: change exactly one thing —
budget allocation from greedy to round-robin — and observe.  The
probe distinguishes G from B by what the linearity does.

This is deliberately not a feature cycle.  It is a controlled
intervention on a single mechanism to localize a finding.

## Physics change (exactly one)

`WORLD-TICK` semantics:

- **OLD (greedy, cycle 37):** for binding in order, fire until its
  pattern is absent or the budget is spent, then move on.
- **NEW (round-robin):** repeat rounds — in each round, every
  binding gets AT MOST ONE firing attempt (its match-and-dispatch
  if matched, skip if absent), then the next round begins; halt
  when the budget is spent or a full round produced zero firings
  (no work left).

All other cycle 37 honesty mechanics unchanged:
- only `'stable-active` laws fire (status gate)
- dispatch via `try-dispatch-cand!` (honest counters)
- consume happens before dispatch; consumed elements are not
  restored on failure
- `WORLD-TICK-BUDGET = 8`, attempts cap = 32 (4× budget)

## Hypotheses (each a yes/no observable)

- **H1 (single-binding neutrality):** with exactly ONE binding,
  round-robin behaves identically to greedy (the loop degenerates).
  Demos 192, 193 produce identical numbers (status, fired, edges,
  momenta) under either policy.  Their existing asserts must pass
  unchanged.

- **H2 (round-robin enables the dormant binding):** in demo 194,
  the second discovered binding `('path2, cand_001)` now fires.
  Per-tick fired-count for `'path2` is > 0 (specifically: 4 of 8
  if rounds are perfectly balanced).

- **H3 (linearity-source localization):**

  - **H3-G:** if greedy was the linearity cause, the world's
    growth pattern changes qualitatively (non-linear, oscillating,
    or stalling).
  - **H3-B:** if the homogeneous law body was the cause, growth
    stays linear but with DIFFERENT coefficients (`'path2`
    consumes 2 edges and the body still creates 2, so net per
    `'path2` firing is +2 nodes / 0 edges; mixed 4+4 schedule
    predicts +16 nodes / +4 edges per tick).

  H3-G and H3-B are mutually exclusive observables.  The probe
  picks one.

- **H4 (closure survival under round-robin):** the evolved closure
  in demo 194 still survives 3 post-cutoff epochs and the 500-
  epoch long-run still ends `'stable-active`.

## NEG (binding)

- **NEG-1:** demo 192 (single binding) numbers IDENTICAL to
  pre-change.  Any drift = round-robin breaks the degenerate case
  = bug.
- **NEG-2:** demo 193 (single binding) numbers IDENTICAL.
- **NEG-3:** demo 194 closure still holds (NEG-2 of the evolved
  closure claim survives the probe).
- **NEG-4:** regression 2373 ✓ unchanged.
- **NEG-5:** total fired per tick ≤ budget (8) always.
- **NEG-6:** attempts cap still bounds work in pathological
  configurations.

## What this cycle is NOT

- Not a fix for monoclone replication.  At most it MOVES the
  monoclone (different ratio, same mechanism).
- Not a richness-of-dynamics demonstration.  If H3-B holds, this
  probe will have established that the linearity source is the
  law's body, and the answer to richness is multi-law ecosystems
  with non-homogeneous bodies (next cycle).
- Not pattern vocabulary growth.
- Not modification of metabolism.

## What outcome means for cycle 39B+

- If **H3-G**: greedy was structural, round-robin alone unlocks
  richer dynamics → next cycle focuses on (better) scheduling.
- If **H3-B** (anticipated): law body is structural → next cycle
  is multi-law ecosystems with INTERFERING bodies (one creates
  edges that another consumes; a closure economy, not a closure
  monolog).

Either way the probe yields directional clarity at minimal cost.

## PASS / FAIL

PASS: H1, H4 confirmed; H2 confirmed; H3 picks G or B
unambiguously; all NEG observed; regression green.

FAIL: NEG-1/-2 violated (single-binding behaviour changed); or
H4 fails (closure breaks under round-robin without any
explanatory mechanism); or NEG-4 regression breaks.

## Implementation contract

1. `sixth/meta/triggers.rkt`: rewrite `prim-world-tick` body to
   round-robin.  Keep budget and attempts caps.  No other file
   changed.
2. Update demo 194 assert for `'path2` firings if H2 holds (the
   ratio is the finding).  Adjust expected pass count.
3. Long-run probe re-run on `experiments/longrun-scaling.6th`
   under round-robin; numbers recorded in RESULTS-187.
4. RESULTS-187 records which hypothesis held and the implications.

## References

- PREDICTIONS-185 / RESULTS-185 — cycle 37 closure (greedy budget
  in place)
- PREDICTIONS-186 / RESULTS-186 — cycle 38 evolved closure +
  monoclone limitation note
