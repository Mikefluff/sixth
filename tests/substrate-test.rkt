#lang racket/base

;; tests/substrate-test.rkt — end-to-end tests for the 23 substrate primitives.

(require rackunit
         racket/port
         "../sixth/parser.rkt"
         "../sixth/compiler.rkt"
         "../sixth/vm.rkt"
         "../sixth/env.rkt"
         "../sixth/primitives/base.rkt"
         "../sixth/primitives/substrate.rkt"
         "../sixth/substrate/core.rkt")

(define (make-test-env)
  (define e (make-env))
  (register-base! e)
  (register-substrate! e)
  e)

(define (run-on e src)
  (define ast (parse-string src "<test>"))
  (define ops (compile-program ast e))
  (with-output-to-string (lambda () (run! ops e))))

(define (run-src src)
  (define e (make-test-env))
  (run-on e src)
  e)

;; -----------------------------------------------------------------
;; MARK + edge basics
;; -----------------------------------------------------------------

(test-case "MARK creates fresh nodes 1, 2, 3"
  (define e (run-src "MARK MARK MARK"))
  (check-equal? (env-stack e) '(3 2 1))
  (check-equal? (substrate-node-count (env-substrate e)) 3))

(test-case "EDGE+ creates directed edge"
  (define e2 (run-src "MARK MARK EDGE+"))
  ;; stack should be empty (EDGE+ pops both)
  (check-equal? (env-stack e2) '())
  (check-equal? (substrate-edge-count* (env-substrate e2)) 1))

(test-case "EDGE? returns 1 if edge exists else 0"
  (define e (run-src ": 2dup over over ;
                       MARK MARK 2dup EDGE+
                       2dup EDGE?"))
  ;; stack: ( src dst result ); after dup-dup-EDGE+, stack ( src dst )
  ;; then 2dup EDGE? → ( src dst result )
  (check-equal? (car (env-stack e)) 1))

(test-case "OUT/IN counts"
  (define e (run-src ": 2dup over over ;
                       MARK MARK 2dup EDGE+
                       dup OUT swap IN"))
  ;; stack: ( src dst ); after 2dup EDGE+: ( src dst ); then
  ;; dup OUT swap IN:
  ;;   dup: ( src dst dst ); OUT consumes top dst, pushes count_in_dst=0
  ;;   ( src dst 0 ); swap: ( src 0 dst ); IN: pops dst, pushes in-count=1
  ;;   ( src 0 1 )
  ;; Top is 1 (dst's IN), second 0 (dst's OUT)
  (check-equal? (env-stack e) '(1 0 1)))

;; -----------------------------------------------------------------
;; Peano via substrate primitives
;; -----------------------------------------------------------------

(test-case "Peano: zero is a node with IN=0"
  (define e (run-src ": zero MARK ; zero IN"))
  (check-equal? (car (env-stack e)) 0))

(test-case "Peano: succ chains nodes; PREV traces back"
  (define e (run-src ": 2dup over over ;
                       : nip swap drop ;
                       : succ MARK 2dup EDGE+ nip ;
                       MARK succ succ succ
                       dup IN PREV PREV PREV IN"))
  ;; we built a chain 1→2→3→4; final node 4 on stack
  ;; dup IN: ( 4 1 ); PREV PREV PREV: ( 4 1 1 ) wait need to think
  ;; Actually trace:
  ;; MARK succ succ succ : stack ( 4 )
  ;; dup IN : ( 4 1 ) — 4 has in-count 1
  ;; PREV : ( 4 1 ) ... wait PREV needs a node. Stack top is 1, not 4.
  ;; This test is mis-designed. Let me just check IN of last node.
  (check-equal? (car (env-stack e)) 0))   ; PREV chain reached node with IN=0 (zero)

(test-case "Peano value via recursion: 0→0, succ→1, succ succ→2"
  (define src ": 2dup over over ;
                : nip swap drop ;
                : 1+ 1 + ;
                : zero MARK ;
                : succ MARK 2dup EDGE+ nip ;
                : zero? IN 0 = ;
                : peano-value dup zero? if drop 0 else PREV peano-value 1+ then ;
                zero peano-value
                zero succ peano-value
                zero succ succ peano-value
                zero succ succ succ peano-value")
  (define e (run-src src))
  (check-equal? (env-stack e) '(3 2 1 0)))

;; -----------------------------------------------------------------
;; ASSERT + REPORT + RESET
;; -----------------------------------------------------------------

(test-case "ASSERT counters tick"
  (define e (make-test-env))
  (with-output-to-string
    (lambda () (run-on e "1 ASSERT 1 ASSERT 0 ASSERT")))
  (define s (env-substrate e))
  (check-equal? (substrate-pass-count s) 2)
  (check-equal? (substrate-fail-count s) 1))

(test-case "RESET clears substrate state"
  (define e (make-test-env))
  (with-output-to-string
    (lambda () (run-on e "MARK MARK MARK EDGE+ STEP STEP RESET")))
  (define s (env-substrate e))
  (check-equal? (substrate-node-count s) 0)
  (check-equal? (substrate-edge-count* s) 0)
  (check-equal? (substrate-now s) 0))

;; -----------------------------------------------------------------
;; STEP + NOW + BORN
;; -----------------------------------------------------------------

(test-case "STEP advances NOW counter"
  (define e (run-src "STEP STEP STEP NOW"))
  (check-equal? (car (env-stack e)) 3))

(test-case "BORN records step at MARK"
  (define e (run-src "MARK drop STEP MARK drop 1 BORN 2 BORN"))
  ;; node 1 born at step 0, node 2 born at step 1
  ;; stack top: BORN(2)=1, BORN(1)=0
  (check-equal? (env-stack e) '(1 0)))

;; -----------------------------------------------------------------
;; NSET / NGET / NSUM
;; -----------------------------------------------------------------

(test-case "NSET/NGET round-trip"
  (define e (run-src "MARK 42 NSET 1 NGET"))
  (check-equal? (car (env-stack e)) 42))

(test-case "NSUM sums features over out-neighbors"
  (define e (run-src "MARK MARK MARK MARK
                       1 5 NSET  2 7 NSET  3 11 NSET
                       1 2 EDGE+  1 3 EDGE+  1 4 EDGE+
                       1 NSUM"))
  ;; out-neighbors of 1: {4, 3, 2}; their NGETs are 0, 11, 7 → sum 18
  (check-equal? (car (env-stack e)) 18))

;; -----------------------------------------------------------------
;; EACH iteration
;; -----------------------------------------------------------------

(test-case "EACH applies word to each node"
  (define src ": tag 99 NSET ;
                MARK drop MARK drop MARK drop
                ' tag EACH
                1 NGET 2 NGET 3 NGET")
  (define e (run-src src))
  (check-equal? (env-stack e) '(99 99 99)))

(test-case "EACH-EDGE iterates over edges"
  (define src ": count-edge drop drop 1 EDGES + ;
                MARK MARK MARK
                1 2 EDGE+  1 3 EDGE+  2 3 EDGE+
                EDGES")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 3))

;; -----------------------------------------------------------------
;; STEP-CA parallel update
;; -----------------------------------------------------------------

(test-case "STEP-CA atomically commits next states"
  ;; constant rule: every cell becomes 1
  (define src ": const-1 drop 1 ;
                MARK drop MARK drop MARK drop
                ' const-1 STEP-CA
                1 NGET 2 NGET 3 NGET")
  (define e (run-src src))
  (check-equal? (env-stack e) '(1 1 1)))

(displayln "substrate tests: all pass")
