#lang racket/base

;; sixth/meta/profiles.rkt — Cycle 36B step 4: SelectionProfile struct.
;;
;; Binding spec: examples/PREDICTIONS-182-selection-law-scaffold.md
;;   §"Five named selector profiles (binding initial set)"
;;
;; A SelectionProfile is a tuple of selection-law hyperparameter
;; overrides.  BASELINE-PROFILE encodes the current canon (cycle 25-33
;; values); the four alternative profiles override individual axes.
;;
;; Routing strategy:
;;   1. current-profile parameter defaults to BASELINE-PROFILE.
;;   2. Existing modules look up hyperparameters via
;;      `(profile-inflation-cost (current-profile))` etc., instead of
;;      reading the bare constant.
;;   3. The bare constants (INFLATION-COST-PER-CAND etc.) remain
;;      exported from runtime.rkt for backwards reference, but the
;;      live read path goes through the profile accessor.
;;
;; This step lands the STRUCT + BASELINE + ALL FIVE PROFILES +
;; with-profile macro + one demonstrated routing site
;; (INFLATION-COST-PER-CAND).  Routing the remaining 8 hyperparameters
;; through their respective call sites is mechanical follow-up
;; (cycle 36B step 5 continuation) and is deferred to a follow-up
;; commit.  The struct field set is complete so no API churn is
;; required when routing the rest.
;;
;; Promotion-organic-only invariant: cycle 36 NEVER promotes a non-
;; baseline profile to canon.  with-profile temporarily binds
;; current-profile inside a dynamic extent; on exit, BASELINE-PROFILE
;; is restored.  No mutation of canon constants.

(provide (struct-out selection-profile)
         BASELINE-PROFILE
         PROFILE-A-BASELINE
         PROFILE-B-LOW-INFLATION
         PROFILE-C-HIGH-INFLATION
         PROFILE-D-LONG-MEMORY
         PROFILE-E-STRICT-COUPLING
         ALL-PROFILES
         current-profile
         with-profile
         profile-name
         profile-inflation-cost
         profile-coupling-n
         profile-coupling-m
         profile-stale-tolerance
         profile-negative-threshold
         profile-momentum-window
         profile-heldout-min-wins
         profile-budget-conservative
         profile-budget-liberal)

(require racket/base
         (for-syntax racket/base))

;; A SelectionProfile is the full 9-axis vector.  Adding a new tunable
;; would require both a field here and a routed accessor below.
(struct selection-profile
  (name                 ;; symbol — 'A 'B 'C 'D 'E
   inflation-cost       ;; integer, default 1 (cycle 31)
   coupling-n           ;; integer, default 5 (cycle 26)
   coupling-m           ;; integer, default 3 (cycle 26)
   stale-tolerance      ;; integer, default 1 (cycle 29)
   negative-threshold   ;; integer, default 2 (cycle 29)
   momentum-window      ;; integer, default 3 (cycle 29)
   heldout-min-wins     ;; integer, default 4 (cycle 28)
   budget-conservative  ;; integer, default 100 (cycle 31)
   budget-liberal)      ;; integer, default 1000 (cycle 31)
  #:transparent)

;; ---- BASELINE = current canon (cycle 25-33 values) -------------------

(define PROFILE-A-BASELINE
  (selection-profile 'A 1 5 3 1 2 3 4 100 1000))

;; Profile B: low inflation (cost = 0).  Predicts more cands survive
;; sparse usage; arena will measure whether this is real productivity
;; or noise.
(define PROFILE-B-LOW-INFLATION
  (selection-profile 'B 0 5 3 1 2 3 4 100 1000))

;; Profile C: high inflation (cost = 3).  Predicts only high-frequency
;; motifs survive; arena will measure if useful-but-modest motifs are
;; lost.
(define PROFILE-C-HIGH-INFLATION
  (selection-profile 'C 3 5 3 1 2 3 4 100 1000))

;; Profile D: long memory (momentum window 5, tolerance 2).  Slower
;; decay; arena will measure if recovery from temporary idle improves.
(define PROFILE-D-LONG-MEMORY
  (selection-profile 'D 1 5 3 2 3 5 4 100 1000))

;; Profile E: strict coupling (N=8, M=5).  Higher promotion bar;
;; arena will measure if false-positive rate drops at the cost of
;; promotion latency.
(define PROFILE-E-STRICT-COUPLING
  (selection-profile 'E 1 8 5 1 2 3 4 100 1000))

(define BASELINE-PROFILE PROFILE-A-BASELINE)

(define ALL-PROFILES
  (list PROFILE-A-BASELINE
        PROFILE-B-LOW-INFLATION
        PROFILE-C-HIGH-INFLATION
        PROFILE-D-LONG-MEMORY
        PROFILE-E-STRICT-COUPLING))

;; ---- current-profile parameter ---------------------------------------
;;
;; Dynamic-extent parameter; defaults to BASELINE.  All hyperparameter
;; lookups in cycle 25-33 modules should read through the routed
;; accessors below, which call (current-profile) internally.

(define current-profile (make-parameter BASELINE-PROFILE))

;; ---- with-profile dynamic binding ------------------------------------
;;
;; (with-profile PROFILE body ...) runs body with current-profile
;; bound to PROFILE.  On exit (normal or via exception), the parent
;; profile is restored.  Used by sandbox runtime mode (step 7) and
;; blind arena harness (step 11).

(define-syntax with-profile
  (syntax-rules ()
    [(_ profile-expr body ...)
     (parameterize ([current-profile profile-expr])
       body ...)]))

;; ---- routed accessors ------------------------------------------------
;;
;; These thunks read from the active profile.  Use these AT EVERY
;; CALL SITE that previously read the bare constant.  This is the
;; "single point of substitution" — selection law switches profile,
;; behavior follows automatically.
;;
;; Step 5 continuation: rewrite cycle 25-33 call sites to read these
;; instead of the bare constants.  Each rewrite is one-line and
;; mechanical; doing them in one sweep is the next session's job.

(define (profile-inflation-cost-active)
  (selection-profile-inflation-cost (current-profile)))

(define (profile-coupling-n-active)
  (selection-profile-coupling-n (current-profile)))

(define (profile-coupling-m-active)
  (selection-profile-coupling-m (current-profile)))

(define (profile-stale-tolerance-active)
  (selection-profile-stale-tolerance (current-profile)))

(define (profile-negative-threshold-active)
  (selection-profile-negative-threshold (current-profile)))

(define (profile-momentum-window-active)
  (selection-profile-momentum-window (current-profile)))

(define (profile-heldout-min-wins-active)
  (selection-profile-heldout-min-wins (current-profile)))

(define (profile-budget-conservative-active)
  (selection-profile-budget-conservative (current-profile)))

(define (profile-budget-liberal-active)
  (selection-profile-budget-liberal (current-profile)))

;; Public re-exports (caller-friendly names matching the existing
;; constant convention).  Use these instead of touching the struct
;; accessor directly — keeps call sites readable.
(define profile-inflation-cost      profile-inflation-cost-active)
(define profile-coupling-n          profile-coupling-n-active)
(define profile-coupling-m          profile-coupling-m-active)
(define profile-stale-tolerance     profile-stale-tolerance-active)
(define profile-negative-threshold  profile-negative-threshold-active)
(define profile-momentum-window     profile-momentum-window-active)
(define profile-heldout-min-wins    profile-heldout-min-wins-active)
(define profile-budget-conservative profile-budget-conservative-active)
(define profile-budget-liberal      profile-budget-liberal-active)

(define (profile-name)
  (selection-profile-name (current-profile)))
