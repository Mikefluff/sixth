#lang racket/base

;; sixth/bridges/torch/tensor.rkt — Racket-side ergonomic wrappers
;; around the raw FFI bindings.  Adds:
;;   - finalizers (GC frees the underlying torch::Tensor)
;;   - convenience constructors that accept Racket lists/vectors
;;   - struct-style printing
;;
;; Tensors are values of struct `tensor`; the raw FFI pointer lives in
;; the field `tensor-ptr`.  Use `tensor-from-list`, `tensor-zeros`,
;; etc. rather than calling FFI directly.

(provide tensor?
         tensor-ptr
         tensor-zeros
         tensor-ones
         tensor-zeros-2d
         tensor-from-list
         tensor-from-list-2d
         tensor-from-int-list
         tensor-arange
         tensor-clone
         tensor-ndim
         tensor-size
         tensor-numel
         tensor-dtype
         tensor-item
         tensor-ref
         tensor-ref-2d
         tensor-set!
         tensor-set-2d!
         tensor-index1
         tensor->list
         tensor-print
         t+ t- t* t/ t-matmul t-sum t-relu t-sigmoid t-neg
         t*scalar t+scalar t-scalar t-pow2
         tensor-requires-grad!
         tensor-requires-grad?
         tensor-backward!
         tensor-grad)

(require ffi/unsafe
         (prefix-in raw: "ffi.rkt"))

(struct tensor (ptr)
  #:methods gen:custom-write
  [(define (write-proc t port mode)
     (define p (tensor-ptr t))
     (cond
       [(not p) (fprintf port "#<tensor:freed>")]
       [else
        (define dt (raw:st_dtype_code p))
        (define n  (raw:st_numel p))
        (fprintf port "#<tensor:~a ~a elem>"
                 (case dt [(0) 'f32] [(1) 'i64] [else 'other])
                 n)]))])

(define (wrap! ptr)
  (define t (tensor ptr))
  (register-finalizer t
                      (lambda (self)
                        (when (tensor-ptr self)
                          (raw:st_tensor_free (tensor-ptr self)))))
  t)

;; ---- constructors ----

(define (tensor-zeros n)       (wrap! (raw:st_zeros1 n)))
(define (tensor-ones  n)       (wrap! (raw:st_ones1 n)))
(define (tensor-zeros-2d r c)  (wrap! (raw:st_zeros2 r c)))
(define (tensor-arange end)    (wrap! (raw:st_arange end)))
(define (tensor-clone t)       (wrap! (raw:st_clone (tensor-ptr t))))

(define (tensor-from-list lst)
  (define n (length lst))
  (define buf (malloc _float n 'atomic))
  (for ([v (in-list lst)] [i (in-naturals)])
    (ptr-set! buf _float i (exact->inexact v)))
  (wrap! (raw:st_from_floats buf n)))

(define (tensor-from-int-list lst)
  (define n (length lst))
  (define buf (malloc _int64 n 'atomic))
  (for ([v (in-list lst)] [i (in-naturals)])
    (ptr-set! buf _int64 i v))
  (wrap! (raw:st_from_int64 buf n)))

;; ---- shape / dtype ----

(define (tensor-ndim t)         (raw:st_ndim (tensor-ptr t)))
(define (tensor-size t dim)     (raw:st_size (tensor-ptr t) dim))
(define (tensor-numel t)        (raw:st_numel (tensor-ptr t)))
(define (tensor-dtype t)
  (case (raw:st_dtype_code (tensor-ptr t))
    [(0) 'float32] [(1) 'int64] [else 'other]))

;; ---- element access ----

(define (tensor-item t)
  (case (tensor-dtype t)
    [(float32) (raw:st_item_float (tensor-ptr t))]
    [(int64)   (raw:st_item_int64 (tensor-ptr t))]
    [else (error 'tensor-item "unsupported dtype")]))

(define (tensor-ref t i)
  (case (tensor-dtype t)
    [(float32) (raw:st_get1_float (tensor-ptr t) i)]
    [(int64)   (raw:st_get1_int64 (tensor-ptr t) i)]
    [else (error 'tensor-ref "unsupported dtype")]))

(define (tensor-set! t i v)
  (case (tensor-dtype t)
    [(float32) (raw:st_set1_float (tensor-ptr t) i (exact->inexact v))]
    [(int64)   (raw:st_set1_int64 (tensor-ptr t) i v)]
    [else (error 'tensor-set! "unsupported dtype")]))

(define (tensor->list t)
  (for/list ([i (in-range (tensor-numel t))])
    (tensor-ref t i)))

(define (tensor-print t) (raw:st_print (tensor-ptr t)))

;; ---- arithmetic ----

(define (t+ a b)        (wrap! (raw:st_add     (tensor-ptr a) (tensor-ptr b))))
(define (t- a b)        (wrap! (raw:st_sub     (tensor-ptr a) (tensor-ptr b))))
(define (t* a b)        (wrap! (raw:st_mul     (tensor-ptr a) (tensor-ptr b))))
(define (t/ a b)        (wrap! (raw:st_div     (tensor-ptr a) (tensor-ptr b))))
(define (t-matmul a b)  (wrap! (raw:st_matmul  (tensor-ptr a) (tensor-ptr b))))
(define (t-sum a)       (wrap! (raw:st_sum     (tensor-ptr a))))
(define (t-relu a)      (wrap! (raw:st_relu    (tensor-ptr a))))
(define (t-sigmoid a)   (wrap! (raw:st_sigmoid (tensor-ptr a))))
(define (t-neg a)       (wrap! (raw:st_neg     (tensor-ptr a))))

;; ---- scalar ops ----
(define (t*scalar a v)  (wrap! (raw:st_mul_scalar (tensor-ptr a) (exact->inexact v))))
(define (t+scalar a v)  (wrap! (raw:st_add_scalar (tensor-ptr a) (exact->inexact v))))
(define (t-scalar a v)  (wrap! (raw:st_sub_scalar (tensor-ptr a) (exact->inexact v))))
(define (t-pow2 a)      (wrap! (raw:st_pow2       (tensor-ptr a))))

;; ---- 2D constructors / access ----
(define (tensor-from-list-2d rows-of-rows)
  (define rows (length rows-of-rows))
  (define cols (length (car rows-of-rows)))
  (define n (* rows cols))
  (define buf (malloc _float n 'atomic))
  (define i 0)
  (for ([r (in-list rows-of-rows)])
    (for ([v (in-list r)])
      (ptr-set! buf _float i (exact->inexact v))
      (set! i (+ i 1))))
  (wrap! (raw:st_from_floats_2d buf rows cols)))

(define (tensor-ref-2d t i j)  (raw:st_get2_float (tensor-ptr t) i j))
(define (tensor-set-2d! t i j v) (raw:st_set2_float (tensor-ptr t) i j (exact->inexact v)))

;; ---- gradient-preserving 1D index ----
(define (tensor-index1 t i) (wrap! (raw:st_index1 (tensor-ptr t) i)))

;; ---- autograd ----

(define (tensor-requires-grad! t [flag #t])
  (raw:st_set_requires_grad (tensor-ptr t) (if flag 1 0)))

(define (tensor-requires-grad? t)
  (not (zero? (raw:st_requires_grad (tensor-ptr t)))))

(define (tensor-backward! t) (raw:st_backward (tensor-ptr t)))

(define (tensor-grad t)
  (define g (raw:st_grad (tensor-ptr t)))
  (and g (wrap! g)))
