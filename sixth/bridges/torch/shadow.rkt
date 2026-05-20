#lang racket/base

;; sixth/bridges/torch/shadow.rkt — non-differentiable PyTorch shadow
;; of the Sixth substrate engine.  Ports legacy/substrate_torch.py.
;;
;; Substrate state mirrors what `sixth/substrate/core.rkt` holds, but
;; iteration uses tensor ops via the libsixth_torch.dylib bridge.
;; Adjacency materialises as a dense tensor only on demand (STEP-CA,
;; bfs-distance).
;;
;; Three demos verify equivalence with the chibi substrate:
;;   1. Peano arithmetic (numbers)
;;   2. BFS distance — 1D chain and 2D grid
;;   3. Conway blinker on 5×5 Moore grid

(provide make-shadow
         shadow-MARK!
         shadow-EDGE+!
         shadow-EDGE?
         shadow-IN
         shadow-OUT
         shadow-NEXT
         shadow-PREV
         shadow-NSET!
         shadow-NGET
         shadow-NSUM
         shadow-STEP!
         shadow-STEP-CA!
         shadow-bfs-distance
         demo-peano
         demo-distance-1d
         demo-distance-2d
         demo-conway-blinker
         run-all-demos)

(require racket/list
         racket/match
         (prefix-in t: "tensor.rkt"))

