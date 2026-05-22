# Demo 126 — Pre-Registered Predictions (cycle 10A)

**Date pre-registered:** 2026-05-22

**Critical commitment:** committed to git BEFORE demo 126 source.
Resolves CS-doctor critique #1 from cycle 9 retrospective —
substrate M=100 SEM was too wide (6270) to detect a possible
systematic deviation of size ~4351 from cycle 9 reference.

---

## Background (the actual question)

Cycle 9 (commit `a2f3625`) showed substrate at n=20, p=10%
measured 130,900 ± 6270 (M=100) vs networkx M=10000 reference
126,549 ± 657.  |diff| = 4351 = 0.69 substrate-σ — looks
"within 1σ" but the 1σ is wide because of M=100.

If we run substrate at M=1000 (50 seeds × 20 samples per seed):
- expected SEM ≈ 62707 / sqrt(1000) ≈ **1983**
- if substrate true mean really is 126,549: |diff| should
  shrink to ≈ 0 ± 1983 (within ±1σ_1000)
- if substrate true mean really is 130,900: |diff| stays
  ≈ 4351, which would be |4351|/1983 ≈ **2.19σ** —
  significant departure, real substrate systematic bias

So M=1000 measurement DISCRIMINATES between:
- "substrate faithful, cycle 9 was lucky alignment of M=100 noise"
- "substrate has real ~3% upward bias vs classical, hidden by M=100 noise in cycle 8"

This is the falsifiable test cycle 9 didn't do.

---

## Literature anchor (lit-review rule applied this time)

Classical Erdős-Rényi finite-size corrections:
- Bollobás, *Random Graphs* (2nd ed., 2001), Ch. 6 — near-critical
  giant component fluctuations at n=20 are ~O(n^(2/3)) ≈ 7.4 nodes,
  so single-graph variance ≈ (n^(2/3) × L_max)² and SEM at M=1000
  scales as 1/sqrt(M) — agrees with our 62707/sqrt(1000) estimate.
- Janson, Łuczak, Ruciński, *Random Graphs* (2000), §5 —
  E[|C(v)|] at n=20, p=0.10 has no closed-form, requires Monte
  Carlo or exact recursion.  The asymptotic formula `n·f² +
  (1-f)/(1-c(1-f))` is the n→∞ limit and known to mis-predict
  at finite n in the near-critical region (subleading O(1/n)
  terms unaccounted).
- Newman, Strogatz, Watts (2001) — generating-function approach
  for finite n gives slow convergence near c=1.

Our networkx reference (cycle 9) is itself Monte Carlo at finite n,
so no asymptotic-formula bias.  This is the right reference.

---

## Pre-registered regimes (PARTITION without gap — cycle 9 fix)

Substrate M=1000 mean at n=20, p=10%, call it `m_1000`:

| regime | range                | meaning                                                      |
|--------|----------------------|--------------------------------------------------------------|
| **D**  | [124,500, 128,500]   | **substrate FAITHFUL** within ±1σ_1000 of reference 126,549 |
| **E**  | > 128,500            | substrate has **systematic UPWARD bias** vs classical (~3%) |
| **F**  | < 124,500            | substrate has **systematic DOWNWARD bias** vs classical     |

No gap.  Boundaries set at reference ± 1σ_1000 = 126,549 ± 1983.

### Falsification commitments

- **Regime D** → substrate truly faithful at n=20, p=10%.
  Cycle 9's "faithful" claim survives a real test.  The
  catalogue gains its first cross-validated substrate finding.
- **Regime E** → substrate has measurable systematic deviation
  from classical ER at near-critical regime.  Real positive
  substrate-derived finding.  Investigate cause in cycle 11
  (bi-edge multi-counting?  observer self-loop scope inflation?
  LCG-RNG bias toward correlated samples?).
- **Regime F** → substrate has downward bias, even less likely
  given cycle-8 M=100 mean was above reference.  Would suggest
  LCG-RNG produces fewer connections than MT.

### Sub-prediction (1σ_1000 sanity)

I predict substrate stddev at M=1000 will be within ±10% of
M=100 substrate stddev (62,707).  If stddev shrinks/grows by
>10%, RNG or sampling exhibits autocorrelation between seeds
— need further investigation.

### Author guess (recorded, non-binding)

- Regime D (faithful): **70%** — most likely; cycle 8 deviation
  was probably M=100 noise (4351 of variance is 4351²/62707² ≈
  0.5% of single-sample variance; plausible).
- Regime E (upward bias): **22%** — non-trivial chance; bi-edge
  semantics could plausibly inflate component count.
- Regime F (downward bias): **8%** — unlikely; would require LCG
  to systematically under-sample edges, unusual for Numerical
  Recipes parameters.

---

## Methodological commitments (binding)

1. `examples/126-substrate-m1000.6th` written AFTER this file
   is committed.  Git timestamp proves.
2. Demo run AFTER both this and source committed.
3. Result reported regardless of regime.  Demo pins values.
4. NO regime boundary adjustment post-hoc.
5. Substrate RNG (LCG) and bi-edge semantics unchanged from
   cycle 8 — this is a sample-size sweep, not a substrate change.
6. M=50 seeds × K=20 samples = 1000 total graphs.  Seed range
   1..50 (LCG).  K=20 per seed to amortize seed-setup overhead.
7. If demo takes > 10 minutes wall-clock, halve to M=25 × K=20
   = 500 with note in measurement commit; if > 20 min at M=500,
   abandon and switch to optimised C/Racket loop.

## What this cycle DOES NOT decide

- n=10 ensemble (still missing — separate cycle).
- Other p values at high M (also missing — separate cycle).
- Feature-loaded substrate (cycle 10C target — see PREDICTIONS-127.md).

## Connection to cycle 9 retraction

Cycle 9 retracted cycle 8's deviation claim by showing my formula
was wrong.  Cycle 10A asks the SYMMETRIC question: was substrate
itself wrong?  Cycle 9 left this open (CS-doctor critique #1).
Cycle 10A is the test that closes it.

After cycle 10A, one of:
- regime D: substrate faithful AT THIS REGIME ONLY (n=20, p=10%);
  catalogue claim becomes valid but narrow.
- regime E/F: substrate has measurable deviation; cycle 8 was
  "right for wrong reason" — substrate-specific physics emerges.

Either outcome is publishable; null result honest.
