#lang racket/base

;; sixth/vm.rkt — stack VM.
;;
;; Executes a compiled opcode vector against an env (sixth/env.rkt).
;; Replaces the 44-case `cond` in legacy/sixth-substrate.scm with an
;; O(1) opcode dispatch (vector-ref) and an O(1) primitive lookup
;; (hash-ref).
;;
;; Tail-call elimination: when `CALL name` is immediately followed by
;; `RET` (last op of current word body), we replace the current frame
;; rather than pushing a new one.  This is what lets recursive Sixth
;; words (peano-add, factorial) run arbitrarily deep.

(provide
  run!
  vm-step!
  push-halt-frame!)

(require "opcodes.rkt"
         "env.rkt"
         "errors.rkt"
         "values.rkt")

;; Each return-stack frame stores: program (opcode vector) and pc.
(struct frame (program pc) #:transparent)

(define (run! program e)
  (let loop ([prog program] [pc 0])
    (cond
      [(>= pc (vector-length prog))
       ;; ran off end without RET — implicit halt
       (void)]
      [else
       (define instr (vector-ref prog pc))
       (define code (op-code instr))
       (cond
         [(= code op-LIT)
          (env-push! e (op-arg instr))
          (loop prog (+ pc 1))]
         [(= code op-CALL)
          (handle-call e prog pc instr loop)]
         [(= code op-JZ)
          (define v (env-pop! e (op-srcloc instr)))
          (loop prog (if (zero-ish? v) (op-arg instr) (+ pc 1)))]
         [(= code op-JMP)
          (loop prog (op-arg instr))]
         [(= code op-RET)
          (pop-return-frame e (lambda (next-prog next-pc)
                                 (loop next-prog next-pc)))]
         [(= code op-PRIM)
          (call-prim! e (op-arg instr) (op-srcloc instr))
          (loop prog (+ pc 1))]
         [else
          (raise (exn:fail:sixth
                  (format "VM: unknown opcode ~a at ~a"
                          code (format-srcloc (op-srcloc instr)))
                  (current-continuation-marks)
                  (op-srcloc instr)))])])))

;; Forth-truthiness: zero-ish? from values.rkt is shared with
;; substrate-assert!, so JZ branching and ASSERT pass/fail agree
;; on what counts as false (incl. boxed-flonum zero).

;; ---- handling CALL with TCO ----

(define (handle-call e prog pc instr loop)
  (define name (op-arg instr))
  (define loc  (op-srcloc instr))
  ;; Primitive takes precedence (rare collision; flagged in env.rkt).
  (define prim (env-lookup-prim e name))
  (cond
    [prim
     (call-prim-direct e prim loc)
     (loop prog (+ pc 1))]
    [else
     (define w (env-lookup-word e name))
     (cond
       [(not w)
        (raise (exn:fail:sixth:unbound
                (format "~a — unbound word `~a`"
                        (format-srcloc loc) name)
                (current-continuation-marks)
                loc
                name))]
       [else
        (define tail? (tail-call? prog pc))
        (cond
          [tail?
           ;; TCO: replace frame rather than push
           (loop (word-opcodes w) 0)]
          [else
           ;; push return frame
           (push-return-frame! e (frame prog (+ pc 1)))
           (loop (word-opcodes w) 0)])])]))

(define (tail-call? prog pc)
  (define next-pc (+ pc 1))
  (and (< next-pc (vector-length prog))
       (= (op-code (vector-ref prog next-pc)) op-RET)))

(define (push-return-frame! e frm)
  (set-env-rstack! e (cons frm (env-rstack e))))

(define (push-halt-frame! e)
  (push-return-frame! e (frame #f #f)))

(define (pop-return-frame e k)
  (define r (env-rstack e))
  (cond
    [(null? r)
     ;; halting from outermost frame — done
     (void)]
    [else
     (define f (car r))
     (set-env-rstack! e (cdr r))
     (cond
       ;; Sentinel frame pushed by call-rule! (EACH/EACH-EDGE/EACH-2PATH)
       ;; — RET hitting it halts the nested run! without continuing into
       ;; the caller's frame.
       [(not (frame-program f)) (void)]
       [else (k (frame-program f) (frame-pc f))])]))

;; ---- primitive invocation ----

(define (call-prim! e name loc)
  (define p (env-lookup-prim e name))
  (cond
    [(not p)
     (raise (exn:fail:sixth:unbound
             (format "~a — unbound primitive `~a`"
                     (format-srcloc loc) name)
             (current-continuation-marks)
             loc
             name))]
    [else (call-prim-direct e p loc)]))

(define (call-prim-direct e proc loc)
  ;; All primitives are 1-arg procs receiving the env.  They mutate
  ;; stack and substrate as needed.  If they need source location for
  ;; error reporting, they read `current-prim-srcloc` parameter.
  (parameterize ([current-prim-srcloc loc])
    (proc e)))

(define current-prim-srcloc (make-parameter #f))
(provide current-prim-srcloc)

;; ---- single-step (testing / debugging) ----

(define (vm-step! prog pc e)
  ;; Execute one op; return new pc (or #f for halt).
  (cond
    [(>= pc (vector-length prog)) #f]
    [else
     (define instr (vector-ref prog pc))
     (define code (op-code instr))
     (cond
       [(= code op-LIT)
        (env-push! e (op-arg instr))
        (+ pc 1)]
       [(= code op-PRIM)
        (call-prim! e (op-arg instr) (op-srcloc instr))
        (+ pc 1)]
       [(= code op-JMP)
        (op-arg instr)]
       [(= code op-JZ)
        (define v (env-pop! e (op-srcloc instr)))
        (if (zero-ish? v) (op-arg instr) (+ pc 1))]
       [(= code op-RET) #f]
       [else
        (raise (exn:fail:sixth
                (format "vm-step: unsupported op ~a (use run! for CALL)" code)
                (current-continuation-marks)
                (op-srcloc instr)))])]))
