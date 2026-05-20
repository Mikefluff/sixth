#lang racket/base

;; sixth/parser.rkt — tokens → AST.
;;
;; Replaces inline `parse-definition` / `parse-if` in legacy/sixth-substrate.scm.
;; Improvements:
;;   - emits structured AST nodes (sixth/ast.rkt) instead of re-tokenizing
;;     strings at evaluation time
;;   - explicit nesting tracking for if/else/then via index pairing
;;   - srcloc preserved on every AST node
;;
;; Grammar (informal):
;;
;;   program     ::= toplevel*
;;   toplevel    ::= definition | use | expr
;;   definition  ::= ':' word body ';'
;;   body        ::= expr*
;;   use         ::= 'use' word ['as' word | '(' word+ ')']
;;   expr        ::= literal | wordref | tick | if-then-else
;;   tick        ::= "'" word
;;   if-then-else::= 'if' body ['else' body] 'then'
;;   literal     ::= NUM | STR

(provide
  parse-tokens
  parse-string
  parse-file)

(require "lexer.rkt"
         "ast.rkt"
         "errors.rkt")

;; -----------------------------------------------------------------
;; Top-level entry points
;; -----------------------------------------------------------------

(define (parse-tokens toks)
  (parse-program toks))

(define (parse-string str [src #f])
  (parse-tokens (tokenize-string str src)))

(define (parse-file path)
  (parse-tokens (tokenize-file path)))

;; -----------------------------------------------------------------
;; Program-level parsing — returns list of top-level AST nodes
;; -----------------------------------------------------------------

(define (parse-program toks)
  (let loop ([toks toks] [acc '()])
    (cond
      [(null? toks) (reverse acc)]
      [else
       (define-values (node rest) (parse-toplevel toks))
       (loop rest (cons node acc))])))

(define (parse-toplevel toks)
  (define t (car toks))
  (case (token-kind t)
    [(colon) (parse-definition (cdr toks) (token-srcloc t))]
    [(use)   (parse-use (cdr toks) (token-srcloc t))]
    [else    (parse-expr toks)]))

;; -----------------------------------------------------------------
;; `: name body ;` definition
;; -----------------------------------------------------------------

(define (parse-definition toks colon-loc)
  (when (null? toks)
    (parse-err colon-loc "definition: expected word name after `:`"))
  (define name-tok (car toks))
  (unless (eq? (token-kind name-tok) 'word)
    (parse-err (token-srcloc name-tok)
               (format "definition: expected word name, got ~a" (token-kind name-tok))))
  (define name (token-value name-tok))
  ;; collect body until matching `;`
  (let loop ([toks (cdr toks)] [body '()])
    (cond
      [(null? toks)
       (parse-err colon-loc (format "definition `: ~a` missing closing `;`" name))]
      [(eq? (token-kind (car toks)) 'semi)
       (values (ast-definition name (reverse body) colon-loc) (cdr toks))]
      [else
       (define-values (node rest) (parse-expr toks))
       (loop rest (cons node body))])))

;; -----------------------------------------------------------------
;; `use foo` / `use foo as f` / `use foo (a b)` — minimal form for now
;; -----------------------------------------------------------------

(define (parse-use toks use-loc)
  (when (null? toks)
    (parse-err use-loc "use: expected module name"))
  (define name-tok (car toks))
  (unless (eq? (token-kind name-tok) 'word)
    (parse-err (token-srcloc name-tok)
               "use: expected module name (a word)"))
  ;; future: parse 'as f' or '(a b)' specifier here
  (values (ast-use-module (string->symbol (token-value name-tok)) use-loc)
          (cdr toks)))

;; -----------------------------------------------------------------
;; Expressions: literals, word refs, ticks, if/then/else
;; -----------------------------------------------------------------

(define (parse-expr toks)
  (define t (car toks))
  (case (token-kind t)
    [(num)
     (values (ast-literal (token-value t) (token-srcloc t)) (cdr toks))]
    [(str)
     (values (ast-literal (token-value t) (token-srcloc t)) (cdr toks))]
    [(word)
     (values (ast-word-ref (string->symbol (token-value t)) (token-srcloc t))
             (cdr toks))]
    [(tick)
     (parse-tick (cdr toks) (token-srcloc t))]
    [(if)
     (parse-if (cdr toks) (token-srcloc t))]
    [(else then semi colon use)
     (parse-err (token-srcloc t)
                (format "unexpected `~a` outside of containing form"
                        (token-value t)))]))

(define (parse-tick toks tick-loc)
  (when (null? toks)
    (parse-err tick-loc "tick: expected word after `'`"))
  (define name-tok (car toks))
  (unless (eq? (token-kind name-tok) 'word)
    (parse-err (token-srcloc name-tok)
               (format "tick: expected word after `'`, got ~a"
                       (token-kind name-tok))))
  (values (ast-quote-word (string->symbol (token-value name-tok)) tick-loc)
          (cdr toks)))

;; -----------------------------------------------------------------
;; `if body [else body] then` — supports nesting via depth counter.
;; -----------------------------------------------------------------

(define (parse-if toks if-loc)
  ;; collect until matching `then` (tracking nested if), with optional
  ;; `else` separator at depth=0
  (let loop ([toks toks]
             [then-body '()]
             [else-body '()]
             [in-else? #f]
             [depth 0])
    (when (null? toks)
      (parse-err if-loc "if: missing closing `then`"))
    (define t (car toks))
    (case (token-kind t)
      [(if)
       (define-values (node rest) (parse-expr toks))
       (if in-else?
           (loop rest then-body (cons node else-body) in-else? depth)
           (loop rest (cons node then-body) else-body in-else? depth))]
      [(else)
       (cond
         [(> depth 0)
          ;; nested else, push into whichever side we're collecting
          (if in-else?
              (loop (cdr toks) then-body (cons (parse-keyword-token t) else-body)
                    in-else? depth)
              (loop (cdr toks) (cons (parse-keyword-token t) then-body) else-body
                    in-else? depth))]
         [else
          (loop (cdr toks) then-body else-body #t depth)])]
      [(then)
       (cond
         [(> depth 0)
          (if in-else?
              (loop (cdr toks) then-body (cons (parse-keyword-token t) else-body)
                    in-else? (- depth 1))
              (loop (cdr toks) (cons (parse-keyword-token t) then-body) else-body
                    in-else? (- depth 1)))]
         [else
          (values (ast-if-then-else (reverse then-body)
                                     (reverse else-body)
                                     if-loc)
                  (cdr toks))])]
      [else
       (define-values (node rest) (parse-expr toks))
       (if in-else?
           (loop rest then-body (cons node else-body) in-else? depth)
           (loop rest (cons node then-body) else-body in-else? depth))])))

;; A throwaway: nested keyword tokens treated as words during nesting
;; bookkeeping; should never escape because depth bookkeeping balances.
(define (parse-keyword-token t)
  (ast-word-ref (string->symbol (token-value t)) (token-srcloc t)))

;; -----------------------------------------------------------------
;; Helpers
;; -----------------------------------------------------------------

(define (parse-err loc msg)
  (raise (exn:fail:sixth:parse
          (format "~a — ~a" (format-srcloc loc) msg)
          (current-continuation-marks)
          loc)))
