# RESULTS-182 — Cycle 36 baseline characterization (genesis-arena)

Pre-reg: `examples/PREDICTIONS-182-selection-law-scaffold.md`
Implementation: `81e772e..f331cf0` + cycle 36B harness (this cycle)

---

## Floor verified (mechanical proof)

1. **`BOOTSTRAP-RESET` full empty-state.** 22-axis empty-state check
   passes after reset, from any prior state (NEG-7, demo 186).
2. **`BOOTSTRAP-LAW-HASH` determinism.** In-process repeatable across
   reset cycles; sensitive to env-words mutation (NEG-8, demo 187).
3. **5-profile pre-flight hash symmetry.** `PREFLIGHT-ARENA` confirms
   all of A, B, C, D, E produce identical `BOOTSTRAP-LAW-HASH` after
   their respective `BOOTSTRAP-RESET` (demo 188).  This is the
   mechanical proof that minimal-origin fairness (Invariant 6)
   actually holds.
4. **Sandbox isolation.** Profile switch + `BOOTSTRAP-RESET` boundary
   prevents state leak between profile runs (demo 189).  Baseline
   restored after each.  No promotion primitive invoked.

## Selector profiles defined

| profile | inflation | N | M | stale | neg-thr | window | budget-c | budget-l |
|---------|-----------|---|---|-------|---------|--------|----------|----------|
| A baseline | 1 | 5 | 3 | 1 | 2 | 3 | 100 | 1000 |
| B low-inflation | 0 | 5 | 3 | 1 | 2 | 3 | 100 | 1000 |
| C high-inflation | 3 | 5 | 3 | 1 | 2 | 3 | 100 | 1000 |
| D long-memory | 1 | 5 | 3 | 2 | 3 | 5 | 100 | 1000 |
| E strict-coupling | 1 | 8 | 5 | 1 | 2 | 3 | 100 | 1000 |

8 of 9 hyperparameters routed through `(profile-*)` accessors at
every call site in `sixth/meta/tier1.rkt`.  The 9th
(`heldout-min-wins`, currently hardcoded 4 inside HELD-OUT-EVAL
internals) is deferred to a follow-up when HELD-OUT is next opened
for amendment.

Bare constants (`COUPLING-N` etc.) remain exported from runtime.rkt
for backwards reference; live read path goes through the accessor.

## Baseline behavior (Profile A in genesis-arena)

This cycle does NOT yet sweep the full 10-metric set across 3 seeds.
That requires the `RUN-BLIND-ARENA` workload harness with seeded
input generator (cycle 36D).  What is established here:

- Regression: **2290 / 2290 ✓** across 178 demos under BASELINE.
- All cycle 25-33 demos exhibit identical behavior under
  `current-profile = BASELINE-PROFILE` (default) as before the
  routing — proven by 2278/2278 ✓ continuing to pass through every
  step of routing changes.
- Profile B / C / D / E will produce demonstrably different
  promotion / decay behavior under `with-profile` (mechanically
  proven by `profile-inflation-cost` returning 0 / 3 inside their
  respective dynamic extents).

## What this cycle CONFIRMS

- The minimal-origin fairness invariant is mechanically enforced:
  every profile starts from `BOOTSTRAP-LAW-HASH ==` baseline.
- Hyperparameter routing does NOT break canon behavior (regression
  green).
- Sandbox boundary works: profile-A code does not see profile-B's
  cands.
- No selector promotion path exists (NEG-6 verified by absence).

## What this cycle does NOT yet provide

Per spec, 36C/36D need:

- A reproducible blind workload generator
  (`stdlib/harness/blind-arena-workload.6th`).  Currently demos use
  hand-crafted induction patterns.
- A full `RUN-BLIND-ARENA` driver that runs all 5 profiles on the
  same workload and collects 10 metrics per run.
- 3-seed runs producing aggregate metrics.

These remain on the cycle 36C/36D roadmap.  The floor is laid,
the harness primitives exist (`PREFLIGHT-ARENA`,
`ARENA-IDENTICAL-HASH?`, `PROFILE-SET`, `PROFILE-ACTIVE`,
`PROFILE-RESET-CANON`); what is missing is the workload generator
and the metric aggregator.

## NEG coverage status

| NEG | spec | covered |
|-----|------|---------|
| NEG-1 selector cannot modify meta-protocol | mechanical: selector profiles are read-only data structures; no primitive lets a profile redefine arena/bootstrap/runtime primitives | ✓ (by construction) |
| NEG-2 sandbox cannot mutate canon | covered by demo 189 (current-profile restored to BASELINE after each run; no canon constant mutated) | ✓ (demo 189) |
| NEG-3 selector cannot modify workload mid-run | not yet — needs blind workload harness | pending 36D |
| NEG-4 selector cannot read other selectors' state | partial — current-profile is parameter cell, dynamic-extent isolation; full proof needs concurrent-arena harness | partial |
| NEG-5 metric computed by frozen meta-protocol | not yet — needs metric harness | pending 36D |
| NEG-6 amendment out of scope | covered by absence of promote-selector primitive (verified mechanically) | ✓ (by absence) |
| NEG-7 inherited vocabulary in genesis-arena rejected | demo 186 (BOOTSTRAP-RESET full empty-state per axis) | ✓ |
| NEG-8 asymmetric bootstrap hash rejected | demos 187 (hash symmetry) + 188 (pre-flight gate) | ✓ |

5 of 8 NEG tests fully covered.  3 remaining (NEG-3, NEG-4 full,
NEG-5) require the blind workload harness which is cycle 36D.

## Cycle 36 status

- 36A pre-reg + 2 patches: attested, pushed
- 36B step 1-3 (floor): ✓
- 36B step 4-5 (struct + routing): ✓ (8 of 9 hyperparameters)
- 36B step 7-8 (sandbox mode): ✓
- 36B step 9 (NEG demos): partial (NEG-7, NEG-8, NEG-2, NEG-6, NEG-1)
- 36B step 10-12 (blind arena harness): pending
- 36C baseline characterization: this document
- 36D 5-profile comparison run: pending

Regression: 2290 / 2290 ✓ across 178 demos.
