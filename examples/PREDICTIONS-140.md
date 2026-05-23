# Demo 140 — Pre-Registered Predictions (cycle 21)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Motivation (user reframe 2026-05-22)

Cycles 19/20 confirmed substrate L-monotonic in strong sense (REGIME
AA per cycle 19, AA' per cycle 20).  But that only validates the
SEARCH side: substrate dynamics CAN minimize a unique-row-count
loss when given enough thermal access.  It does NOT validate L as a
substrate-of-cognition loss.

User reframe: substrate-of-cognition needs BOTH compression AND
prediction.  Pure MDL groups can be degenerate (e.g. cycle 20's
cycle_n10 collapsed L 10→1, single group, zero predictive content).

Operational hypothesis:
> Objecthood = compression-stable AND prediction-useful grouping.

This cycle tests whether MDL-discovered groups predict substrate
dynamics better than baseline groupings AT THE SAME GROUP COUNT.

---

## Setup (pre-committed)

### Inputs

Same 6 substrates as cycles 19/20 (frozen reference):
1. ER(n=10, p=0.30) seed 1
2. ER(n=20, p=0.20) seed 2
3. ER(n=15, p=0.40) seed 3
4. Path n=10
5. Cycle n=10
6. ER(n=15, p=0.25) seed 4

### Groupings

For each substrate with initial adjacency A_init:

1. **G_substrate** — run STEP-CA-MIN-STRONG (cycle 20 algorithm,
   identical hyperparams: T=200, T0=2.0, alpha=0.95, 2-edge sample
   200, seed=42) → A_final.  G_substrate = equivalence classes of
   identical row-vectors in A_final.  K = |G_substrate|.

2. **G_random** — random partition of n nodes into exactly K groups
   (seed=137 fixed pre-commit).

3. **G_degree** — sort nodes by out-degree of A_init, slice into K
   contiguous quantile bins (ties broken by node id).

### Prediction task

For each grouping G:
- Initial activation a_0 ∈ R^n = out-degree sequence of A_init,
  normalized to unit L2.
- True trajectory: a_{t+1} = normalize(A_init · a_t), T_pred=20 steps.
- Group projection: ā_t[i] = mean(a_t[j] for j in group(i)).
- Predicted trajectory: â_{t+1} = normalize(A_init · ā_t),
  starting from a_0.
- Per-step error: e_t = ||â_t - a_t||² / max(eps, ||a_t||²).
- Mean error per grouping: PredError(G) = mean(e_t) over t=1..T_pred.

### Aggregate metric

For each substrate s:
- delta_random(s) = PredError(G_random) - PredError(G_substrate)
- delta_degree(s) = PredError(G_degree) - PredError(G_substrate)
- Positive delta ⇒ substrate predicts better.

If K = 1 for substrate s (degenerate L=1 attractor), all three
groupings collapse to single-cluster mean → identical PredError.
Such cases count as TIE (delta = 0).

---

## Pre-registered regimes (no gap, partition)

| regime | condition | meaning |
|--------|-----------|---------|
| **AAA** | substrate strictly beats BOTH random AND degree on ≥5/6 (after ties) AND mean(delta_random) > 0.05 AND mean(delta_degree) > 0.05 | MDL groups ARE predictive — pure compression already discovers dynamics-respecting structure.  Cycle 22 would still need prediction term but as enhancement, not necessity. |
| **BBB** | substrate beats both baselines on 3-4/6 OR mean(delta) ∈ [0.01, 0.05] | mixed: MDL groups partially predict; need explicit prediction term in L. |
| **CCC** | substrate beats baselines on ≤2/6 AND mean(delta) < 0.01 OR negative | pure MDL groups DO NOT predict — user hypothesis confirmed: need L_combined = MDL + λ·prediction.  Most informative outcome; directly motivates cycle 22 combined loss. |

### Special note on TIE cases

cycle_n10 collapsed to K=1 in cycle 20.  Substrate "found"
a degenerate single-class object: zero predictive structure.
This is itself a finding: MDL with strong search can over-compress.
Recorded but excluded from comparison (TIE counted neither for
nor against).

### Author guess (non-binding, honest)

- AAA: **20%** — would mean MDL alone is enough; surprising
- BBB: **30%** — most likely; some MDL groups will respect dynamics
- CCC: **50%** — strong prior; the cycle_n10 degeneracy is suggestive
  that pure MDL favors compression at expense of predictive structure

**MOST INFORMATIVE OUTCOME: CCC.**  CCC directly tells us the
combined loss `L = MDL + λ·pred_error` is necessary, not just nice.
This is the operationalization of the user's roadmap claim:
"objecthood = compression-stable AND prediction-useful, not just
compression-stable."

---

## Falsification consequences

- **AAA** → MDL groups are already predictive.  User hypothesis is
  weakened: prediction term in L would be redundant.  Cycle 22 would
  pivot to test Information Bottleneck (compression with relevance
  constraint) for a sharper distinction.
- **BBB** → mixed; cycle 22 implements combined L = MDL + λ·pred_error
  with grid search over λ ∈ {0.1, 1, 10}, tests if combined loss
  beats both pure MDL and pure prediction baselines.
- **CCC** → user hypothesis CONFIRMED.  MDL alone is structural
  noise.  Cycle 22 implements combined L explicitly and re-tests
  on same 6 substrates.  Validates the 7-track research program:
  each loss family must be tested in isolation BEFORE composition.

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. Same 6 substrates as cycles 19/20 exactly; no re-selection.
5. STEP-CA-MIN-STRONG hyperparams identical to cycle 20 (frozen).
6. PredError on A_init (NOT A_final) — substrate dynamics being
   predicted are the ORIGINAL substrate's, not the L-min product.
7. K = |G_substrate| determined by substrate, baselines USE this K.
8. Random partition seed = 137 fixed pre-commit.
9. T_pred = 20 fixed; no early-stopping.
10. No tuning of any hyperparam after first run.
11. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: Tishby-Pereira-Bialek (1999) Information Bottleneck
      `physics/0004057`; LeCun et al. (2006) "A Tutorial on
      Energy-Based Learning"; Bengio GFlowNet (2021); Rissanen (1978)
      MDL; user reframe 2026-05-22
- [x] Rule 3: deterministic given fixed seeds; single run per substrate
- [x] Rule 4: AAA/BBB/CCC partition without gap
- [x] Rule 5: same substrate set as cycles 19/20
- [x] Rule 6: aggregate counter update post-result
- [x] Rule 7: AAA / CCC are sharply distinct; substrate could fail
      to beat random baseline → falsifiable
- [x] Rule 8: scope = 6 substrates, K = |G_substrate|, T_pred=20,
      L2-normalized activations
- [x] Rule 9: attestation pending

## References

- Cycle 19 (commit 5d6725a), Cycle 20 (commit d37aea1) — frozen
  reference; same 6 substrates, same STRONG hyperparams
- Tishby-Pereira-Bialek (1999) — Information Bottleneck
- Rissanen (1978) — Minimum Description Length
- LeCun et al. (2006) — Energy-Based Learning tutorial
- Bengio (2021) — GFlowNet
- User insight (2026-05-22) — objecthood = MDL + prediction
