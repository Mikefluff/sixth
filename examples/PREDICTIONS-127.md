# Demo 127 — Pre-Registered Predictions (cycle 10C)

**Date pre-registered:** 2026-05-22

**Critical commitment:** committed to git BEFORE demo 127 source.
Attested via `scripts/attest_prediction.sh` per METHODOLOGY.md
Rule 9.  This is the first pre-registration that pivots from
phi-perc on bare graphs (which cycle 9 showed is a tautology
of classical graph theory) to phi-integ on feature-loaded
substrate, where the measure has higher-order moment content.

---

## Why this cycle (CS-doctor pivot)

Cycle 9 CS-doctor critique #7 (tautology detection): phi-perc
on bare ER reduces to `|connected_component| × L_max`, a unit
test of substrate BFS against networkx BFS.  Cycle 10A
confirmed faithfulness but **did not produce a substrate-derived
finding** beyond classical graph theory.

Where COULD substrate-derived content live?  Per Track 2.1b
(demo 108, RESULTS.md): **phi-integ is the only Φ-family
member with nonlinear response to substrate density**.  It
depends on observer's neighbours' features (NSUM), not just
component membership.  Feature-load each node with its OUT
count: `phi-integ(O) = OUT(O) · self-ref · NSUM(O) · L_max`,
where `NSUM(O) = sum over out-neighbours v of NGET(v)`.

On random ER substrate this is `sum of (OUT(v) for v in N(O) ∪ {O})`
weighted by `OUT(O)` — a **degree-degree correlator**, second
moment of degree sequence.  This is information classical
ensemble means do NOT capture by themselves.

---

## Theoretical setup

For G(n, p) undirected simple graph, observer = node 1 with
self-loop, all bi-edges otherwise:

- `OUT(1)` = 1 (self-loop) + binomial(n-1, p) bi-edges out of 1.
  `E[OUT(1)] = 1 + (n-1)p`
- `OUT(v)` for v ≠ 1 = binomial(n-1, p) bi-edges
  (no self-loop on non-observers).  `E[OUT(v)] = (n-1)p`
- Observer's out-neighbours: `{1} ∪ {v : bi-edge(1,v)}`.
- `NSUM(1) = OUT(1) + Σ_{v: (1,v) bi-edge} OUT(v)`

### Analytic expectation (independence approximation)

Under independence between OUT(1) and the OUT(v)'s for
v ≠ 1 (which is an approximation, not exact — they share
the (1,v) edge indicator):

```
E[OUT(1)]           = 1 + (n-1)p
E[NSUM(1)]          = E[OUT(1)] + (n-1)·p·E[OUT(v) | edge (1,v)]
E[OUT(v) | (1,v)]   = 1 + (n-2)p   (one edge to 1, plus binomial(n-2, p))
E[phi-integ(1)]     = E[OUT(1)] · E[NSUM(1)] · L_max         (independence!)
```

For n=20, p=0.10, L_max = 10000:
- `E[OUT(1)] = 1 + 19·0.10 = 2.9`
- `E[OUT(v) | (1,v) edge] = 1 + 18·0.10 = 2.8`
- `E[NSUM(1)] = 2.9 + 19·0.10·2.8 = 2.9 + 5.32 = 8.22`
- `E[phi-integ(1)] ≈ 2.9 · 8.22 · 10000 ≈ 238,380` (independence)

### Why independence is wrong (and how it would bias)

`OUT(1)` and `Σ_{v: (1,v)} OUT(v)` are positively correlated:
when `OUT(1)` is high, more terms enter the NSUM sum.  But
within the sum, each `OUT(v) | (1,v) edge` is the same
expectation, and edges other than (1,v) are independent.

The product expectation includes:
`E[OUT(1) · NSUM(1)] = E[OUT(1) · OUT(1) + OUT(1)·Σ_{v: (1,v)} OUT(v)]`
            `= E[OUT(1)²] + E[OUT(1)·Σ_{v: (1,v)} OUT(v)]`

`E[OUT(1)²] = Var(OUT(1)) + E[OUT(1)]² = (n-1)p(1-p) + (1+(n-1)p)²`
        for n=20, p=0.1: `= 19·0.10·0.90 + 2.9² = 1.71 + 8.41 = 10.12`

The cross term `E[OUT(1)·Σ_{v: (1,v)} OUT(v)]`: by exchangeability,
sum over the n-1 candidate v's of
`E[I(1,v) · OUT(1) · OUT(v)]`.  Given the (1,v) edge exists:
- `OUT(1) = 1 + I(1,v) + Σ_{w ≠ v} I(1,w) = 1 + 1 + binomial(n-2, p)`
- `OUT(v) = I(1,v) + Σ_{w ≠ 1} I(v,w) = 1 + binomial(n-2, p)`
- conditional on edge (1,v), OUT(1) and OUT(v) are independent
  (different binomials over disjoint edge sets, given edge (1,v))
- `E[OUT(1) · OUT(v) | (1,v) edge] = (2 + (n-2)p) · (1 + (n-2)p)`
   for n=20, p=0.1: `= 3.8 · 2.8 = 10.64`

