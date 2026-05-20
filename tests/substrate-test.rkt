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

(test-case "Peano: succ chains nodes; PREV traces back to root"
  (define e (run-src ": 2dup over over ;
                       : nip swap drop ;
                       : succ MARK 2dup EDGE+ nip ;
                       MARK succ succ succ
                       PREV PREV PREV IN"))
  ;; Built chain 1→2→3→4 (node 4 has IN-edge from node 3, etc.)
  ;; Stack after MARK succ succ succ: ( 4 ).  Then:
  ;;   PREV  →  ( 3 )      (node 3 is the predecessor of 4)
  ;;   PREV  →  ( 2 )
  ;;   PREV  →  ( 1 )      (root)
  ;;   IN    →  ( 0 )      (root has no incoming edge → IN=0)
  (check-equal? (car (env-stack e)) 0))

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

;; -----------------------------------------------------------------
;; Round-2 audit coverage gaps — EDGE-, EACH-2PATH, NEXT, NGET/NSUM
;; on unset nodes, BORN on never-marked node.
;; -----------------------------------------------------------------

(test-case "EDGE- removes an existing directed edge"
  ;; Build edge 1→2, count (1), remove, recount (0), query (0).
  (define e (run-src ": 2dup over over ;
                       : 2drop drop drop ;
                       MARK MARK 2dup EDGE+ 2drop
                       EDGES
                       1 2 EDGE-
                       EDGES
                       1 2 EDGE?"))
  (check-equal? (env-stack e) '(0 0 1)))

(test-case "EDGE- on missing edge is a no-op"
  (define e (run-src "MARK MARK 1 2 EDGE- EDGES"))
  (check-equal? (car (env-stack e)) 0))

(test-case "NEXT returns out-neighbour of a node"
  (define e (run-src "MARK MARK MARK
                       1 2 EDGE+   1 3 EDGE+
                       1 NEXT"))
  ;; NEXT returns one of the out-neighbours; either 2 or 3 is acceptable.
  (define v (car (env-stack e)))
  (check-true (or (= v 2) (= v 3))))

(test-case "NGET on unset node returns 0"
  (define e (run-src "MARK NGET"))
  (check-equal? (car (env-stack e)) 0))

(test-case "NSUM on isolated node returns 0"
  (define e (run-src "MARK 10 NSET   1 NSUM"))
  (check-equal? (car (env-stack e)) 0))

(test-case "BORN on never-marked node returns -1 (sentinel)"
  ;; Node id 999 was never MARKed.
  (define e (run-src "999 BORN"))
  (check-equal? (car (env-stack e)) -1))

(test-case "EACH on empty substrate is a no-op"
  (define src ": tag 99 NSET ;
                ' tag EACH
                NODES")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 0))

(test-case "EACH-2PATH iterates length-2 paths"
  ;; Chain 1→2→3 has one length-2 path (1, 2, 3).
  (define src (string-append
                ": count-2path drop drop drop "
                "  " (string #\") "count-2p" (string #\")
                " load 1 + " (string #\") "count-2p" (string #\") " store ;\n"
                "0 " (string #\") "count-2p" (string #\") " store\n"
                "MARK MARK MARK\n"
                "1 2 EDGE+   2 3 EDGE+\n"
                "' count-2path EACH-2PATH\n"
                (string #\") "count-2p" (string #\") " load"))
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 1))

(test-case "RESET-then-MARK starts fresh node IDs"
  (define e (make-test-env))
  (with-output-to-string
    (lambda () (run-on e "MARK MARK MARK RESET MARK"))) ; → node id 1 again
  (check-equal? (substrate-node-count (env-substrate e)) 1))

(test-case "REPORT writes counts to stdout"
  (define e (make-test-env))
  ;; run-on already wraps run! in with-output-to-string and returns
  ;; the captured string — don't double-wrap.
  (define out (run-on e "MARK MARK 1 ASSERT 0 ASSERT REPORT"))
  (check-true (regexp-match? #rx"pass=" out))
  (check-true (regexp-match? #rx"fail=" out)))

(displayln "substrate tests: all pass")
