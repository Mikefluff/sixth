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

---

## Aggregate

| Track | Hypothesis | Outcome | Demo | ✓ |
|-------|------------|---------|------|---|
| 1.3 | HEDGE3 realises Peirce thesis | **NEGATIVE** — ergonomic only | 105 | 21 |
| 2.1 | Φ_PA has phase transition | **NEGATIVE** — linear-only | 106 | 25 |
| 2.3 | Open-ended rewrite gives emergent topology | **POSITIVE** — universal 3× growth law | 107 | 18 |

**Net research output (session 2026-05-21):** 3 demos, 64 asserts,
**2 honest negative results + 1 positive substrate-derived universal
property**.  Negative results bound Φ_PA / HEDGE3 expressive power
formally; positive result demonstrates first non-tautological
cosmogenesis in the catalogue.

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
