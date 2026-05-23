# Demo 142 — Pre-Registered Predictions (cycle 23, Phase A)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Direction change (NOT another MDL rescue)

Cycle 22 (commit `ff813ae`) closed MDL family cleanly:
- C19 AA: MDL descent works mechanically (weak monotone)
- C20 AA': stronger search confirms (5/6 unstuck)
- C21 CCC: pure MDL groups lose to degree (5/5 non-tie)
- C22 CCCC: MDL + prediction + DegeneracyPenalty STILL 2/6 vs degree

Three operationalizations, three failures.  MDL family exhausted.

**Cycle 23 is NOT another attempt to rescue MDL.**  Cycle 23 tests a
different hypothesis per user spec (2026-05-23):

> Objecthood may be predictive rather than compressive.

Compression appears only as a model-complexity *constraint*, not as
a primary driver.

---

## Loss function (pre-committed)

```
L23(A | A_init) = PredError(groups(A), A_init) +
                  α · ModelComplexity(groups(A)) +
                  γ · DegeneracyPenalty(groups(A))

PredError = mean over t=1..T_pred of ||pred_t - true_t||^2 / ||true_t||^2
            (cycle 21/22 formula; T_pred = 20)

ModelComplexity = K / n         ∈ [1/n, 1]
                  (group count normalized — minimal complexity penalty,
                   NOT MDL as primary driver)

DegeneracyPenalty = (max_group_size / n)^2 + (singletons / K)   ∈ [0, 2]
                    (identical to C22 — kills K=1 collapse)

γ = 0.1 fixed pre-commit (identical to C22 μ).
α ∈ {0.01, 0.1, 1} fixed grid pre-commit.
```

**Compared to C22 (`L22 = MDL_norm + λ·Pred_norm + μ·Penalty`)**:
- C22 had compression as primary, prediction as add-on
- C23 has prediction as primary, complexity as add-on
- C22 used NORMALIZED PredError; C23 uses RAW PredError
  (because PredError IS the central quantity, not a side term)
- The grids are different (C22 λ ∈ {0.1, 1, 10}, C23 α ∈ {0.01, 0.1, 1})

---

## STEP-CA-PRED dynamics (pre-committed)

Identical to C22 STEP-CA-MIN-COMBINED except `delta` is `ΔL23`,
not `ΔL22`:

For each step t ∈ [0, 199]:
1. Compute current L23(A).
2. Enumerate n² single-edge toggles; evaluate L23(A_new).
3. Sample 200 random 2-edge toggles (seed=42); evaluate L23(A_new).
4. Pick candidate with lowest L23.  delta ≤ 0 → accept; delta > 0 →
   SA accept with p = exp(-delta / T(t)), T(t) = 2.0 · 0.95^t.
5. Apply.

Repeated independently for each α ∈ {0.01, 0.1, 1}.

Per-step diagnostic log:
- second_best_delta (gap between best and second-best move)
- max_group_size_ratio
- partition_entropy = -Σ p_i log p_i (group size entropy)

second_best_delta diagnoses whether SA is making meaningful choices
or wandering across plateaus.

---

## Substrate set (same 6 as cycles 19/20/21/22)

1. ER(n=10, p=0.30) seed 1
2. ER(n=20, p=0.20) seed 2
3. ER(n=15, p=0.40) seed 3
4. Path n=10
5. Cycle n=10
6. ER(n=15, p=0.25) seed 4

**Phase B (cycle 24)** will introduce new substrates with degree-
UNINFORMATIVE dynamics to test whether degree-baseline dominance in
C21/22 was substrate-of-cognition failure OR benchmark artifact.

---

## Pre-registered measurements (per substrate, per α)

For each α and substrate:
- `K_sub` = group count of substrate A_final
- `PE_sub` = PredError of substrate grouping on A_init
- `K_deg = K_sub`, `PE_deg` = PredError of degree grouping at same K
- `pred_win` = PE_sub < PE_deg (THE primary win criterion)
- `delta_pred = PE_deg - PE_sub` (positive = substrate wins)
- `is_K1` = K_sub == 1
- `max_size_ratio`, `partition_entropy` (diagnostic)

Per α aggregate:
- `pred_wins(α)` = # substrates with pred_win true
- `has_K1(α)` = any substrate with K=1
- `mean_delta(α)` = mean(delta_pred) across all 6
- `concentrated(α)` = TRUE if all wins are confined to
  {ER_n10_p30, path_n10} (the two that worked in C22)
- `robust_drop(α)` = max drop in pred_wins when removing any single
  substrate

**Best α** = argmax(pred_wins); ties broken by mean_delta.

---

## Pre-registered regimes (no gap, partition)

