#lang racket/base

;; sixth/meta/runtime.rkt — Tier 1 runtime context for primitive
;; induction per docs/META-SEMANTICS.md v2.
;;
;; Holds the runtime side of the 4-tuple
;;   Runtime = { world_state, law_state, trace, ledger }
;;
;; world_state is in env (existing).
;; law_state is env-words (existing dictionary).
;; trace is a box of (cons kind name) entries (in reverse order),
;;   captured by vm.rkt's current-engine-trace parameter hook.
;; ledger is a box of meta-event records (append-only).
;;
;; Provides:
;;   - install-meta-runtime! : env -> void
;;     adds underscore-prefixed _trace, _ledger, _law-hash, _cand-counter
;;     and _cand-bodies entries directly into env-memory (bypasses user
;;     guard since we use hash-set! on the raw memory hash).
;;
;;   - trace-of / ledger-of / law-hash-of / cand-counter-of / cand-bodies-of
;;     accessor helpers.
;;
;;   - compute-law-hash : env -> integer
;;     deterministic digest of current dictionary (env-words).
;;
;; The law_hash is computed on demand from env-words.  It mutates
;; whenever INDUCE-RUNTIME or ROLLBACK-RUNTIME touches the dictionary.

(provide install-meta-runtime!
         trace-of
         ledger-of
         cand-counter-of
         cand-bodies-of
         compute-law-hash
         ;; Re-export the VM trace parameter so meta primitives can
         ;; toggle trace on / off without further requires.
         current-engine-trace)

(require racket/base
         racket/list
         "../env.rkt"
         "../vm.rkt")

;; ---- in-env storage (underscore-prefixed = engine-reserved) ----

(define MEM_TRACE          '_trace)
(define MEM_LEDGER         '_ledger)
(define MEM_CAND_COUNTER   '_cand-counter)
(define MEM_CAND_BODIES    '_cand-bodies)

(define (install-meta-runtime! e)
  (define mem (env-memory e))
  ;; Hash-set! directly, bypassing env-store!'s underscore guard.
  (hash-set! mem MEM_TRACE        (box '()))
  (hash-set! mem MEM_LEDGER       (box '()))
  (hash-set! mem MEM_CAND_COUNTER (box 0))
  (hash-set! mem MEM_CAND_BODIES  (box '()))
  ;; Bind the VM trace parameter to the same box so vm.rkt's
  ;; trace-append! populates _trace.  Parameter is dynamic; this
  ;; only takes effect inside the parameterize wrap below (see
  ;; with-meta-runtime).  For top-level load_file calls, we install
  ;; through cli.rkt wrapping the load in parameterize.
  (void))

(define (trace-of e)
  (hash-ref (env-memory e) MEM_TRACE (box '())))

(define (ledger-of e)
  (hash-ref (env-memory e) MEM_LEDGER (box '())))

(define (cand-counter-of e)
  (hash-ref (env-memory e) MEM_CAND_COUNTER (box 0)))

(define (cand-bodies-of e)
  (hash-ref (env-memory e) MEM_CAND_BODIES (box '())))

;; ---- law_hash computation ----

(define (compute-law-hash e)
  ;; Deterministic digest of env-words keys.  We hash only the
  ;; dictionary key set; word body changes (would be a different
  ;; word) are irrelevant since we never mutate existing bodies.
  ;; equal-hash-code over the sorted symbol list is sufficient.
  (define keys (sort (hash-keys (env-words e)) symbol<?))
  (equal-hash-code keys))
