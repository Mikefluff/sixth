#lang scribble/manual
@require[scribble/manual]

@title{Sixth — Foundational Substrate Language}
@author{Mikhail Savchenko}

Sixth is a small Forth-like stack language hosted on Racket with an
attached hypergraph-rewriting substrate.  From 17 base primitives and
23 substrate primitives, the bundled emergence demos derive numbers,
time, space, conservation laws, particles, observers, and universal
computation, then ascend through substrate-native autopoiesis,
conscious evolution, and cosmogenesis bootstrap.

@bold{Status:} engine + stdlib + 76 demos (sacred hello world +
Pilots A--K + 3 substrate-monism trace pilots + 2 long-epoch
parametric + 5 foundation visual traces + 2 atomic-build traces +
1 PA-ontological shell decomposition + Pilot G composite distinction
+ Pilot H mutation + substrate-readable selection + Pilot I
multi-level particle hierarchy + Pilot J substrate-native charge
conservation + Pilot K spontaneous coalition assembly, 1049 ✓) + @litchar{#lang sixth} + Racket-FFI PyTorch bridges
(shadow / diff / nn-cl) all working.  Pilot E adds three candidate substrate-
readable observability measures (@litchar{phi-pa},
@litchar{phi-integ}, @litchar{phi-bidir}); Pilot F instantiates the
preprint's transformer / brain / split-brain / ant-colony encoding
maps on toy substrates; three visual-trace pilots
(@litchar{stdlib/dot.6th} + @litchar{code/render_trace.py}) render
Pilots C, D, and F.3 substrate evolution as multi-panel figures or
animated GIFs via @exec{make traces} / @exec{make gif-pilot-d};
demo 40 is a parametric long-epoch autopoiesis run controlled by
the CLI @exec{-D max-cycles=N -D snap-every=K} flags (TCO-safe
arbitrary scale).  Single-shot artifact status: @exec{make verify}.
See @litchar{CLAIMS.md} for the three-tier taxonomy and
@litchar{LANGUAGE.md} for Sixth as a stand-alone programming
language separable from the v9.0 cosmology claims.  Reference
implementation for the Pointer Architecture v9.0 preprint.

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
racket -l sixth/cli -- run examples/12-numbers.6th
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
