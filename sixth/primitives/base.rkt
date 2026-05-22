#lang racket/base

;; sixth/primitives/base.rkt — the 17 base Sixth primitives
;; (14 stack/arith/cmp/mem + 3 I/O).
;;
;; Each primitive is a 1-arg procedure (env -> void) that mutates the
;; env.  Registered into the env's primitive hash via `register-base!`.
;;
;; Conventions match legacy/sixth.scm but using Racket's `let*` (left-
;; to-right) so the chibi-Scheme `let` reorder bug is structurally
;; impossible.

(provide register-base!)

(require "../env.rkt"
         "../errors.rkt"
         "../vm.rkt"
         "../values.rkt"
         racket/format)

;; ---- helpers ----

(define (pop1 e)
  (env-pop! e (current-prim-srcloc)))

(define (peek1 e)
  (env-peek e (current-prim-srcloc)))

(define (push1 e v)
  (env-push! e v))

(define (expect-num v who)
  (cond
    [(number? v) v]
    [else
     (raise (exn:fail:sixth:type
             (format "~a — `~a`: expected number, got ~a (~a)"
                     (format-srcloc (current-prim-srcloc))
                     who (value-tag v) (value->display v))
             (current-continuation-marks)
             (current-prim-srcloc)
             'num
             (value-tag v)))]))

(define (bool->int b) (if b 1 0))

;; ---- the 17 primitives ----

(define (prim-dup e)  (push1 e (peek1 e)))
(define (prim-drop e) (pop1 e))
(define (prim-swap e)
  (define a (pop1 e))
  (define b (pop1 e))
  (push1 e a)
  (push1 e b))
(define (prim-over e)
  (define a (pop1 e))
  (define b (peek1 e))
  (push1 e a)
  (push1 e b))

(define (prim-+ e)
  (define b (expect-num (pop1 e) '+))
  (define a (expect-num (pop1 e) '+))
  (push1 e (+ a b)))
(define (prim-- e)
  (define b (expect-num (pop1 e) '-))
  (define a (expect-num (pop1 e) '-))
  (push1 e (- a b)))
(define (prim-* e)
  (define b (expect-num (pop1 e) '*))
  (define a (expect-num (pop1 e) '*))
  (push1 e (* a b)))
(define (prim-/ e)
  (define b (expect-num (pop1 e) '/))
  (define a (expect-num (pop1 e) '/))
  (when (zero? b)
    (raise (exn:fail:sixth
            (format "~a — division by zero"
                    (format-srcloc (current-prim-srcloc)))
            (current-continuation-marks)
            (current-prim-srcloc))))
  (push1 e (quotient a b)))
(define (prim-mod e)
  (define b (expect-num (pop1 e) 'mod))
  (define a (expect-num (pop1 e) 'mod))
  (push1 e (remainder a b)))

(define (prim-= e)
  ;; Numeric `=` when both operands are numbers — so `1 1.0 =` returns
  ;; 1 (numerically equal, surprising-otherwise).  Structural `equal?`
  ;; for everything else (symbols, strings, nodes, etc.).  Previously
  ;; used `equal?` unconditionally, so mixed INT/FLOAT comparisons —
  ;; common from FFI/torch-bridge results — silently returned 0.
  (define b (pop1 e))
  (define a (pop1 e))
  (push1 e (bool->int
            (cond
              [(and (number? a) (number? b)) (= a b)]
              [else (equal? a b)]))))
(define (prim-< e)
  (define b (expect-num (pop1 e) '<))
  (define a (expect-num (pop1 e) '<))
  (push1 e (bool->int (< a b))))
(define (prim-> e)
  (define b (expect-num (pop1 e) '>))
  (define a (expect-num (pop1 e) '>))
  (push1 e (bool->int (> a b))))

(define (prim-store e)
  (define addr (pop1 e))
  (define val  (pop1 e))
  (env-store! e addr val (current-prim-srcloc)))
(define (prim-load e)
  (define addr (pop1 e))
  (push1 e (env-load e addr)))

;; ---- I/O primitives  ----

(define (prim-dot e)
  (define v (pop1 e))
  (display (value->display v))
  (display " "))
(define (prim-cr e)
  (newline))
(define (prim-emit e)
  (define v (pop1 e))
  (display (integer->char (expect-num v 'emit))))

;; ---- registration ----

(define (register-base! e)
  (for ([entry (in-list base-primitives)])
    (env-register-prim! e (car entry) (cdr entry))))

(define base-primitives
  (list
    (cons 'dup   prim-dup)
    (cons 'drop  prim-drop)
    (cons 'swap  prim-swap)
    (cons 'over  prim-over)
    (cons '+     prim-+)
    (cons '-     prim--)
    (cons '*     prim-*)
    (cons '/     prim-/)
    (cons 'mod   prim-mod)
    (cons '=     prim-=)
    (cons '<     prim-<)
    (cons '>     prim->)
    (cons 'store prim-store)
    (cons 'load  prim-load)
    (cons '|.|   prim-dot)
    (cons 'cr    prim-cr)
    (cons 'emit  prim-emit)))
