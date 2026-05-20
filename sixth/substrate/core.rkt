#lang racket/base

;; sixth/substrate/core.rkt — substrate state.
;;
;; A `substrate` is a mutable record holding:
;;   - next-id    : auto-incrementing integer for fresh nodes
;;   - out-edges  : hash node-id → list of out-target ids (newest first)
;;   - in-edges   : hash node-id → list of in-source ids
;;   - edge-count : total directed-edge count (kept in sync)
;;   - features   : hash node-id → scalar feature (NSET/NGET)
;;   - born-at    : hash node-id → step number at creation
;;   - step       : monotone tick counter
;;   - assert-pass / assert-fail : counters for ASSERT primitive

(provide
  (struct-out substrate)
  make-substrate
  substrate-reset!
  substrate-mark!
  substrate-edge+!
  substrate-edge-!
  substrate-edge?
  substrate-outs
  substrate-ins
  substrate-out-count
  substrate-in-count
  substrate-next
  substrate-prev
  substrate-node-count
  substrate-edge-count*
  substrate-step!
  substrate-now
  substrate-born
  substrate-nset!
  substrate-nget
  substrate-nsum
  substrate-assert!
  substrate-pass-count
  substrate-fail-count
  substrate-report)

(struct substrate
  ([next-id   #:mutable]
   out-edges
   in-edges
   [edge-count #:mutable]
   features
   born-at
   [step      #:mutable]
   [assert-pass #:mutable]
   [assert-fail #:mutable])
  #:transparent)

(define (make-substrate)
  (substrate 0
              (make-hasheqv)
              (make-hasheqv)
              0
              (make-hasheqv)
              (make-hasheqv)
              0
              0
              0))

(define (substrate-reset! s)
  (set-substrate-next-id!     s 0)
  (set-substrate-edge-count!  s 0)
  (set-substrate-step!        s 0)
  (set-substrate-assert-pass! s 0)
  (set-substrate-assert-fail! s 0)
  (hash-clear! (substrate-out-edges s))
  (hash-clear! (substrate-in-edges  s))
  (hash-clear! (substrate-features  s))
  (hash-clear! (substrate-born-at   s)))

;; ---- MARK ----

(define (substrate-mark! s)
  (define id (+ 1 (substrate-next-id s)))
  (set-substrate-next-id! s id)
  (hash-set! (substrate-born-at s) id (substrate-step s))
  id)

;; ---- edges ----

(define (outs-of s n)
  (hash-ref (substrate-out-edges s) n '()))

(define (ins-of s n)
  (hash-ref (substrate-in-edges s) n '()))

(define (substrate-edge+! s src dst)
  (define existing (outs-of s src))
  (unless (member dst existing)
    (hash-set! (substrate-out-edges s) src (cons dst existing))
    (hash-set! (substrate-in-edges  s) dst (cons src (ins-of s dst)))
    (set-substrate-edge-count! s (+ 1 (substrate-edge-count s)))))

(define (substrate-edge-! s src dst)
  (define existing (outs-of s src))
  (when (member dst existing)
    (hash-set! (substrate-out-edges s) src (filter-not-equal existing dst))
    (hash-set! (substrate-in-edges  s) dst (filter-not-equal (ins-of s dst) src))
    (set-substrate-edge-count! s (- (substrate-edge-count s) 1))))

(define (filter-not-equal lst v)
  (cond [(null? lst) '()]
        [(equal? (car lst) v) (filter-not-equal (cdr lst) v)]
        [else (cons (car lst) (filter-not-equal (cdr lst) v))]))

(define (substrate-edge? s src dst)
  (and (member dst (outs-of s src)) #t))

(define (substrate-outs s n) (outs-of s n))
(define (substrate-ins  s n) (ins-of  s n))

(define (substrate-out-count s n) (length (outs-of s n)))
(define (substrate-in-count  s n) (length (ins-of  s n)))

(define (substrate-next s n)
  (define o (outs-of s n))
  (if (null? o) 0 (car o)))

(define (substrate-prev s n)
  (define i (ins-of s n))
  (if (null? i) 0 (car i)))

(define (substrate-node-count s) (substrate-next-id s))

(define (substrate-edge-count* s) (substrate-edge-count s))

;; ---- time ----

(define (substrate-step! s) (set-substrate-step! s (+ 1 (substrate-step s))))
(define (substrate-now  s) (substrate-step s))
(define (substrate-born s n) (hash-ref (substrate-born-at s) n -1))

;; ---- features ----

(define (substrate-nset! s n v)
  (hash-set! (substrate-features s) n v))

(define (substrate-nget s n)
  (hash-ref (substrate-features s) n 0))

(define (substrate-nsum s n)
  (for/sum ([dst (in-list (outs-of s n))])
    (hash-ref (substrate-features s) dst 0)))

;; ---- assertions ----

(define (substrate-assert! s v)
  (cond
    [(or (eq? v 0) (eq? v 0.0) (eq? v #f) (not (number? v)))
     (set-substrate-assert-fail! s (+ 1 (substrate-assert-fail s)))
     #f]
    [else
     (set-substrate-assert-pass! s (+ 1 (substrate-assert-pass s)))
     #t]))

(define (substrate-pass-count s) (substrate-assert-pass s))
(define (substrate-fail-count s) (substrate-assert-fail s))

(define (substrate-report s)
  (display "─────────────────────────────────") (newline)
  (display (format "REPORT  nodes=~a  edges=~a  steps=~a  pass=~a  fail=~a~n"
                    (substrate-node-count s)
                    (substrate-edge-count* s)
                    (substrate-now s)
                    (substrate-pass-count s)
                    (substrate-fail-count s))))
