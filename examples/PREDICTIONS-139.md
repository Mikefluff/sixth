# Demo 139 — Pre-Registered Predictions (cycle 20)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Motivation (cycle 19 honest caveat)

Cycle 19 (commit `5d6725a`) achieved REGIME AA per pre-reg classifier
(6/6 monotone, R = ∞) but only 2/6 substrates exhibited nonzero
L-descent.  4/6 stuck at initial state because greedy single-edge
STEP-CA-MIN couldn't find any toggle reducing L.

Two falsifiable hypotheses for the 4/6 plateau:
- **H_search** — greedy local search insufficient; stronger optimizer
  (2-edge moves + simulated annealing) WILL find descent paths
- **H_landscape** — L itself flat/plateau-rich from random ER starts;
  no descent path exists at any reasonable step size, regardless of
  optimizer.  Substrate-as-energetic system needs different L.

Cycle 20 distinguishes these.

---

## Optimizer (pre-committed)

**STEP-CA-MIN-STRONG**: at each step, evaluate three candidate move
classes and apply the best L-reducing move (or accept worse moves
with SA probability).

1. **Single-edge toggle** (cycle 19 baseline): n² candidates.
2. **Two-edge toggle**: pairs (i,j), (k,l) toggled simultaneously.
   Enumerated via O(n²) random sample of 200 distinct pairs per step
   (full O(n⁴) enumeration intractable at n=20).  Fixed RNG seed.
3. **Simulated annealing acceptance**:
   - Compute ΔL for chosen candidate.
   - If ΔL ≤ 0 → accept (greedy or lateral).
   - If ΔL > 0 → accept with probability exp(-ΔL / T(t)).
   - Temperature schedule: T(t) = T₀ · α^t with T₀=2.0, α=0.95.

Total step budget: T=200 steps per substrate (4× cycle 19 to allow
SA exploration).  Fixed RNG seed (= 42) for full reproducibility.

---

## Same 6 substrates as cycle 19

For direct comparability, test on IDENTICAL initial states:
1. ER(n=10, p=0.30) seed 1
2. ER(n=20, p=0.20) seed 2
3. ER(n=15, p=0.40) seed 3
4. Path n=10
5. Cycle n=10
6. ER(n=15, p=0.25) seed 4

Cycle 19 single-edge greedy result on these (frozen reference):
- ER_n10_p30: descent 4 ✓
- ER_n20_p20: descent 0 ✗ stuck
- ER_n15_p40: descent 0 ✗ stuck
- path_n10:   descent 2 ✓
- cycle_n10:  descent 0 ✗ stuck (already at L=10 plateau)
- ER_n15_p25: descent 0 ✗ stuck

---

## Pre-registered measurements

For each substrate:
1. `L_init` (already known from cycle 19)
2. `L_final_strong` after T=200 steps of STEP-CA-MIN-STRONG
3. `L_descent_strong` = L_init - L_final_strong
4. `L_descent_greedy` from cycle 19 (frozen reference)
5. `L_descent_random` from cycle 19 (frozen reference, T=50 random)

Aggregate:
- `n_unstuck` = number of substrates where L_descent_strong > L_descent_greedy
- `total_descent_strong` = sum of L_descent_strong
- `total_descent_greedy` = 6 (cycle 19 sum)
- `R_strong_vs_greedy` = total_strong / max(1, total_greedy)

---

## Pre-registered regimes (no gap, partition)

| regime | condition | meaning |
|--------|-----------|---------|
| **AA'** | n_unstuck ≥ 5 AND R_strong_vs_greedy > 2.0 | H_search WINS: stronger optimizer unstuck the plateaus; L is the right energetic quantity, cycle 19 result was search-limited |
| **BB'** | n_unstuck ∈ {3, 4} OR R_strong_vs_greedy ∈ [1.3, 2.0] | mixed: SA helps but plateau partially fundamental |
| **CC'** | n_unstuck ≤ 2 AND R_strong_vs_greedy < 1.3 | H_landscape WINS: L itself is plateau-rich from random ER, substrate dynamics OK but L is wrong loss function |

### Author guess (non-binding, honest)

- AA': **20%** — single→two-edge alone might unstuck ER_n20 but cycle/ER_p40 unlikely
- BB': **40%** — most likely; SA gets some plateaus but L has genuine flat regions
- CC': **40%** — equally likely; row-uniqueness L from random adjacency may simply have NO single-or-few-edge descent path because all rows are unique with high probability and breaking that requires ≥k-edge coordinated move

Most informative: AA' confirms L + substrate model; CC' falsifies L as
the right energetic quantity and forces cycle 21 to test alternative
L (e.g. spectral entropy, von Neumann graph entropy, total degree
variance).

---

## Falsification consequences

- **AA'** → substrate IS L-energetic in strong sense; cycle 21 can move
  to formalize PROOF of L-monotonicity for substrate dynamics; submit
  to MoC 7 abstract as substrate energetic claim.
- **BB'** → substrate L-monotonic in mixed sense; cycle 21 tests
  alternative L AND alternative move sets to disambiguate.
- **CC'** → L = unique-row-count IS wrong; cycle 21 tests alternative
  L families (spectral, structural-entropy, von-Neumann graph entropy).
  HONEST: cycle 19 + 18 stand as positive results but the broader
  "substrate minimizes A loss" claim needs different L. Most exciting
  outcome — clear next experiment.

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. Same 6 substrates as cycle 19 exactly; no re-selection.
5. T=200 fixed; no early-stopping post-hoc.
6. RNG seed = 42 fixed; reproducible.
7. SA params (T₀=2.0, α=0.95) fixed pre-commit; no tuning post-hoc.
8. 2-edge sample size = 200/step fixed; no tuning post-hoc.
9. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: Kirkpatrick et al. (1983) "Optimization by Simulated
      Annealing" Science 220:671; Metropolis (1953) acceptance criterion;
      cycle 19 baseline frozen reference (commit 5d6725a)
- [x] Rule 3: deterministic given seed; single run per substrate
- [x] Rule 4: AA'/BB'/CC' partition without gap
- [x] Rule 5: same substrate set as cycle 19 for direct comparison
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: H_search vs H_landscape — both falsifiable; CC' would
      directly negate L as the right substrate loss
- [x] Rule 8: scope = 6 substrates, T=200 steps, SA + 2-edge moves
      with fixed hyperparameters
- [x] Rule 9: attestation pending

## References

- Cycle 19 (commit 5d6725a) — single-edge greedy baseline
- Kirkpatrick, Gelatt, Vecchi (1983) Science 220:671 — SA
- Metropolis et al. (1953) J Chem Phys 21:1087 — acceptance criterion
- User insight (2026-05-22) — universe minimizes A loss function
