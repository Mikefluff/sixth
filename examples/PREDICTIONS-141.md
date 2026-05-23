# Demo 141 — Pre-Registered Predictions (cycle 22)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Motivation (user spec 2026-05-22)

Cycle 21 (commit `ee5567a`) confirmed REGIME CCC: pure MDL groups
LOSE to degree baseline on 5/5 non-tie substrates (mean delta
-0.0045).  cycle_n10 collapsed to K=1, demonstrating MDL's drive to
over-compress without predictive grounding.

User hypothesis: objecthood = compression-stable AND prediction-useful
grouping.  Cycle 22 operationalizes this DIRECTLY by changing the
loss function the substrate MINIMIZES, not by post-hoc scoring.

Critical commitment per user spec:
- Pre-registered grid `λ ∈ {0.1, 1, 10}` — NO gradient descent on λ.
- `μ = 0.1` fixed — NO post-hoc adjustment.
- Normalization OBLIGATORY (different scales of MDL and PredError).
- DegeneracyPenalty OBLIGATORY (must kill K=1 collapse).
- STEP-CA chooses moves by `Δ(L_combined)`, NOT `ΔMDL`.

---

## Loss function (pre-committed)

```
L22(A | A_init) = MDL_norm(A) + λ · Pred_norm(A | A_init) + μ · DegeneracyPenalty(A)

MDL_norm(A) = |unique rows of A| / n                          ∈ [1/n, 1]

Pred_norm(A | A_init) = PredError(groups(A), A_init) /
                        PredError(groups_K1, A_init)         ∈ [0, ~1+]
  where groups(A) = row-equivalence classes of A,
        groups_K1 = single-cluster baseline (worst case),
        PredError uses normalized A_init dynamics, T_pred = 20

DegeneracyPenalty(A) = (max_group_size / n)² + (singletons / K)  ∈ [0, 2]
  where max_group_size = max(|G_i|),
        singletons = #{i : |G_i| = 1},
        K = number of groups
  (depth_overfit term = 0 — partitions are flat, no hierarchy)

μ = 0.1   (fixed pre-commit)
λ ∈ {0.1, 1, 10}   (fixed grid pre-commit)
```

**Why normalization matters**: pure MDL ∈ [1/n, 1], PredError can be
1e-4 to 1.  Without `/PredError_K1`, λ would be a scale crutch, not
a semantic weight.

**Why DegeneracyPenalty matters**: cycle_n10 K=1 case got
`max_group_size_ratio² = 1` and `singletons/K = 0`, giving 1.0
penalty.  At μ=0.1 that's +0.1 added to L22 — enough to outweigh
MDL_norm reaching its minimum 0.1.

---

## STEP-CA-MIN-COMBINED-STRONG (pre-committed)

Identical to cycle 20 STEP-CA-MIN-STRONG except `delta` is `ΔL22`,
not `ΔMDL`:

For each step t ∈ [0, 199]:
1. Compute current L22(A).
2. Enumerate n² single-edge toggles; for each, evaluate L22(A_new).
3. Sample 200 random 2-edge toggles (RNG seed 42 same as cycle 20);
   for each, evaluate L22(A_new).
4. Pick candidate with lowest L22.  If delta ≤ 0 → accept.
   If delta > 0 → SA accept with p = exp(-delta / T(t)), T(t) =
   2.0 · 0.95^t.
5. Apply.

Repeated independently for each λ ∈ {0.1, 1, 10}.

---

## Substrate set (same 6 as cycles 19/20/21)

1. ER(n=10, p=0.30) seed 1
2. ER(n=20, p=0.20) seed 2
3. ER(n=15, p=0.40) seed 3
4. Path n=10
5. Cycle n=10
6. ER(n=15, p=0.25) seed 4

---

## Baselines (per substrate, evaluated at K = K_combined of best λ)

- **degree** — sort by out-degree, K contiguous bins (cycle 21
  baseline, frozen comparison)
- **random** — random partition into K groups, seed=137 (cycle 21
  baseline, frozen comparison)
- **MDL-pure** — substrate from cycle 20 STEP-CA-MIN-STRONG (frozen)

For each λ, baselines re-computed at K_combined of that λ (since
combined might give different K than pure MDL).

---

## Pre-registered measurements (per substrate, per λ)

- `K_combined(s, λ)` — group count from row-equivalence of A_final
- `MDL_combined(s, λ)` = `K_combined / n`
- `PredError_combined(s, λ)` — on A_init dynamics, T_pred=20
- `L22_combined(s, λ)` — final L22 with this λ
- `K_combined == 1` — degeneracy flag
- For degree baseline at K_combined:
  - `L22_degree(s, λ)` — degree-grouping evaluated under L22 with same λ
  - `PredError_degree(s, λ)` — degree-grouping PredError
- `combined_score_win(s, λ)` = `L22_combined < L22_degree`
- `pred_win(s, λ)` = `PredError_combined < PredError_degree`
- `both_win(s, λ)` = AND of the two

