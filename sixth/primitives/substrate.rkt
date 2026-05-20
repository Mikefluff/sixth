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

(define (prim-EACH e)
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define max-node (substrate-node-count s))
  (for ([i (in-range 1 (+ 1 max-node))])
    (push1 e i)
    (call-rule! e wname loc)))

(define (prim-EACH-EDGE e)
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  ;; snapshot edges first
  (define edges
    (for/fold ([acc '()]) ([(src dsts) (in-hash (substrate-out-edges s))])
      (for/fold ([a acc]) ([dst (in-list dsts)])
        (cons (cons src dst) a))))
  (for ([pair (in-list edges)])
    (push1 e (car pair))
    (push1 e (cdr pair))
    (call-rule! e wname loc)))

(define (prim-EACH-2PATH e)
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define paths
    (for/fold ([acc '()]) ([(src mids) (in-hash (substrate-out-edges s))])
      (for/fold ([a1 acc]) ([mid (in-list mids)])
        (for/fold ([a2 a1]) ([dst (in-list (substrate-outs s mid))])
          (cons (list src mid dst) a2)))))
  (for ([triple (in-list paths)])
    (push1 e (car triple))
    (push1 e (cadr triple))
    (push1 e (caddr triple))
    (call-rule! e wname loc)))

(define (prim-STEP-CA e)
  (define loc (current-prim-srcloc))
  (define wname (resolve-word-name (pop1 e) loc))
  (define s (sub e))
  (define max-node (substrate-node-count s))
  ;; compute next states for all nodes
  (define next-states
    (for/list ([i (in-range 1 (+ 1 max-node))])
      (push1 e i)
      (call-rule! e wname loc)
      (cons i (pop1 e))))
  ;; commit atomically
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
    (cons 'REPORT       prim-REPORT)))
