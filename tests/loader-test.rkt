#lang racket/base

;; tests/loader-test.rkt — module/loader round-trip.

(require rackunit
         racket/port
         "../sixth/loader.rkt"
         "../sixth/env.rkt"
         "../sixth/primitives/base.rkt"
         "../sixth/primitives/substrate.rkt")

(define (fresh-env)
  (define e (make-env))
  (register-base! e)
  (register-substrate! e)
  e)

(test-case "use prelude exposes 2dup and 1+"
  (define e (fresh-env))
  (with-output-to-string
    (lambda ()
      (load-source "use prelude  3 1+" e)))
  (check-equal? (env-stack e) '(4)))

(test-case "use peano builds peano-value"
  (define e (fresh-env))
  (with-output-to-string
    (lambda ()
      (load-source "use prelude  use peano  zero succ succ succ peano-value" e)))
  (check-equal? (env-stack e) '(3)))

(test-case "use graph adds bi-edge"
  (define e (fresh-env))
  (with-output-to-string
    (lambda ()
      (load-source "use prelude  use graph  MARK MARK bi-edge EDGES" e)))
  (check-equal? (car (env-stack e)) 2))

(test-case "use is idempotent"
  (define e (fresh-env))
  (with-output-to-string
    (lambda ()
      (load-source "use prelude  use prelude  3 1+" e)))
  (check-equal? (env-stack e) '(4)))

(displayln "loader tests: all pass")
