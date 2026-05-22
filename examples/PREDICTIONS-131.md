# Demo 131 — Pre-Registered Predictions (cycle 12C)

**Date pre-registered:** 2026-05-22

**Attested:** committed AFTER `scripts/attest_prediction.sh` per Rule 9.

**Pre-commit hook**: should pass Rules 2/4/9 automatically.

---

## Falsifies Conjecture 2 from SUBSTRATE-EQUIV-CONJECTURE.md

Conjecture 2 (storage advantage bound):

> Storage ratio R(S) = StorageCost_HEDGE3(S) / StorageCost_min_binary_equiv(S)
> is bounded by a constant factor for HEDGE3 substrates.

Cycle 12C runs counter-example search on small substrates
(n ≤ 6 nodes, all combinations of HEDGE3 typed hyperedges)
to find configurations where R(S) is extreme.

---

## Methodology

`scripts/search_substrate_counterexample.py`:

1. For each n ∈ {3, 4, 5, 6}:
2.   For each k ∈ {1, 2, …, max_k}:
3.     Sample / enumerate HEDGE3 hyperedge sets of size k
4.     For each substrate S:
5.       Compute HEDGE3 storage cost: 5k (per-hyperedge fields)
6.       Compute minimal binary encoding storage cost
7.       Compute R(S) = HEDGE3 / binary
8.     Track max R, min R, and configurations achieving extremes

Reference: Schaeffer (1997) "Graph algorithms on hypergraphs"
re. hypergraph-to-graph encoding cost; demo 105 (cycle 1).

### Binary encoding (the cost we compare against)

For each HEDGE3 hyperedge (s, d, w, kind):
- Add 1 auxiliary node `H_id` representing the hyperedge identity
- Add 3 binary edges: (H_id, s), (H_id, d), (H_id, w) [structural]
- Add 1 edge label: kind ∈ {WITNESS, MEDIATOR, CONTEXT, SIMPLEX}
- Total per hyperedge: 1 aux node + 4 edges = 5 storage units
  (1 for the node, 1 for the kind label, 3 for structural edges)

**Hmm: that's 5 binary units per hyperedge vs 5 HEDGE3 fields per
hyperedge.  Naive ratio R ≈ 1.0.**

Wait — demo 105 reported 5× advantage.  Let me recheck what
demo 105's encoding actually was.

(This sanity check needs to happen during 12C run; if naive
encoding gives R ≈ 1, then demo 105's "5x" was overstating.
That itself is informative.)

---

## Pre-registered regimes (no gap, partition)

`R_max` = maximum R(S) found over all enumerated substrates.

| regime | condition          | meaning                                                 |
|--------|--------------------|--------------------------------------------------------|
| **N**  | R_max > 2.0        | counter-example to "constant factor only" — HEDGE3 has > 2x advantage at some config; substrate-derived finding |
| **O**  | R_max ∈ [1.5, 2.0]  | modest advantage exists; HEDGE3 useful but bounded     |
| **P**  | R_max ∈ [1.0, 1.5)  | barely better; demo 105's "5x" was likely sub-optimal binary baseline |
| **Q**  | R_max < 1.0         | HEDGE3 is WASTEFUL; binary encoding more compact; retract demo 105 advantage claim |

### Falsification consequences

- **N** → first substrate-derived advantage finding in catalogue.
  Encode best counter-example as `demo 132`; cycle 13 extends
  search to larger n.
- **O** → modest advantage; document and move on.
- **P** → re-examine demo 105's encoding; previous "5×" may
  have used a sub-optimal binary scheme.
- **Q** → HEDGE3 has NO storage advantage; retract demo 105's
  claim; substrate's only remaining benefit is ergonomics.

### Author guess (non-binding)

- N: 20% — possible if some HEDGE3 configurations are denser
  than triangle encoding allows for.
- O: 30%
- P: 35% — most likely; demo 105 probably overstated.
- Q: 15%

Most informative: **N** (substrate-derived finding) or **Q**
(retract previous claim, narrower scope).

---

## Methodological commitments (binding)

1. `scripts/search_substrate_counterexample.py` written AFTER
   this file committed.
2. Enumeration run AFTER both committed.
3. Result reported regardless of regime.
4. Exhaustive enumeration at n=3, 4, 5; sampled at n=6 (full
   enumeration cost is 4⁵⁴⁰ which is intractable).
5. Sample budget: 10,000 random configurations per (n, k).
6. Reproducibility: Python random seeded with 12345.
7. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: before source
- [x] Rule 2: Schaeffer (1997), demo 105 cited
- [x] Rule 3: exhaustive at small n
- [x] Rule 4: regimes N/O/P/Q partition without gap
- [x] Rule 5: first search; cycle 13 extends
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: storage ratio not a tautology — depends on
      binary encoding choice
- [x] Rule 8: scope n ≤ 6
- [x] Rule 9: attestation pending
