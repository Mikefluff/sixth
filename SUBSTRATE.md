# Sixth Substrate — Foundational Pointer Architecture

This document accompanies the Sixth substrate implementation in
`sixth/primitives/substrate.rkt` and the 74 emergence demonstrations
under `examples/`. The goal is *not* to derive physics — it is to
build the minimum formal artifact in which structures such as
numbers, time, space, conservation laws, particles, self-reference,
observers, autopoiesis, and universal computation are demonstrably
*derived from*, rather than *postulated alongside*, the substrate.

The substrate has only three ontological primitives:

```
1.  DIFFERENCE      — at least two distinct tokens exist
2.  POINTER         — a token may be related to another token
3.  REWRITE         — the set of pointers can be transformed by a rule
```

Everything else — counting, ordering, space, motion, observation,
self-knowing, universal computation, autopoiesis, cosmogenesis —
emerges from how those three compose.


## Mapping to Pointer Architecture v9.0 primitives

PA v9.0 (Savchenko 2026) declares five primitive components of any
substrate-of-cognition `𝒮 = (G, R, C, A, π)`:

| PA primitive          | Substrate realization                                        |
|-----------------------|--------------------------------------------------------------|
| **G** (graph)         | Hypergraph of `MARK`ed nodes plus `EDGE+` adjacency          |
| **R** (rewriting)     | `STEP`, `EACH`, `EACH-EDGE`, `EACH-2PATH`, `STEP-CA`         |
| **C** (commit)        | Snapshot-then-commit semantics of `STEP-CA` and `EACH-*`     |
| **A** (archive)       | `BORN(n)` records the step a node was created                |
| **π** (observer)      | A node whose `EDGE+` set is its view of the substrate        |

The complete substrate engine — 23 primitives on top of base Sixth —
is listed in [`LANGUAGE.md`](./LANGUAGE.md) and
`docs/substrate.scrbl`. Every primitive operates on the bare
difference + pointer level: a token (`MARK`ed), a relation between
two tokens (`EDGE+`), or a transformation of those relations
(`STEP` / `EACH` / `STEP-CA`).


## What the demos demonstrate

The 74 demonstrations live in `examples/` (file-by-file index in
[`examples/README.md`](./examples/README.md)). Each isolates a
single derivation chain, organised in six conceptual phases that
go from simplest distinction to highest-order composition:

- **01–11 Canonical Spencer-Brown ladder.** Eleven atomic demos,
  each adding one rung to the substrate's self-construction:
  void → first-distinction → second-distinction → first-pointer →
  self-pointer → mutual-pointing → observer-state → I/not-I →
  recognition → closure-of-not-I → measurement (first non-trivial
  Φ_PA). Reading this phase IS reading what the substrate IS.
- **12–31 Applications.** Reusable patterns built on the ladder:
  Peano arithmetic (12), substrate-time via sprout rules (13),
  fixed-point stability (14), rule conflict (15), strange-loop
  topology (16), Rovelli-relational observers (17), Turing-
  completeness via rewrite (18), 1D BFS (19), Rule 90 CA (20),
  Hofstadter self-model (21), substrate energy (22), Wolfram
  generic rules (23), ring-Noether conservation (24), 2D grid
  (25), Rule 184 1D glider (26), Rule 110 universal CA (27),
  relational consensus (28), morphism (29), Conway blinker (30),
  Conway glider (31).
- **32–36 Pilot A — substrate-native autopoiesis** (Maturana–Varela
  on the discrete substrate).
- **37–40 Pilot B — observer-driven conscious evolution** (Lamarck-
  style, NOT blind Darwin).
- **41–42 Pilots C and D — cosmogenesis.** C bootstraps a 13-node
  48-edge cosmos from one MARK and survives harsh decay; D adds the
  substrate-monist halting predicate (no host counter).
- **43 Pilot E — substrate-internal Φ_PA measurement.**
- **44–47 Pilot F — encoding-map pilots** (PSH1–PSH5 toys for
  transformer / brain / split-brain / ant colony).
