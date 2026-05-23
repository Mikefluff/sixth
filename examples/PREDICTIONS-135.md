# Demo 135 — Pre-Registered Predictions (cycle 16)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Source method

Beck &amp; Ramstead (2025), "Dynamic Markov Blanket Detection for
Macroscopic Physics Discovery", arXiv:2502.21217.  Code:
`github.com/bayesianempirimancer/pyDMBD`.

DMBD algorithm: Variational Bayesian EM on factorial Hidden Markov
Model with Markov-blanket-structured latents (s, b, z = environment,
boundary, internal).  Per-observation assignment ω_i(t) ∈ {S, B_n,
Z_n} dynamically labels microscopic elements.  Validated on
Newton's cradle, burning fuse, Lorenz attractor, Particle Lenia
(cell-like simulation).

---

## Application to Sixth substrate

For each Sixth canonical substrate S (from cycle 13), generate
trajectory by iterated NSUM-update (T=50 steps):
- Initial NSET = OUT (degree feature)
- Apply STEP-CA NSUM-rule for 50 iterations
- Record y_i(t) = NSET feature at node i, time t
- Shape: (T=50, n_nodes, feature_dim=1)

Apply DMBD with:
- `hidden_dims = (4, 4, 4)` (s, b, z latent dimensions)
- `role_dims = (4, 4, 4)` (s, b, z observation roles)
- 10 random restarts, pick highest-ELBO model

Compare to random graph rewrite baselines:
- Same n, p
- Random rewrite rule selection at each step
- M=50 random baselines per substrate

For each substrate / baseline:
1. Run DMBD inference
2. Extract assignment posterior `model.obs_model.NA`
3. Count number of distinct objects detected
   (assignment classes with > 5% support across trajectory)
4. Compute mean DMBD ELBO

---

## Pre-registered regimes (partition, no gap)

Metric: `R_objects = mean_objects_substrate / mean_objects_random_baseline`
where mean_objects = average number of distinct DMBD-detected objects
across 10 canonical substrates / 50 random baselines.

| regime | condition | meaning |
|--------|-----------|---------|
| **EE** | R_objects > 1.5 | substrate produces MORE emergent macroscopic structure than random — first substrate-of-cognition emergence finding |
| **FF** | R_objects ∈ [0.7, 1.5] | substrate ≈ random in emergence — null finding |
| **GG** | R_objects < 0.7 | substrate produces LESS structure than random — anti-distinguishing |

### Secondary metric

`R_elbo = mean_ELBO(substrate) / mean_ELBO(random_baseline)`

- R_elbo > 1.1 → substrate dynamics fit DMBD's MB model better than random
  (substrate has more MB-amenable structure)
- R_elbo ∈ [0.9, 1.1] → indistinguishable
- R_elbo < 0.9 → substrate fits worse (less MB-compatible)

### Falsification consequences

- **Regime EE + R_elbo > 1.1** → substrate produces emergent
  Markov-blanket-amenable structure beyond what random rewrites
  yield.  **First positive substrate-of-cognition finding**
  in catalogue.  Publishable at MoC 7 / IWAI 2025.
- **Regime FF** → substrate doesn't escape "graph theory" at the
  MB level either.  Null joining Cogitate 2025, Koch 2026.
  Catalogue gets clean negative result.
- **Regime GG** → substrate is anti-conducive to MB emergence.
  Less publishable but informative about substrate's structural
  properties.

### Sub-prediction

DMBD should detect ≥1 object for ANY non-degenerate trajectory
(per Beck-Ramstead validation on simple systems).  If ALL
substrates yield 0 detected objects → likely implementation
bug, not finding.

### Author guess (non-binding)

- Regime FF (substrate ≈ random): **55%** — pattern from 15 cycles
  suggests substrate doesn't escape classical
- Regime EE (substrate emergence): **25%** — Markov blanket is
  qualitatively different from spectral measures we tested; might
  surface substrate-specific structure
- Regime GG (anti-distinguishing): **20%** — random graphs may
  produce richer MB structure than ordered canonical substrates

Most informative: EE (first positive substrate finding).
Most likely: FF (substrate ≈ random extends to MB level).

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. M=50 random baselines per substrate; 10 DMBD restarts per dataset
   (per Beck-Ramstead recommendation).
5. Reproducibility: torch random seed = 12345; substrate generation
   deterministic.
6. DMBD parameters fixed: hidden_dims=(4,4,4), role_dims=(4,4,4),
   regression_dim=-1, control_dim=-1, lr=0.5, iters=40.
   No post-hoc parameter tuning.
7. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE script
- [x] Rule 2: Beck-Ramstead (2025) arXiv:2502.21217; pyDMBD code
      referenced; Friston FEP framework cited
- [x] Rule 3: M=50 baselines × 10 DMBD restarts × 10 substrates =
      5000 model fits; substantial sample
- [x] Rule 4: regimes EE/FF/GG partition without gap
- [x] Rule 5: first DMBD-on-Sixth application; cycle 17 could
      cross-validate at larger n
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: DMBD output (object count, ELBO) is NOT a tautology
      of substrate adjacency — it depends on temporal dynamics
- [x] Rule 8: scope = 10 canonical substrates, n ≤ 20, T=50 steps,
      NSUM-update rule
- [x] Rule 9: attestation pending

## References

- Beck &amp; Ramstead (2025) arXiv:2502.21217 — DMBD source method
- Friston FEP literature — broader framework
- Cycle 13-15 commits — prior EICS substrate measurements
- pyDMBD codebase: github.com/bayesianempirimancer/pyDMBD
