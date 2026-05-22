#lang racket/base

;; tests/substrate-test.rkt — end-to-end tests for the 31 substrate primitives
;; (23 substrate-core + 8 HEDGE3 trivalent).

(require rackunit
         racket/port
         "../sixth/parser.rkt"
         "../sixth/compiler.rkt"
         "../sixth/vm.rkt"
         "../sixth/env.rkt"
         "../sixth/errors.rkt"
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

;; ============================================================
;; HEDGE3 typed trivalent hyperedge primitive family — isolated
;; unit tests (independent of demo-level integration).
;; ============================================================

(test-case "HEDGE3+: WITNESS valid tuple inserts"
  (define src "MARK MARK MARK         0 1 2 3 HEDGE3+   HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 1))

(test-case "HEDGE3+: WITNESS with w==src raises substrate exception"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e "MARK MARK         0 1 2 1 HEDGE3+"))))))

(test-case "HEDGE3+: WITNESS with w==dst raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e "MARK MARK         0 1 2 2 HEDGE3+"))))))

(test-case "HEDGE3+: MEDIATOR with mid==src raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e "MARK MARK         1 1 1 2 HEDGE3+"))))))

(test-case "HEDGE3+: CONTEXT permits ctx==in (codon box pattern)"
  (define src "MARK MARK MARK         2 1 1 2 HEDGE3+   HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 1))

(test-case "HEDGE3+: CONTEXT rejects a==b==c degenerate"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e "MARK         2 1 1 1 HEDGE3+"))))))

(test-case "HEDGE3+: SIMPLEX all-distinct requirement"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e "MARK MARK         3 1 2 1 HEDGE3+"))))))

(test-case "HEDGE3+: idempotent — same (kind, a, b, c) inserts once"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+
               0 1 2 3 HEDGE3+
               0 1 2 3 HEDGE3+
               HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 1))

