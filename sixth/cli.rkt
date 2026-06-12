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
         racket/list
         racket/string
         (only-in "main.rkt" sixth-version)
         "env.rkt"
         "loader.rkt"
         "vm.rkt"
         "primitives/base.rkt"
         "primitives/substrate.rkt"
         "meta/runtime.rkt"
         "meta/tier1.rkt"
         "meta/tier2.rkt"
         "meta/test-harness.rkt"
         "meta/bootstrap.rkt"
         "meta/arena.rkt"
         "meta/triggers.rkt")

(define no-prelude? (make-parameter #f))
(define defines    (make-parameter '()))   ; list of (cons KEY VAL)

;; --define KEY=VAL pre-populates a memory key before the file runs.
;; Value is parsed as integer when possible, otherwise stored as
;; string.  Used to parameterise demos that read e.g. `"max-cycles"
;; load` for long-epoch runs.
(define (parse-define arg)
  (define eq (string-split arg "="))
  (cond
    [(< (length eq) 2)
     (printf "ERR: --define expects KEY=VAL, got `~a`~n" arg)
     (exit 2)]
    [else
     (define key (car eq))
     (define raw (string-join (cdr eq) "="))
     (define val (or (string->number raw) raw))
     (defines (cons (cons key val) (defines)))]))

(define (apply-defines! e)
  (for ([kv (in-list (reverse (defines)))])
    (env-store! e (car kv) (cdr kv))))

(define (make-runtime-env)
  (define e (make-env))
  (register-base! e)
  (register-substrate! e)
  (install-meta-runtime! e)
  (register-tier1! e)
  (register-tier2! e)
  ;; Cycle 32: test-harness primitives are always REGISTERED but
  ;; GATED behind ENABLE-TEST-HARNESS.  Without that call, any
  ;; REBIND-CAND-BODY invocation raises + contaminates the target.
  (register-test-harness! e)
  ;; Cycle 36B: BOOTSTRAP-RESET / BOOTSTRAP-LAW-HASH primitives.
  (register-bootstrap! e)
  (register-arena! e)
  ;; Cycle 37: pattern-triggered laws (BIND-TRIGGER / WORLD-TICK).
  (register-triggers! e)
  (unless (no-prelude?)
    (use-module! "prelude" e))
  (apply-defines! e)
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
  ;; Bind all three meta-runtime hooks:
  ;;   - current-engine-trace populates env's _trace box (cycle 25A)
  ;;   - current-cand-dispatch-hook bumps cand use counter (25D item 10)
  ;;   - current-cand-nested-hook records runtime-observed deps (cycle 32)
  (parameterize ([current-engine-trace      (trace-of e)]
                 [current-cand-dispatch-hook (make-cand-dispatch-hook)]
                 [current-cand-nested-hook   (make-cand-nested-hook)])
    (load-file path e)))

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
   #:multi
   [("-D" "--define") kv "set memory key (repeatable; KEY=VAL)" (parse-define kv)]
   #:args args
   (cond
     [(null? args) (cmd-repl)]
     [(equal? (car args) "repl") (cmd-repl)]
     [(equal? (car args) "run")
      (when (null? (cdr args))
        (printf "usage: sixth run [--define KEY=VAL]... <file.6th>~n") (exit 2))
      (cmd-run (cadr args))]
     [(equal? (car args) "test") (cmd-test)]
     [(equal? (car args) "bench") (cmd-bench)]
     [else
      ;; default: treat first arg as a .6th file to run
      (cmd-run (car args))])))
