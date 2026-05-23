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

1. **The substrate exists as an 82-primitive language.** The Sixth
   engine compiles, the 82 primitives are exposed across
   `sixth/primitives/*.rkt` and `sixth/meta/*.rkt`:
   - **49 object-level** (mutate world-state): 17 base + 24
     substrate-core + 8 HEDGE3 trivalent.  `HASH-WORLD` added in
     cycle 25B as a deterministic substrate digest.
   - **33 meta-level** (mutate law-state per META-SEMANTICS.md v2.1):
     25 Tier 1 (ephemeral lifecycle + hardening + energy
     accounting + cycle-26 testing) + 8 Tier 2 stable-promotion
     stubs (gate-closed until cycle 27+ wires held-out infra).

   The module loader resolves the stdlib and `substrates/` paths,
   and a `#lang sixth` reader is registered.  Counted via
   `grep -E "^\s*\(cons '" sixth/primitives/*.rkt sixth/meta/*.rkt`.

2. **All 142 demonstrations pass deterministically.** `examples-test.rkt`
   asserts cumulative `pass=2070 fail=0` across 142 demos organised
   in conceptual tracks (additions since v9.0 baseline):
   - **Spencer-Brown / pilots / HEDGE3 / honest-emergence
     (01–104)** — unchanged from v9.0 baseline.
   - **Substrate-physics / cosmology / Φ measures (105–130)** —
     additions through cycle 12.
   - **Loss-family arc (131–142)** — closed CCCCC at cycle 23A
     (commit `36fb9ee`).  Four substrate-derived negatives:
     HEDGE3 (12C), pure MDL groups (21), MDL+prediction (22),
     predictive-only (23A).
   - **Meta-semantics arc (143–148)** — cycles 25-26.  Demos
     143 (Tier 1 mechanics), 144 (substrate signatures), 145
     (15-item hardening), 146 (energy accounting v0), 147
     (happy-path runtime promotion with energy gate), 148
     (negative path: energy gate rejects length-1 motif).
   - **Canonical Spencer-Brown ladder (01–11)** — eleven atomic
     rungs from void to first-Φ_PA.
   - **Substrate applications (12–31)** — Peano / time / conservation
     / CA / Conway / morphism / Rovelli observers / Hofstadter
     self-model.
   - **Pilots A–F (32–47)** — autopoiesis / observer-driven
     evolution / cosmogenesis / Φ_PA measurement / encoding maps
     for transformer / brain / split-brain / colony.
   - **Pilots G–K (48–52)** — composite distinction via meta-self-
     loop, mutation + substrate-readable selection producing three
     distinct "particle species", multi-level hierarchy, Σ NGET
     Noether-style conservation under STEP-CA, spontaneous
     coalition assembly.
   - **Long-epoch parametric (53–54)**.
   - **Visual-trace track (55–74)** — DOT-snapshot companion for
     every numerical pilot, including the PA-ontological shell
     decomposition (65) that unfolds the first shell of Pilot D
     (demo 42) into the eleven Spencer-Brown events realised by
     canonical-ladder rungs 1–11.
   - **Pilots L–M (75–78)** — particle interaction (bound-state
     formation) and its inverse (decay when M's self-loop is
     severed); flavour charges conserved on both paths.
   - **Stress-test track (79–84)** — parametric long-run invariants
     (default 1000 cycles in CI; `-D max-cycles=N` scales to
     10⁴/10⁵/10⁶); asserts max-drift = 0 at every step for charge
     conservation (79), bind+decay idempotence (80), autopoiesis
     stability (81), Conway blinker periodicity (82), sprout linear
     growth (83), Rule 184 ring conservation (84).  Showcase:
     `make stress-test STRESS_CYCLES=1000000` confirms all six
     invariants hold exactly across one million iterations each.
   - **Honest-emergence track (85–89, 91–92)** — substrate-walked
     scanner rules SPAWN composites in response to substrate state
     rather than the demo hand-placing the answer (corrective to
     Pilots G/H/I/L/M/K which hand-place).
   - **Peircean trit observer (90)** — substrate-readable classifier
     tagging every node into balanced trit {−1, 0, +1}; firstness /
     secondness / thirdness anchored on Peirce's reduction thesis
     (Burch 1991; Hereth Correia & Pöschel 2006).
   - **HEDGE3 typed trivalent (93–94, 98, 100, 103–104)** — typed
     trivalent hyperedge surface with strict structural typing
     enforced at insertion.  Substantive applications: simplicial
     complex with Euler χ = V−E+F (98); MEDIATOR causal hypergraph
     with forward/backward reachability cones (100); strict-typing
     integration check via `HEDGE3-VALID?` predicate (103);
     substrate-derived causal time as fixpoint over MEDIATOR DAG
     (104).  Gaps 95–97, 99, 101–102 are intentional cuts of
     fake-deep hash-table demos (see CHANGELOG for rationale).

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

