#lang racket/base

;; sixth/values.rkt — tagged value union for Sixth runtime.
;;
;; Sixth has a small set of value types.  Each is a Racket value of a
;; specific structural shape:
;;
;;   INT     — exact-integer?            (base numeric)
;;   FLOAT   — flonum?                   (substrate features, autograd)
;;   BOOL    — 0 or 1                    (Forth convention)
;;   SYM     — symbol?                   (quoted word names, memory keys)
;;   STR     — string?                   (real string literals)
;;   NODE    — (node id)                 (substrate node id)
;;   EDGE    — (edge src dst)            (substrate edge)
;;   LIST    — list?                     (heterogeneous list)
;;   TENSOR  — (tensor ptr shape)        (only when bridges loaded)
;;
;; Type tags are checked at primitive call sites via the `expect-*`
;; helpers, which raise `exn:fail:sixth:type` with source-location info
;; on mismatch.
;;
;; Status: Phase A skeleton.  Real implementations land in Phase C / D.

(provide
  (struct-out node)
  (struct-out edge)
  (struct-out tensor)
  value-tag
  value->display)

(struct node   (id)              #:transparent)
(struct edge   (src dst)         #:transparent)
(struct tensor (ptr shape)       #:transparent)

;; Returns a symbol describing the tag of a Sixth value.
(define (value-tag v)
  (cond
    [(exact-integer? v) 'INT]
    [(and (real? v) (inexact? v)) 'FLOAT]
    [(string? v) 'STR]
    [(symbol? v) 'SYM]
    [(node? v) 'NODE]
    [(edge? v) 'EDGE]
    [(tensor? v) 'TENSOR]
    [(list? v) 'LIST]
    [else 'UNKNOWN]))

;; How a Sixth value renders when printed via `.`
(define (value->display v)
  (cond
    [(node? v) (format "#n~a" (node-id v))]
    [(edge? v) (format "#e~a→~a" (edge-src v) (edge-dst v))]
    [(tensor? v) (format "#t~a" (tensor-shape v))]
    [(string? v) v]
    [(symbol? v) (symbol->string v)]
    [else (format "~a" v)]))
