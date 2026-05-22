# Substrate-Equivalence Conjectures and Counter-Example Search

**Date:** 2026-05-22 (cycle 12B)

**Purpose:** formalize the falsifiable claims about Sixth substrate
that cycle 12+ tests via counter-example search.  This document
replaces hand-waving about "substrate-derived findings" with
specific conjectures whose disproof requires a SINGLE concrete
counter-example.

This follows the OpenAI-style methodology (Habr 1037534,
2026-05-22) where Erdős's 1946 unit-distance hypothesis was
disproved by computational counter-example search rather than
by general-theoretic argument.

---

## Three conjectures about Sixth substrate

### CONJECTURE 1 — Computational equivalence of Φ-family

> For every Φ defined in `stdlib/phi.6th` (phi-pa, phi-integ,
> phi-bidir, phi-pa-witness, phi-perc), and any substrate S,
> observer O: Φ(S, O) is a function of the labeled binary
> multi-graph encoding of S (where labels include
> hyperedge-type and direction).
>
> **Status: TRUE by inspection.**  Confirmed without search.
> Each Φ in stdlib/phi.6th is written as a finite composition
> of classical graph operations (OUT, IN, EDGE?, BFS, NSUM)
> that depend only on edge structure with labels.  No Φ in
> the family uses substrate-only state.

**Implication:** any cycle testing substrate vs networkx
"classical" reference where networkx uses appropriate edge
labels MUST find substrate ≡ classical.  Cycles 9, 11A, 11A.1
confirmed this for phi-perc and phi-integ on bi-edge substrate.

This conjecture does NOT need a counter-example search — it's
true definitionally.  Listed here so the catalogue knows what
is and is NOT a falsifiable target.

### CONJECTURE 2 — Storage advantage bound (the falsifiable one)

> For any substrate S consisting of n nodes and k HEDGE3
> triadic typed hyperedges, the storage ratio
>
>   R(S) = StorageCost_HEDGE3(S) / StorageCost_min_binary_equiv(S)
>
> is bounded:
>
>   1/F ≤ R(S) ≤ 1/F'   for constants F, F'.
>
> Demo 105 (commit pending) measured R ≈ 5 for triadic
> WITNESS-query substrates at small n.  CONJECTURE 2 says
> this is a CONSTANT-FACTOR advantage, NOT super-constant.

**Falsifying counter-example would be:**
- A substrate configuration where R(S) GROWS with n (super-
  constant advantage), or
- A substrate configuration where R(S) < 1 (binary encoding
  is MORE compact, contradicting expected advantage).

**Either outcome is a substrate-derived finding:**
- R(S) grows with n → HEDGE3 has scaling advantage; substrate
  is essential (not just ergonomic) at large scale.
- R(S) < 1 → HEDGE3 is wasteful for some configurations;
  bound the regime where it's actually better.

**Cycle 12C tests this** via exhaustive enumeration of small
HEDGE3 substrates (n=3..6, hyperedges up to all triples).

### CONJECTURE 3 — Computational ergonomics

> No substrate primitive computes a measurement that classical
> graph theory cannot define algorithmically (with arbitrary
> labeling).
>
> **Status: TRUE by inspection.**  Every substrate primitive
> (MARK, EDGE+, OUT, IN, NSET, NGET, NSUM, STEP-CA, BFS) has a
> classical algorithmic equivalent on labeled graphs.

**Implication:** substrate offers no purely COMPUTATIONAL
advantage at the level of expressibility.  Advantages, if any,
are in (a) storage cost (Conjecture 2), (b) ergonomic concision
(single primitive vs multi-step code).

(b) is measurable as code-length / cognitive-load metric but
not naturally falsifiable as a research finding.  Skipped.

---

## What this triplet means for the research programme

Of the three conjectures, ONE is genuinely falsifiable via
search: Conjecture 2 (storage bound).  Conjectures 1 and 3
are true by construction of the substrate implementation we
ship.

**Therefore:** any substrate-derived finding the catalogue
will ever produce must come from disproving Conjecture 2
(super-constant HEDGE3 storage advantage) OR from a fundamentally
different substrate primitive not currently in Sixth (HEDGE4,
typed cycle structures, etc., none of which exist as of cycle 12).

**Catalogue current state after this formalization:**
- Conjecture 1: confirmed true (substrate ≡ classical for Φ-family)
- Conjecture 2: untested at scale; cycle 12C runs counter-example search
- Conjecture 3: confirmed true (substrate ≡ classical computationally)

This is the HONEST methodological framing.  Previous cycles'
attempts to find "substrate-derived findings" via Φ-family
measurements on bi-edge ER ensembles were destined to confirm
Conjecture 1; we now know this in advance.

---

## Counter-example search methodology (cycle 12C)

### Configuration space

