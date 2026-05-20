#lang racket/base

;; sixth/reader.rkt — Racket reader for `#lang sixth`.

(provide read read-syntax)

(require syntax/strip-context
         racket/port)

(define (read in)
  (syntax->datum (read-syntax #f in)))

(define (read-syntax src in)
  (define body-str (port->string in))
  (strip-context
   #`(module sixth-module sixth/lang
       #,body-str)))
