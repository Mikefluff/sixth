# Demo 125 — Pre-Registered Predictions (cycle 9)

**Date pre-registered:** 2026-05-22

**Critical commitment:** this file is committed to git BEFORE
the reference script (`scripts/ref_ergraph_125.py`) is written
or run.  Git history proves predictions were derived before
measurement.  Any post-hoc revision must be flagged
`[POST-HOC]` with reason.

---

## Background

Cycle 8 (PREDICTIONS-124.md, commit `b0fcccd` / measurement
`8015c49`) found:

- substrate phi-perc at n=20, p=10% measured **130,900**
- pre-registered classical ER prediction was **108,400**
- deviation **+21%**, OUTSIDE ±15% tight bound

Three candidate explanations were itemised:
1. **Substrate set-semantics correction** — bi-edge + observer
   self-loop alters effective edge distribution.
2. **Formula approximation breaks** at c=(n-1)p=1.9 — the
   `E[|C(v)|] = n·f² + (1-f)/(1-c(1-f))` formula is asymptotic
   (n→∞); near-critical finite-size corrections may inflate.
3. **Genuine substrate-specific correction** to phi-perc
   semantics not captured by either classical theory or
   asymptotic formula.

Cycle 9 distinguishes (1) vs (2) vs (3) using an **independent
reference**: classical undirected G(n,p) Monte Carlo via
`networkx` and Python's Mersenne Twister.  This is not the
substrate; it is the *true* classical reference at finite n.

---

## Theoretical setup

- `networkx.fast_gnp_random_graph(n=20, p=0.10, seed=...)`
  produces simple undirected G(n,p).
- For each graph, compute
  `S = |connected_component(G, node=0)|`.
- Repeat M=1000 times with seeds 1..1000.
- `mean_S` is the **true classical reference** for
  E[|cluster(v)|] at n=20, p=0.10 (Mersenne Twister noise
  at the 1/√1000 ≈ 3% level).
- Multiply by `L_max = 10000` to compare directly with
  substrate phi-perc.

This is the same observable substrate measures — BFS reachable
set from node 0 in an undirected ER graph — computed in an
independent implementation.

---

## Pre-registered predictions

I predict `mean_S × 10000` (gold-standard classical Monte
Carlo) will fall in **exactly one** of three regimes.  Each
regime corresponds to one of the three hypotheses; the
regimes are mutually exclusive and exhaustive within ±1000.

| regime  | range                | supports                          |
|---------|----------------------|-----------------------------------|
| **A**   | 100,000 – 115,000    | H2 inverted: formula was right, substrate deviates ~21% above true classical ⇒ **substrate-specific finding** survives. |
| **B**   | 120,000 – 140,000    | H2 supported: my asymptotic formula under-estimated at near-critical n=20 c=1.9 by 20%-ish; substrate tracks **true** classical fine; the cycle-8 deviation was a *theory-side* error, not a substrate finding. |
| **C**   | other (< 100k or > 140k, or 115k–120k boundary) | unanticipated — investigate further (formula AND substrate both wrong, or RNG/setup mismatch). |

### Quantitative falsification commitments

- If networkx mean_S × 10000 falls in **regime A**: the
  cycle-8 substrate-vs-classical deviation **stands as a
  genuine substrate finding**; cycle 9 confirms substrate
  phi-perc has measurable departure from true classical ER
  at near-critical regime.
- If networkx mean_S × 10000 falls in **regime B**: the
  cycle-8 finding **must be retracted as a theory-side
  error**, not a substrate finding.  Substrate tracks true
  classical to within RNG noise; my hand-derived asymptotic
  formula was the bug.  This would be the third major retract
  in the catalogue (after cycles 4-5 and 7).
- If networkx mean_S × 10000 falls in **regime C**: cycle 9
  is inconclusive; cycle 10 needed for finer analysis (likely
  M=10000 reference, or analytic computation via cluster-size
  generating function at finite n).

### Sub-prediction: 1σ bound

I additionally predict the standard error of mean_S × 10000
(i.e. stddev(S)/√M × 10000) will be ≤ 2000 at M=1000.  If
this bound is violated, the reference is too noisy to
distinguish A/B and we need M ≥ 10000.

### Author guess (BEFORE running)

Subjective probability assessment (not binding, but recorded
for honesty):

- Regime A (substrate deviates from true classical): **35%**
- Regime B (formula was wrong, substrate is fine): **55%**
- Regime C (unanticipated): **10%**

I lean toward regime B because finite-size corrections at
n=20, c=1.9 are known in percolation theory to be large.  But
substrate using bi-edge + LCG RNG + per-sample observer
self-loop could plausibly inflate by 20% in a way classical
ER would not — so A is non-trivial.

---

## Methodological commitments (binding)

1. `scripts/ref_ergraph_125.py` is written AFTER this file is
   committed.  Git timestamp proves order.
2. Script run AFTER both this file and source are committed.
3. Results reported regardless of which regime hits.
4. NO regime boundary adjustment post-hoc.  If a measurement
   lands at 116,500 (between A and B), that's regime C; do
   not redraw boundaries.
5. The script will use Mersenne Twister via networkx seed
   parameter, not substrate LCG.  This is the WHOLE POINT —
   independent RNG implementation.
6. The script will use undirected G(n,p) without observer
   self-loop.  This matches classical theory.  Substrate's
   bi-edge + self-loop is the substrate semantics being
   tested against this reference.

## Connection to RESULTS.md

Cycle 8 (commit `8015c49`) flagged three hypotheses as
"work for cycle 9".  This pre-registration commits cycle 9's
falsifiable test of those hypotheses.  The cycle-9 measurement
section in RESULTS.md will reference THIS file by git hash
and report outcome regardless of direction.

---

## What this cycle CANNOT decide

Even with this reference test, we cannot distinguish:
- Substrate edge multiplicity vs RNG distribution differences
- Whether the substrate "deviation" (if it persists in
  regime A) is from phi-perc's BFS semantics, bi-edge
  semantics, or LCG-RNG sample-path differences.

Distinguishing these requires cycle 10+ (port substrate
algorithm to Python verbatim, compare under Mersenne Twister).
