#lang racket/base

;; sixth/compiler.rkt — AST → opcode vector.
;;
;; Each word body and each top-level program lowers to a vector of `op`
;; structs.  Word definitions register into the env; top-level non-
;; definition AST nodes become the emitted program opcodes.
;;
;; If/then/else uses standard back-patching:
;;   <cond>
;;   JZ else-target           ← patch with absolute index of else-start
;;   <then-body>
;;   JMP end-target           ← patch with absolute index after else-body
;;   else-target:
;;   <else-body>
;;   end-target:

(provide
  compile-program
  compile-body)

(require "ast.rkt"
         "opcodes.rkt"
         "env.rkt"
         "errors.rkt")

;; Mutable opcode buffer wrapping a list with length counter.
(struct buf ([ops #:mutable] [len #:mutable]) #:transparent)

(define (make-buf) (buf '() 0))

;; Emit one op; return the absolute index of the new slot.
(define (buf-emit! b code arg srcloc)
  (set-buf-ops! b (cons (op code arg srcloc) (buf-ops b)))
  (define idx (buf-len b))
  (set-buf-len! b (+ idx 1))
  idx)

;; Patch an existing op at `idx` — replace its `arg` with `new-arg`.
(define (buf-patch! b idx new-arg)
  ;; ops is stored reverse-order; index `idx` (absolute, 0-based) is at
  ;; reverse position `(len - 1 - idx)`.  Splice in a new op there.
  (define n (buf-len b))
  (define rev-idx (- n 1 idx))
  (define ops-list (buf-ops b))
  (set-buf-ops!
   b
   (let loop ([i 0] [lst ops-list])
     (cond
       [(= i rev-idx)
        (define old (car lst))
        (cons (op (op-code old) new-arg (op-srcloc old)) (cdr lst))]
       [else (cons (car lst) (loop (+ i 1) (cdr lst)))]))))

(define (buf-finalize b)
  (list->vector (reverse (buf-ops b))))

(define (buf-position b) (buf-len b))

;; -----------------------------------------------------------------
;; Public API
;; -----------------------------------------------------------------

(define (compile-program nodes e)
  ;; Register word definitions and use statements; collect rest as
  ;; program body.  Then compile body to opcodes.
  (define body
    (for/fold ([acc '()]) ([n (in-list nodes)])
      (cond
        [(ast-definition? n)
         (define w
           (word (string->symbol (ast-definition-name n))
                  (compile-body (ast-definition-body n) e)
                  (ast-definition-srcloc n)))
         (env-register-word! e (word-name w) w)
         acc]
        [(ast-use-module? n)
         ;; module resolution wired in Phase E
         acc]
        [else (cons n acc)])))
  (compile-body (reverse body) e))

(define (compile-body nodes e)
  (define b (make-buf))
  (for ([n (in-list nodes)])
    (compile-node! n b e))
  (buf-emit! b op-RET #f #f)
  (buf-finalize b))

;; -----------------------------------------------------------------
;; Node-level compilation
;; -----------------------------------------------------------------

(define (compile-node! n b e)
  (cond
    [(ast-literal? n)
     (buf-emit! b op-LIT (ast-literal-value n) (ast-literal-srcloc n))]
    [(ast-word-ref? n)
     (buf-emit! b op-CALL (ast-word-ref-name n) (ast-word-ref-srcloc n))]
    [(ast-quote-word? n)
     (buf-emit! b op-LIT (ast-quote-word-name n) (ast-quote-word-srcloc n))]
    [(ast-if-then-else? n)
     (compile-if! n b e)]
    [(ast-definition? n)
     (raise (exn:fail:sixth:parse
             (format "~a — `: name ... ;` cannot appear inside word body"
                     (format-srcloc (ast-definition-srcloc n)))
             (current-continuation-marks)
             (ast-definition-srcloc n)))]
    [(ast-use-module? n)
     (raise (exn:fail:sixth:parse
             (format "~a — `use` cannot appear inside word body"
                     (format-srcloc (ast-use-module-srcloc n)))
             (current-continuation-marks)
             (ast-use-module-srcloc n)))]
    [else
     (raise (exn:fail:sixth
             (format "compile: unknown AST node ~a" n)
             (current-continuation-marks)
             #f))]))

(define (compile-if! n b e)
  (define loc (ast-if-then-else-srcloc n))
  (define has-else? (not (null? (ast-if-then-else-else-body n))))
  ;; emit JZ placeholder
  (define jz-idx (buf-emit! b op-JZ #f loc))
  ;; then-body
  (for ([nn (in-list (ast-if-then-else-then-body n))])
    (compile-node! nn b e))
  (cond
    [has-else?
     (define jmp-idx (buf-emit! b op-JMP #f loc))
     (define else-start (buf-position b))
     (for ([nn (in-list (ast-if-then-else-else-body n))])
       (compile-node! nn b e))
     (define end-target (buf-position b))
     (buf-patch! b jz-idx else-start)
     (buf-patch! b jmp-idx end-target)]
    [else
     (define end-target (buf-position b))
     (buf-patch! b jz-idx end-target)]))
