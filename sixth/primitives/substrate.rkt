#lang racket/base

;; sixth/primitives/substrate.rkt — the 23 substrate primitives.
;;
;; Wires the substrate-core operations to Sixth-callable primitives.
;; Registered via `register-substrate!` on an env that should have
;; a fresh `substrate` attached as env-substrate.

(provide register-substrate!)

(require "../env.rkt"
         "../errors.rkt"
         "../vm.rkt"
         "../values.rkt"
         "../substrate/core.rkt")

(define (pop1 e) (env-pop! e (current-prim-srcloc)))
(define (push1 e v) (env-push! e v))

(define (sub e) (env-substrate e))

;; ---- difference / pointer ----

(define (prim-MARK e)
  (push1 e (substrate-mark! (sub e))))

(define (prim-EDGE+ e)
  (define dst (pop1 e))
  (define src (pop1 e))
  (substrate-edge+! (sub e) src dst))

(define (prim-EDGE- e)
  (define dst (pop1 e))
  (define src (pop1 e))
  (substrate-edge-! (sub e) src dst))

(define (prim-EDGE? e)
  (define dst (pop1 e))
  (define src (pop1 e))
  (push1 e (if (substrate-edge? (sub e) src dst) 1 0)))

;; ---- typed trivalent hyperedges (HEDGE3) ----
;;
;; HEDGE3+/?/− take 4 stack args: kind, a, b, c (in push order).  The kind
;; integer is enforced as the first slot but is interpreted by stdlib/hedge.6th
;; (substrate stays semantics-neutral).

(define (prim-HEDGE3+ e)
  (define c    (pop1 e))
  (define b    (pop1 e))
  (define a    (pop1 e))
  (define kind (pop1 e))
  (substrate-hedge3+! (sub e) kind a b c))

(define (prim-HEDGE3- e)
  (define c    (pop1 e))
  (define b    (pop1 e))
  (define a    (pop1 e))
  (define kind (pop1 e))
  (substrate-hedge3-! (sub e) kind a b c))

(define (prim-HEDGE3? e)
  (define c    (pop1 e))
  (define b    (pop1 e))
  (define a    (pop1 e))
  (define kind (pop1 e))
  (push1 e (if (substrate-hedge3? (sub e) kind a b c) 1 0)))

(define (prim-HEDGE3-VALID? e)
  ;; Predicate-only structural validation.  No insertion, no side
  ;; effects, no exception.  Used by demos to test whether a tuple
  ;; would pass the kind's structural invariants before risking an
  ;; insert-time exn:fail:sixth:substrate.
  (define c    (pop1 e))
  (define b    (pop1 e))
  (define a    (pop1 e))
  (define kind (pop1 e))
  (push1 e (if (substrate-hedge3-valid? kind a b c) 1 0)))

(define (prim-HEDGES3 e)
  (push1 e (substrate-hedge3-count* (sub e))))

(define (prim-HEDGES3-KIND e)
  (define kind (pop1 e))
  (push1 e (substrate-hedge3-kind-count* (sub e) kind)))

