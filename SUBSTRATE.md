# Sixth Substrate — Foundational Pointer Architecture

## Покажется так, как и должно

This document accompanies the Sixth substrate implementation in
`sixth-substrate.scm` and the 19 emergence demonstrations
`demo-*.6th`. The goal is *not* to derive physics — it is to build
the minimum formal artifact in which structures such as numbers, time,
space, conservation laws, particles, self-reference, observers, and
universal computation are demonstrably *derived from*, rather than
*postulated alongside*, the substrate.

The substrate has only three ontological primitives:

```
1.  DIFFERENCE      — at least two distinct tokens exist
2.  POINTER         — a token may be related to another token
3.  REWRITE         — the set of pointers can be transformed by a rule
```

Everything else — counting, ordering, space, motion, observation,
self-knowing — emerges from how those three are composed.


## Mapping to Pointer Architecture v8.0 primitives

PA v8.0 (Savchenko) declares five primitive components of any
substrate-of-cognition:

| PA primitive          | Substrate realization                                       |
|-----------------------|-------------------------------------------------------------|
| **G** (graph)         | Hypergraph of `MARK`ed nodes plus `EDGE+` adjacency        |
| **R** (rewriting)     | `STEP`, `EACH`, `EACH-EDGE`, `EACH-2PATH`, `STEP-CA`        |
| **C** (commit)        | Snapshot-then-commit semantics of `STEP-CA` and `EACH-*`    |
| **A** (archive)       | `BORN(n)` records the step a node was created                |
| **π** (observer)      | A node whose `EDGE+` set is its view of the substrate      |

The complete substrate engine — 23 primitives on top of base Sixth — is
listed in the README.  Every primitive operates on the bare difference
+ pointer level: a token (MARKed), a relation between two tokens
(EDGE+), or a transformation of those relations (STEP / EACH /
STEP-CA).


## What the demos demonstrate

The 19 demonstrations (`demo-*.6th`, runnable individually or together
via `demo-all.6th`) each isolate a single derivation chain:

| # | Demo                | Derived structure                                  |
|---|---------------------|----------------------------------------------------|
| 1 | numbers             | Peano arithmetic from MARK + EDGE+ + IN + PREV     |
| 2 | time                | Causal ordering as STEP-index of rewrites         |
| 3 | stable              | Fixed points of local rewrite rules               |
| 4 | conflict            | Rule-order = physics-choice (different futures)   |
| 5 | loop                | Self-reference as cyclic pointer topology         |
| 6 | observers           | Observer-relative facts on partial views          |
| 7 | rewrite             | Transitive closure from {{x,y},{y,z}}⇒{x,z}        |
| 8 | distance            | 1D BFS metric from edge-relaxation                |
| 9 | ca (Rule 90)        | Sierpinski fractal from XOR neighbour rule        |
|10 | self-model          | Substrate contains its own description (Quine)    |
|11 | energy              | Edge-Δ monotone → 0 (thermodynamic equilibrium)   |
|12 | wolfram             | Classical Wolfram hypergraph rule on substrate     |
|13 | conservation        | Ring + shift rule → invariant cell-sum (mass)     |
|14 | grid                | 2D Manhattan metric from grid topology            |
|15 | glider              | Rule 184 single-car propagating particle          |
|16 | rule110             | Turing-complete dynamics from minimal substrate   |
|17 | consensus           | Intersubjective truth = view intersection          |
|18 | morphism            | Structure-preserving subgraph map (category)       |
|19 | conway              | Game-of-Life blinker on 5×5 Moore-grid (2D CA)    |

All 320 assertions across these 19 demos pass.

```
$ echo 'loadfile demo-all.6th
quit' | chibi-scheme sixth-substrate.scm | tail -1
REPORT  nodes=25  edges=144  steps=0  pass=320  fail=0
```


## Catalog of substrate primitives

### Layer 0 — base Sixth (15)

Stack operations: `dup` `drop` `swap` `over`.
Arithmetic: `+` `-` `*` `/` `mod`.
Comparison: `=` `<` `>`.
Memory: `store` `load`.
Control: `if`/`else`/`then`, `:`/`;`, `eval`, `loadfile`.

### Layer 1 — substrate (23, added in this work)

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

