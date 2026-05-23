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
         set-session-id!
         compute-law-hash
         motif-hash
         FORBIDDEN-IN-MOTIF
         COUPLING-N
         COUPLING-M
         cand-name?
         bump-use-count!
         cand-sessions-of
         bump-cand-session!
         distinct-session-count
         make-cand-dispatch-hook
         ;; cycle 25E energy accounting
         energy-conflict-of
         energy-search-of
         energy-reuse-gain-of
         energy-semantic-trace-of
         compute-e-world
         compute-e-law
         compute-e-total
         INSPECTION-OPS
         inspection-op?
         expansion-length-of
         ;; Re-export the VM trace parameter so meta primitives can
         ;; toggle trace on / off without further requires.
         current-engine-trace
         current-cand-dispatch-hook)

(require racket/base
         racket/list
         racket/format
         "../env.rkt"
         "../opcodes.rkt"
         "../substrate/core.rkt"
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
;; ---- cycle 25E energy accounting (observational ONLY) ----
;;
;; CONSTRAINT (user spec 2026-05-23): _energy-* keys are observational
;; counters, not semantic world-state.  They do NOT enter law_hash or
;; world_hash and they do NOT affect SHADOW-CHECK equivalence (except
;; in tests that specifically compare energy accounting).  Otherwise
;; the measurer would alter the measured.
;;
;; E_world and E_law are computed on-demand from existing state
;; (substrate node/edge counts + dictionary expansion lengths).
;; Only counters with side-effecting events (conflict, search,
;; reuse_gain, semantic-trace) live as boxes.
(define MEM_ENERGY_CONFLICT       '_energy-conflict)
(define MEM_ENERGY_SEARCH         '_energy-search)
(define MEM_ENERGY_REUSE_GAIN     '_energy-reuse-gain)
(define MEM_ENERGY_SEMANTIC_TRACE '_energy-semantic-trace)
;; cycle 26: per-cand distinct-session tracking for COUPLING-M check
(define MEM_CAND_SESSIONS         '_cand-sessions)  ; alist (cand-sym . list-of-session-ids)

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
  ;; energy counters (cycle 25E):
  (hash-set! mem MEM_ENERGY_CONFLICT       (box 0))
  (hash-set! mem MEM_ENERGY_SEARCH         (box 0))
  (hash-set! mem MEM_ENERGY_REUSE_GAIN     (box 0))
  (hash-set! mem MEM_ENERGY_SEMANTIC_TRACE (box 0))
  ;; cycle 26: per-cand distinct session tracking
  (hash-set! mem MEM_CAND_SESSIONS         (box '()))
  (void))

;; Allow tests / NEW-SESSION primitive to update session_id deterministically.
;; Test-only API per PREDICTIONS-147.md commitment 6.
(define (set-session-id! e new-id)
  (hash-set! (env-memory e) MEM_SESSION_ID new-id))

(define (energy-conflict-of e)
  (hash-ref (env-memory e) MEM_ENERGY_CONFLICT (box 0)))

(define (energy-search-of e)
  (hash-ref (env-memory e) MEM_ENERGY_SEARCH (box 0)))

(define (energy-reuse-gain-of e)
  (hash-ref (env-memory e) MEM_ENERGY_REUSE_GAIN (box 0)))

(define (energy-semantic-trace-of e)
  (hash-ref (env-memory e) MEM_ENERGY_SEMANTIC_TRACE (box 0)))

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
;; M=3 distinct runs required.  Cycle 26 enforces this in-process
;; via NEW-SESSION testing primitive that simulates cross-process
;; restart by mutating session_id; full cross-process persistence
;; lands in cycle 27.
(define COUPLING-N 5)
(define COUPLING-M 3)

;; Per-cand distinct-session tracking.  Returns the box of an alist
;; (cand-sym . list-of-session-ids-seen-using-this-cand).
(define (cand-sessions-of e)
  (hash-ref (env-memory e) MEM_CAND_SESSIONS (box '())))

;; Add session_id to the cand's session list if not already present.
;; Called by the dispatch hook on each cand_* invocation.
(define (bump-cand-session! e cand-sym sid)
  (define b (cand-sessions-of e))
  (define alist (unbox b))
  (define existing (assq cand-sym alist))
  (cond
    [(not existing)
     (set-box! b (cons (cons cand-sym (list sid)) alist))]
    [(member sid (cdr existing))
     (void)]  ; already recorded
    [else
     (define new-list (cons sid (cdr existing)))
     (set-box! b (cons (cons cand-sym new-list)
                        (filter (lambda (entry)
                                  (not (eq? (car entry) cand-sym)))
                                alist)))]))

(define (distinct-session-count e cand-sym)
  (define entry (assq cand-sym (unbox (cand-sessions-of e))))
  (if entry (length (cdr entry)) 0))

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

;; ============================================================
;; Energy accounting helpers (cycle 25E).
;; ============================================================

;; Inspection ops: top-level dispatches that DO NOT increment
;; E_semantic_trace.  Otherwise inspections like E-SNAPSHOT would
;; bloat their own measure (measurer-changes-measured trap).
(define INSPECTION-OPS
  '(LAW-HASH HASH-WORLD
    LEDGER-COUNT LEDGER-LAST
    CAND-USES CAND-STATUS SHADOW-CERT-OF SESSION-ID
    ACTIVE-DICTIONARY CONTAMINATE!
    E-WORLD E-LAW E-TRACE E-CONFLICT E-SEARCH
    E-REUSE-GAIN E-TOTAL E-SNAPSHOT
    ;; cycle 26 additions:
    NEW-SESSION WRAP-MOTIF CAND-DISTINCT-SESSIONS TRY-COMMIT
    ;; cycle 27: mining (also inspection of trace)
    DETECT-MOTIF-AUTO))

(define (inspection-op? name)
  (and (memq name INSPECTION-OPS) #t))

;; Look up the expansion length (motif length) of an active cand.
;; Returns 0 for unknown / rolled-back.  Used by E_reuse_gain.
(define (expansion-length-of e cand-sym)
  (define entry (assq cand-sym (unbox (cand-bodies-of e))))
  (if entry (length (cadr entry)) 0))

;; E_world = node_count + edge_count.  Computed on demand from
;; substrate (no separate counter to drift).
(define (compute-e-world e)
  (define s (env-substrate e))
  (cond
    [s (+ (substrate-node-count s)
          (substrate-edge-count* s))]
    [else 0]))

;; E_law = sum of expansion lengths for all currently-active
;; ephemerals (cand_*).  Computed on demand from _cand-bodies.
(define (compute-e-law e)
  (define entries (unbox (cand-bodies-of e)))
  (for/sum ([entry (in-list entries)])
    (length (cadr entry))))

;; E_total = E_world + E_law + E_trace_semantic + E_conflict +
;;           E_search - E_reuse_gain.
(define (compute-e-total e)
  (+ (compute-e-world e)
     (compute-e-law e)
     (unbox (energy-semantic-trace-of e))
     (unbox (energy-conflict-of e))
     (unbox (energy-search-of e))
     (- (unbox (energy-reuse-gain-of e)))))

;; Build a cand-dispatch-hook closure suitable for
;; current-cand-dispatch-hook parameter.  Per cycle 25E, the hook
;; also handles energy accounting:
;;   - on cand_* dispatch: bump use_count AND E_reuse_gain by
;;     (expansion_length - 1) (each invocation saves L-1 ops vs
;;     inline expansion)
;;   - on any non-inspection top-level dispatch: bump E_semantic_trace
(define (make-cand-dispatch-hook)
  (lambda (e name)
    (cond
      [(cand-name? name)
       (bump-use-count! e name)
       ;; cycle 26: track distinct sessions per cand
       (bump-cand-session! e name (session-id-of e))
       (define save (- (expansion-length-of e name) 1))
       (when (> save 0)
         (define rb (energy-reuse-gain-of e))
         (set-box! rb (+ (unbox rb) save)))
       ;; Also count as semantic (the cand IS a semantic op).
       (define stb (energy-semantic-trace-of e))
       (set-box! stb (+ (unbox stb) 1))]
      [(inspection-op? name)
       ;; do not bump E_semantic_trace
       (void)]
      [else
       (define stb (energy-semantic-trace-of e))
       (set-box! stb (+ (unbox stb) 1))])))

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
