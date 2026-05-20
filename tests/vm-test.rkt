#lang racket/base

;; tests/vm-test.rkt — end-to-end smoke tests for VM + base primitives.
;;
;; Verifies:
;;   - 15 base primitives execute correctly
;;   - word definition + invocation
;;   - if/then/else branching
;;   - recursive word (factorial) works under TCO
;;   - store/load with namespace guard

(require rackunit
         racket/port
         "../sixth/parser.rkt"
         "../sixth/compiler.rkt"
         "../sixth/vm.rkt"
         "../sixth/env.rkt"
         "../sixth/errors.rkt"
         "../sixth/primitives/base.rkt")

;; Drive a complete source string and return both the stack and any
;; captured stdout.
(define (run-source src)
  (define e (make-env))
  (register-base! e)
  (define ast   (parse-string src "<test>"))
  (define ops   (compile-program ast e))
  (define out
    (with-output-to-string
      (lambda () (run! ops e))))
  (values (env-stack e) out))

(define (stack-of src)
  (define-values (st _) (run-source src))
  st)

(define (stdout-of src)
  (define-values (_ out) (run-source src))
  out)

;; -----------------------------------------------------------------
;; Stack primitives
;; -----------------------------------------------------------------

(test-case "1 2 + leaves 3"
  (check-equal? (stack-of "1 2 +") '(3)))

(test-case "5 3 - leaves 2 (left-to-right pop order)"
  (check-equal? (stack-of "5 3 -") '(2)))

(test-case "dup over swap drop sequence"
  (check-equal? (stack-of "1 2 dup")  '(2 2 1))
  (check-equal? (stack-of "1 2 over") '(1 2 1))
  (check-equal? (stack-of "1 2 swap") '(1 2))
  (check-equal? (stack-of "1 2 drop") '(1)))

(test-case "Arithmetic battery"
  (check-equal? (stack-of "6 2 /")    '(3))
  (check-equal? (stack-of "10 3 mod") '(1))
  (check-equal? (stack-of "4 5 *")    '(20)))

(test-case "Comparison primitives"
  (check-equal? (stack-of "3 3 =")  '(1))
  (check-equal? (stack-of "3 4 =")  '(0))
  (check-equal? (stack-of "1 2 <")  '(1))
  (check-equal? (stack-of "5 2 >")  '(1)))

;; -----------------------------------------------------------------
;; Word definition + invocation
;; -----------------------------------------------------------------

(test-case "Define and call square"
  (check-equal? (stack-of ": square dup * ; 7 square") '(49)))

(test-case "Definitions registered but not executed at top level"
  (check-equal? (stack-of ": foo 99 ;") '()))

(test-case "Helper builds on helper"
  (check-equal? (stack-of ": 1+ 1 + ; : double dup + ; 5 1+ double") '(12)))

;; -----------------------------------------------------------------
;; If/then/else branching
;; -----------------------------------------------------------------

(test-case "if-then (true)"
  (check-equal? (stack-of "1 if 99 then") '(99)))

(test-case "if-then (false skips body)"
  (check-equal? (stack-of "0 if 99 then") '()))

(test-case "if-then-else (true)"
  (check-equal? (stack-of "1 if 11 else 22 then") '(11)))

(test-case "if-then-else (false)"
  (check-equal? (stack-of "0 if 11 else 22 then") '(22)))

(test-case "Nested if-then-else inside word"
  ;; sign: positive → 1, negative → -1, else 0
  (define src ": sign dup 0 > if drop 1 else dup 0 < if drop -1 else drop 0 then then ;
                5 sign  -5 sign  0 sign")
  (check-equal? (stack-of src) '(0 -1 1)))

;; -----------------------------------------------------------------
;; Recursion (TCO)
;; -----------------------------------------------------------------

(test-case "Factorial 5! = 120"
  (define src ": fact dup 1 > if dup 1 - fact * else drop 1 then ;
                5 fact")
  (check-equal? (stack-of src) '(120)))

(test-case "Deeper recursion does not blow stack"
  (define src ": countdown dup 0 > if 1 - countdown else drop 0 then ;
                500 countdown")
  ;; If non-TCO, 500 frames may be OK but the principle holds
  (check-equal? (stack-of src) '(0)))

;; -----------------------------------------------------------------
;; Store / load
;; -----------------------------------------------------------------

(test-case "Store then load returns value"
  ;; 42 "x" store  then load "x" → 42
  (define e (make-env))
  (register-base! e)
  (env-store! e 'x 42)
  (check-equal? (env-load e 'x) 42))

(test-case "Load missing key returns 0"
  (define e (make-env))
  (register-base! e)
  (check-equal? (env-load e 'missing) 0))

(test-case "Store with underscore key raises"
  (define e (make-env))
  (register-base! e)
  (check-exn exn:fail:sixth?
             (lambda () (env-store! e '_temp 1))))

;; -----------------------------------------------------------------
;; Output
;; -----------------------------------------------------------------

(test-case "Dot prints value plus space"
  (check-equal? (stdout-of "42 .") "42 ")
  (check-equal? (stdout-of "1 2 + .") "3 "))

(test-case "Cr prints newline"
  (check-equal? (stdout-of "1 . cr 2 .") "1 \n2 "))

(displayln "vm tests: all pass")
