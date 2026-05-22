# Demo 128 — Pre-Registered Predictions (cycle 11A)

**Date pre-registered:** 2026-05-22

**Critical commitment:** committed AFTER attestation via
`scripts/attest_prediction.sh`.  Files predictions BEFORE
reference script.  This cycle directly addresses CS-doctor
critique #3 of cycle 10C: phi-integ "regime D" match was
to my hand-derived analytic 303,400, not to an independent
computation — repeating the cycle-8 mistake.

---

## Background (the actual question)

Cycle 10C (commit `539c01f`) measured substrate phi-integ at
n=20, p=10%, M=1000:
- substrate mean: **297,650**
- my analytic (correlation-corrected): 303,400
- regime D fired (substrate matches my analytic within 2%)

**But:** no independent computation of phi-integ on the same
ensemble was performed.  If my analytic is wrong by 5% (and
substrate is wrong by another 5% in the same direction), they
match each other but both differ from truth.  This is exactly
the cycle-8 pattern that cycle 9 retracted.

This cycle introduces independent phi-integ Monte Carlo via
`networkx`.  Falsifies one of three outcomes:

- **Regime D'**: ref matches substrate AND analytic.
  Cycle 10C survives cross-check; substrate truly faithful
  at second-moment level.  My analytic was right.
- **Regime E'**: ref matches substrate but NOT analytic.
  Cycle 10C survives but my analytic was wrong (compensating
  error?  bug in derivation?).  Investigate.
- **Regime F'**: ref matches analytic but NOT substrate.
  Substrate has measurable deviation from true ensemble.
  Cycle 10C RETRACTED.  Substrate-specific anomaly worth
  finding.
- **Regime G'**: ref matches NEITHER.  Investigate everything.

---

## Theoretical setup

For undirected simple G(n=20, p=0.10) via
`networkx.fast_gnp_random_graph` + observer self-loop added:

phi-integ semantics (substrate-equivalent):
```
phi_integ(G, observer):
    NGET[v] := degree(v) for all v   (this is the "NSET OUT" feature load)
    NSUM[observer] := sum(NGET[v] for v in out_neighbours(observer))
    return degree(observer) * 1 * NSUM[observer] * L_max
```

In undirected G(n, p) with observer self-loop:
- out_neighbours(observer) = {observer} ∪ {v : edge (observer, v)}
- degree(observer) = 1 (self-loop) + len(other_neighbours)
- For v ≠ observer: degree(v) = len(neighbours(v)) — no self-loops

This is exactly what substrate computes (with bi-edge = both
directed edges, OUT = directed out-degree).

**Equivalence claim** (to be verified by ref computation):
- substrate OUT(observer) === degree(observer) (with self-loop counted once)
- substrate OUT(v ≠ observer) === degree(v) (no self-loop)
- substrate NSUM(observer) === Σ_{v ∈ out_nbrs(observer)} OUT(v)
- substrate phi-integ === degree(observer) · NSUM(observer) · 10000

If networkx-computed phi-integ matches substrate, equivalence
holds.

---

## Pre-registered regimes (no gap, partition)

`ref_mean` = networkx Monte Carlo mean of phi-integ at n=20,
p=0.10, M=10000, observer = node 0 with explicit self-loop.

Substrate mean (cycle 10C): 297,650.  My analytic: 303,400.

| regime | condition                                                | meaning                                          |
|--------|---------------------------------------------------------|--------------------------------------------------|
| **D'** | |ref - substrate| ≤ 5000 AND |ref - analytic| ≤ 9000   | both match: substrate AND analytic confirmed     |
| **E'** | |ref - substrate| ≤ 5000 AND |ref - analytic| > 9000   | substrate matches ref; my analytic was off       |
| **F'** | |ref - substrate| > 5000 AND |ref - analytic| ≤ 9000   | substrate DEVIATES from ref; analytic was right; cycle 10C retract |
| **G'** | both diffs > thresholds                                  | neither matches; investigate both                |

