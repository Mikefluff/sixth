#lang scribble/manual
@require[scribble/manual]

@title[#:tag "stdlib"]{Standard library}

The stdlib lives in @filepath{stdlib/} as ordinary @filepath{.6th}
source.  Words here are not primitives — they are defined in Sixth on
top of the 38 base + substrate ops.  The bootstrap-claim primitive
count is preserved.

Load any stdlib file with @litchar{use}, e.g. @litchar{use prelude}.

@section{prelude}

Auto-loaded by the REPL and by @litchar{#lang sixth} unless
@litchar{--no-prelude} is given.

@subsection{Stack helpers}

@tabular[
  (list
    (list @litchar{2dup}   "( a b -- a b a b )"     "duplicate top pair")
    (list @litchar{2drop}  "( a b -- )"             "drop top pair")
    (list @litchar{nip}    "( a b -- b )"           "drop second-from-top")
    (list @litchar{tuck}   "( a b -- b a b )"       "copy top under second")
    (list @litchar{rot}    "( a b c -- b c a )"     "rotate top three")
    (list @litchar{-rot}   "( a b c -- c a b )"     "inverse rotation"))]

@subsection{Arithmetic shortcuts}

@tabular[
  (list
    (list @litchar{1+}     "( n -- n+1 )"   "increment by 1")
    (list @litchar{1-}     "( n -- n−1 )"   "decrement by 1")
    (list @litchar{2+}     "( n -- n+2 )"   "increment by 2")
    (list @litchar{2-}     "( n -- n−2 )"   "decrement by 2")
    (list @litchar{2*}     "( n -- 2n )"    "double")
    (list @litchar{2/}     "( n -- n/2 )"   "halve"))]

@subsection{Logic / numeric helpers}

@tabular[
  (list
    (list @litchar{not}      "( v -- 0/1 )"     "true iff v is zero")
    (list @litchar{true}     "( -- 1 )"          "push 1")
    (list @litchar{false}    "( -- 0 )"          "push 0")
    (list @litchar{negate}   "( n -- −n )"       "additive inverse")
    (list @litchar{abs}      "( n -- |n| )"      "absolute value")
    (list @litchar{square}   "( n -- n² )"       "n times n")
    (list @litchar{min}      "( a b -- min )"    "smaller of two")
    (list @litchar{max}      "( a b -- max )"    "larger of two"))]

@section{peano}

Peano arithmetic constructed entirely from MARK + EDGE+.  Each natural
number is a chain of nodes.

@tabular[
  (list
    (list @litchar{zero}         "( -- n )"          "fresh chain root (single node)")
    (list @litchar{succ}         "( n -- m )"        "extend chain, return new head")
    (list @litchar{zero?}        "( n -- 0/1 )"      "is this a chain root?")
    (list @litchar{peano-value}  "( n -- k )"        "recover the natural by walking back")
    (list @litchar{peano-add}    "( a b -- c )"      "natural addition by chain concat")
    (list @litchar{peano-mul}    "( a b -- c )"      "natural multiplication by repeated add"))]

@section{graph}

@tabular[
  (list
    (list @litchar{bi-edge}   "( a b -- )"   "add edges a→b AND b→a"))]

@section{bfs}

BFS-style edge relaxation over substrate features.  Convention:
feature value −1 means "unreached".

@tabular[
  (list
    (list @litchar{eff-dist}   "( n -- d )"    "NGET with −1 mapped to a big number")
    (list @litchar{relax-edge} "( a b -- )"    "if d(a)+1 < d(b), set d(b) := d(a)+1")
    (list @litchar{set-inf}    "( n -- )"      "shorthand for NSET to −1")
    (list @litchar{bfs-init}   "( src -- src )" "set all features to −1, then src to 0")
    (list @litchar{bfs-step}   "( -- )"        "one STEP + relax over all edges"))]

@section{debug}

@tabular[
  (list
    (list @litchar{assert-eq}  "( a b -- )"   "ASSERT that a = b"))]

@section{Planned stdlib (future work)}

@itemlist[
  @item{@filepath{math.6th} — @litchar{factorial}, @litchar{gcd},
        @litchar{lcm}, @litchar{power}.}
  @item{@filepath{grid.6th} — @litchar{grid-2d} that constructs the
        Moore or von-Neumann adjacency in one call (replacing the
        144-edge hand-written block in Conway demos).}
  @item{@filepath{ca.6th} — common CA rules (@litchar{rule90},
        @litchar{rule110}, @litchar{rule184}, @litchar{conway-rule})
        as named stdlib words.}
]
