#lang racket/base

;; sixth/main.rkt — public entry-point for the Sixth language collection.
;;
;; Re-exports the high-level API: interpreter construction, file loading,
;; REPL, and the substrate.  Detail implementations live in sibling
;; modules (lexer, parser, ast, compiler, vm, env, substrate/*).
;;
;; Status: Phase A skeleton.  All entries are stubs raising
;; `(error 'sixth "Phase X not yet implemented")` until their phase
;; lands.

(provide
  ;; Core interpreter
  make-interpreter
  load-file
  eval-string
  repl
  ;; Substrate access
  make-substrate
  substrate-reset!
  ;; Version
  sixth-version)

(define (sixth-version) "0.1.0-phaseA")

(define (make-interpreter . _)
  (error 'sixth "Phase C not yet implemented: make-interpreter"))

(define (load-file _path)
  (error 'sixth "Phase C not yet implemented: load-file"))

(define (eval-string _str)
  (error 'sixth "Phase C not yet implemented: eval-string"))

(define (repl . _)
  (error 'sixth "Phase C not yet implemented: repl"))

(define (make-substrate . _)
  (error 'sixth "Phase D not yet implemented: make-substrate"))

(define (substrate-reset! _sub)
  (error 'sixth "Phase D not yet implemented: substrate-reset!"))
