# Sixth — foundational substrate language

> 15 base primitives + 23 substrate primitives.
> From `MARK` and `EDGE+` rise numbers, time, space, conservation laws,
> particles, observers, and universal computation.

Sixth is a small Forth-like stack language hosted on Racket, with an
attached hypergraph-rewriting substrate.  The language is the engine
through which a Pointer-Architecture substrate is built up from the
single primitive of *difference* (`MARK` — create a fresh distinguishable
token) plus the primitive of *pointer* (`EDGE+` — relate one token to
another) plus the primitive of *rewrite* (`EACH` family + `STEP-CA` —
apply a rule to the substrate).

20 emergence demonstrations (`examples/`) cover Peano arithmetic, causal
time, fixed-point stability, rule-order resolution, self-reference,
relational facts, transitive closure, 1D and 2D distance, Rule 90 / 110
cellular automata, Wolfram hypergraph rewriting, conservation laws,
Conway's Game of Life with both blinker and glider, intersubjective
consensus, and category-style substrate morphism.

A native Racket-FFI bridge to libtorch (`sixth/bridges/torch/`) lifts
the same substrate into autograd, enabling differentiable substrate
operations and a Substrate-NN architecture for continual learning.

## Quickstart

```bash
raco pkg install --link .
raco test sixth
racket -l sixth/cli -- examples/all.6th
```

REPL:

```bash
racket -l sixth/repl
```

`#lang sixth` files:

```racket
#lang sixth
3 4 + .   \ prints 7
```

## Status

Refactor in progress (Phase A of I).  Original chibi-Scheme prototype
is preserved unmodified in `legacy/` as a parity oracle.

See [`SUBSTRATE.md`](./SUBSTRATE.md) for the foundational PA mapping
and literature references.
