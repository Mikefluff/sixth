# Demo 124 — Pre-Registered Predictions

**Date pre-registered:** 2026-05-22

**Critical commitment:** this file is committed to git BEFORE
demo 124 source is written or run.  Git history proves
predictions were derived from classical Erdős-Rényi theory
WITHOUT reference to substrate measurement.  Any post-hoc
revision must be flagged as `[POST-HOC]` with reason.

---

## Theoretical basis

Classical Erdős-Rényi G(n, p):
- Mean degree: c = (n-1) · p
- Subcritical: c < 1, no giant component, mean cluster size of
  random node ≈ 1/(1 - c) (formula diverges at critical)
- Supercritical: c > 1, giant fraction f satisfies
    1 - f = exp(-c · f)
  Mean cluster size of random node:
    E[|cluster(v)|] = n · f² + (1 - f) / (1 - c·(1 - f))

Substrate phi-perc(observer) with observer self-loop:
    phi-perc(O) = |component(O)| · L_max
    L_max = 10000

Therefore:
    E[phi-perc] = L_max · E[|cluster(v)|]

Predictions below derived from these formulas ONLY, no
substrate data consulted.

## Pre-registered predictions for n=20

| p%  | c=19p | regime         | f (numerical) | E[\|cluster\|] | E[phi-perc] |
|-----|-------|----------------|---------------|----------------|-------------|
|  5  | 0.95  | NEAR-CRITICAL  | 0 (formula)   | unbounded     | UNCERTAIN   |
| 10  | 1.9   | SUPERCRITICAL  | 0.715         | 10.84         | 108,400     |
| 15  | 2.85  | DEEP SUPER     | 0.910         | 16.68         | 166,800     |
| 20  | 3.8   | VERY DEEP      | 0.978         | 19.15         | 191,500     |
| 30  | 5.7   | NEAR-COMPLETE  | 0.997         | 19.88         | 198,800     |

## Pre-registered bounds (±15% allowance for finite-size + RNG noise)

| p% | predicted   | lower (±15%) | upper (±15%) | classification target |
|----|-------------|--------------|--------------|------------------------|
|  5 | UNCERTAIN   | 10,000       | 200,000      | wide (critical region) |
| 10 | 108,400     |  92,140      | 124,660      | tight bound            |
| 15 | 166,800     | 141,780      | 191,820      | tight bound            |
| 20 | 191,500     | 162,775      | 220,225      | tight bound            |
| 30 | 198,800     | 168,980      | 228,620      | tight bound            |

## Hypothesis structure

**H0 (null, classical-tracks-substrate):** substrate phi-perc
matches classical ER prediction within ±15% at ALL p in {10, 15,
20, 30}%.  (p=5% has wide bound, doesn't discriminate.)

**H1 (substrate-deviates):** substrate phi-perc falls OUTSIDE
classical ±15% bound at one or more p in {10, 15, 20, 30}%.

## Falsification rules (pre-committed)

- If ALL 4 tight-bound predictions match within ±15%: H0 not
  rejected.  Substrate is consistent with classical ER theory
  at n=20 to ±15%.  **NULL FINDING.** (Not exciting but honest:
  substrate behaves like ordinary random graph reachability.)
- If 1-2 predictions deviate outside bound: weak evidence of
  substrate-specific behavior.  Investigate regime where deviation
  occurs.
- If 3+ predictions deviate outside bound: substrate diverges
  systematically from classical ER.  **POSITIVE FINDING** of
  substrate-derived correction.

## Methodological commitments

1. Demo 124 source written AFTER this file is committed.
2. Demo 124 will run M=5 seeds × K=20 samples = 100 random
   G(20, p) graphs per p.
3. Results reported regardless of outcome.
4. NO bound adjustment after seeing data.  If predictions miss,
   miss is reported.  If theory needs revision, revision is
   separate cycle (cycle 9).
5. Substrate measurement is the experimental variable; classical
   ER is the theoretical reference.

## Predicted SCENARIO outcomes (rough estimates)

I expect (based on intuition, not on substrate data — author
guess BEFORE running):

1. **Most likely (60%):** substrate matches classical within
   ±15% at p ≥ 15%, possibly deviates at p=10% (closer to
   critical for n=20, where finite-size corrections are large).
2. **Possible (25%):** all 4 tight bounds match.  Substrate
   tracks classical to ±15% accuracy.  Boring but valid result.
3. **Possible (15%):** substantial deviation at multiple p
   values — substrate has systematic correction or set-semantics
   effect not captured in classical theory.

ALL scenarios are reportable.  No fallback claim if
disconfirmed; null result honest.

## Connection to RESULTS.md

After demo 124 runs, this PREDICTIONS file remains immutable.
Measurement report goes into RESULTS.md "CYCLE 8" section
referencing this file by its git-committed hash.

This is the **first cycle in catalogue with binding pre-
registration in git history** that predates measurement.