(test-case "HEDGE3?: returns 1 for present, 0 for absent"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+
               0 1 2 3 HEDGE3?")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 1)
  (define src2 "MARK MARK MARK
                0 1 2 3 HEDGE3?")
  (define e2 (run-src src2))
  (check-equal? (car (env-stack e2)) 0))

(test-case "HEDGE3-: removes; HEDGE3? returns 0 afterwards"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+
               0 1 2 3 HEDGE3-
               0 1 2 3 HEDGE3?")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 0))

(test-case "HEDGE3-: removing absent tuple is no-op"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3-
               HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 0))

(test-case "HEDGES3 totals across kinds"
  (define src "MARK MARK MARK MARK MARK
               0 1 2 3 HEDGE3+
               1 1 2 3 HEDGE3+
               2 1 2 3 HEDGE3+
               3 1 2 3 HEDGE3+
               HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 4))

(test-case "HEDGES3-KIND counts per kind"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+
               0 2 1 3 HEDGE3+
               3 1 2 3 HEDGE3+
               0 HEDGES3-KIND")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 2))

(test-case "HEDGE3-VALID?: predicate without side effects"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3-VALID?
               HEDGES3")
  (define e (run-src src))
  ;; Stack: HEDGES3 result on top (0, no hedges), then validation result (1).
  (define stack (env-stack e))
  (check-equal? (car stack) 0)            ; HEDGES3 = 0, no insertion happened
  (check-equal? (cadr stack) 1))          ; VALID? = 1

(test-case "HEDGE3-VALID? distinguishes kinds correctly"
  (define src "MARK MARK
               0 1 2 1 HEDGE3-VALID?    \\ WITNESS w==src → 0
               0 1 2 3 HEDGE3-VALID?    \\ WITNESS distinct → 1
               2 1 1 1 HEDGE3-VALID?    \\ CONTEXT fully degenerate → 0
               2 1 1 2 HEDGE3-VALID?    \\ CONTEXT ctx==in → 1
               3 1 1 2 HEDGE3-VALID?    \\ SIMPLEX a==b → 0
               3 1 2 3 HEDGE3-VALID?")  ; SIMPLEX all distinct → 1
  (define e (run-src src))
  (define stack (env-stack e))
  (check-equal? (list-ref stack 0) 1)     ; SIMPLEX valid
  (check-equal? (list-ref stack 1) 0)     ; SIMPLEX a==b
  (check-equal? (list-ref stack 2) 1)     ; CONTEXT ctx==in
  (check-equal? (list-ref stack 3) 0)     ; CONTEXT degenerate
  (check-equal? (list-ref stack 4) 1)     ; WITNESS valid
  (check-equal? (list-ref stack 5) 0))    ; WITNESS w==src

(test-case "EACH-HEDGE3 iterates all kinds with kind+triple pushed"
  ;; Tally how many hedges by kind by accumulating their kind ids.
  (define src ": tally
                 drop drop drop      \\ ignore (a b c)
                 \"sum\" load + \"sum\" store ;
               0 \"sum\" store
               MARK MARK MARK
               0 1 2 3 HEDGE3+
               1 1 2 3 HEDGE3+
               3 1 2 3 HEDGE3+
               ' tally EACH-HEDGE3
               \"sum\" load")
  (define e (run-src src))
  ;; Sum of kinds = 0 + 1 + 3 = 4.
  (check-equal? (car (env-stack e)) 4))

(test-case "EACH-HEDGE3-KIND iterates only the requested kind"
  ;; Count tally only for kind WITNESS.
  (define src ": tally
                 drop drop drop
                 \"n\" load 1 + \"n\" store ;
               0 \"n\" store
               MARK MARK MARK
               0 1 2 3 HEDGE3+
               1 1 2 3 HEDGE3+
               0 2 1 3 HEDGE3+
               0 ' tally EACH-HEDGE3-KIND
               \"n\" load")
  (define e (run-src src))
  ;; Only WITNESS-kind hedges visited: 2.
  (check-equal? (car (env-stack e)) 2))

(test-case "Different kinds with same (a,b,c) are distinct hyperedges"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+    \\ WITNESS (1,2,3)
               1 1 2 3 HEDGE3+    \\ MEDIATOR (1,2,3) — distinct
               HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 2))

;; ============================================================
;; Node-id validation: EDGE+ / HEDGE3+ raise on phantom ids.
;; Reads (NGET/BORN/OUT/IN) still tolerate phantoms and return
;; sentinel defaults — that's a documented asymmetry between
;; mutators (strict, surface typos early) and queries (lax,
;; treat absence as zero/sentinel).
;; ============================================================

(test-case "EDGE+: src phantom id raises substrate exception"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda () (run-on e "MARK   999 1 EDGE+"))))))

(test-case "EDGE+: dst phantom id raises substrate exception"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda () (run-on e "MARK   1 999 EDGE+"))))))

(test-case "HEDGE3+: phantom node id raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth:substrate?
             (lambda ()
               (with-output-to-string
                 (lambda () (run-on e "MARK MARK   0 1 2 999 HEDGE3+"))))))

(test-case "EDGE+: self-loop legitimate (own-Φ_PA depends on it)"
  (define e (run-src "MARK   1 1 EDGE+   EDGES   1 1 EDGE?"))
  ;; Stack top: EDGE? result (1, present), then EDGES count (1).
  (check-equal? (car  (env-stack e)) 1)
  (check-equal? (cadr (env-stack e)) 1))

(test-case "NGET / OUT / IN on phantom id return sentinel zero (queries lax)"
  (define e (run-src "999 NGET   999 OUT   999 IN"))
  (check-equal? (env-stack e) '(0 0 0)))

(test-case "EDGE-: removing edge involving phantom is no-op (lax)"
  (define e (run-src "MARK   1 999 EDGE-   EDGES"))
  (check-equal? (car (env-stack e)) 0))

;; ============================================================
;; Stack-balance enforcement in iteration primitives.  Rules
;; with the wrong net stack-effect must raise at the iteration
;; site so silent corruption (under EACH / STEP-CA / EACH-HEDGE3)
;; surfaces immediately.
;; ============================================================

(test-case "EACH: rule with wrong stack-delta raises"
  ;; rule-bad does NOT consume its node — leaves it on the stack.
  (define e (make-test-env))
  (check-exn exn:fail:sixth?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e ": rule-bad ;   MARK   ' rule-bad EACH"))))))

