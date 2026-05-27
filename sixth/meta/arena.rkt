#lang racket/base

;; sixth/meta/arena.rkt — Cycle 36B step 7-12.
;;
;; Sandbox runtime mode + blind arena harness + pre-flight gate.
;;
;; Sixth-level primitives:
;;   PROFILE-ACTIVE        ( -- sym )      name of active selection profile
;;   PROFILE-SET           ( sym -- )      switch active profile by name
;;   PROFILE-RESET-CANON   ( -- )          restore baseline (A)
;;   PREFLIGHT-ARENA       ( -- 1/0 )      assert symmetric bootstrap hash
;;                                          across all five profiles after
;;                                          their respective BOOTSTRAP-RESET
;;   ARENA-IDENTICAL-HASH? ( -- 1/0 )      same as PREFLIGHT-ARENA but
;;                                          returns boolean without raise
;;   ARENA-PROFILE-COUNT   ( -- n )        count of defined profiles
;;
;; Sandbox semantics: PROFILE-SET / with-profile uses Racket's
;; parameterize mechanism which is dynamic-extent.  Combined with
;; BOOTSTRAP-RESET (which wipes cand_NNN from env-words), each profile
;; run in genesis-arena starts from an identical clean floor and
;; cannot leak state to the next profile's run.
;;
;; Pre-flight gate: PREFLIGHT-ARENA iterates ALL-PROFILES, for each
;; runs BOOTSTRAP-RESET and reads BOOTSTRAP-LAW-HASH.  All five
;; hashes must be identical.  On divergence: ledger event
;; 'asymmetric-bootstrap-hash + raise.  This is the operational
;; enforcement of Invariant 6 (minimal-origin fairness).

(provide register-arena!
         ARENA-TABLE)

(require racket/base
         racket/list
         "../env.rkt"
         "../errors.rkt"
         "../vm.rkt"
         "runtime.rkt"
         "profiles.rkt"
         "bootstrap.rkt"
         (only-in "../vm.rkt" run!))

(define (push! e v) (env-push! e v))
(define (pop! e) (env-pop! e (current-prim-srcloc)))

(define (lookup-profile-by-name sym)
  (findf (lambda (p) (eq? (selection-profile-name p) sym))
         ALL-PROFILES))

;; ---- PROFILE-ACTIVE --------------------------------------------------

(define (prim-profile-active e)
  (push! e (profile-name)))

