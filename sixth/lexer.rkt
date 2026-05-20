#lang racket/base

;; sixth/lexer.rkt — char stream → tokens.
;;
;; Replaces the inline `tokenize` in legacy/sixth-substrate.scm.
;; Improvements:
;;   - source positions (file, line, column) on every token
;;   - real string literals  "with \n escapes"
;;   - inline `( ... )` block comments (Forth convention)
;;   - line comments via `\ ` (backslash + space-or-EOL)
;;   - tick `'` is its own token (not a character buried in next word)
;;
;; Token kinds:
;;   'num     value: exact-integer? or flonum?
;;   'str     value: string?
;;   'word    value: string?           (everything else)
;;   'colon   :       (start of definition)
;;   'semi    ;       (end of definition)
;;   'if      if
;;   'else    else
;;   'then    then
;;   'tick    '       (push next token name as literal symbol)
;;   'use     use     (module import keyword)
;;
;; Note: keywords (if/else/then/use) are recognized at lex time, not at
;; parse time, so the parser does not need to compare strings.

(provide
  (struct-out token)
  tokenize
  tokenize-port
  tokenize-string
  tokenize-file)

(require "errors.rkt"
         racket/port)

(struct token (kind value srcloc) #:transparent)

(define (make-srcloc src line col pos span)
  (srcloc src line col pos span))

(define (mk-token kind value src line col pos span)
  (token kind value (make-srcloc src line col pos span)))

;; -----------------------------------------------------------------
;; Character classification
;; -----------------------------------------------------------------

(define (sixth-whitespace? c)
  (or (char=? c #\space)
      (char=? c #\tab)
      (char=? c #\newline)
      (char=? c #\return)))

(define (sixth-delimiter? c)
  (or (sixth-whitespace? c)
      (char=? c #\()
      (char=? c #\))
      (char=? c #\')
      (char=? c #\")))

;; -----------------------------------------------------------------
;; Position-tracking port reader
;; -----------------------------------------------------------------

;; line: 1-based (per Racket srcloc convention)
;; col:  0-based (per Racket srcloc convention)
;; pos:  1-based (per Racket srcloc convention)
(struct cursor ([line #:mutable] [col #:mutable] [pos #:mutable]))

(define (make-cursor)
  (cursor 1 0 1))

(define (advance-cursor! cur c)
  (set-cursor-pos! cur (+ 1 (cursor-pos cur)))
  (cond
    [(char=? c #\newline)
     (set-cursor-line! cur (+ 1 (cursor-line cur)))
     (set-cursor-col! cur 0)]
    [else
     (set-cursor-col! cur (+ 1 (cursor-col cur)))]))

(define (read-char-cur in cur)
  (define c (read-char in))
  (when (char? c) (advance-cursor! cur c))
  c)

(define (peek-char-cur in)
  (peek-char in))

;; -----------------------------------------------------------------
;; Read one token (advancing past leading whitespace + comments)
;; -----------------------------------------------------------------

(define (skip-whitespace! in cur)
  (let loop ()
    (define c (peek-char-cur in))
    (when (and (char? c) (sixth-whitespace? c))
      (read-char-cur in cur)
      (loop))))

;; Skip a `\ comment to end-of-line` (consumes the EOL).
;; Returns #t when one was consumed.
(define (try-skip-line-comment! in cur src)
  (define c (peek-char-cur in))
  (cond
    [(and (char? c) (char=? c #\\))
     ;; Look at the next char: if whitespace/EOF, treat as line comment.
     (read-char-cur in cur)  ; consume \
     (define c2 (peek-char-cur in))
     (cond
       [(or (eof-object? c2)
            (sixth-whitespace? c2))
        (let loop ()
          (define cc (read-char-cur in cur))
          (cond
            [(eof-object? cc) (void)]
            [(char=? cc #\newline) (void)]
            [else (loop)]))
        #t]
       [else
        ;; Not a comment — `\X` where X is non-whitespace.  Treat as
        ;; the start of a word that includes the backslash.  We need to
        ;; unread the \ — Racket has no unread, so we synthesise via a
        ;; pushback port.  For now: raise an error; backslash-prefixed
        ;; words are not supported.
        (raise (exn:fail:sixth:lex
                (format "lex error at ~a: '\\' not followed by whitespace"
                        (format-srcloc (make-srcloc src
                                                     (cursor-line cur)
                                                     (cursor-col cur)
                                                     (cursor-pos cur)
                                                     1)))
                (current-continuation-marks)
                (make-srcloc src (cursor-line cur) (cursor-col cur)
                              (cursor-pos cur) 1)))])]
    [else #f]))

;; Skip a `( ... )` block comment.  Nesting is NOT supported (Forth
;; convention).  Returns #t when one was consumed.
(define (try-skip-block-comment! in cur src)
  (define c (peek-char-cur in))
  (cond
    [(and (char? c) (char=? c #\())
     (read-char-cur in cur)  ; consume (
     (let loop ()
       (define cc (read-char-cur in cur))
       (cond
         [(eof-object? cc)
          (raise (exn:fail:sixth:lex
                  "lex error: unterminated `( ... )` block comment"
                  (current-continuation-marks)
                  (make-srcloc src (cursor-line cur) (cursor-col cur)
                                (cursor-pos cur) 1)))]
         [(char=? cc #\)) (void)]
         [else (loop)]))
     #t]
    [else #f]))

(define (skip-trivia! in cur src)
  (let loop ()
    (skip-whitespace! in cur)
    (cond
      [(try-skip-line-comment! in cur src)  (loop)]
      [(try-skip-block-comment! in cur src) (loop)]
      [else (void)])))

;; -----------------------------------------------------------------
;; String literal reader
;; -----------------------------------------------------------------

(define (read-string-literal! in cur src)
  (define start-line (cursor-line cur))
  (define start-col  (cursor-col cur))
  (define start-pos  (cursor-pos cur))
  (read-char-cur in cur)  ; consume opening "
  (define out (open-output-string))
  (let loop ()
    (define c (read-char-cur in cur))
    (cond
      [(eof-object? c)
       (raise (exn:fail:sixth:lex
               "lex error: unterminated string literal"
               (current-continuation-marks)
               (make-srcloc src start-line start-col start-pos 1)))]
      [(char=? c #\") (void)]
      [(char=? c #\\)
       (define esc (read-char-cur in cur))
       (cond
         [(eof-object? esc)
          (raise (exn:fail:sixth:lex
                  "lex error: unterminated escape in string"
                  (current-continuation-marks)
                  (make-srcloc src start-line start-col start-pos 1)))]
         [(char=? esc #\n) (write-char #\newline out) (loop)]
         [(char=? esc #\t) (write-char #\tab out) (loop)]
         [(char=? esc #\r) (write-char #\return out) (loop)]
         [(char=? esc #\\) (write-char #\\ out) (loop)]
         [(char=? esc #\") (write-char #\" out) (loop)]
         [else
          (raise (exn:fail:sixth:lex
                  (format "lex error: unknown escape \\~a" esc)
                  (current-continuation-marks)
                  (make-srcloc src (cursor-line cur) (cursor-col cur)
                                (cursor-pos cur) 1)))])]
      [else (write-char c out) (loop)]))
  (define value (get-output-string out))
  (mk-token 'str value src start-line start-col start-pos
            (- (cursor-pos cur) start-pos)))

;; -----------------------------------------------------------------
;; Word / number reader (anything not a special form)
;; -----------------------------------------------------------------

(define (read-word! in cur src)
  (define start-line (cursor-line cur))
  (define start-col  (cursor-col cur))
  (define start-pos  (cursor-pos cur))
  (define out (open-output-string))
  (let loop ()
    (define c (peek-char-cur in))
    (cond
      [(or (eof-object? c) (sixth-delimiter? c)) (void)]
      [else (write-char (read-char-cur in cur) out) (loop)]))
  (define s (get-output-string out))
  (define span (- (cursor-pos cur) start-pos))
  ;; classify
  (cond
    [(equal? s ":")    (mk-token 'colon s src start-line start-col start-pos span)]
    [(equal? s ";")    (mk-token 'semi  s src start-line start-col start-pos span)]
    [(equal? s "if")   (mk-token 'if    s src start-line start-col start-pos span)]
    [(equal? s "else") (mk-token 'else  s src start-line start-col start-pos span)]
    [(equal? s "then") (mk-token 'then  s src start-line start-col start-pos span)]
    [(equal? s "use")  (mk-token 'use   s src start-line start-col start-pos span)]
    [else
     (define n (string->number s))
     (if n
         (mk-token 'num n src start-line start-col start-pos span)
         (mk-token 'word s src start-line start-col start-pos span))]))

;; -----------------------------------------------------------------
;; Top-level: tokenize an input port
;; -----------------------------------------------------------------

(define (tokenize-port in [src #f])
  (define cur (make-cursor))
  (define acc '())
  (let loop ()
    (skip-trivia! in cur src)
    (define c (peek-char-cur in))
    (cond
      [(eof-object? c) (void)]
      [(char=? c #\")
       (set! acc (cons (read-string-literal! in cur src) acc))
       (loop)]
      [(char=? c #\')
       (define t (mk-token 'tick "'" src (cursor-line cur) (cursor-col cur)
                            (cursor-pos cur) 1))
       (read-char-cur in cur)
       (set! acc (cons t acc))
       (loop)]
      [else
       (set! acc (cons (read-word! in cur src) acc))
       (loop)]))
  (reverse acc))

(define (tokenize str [src #f])
  (tokenize-string str src))

(define (tokenize-string str [src #f])
  (define in (open-input-string str))
  (tokenize-port in src))

(define (tokenize-file path)
  (call-with-input-file path
    (lambda (in) (tokenize-port in path))))