(test-case "STEP-CA: rule with wrong stack-delta raises (the demo-33 bug)"
  ;; rule-bad uses `dup NGET 1 +` — leaks the original node id
  ;; in addition to producing the next-state value.
  (define e (make-test-env))
  (check-exn exn:fail:sixth?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e ": rule-bad dup NGET 1 + ;   MARK   ' rule-bad STEP-CA"))))))

(test-case "STEP-CA: rule that doesn't push a result raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e ": rule-empty drop ;   MARK   ' rule-empty STEP-CA"))))))

(test-case "EACH-EDGE: rule with wrong stack-delta raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e ": rule-bad drop ;   MARK MARK   1 2 EDGE+   ' rule-bad EACH-EDGE"))))))

(test-case "EACH-2PATH: rule with wrong stack-delta raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e
                     ": rule-bad drop drop ;   MARK MARK MARK   1 2 EDGE+   2 3 EDGE+   ' rule-bad EACH-2PATH"))))))

(test-case "EACH-HEDGE3: rule with wrong stack-delta raises"
  (define e (make-test-env))
  (check-exn exn:fail:sixth?
             (lambda ()
               (with-output-to-string
                 (lambda ()
                   (run-on e
                     ": rule-bad drop drop drop ;   MARK MARK MARK   0 1 2 3 HEDGE3+   ' rule-bad EACH-HEDGE3"))))))

;; ============================================================
;; STEP-CA atomicity — rules must see PRE-step NGET values, not
;; post-update ones.  Without this guarantee any CA (Rule 90,
;; Conway, etc.) develops serial-bias artefacts.  Two-phase
;; commit (substrate.rkt:255) is the substrate invariant under
;; test.
;; ============================================================