(define (prim-EACH-HEDGE3 e)
  ;; Iterates all hyperedges across all kinds.  Rule receives (kind a b c)
  ;; and is expected to consume all four (net stack delta 0 from the
  ;; pre-push depth).
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define keys (substrate-hedges-snapshot s))
  (for ([key (in-list keys)])
    (define pre (env-stack-depth e))
    (push1 e (vector-ref key 0))
    (push1 e (vector-ref key 1))
    (push1 e (vector-ref key 2))
    (push1 e (vector-ref key 3))
    (call-rule! e wname loc)
    (assert-stack-delta! e pre 0 wname loc 'EACH-HEDGE3)))

(define (prim-EACH-HEDGE3-KIND e)
  ;; ( kind rule -- ).  Iterates only hyperedges of the given kind.
  ;; Rule receives (a b c) and is expected to consume all three
  ;; (net stack delta 0 from the pre-push depth).
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define kind (pop1 e))
  (define s (sub e))
  (define keys (substrate-hedges-snapshot-kind s kind))
  (for ([key (in-list keys)])
    (define pre (env-stack-depth e))
    (push1 e (vector-ref key 1))
    (push1 e (vector-ref key 2))
    (push1 e (vector-ref key 3))
    (call-rule! e wname loc)
    (assert-stack-delta! e pre 0 wname loc 'EACH-HEDGE3-KIND)))

;; ---- traversal ----

(define (prim-OUT e)
  (define n (pop1 e))
  (push1 e (substrate-out-count (sub e) n)))

(define (prim-IN e)
  (define n (pop1 e))
  (push1 e (substrate-in-count (sub e) n)))

(define (prim-NEXT e)
  (define n (pop1 e))
  (push1 e (substrate-next (sub e) n)))

(define (prim-PREV e)
  (define n (pop1 e))
  (push1 e (substrate-prev (sub e) n)))

;; ---- counts ----

(define (prim-NODES e)
  (push1 e (substrate-node-count (sub e))))

(define (prim-EDGES e)
  (push1 e (substrate-edge-count* (sub e))))

;; ---- time ----

(define (prim-STEP e) (substrate-step! (sub e)))
(define (prim-NOW  e) (push1 e (substrate-now (sub e))))
(define (prim-BORN e)
  (define n (pop1 e))
  (push1 e (substrate-born (sub e) n)))

;; ---- iteration ----
;; rule-name must be a symbol (pushed via tick) or string

(define (resolve-word-name v loc)
  (cond
    [(symbol? v) v]
    [(string? v) (string->symbol v)]
    [else
     (raise (exn:fail:sixth:type
             (format "~a — iteration: rule name must be symbol or string, got ~a"
                     (format-srcloc loc) (value-tag v))
             (current-continuation-marks)
             loc
             'sym
             (value-tag v)))]))

(define (call-rule! e wname loc)
  (define w (env-lookup-word e wname))
  (unless w
    (raise (exn:fail:sixth:unbound
            (format "~a — iteration: unknown rule `~a`" (format-srcloc loc) wname)
            (current-continuation-marks)
            loc
            wname)))
  ;; Reentrant VM call against the word's opcodes.  Push a halt-sentinel
  ;; on the rstack so the inner `run!` returns (via RET) without popping
  ;; the outer caller's return frame.
  (define ops (word-opcodes w))
  (push-halt-frame! e)
  (run! ops e))

;; Wrap a rule invocation with a stack-delta contract.  `pre-depth` is
;; the stack depth observed BEFORE the iteration pushed the rule's
;; arguments; `expected-delta` is the net stack effect the rule body
;; should produce relative to pre-depth (e.g. -3 for EACH-2PATH whose
;; rule consumes (src, mid, dst); +0 for STEP-CA whose rule consumes
;; a node id and produces its new value).  Raises exn:fail:sixth on
;; mismatch with rule name + observed-vs-expected depth so silently
;; unbalanced rules surface as a clear error at the iteration site,
;; not as cascading underflow several iterations later.
(define (assert-stack-delta! e pre-depth expected-delta wname loc prim-name)
  (define actual (env-stack-depth e))
  (define expected (+ pre-depth expected-delta))
  (unless (= actual expected)
    (raise (exn:fail:sixth
            (format "~a — ~a: rule `~a` left stack at depth ~a, expected ~a (delta ~a vs expected ~a)"
                    (format-srcloc loc) prim-name wname
                    actual expected
                    (- actual pre-depth)
                    expected-delta)
            (current-continuation-marks)
            loc))))

(define (prim-EACH e)
  ;; Rule receives ( node ) and must consume it (net delta 0 from pre).
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define max-node (substrate-node-count s))
  (for ([i (in-range 1 (+ 1 max-node))])
    (define pre (env-stack-depth e))
    (push1 e i)
    (call-rule! e wname loc)
    (assert-stack-delta! e pre 0 wname loc 'EACH)))

(define (prim-EACH-EDGE e)
  ;; Rule receives ( src dst ) and must consume both (net delta 0).
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  ;; snapshot edges first
  (define edges
    (for/fold ([acc '()]) ([(src dsts) (in-hash (substrate-out-edges s))])
      (for/fold ([a acc]) ([dst (in-list dsts)])
        (cons (cons src dst) a))))
  (for ([pair (in-list edges)])
    (define pre (env-stack-depth e))
    (push1 e (car pair))
    (push1 e (cdr pair))
    (call-rule! e wname loc)
    (assert-stack-delta! e pre 0 wname loc 'EACH-EDGE)))

(define (prim-EACH-2PATH e)
  ;; Rule receives ( src mid dst ) and must consume all three (net 0).
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define paths
    (for/fold ([acc '()]) ([(src mids) (in-hash (substrate-out-edges s))])
      (for/fold ([a1 acc]) ([mid (in-list mids)])
        (for/fold ([a2 a1]) ([dst (in-list (substrate-outs s mid))])
          (cons (list src mid dst) a2)))))
  (for ([triple (in-list paths)])
    (define pre (env-stack-depth e))
    (push1 e (car triple))
    (push1 e (cadr triple))
    (push1 e (caddr triple))
    (call-rule! e wname loc)
    (assert-stack-delta! e pre 0 wname loc 'EACH-2PATH)))

(define (prim-STEP-CA e)
  ;; Rule receives ( node ) and must produce exactly one result (net +1
  ;; from pre-push depth), which is collected as the node's next state.
  ;; Two-phase: collect all next states first, then commit via NSET so
  ;; the rule body sees PRE-step values throughout — preventing
  ;; serial-bias artefacts in CA rules.
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define max-node (substrate-node-count s))
  (define next-states
    (for/list ([i (in-range 1 (+ 1 max-node))])
      (define pre (env-stack-depth e))
      (push1 e i)
      (call-rule! e wname loc)
      (assert-stack-delta! e pre 1 wname loc 'STEP-CA)
      (cons i (pop1 e))))
  (for ([pair (in-list next-states)])
    (substrate-nset! s (car pair) (cdr pair))))

;; ---- features ----

(define (prim-NSET e)
  (define v (pop1 e))
  (define n (pop1 e))
  (substrate-nset! (sub e) n v))

(define (prim-NGET e)
  (define n (pop1 e))
  (push1 e (substrate-nget (sub e) n)))

(define (prim-NSUM e)
  (define n (pop1 e))
  (push1 e (substrate-nsum (sub e) n)))

;; ---- admin/test ----

(define (prim-ASSERT e)
  (define v (pop1 e))
  (define s (sub e))
  (define ok? (substrate-assert! s v))
  (define loc (current-prim-srcloc))
  (cond
    [ok?
     (display (format "✓ assert@~a (val=~a)~n"
                       (substrate-now s) v))]
    [else
     (display (format "✗ ASSERT FAIL at step ~a  value=~a  (~a)~n"
                       (substrate-now s) v (format-srcloc loc)))]))

(define (prim-RESET e)
  (substrate-reset! (sub e)))

(define (prim-REPORT e)
  (substrate-report (sub e)))

;; ---- world hashing ----
;;
;; HASH-WORLD ( -- hash )
;;   Computes a deterministic 64-bit-ish digest of the substrate
;;   world-state.  Sensitive to: node count, edge set (per-node
;;   sorted), hedge set.  Insensitive to node-allocation order
;;   for sets — because we sort out-edge lists before hashing.
;;
;;   Used by stdlib substrate generators to sign their output
;;   (substrates/manifest.6th expects deterministic signatures).

(define (prim-HASH-WORLD e)
  (define s (sub e))
  (define n (substrate-node-count s))
  ;; Collect per-node sorted out-edge lists; this normalises against
  ;; insertion-order variation in the edge hash.
  (define edge-summary
    (for/list ([nid (in-range n)])
      (cons nid (sort (substrate-outs s nid) <))))
  (define hedge-summary
    (sort (substrate-hedges-snapshot s)
          (lambda (a b)
            (string<? (format "~a" a) (format "~a" b)))))
  (push1 e (equal-hash-code (list n edge-summary hedge-summary))))

;; ---- registration ----

(define (register-substrate! e)
  ;; Allocate fresh substrate if not present
  (unless (env-substrate e)
    (set-env-substrate! e (make-substrate)))
  (for ([entry (in-list substrate-primitives)])
    (env-register-prim! e (car entry) (cdr entry))))

(define substrate-primitives
  (list
    (cons 'MARK         prim-MARK)
    (cons 'EDGE+        prim-EDGE+)
    (cons 'EDGE-        prim-EDGE-)
    (cons 'EDGE?        prim-EDGE?)
    (cons 'HEDGE3+      prim-HEDGE3+)
    (cons 'HEDGE3-      prim-HEDGE3-)
    (cons 'HEDGE3?      prim-HEDGE3?)
    (cons 'HEDGE3-VALID? prim-HEDGE3-VALID?)
    (cons 'HEDGES3      prim-HEDGES3)
    (cons 'HEDGES3-KIND prim-HEDGES3-KIND)
    (cons 'EACH-HEDGE3  prim-EACH-HEDGE3)
    (cons 'EACH-HEDGE3-KIND prim-EACH-HEDGE3-KIND)
    (cons 'OUT          prim-OUT)
    (cons 'IN           prim-IN)
    (cons 'NEXT         prim-NEXT)
    (cons 'PREV         prim-PREV)
    (cons 'NODES        prim-NODES)
    (cons 'EDGES        prim-EDGES)
    (cons 'STEP         prim-STEP)
    (cons 'NOW          prim-NOW)
    (cons 'BORN         prim-BORN)
    (cons 'EACH         prim-EACH)
    (cons 'EACH-EDGE    prim-EACH-EDGE)
    (cons 'EACH-2PATH   prim-EACH-2PATH)
    (cons 'STEP-CA      prim-STEP-CA)
    (cons 'NSET         prim-NSET)
    (cons 'NGET         prim-NGET)
    (cons 'NSUM         prim-NSUM)
    (cons 'ASSERT       prim-ASSERT)
    (cons 'RESET        prim-RESET)
    (cons 'REPORT       prim-REPORT)
    (cons 'HASH-WORLD   prim-HASH-WORLD)))