Per λ aggregate:
- `count_combined_wins(λ)` = #substrates with `combined_score_win` true
- `count_pred_wins(λ)` = #substrates with `pred_win` true
- `count_both_wins(λ)` = #substrates with `both_win` true
- `has_K1(λ)` = ∃ substrate with K_combined = 1
- `mean_delta_pred(λ)` = mean(PredError_degree - PredError_combined)
- `robust_drop(λ)` = max drop in count_both_wins when removing
  ANY single substrate (single-substrate sensitivity check)

**Best λ** = argmax(count_both_wins); ties broken by mean_delta_pred.

---

## Pre-registered regimes (no gap, partition)

| regime | condition on best λ | meaning |
|--------|---------------------|---------|
| **AAAA** | count_both ≥ 4 AND no K=1 AND mean_delta_pred > 0 AND robust_drop ≤ 1 | STRONG PASS — combined L beats degree on prediction AND combined score on ≥4 substrates; robust (no single-substrate artifact); no degeneracy collapse |
| **BBBB** | count_both ≥ 3 AND no K=1 AND mean_delta_pred > 0 | PASS — combined L beats degree on ≥3 substrates; combined loss validated as substrate-of-objecthood signal |
| **CCCC** | count_both ≤ 2 OR has_K1 OR mean_delta_pred ≤ 0 | FAIL — MDL+prediction family is wrong direction; cycle 23 must pivot to Information Bottleneck (track 4) or Predictive Processing (track 5) |

### Author guess (non-binding, honest)

- AAAA: **15%** — strong pass requires combined to consistently beat
  degree on prediction, which is a high bar since degree is well-suited
  to linear NSUM-update dynamics
- BBBB: **40%** — modest pass; combined likely helps on 3-4
  substrates where MDL had grossly over-compressed
- CCCC: **45%** — possible; if degree-grouping is structurally optimal
  for these specific substrates, no L modification within MDL family
  can beat it.  Would push to IB/predictive processing tracks.

**Most informative outcomes:**
- AAAA → first concrete substrate-of-objecthood positive
- CCCC → MDL family entirely exhausted; clear pivot to next loss track

---

## Falsification consequences

- **AAAA** → first clean substrate-derived positive in the cognition
  direction.  Publishable micro-result: "MDL alone fails, but MDL
  constrained by prediction discovers more object-like groupings
  than degree baseline on canonical substrates."  Cycle 23 = EBM
  formulation; Cycle 24 = Active Inference mini-agent.
- **BBBB** → modest positive; cycle 23 tests if Information
  Bottleneck (track 4) gives stronger or comparable signal at the
  same per-substrate cost.
- **CCCC** → MDL family confirmed dead end.  Cycle 23 pivots to
  Information Bottleneck (track 4): `L = compression_cost +
  β·lost_relevance` per Tishby-Pereira-Bialek (1999).  Catalogue
  records 3rd substrate-derived negative.

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. Same 6 substrates as cycles 19/20/21 exactly.
5. SA hyperparams (T0=2.0, alpha=0.95, T=200, 2-edge sample=200,
   seed=42) IDENTICAL to cycle 20 — frozen reference.
6. λ grid {0.1, 1, 10} FIXED; no extension post-hoc.
7. μ = 0.1 FIXED.
8. Random partition seed = 137 (cycle 21 reference).
9. PredError_K1 baseline computed ONCE per substrate, cached.
10. All 3 λ values run; ALL results reported (no λ cherry-picking).
11. Best λ = argmax(count_both_wins), tiebreak by mean_delta_pred.
12. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 21 (commit ee5567a) as frozen falsification;
      Rissanen MDL (1978); Tishby-Pereira-Bialek IB (1999);
      Kirkpatrick SA (1983); user spec 2026-05-22
- [x] Rule 3: deterministic given fixed seeds; single run per (s, λ)
- [x] Rule 4: AAAA/BBBB/CCCC partition without gap
- [x] Rule 5: same substrate set as cycles 19/20/21
- [x] Rule 6: aggregate counter update post-result
- [x] Rule 7: AAAA / CCCC are sharply distinct; substrate could fail
      to beat degree even with prediction-aware loss → genuine
      falsifiability
- [x] Rule 8: scope = 6 substrates × 3 λ values, T=200 steps,
      fixed hyperparams, single-substrate sensitivity check
- [x] Rule 9: attestation pending

## References

- Cycle 21 (commit ee5567a) — pure MDL fails (REGIME CCC frozen)
- Cycle 20 (commit d37aea1) — STEP-CA-MIN-STRONG hyperparams
- Rissanen (1978) — MDL
- Tishby-Pereira-Bialek (1999) `physics/0004057` — Information Bottleneck
- Kirkpatrick-Gelatt-Vecchi (1983) — Simulated Annealing
- User spec (2026-05-22) — pre-registered grid, mandatory normalization,
  mandatory DegeneracyPenalty, dynamics-level loss (not post-hoc)
