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
;; For cycle 25A: a motif passes SHADOW-CHECK if every symbol in it
;; is currently a callable primitive OR word in the active dictionary
;; (i.e., the motif is *expandable* against current law-state).
;;
;; Cost-bound check: motif length <= MOTIF_MAX_LEN (already enforced
;; by DETECT-MOTIF).
;;
;; This is the minimal honest equivalence check: a candidate primitive
;; whose expansion calls only existing dispatch is by construction
;; semantically equivalent to its expansion, modulo runtime cost.
;; A fuller world-state forking comparison comes in cycle 26 when
;; semantic substrate motifs are tested.
;; ----------------------------------------------------------------------

(define (motif-expandable? e motif)
  (andmap (lambda (sym)
            (or (env-lookup-prim e sym)
                (env-lookup-word e sym)))
          motif))

(define (prim-shadow-check e)
  (define motif (require-list (pop! e) 'SHADOW-CHECK))
  (cond
    [(null? motif) (push! e 0)]
    [(motif-expandable? e motif) (push! e 1)]
    [else (push! e 0)]))

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

(define (prim-induce-runtime e)
  (define motif (require-list (pop! e) 'INDUCE-RUNTIME))
  (cond
    [(null? motif)
     (raise (exn:fail:sixth
             (format "~a — INDUCE-RUNTIME: empty motif"
                     (format-srcloc (current-prim-srcloc)))
             (current-continuation-marks)
             (current-prim-srcloc)))]
    [(not (motif-expandable? e motif))
     (raise (exn:fail:sixth
             (format "~a — INDUCE-RUNTIME: motif not expandable in current law-state"
                     (format-srcloc (current-prim-srcloc)))
             (current-continuation-marks)
             (current-prim-srcloc)))])
  (define cand-sym (next-cand-name e))
  (define opcodes  (build-motif-opcodes motif))
  (define w (word cand-sym opcodes (current-prim-srcloc)))
  ;; bodies registry first (so rollback can remove cleanly)
  (define bb (cand-bodies-of e))
  (set-box! bb (cons (list cand-sym motif) (unbox bb)))
  ;; law-state mutation:
  (env-register-word! e cand-sym w)
  ;; trace + ledger:
  (define b (current-engine-trace))
  (when b (set-box! b (cons (cons 'induce cand-sym) (unbox b))))
  (record-ledger! e (list 'induce-runtime cand-sym motif
                           (compute-law-hash e)))
  (push! e cand-sym))

;; ---- ROLLBACK-RUNTIME ------------------------------------------------
;;
;; Removes cand_NNN from env-words.  Refuses to rollback non-cand_*
;; symbols (stable primitives are immutable from runtime per §6).
;;
;; Mutates law_hash back; appends event to trace + ledger.
;; ----------------------------------------------------------------------

(define (cand-name? sym)
  (and (symbol? sym)
       (let ([s (symbol->string sym)])
         (and (>= (string-length s) 5)
              (string=? (substring s 0 5) "cand_")))))

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
     ;; Already absent — idempotent rollback OK.
     (void)]
    [else
     ;; Remove from words hash.
     (hash-remove! (env-words e) cand-sym)
     (define bb (cand-bodies-of e))
     (set-box! bb (filter (lambda (entry)
                            (not (eq? (car entry) cand-sym)))
                          (unbox bb)))
     (define b (current-engine-trace))
     (when b (set-box! b (cons (cons 'rollback cand-sym) (unbox b))))
     (record-ledger! e (list 'rollback-runtime cand-sym
                              (compute-law-hash e)))]))

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

(define (prim-commit-primitive e)
  (define cand-sym (require-sym (pop! e) 'COMMIT-PRIMITIVE))
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
    [else
     (record-ledger! e (list 'commit-primitive cand-sym
                              (compute-law-hash e)))
     ;; Push back the cand-sym (as candidate-record placeholder).
     (push! e cand-sym)]))

;; ---- LAW-HASH --------------------------------------------------------

(define (prim-law-hash e)
  (push! e (compute-law-hash e)))

;; ---- registry --------------------------------------------------------

(define TIER1-TABLE
  (list (cons 'DETECT-MOTIF      prim-detect-motif)
        (cons 'SHADOW-CHECK      prim-shadow-check)
        (cons 'INDUCE-RUNTIME    prim-induce-runtime)
        (cons 'ROLLBACK-RUNTIME  prim-rollback-runtime)
        (cons 'COMMIT-PRIMITIVE  prim-commit-primitive)
        (cons 'LAW-HASH          prim-law-hash)))

(define (register-tier1! e)
  (for ([entry (in-list TIER1-TABLE)])
    (env-register-prim! e (car entry) (cdr entry))))
