# RESULTS-183 — Cycle 36D 5-profile blind arena comparison

Pre-reg: `examples/PREDICTIONS-182-selection-law-scaffold.md`
Implementation: cycles `81e772e..` through this commit
Demo: `examples/190-arena-5-profile-comparison.6th`
Workload: `stdlib/harness/blind-arena-workload.6th` (frozen)

---

## NOTE — track deprecated 2026-05-25

User direction after this writeup: selector-arena framing was
**over-engineered**.  Comparing constitutions before observing
whether ANY fixed physics produces durable evolution is premature.

**Selector-arena track is DEPRECATED for active development.**

Preserved for reference but OFF the active roadmap:
- SelectionProfile struct + 5 named profiles (A–E)
- PROFILE-SET / PROFILE-RESET-CANON / PROFILE-ACTIVE
- RUN-WORKLOAD-PROFILE
- Hyperparameter routing through `(profile-*)` accessors
- Cycle 37+ amendment protocol (not pursued)

**Preserved as floor for future cycles:**
- BOOTSTRAP-RESET (full empty-state in-place reset)
- BOOTSTRAP-LAW-HASH (canonical fingerprint)
- BOOTSTRAP-EMPTY? / BOOTSTRAP-RESIDUAL
- PREFLIGHT-ARENA / ARENA-IDENTICAL-HASH? (clean-start verification)

New direction: **PREDICTIONS-184 cycle 36R — Fixed-Physics Genesis
Runs.** Single canon rule-set, multiple seeded workloads, observe
what motif shapes survive across seeds.  Base criteria
(equivalence, energy, time, transfer, decay, memory, canon
boundary) are physics, not candidates.

The data below stands as forensic record of what the arena
scaffold DID; the framing it operated under is set aside.

---

---

## What this cycle delivers

The 5-profile blind arena comparison runs end-to-end:

1. **Pre-flight gate** asserts `BOOTSTRAP-LAW-HASH(A) == ... ==
   BOOTSTRAP-LAW-HASH(E)` across all 5 profiles after their
   respective `BOOTSTRAP-RESET`.  Pass.
2. **`RUN-WORKLOAD-PROFILE`** runs the frozen blind workload
   under each of the 5 selector profiles in turn, with
   `current-profile` dynamic-extent binding for each run.
3. **Metrics** (`cand_count`, `promoted?`) computed by frozen
   meta-protocol after each run, NOT by the selector.
4. **No promotion**: at no point in the arena does any selector
   amend canon hyperparameters.  Baseline restored after each
   profile run.

## Raw arena results

Single blind workload `blind-arena-workload`:
- Phase 1: induce L=2 motif (MARK drop) via DETECT-MOTIF-AUTO
- Phase 2: 10 cand uses across 5 distinct sessions (saturates
  coupling-N=5 baseline and coupling-N=8 for Profile E)

| profile | label | inflation | N | M | stale | neg-thr | window | cand_count | promoted? |
|---------|-------|-----------|---|---|-------|---------|--------|------------|-----------|
| A | baseline | 1 | 5 | 3 | 1 | 2 | 3 | 1 | 0 |
| B | low-inflation | 0 | 5 | 3 | 1 | 2 | 3 | 1 | 0 |
| C | high-inflation | 3 | 5 | 3 | 1 | 2 | 3 | 1 | 0 |
| D | long-memory | 1 | 5 | 3 | 2 | 3 | 5 | 1 | 0 |
| E | strict-coupling | 1 | 8 | 5 | 1 | 2 | 3 | 1 | 0 |

## Interpretation

`cand_count == 1` for all 5 profiles: the workload induces exactly
one motif (MARK drop) under each selector law.  This is expected
because INDUCE-RUNTIME is independent of inflation/coupling — those
gates affect downstream COMMIT/PROMOTE only.

`promoted? == 0` for all 5 profiles: no cand reached
'stable-active status because the workload does not invoke COMMIT
→ HELD-OUT → PROMOTE chain.  This is by design for the MVP
workload — to keep the demo finite and avoid coupling-rule sub-
case explosions across profiles.

The workload as-currently-defined demonstrates the arena machinery
(pre-flight gate + parameterized run + metric collection + sandbox
boundary) but does not yet exercise the selector-discriminating
gates (inflation, momentum decay, COMMIT/PROMOTE).  A richer
workload that walks the full lifecycle and produces differentiated
metrics across profiles is cycle 37+ work — and requires the
**multi-seed** + **full 10-metric set** scaffolding that is
explicitly out of cycle 36 scope (pre-reg §"What cycle 36 is NOT").