- **48–52 Pilots G–K — composite distinction and its extensions.**
  G: composite held by meta-self-loop. H: mutation + substrate-
  readable selection produces three distinct surviving species.
  I: three-level hierarchy (instances → families → genus) by
  iterated composite-distinction. J: Σ NGET Noether-style
  conservation under STEP-CA `charge-shift`. K: spontaneous
  coalition assembly — same hierarchy as I rebuilt from scratch by
  one substrate-readable `try-spawn-coalition` rule.
- **53–54 Long-epoch parametric pilots.** TCO-safe runs of arbitrary
  cycle count; demo 53 shows after-decay/after-restore sub-cycle
  snapshots for visible autopoiesis dynamics; demo 54 grows the
  substrate every K cycles.
- **55–74 Visual-trace track.** Every numerical pilot's DOT-snapshot
  companion, consolidated at the end of the catalogue: substrate-
  monism traces of Pilots C/D/F.3 (55–57), foundation visual traces
  for Conway/Wolfram CAs (58–62), atomic-build traces (63–64) where
  every MARK/EDGE+ becomes its own frame, PA-ontological shell
  decomposition (65) that unfolds the first shell of Pilot D into
  the 11 events of the canonical ladder, Pilot E visual trace (66),
  Pilot F.1/F.2/F.4 visual traces (67–69), composite distinction
  trace (70), mutation-selection trace (71), particle-families
  trace (72), charge-conservation trace (73), spontaneous-assembly
  trace (74).

All 1016 assertions pass deterministically. Run the regression in
one command:

```bash
make verify
# language tests:    ok
# substrate tests:   ok
# examples:          1016 / 1016 ✓ across 74 demos
# docs build:        ok
# artifact status:   reproducible
```


## Catalog of substrate primitives

### Layer 0 — base Sixth (15)

Stack operations: `dup` `drop` `swap` `over`.
Arithmetic: `+` `-` `*` `/` `mod`.
Comparison: `=` `<` `>`.
Memory: `store` `load`.
I/O: `.` `cr` `emit`.
Definition: `:`/`;`.

### Layer 1 — substrate (23)

```
Difference:        MARK
Pointer:           EDGE+   EDGE-   EDGE?
Traversal:         OUT     IN      NEXT     PREV
Counts:            NODES   EDGES
Time:              STEP    NOW     BORN
Iteration:         EACH    EACH-EDGE   EACH-2PATH   STEP-CA
Features:          NSET    NGET    NSUM
Syntactic:         '       (tick — push next token literal)
Test/admin:        ASSERT  RESET   REPORT
```

That is 38 operations total. Every demo uses only these; stdlib
helpers (`bi-edge`, `clique`, `grid-2d`, `rule110`, `phi-pa`, …)
are composed from the 38 in Sixth itself, under `stdlib/`.


## Related work

This is research-program territory; the demos are deliberately
minimal, the formal lineage is rich.

### Foundational

- **G. Spencer-Brown, _Laws of Form_ (1969)** — single primitive
  (the mark of distinction), develops calculus of distinctions,
  paradox of self-reference. Closest formal predecessor of "start
  from difference". Realised explicitly in demos 00 and 48.

- **F. Varela & H. Maturana, _Autopoiesis_ (1972)** — self-producing
  systems via distinction. Observer included. Operationalised in
  Pilot A (demos 21–25).

- **G. Bateson, _Steps to an Ecology of Mind_ (1972)** — "the
  difference that makes a difference" as definition of information.

- **C. S. Peirce, semiotic triad** — sign / object / interpretant;
  firstness / secondness / thirdness.

- **A. N. Whitehead, _Process and Reality_ (1929)** — events as
  primary, objects as patterns of events.

### Discrete-substrate physics

- **J. A. Wheeler, _It from Bit_ (1990)** — matter from information
  distinction; participatory universe.

- **S. Wolfram, _A New Kind of Science_ (2002) and the Wolfram
  Physics Project (2020–)** — hypergraph rewriting from minimal
  rules. Demos 09, 12, 13, 15, 16, 19, 20, 42–46 are direct
  instantiations.

- **L. Smolin, _The Trouble with Physics_; "relational physics"** —
  no absolute frame; all properties are relations between observers.

