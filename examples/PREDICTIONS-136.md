# Demo 136 — Pre-Registered Predictions (cycle 17)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## CS-doctor follow-up to cycle 16

Cycle 16 (commit `e98ad84`) found:
- Primary metric R_objects = 0.736 → REGIME FF (null on object emergence)
- Secondary metric **R_ELBO = 1.489 (+49% better MB-model fit)**

The ELBO signal is substantial (49%) and substantially exceeds
pre-reg threshold R_ELBO > 1.1.  But cycle 16 used **random
rewrite baseline at p=0.20** — sparse-random comparison.

Cycle 14 lesson (commits `50ceb60`/`1f004c5`): cycle 13's R=1.795
EICS signal vs ER baseline narrowed to R=0.815 with degree-matched
random k-regular baseline.  Most of cycle 13 signal was sparse-
baseline artifact.

**Cycle 17 tests cycle 16's ELBO signal under same stricter
baseline**: random k-regular graphs matching each substrate's
mean degree.

If R_ELBO survives → genuine substrate-of-cognition signal at
FEP/MB level (substrate's iterated NSUM dynamics produce
trajectories more MB-amenable than degree-matched random).

If R_ELBO vanishes → cycle 16 was cycle 13/14 pattern repeated.

---

## Methodology

`scripts/dmbd_sixth_regular.py`:

Same as cycle 16 except baseline replaced:
- **Baseline (cycle 17)**: networkx random_regular_graph at
  k = round(mean_degree(substrate))
- All other parameters identical (DMBD config, T=50, restarts,
  etc.)

For each substrate:
1. Compute mean degree excluding self-loops
2. Generate M=20 random k-regular graphs matched
3. Run DMBD on substrate trajectory + baseline trajectories
4. Compare ELBO + object counts

---

## Pre-registered regimes (no gap, partition)

`R_ELBO_regular` = mean_ELBO(substrate) / mean_ELBO(random_regular)

Cycle 16 measured R_ELBO = 1.489 vs sparse-random baseline.
Cycle 17 expectation:

| regime | condition | meaning |
|--------|-----------|---------|
| **HH** | R_ELBO_regular > 1.3 | signal SURVIVES degree-matched baseline → genuine substrate-distinguishing MB-amenability finding |
| **II** | R_ELBO_regular ∈ [0.9, 1.3] | signal degraded but present → partial; modest claim |
| **JJ** | R_ELBO_regular < 0.9 | signal VANISHES → cycle 16 was sparse-baseline artifact; retract cycle 16 |

Secondary: R_objects_regular (object count ratio).
- > 1.5 / [0.5, 1.5] / < 0.5 partition

### Falsification consequences

- **Regime HH** → first GENUINE substrate-distinguishing signal
  in catalogue (survives degree-matched control).  Publishable at
  MoC 7 / IWAI 2025 as "Sixth substrate trajectories are more
  MB-amenable than degree-matched random under iterated NSUM
  dynamics."
- **Regime II** → partial; modest signal; document with caveat
  about magnitude reduction from sparse to degree-matched.
- **Regime JJ** → cycle 16 ELBO signal RETRACTED.  Extends
  "substrate ≡ classical" pattern to FEP/MB level too.  Catalogue
  remains at 0 substrate-distinguishing findings.

### Sub-prediction (sanity)

ELBO values should be in same magnitude range as cycle 16
(few hundred).  If wildly different → implementation issue.

### Author guess (non-binding)

- Regime HH (signal survives, R > 1.3): **25%** — possible if
  substrate's NSUM dynamics genuinely produce more MB-structured
  trajectories
- Regime II (partial, [0.9, 1.3]): **35%** — most likely; degree-
  matched baseline will eat most of the signal
- Regime JJ (vanishes, < 0.9): **40%** — most likely outcome
  given cycle 14 pattern; cycle 16 likely sparse-baseline artifact

Most informative: HH (first survives) or JJ (clean retract).
II hedges.

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. M=20 random regular baselines per substrate (matches cycle 16
   M for consistent comparison).
5. DMBD parameters IDENTICAL to cycle 16: hidden_dims=(4,4,4),
   role_dims=(4,4,4), regression_dim=-1, control_dim=-1, lr=0.5,
   iters=30, 3 restarts per substrate, 1 per baseline.
6. Reproducibility: torch seed=12345; networkx seeds=1..M.
7. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE script
- [x] Rule 2: Beck-Ramstead (2025) arXiv:2502.21217;
      Cycle 14 commit 1f004c5 — analogous test pattern
- [x] Rule 3: M=20 baselines × multiple substrates — adequate
- [x] Rule 4: regimes HH/II/JJ partition without gap
- [x] Rule 5: this IS the cycle 14-pattern Rule-5 cross-validation
      for cycle 16
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: degree-matched comparison tests if signal is genuine
      vs structured-vs-sparse-random artifact
- [x] Rule 8: scope same as cycle 16 (10 canonical substrates)
- [x] Rule 9: attestation pending

## References

- Beck & Ramstead (2025) arXiv:2502.21217 — DMBD source
- Cycle 16 commit e98ad84 — original ELBO signal being tested
- Cycle 14 commit 1f004c5 — methodology pattern (degree-matched
  baseline narrowed cycle 13 signal from 1.795 to 0.815)
