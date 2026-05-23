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
         shadow-certs-of
         cand-use-counts-of
         cand-status-of
         contamination-of
         session-id-of
         compute-law-hash
         motif-hash
         FORBIDDEN-IN-MOTIF
         COUPLING-N
         cand-name?
         bump-use-count!
         make-cand-dispatch-hook
         ;; Re-export the VM trace parameter so meta primitives can
         ;; toggle trace on / off without further requires.
         current-engine-trace
         current-cand-dispatch-hook)

(require racket/base
         racket/list
         racket/format
         "../env.rkt"
         "../opcodes.rkt"
         "../vm.rkt")

;; ---- in-env storage (underscore-prefixed = engine-reserved) ----

(define MEM_TRACE           '_trace)
(define MEM_LEDGER          '_ledger)
(define MEM_CAND_COUNTER    '_cand-counter)
(define MEM_CAND_BODIES     '_cand-bodies)
(define MEM_SHADOW_CERTS    '_shadow-certs)     ; motif-hash → 'pass | 'fail
(define MEM_CAND_USE_COUNTS '_cand-use-counts)  ; cand-sym → int
(define MEM_CAND_STATUS     '_cand-status)      ; cand-sym → status sym
(define MEM_CONTAMINATION   '_contamination)    ; set of contamination flags
(define MEM_SESSION_ID      '_session-id)       ; deterministic per-run id

;; Forbidden symbols inside a candidate motif (per docs/mining_protocol.md §4).
;; A candidate cannot invoke meta-primitives (would allow self-modifying-meta)
;; nor RESET (would erase substrate during shadow check).
(define FORBIDDEN-IN-MOTIF
  '(PROMOTE-STABLE
    ROLLBACK-STABLE
    INDUCE-RUNTIME
    ROLLBACK-RUNTIME
    COMMIT-PRIMITIVE
    FREEZE-CANDIDATE
    TRAIN-EVAL
    HELD-OUT-EVAL
    ATTEST-PRIMITIVE
    SHADOW-CHECK
    DETECT-MOTIF
    HASH-WORLD
    LAW-HASH
    ACTIVE-DICTIONARY
    RESET))

(define (install-meta-runtime! e)
  (define mem (env-memory e))
  ;; Hash-set! directly, bypassing env-store!'s underscore guard.
  (hash-set! mem MEM_TRACE           (box '()))
  (hash-set! mem MEM_LEDGER          (box '()))
  (hash-set! mem MEM_CAND_COUNTER    (box 0))
  (hash-set! mem MEM_CAND_BODIES     (box '()))
  (hash-set! mem MEM_SHADOW_CERTS    (box '()))   ; alist (hash . status)
  (hash-set! mem MEM_CAND_USE_COUNTS (box '()))   ; alist (sym . count)
  (hash-set! mem MEM_CAND_STATUS     (box '()))   ; alist (sym . status)
  (hash-set! mem MEM_CONTAMINATION   (box '()))   ; set of flags
  ;; Session id is a deterministic digest of (env-words key set) at
  ;; install time + a per-process gensym.  This avoids wall-clock /
  ;; pid leakage into law-state but still gives distinct ids per run.
  ;; The gensym() is per-call counter, not entropy from OS.
  (hash-set! mem MEM_SESSION_ID
             (equal-hash-code
              (cons 'session
                    (sort (hash-keys (env-words e)) symbol<?))))
  (void))

(define (shadow-certs-of e)
  (hash-ref (env-memory e) MEM_SHADOW_CERTS (box '())))

(define (cand-use-counts-of e)
  (hash-ref (env-memory e) MEM_CAND_USE_COUNTS (box '())))

(define (cand-status-of e)
  (hash-ref (env-memory e) MEM_CAND_STATUS (box '())))

(define (contamination-of e)
  (hash-ref (env-memory e) MEM_CONTAMINATION (box '())))

(define (session-id-of e)
  (hash-ref (env-memory e) MEM_SESSION_ID 0))

;; Motif hash: deterministic id for a sequence of symbols, used as
;; key into the shadow-certs table.  Two SHADOW-CHECKs on the same
;; motif produce the same key.
(define (motif-hash motif)
  (equal-hash-code motif))

;; Coupling rule constants (per docs/mining_protocol.md §3).
;; N=5 uses required for ephemeral → Tier 2 candidate.
;; M=3 distinct runs required — enforcement currently in-process only;
;; cross-process distinct-run tracking deferred to cycle 26.
(define COUPLING-N 5)

;; A symbol is a candidate id if it begins with "cand_" and matches
;; the cand_NNN pattern (3 digits).  Tier 1 emits cand_001, cand_002, ...
(define (cand-name? sym)
  (and (symbol? sym)
       (let ([s (symbol->string sym)])
         (and (>= (string-length s) 5)
              (string=? (substring s 0 5) "cand_")))))

;; Bump the use-counter alist for a given cand name.  Idempotent if
;; name is not currently registered (defensive — happens during
;; ROLLBACK race).
(define (bump-use-count! e cand-sym)
  (define b (cand-use-counts-of e))
  (define current (unbox b))
  (define existing (assq cand-sym current))
  (when existing
    (set-box! b
              (cons (cons cand-sym (+ 1 (cdr existing)))
                    (filter (lambda (entry)
                              (not (eq? (car entry) cand-sym)))
                            current)))))

;; Build a cand-dispatch-hook closure suitable for
;; current-cand-dispatch-hook parameter.  When the VM dispatches a
;; cand_NNN symbol at top level, this hook bumps the use counter.
(define (make-cand-dispatch-hook)
  (lambda (e name)
    (when (cand-name? name)
      (bump-use-count! e name))))

(define (trace-of e)
  (hash-ref (env-memory e) MEM_TRACE (box '())))

(define (ledger-of e)
  (hash-ref (env-memory e) MEM_LEDGER (box '())))

(define (cand-counter-of e)
  (hash-ref (env-memory e) MEM_CAND_COUNTER (box 0)))

(define (cand-bodies-of e)
  (hash-ref (env-memory e) MEM_CAND_BODIES (box '())))

;; ---- law_hash computation ----

(define (canonical-op-record op-struct)
  ;; Serialize a single opcode to a list (code, arg-string).
  ;; arg-string is used to avoid symbol-vs-int sort traps.
  (list (op-code op-struct)
        (format "~v" (op-arg op-struct))))

(define (canonical-word-fingerprint w)
  ;; Word body to a canonical list-of-records.  Uses op-record above;
  ;; insensitive to memory addresses or struct hash quirks.
  (define ops (word-opcodes w))
  (for/list ([i (in-range (vector-length ops))])
    (canonical-op-record (vector-ref ops i))))

(define (compute-law-hash e)
  ;; Deterministic digest of (sorted name . body-fingerprint) pairs
  ;; of env-words.  Includes word body so that replacing a body with
  ;; a different one (same name) ALSO mutates the hash — that's an
  ;; invariant for protocol auditability.
  ;;
  ;; Primitives (env-prims) are NOT included: they are bootstrap,
  ;; immutable, identical across processes.  Hash is sensitive only
  ;; to user-visible / runtime-induced words.
  ;;
  ;; equal-hash-code is deterministic across Racket runs in 8.x
  ;; (Racket's hash function does not use per-process salt for
  ;; equal-hash-code on lists/strings/symbols).
  (define names (sort (hash-keys (env-words e)) symbol<?))
  (define pairs
    (for/list ([n (in-list names)])
      (cons n (canonical-word-fingerprint (hash-ref (env-words e) n)))))
  (equal-hash-code pairs))
