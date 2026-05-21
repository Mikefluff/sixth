# Sixth — the language, on its own terms

External-reviewer feedback (2026-05-20):
> Separate "language spec" from "cosmology claims".
> The language must survive criticism even if someone does not
> accept the metaphysics.

This document is Sixth without the cosmology. Read it if you want to
know what Sixth IS as a programming language, independent of any
v9.0 preprint claim about consciousness, holographic dark energy, or
the substrate-monist identity thesis. The language stands or falls
on its own merits as engineering; the cosmology claims build on top
and are independently falsifiable (see [CLAIMS.md](./CLAIMS.md)).

## What Sixth is

Sixth is a small Forth-like concatenative stack language hosted on
Racket. The execution model is a value-stack VM with 38 primitive
words, a module loader, and a `#lang sixth` reader so a `.rkt` file
beginning with `#lang sixth` runs as a Sixth program via standard
`raco`.

The primitive count is the project's load-bearing engineering
constraint: 17 base primitives + 23 substrate primitives. Everything
else — control flow helpers, Peano arithmetic, graph constructors,
cellular automaton rules, BFS, the substrate-monist observability
measures of `stdlib/phi.6th` — is written *in Sixth itself*,
imported via `use <module>`. The substrate hypergraph layer (`MARK`,
`EDGE+`, `EACH`, `STEP-CA`, etc.) is the second tier of primitives;
the first tier is plain stack/arithmetic/control.

## What Sixth is not

- It is not a claim about consciousness. The `phi-pa` stdlib word
  is a computable scalar with a definition (`OUT(O) · 1[O EDGE? O]
  · L_max`); whether it tracks phenomenal experience is a
  philosophical conjecture, marked Tier 3 in
  [CLAIMS.md](./CLAIMS.md).
- It is not a claim about physics. The v9.0 preprint maps Sixth to
  Pointer Architecture and from there to discrete quantum-gravity
  candidates; that mapping is independently falsifiable (forward
  triggers F1, F2, F3 of the preprint) and does not affect whether
  Sixth compiles and runs.
- It is not a claim about cosmology. The 13-node 49-edge cosmos
  built by demo 31 is a substrate-graph constructed by Sixth code,
  visible in the released artifact, with a regression test gating
  its persistence. The interpretation that "this is what cosmogenesis
  looks like" is a philosophical reading. The construction is
  reproducible regardless of the reading.

If you reject every interpretive claim of the v9.0 preprint, Sixth
still gives you: a Forth-like language with `#lang sixth` integration,
a hypergraph rewriting engine with 23 substrate primitives, 64 demos
of emergence from 17+23 base operations, a Racket-FFI PyTorch bridge,
and a Scribble-rendered manual.

## Stack language quick reference

```
\ Word definitions
: factorial dup 1 > if dup 1 - factorial * else drop 1 then ;

\ Stack operations  (prelude)
dup drop swap over 2dup 2drop nip tuck rot -rot

\ Arithmetic
1 2 +    \ → 3
5 3 -    \ → 2
4 5 *    \ → 20
10 3 mod \ → 1

\ Comparisons (Forth convention: 1 = true, 0 = false)
3 5 <    \ → 1
4 4 =    \ → 1

\ Control flow
if … else … then
\ (tail-call recursion replaces explicit loops; the VM optimises
\ tail calls)

\ Memory (module-scoped key/value)
42 "answer" store
"answer" load .   \ prints "42 "

\ I/O
. cr emit
"hello world" . cr
```

## Module system

```sixth
use prelude        \ 2dup 2drop nip tuck rot -rot 1+ 1- not >= <= ...
use peano          \ Peano arithmetic (zero, succ, peano-add, peano-mul)
use graph          \ bi-edge  (only — clique/chain/tri-edge not shipped)
use bfs            \ eff-dist, bfs-init, bfs-step, relax-edge
use debug          \ assert-eq  (only — dump-stack/trace/words not shipped)
use phi            \ phi-pa, phi-integ, phi-bidir, phi-self-ref, phi-L-max
use dot            \ dot-snapshot, dot-snapshot-state, dot-header, ...
```

