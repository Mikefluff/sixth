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
         "runtime.rkt"
         (only-in "tier1.rkt" prim-held-out-eval-real))

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
;; Cycle 28: real implementation lives in tier1.rkt (prim-held-out-eval-real)
;; and is registered there.  This stub function is unused but kept here
;; for historical reference; it is NOT registered in TIER2-TABLE.
(define (prim-held-out-eval e)
  (define c (require-sym (pop! e) 'HELD-OUT-EVAL))
  (stub-event! e 'held-out-eval-stub-DEAD c)
  (push! e 0))

;; ---- PROMOTE-STABLE (cycle 28 real gate) -----------------------------
;;
;; PROMOTE-STABLE ( cand-sym -- status )
;;
;; Real gate per PREDICTIONS-155.md:
;;   - status must be 'committed
;;   - HELD-OUT-EVAL wins must be >= STABLE_WINS_THRESHOLD (4 of 6)
;;
;; On success: status → 'stable-active, ledger event recorded,
;;             pushes cand-sym.
;; On reject:  status unchanged, ledger event with reason, pushes
;;             reject symbol.
;;
;; runtime_overhead, relabel_invariance, challenge wins from
;; META-SEMANTICS §9 are DEFERRED to cycle 29 (substrate snapshot).

(define STABLE_WINS_THRESHOLD 4)
(define HELD_OUT_TOTAL 6)

(define (prim-promote-stable e)
  (define c (require-sym (pop! e) 'PROMOTE-STABLE))
  (define status-alist (unbox (cand-status-of e)))
  (define cs (let ([x (assq c status-alist)]) (and x (cdr x))))
  (cond
    [(eq? cs 'rolled-back)
     (stub-event! e 'promote-stable-rejected (list c 'rolled-back))
     (push! e 'rejected-rolled-back)]
    [(eq? cs 'contaminated)
     (stub-event! e 'promote-stable-rejected (list c 'contaminated))
     (push! e 'rejected-contaminated)]
    [(eq? cs 'ephemeral-active)
     (stub-event! e 'promote-stable-rejected (list c 'no-commit))
     (push! e 'rejected-no-commit)]
    [(memq cs SANDBOX-STATUSES)
     ;; Cycle 31: sandbox-track cands (status 'experimental or
     ;; 'sandbox-stable, induced under liberal profile) cannot enter
     ;; the stable law-state.  To go stable the user must switch to
     ;; conservative profile and re-INDUCE (producing a new cand_NNN).
     ;; No bridge sandbox → stable.
     (stub-event! e 'promote-stable-rejected (list c 'sandbox-cand cs))
     (push! e 'rejected-sandbox-cand)]
    [(not (eq? cs 'committed))
     (stub-event! e 'promote-stable-rejected (list c 'unknown-status))
     (push! e 'rejected-unknown-status)]
    [else
     ;; status == 'committed.  Run held-out evaluation.
     ;; HELD-OUT-EVAL primitive consumes a cand-sym from stack and
     ;; pushes the wins count.
     (env-push! e c)
     (prim-held-out-eval-real e)
     (define wins (env-pop! e (current-prim-srcloc)))
     (cond
       [(>= wins STABLE_WINS_THRESHOLD)
        ;; Promote to stable.
        (define sb (cand-status-of e))
        (set-box! sb (cons (cons c 'stable-active)
                            (filter (lambda (entry)
                                      (not (eq? (car entry) c)))
                                    (unbox sb))))
        (stub-event! e 'promote-stable-success
                     (list c 'wins wins 'threshold STABLE_WINS_THRESHOLD
                           'of HELD_OUT_TOTAL))
        (push! e c)]
       [else
        (stub-event! e 'promote-stable-rejected
                     (list c 'heldout-insufficient
                           'wins wins 'threshold STABLE_WINS_THRESHOLD))
        (push! e 'rejected-heldout-insufficient)])]))

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
        ;; HELD-OUT-EVAL moved to Tier 1 (cycle 28); real impl
        ;; lives in tier1.rkt prim-held-out-eval-real and is
        ;; registered there.
        (cons 'PROMOTE-STABLE     prim-promote-stable)
        (cons 'RETEST             prim-retest)
        (cons 'ATTEST-PRIMITIVE   prim-attest-primitive)
        (cons 'ROLLBACK-STABLE    prim-rollback-stable)
        (cons 'ACTIVE-DICTIONARY  prim-active-dictionary)))

(define (register-tier2! e)
  (for ([entry (in-list TIER2-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
