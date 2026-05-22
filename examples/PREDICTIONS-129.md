# Demo 129 — Pre-Registered Predictions (cycle 11A.1)

**Date pre-registered:** 2026-05-22

**Critical commitment:** committed AFTER attestation.  Resolves
cycle 11A regime F' ambiguity — was the 12,927 substrate-vs-
reference deviation real or sampling artifact at substrate M=1000?

---

## Background

Cycle 11A (commit `308fbe3`) showed:
- ref (networkx, M=10000):  310,577 ± SEM 3,275
- substrate (cycle 10C, M=1000): 297,650 ± SEM 9,737
- |diff| = 12,927  (1.26σ combined SEM)

Regime F' fired per pre-reg threshold 5000, but the deviation
is within combined 2σ.  The question: at substrate M=10000
(matching reference precision), does substrate converge to
310,577 (sampling artifact) or stay near 297,650 (real bias)?

This is THE decisive test for whether cycle 11A's "first
substrate-derived deviation" finding is a real phenomenon or
a small-M artifact.

---

## Theoretical setup

Substrate phi-integ at n=20, p=10%, with:
- All bi-edges with p=10% (LCG via stdlib/rand.6th)
- Observer self-loop on node 1
- NSET each node to its OUT count
- Sample size: **M=500 seeds × K=20 samples = 10,000 graphs**

Substrate SEM at M=10000 should be:
  stddev / sqrt(10000) ≈ 308074 / 100 = 3,081

This matches reference SEM 3,275 (both at ~3000).  Combined SEM
≈ sqrt(3081² + 3275²) ≈ 4,497.

A deviation of 12,927 from reference would be 12927/4497 ≈
**2.87σ** — significant.  If it persists, real bias.

A deviation of <5,000 would be within ~1σ combined — sampling
artifact.

---

## Pre-registered regimes (no gap, partition)

`sub_m10k` = substrate phi-integ mean at M=10000.
Reference: 310,577.

| regime | condition                          | meaning                                                |
|--------|------------------------------------|--------------------------------------------------------|
| **H**  | |sub_m10k - 310,577| ≤ 5,000        | substrate CONVERGES to ref; cycle 11A F' was sampling artifact; substrate fine; cycle 10C effectively confirmed |
| **I**  | 5,000 < |sub_m10k - 310,577| ≤ 12,000 | substrate stays partially low; possibly real bias of ~2%; investigate cycle 12   |
| **J**  | |sub_m10k - 310,577| > 12,000        | substrate has CONFIRMED systematic deviation ≥4%; cycle 10C/11A finding STANDS as real substrate-derived bias |

Threshold 5,000 chosen to be slightly more than ref SEM 3,275
(generous to substrate).  Threshold 12,000 chosen as 1× the
original cycle 11A deviation 12,927.

### Falsification consequences

- **Regime H** → cycle 11A regime F' was sample-size artifact.
  Substrate is faithful at second-moment level after all.
  Cycle 10C effectively confirmed (with caveat that cycle 10C
  M=1000 wasn't tight enough to discriminate).
- **Regime I** → substrate has small but real bias.  Cycle 12
  investigates source (LCG?  bi-edge?  feature-load order?).
- **Regime J** → substrate has confirmed ≥4% systematic
  deviation from networkx reference.  REAL substrate-derived
  finding: substrate phi-integ ensemble differs from classical.
  Investigate cause; if reproducible, this is the first cycle
  to demonstrate substrate behavior diverging measurably from
  classical Monte Carlo.

### Sub-prediction

Substrate stddev at M=10000 should be within ±5% of M=1000
substrate stddev (308,074).  Predicted bounds [292,670, 323,478].
Outside → ensemble variance is sample-size-dependent
(suspicious; classical ensembles have stable variance).

### Author guess (non-binding)

- Regime H (sampling artifact): **65%** — most likely; M=1000 
  was on the edge of resolution.
- Regime I (small bias): **25%** — possible if LCG-RNG has
  ~1-2% rate-bias relative to MT.
- Regime J (real bias ≥4%): **10%** — would be the first cycle
  with a substrate-derived deviation finding that survives
  independent reference.

Most informative outcome: **J** (real substrate finding).
Most likely: **H** (substrate faithful).

---

## Methodological commitments (binding)

1. `examples/129-substrate-phi-integ-m10k.6th` written AFTER
   this file committed.
2. Demo run AFTER both files committed.
3. Result reported regardless; NO post-hoc bound adjustment.
4. M=500 seeds × K=20 samples = 10,000 graphs (matches ref M).
5. Same LCG-RNG, same bi-edge, same feature-load as cycle 10C
   — only sample size changes.
6. If demo runtime > 60s, halve to M=250 × K=20 = 5000 and
   note in commit.
7. Attestation via `attest_prediction.sh` BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: lit — phi-integ semantics direct, no asymptotic
- [x] Rule 3: M=10000 matches reference precision
- [x] Rule 4: regimes partition without gap
- [x] Rule 5: this IS Rule 5 cross-validation cycle for 11A
- [x] Rule 6: aggregate count updated post-measurement
- [x] Rule 7: substrate-vs-ref is not a tautology — different
      implementations of the same observable, can diverge.
- [x] Rule 8: scope n=20, p=10%, observer-with-self-loop only
- [x] Rule 9: attest before commit