### Tier 1 additions from meta-semantics arc (cycles 24-26)

7. **Sixth supports runtime law-state mutation.** During a single
   execution session the active dictionary can change, with the
   mutation observable via `LAW-HASH` and recorded in the meta-
   ledger.  Verified by `examples/143-runtime-promotion.6th`
   (7 asserts): a motif `MARK MARK bi-edge` is detected via
   `DETECT-MOTIF`, induced via `INDUCE-RUNTIME` after a passing
   `SHADOW-CHECK`, and rolled back via `ROLLBACK-RUNTIME` — the
   `law_hash` trajectory `h0 → h1 → h0` is asserted.

8. **The law mutation passes 15 hardening invariants.** Verified by
   `examples/145-hardening-suite.6th` (22 asserts).  Includes:
   canonical `law_hash` (sensitive to word bodies, not just keys);
   `world_hash` / `law_hash` separation (mutation of one does not
   affect the other); SHADOW-CHECK rejects forbidden meta-primitives
   in motifs; INDUCE-RUNTIME requires a valid shadow certificate
   (defence-in-depth); ROLLBACK transactionally clears certificate
   AND counters; substrate generators deterministic on re-run; no
   hidden entropy in `law_hash`.

9. **Energy accounting is observational, not gating in cycle 25E.**
   `_energy-*` keys do not enter `law_hash` or `world_hash`
   (Heisenberg-trap defence per META-SEMANTICS.md v2.1 §17).
   Verified by `examples/146-energy-accounting.6th` (10 asserts):
   8 inspection primitives (`E-WORLD`, `E-LAW`, `E-TRACE`,
   `E-CONFLICT`, `E-SEARCH`, `E-REUSE-GAIN`, `E-TOTAL`,
   `E-SNAPSHOT`) report runtime cost without affecting the
   measured state.

10. **`COMMIT-PRIMITIVE` enforces coupling + energy gate.** Cycle 26
    activates three gates simultaneously:
    - N=5 uses (counted by VM dispatch hook on every `cand_*` call)
    - M=3 distinct sessions (tracked per-candidate via session-id set)
    - `net_delta_e < 0` (energy v0: `law_cost - reuse_gain`)

    Verified by `examples/147-runtime-promotion-happy.6th`
    (12 asserts): the motif `MARK MARK bi-edge` (L=3) passes
    after 5 uses across 3 sessions (`net_delta_e = -7`).

11. **The energy gate actually rejects, not decorates.** Verified by
    `examples/148-runtime-promotion-energy-fail.6th` (7 asserts).
    A length-1 motif (single `MARK` constructed via `WRAP-MOTIF`)
    satisfies coupling (N=5, M=3) but has `reuse_gain = 0` because
    expansion saves no ops.  `TRY-COMMIT` returns
    `'rejected-energy`; status stays `'ephemeral-active`.

12. **Substrate generation is Sixth-native.** 12 frozen substrates
    (6 train + 6 held-out, from `substrates/manifest.6th`) are
    generated by Sixth-language words in
    `stdlib/substrate-gen.6th` using `stdlib/rand.6th`'s LCG; no
    Python in core path.  Each substrate's `HASH-WORLD` signature
    is pinned; verified by `examples/144-substrate-signatures.6th`
    (16 asserts: 12 signatures + 4 Tier 2 stub probes).

The catalogue formulation now machine-enforced:

> primitive ≠ named macro.
>
> primitive = runtime-induced law candidate that survived
> equivalence (SHADOW-CHECK), reuse (N=5 uses), multi-session
> coupling (M=3), and negative energy delta (`net_delta_e < 0`).

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
