#lang scribble/manual
@require[scribble/manual]

@title[#:tag "architecture"]{Engine architecture}

The Sixth implementation lives under @filepath{sixth/} as an ordinary
Racket collection.  Components are intentionally separable —
each one is small enough to read in a sitting and has a clear
contract with its neighbours.

@section{Pipeline}

@verbatim|{
.6th source
   │
   ▼
[ Lexer ]   sixth/lexer.rkt
   │  tokens with srcloc
   ▼
[ Parser ]  sixth/parser.rkt
   │  AST nodes (sixth/ast.rkt)
   ▼
[ Compiler ] sixth/compiler.rkt
   │  opcode vector (sixth/opcodes.rkt)
   ▼
[ VM ]      sixth/vm.rkt
   │  side effects on env (stack, words, memory)
   ▼
[ Substrate ] sixth/substrate/core.rkt
}|

@section{Components}

@itemlist[
  @item{@bold{Lexer} (@filepath{sixth/lexer.rkt}) — character stream
        to tokens.  Each token carries a @racket[srcloc] for error
        reporting.  Backslash line comments, parenthesised inline
        comments, integer and string literals, named tokens for the
        seven reserved words.}
  @item{@bold{Parser} (@filepath{sixth/parser.rkt}) — tokens to AST
        nodes.  Recursive-descent.  Handles word definitions, nested
        @litchar{if/else/then}, tick (@litchar{'}), and module
        @litchar{use}.}
  @item{@bold{AST} (@filepath{sixth/ast.rkt}) — struct definitions:
        @racket[ast-literal], @racket[ast-word-ref],
        @racket[ast-definition], @racket[ast-if-then-else],
        @racket[ast-quote-word], @racket[ast-use-module].}
  @item{@bold{Compiler} (@filepath{sixth/compiler.rkt}) — AST to flat
        opcode vector.  Back-patches branch targets for if/else/then.
        Word bodies are compiled @bold{once} (legacy chibi re-tokenised
        the body string on every call).}
  @item{@bold{Opcodes} (@filepath{sixth/opcodes.rkt}) — instruction
        struct @racket[(op code arg srcloc)].  Six opcodes: LIT, CALL,
        JZ, JMP, RET, PRIM.}
  @item{@bold{VM} (@filepath{sixth/vm.rkt}) — stack machine.
        Dispatches opcodes via vector-ref (O(1)), primitives via
        hash-ref (O(1)).  Tail-call elimination when CALL is
        immediately followed by RET, replacing the current frame
        instead of pushing.  This is what lets recursive Sixth words
        (factorial, peano-mul) run arbitrarily deep without growing
        the host stack.}
  @item{@bold{Environment} (@filepath{sixth/env.rkt}) — mutable struct
        holding data stack, return stack, word registry, primitive
        registry, memory hash, and substrate handle.  Underscore-keyed
        memory writes are rejected (reserved for engine internals).}
  @item{@bold{Errors} (@filepath{sixth/errors.rkt}) — exception
        hierarchy: @racket[exn:fail:sixth], @racket[:lex], @racket[:parse],
        @racket[:type], @racket[:stack], @racket[:unbound],
        @racket[:substrate].  All carry srcloc for error rendering.}
  @item{@bold{Substrate core} (@filepath{sixth/substrate/core.rkt}) —
        the hypergraph state: node id allocator, in/out edge maps,
        feature map, step counter, BORN map, assert counters.  Used
        by every substrate primitive.}
  @item{@bold{Primitives} (@filepath{sixth/primitives/}) —
        @filepath{base.rkt} (15 base + 3 I/O), @filepath{substrate.rkt}
        (23 substrate).  Each primitive is a one-argument procedure
        @racket[(proc env)] that mutates the env.}
  @item{@bold{Loader} (@filepath{sixth/loader.rkt}) — module
        resolution and caching.  @litchar{use foo} resolves against
        the current file's directory, then cwd, then
        @envvar{SIXTH_PATH}.  Per-env weak cache so tests don't
        pollute each other.}
  @item{@bold{CLI} (@filepath{sixth/cli.rkt}) — @litchar{racket -l
        sixth/cli -- repl|run|test|bench}.}
  @item{@bold{@litchar{#lang sixth}} (@filepath{sixth/lang/reader.rkt}
        and @filepath{sixth/lang.rkt}) — language driver via
        @racket[syntax/module-reader] so any @filepath{.rkt} file
        starting with @litchar{#lang sixth} runs as a Sixth program.}
]

@section{Why the primitive-count contract matters}

The bootstrap claim of Sixth is that 15 base + 23 substrate = 38
operations suffice to derive everything in the demos.  This is the
ontological pitch: counting, time, space, conservation, particles,
observers, universal computation — all from 38 ops.

If we promoted convenient helpers (e.g. @litchar{2dup},
@litchar{bi-edge}, @litchar{grid-2d}) to engine primitives just to
shorten demo code, the claim weakens by exactly the number of
promotions.  So the stdlib is written in Sixth and the engine stays at
38.  Phase F of the refactor verified this: all 20 demos still pass
under the engine after duplicated helpers were moved to stdlib.

@section{Iteration semantics}

The four iterators all snapshot @bold{before} iterating, so mutations
inside the body do not change the iteration set.

@itemlist[
  @item{@litchar{EACH} — snapshot node-id range [1..N], call rule for
        each.}
  @item{@litchar{EACH-EDGE} — snapshot list of (src, dst) pairs from
        all out-edges, call rule for each pair.}
  @item{@litchar{EACH-2PATH} — snapshot list of (x, y, z) triples
        where x→y and y→z, call rule for each triple.}
  @item{@litchar{STEP-CA} — snapshot node-id range, compute next
        state by calling rule on each id (rule pushes the new value),
        @bold{then} commit all new values atomically via NSET.  This
        is what gives honest CA semantics — no serial-update bias.}
]

@section{Reentrant VM and the halt-sentinel frame}

The iterator primitives invoke @racket[run!] reentrantly on the rule
word's opcodes.  Because @racket[run!] shares the env's return stack
with whatever called the iterator, a naive nested @racket[run!] would
pop the caller's frame at the inner @litchar{RET}.

Fix: @racket[call-rule!] pushes a halt-sentinel frame
@racket[(frame #f #f)] before invoking the inner @racket[run!].
@racket[pop-return-frame] recognises the sentinel and halts the
nested execution cleanly rather than continuing into a bogus frame.
This is the pattern used in language workbenches that share a stack
across nested interpreters.

@section{Compilation note}

Word bodies are compiled to a single opcode vector at definition
time.  Calls into the word jump directly to that vector; iterators
@racket[call-rule!] them the same way.  There is no eval-by-text path
at runtime, so source files are parsed at most once.

Branch targets for @litchar{if/else/then} are emitted as JZ/JMP
opcodes with placeholder targets, then back-patched once the
corresponding @litchar{else} or @litchar{then} is parsed.
