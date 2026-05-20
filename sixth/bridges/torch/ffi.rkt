#lang racket/base

;; sixth/bridges/torch/ffi.rkt — racket/foreign bindings to
;; libsixth_torch.dylib, which is a thin C++ shim over libtorch.
;;
;; If the dylib is not present, requiring this module raises
;; exn:fail:sixth:torch-not-installed with a build hint.

(provide (all-defined-out))

(require ffi/unsafe
         ffi/unsafe/define
         racket/runtime-path)

(define-runtime-path here ".")

(define lib-path
  (build-path here "../../../build/libsixth_torch.dylib"))

(struct exn:fail:sixth:torch-not-installed exn:fail ())

(define lib
  (with-handlers
    ([exn:fail?
      (lambda (e)
        (raise
         (exn:fail:sixth:torch-not-installed
          (format
           "libsixth_torch.dylib not found.  Build it with:\n  sh sixth/bridges/torch/native/build.sh\n  (expected at ~a)\nOriginal error: ~a"
           lib-path (exn-message e))
          (current-continuation-marks))))])
    (ffi-lib lib-path)))

(define-ffi-definer define-st lib)

;; ---- opaque tensor handle ----
(define _st_tensor-pointer (_cpointer/null 'st_tensor))

;; ---- versioning ----
(define-st st_version (_fun -> _string))

;; ---- construction ----
(define-st st_zeros1     (_fun _int64 -> _st_tensor-pointer))
(define-st st_ones1      (_fun _int64 -> _st_tensor-pointer))
(define-st st_zeros2     (_fun _int64 _int64 -> _st_tensor-pointer))
(define-st st_from_floats (_fun _pointer _int64 -> _st_tensor-pointer))
(define-st st_from_int64  (_fun _pointer _int64 -> _st_tensor-pointer))
(define-st st_arange     (_fun _int64 -> _st_tensor-pointer))
(define-st st_clone      (_fun _st_tensor-pointer -> _st_tensor-pointer))

;; ---- destruction ----
(define-st st_tensor_free (_fun _st_tensor-pointer -> _void))

;; ---- shape / dtype ----
(define-st st_ndim       (_fun _st_tensor-pointer -> _int64))
(define-st st_size       (_fun _st_tensor-pointer _int64 -> _int64))
(define-st st_numel      (_fun _st_tensor-pointer -> _int64))
(define-st st_dtype_code (_fun _st_tensor-pointer -> _int))

;; ---- element access ----
(define-st st_item_float (_fun _st_tensor-pointer -> _float))
(define-st st_item_int64 (_fun _st_tensor-pointer -> _int64))
(define-st st_get1_float (_fun _st_tensor-pointer _int64 -> _float))
(define-st st_get1_int64 (_fun _st_tensor-pointer _int64 -> _int64))
(define-st st_set1_float (_fun _st_tensor-pointer _int64 _float -> _void))
(define-st st_set1_int64 (_fun _st_tensor-pointer _int64 _int64 -> _void))

;; ---- arithmetic ----
(define-st st_add     (_fun _st_tensor-pointer _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_sub     (_fun _st_tensor-pointer _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_mul     (_fun _st_tensor-pointer _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_div     (_fun _st_tensor-pointer _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_matmul  (_fun _st_tensor-pointer _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_sum     (_fun _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_relu    (_fun _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_sigmoid (_fun _st_tensor-pointer -> _st_tensor-pointer))
(define-st st_neg     (_fun _st_tensor-pointer -> _st_tensor-pointer))

;; ---- scalar arithmetic ----
(define-st st_mul_scalar (_fun _st_tensor-pointer _float -> _st_tensor-pointer))
(define-st st_add_scalar (_fun _st_tensor-pointer _float -> _st_tensor-pointer))
(define-st st_sub_scalar (_fun _st_tensor-pointer _float -> _st_tensor-pointer))
(define-st st_pow2       (_fun _st_tensor-pointer -> _st_tensor-pointer))

;; ---- 2D ----
(define-st st_from_floats_2d (_fun _pointer _int64 _int64 -> _st_tensor-pointer))
(define-st st_get2_float     (_fun _st_tensor-pointer _int64 _int64 -> _float))
(define-st st_set2_float     (_fun _st_tensor-pointer _int64 _int64 _float -> _void))

;; ---- indexing (preserves grad) ----
(define-st st_index1 (_fun _st_tensor-pointer _int64 -> _st_tensor-pointer))

;; ---- autograd ----
(define-st st_set_requires_grad (_fun _st_tensor-pointer _int -> _void))
(define-st st_requires_grad     (_fun _st_tensor-pointer -> _int))
(define-st st_backward          (_fun _st_tensor-pointer -> _void))
(define-st st_grad              (_fun _st_tensor-pointer -> _st_tensor-pointer))

;; ---- printing ----
(define-st st_print (_fun _st_tensor-pointer -> _void))
