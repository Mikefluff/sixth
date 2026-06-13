#lang racket/base

;; sixth/meta/triggers.rkt — Cycle 37: pattern-triggered laws.
;;
;; Binding spec: examples/PREDICTIONS-185-cycle37-reentry-first-closure.md
;;
;; The bridge between law execution (writes the WORLD) and law
;; activation (previously listened only to the TRACE).  A promoted
;; law can be bound to a graph pattern; WORLD-TICK fires bound laws
;; whose patterns are PRESENT in the hypergraph, with consume
;; semantics: matching destroys the matched elements, so persistence
;; requires that firing rebuilds trigger conditions.  A law-set that
;; maintains its own reuse this way after external dispatches stop
;; exhibits CLOSURE (the operational claim — nothing more).
;;
;; Pattern vocabulary v0 (frozen):
;;   'edge      any directed edge (a,b)      consume: delete it
;;   'path2     edges (a,b),(b,c)            consume: delete both
;;   'selfloop  edge (a,a)                   consume: delete it
;;   ('isolated-node deferred: substrate nodes are never deleted
;;    by design — validate-node! relies on monotone ids — so its
;;    consume semantics cannot be implemented without a substrate
;;    physics change.  Documented deviation from the pre-reg's v0
;;    table; requires its own cycle if ever needed.)
;;
;; Honesty constraints (binding):
;;   - Only 'stable-active laws fire (no resurrection via triggers).
;;   - Dispatch goes through try-dispatch-cand! — reuse counters
;;     bump exactly as for an external call; failures bump
;;     recent_failures; consumed elements are NOT restored on
;;     failure (failure has a real cost).
;;   - WORLD-TICK-BUDGET = 8 successful firings per tick, hard cap.
;;   - Metabolism unchanged: world-driven reuse pays the same
;;     carry + inflation taxes as external reuse.

(provide register-triggers!
         TRIGGERS-TABLE
         WORLD-TICK-BUDGET
         triggers-of)

(require racket/base
         racket/list
         "../env.rkt"
         "../errors.rkt"
         "../substrate/core.rkt"
         "../vm.rkt"
         "runtime.rkt"
         (only-in "tier1.rkt" try-dispatch-cand!))

(define (push! e v) (env-push! e v))
(define (pop! e) (env-pop! e (current-prim-srcloc)))

(define WORLD-TICK-BUDGET 8)

(define PATTERN-VOCAB '(edge path2 selfloop))

;; ---- registry ---------------------------------------------------------
;;
;; _triggers: box of alist ((cand-sym . pattern-sym) ...) in binding
;; order.  Installed by install-meta-runtime! / reset-meta-state!
;; (runtime.rkt) and checked as an empty-state axis by
;; bootstrap-state-clean? (bootstrap.rkt) per NEG-7 reset hygiene.

(define (triggers-of e)
  (hash-ref (env-memory e) '_triggers (box '())))

;; ---- pattern matching (deterministic: lowest node ids first) ----------

(define (sorted-outs s n)
  (sort (substrate-outs s n) <))