Threshold 5000 for substrate (≈ 0.5 substrate-SEM at M=1000 =
9737; conservative since reference is at M=10000 so SEM ≈ 1000
of its own).  Threshold 9000 for analytic (≈ 3% of magnitude).

### Falsification consequences

- **Regime D'** → cycle 10C STANDS as cross-validated.
  Catalogue gains its first cross-validated non-trivial
  substrate measurement.  My analytic and substrate both
  reflect true classical second-moment ER theory.
- **Regime E'** → cycle 10C STANDS for substrate but
  PREDICTIONS-127.md analytic derivation must be reviewed
  for bug.  Mean estimate methodology needs rework.
- **Regime F'** → cycle 10C **RETRACTED**.  Substrate has
  measurable deviation from true classical phi-integ.
  This would be the FIRST genuinely substrate-specific
  finding (substrate diverges from independent classical).
  Investigate cause: bi-edge semantics?  observer self-loop?
  feature-load order?  LCG-RNG correlation?
- **Regime G'** → confusion; cycle 12 detailed analysis.

### Sub-prediction

Ref stddev at M=10000 should be similar magnitude to substrate
stddev (308,074), since both compute same observable on same
distribution.  Sub-pred: ref stddev ∈ [240,000, 380,000].
Substrate stddev was 308,074; tolerance ±20%.

If sub-pred fails: phi-integ variance behaves differently in
networkx vs substrate — RNG implementation difference (LCG
auto-correlation in substrate?) or substrate edge-generation
order effect.

### Author guess (recorded, non-binding)

- **D'**: 55% — both my analytic and substrate are likely
  correct; ref just confirms.
- **E'**: 25% — I may have made an algebra error somewhere
  in PREDICTIONS-127.md derivation; substrate would still
  be correct because it just runs the formula directly.
- **F'**: 15% — substrate may have subtle implementation
  difference from textbook phi-integ.
- **G'**: 5% — bigger problem.

Most informative outcome: **F'** (cycle 10C retract → real
substrate-derived finding).  Most likely: **D'** or **E'**.

---

## Methodological commitments (binding)

1. `scripts/ref_phi_integ_128.py` written AFTER this file
   committed.
2. Reference run AFTER both files committed.
3. Result reported regardless of regime; NO post-hoc adjust.
4. M = 10,000 reference samples, seeds 1..10000 via networkx
   Mersenne Twister.
5. Reference uses `networkx.fast_gnp_random_graph(n=20, p=0.1, seed=s)`
   PLUS adds `g.add_edge(0, 0)` (self-loop on node 0).
6. phi-integ computation: `g.degree(0) * sum(g.degree(v) for v in g.neighbors(0)) * 10000`
   (graph is undirected; degree includes self-loop double-count
   convention per networkx).
7. **IMPORTANT**: undirected networkx `degree(0)` counts self-
   loop as 2 (one for each endpoint).  Substrate counts it as
   1 (single directed self-loop edge).  Reference must handle
   this discrepancy explicitly.  If left unhandled, ref will
   over-estimate by factor ~2 due to self-loop double-counting.
8. Attestation: this file run through `attest_prediction.sh`
   BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file committed before reference script
- [x] Rule 2: literature — phi-integ on bare ER is classical
      graph statistic; reference is direct numerical computation
      of same observable, no asymptotic assumption.
- [x] Rule 3: M=10000 for reference (10× substrate's M=1000)
- [x] Rule 4: regimes D'/E'/F'/G' partition without gap
- [x] Rule 5: this IS the cross-validation cycle for 10C
- [x] Rule 6: aggregate count to be updated post-measurement
- [x] Rule 7: ref vs substrate is a real comparison (different
      implementations), not a tautology
- [x] Rule 8: scope claim is exactly n=20, p=10%, observer-with-
      self-loop
- [x] Rule 9: attest before commit