- **D. Deutsch & C. Marletto, _Constructor Theory_** — what
  transformations are possible vs impossible.

### Self-reference / consciousness

- **K. Gödel, incompleteness via self-reference (1931)**.

- **D. Hofstadter, _Gödel, Escher, Bach_ (1979); _I Am a Strange
  Loop_ (2007)** — recursive self-modeling. Demo 10 is the
  substrate-level realization of his "strange loop" structure.

- **C. Rovelli, _Relational Quantum Mechanics_ (1996)** — observer-
  dependent facts. Demos 06, 17 instantiate this for substrate.

- **F. Varela & H. von Foerster, _second-order cybernetics_** —
  observer included in observed system.

### ML / contemporary

- **V. Vanchurin, _The world as a neural network_ (2020); _Geometric
  Learning Dynamics_ (2025, arXiv:2544.14728)** — physics-as-learning-
  dynamics. Sixth provides a discrete counterpart on which similar
  emergence arguments can be tested directly.

- **E. Witten, _Algebraic Observer Programme_ (2022)** — observer-
  relative subalgebras of operators. Demos 06, 17 are the substrate
  version (subgraph as observer subalgebra). The v9.0 preprint's
  `sec:substrate-cone` proposes that the Sixth substrate is the
  discrete substructure realising the algebraic-observer programme.

- **M. Savchenko, _Pointer Architecture v9.0_ (2026)** — the
  preprint for which Sixth is the reference implementation. Sixth
  proves the language layer (Tier 1 of [`CLAIMS.md`](./CLAIMS.md));
  the v9.0 preprint takes Tiers 2 and 3 on top.


## Open directions

Several directions remain after the v9.0 cut. The substrate is
sufficient for the released demos and can be extended further.

**Engine extensions:**
- declarative pattern matching with multi-edge LHS and named
  variables (Wolfram-style rewrite rules with binding);
- explicit conflict resolution as first-class primitives (priority,
  random, energy-min);
- typed/labelled edges for richer hypergraph patterns;
- compiled hot path for large-scale CA runs;
- parallel rule application via Racket places or futures.

**More emergence proofs:**
- propagating gliders in Conway 2D Life (needs ≥7×7 grid);
- substrate-level analog of Noether's theorem with rigorous proof;
- emergent entropy and second law from substrate dynamics;
- multi-substrate morphism composition (full category).

**Bridges to applied PA (Phase H — partially shipped):**
- `sixth/bridges/torch/` ships shadow / diff / nn — Substrate ⇄
  Tensor view, autograd over substrate features, and the
  Substrate-NN continual-learning architecture, all via native
  Racket FFI to libtorch (no Python in the path);
- still pending: direct comparison of NN-substrate runs to Sixth-
  substrate runs on identical tasks; using substrate-validated
  rules as inductive biases for neural architectures.

**Companion preprints (v9.0 future work):**
- real Mamba Φ_PA computation for PSH2 corroboration (companion
  preprint #1);
- real EEG analysis on Casali PCI for PSH3/PSH4 corroboration
  (companion preprint #2);
- ant-colony cartography collaboration with myrmecologists for PSH5.

**Formalisation:**
- categorical (functorial) account of `EACH-*` operators;
- formal Turing-completeness proof via the released Rule 110 demos
  (16 + 44);
- formal connection of substrate primitives to Spencer-Brown's
  algebra.


## Running the artefact

```bash
cd /Users/mikefluff/Documents/Programming/sixt
raco pkg install --link .          # install the Sixth Racket collection

# the whole regression — all 74 demos, all 1016 assertions
make verify

# any single demo
racket -l sixth/cli -- run examples/00-first-distinction.6th

# REPL
racket -l sixth/cli -- repl
```

The legacy chibi-Scheme prototype is preserved unmodified under
`legacy/` for historical reference; the production implementation
is Racket-hosted (Phase A–I of the refactor plan complete; see
[`README.md`](./README.md) and [`docs/migration.scrbl`](./docs/migration.scrbl)).

This artefact is reproducible, minimal, and self-contained. It is
the foundational layer beneath the Pointer Architecture v9.0
preprint: the substrate from which an NN-shadow implementation
should be derived, rather than the other way around.