## What this cycle CONFIRMS

- Arena harness mechanically operational end-to-end.
- Pre-flight gate enforces minimal-origin fairness.
- Sandbox boundary prevents profile cross-contamination.
- Metrics computed by frozen meta-protocol (NEG-5 operational).
- No selector promoted to canon (NEG-6 by absence).
- Baseline canon restored after every profile run (NEG-2).

## What this cycle does NOT yet provide

- **Multi-seed runs** (3 seeds per profile).  Workload is single-
  seed (deterministic hand-crafted).  Cycle 37+ needs a seeded
  generator that produces structurally-varied workloads.
- **10 distinct metrics**.  Currently 2 (cand_count, promoted?).
  Full metric set (false-positive rate, time-to-promote, decay
  latency, etc.) needs both the multi-seed generator and per-
  metric formulas defined by the meta-protocol.
- **Discriminating workload**.  Current workload does not exercise
  the inflation / coupling / momentum gates differentially.  A
  workload that runs full COMMIT → HELD-OUT → PROMOTE → decay
  lifecycle under each profile is needed to actually compare
  selector laws on outcomes.

These remain on the **cycle 37+** roadmap.  Per the binding spec
(§"What cycle 36 is NOT"): "Not a selector competition with
promotion logic (that's cycle 37+)."

## Cycle 36 status — FINAL

| phase | status |
|-------|--------|
| 36A pre-reg + 2 patches | attested, pushed |
| 36B step 1-3 (floor) | ✓ |
| 36B step 4 (struct + 5 profiles) | ✓ |
| 36B step 5 (8/9 hyperparameter routing) | ✓ |
| 36B step 7-8 (sandbox mode) | ✓ |
| 36B step 9 (NEG demos: 5 of 8 covered) | ✓ partial |
| 36B step 10-12 (blind workload + RUN-WORKLOAD-PROFILE + pre-flight gate) | ✓ |
| 36C baseline characterization | ✓ RESULTS-182 |
| 36D 5-profile comparison | ✓ RESULTS-183 (this document) |

Regression: 2297 / 2297 ✓ across 179 demos.

## NEG coverage final matrix

| NEG | spec | covered |
|-----|------|---------|
| NEG-1 selector cannot modify meta-protocol | mechanical: selector profile is read-only struct | ✓ |
| NEG-2 sandbox cannot mutate canon | demos 189, 190 (PROFILE-RESET-CANON + dynamic-extent restore) | ✓ |
| NEG-3 selector cannot modify workload mid-run | mechanical: workload is a frozen `: ... ;` word; selector has no edit primitive | ✓ |
| NEG-4 selector cannot read other selectors' state | partial: current-profile dynamic-extent isolates; full proof needs concurrent harness | partial |
| NEG-5 metric computed by frozen meta-protocol | demo 190 (RUN-WORKLOAD-PROFILE computes metrics in Racket, selector never touches metric path) | ✓ |
| NEG-6 amendment out of scope | mechanical: no promote-selector primitive exists; demo 190 verifies baseline restoration | ✓ |
| NEG-7 inherited vocabulary | demo 186 | ✓ |
| NEG-8 asymmetric bootstrap hash | demos 187, 188 | ✓ |

7 of 8 NEG tests fully covered.  NEG-4 partial (full coverage needs
multi-process harness, out of cycle 36 scope).

## Outstanding follow-up (single-line tasks)

- Route `heldout-min-wins` (currently hardcoded 4 in HELD-OUT-EVAL)
  through `(profile-heldout-min-wins)`.
- Workload variants for cycle 37+ that exercise full lifecycle
  under each profile.

## Cycle 36 — closure

Cycle 36 delivered the **operational scaffold for selection-law
comparison without changing any selection law**.  Floor is iron
(BOOTSTRAP-RESET / BOOTSTRAP-LAW-HASH / pre-flight gate); 5
profiles are defined and routable; sandbox isolation works;
metrics are frozen-meta-protocol-computed; no promotion path
exists.

The decision of WHICH selection law to amend (if any), and the
amendment protocol itself, is **cycle 37+** with separate pre-reg.
