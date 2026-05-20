#lang scribble/manual
@require[scribble/manual]

@title[#:tag "language"]{The Sixth Language}

Sixth is a postfix stack language.  Whitespace separates tokens;
values are pushed onto the data stack; words (named procedures) pop
arguments and push results.  This chapter is the language reference.

@section{Lexical structure}

Source files use the @filepath{.6th} extension and UTF-8 encoding.

@subsection{Comments}

@itemlist[
  @item{Backslash to end-of-line: @litchar{\ this is a line comment}.}
  @item{Parenthesised inline: @litchar{( stack: a b -- a+b )}.  Nesting
        is not supported; the first unmatched @litchar{)} closes.}
]

@subsection{Literals}

@itemlist[
  @item{Integers: @litchar{42}, @litchar{-7}, @litchar{0}.}
  @item{Strings: @litchar{"hello"} with escapes @litchar{\n} @litchar{\t}
        @litchar{\\} @litchar{\"}.  Strings are mostly used as memory
        keys.}
]

@subsection{Identifiers}

Any whitespace-delimited token that is not a literal or reserved word
is a word reference.  Conventionally:

@itemlist[
  @item{Primitives and substrate ops are UPPERCASE (@litchar{MARK},
        @litchar{EDGE+}, @litchar{STEP-CA}).}
  @item{User words and stdlib helpers are lowercase
        (@litchar{factorial}, @litchar{bi-edge}).}
]

This is convention only; the parser is case-sensitive but does not
enforce a casing rule.

@subsection{Reserved words}

@litchar{:} @litchar{;} @litchar{if} @litchar{else} @litchar{then}
@litchar{'} @litchar{use}.  These cannot be used as word names.

@section{Syntactic constructs}

@subsection{Word definition}

@verbatim|{
: name body... ;
}|

Defines @litchar{name} to execute @litchar{body...} when called.
Examples:

@verbatim|{
: square dup * ;
: factorial dup 1 > if dup 1 - factorial * else drop 1 then ;
}|

Definitions may appear at any top-level point and may be redefined;
later definitions shadow earlier ones in the current module.

@subsection{Conditional}

@verbatim|{
condition if then-body else else-body then
}|

@litchar{condition} pops one value; zero (or @litchar{0.0}) is false,
anything else is true.  The @litchar{else} branch is optional:

@verbatim|{
: not-zero? if 1 then ;       \ no else: empty branch
}|

@litchar{if/then/else} blocks may nest; balance is checked at parse
time.

@subsection{Word reference (tick)}

@verbatim|{
' word-name
}|

Pushes the symbol of @litchar{word-name} onto the stack without
executing it.  Used to pass words as values to iterators like
@litchar{EACH} and @litchar{STEP-CA}:

@verbatim|{
' sprout EACH         \ apply `sprout` to every node
' rule90 STEP-CA      \ commit Rule-90 next-states atomically
}|

@subsection{Module import}

@verbatim|{
use module-name
}|

Loads @filepath{module-name.6th} from the same directory, the current
working directory, or any directory in the @envvar{SIXTH_PATH}
environment variable.  The module's word definitions become callable
in the importing module.  Importing is idempotent — re-importing the
same module is a no-op.

@section{Data stack}

The data stack holds tagged values.  Each value has a tag:

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Tag}    @bold{Native Racket}      @bold{Use})
    (list "INT"         "exact-integer"           "arithmetic, node ids")
    (list "FLOAT"       "inexact-real"            "differentiable features")
    (list "STR"         "string"                  "memory keys")
    (list "SYM"         "symbol"                  "quoted word names")
    (list "NODE"        "exact-integer"           "substrate node ids")
    (list "EDGE"        "(cons src dst)"          "reserved for future pattern matching")
    (list "TENSOR"      "ffi pointer + shape"     "only when bridges loaded"))]

Numeric primitives expect INT or FLOAT and produce the corresponding
result type.  Type mismatches raise a runtime error with source
location.

@section{Memory namespace}

The @litchar{store} and @litchar{load} primitives operate on a
per-module key-value memory.  Keys may be strings or symbols.

@itemlist[
  @item{Keys beginning with an underscore (@litchar{_}) are reserved
        for engine internals.  Attempting to @litchar{store} to one
        raises an error.}
  @item{There is no shared global memory across modules — each module
        has its own hash.}
]

@section{Base primitives (15)}

