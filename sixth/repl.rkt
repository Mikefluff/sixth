#lang racket/base

;; sixth/repl.rkt — interactive shell.
;; Status: Phase A skeleton; real impl in Phase C.

(provide repl)

(require (prefix-in m: "main.rkt"))

(define (repl)
  (printf "sixth REPL ~a — Phase C will implement.~n" (m:sixth-version))
  (printf "(stub)  sixth> ")
  (let loop ()
    (define line (read-line))
    (cond
      [(eof-object? line) (newline)]
      [(or (equal? line "quit") (equal? line "q")) (printf "Bye.~n")]
      [else
       (printf "  not yet implemented: ~a~n" line)
       (printf "(stub)  sixth> ")
       (loop)])))
