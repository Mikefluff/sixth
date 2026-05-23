# Demo 138 — Pre-Registered Predictions (cycle 19)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Energetic formulation (user insight, 2026-05-22)

Cycle 18 (commit `ebf40c5`) was STRUCTURAL: matryoshka compression
verified algebraically.  CS-doctor critique (this session): structural
counting is tautology of arithmetic, not substrate physics.

User insight: cycle 19+ should be ENERGETIC.  Substrate evolves
toward configurations minimizing a loss function L; this L IS what
the universe minimizes (per convergence of FEP, Jaynes, EBM, MDL,
Wolfram causal invariance).

This cycle pre-registers a specific L (Minimum Description Length
flavor) and tests if Sixth substrate dynamics minimize it.

---

## Loss function definition (pre-committed)

```
L(state) = |{ unique out-neighbor pattern across nodes }|
         = number of distinct row-vectors in adjacency matrix
```

Concretely: for substrate state with n nodes and adjacency matrix
A ∈ {0,1}^(n×n), L(state) = number of distinct rows of A.

- Minimum: L = 1 (all nodes have identical out-neighbors)
- Maximum: L = n (every node has unique out-neighbor pattern)

**Connection to MDL**: states with low L can be matryoshka-encoded
shorter (group nodes with identical patterns, store pattern once).
State with L=1 has trivial description (one pattern × n nodes).

**Connection to substrate-of-cognition**: nodes with identical
out-neighbor patterns are FUNCTIONALLY EQUIVALENT.  Substrate
converging to low L means substrate is finding functional
equivalence classes — perception of "objects" as equivalence.

---

## STEP-CA-MIN dynamics (pre-committed)

At each step:
1. Enumerate candidate edge modifications:
   - For each (i, j) pair: toggle A[i, j]
   - n² candidates total
2. For each candidate, compute resulting L
3. Apply modification that REDUCES L most (ties broken by lowest i, j)
4. If no modification reduces L, halt (local minimum reached)

This is greedy energy descent on L.  Deterministic given initial
state.

---

## Pre-registered measurements

For each test case (initial substrate):
1. Compute L(t=0) = initial L
2. Apply STEP-CA-MIN for T=50 steps (or until convergence)
3. Record L(t) trajectory
4. Compute L(t_final) = final L
5. Verify monotone non-increase: L(t+1) ≤ L(t) for all t

Test substrates (deterministic, no random):
- ER random graph G(n=10, p=0.30) with seed=1
- ER random graph G(n=20, p=0.20) with seed=2
- ER random graph G(n=15, p=0.40) with seed=3
- Path graph n=10 (initial low L?)
- Cycle graph n=10 (initial low L?)
- Random n=15 with seed=4

Baseline (random rewrite for comparison):
- Same initial substrate
- Random edge modification at each step (no L-based selection)
- T=50 steps
- Track L(t)

---

## Pre-registered regimes (no gap, partition)

For each test case, classify:
- `monotone?`: L(t) is non-increasing across ALL 50 steps
- `L_descent_total`: L(0) - L(T) — total reduction
- `L_baseline_descent`: same metric for random rewrite baseline
- `R_descent` = L_descent_total / L_baseline_descent — descent
   advantage over random

Aggregate across 6 test cases.

| regime | condition | meaning |
|--------|-----------|---------|
| **AA** | monotone? == True for ALL 6 AND mean(R_descent) > 1.5 | substrate dynamics MINIMIZE L; descent significantly better than random — energetic substrate behavior confirmed |
| **BB** | monotone? for ≥4/6 OR mean(R_descent) ∈ [1.1, 1.5] | partial; substrate descends but with noise or modest advantage |
| **CC** | monotone? for ≤3/6 AND mean(R_descent) < 1.1 | substrate doesn't reliably minimize L; L isn't the right loss OR STEP-CA-MIN implementation broken |

### Sub-prediction (sanity)

For initial random ER state, L_initial should be ≈ n (most rows
distinct).  L_final under STEP-CA-MIN should be substantially
less.  If L_final ≈ L_initial → no descent achieved.

### Author guess (non-binding)

- Regime AA (clean descent, monotone, >1.5× baseline): **80%** —
  greedy descent on simple combinatorial L should work cleanly
- Regime BB (partial): **15%**
- Regime CC (broken): **5%** — only if implementation bug

Most informative: AA confirms energetic substrate works (as
predicted by user insight); CC would mean L poorly chosen OR
substrate dynamics not implementable as MDL descent.

---

## Falsification consequences

- **Regime AA** → substrate exhibits L-energetic dynamics; matryoshka
  encoding emerges from descent, not pre-specified.  This is the
  DYNAMIC analogue of cycle 18's structural finding.  Combined
  with cycle 18, substrate has: (a) structural compression
  capability + (b) dynamics that discover compression.  Substrate-
  of-cognition mechanism becomes concrete: L-descent IS perception.
- **Regime BB** → modest L-descent; substrate approximates energetic
  behavior but not cleanly.  Honest partial result.
- **Regime CC** → L = unique-row-count is wrong loss for substrate
  OR implementation broken.  Cycle 20 tries different L (e.g.,
  total edge count, structural entropy, eigenvalue spectrum).

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. STEP-CA-MIN deterministic (greedy with tiebreaker); no RNG.
5. 6 test cases exactly as specified; no cherry-picking.
6. T=50 steps fixed (no early-stopping post-hoc).
7. Reproducibility: numpy seed for ER generation = 1, 2, 3, 4.
8. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: Friston FEP, Jaynes max-caliber, Solomonoff prior,
      Wolfram causal invariance — convergent loss-minimization
      frameworks; Schmidhuber Speed Prior (2002); MDL textbook
      (Grünwald 2007)
- [x] Rule 3: deterministic test; no statistical sampling needed
- [x] Rule 4: AA/BB/CC partition without gap
- [x] Rule 5: first MDL-descent on substrate; cycle 20 cross-validates
      with different L
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: L-descent is NOT tautology — substrate could fail to
      monotone-decrease (CC) if dynamics aren't expressible as
      L-minimization
- [x] Rule 8: scope = 6 test cases, T=50 steps, specific L definition
- [x] Rule 9: attestation pending

## References

- Cycle 18 commit ebf40c5 — structural matryoshka finding
- Friston (2010) — FEP variational free energy
- Beck-Ramstead (2025) arXiv:2502.21217 — Jaynes max caliber +
  Markov blanket framework
- Schmidhuber (2002) — Speed Prior, universal MDL
- Grünwald (2007) — MDL textbook
- Spisak-Friston (2025) arXiv:2505.22749 — FEP-EBM bridge
- User insight 2026-05-22 — universe's loss function = what
  substrate should minimize
