#lang racket/base

;; sixth/cli.rkt — command-line entry-point.
;; Invoked via `racket -l sixth/cli -- <args>`.
;;
;; Subcommands:
;;   repl                  launch interactive shell
;;   run <file>            load and execute a .6th source file
;;   test                  hand off to `raco test sixth`
;;   bench                 run perf benchmarks (Phase I)

(require racket/cmdline
         (only-in "main.rkt" sixth-version)
         "env.rkt"
         "loader.rkt"
         "primitives/base.rkt"
         "primitives/substrate.rkt")

(define no-prelude? (make-parameter #f))

(define (make-runtime-env)
  (define e (make-env))
  (register-base! e)
  (register-substrate! e)
  (unless (no-prelude?)
    (use-module! "prelude" e))
  e)

(define (cmd-repl)
  (printf "sixth REPL ~a — minimal shell. EOF or `quit` to exit.~n"
          (sixth-version))
  (define e (make-runtime-env))
  (let loop ()
    (display "sixth> ")
    (flush-output)
    (define line (read-line))
    (cond
      [(eof-object? line) (newline)]
      [(or (equal? line "quit") (equal? line "q") (equal? line "exit"))
       (printf "Bye.~n")]
      [else
       (with-handlers ([exn:fail? (lambda (e)
                                     (printf "ERR: ~a~n" (exn-message e)))])
         (load-source line e))
       (printf "  stack: ~v~n" (env-stack e))
       (loop)])))

(define (cmd-run path)
  (define e (make-runtime-env))
  (load-file path e))

(define (cmd-test)
  (printf "sixth test — run `raco test sixth tests`~n")
  (exit 0))

(define (cmd-bench)
  (printf "sixth bench — Phase I will wire this~n")
  (exit 1))

(module+ main
  (command-line
   #:program "sixth"
   #:once-each
   [("--no-prelude") "skip auto-loading prelude" (no-prelude? #t)]
   #:args args
   (cond
     [(null? args) (cmd-repl)]
     [(equal? (car args) "repl") (cmd-repl)]
     [(equal? (car args) "run")
      (when (null? (cdr args))
        (printf "usage: sixth run <file.6th>~n") (exit 2))
      (cmd-run (cadr args))]
     [(equal? (car args) "test") (cmd-test)]
     [(equal? (car args) "bench") (cmd-bench)]
     [else
      ;; default: treat first arg as a .6th file to run
      (cmd-run (car args))])))
