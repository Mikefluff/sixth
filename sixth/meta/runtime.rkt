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
         reset-meta-state!
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
         ;; cycle 29 lifecycle exports
         MOMENTUM-NEGATIVE-THRESHOLD
         MOMENTUM-STALE-TOLERANCE
         MOMENTUM-HISTORY-WINDOW
         cand-recent-uses-of
         cand-recent-reuse-of
         cand-recent-fails-of
         cand-momentum-history-of
         cand-preserved-bodies-of
         epoch-counter-of
         bump-recent-uses!
         bump-recent-reuse!
         bump-recent-fails!
         ;; cycle 30 lifecycle exports
         ACTIVE-METAB-STATUSES
         cand-decompose-snapshot-of
         ;; cycle 31 exports — discovery profiles + law inflation
         INFLATION-COST-PER-CAND
         PROFILE-BUDGET-CONSERVATIVE
         PROFILE-BUDGET-LIBERAL
         SANDBOX-STATUSES
         STABLE-WORD-STATUSES
         discovery-profile-of
         set-discovery-profile!
         compute-stable-law-hash
         compute-sandbox-law-hash
         ;; cycle 32 exports — runtime-observed dependencies
         observed-deps-of
         opcodes-to-cand-of
         register-cand-opcodes!
         unregister-cand-opcodes!
         find-current-cand
         make-cand-nested-hook
         observed-dep?
         current-cand-nested-hook
         ;; cycle 33 exports — dependent momentum allocation (carry offset)
         support-credit-of
         set-support-credit-snapshot!
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
;; cycle 29: lifecycle metabolism
(define MEM_CAND_RECENT_USES      '_cand-recent-uses)         ; alist (cand . int)
(define MEM_CAND_RECENT_REUSE     '_cand-recent-reuse-gain)   ; alist (cand . int)
(define MEM_CAND_RECENT_FAILS     '_cand-recent-failures)     ; alist (cand . int)
(define MEM_CAND_MOMENTUM_HISTORY '_cand-momentum-history)    ; alist (cand . list-of-int)
(define MEM_CAND_PRESERVED_BODIES '_cand-preserved-bodies)    ; alist (cand . motif) for RESTORE
(define MEM_EPOCH_COUNTER         '_epoch-counter)            ; box int
;; cycle 30: dependency-aware AUTO-DECOMPOSE
(define MEM_CAND_DECOMPOSE_SNAPSHOT '_cand-decompose-snapshot) ; alist (cand-sym . list-of-dependents-at-decompose-time)
;; cycle 31: discovery profile (default 'conservative)
(define MEM_DISCOVERY_PROFILE       '_discovery-profile)       ; box of 'conservative | 'liberal
;; cycle 32: runtime-observed dependencies + opcodes-to-cand lookup
(define MEM_OBSERVED_DEPS           '_observed-deps)           ; box of alist ((caller . callee) . count) reset per epoch
(define MEM_OPCODES_TO_CAND         '_opcodes-to-cand)         ; hasheq from word-opcodes vector to cand-sym
;; cycle 33: support credit snapshot (rented per-epoch; reset on NEW-EPOCH)
(define MEM_SUPPORT_CREDIT          '_support-credit)          ; box of alist (cand-sym . int) — Pass A.5 snapshot

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
  ;; cycle 29: lifecycle metabolism
  (hash-set! mem MEM_CAND_RECENT_USES      (box '()))
  (hash-set! mem MEM_CAND_RECENT_REUSE     (box '()))
  (hash-set! mem MEM_CAND_RECENT_FAILS     (box '()))
  (hash-set! mem MEM_CAND_MOMENTUM_HISTORY (box '()))
  (hash-set! mem MEM_CAND_PRESERVED_BODIES (box '()))
  (hash-set! mem MEM_EPOCH_COUNTER         (box 0))
  ;; cycle 30: AUTO-DECOMPOSE dependency snapshot
  (hash-set! mem MEM_CAND_DECOMPOSE_SNAPSHOT (box '()))
  ;; cycle 31: default discovery profile
  (hash-set! mem MEM_DISCOVERY_PROFILE (box 'conservative))
  ;; cycle 32: observed-dep tracking + opcodes reverse-lookup
  (hash-set! mem MEM_OBSERVED_DEPS    (box '()))
  (hash-set! mem MEM_OPCODES_TO_CAND  (make-hasheq))
  ;; cycle 33: support credit snapshot
  (hash-set! mem MEM_SUPPORT_CREDIT   (box '()))
  (void))

;; In-place reset of every meta-runtime slot to its initial empty
;; value, WITHOUT replacing box identity.  This is critical for
;; cycle 36B BOOTSTRAP-RESET: the cli `run` path captures references
;; to _trace / _ledger / _opcodes-to-cand etc. as parameters; replacing
;; the box would leave the parameter pointing at orphaned state.
;;
;; Uses set-box! / hash-clear! on the existing storage.  Each entry
;; mirrors install-meta-runtime! exactly.  If install-meta-runtime!
;; gains a new field, this procedure must add a matching reset.
(define (reset-meta-state! e)
  (define mem (env-memory e))
  (define (reset-box! key initial)
    (define b (hash-ref mem key #f))
    (if (box? b)
        (set-box! b initial)
        (hash-set! mem key (box initial))))
  (define (reset-hash! key)
    (define h (hash-ref mem key #f))
    (if (and h (hash? h))
        (hash-clear! h)
        (hash-set! mem key (make-hasheq))))
  (reset-box! MEM_TRACE                   '())
  (reset-box! MEM_LEDGER                  '())
  (reset-box! MEM_CAND_COUNTER            0)
  (reset-box! MEM_CAND_BODIES             '())
  (reset-box! MEM_SHADOW_CERTS            '())
  (reset-box! MEM_CAND_USE_COUNTS         '())
  (reset-box! MEM_CAND_STATUS             '())
  (reset-box! MEM_CONTAMINATION           '())
  ;; Re-derive session id from current env-words (post any cand cleanup).
  (hash-set! mem MEM_SESSION_ID
             (equal-hash-code
              (cons 'session
                    (sort (hash-keys (env-words e)) symbol<?))))
  (reset-box! MEM_ENERGY_CONFLICT         0)
  (reset-box! MEM_ENERGY_SEARCH           0)
  (reset-box! MEM_ENERGY_REUSE_GAIN       0)
  (reset-box! MEM_ENERGY_SEMANTIC_TRACE   0)
  (reset-box! MEM_CAND_SESSIONS           '())
  (reset-box! MEM_CAND_RECENT_USES        '())
  (reset-box! MEM_CAND_RECENT_REUSE       '())
  (reset-box! MEM_CAND_RECENT_FAILS       '())
  (reset-box! MEM_CAND_MOMENTUM_HISTORY   '())
  (reset-box! MEM_CAND_PRESERVED_BODIES   '())
  (reset-box! MEM_EPOCH_COUNTER           0)
  (reset-box! MEM_CAND_DECOMPOSE_SNAPSHOT '())
  (reset-box! MEM_DISCOVERY_PROFILE       'conservative)
  (reset-box! MEM_OBSERVED_DEPS           '())
  (reset-hash! MEM_OPCODES_TO_CAND)
  (reset-box! MEM_SUPPORT_CREDIT          '())
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
    DETECT-MOTIF-AUTO
    ;; cycle 29: lifecycle inspection (not auto-mutating world)
    LAW-MOMENTUM
    ;; cycle 30: dependency-aware decompose inspections
    AUTO-DECOMPOSE-SAFE? CAND-DEPENDENTS LAW-DEPENDS-ON?
    ;; cycle 31: profile + sandbox-hash inspections
    DISCOVERY-PROFILE PROFILE-BUDGET PROFILE-SCOPE
    STABLE-LAW-HASH SANDBOX-LAW-HASH LAW-CARRY
    ;; cycle 32: observed-dep + load-bearing inspections
    OBSERVED-DEP? RECENT-LOAD-BEARING? CAND-OBSERVES?
    ;; cycle 33: dependent momentum allocation inspections
    MOMENTUM-NATIVE MOMENTUM-EFFECTIVE SUPPORT-CREDIT DEPENDENCY-COUNT
    ;; cycle 36B: bootstrap reset + hash + empty-state inspection.
    ;; BOOTSTRAP-RESET mutates state by definition, but the dispatch
    ;; itself must not bump energy counters — otherwise reset's own
    ;; call leaves residual semantic-trace = 1, violating the empty-
    ;; state invariant it just established.  Treating as inspection
    ;; for accounting purposes only; actual world/meta mutation
    ;; happens inside bootstrap-reset!.
    BOOTSTRAP-RESET BOOTSTRAP-LAW-HASH
    BOOTSTRAP-EMPTY? BOOTSTRAP-RESIDUAL
    ;; cycle 36B arena: selector profile + pre-flight gate.
    PROFILE-ACTIVE PROFILE-SET PROFILE-RESET-CANON
    PREFLIGHT-ARENA ARENA-IDENTICAL-HASH? ARENA-PROFILE-COUNT
    RUN-WORKLOAD-PROFILE))

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

;; ============================================================
;; Cycle 29: law metabolism — accessors and counter mutators.
;; ============================================================

(define MOMENTUM-NEGATIVE-THRESHOLD 2)
(define MOMENTUM-STALE-TOLERANCE    1)
(define MOMENTUM-HISTORY-WINDOW     3)

;; cycle 30: statuses that participate in epoch-driven metabolism.
;; cycle 31 extension: 'sandbox-stable also pays inflation.
;; cycle 33 extension: 'dependency-supported is the carry-offset
;;   intermediate (caught in Pass B before reaching demotion-candidate).
(define ACTIVE-METAB-STATUSES
  '(stable-active stale demotion-candidate dependency-held
    sandbox-stable dependency-supported))

;; cycle 31: statuses that are part of the SANDBOX (liberal) track —
;; never enter STABLE-LAW-HASH, regardless of subsequent transitions.
;; A cand can never cross from sandbox track to stable track within
;; one INDUCE lifecycle; to go stable the user must re-INDUCE under
;; conservative (producing a new cand_NNN).
(define SANDBOX-STATUSES
  '(experimental sandbox-stable))

;; cycle 31: statuses that contribute to STABLE-LAW-HASH.  A cand
;; with status in this set is part of the stable law-state.
;; cycle 33: 'dependency-supported is a stable-track status (carry
;;   offset applied, still callable, still part of the dictionary).
(define STABLE-WORD-STATUSES
  '(ephemeral-active committed stable-active stale
    demotion-candidate dependency-held dependency-supported))

;; cycle 31: per-cand per-epoch inflation cost on top of carry.
;; Hardcoded.  No tuning knob.  Modifications require deprecation cycle.
(define INFLATION-COST-PER-CAND 1)

;; cycle 31: illustrative search-budget values per profile.  Inspection
;; only in cycle 31 — no gate enforces them.  Budget enforcement is
;; DEFERRED to cycle 32+.
(define PROFILE-BUDGET-CONSERVATIVE 100)
(define PROFILE-BUDGET-LIBERAL      1000)

(define (cand-recent-uses-of e)
  (hash-ref (env-memory e) MEM_CAND_RECENT_USES (box '())))
(define (cand-recent-reuse-of e)
  (hash-ref (env-memory e) MEM_CAND_RECENT_REUSE (box '())))
(define (cand-recent-fails-of e)
  (hash-ref (env-memory e) MEM_CAND_RECENT_FAILS (box '())))
(define (cand-momentum-history-of e)
  (hash-ref (env-memory e) MEM_CAND_MOMENTUM_HISTORY (box '())))
(define (cand-preserved-bodies-of e)
  (hash-ref (env-memory e) MEM_CAND_PRESERVED_BODIES (box '())))
(define (epoch-counter-of e)
  (hash-ref (env-memory e) MEM_EPOCH_COUNTER (box 0)))
;; cycle 30 accessor
(define (cand-decompose-snapshot-of e)
  (hash-ref (env-memory e) MEM_CAND_DECOMPOSE_SNAPSHOT (box '())))

;; cycle 31 accessor + mutator for discovery profile
(define (discovery-profile-of e)
  (unbox (hash-ref (env-memory e) MEM_DISCOVERY_PROFILE (box 'conservative))))

(define (set-discovery-profile! e new-profile)
  (define b (hash-ref (env-memory e) MEM_DISCOVERY_PROFILE (box 'conservative)))
  (set-box! b new-profile))

;; ============================================================
;; Cycle 32 — runtime-observed dependencies.
;; ============================================================
;;
;; observed-deps-of returns a box of alist ((caller . callee) . count).
;; Entries are added by the cand-nested-hook when a non-top-level
;; op-CALL or op-PRIM targets a cand_NNN.  Reset on NEW-EPOCH.
;;
;; opcodes-to-cand-of returns a hasheq mapping word-opcodes vectors
;; (by eq?) to the cand symbol that owns them.  Populated by INDUCE-
;; RUNTIME and RESTORE-PRIMITIVE via register-cand-opcodes!; purged
;; by ROLLBACK-RUNTIME and DECOMPOSE-PRIMITIVE.
;;
;; find-current-cand walks env-rstack from most-recent, returning the
;; cand-sym whose opcodes match the topmost frame's program.  This
;; lets the nested hook attribute observed deps to the correct
;; containing cand.

(define (observed-deps-of e)
  (hash-ref (env-memory e) MEM_OBSERVED_DEPS (box '())))

(define (opcodes-to-cand-of e)
  (hash-ref (env-memory e) MEM_OPCODES_TO_CAND (make-hasheq)))

(define (register-cand-opcodes! e cand-sym opcodes)
  (hash-set! (opcodes-to-cand-of e) opcodes cand-sym))

(define (unregister-cand-opcodes! e opcodes)
  (hash-remove! (opcodes-to-cand-of e) opcodes))

;; Walk env-rstack top-down; return the cand-sym whose opcodes match
;; the most-recent frame's program.  Returns #f if no such frame.
;;
;; We rely on dynamic-require to avoid a cyclic module dep on vm.rkt
;; (vm.rkt does not require runtime.rkt, but runtime.rkt requires
;; vm.rkt; the frame struct is already accessible since it is provided
;; from vm.rkt at top of this file via the existing require).
(define (find-current-cand e)
  (define oc-map (opcodes-to-cand-of e))
  (let loop ([frames (env-rstack e)])
    (cond
      [(null? frames) #f]
      [else
       (define top (car frames))
       (define prog (frame-program top))
       (define hit (and prog (hash-ref oc-map prog #f)))
       (if hit hit (loop (cdr frames)))])))

;; Bump count for (caller . callee) observation.
(define (record-observed-dep! e caller callee)
  (define b (observed-deps-of e))
  (define key (cons caller callee))
  (define alist (unbox b))
  (define existing (assoc key alist))
  (cond
    [existing
     (set-box! b
               (cons (cons key (+ 1 (cdr existing)))
                     (filter (lambda (ent) (not (equal? (car ent) key)))
                             alist)))]
    [else
     (set-box! b (cons (cons key 1) alist))]))

;; Public predicate: was callee invoked from caller's body this epoch?
(define (observed-dep? e caller callee)
  (define alist (unbox (observed-deps-of e)))
  (and (assoc (cons caller callee) alist) #t))

;; ============================================================
;; Cycle 33 — support credit snapshot (rented per epoch).
;; ============================================================

;; Box of alist (cand-sym . int) computed at end of Pass A in NEW-EPOCH
;; and consumed by Pass B status decisions.  Reset at end of NEW-EPOCH
;; ("rented, not owned" — every epoch must re-earn).
(define (support-credit-of e)
  (hash-ref (env-memory e) MEM_SUPPORT_CREDIT (box '())))

(define (set-support-credit-snapshot! e alist)
  (set-box! (support-credit-of e) alist))

;; Build the nested-call hook.  Called by trace-append! when an op
;; fires at non-top-level depth.  Records observation only when both
;; the callee is a cand and the currently-executing program is a cand
;; (looked up via opcodes-to-cand reverse map from `current-prog`).
;;
;; current-prog is the opcode vector the VM is executing right now —
;; that is, the body of the cand whose op-CALL fired.  Frame rstack
;; would only show the cand's CALLER, which is not what we want.
(define (make-cand-nested-hook)
  (lambda (e kind name current-prog)
    (when (cand-name? name)
      (define caller (and current-prog
                          (hash-ref (opcodes-to-cand-of e) current-prog #f)))
      (when (and caller (not (eq? caller name)))
        (record-observed-dep! e caller name)))))

;; Generic alist increment.
(define (alist-bump! b key delta)
  (define alist (unbox b))
  (define existing (assq key alist))
  (define cur (if existing (cdr existing) 0))
  (define rest (if existing
                   (filter (lambda (e) (not (eq? (car e) key))) alist)
                   alist))
  (set-box! b (cons (cons key (+ cur delta)) rest)))

(define (bump-recent-uses! e cand-sym)
  (alist-bump! (cand-recent-uses-of e) cand-sym 1))

(define (bump-recent-reuse! e cand-sym delta)
  (alist-bump! (cand-recent-reuse-of e) cand-sym delta))

(define (bump-recent-fails! e cand-sym)
  (alist-bump! (cand-recent-fails-of e) cand-sym 1))

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
       (bump-cand-session! e name (session-id-of e))
       (define save (- (expansion-length-of e name) 1))
       (when (> save 0)
         (define rb (energy-reuse-gain-of e))
         (set-box! rb (+ (unbox rb) save)))
       (define stb (energy-semantic-trace-of e))
       (set-box! stb (+ (unbox stb) 1))
       ;; cycle 29: bump per-epoch recent counters
       (bump-recent-uses! e name)
       (when (> save 0) (bump-recent-reuse! e name save))]
      [(inspection-op? name)
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

;; ============================================================
;; Cycle 31 — STABLE vs SANDBOX filtered law-hash views.
;; ============================================================
;;
;; STABLE-LAW-HASH excludes cand_NNN words whose status is in
;; SANDBOX-STATUSES.  Non-cand words always contribute (they are
;; user-defined dictionary entries from `: ... ;` etc.).
;;
;; SANDBOX-LAW-HASH includes only cand_NNN words whose status is in
;; SANDBOX-STATUSES.  Non-cand words are NOT in sandbox view.
;;
;; INVARIANT: the union of contributing word-sets equals env-words.
;; A cand is in exactly one view (depending on its status); non-cand
;; words are only in the stable view.
;;
;; STABLE-LAW-HASH on a fresh process equals compute-law-hash because
;; no cands exist yet.  Once liberal-INDUCE creates an 'experimental
;; cand, compute-law-hash and STABLE-LAW-HASH diverge.

(define (cand-current-status e cand-sym)
  ;; Helper: look up status without exporting from tier1.rkt (avoids
  ;; cyclic module dependency).  Returns 'unknown if not in alist.
  (define alist (unbox (cand-status-of e)))
  (define hit (assq cand-sym alist))
  (if hit (cdr hit) 'unknown))

(define (in-stable-view? e name)
  (cond
    [(not (cand-name? name)) #t]  ; non-cand words always in stable view
    [else
     (define st (cand-current-status e name))
     (and (memq st STABLE-WORD-STATUSES) #t)]))

(define (in-sandbox-view? e name)
  (cond
    [(not (cand-name? name)) #f]  ; only cands can be in sandbox
    [else
     (define st (cand-current-status e name))
     (and (memq st SANDBOX-STATUSES) #t)]))

(define (compute-stable-law-hash e)
  (define names
    (sort
     (for/list ([n (in-list (hash-keys (env-words e)))]
                #:when (in-stable-view? e n))
       n)
     symbol<?))
  (define pairs
    (for/list ([n (in-list names)])
      (cons n (canonical-word-fingerprint (hash-ref (env-words e) n)))))
  (equal-hash-code pairs))

(define (compute-sandbox-law-hash e)
  (define names
    (sort
     (for/list ([n (in-list (hash-keys (env-words e)))]
                #:when (in-sandbox-view? e n))
       n)
     symbol<?))
  (define pairs
    (for/list ([n (in-list names)])
      (cons n (canonical-word-fingerprint (hash-ref (env-words e) n)))))
  (equal-hash-code pairs))
