#lang racket/base

;; sixth/meta/tier1.rkt — Tier 1 ephemeral primitive induction
;; per docs/META-SEMANTICS.md v2 §4.
;;
;; Registers 6 ephemeral meta-primitives:
;;   DETECT-MOTIF        ( -- motif-list )
;;   SHADOW-CHECK        ( motif -- pass? )
;;   INDUCE-RUNTIME      ( motif -- cand-id )
;;   ROLLBACK-RUNTIME    ( cand-id -- )
;;   COMMIT-PRIMITIVE    ( cand-id -- candidate-record )
;;   LAW-HASH            ( -- hash )
;;
;; A "motif" on the Sixth stack is a LIST of symbols (word names) in
;; execution order, e.g. '(MARK MARK bi-edge).
;;
;; USE-RUNTIME is implicit: once a cand_NNN word lives in env-words,
;; standard VM dispatch (op-CALL) resolves it normally.

(provide register-tier1!
         prim-held-out-eval-real
         K_HELDOUT
         HELD-OUT-SUBSTRATES)

(require racket/list
         racket/string
         racket/format
         "../env.rkt"
         "../errors.rkt"
         "../opcodes.rkt"
         "../substrate/core.rkt"
         "../vm.rkt"
         "runtime.rkt")

;; ---- mining params (frozen here for cycle 25; will move to
;;      mining_protocol.md attestation in cycle 25C) ----
(define MOTIF_WINDOW_K 20)   ; trace window scanned by DETECT-MOTIF
(define MOTIF_REPEAT_R 3)    ; minimum repetition count
(define MOTIF_MIN_LEN 2)     ; minimum motif length
(define MOTIF_MAX_LEN 5)     ; maximum motif length

;; ---- helpers ----

(define (push! e v) (env-push! e v))
(define (pop! e)    (env-pop! e (current-prim-srcloc)))

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