(define (find-edge s [self-only? #f])
  ;; First edge (a,b) in (a asc, b asc) order.  self-only? restricts
  ;; to a == b.
  (let loop ([a 1])
    (cond
      [(> a (substrate-node-count s)) #f]
      [else
       (define bs (sorted-outs s a))
       (define hit
         (if self-only?
             (and (member a bs) a)
             (and (pair? bs) (car bs))))
       (if hit (list a hit) (loop (+ a 1)))])))

(define (find-path2 s)
  ;; First (a,b),(b,c) in lexicographic (a,b,c) order.  a==b or
  ;; b==c (self-loops) are legitimate matches.
  (let loop ([a 1])
    (cond
      [(> a (substrate-node-count s)) #f]
      [else
       (define hit
         (for*/first ([b (in-list (sorted-outs s a))]
                      [c (in-list (sorted-outs s b))])
           (list a b c)))
       (or hit (loop (+ a 1)))])))

;; Returns #f (no match) or a thunk that consumes the matched
;; elements when called.
(define (match-pattern s pat)
  (case pat
    [(edge)
     (define m (find-edge s))
     (and m (lambda () (substrate-edge-! s (car m) (cadr m))))]
    [(selfloop)
     (define m (find-edge s #t))
     (and m (lambda () (substrate-edge-! s (car m) (cadr m))))]
    [(path2)
     (define m (find-path2 s))
     (and m (lambda ()
              (substrate-edge-! s (car m) (cadr m))
              (substrate-edge-! s (cadr m) (caddr m))))]
    [else #f]))

;; ---- status gate -------------------------------------------------------

(define (stable-active? e cand-sym)
  (define hit (assq cand-sym (unbox (cand-status-of e))))
  (and hit (eq? (cdr hit) 'stable-active)))

;; ---- primitives ---------------------------------------------------------

(define (prim-bind-trigger e)
  ;; ( pattern-sym cand-sym -- )
  (define cand (pop! e))
  (define pat  (pop! e))
  (unless (memq pat PATTERN-VOCAB)
    (raise (exn:fail:sixth
            (format "~a — BIND-TRIGGER: unknown pattern ~v (vocabulary v0: ~a)"
                    (format-srcloc (current-prim-srcloc)) pat PATTERN-VOCAB)
            (current-continuation-marks)
            (current-prim-srcloc))))
  (unless (cand-name? cand)
    (raise (exn:fail:sixth
            (format "~a — BIND-TRIGGER: ~v is not a candidate law"
                    (format-srcloc (current-prim-srcloc)) cand)
            (current-continuation-marks)
            (current-prim-srcloc))))
  (define tb (triggers-of e))
  (set-box! tb (append (unbox tb) (list (cons cand pat))))
  (define lb (ledger-of e))
  (set-box! lb (cons (list 'bind-trigger cand pat) (unbox lb))))

(define (prim-unbind-trigger e)
  ;; ( cand-sym -- )
  (define cand (pop! e))
  (define tb (triggers-of e))
  (set-box! tb (filter (lambda (b) (not (eq? (car b) cand))) (unbox tb)))
  (define lb (ledger-of e))
  (set-box! lb (cons (list 'unbind-trigger cand) (unbox lb))))

(define (prim-trigger-count e)
  (push! e (length (unbox (triggers-of e)))))

(define (prim-world-tick e)
  ;; ( -- fired-count )
  ;; Round-robin budget allocation (cycle 39A): in each round, each
  ;; binding gets at most one firing attempt; rounds repeat until
  ;; the budget is spent or a full round produced zero firings (no
  ;; work left, or every remaining binding has lost stable-active
  ;; status mid-tick).  This replaces cycle 37's greedy iteration
  ;; (per PREDICTIONS-187 cycle 39A probe; see RESULTS-187).
  ;;
  ;; Cycle 37 honesty mechanics unchanged: status gate, honest
  ;; counters via try-dispatch-cand!, consume-before-dispatch,
  ;; consumed elements not restored on failure, attempts cap.
  (define s (env-substrate e))
  (define fired 0)
  (define attempts 0)
  (define MAX-ATTEMPTS (* 4 WORLD-TICK-BUDGET))
  (let round-loop ()
    (define round-fired 0)
    (for ([binding (in-list (unbox (triggers-of e)))]
          #:break (or (>= fired WORLD-TICK-BUDGET)
                      (>= attempts MAX-ATTEMPTS)))
      (when (stable-active? e (car binding))
        (define consume! (match-pattern s (cdr binding)))
        (when consume!
          (consume!)
          (set! attempts (+ attempts 1))
          (when (try-dispatch-cand! e (car binding))
            (set! fired (+ fired 1))
            (set! round-fired (+ round-fired 1))))))
    (when (and (> round-fired 0)
               (< fired WORLD-TICK-BUDGET)
               (< attempts MAX-ATTEMPTS))
      (round-loop)))
  (define lb (ledger-of e))
  (set-box! lb (cons (list 'world-tick fired) (unbox lb)))
  (push! e fired))

;; ---- cycle 38: binding discovery ----------------------------------------
;;
;; DETECT-BINDING-AUTO mines _binding-cooccur (populated by the
;; ecological observer in runtime.rkt's cand-dispatch-hook) and
;; registers (pattern, law) bindings for every pair that crossed
;; BINDING-COOCCUR-N — provided the law is currently 'stable-active
;; and the binding is not already present.  Auto-bindings land in
;; the same _triggers registry as hand-wired ones; cycle 37 physics
;; applies unchanged.  Discovery is correlation-only and
;; deliberately permissive: the metabolism decides which discovered
;; bindings are loops and which are leaks.

(define BINDING-COOCCUR-N 5)

(define (prim-binding-cooccur e)
  ;; ( pattern-sym cand-sym -- n )
  (define cand (pop! e))
  (define pat  (pop! e))
  (define hit (assoc (cons cand pat) (unbox (binding-cooccur-of e))))
  (push! e (if hit (cdr hit) 0)))

(define (prim-detect-binding-auto e)
  ;; ( -- new-bindings-count )
  (define tb (triggers-of e))
  (define existing (unbox tb))
  (define new-bindings
    (for/list ([row (in-list (reverse (unbox (binding-cooccur-of e))))]
               #:when (and (>= (cdr row) BINDING-COOCCUR-N)
                           (stable-active? e (car (car row)))
                           (not (member (car row) existing))))
      (car row)))   ; (cand . pattern) — same shape as _triggers entries
  (for ([b (in-list new-bindings)])
    (set-box! tb (append (unbox tb) (list b)))
    (define lb (ledger-of e))
    (set-box! lb (cons (list 'auto-bind (car b) (cdr b)
                             'cooccur (cdr (assoc b (unbox (binding-cooccur-of e)))))
                       (unbox lb))))
  (push! e (length new-bindings)))

;; ---- registration -------------------------------------------------------

(define TRIGGERS-TABLE
  (list (cons 'BIND-TRIGGER        prim-bind-trigger)
        (cons 'UNBIND-TRIGGER      prim-unbind-trigger)
        (cons 'TRIGGER-COUNT       prim-trigger-count)
        (cons 'WORLD-TICK          prim-world-tick)
        (cons 'DETECT-BINDING-AUTO prim-detect-binding-auto)
        (cons 'BINDING-COOCCUR     prim-binding-cooccur)))

(define (register-triggers! e)
  (for ([entry (in-list TRIGGERS-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
