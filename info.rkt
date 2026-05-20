#lang info

;; This package provides multiple collections from the directory tree:
;;   - sixth/   the language engine + primitives + bridges
;;   - tests/   (a "collection" for raco test to find)
;;
;; Top-level info.rkt declares package-wide metadata.  Per-collection
;; metadata (scribblings, deps) lives under each collection.

(define collection 'multi)

(define version "0.1.0")
(define pkg-desc
  "Sixth — minimal foundational substrate language for Pointer Architecture.
   15 base + 23 substrate primitives, hypergraph rewriting engine, autograd
   PyTorch bridge, #lang sixth Racket support.")
(define pkg-authors '("Mikhail Savchenko"))
(define license '(MIT))

(define deps
  '("base"
    "rackunit-lib"))

(define build-deps
  '("scribble-lib"
    "racket-doc"
    "rackunit-doc"))

(define test-omit-paths '("legacy"))
(define compile-omit-paths '("legacy"))