(define (require-sym v who)
  (cond
    [(symbol? v) v]
    [else
     (raise (exn:fail:sixth:type
             (format "~a — `~a`: expected SYM cand id, got ~v"
                     (format-srcloc (current-prim-srcloc)) who v)
             (current-continuation-marks)
             (current-prim-srcloc)
             'SYM
             'OTHER))]))

;; ---- DETECT-MOTIF ----------------------------------------------------
;;
;; Scans the last K trace entries for ANY n-gram of length [MIN_LEN,
;; MAX_LEN] that appears R or more times as consecutive non-overlapping
;; occurrences.  Returns the LONGEST such motif (ties broken by most-
;; recent occurrence).
;;
;; If no qualifying motif found, returns empty list '().
;; ----------------------------------------------------------------------

(define (extract-recent-trace e)
  ;; trace is stored in reverse order (most recent first).
  ;; Return as forward-order list of name-symbols (drop kind).
  (define box (trace-of e))
  (define rev (unbox box))
  (define window (if (> (length rev) MOTIF_WINDOW_K)
                     (take rev MOTIF_WINDOW_K)
                     rev))
  (reverse (map cdr window)))

(define (count-nonoverlap-occurrences seq motif)
  ;; Count non-overlapping occurrences of motif anywhere in seq
  ;; (greedy left-to-right scan).
  (define mlen (length motif))
  (define slen (length seq))
  (cond
    [(or (zero? mlen) (< slen mlen)) 0]
    [else
     (let loop ([i 0] [count 0])
       (cond
         [(> (+ i mlen) slen) count]
         [(equal? (take (drop seq i) mlen) motif)
          (loop (+ i mlen) (+ count 1))]
         [else
          (loop (+ i 1) count)]))]))

(define (find-motif-of-length seq len)
  ;; Enumerate all unique n-grams of given length in seq.  Return
  ;; the most-recent one (highest starting index) whose
  ;; non-overlapping occurrence count >= MOTIF_REPEAT_R.  This
  ;; tiebreaker (most-recent) is deterministic, observable, and
  ;; prevents earlier-pattern bias.
  (define slen (length seq))
  (cond
    [(< slen len) #f]
    [else
     (let loop ([i (- slen len)] [best #f])
       (cond
         [(< i 0) best]
         [else
          (define cand (take (drop seq i) len))
          (cond
            [best (loop (- i 1) best)]      ; we already have a winner closer to tail
            [else
             (define reps (count-nonoverlap-occurrences seq cand))
             (cond
               [(>= reps MOTIF_REPEAT_R) (loop (- i 1) cand)]
               [else (loop (- i 1) #f)])])]))]))

(define (prim-detect-motif e)
  (define seq (extract-recent-trace e))
  ;; Try longest first, back off to shortest.
  (let loop ([len (min MOTIF_MAX_LEN (length seq))])
    (cond
      [(< len MOTIF_MIN_LEN)
       (push! e '())]
      [else
       (define m (find-motif-of-length seq len))
       (cond
         [m (push! e m)]
         [else (loop (- len 1))])])))

;; ============================================================
;; DETECT-MOTIF-AUTO (cycle 27B, per docs/mining_protocol.md §3-§4)
;; ============================================================
;;
;; Global mining (not tail-anchored).  Returns the GLOBAL top-1
;; candidate by (frequency desc, length desc, motif-hash asc)
;; from the recent trace window.
;;
;; Filters per frozen mining_protocol.md §4:
;;   - excludes n-grams containing FORBIDDEN-IN-MOTIF symbols
;;   - excludes n-grams containing INSPECTION-OPS symbols
;;   - length in [MOTIF_MIN_LEN=2, MOTIF_MAX_LEN=5..6]
;;   - frequency >= MOTIF_REPEAT_R=3
;;
;; Differs from DETECT-MOTIF:
;;   DETECT-MOTIF: returns the most-recent (tail-anchored) candidate
;;                 with positional preference; legacy heuristic.
;;   DETECT-MOTIF-AUTO: deterministic global search with explicit
;;                      ranking, used by automated discovery.
;; ============================================================

(define (n-gram-clean? motif)
  ;; Returns #t if motif contains no FORBIDDEN-IN-MOTIF or
  ;; INSPECTION-OPS symbols.
  (andmap (lambda (sym)
            (and (not (memq sym FORBIDDEN-IN-MOTIF))
                 (not (memq sym INSPECTION-OPS))))
          motif))

(define (enumerate-n-grams seq len)
  ;; Returns a list of distinct n-grams (as lists) of given length
  ;; present in seq.  Deduped.
  (define slen (length seq))
  (define seen (make-hash))
  (cond
    [(< slen len) '()]
    [else
     (for ([i (in-range 0 (+ 1 (- slen len)))])
       (define cand (take (drop seq i) len))
       (hash-set! seen cand #t))
     (hash-keys seen)]))

(define (find-best-motif-global seq)
  ;; Enumerate all distinct clean n-grams across all valid lengths.
  ;; For each, compute non-overlapping occurrence count.  Filter by
  ;; count >= R.  Rank by (freq desc, len desc, motif-hash asc).
  ;; Return top-1 or #f.
  (define candidates
    (for*/list ([len (in-range MOTIF_MIN_LEN (+ 1 MOTIF_MAX_LEN))]
                [ng (in-list (enumerate-n-grams seq len))]
                #:when (n-gram-clean? ng)
                #:when (>= (count-nonoverlap-occurrences seq ng)
                            MOTIF_REPEAT_R))
      (vector ng len
              (count-nonoverlap-occurrences seq ng)
              (motif-hash ng))))
  (cond
    [(null? candidates) #f]
    [else
     ;; Sort by (freq desc, len desc, hash asc).
     (define sorted
       (sort candidates
             (lambda (a b)
               (cond
                 [(> (vector-ref a 2) (vector-ref b 2)) #t]
                 [(< (vector-ref a 2) (vector-ref b 2)) #f]
                 [(> (vector-ref a 1) (vector-ref b 1)) #t]
                 [(< (vector-ref a 1) (vector-ref b 1)) #f]
                 [else (< (vector-ref a 3) (vector-ref b 3))]))))
     (vector-ref (car sorted) 0)]))

(define (prim-detect-motif-auto e)
  (define seq (extract-recent-trace e))
  (define motif (find-best-motif-global seq))
  (push! e (or motif '())))

;; ---- SHADOW-CHECK ----------------------------------------------------
;;
;; Hardened in cycle 25D per user spec items 3 + 4.
;;
;; A motif passes SHADOW-CHECK iff ALL of:
;;   - non-empty
;;   - every symbol callable (primitive OR word in active dictionary)
;;   - no symbol from FORBIDDEN-IN-MOTIF (meta-primitives + RESET).
;;     This prevents self-modifying-meta loops and shadow-time substrate
;;     wipes.
;;   - if non-empty motif, the LAW-HASH measured before and after the
;;     full sym-by-sym lookup is identical (mechanical: lookup is
;;     pure, so this is a tautology — but the check surfaces if a
;;     future SHADOW-CHECK extension introduces lookup side effects)
;;
;; On pass, SHADOW-CHECK records a CERTIFICATE in env-memory
;; `_shadow-certs`: an alist (motif-hash . 'pass).  INDUCE-RUNTIME
;; requires a matching pass certificate.
;;
;; Forbidden-symbol or expandability failure → records (motif-hash .
;; 'fail).
;; ----------------------------------------------------------------------

(define (motif-expandable? e motif)
  (andmap (lambda (sym)
            (or (env-lookup-prim e sym)
                (env-lookup-word e sym)))
          motif))

(define (motif-has-forbidden? motif)
  (ormap (lambda (sym)
           (memq sym FORBIDDEN-IN-MOTIF))
         motif))

(define (record-shadow-cert! e motif status)
  (define b (shadow-certs-of e))
  (define mh (motif-hash motif))
  (define existing (assv mh (unbox b)))
  (cond
    [existing
     ;; Re-shadowing same motif: keep first status.  Append duplicate
     ;; attempt to ledger (transparency).
     (define lb (ledger-of e))
     (set-box! lb (cons (list 'shadow-recheck mh (cdr existing) 'kept)
                         (unbox lb)))]
    [else
     (set-box! b (cons (cons mh status) (unbox b)))]))

(define (shadow-cert-status e motif)
  (define mh (motif-hash motif))
  (define hit (assv mh (unbox (shadow-certs-of e))))
  (and hit (cdr hit)))

(define (bump-energy-search! e amount)
  (define b (energy-search-of e))
  (set-box! b (+ (unbox b) amount)))

(define (bump-energy-conflict! e amount)
  (define b (energy-conflict-of e))
  (set-box! b (+ (unbox b) amount)))

(define (prim-shadow-check e)
  (define motif (require-list (pop! e) 'SHADOW-CHECK))
  (define law-before (compute-law-hash e))
  ;; Cycle 25E: every SHADOW-CHECK costs E_search proportional to
  ;; motif length (one symbol lookup per motif element).
  (bump-energy-search! e (length motif))
  (cond
    [(null? motif)
     (push! e 0)]
    [(motif-has-forbidden? motif)
     (record-shadow-cert! e motif 'fail-forbidden)
     (bump-energy-conflict! e 100)
     (push! e 0)]
    [(not (motif-expandable? e motif))
     (record-shadow-cert! e motif 'fail-unexpandable)
     (bump-energy-conflict! e 100)
     (push! e 0)]
    [else
     (define law-after (compute-law-hash e))
     (cond
       [(= law-before law-after)
        (record-shadow-cert! e motif 'pass)
        (push! e 1)]
       [else
        (record-shadow-cert! e motif 'fail-law-mutation)
        (bump-energy-conflict! e 100)
        (push! e 0)])]))

;; ---- INDUCE-RUNTIME --------------------------------------------------
;;
;; Generates cand_NNN, builds an opcode vector that executes the motif
;; sequence, registers it in env-words.  Pushes the candidate symbol on
;; the stack and appends events to trace + ledger.
;;
;; Pre-conditions checked:
;;   - motif is a non-empty list
;;   - motif expandable (i.e., would pass SHADOW-CHECK)
;; Side effect:
;;   - law_hash mutates (env-words grew)
;;   - trace gets ('induce . cand-sym) entry
;;   - ledger gets a structured event record
;; ----------------------------------------------------------------------

(define (next-cand-name e)
  (define cb (cand-counter-of e))
  (define n  (+ (unbox cb) 1))
  (set-box! cb n)
  (string->symbol (format "cand_~a" (~r-3 n))))

(define (~r-3 n)
  ;; pad to 3 digits
  (define s (number->string n))
  (string-append (make-string (max 0 (- 3 (string-length s))) #\0) s))

(define (build-motif-opcodes motif)
  ;; Each symbol becomes an op-CALL by name; final op-RET ends the word.
  (define n (length motif))
  (define v (make-vector (+ n 1) #f))
  (for ([i (in-naturals 0)]
        [name (in-list motif)])
    (vector-set! v i (op op-CALL name (current-prim-srcloc))))
  (vector-set! v n (op op-RET 0 (current-prim-srcloc)))
  v)

(define (record-ledger! e event)
  (define lb (ledger-of e))
  (set-box! lb (cons event (unbox lb))))

;; INDUCE-RUNTIME hardened cycle 25D per user spec item 4:
;; requires a passing SHADOW-CHECK certificate on the same motif.
;; No certificate, failed certificate, or wrong motif → reject.

(define (prim-induce-runtime e)
  (define motif (require-list (pop! e) 'INDUCE-RUNTIME))
  (cond
    [(null? motif)
     (raise (exn:fail:sixth
             (format "~a — INDUCE-RUNTIME: empty motif"
                     (format-srcloc (current-prim-srcloc)))
             (current-continuation-marks)
             (current-prim-srcloc)))])
  (define cert (shadow-cert-status e motif))
  (cond
    [(not cert)
     (raise (exn:fail:sixth
             (format "~a — INDUCE-RUNTIME: no SHADOW-CHECK certificate for motif ~v"
                     (format-srcloc (current-prim-srcloc)) motif)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (eq? cert 'pass))
     (raise (exn:fail:sixth
             (format "~a — INDUCE-RUNTIME: shadow certificate is ~a (require 'pass) for motif ~v"
                     (format-srcloc (current-prim-srcloc)) cert motif)
             (current-continuation-marks)
             (current-prim-srcloc)))])
  ;; Defence in depth: re-check forbidden symbols and expandability
  ;; in case the cert is stale (motif passed SHADOW-CHECK but
  ;; afterwards a primitive was removed — shouldn't happen, but if).
  (when (motif-has-forbidden? motif)
    (raise (exn:fail:sixth
            (format "~a — INDUCE-RUNTIME: motif has forbidden symbols (defence-in-depth)"
                    (format-srcloc (current-prim-srcloc)))
            (current-continuation-marks)
            (current-prim-srcloc))))
  (unless (motif-expandable? e motif)
    (raise (exn:fail:sixth
            (format "~a — INDUCE-RUNTIME: motif not expandable now (cert was stale)"
                    (format-srcloc (current-prim-srcloc)))
            (current-continuation-marks)
            (current-prim-srcloc))))
  (define cand-sym (next-cand-name e))
  (define opcodes  (build-motif-opcodes motif))
  (define w (word cand-sym opcodes (current-prim-srcloc)))
  ;; bodies registry first (so rollback can remove cleanly)
  (define bb (cand-bodies-of e))
  (set-box! bb (cons (list cand-sym motif) (unbox bb)))
  ;; status registry: candidate becomes 'ephemeral-active
  (define sb (cand-status-of e))
  (set-box! sb (cons (cons cand-sym 'ephemeral-active) (unbox sb)))
  ;; use counter initialised to 0
  (define ub (cand-use-counts-of e))
  (set-box! ub (cons (cons cand-sym 0) (unbox ub)))
  ;; law-state mutation:
  (env-register-word! e cand-sym w)
  ;; trace + ledger:
  (define b (current-engine-trace))
  (when b (set-box! b (cons (cons 'induce cand-sym) (unbox b))))
  (record-ledger! e (list 'induce-runtime cand-sym motif
                           (motif-hash motif)
                           (compute-law-hash e)
                           (session-id-of e)))
  (push! e cand-sym))

;; ---- ROLLBACK-RUNTIME ------------------------------------------------
;;
;; Removes cand_NNN from env-words.  Refuses to rollback non-cand_*
;; symbols (stable primitives are immutable from runtime per §6).
;;
;; Mutates law_hash back; appends event to trace + ledger.
;; ----------------------------------------------------------------------

;; ROLLBACK-RUNTIME hardened cycle 25D items 5 + 8:
;; transactionally removes ephemeral AND clears all derived state:
;;   - words hash entry
;;   - cand-bodies registry
;;   - cand-status alist (sets 'rolled-back instead of deleting,
;;     so re-use detection works)
;;   - use-count alist entry (deleted; count is meaningless post-rollback)
;;   - shadow certificate for that motif (so a future induce on same
;;     motif must re-pass SHADOW-CHECK — anti-rubber-stamp)
;;
;; Status before rollback recorded in ledger; non-active status
;; (e.g., already 'rolled-back) is no-op + ledger note.

(define (prim-rollback-runtime e)
  (define cand-sym (require-sym (pop! e) 'ROLLBACK-RUNTIME))
  (cond
    [(not (cand-name? cand-sym))
     (raise (exn:fail:sixth
             (format "~a — ROLLBACK-RUNTIME: cannot rollback non-candidate ~a (stable primitives immutable)"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (env-lookup-word e cand-sym))
     (record-ledger! e (list 'rollback-runtime-noop cand-sym
                              'already-absent))]
    [else
     ;; Find the motif for this cand to clear its certificate.
     (define cb (cand-bodies-of e))
     (define cand-entry (assq cand-sym (unbox cb)))
     (define motif (and cand-entry (cadr cand-entry)))
     ;; Remove from words hash.
     (hash-remove! (env-words e) cand-sym)
     ;; cand-bodies: remove entry.
     (set-box! cb (filter (lambda (entry)
                            (not (eq? (car entry) cand-sym)))
                          (unbox cb)))
     ;; cand-status: mark as rolled-back (NOT deleted — so coupling
     ;; rule + contamination checks can still see history).
     (define sb (cand-status-of e))
     (set-box! sb (cons (cons cand-sym 'rolled-back)
                         (filter (lambda (entry)
                                   (not (eq? (car entry) cand-sym)))
                                 (unbox sb))))
     ;; use-count: delete (counts are meaningless post-rollback).
     (define ub (cand-use-counts-of e))
     (set-box! ub (filter (lambda (entry)
                            (not (eq? (car entry) cand-sym)))
                          (unbox ub)))
     ;; Clear shadow certificate for this motif (anti-rubber-stamp).
     (when motif
       (define cert-b (shadow-certs-of e))
       (define mh (motif-hash motif))
       (set-box! cert-b (filter (lambda (entry)
                                  (not (= (car entry) mh)))
                                (unbox cert-b))))
     ;; Trace + ledger.
     (define b (current-engine-trace))
     (when b (set-box! b (cons (cons 'rollback cand-sym) (unbox b))))
     (record-ledger! e (list 'rollback-runtime cand-sym
                              (compute-law-hash e)
                              (session-id-of e)))]))

;; ---- COMMIT-PRIMITIVE (stub for cycle 25A) ---------------------------
;;
;; In cycle 25A, COMMIT-PRIMITIVE is a stub: it appends a
;; 'commit-primitive event to the ledger but does NOT yet implement
;; full Tier 2 SPECIFY/FREEZE/HELD-OUT-EVAL.  That's cycle 25B.
;;
;; For cycle 25A acceptance, we only need COMMIT-PRIMITIVE to:
;;   - validate the cand-sym refers to an existing ephemeral
;;   - emit a ledger record marking "ephemeral became candidate"
;;   - leave the ephemeral in active dictionary (no removal)
;; ----------------------------------------------------------------------

;; COMMIT-PRIMITIVE hardened cycle 25D items 7 + 8:
;; enforces coupling rule (N=5 uses). Refuses on:
;;   - non-candidate symbol
;;   - candidate not currently active (rolled back or never induced)
;;   - candidate status indicates rolled-back / contaminated
;;   - use-count below COUPLING-N
;;
;; M=3 distinct runs check is in-process only here (we don't have
;; cross-process session persistence yet); cycle 26 extends this.

(define (prim-commit-primitive e)
  (define cand-sym (require-sym (pop! e) 'COMMIT-PRIMITIVE))
  (define status-alist (unbox (cand-status-of e)))
  (define use-alist    (unbox (cand-use-counts-of e)))
  (define cand-status  (let ([x (assq cand-sym status-alist)])
                          (and x (cdr x))))
  (define cand-uses    (let ([x (assq cand-sym use-alist)])
                          (and x (cdr x))))
  (cond
    [(not (cand-name? cand-sym))
     (raise (exn:fail:sixth
             (format "~a — COMMIT-PRIMITIVE: not a candidate ~a"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (env-lookup-word e cand-sym))
     (raise (exn:fail:sixth
             (format "~a — COMMIT-PRIMITIVE: candidate ~a not in active dict"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(eq? cand-status 'rolled-back)
     (raise (exn:fail:sixth
             (format "~a — COMMIT-PRIMITIVE: candidate ~a was rolled-back; cannot commit"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(eq? cand-status 'contaminated)
     (raise (exn:fail:sixth
             (format "~a — COMMIT-PRIMITIVE: candidate ~a is contaminated; cannot commit"
                     (format-srcloc (current-prim-srcloc)) cand-sym)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(or (not cand-uses) (< cand-uses COUPLING-N))
     (raise (exn:fail:sixth
             (format "~a — COMMIT-PRIMITIVE: candidate ~a has only ~a uses (require >= ~a per coupling rule)"
                     (format-srcloc (current-prim-srcloc))
                     cand-sym (or cand-uses 0) COUPLING-N)
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [else
     ;; Cycle 26: enforce M=3 distinct sessions in-process.
     (define distinct-m (distinct-session-count e cand-sym))
     ;; Cycle 26: energy gate now ACTIVE (was dry-run in 25E).
     (define exp-len (expansion-length-of e cand-sym))
     (define reuse-gain (* cand-uses (max 0 (- exp-len 1))))
     (define net-delta-e (- exp-len reuse-gain))
     (define would-pass-energy (< net-delta-e 0))
     ;; Always write the energy-dry-run record for forensic.
     (record-ledger! e (list 'commit-primitive cand-sym
                              cand-uses
                              (compute-law-hash e)
                              (session-id-of e)
                              'energy-gate-active
                              (list 'law-cost exp-len
                                    'reuse-gain reuse-gain
                                    'net-delta-e net-delta-e
                                    'would-pass-energy-gate would-pass-energy
                                    'distinct-sessions distinct-m)))
     (cond
       [(< distinct-m COUPLING-M)
        (raise (exn:fail:sixth
                (format "~a — COMMIT-PRIMITIVE: candidate ~a used in ~a distinct sessions (require >= ~a per coupling rule)"
                        (format-srcloc (current-prim-srcloc))
                        cand-sym distinct-m COUPLING-M)
                (current-continuation-marks)
                (current-prim-srcloc)))]
       [(not would-pass-energy)
        (raise (exn:fail:sixth
                (format "~a — COMMIT-PRIMITIVE: candidate ~a not energetically justified (net delta_e=~a, require < 0; law_cost=~a, reuse_gain=~a)"
                        (format-srcloc (current-prim-srcloc))
                        cand-sym net-delta-e exp-len reuse-gain)
                (current-continuation-marks)
                (current-prim-srcloc)))]
       [else
        ;; Promote ephemeral-active → committed (next stop: Tier 2 SPECIFY).
        (define sb (cand-status-of e))
        (set-box! sb (cons (cons cand-sym 'committed)
                            (filter (lambda (entry)
                                      (not (eq? (car entry) cand-sym)))
                                    (unbox sb))))
        (push! e cand-sym)])]))

;; ---- LAW-HASH --------------------------------------------------------

(define (prim-law-hash e)
  (push! e (compute-law-hash e)))

;; ---- inspection primitives (cycle 25D items 8, 9, 10) ----------------
;;
;; LEDGER-COUNT       ( -- n )         number of meta events recorded
;; LEDGER-LAST        ( -- event-list ) most recent event as a LIST
;; CAND-USES          ( cand -- n )    use-count of an ephemeral
;; CAND-STATUS        ( cand -- sym )  status sym: 'ephemeral-active,
;;                                       'committed, 'rolled-back,
;;                                       'contaminated, or 'unknown
;; SHADOW-CERT-OF     ( motif -- sym ) cert status sym: 'pass,
;;                                       'fail-forbidden,
;;                                       'fail-unexpandable,
;;                                       'fail-law-mutation, or 'none
;; SESSION-ID         ( -- n )         current runtime session id
;; CONTAMINATE!       ( cand reason -- ) flag a candidate contaminated
;;                                       (testing/forensic use)
;;
;; These are designed for assertions in test demos that need to inspect
;; internal state without raw Racket access.

(define (prim-ledger-count e)
  (push! e (length (unbox (ledger-of e)))))

(define (prim-ledger-last e)
  (define l (unbox (ledger-of e)))
  (cond
    [(null? l) (push! e '())]
    [else      (push! e (car l))]))

(define (prim-cand-uses e)
  (define c (require-sym (pop! e) 'CAND-USES))
  (define x (assq c (unbox (cand-use-counts-of e))))
  (push! e (if x (cdr x) 0)))

(define (prim-cand-status e)
  (define c (require-sym (pop! e) 'CAND-STATUS))
  (define x (assq c (unbox (cand-status-of e))))
  (push! e (if x (cdr x) 'unknown)))

(define (prim-shadow-cert-of e)
  (define motif (require-list (pop! e) 'SHADOW-CERT-OF))
  (define s (shadow-cert-status e motif))
  (push! e (or s 'none)))

(define (prim-session-id e)
  (push! e (session-id-of e)))

(define (prim-contaminate! e)
  (define reason (pop! e))
  (define c (require-sym (pop! e) 'CONTAMINATE!))
  (define sb (cand-status-of e))
  (set-box! sb (cons (cons c 'contaminated)
                      (filter (lambda (entry)
                                (not (eq? (car entry) c)))
                              (unbox sb))))
  ;; cycle 25E: invariant violation += 1000 to E_conflict.
  (define eb (energy-conflict-of e))
  (set-box! eb (+ (unbox eb) 1000))
  (record-ledger! e (list 'contamination c reason
                           (compute-law-hash e)
                           (session-id-of e))))

;; ============================================================
;; Energy inspection primitives (cycle 25E, item 16-20 hardening).
;; All 8 are INSPECTION-OPS — they read counters without bumping
;; E_semantic_trace.  The dispatch hook in runtime.rkt enforces
;; the inspection exemption.
;; ============================================================

(define (prim-e-world e)
  (push! e (compute-e-world e)))

(define (prim-e-law e)
  (push! e (compute-e-law e)))

(define (prim-e-trace e)
  (push! e (unbox (energy-semantic-trace-of e))))

(define (prim-e-conflict e)
  (push! e (unbox (energy-conflict-of e))))

(define (prim-e-search e)
  (push! e (unbox (energy-search-of e))))

(define (prim-e-reuse-gain e)
  (push! e (unbox (energy-reuse-gain-of e))))

(define (prim-e-total e)
  (push! e (compute-e-total e)))

;; E-SNAPSHOT ( -- list ) pushes a single LIST containing all
;; components + world_hash + law_hash + session_id + step.
;; Format (positional):
;;   (E_world E_law E_trace E_conflict E_search E_reuse_gain
;;    E_total world_hash law_hash session_id)
;; Step (substrate-now) is omitted — substrate's step counter is
;; world-state, observable via NOW separately.
(define (prim-e-snapshot e)
  (define w   (compute-e-world e))
  (define l   (compute-e-law e))
  (define tr  (unbox (energy-semantic-trace-of e)))
  (define cf  (unbox (energy-conflict-of e)))
  (define sr  (unbox (energy-search-of e)))
  (define rg  (unbox (energy-reuse-gain-of e)))
  (define tot (compute-e-total e))
  ;; compute hashes locally — these are inspection, do not mutate.
  (define wh  (require-hash-world e))
  (define lh  (compute-law-hash e))
  (define sid (session-id-of e))
  (push! e (list w l tr cf sr rg tot wh lh sid)))

;; ---- cycle 26 additions ----
;;
;; NEW-SESSION ( -- )  test primitive: increment session_id by 1.
;;   Simulates "process restart" within one demo run.  Per
;;   PREDICTIONS-147.md commitment 6: test-only, cycle 27 replaces
;;   with cross-process persistence and removes this primitive.
;;
;; WRAP-MOTIF ( sym -- list )  helper: wrap a single symbol in
;;   a 1-element LIST.  DETECT-MOTIF cannot produce length-1 motifs
;;   (MIN_LEN=2 in mining_protocol.md §3) so this lets test demos
;;   construct known-input negative motifs.
;;
;; CAND-DISTINCT-SESSIONS ( cand -- n )  inspection: number of
;;   distinct session_ids that have invoked this candidate.

(define (prim-new-session e)
  (set-session-id! e (+ 1 (session-id-of e))))

(define (prim-wrap-motif e)
  (define s (require-sym (pop! e) 'WRAP-MOTIF))
  (push! e (list s)))

(define (prim-cand-distinct-sessions e)
  (define c (require-sym (pop! e) 'CAND-DISTINCT-SESSIONS))
  (push! e (distinct-session-count e c)))

;; ============================================================
;; Cycle 29 — Law Metabolism
;; ============================================================

(define (set-status! e cand-sym new-status)
  (define sb (cand-status-of e))
  (set-box! sb (cons (cons cand-sym new-status)
                      (filter (lambda (ent) (not (eq? (car ent) cand-sym)))
                              (unbox sb)))))

(define (get-status e cand-sym)
  (define x (assq cand-sym (unbox (cand-status-of e))))
  (if x (cdr x) 'unknown))

(define (alist-lookup b key) (let ([x (assq key (unbox b))]) (if x (cdr x) 0)))

(define (compute-momentum-for e cand-sym)
  (define reuse (alist-lookup (cand-recent-reuse-of e) cand-sym))
  (define fails (alist-lookup (cand-recent-fails-of e) cand-sym))
  (define carry (expansion-length-of e cand-sym))
  (- reuse carry fails))

(define (prim-law-momentum e)
  (define c (require-sym (pop! e) 'LAW-MOMENTUM))
  (push! e (compute-momentum-for e c)))

;; NEW-EPOCH: compute momentum for all active cands, push to history,
;; transition statuses, reset recent counters.
(define (prim-new-epoch e)
  (define ec (epoch-counter-of e))
  (set-box! ec (+ 1 (unbox ec)))
  ;; Build list of cands currently in bodies that have statuses we care about
  (for ([entry (in-list (unbox (cand-bodies-of e)))])
    (define cand-sym (car entry))
    (define st (get-status e cand-sym))
    (when (memq st '(stable-active stale demotion-candidate))
      (define m (compute-momentum-for e cand-sym))
      (define hb (cand-momentum-history-of e))
      (define cur-hist (or (let ([x (assq cand-sym (unbox hb))])
                             (and x (cdr x))) '()))
      (define new-hist
        (let ([h (cons m cur-hist)])
          (if (> (length h) MOMENTUM-HISTORY-WINDOW)
              (take h MOMENTUM-HISTORY-WINDOW)
              h)))
      (set-box! hb (cons (cons cand-sym new-hist)
                          (filter (lambda (ent) (not (eq? (car ent) cand-sym)))
                                  (unbox hb))))
      ;; Status transition
      (cond
        [(> m MOMENTUM-STALE-TOLERANCE)
         (set-status! e cand-sym 'stable-active)]
        [(<= (abs m) MOMENTUM-STALE-TOLERANCE)
         (set-status! e cand-sym 'stale)]
        [else
         (define last-n (if (>= (length new-hist) MOMENTUM-NEGATIVE-THRESHOLD)
                            (take new-hist MOMENTUM-NEGATIVE-THRESHOLD)
                            new-hist))
         (cond
           [(and (= (length last-n) MOMENTUM-NEGATIVE-THRESHOLD)
                 (andmap (lambda (mm) (< mm (- MOMENTUM-STALE-TOLERANCE))) last-n))
            (set-status! e cand-sym 'demotion-candidate)]
           [else
            (set-status! e cand-sym 'stale)])])))
  ;; Reset recent counters for next epoch
  (set-box! (cand-recent-uses-of e) '())
  (set-box! (cand-recent-reuse-of e) '())
  (set-box! (cand-recent-fails-of e) '())
  (record-ledger! e (list 'new-epoch (unbox ec))))

(define (prim-mark-stale e)
  (define c (require-sym (pop! e) 'MARK-STALE))
  (set-status! e c 'stale)
  (record-ledger! e (list 'mark-stale c)))

(define (prim-demote-primitive e)
  (define c (require-sym (pop! e) 'DEMOTE-PRIMITIVE))
  (define st (get-status e c))
  (cond
    [(not (memq st '(stable-active stale)))
     (raise (exn:fail:sixth
             (format "~a — DEMOTE-PRIMITIVE: cannot demote ~a (status=~a)"
                     (format-srcloc (current-prim-srcloc)) c st)
             (current-continuation-marks) (current-prim-srcloc)))]
    [else
     (set-status! e c 'demotion-candidate)
     (record-ledger! e (list 'demote-primitive c st))]))

(define (prim-decompose-primitive e)
  (define c (require-sym (pop! e) 'DECOMPOSE-PRIMITIVE))
  (define st (get-status e c))
  (cond
    [(not (eq? st 'demotion-candidate))
     (raise (exn:fail:sixth
             (format "~a — DECOMPOSE-PRIMITIVE: cand ~a status=~a (require 'demotion-candidate)"
                     (format-srcloc (current-prim-srcloc)) c st)
             (current-continuation-marks) (current-prim-srcloc)))]
    [else
     ;; Preserve body for RESTORE before removing from dict
     (define cb (cand-bodies-of e))
     (define body-entry (assq c (unbox cb)))
     (when body-entry
       (define pb (cand-preserved-bodies-of e))
       (set-box! pb (cons (cons c (cadr body-entry))
                          (filter (lambda (ent) (not (eq? (car ent) c)))
                                  (unbox pb)))))
     ;; Remove from active dict (mutates law_hash)
     (hash-remove! (env-words e) c)
     ;; Remove from cand-bodies (so expansion-length-of returns 0)
     (set-box! cb (filter (lambda (ent) (not (eq? (car ent) c))) (unbox cb)))
     (set-status! e c 'decomposed)
     (record-ledger! e (list 'decompose-primitive c (compute-law-hash e)))]))

(define (prim-restore-primitive e)
  (define c (require-sym (pop! e) 'RESTORE-PRIMITIVE))
  (define st (get-status e c))
  (cond
    [(not (eq? st 'decomposed))
     (raise (exn:fail:sixth
             (format "~a — RESTORE-PRIMITIVE: cand ~a status=~a (require 'decomposed)"
                     (format-srcloc (current-prim-srcloc)) c st)
             (current-continuation-marks) (current-prim-srcloc)))]
    [else
     (define pb (cand-preserved-bodies-of e))
     (define p-entry (assq c (unbox pb)))
     (cond
       [(not p-entry)
        (raise (exn:fail:sixth
                (format "~a — RESTORE-PRIMITIVE: no preserved body for ~a"
                        (format-srcloc (current-prim-srcloc)) c)
                (current-continuation-marks) (current-prim-srcloc)))]
       [else
        (define motif (cdr p-entry))
        (define opcodes (build-motif-opcodes motif))
        (define w (word c opcodes (current-prim-srcloc)))
        ;; Restore body and dict entry
        (define cb (cand-bodies-of e))
        (set-box! cb (cons (list c motif) (unbox cb)))
        (env-register-word! e c w)
        (set-status! e c 'stable-active)
        (record-ledger! e (list 'restore-primitive c (compute-law-hash e)))])]))

;; ============================================================
;; HELD-OUT-EVAL (cycle 28B real impl, replaces cycle 25B stub)
;; ============================================================
;;
;; HELD-OUT-EVAL ( cand-sym -- wins )
;;
;; For each of 6 frozen held-out substrates:
;;   1. Substrate-RESET (clears world; preserves dictionary).
;;   2. Look up substrate-word in env-words; run it via VM.
;;      (Manifest words push expected signature on stack; drop it.)
;;   3. Snapshot E-REUSE-GAIN before.
;;   4. Loop K_HELDOUT=5 times: try-dispatch cand-sym.
;;      On exception → mark substrate as LOSE, break.
;;   5. Snapshot E-REUSE-GAIN after.
;;   6. WIN iff all K calls succeeded AND delta >= K * (exp_len - 1).
;;
;; Returns the integer wins count (0..6).

(define K_HELDOUT 5)

(define HELD-OUT-SUBSTRATES
  '(heldout-path-n12
    heldout-cycle-n12
    heldout-er-n10-p30
    heldout-er-n20-p15
    heldout-motif-wedges
    heldout-hidden-family-n24))

(define (load-substrate-by-name! e name)
  ;; Look up and run the manifest word.  Push the signature it
  ;; produces, then drop it (we don't verify here — manifest
  ;; integrity is demo 144's job).
  (define w (env-lookup-word e name))
  (unless w
    (raise (exn:fail:sixth
            (format "~a — HELD-OUT-EVAL: substrate word ~a not found in dictionary (did you `use manifest`?)"
                    (format-srcloc (current-prim-srcloc)) name)
            (current-continuation-marks)
            (current-prim-srcloc))))
  ;; Run the word's opcodes.  Push a halt-sentinel so RET halts
  ;; cleanly without entering caller's frame.
  (push-halt-frame! e)
  (run! (word-opcodes w) e)
  ;; Drop the trailing signature pushed by the manifest word.
  (env-pop! e (current-prim-srcloc)))

(define (substrate-RESET! e)
  ;; Reuse RESET primitive through the dispatch path.
  (define reset-prim (env-lookup-prim e 'RESET))
  (when reset-prim (reset-prim e)))

(define (try-dispatch-cand! e cand-sym)
  ;; Dispatch a candidate word once.  Returns #t on success, #f on
  ;; any raised exception (e.g., stack underflow inside body).
  ;; Manually invokes the dispatch hook so use_count / reuse_gain
  ;; tracking fires (we're bypassing the VM's normal op-CALL path).
  ;;
  ;; On exception: clean up the half-pushed return frame so subsequent
  ;; dispatches start with a clean rstack.
  (define w (env-lookup-word e cand-sym))
  (cond
    [(not w) #f]
    [else
     (define hook (current-cand-dispatch-hook))
     (define rstack-snapshot (env-rstack e))
     (define stack-snapshot  (env-stack e))
     (with-handlers ([(lambda (_) #t)
                      (lambda (_)
                        ;; Restore both stacks to pre-dispatch state.
                        (set-env-rstack! e rstack-snapshot)
                        (set-env-stack!  e stack-snapshot)
                        #f)])
       (when hook (hook e cand-sym))
       (push-halt-frame! e)
       (run! (word-opcodes w) e)
       #t)]))

(define (prim-held-out-eval-real e)
  (define cand-sym (require-sym (pop! e) 'HELD-OUT-EVAL))
  (define exp-len (expansion-length-of e cand-sym))
  (cond
    [(= exp-len 0)
     ;; Cand not in dictionary or has no body — no transferable
     ;; behavior to test.  Return 0 wins.
     (record-ledger! e (list 'heldout-eval cand-sym 0 'no-body))
     (push! e 0)]
    [else
     (define expected-gain (* K_HELDOUT (max 0 (- exp-len 1))))
     (define wins
       (for/sum ([sub-name (in-list HELD-OUT-SUBSTRATES)])
         (substrate-RESET! e)
         (with-handlers ([exn:fail? (lambda (_) 0)])
           (load-substrate-by-name! e sub-name)
           (define reuse-pre (unbox (energy-reuse-gain-of e)))
           (define all-succeeded?
             (for/and ([_ (in-range K_HELDOUT)])
               (try-dispatch-cand! e cand-sym)))
           (define reuse-post (unbox (energy-reuse-gain-of e)))
           (define delta (- reuse-post reuse-pre))
           (if (and all-succeeded? (>= delta expected-gain))
               1
               0))))
     (record-ledger! e (list 'heldout-eval cand-sym wins
                              'k_heldout K_HELDOUT
                              'expansion-length exp-len
                              'expected-gain expected-gain
                              (session-id-of e)))
     (push! e wins)]))

;; TRY-COMMIT ( cand -- result )  — same as COMMIT-PRIMITIVE but
;; catches gate-rejection exceptions and pushes a status symbol
;; instead of raising.  Used by negative demos to assert that the
;; gate correctly REJECTS without crashing the test.
;;
;; Returns: cand-sym on success, or a 'rejected-* symbol on
;; rejection.  Rejection reason is parsed from the exception message.
(define (prim-try-commit e)
  (define c (require-sym (pop! e) 'TRY-COMMIT))
  (with-handlers
    ([exn:fail:sixth?
      (lambda (ex)
        (define msg (exn-message ex))
        (define kind
          (cond
            [(regexp-match? #px"not energetically justified" msg)
             'rejected-energy]
            [(regexp-match? #px"distinct sessions" msg)
             'rejected-coupling-m]
            [(regexp-match? #px"coupling rule" msg)
             'rejected-coupling-n]
            [(regexp-match? #px"rolled-back" msg)
             'rejected-rolled-back]
            [(regexp-match? #px"contaminated" msg)
             'rejected-contaminated]
            [else 'rejected-other]))
        (record-ledger! e (list 'try-commit-rejected c kind))
        (push! e kind))])
    (push! e c)
    (prim-commit-primitive e)))

;; Helper: get current world hash without going through primitive
;; dispatch (avoid double-counting in inspection).
(define (require-hash-world e)
  ;; Replicate prim-HASH-WORLD logic from sixth/primitives/substrate.rkt:
  ;;   hash of (n, sorted-out-edges, sorted-hedges).
  (define s (env-substrate e))
  (cond
    [(not s) 0]
    [else
     ;; Lazy require via dynamic-require would avoid linking the
     ;; whole substrate module here, but we already require core.rkt
     ;; from runtime.rkt so the function is in scope through
     ;; substrate-outs / substrate-node-count.
     ;; We reimplement to avoid cross-module dependency on primitives/.
     (define n (substrate-node-count s))
     (define edge-summary
       (for/list ([nid (in-range n)])
         (cons nid (sort (substrate-outs s nid) <))))
     (define hedge-summary
       (sort (substrate-hedges-snapshot s)
             (lambda (a b)
               (string<? (format "~a" a) (format "~a" b)))))
     (equal-hash-code (list n edge-summary hedge-summary))]))

;; ---- registry --------------------------------------------------------

(define TIER1-TABLE
  (list (cons 'DETECT-MOTIF      prim-detect-motif)
        (cons 'SHADOW-CHECK      prim-shadow-check)
        (cons 'INDUCE-RUNTIME    prim-induce-runtime)
        (cons 'ROLLBACK-RUNTIME  prim-rollback-runtime)
        (cons 'COMMIT-PRIMITIVE  prim-commit-primitive)
        (cons 'LAW-HASH          prim-law-hash)
        ;; cycle 25D inspection / hardening:
        (cons 'LEDGER-COUNT      prim-ledger-count)
        (cons 'LEDGER-LAST       prim-ledger-last)
        (cons 'CAND-USES         prim-cand-uses)
        (cons 'CAND-STATUS       prim-cand-status)
        (cons 'SHADOW-CERT-OF    prim-shadow-cert-of)
        (cons 'SESSION-ID        prim-session-id)
        (cons 'CONTAMINATE!      prim-contaminate!)
        ;; cycle 25E energy accounting (observational):
        (cons 'E-WORLD           prim-e-world)
        (cons 'E-LAW             prim-e-law)
        (cons 'E-TRACE           prim-e-trace)
        (cons 'E-CONFLICT        prim-e-conflict)
        (cons 'E-SEARCH          prim-e-search)
        (cons 'E-REUSE-GAIN      prim-e-reuse-gain)
        (cons 'E-TOTAL           prim-e-total)
        (cons 'E-SNAPSHOT        prim-e-snapshot)
        ;; cycle 26 additions: M=3 + energy-gate test infrastructure
        (cons 'NEW-SESSION                prim-new-session)
        (cons 'WRAP-MOTIF                 prim-wrap-motif)
        (cons 'CAND-DISTINCT-SESSIONS     prim-cand-distinct-sessions)
        (cons 'TRY-COMMIT                 prim-try-commit)
        ;; cycle 27: automated discovery mining engine
        (cons 'DETECT-MOTIF-AUTO          prim-detect-motif-auto)
        ;; cycle 28: real held-out evaluation (replaces Tier 2 stub)
        (cons 'HELD-OUT-EVAL              prim-held-out-eval-real)
        ;; cycle 29: law metabolism
        (cons 'NEW-EPOCH                  prim-new-epoch)
        (cons 'LAW-MOMENTUM               prim-law-momentum)
        (cons 'MARK-STALE                 prim-mark-stale)
        (cons 'DEMOTE-PRIMITIVE           prim-demote-primitive)
        (cons 'DECOMPOSE-PRIMITIVE        prim-decompose-primitive)
        (cons 'RESTORE-PRIMITIVE          prim-restore-primitive)))

(define (register-tier1! e)
  (for ([entry (in-list TIER1-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
