#lang scribble/manual
@require[scribble/manual]

@title[#:tag "migration"]{Migration from legacy chibi-Scheme}

The original Sixth was a small chibi-Scheme Forth (~140 line core
plus ~440 line substrate extension).  This chapter is for readers
familiar with that version who want to port code, or are curious
what changed and why.

@section{Where the legacy code lives}

Everything from the chibi-Scheme era is preserved under
@filepath{legacy/}:

@itemlist[
  @item{@filepath{legacy/sixth.scm} — original 15 base primitives.}
  @item{@filepath{legacy/sixth-substrate.scm} — substrate engine.}
  @item{@filepath{legacy/demo-*.6th} — original 20 emergence demos.}
  @item{@filepath{legacy/substrate_torch*.py},
        @filepath{legacy/substrate_nn_cl.py} — Python PyTorch
        bridges (still callable as Python scripts; native Racket
        bindings are Phase H).}
  @item{@filepath{legacy/README*.md} — original documentation.}
]

The @filepath{legacy/info.rkt} disables raco compilation and testing
of this directory, so it is read-only as far as the engine is
concerned.

@section{What changed}

@subsection{Engine}

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Concern}              @bold{Legacy chibi}              @bold{Racket-hosted})
    (list "Dispatch"                  "44-arm cond"                    "hash → O(1)")
    (list "Word body"                 "string, re-tokenised per call"  "opcode vector, compiled once")
    (list "Error reporting"           "no source location"             "file:line:col with category")
    (list "Modules"                   "loadfile only"                  "use foo with namespace and cache")
    (list "Engine memory namespace"   "shared *memory* with user"      "underscore-prefix reserved")
    (list "Recursion"                 "blew stack on peano-mul"        "TCO via Racket tail position")
    (list "Reader"                    "own REPL"                       "#lang sixth = native Racket lang"))]

@subsection{Demos}

@itemlist[
  @item{Helpers @litchar{2dup}, @litchar{nip}, @litchar{not},
        @litchar{1+}, @litchar{succ}, @litchar{bi-edge} that every
        demo redefined are now in @filepath{stdlib/prelude.6th},
        @filepath{stdlib/peano.6th}, and @filepath{stdlib/graph.6th}.
        Each demo @litchar{use}s the relevant stdlib instead of
        redefining.}
  @item{BFS helpers @litchar{eff-dist}, @litchar{relax-edge},
        @litchar{set-inf}, @litchar{bfs-init}, @litchar{bfs-step}
        moved to @filepath{stdlib/bfs.6th}.}
  @item{Demo @litchar{ASSERT}-style equality checks (@litchar{a b = ASSERT})
        were converted to @litchar{assert-eq} from
        @filepath{stdlib/debug.6th} for readability.}
  @item{Memory keys starting with underscore (@litchar{_start},
        @litchar{_count}, @litchar{_a}, @litchar{_b}, @litchar{_w},
        @litchar{_violations}) were renamed because the new engine
        reserves underscore keys for itself.}
]

@subsection{Bugs fixed in the port}

@itemlist[
  @item{Chibi's @racket[let] evaluated its bindings in unspecified
        order, which broke @litchar{swap} and @litchar{5 3 -} when
        translated literally.  Racket guarantees left-to-right
        @racket[let] evaluation per R7RS, so this no longer needs the
        @racket[let*] workaround.}
  @item{Iterator reentrancy: in the legacy engine, calling
        @litchar{EACH} inside a word body could pop the caller's
        return frame on inner @litchar{RET}.  Fixed with a halt-
        sentinel frame in @racket[call-rule!]; see
        @secref{architecture}.}
]

@section{Porting a legacy demo}

Mechanical recipe.  Take
@filepath{legacy/demo-something.6th} and produce
@filepath{examples/NN-something.6th}.

@itemlist[
  @item{Strip the inline helpers @litchar{: 2dup ... ;},
        @litchar{: nip ... ;}, @litchar{: not ... ;}, @litchar{: 1+
        ... ;}, @litchar{: zero ... ;}, @litchar{: succ ... ;},
        @litchar{: bi-edge ... ;}.  Replace with
        @litchar{use prelude}, @litchar{use peano}, @litchar{use graph}
        at the top.}
  @item{If the demo did BFS-style relaxation, add @litchar{use bfs}
        and remove the local definitions of @litchar{eff-dist},
        @litchar{relax-edge}, @litchar{set-inf}, @litchar{bfs-init},
        @litchar{bfs-step}.}
  @item{Add @litchar{use debug} and convert @litchar{... = ASSERT}
        sequences to @litchar{... assert-eq} where the comparison is
        equality.  Keep raw @litchar{ASSERT} for boolean predicates
        like @litchar{EDGE?} or @litchar{>}.}
  @item{Rename any underscore-prefixed memory keys to non-underscore
        equivalents.  Convention: prefix with a per-word slug
        (@litchar{"bfs-a"}, @litchar{"cw-sum"},
        @litchar{"loop-count"}).}
  @item{Run the demo: @litchar{racket -l sixth/cli -- run
        examples/NN-something.6th}.  Confirm @litchar{REPORT} shows
        the expected pass count and @bold{no} fails.}
]

@section{Side-by-side example}

Original (@filepath{legacy/demo-numbers.6th}, head):

@verbatim|{
: 2dup over over ;
: nip swap drop ;
: 1+ 1 + ;

: zero MARK ;
: succ MARK 2dup EDGE+ nip ;

: zero? IN 0 = ;
: peano-value
  dup zero? if drop 0
  else PREV peano-value 1+ then ;
}|

Migrated (@filepath{examples/01-numbers.6th}, head):

@verbatim|{
use prelude
use peano
use debug

STEP zero peano-value 0 assert-eq
}|

The seven shared definitions disappeared (now in
@filepath{stdlib/prelude.6th} and @filepath{stdlib/peano.6th}); the
assertion idiom became @litchar{assert-eq} for readability.  The
@litchar{STEP} stays as a substrate primitive because it advances the
NOW counter — that semantics is intentional.

@section{What did NOT change}

@itemlist[
  @item{The primitive count: 15 base + 23 substrate = 38.  Same as
        the legacy claim.}
  @item{Iterator semantics: snapshot-then-iterate, STEP-CA
        parallel-update.}
  @item{The 20 demos.  Same scenarios, same assertions (we got 352
        @litchar{✓} where the legacy reported 320, because the new
        engine's per-RESET counter is reported alongside the printed
        @litchar{✓} marks; cumulative pass is unchanged).}
]
