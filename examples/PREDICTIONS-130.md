# Demo 130 — Pre-Registered Predictions (cycle 11B)

**Date pre-registered:** 2026-05-22

**Critical commitment:** committed AFTER attestation per Rule 9.
This is the first PREDICTIONS-N.md authored under the active
pre-commit hook (installed 2026-05-22, commit `a86686d`); the
hook enforces this file passes Rules 2/4/9 before commit lands.

---

## Why this cycle (closes critique #4 from cycle 10 retrospective)

CS-doctor critique #4 (cycle 10 retrospective): catalogue has
**zero substrate-derived findings beyond classical theory**.
All cycle 1-10 "findings" are conformance tests confirming
substrate ≡ classical graph implementation.

To produce a finding that's GENUINELY substrate-derived (could
not be matched by trivial networkx replication), we need:
1. A measure defined naturally in substrate primitives
   (here: phi-integ under STEP-CA-like iterated NSUM)
2. A prediction derived from substrate-axiomatic structure
   (here: iterated NSUM converges to leading-eigenvector scaling
   per Pointer Architecture's "feature integration" axiom)
3. A falsifiable outcome that disconfirms substrate axioms
   if measurement diverges

Cycle 11B does this with **iterated NSUM dynamics on ER substrate**:
- Initialize NGET = 1 for all nodes (uniform feature)
- Apply NSUM-update rule: NSET each v ← NSUM(v) at step t
- Measure phi-integ(observer = 1) at t = 0, 1, 2

This is direct application of substrate's NSET/NSUM primitives;
networkx has no single-call equivalent (must hand-build).
The DYNAMIC is substrate-native (iterated feature propagation);
the PREDICTION uses both classical spectral theory AND a
substrate-axiomatic claim.

---

## Theoretical setup

Substrate: undirected ER G(n=20, p=0.10) with bi-edges, observer
self-loop on node 1, ALL nodes additionally given self-loops
(so feature self-propagation works for every node, not only
observer).

Iterated update rule R:
```
At each step t:
  for each node v:
    new_feature(v) = NSUM(v) at step t   = Σ_{u ∈ out_nbrs(v)} old_feature(u)
```

Initial condition: every NGET = 1.

This is **matrix power iteration**: feature vector x evolves
as x_{t+1} = A x_t where A is substrate's adjacency matrix
(directed, with bi-edges as A_{ij}=A_{ji}=1).

### Classical spectral prediction

Adjacency matrix A is real symmetric (bi-edges make it
symmetric in undirected ER) plus diagonal 1s (self-loops).

Let λ₁ = largest eigenvalue of A.

After t iterations, leading eigenvector v_1 dominates:
  x_t ≈ λ₁^t · v_1   (asymptotically, t → ∞)

For ER G(n=20, p=0.10) with self-loops on all 20 nodes,
adjacency matrix has diagonal 1s + bi-edges with prob 0.10
elsewhere.

E[degree] = 1 (self-loop) + (n-1)p = 2.9.
For ER random graphs near np = 2, leading eigenvalue
λ₁ ≈ max(d_max, √(np)) per Krivelevich-Sudakov (2003).

In our setup: d_max for n=20, p=0.10 typically 5-7;
√(np) ≈ 1.41.  So λ₁ ≈ 5-7.

**Spectral prediction**: phi-integ at t=1 / phi-integ at t=0
≈ E[λ₁] for ensemble at t=0.

At t=0: NGET = 1 everywhere.  NSUM(1) = OUT(1) = degree of
observer.  phi-integ(1) = OUT(1) · NSUM(1) · L_max = OUT(1)² · L_max.

E[phi-integ at t=0] = E[OUT(1)²] · L_max
                    = (Var(OUT(1)) + E[OUT(1)]²) · L_max
                    = (1.71 + 8.41) · 10000  (per PREDICTIONS-127.md)
                    = 101,200

At t=1: NGET = OUT.  phi-integ as in cycle 10C / 11A.
E[phi-integ at t=1] (ref M=10000) = 310,577.

Ratio prediction t=1/t=0 = 310577/101200 ≈ **3.07**.

This ratio equals roughly E[OUT(v) · OUT(O)] / E[OUT(O)²] where
v is random out-neighbour — connected to spectral structure
but not identically equal.

At t=2: harder analytically.  By spectral argument, ratio
t=2/t=1 should approach λ₁ as t grows.

### Substrate-axiomatic prediction

Pointer Architecture v9.0 (per SUBSTRATE.md / preprint) posits
substrate features compose via NSUM/NSET to form integrative
representations.  The axiom relevant here:

> **PA Axiom of Feature Integration (informal):** under
> iterated NSUM-update with all self-loops present, substrate
> features converge to a fixed point proportional to the
> leading eigenvector of the adjacency-with-self-loops matrix.

If this axiom holds, ratios x_{t+1}(v) / x_t(v) → λ₁ for all
v as t → ∞.

Concrete prediction for cycle 11B: at t=2 the ratio
phi-integ(1) at t=2 / phi-integ(1) at t=1 should approach
λ₁ — but NOT yet converged (2 iterations is too few).

I predict:
  ratio(t=1/t=0) = ~3.07  (classical analytic)
  ratio(t=2/t=1) ∈ [4.0, 8.0]  (approaching λ₁ but not yet)

### Combining: substrate-axiomatic falsification

The axiom predicts MONOTONE convergence: ratio(t+1/t) is
non-decreasing toward λ₁.  If substrate violates monotonicity
(ratio drops between consecutive iterations), the axiom is
falsified.

---

## Pre-registered regimes (no gap, partition)

Three substrate observables to measure:
- `phi_t0` — phi-integ(1) at t=0 (NGET = 1 initial)
- `phi_t1` — phi-integ(1) at t=1 (NGET = OUT after one update)
- `phi_t2` — phi-integ(1) at t=2 (NGET = NSUM after two updates)

Ratios:
- `r10 = phi_t1 / phi_t0`
- `r21 = phi_t2 / phi_t1`

Single-run measurement at single seed (M=1, K=1) for proof-of-
concept; ensemble at M=20 × K=5 = 100 graphs for stable
statistics.

| regime | condition | meaning |
|--------|-----------|---------|
| **K**  | r10 ∈ [250, 380] AND r21 ≥ r10 | **Axiom HOLDS**: monotone non-decreasing ratios, both within spectral expectation.  Substrate-derived dynamics validated against substrate axiom. |
| **L**  | r10 ∈ [250, 380] AND r21 < r10 | Axiom VIOLATED: ratio drops at t=2.  Substrate dynamics non-monotone — substrate axiom of feature integration is FALSIFIED.  Real substrate-specific finding (in opposite direction to expected). |
| **M**  | r10 ∉ [250, 380] | Setup error or different scaling — investigate.  Cycle 12 deep dive. |

Note: ratios `r10` and `r21` are scaled by 100 to fit integer
arithmetic.  Pre-reg bounds: r10 in [250, 380] means actual
ratio in [2.5, 3.8], encompassing my analytic 3.07 ± 25%.

### Falsification consequences

- **Regime K** → substrate validates substrate-axiomatic
  prediction (monotone convergence to leading eigenvector).
  This is the FIRST substrate-derived finding that uses a
  substrate-axiomatic prediction, not just a classical theory
  prediction.
- **Regime L** → substrate FALSIFIES the axiomatic prediction.
  Substrate dynamics differ from leading-eigenvector evolution.
  This is ALSO a real substrate-derived finding — a NEGATIVE
  one but informative.  Pointer Architecture's "feature
  integration" axiom needs revision.
- **Regime M** → ratio scaling unexpected; setup issue or
  substrate has different dynamics altogether.  Cycle 12.

Either K or L is publishable.

### Author guess (non-binding)

- Regime K (axiom holds, monotone non-decreasing): **60%**
- Regime L (axiom falsified, non-monotone): **25%**
- Regime M (setup off): **15%** — first time running iterated
  NSUM at ensemble scale; subtle bugs possible.

Most informative outcome: **L** (substrate-axiom falsification).
Most likely: **K**.

---

## Methodological commitments (binding)

1. `examples/130-iterated-nsum-dynamics.6th` written AFTER
   this file committed.
2. Demo run AFTER both files committed.
3. Result reported regardless of regime.
4. M=20 × K=5 = 100 graphs per ratio measurement.
5. Iteration uses STEP-CA-style commit: compute all new
   features from OLD features at each step (no serial bias);
   substrate primitive STEP-CA implements this two-phase
   commit — use it.
6. Attestation via attest_prediction.sh BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: lit citations — Krivelevich-Sudakov (2003) on
      spectral properties of ER random graphs;
      Newman *Networks* (2018) §13.4 on degree-degree.
- [x] Rule 3: M=100 samples per ratio.  Smaller than M=1000
      because **3 measurements per sample** (t=0, t=1, t=2 each
      require graph rebuild) so compute cost is 3× per graph.
      Noted in commit if precision insufficient.
- [x] Rule 4: regimes K/L/M partition without gap (boundaries
      adjacent, M = "everything outside K/L's r10 bound")
- [x] Rule 5: this is FIRST measurement of iterated-NSUM
      dynamics; future cycle re-validates at higher M
- [x] Rule 6: aggregate update post-measurement
- [x] Rule 7: ratio r21 / r10 monotonicity is NOT a tautology;
      depends on substrate dynamic implementation — could go
      either way.
- [x] Rule 8: scope n=20, p=10%, all-self-loops, observer=1
- [x] Rule 9: attest before commit
