#lang racket/base

;; sixth/bridges/torch/diff.rkt — DIFFERENTIABLE substrate.
;; Ports legacy/substrate_torch_diff.py.
;;
;; Substrate adjacency and features live as autograd tensors; STEP-CA,
;; NSUM, and BFS are differentiable.  Two demos:
;;   A — gradient flows through NSUM (message passing on adjacency).
;;   B — gradient descent on initial state to reach a target via
;;       a linear-diffusion rule.
;;
;; Demo C (MLP rule learning) requires nn.Sequential / Adam, which is
;; outside the scope of this minimal FFI.  See nn.rkt for the planned
;; surface.

(provide make-diff-substrate
         diff-add-edge!
         diff-bi-edge!
         diff-set-features!
         diff-features
         diff-nsum
         diff-step-ca!
         demo-grad-through-nsum
         demo-learn-initial
         run-all-demos)

(require racket/list
         (prefix-in t: "tensor.rkt"))

;; A DiffSubstrate carries:
;;   - N            : node count (ids 1..N)
;;   - adjacency    : t:tensor of shape (N+1, N+1), float32
;;   - features     : t:tensor of shape (N+1,), float32 (may require_grad)
;; Adjacency is structural and not differentiable; features may be.

(struct diff-substrate
  (N
   [adj      #:mutable]
   [features #:mutable]))

(define (make-diff-substrate N)
  (diff-substrate
   N
   (t:tensor-zeros-2d (+ N 1) (+ N 1))
   (t:tensor-zeros (+ N 1))))

(define (diff-add-edge! d s dst [w 1.0])
  (t:tensor-set-2d! (diff-substrate-adj d) s dst w))

(define (diff-bi-edge! d a b [w 1.0])
  (diff-add-edge! d a b w)
  (diff-add-edge! d b a w))

(define (diff-set-features! d x) (set-diff-substrate-features! d x))
(define (diff-features d) (diff-substrate-features d))

(define (diff-nsum d)
  (t:t-matmul (diff-substrate-adj d) (diff-substrate-features d)))

(define (diff-step-ca! d rule)
  (define nbr (diff-nsum d))
  (define new-x (rule (diff-substrate-features d) nbr))
  (set-diff-substrate-features! d new-x))

;; ============================================================
;; Demo A — gradient through NSUM
;; ============================================================

(define (demo-grad-through-nsum)
  (displayln (make-string 60 #\─))
  (displayln "DEMO A — gradient flows through NSUM (message passing)")
  (displayln (make-string 60 #\─))
  (define sub (make-diff-substrate 4))
  (diff-add-edge! sub 1 2)
  (diff-add-edge! sub 1 3)
  (diff-add-edge! sub 1 4)
  (define x (t:tensor-from-list '(0.0 0.0 1.0 2.0 3.0)))
  (t:tensor-requires-grad! x)
  (diff-set-features! sub x)
  (define nbr (diff-nsum sub))
  ;; node 1's neighbour-sum should equal x[2]+x[3]+x[4] = 6
  (define target (t:tensor-index1 nbr 1))
  (define target-val (t:tensor-item target))
  (printf "  ✓ NSUM(node 1) = ~a (expected 6)~n" target-val)
  (unless (< (abs (- target-val 6.0)) 1e-5)
    (error 'demo-A "NSUM value mismatch: got ~a, want 6" target-val))
  (t:tensor-backward! target)
  (define g (t:tensor-grad x))
  (define gs (t:tensor->list g))
  ;; gradient should be (0 0 1 1 1) — each of x[2..4] contributed 1
  (printf "  ✓ ∂NSUM(1)/∂x = ~a (expected (0 0 1 1 1))~n" gs)
  (for ([i (in-list '(2 3 4))])
    (unless (< (abs (- (list-ref gs i) 1.0)) 1e-5)
      (error 'demo-A "grad[~a] != 1" i))))

;; ============================================================
;; Demo B — learn initial state via diffusion to reach a target
;; ============================================================
;;
;; Diffusion rule: next = 0.5*x + 0.25*nbr.  After 3 steps we want
;; cell 6 ≈ 1.0 and cell 1 ≈ 0.0.  Gradient descent on the initial
;; feature vector via plain SGD (no Adam shim yet).

(define (diffusion-rule x nbr)
  (t:t+ (t:t*scalar x 0.5) (t:t*scalar nbr 0.25)))

(define (chain-substrate N)
  (define d (make-diff-substrate N))
  (for ([i (in-range 1 N)])
    (diff-bi-edge! d i (+ i 1)))
  d)

(define (build-diffusion-loss init-tensor)
  ;; Apply 3 diffusion steps starting from init-tensor, return scalar loss.
  (define N 11)
  (define sub (chain-substrate N))
  (diff-set-features! sub init-tensor)
  (diff-step-ca! sub diffusion-rule)
  (diff-step-ca! sub diffusion-rule)
  (diff-step-ca! sub diffusion-rule)
  (define x (diff-features sub))
  (define x6 (t:tensor-index1 x 6))      ; should approach 1.0
  (define x1 (t:tensor-index1 x 1))      ; should approach 0.0
  (define err6 (t:t-pow2 (t:t-scalar x6 1.0)))
  (define err1 (t:t-pow2 x1))
  (t:t+ err6 err1))

(define (init-with-grad N value)
  (define t (t:tensor-from-list
             (for/list ([_ (in-range N)]) value)))
  (t:tensor-requires-grad! t)
  t)

(define (demo-learn-initial)
  (displayln (make-string 60 #\─))
  (displayln "DEMO B — gradient descent on initial state via diffusion rule")
  (displayln (make-string 60 #\─))
  (define N 11)
  (define lr 0.05)
  (define init (init-with-grad (+ N 1) 0.1))
  (define loss0
    (let ([l (build-diffusion-loss init)])
      (t:tensor-item l)))
  ;; SGD loop: at each step build the loss, backprop, manually update init.
  (define final-loss
    (for/fold ([last #f]) ([step (in-range 100)])
      (define loss-t (build-diffusion-loss init))
      (t:tensor-backward! loss-t)
      (define g (t:tensor-grad init))
      ;; init <- init - lr * grad  (manual SGD, with grad detached)
      (define new-init-vals
        (for/list ([v (in-list (t:tensor->list init))]
                   [gv (in-list (t:tensor->list g))])
          (- v (* lr gv))))
      (define new-t (t:tensor-from-list new-init-vals))
      (t:tensor-requires-grad! new-t)
      (set! init new-t)
      (t:tensor-item loss-t)))
  (printf "  initial loss: ~a~n" (real->decimal-string loss0 4))
  (printf "  final loss:   ~a~n" (real->decimal-string final-loss 4))
  (printf "  learned init: ~a~n"
          (for/list ([v (in-list (cdr (t:tensor->list init)))])
            (real->decimal-string v 2)))
  ;; sanity-check the trained init reproduces the target
  (define sub (chain-substrate N))
  (diff-set-features! sub init)
  (diff-step-ca! sub diffusion-rule)
  (diff-step-ca! sub diffusion-rule)
  (diff-step-ca! sub diffusion-rule)
  (define xs (t:tensor->list (diff-features sub)))
  (printf "  after 3 steps: cell 6 = ~a (target 1.0); cell 1 = ~a (target 0.0)~n"
          (real->decimal-string (list-ref xs 6) 3)
          (real->decimal-string (list-ref xs 1) 3))
  (unless (< final-loss 0.01)
    (error 'demo-B "loss did not converge: final=~a" final-loss)))

;; ============================================================

(define (run-all-demos)
  (displayln (make-string 60 #\=))
  (displayln "DIFFERENTIABLE SUBSTRATE — Racket FFI + libtorch autograd")
  (displayln (make-string 60 #\=))
  (newline)
  (demo-grad-through-nsum)  (newline)
  (demo-learn-initial)      (newline)
  (displayln (make-string 60 #\=))
  (displayln "ALL DIFFERENTIABILITY DEMOS PASS — substrate ↔ NN bridge.")
  (displayln (make-string 60 #\=)))

(module+ main
  (run-all-demos))
