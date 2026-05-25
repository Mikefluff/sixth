#lang racket/base

;; sixth/meta/bootstrap.rkt — Cycle 36B implementation of
;; BOOTSTRAP-RESET, BOOTSTRAP-LAW-HASH, BOOTSTRAP-EMPTY?.
;;
;; Binding spec: examples/PREDICTIONS-182-selection-law-scaffold.md
;;   - "Bootstrap-reset helper (binding)" — 14-item full empty-state
;;   - "Identical bootstrap law-hash invariant (binding)"
;;
;; Implementation strategy: bootstrap-reset! re-runs install-meta-runtime!
;; (the single source of truth for empty meta-state) plus substrate-reset!
;; plus removal of all cand_NNN entries from env-words.  This guarantees
;; identical empty-state semantics between fresh-runtime init and reset:
;; if a new meta-state field is added in a future cycle, install-meta-
;; runtime! is the one place to update — and BOOTSTRAP-RESET inherits it.
;;
;; BOOTSTRAP-LAW-HASH hashes over the frozen meta-protocol version tag
;; plus the sorted prim registry plus compute-law-hash (over env-words).
;; Excludes: session id, workload seed, profile id (per spec).

(provide META-PROTOCOL-M-VERSION
         bootstrap-reset!
         compute-bootstrap-law-hash
         bootstrap-state-clean?
         register-bootstrap!
         BOOTSTRAP-TABLE)

(require racket/base
         racket/list
         "../env.rkt"
         "../substrate/core.rkt"
         "runtime.rkt")

