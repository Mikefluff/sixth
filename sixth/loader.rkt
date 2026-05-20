#lang racket/base

;; sixth/loader.rkt — file loader + `use` module resolution.

(provide
  load-file
  load-source
  use-module!
  current-sixth-path)

(require racket/path
         racket/runtime-path
         "lexer.rkt"
         "parser.rkt"
         "compiler.rkt"
         "vm.rkt"
         "env.rkt"
         "errors.rkt"
         "ast.rkt")

(define-runtime-path stdlib-dir "../stdlib")

(define current-sixth-path
  (make-parameter
   (list (path->complete-path stdlib-dir))))

;; Per-env loaded-modules cache, keyed by env identity.
;; (Avoids cross-test pollution of a global parameter.)
(define env-load-cache (make-weak-hasheq))

(define (loaded? env path)
  (define h (hash-ref env-load-cache env #f))
  (and h (hash-has-key? h path)))

(define (mark-loaded! env path)
  (define h (hash-ref! env-load-cache env (lambda () (make-hash))))
  (hash-set! h path #t))

(define (resolve-module-path name [from-file #f])
  (define candidates
    (append
     (if from-file
         (list (build-path (path-only (path->complete-path from-file))
                            (string-append name ".6th")))
         '())
     (list (build-path (current-directory) (string-append name ".6th")))
     (for/list ([p (in-list (current-sixth-path))])
       (build-path p (string-append name ".6th")))))
  (for/or ([p (in-list candidates)])
    (and (file-exists? p) (path->complete-path p))))

(define (load-file path env)
  (define abs (path->complete-path path))
  (unless (loaded? env abs)
    (mark-loaded! env abs)
    (define ast (parse-file abs))
    (define filtered (process-uses! ast env abs))
    (define ops (compile-program filtered env))
    (run! ops env)))

(define (load-source src env [from-file #f])
  (define ast (parse-string src (or from-file "<string>")))
  (define filtered (process-uses! ast env from-file))
  (define ops (compile-program filtered env))
  (run! ops env))

(define (process-uses! nodes env from-file)
  (for/list ([n (in-list nodes)]
             #:unless (handle-use! n env from-file))
    n))

(define (handle-use! n env from-file)
  (cond
    [(ast-use-module? n)
     (define name (symbol->string (ast-use-module-spec n)))
     (define resolved (resolve-module-path name from-file))
     (unless resolved
       (raise (exn:fail:sixth
               (format "~a — use: cannot resolve module `~a`"
                       (format-srcloc (ast-use-module-srcloc n))
                       name)
               (current-continuation-marks)
               (ast-use-module-srcloc n))))
     (load-file resolved env)
     #t]
    [else #f]))

(define (use-module! name env [from-file #f])
  (define resolved (resolve-module-path name from-file))
  (unless resolved
    (raise (exn:fail:sixth
            (format "use: cannot resolve module `~a`" name)
            (current-continuation-marks)
            #f)))
  (load-file resolved env))