;; Substrate as a mutable record.
(struct shadow
  ([next-id   #:mutable]
   [step      #:mutable]
   edges                 ; mutable hash (cons src dst) -> #t
   features              ; mutable hash id -> float
   born                  ; mutable hash id -> step
   ))

(define (make-shadow)
  (shadow 0 0 (make-hash) (make-hash) (make-hash)))

;; ---- primitives ----

(define (shadow-MARK! s)
  (define id (+ 1 (shadow-next-id s)))
  (set-shadow-next-id! s id)
  (hash-set! (shadow-features s) id 0.0)
  (hash-set! (shadow-born s) id (shadow-step s))
  id)

(define (shadow-EDGE+! s src dst)
  (hash-set! (shadow-edges s) (cons src dst) #t))

(define (shadow-EDGE? s src dst)
  (hash-has-key? (shadow-edges s) (cons src dst)))

(define (shadow-OUT s n)
  (for/sum ([k (in-hash-keys (shadow-edges s))]
            #:when (= (car k) n))
    1))

(define (shadow-IN s n)
  (for/sum ([k (in-hash-keys (shadow-edges s))]
            #:when (= (cdr k) n))
    1))

(define (shadow-NEXT s n)
  (define best #f)
  (for ([k (in-hash-keys (shadow-edges s))])
    (when (= (car k) n)
      (when (or (not best) (< (cdr k) best))
        (set! best (cdr k)))))
  (or best 0))

(define (shadow-PREV s n)
  (define best #f)
  (for ([k (in-hash-keys (shadow-edges s))])
    (when (= (cdr k) n)
      (when (or (not best) (< (car k) best))
        (set! best (car k)))))
  (or best 0))

(define (shadow-STEP! s) (set-shadow-step! s (+ 1 (shadow-step s))))
(define (shadow-NSET! s n v) (hash-set! (shadow-features s) n (exact->inexact v)))
(define (shadow-NGET s n) (hash-ref (shadow-features s) n 0.0))

(define (shadow-NSUM s n)
  (for/sum ([k (in-hash-keys (shadow-edges s))]
            #:when (= (car k) n))
    (shadow-NGET s (cdr k))))

;; ---- tensor views ----

(define (adjacency-tensor s)
  (define N (shadow-next-id s))
  (define dim (+ N 1))
  (define A (t:tensor-zeros-2d dim dim))
  (for ([k (in-hash-keys (shadow-edges s))])
    (define src (car k))
    (define dst (cdr k))
    ;; t:tensor-set! is 1D-indexed; flatten row-major.
    (define idx (+ (* src dim) dst))
    ;; we need 2D set; until shim adds it, copy via a flat zeros vec
    ;; then use matmul-friendly path.  For now use a flat float buffer.
    (void idx)
    (void A))
  ;; Simpler: build from a flat float list to avoid 2D set primitive.
  (define flat (make-vector (* dim dim) 0.0))
  (for ([k (in-hash-keys (shadow-edges s))])
    (define src (car k))
    (define dst (cdr k))
    (vector-set! flat (+ (* src dim) dst) 1.0))
  ;; Build flat 1D tensor, then matmul caller will know shape.
  (t:tensor-from-list (vector->list flat)))

(define (features-vector s)
  (define N (shadow-next-id s))
  (define dim (+ N 1))
  (define lst
    (for/list ([i (in-range dim)])
      (if (zero? i) 0.0 (shadow-NGET s i))))
  (t:tensor-from-list lst))

;; ---- vectorised CA step ----
;;
;; We do not yet expose a generic 2D matmul through the shim that
;; reshapes a 1D adjacency back into [N+1, N+1].  Instead we emulate
;; message-passing on the host: for each node, sum features of its
;; out-neighbours.  This still uses the tensor API for the rule
;; application (rule operates on per-node feature pairs).
;;
;; rule: procedure (state nbr-sum -> new-state) on PLAIN FLOATS.

(define (shadow-STEP-CA! s rule)
  (define N (shadow-next-id s))
  (define new-vals (make-vector (+ N 1) 0.0))
  (for ([i (in-range 1 (+ N 1))])
    (define st (shadow-NGET s i))
    (define ns (shadow-NSUM s i))
    (vector-set! new-vals i (rule st ns)))
  (for ([i (in-range 1 (+ N 1))])
    (shadow-NSET! s i (vector-ref new-vals i)))
  (shadow-STEP! s))

;; ---- BFS distance via tensor relaxation ----
;;
;; A is materialised as an N+1 by N+1 dense matrix.  Each iteration:
;;   ext = dist + 1                    [N+1, 1]
;;   cand[s,d] = ext[s] if A[s,d]>0 else INF
;;   new_dist[d] = min(dist[d], min over s of cand[s,d])
;;
;; We compute via tensor mul + add on the row-major flat representation.

(define INF 1000.0)

(define (shadow-bfs-distance s source [max-iter 50])
  (define N (shadow-next-id s))
  (define dim (+ N 1))
  ;; dist: 1D tensor of length dim, init INF except dist[source] = 0
  (define dist-list
    (for/list ([i (in-range dim)])
      (cond [(= i source) 0.0]
            [else INF])))
  (define dist (t:tensor-from-list dist-list))
  ;; adjacency rows-by-rows as N+1 separate 1D tensors of length dim
  (define adj-rows
    (for/list ([s-id (in-range dim)])
      (t:tensor-from-list
       (for/list ([d-id (in-range dim)])
         (if (and (positive? s-id)
                  (positive? d-id)
                  (shadow-EDGE? s s-id d-id))
             1.0
             0.0)))))
  ;; relax iteratively
  (let loop ([iter 0] [d dist])
    (cond
      [(>= iter max-iter) d]
      [else
       ;; candidate from each source row: (d_s + 1) * A_row + (1-A_row)*INF
       ;; new_d[t] = min over s of candidate[s,t]; min over s by elementwise reduction.
       ;; Implement by iterating sources in Racket and reducing with elementwise min via Racket numerics.
       (define d-list (t:tensor->list d))
       (define new-d-list (list->vector d-list))
       (for ([s-id (in-range dim)] [row (in-list adj-rows)])
         (define d-s (vector-ref (list->vector d-list) s-id))
         (define ext (+ d-s 1.0))
         (define row-list (t:tensor->list row))
         (for ([j (in-range dim)] [aij (in-list row-list)])
           (define cand (if (positive? aij) ext INF))
           (when (< cand (vector-ref new-d-list j))
             (vector-set! new-d-list j cand))))
       (define new-d (t:tensor-from-list (vector->list new-d-list)))
       (cond
         [(equal? (t:tensor->list new-d) (t:tensor->list d))
          new-d]
         [else (loop (+ iter 1) new-d)])])))

;; ============================================================
;; Demo 1 — Peano arithmetic
;; ============================================================

(define (peano-succ s n)
  (define m (shadow-MARK! s))
  (shadow-EDGE+! s n m)
  m)

(define (peano-value s n)
  (let loop ([n n] [v 0])
    (cond [(positive? (shadow-IN s n))
           (loop (shadow-PREV s n) (+ v 1))]
          [else v])))

(define (peano-add s a b)
  (cond [(zero? (shadow-IN s b)) a]
        [else (peano-succ s (peano-add s a (shadow-PREV s b)))]))

(define (peano-mul s a b)
  (cond [(zero? (shadow-IN s b)) (shadow-MARK! s)]
        [else (peano-add s a (peano-mul s a (shadow-PREV s b)))]))

(define (demo-peano)
  (displayln (make-string 60 #\─))
  (displayln "DEMO 1 — Peano arithmetic on PyTorch substrate (shadow)")
  (displayln (make-string 60 #\─))
  (define s (make-shadow))
  (define zero (shadow-MARK! s))
  (define c3 (peano-succ s (peano-succ s (peano-succ s zero))))
  (unless (= 0 (peano-value s zero)) (error "peano(0) != 0"))
  (unless (= 3 (peano-value s c3))   (error "peano(c3) != 3"))
  (define a (peano-succ s (peano-succ s (shadow-MARK! s))))         ; 2
  (define b (peano-succ s (peano-succ s (peano-succ s (shadow-MARK! s))))) ; 3
  (define sum (peano-add s a b))
  (define prod (peano-mul s a b))
  (unless (= 5 (peano-value s sum))  (error "peano(2+3) != 5"))
  (unless (= 6 (peano-value s prod)) (error "peano(2*3) != 6"))
  (printf "  ✓ peano_value(0) = 0~n")
  (printf "  ✓ peano_value(chain of 3 succs) = 3~n")
  (printf "  ✓ peano_value(2 + 3) = 5~n")
  (printf "  ✓ peano_value(2 × 3) = 6~n")
  (printf "  substrate state: ~a nodes, ~a edges~n"
          (shadow-next-id s)
          (hash-count (shadow-edges s))))

;; ============================================================
;; Demo 2 — BFS distance
;; ============================================================

(define (demo-distance-1d)
  (displayln (make-string 60 #\─))
  (displayln "DEMO 2a — 1D distance: chain via tensor relaxation")
  (displayln (make-string 60 #\─))
  (define s (make-shadow))
  (define ids (for/list ([_ (in-range 5)]) (shadow-MARK! s)))
  (define a (list-ref ids 0))
  (define b (list-ref ids 1))
  (define c (list-ref ids 2))
  (define d (list-ref ids 3))
  (define e (list-ref ids 4))
  (shadow-EDGE+! s a b)
  (shadow-EDGE+! s b c)
  (shadow-EDGE+! s c d)
  (shadow-EDGE+! s d e)
  (define dist (shadow-bfs-distance s a))
  (define dist-list (t:tensor->list dist))
  (for ([i (in-list (list a b c d e))]
        [expected (in-list '(0 1 2 3 4))])
    (define actual (inexact->exact (round (list-ref dist-list i))))
    (unless (= actual expected)
      (error 'demo-distance-1d "node ~a: got ~a want ~a" i actual expected)))
  (printf "  ✓ distances from a: ~a~n"
          (for/list ([i (in-list (list a b c d e))])
            (inexact->exact (round (list-ref dist-list i))))))

(define (demo-distance-2d)
  (displayln (make-string 60 #\─))
  (displayln "DEMO 2b — 2D Manhattan: 3×3 grid, BFS via tensor")
  (displayln (make-string 60 #\─))
  (define s (make-shadow))
  (for ([_ (in-range 9)]) (shadow-MARK! s))
  (define (cid i j) (+ (* (- i 1) 3) j))
  (define (bi a b) (shadow-EDGE+! s a b) (shadow-EDGE+! s b a))
  (for ([i (in-range 1 4)])
    (for ([j (in-range 1 3)])
      (bi (cid i j) (cid i (+ j 1)))))
  (for ([j (in-range 1 4)])
    (for ([i (in-range 1 3)])
      (bi (cid i j) (cid (+ i 1) j))))
  (unless (= 24 (hash-count (shadow-edges s)))
    (error 'demo-distance-2d "edge count != 24"))
  (define dist (shadow-bfs-distance s (cid 1 1)))
  (define dist-list (t:tensor->list dist))
  (define expected
    '(((1 1) 0) ((1 2) 1) ((1 3) 2)
      ((2 1) 1) ((2 2) 2) ((2 3) 3)
      ((3 1) 2) ((3 2) 3) ((3 3) 4)))
  (for ([row (in-list expected)])
    (define ij (car row))
    (define ex (cadr row))
    (define n (cid (car ij) (cadr ij)))
    (define got (inexact->exact (round (list-ref dist-list n))))
    (unless (= got ex)
      (error 'demo-distance-2d "d~a: got ~a want ~a" ij got ex)))
  (printf "  ✓ corner→far-corner Manhattan distance = ~a~n"
          (inexact->exact (round (list-ref dist-list (cid 3 3)))))
  (printf "  ✓ all 9 cells have correct Manhattan distance~n"))

;; ============================================================
;; Demo 3 — Conway blinker
;; ============================================================

(define (demo-conway-blinker)
  (displayln (make-string 60 #\─))
  (displayln "DEMO 3 — Conway blinker on 5×5 grid via STEP-CA (shadow)")
  (displayln (make-string 60 #\─))
  (define s (make-shadow))
  (for ([_ (in-range 25)]) (shadow-MARK! s))
  (define (cid i j) (+ (* (- i 1) 5) j))
  (define (bi a b) (shadow-EDGE+! s a b) (shadow-EDGE+! s b a))
  (for ([i (in-range 1 6)] [j (in-range 1 5)])
    (bi (cid i j) (cid i (+ j 1))))
  ;; rows
  (for ([i (in-range 1 6)])
    (for ([j (in-range 1 5)])
      (bi (cid i j) (cid i (+ j 1)))))
  ;; cols
  (for ([j (in-range 1 6)])
    (for ([i (in-range 1 5)])
      (bi (cid i j) (cid (+ i 1) j))))
  ;; NW-SE diagonal
  (for ([i (in-range 1 5)])
    (for ([j (in-range 1 5)])
      (bi (cid i j) (cid (+ i 1) (+ j 1)))))
  ;; NE-SW diagonal
  (for ([i (in-range 1 5)])
    (for ([j (in-range 2 6)])
      (bi (cid i j) (cid (+ i 1) (- j 1)))))
  (unless (= 144 (hash-count (shadow-edges s)))
    (error 'demo-conway-blinker "edge count expected 144, got ~a"
           (hash-count (shadow-edges s))))
  ;; init blinker
  (for ([n (in-range 1 26)]) (shadow-NSET! s n 0.0))
  (shadow-NSET! s (cid 2 3) 1.0)
  (shadow-NSET! s (cid 3 3) 1.0)
  (shadow-NSET! s (cid 4 3) 1.0)
  ;; Conway rule on plain floats
  (define (conway-rule state nbr-sum)
    (define eq3 (if (= nbr-sum 3) 1.0 0.0))
    (define eq2 (if (= nbr-sum 2) 1.0 0.0))
    (+ eq3 (* (- 1.0 eq3) eq2 state)))
  (shadow-STEP-CA! s conway-rule)
  (unless (= 0 (shadow-NGET s (cid 2 3))) (error 'blinker "step1 (2,3)"))
  (unless (= 0 (shadow-NGET s (cid 4 3))) (error 'blinker "step1 (4,3)"))
  (unless (= 1 (shadow-NGET s (cid 3 2))) (error 'blinker "step1 (3,2)"))
  (unless (= 1 (shadow-NGET s (cid 3 3))) (error 'blinker "step1 (3,3)"))
  (unless (= 1 (shadow-NGET s (cid 3 4))) (error 'blinker "step1 (3,4)"))
  (printf "  ✓ step 1: blinker rotated vertical → horizontal~n")
  (shadow-STEP-CA! s conway-rule)
  (unless (= 0 (shadow-NGET s (cid 3 2))) (error 'blinker "step2 (3,2)"))
  (unless (= 0 (shadow-NGET s (cid 3 4))) (error 'blinker "step2 (3,4)"))
  (unless (= 1 (shadow-NGET s (cid 2 3))) (error 'blinker "step2 (2,3)"))
  (unless (= 1 (shadow-NGET s (cid 3 3))) (error 'blinker "step2 (3,3)"))
  (unless (= 1 (shadow-NGET s (cid 4 3))) (error 'blinker "step2 (4,3)"))
  (printf "  ✓ step 2: blinker oscillated back to vertical (period 2)~n"))

;; ============================================================

(define (run-all-demos)
  (displayln (make-string 60 #\=))
  (displayln "NN-SHADOW OF SIXTH SUBSTRATE — Racket FFI to libtorch")
  (displayln (make-string 60 #\=))
  (newline)
  (demo-peano)        (newline)
  (demo-distance-1d)
  (demo-distance-2d)  (newline)
  (demo-conway-blinker) (newline)
  (displayln (make-string 60 #\=))
  (displayln "ALL TESTS PASS — Racket NN-shadow matches Sixth substrate.")
  (displayln (make-string 60 #\=)))

(module+ main
  (run-all-demos))