- n ∈ {3, 4, 5, 6} nodes
- HEDGE3 typed hyperedges: subset of all `n × n × n = n³`
  ordered triples (s, d, w), kind ∈ {WITNESS, MEDIATOR,
  CONTEXT, SIMPLEX}
- bi-edges: independent of hyperedges (subset of pairs)
- For each configuration: compute R(S) = HEDGE3-storage /
  minimal-binary-with-attribute-equivalent storage

### Storage metrics (concrete)

- **HEDGE3 storage**: 5 fields per hyperedge (s, d, w, kind, id).
  Per HEDGE3 cost = 5.  Total for k hyperedges = 5k.
- **Binary-equivalent storage** (per demo 105): each HEDGE3 becomes
  1 auxiliary node + 4 binary edges (3 for triadic structure +
  1 for kind label).  Per HEDGE3 cost = 1 aux node + 4 edges + 1
  edge-label = 6.  Total = 6k.
- Ratio R(S) = 5k / 6k = 5/6 ≈ 0.83 (HEDGE3 is 17% MORE compact
  than this binary encoding).

Wait — this isn't 5× advantage like demo 105 reported.  Either
demo 105's encoding scheme was sub-optimal, or my arithmetic
here is wrong.  Either way: the actual ratio is the target
of cycle 12C search.

### Search algorithm

```python
for n in [3, 4, 5, 6]:
    for k in [1, 2, ..., n³]:
        for typed_triples in combinations(all_triples_with_kinds, k):
            S = build_substrate(n, typed_triples)
            R = storage_HEDGE3(S) / storage_min_binary(S)
            if R > F_max_so_far or R < F_min_so_far:
                log(S, R)  # candidate counter-example
                update_bounds()
```

### Counter-example criteria

- **R > 2.0** on any S: HEDGE3 has at least 2x storage advantage
  over best binary encoding at this n.  If this happens for
  small n=3..6, it likely persists at large n.
- **R grows with n**: super-constant scaling.  Stronger evidence
  HEDGE3 is fundamentally more compact.
- **R < 1**: HEDGE3 is wasteful here — binary encoding is more
  compact.  Negative finding but informative.

### Comparison "minimal binary" choice

We use the encoding that's most compact while preserving the
ability to:
1. Reconstruct the (s, d, w, kind) tuple uniquely from binary
2. Compute Φ-family equivalents on the binary graph

The "min_binary" computation is itself a graph-theoretic
optimization problem.  For small n we enumerate candidate
encodings; cost is acceptable for n ≤ 6.

---

## Connection to METHODOLOGY.md

Cycle 12C compliant with all 9 rules:
- Rule 1: this doc committed before search script
- Rule 2: Habr 1037534 (Erdős/OpenAI), demo 105 (Sixth)
- Rule 3: exhaustive enumeration, no statistical noise
- Rule 4: regimes K (R > 2), L (R < 1), M (1 ≤ R ≤ 2)
- Rule 5: this is FIRST search; cross-validate at larger n
- Rule 6: outcome will update aggregate count
- Rule 7: storage ratio is NOT a tautology — depends on which
  binary encoding is chosen
- Rule 8: scope claim limited to n ≤ 6
- Rule 9: PREDICTIONS-131.md attests this conjecture file in
  the next commit

---

## Pre-registered prediction (regime classifier for cycle 12C)

After running enumeration:

| regime | condition           | meaning                                          |
|--------|--------------------|--------------------------------------------------|
| **N**  | max R(S) > 2.0     | counter-example found; HEDGE3 has > 2× advantage at some config |
| **O**  | max R(S) ∈ [1.5, 2] | HEDGE3 advantage exists but modest, within range demo 105 hinted |
| **P**  | max R(S) ∈ [1, 1.5) | HEDGE3 barely advantageous; demo 105's "5x" was sub-optimal binary encoding |
| **Q**  | max R(S) < 1      | HEDGE3 is wasteful for tested configs; advantage vanishes |

Author guess:
- N (advantage > 2x): 20%
- O (modest 1.5-2x): 30%
- P (barely advantageous): 35%
- Q (wasteful): 15%

Most informative outcomes: **N** (real substrate finding) or
**Q** (retract HEDGE3 advantage claim).

---

## What this DOESN'T promise

This methodology cannot produce a finding "substrate has
consciousness measure that classical graph theory lacks".
That claim is foreclosed by Conjecture 1 (true by construction).

Cycle 12+ specifically targets **substrate engineering
properties** (storage, ergonomics) — the only remaining domain
where substrate can differ from classical without contradicting
its own definitions.

If the user wants substrate to demonstrate something stronger,
the substrate's Φ-family definitions would need to be revised
to use STATE that's not classical-graph-encodable.  This is
a substrate REDESIGN task, not a measurement task.
