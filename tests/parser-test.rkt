#lang racket/base

;; tests/parser-test.rkt — rackunit suite for the parser.

(require rackunit
         "../sixth/parser.rkt"
         "../sixth/ast.rkt"
         "../sixth/errors.rkt")

(define (parse s) (parse-string s "<test>"))

;; -----------------------------------------------------------------
;; Literals & word references
;; -----------------------------------------------------------------

(test-case "Single integer literal"
  (define nodes (parse "42"))
  (check-equal? (length nodes) 1)
  (check-true (ast-literal? (car nodes)))
  (check-equal? (ast-literal-value (car nodes)) 42))

(test-case "Word reference"
  (define nodes (parse "dup"))
  (check-true (ast-word-ref? (car nodes)))
  (check-equal? (ast-word-ref-name (car nodes)) 'dup))

(test-case "Sequence of literals and words"
  (define nodes (parse "1 2 +"))
  (check-equal? (length nodes) 3)
  (check-true (ast-literal? (car nodes)))
  (check-true (ast-literal? (cadr nodes)))
  (check-true (ast-word-ref? (caddr nodes)))
  (check-equal? (ast-word-ref-name (caddr nodes)) '+))

;; -----------------------------------------------------------------
;; Definitions
;; -----------------------------------------------------------------

(test-case "Simple definition"
  (define nodes (parse ": square dup * ;"))
  (check-equal? (length nodes) 1)
  (define d (car nodes))
  (check-true (ast-definition? d))
  (check-equal? (ast-definition-name d) "square")
  (define body (ast-definition-body d))
  (check-equal? (length body) 2)
  (check-true (ast-word-ref? (car body)))
  (check-equal? (ast-word-ref-name (car body)) 'dup)
  (check-true (ast-word-ref? (cadr body)))
  (check-equal? (ast-word-ref-name (cadr body)) '*))

(test-case "Multiple definitions"
  (define nodes (parse ": 1+ 1 + ; : 2dup over over ;"))
  (check-equal? (length nodes) 2)
  (check-true (ast-definition? (car nodes)))
  (check-true (ast-definition? (cadr nodes))))

(test-case "Unterminated definition raises"
  (check-exn exn:fail:sixth:parse?
             (lambda () (parse ": square dup *"))))

;; -----------------------------------------------------------------
;; if / else / then
;; -----------------------------------------------------------------

(test-case "if-then (no else)"
  (define nodes (parse ": pos? 0 > if 1 then ;"))
  (define body (ast-definition-body (car nodes)))
  (define ite (caddr body))
  (check-true (ast-if-then-else? ite))
  (check-equal? (length (ast-if-then-else-then-body ite)) 1)
  (check-equal? (length (ast-if-then-else-else-body ite)) 0))

(test-case "if-then-else"
  (define nodes (parse ": sign 0 > if 1 else -1 then ;"))
  (define body (ast-definition-body (car nodes)))
  (define ite (caddr body))
  (check-true (ast-if-then-else? ite))
  (check-equal? (length (ast-if-then-else-then-body ite)) 1)
  (check-equal? (length (ast-if-then-else-else-body ite)) 1))

(test-case "Nested if-then-else"
  (define nodes (parse ": tri 0 > if 0 > if 1 else 2 then else 3 then ;"))
  (define body (ast-definition-body (car nodes)))
  ;; body: 0 > if (nested-form) ; so outer is body[2]
  (define outer (caddr body))
  (check-true (ast-if-then-else? outer))
  ;; outer's then-body: 0 > if 1 else 2 then → nested if at index 2
  (define nested (caddr (ast-if-then-else-then-body outer)))
  (check-true (ast-if-then-else? nested)))

(test-case "Unterminated if raises"
  (check-exn exn:fail:sixth:parse?
             (lambda () (parse "if 1"))))

;; -----------------------------------------------------------------
;; Tick (')
;; -----------------------------------------------------------------

(test-case "Tick produces ast-quote-word"
  (define nodes (parse "' my-rule"))
  (check-true (ast-quote-word? (car nodes)))
  (check-equal? (ast-quote-word-name (car nodes)) 'my-rule))

(test-case "Tick without word raises"
  (check-exn exn:fail:sixth:parse?
             (lambda () (parse "'"))))

;; -----------------------------------------------------------------
;; use
;; -----------------------------------------------------------------

(test-case "use module"
  (define nodes (parse "use prelude"))
  (check-true (ast-use-module? (car nodes)))
  (check-equal? (ast-use-module-spec (car nodes)) 'prelude))

(test-case "use missing arg raises"
  (check-exn exn:fail:sixth:parse?
             (lambda () (parse "use"))))

;; -----------------------------------------------------------------
;; Realistic legacy demo snippets
;; -----------------------------------------------------------------

(test-case "Peano definitions parse"
  (define src ": zero MARK ;
                : succ MARK 2dup EDGE+ nip ;
                : zero? IN 0 = ;")
  (define nodes (parse src))
  (check-equal? (length nodes) 3)
  (for ([n (in-list nodes)])
    (check-true (ast-definition? n))))

(test-case "Recursive peano-value parses"
  (define src ": peano-value dup zero? if drop 0 else PREV peano-value 1+ then ;")
  (define nodes (parse src))
  (check-equal? (length nodes) 1)
  (define body (ast-definition-body (car nodes)))
  ;; should be: dup zero? <if-then-else>
  (check-equal? (length body) 3)
  (check-true (ast-if-then-else? (caddr body))))

(displayln "parser tests: all pass")
