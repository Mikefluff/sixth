# Demo 134 — Pre-Registered Predictions (cycle 15)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Follow-up to cycle 14

Cycle 14 (commit `1f004c5`) found ONE substrate-distinguishing
signal surviving degree-matched k-regular baseline:
**cycle_n10 with all-self-loops → R_regular = 2.00**.

Cycle 15 investigates WHY: is this signal substrate-specific
to cyclic topology, or a small-n artifact?

Two tests:

1. **Scaling**: does R grow / shrink / stay constant with n?
2. **Symmetry breaking**: does adding chords (extra edges)
   destroy the signal?

---

## Methodology

`scripts/eics_cycle_scaling.py`:

For each n ∈ {5, 10, 20, 50, 100}:
- Build cycle_n with all-self-loops (substrate)
- Compute EICS(substrate, T=10)
- Generate M=200 random k=2 regular baselines (matching cycle's
  pure-cycle degree before self-loops)
- Compute R(n) = EICS_cycle / mean(EICS_random_regular)

For chord variants at n=10:
- cycle_10 (baseline = R=2.00 from cycle 14)
- cycle_10 + 1 chord (5-shortcut)
- cycle_10 + 2 chords
- cycle_10 + 5 chords (heavily perturbed)
- compute R per variant

---

## Pre-registered regimes (no gap, partition)

### Scaling regime (R_overall_scaling = mean R across n=5..100)

| regime | condition | meaning |
|--------|-----------|---------|
| **X**  | R grows monotonically with n, R(100) > 1.5 | scaling-substrate-specific signal — genuine cyclic-topology finding that survives all scales |
| **Y**  | R approximately constant ≈ 2.0 across n | persistent scale-invariant cycle signal |
| **Z**  | R shrinks with n, R(100) < 1.2 | small-n artifact — signal vanishes at scale, cycle 14 finding was finite-size effect |
| **AA** | non-monotone or any other pattern | unexpected; investigate |

### Chord-breaking regime (R_chord-breaking)

`R_decay = R(cycle_10 + 5 chords) / R(cycle_10)`:

| regime | condition | meaning |
|--------|-----------|---------|
| **BB** | R_decay < 0.5 | signal FRAGILE — chord destroys cycle distinctiveness |
| **CC** | R_decay ∈ [0.5, 1.5] | signal ROBUST — survives perturbation |
| **DD** | R_decay > 1.5 | chord ENHANCES signal — surprising |

### Falsification consequences

**Best outcome (X + CC)**: cycle finding scales AND is robust to
perturbation → substantial substrate-distinguishing result;
publishable as "Sixth cycle-substrate topology produces EICS
signature exceeding degree-matched random across scales and
modest perturbations".

**Worst outcome (Z + BB)**: cycle 14's signal was small-n + fragile;
retracts cycle 14 entirely.

**Mixed**: scope claim narrowed accordingly.

### Sub-prediction (sanity)

EICS values for all tested configurations should be in [0, 1).
EICS for cycle_n100 should be larger than EICS for matched
k=2-regular random graph (which has same degree but no
rotational symmetry).

### Author guess (non-binding)

Scaling:
- X (grows): 30% — cyclic signal could amplify at larger n
- Y (constant ~2.0): 35% — most likely scale-invariant
- Z (shrinks): 25% — small-n artifact
- AA (other): 10%

Chord-breaking:
- BB (fragile, < 0.5): 40%
- CC (robust, [0.5, 1.5]): 50% — most likely modest decay
- DD (enhances, > 1.5): 10%

Most informative: X + CC together (signal scales AND is robust)
or Z + BB together (signal was artifact + fragile).

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. M=200 random baselines per (n, k) — smaller than cycle 14's
   M=500 because n=100 case is compute-heavy.
5. Reproducibility: numpy seed = 12345; cycle constructions
   deterministic.
6. EICS implementation unchanged (T=10).
7. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE script
- [x] Rule 2: Krasnovsky (2025) arXiv:2509.07149; cycle 13/14
      commits referenced
- [x] Rule 3: M=200 — adequate for noise floor at this scale
- [x] Rule 4: scaling X/Y/Z/AA partition without gap; chord
      BB/CC/DD partition without gap
- [x] Rule 5: this IS the Rule 5 deeper-investigation for cycle 14
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: scaling and chord-perturbation are NOT tautologies —
      they test if the surviving signal is genuine
- [x] Rule 8: scope n ≤ 100 cycles only; chord variants at n=10 only
- [x] Rule 9: attestation pending

## References

- Krasnovsky (2025) arXiv:2509.07149 — EICS methodology
- Cycle 13C/D commit 3e4e895 — original EICS application
- Cycle 14C commit 1f004c5 — degree-matched cross-validation
- Watts, Strogatz (1998) — small-world networks (relevance to
  chord-perturbation analysis)