Note: this stdlib set is what the released artefact ships.  Some
larger helpers advertised in earlier drafts (`grid`, `ca`, `math`
modules; `clique`, `chain-of`, `tri-edge`, `dump-stack`, `words`,
`trace`) are not yet implemented; demos that need 2-D grids inline
their construction (see demos 14, 19, 20).

Module loader resolves names against `SIXTH_PATH`. A `.6th` file
under the search path is a module; its top-level forms execute on
`use`, populating the importing module's word/memory namespace.

## Substrate primitives (the 23)

```
\ Construction
MARK                  ( -- n )           create fresh node
EDGE+    ( src dst -- )                  add directed edge
EDGE-    ( src dst -- )                  remove directed edge
NSET     ( n v -- )                      set node feature
RESET                                    clear substrate

\ Interrogation
NODES                 ( -- count )
EDGES                 ( -- count )
EDGE?    ( src dst -- 0|1 )
OUT      ( n -- count )
IN       ( n -- count )
NGET     ( n -- v )
NSUM     ( n -- sum-of-neighbour-features )
NEXT     ( n -- next-id )
PREV     ( n -- prev-id )
NOW                   ( -- time )
BORN     ( n -- step )

\ Iteration
EACH         ' rule  ( -- )    iterate rule over every node
EACH-EDGE    ' rule  ( -- )    iterate rule over every edge
EACH-2PATH   ' rule  ( -- )    iterate over length-2 paths

\ Time
STEP                                     advance the substrate clock
STEP-CA      ' rule                      parallel-update CA step

\ Diagnostics
REPORT                                   substrate state summary
```

## `#lang sixth`

```racket
#lang sixth
: square dup * ;
7 square .   \ prints 49
```

Any Racket-aware editor (DrRacket, racket-mode) provides Check
Syntax, error highlighting, and `raco make` compilation for
`#lang sixth` files.

## Visual trace

`stdlib/dot.6th` defines `dot-snapshot` which emits the current
substrate as a GraphViz DOT block on stdout. Multiple snapshots can
be emitted between substrate operations to record the substrate's
evolution. The companion `code/render_trace.py` parses the snapshot
stream and produces a multi-panel matplotlib figure (PNG / SVG /
PDF). See `examples/37-trace-pilot-d.6th` for the Pilot D evolution
rendered as five panels (shell-count 0..4); render with
`make trace-pilot-d`.

## Engineering invariants

- 40 primitives. No promotion of stdlib to primitive without
  documented justification.
- 963 ✓ across 64 demos. The regression gate
  (`tests/examples-test.rkt`) enforces `pass=963 fail=0`. Single-
  command verification: `make verify`. Parametric / long-epoch
  runs via the CLI `-D KEY=VAL` flag (see `examples/40-long-epoch-
  autopoiesis.6th` and `examples/41-long-epoch-growth.6th`).
  Visual instrumentation via `make traces`, `make gifs`,
  `make foundation-gifs`, `make atomic-gifs`.
- `legacy/` holds the original chibi-Scheme prototype as a parity
  oracle. Not maintained; preserved for comparison.
- TCO is mandatory. The VM optimises tail calls; no recursion-depth
  surprises.
- O(1) opcode dispatch. The VM compiles word bodies to flat opcode
  vectors at load time.

## When the language interests you and the cosmology does not

Use Sixth, ignore the v9.0 preprint, contribute lexer / parser /
VM / stdlib improvements. The substrate primitives are documented
in `docs/substrate.scrbl` independently of any consciousness or
quantum-gravity interpretation; the demos in `examples/01` through
`examples/20` are pure programming (arithmetic, CA, Conway, BFS)
with no metaphysical commitments.

## Reference

- [README.md](./README.md) — high-level project overview
- [SUBSTRATE.md](./SUBSTRATE.md) — substrate-philosophical mapping
  for the Pointer Architecture v9.0 preprint (Tier 3 reading)
- [CLAIMS.md](./CLAIMS.md) — three-tier taxonomy separating
  language (Tier 1) from interpretive claims (Tiers 2, 3)
- `docs/manual.scrbl` — Scribble manual rendered with
  `make docs-html`
