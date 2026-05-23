# Research-Track Results

Ongoing log of substantive findings from research tracks 1–4 (see
`docs/RESEARCH-PLAN.md` for the long-form plan; this document is the
**short-form result tracker**).

Each entry: hypothesis → method → outcome → consequence for the
v9.0 preprint claims.  Both positive and negative results are
catalogued — null results are research output, not failure.

---

## Track 1 — Formal foundations

### 1.3 HEDGE3 expressivity separation — **NEGATIVE** (2026-05-21)

**Hypothesis (under test):** the HEDGE3 typed trivalent hyperedge
primitive realises Peirce's reduction thesis as a substrate-level
computational-complexity argument — there exists a query class
polynomial-time on HEDGE3-substrate, super-polynomial without.

**Method:** demo
[`examples/105-hedge3-expressivity-vs-binary.6th`](examples/105-hedge3-expressivity-vs-binary.6th)
(21 ✓).  Implement the same triadic-pattern query Q(s,d) = {w | (s,d,w)
is WITNESS} on two equivalent substrate encodings:
- (A) HEDGE3-native: 5 hash entries
- (B) Binary-encoded with role-tagged auxiliary nodes: 20 aux nodes +
  30 binary edges

Verify queries return identical answers on identical logical content;
compare asymptotic complexity and constant factors.

**Outcome:** **no complexity-class separation.** Both encodings are
O(N) per query with proper indexing.  HEDGE3 provides ~5× storage
advantage and ergonomic substrate surface — but the Peirce-reduction-
thesis claim as currently framed in the v9.0 preprint and SUBSTRATE.md
is not supported by direct substrate-level implementation.

**Consequence:** the SUBSTRATE.md HEDGE3 paragraph and README.md HEDGE3
row should downgrade from «substrate-level realisation of Peirce's
reduction thesis» to «ergonomic substrate-level surface for triadic-
relation patterns».  The Peircean **semantic typology** of the four
canonical kinds (WITNESS / MEDIATOR / CONTEXT / SIMPLEX) remains valid
as ontological framing; the **expressivity theorem** does not.

**Status:** demo 105 in regression gate.  Documentation downgrade
pending — see CHANGELOG.md and docs/ updates required.

---

## Track 2 — Discriminating computational evidence

### 2.1 Φ_PA family phase-transition search — **NEGATIVE** (2026-05-21)

**Hypothesis (under test):** the Φ_PA family of substrate-readable
consciousness measures exhibits phase-transition behaviour — a
discontinuity or critical exponent — under continuous variation of
substrate topological parameters.

**Method:** demo
[`examples/106-phi-pa-parametric-sweep.6th`](examples/106-phi-pa-parametric-sweep.6th)
(25 ✓).  Sweep observer out-degree k = 0..9 on a fixed-template
substrate with self-loop; measure phi-pa(k).  Compute first-difference
phi-pa(k+1) - phi-pa(k) for k = 2..7.  Test self-ref switch behaviour
by adding / removing the observer's self-loop.

**Outcome:** **phi-pa is exactly linear in scope** with constant slope
L_max = 10000.  Every first-difference equals 10000 — zero variance in
slope across the sweep.  No discontinuity, no critical exponent.  The
self-ref switch is a binary STEP (0 → scope·L_max), not a smooth
phase transition — topological indicator, not critical phenomenon.

**Consequence:** the Φ_PA family as currently defined (phi-pa,
phi-bidir, phi-pa-witness) does NOT replicate Tononi-IIT Φ-criticality
(Mediano 2019).  All three measures are degree-polynomial × self-loop-
step.  This is a substrate-derived BOUND on current Φ_PA expressive
power.

phi-integ is the only family member with nonlinear (cubic-in-density)
scaling via NSUM, but a full sweep requires feature-loaded random
substrate — **deferred to companion preprint #1** (Pythia attention).

**Open question:** future measures requiring phase-transition signatures
must introduce genuine nonlinearity (mutual information, KL-divergence
on substrate-state ensembles, percolation-theoretic order parameters).
None currently shipped in `stdlib/phi.6th`.

**Status:** demo 106 in regression gate.  Preprint section
§sec:phi-pa-alternatives should reflect this bound honestly.

### 2.1b phi-integ deferred density sweep — **PARTIAL POSITIVE** (2026-05-21)

**Hypothesis (under test):** phi-integ (the only nonlinear member of
the Φ-family) exhibits phase-transition or critical-exponent
behaviour that phi-pa lacks.

**Method:** demo
[`examples/108-phi-integ-density-sweep.6th`](examples/108-phi-integ-density-sweep.6th)
(24 ✓).  Build feature-loaded substrate (NSET every node to its
current OUT), sweep edge density from minimal (self-loops only) to
~75% saturated.  Measure phi-integ(observer) at 10 density milestones.

**Outcome:** **piecewise-linear two-regime response.**  Two distinct
slopes:
- Observer-saturation regime (k < n): ∆phi-integ per edge GROWS from
  50000 → 170000 as observer's own scope expands
- Neighbour-saturation regime (k >= n): ∆phi-integ per edge PLATEAUS
  at exactly 100000/edge

Crossover at the point observer reaches full scope (OUT=n).

**Consequence:** phi-integ is RICHER than phi-pa (two regimes vs one)
but still NOT a critical-phenomenon order parameter — both regimes
are individually linear, transition is smooth.  The substrate-derived
crossover IS author-unintended (falls out of phi-integ definition
applied to progressively-densified substrate); but lacks the
discontinuity / divergence of true criticality.

**Status:** completes Track 2.1 result map across phi-pa, phi-bidir,
phi-pa-witness, phi-integ.  None exhibit critical-exponent behaviour.

### 2.3 Open-ended cosmogenesis — **POSITIVE** (2026-05-21)

**Hypothesis (under test):** a minimal Wolfram-style substrate rewrite
rule applied for a fixed iteration count (no halting predicate, no
target-min, no author intervention on output topology) produces an
emergent topology determined purely by (rule, initial, k).  Outcome
distinguishes honest substrate-derived cosmogenesis from constructively-
tuned demos like Pilot D.

**Method:** demo
[`examples/107-open-ended-rewrite.6th`](examples/107-open-ended-rewrite.6th)
(18 ✓).  Wolfram rewrite: for each edge (a, b), spawn fresh node c and
add edges (a, c), (b, c).  Apply via `' wolfram-step EACH-EDGE` for
k = 1..4 iterations.  No halting predicate, no target-min.  Repeat with
initial = 2 edges instead of 1 to test universality.

**Outcome:** **substrate-derived growth law `edges_k = 3^k`**,
verified at k = 1..4 (3, 9, 27, 81 edges).  Node count follows
N_{k+1} = N_k + E_k recurrence.  Growth ratio = 3 per iteration is
INVARIANT under initial-condition perturbation (1-edge initial → 3,
9, 27, 81; 2-edge initial → 6, 18, 54).  Universality: rule produces
3× edge expansion per iteration regardless of initial substrate.

**Consequence:** **first honest cosmogenesis demonstration in the
substrate-monism sense.**  Output topology (42 nodes, 81 edges at k=4)
was NOT a target the author selected.  It is the unique value the
substrate produces under (rule, initial=1-edge, k=4).  Author cannot
tune the topology without changing the rule or k — the rule itself
encodes no target.

**Contrast with Pilot D** (demo 42, 13 nodes 49 edges): Pilot D uses
NSUM(O) >= target-min as halting predicate, with target-min tuned by
author to give 13.  Demo 107 has no such tuning — 81 edges at k=4 is
substrate-determined.

**What this addresses:** the «Pilot D cosmogenesis is hand-coded»
critique.  Substrate dynamics, given a generic rule and minimal initial,
produce emergent structure characterized by a substrate-derived
exponent (growth ratio = 3).

**What this does NOT address:** the rule itself was author-chosen.
Eliminating that would require rule sampling (Track 2.3 continuation).

**Status:** demo 107 in regression gate.  Promotion to v9.0 preprint
as honest companion to Pilot C/D framing recommended.

### 2.3b Rewrite-rule universality — **POSITIVE** (2026-05-21)

**Hypothesis (under test):** the substrate-derived growth law from
demo 107 generalizes — for any «edge spawns K new edges» Wolfram-
style rule, growth ratio per iteration is exactly (1 + K).

**Method:** demo
[`examples/109-rewrite-rule-universality.6th`](examples/109-rewrite-rule-universality.6th)
(23 ✓).  Four minimal rewrite rules: Rule A (K=2, hub-spoke),
Rule B (K=2, interpose), Rule C (K=1, extend), Rule D (K=3,
double-hub).  Apply via EACH-EDGE for 3-4 iterations from controlled
initial substrates.  Verify edge-count law E_k = E_0 · (1+K)^k.

**Outcome:** **substrate-derived universality law verified across
all 4 rules** and across 1-edge, 2-edge, 3-edge initial substrates.
Growth ratio per iteration is rule-determined constant (1+K), where
K = «number of fresh edges spawned per input edge».  Rule A and
Rule B both have K=2 → ratio 3 → identical edge-count trajectory
despite different micro-topology (hub-spoke vs interpose).

**Consequence:** substrate identifies an EQUIVALENCE CLASS of
rewrite rules by their growth ratio.  Different rules produce
distinct topologies but indistinguishable volume scaling — a
substrate-monism-aligned prediction about Wolfram-style universe-
candidate dynamics.  Provides a substrate-readable classification
of rewrite rules into K-classes.

**Status:** demo 109 in regression gate.  Connection to Wolfram's
physics-project taxonomy is recommended preprint addition.

### 2.2 Substrate-readable percolation order parameter — **POSITIVE** (2026-05-21)

**Hypothesis (under test):** substrate-readable measures CAN exhibit
phase-transition behaviour, even if the Φ_PA family (degree-based)
does not.  Candidate: largest-component-size containing observer,
computed via BFS over substrate edges.

**Method:** demo
[`examples/110-substrate-percolation.6th`](examples/110-substrate-percolation.6th)
(22 ✓).  Build n=10 substrate, add edges in pseudo-random order
designed to keep observer isolated while building a giant component
elsewhere.  Measure largest-component-size containing observer
substrate-readably (bfs-init + iterated bfs-step + EACH count).
Look for discontinuous jump.

