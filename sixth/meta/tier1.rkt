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

(provide register-tier1!)

(require racket/list
         racket/string
         "../env.rkt"
         "../errors.rkt"
         "../opcodes.rkt"
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

(define (prim-shadow-check e)
  (define motif (require-list (pop! e) 'SHADOW-CHECK))
  (define law-before (compute-law-hash e))
  (cond
    [(null? motif)
     (push! e 0)]
    [(motif-has-forbidden? motif)
     (record-shadow-cert! e motif 'fail-forbidden)
     (push! e 0)]
    [(not (motif-expandable? e motif))
     (record-shadow-cert! e motif 'fail-unexpandable)
     (push! e 0)]
    [else
     ;; Lookup-only check: law-hash should not have changed.
     ;; Sanity for future extensions of SHADOW-CHECK that might
     ;; accidentally mutate dictionary.
     (define law-after (compute-law-hash e))
     (cond
       [(= law-before law-after)
        (record-shadow-cert! e motif 'pass)
        (push! e 1)]
       [else
        (record-shadow-cert! e motif 'fail-law-mutation)
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
     ;; Promote ephemeral-active → committed (next stop: Tier 2 SPECIFY).
     (define sb (cand-status-of e))
     (set-box! sb (cons (cons cand-sym 'committed)
                         (filter (lambda (entry)
                                   (not (eq? (car entry) cand-sym)))
                                 (unbox sb))))
     (record-ledger! e (list 'commit-primitive cand-sym
                              cand-uses
                              (compute-law-hash e)
                              (session-id-of e)))
     (push! e cand-sym)]))

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
  (record-ledger! e (list 'contamination c reason
                           (compute-law-hash e)
                           (session-id-of e))))

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
        (cons 'CONTAMINATE!      prim-contaminate!)))

(define (register-tier1! e)
  (for ([entry (in-list TIER1-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
