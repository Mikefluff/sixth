#lang racket/base

;; tests/lexer-test.rkt — rackunit suite for the lexer.

(require rackunit
         "../sixth/lexer.rkt"
         "../sixth/errors.rkt")

(define (kinds toks)
  (map token-kind toks))

(define (values* toks)
  (map token-value toks))

(define (lex s)
  (tokenize-string s "<test>"))

;; -----------------------------------------------------------------
;; Numbers and basic words
;; -----------------------------------------------------------------

(test-case "Single integer"
  (define ts (lex "42"))
  (check-equal? (kinds ts) '(num))
  (check-equal? (values* ts) '(42)))

(test-case "Negative integer"
  (define ts (lex "-7"))
  (check-equal? (kinds ts) '(num))
  (check-equal? (values* ts) '(-7)))

(test-case "Floating point"
  (define ts (lex "3.14"))
  (check-equal? (kinds ts) '(num))
  (check-equal? (values* ts) '(3.14)))

(test-case "Simple word"
  (define ts (lex "dup"))
  (check-equal? (kinds ts) '(word))
  (check-equal? (values* ts) '("dup")))

(test-case "Multiple tokens"
  (define ts (lex "1 2 +"))
  (check-equal? (kinds ts) '(num num word))
  (check-equal? (values* ts) '(1 2 "+")))

;; -----------------------------------------------------------------
;; Keywords
;; -----------------------------------------------------------------

(test-case "Control keywords"
  (define ts (lex ": square dup * ; if else then use"))
  (check-equal? (kinds ts)
                '(colon word word word semi if else then use)))

;; -----------------------------------------------------------------
;; Tick
;; -----------------------------------------------------------------

(test-case "Tick is its own token"
  (define ts (lex "' my-rule EACH"))
  (check-equal? (kinds ts) '(tick word word))
  (check-equal? (values* ts) '("'" "my-rule" "EACH")))

;; -----------------------------------------------------------------
;; String literals
;; -----------------------------------------------------------------

(test-case "Basic string literal"
  (define ts (lex "\"hello world\""))
  (check-equal? (kinds ts) '(str))
  (check-equal? (values* ts) '("hello world")))

(test-case "String with escapes"
  (define ts (lex "\"a\\nb\\tc\""))
  (check-equal? (kinds ts) '(str))
  (check-equal? (values* ts) '("a\nb\tc")))

(test-case "Unterminated string raises lex error"
  (check-exn exn:fail:sixth:lex?
             (lambda () (lex "\"oops"))))

;; -----------------------------------------------------------------
;; Comments
;; -----------------------------------------------------------------

(test-case "Backslash line comment"
  (define ts (lex "1 \\ this is comment\n2"))
  (check-equal? (kinds ts) '(num num))
  (check-equal? (values* ts) '(1 2)))

(test-case "Trailing backslash comment without newline"
  (define ts (lex "1 \\ trailing"))
  (check-equal? (kinds ts) '(num)))

(test-case "Inline paren comment"
  (define ts (lex "1 ( drop the comment ) 2"))
  (check-equal? (kinds ts) '(num num))
  (check-equal? (values* ts) '(1 2)))

(test-case "Unterminated paren comment raises"
  (check-exn exn:fail:sixth:lex?
             (lambda () (lex "1 ( oops"))))

;; -----------------------------------------------------------------
;; Source location tracking
;; -----------------------------------------------------------------

(test-case "Source positions on first token"
  (define ts (lex "  42"))
  (define loc (token-srcloc (car ts)))
  (check-equal? (srcloc-line loc) 1)
  (check-equal? (srcloc-column loc) 2))

(test-case "Newline advances line counter"
  (define ts (lex "1\n2"))
  (define t2 (cadr ts))
  (check-equal? (srcloc-line (token-srcloc t2)) 2)
  (check-equal? (srcloc-column (token-srcloc t2)) 0))

;; -----------------------------------------------------------------
;; Legacy demo compatibility — sample patterns from existing .6th
;; -----------------------------------------------------------------

(test-case "Word definition body parse-safe"
  (define ts (lex ": 2dup over over ;"))
  (check-equal? (kinds ts)
                '(colon word word word semi))
  (check-equal? (values* ts)
                '(":" "2dup" "over" "over" ";")))

(test-case "Substrate MARK + EDGE+ pattern"
  (define ts (lex "MARK MARK 2dup EDGE+ nip"))
  (check-equal? (kinds ts)
                '(word word word word word))
  (check-equal? (values* ts)
                '("MARK" "MARK" "2dup" "EDGE+" "nip")))

(test-case "Conditional with multiple branches"
  (define ts (lex "dup zero? if drop 0 else PREV peano-value 1+ then"))
  (check-equal? (kinds ts)
                '(word word if word num else word word word then)))

(displayln "lexer tests: all pass")
