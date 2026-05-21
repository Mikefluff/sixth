# Claims — what Sixth proves, demonstrates, and conjectures

External-reviewer feedback (2026-05-20) flagged that the Sixth project
risks conflating three very different epistemic categories: proved-by-
running-the-code, demonstrated-by-construction, and philosophical
conjecture under empirical falsifier. This document is the explicit
three-tier map. The goal is honest scope: a referee reading the v9.0
preprint or the released code should never have to guess which tier
a given sentence belongs to.

**Single-command verification of Tier 1**: run `make verify`. The
output prints `artifact status:  reproducible` if every Tier-1
statement below holds against the released code; otherwise it prints
`BROKEN` and exits non-zero. Tier 1 is therefore inspectable in one
shell invocation without trust in this document.

## Tier 1 — Proven by tests

Statements in this tier are mechanically verified on every CI run by
`raco test tests/examples-test.rkt` and the `make verify` summary
target. Failure of any one of them is an immediate falsification
trigger F0 of the v9.0 preprint.

1. **The substrate exists as a 40-primitive language.** The Sixth
   engine compiles, the 40 primitives are exposed by
   `sixth/primitives/*.rkt`, the module loader resolves the stdlib,
   and a `#lang sixth` reader is registered.

2. **All 98 demonstrations pass deterministically.** `examples-test.rkt`
   asserts cumulative `pass=1469 fail=0` across 98 demos organised
   in six conceptual phases: the canonical Spencer-Brown ladder
   (01–11, eleven atomic rungs from void to first-Φ_PA), substrate
   applications (12–31, Peano / time / conservation / CA / Conway /
   morphism / Rovelli observers / Hofstadter self-model), Pilots
   A–F (32–47: autopoiesis / observer-driven evolution / cosmogenesis
   / Φ_PA measurement / encoding maps for transformer / brain /
   split-brain / colony), Pilots G–K (48–52: composite distinction
   via meta-self-loop, mutation + substrate-readable selection
   producing three distinct "particle species", multi-level
   hierarchy, Σ NGET Noether-style conservation under STEP-CA,
   spontaneous coalition assembly re-building the hierarchy from
   one substrate-readable rule), long-epoch parametric pilots
   (53–54), the full visual-trace track (55–74) which provides
   a DOT-snapshot companion for every numerical pilot — including
   the PA-ontological shell decomposition (65) that unfolds the
   first shell of Pilot D (demo 42) into the eleven Spencer-Brown
   events realised individually by canonical-ladder rungs 1–11 —
   Pilot L (75–76) which demonstrates substrate-native particle
   interaction: two structurally distinct observers bind via a BIND
   rule, forming a composite bound state with its own Φ_PA while
   the flavour charges of constituents are individually conserved,
   Pilot M (77–78) which exhibits the inverse process (decay when
   M's self-loop is severed, particles return to free state with
   charge conservation preserved), and the stress-test track
   (79–81) which re-runs the dynamic invariants at parametric
   depth (default 1000 cycles in CI; `-D max-cycles=N` scales to
   10⁴/10⁵/10⁶) and asserts max-drift = 0 at every step: charge
   conservation on a closed ring (79), bind+decay idempotence
   (80), autopoiesis stability (81).  Showcase: `make stress-test
   STRESS_CYCLES=1000000` confirms all three invariants hold
   exactly across one million iterations each.

3. **The Φ_PA stdlib word reproduces Definition def:phi-pa.** Demo 43
   asserts `phi-pa` on three canonical observers (non-reflexive
   scope-5, reflexive scope-5, demo-42-shape scope-13) and the values
   match the preprint's worked arithmetic: 0 / 50000 / 130000.

4. **Pilot D (demo 42) bootstraps a 13-node 49-edge substrate from
   one MARK** under a substrate-internally-driven halting predicate
   (no host counter).

5. **Pilot E (demo 43) computes Φ_PA from within the substrate** via
   `OUT`, `EDGE?`, `phi-L-max` alone — substrate-readability of the
   measure is exhibited, not asserted.

6. **Φ_integ discriminates intact from split-brain on the toy
   substrate** (demo 46): basic Φ_PA returns 50000 in both states
   (matched scope, indifferent), Φ_integ returns 400000 intact vs
   200000 split (halves at callosotomy). PSH4's subadditivity is
   shown to require the alternative-measures programme.

These are properties of the released code. They do not depend on any
metaphysical position.

## Tier 2 — Demonstrated by examples

Statements in this tier are exhibited on synthetic or toy substrates
inside the released artifact. They show that an encoding pipeline
composes structurally and yields the predicted direction, but they
do not yet engage with real Pythia weights, real EEG corpora, or
real ant colonies. They are not yet falsified or corroborated against
nature.

