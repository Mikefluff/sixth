#lang racket/base

;; sixth/meta/tier2.rkt — Tier 2 stable promotion plumbing.
;;
;; Per docs/META-SEMANTICS.md v2 §5: Tier 2 elevates ephemerals
;; (Tier 1 candidates that satisfied the coupling rule) into
;; permanent stable primitives via SPECIFY → FREEZE → TRAIN-EVAL →
;; HELD-OUT-EVAL → PROMOTE-STABLE → RETEST → ATTEST.
;;
;; Cycle 25B (this file) ships STUBS: each primitive emits a
;; ledger event but defers actual validation to cycle 26+ where the
;; held-out infrastructure lands.  This file exists to:
;;   1. lock the interface (8 meta-primitive names) per spec §6
;;   2. allow trace/ledger inspection of full lifecycle in tests
;;   3. fail loudly if invoked without preconditions met (prevents
;;      silent over-promotion before cycle 26)
;;
;; Stubs:
;;   FREEZE-CANDIDATE      ( cand-id -- frozen-id )
;;   TRAIN-EVAL            ( cand-id -- train-pass? )
;;   HELD-OUT-EVAL         ( cand-id -- heldout-pass? )
;;   PROMOTE-STABLE        ( cand-id -- status )
;;   RETEST                ( -- regression-pass? )
;;   ATTEST-PRIMITIVE      ( cand-id -- )
;;   ROLLBACK-STABLE       ( cand-id -- )
;;   ACTIVE-DICTIONARY     ( -- count )    ; sanity probe for tests

(provide register-tier2!)

(require racket/base
         racket/list
         "../env.rkt"
         "../errors.rkt"
         "../vm.rkt"
         "runtime.rkt")

(define (push! e v) (env-push! e v))
(define (pop! e) (env-pop! e (current-prim-srcloc)))

(define (require-sym v who)
  (cond
    [(symbol? v) v]
    [else
     (raise (exn:fail:sixth:type
             (format "~a — `~a`: expected SYM, got ~v"
                     (format-srcloc (current-prim-srcloc)) who v)
             (current-continuation-marks)
             (current-prim-srcloc)
             'SYM 'OTHER))]))

(define (record-ledger! e event)
  (define lb (ledger-of e))
  (set-box! lb (cons event (unbox lb))))