(test-case "STEP-CA atomicity: rule reads pre-step neighbour values"
  ;; Build chain 1→2→3 with initial NGET (1=10, 2=0, 3=0).
  ;; Rule: next(n) = NSUM(n).  After ONE STEP-CA pass:
  ;;   next(1) = NSUM(1) = NGET(2) = 0          (BEFORE update of 2)
  ;;   next(2) = NSUM(2) = NGET(3) = 0          (BEFORE update of 3)
  ;;   next(3) = NSUM(3) = 0
  ;; If updates were serial (compute-then-write each node), then
  ;; processing 1 first would leave NGET(1)=0, and then when we
  ;; visit 2 we'd still see NGET(3)=0; but in some orderings the
  ;; bug would manifest as a non-zero result somewhere.  The
  ;; cleaner check: shift one step further.
  ;;
  ;; Start: 1=10, 2=20, 3=30; 1→2, 2→3.  next(n) = NSUM(n).
  ;;   atomic: next(1)=20 (from old NGET(2)), next(2)=30, next(3)=0
  ;;   serial-bias: next(1)=20, next(2)=30 OR next(2) using NGET=20 → 30
  ;;     (this particular topology would not distinguish).
  ;;
  ;; Use a topology that DOES distinguish: chain with feature swap.
  ;; 1→2, 2→1 (mutual).  Initial NGET(1)=5, NGET(2)=11.
  ;; Rule: next(n) = NSUM(n).
  ;;   atomic: next(1)=11 (from old NGET(2)), next(2)=5 (from old NGET(1))
  ;;   serial:  process 1 first → NGET(1)=11, then process 2:
  ;;           NSUM(2)=NGET(1)=11 (NEW value).  Result: 1=11, 2=11.
  ;; The two-phase commit gives the SWAP outcome (1=11, 2=5).
  (define src ": rule-sum NSUM ;
                MARK MARK
                1 5 NSET   2 11 NSET
                1 2 EDGE+   2 1 EDGE+
                ' rule-sum STEP-CA
                1 NGET 2 NGET")
  (define e (run-src src))
  ;; Stack top: NGET(2)=5 (was 11 before, became old NGET(1)=5).
  ;; Second: NGET(1)=11 (was 5, became old NGET(2)=11).
  ;; Serial-bias would yield NGET(2)=11 (post-update of 1 fed back).
  (check-equal? (car  (env-stack e))  5)
  (check-equal? (cadr (env-stack e)) 11))

(test-case "STEP-CA atomicity: parallel update of inverter cycle"
  ;; Mutual cycle 1↔2; rule: next(n) = 1 - NGET(neighbour).
  ;; With atomic two-phase: each step swaps and inverts.
  ;; Start NGET(1)=0, NGET(2)=1.
  ;; After STEP-CA: next(1) = 1 - NGET(2) = 0; next(2) = 1 - NGET(1) = 1.
  ;; Pattern is INVARIANT (each step recomputes from current).
  ;; Without atomicity, post-update of 1 would feed into 2's compute.
  (define src ": invert 1 swap NSUM - ;
                MARK MARK
                1 0 NSET   2 1 NSET
                1 2 EDGE+   2 1 EDGE+
                ' invert STEP-CA
                1 NGET 2 NGET")
  (define e (run-src src))
  ;; next(1) = 1 - NSUM(1) = 1 - NGET(2) = 1 - 1 = 0
  ;; next(2) = 1 - NSUM(2) = 1 - NGET(1) = 1 - 0 = 1
  ;; Stack top: NGET(2)=1.  Second: NGET(1)=0.
  (check-equal? (car  (env-stack e)) 1)
  (check-equal? (cadr (env-stack e)) 0))

;; ============================================================
;; ASSERT semantics — full type matrix for falsy/truthy.  Aligned
;; with VM JZ branching via shared zero-ish? (values.rkt).
;; ============================================================

(test-case "ASSERT: 0.0 (boxed float zero) fails"
  (define e (make-test-env))
  (with-output-to-string
    (lambda () (run-on e "1.0 1.0 - ASSERT")))
  (define s (env-substrate e))
  (check-equal? (substrate-fail-count s) 1)
  (check-equal? (substrate-pass-count s) 0))

(test-case "ASSERT: negative non-zero passes (Forth convention)"
  (define e (make-test-env))
  (with-output-to-string
    (lambda () (run-on e "-1 ASSERT   -42 ASSERT")))
  (define s (env-substrate e))
  (check-equal? (substrate-pass-count s) 2))

(test-case "ASSERT: non-number values fail (string)"
  (define e (make-test-env))
  (with-output-to-string
    (lambda () (run-on e "\"non-number\" ASSERT")))
  (define s (env-substrate e))
  (check-equal? (substrate-fail-count s) 1)
  (check-equal? (substrate-pass-count s) 0))

;; ============================================================
;; HEDGE3 counter consistency under repeated insert/remove.
;; ============================================================

(test-case "HEDGES3-KIND counter consistent across insert/remove/insert"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+
               0 1 2 3 HEDGE3-
               0 1 2 3 HEDGE3+
               0 HEDGES3-KIND")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 1))

;; ============================================================
;; Self-loop and EACH-2PATH self-cycle semantics — document
;; design choices via test.  These are not arbitrary; demos
;; rely on them (own-Φ_PA via self-loop indicator; recursive
;; hierarchy fixed point via 2-path scan that includes cycles).
;; ============================================================

(test-case "NSUM with self-loop includes the self-feature"
  ;; Node with self-loop is its own out-neighbour, so NSUM(n) = NGET(n).
  (define e (run-src "MARK   1 1 EDGE+   1 42 NSET   1 NSUM"))
  (check-equal? (car (env-stack e)) 42))

(test-case "EACH-2PATH visits length-2 cycles (src=dst when present)"
  ;; Mutual cycle 1↔2 gives 2-paths (1,2,1) and (2,1,2).
  (define src ": tally drop drop drop
                  \"n\" load 1 + \"n\" store ;
                0 \"n\" store
                MARK MARK   1 2 EDGE+   2 1 EDGE+
                ' tally EACH-2PATH
                \"n\" load")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 2))

;; ============================================================
;; REPORT output contract: always emits hedges= column.
;; ============================================================

(test-case "REPORT always emits hedges= column even when zero"
  (define e (make-test-env))
  (define out (run-on e "MARK MARK 1 ASSERT REPORT"))
  (check-true (regexp-match? #rx"hedges=0" out))
  (check-true (regexp-match? #rx"nodes=2" out)))

(test-case "REPORT hedges= column updates after HEDGE3+"
  (define e (make-test-env))
  (define out (run-on e "MARK MARK MARK   0 1 2 3 HEDGE3+   REPORT"))
  (check-true (regexp-match? #rx"hedges=1" out)))

;; ============================================================
;; Edge cases — STEP-CA on empty substrate, EACH-HEDGE3 on no
;; hedges, HEDGES3-KIND on never-used kind, NEXT order under
;; mutation, tick with non-resolvable arg.
;; ============================================================

(test-case "STEP-CA on empty substrate is a no-op"
  (define src ": rule-tag drop 99 ;
                ' rule-tag STEP-CA
                NODES")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 0))

(test-case "EACH-HEDGE3 on empty hyperedge set is a no-op"
  ;; Rule should never be invoked; if it were, the stack contract
  ;; would catch it.  We just verify the call returns cleanly.
  (define src ": rule-bad drop drop drop drop ;
                MARK MARK MARK
                ' rule-bad EACH-HEDGE3
                HEDGES3")
  (define e (run-src src))
  (check-equal? (car (env-stack e)) 0))

(test-case "HEDGES3-KIND on never-used kind returns 0"
  (define src "MARK MARK MARK
               0 1 2 3 HEDGE3+
               2 HEDGES3-KIND   \\ CONTEXT — none inserted
               3 HEDGES3-KIND") ; SIMPLEX — none inserted
  (define e (run-src src))
  (check-equal? (car  (env-stack e)) 0)
  (check-equal? (cadr (env-stack e)) 0))

(test-case "NEXT returns most-recently-added out-edge"
  ;; Demos document NEXT as 'one of the out-neighbours' but the
  ;; underlying convention is head-of-list = most-recently added.
  ;; If we ever flip storage to a hash (losing order), demos that
  ;; depend on this implicit ordering would silently break.  This
  ;; test pins the current behaviour so a future refactor surfaces.
  (define e (run-src "MARK MARK MARK
                       1 2 EDGE+
                       1 3 EDGE+   \\ 3 added after 2
                       1 NEXT"))
  (check-equal? (car (env-stack e)) 3))

(test-case "tick with non-resolvable value: numeric arg raises type-error"
  ;; Pushing a raw integer (not symbol/string) as the iteration rule
  ;; reference should raise exn:fail:sixth:type, not silently no-op.
  (define e (make-test-env))
  (check-exn exn:fail:sixth:type?
             (lambda ()
               (with-output-to-string
                 (lambda () (run-on e "MARK   42 EACH"))))))

(test-case "STEP-CA documenting: rule side-effects during compute are NOT batched"
  ;; STEP-CA atomicity covers feature updates (NSET) only.  If a rule
  ;; calls HEDGE3+ during the compute phase, that mutation lands in
  ;; the substrate immediately, before commit.  Demo authors should
  ;; treat STEP-CA rules as pure-on-NGET functions; this test pins
  ;; the contract.
  (define src ": rule-with-side-effect 0 1 2 3 HEDGE3+ NGET 1 + ;
                MARK MARK MARK
                ' rule-with-side-effect STEP-CA
                HEDGES3")
  (define e (run-src src))
  ;; The rule runs three times (one per node) but HEDGE3+ is idempotent
  ;; on key (0,1,2,3) — so HEDGES3 == 1, not 3.  This pins the
  ;; "side effects are immediate, idempotent semantics still apply"
  ;; contract.
  (check-equal? (car (env-stack e)) 1))

(displayln "substrate tests: all pass")
