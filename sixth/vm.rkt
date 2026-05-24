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
  push-halt-frame!
  current-engine-trace
  current-cand-dispatch-hook
  current-cand-nested-hook
  frame
  frame-program
  frame-pc)

;; current-engine-trace: parameter holding either #f (default; zero
;; overhead) or a `box` of a list of (cons kind name) trace entries
;; in reverse order (most recent first).  Set by meta-runtime to
;; enable Tier 1 motif detection per META-SEMANTICS.md §3.
;;
;; Trace records every op-PRIM and op-CALL execution: the kind is
;; either 'prim or 'call, and the name is the symbol invoked.
;; Word-internal CALLs are NOT recorded (they're expansion of the
;; outer call already recorded); only top-level dispatch.
(define current-engine-trace (make-parameter #f))

;; Parameter for cand-dispatch counter hook (cycle 25D item 10).
;; If bound, called as (hook e name) on every TOP-LEVEL CALL / PRIM
;; dispatch.  Used by meta-runtime to bump per-candidate use counter
;; when a `cand_NNN` word actually executes (not merely registered).
(define current-cand-dispatch-hook (make-parameter #f))

;; Parameter for nested-call hook (cycle 32).  If bound, called as
;; (hook e kind name) on every NON-top-level CALL / PRIM dispatch.
;; Used by meta-runtime to record runtime-observed dependencies:
;; when cand_B's body executes and within it cand_A is invoked nested,
;; this hook records the (caller=cand_B, callee=cand_A) observation.
;; The hook implementation walks rstack to identify the containing cand.
(define current-cand-nested-hook (make-parameter #f))

;; Log only TOP-LEVEL ops (rstack empty or just halt-sentinel).  When
;; inside a word body, rstack has the CALLER's frame (back-pointer for
;; return); the currently-executing program is the `prog` parameter
;; in run!'s loop, not on the rstack.  Cycle 32 passes `current-prog`
;; into trace-append! so the nested hook can identify the containing
;; cand directly via the opcodes-to-cand reverse-lookup.
(define (trace-append! e kind name current-prog)
  (define top-level?
    (let ([depth (length (env-rstack e))])
      (or (= depth 0)
          (and (= depth 1)
               (not (frame-program (car (env-rstack e))))))))
  (cond
    [top-level?
     (define b (current-engine-trace))
     (when b
       (set-box! b (cons (cons kind name) (unbox b))))
     (define hook (current-cand-dispatch-hook))
     (when hook (hook e name))]
    [else
     ;; Cycle 32: nested call within a cand body.  Fire the nested
     ;; hook if installed.  Does NOT append to user-visible trace
     ;; (only top-level events are user-observable for motif mining).
     (define nh (current-cand-nested-hook))
     (when nh (nh e kind name current-prog))]))

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
          (trace-append! e 'call (op-arg instr) prog)
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
          (trace-append! e 'prim (op-arg instr) prog)
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

;; Tail-call detection.  A CALL is in tail position if the next opcode
;; is RET *or* an unconditional JMP whose target is RET.  The second
;; case covers tail recursion through an if/else branch: the compiler
;; emits CALL-followed-by-JMP at the end of the THEN body, where JMP
;; jumps over the ELSE body to the trailing RET.  Without this two-
;; step recognition, recursive words with their tail call inside an
;; if-branch (peano-add, peano-mul, countdown, anything matching the
;; pattern `if ... rec then`) silently fall back to non-TCO and grow
;; the rstack linearly in recursion depth.
(define (tail-call? prog pc)
  (define n (vector-length prog))
  (define next-pc (+ pc 1))
  (and (< next-pc n)
       (let ([instr (vector-ref prog next-pc)])
         (define code (op-code instr))
         (cond
           [(= code op-RET) #t]
           [(= code op-JMP)
            (define target (op-arg instr))
            (and (exact-integer? target)
                 (<= 0 target)
                 (< target n)
                 (= (op-code (vector-ref prog target)) op-RET))]
           [else #f]))))

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
