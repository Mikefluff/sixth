#lang racket/base

;; sixth/meta/test-harness.rkt — TEST-ONLY fixture harness for
;; constructing cand-state arrangements that cannot be produced by
;; the normal INDUCE-RUNTIME → COMMIT → PROMOTE-STABLE pipeline.
;;
;; ============================================================
;; CLAIM (audit-grade):
;;
;;   This module is NOT part of the runtime meta-semantics described
;;   in docs/META-SEMANTICS.md.  It is a TEST FIXTURE BUILDER.
;;
;;   The primitives below are registered alongside the normal Tier 1
;;   primitives but are GATED behind an explicit ENABLE-TEST-HARNESS
;;   invocation.  Any attempt to use REBIND-CAND-BODY without first
;;   calling ENABLE-TEST-HARNESS:
;;     - raises an error,
;;     - marks the targeted cand as 'contaminated (cycle 25D
;;       contamination semantics),
;;     - logs the violation to the ledger as
;;       'test-harness-violation (NOT as a law-state event).
;;
;;   On legitimate use within a test harness:
;;     - REBIND-CAND-BODY mutates env-words for an existing cand
;;     - ledger event is tagged 'test-harness-rebind
;;       (NOT 'law-mutation, NOT 'induce-runtime, NOT 'restore)
;;     - the law-hash WILL change as a structural consequence;
;;       this is correct — the test fixture's intent is to OBSERVE
;;       what the system does with an unusual configuration
;;
;;   USED ONLY TO: construct otherwise-unreachable cyclic dependency
;;   fixtures (Demo 170: cycle without external positive anchor must
;;   collapse via has-recent-load-bearing? visited-set DFS).
;;
;; ============================================================

(provide register-test-harness!)

(require racket/base
         "../env.rkt"
         "../errors.rkt"
         "../opcodes.rkt"
         "../vm.rkt"
         "runtime.rkt")

;; Per-process flag indicating test-harness is enabled.  Stored in
;; env-memory so it doesn't leak across processes or runs.
(define MEM_TEST_HARNESS_ENABLED '_test-harness-enabled)

(define (test-harness-enabled? e)
  (and (unbox (hash-ref (env-memory e) MEM_TEST_HARNESS_ENABLED (box #f)))
       #t))

(define (set-test-harness-enabled! e flag)
  (define b (hash-ref (env-memory e) MEM_TEST_HARNESS_ENABLED #f))
  (cond
    [b (set-box! b flag)]
    [else (hash-set! (env-memory e) MEM_TEST_HARNESS_ENABLED (box flag))]))

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
             'SYM
             'OTHER))]))

(define (require-list v who)
  (cond
    [(list? v) v]
    [else
     (raise (exn:fail:sixth:type
             (format "~a — `~a`: expected LIST motif, got ~v"
                     (format-srcloc (current-prim-srcloc)) who v)
             (current-continuation-marks)
             (current-prim-srcloc)
             'LIST
             'OTHER))]))

;; ENABLE-TEST-HARNESS ( -- )
;;   Sets the test-harness flag for this env.  Ledger records the
;;   transition as 'test-harness-enabled (not as a law-state event).
;;
;;   This is the explicit gate every test fixture must call before
;;   using REBIND-CAND-BODY.  Production demos do NOT call this.
(define (prim-enable-test-harness e)
  (set-test-harness-enabled! e #t)
  (define lb (hash-ref (env-memory e) '_ledger #f))
  (when lb
    (set-box! lb (cons (list 'test-harness-enabled) (unbox lb)))))

;; DISABLE-TEST-HARNESS ( -- )
;;   Clear the flag.  Test fixtures should call this at the END of
;;   the test phase to confirm subsequent code runs in production
;;   semantics.
(define (prim-disable-test-harness e)
  (set-test-harness-enabled! e #f)
  (define lb (hash-ref (env-memory e) '_ledger #f))
  (when lb
    (set-box! lb (cons (list 'test-harness-disabled) (unbox lb)))))

;; TEST-HARNESS? ( -- 0|1 )
;;   Inspection: is the flag currently set?
(define (prim-test-harness? e)
  (push! e (if (test-harness-enabled? e) 1 0)))

;; REBIND-CAND-BODY ( cand motif -- )
;;
;; Replaces the opcode body of an existing cand with `motif`'s
;; opcodes.  The motif must be expandable in the current dictionary
;; (each symbol must be a registered primitive or word).
;;
;; Cand status is preserved (not reset).  cand-bodies entry and
;; opcodes-to-cand reverse-lookup are updated atomically.  Ledger
;; event tagged 'test-harness-rebind.
;;
;; GATED: raises if test-harness is not enabled; marks the cand
;; as 'contaminated and logs 'test-harness-violation.
(define (prim-rebind-cand-body e)
  (define motif    (require-list (pop! e) 'REBIND-CAND-BODY))
  (define cand-sym (require-sym (pop! e) 'REBIND-CAND-BODY))
  (cond
    [(not (test-harness-enabled? e))
     ;; Contaminate and refuse.
     (define lb (hash-ref (env-memory e) '_ledger #f))
     (when lb
       (set-box! lb (cons (list 'test-harness-violation cand-sym
                                 'reason 'rebind-without-enable)
                          (unbox lb))))
     ;; Mark contaminated (cycle 25D semantics) so any subsequent
     ;; pipeline action on this cand fails loudly.
     (define sb (hash-ref (env-memory e) '_cand-status #f))
     (when sb
       (set-box! sb (cons (cons cand-sym 'contaminated)
                          (filter (lambda (ent) (not (eq? (car ent) cand-sym)))
                                  (unbox sb)))))
     (raise (exn:fail:sixth
             (format "~a — REBIND-CAND-BODY: test harness not enabled. cand ~a marked 'contaminated. Call ENABLE-TEST-HARNESS first."
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(null? motif)
     (raise (exn:fail:sixth
             (format "~a — REBIND-CAND-BODY: empty motif"
                     (format-srcloc (current-prim-srcloc)))
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (cand-name? cand-sym))
     (raise (exn:fail:sixth
             (format "~a — REBIND-CAND-BODY: only cand_NNN symbols may be rebound, got ~a"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (env-lookup-word e cand-sym))
     (raise (exn:fail:sixth
             (format "~a — REBIND-CAND-BODY: cand ~a not in active dict"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (motif-expandable? e motif))
     (raise (exn:fail:sixth
             (format "~a — REBIND-CAND-BODY: motif ~v not expandable (unknown symbol)"
                     (format-srcloc (current-prim-srcloc)) motif)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [else
     ;; Atomic rebind: clear old opcodes-to-cand mapping, build new
     ;; opcodes, register new word, update cand-bodies, register new
     ;; opcodes-to-cand mapping.  Status untouched.
     (define old-w (env-lookup-word e cand-sym))
     (when old-w (unregister-cand-opcodes! e (word-opcodes old-w)))
     (define new-opcodes
       (let* ([n (length motif)]
              [v (make-vector (+ n 1) #f)])
         (for ([i (in-naturals 0)]
               [sym (in-list motif)])
           (vector-set! v i (op op-CALL sym (current-prim-srcloc))))
         (vector-set! v n (op op-RET 0 (current-prim-srcloc)))
         v))
     (define new-w (word cand-sym new-opcodes (current-prim-srcloc)))
     (env-register-word! e cand-sym new-w)
     (register-cand-opcodes! e cand-sym new-opcodes)
     ;; Update cand-bodies entry (replace motif).
     (define cb (hash-ref (env-memory e) '_cand-bodies #f))
     (when cb
       (set-box! cb (cons (list cand-sym motif)
                          (filter (lambda (ent) (not (eq? (car ent) cand-sym)))
                                  (unbox cb)))))
     (define lb (hash-ref (env-memory e) '_ledger #f))
     (when lb
       (set-box! lb (cons (list 'test-harness-rebind cand-sym motif)
                          (unbox lb))))]))

;; Local helper: check motif symbols are all callable.
(define (motif-expandable? e motif)
  (andmap (lambda (sym)
            (or (env-lookup-prim e sym)
                (env-lookup-word e sym)))
          motif))

;; MOTIF-CONS ( list sym -- list )
;;   Prepend `sym` to `list` to build motif fixtures.  Test-only
;;   helper alongside REBIND-CAND-BODY: standard motif construction
;;   goes through DETECT-MOTIF-AUTO, but cyclic-dependency fixtures
;;   need a way to construct arbitrary motif lists by hand.  Safe in
;;   itself (no state mutation, no law-hash change); ungated.
(define (prim-motif-cons e)
  (define sym (require-sym (pop! e) 'MOTIF-CONS))
  (define lst (pop! e))
  (cond
    [(not (list? lst))
     (raise (exn:fail:sixth:type
             (format "~a — MOTIF-CONS: list arg (deeper on stack) must be LIST, got ~v"
                     (format-srcloc (current-prim-srcloc)) lst)
             (current-continuation-marks)
             (current-prim-srcloc)
             'LIST
             'OTHER))]
    [else (push! e (cons sym lst))]))

(define HARNESS-TABLE
  (list (cons 'ENABLE-TEST-HARNESS   prim-enable-test-harness)
        (cons 'DISABLE-TEST-HARNESS  prim-disable-test-harness)
        (cons 'TEST-HARNESS?         prim-test-harness?)
        (cons 'REBIND-CAND-BODY      prim-rebind-cand-body)
        (cons 'MOTIF-CONS            prim-motif-cons)))

(define (register-test-harness! e)
  (for ([entry (in-list HARNESS-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
