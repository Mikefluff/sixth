#lang racket/base

;; sixth/ast.rkt — AST node types.
;;
;; The parser produces a sequence of AST nodes that the compiler
;; lowers to opcodes.  Every node carries an optional srcloc for
;; error reporting.
;;
;; Forms:
;;   (literal value srcloc)            — push a literal onto the stack
;;   (word-ref name srcloc)            — invoke a word by name
;;   (definition name body srcloc)     — `: name ... ;`
;;   (if-then-else then-branch else-branch srcloc)  — `if ... else ... then`
;;   (quote-word name srcloc)          — `' name` (push name as symbol)
;;   (use-module spec srcloc)          — `use foo` / `use foo as f` / `use foo (a b)`
;;
;; Status: Phase A skeleton.

(provide
  (struct-out ast-literal)
  (struct-out ast-word-ref)
  (struct-out ast-definition)
  (struct-out ast-if-then-else)
  (struct-out ast-quote-word)
  (struct-out ast-use-module))

(struct ast-literal       (value srcloc)              #:transparent)
(struct ast-word-ref      (name srcloc)               #:transparent)
(struct ast-definition    (name body srcloc)          #:transparent)
(struct ast-if-then-else  (then-body else-body srcloc) #:transparent)
(struct ast-quote-word    (name srcloc)               #:transparent)
(struct ast-use-module    (spec srcloc)               #:transparent)