1. **Transformer encoding map (Pilot F.1, demo 44).** On a 4×3 toy
   feedforward attention substrate, the unembedding-near observer has
   Φ_PA = 0 in single-pass mode (PSH1 direction) and Φ_PA = 40000
   when a cross-step back-edge is added (PSH2 direction). The encoding
   pipeline of §sec:encoding-transformer composes; whether it
   discriminates real Pythia from real Mamba is companion-preprint #1.

2. **Brain encoding map (Pilot F.2, demo 45).** On an 8-area DMN-hub
   substrate, the DMN observer has Φ_PA = 80000 in the
   thalamocortical-loop state and Φ_PA = 0 in the propofol-decoupled
   state (PSH3 direction). The encoding pipeline of
   §sec:encoding-brain composes; whether it tracks Casali PCI on
   real EEG is companion-preprint #2.

3. **Split-brain encoding (Pilot F.3, demo 46).** Φ_integ on a 5-node
   intact-vs-callosotomised brain halves at callosotomy with matched
   scope (PSH4 direction). The encoding-plus-alternative-measure
   composes; real split-brain EEG is companion-preprint #2.

4. **Ant colony encoding (Pilot F.4, demo 47).** On a 6-chamber
   queen-centric colony substrate, the queen observer has Φ_PA =
   60000 with the pheromone self-loop and Φ_PA = 0 without (PSH5
   direction). The encoding pipeline of §sec:encoding-colony
   composes; real colony cartography is myrmecology-collaboration
   future work.

5. **The Sixth-language ascent from one mark to a self-measuring
   cosmos** (demos 01 → 43). Construction-by-construction, not
   theorem.

Tier 2 buys: the substrate-encoding maps are not vapor — the released
code instantiates each one structurally. Tier 2 does NOT buy:
empirical corroboration on real systems.

## Tier 3 — Philosophical / research hypotheses

Statements in this tier are not theorems and not yet empirically
adjudicated. They are working hypotheses that the substrate makes
formally falsifiable. The v9.0 preprint introduces each one with
explicit "working hypothesis" language.

1. **Substrate-monist identity thesis.** Phenomenal consciousness IS
   the substrate-state of a node with Φ_PA > 0 (preprint
   §sec:hard-problem-position). Identity is the *content* of the
   hypothesis; conjecture is the *epistemic status*. Falsified if
   F5 fires (no substrate-encoding map yields the predicted
   direction on P1–P5 after companion-preprint work).

2. **Φ_PA is the right substrate-readable consciousness measure.**
   Adopted as a *working candidate*. The stdlib ships three measures
   (`phi-pa`, `phi-integ`, `phi-bidir`); the empirical question of
   which discriminates P1–P5 best is open. Pilot F.3 already
   exhibits that `phi-pa` is insufficient for PSH4. F5 does not
   depend on a unique choice of measure.

3. **The substrate IS the universe at the right scale.** The v9.0
   preprint's quantum-gravity / holographic-dark-energy mapping
   (§sec:substrate-cone, §sec:cosmological-arealaw) proposes that
   the PA substrate is the discrete substructure realising the
   algebraic-observer programme of Witten 2022 et al. This is a
   structural correspondence, not a derivation; promotion to formal
   isomorphism is forward trigger F2.

4. **Consciousness is operationally definable at all.** The
   substrate's contribution to the hard problem is the conjecture
   that the structural skeleton of phenomenal experience is
   substrate-readable (Φ_PA or any of its candidate alternatives).
   The phenomenal-content question — why this particular experience
   corresponds to this particular configuration — is not addressed
   and may remain a mysterian residue.

Tier 3 is honest about being conjecture. The substrate is operational
whether or not Tier 3 turns out to be empirically adequate.

## Tier separation contract

A Sixth README, manual, or preprint sentence belongs to exactly one
tier. When in doubt:

- If `raco test` would fail if the statement were false → Tier 1.
- If a demo runs successfully and verifies the statement on synthetic
  data → Tier 2.
- If we are proposing an interpretation of what the verified substrate
  *means* → Tier 3.

A Tier-3 sentence does not pretend to be Tier-1. A Tier-2 sentence
does not pretend to engage with real data. A Tier-1 sentence does not
need defensive hedging because the test runs.

The substrate stands on Tier 1. Tiers 2 and 3 build on it but their
empirical adequacy is independently falsifiable. Failure of any
Tier-3 conjecture does not invalidate Tier 1; failure of Tier 1
collapses Tier 2 and Tier 3 with it.
