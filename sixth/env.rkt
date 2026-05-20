#lang racket/base

;; sixth/env.rkt — runtime environment.
;;
;; Holds:
;;   - the data stack
;;   - the return stack (for word call/return)
;;   - the word registry (name symbol → Word struct)
;;   - the primitive registry (name symbol → procedure (env -> void))
;;   - per-module memory hash (user `store`/`load` namespace)
;;   - the substrate (filled when sixth/substrate is loaded)
;;
;; A Word is `(word name opcodes srcloc)` — the compiler emits these.
;;
;; The environment is mutable; instances are created via `make-env`.

(provide
  (struct-out env)
  (struct-out word)
  make-env
  env-push!
  env-pop!
  env-peek
  env-stack-depth
  env-register-prim!
  env-register-word!
  env-lookup-word
  env-lookup-prim
  env-store!
  env-load
  env-memory-keys)

(require "errors.rkt"
         "values.rkt")

(struct word (name opcodes srcloc) #:transparent)

;; Mutable runtime environment.
(struct env
  ([stack    #:mutable]            ; list, top first
   [rstack   #:mutable]            ; return stack
   words                            ; mutable hash sym -> word
   prims                            ; mutable hash sym -> procedure
   memory                           ; mutable hash any -> any (user store/load)
   [substrate #:mutable])           ; opaque, set by substrate module
  #:transparent)

(define (make-env)
  (env '()
       '()
       (make-hasheq)
       (make-hasheq)
       (make-hash)
       #f))

;; ---- stack ops ----

(define (env-push! e v)
  (set-env-stack! e (cons v (env-stack e))))

(define (env-pop! e [loc #f])
  (define s (env-stack e))
  (when (null? s)
    (raise (exn:fail:sixth:stack
            (format "~a — stack underflow" (format-srcloc loc))
            (current-continuation-marks)
            loc)))
  (set-env-stack! e (cdr s))
  (car s))

(define (env-peek e [loc #f])
  (define s (env-stack e))
  (when (null? s)
    (raise (exn:fail:sixth:stack
            (format "~a — stack underflow on peek" (format-srcloc loc))
            (current-continuation-marks)
            loc)))
  (car s))

(define (env-stack-depth e) (length (env-stack e)))

;; ---- registry ops ----

(define (env-register-prim! e name proc)
  (hash-set! (env-prims e) name proc))

(define (env-register-word! e name w)
  (hash-set! (env-words e) name w))

(define (env-lookup-word e name)
  (hash-ref (env-words e) name #f))

(define (env-lookup-prim e name)
  (hash-ref (env-prims e) name #f))

;; ---- memory (user store/load) ----

(define (env-store! e key val [loc #f])
  ;; Underscore-prefixed keys are reserved for engine internals.
  (when (and (symbol? key)
             (let ([s (symbol->string key)])
               (and (> (string-length s) 0)
                    (char=? (string-ref s 0) #\_))))
    (raise (exn:fail:sixth
            (format "~a — `store`: keys starting with `_` are reserved (~a)"
                    (format-srcloc loc) key)
            (current-continuation-marks)
            loc)))
  (when (and (string? key)
             (> (string-length key) 0)
             (char=? (string-ref key 0) #\_))
    (raise (exn:fail:sixth
            (format "~a — `store`: keys starting with `_` are reserved (~a)"
                    (format-srcloc loc) key)
            (current-continuation-marks)
            loc)))
  (hash-set! (env-memory e) key val))

(define (env-load e key)
  (hash-ref (env-memory e) key 0))

(define (env-memory-keys e)
  (hash-keys (env-memory e)))