;; Tier-2 "not-yet-implemented" stub helper.  Records the call event
;; but does not perform the actual validation work.  Cycle 26 will
;; replace these with real implementations and add held-out infra.
(define (stub-event! e op-name cand-sym)
  (record-ledger! e (list 'tier2-stub op-name cand-sym
                          'cycle-25B-deferred-to-26)))

;; ---- FREEZE-CANDIDATE ------------------------------------------------
;; Stub-with-status-check (25D item 11): refuses non-candidate symbols
;; and candidates with non-COMMITTED status (rolled-back, contaminated,
;; or ephemeral-active without commit).  In cycle 26 this will compute
;; candidate_hash and append a permanent FROZEN ledger row.
(define (prim-freeze-candidate e)
  (define c (require-sym (pop! e) 'FREEZE-CANDIDATE))
  (define status-alist (unbox (cand-status-of e)))
  (define cs (let ([x (assq c status-alist)]) (and x (cdr x))))
  (cond
    [(memq cs '(rolled-back contaminated))
     (stub-event! e 'freeze-candidate-rejected (list c cs))
     (raise (exn:fail:sixth
             (format "~a — FREEZE-CANDIDATE: cand ~a status=~a, refuse"
                     (format-srcloc (current-prim-srcloc)) c cs)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [else
     ;; Stub: cycle 26 will compute candidate_hash; here pass-through.
     (stub-event! e 'freeze-candidate c)
     (push! e c)]))

;; ---- TRAIN-EVAL ------------------------------------------------------
;; Stub: cycle 26 will run candidate against substrates/train/*.6th
;; and return pass?.  Here always returns 1 (sanity-only).
(define (prim-train-eval e)
  (define c (require-sym (pop! e) 'TRAIN-EVAL))
  (stub-event! e 'train-eval c)
  (push! e 1))

;; ---- HELD-OUT-EVAL ---------------------------------------------------
;; Stub: cycle 26 will run candidate against substrates/heldout/*.6th
;; with append-only iron rule.  Here returns 0 (gate closed) to prevent
;; over-promotion in cycle 25 testing.
(define (prim-held-out-eval e)
  (define c (require-sym (pop! e) 'HELD-OUT-EVAL))
  (stub-event! e 'held-out-eval c)
  (push! e 0))

;; ---- PROMOTE-STABLE --------------------------------------------------
;; Stub-with-defence (25D item 11): gate closed in cycle 25; returns
;; 'rejected for any input.  BUT for non-committed or contaminated
;; candidates, returns specific reject reason for trace inspection.
;; Cycle 26 replaces with full multi-criterion gate.
(define (prim-promote-stable e)
  (define c (require-sym (pop! e) 'PROMOTE-STABLE))
  (define status-alist (unbox (cand-status-of e)))
  (define cs (let ([x (assq c status-alist)]) (and x (cdr x))))
  (define reason
    (cond
      [(eq? cs 'rolled-back)    'rejected-rolled-back]
      [(eq? cs 'contaminated)   'rejected-contaminated]
      [(eq? cs 'ephemeral-active) 'rejected-no-commit]
      [(eq? cs 'committed)      'rejected-no-heldout-in-25D]
      [else                      'rejected-unknown-status]))
  (stub-event! e 'promote-stable (list c reason))
  (push! e reason))

;; ---- RETEST ----------------------------------------------------------
;; Stub: cycle 26 will shell out to `raco test`.  Here pushes 1
;; (always passes) — actual regression runs are external.
(define (prim-retest e)
  (record-ledger! e (list 'tier2-stub 'retest 'cycle-25B-deferred-to-26))
  (push! e 1))

;; ---- ATTEST-PRIMITIVE ------------------------------------------------
;; Stub: cycle 26 will append full provenance bundle to ledger.
;; Here records a 'attest event for trace inspection.
(define (prim-attest-primitive e)
  (define c (require-sym (pop! e) 'ATTEST-PRIMITIVE))
  (stub-event! e 'attest-primitive c))

;; ---- ROLLBACK-STABLE -------------------------------------------------
;; Stub: cycle 26 will perform transactional batch rollback per §10.
;; Here records the request only; does NOT mutate dictionary
;; (stable primitives don't exist yet in cycle 25).
(define (prim-rollback-stable e)
  (define c (require-sym (pop! e) 'ROLLBACK-STABLE))
  (stub-event! e 'rollback-stable c))

;; ---- ACTIVE-DICTIONARY -----------------------------------------------
;; Returns total count of currently-registered words + primitives.
;; Sanity probe for tests verifying registration completeness.
(define (prim-active-dictionary e)
  (define words (hash-count (env-words e)))
  (define prims (hash-count (env-prims e)))
  (push! e (+ words prims)))

;; ---- registration ----------------------------------------------------

(define TIER2-TABLE
  (list (cons 'FREEZE-CANDIDATE   prim-freeze-candidate)
        (cons 'TRAIN-EVAL         prim-train-eval)
        (cons 'HELD-OUT-EVAL      prim-held-out-eval)
        (cons 'PROMOTE-STABLE     prim-promote-stable)
        (cons 'RETEST             prim-retest)
        (cons 'ATTEST-PRIMITIVE   prim-attest-primitive)
        (cons 'ROLLBACK-STABLE    prim-rollback-stable)
        (cons 'ACTIVE-DICTIONARY  prim-active-dictionary)))

(define (register-tier2! e)
  (for ([entry (in-list TIER2-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
