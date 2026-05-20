#lang scribble/manual
@require[scribble/manual]

@title[#:tag "substrate"]{The Substrate}

This chapter is the foundations document.  Migrated from the legacy
@filepath{SUBSTRATE.md}; updated for the Racket-hosted implementation.

@section{Three ontological primitives}

The substrate has only three:

@itemlist[
  @item{@bold{Difference} — at least two distinct tokens exist.
        Created by @litchar{MARK}.}
  @item{@bold{Pointer} — a token may be related to another.  Created
        by @litchar{EDGE+}.}
  @item{@bold{Rewrite} — the set of pointers can be transformed by a
        rule.  Driven by @litchar{STEP}, @litchar{EACH},
        @litchar{EACH-EDGE}, @litchar{EACH-2PATH}, @litchar{STEP-CA}.}
]

Everything else — counting, ordering, space, motion, observation,
self-knowing, universal computation — emerges from how those three
compose.

@section{Mapping to Pointer Architecture v8.0}

Pointer Architecture v8.0 declares five primitive components of any
substrate of cognition.  Each maps onto a substrate construct:

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{PA primitive}    @bold{Substrate realization})
    (list "G  (graph)"           "MARKed nodes plus EDGE+ adjacency")
    (list "R  (rewriting)"       "STEP / EACH / EACH-EDGE / EACH-2PATH / STEP-CA")
    (list "C  (commit)"          "snapshot-then-commit semantics of STEP-CA and EACH-*")
    (list "A  (archive)"         "BORN(n) records the step a node was created")
    (list "π  (observer)"        "a node whose EDGE+ set is its view of the substrate"))]

@section{What the demos demonstrate}

The 20 demos in @filepath{examples/} each isolate a single derivation
chain.

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{#}    @bold{Demo}                @bold{Derived structure})
    (list "01"        "numbers"                  "Peano arithmetic from MARK + EDGE+ + IN + PREV")
    (list "02"        "time"                     "Causal ordering as STEP-index of rewrites")
    (list "03"        "stable"                   "Fixed points of local rewrite rules")
    (list "04"        "conflict"                 "Rule-order = physics-choice (different futures)")
    (list "05"        "loop"                     "Self-reference as cyclic pointer topology")
    (list "06"        "observers"                "Observer-relative facts on partial views")
    (list "07"        "rewrite-tc"               "Transitive closure from {{x,y},{y,z}} → x→z")
    (list "08"        "distance-1d"              "1D BFS metric from edge-relaxation")
    (list "09"        "ca-rule90"                "Sierpinski fractal from XOR neighbour rule")
    (list "10"        "self-model"               "Substrate contains its own description (Quine)")
    (list "11"        "energy"                   "Edge-Δ monotone → 0 (thermodynamic equilibrium)")
    (list "12"        "wolfram"                  "Classical Wolfram hypergraph rule on substrate")
    (list "13"        "conservation"             "Ring + shift rule → invariant cell-sum (mass)")
    (list "14"        "grid-2d"                  "2D Manhattan metric from grid topology")
    (list "15"        "glider-1d"                "Rule 184 single-car propagating particle")
    (list "16"        "rule110"                  "Turing-complete dynamics from minimal substrate")
    (list "17"        "consensus"                "Intersubjective truth = view intersection")
    (list "18"        "morphism"                 "Structure-preserving subgraph map (category)")
    (list "19"        "conway-blinker"           "Game-of-Life blinker on 5×5 Moore-grid (2D CA)")
    (list "20"        "conway-glider"            "GoL 5-cell glider translates (+1,+1) in 4 steps"))]

All 352 assertions across these 20 demos pass under the Racket-hosted
engine.

@section{Catalog of substrate primitives}

@subsection{Difference + pointer + traversal}

@tabular[
  (list
    (list @litchar{MARK}        "( -- n )"        "create a new node, push its id")
    (list @litchar{EDGE+}       "( a b -- )"      "add edge a→b")
    (list @litchar{EDGE-}       "( a b -- )"      "remove edge a→b")
    (list @litchar{EDGE?}       "( a b -- 0/1 )"  "is there edge a→b?")
    (list @litchar{OUT}         "( n -- k )"      "out-degree")
    (list @litchar{IN}          "( n -- k )"      "in-degree")
    (list @litchar{NEXT}        "( n -- m )"      "first out-neighbour, 0 if none")
    (list @litchar{PREV}        "( n -- m )"      "first in-neighbour, 0 if none"))]

@subsection{Counts and time}

@tabular[
  (list
    (list @litchar{NODES}       "( -- k )"        "total number of nodes")
    (list @litchar{EDGES}       "( -- k )"        "total number of edges")
    (list @litchar{STEP}        "( -- )"          "increment global step counter")
    (list @litchar{NOW}         "( -- s )"        "current step")
    (list @litchar{BORN}        "( n -- s )"      "step at which node n was MARKed (−1 if absent)"))]

@subsection{Iteration}

@tabular[
  (list
    (list @litchar{EACH}        "( ' w -- )"      "call word w on every node id")
    (list @litchar{EACH-EDGE}   "( ' w -- )"      "call word w on every (src dst)")
    (list @litchar{EACH-2PATH}  "( ' w -- )"      "call word w on every (x y z)")
    (list @litchar{STEP-CA}     "( ' w -- )"      "compute w on all nodes from snapshot, commit atomically"))]