So per v: `p · E[OUT(1) · OUT(v) | (1,v)] = 0.10 · 10.64 = 1.064`
Sum over (n-1) v's: `19 · 1.064 = 20.22`

`E[OUT(1) · NSUM(1)] = 10.12 + 20.22 = 30.34`
`E[phi-integ(1)] = 30.34 · 10000 = 303,400` (exact under
linearity-of-expectation, accounting for correlations)

### Comparison: independence vs corrected

- Independence approximation: 238,380
- Correlation-corrected:      303,400
- Ratio:                      1.273

The independence approximation underestimates by ~27%.
This is itself a non-trivial result: **degree-degree
correlation contributes ~27% of `E[phi-integ]` even for
uncorrelated edges**.  Real classical Erdős-Rényi has
this effect; substrate should reproduce it.

---

## Pre-registered regimes (no gap, per Rule 4)

Substrate M=1000 mean `m_phi_integ` at n=20, p=10%:

| regime | range                  | meaning                                                                  |
|--------|-----------------------|--------------------------------------------------------------------------|
| **D**  | [275,000, 330,000]     | Matches correlation-corrected analytic 303,400 ± ~10%.  Substrate reproduces classical higher-moment ER theory faithfully. |
| **E**  | [210,000, 275,000)     | Closer to independence approximation 238,380.  Substrate appears to "miss" degree-degree correlations.  Would be a substrate-specific bug or feature. |
| **F**  | < 210,000 or > 330,000 | Unanticipated.  Investigate via Python reference. |

Boundaries set so:
- D contains 303,400 ± 9% (matches correlation-corrected derivation)
- E contains 238,380 ± 15% (matches independence approximation)
- F is the rest

These ranges partition outcome space without gap.

### Falsification commitments

- **Regime D** → substrate faithful at second-moment level too;
  reproduces ~27% degree-correlation contribution to E[phi-integ].
  **Promotion**: phi-integ becomes substrate-validated higher-
  moment measure on bare ER.  Cycle 11+ can move to STEP-CA
  dynamics where networkx has no direct analog.
- **Regime E** → substrate misses correlation; behaves like
  independence approximation.  **This would be a substrate-
  specific anomaly worth investigating** — bi-edge semantics
  or NSUM implementation drops the correlation.
- **Regime F** → bug or unexpected behaviour.  Cycle 11+ needs
  Python phi-integ reference for diagnosis.

### Sub-prediction (sanity)

Sub-prediction 1: substrate sample stddev should be in
range [400,000, 1,200,000].  Variance of OUT(1)·NSUM(1)
is large because both factors fluctuate, and product
variance can be substantial.  Outside this range → RNG
or feature-load implementation suspect.

Sub-prediction 2: E[OUT(1)] alone at M=1000 should be
within [2.6, 3.2].  Direct sanity check on RNG.

### Author guess (recorded, non-binding)

- Regime D (matches correlation-corrected): **65%**
- Regime E (matches independence approximation): **20%**
- Regime F (unanticipated): **15%**

I lean D because substrate has no reason to miss correlations
— bi-edge is symmetric, NSUM iterates over out-edges directly.
But cycle-8/9 humility says 65% not 90%.

---

## Methodological commitments (binding)

1. `examples/127-feature-loaded-phi-integ.6th` written AFTER
   this file committed.  Git timestamp proves.
2. Demo run AFTER both files committed.
3. Result reported regardless of regime; NO post-hoc adjustment.
4. M=50 seeds × K=20 = 1000 graphs at n=20, p=10%.  Same RNG
   (LCG via stdlib/rand.6th).  All nodes feature-loaded with
   NSET-OUT after each graph generation.
5. Each node feature-loaded; demo 124's all-self-loops-on-observer-only
   strategy is INSUFFICIENT here — phi-integ needs NSET on every
   node so NSUM can read neighbour features.
6. Attestation: this file attested via attest_prediction.sh
   BEFORE source written.

## Connection to METHODOLOGY.md

This is the first cycle authored under METHODOLOGY.md.  Rule
compliance checklist:
- [x] Rule 1: file committed before demo source
- [x] Rule 2: literature citation — degree-degree correlation
      in ER is in Newman's *Networks* (2nd ed., 2018) §13.4;
      independence approximation breakdown noted in Janson-
      Łuczak-Ruciński §3.
- [x] Rule 2: regime validity — exact within sampling for n=20
      finite (Bollobás Ch. 6).
- [x] Rule 3: M=1000; reference if needed at M=10× via Python
- [x] Rule 4: regimes partition without gap
- [x] Rule 5: this is a first measurement of phi-integ ensemble
      (single cycle, future cycle should cross-validate)
- [x] Rule 6: aggregate count will be updated post-measurement
- [x] Rule 7: phi-integ on feature-loaded ER is NOT a tautology
      of classical reachability — it depends on second-moment
      of degree distribution, beyond connected-component size
- [x] Rule 8: scope claim limited to n=20, p=10%, feature-load=OUT
- [x] Rule 9: will attest via attest_prediction.sh before commit
