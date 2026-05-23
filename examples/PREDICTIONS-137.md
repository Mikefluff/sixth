# Demo 137 — Pre-Registered Predictions (cycle 18)

**Date pre-registered:** 2026-05-22

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Insight (user-supplied, cycle 18)

Cycle 12 measured HEDGE3 vs binary storage and found NO advantage
(REGIME O, R_max = 1.5×, mean 1.13-1.23× WORSE).  But the test
treated each HEDGE3 as isolated 5-field record — no observer-
grouping semantics.

The Pointer Architecture insight: **observer perceives stable group
as 1 unit referenced inside itself** ("это теперь 1 — внутри меня",
matryoshka).  Group stored ONCE in substrate, referenced N times by
observers.

When N observers share a group of K members:
- Flat encoding: N × K edge records (each observer → each member)
- Matryoshka:    K members in group + N pointers to group = K + N records
- Compression ratio: (N+K) / (N×K)

Asymptotically:
- As K grows with N fixed: ratio → 1/N
- As N grows with K fixed: ratio → 1/K
- Diagonal N=K: ratio → 2/K → 0

This is **substrate-derived compression** that:
1. Classical graph theory doesn't naturally express (graph storage
   is observer-independent)
2. Implementable in current Sixth using MARK + bi-edge (no new primitives)
3. Falsifiable: predict (N+K)/(N×K) scaling and verify

---

## Methodology

`stdlib/group.6th`:
- `perceive-group ( -- group-id )` — MARK new node as group
- `add-to-group ( group member -- )` — bi-edge group → member
- `share-group ( observer group -- )` — bi-edge observer → group

`examples/137-matryoshka-storage.6th`:

For each (N, K) ∈ {(2,2), (3,5), (5,5), (10,10), (5,20), (20,5)}:
1. **Flat encoding**: build substrate with N observers, K members,
   N×K direct edges observer → member.  Measure EDGES count.
2. **Matryoshka encoding**: build substrate with N observers, K members,
   1 group, K group→member edges, N observer→group edges.  Measure EDGES.
3. Compute R(N,K) = flat_edges / matryoshka_edges

Predict R(N,K) = (N×K) / (N+K).

---

## Pre-registered regimes (no gap, partition)

For the 6 (N,K) test points, compute observed vs predicted R per point.
Aggregate: mean absolute relative error between observed and predicted.

`MARE = mean |R_observed - R_predicted| / R_predicted` across all 6 points.

| regime | condition | meaning |
|--------|-----------|---------|
| **KK** | MARE < 0.10 (within 10%) | matryoshka scaling CONFIRMED → substrate-derived compression demonstrated |
| **LL** | MARE ∈ [0.10, 0.50] | partial fit; pattern correct but magnitude off |
| **MM** | MARE > 0.50 | matryoshka scaling NOT achieved → implementation broken or theory wrong |

### Sub-prediction

Specific R values:
- R(2,2) = 4/4 = 1.0
- R(3,5) = 15/8 = 1.875
- R(5,5) = 25/10 = 2.5
- R(10,10) = 100/20 = 5.0
- R(5,20) = 100/25 = 4.0
- R(20,5) = 100/25 = 4.0

If MARE < 10% these specific values match within tolerance.

### Falsification consequences

- **Regime KK** → matryoshka pattern WORKS in current Sixth using
  existing primitives.  Substrate-derived compression demonstrated:
  observer-grouping gives genuine storage reduction when groups are
  shared.  First substrate-derived **engineering** finding that
  classical graph theory doesn't naturally capture.
- **Regime LL** → pattern partially works; magnitude wrong.
  Investigate primitive limitations.
- **Regime MM** → matryoshka broken; either substrate primitives
  insufficient OR theory wrong.

### Connection to Φ-family

If KK fires, define `phi-pa-matryoshka(O)` in future cycle: counts
group-pointers (treating each group as 1 unit from observer POV).
Recursive: groups containing group-refs counted recursively.

Conjecture (deferred to cycle 19): phi-pa-matryoshka exhibits
nonlinear scaling with observer's perceived structure depth,
unlike phi-pa which is linear in scope.

### Author guess (non-binding)

- Regime KK (matryoshka works): **75%** — pattern is straightforward
  and uses existing primitives correctly; should work
- Regime LL (partial): **15%** — possible if EDGES counter has subtle
  off-by-one for shared structure
- Regime MM (broken): **10%** — unlikely; uses well-tested primitives

Most informative: KK confirms substrate-derived engineering finding;
MM would force redesign.

---

## Methodological commitments (binding)

1. stdlib/group.6th written AFTER this file committed.
2. Demo source AFTER both.
3. Result reported regardless.
4. Substrate primitives: ONLY existing MARK + bi-edge + EDGES (no
   new primitives added).
5. 6 (N,K) test points exactly as specified above; no cherry-picking.
6. Reproducibility: deterministic construction (no RNG).
7. Attestation BEFORE commit.

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 12 retraction commit 0beac84 referenced;
      Hofstadter (1979) Gödel-Escher-Bach on strange loops as
      conceptual basis for nested grouping
- [x] Rule 3: deterministic 6-point test, no statistical sample
- [x] Rule 4: KK/LL/MM partition without gap
- [x] Rule 5: first matryoshka test; cycle 19 would extend with
      phi-pa-matryoshka measure
- [x] Rule 6: aggregate count update post-result
- [x] Rule 7: matryoshka compression is NOT a tautology — depends
      on substrate primitive design supporting reference-by-pointer
- [x] Rule 8: scope = 6 specific (N,K) points, no extrapolation
- [x] Rule 9: attestation pending

## References

- Cycle 12 commit 0beac84 — HEDGE3 storage no-advantage finding
  (which matryoshka pattern addresses)
- Hofstadter (1979), Gödel, Escher, Bach — strange loops, nesting
- User insight 2026-05-22 — observer's "now this is 1 inside me"
  matryoshka principle
