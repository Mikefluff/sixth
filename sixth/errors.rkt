#lang racket/base

;; sixth/errors.rkt — exception hierarchy + source-location rendering.
;;
;; All Sixth runtime/compile errors derive from `exn:fail:sixth`.
;; Each carries a `srcloc` (which may be #f for synthetic errors).
;;
;; Subtypes:
;;   exn:fail:sixth:lex       — lexer errors (bad characters, unterminated string)
;;   exn:fail:sixth:parse     — parser errors (unmatched if/then, missing ;)
;;   exn:fail:sixth:type      — type mismatch at primitive call
;;   exn:fail:sixth:stack     — stack underflow / type-on-wrong-position
;;   exn:fail:sixth:unbound   — word not defined
;;   exn:fail:sixth:substrate — substrate-level error (e.g. zero-arity rule)
;;
;; Status: Phase A skeleton.

(provide
  (struct-out exn:fail:sixth)
  (struct-out exn:fail:sixth:lex)
  (struct-out exn:fail:sixth:parse)
  (struct-out exn:fail:sixth:type)
  (struct-out exn:fail:sixth:stack)
  (struct-out exn:fail:sixth:unbound)
  (struct-out exn:fail:sixth:substrate)
  format-srcloc)

(struct exn:fail:sixth            exn:fail (srcloc)            #:transparent)
(struct exn:fail:sixth:lex        exn:fail:sixth ()            #:transparent)
(struct exn:fail:sixth:parse      exn:fail:sixth ()            #:transparent)
(struct exn:fail:sixth:type       exn:fail:sixth (expected got) #:transparent)
(struct exn:fail:sixth:stack      exn:fail:sixth ()            #:transparent)
(struct exn:fail:sixth:unbound    exn:fail:sixth (name)        #:transparent)
(struct exn:fail:sixth:substrate  exn:fail:sixth ()            #:transparent)

;; Render a srcloc in `file:line:col` form, or `<repl>` if missing.
(define (format-srcloc loc)
  (cond
    [(not loc) "<repl>"]
    [(srcloc? loc)
     (format "~a:~a:~a"
             (or (srcloc-source loc) "<unknown>")
             (or (srcloc-line loc) "?")
             (or (srcloc-column loc) "?"))]
    [else "<unknown>"]))
