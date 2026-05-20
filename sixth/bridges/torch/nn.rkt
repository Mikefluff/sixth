#lang racket/base

;; sixth/bridges/torch/nn.rkt — DELIBERATELY NOT a port of
;; legacy/substrate_nn_cl.py.
;;
;; That Python file is a standard GNN with substrate-themed variable
;; names:
;;   "substrate memory"    = nn.Parameter(torch.randn(M, D))
;;   "substrate adjacency" = top-K-masked attention scores
;;   "substrate update"    = K-round GNN message passing
;;   "per-task observer"   = softmax attention pointer
;;   "freeze substrate"    = requires_grad = False
;;
;; Porting it would give us PyTorch-with-substrate-vocabulary in
;; Racket — three thousand lines of FFI binding for an architecture
;; that doesn't use a single substrate primitive.
;;
;; Substrate-native learning lives in examples/21-substrate-autodiff.6th
;; onwards.  Those demos build autodiff, SGD, MLPs, meta-learning, and
;; continual learning from the substrate's 38 primitives + a tiny
;; extension for gradient-channel features, with no torch dependency
;; for architecture (only for accelerated execution via shadow.rkt and
;; diff.rkt).
;;
;; The legacy Python implementation remains usable for production
;; training; this Racket bridge is intentionally a stub so future code
;; can import a stable name without committing to the rebrand.

(provide rebrand-note
         substrate-native-roadmap)

(define (rebrand-note)
  (displayln "─────────────────────────────────────────────────────────")
  (displayln "sixth/bridges/torch/nn.rkt — substrate-native NN policy")
  (displayln "─────────────────────────────────────────────────────────")
  (displayln "legacy/substrate_nn_cl.py is a standard GNN with substrate-")
  (displayln "themed variable names.  Substrate-native NN architectures")
  (displayln "live in examples/21..25 and use only substrate primitives.")
  (displayln "Run them with: racket -l sixth/cli -- run examples/21-...")
  (displayln "─────────────────────────────────────────────────────────"))

(define (substrate-native-roadmap)
  '((21 substrate-autodiff
        "Reverse-mode AD as STEP-CA on reversed substrate.")
    (22 substrate-linreg
        "y = Wx + b trained by substrate-native SGD.")
    (23 substrate-mlp-xor
        "2-2-1 MLP for XOR, substrate-only forward + backward.")
    (24 substrate-meta-learner
        "Observer node observes its own gradients; rewrites update rule.")
    (25 substrate-continual
        "Continual learning by observer expansion, no freeze protocol.")))
