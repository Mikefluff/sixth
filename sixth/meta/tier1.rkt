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
  ;; status registry: branches on cycle 31 discovery profile.
  ;; - conservative (default): status = 'ephemeral-active (cycle 25 flow,
  ;;   pre-promotion pipeline; can be COMMIT'd then PROMOTE-STABLE'd)
  ;; - liberal: status = 'experimental (sandbox track, callable but
  ;;   filtered out of STABLE-LAW-HASH; cannot COMMIT or PROMOTE-STABLE;
  ;;   can be PROMOTE-EXPERIMENTAL'd to 'sandbox-stable)
  (define init-status
    (case (discovery-profile-of e)
      [(liberal)      'experimental]
      [else           'ephemeral-active]))
  (define sb (cand-status-of e))
  (set-box! sb (cons (cons cand-sym init-status) (unbox sb)))
  ;; use counter initialised to 0
  (define ub (cand-use-counts-of e))
  (set-box! ub (cons (cons cand-sym 0) (unbox ub)))
  ;; law-state mutation:
  (env-register-word! e cand-sym w)
  ;; cycle 32: opcodes → cand reverse-lookup for find-current-cand
  (register-cand-opcodes! e cand-sym opcodes)
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
     ;; cycle 32: drop opcodes → cand mapping before removing word
     (define existing-w (env-lookup-word e cand-sym))
     (when existing-w
       (unregister-cand-opcodes! e (word-opcodes existing-w)))
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
    [(memq cand-status SANDBOX-STATUSES)
     ;; Cycle 31: liberal-track cand cannot be committed.  Only
     ;; conservative-INDUCEd cands (status 'ephemeral-active) are
     ;; eligible for the COMMIT → PROMOTE-STABLE pipeline.
     (raise (exn:fail:sixth
             (format "~a — COMMIT-PRIMITIVE: candidate ~a is sandbox-track (status=~a); not eligible (rejected-not-conservative)"
                     (format-srcloc (current-prim-srcloc)) cand-sym cand-status)
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
;; Cycle 30 — Dependency-aware AUTO-DECOMPOSE + 'dependency-held + cascade restore
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
  ;; Cycle 31: every active primitive pays INFLATION-COST-PER-CAND=1
  ;; per epoch on top of its expansion-length carry.  The +1 penalty
  ;; never changes any cycle 29/30 demo transition (analytically
  ;; verified in PREDICTIONS-163.md backward-compat contract) but
  ;; prevents stable primitives from sitting forever without
  ;; contributing.
  (define reuse (alist-lookup (cand-recent-reuse-of e) cand-sym))
  (define fails (alist-lookup (cand-recent-fails-of e) cand-sym))
  (define carry (expansion-length-of e cand-sym))
  (- reuse carry fails INFLATION-COST-PER-CAND))

(define (prim-law-momentum e)
  (define c (require-sym (pop! e) 'LAW-MOMENTUM))
  (push! e (compute-momentum-for e c)))

;; ---- cycle 30: dependency graph derived from motif bodies ----
;;
;; A `cand_a` depends on `cand_b` iff cand_a's motif (as stored in
;; _cand-bodies) contains the symbol cand_b.  This is a STATIC
;; usage graph derived from opcode bodies — deterministic,
;; rebuildable on demand.  No runtime tracing involved.

(define (cand-depends-on? e cand-a cand-b)
  (define entry (assq cand-a (unbox (cand-bodies-of e))))
  (and entry (memq cand-b (cadr entry)) #t))

(define (active-dependents-of e cand)
  ;; List of cands (excluding cand itself) whose motif contains cand
  ;; AND whose current status is in ACTIVE-METAB-STATUSES.
  (for/list ([entry (in-list (unbox (cand-bodies-of e)))]
             #:when (let ([other (car entry)])
                      (and (not (eq? other cand))
                           (memq cand (cadr entry))
                           (memq (get-status e other)
                                 ACTIVE-METAB-STATUSES))))
    (car entry)))

(define (has-positive-dependent-momentum? e cand)
  ;; Cycle 30 direct-only predicate.  Kept for diagnostics; Pass C
  ;; uses has-recent-load-bearing? (cycle 32 strengthened version).
  (for/or ([d (in-list (active-dependents-of e cand))])
    (> (compute-momentum-for e d) MOMENTUM-STALE-TOLERANCE)))

;; ============================================================
;; Cycle 32 — runtime-observed transitive load-bearing predicate.
;; ============================================================
;;
;; A cand is "load-bearing" only if some active dependent OBSERVED
;; calling it nested this epoch AND that dependent is either
;; positive-momentum itself OR is supported by its own chain
;; terminating in a positive anchor.  Visited-set DFS guards against
;; immortal-cycle protection (a closed cycle of cands without any
;; external positive anchor cannot mutually save each other).
;;
;; Positive anchor predicate: status in {stable-active, sandbox-stable}
;; AND momentum > MOMENTUM-STALE-TOLERANCE.  Pre-cycle-31 it was just
;; m > STALE_TOLERANCE; the status filter additionally excludes
;; intermediate dependency-held / demotion-candidate cands from
;; being the terminal anchor (they must be transitively traced).

(define (positive-anchor? e cand)
  (and (memq (get-status e cand) '(stable-active sandbox-stable))
       (> (compute-momentum-for e cand) MOMENTUM-STALE-TOLERANCE)))

(define (has-recent-load-bearing? e cand)
  (let walk ([c cand] [visited (list cand)])
    (define deps (active-dependents-of e c))
    (for/or ([d (in-list deps)])
      (cond
        [(member d visited) #f]                     ; cycle guard
        [(not (observed-dep? e d c)) #f]            ; observation required
        [(positive-anchor? e d) #t]                 ; chain terminates here
        [else (walk d (cons d visited))]))))        ; transitive recurse

(define (prim-observed-dep? e)
  (define b (require-sym (pop! e) 'OBSERVED-DEP?))
  (define a (require-sym (pop! e) 'OBSERVED-DEP?))
  (push! e (if (observed-dep? e a b) 1 0)))

(define (prim-cand-observes? e)
  ;; Convenience alias for OBSERVED-DEP? with the same arg order.
  (define b (require-sym (pop! e) 'CAND-OBSERVES?))
  (define a (require-sym (pop! e) 'CAND-OBSERVES?))
  (push! e (if (observed-dep? e a b) 1 0)))

(define (prim-recent-load-bearing? e)
  (define c (require-sym (pop! e) 'RECENT-LOAD-BEARING?))
  (push! e (if (has-recent-load-bearing? e c) 1 0)))

(define (prim-auto-decompose-safe? e)
  (define c (require-sym (pop! e) 'AUTO-DECOMPOSE-SAFE?))
  (define local-m (compute-momentum-for e c))
  (cond
    [(>= local-m (- MOMENTUM-STALE-TOLERANCE))
     ;; Local momentum has not crossed the negative tolerance band yet.
     (push! e 0)]
    [(has-positive-dependent-momentum? e c)
     ;; Structurally load-bearing for an active dependent.
     (push! e 0)]
    [else (push! e 1)]))

(define (prim-cand-dependents e)
  (define c (require-sym (pop! e) 'CAND-DEPENDENTS))
  (push! e (active-dependents-of e c)))

(define (prim-law-depends-on? e)
  (define b (require-sym (pop! e) 'LAW-DEPENDS-ON?))
  (define a (require-sym (pop! e) 'LAW-DEPENDS-ON?))
  (push! e (if (cand-depends-on? e a b) 1 0)))

;; Snapshot the active dependents at decompose time, so RESTORE can
;; emit a cascade-restore ledger event identifying which dependents
;; had their callability broken.  Cycle 30 does NOT auto-promote
;; dependents on restore; cascade is forensic + structural only.
(define (record-pre-decompose-snapshot! e c)
  (define ds-b (cand-decompose-snapshot-of e))
  (define deps (active-dependents-of e c))
  (set-box! ds-b (cons (cons c deps)
                       (filter (lambda (ent) (not (eq? (car ent) c)))
                               (unbox ds-b)))))

;; Core decompose mechanics, shared between manual DECOMPOSE-PRIMITIVE
;; and auto-decompose from NEW-EPOCH.  Assumes status='demotion-candidate
;; has been verified by the caller.  Records snapshot, preserves body,
;; removes from dict (and opcodes-to-cand map), sets status, emits ledger.
(define (do-decompose! e c ledger-tag)
  (record-pre-decompose-snapshot! e c)
  (define cb (cand-bodies-of e))
  (define body-entry (assq c (unbox cb)))
  (when body-entry
    (define pb (cand-preserved-bodies-of e))
    (set-box! pb (cons (cons c (cadr body-entry))
                       (filter (lambda (ent) (not (eq? (car ent) c)))
                               (unbox pb)))))
  ;; cycle 32: drop opcodes → cand mapping before removing word
  (define existing-w (env-lookup-word e c))
  (when existing-w
    (unregister-cand-opcodes! e (word-opcodes existing-w)))
  (hash-remove! (env-words e) c)
  (set-box! cb (filter (lambda (ent) (not (eq? (car ent) c))) (unbox cb)))
  (set-status! e c 'decomposed)
  (record-ledger! e (list ledger-tag c (compute-law-hash e))))

;; ---- NEW-EPOCH (cycle 30 three-pass version) ----
;;
;; Pass A: snapshot active-metab cands, compute their epoch-end momenta,
;;         push to history (truncated to window).
;; Pass B: status transitions per cycle 29 rules — applies to ALL active
;;         metab cands (including 'dependency-held: they re-enter the
;;         normal track if m recovered, or re-fall into demotion-candidate
;;         if m still bad).
;; Pass C: for each cand now 'demotion-candidate, apply the dependency-aware
;;         AUTO-DECOMPOSE gate:
;;           - if any active dependent has positive momentum → 'dependency-held
;;           - else → auto-decompose (do-decompose! with 'auto-decompose tag)
;;
;; Counters reset at end so the next epoch starts clean.
(define (prim-new-epoch e)
  (define ec (epoch-counter-of e))
  (set-box! ec (+ 1 (unbox ec)))

  (define active-cands
    (for/list ([entry (in-list (unbox (cand-bodies-of e)))]
               #:when (memq (get-status e (car entry))
                            ACTIVE-METAB-STATUSES))
      (car entry)))

  ;; Pass A: compute momentum, push history
  (for ([c (in-list active-cands)])
    (define m (compute-momentum-for e c))
    (define hb (cand-momentum-history-of e))
    (define cur-hist (or (let ([x (assq c (unbox hb))])
                           (and x (cdr x))) '()))
    (define new-hist
      (let ([h (cons m cur-hist)])
        (if (> (length h) MOMENTUM-HISTORY-WINDOW)
            (take h MOMENTUM-HISTORY-WINDOW)
            h)))
    (set-box! hb (cons (cons c new-hist)
                       (filter (lambda (ent) (not (eq? (car ent) c)))
                               (unbox hb)))))

  ;; Pass B: status transitions based on m + history (cycle 29 rules,
  ;; uniformly applied including to 'dependency-held cands).
  (for ([c (in-list active-cands)])
    (define m (compute-momentum-for e c))
    (define hb (cand-momentum-history-of e))
    (define hist (or (let ([x (assq c (unbox hb))]) (and x (cdr x))) '()))
    (cond
      [(> m MOMENTUM-STALE-TOLERANCE)
       (set-status! e c 'stable-active)]
      [(<= (abs m) MOMENTUM-STALE-TOLERANCE)
       (set-status! e c 'stale)]
      [else
       (define last-n (if (>= (length hist) MOMENTUM-NEGATIVE-THRESHOLD)
                          (take hist MOMENTUM-NEGATIVE-THRESHOLD)
                          hist))
       (cond
         [(and (= (length last-n) MOMENTUM-NEGATIVE-THRESHOLD)
               (andmap (lambda (mm) (< mm (- MOMENTUM-STALE-TOLERANCE)))
                       last-n))
          (set-status! e c 'demotion-candidate)]
         [else
          (set-status! e c 'stale)])]))

  ;; Pass C: dependency-aware AUTO-DECOMPOSE gate for current demotion-candidates.
  ;; Snapshot the list before any decompose so order is invariant.
  (define demotion-cands
    (for/list ([c (in-list active-cands)]
               #:when (eq? (get-status e c) 'demotion-candidate))
      c))
  (for ([c (in-list demotion-cands)])
    (cond
      [(has-recent-load-bearing? e c)
       (set-status! e c 'dependency-held)
       (record-ledger! e (list 'dependency-held c
                                (active-dependents-of e c)))]
      [else
       (do-decompose! e c 'auto-decompose)]))

  ;; Reset recent counters for next epoch
  (set-box! (cand-recent-uses-of e) '())
  (set-box! (cand-recent-reuse-of e) '())
  (set-box! (cand-recent-fails-of e) '())
  ;; Cycle 32: reset observed-dep tracking for next epoch
  (set-box! (observed-deps-of e) '())
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
     (do-decompose! e c 'decompose-primitive)]))

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
        ;; cycle 32: re-register opcodes → cand mapping (new vector created above)
        (register-cand-opcodes! e c opcodes)
        (set-status! e c 'stable-active)
        (record-ledger! e (list 'restore-primitive c (compute-law-hash e)))
        ;; Cycle 30: cascade-restore forensic — emit ledger event with
        ;; the dependents recorded at decompose time, if any.  Structural
        ;; reactivation of the dependents is automatic (env-words now has
        ;; this cand back, so their next dispatch resolves), but cycle 30
        ;; does NOT auto-promote dependents — they must earn their own
        ;; positive momentum back through normal use.
        (define ds-b (cand-decompose-snapshot-of e))
        (define snap-entry (assq c (unbox ds-b)))
        (when snap-entry
          (record-ledger! e
                          (list 'restore-cascade c (cdr snap-entry)
                                (compute-law-hash e))))])]))

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
  ;; any raised exception (e.g., stack underflow, unbound nested
  ;; reference after auto-decompose).
  ;;
  ;; Hook is fired ONLY on success (cycle 30: a faulting call must not
  ;; bump reuse_gain — otherwise momentum would credit failed reuses).
  ;; On failure, the cand's recent_failures counter is bumped so the
  ;; next NEW-EPOCH momentum reflects the breakage.
  (cond
    [(not (env-lookup-word e cand-sym))
     ;; Cand absent (e.g. decomposed) — count as failure for callers
     ;; that meaningfully expected it to exist.
     (when (cand-name? cand-sym)
       (bump-recent-fails! e cand-sym))
     #f]
    [else
     (define w (env-lookup-word e cand-sym))
     (define hook (current-cand-dispatch-hook))
     (define rstack-snapshot (env-rstack e))
     (define stack-snapshot  (env-stack e))
     (define result
       (with-handlers ([(lambda (_) #t)
                        (lambda (_)
                          (set-env-rstack! e rstack-snapshot)
                          (set-env-stack!  e stack-snapshot)
                          #f)])
         (push-halt-frame! e)
         (run! (word-opcodes w) e)
         #t))
     (cond
       [result
        (when hook (hook e cand-sym))]
       [else
        (when (cand-name? cand-sym)
          (bump-recent-fails! e cand-sym))])
     result]))

;; TRY-DISPATCH ( cand -- 0|1 )  cycle 30 testing primitive.
;; Calls try-dispatch-cand! and pushes 1 on success, 0 on failure.
;; Used by demos that need to observe broken callability without
;; aborting the program (e.g., demo 162 phase 3 after auto-decompose).
(define (prim-try-dispatch e)
  (define c (require-sym (pop! e) 'TRY-DISPATCH))
  (define result (try-dispatch-cand! e c))
  (push! e (if result 1 0)))

;; ============================================================
;; Cycle 31 — Discovery profiles + sandbox track + LAW-CARRY
;; ============================================================

(define (prim-set-discovery-profile e)
  (define p (require-sym (pop! e) 'SET-DISCOVERY-PROFILE))
  (cond
    [(memq p '(conservative liberal))
     (set-discovery-profile! e p)
     (record-ledger! e (list 'set-discovery-profile p (session-id-of e)))]
    [else
     (raise (exn:fail:sixth
             (format "~a — SET-DISCOVERY-PROFILE: profile must be 'conservative or 'liberal, got ~v"
                     (format-srcloc (current-prim-srcloc)) p)
             (current-continuation-marks) (current-prim-srcloc)))]))

(define (prim-discovery-profile e)
  (push! e (discovery-profile-of e)))

(define (prim-profile-budget e)
  (push! e
         (case (discovery-profile-of e)
           [(liberal)      PROFILE-BUDGET-LIBERAL]
           [else           PROFILE-BUDGET-CONSERVATIVE])))

(define (prim-profile-scope e)
  (push! e
         (case (discovery-profile-of e)
           [(liberal)      'sandbox]
           [else           'stable])))

(define (prim-promote-experimental e)
  (define c (require-sym (pop! e) 'PROMOTE-EXPERIMENTAL))
  (define st (get-status e c))
  (cond
    [(not (eq? st 'experimental))
     (raise (exn:fail:sixth
             (format "~a — PROMOTE-EXPERIMENTAL: cand ~a status=~a (require 'experimental)"
                     (format-srcloc (current-prim-srcloc)) c st)
             (current-continuation-marks) (current-prim-srcloc)))]
    [else
     (set-status! e c 'sandbox-stable)
     (record-ledger! e (list 'promote-experimental c
                              (compute-law-hash e)
                              (session-id-of e)))
     (push! e c)]))

(define (prim-stable-law-hash e)
  (push! e (compute-stable-law-hash e)))

(define (prim-sandbox-law-hash e)
  (push! e (compute-sandbox-law-hash e)))

(define (prim-law-carry e)
  ;; Returns expansion_length of cand (which is the carry_cost
  ;; component of momentum bookkeeping).  Inflation is not added
  ;; here — LAW-CARRY is the structural cost, momentum reflects
  ;; the full tax.
  (define c (require-sym (pop! e) 'LAW-CARRY))
  (push! e (expansion-length-of e c)))

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
            [(regexp-match? #px"rejected-not-conservative" msg)
             'rejected-not-conservative]
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
        (cons 'RESTORE-PRIMITIVE          prim-restore-primitive)
        ;; cycle 30: dependency-aware AUTO-DECOMPOSE
        (cons 'AUTO-DECOMPOSE-SAFE?       prim-auto-decompose-safe?)
        (cons 'CAND-DEPENDENTS            prim-cand-dependents)
        (cons 'LAW-DEPENDS-ON?            prim-law-depends-on?)
        (cons 'TRY-DISPATCH               prim-try-dispatch)
        ;; cycle 31: discovery profiles + sandbox track + inflation forensics
        (cons 'SET-DISCOVERY-PROFILE      prim-set-discovery-profile)
        (cons 'DISCOVERY-PROFILE          prim-discovery-profile)
        (cons 'PROFILE-BUDGET             prim-profile-budget)
        (cons 'PROFILE-SCOPE              prim-profile-scope)
        (cons 'PROMOTE-EXPERIMENTAL       prim-promote-experimental)
        (cons 'STABLE-LAW-HASH            prim-stable-law-hash)
        (cons 'SANDBOX-LAW-HASH           prim-sandbox-law-hash)
        (cons 'LAW-CARRY                  prim-law-carry)
        ;; cycle 32: runtime-observed deps + transitive load-bearing
        (cons 'OBSERVED-DEP?              prim-observed-dep?)
        (cons 'CAND-OBSERVES?             prim-cand-observes?)
        (cons 'RECENT-LOAD-BEARING?       prim-recent-load-bearing?)))

(define (register-tier1! e)
  (for ([entry (in-list TIER1-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