All four iterators snapshot the node or edge set before iterating, so
mutations inside the body do not affect the iteration order.
@litchar{STEP-CA} additionally collects per-node next-state values
during iteration and applies them all at once — the parallel-update
semantics needed for honest CA.

@subsection{Node features}

@tabular[
  (list
    (list @litchar{NSET}        "( n v -- )"      "set node n's feature value")
    (list @litchar{NGET}        "( n -- v )"      "get node n's feature value (0 if unset)")
    (list @litchar{NSUM}        "( n -- s )"      "sum of NGET over n's out-neighbours"))]

@subsection{Assertions and admin}

@tabular[
  (list
    (list @litchar{ASSERT}      "( v -- )"        "print ✓/✗; fail if v is zero")
    (list @litchar{RESET}       "( -- )"          "clear substrate, zero step and assert counters")
    (list @litchar{REPORT}      "( -- )"          "print one-line summary: nodes / edges / steps / pass / fail"))]

That is 38 operations total (15 base + 23 substrate).  Every demo uses
only these plus stdlib helpers written in Sixth itself.

@section{Related work}

This is research-program territory; the demos are deliberately minimal,
the formal lineage is rich.

@subsection{Foundational}

@itemlist[
  @item{G. Spencer-Brown, @italic{Laws of Form} (1969) — single primitive
        (the mark of distinction), develops calculus of distinctions,
        paradox of self-reference.  Closest formal predecessor of
        "start from difference".}
  @item{F. Varela & H. Maturana, @italic{Autopoiesis} (1972) —
        self-producing systems via distinction.  Observer included.}
  @item{G. Bateson, @italic{Steps to an Ecology of Mind} (1972) —
        "the difference that makes a difference" as definition of
        information.}
  @item{C. S. Peirce, semiotic triad — sign / object / interpretant;
        firstness / secondness / thirdness.}
  @item{A. N. Whitehead, @italic{Process and Reality} (1929) — events
        as primary, objects as patterns of events.}
]

@subsection{Discrete-substrate physics}

@itemlist[
  @item{J. A. Wheeler, @italic{It from Bit} (1990) — matter from
        information distinction; participatory universe.}
  @item{S. Wolfram, @italic{A New Kind of Science} (2002) and the
        Wolfram Physics Project (2020–) — hypergraph rewriting from
        minimal rules.  Demos 07, 12, 13, 15, 19, 20 are direct
        instantiations of this style.}
  @item{L. Smolin, @italic{The Trouble with Physics}; "relational
        physics" — no absolute frame; all properties are relations
        between observers.}
  @item{D. Deutsch & C. Marletto, @italic{Constructor Theory} — what
        transformations are possible vs impossible.}
]

@subsection{Self-reference and consciousness}

@itemlist[
  @item{K. Gödel, incompleteness via self-reference (1931).}
  @item{D. Hofstadter, @italic{Gödel, Escher, Bach} (1979); @italic{I
        Am a Strange Loop} (2007) — recursive self-modeling.  Demo 10
        is the substrate-level realization of his "strange loop".}
  @item{C. Rovelli, @italic{Relational Quantum Mechanics} (1996) —
        observer-dependent facts.  Demos 06 and 17 instantiate this
        for substrate.}
  @item{F. Varela & H. von Foerster, second-order cybernetics — the
        observer included in the observed system.}
]

@subsection{ML / contemporary}

@itemlist[
  @item{V. Vanchurin, @italic{The world as a neural network} (2020);
        @italic{Geometric Learning Dynamics} (2025, arXiv:2504.14728)
        — physics-as-learning-dynamics.  The substrate provides a
        discrete counterpart on which similar emergence arguments can
        be tested directly.}
  @item{E. Witten, @italic{Algebraic Observer Programme} (2022) —
        observer-relative subalgebras of operators.  Demos 06 and 17
        are the substrate version (subgraph as observer subalgebra).}
  @item{M. Savchenko, @italic{Pointer Architecture v8.0} (2026) — the
        present PhD substrate.  This artifact is its foundational
        layer.}
]

@section{Open directions}

@subsection{Engine extensions}

@itemlist[
  @item{Declarative pattern matching with multi-edge LHS and named
        variables.}
  @item{Explicit conflict-resolution primitives (priority, random,
        energy-min).}
  @item{Typed / labelled edges for richer hypergraph patterns.}
  @item{Compiled hot path for large-scale CA runs (vectorized
        STEP-CA).}
]

@subsection{More emergence proofs}

@itemlist[
  @item{Substrate-level analogue of Noether's theorem.}
  @item{Emergent entropy and second law.}
  @item{Multi-substrate morphism composition (full category).}
]

@subsection{Bridge to applied PA}

@itemlist[
  @item{Substrate primitives realized as PyTorch vectorized operations
        ("NN-shadow") — Phase H.}
  @item{Direct comparison of NN-substrate runs to Sixth-substrate runs
        on identical tasks.}
  @item{Using substrate-validated rules as inductive biases for neural
        architectures.}
]

@subsection{Formalisation}

@itemlist[
  @item{Categorical (functorial) account of @litchar{EACH-*} operators.}
  @item{Formal proof of substrate Turing-completeness via Rule 110
        embedding.}
  @item{Connection of substrate primitives to Spencer-Brown's algebra.}
]