That is 38 operations total. Every demo above uses only these.


## Related work

This is research-program territory; the demos are deliberately minimal,
the formal lineage is rich.

### Foundational

- **G. Spencer-Brown, _Laws of Form_ (1969)** — single primitive (the
  mark of distinction), develops calculus of distinctions, paradox of
  self-reference. Closest formal predecessor of "start from
  difference".

- **F. Varela & H. Maturana, _Autopoiesis_ (1972)** — self-producing
  systems via distinction. Observer included.

- **G. Bateson, _Steps to an Ecology of Mind_ (1972)** — "the
  difference that makes a difference" as definition of information.

- **C. S. Peirce, semiotic triad** — sign / object / interpretant;
  firstness / secondness / thirdness.

- **A. N. Whitehead, _Process and Reality_ (1929)** — events as
  primary, objects as patterns of events.

### Discrete-substrate physics

- **J. A. Wheeler, _It from Bit_ (1990)** — matter from information
  distinction; participatory universe.

- **S. Wolfram, _A New Kind of Science_ (2002) and the Wolfram Physics
  Project (2020–)** — hypergraph rewriting from minimal rules.
  Demos 7, 12, 13, 15, 19 are direct instantiations of this style.

- **L. Smolin, _The Trouble with Physics_; "relational physics"** —
  no absolute frame; all properties are relations between observers.

- **D. Deutsch & C. Marletto, _Constructor Theory_** — what
  transformations are possible vs impossible.

### Self-reference / consciousness

- **K. Gödel, incompleteness via self-reference (1931)**.

- **D. Hofstadter, _Gödel, Escher, Bach_ (1979); _I Am a Strange Loop_
  (2007)** — recursive self-modeling. Demo 10 is the substrate-level
  realization of his "strange loop" structure.

- **C. Rovelli, _Relational Quantum Mechanics_ (1996)** — observer-
  dependent facts. Demos 6, 17 instantiate this for substrate.

- **F. Varela & H. von Foerster, _second-order cybernetics_** —
  observer included in observed system.

### ML / contemporary

- **V. Vanchurin, _The world as a neural network_ (2020); _Geometric
  Learning Dynamics_ (2025, arXiv:2504.14728)** — physics-as-learning-
  dynamics. Our substrate provides a discrete counterpart on which
  similar emergence arguments can be tested directly.

- **W. Witten, _Algebraic Observer Programme_ (2022)** —
  observer-relative subalgebras of operators. Demo 6, 17 are the
  substrate version (subgraph as observer subalgebra).

- **M. Savchenko, _Pointer Architecture v8.0_ (2026)** —
  the present PhD substrate. This artifact is its foundational layer.


## Open directions

The substrate is sufficient for the demos above and can be
straightforwardly extended in several directions.

**Engine extensions (1-2 days each):**
- declarative pattern matching with multi-edge LHS and named variables;
- explicit conflict resolution as first-class primitives (priority,
  random, energy-min);
- typed/labelled edges for richer hypergraph patterns;
- compiled hot path for large-scale CA runs.

**More emergence proofs:**
- propagating gliders in Conway 2D Life (needs ≥7×7 grid);
- Rule 110 universal-computation embedding;
- substrate-level analog of Noether's theorem;
- emergent entropy and second law;
- multi-substrate morphism composition (full category).

**Bridge to applied PA:**
- substrate primitives realized as PyTorch vectorized operations
  ("NN-shadow");
- direct comparison of NN-substrate runs to Sixth-substrate runs on
  identical tasks;
- using substrate-validated rules as inductive biases for neural
  architectures.

**Formalisation:**
- categorical (functorial) account of `EACH-*` operators;
- proof of substrate Turing-completeness via Rule 110 embedding;
- formal connection of substrate primitives to Spencer-Brown's
  algebra.


## Running the artefact

```
cd /Users/mikefluff/Documents/Programming/sixt
echo 'loadfile demo-all.6th
quit' | chibi-scheme sixth-substrate.scm
```

Individual demos run the same way with `demo-<name>.6th` substituted.

This artefact is reproducible, minimal, and self-contained. It is the
foundational layer beneath the Pointer Architecture v8.0 PhD: the
substrate from which a NN-shadow implementation should be derived,
rather than the other way around.
