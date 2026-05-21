# Sixth — Curated Tour

> A 10-demo reading path through 102 demonstrations. Each entry is
> chosen because it shifts the mental model of what the substrate
> IS, not because it covers a feature checkbox.  Reading these 10
> in order takes ~40 minutes (run + read source); reading all 102
> is unnecessary unless you are auditing the regression gate.

The full catalogue (with phase headings and every demonstration's
assertion count) is in [`examples/README.md`](../examples/README.md).
This document is the **author's honest pick** of which demos earn
their place in your head.

---

## 0. Quickstart (before the tour)

```bash
raco pkg install --link .
make verify
```

Expected output ends with `artifact status:  reproducible`.  If
that line is present, every demo below will run by name; if not,
fix the install before reading further.

To run any tour stop on its own:

```bash
racket -l sixth/cli -- run examples/<demo-file>.6th
```

---

## 1. The canonical Spencer-Brown ladder (demos 01–11)

**File range:** `examples/01-void.6th` through `examples/11-measurement.6th`.

Eleven atomic demonstrations, each one rung of the substrate's
self-construction: void → first distinction → second distinction →
first pointer → self-pointer → mutual-pointing → observer-state →
I/not-I → recognition → closure-of-not-I → measurement (first
non-trivial Φ_PA).

**Why it earns a tour slot.** Everything else in the substrate is
*derived from* this ascent.  If you read the rest of the tour
without internalising the ladder, the later substrate concepts
will feel like API documentation.  If you internalise the ladder,
the later concepts feel inevitable.  This is the only tour entry
covering more than one file because the eleven rungs are not
independently meaningful — they are eleven moments of one
construction.

**What's NEW about it** vs other Spencer-Brown framings: every
rung is a substrate-readable program, not commentary.  You can
`RESET` after each rung and verify it stands on its own.

---

## 2. Substrate Turing-completeness (demo 18)

**File:** `examples/18-rewrite-tc.6th`.