| regime | condition on best α | meaning |
|--------|---------------------|---------|
| **AAAAA** | pred_wins ≥ 4 AND mean_delta > 0.005 AND NOT concentrated AND NOT has_K1 AND robust_drop ≤ 1 | STRONG PASS — predictive loss generalizes across substrate families, beats degree consistently |
| **BBBBB** | pred_wins ≥ 3 AND NOT has_K1 AND mean_delta > 0 | WEAK PASS — predictive loss helps on some substrates; cycle 24 tests if effect grows on degree-blind benchmarks |
| **CCCCC** | pred_wins ≤ 2 OR has_K1 OR mean_delta ≤ 0 OR concentrated | FAIL — predictive-only loss does NOT improve over degree on NSUM dynamics.  Two interpretations: (a) substrate-of-cognition can't beat degree on degree-biased benchmark; (b) substrate genuinely lacks predictive structure.  Cycle 24 (Phase B) distinguishes by testing degree-blind dynamics. |

### Author guess (non-binding, honest)

- AAAAA: **15%** — strong pass requires beating degree on most
  substrates; degree is sufficient statistic for NSUM-update which is
  the dynamics being predicted; intrinsically hard
- BBBBB: **30%** — modest pass possible if PredError-focused loss
  finds groups degree-grouping misses on path/cycle-like structure
- CCCCC: **55%** — most likely; if NSUM dynamics IS degree-driven,
  no PredError-focused loss should beat degree on these substrates

### Critical diagnostic (regardless of regime)

If CCCCC fires AND mean_delta is approximately equal across all
α values → benchmark artifact strongly suggested (PredError landscape
flat; no α can find groups that beat degree because degree IS the
oracle for NSUM).

If CCCCC fires BUT some α has noticeably better delta than others →
landscape has structure but SA can't find it; cycle 24 should still
test degree-blind benchmarks to rule out degree-bias.

---

## Falsification consequences

- **AAAAA** → predictive-loss family validated on existing benchmark.
  Cycle 24 (Phase B) tests if it generalizes to degree-blind dynamics
  (motif, role, hidden-family).  If 24 also passes → first major
  substrate-of-cognition positive.  If 24 fails → original pass was
  benchmark-dependent.
- **BBBBB** → modest signal; cycle 24 is critical to distinguish
  real predictive content vs degree-bias artifact.
- **CCCCC** → predictive-only loss on degree-driven dynamics
  insufficient.  Cycle 24 (Phase B) is the make-or-break test:
  if substrate beats degree on degree-blind benchmark → cycle 22/23
  failures were benchmark artifacts; substrate-of-cognition lives;
  pivot ALL future tests to degree-blind benchmark suite.
  If substrate ALSO fails on degree-blind → substrate genuinely
  lacks objecthood signal in current Sixth implementation; need
  primitive set redesign or substrate-as-cognition hypothesis
  rejected.

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. Same 6 substrates as cycles 19/20/21/22 exactly.
5. SA hyperparams (T0=2.0, α_SA=0.95, T=200, 2-edge sample=200,
   seed=42) identical to C20/C22 — frozen reference.
6. α grid {0.01, 0.1, 1} FIXED; no extension post-hoc.
7. γ = 0.1 FIXED (same as C22 μ).
8. Random partition seed = 137 (cycle 21/22 frozen reference).
9. PASS evaluated by PredError, NOT by L23 (avoids penalty tricks
   per user spec).
10. All 3 α values run; ALL results reported (no cherry-picking).
11. Best α = argmax(pred_wins); tiebreak by mean_delta.
12. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 22 (commit ff813ae) frozen MDL-family negative;
      Friston (2010) FEP / predictive processing; Clark (2013)
      "Whatever next? Predictive brains, situated agents, and the
      future of cognitive science" BBS 36:181; user spec 2026-05-23
- [x] Rule 3: deterministic given fixed seeds
- [x] Rule 4: AAAAA/BBBBB/CCCCC partition without gap
- [x] Rule 5: same substrate set as C19-22
- [x] Rule 6: aggregate counter update post-result
- [x] Rule 7: AAAAA / CCCCC sharply distinct; substrate could fail
      to beat degree even with prediction-as-primary loss
- [x] Rule 8: scope = 6 substrates × 3 α values, T=200 steps,
      single-substrate sensitivity check, concentration check
- [x] Rule 9: attestation pending

## References

- Cycle 22 (commit ff813ae) — MDL family closed
- Friston (2010) — FEP / predictive processing
- Clark (2013) BBS 36:181 — predictive brains
- Spratling (2017) "A review of predictive coding algorithms"
  Brain & Cognition 112:92
- User spec (2026-05-23) — NOT another MDL rescue; predictive
  objecthood without MDL; γ=0.1, α grid {0.01, 0.1, 1}; PASS by
  PredError not L23; phases A (continuity) and B (degree-blind)