@subsection{Stack}

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Word}  @bold{Effect}            @bold{Stack})
    (list "dup"        "duplicate top"          "( a -- a a )")
    (list "drop"       "discard top"            "( a -- )")
    (list "swap"       "exchange top two"       "( a b -- b a )")
    (list "over"       "copy second-from-top"   "( a b -- a b a )"))]

@subsection{Arithmetic}

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Word}  @bold{Effect}            @bold{Stack})
    (list "+"          "add"                    "( a b -- a+b )")
    (list "-"          "subtract"               "( a b -- a-b )")
    (list "*"          "multiply"               "( a b -- a*b )")
    (list "/"          "divide"                 "( a b -- a/b )")
    (list "mod"        "modulus"                "( a b -- a%b )"))]

@subsection{Comparison}

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Word}  @bold{Effect}                 @bold{Stack})
    (list "="          "equal?"                      "( a b -- 0/1 )")
    (list "<"          "less than?"                  "( a b -- 0/1 )")
    (list ">"          "greater than?"               "( a b -- 0/1 )"))]

@subsection{Memory and I/O}

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Word}   @bold{Effect}                  @bold{Stack})
    (list "store"       "set key→value"               "( val key -- )")
    (list "load"        "fetch value (0 if absent)"   "( key -- val )")
    (list "."           "print top + space"           "( a -- )")
    (list "cr"          "print newline"               "( -- )")
    (list "emit"        "print char-code as char"     "( n -- )"))]

@litchar{.}, @litchar{cr}, @litchar{emit} are I/O helpers and are
counted alongside the 15 base primitives in the bootstrap claim only
as conveniences.  The arithmetic-and-stack core is 15.

@section{Substrate primitives (23)}

The substrate primitives are documented in detail in
@secref{substrate}.  Quick reference:

@tabular[#:style 'boxed
  #:row-properties '(bottom-border ())
  (list
    (list @bold{Word}      @bold{Stack}             @bold{Effect})
    (list "MARK"           "( -- n )"               "new node, push id")
    (list "EDGE+"          "( a b -- )"             "add edge a→b")
    (list "EDGE-"          "( a b -- )"             "remove edge a→b")
    (list "EDGE?"          "( a b -- 0/1 )"         "is there edge a→b?")
    (list "OUT"            "( n -- k )"             "out-degree")
    (list "IN"             "( n -- k )"             "in-degree")
    (list "NEXT"           "( n -- m )"             "first out-neighbour")
    (list "PREV"           "( n -- m )"             "first in-neighbour")
    (list "NODES"          "( -- k )"               "total node count")
    (list "EDGES"          "( -- k )"               "total edge count")
    (list "STEP"           "( -- )"                 "increment step counter")
    (list "NOW"            "( -- k )"               "current step")
    (list "BORN"           "( n -- s )"             "step at which n was MARKed")
    (list "EACH"           "( ' word -- )"          "call word for every node id")
    (list "EACH-EDGE"      "( ' word -- )"          "call word for every (src dst)")
    (list "EACH-2PATH"     "( ' word -- )"          "call word for every (x y z)")
    (list "STEP-CA"        "( ' word -- )"          "atomic parallel state update")
    (list "NSET"           "( n v -- )"             "set node feature")
    (list "NGET"           "( n -- v )"             "get node feature")
    (list "NSUM"           "( n -- s )"             "sum features of out-neighbours")
    (list "ASSERT"         "( v -- )"               "fail if v is zero")
    (list "RESET"          "( -- )"                 "clear substrate, zero counters")
    (list "REPORT"         "( -- )"                 "print summary line"))]

Tick (@litchar{'}) is used to push a word symbol for iterators.
Iterators @litchar{EACH}, @litchar{EACH-EDGE}, @litchar{EACH-2PATH}
snapshot the node or edge set before iterating; mutations inside the
body do not affect iteration order.  @litchar{STEP-CA} computes all
next states from the current snapshot and commits them atomically —
the parallel-update semantics needed for honest cellular automata.

@section{Errors}

Runtime errors carry source locations:

@verbatim|{
TypeError at chain.6th:42:7 — `+` expected INT INT, got INT STR
stack underflow at peano.6th:14:6
unbound word `srpout` at demo.6th:18:5
}|

Categories:

@itemlist[
  @item{@bold{stack} — underflow on @litchar{pop} or @litchar{peek}.}
  @item{@bold{unbound} — call to an undefined word or primitive.}
  @item{@bold{type} — primitive received wrong tag.}
  @item{@bold{substrate} — edge to non-existent node, etc.}
  @item{@bold{lex/parse} — malformed source.}
]