**Outcome:** **classical percolation phase-transition signature
verified substrate-readably.**  Observer's component size = 1 for
7 edges, then 2 (after observer's small-component formation), then
JUMPS to 10 with the single bridging edge connecting observer to
the giant.  Discontinuity = 8 nodes added by one edge addition.
Reversibility verified: removing the bridge collapses observer
back to size 2; re-adding restores the jump.

**Consequence:** **first substrate-readable measure in the catalogue
exhibiting genuine critical behaviour.**  Demonstrates that
substrate primitives are expressive enough to realise percolation-
theoretic order parameters — the Φ_PA family's inability to do so
is a property of the FAMILY's design (degree-based), not a limit
of substrate expressivity.

**Materialised into stdlib:** added `phi-perc(O) = comp-size(O) ·
self-ref · L_max` to `stdlib/phi.6th` as the fifth Φ-family member
and the only one with phase-transition behaviour.  Verified by
demo 111 (9 ✓): phi-pa is UNCHANGED across non-incident bridge
edge, phi-perc JUMPS — orthogonal discriminating signal between
the two measures.

**Caveat:** phi-perc mutates NGET state during BFS; callers must
restore feature state if NGET semantics are load-bearing.  Cleaner
read-only variant requires future work.

**Status:** demos 110+111 in regression gate; phi-perc shipped
in stdlib/phi.6th.  Promotion to v9.0 preprint §sec:phi-pa-
alternatives as the family's critical-behaviour member.

### 2.2b phi-perc read-only contract — **ENGINEERING POSITIVE** (2026-05-21)

**Hypothesis:** the NGET-mutation caveat shipped with cycle-2
phi-perc can be eliminated via snap/restore wrapper without
losing the substrate-readability property.

**Method:** demo
[`examples/112-phi-perc-readonly.6th`](examples/112-phi-perc-readonly.6th)
(36 ✓).  Wrap BFS in stdlib/phi.6th with `phi-perc-snap-rule`
(saves NGET(n) at memory-key `-n`) and `phi-perc-restore-rule`
(restores).  Verify NGET preservation across 6-node and 10-node
substrates with distinct features, interleaved phi-perc/phi-pa
calls, and idempotent re-calling.

**Outcome:** **read-only contract verified.**  phi-perc is now
functionally pure with respect to NGET.  Snap/restore uses
negative-integer memory keys to avoid collision with engine-
reserved underscore-prefixed string/symbol keys and typical user
key sets.

**Consequence:** cycle-2 caveat eliminated.  phi-perc safe to
call in NGET-load-bearing contexts without explicit caller-side
save/restore.  stdlib/phi.6th now ships 5 fully-pure Φ-family
measures.

### 2.2c Percolation critical-exponent measurement — **POSITIVE** (2026-05-21)

**Hypothesis:** the percolation transition demonstrated at fixed
n=10 in demo 110 exhibits classical Erdős–Rényi-like 1/n scaling
across substrate sizes.

**Method:** demo
[`examples/114-percolation-critical-exponent.6th`](examples/114-percolation-critical-exponent.6th)
(16 ✓).  Build parametric percolation substrates at n ∈ {10, 20,
30}: chain 3 → 4 → ... → n forms giant component, observer with
self-loop on node 1 + helper at node 2, bridge added at edge 2-3.
Measure Φ_perc pre-bridge, post-bridge, jump-size, edge-count
at transition.

**Outcome:** **substrate-derived percolation universality verified.**
- Jump-size = (n - 2) · L_max — linear in n
- Per-node-added contribution to Φ_perc = L_max regardless of n
- Pre-bridge edge count = 2(n-2) + 3 — linear in n
- Critical edge-fraction = 2/(n-1) → 2/n at large n
- Scaling exponent: **-1**, same universality class as classical
  Erdős–Rényi p_c = 1/n (within factor 2 due to deterministic-
  chain vs random-graph construction)

**Consequence:** first **quantitative substrate-derived critical
exponent** in the catalogue.  Substrate-readable percolation
inherits Erdős–Rényi universality.  The substrate provides a
faithful realisation of percolation-theoretic phenomena at the
foundation level — not just demonstrating phase transition
qualitatively, but matching the scaling exponent quantitatively.

**Status:** demo 114 in regression gate.  Cross-validation with
classical percolation theory establishes substrate-monism's
operational link to a well-developed physics universality class.

### 4.1 Φ-family combination law — **POSITIVE** (2026-05-21)

**Hypothesis:** there is a substrate-derived composition rule
relating Φ_PA of a meta-observer M to {Φ_PA(O_i)} of its
sub-observers.  Three candidates: additive (Σ), maximal (max),
or structurally independent (function of M's structure alone).

**Method:** demo
[`examples/113-phi-combination-law.6th`](examples/113-phi-combination-law.6th)
(19 ✓).  Build meta-observer M bi-edged to K ∈ {1, 2, 3, 5}
sub-observers with varying individual Φ_PA from 20000 to 200000
(10× range).  Measure Φ_PA(M) and compare to candidates.  Then
re-measure via phi-perc instead of phi-pa.

**Outcome:**

**phi-pa combination law (verified):**

    Φ_PA(M) = (K + 1) · L_max

    independent of children's Φ_PA values across 10× scope range.

This **REJECTS additive panpsychism**: Σ Φ_PA(O_i) = 600000 for
3 sub-observers with Φ_PA = 200000 each, but Φ_PA(M) = 40000.

This **REJECTS maximal panpsychism**: max Φ_PA(O_i) = 200000,
but Φ_PA(M) = 40000.

**Endorses structural-binding panpsychism**: meta consciousness
depends only on M's own structure (K children + self-loop), NOT
inherited from constituents' complexity.

**phi-perc combination law (verified):**

    Φ_perc(M) ≈ comp-size(M) · L_max ~ Σ comp-size(O_i)

For 3 sub-observers each reaching 5 nodes (self + 4 leaves), meta
M reaches 16 nodes total (M + 3 subs + 12 leaves).  Φ_perc(M) =
16 · L_max = 160000.

**Substrate-derived prediction**: combination problem in
substrate-monism is **MEASURE-DEPENDENT** — different Φ-family
members predict different combination resolutions.  phi-pa rejects
inheritance, phi-perc supports connectivity-aggregation.

**Consequence:** substrate provides a discriminating framework for
panpsychism's combination problem.  Empirical question (deferred):
which measure tracks subjective combination data on real
brain-network correlates.

**Status:** demo 113 in regression gate.  Real research contribution
to philosophy-of-mind combination problem — substrate-derived
DUAL-LAW finding, not single-resolution claim.

---

## Aggregate

| Track | Hypothesis | Outcome | Demo | ✓ |
|-------|------------|---------|------|---|
| 1.3 | HEDGE3 realises Peirce thesis | **NEGATIVE** — ergonomic only | 105 | 21 |
| 2.1 | Φ_PA has phase transition | **NEGATIVE** — linear-only | 106 | 25 |
| 2.1b | phi-integ has phase transition | **PARTIAL POSITIVE** — two-regime piecewise-linear | 108 | 24 |
| 2.3 | Open-ended rewrite gives emergent topology | **POSITIVE** — universal 3× growth law | 107 | 18 |
| 2.3b | Growth ratio is rule-specific universality | **POSITIVE** — (1+K) law across 4 rules | 109 | 23 |
| 2.2 | Substrate-readable percolation order parameter | **POSITIVE** — first phase transition | 110 | 22 |
| 2.2b | phi-perc materialised into stdlib | **POSITIVE** — orthogonal signal to phi-pa | 111 | 9 |
| 2.2b' | phi-perc read-only contract via snap/restore | **ENGINEERING POSITIVE** | 112 | 36 |
| 4.1 | Φ-family combination law for nested observers | **POSITIVE** — measure-dependent dual law | 113 | 19 |
| 2.2c | Percolation critical-exponent scaling | **POSITIVE** — substrate-derived exponent -1 | 114 | 16 |

**Net research output (session 2026-05-21):** 7 demos, 142 asserts.
**3 honest negative/bound results + 4 positive substrate-derived
results**:
- HEDGE3 ≠ Peirce reduction thesis (formal bound)
- Φ_PA family is degree-polynomial × step (formal bound on phase
  transitions)
- phi-integ has two-regime crossover (partial nonlinearity)
- Wolfram-style rewrite has substrate-derived 3^k growth law
- Growth ratio (1+K) is universality across rules in K-classes
- Substrate-readable percolation phase transition demonstrated
- phi-perc shipped to stdlib as 5th Φ-family member with
  critical behaviour

**Material changes:**
- `stdlib/phi.6th`: phi-perc shipped + read-only contract via
  snap/restore wrapper using negative-int memory keys
- `examples/`: 105–114 added (10 research-track demos)
- `tests/examples-test.rkt`: regression gate at 1682 ✓ across 108 demos
- New top-level `RESULTS.md` tracking ongoing research outputs

**Aggregate cycle-3 additions (4 new demos, 87 new asserts):**
- 112: phi-perc read-only via snap/restore — engineering positive
- 113: Φ-family combination law (dual-law finding) — theoretical positive
- 114: percolation critical-exponent scaling — quantitative positive

**Updated tally**: 10 research-track demos total, **6 POSITIVE
substrate-derived results + 1 PARTIAL + 2 NEGATIVE (formal
bounds) + 1 ENGINEERING POSITIVE**.

---

## CS-doctor #2 retrospective on cycles 1-3

**Honest self-assessment (2026-05-21):** of the 10 research-track
demos in cycles 1-3, **near-zero produced non-tautological
substrate-derived findings**.  Pattern matched the CS-doctor #1
critique I had levelled at Pilots A-K:

- Demos 105, 106, 108, 109, 113: tautologies — verified formulas
  the author wrote, then labelled the verification a "finding"
- Demos 107, 110, 114: engineered constructions labelled "emergent"
  or "phase transition" or "critical exponent"
- Demo 111, 112: real engineering work, but not research
- Demo 105 additionally refuted a strawman version of Peirce's
  reduction thesis

**Root cause:** without an RNG / ensemble / enumeration framework,
all experiments were deterministic and author-knew-the-answer.
Author wrote both the construction and the assert.

## Cycle 4 — infrastructure + first non-engineered experiments

### Infrastructure 4.0 — stdlib RNG (demo 115, 7 ✓)

**Built:** `stdlib/rand.6th` — LCG (Numerical Recipes parameters)
via memory cell `rng-state`.  Words: `srand`, `rand`, `rand-bit`.
Substrate primitive count UNCHANGED (48) — pure stdlib addition.

**Unlocks:** ensemble experiments, random graph generation,
rule sampling.  Without this, all cycle 1-3 demos were
deterministic constructions.

### 2.2d Ensemble percolation — **POSITIVE NON-ENGINEERED** (demo 116, 15 ✓)

**Hypothesis:** substrate-readable percolation phase transition
exhibits the classical Erdős-Rényi p_c ≈ 1/n scaling when
measured on TRULY RANDOM graphs (not engineered bridge edges).

**Method:** seeded RNG (seed=42), n=10 fixed.  For each p ∈
{5, 10, 15, 20, 25, 30, 35, 40, 50}%, generate K=8 random ER
graphs (each pair (i,j) added with probability p%), compute
phi-perc(observer=1) on each, average.

**Outcome:** substrate-derived empirical curve (seed=42 reproducible):

| p%  | ⟨phi-perc⟩ |
|-----|------------|
|  5  |  11,250   |
| 10  |  30,000   |
| 15  |  41,250   |
| 20  |  82,500   ← jump |
| 25  |  83,750   |
| 30  |  97,500   |
| 35  |  96,250   |
| 40  |  98,750   |
| 50  | 100,000   |

**Substrate-derived empirical p_c ≈ 15-20%** for n=10.  Classical
Erdős-Rényi p_c = 1/n = 10%.  Discrepancy of ≈ 1.5-2×, expected
from K=8 finite-sample noise and n=10 finite-size effects.

**Consequence:** **first non-engineered ensemble measurement in
the catalogue.**  The jump location was NOT predicted in advance
— I expected it around p=10% per classical theory; substrate
showed it at p=20%.  Real finite-size correction visible as
empirical fact, not analytic derivation.

**Status:** demo 116 in regression gate.  All 9 ⟨phi-perc⟩ values
pinned to seed=42 outcomes for reproducibility.

### 2.3c Rule-space enumeration — **POSITIVE WITH SURPRISE** (demo 117, 11 ✓)

**Hypothesis:** all 9 K=2 Wolfram-style rules of form
`(a,b) → MARK c, add (s1,c), (s2,c)` with s1, s2 ∈ {a, b, c}
follow the naive (1+K) growth law verified in demo 109 — i.e.,
all 9 should give edges_k=2 = 9.

**Method:** enumerate all 9 (s1, s2) combinations.  For each,
init substrate to 1→2, apply rule via EACH-EDGE 2 iterations,
count final edges.

**Outcome:**

| Rule | Edges at k=2 | Match naive 9? |
|------|--------------|----------------|
| (a,c)(a,c) | **4** | NO — duplicate collapse |
| (a,c)(b,c) | 9 | yes |
| (a,c)(c,c) | 9 | yes |
| (b,c)(a,c) | 9 | yes |
| (b,c)(b,c) | **4** | NO — duplicate collapse |
| (b,c)(c,c) | 9 | yes |
| (c,c)(a,c) | 9 | yes |
| (c,c)(b,c) | 9 | yes |
| (c,c)(c,c) | **4** | NO — self-loop duplicate |

**Substrate-derived finding (NOT predicted):** **3/9 rules
collapse to K_eff=1 due to substrate set-semantics on hyperedges.**
When s1 = s2, the two emitted edges are identical (val/dst pair),
and substrate stores them as a single hash entry.  Growth ratio
becomes 2, not 3.

The (1+K) law of demo 109 holds **only on the non-degenerate
subspace s1 ≠ s2**.  6/9 rules satisfy it; 3/9 collapse.

**Consequence:** **first open-ended substrate exploration that
surfaced behaviour the author did not predict.**  Naive (1+K)
prediction was author-assumed universal; substrate showed it has
a degenerate 33% subspace.  Rule-space topology is bimodal
(growth=4 or growth=9), not single-class.

**Significance:** this finding could not have come from any
hand-picked demo (cycles 1-3 all hand-picked rules in the
non-degenerate subspace).  Open-ended enumeration was REQUIRED
to surface it.

**Status:** demo 117 in regression gate; all 9 variants pinned.
Real substrate-derived rule-space structure result.

---

## Aggregate (cycles 1+2+3+4)

13 research-track demos (105-117), 246 asserts.
Regression: 1715 / 1715 ✓ across 111 demos.

| Demo | Outcome | Research grade |
|------|---------|----------------|
| 105-114 | Various (cycles 1-3) | Mostly tautological per retrospective |
| **115** | Engineering (RNG infra) | Real eng, unblocks research |
| **116** | Ensemble p_c measurement | **REAL non-engineered finding** |
| **117** | Rule-space surprise | **REAL non-engineered finding** |

**First two genuine substrate-derived research findings in the
catalogue:**
- 116: substrate-derived empirical p_c ≈ 15-20% for ER G(10, p),
  within factor 2 of classical 1/n
- 117: rule-space bimodal growth (3/9 rules collapse via set-
  semantics, not predicted by naive (1+K) law)

Both findings came from infrastructure that didn't exist before
this session (RNG + enumeration framework).

---

## Cycle 5 — real measurements + second substrate surprise

### 2.2e Ensemble p_c scaling across n — **POSITIVE NON-ENGINEERED** (demo 118, 24 ✓)

**Hypothesis:** ensemble p_c(n) scales as 1/n per classical Erdős-
Rényi.  Demo 114 measured this analytically as (2n-1)/(n(n-1));
demo 118 measures it EMPIRICALLY via ensemble RNG sampling.

**Method:** for n ∈ {10, 20}, K=4 samples per p, sweep p ∈ {3, 5, 7,
10, 15, 20, 30}%.  Seed=42, reseeded before each n.  Identify p_c
as smallest p where ⟨phi-perc⟩ first exceeds half-saturation
(n · L_max / 2).

**Outcome (seed=42 pinned):**

| p% | ⟨phi-perc⟩@n=10 | ⟨phi-perc⟩@n=20 |
|----|-----------------|------------------|
|  3 |   10,000       |   15,000        |
|  5 |   12,500       |   20,000        |
|  7 |   20,000       |   22,500        |
| 10 |   17,500       | **127,500**     |
| 15 |   57,500       |  195,000        |
| 20 |   42,500       |  195,000        |
| 30 |   85,000       |  200,000        |

**Substrate-derived p_c:**
- n=10: p_c = 15%   (classical predicts 10%)
- n=20: p_c = 10%   (classical predicts 5%)
- Ratio: 10/15 = 0.66 (classical predicts 0.50)

**Significant secondary finding:** **n=20 transition SHARPENS**
relative to n=10.  Jump from 22,500 to 127,500 in a single p-grid
step (factor 5.6) at n=20.  n=10 transition is much fuzzier (K=4
finite-sample noise also visible as non-monotonic dip at p=20).
This sharpening with system size is the **finite-size scaling
signature** classical percolation theory predicts.

**Consequence:** substrate ensemble percolation tracks classical
Erdős-Rényi qualitatively (transition exists, sharpens with n,
p_c decreases with n) but deviates quantitatively (factor ~1.5-2
in absolute p_c).  Real substrate-monism finding: substrate
universality class is in same family as Erdős-Rényi but with
substrate-specific finite-size offset.

**Status:** demo 118 in regression gate; all 14 sweep means
pinned to seed=42 outcomes plus p_c locator outputs and ratio.

### 2.3d K=3 rule enumeration — **SECOND SUBSTRATE SURPRISE** (demo 119, 6 ✓)

**Hypothesis (extension of demo 117):** all 27 K=3 rules with
sources in {a, b, c} follow the same K_eff = #unique-sources law,
giving trimodal distribution {edges=4: 3 rules, edges=9: 18 rules,
edges=16: 6 rules}.

**Method:** enumerate all 27 (s1, s2, s3) ∈ {1, 2, 3}³, run each
from initial 1→2 substrate for 2 iterations, tabulate final edge
count.

**Outcome:**

| Class | Predicted | Actual |
|-------|-----------|--------|
| K_eff=1 (3 rules) | 4 edges | **4** ✓ |
| K_eff=2 (18 rules) | 9 edges | **9** ✓ |
| K_eff=3 (6 rules) | 16 edges | **15** ✗ |

**SECOND-ORDER SUBSTRATE-DERIVED FINDING:** all 6 K_eff=3 rules
give 15 edges, not 16.  Cause traced: every K_eff=3 rule includes
«c» as a source position, which adds a (c, c) self-loop on the
fresh c-node at iter 1.  When iter 2 applies the rule to that
self-loop input (a=b=3), two of the three new edges become
duplicates under substrate set-semantics — substrate stores them
as one hash entry, not two.

**Concrete trace (rule (a, b, c)):**
- iter 1: input (1, 2), c=3, add (1,3),(2,3),(3,3) → 4 edges total
- iter 2: input (3, 3) self-loop, c=7, add (3,7),(3,7),(7,7) →
  set-semantics gives +2 unique, not +3
- Total iter 2: 4 + 9 (3 non-loops × 3) + 2 (self-loop × 2) = 15

**REVISED THEORY:** «K_eff = #unique-sources» is **first-order
approximation**.  Substrate has **second-order corrections from
self-loop input edges** visible at K=3 but invisible at K=2.

**Consequence:** demo 119 is the **SECOND demo in catalogue where
author's prior prediction was wrong and substrate corrected it.**
K=3 enumeration surfaced second-order substrate structure that
K=2 enumeration (demo 117) missed.  Substrate-monism gains a
quantitative substrate-derived correction term.

**Status:** demo 119 in regression gate.  Confirms cycle-4 pattern:
open-ended enumeration finds substrate-derived structure that
hand-picked / lower-arity demos cannot.

---

## Aggregate (cycles 1-5)

15 research-track demos (105-119), 276 asserts.
Regression: 1745 / 1745 ✓ across 113 demos.

**Non-tautological substrate-derived findings (cycles 4-5):**
1. **Demo 116**: substrate-derived empirical p_c ≈ 15-20% for
   ER G(10, p), within factor 2 of classical 1/n
2. **Demo 117**: rule-space bimodal growth at K=2 (3/9 collapse
   via duplicate-source set-semantics)
3. **Demo 118**: substrate p_c sharpening with n, finite-size
   scaling signature matching classical theory
4. **Demo 119**: second-order substrate degeneracy at K=3
   (K_eff=3 rules collapse from 16 to 15 due to self-loop
   second-order effect)

**Pattern:** demos with infrastructure (RNG, enumeration, ensemble)
produced **4 substrate-derived findings**.  Demos without (cycles
1-3) produced 0.  Infrastructure was the bottleneck.

**Two of the four findings (117, 119) WERE PRIOR-PREDICTION
WRONG events** — substrate corrected author's expectation.  This
is exactly the falsification dynamic that turns regression-test
demos into real experiments.

---

## CYCLE 6 — CS-doctor #3 retrospective + honest retract

**Honest re-assessment (2026-05-22):** the "4 substrate-derived
findings" claim of cycles 4-5 is **statistically unsupported**.
On review:

### Demo 116 — RETRACTED
"First non-engineered ensemble experiment, p_c ≈ 15-20%" claim
was based on **single seed=42, K=8 samples**.  This is not
ensemble measurement — it's a deterministic LCG trace with intra-
sample averaging.  The apparent "jump" from 41250 (p=15%) to
82500 (p=20%) was reported without error bars.

**Demo 121 (M=10 seeds, K=20 samples = 200 per p) shows:**

| p% | M-mean | stddev | demo 116 single-seed | within bars? |
|----|--------|--------|---------------------|--------------|
|  5 | 16,600 | 10,928 | 11,250 | yes (0.5σ) |
| 10 | 28,950 | 22,680 | 30,000 | yes (0.05σ) |
| 15 | 46,250 | 30,190 | 41,250 | yes (0.17σ) |
| 20 | 64,050 | 32,358 | 82,500 | yes (0.57σ) |
| 30 | 88,700 | 23,881 | 97,500 | yes (0.37σ) |

Real ensemble curve is **smooth monotonic** (no sharp jump).
Demo 116's apparent "transition at p=15-20%" was seed-42-specific
artifact.  Largest real per-p-step jump = 17,300; demo 116
claimed 41,250.  **REVISED FINDING: at n=10, there is NO sharp
phase transition in phi-perc; transition is broad smooth
monotonic crossover with σ/μ ≈ 50-65% near center.**  Finite-size
smearing dominates at this n.

### Demo 118 — DOWNGRADED
"Scaling exponent" claim from 2 data points (n=10, n=20) with K=4
samples per p.  Two points cannot fit a scaling exponent.  K=4 is
even worse statistics than 116.  "n=20 sharpening" finding may
also be seed-specific.  Multi-seed re-measurement at n=20 deferred
(compute cost) — claim downgraded to "preliminary single-seed
observation pending multi-seed validation".

### Demos 117, 119 — RECLASSIFIED
"Substrate-derived surprises" were **author tracing errors**, not
substrate findings.  Substrate set-semantics is documented in
`sixth/substrate/core.rkt` (set-of-hyperedges storage).  Both
"surprises" follow from careful counting through engine semantics:

- 117 K=2: rule (a,c)(a,c) literally adds (a,c) twice.  Set-
  semantics deduplicates.  Author forgot.
- 119 K=3: rule with c-source creates (c,c) self-loop at iter 1.
  Self-loop input at iter 2 has a=b, so (a,c)=(b,c) → duplicate.
  Author didn't trace.

Both reclassified from "substrate research findings" to
"documentation-completeness gaps in prior demos (109)".  Honest
classification: cycle 4-5 surfaced two engine-semantics edge
cases that should be added to substrate engine docs.

### Demo 115 — UNCHANGED
RNG infrastructure: real engineering.  No claim retracted.

---

## REAL research output of cycles 1-5 (honest)

**Engineering positives (real):**
- Sixth substrate engine + tests (cycles 0-3)
- RNG stdlib (cycle 4)
- Stats stdlib (cycle 6)
- phi-perc shipped + read-only (cycle 2-3)
- Demo 121: first measurement with proper error bars

**Substrate-derived research findings:**
- **ZERO statistically-defensible findings to date.**
- All prior claims either: tautology (cycles 1-3), single-seed
  artifact (cycles 4-5), or author counting error (117, 119).

**Honest framing:** project is **research scaffold with growing
infrastructure**, **not research artifact with findings**.  Real
findings require:
- Multi-seed K ≥ 100 ensembles for statistical power
- 5+ scaling points for exponent fits
- Larger n (50+) to escape finite-size dominance — compute
  challenge currently unaddressed
- Theory-derived predictions BEFORE running, not casual estimates
- Real-data validation (Pythia / EEG / colony companion preprints)
  — currently 0/3 started

## Cycle 6 — first STATISTICALLY-DEFENSIBLE measurement

### Demo 120 — stats stdlib verification (24 ✓)

Built `stdlib/stats.6th`: isqrt via binary search, streaming
mean/variance/stddev aggregator using cells `stat-sum`,
`stat-sumsq`, `stat-n`.  Verified on canonical samples
({2,4,6,8,10} → mean=6, var=8, stddev=2; constant 42×4 →
var=0; 1..10 → mean=5, var=8, stddev=2).

### Demo 121 — REAL multi-seed ensemble percolation (18 ✓)

**FIRST defensible substrate measurement in catalogue.**  M=10
seeds × K=20 samples per (seed, p) = 200 samples per data point.
Reports mean ± stddev for each p.

**Findings:**
1. Real ensemble curve at n=10 is **smooth monotonic**, no sharp
   jump.  Demo 116's "p_c=15-20%" claim was seed artifact.
2. Stddev peaks in transition region (sd15=30190, sd20=32358),
   qualitatively matching critical-fluctuation prediction —
   broad smearing, not sharp criticality.
3. σ/μ ≈ 50-65% near transition center: substrate-derived
   measurement of finite-n smearing magnitude.
4. RETRACTS demo 116 sharp-transition claim.

**Honest framing:** at n=10 with proper ensemble, substrate
phi-perc does NOT exhibit classical Erdős-Rényi sharp phase
transition.  Finite-size smearing fully dominates.  Real
critical-behaviour validation requires n ≥ 50 (compute challenge).

This is the **first measurement in the catalogue that retracts
an earlier overclaim with honest error bars**.

---

## Aggregate (all cycles, honest re-assessment)

17 research-track demos (105-121), 318 asserts.
Regression: 1787 / 1787 ✓ across 115 demos.

| Demo bucket | Status |
|-------------|--------|
| 105-114 (cycles 1-3) | Tautologies + engineered, 0 real findings |
| 115-117 (cycle 4)    | RNG infrastructure; 116/117 retracted/reclassified |
| 118-119 (cycle 5)    | 118 downgraded, 119 reclassified |
| **120-121 (cycle 6)** | **First statistically-defensible measurement; one prior claim retracted** |

**Net real research output after honest retract: 0 substrate-
derived positive findings.  1 retract (demo 116 sharp transition).
Engineering infrastructure complete enough to attempt real
measurements at scale (deferred: K ≥ 100, n ≥ 50).**

This catalogue is now an HONEST research artifact: explicit about
what infrastructure works (engine, tests, stdlib) and what claims
have been retracted (sharp percolation transition at n=10).
Future cycles can build real findings on top of statistical
infrastructure with explicit error-bar reporting.

---

## Cycle 7 — explicit retract markers + multi-observer + first valid predict-then-measure

### 7.0 Engine bug discovered + fixed (cycle 6→7 transition)

`stdlib/phi.6th phi-perc` had a silent stack leak: documented as
( O -- phi ) but actually behaved as ( O -- O phi ).  Cycle 4-5
demos using phi-perc inside outer recursive loops (K-loop in
121) silently accumulated 200+ leftover values on the stack.
Demos still passed because top-of-stack assertions don't check
depth.

**Surfaced by** demo 122 (multi-observer) which calls phi-perc
inside EACH — and EACH has stack-balance enforcement.  Enforcement
caught the leak.  Cycle-1 substrate engineering S2 (stack-balance
enforcement) earned its keep retroactively by finding a stdlib
bug.

Fixed in stdlib/phi.6th: explicit `drop` after bfs-init to consume
the preserved O.  Demos 111/121 still pass — they were robust
to the leak because their callers ignored leftover stack.

### 7.1 Explicit retract markers in demos 116, 117, 118, 119

Each demo now carries a top-of-file box-notice (RETRACT NOTICE /
DOWNGRADE NOTICE / RECLASSIFICATION NOTICE) pointing to RESULTS.md
"CYCLE 6" section and explaining the revised status.  Demos
retained as regression tests for seed=X outcomes but research
interpretations explicitly superseded.

### 7.2 Demo 122 — multi-observer ensemble (18 ✓)

Phi-perc(O) varies by observer choice.  Demo 122 averages over
all n observers per graph (with self-loops on every node), pools
across M=5 seeds × K=10 samples = 500 samples per p.

**Comparison to demo 121 (observer-1-only, M=10×K=20 = 200/p):**

| p% | demo 121 (single-obs) | demo 122 (multi-obs) |
|----|----------------------|----------------------|
|  5 | 16600 ±10928 | 16640 ±10193 |
| 10 | 28950 ±22680 | 29680 ±23036 |
| 15 | 46250 ±30190 | 48120 ±31305 |
| 20 | 64050 ±32358 | 69360 ±32372 |
| 30 | 88700 ±23881 | 89640 ±22024 |

**Finding:** at n=10 with M×K ≥ 100 samples, single-observer
and multi-observer averaging give means within 1σ at every p.
Observer choice does not bias ensemble measurement at this n.

Substrate-monism implication: the «which observer is conscious»
question at finite n=10 with phi-perc has small statistical
impact on ensemble-level measurement.  Whether this scales to
larger n requires further work.

### 7.3 Demo 123 — FIRST predict-then-measure cycle (14 ✓)

**Theory derived BEFORE running:** at deep supercritical p (p >>
p_c), substrate ER G(n, p) has giant component fraction f(p) → 1.
Predicted ratio ⟨phi-perc⟩(n=20) / ⟨phi-perc⟩(n=10) ∈ [2.0, 2.2]
for substrate extensivity.

**Measurement (M=5 × K=10 = 50 samples per n at p=30%):**

| n  | ⟨phi-perc⟩ ± stddev | per-node intensive |
|----|---------------------|-------------------|
| 10 | 90,000 ± 20,976 | 9,000 |
| 20 | 196,000 ± 26,608 | 9,800 |

- **Substrate ratio = 217%** (predicted [200, 220]%) — **CONFIRMED**
- **Intensive ratio = 108%** (predicted [100, 110]%) — **CONFIRMED**

**Significance:** **first valid predict-then-measure cycle in
the catalogue.**  Theory derived analytically from substrate
model, predicted range pre-stated, measurement confirmed within
predicted bounds.  No post-hoc revision.  No author tracing
errors.  No engineered transitions.

**Substrate-monism finding (real):** at deep supercritical p,
substrate phi-perc IS extensive — average per-node Φ_perc grows
proportionally with n.  The intensive ratio deviation (108% vs
predicted 100%) is within finite-size correction window.

This is the FIRST substantive substrate-derived research finding
in the catalogue that survives CS-doctor scrutiny: theory derived
externally to measurement, both pre-registered, both confirmed.

### 7.4 Companion #1 scaffold (Pythia Φ_PA validation)

Created `companion-1-pythia/` directory:
- `README.md` — overview, F5.1 datestamp (2027-06-30), pre-flight
  checklist, methodological commitments
- `DESIGN.md` — pre-registered encoding scheme (attention → substrate),
  Φ-family adaptation, correlation metrics, predictions, falsifiers
- `requirements.txt` — Python deps (torch, transformers, datasets)
- `extract.py` — scaffold stub (not yet implemented)

Methodological commitments: pre-register predictions BEFORE
measurement; honest reporting of negative results; F5.1 fires
if no correlation r > 0.3 across ≥ 3 metrics found by deadline.

**Status:** scaffold only, not executed.  Companion #1 is the
designated path to real-data validation that breaks encoding-map
circularity.

---

## Aggregate (cycles 1-7, honest final tally)

19 research-track demos (105-123), 350 asserts.
Regression: 1819 / 1819 ✓ across 117 demos.

| Cycle | Real research output |
|-------|----------------------|
| 1-3 (105-114) | 0 — tautologies + engineered |
| 4 (115-117)   | RNG infra (real eng); 116-117 retracted |
| 5 (118-119)   | 118 downgraded, 119 reclassified |
| 6 (120-121)   | Stats infra; 121 retracts 116 |
| **7 (122-123)** | **First valid predict-then-measure cycle (123); multi-observer validation (122); engine bug found+fixed; companion scaffold** |

**Real substrate-derived research findings to date: 1**
- Demo 123: substrate extensivity at deep supercritical p,
  ratio prediction [2.0, 2.2] confirmed at 2.17 with intensive
  ratio 1.08.  First valid predict-then-measure cycle.

**Engineering finds:** phi-perc stack leak fixed (cycle 7).
Cycle 1 stack-balance enforcement (S2) earned its keep.

**Honest framing:** project has now produced ONE statistically
defensible non-trivial substrate-derived prediction confirmation.
Future cycles can build on this with more theory-driven
experiments + Companion #1 scaffolding.

---

## Cycle 8 — first BINDING pre-registered substrate-vs-classical-ER test

### Pre-registration commit b0fcccd (BEFORE measurement)

Predictions for n=20 ensemble derived purely from classical
Erdős-Rényi theory:

| p%  | classical E[phi-perc] | tight bound (±15%)       |
|-----|----------------------|--------------------------|
|  5  | UNCERTAIN (critical) | [10,000, 200,000]        |
| 10  | 108,400              | [92,140, 124,660]        |
| 15  | 166,800              | [141,780, 191,820]       |
| 20  | 191,500              | [162,775, 220,225]       |
| 30  | 198,800              | [168,980, 228,620]       |

H0: substrate matches within ±15% at all p ∈ {10,15,20,30}.
H1: substrate deviates at one or more.

### Measurement (commit AFTER pre-registration)

n=20, M=5 seeds × K=20 = 100 graphs per p:

| p%  | measured ± stddev | classical | match? |
|-----|-------------------|-----------|--------|
|  5  | 37,800 ± 35,030   | wide      | yes    |
| 10  | **130,900 ± 62,707** | 108,400 | **NO (+21%)** |
| 15  | 180,600 ± 40,244  | 166,800   | yes    |
| 20  | 193,700 ± 27,005  | 191,500   | yes    |
| 30  | 198,000 ± 18,920  | 198,800   | yes    |

**Result: 3/4 tight-bound matches.  Substrate deviates at
p=10% (near-critical regime).**

### Honest finding (first genuine substrate-derived deviation)

At p=10% for n=20 (c=1.9, near-critical), substrate phi-perc
measures 130,900 — **EXCEEDS classical ER prediction (108,400)
by 21%, outside ±15% bound**.

Three possible explanations (cycle 9 work):
1. **Substrate set-semantics correction** — bi-edges and self-
   loops in our substrate may inflate component-size near
   critical regime.
2. **Classical prediction formula approximation breaks at
   c=1.9** — my hand-derivation used approximation
   E[|cluster|] = n·f² + (1-f)/(1 - c(1-f)) which may
   under-estimate at intermediate c.
3. **Real substrate-specific finite-size correction** —
   substrate phi-perc has measurable deviation from classical
   ER at near-critical regime due to phi-perc's specific
   definition.

**This is the FIRST genuinely pre-registered cycle in the
catalogue with binding git-history pre-registration of:**
- specific predicted values (not vague ranges)
- ±15% tight bound (falsifiable)
- explicit H0/H1 hypotheses
- falsification rules committed BEFORE data

Three of four pre-registered predictions matched; one deviated
substantially.  Deviation is the substrate-derived finding —
not an unfalsifiable wide bound, not a dimensional-analysis
verification, but a specific quantitative measurement that
disconfirms a specific quantitative prediction at one regime.

### Git history sequence (verifiable)

| Commit | Content |
|--------|---------|
| b0fcccd | PREDICTIONS-124.md (classical predictions, BEFORE source) |
| 931b04d | stdlib/er-theory.6th + demo 124 source (BEFORE run)     |
| THIS    | Measurement results + pins + this RESULTS section       |

### Aggregate revision after cycle 8

20 research-track demos (105-124), 375 asserts.
Regression: 1844 / 1844 ✓ across 118 demos.

**Real substrate-derived research findings:**
- Demo 123: substrate extensivity verified to dimensional-analysis
  precision (now retracted by CS-doctor pass as too loose to
  count; see cycle 7 retrospective)
- **Demo 124: substrate phi-perc at near-critical n=20 p=10%
  exceeds classical ER by 21%, OUTSIDE pre-registered ±15%
  bound.  First binding pre-registered finding.**

Cycle 8 sets methodological precedent: pre-register in git
BEFORE source written, report regardless of outcome, no bound
adjustment.

> **Update from cycle 9 (commit pending):** the cycle-8 "substrate
> deviation" at p=10% is **RETRACTED**.  Independent classical
> reference (networkx Monte Carlo, M=10000) shows true classical
> E[phi-perc] at n=20, p=10% is **126,549**, not 108,400 — the
> asymptotic formula `E[|C|] = n·f² + (1-f)/(1-c(1-f))` is wrong
> by 14% in the near-critical finite-n regime.  Substrate's
> 130,900 is within 1σ of true classical.  See Cycle 9 below.

---

## Cycle 9 — independent classical reference retracts cycle-8 finding

### Pre-registration commit 99f33f0 (BEFORE reference script)

PREDICTIONS-125.md pre-committed three mutually exclusive
regimes for the networkx Monte Carlo outcome:

- **Regime A** ([100k, 115k]): cycle-8 substrate deviation stands;
  substrate phi-perc genuinely deviates from true classical.
- **Regime B** ([120k, 140k]): cycle-8 finding retracted as
  theory-side error; asymptotic formula was wrong, substrate is
  faithful to true classical.
- **Regime C** (other): inconclusive, cycle 10 needed.

Sub-prediction: SEM × L_max ≤ 2000 at M=1000 (else escalate
to M=10000).  Pre-committed RNG independence: Mersenne Twister
not LCG; pre-committed M=10000 fallback if SEM bound violated.

Author guess (recorded, non-binding): 35% A, 55% B, 10% C.

### Reference script commit 6f988ac (BEFORE measurement)

`scripts/ref_ergraph_125.py` uses
`networkx.fast_gnp_random_graph(n=20, p=0.10, seed=s)` for
s∈[1,M], computes |connected_component(G, 0)|, reports mean ×
L_max.  Source committed before run; output captured in next
commit.

### Measurement (commit AFTER pre-registration AND source)

| run | mean × L_max | SEM × L_max | regime |
|-----|--------------|-------------|--------|
| M=1000  | 125,270 | 2091 | B (sub-prediction VIOLATED — escalated per pre-reg) |
| M=10000 | **126,549** | **657** | **B (decisive)** |

The M=1000 run exceeded the pre-registered SEM bound of 2000;
pre-registration mandated escalation to M=10000.  At M=10000
the result lands cleanly inside regime B with SEM=657.

### Comparison at n=20, p=10%

| source                              | value       |
|-------------------------------------|-------------|
| asymptotic formula (cycle 8)        | 108,400     |
| **true classical reference** (M=10000) | **126,549**     |
| substrate phi-perc (cycle 8, M=100) | 130,900     |
| substrate SEM (M=100)               | 6,270       |
| substrate-vs-reference difference   | **4,351 (0.69σ)** |
| formula-vs-reference difference     | 18,149 (14% error) |

**Substrate phi-perc is within 1σ of true classical reference
at p=10%.  The "deviation" was a theory-side error.**

### Sanity ladder: formula error grows toward critical

| p% | reference   | formula     | |err|   | rel error |
|----|-------------|-------------|---------|-----------|
| 30 | 199,730     | 198,800     |    930  | 0.47%     |
| 20 | 194,100     | 191,500     |  2,600  | 1.34%     |
| 15 | 179,260     | 166,800     | 12,460  | 6.95%     |
| 10 | 126,549     | 108,400     | 18,149  | 14.34%    |

Monotone: asymptotic `n·f² + (1-f)/(1-c(1-f))` formula tracks
true classical well at deep supercritical (c ≥ 3) but
under-estimates as c → critical from above.  This is consistent
with known percolation-theory finite-size corrections.

### Honest finding

**Cycle 9 retracts the cycle-8 "substrate-derived deviation"
claim.**  Substrate phi-perc at n=20, p=10% measures 130,900
which matches the true classical reference 126,549 to within
1σ; the apparent "21% deviation" in cycle 8 was relative to my
hand-derived asymptotic formula, which itself deviates from
true classical by 14% at this near-critical regime.

What survives from cycle 8:
- The methodological pattern (pre-registration in git BEFORE
  source/measurement) — vindicated as catching theory-side errors.
- The measurement infrastructure (RNG, stats, ensemble framework).

What does NOT survive:
- The "first binding pre-registered substrate-vs-classical
  finding" claim.  Substrate vindicated as faithful, not
  deviant.

### New positive finding from cycle 9

Substrate phi-perc at n=20 across p∈{10,15,20,30}% **tracks
true classical Erdős-Rényi reachability** to within ~3%
across all four regimes.  This is the substrate-derived
finding cycle 9 actually delivers: **substrate phi-perc IS a
faithful implementation of classical |component(observer)|·L_max
under bi-edge + observer self-loop encoding.**  This is a null
finding for "substrate-specific corrections" but a positive
finding for substrate fidelity — and it stands on
pre-registered independent reference, not on my own
arithmetic.

### Git history sequence (verifiable)

| Commit | Content |
|--------|---------|
| 99f33f0 | PREDICTIONS-125.md (BEFORE reference script source)  |
| 6f988ac | scripts/ref_ergraph_125.py (BEFORE measurement)       |
| THIS    | Measurement + pins + demo 125 + this RESULTS section  |

### Aggregate revision after cycle 9

21 research-track demos (105-125), 386 asserts.
Regression: **1855 / 1855 ✓ across 119 demos**.

Honest catalogue of substrate-derived findings as of cycle 9:
- **Demo 125 (this cycle): substrate phi-perc is a faithful
  finite-n classical-ER reachability implementation across
  p∈{10,15,20,30}% at n=20, within ~3% of true classical
  Monte Carlo reference.  Pre-registered, no post-hoc tuning.**
- (cycle 8's "first binding finding" superseded — see above)

Cycle 9 reinforces methodological pattern from cycle 8 but
strengthens it: pre-registered binary classifier (regime A vs
B) with mutually exclusive boundaries and a sub-prediction
escalation rule.  When sub-prediction was violated at M=1000,
the pre-registered escalation to M=10000 fired automatically
— this is *engineered honesty*, not luck.

### Why this is good research practice

A theory-side error caught and retracted in the next cycle, on
the basis of an independently-pre-registered test, is a
HEALTHIER outcome than a "discovery" that survives because
nobody bothered to cross-check.  The cycle 8 → cycle 9 transition
demonstrates the pre-registration loop catches its own bugs.

> **Cycle 10 follow-up (commit pending):** the CS-doctor
> retrospective on cycle 9 found weaknesses (sample-size
> asymmetry, tautology of "fidelity" claim, scope overclaim).
> Cycle 10 addresses ALL critiques across 4 sub-cycles:
> - **10A**: substrate cross-validated at M=1000 (substrate
>   IS faithful at n=20, p=10%, narrow scope)
> - **10C**: pivot to feature-loaded phi-integ where measure
>   is NON-tautological — first real substrate-derived
>   measurement.
> - **10D+E**: METHODOLOGY.md (9 rules from cycles 1-9
>   retrospectives) and attestation infrastructure.

---

## Cycle 10 — CS-doctor critiques addressed (4 sub-cycles)

After cycle 9 retraction, the catalogue's reliability was
called into question.  Cycle 10 addresses CS-doctor critiques
sub-cycle by sub-cycle.

### Cycle 10A — substrate M=1000 cross-validation

**Pre-registration commit `f31ba43`** (PREDICTIONS-126.md).
Demo source `4f7aa93`; measurement `5a80a97`.

Substrate phi-perc M=50 × K=20 = 1000 graphs at n=20, p=10%:

| metric              | value       |
|---------------------|-------------|
| sample mean         | 125,120     |
| sample stddev       | 67,282      |
| SEM (= stddev/√M)   | 2,170       |
| reference (cycle 9) | 126,549     |
| |diff| vs reference | 1,429       |
| 1σ (SEM-based)      | 2,170       |
| diff / SEM          | 0.66        |

**REGIME D fired (faithful, within ±1σ_1000 of reference).**

Cycle 8 measured 130,900 ± 6,270 (M=100); cycle 10A measures
125,120 ± 2,170 (M=1000).  The 130,900 was M=100 noise; true
substrate mean at this regime is essentially equal to true
classical reference 126,549 within sampling precision.

**Outcome: cycle-9 weak claim ("within 1σ at M=100") is
cross-validated at 10× tighter precision.**  Catalogue gains
its first cross-validated substrate finding at narrow scope
(n=20, p=10%).

### Cycle 10D + 10E — METHODOLOGY.md + attestation

**Commit `0354e81`** consolidates 9 rules learned across cycles
1-9 into `METHODOLOGY.md`:

1. Pre-registration in git BEFORE source
2. Literature review BEFORE pre-registration
3. Sample size discipline (M ≥ 1000 for ~3% precision)
4. Regime partitions without gap
5. Cross-validation before "stable" status
6. Honest aggregate accounting
7. Tautology detection (cycle 9 retrospective)
8. Scope claims match measurement scope
9. External attestation infrastructure

Implementation:
- `scripts/attest_prediction.sh` — SHA-256 + ledger append
- `attestations/ledger.txt` — append-only tamper-evident log
- `attestations/README.md` — anchor mechanisms documented

PREDICTIONS-124/125/126 retroactively attested.
PREDICTIONS-127 is the first ATTESTED-BEFORE-COMMIT entry.

### Cycle 10C — phi-integ pivot beyond tautology

**Pre-registration commit `b482dc7`** (PREDICTIONS-127.md,
attested per Rule 9).  Demo + measurement `539c01f`.

Cycle 9 CS-doctor critique #7: phi-perc on bare ER reduces to
`|connected_component| × L_max`, which classical theory and
substrate compute identically.  Not a substrate finding.

Pivot: phi-integ depends on NSUM of out-neighbours' OUT —
**second moment of degree distribution**, NOT reducible to
connected-component theory.

Analytic prediction (PREDICTIONS-127.md):
- Independence approximation:   238,380
- Correlation-corrected:        303,400

Measurement (n=20, p=10%, M=1000):

| metric                      | value       |
|-----------------------------|-------------|
| phi-integ mean              | 297,650     |
| phi-integ stddev            | 308,074     |
| phi-integ SEM               | 9,937       |
| E[OUT(1)] sample            | 2.85        |
| regime D match ([275k,330k])| **YES**     |
| regime E match (independence) | no        |

**REGIME D fired.**  Substrate REPRODUCES correlation-corrected
analytic 303,400 within 2%.  Substrate captures the ~27%
contribution of degree-degree correlation to E[phi-integ] on
bare ER.

**This is the first non-tautological substrate measurement
post-cycle-9 retraction.**  phi-integ is a higher-moment
graph statistic; substrate's BFS+NSUM implementation
correctly captures the higher-moment ensemble.

#### Sub-prediction transparency (Rule 6)

- Sub-1 (stddev ∈ [400k, 1200k]): **FAILED**.  Actual stddev
  308,074 below the bound.  Real finding: substrate phi-integ
  variance is LOWER than naive product-variance estimate
  — there are cancellations between OUT(1) and NSUM(1) at the
  variance level that don't appear at the mean level.  Worth
  follow-up cycle.  Does NOT affect main regime classification.
- Sub-2 (E[OUT(1)] ∈ [2.6, 3.2]): **PASSED** (2.85) after
  fixing integer-division bug in stat-mean.  Lesson: scale
  before divide to test non-integer means; logged.

### Aggregate accounting after cycle 10 (per Rule 6)

| status             | count | items                                          |
|--------------------|-------|------------------------------------------------|
| **Cross-validated**| 3     | cycle 6 stats infra; cycle 7 extensivity ratio; cycle 10A substrate phi-perc faithfulness at n=20 p=10% |
| **Pending cross-validation** | 1 | cycle 10C phi-integ correlation match (first measurement only) |
| **Retracted**      | 5     | cycle 1-3 demos (cycle 4-5); cycle 4-5 K_eff (cycle 6); cycle 7 phi-perc leak self-fixed; cycle 8 "deviation" (cycle 9); cycle 9 "fidelity" overclaim (cycle 10C scope) |
| **Infrastructure** | n/a   | cycle 10D+E methodology, attestation, lit-citation rule, regime-partition rule |

Net catalogue health: **3 stable findings**, 1 pending, 5
retracted, plus a methodology layer.  Honest counting per
Rule 6 makes this visible.

### Git history sequence (verifiable per Rule 9)

| Commit | Phase | Content |
|--------|-------|---------|
| f31ba43 | 10A pre-reg | PREDICTIONS-126.md (BEFORE source) |
| 4f7aa93 | 10A source  | demo 126 source (BEFORE measurement)  |
| 5a80a97 | 10A measure | substrate M=1000, regime D, cross-val |
| 0354e81 | 10D+10E     | METHODOLOGY.md + attestations infra   |
| b482dc7 | 10C pre-reg | PREDICTIONS-127.md (attested, BEFORE) |
| 539c01f | 10C measure | demo 127 + regime D phi-integ match   |
| THIS    | 10B reframe | this RESULTS.md section + CHANGELOG   |

Ledger cumulative SHA after cycle 10C: `11f940f7fc5c…77496`
(first external anchor pending per attestations/README.md
anchors index).

### Honest framing of catalogue state

**What survives CS-doctor scrutiny as of cycle 10:**
- Substrate **correctly implements classical graph theory**
  at second-moment level (cycle 10A first-moment, cycle 10C
  second-moment via degree-degree correlation).
- Substrate phi-perc is a faithful BFS at n=20 p=10%; phi-integ
  ensemble captures ~27% correlation contribution analytically
  predicted from classical ER.

**What does NOT survive:**
- Any "substrate-derived deviation from classical" claim.  The
  cycle-8 candidate was an asymptotic-formula bug; cycle-10A
  confirmed substrate matches true classical.
- Any "substrate-specific finite-size correction" claim.  Not
  measured.
- Any "consciousness-measure content" claim of phi-perc /
  phi-integ on bare ER substrates.  These are graph statistics,
  not consciousness measures, until applied to feature-loaded
  + dynamic substrate where node features encode model state
  (Track 3.1 Pythia).

**What is the legitimate research direction (cycle 11+):**
- phi-integ ensemble on substrate AFTER STEP-CA rule execution
  (substrate-native dynamics; no direct networkx analog).
- HEDGE3 typed hyperedge benchmarks where Peirce-pattern
  queries genuinely benefit from substrate-level typing.
- Companion #1 (Pythia attention) where substrate is the
  natural representation, not a re-encoding of classical
  graphs.

This is a substantially narrower programme than the v9.0
preprint implies, but it is the one supported by what cycles
1-10 actually demonstrate.

---

## Cycle 11 — substrate vs independent ref + first attempted falsification

### 11A (commits `6a1fd73` / `a9ef2fc` / `308fbe3`)

Networkx Monte Carlo M=10000 reference for phi-integ semantics.
Reference 310,577 vs substrate cycle 10C 297,650 — regime F'
fired (substrate deviates from ref by 12,927 = 1.26σ combined).

### 11A.1 (commits `c0ee1a8` / `dd8c938` / `bad2ae0`)

Substrate M=10000 to resolve F'.  Mean 304,701 → diff 5,876 =
1.29σ combined.  Regime I (small possible bias).  Statistically
not significant — substrate consistent with ref to within
precision.

### 11B (commits `618c618` / `a84ea95`) — **RETRACTED in cycle 12A**

Iterated NSUM dynamics: r10=305, r21=302.  Regime L "fired"
per pre-reg strict inequality.  See Cycle 12A below for full
retraction.

### 11C (commit `c0de275`)

First external ledger anchor: git tag `attest-2026-05-22-cycle11`
pushed to GitHub.  Ledger SHA `77e0a79c…ab116`.  Closes Rule 9
violation from cycle 10D.

### 11D (commits `a86686d` / `618c618`)

Pre-commit hook `scripts/pre-commit-methodology.sh` enforces
Rules 2/4/9.  Fired on own first commit; regex fixed and
re-committed.

---

## Cycle 12 — Counter-example methodology (Option I pivot)

### Strategic pivot

After 11 cycles producing ZERO substrate-derived findings
beyond classical theory, the catalogue methodology was
re-evaluated.  Inspired by OpenAI's recent autonomous
disproof of Erdős's 1946 unit-distance hypothesis via
counter-example search (Habr 1037534, 2026-05-22): switch
from **validation** ("test substrate ≡ classical and confirm
within precision") to **counter-example search** ("formal
conjecture substrate ≡ classical; SEARCH configuration space
for a counter-example; one suffices to disprove").

### 12A — Cycle 11B RETRACTION (6th retract in catalogue)

Cycle 11B's "regime L — substrate-axiom FALSIFIED" claim is
**RETRACTED** for the reasons:

1. **Coin-flip pre-reg rule.** Pre-registered rule was
   `r21 ≥ r10` (strict inequality, no tolerance).  Under null
   hypothesis (substrate satisfies axiom), `P(r21_meas < r10_meas) ≈ 0.5`
   by sampling symmetry.  Pre-reg was a coin flip masquerading
   as a falsification test.
2. **Effect within sampling.** 3-unit difference in scaled×100
   units at M=100 is within sampling SEM (~5).  Statistically
   consistent with null.
3. **Strawman axiom.** "PA feature-integration axiom"
   attributed to Pointer Architecture was standard power-
   iteration theorem from linear algebra.  Falsifying it
   doesn't disprove PA — disproves the axiom-labeling.
4. **r ≈ mean-degree confirms substrate ≡ power-iteration.**
   For ER with self-loops, λ₁ ≈ mean degree ≈ 2.9.  Substrate
   ratios 3.05 and 3.02 are at λ₁.  Substrate correctly
   implements matrix power iteration; no anomaly.

Demo 130 retained in regression gate with explicit RETRACT
NOTICE at the top.  Pins unchanged; interpretation downgraded
from "axiom falsified" to "substrate correctly implements
spectral power iteration".

### Aggregate accounting (post-cycle-12A, honest)

| status | count | items |
|--------|-------|-------|
| **Substrate-derived findings** | **0** | cycle 11B retracted; no substrate-distinguishing behaviour ever observed |
| Substrate ≈ classical (within precision) | 2 | cycle 10A phi-perc; cycle 11A.1 phi-integ |
| Pending real substrate-distinguishing test | n/a | requires Option I search (12B/12C) |
| Retracted | 6 | cycles 1-3, 4-5, 7-self, 8, 9-scope, **11B** |
| Infrastructure | live | methodology + pre-commit hook + attestation + first external anchor |

The catalogue is honest:
- Substrate is a correct hypergraph rewriting engine.
- Substrate-derived findings beyond classical theory: **none**.
- Methodology infrastructure is real and enforces itself.

### 12B (commit `8adbdee`) — Formal conjecture document

`docs/SUBSTRATE-EQUIV-CONJECTURE.md` formalizes three conjectures:
1. Φ-family computational equivalence: TRUE by inspection
2. HEDGE3 storage advantage bound: UNKNOWN (cycle 12C target)
3. Computational ergonomics: TRUE by inspection

PREDICTIONS-131.md attested + committed BEFORE search script.

### 12C (commit `0beac84`) — Counter-example search result

Exhaustive enumeration n=3..6, 99,497 configurations.  Max
R(S) = 1.500, min R(S) = 1.000.  **REGIME O fires per
pre-registered threshold; pre-registration's prose labels were
inverted (R > 1 means HEDGE3 takes MORE storage, not advantage).**

**Substrate-derived finding (NEGATIVE direction)**: HEDGE3 has
NO storage advantage at n=3..6.  At worst 1.5× more; mean
1.13-1.23× more.  Demo 105's "5× storage advantage" was against
naive binary; against shared-aux-node binary, HEDGE3 is parity-
or-worse.

Updated aggregate (per Rule 6 honest accounting):
- Substrate-derived findings (pre-registered, surviving scrutiny): **1** (cycle 12C HEDGE3 storage NULL)
- Substrate ≈ classical: 2
- Retracted: 7 (cycles 1-3, 4-5, 7-self, 8, 9-scope, 11B, demo 105 storage advantage)
- Infrastructure: live

---

## Cycle 13 — Strategic refresh after external research

### Strategic context (commits `c0de275`+deep research 2026-05-22)

After 12 cycles producing one substrate-derived finding (negative)
and seven retractions, three parallel deep-research agents were
launched on 2026-05-22:

1. **PA v9.0 external existence** — confirmed PA v9.0 has **NO
   public preprint, peer-reviewed paper, or third-party citation**.
   All definitions (`(G, R, C, A, π)` tuple, Φ_PA, substrate-monist
   halting, PSH1-5 maps) exist only inside `/sixt`.  The theory
   IS the codebase; there is no external axiomatic foundation to
   align to.

2. **Wolfram Physics Project status** — Wolfram Physics Project
   is **in the same trap as Sixth**.  Aaronson and Harlow
   (Scientific American): "infinitely flexible philosophy, no
   concrete new predictions."  Wolfram himself: "not directly
   amenable to experimental falsification."  Sixth is not
   isolated — the entire hypergraph-rewriting-substrate-research
   programme has this challenge.

3. **Positive escape exists**: Causal Sets (Sorkin) demonstrated
   how to escape via discreteness × symmetry binding.  Sorkin's
   1987 prediction of Λ ~ √N from spacetime discreteness was
   confirmed by 1998 dark-energy discovery — substrate-essential
   because the prediction comes from discreteness × Lorentz-
   invariance × Poisson sprinkling specifically.

4. **One concrete published methodology not yet applied to
   hypergraph substrates**: Krasnovsky's EICS (Effective Information
   Consistency Score, arXiv 2509.07149, Sept 2025).  Sheaf-cohomology
   inconsistency × Gaussian effective-information proxy.  White-box,
   single-pass, dimensionless — cross-substrate comparable.  Has
   been applied to transformer circuits but never to hypergraph
   rewriting substrates.  Could be Sixth's first SUBSTRATE-
   DISTINGUISHING measurement.

### 13A — Honest reframe (this commit)

The catalogue's honest current state:

| claim | evidence |
|-------|----------|
| Sixth is a working hypergraph rewriting engine | YES — 1925 ✓ across 125 demos |
| Sixth implements PA v9.0 | UNTESTABLE — PA v9.0 has no public formalization |
| Sixth's Φ-family measures consciousness | NO — measures are classical graph statistics |
| Sixth's HEDGE3 has storage advantage | NO — cycle 12C shows parity-or-worse vs optimized binary |
| Substrate-monism is supported by measurements | NO — substrate ≡ classical at every tested observable |
| Methodology infrastructure is solid | YES — pre-reg + attestation + hook + anchor |
| Negative-result catalogue is publishable | YES — Koch 2026 + Cogitate 2025 + AlphaEvolve provide receptive context |

**Therefore**: Sixth's claim space is downgraded to:

- **Engineering**: Sixth is a Racket-hosted reference implementation
  of typed-hypergraph rewriting, with methodology infrastructure
  (pre-reg, attestation, enforcement hook) usable for
  substrate-research community.
- **Negative results**: Sixth has been systematically tested via
  pre-registered cycles and consistently shows substrate ≡ classical
  for all currently-defined Φ measures.  This is itself a research
  contribution (negative-result paper).
- **Consciousness measures**: NOT supported by current measurements.
  Φ-family naming retained for codebase continuity but reframed
  in stdlib comments as "candidate observables" not "consciousness
  measures".

The "Pointer Architecture v9.0" framing is suspended pending either:
(a) author publishes formal axioms externally, OR
(b) cycle 13B+ produces a substrate-distinguishing measurement that
    falls out of a specific PA axiom not reducible to classical.

### 13B (next) — EICS application as cycle's final attempt

If EICS_substrate ≈ EICS_random_baseline at matched size, cycle
13 reports null and Sixth is finalized as engineering/methodology
contribution.  If EICS shows substrate-distinguishing signal
(unexpected), cycle 14+ investigates.

Pre-registration commit pending.  Companion #1 Pythia (long-term)
remains the future site where EICS could be applied to real LLM
substrates.

## Meta-Semantics Milestone (Cycles 24-26)

A separate research arc from the loss-family work (cycles 14-23A,
which closed CCCCC at commit `36fb9ee`).  This arc tests whether
Sixth, as an *engine*, can move from fixed-primitive interpretation
to runtime-evolving law-state.

### Cycle 24 — Protocol specification

**Deliverable:** `docs/META-SEMANTICS.md` v2 (commit `360604d`) +
v2.1 amendment with §17 Energy Accounting (commit `67cab83`).

**Scope:** normative specification only.  No code.  Establishes the
two-tier primitive lifecycle (Tier 1 ephemeral in-run, Tier 2 stable
cross-run via held-out gate) BEFORE any primitive induction code is
written, so rules of the game are fixed independent of any specific
candidate.

**v1 → v2 supersession**: v1 (commit `ec7370f`) described offline
deployment pipeline; deprecated within session because it missed the
runtime-evaluation requirement.  Audit trail in ledger (`096d2902`
→ `9f43e3a8`).  v1 was never used as basis for any cycle 25+ test.

### Cycle 25 — Runtime plumbing (5 sub-commits)

| sub | commit | scope |
|-----|--------|-------|
| 25A | `34cad87` | Tier 1: 6 meta-prims + 4-tuple runtime + demo 143 |
| 25B | `2421e0f` | Tier 2 stubs (8) + 12 frozen Sixth-native substrates + manifest |
| 25C | `b660eb5` | mining_protocol.md frozen hyperparameters |
| 25D | `78143cf` | 15-item hardening pass (demo 145, 22 asserts) |
| 25E | `67cab83` | Energy Accounting v0 — observational (demo 146, 10 asserts) |

**Key architectural result of cycle 25A:** `law_hash` mutates inside
a single run (verified by demo 143: 231849... → 278734... → 231849...
across `INDUCE-RUNTIME` and `ROLLBACK-RUNTIME`).  This is NOT a
deployment pipeline event; it is mid-execution self-modification of
the active dictionary.

**Anti-Python guardrail (cycle 25B per user spec 2026-05-23):**
substrate generation lives in Sixth (`stdlib/substrate-gen.6th`)
via existing PRNG (`stdlib/rand.6th`) and recursion.  No Python in
core path.  12 substrates (6 train + 6 held-out) generated and
signed at `substrates/manifest.6th`.  Python remains for external
visualization only.

**Hardening invariants (cycle 25D):** 15 items asserted via
demo 145.  Highlights:
- canonical `law_hash` includes word body (replacement detected)
- `world_hash` and `law_hash` separated (mutation of one doesn't
  affect the other; verified inline)
- SHADOW-CHECK forbidden-symbol blacklist + lookup-purity
- INDUCE-RUNTIME requires valid shadow certificate (defence-in-depth)
- ROLLBACK transactional: clears certificate, status → 'rolled-back
- contamination is first-class status with explicit reject paths
- substrate generators deterministic on re-run

### Cycle 26 — Energy gate ACTIVE + manual validation

**Pre-reg:** PREDICTIONS-147.md (commit `e4dd80d`, attested
`afe4782b`).

**Implementation (commit `2e1edbf`):**

| mechanism | enforcement |
|-----------|-------------|
| Coupling N=5 uses | `COMMIT-PRIMITIVE` raises if `uses < N` |
| Coupling M=3 distinct sessions | `COMMIT-PRIMITIVE` raises if `len(sessions) < M` |
| Energy gate `net_delta_e < 0` | `COMMIT-PRIMITIVE` raises if `net_delta_e >= 0` |
| Per-cand session tracking | dispatch hook adds session-id to per-cand set |
| `NEW-SESSION` test primitive | increments deterministic session_id (test-only) |
| `WRAP-MOTIF` helper | construct length-1 motif (DETECT-MOTIF can't) |
| `TRY-COMMIT` | catches exn:fail:sixth, returns status sym |

**Demo 147 (happy path, 12 asserts):**
- Motif `MARK MARK bi-edge` (L=3)
- N=5 uses split across M=3 sessions
- `E_law` post-INDUCE = 3, `E_reuse_gain` post-5-uses = 10
- `net_delta_e` = 3 - 10 = **-7** → energy gate passes
- COMMIT succeeds, status `'committed`, FREEZE stub accepts

**Demo 148 (negative path, 7 asserts):**
- Single `MARK` (L=1) via `WRAP-MOTIF`
- Same coupling: N=5 across M=3 sessions
- `E_reuse_gain` = 5×(1-1) = **0**
- `net_delta_e` = 1 - 0 = **+1** → energy gate REJECTS
- `TRY-COMMIT` returns `'rejected-energy`
- Status stays `'ephemeral-active`, not promoted

**Why demo 148 matters more than demo 147**: demo 147 only proves
the mechanism works on happy path.  Demo 148 proves the gate
**actually gates**, not just decorates.  Without demo 148, a
critic could say energy_gate is theater.  With 148, the rejection
path is machine-asserted.

### What the meta-semantics arc claims (honest scope)

**Now operationally true (machine-verified at every regression run):**

1. Sixth supports runtime law-state mutation: a single execution
   session can change its own active dictionary mid-run, with the
   mutation observable in `law_hash` and recorded in `ledger`.

2. The mutation is gated: a candidate is committed only if it
   satisfies coupling (N=5 uses across M=3 sessions) AND energy
   (`net_delta_e < 0` per energy v0 formula).

3. Negative validation: a candidate that meets coupling but fails
   energy is rejected (`'rejected-energy` symbol returned).  The
   gate is not decoration.

4. Substrate generation is Sixth-native: `_energy-*` keys are
   observational only and do not enter `law_hash` or `world_hash`.

### What it does NOT claim

- It does NOT claim automated discovery: cycle 26 uses
  hand-crafted motifs.  Cycle 27 is the first automated test.
- It does NOT claim cognition-substrate behavior: energy v0
  is a count-based formula, not a theory of meaning.
- It does NOT claim primitive induction generalizes to useful
  cognitive structure: the test cases are toy motifs chosen for
  protocol validation, not scientific signal.
- It does NOT validate Tier 2 stable promotion: cycle 26 only
  reaches the `'committed` Tier 1 status; Tier 2 stubs remain
  gate-closed (HELD-OUT-EVAL returns 0) until cycle 27+ wires
  held-out infrastructure.

### Aggregate state after cycle 26

- Regression: **2070 / 2070 ✓ across 142 demos**.
- Frozen substrate set: 12 (train + held-out).
- Frozen mining protocol: hyperparameters in `docs/mining_protocol.md`,
  cannot change without deprecation cycle.
- Meta-semantics specification: v2.1 attested via ledger;
  modifications require new pre-reg.
- Energy accounting: v0 formula attested; v1 deferred to post-cycle-27
  pending evidence whether v0 is too crude.

### Catalogue formulation (post-cycle-26)

> primitive ≠ named macro.
>
> primitive = runtime-induced law candidate that survived
> equivalence (SHADOW-CHECK), reuse (N=5 uses), multi-session
> coupling (M=3), and negative energy delta (`net_delta_e < 0`).

This formulation is now machine-enforced.

---

## Cycle 27 — Automated Tier 1 Discovery

**Pre-reg:** `examples/PREDICTIONS-149.md` (commit `8828052`,
attested ledger sha `87a64fe7`).

**Single primary claim** (verified):

> Sixth can automatically discover and commit an energetically
> justified runtime law candidate from execution traces under a
> frozen mining protocol (`docs/mining_protocol.md` commit
> `b660eb5`).

### What was implemented

`DETECT-MOTIF-AUTO` Tier 1 primitive (`sixth/meta/tier1.rkt`):
- enumerates all distinct n-grams of length [MIN_LEN, MAX_LEN] in
  the trace window K=20
- filters n-grams containing any `FORBIDDEN-IN-MOTIF` or
  `INSPECTION-OPS` symbol
- counts non-overlapping occurrences per distinct n-gram
- ranks by `(frequency desc, length desc, motif-hash asc)` —
  fully deterministic
- returns top-1 (or empty list)

Distinct from existing `DETECT-MOTIF` (tail-anchored legacy
heuristic).  Used by automated discovery; existing `DETECT-MOTIF`
remains for the cycle-25/26 happy-path test demos.

### Happy path (demo 149)

Workload: 4 inline `MARK MARK bi-edge` sequences with `NODES drop`
noise between.  Source code does NOT name the candidate motif
anywhere — the miner alone selects via deterministic ranking.

Result: miner discovered `(MARK MARK bi-edge)` (length 3, freq 4
in the workload), passed SHADOW-CHECK, INDUCE → cand_001, used 5
times across 3 sessions (`NEW-SESSION` between), `net_delta_e =
3 - 10 = -7`, COMMIT succeeded, status `'committed`,
ATTEST-PRIMITIVE stub recorded.  10 asserts pass.

### Negative controls (demos 150, 151, 152)

Three negative demos verify that the miner correctly REJECTS bad
inputs (no candidate committed):

| demo | workload | expected | result |
|------|----------|----------|--------|
| 150 | trace without 2-gram appearing ≥3× | empty motif, no induce | ✓ |
| 151 | distinctive motif appears only 2× | empty motif (below R=3) | ✓ |
| 152 | repeated n-gram laced with LAW-HASH (INSPECTION-OPS) | clean alternative returned, no forbidden in output | ✓ |

Each negative passes 2 asserts.

### Demos 153, 154 — DEFERRED (documented gaps)

**153 world-mismatch**: requires substrate-snapshot infrastructure
to compare a candidate's run-time behavior against its expansion's
behavior beyond symbol-level equivalence.  Substrate snapshot
deferred to cycle 28.

**154 energy-fail-auto**: structurally impossible under frozen
protocol — `MIN_LEN=2` prevents length-1 motifs from being
discovered, so the energy gate cannot fire "too late" at COMMIT
for auto-discovered candidates.  This is the defence hierarchy
working as designed: `MIN_LEN` at mining (first defence) preempts
the energy gate at commit (last defence).  Cycle 26 demo 148
already verified the energy gate works for hand-crafted length-1
inputs.

### What cycle 27 demonstrates

- Automated Tier 1 discovery is operational: the miner finds a
  candidate, SHADOW gates, runtime mutation happens, candidate is
  used, COMMIT under N=5 / M=3 / energy<0 gates succeeds — all
  without human curation of the candidate motif.

### What cycle 27 does NOT claim

- The discovered candidate is *useful* for anything beyond protocol
  validation.
- Sixth has discovered "a useful law" or "a substrate-of-cognition
  primitive".
- Stable promotion has been validated.  PROMOTE-STABLE still
  returns `'rejected-no-heldout-in-25D` (the Tier 2 gate is
  closed).
- The negative controls are exhaustive (153 and 154 are
  documented gaps).

### Aggregate state after cycle 27

- Regression: **2086 / 2086 ✓ across 146 demos**.
- Mining protocol parameters unchanged from cycle 25C freeze.
- Tier 2 stable promotion still gate-closed; cycle 28+ wires
  held-out infrastructure.
- Energy gate operational; demo 148 verifies it rejects;
  demo 149 verifies it accepts justified candidates.

### Catalogue formulation (post-cycle-27)

> automated discovery = trace mining + deterministic ranking +
> blind candidate naming + protocol-validated commit.
>
> Cycle 25: закон можно менять.
> Cycle 26: закон можно закреплять по цене.
> Cycle 27: кандидат в закон можно находить автоматически.

The next test (cycle 28+) is whether candidates discovered on
train substrates carry over to held-out — first real
generalization claim.

---

## Pending / future tracks

| Track | Description | ETA |
|-------|-------------|-----|
| 1.1 | L_max derivation from invariance | open |
| 1.2 | Φ_PA family axiomatization | open |
| 1.4 | Substrate-monism vs functionalism formal | open |
| 2.2 | Spontaneous symmetry breaking | open |
| 2.4 | Φ_PA response under perturbation | open |
| 3.1 | Companion #1: Pythia Φ_PA validation | 2027-06-30 |
| 3.2 | Companion #2: Casali PCI vs Φ_integ on archived EEG | 2027-12-31 |
| 4.1 | Combination problem (nested observer Φ_PA composition) | open |
| 4.2 | Content theory sketch | open |
| 4.3 | Cross-substrate Φ_PA invariance | open |
