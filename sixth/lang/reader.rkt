#lang s-exp syntax/module-reader

sixth/lang
#:read sixth-read
#:read-syntax sixth-read-syntax
#:whole-body-readers? #t

(require racket/port)

(define (sixth-read in)
  (list (port->string in)))

(define (sixth-read-syntax src in)
  (list (datum->syntax #f (port->string in))))