;; ---- PROFILE-SET -----------------------------------------------------
;;
;; Symbol → switch active profile.  Unlike with-profile (Racket
;; dynamic-extent), this is a top-level mutation of current-profile's
;; parameter cell.  Used in NEG demos and short-extent arena calls.
;; PROFILE-RESET-CANON restores BASELINE.
(define (prim-profile-set e)
  (define sym (pop! e))
  (define p (lookup-profile-by-name sym))
  (cond
    [p (current-profile p)]
    [else
     (raise (exn:fail:sixth
             (format "PROFILE-SET: unknown profile ~v" sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]))

(define (prim-profile-reset-canon e)
  (current-profile BASELINE-PROFILE))

;; ---- PREFLIGHT-ARENA -------------------------------------------------
;;
;; For each profile in ALL-PROFILES:
;;   (a) parameterize current-profile := p
;;   (b) bootstrap-reset! e
;;   (c) collect compute-bootstrap-law-hash
;; Then assert all collected hashes are equal.
;;
;; Returns 1 on success.  On asymmetry: appends
;;   ('asymmetric-bootstrap-hash <pair-of-profile-names>)
;; to the ledger and raises exn:fail:sixth.  Per spec NEG-8.

(define (prim-preflight-arena e)
  (define hashes
    (for/list ([p (in-list ALL-PROFILES)])
      (parameterize ([current-profile p])
        (bootstrap-reset! e)
        (compute-bootstrap-law-hash e))))
  (define first-hash (car hashes))
  (define divergent
    (for/or ([p (in-list (cdr ALL-PROFILES))]
             [h (in-list (cdr hashes))])
      (and (not (= h first-hash))
           (cons (selection-profile-name (car ALL-PROFILES))
                 (selection-profile-name p)))))
  (cond
    [divergent
     ;; Append ledger event then raise.
     (define lb (ledger-of e))
     (set-box! lb (cons (list 'asymmetric-bootstrap-hash divergent)
                        (unbox lb)))
     (raise (exn:fail:sixth
             (format "PREFLIGHT-ARENA: asymmetric bootstrap hash between profiles ~v"
                     divergent)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [else
     ;; Leave runtime in a defined state: BOOTSTRAP-RESET'd, baseline
     ;; profile active.  The arena caller will switch profile and
     ;; run workload.
     (current-profile BASELINE-PROFILE)
     (bootstrap-reset! e)
     (push! e 1)]))

;; ARENA-IDENTICAL-HASH? — same check but returns 0/1 without raise.
;; Useful for demos that want to *observe* divergence without crashing.
(define (prim-arena-identical-hash? e)
  (define hashes
    (for/list ([p (in-list ALL-PROFILES)])
      (parameterize ([current-profile p])
        (bootstrap-reset! e)
        (compute-bootstrap-law-hash e))))
  (define first-hash (car hashes))
  (define ok (andmap (lambda (h) (= h first-hash)) (cdr hashes)))
  (current-profile BASELINE-PROFILE)
  (bootstrap-reset! e)
  (push! e (if ok 1 0)))

;; ---- ARENA-PROFILE-COUNT ---------------------------------------------

(define (prim-arena-profile-count e)
  (push! e (length ALL-PROFILES)))

;; ---- RUN-WORKLOAD-PROFILE -----------------------------------------
;;
;; Stack effect: ( profile-sym workload-word-sym -- cand_count promoted? )
;;
;; Driver primitive: looks up workload-word-sym in env-words, runs it
;; inside (with-profile <profile>) + BOOTSTRAP-RESET'd state, then
;; collects two summary metrics:
;;   - cand_count: count of cand_NNN entries in env-words after run
;;   - promoted?: 1 if any cand has status 'stable-active, else 0
;;
;; Metrics are computed by the frozen meta-protocol (this function),
;; NOT by the selector profile.  Selector profile data has no metric
;; computation path — operational enforcement of NEG-5.

(define (prim-run-workload-profile e)
  (define wname (pop! e))
  (define pname (pop! e))
  (define p (lookup-profile-by-name pname))
  (define w (env-lookup-word e wname))
  (unless p
    (raise (exn:fail:sixth
            (format "RUN-WORKLOAD-PROFILE: unknown profile ~v" pname)
            (current-continuation-marks)
            (current-prim-srcloc))))
  (unless w
    (raise (exn:fail:sixth
            (format "RUN-WORKLOAD-PROFILE: word ~v not defined; load workload module first"
                    wname)
            (current-continuation-marks)
            (current-prim-srcloc))))
  ;; Use dynamic-wind to ensure baseline is restored even on
  ;; workload exception (NEG-2: canon cannot stay mutated).
  (parameterize ([current-profile p])
    (bootstrap-reset! e)
    (with-handlers ([exn:fail?
                     (lambda (ex)
                       (current-profile BASELINE-PROFILE)
                       (raise ex))])
      ;; Run the workload word body.
      (run! (word-opcodes w) e)))
  ;; After dynamic extent exits, current-profile is BASELINE again
  ;; via parameterize.  Now collect metrics from the post-workload
  ;; state — BEFORE another BOOTSTRAP-RESET would wipe them.
  (define cand-count
    (for/sum ([k (in-list (hash-keys (env-words e)))]
              #:when (cand-name? k))
      1))
  (define statuses (unbox (cand-status-of e)))
  (define promoted?
    (if (for/or ([row (in-list statuses)])
          (eq? (cdr row) 'stable-active))
        1
        0))
  (push! e cand-count)
  (push! e promoted?))

;; ---- RUN-GENESIS-SEED ------------------------------------------------
;;
;; Stack effect: ( workload-word-sym -- promoted_count decomposed_count )
;;
;; Cycle 36R driver: runs a seeded blind workload under the FIXED
;; canon rule-set (no profile switching).  Captures two cross-seed
;; comparable metrics.  Detailed per-event log accumulates in
;; _ledger throughout the run.
;;
;; This primitive deliberately does NOT take a profile-sym argument.
;; Cycle 36R is about evolution under one physics, multiple starting
;; conditions — not selection-law comparison.  NEG-6 enforcement.

(define (prim-run-genesis-seed e)
  (define wname (pop! e))
  (define w (env-lookup-word e wname))
  (unless w
    (raise (exn:fail:sixth
            (format "RUN-GENESIS-SEED: word ~v not defined" wname)
            (current-continuation-marks)
            (current-prim-srcloc))))
  ;; Run under BASELINE always; no with-profile.
  (current-profile BASELINE-PROFILE)
  (bootstrap-reset! e)
  (with-handlers ([exn:fail?
                   (lambda (ex)
                     (current-profile BASELINE-PROFILE)
                     (raise ex))])
    (run! (word-opcodes w) e))
  ;; Forensic capture: count promoted and decomposed cands.
  (define statuses (unbox (cand-status-of e)))
  (define promoted-count
    (for/sum ([row (in-list statuses)]
              #:when (eq? (cdr row) 'stable-active))
      1))
  (define decomposed-count
    (for/sum ([row (in-list statuses)]
              #:when (memq (cdr row) '(decomposed rolled-back)))
      1))
  (push! e promoted-count)
  (push! e decomposed-count))

;; ---- registration ----------------------------------------------------

(define ARENA-TABLE
  (list (cons 'PROFILE-ACTIVE         prim-profile-active)
        (cons 'PROFILE-SET            prim-profile-set)
        (cons 'PROFILE-RESET-CANON    prim-profile-reset-canon)
        (cons 'PREFLIGHT-ARENA        prim-preflight-arena)
        (cons 'ARENA-IDENTICAL-HASH?  prim-arena-identical-hash?)
        (cons 'ARENA-PROFILE-COUNT    prim-arena-profile-count)
        (cons 'RUN-WORKLOAD-PROFILE   prim-run-workload-profile)
        (cons 'RUN-GENESIS-SEED       prim-run-genesis-seed)))

(define (register-arena! e)
  (for ([entry (in-list ARENA-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
