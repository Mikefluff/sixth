#lang racket/base

;; sixth/lang.rkt — language driver for `#lang sixth`.
;;
;; The reader produces:
;;   (module name sixth/lang "<original source string>")
;; which expands via our `#%module-begin` to a runtime program that
;; tokenizes/parses/compiles/runs the source against a freshly
;; constructed environment with base + substrate + prelude loaded.

(provide (rename-out [sixth-module-begin #%module-begin])
         #%top
         #%app
         #%datum
         #%top-interaction)

(require (for-syntax racket/base
                     syntax/parse))

(define-syntax (sixth-module-begin stx)
  (syntax-parse stx
    [(_ source-string:str)
     #'(#%module-begin
        (require sixth/env
                 sixth/loader
                 sixth/primitives/base
                 sixth/primitives/substrate)
        (define e (make-env))
        (register-base! e)
        (register-substrate! e)
        (use-module! "prelude" e)
        (load-source source-string e))]))
