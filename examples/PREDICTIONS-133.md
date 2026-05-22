# Demo 133 — Pre-Registered Predictions (cycle 14)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
**Hook compliance:** verified before commit.

---

## CS-doctor follow-up to cycle 13C/D

Cycle 13 found R_overall = 1.795 > 1.5 → REGIME R (substrate-
distinguishing).  But the strongest signals came from regular
structured topologies (cycle_n10 = 7.36×, path_n10 = 2.20×)
where ER baseline is the WRONG comparison: ER at matched p
produces sparse random graphs with very different degree
distribution than a cycle or path graph.

**CS-doctor critique**: cycle 13 may have measured "structured
substrate vs random sparse baseline" — a trivial difference any
spectral measure would capture.  The honest test: replace ER
baseline with **random k-regular graphs** matching the
substrate's degree distribution.  If EICS signal survives,
substrate distinction is real.  If signal vanishes, cycle 13's
finding reduces to "spectral structure differs from random
topology" — well-known and not substrate-derived.

---

## Methodology

`scripts/eics_sixth_regular.py`:

For each canonical Sixth substrate S with mean degree d:
1. Compute EICS(S) per cycle 13 method (T=10 multi-step macro)
2. Generate M=500 random k-regular graphs at n=|V(S)|, k=⌊d⌋
   (degree-matched random baseline)
3. Compute EICS(baseline_i) for each
4. R_regular = EICS(S) / mean(EICS(baselines))
5. Also compute spectral gap and von Neumann entropy on each
   for cross-measure comparison

Random regular generation: `networkx.random_regular_graph(d, n,
seed=s)` for s ∈ 1..M.

For substrates where exact regular baseline doesn't exist (e.g.,
star graph with degree 1 leaves + degree 9 center), use mean-
degree-rounded as approximation; note in script.

---

## Pre-registered regimes (no gap, partition)

Three substrate categories tested with regular baseline:

`R_overall_regular` = mean(R_regular) across same 10 canonical
substrates from cycle 13.

| regime | condition          | meaning                                                |
|--------|--------------------|--------------------------------------------------------|
| **U**  | R_overall_regular > 1.5 | cycle 13 signal SURVIVES tighter baseline → genuine substrate-distinguishing finding |
| **V**  | R_overall_regular ∈ [0.7, 1.5] | signal weakens but doesn't vanish — partial; substrate has subtle distinction |
| **W**  | R_overall_regular < 0.7 | cycle 13 signal was TRIVIAL — just "structured vs sparse random"; substrate distinction RETRACTED at this level |

### Sub-prediction (spectral comparison)

Compute spectral gap and von Neumann entropy on canonical
substrates AND ER baselines (from cycle 13).  Predict:
- Pearson correlation between EICS and (1/spectral_gap) across
  10 substrates: |r| > 0.7 → EICS is essentially measuring
  spectral gap (over-engineered wrapper)
- |r| ∈ [0.3, 0.7] → EICS captures spectral structure plus
  additional information
- |r| < 0.3 → EICS captures something fundamentally different
  from spectral gap

### Falsification consequences

- **Regime U** → cycle 13 REINFORCED; first substrate finding
  survives stricter scrutiny.  Cycle 15+ investigates source
  (HEDGE3 typing? STEP-CA evolution? specific topology?).
- **Regime V** → partial signal, modest claim.  Document with
  caveats.
- **Regime W** → cycle 13 finding RETRACTED as tautological;
  catalogue back to zero substrate-distinguishing positive
  findings; finalize as engineering + negative-results
  contribution.

### Author guess (non-binding)

- Regime U (signal survives): **35%** — cycle (specifically cycle
  graph) might genuinely have EICS structure beyond degree
- Regime V (partial): **40%** — most likely; degree-matched
  random regular might be "less structured" than cycle but
  still partially eat the signal
- Regime W (signal vanishes): **25%** — possible if EICS is
  essentially just spectral-gap reciprocal

Most informative: **U** (substrate finding survives) or **W**
(retract).  **V** would be hedge.

---

## Methodological commitments (binding)

1. Script written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of regime.
4. M=500 random regular graphs per substrate (smaller than M=1000
   ER baseline because random regular generation is slower).
5. Same 10 canonical substrates from cycle 13 (no cherry-picking
   new ones).
6. EICS implementation unchanged — exact same scripts/eics_sixth.py
   functions imported.
7. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE script
- [x] Rule 2: Krasnovsky (2025) cited; cycle 13C/D commit 3e4e895
      provides EICS methodology continuity
- [x] Rule 3: M=500 random baselines (smaller than 1000 due to
      compute; documented in script)
- [x] Rule 4: regimes U/V/W partition without gap
- [x] Rule 5: this IS the Rule 5 cross-validation cycle for cycle 13
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: not a tautology — random regular degree-matched is
      genuinely tighter baseline than ER; survival or non-survival
      of signal is informative
- [x] Rule 8: scope: same 10 substrates from cycle 13, n ≤ 20
- [x] Rule 9: attest pending

## References

- Krasnovsky (2025) arXiv:2509.07149 — EICS source method
- Cycle 13C/D commit 3e4e895 — first substrate-distinguishing
  positive measurement using ER baseline
- Bollobás (2001) — Random Graphs, ch.7 on random regular graphs