A `STEP-CA` rule encoding Rule 110 (Wolfram's universal CA) on the
substrate, demonstrating that substrate-level rewriting alone is
Turing-complete.  No host computation; the substrate IS the
universal computer.

**Why it earns a tour slot.** The PA position requires substrate-
internal universal computation (otherwise observers couldn't
in principle simulate any computable phenomenon).  This demo is
the discharging of that requirement in 23 assertions.  Once you
have read 01–11 and then 18, you have read the entire
"substrate is computationally adequate" case.

---

## 3. Substrate-native autopoiesis (demo 32)

**File:** `examples/32-autopoietic-ring.6th`.

A ring of nodes whose update rule reads its own next/prev
neighbours and rewrites itself — the discrete analogue of
Maturana–Varela autopoiesis.  The ring maintains itself across
arbitrary cycle count without external regulation; severing a
single edge breaks the autopoietic closure; restoring it
reinstates the substrate's self-maintenance.

**Why it earns a tour slot.** This is the **first demonstration
that "self-producing system" is a substrate-level structural
property**, not a biological metaphor.  Pilot A (demos 32–36) all
build on this — pick 32 as the canonical entry because it shows
the property in its most minimal form.

---

## 4. Cosmogenesis from one MARK (demo 41)

**File:** `examples/41-cosmogenesis-bootstrap.6th`.

A substrate-resident observer constructs a 13-node 48-edge
"cosmos" starting from a single `MARK` at t=0.  The construction
is observer-driven (the observer's own scope-update rule produces
the next node and edge); it survives a harsh autopoietic decay
phase that strips most edges; the observer rebuilds.

**Why it earns a tour slot.** Cosmogenesis from one distinction
is the substrate-monist position made operational.  The
demonstration is small (21 assertions) but the conceptual content
is "the substrate constructs its own world starting from one
difference."  If you accept the ladder (1) and Turing-completeness
(2), this is the third pillar: the substrate is also
self-constructive.

---

## 5. Substrate measures itself (demo 43)

**File:** `examples/43-phi-pa-measurement.6th`.

Three observer configurations: one with no self-reference, one
with self-reference and scope 5, one with self-reference and
scope 13.  All three measured by the same `phi-pa` word from
`stdlib/phi.6th`.  Result: Φ_PA = 0, 50000, 130000 respectively.

**Why it earns a tour slot.** Φ_PA is the central scalar of the
v9.0 preprint.  This demo shows it is **substrate-readable**:
not an external observer's annotation, but a value the substrate
computes about itself using the same 40 primitives that built it.
If Φ_PA were a host-computed quantity the substrate-monist
position would be philosophical hand-waving; because it's
substrate-readable, it is operational.

---

## 6. Split-brain discriminates Φ_PA candidates (demo 46)

**File:** `examples/46-phi-pa-split-brain-toy.6th`.

A small substrate modelling intact vs callosotomy (corpus
callosum severed).  Φ_PA is **indifferent** under the split (both
hemispheres preserve their scope), but Φ_integ (the integration-
weighted variant from `stdlib/phi.6th`) **halves** at the split.

**Why it earns a tour slot.** The PA framework ships **multiple
candidate measures** of consciousness, not a single anointed
scalar.  This is the demo that motivates having alternatives: the
split-brain phenomenon discriminates one candidate (Φ_integ) from
another (Φ_PA) on synthetic data.  Reading 43 then 46 in sequence
sets up the empirical question F5 of the preprint: which
candidate discriminates real-data predictions P1–P5 best?

---

## 7. Charge conservation Noether-style (demo 51)

**File:** `examples/51-charge-conservation.6th`.

An 11-cell ring with 5 "particles" (tagged NGET ∈ {1,2,3}).  A
`STEP-CA` rule (generalised Wolfram Rule 184) moves each particle
right one cell per step iff the right neighbour is empty.  Across
5 steps, **Σ NGET is conserved exactly** (Noether-style) AND
per-species count is conserved.

**Why it earns a tour slot.** Conservation laws are usually
*derived* from symmetries via Noether's theorem in continuous
physics.  Here, the same conservation grammar emerges from a
discrete CA rule on the substrate, substrate-readable by a single
`EACH + sum` query.  This is the substrate analog of "the
existence of a continuous symmetry implies a conserved quantity"
made operational on a 38-primitive computational substrate.

The same conservation pattern reappears at 10⁶ scale in demo 79
(stress-test track) — Σ NGET drift is exactly 0 across one
million STEP-CAs.

---

## 8. Honest emergence — composites EMERGE, not hand-placed (demos 86, 92)

**Files:** `examples/86-emergent-composite-from-chain.6th`,
`examples/92-recursive-hierarchy-fixed-point.6th`.

Demo 86: start with a plain 5-cell chain (4 bi-edges, no
triangles).  Apply `close-2path` rule via `EACH-2PATH` —
transitive-closure edges 1↔3, 2↔4, 3↔5 appear.  Apply triangle-
scanner rule — 3 composite observers spawn for the 3 triangles
that arose.  **Every node and every edge past t=0 is a
substrate-readable response to substrate-readable conditions.**
Nothing past the initial chain is hand-placed.

Demo 92: extend to N tiers.  Same `close-2path` + `scan-triangle`
+ `link-composites` rules at every tier with memory-stored NGET
filter; recurse to fixed point.  Pattern of spawns: 5 → 3 → 1 →
0 (data-driven termination).

**Why these earn one combined tour slot.** Pilots G/H/I/K/L/M
(demos 48–52, 75–77) all hand-place their composites and then
assert the construction has predicted properties — *verifying
that "if I wrote a triangle, it has three corners"*.  The
honest-emergence track (85–92) corrects this: the substrate
DERIVES composite-distinction structure from minimal initial
state via substrate-readable rules.  This is a major
**methodological self-correction** in the catalogue and is the
single most important conceptual upgrade after the original
v9.0 ascent.

---

## 9. MEDIATOR causal hypergraph — Wolfram-aligned (demo 100)

**File:** `examples/100-mediator-causal-graph.6th`.

6 MEDIATOR hyperedges `(substrate-state, rule-node,
substrate-state)` build a DAG of causal events.  Substrate-readable
queries:

- forward causal cone of s1 via NGET fixpoint iteration: 6 nodes
- backward ancestor set of s6: 5 nodes
- direct descendants / antecedents / "which rule produced s6"
- per-rule firing counts

**Why it earns a tour slot.**  Time as a substrate-readable
partial order over rule firings is the Wolfram Physics Project's
foundational move.  This demo realises it concretely on the
Sixth substrate via the HEDGE3 MEDIATOR kind.  The substrate
carries its own causal history as first-class hyperedges; **no
external clock, no host-side event log**.  If you have followed
the tour to this point, this is where substrate-monism extends
from state to causality.

The HEDGE3 primitive family itself (added May 2026) is
documented in stdlib/hedge.6th; the four canonical kinds
(WITNESS / MEDIATOR / CONTEXT / SIMPLEX) are introduced in demos
93–98 if you want to study the primitive layer in isolation
before this application.

---

## 10. Φ_PA^W — formal substrate-measure extension (demo 102)

**File:** `examples/102-phi-pa-witness-extension.6th`.

A new substrate-readable observability measure:

```
Φ_PA^W(O) := (OUT(O) + W(O)) · 1[O EDGE? O] · L_max
```

where `W(O)` is the count of WITNESS hyperedges with O as third
leg — the number of substrate edges O grounds as witness.
Reduces to Φ_PA when W(O) = 0 (backward compatibility).

The demo constructs four observers with intentionally different
binary-vs-witnessing profiles.  **Φ_PA and Φ_PA^W rank them
differently**: an adjudicator-style observer with small binary
scope and many witnessing assertions is invisible to Φ_PA but
top-tier under Φ_PA^W.

**Why it earns a tour slot.** This is the **only formal
extension of the consciousness-measure family** in the entire
post-v9.0 catalogue.  Φ_integ and Φ_bidir (preprint
sec:phi-pa-alternatives) were already in the stdlib.  Φ_PA^W is
new and falsifiable: it makes a different prediction about which
observers count as "more conscious" in any substrate with
typed-trivalent provenance structure.

---

## Why these 10 and not the other 92

Honest accounting of what was cut and why:

| Reason for cut | Demos affected | Approx count |
|----------------|----------------|--------------|
| **Variants of one mental model** | 02–11 already represented as one slot; 33–36 reinforce 32 (autopoiesis); 49–50, 52, 75–77 reinforce 48 (composite distinction); 87–91 reinforce 86 (honest emergence); 93–98 reinforce 100 (HEDGE3 introduction) | ~30 |
| **Visual-trace companions** | 55–74 are DOT-rendered companions to the numerical pilots, not new content | 20 |
| **Stress-test track** | 79–84 are reproducibility-at-10⁶-scale variants of pilots already covered (J', L+M, A', Conway, Sprout, Rule 184) | 6 |
| **Application coverage** | 12–17, 19–31 demonstrate that the substrate derives standard CS structures (Peano, BFS, observers, conservation, CA family, consensus, morphism, Conway).  Each is a single specific application; collectively they discharge "substrate is rich enough", individually no one is essential reading | ~25 |
| **Pilot F encoding-map pilots** | 44, 45, 47 are alternative-substrate encodings (transformer, brain, ant colony); 46 was kept as the discriminator demo, but 44/45/47 are reinforcement | 3 |
| **Long-epoch parametric** | 53–54 demonstrate TCO-safe parametric runs; valuable for reproducibility, not for mental model | 2 |
| **Peircean trit + four HEDGE3 kinds in detail** | 90 (Peircean trit classifier), 94 (all four kinds coexisting), 97 (MEDIATOR in depth), 98 (SIMPLEX in depth) — all give substantive content but the substrate-monist commitment is already made by demos in this tour | ~4 |
| **Substantive HEDGE3 applications** | 99 (self-modification) and 101 (belief revision) are *substantive* and almost made the tour; cut for length (replaced by their cousin 100 which best demonstrates the substrate-monist commitment over causal structure) | 2 |

The cuts are not because those demos are weak.  Many of them
(99 self-modification, 101 belief revision, 88 emergent
two-tier hierarchy, 46 split-brain, 75 particle binding) are
*specifically pleasant*.  They are cut because reading more than
ten demos in a tour starts to defeat the purpose — *curation IS
the value of a tour*.

If you have read the ten tour entries and want more, the order
of next-best demos is:

11. **Demo 88** — emergent two-tier hierarchy (intermediate
    between 86 and 92; concrete case before the fixed-point
    generalisation).
12. **Demo 75** — particle binding (Pilot L); HEDGE3 thinking
    before HEDGE3 existed.
13. **Demo 99** — substrate-self-modification via CONTEXT
    history; learning in minimal form.
14. **Demo 101** — WITNESS belief revision; substrate-native
    consensus.
15. **Demo 65** — PA-ontological shell decomposition; the
    eleven rungs of the canonical ladder unfolded as one
    sub-cycle of Pilot D.

---

## What to read instead of more demos

After this tour you have read the substrate's mental model.
Further depth is in the **companion documents**, not in more
demonstrations:

- `SUBSTRATE.md` — formal documentation of the 38 base + 7
  HEDGE3 primitives + stdlib organisation.
- `LANGUAGE.md` — Sixth as a stand-alone programming language,
  for readers who reject the v9.0 cosmology and want only the
  language.
- `CLAIMS.md` — three-tier taxonomy separating what the tests
  prove (Tier 1), what the demos show on synthetic data
  (Tier 2), and what remains philosophical hypothesis (Tier 3).
- `/Users/mikefluff/Documents/godacademy/preprints/pointer-architecture/main.tex` —
  the v9.0 preprint itself (70 pages, includes the Filioque /
  Peirce / Φ_PA^W extensions added May 2026).

---

## Versioning

This tour is curated for the **v0.8 release** of Sixth (artifact
tag, repository state at commit `0757d32` or later).  Demo
numbering is stable from v0.8 forward.  Earlier versions had a
v0.7 ascent (demos 1–67) and pre-HEDGE3 organisation; the
present tour assumes v0.8.

If you find a demo file referenced here that no longer exists,
the catalogue has moved past v0.8; check `examples/README.md`
for the current numbering.
