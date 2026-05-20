#lang scribble/manual
@require[scribble/manual]

@title{Sixth — Foundational Substrate Language}
@author{Mikhail Savchenko}

Sixth is a small Forth-like stack language hosted on Racket with an
attached hypergraph-rewriting substrate.  From 15 base primitives and
23 substrate primitives, the bundled emergence demos derive numbers,
time, space, conservation laws, particles, observers, and universal
computation, then ascend through substrate-native autopoiesis,
conscious evolution, and cosmogenesis bootstrap.

@bold{Status:} engine + stdlib + 32 demos (Pilots A--E, 571 ✓) +
@litchar{#lang sixth} + Racket-FFI PyTorch bridges (shadow / diff /
nn-cl) all working.  Pilot E adds the substrate-monist @litchar{phi-pa}
word so the same 38 primitives that build the substrate now also
compute the consciousness-measure on it.  Reference implementation
for the Pointer Architecture v9.0 preprint.

@table-of-contents[]

@include-section["language.scrbl"]
@include-section["substrate.scrbl"]
@include-section["stdlib.scrbl"]
@include-section["architecture.scrbl"]
@include-section["migration.scrbl"]

@section{Getting started}

Install the package via @exec{raco pkg install --link .} from the repo
root.  Run a demo:

@verbatim|{
racket -l sixth/cli -- run examples/01-numbers.6th
}|

Open a REPL:

@verbatim|{
racket -l sixth/cli -- repl
}|

Use @litchar{#lang sixth} directly:

@verbatim|{
#lang sixth
: factorial dup 1 > if dup 1 - factorial * else drop 1 then ;
5 factorial .
}|

@section{Bootstrap claim}

The substrate has three ontological primitives:

@itemlist[
  @item{@bold{Difference} — at least two distinct tokens exist (@litchar{MARK}).}
  @item{@bold{Pointer} — a token may be related to another (@litchar{EDGE+}).}
  @item{@bold{Rewrite} — the set of pointers can be transformed by a rule
        (@litchar{STEP}, @litchar{EACH}, @litchar{STEP-CA}).}
]

Everything else — counting, ordering, space, motion, observation,
self-knowing, universal computation — emerges from how those three
compose.  The @secref{substrate} chapter documents the derivations
demo-by-demo.