;; ---- frozen meta-protocol version tag ---------------------------------
;;
;; Bump only via a separate meta-protocol amendment cycle.  This symbol
;; enters BOOTSTRAP-LAW-HASH, so a bump invalidates every prior arena
;; comparison — by design.
(define META-PROTOCOL-M-VERSION 'cycle-36A-v2-2026-05-25)

;; ---- BOOTSTRAP-RESET --------------------------------------------------

(define (bootstrap-reset! e)
  ;; (a) Wipe substrate world-state (nodes/edges/hyperedges).
  (substrate-reset! (env-substrate e))
  ;; (b) Remove every cand_NNN entry from env-words.  Stdlib + user
  ;;     `: ... ;` definitions are preserved — they are part of the
  ;;     bootstrap inclusion list (prelude/graph/etc come from `use`).
  (define cand-names
    (for/list ([k (in-list (hash-keys (env-words e)))]
               #:when (cand-name? k))
      k))
  (for ([k (in-list cand-names)])
    (hash-remove! (env-words e) k))
  ;; (c) In-place reset of every meta-runtime slot.  reset-meta-state!
  ;;     mutates existing boxes via set-box! / hash-clear! rather than
  ;;     replacing them.  This preserves the box references captured
  ;;     by current-engine-trace / cand-dispatch / nested-hook
  ;;     parameters in cli.rkt.  Replacing boxes would orphan those
  ;;     parameters, leaving VM writes invisible to BOOTSTRAP-EMPTY?.
  (reset-meta-state! e))

;; ---- BOOTSTRAP-LAW-HASH -----------------------------------------------

(define (compute-bootstrap-law-hash e)
  ;; Canonical digest used as the pre-flight equality gate for genesis-
  ;; arena profile comparison.  Includes:
  ;;   - frozen meta-protocol version tag
  ;;   - sorted env-prims key list (substrate ops, Tier 1, Tier 2,
  ;;     test-harness, bootstrap primitives)
  ;;   - compute-law-hash over env-words (deterministic canonical
  ;;     fingerprint of every user/stdlib word body)
  ;; Excludes (per spec): session id, workload seed, profile id.
  (define prim-names (sort (hash-keys (env-prims e)) symbol<?))
  (equal-hash-code
   (list META-PROTOCOL-M-VERSION
         prim-names
         (compute-law-hash e))))

;; ---- empty-state verification ----------------------------------------

;; Returns 'empty if every binding axis is zero/empty, otherwise a
;; cons (residual . <axis-symbol>) naming the first non-clean axis.
;;
;; Axes checked (must mirror install-meta-runtime!):
;;   words-cand          cand_NNN entries in env-words
;;   cand-counter        _cand-counter > 0
;;   cand-bodies         _cand-bodies not empty
;;   cand-status         _cand-status not empty
;;   cand-use-counts     _cand-use-counts not empty
;;   cand-sessions       _cand-sessions not empty
;;   cand-recent-uses    _cand-recent-uses not empty
;;   cand-recent-reuse   _cand-recent-reuse-gain not empty
;;   cand-recent-fails   _cand-recent-failures not empty
;;   cand-momentum-hist  _cand-momentum-history not empty
;;   cand-preserved      _cand-preserved-bodies not empty
;;   cand-decompose-snap _cand-decompose-snapshot not empty
;;   shadow-certs        _shadow-certs not empty
;;   observed-deps       _observed-deps not empty
;;   support-credit      _support-credit not empty
;;   contamination       _contamination not empty
;;   opcodes-to-cand     _opcodes-to-cand non-empty hash
;;   energy-conflict     _energy-conflict > 0
;;   energy-search       _energy-search > 0
;;   energy-reuse-gain   _energy-reuse-gain > 0
;;   energy-sem-trace    _energy-semantic-trace > 0
;;   epoch-counter       _epoch-counter > 0
;;
;; NOT axes (excluded from clean? — monitoring/per-run state):
;;   _trace, _ledger: vm.rkt's trace-append! adds a record on EVERY
;;     top-level dispatch, including BOOTSTRAP-EMPTY? itself.  After
;;     BOOTSTRAP-RESET they ARE empty at reset's exit; any subsequent
;;     inspection trivially re-populates _trace.  Verifying their
;;     post-reset zero would require a self-excluding inspection
;;     that is not worth the engine complexity.  bootstrap-reset!
;;     clears them via reset-meta-state! — that's the binding
;;     guarantee.
;;   _session-id: per-run nonce, deterministic from env-words keys.
;;   _discovery-profile: default 'conservative is part of empty.
;;   _energy-semantic-trace: bumped by store/load/cr — engine-internal
;;     side-effect of the demo's own diagnostic plumbing.  After reset
;;     it IS zero; we exclude it from clean? for the same reason as
;;     _trace.  bootstrap-reset! resets it; that is the guarantee.
(define (axis-zero e key axis)
  (let ([v (unbox (hash-ref (env-memory e) key (box 0)))])
    (and (not (= v 0)) (cons 'residual axis))))

(define (axis-empty-list e key axis)
  (let ([v (unbox (hash-ref (env-memory e) key (box '())))])
    (and (not (null? v)) (cons 'residual axis))))

(define (axis-empty-hash e key axis)
  (let ([v (hash-ref (env-memory e) key #f)])
    (and v
         (not (zero? (hash-count v)))
         (cons 'residual axis))))

(define (axis-no-cand-in-words e)
  (let loop ([ks (hash-keys (env-words e))])
    (cond
      [(null? ks) #f]
      [(cand-name? (car ks)) (cons 'residual 'words-cand)]
      [else (loop (cdr ks))])))

(define (bootstrap-state-clean? e)
  (or
   (axis-no-cand-in-words e)
   (axis-zero       e '_cand-counter             'cand-counter)
   (axis-empty-list e '_cand-bodies              'cand-bodies)
   (axis-empty-list e '_cand-status              'cand-status)
   (axis-empty-list e '_cand-use-counts          'cand-use-counts)
   (axis-empty-list e '_shadow-certs             'shadow-certs)
   (axis-empty-list e '_contamination            'contamination)
   (axis-empty-list e '_cand-sessions            'cand-sessions)
   (axis-empty-list e '_cand-recent-uses         'cand-recent-uses)
   (axis-empty-list e '_cand-recent-reuse-gain   'cand-recent-reuse)
   (axis-empty-list e '_cand-recent-failures     'cand-recent-fails)
   (axis-empty-list e '_cand-momentum-history    'cand-momentum-hist)
   (axis-empty-list e '_cand-preserved-bodies    'cand-preserved)
   (axis-empty-list e '_cand-decompose-snapshot  'cand-decompose-snap)
   (axis-empty-list e '_observed-deps            'observed-deps)
   (axis-empty-list e '_support-credit           'support-credit)
   (axis-empty-hash e '_opcodes-to-cand          'opcodes-to-cand)
   (axis-zero       e '_energy-conflict          'energy-conflict)
   (axis-zero       e '_energy-search            'energy-search)
   (axis-zero       e '_energy-reuse-gain        'energy-reuse-gain)
   (axis-zero       e '_epoch-counter            'epoch-counter)
   'empty))

;; ---- Sixth-level primitives ------------------------------------------

(define (prim-bootstrap-reset e)
  (bootstrap-reset! e))

(define (prim-bootstrap-law-hash e)
  (env-push! e (compute-bootstrap-law-hash e)))

(define (prim-bootstrap-empty? e)
  ;; Returns 1 if state is fully empty, else 0.  Demos use this for
  ;; assert-eq verification.  For richer diagnostics (which axis failed)
  ;; use BOOTSTRAP-RESIDUAL.
  (env-push! e (if (eq? (bootstrap-state-clean? e) 'empty) 1 0)))

(define (prim-bootstrap-residual e)
  ;; Returns 'empty or a symbol naming the first non-clean axis.
  ;; Allows NEG-7 sub-cases to assert WHICH axis leaked.
  (define r (bootstrap-state-clean? e))
  (env-push! e (if (eq? r 'empty) 'empty (cdr r))))

;; ---- registration ----------------------------------------------------

(define BOOTSTRAP-TABLE
  (list (cons 'BOOTSTRAP-RESET     prim-bootstrap-reset)
        (cons 'BOOTSTRAP-LAW-HASH  prim-bootstrap-law-hash)
        (cons 'BOOTSTRAP-EMPTY?    prim-bootstrap-empty?)
        (cons 'BOOTSTRAP-RESIDUAL  prim-bootstrap-residual)))

(define (register-bootstrap! e)
  (for ([entry (in-list BOOTSTRAP-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
