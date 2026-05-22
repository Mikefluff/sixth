# Demo 132 — Pre-Registered Predictions (cycle 13C)

**Date pre-registered:** 2026-05-22

**Attested:** committed AFTER `scripts/attest_prediction.sh` per Rule 9.

**Pre-commit hook**: should pass Rules 2/4/9 automatically.

---

## Source method

Krasnovsky (2025), "Measuring Uncertainty in Transformer Circuits
with Effective Information Consistency", arXiv:2509.07149.

EICS algorithm extracted in `docs/EICS-HOOK.md`.  Application to
Sixth substrate adapts the Jacobian to the substrate's NSUM
adjacency.

## References

- Krasnovsky (2025) — arXiv:2509.07149 — EICS source method, all
  formulas extracted in EICS-HOOK.md.
- Cogitate Consortium (2025) — Nature, 30 April — adversarial test
  of IIT vs GNWT, context for negative-result publishability.
- Koch (2026) — arXiv:2603.27597 — "calibration problem" framing
  for negative results in artificial consciousness.

---

## What this cycle tests

Conjecture (extending SUBSTRATE-EQUIV-CONJECTURE Conjecture 1
to a non-Sixth-Φ-family measure):

> EICS computed on Sixth substrate is statistically indistinguishable
> from EICS computed on a matched random Erdős-Rényi graph of the
> same size, when each is in equilibrium with NSET-OUT feature load.

If this conjecture holds: cycle 13C confirms substrate ≡ classical
for ALL currently-known computational-consciousness measurements,
including EICS (the most external / published one).

If the conjecture fails: substrate has a measurable EICS signature
that random ER graphs lack — first SUBSTRATE-DISTINGUISHING
signal in the catalogue.

---

## Methodology

`scripts/eics_sixth.py` computes EICS on:

1. **Canonical substrates** (10 hand-designed, n=10-20):
   - Sparse ER with self-loops (cycle 10-11 substrates)
   - Dense ER with all-pairs bi-edges
   - Pure HEDGE3 substrates (WITNESS-typed triadic structures)
   - Mixed bi-edge + HEDGE3 substrates
   - All with NSET features loaded as OUT
2. **Random ER baseline** (M=1000 per n, p ∈ {0.05, 0.10, 0.15, 0.20}):
   - networkx fast_gnp_random_graph
   - Self-loops added
   - Features loaded as degree

For each pair (substrate_class, matched_baseline):
- compute EICS distribution
- compute R = mean(EICS_substrate) / mean(EICS_baseline)

---

## Pre-registered regimes (no gap, partition)

`R_overall` = average of R across the 10 canonical substrates
(comparing each to its matched random baseline at same n and
mean degree).

| regime | condition          | meaning                                                  |
|--------|--------------------|---------------------------------------------------------|
| **R**  | R_overall > 1.5    | substrate has SUBSTANTIALLY higher EICS than random — first substrate-distinguishing signal in Sixth catalogue |
| **S**  | R_overall ∈ [0.8, 1.5] | substrate EICS ≈ random EICS — Conjecture confirmed; substrate ≡ classical for EICS measure too |
| **T**  | R_overall < 0.8    | substrate EICS LOWER than random — substrate is LESS coherent than random graphs; surprising, investigate |

Boundaries 0.8 and 1.5 chosen to allow 20% noise margin around
R=1.0 (statistical null) while flagging substantial signals
either direction.

### Falsification consequences

- **Regime R** → Cycle 14+ deeply investigates source of
  substrate-EICS advantage.  Could be:
  - HEDGE3 typed edges contributing structural coherence
  - Self-loop pattern Sixth uses contributing
  - Real substrate computational signature
  - If reproducible at multiple n, this is a publishable finding.
- **Regime S** → Most likely outcome by author guess.  Confirms
  substrate ≡ classical even by best-available external measure.
  Catalogue finalizes; Sixth published as engineering + methodology
  contribution + negative-result paper.  Companion #1 Pythia
  becomes future test site.
- **Regime T** → Substrate is LESS coherent than random.  Suggests
  Sixth's particular topology (sparse, self-loops only on
  observer in many demos) is anti-correlated with coherence.
  Less publishable but informative.

### Sub-prediction (sanity)

EICS values themselves should be in [0, 1) range as defined.
If any value outside this range: implementation bug; halt and fix.

### Author guess (non-binding)

- Regime S (substrate ≈ random): **70%** — pattern of 12 cycles
  suggests substrate doesn't escape classical via any known
  measurement.
- Regime R (substrate > random): **20%** — possible if HEDGE3
  typed structure adds coherence; would be cycle's positive finding.
- Regime T (substrate < random): **10%** — unlikely; would require
  Sixth's topology to be specifically less-coherent than ER.

Most informative outcome: **R** (first substrate-distinguishing
signal).  Most likely: **S** (null finding, finalizes catalogue).

---

## Methodological commitments (binding)

1. `scripts/eics_sixth.py` written AFTER this file committed.
2. Reference run AFTER both files committed.
3. Result reported regardless of regime.
4. M=1000 random baseline; canonical substrates exactly 10.
5. Reproducibility: numpy seed = 12345; Sixth canonical substrates
   defined deterministically in script.
6. EICS implementation follows Krasnovsky 2509.07149 formulas
   exactly; deviations (e.g., for directed graphs vs DAG)
   documented in script.
7. Attestation via attest_prediction.sh BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file before script
- [x] Rule 2: Krasnovsky 2509.07149 cited; EICS formulas in
      docs/EICS-HOOK.md
- [x] Rule 3: M=1000 random baseline (10x typical substrate cycle)
- [x] Rule 4: regimes R/S/T partition without gap
- [x] Rule 5: first EICS application on Sixth; cycle 14+ replicates
- [x] Rule 6: aggregate count updated post-result
- [x] Rule 7: EICS is NOT a tautology of Sixth's internal definitions —
      it's a sheaf + Gaussian-information measure from external paper
- [x] Rule 8: scope n ≤ 20 + classical ER baseline only
- [x] Rule 9: attestation pending
