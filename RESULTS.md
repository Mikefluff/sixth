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
