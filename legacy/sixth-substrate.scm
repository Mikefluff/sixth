#!/usr/bin/env scheme
;; SIXTH-SUBSTRATE — Sixth extended with hypergraph + rewrite primitives.
;;
;; Adds (on top of base Sixth 15 primitives) a substrate of nodes + directed
;; edges, with operations sufficient to grow Peano arithmetic, then sequence,
;; then stable patterns under rewriting.
;;
;; New primitives:
;;   MARK     ( -- n )       create fresh node, push id (ids start at 1)
;;   EDGE+    ( s d -- )     add directed edge s→d
;;   EDGE-    ( s d -- )     remove edge s→d
;;   EDGE?    ( s d -- bit ) 1 if edge exists, else 0
;;   OUT      ( n -- count ) outgoing edge count
;;   IN       ( n -- count ) incoming edge count
;;   NEXT     ( n -- m )     first outgoing target (0 = none)
;;   PREV     ( n -- m )     first incoming source  (0 = none)
;;   NODES    ( -- count )   total nodes created
;;   EDGES    ( -- count )   total edges currently
;;   STEP     ( -- )         increment step counter (= 1 tick of time)
;;   NOW      ( -- step )    current step counter
;;   ASSERT   ( v -- )       error if v = 0, log ok otherwise
;;   RESET    ( -- )         clear all substrate state

(import (scheme base) (scheme read) (scheme write) (scheme file) (srfi 69))

(define (caddr x) (car (cdr (cdr x))))

;; ---------- base Sixth state ----------
(define *stack* '())
(define *memory* (make-hash-table equal?))
(define *words* (make-hash-table equal?))

(define (push! x) (set! *stack* (cons x *stack*)))
(define (pop!) (let ((x (car *stack*))) (set! *stack* (cdr *stack*)) x))
(define (peek) (car *stack*))

(define (sixth-dup) (push! (peek)))
(define (sixth-drop) (pop!))
(define (sixth-swap) (let* ((a (pop!)) (b (pop!))) (push! a) (push! b)))
(define (sixth-over) (let* ((a (pop!)) (b (peek))) (push! a) (push! b)))
(define (sixth-+) (let* ((b (pop!)) (a (pop!))) (push! (+ a b))))
(define (sixth--) (let* ((b (pop!)) (a (pop!))) (push! (- a b))))
(define (sixth-*) (let* ((b (pop!)) (a (pop!))) (push! (* a b))))
(define (sixth-/) (let* ((b (pop!)) (a (pop!))) (push! (quotient a b))))
(define (sixth-mod) (let* ((b (pop!)) (a (pop!))) (push! (remainder a b))))
(define (sixth-=) (let* ((b (pop!)) (a (pop!))) (push! (if (equal? a b) 1 0))))
(define (sixth-<) (let* ((b (pop!)) (a (pop!))) (push! (if (< a b) 1 0))))
(define (sixth->) (let* ((b (pop!)) (a (pop!))) (push! (if (> a b) 1 0))))
(define (sixth-store) (let* ((addr (pop!)) (val (pop!))) (hash-table-set! *memory* addr val)))
(define (sixth-load) (let* ((addr (pop!)))
                       (push! (if (hash-table-exists? *memory* addr)
                                  (hash-table-ref *memory* addr) 0))))

;; ---------- substrate state ----------
(define *nodes* (make-hash-table equal?))
(define *out-edges* (make-hash-table equal?))
(define *in-edges*  (make-hash-table equal?))
(define *born-at*  (make-hash-table equal?))
(define *node-features* (make-hash-table equal?))
(define *next-node-id* 0)
(define *step-counter* 0)
(define *edge-count* 0)

(define (substrate-reset)
  (set! *nodes* (make-hash-table equal?))
  (set! *out-edges* (make-hash-table equal?))
  (set! *in-edges*  (make-hash-table equal?))
  (set! *born-at*  (make-hash-table equal?))
  (set! *node-features* (make-hash-table equal?))
  (set! *next-node-id* 0)
  (set! *step-counter* 0)
  (set! *edge-count* 0))

(define (substrate-nset)
  (let* ((v (pop!)) (n (pop!)))
    (hash-table-set! *node-features* n v)))

(define (substrate-nget)
  (let* ((n (pop!)))
    (push! (if (hash-table-exists? *node-features* n)
                (hash-table-ref *node-features* n) 0))))

(define (substrate-nsum)
  ;; Sum NGET values of all out-neighbours of n.
  ;; Used for CA neighbour counting (Conway etc.).
  (let* ((n (pop!)) (s 0))
    (for-each (lambda (dst)
                (set! s (+ s (if (hash-table-exists? *node-features* dst)
                                  (hash-table-ref *node-features* dst) 0))))
              (outs-of n))
    (push! s)))

(define (substrate-mark)
  (set! *next-node-id* (+ *next-node-id* 1))
  (hash-table-set! *nodes* *next-node-id* '())
  (hash-table-set! *born-at* *next-node-id* *step-counter*)
  (push! *next-node-id*))

(define (substrate-born)
  (let* ((n (pop!)))
    (push! (if (hash-table-exists? *born-at* n)
                (hash-table-ref *born-at* n) -1))))

(define (substrate-each)
  ;; pop word name (string); apply it to each existing node id, with
  ;; the node id pushed onto the stack before each invocation.  Snapshot
  ;; the node set at start of iteration so newly-marked nodes do not
  ;; participate in the same step (=discrete simulation tick semantics).
  (let* ((wname (pop!))
         (max-node *next-node-id*))
    (let loop ((i 1))
      (when (<= i max-node)
        (push! i)
        (if (hash-table-exists? *words* wname)
            (eval-string (hash-table-ref *words* wname))
            (error (string-append "EACH: unknown rule '"
                                    (if (string? wname) wname "?") "'")))
        (loop (+ i 1))))))

(define (substrate-each-edge)
  ;; pop word name (string); apply it to each existing edge (src,dst),
  ;; pushing src and dst before each invocation.  Snapshot edge set
  ;; so edges added by the rule itself do not extend the iteration.
  (let* ((wname (pop!)) (all-edges '()))
    (for-each
      (lambda (src)
        (for-each (lambda (dst)
                    (set! all-edges (cons (list src dst) all-edges)))
                  (hash-table-ref *out-edges* src)))
      (hash-table-keys *out-edges*))
    (for-each
      (lambda (pair)
        (push! (car pair))
        (push! (cadr pair))
        (if (hash-table-exists? *words* wname)
            (eval-string (hash-table-ref *words* wname))
            (error (string-append "EACH-EDGE: unknown rule '"
                                    (if (string? wname) wname "?") "'"))))
      all-edges)))

(define (substrate-step-ca)
  ;; CA-style parallel update. Rule (word on stack) takes node id,
  ;; returns new state value on top of stack.  All next states
  ;; computed against the CURRENT feature map; commit all at end.
  ;; This enables simultaneous (parallel) update — no serial bias.
  (let* ((wname (pop!)) (next-states '())
         (max-node *next-node-id*))
    (let loop ((i 1))
      (when (<= i max-node)
        (push! i)
        (if (hash-table-exists? *words* wname)
            (eval-string (hash-table-ref *words* wname))
            (error (string-append "STEP-CA: unknown rule '"
                                    (if (string? wname) wname "?") "'")))
        (set! next-states (cons (cons i (pop!)) next-states))
        (loop (+ i 1))))
    (for-each (lambda (pair)
                (hash-table-set! *node-features* (car pair) (cdr pair)))
              next-states)))

(define (substrate-each-2path)
  ;; pop word name (string); apply rule to each snapshot 2-path (a,b,c)
  ;; where edges a→b and b→c both exist at start of iteration.  Pushes
  ;; a b c before each call.  Order-independent (snapshot).
  (let* ((wname (pop!)) (paths '()))
    (for-each
      (lambda (src)
        (for-each
          (lambda (mid)
            (for-each (lambda (dst)
                        (set! paths (cons (list src mid dst) paths)))
                      (outs-of mid)))
          (hash-table-ref *out-edges* src)))
      (hash-table-keys *out-edges*))
    (for-each
      (lambda (triple)
        (push! (car triple))
        (push! (cadr triple))
        (push! (caddr triple))
        (if (hash-table-exists? *words* wname)
            (eval-string (hash-table-ref *words* wname))
            (error (string-append "EACH-2PATH: unknown rule '"
                                    (if (string? wname) wname "?") "'"))))
      paths)))

(define (outs-of n) (if (hash-table-exists? *out-edges* n)
                          (hash-table-ref *out-edges* n) '()))
(define (ins-of  n) (if (hash-table-exists? *in-edges*  n)
                          (hash-table-ref *in-edges*  n) '()))

(define (substrate-edge+)
  (let* ((dst (pop!)) (src (pop!)))
    (when (not (member dst (outs-of src)))
      (hash-table-set! *out-edges* src (cons dst (outs-of src)))
      (hash-table-set! *in-edges*  dst (cons src (ins-of  dst)))
      (set! *edge-count* (+ *edge-count* 1)))))

(define (substrate-edge-)
  (let* ((dst (pop!)) (src (pop!)))
    (when (member dst (outs-of src))
      (hash-table-set! *out-edges* src
                        (filter (lambda (x) (not (equal? x dst))) (outs-of src)))
      (hash-table-set! *in-edges*  dst
                        (filter (lambda (x) (not (equal? x src))) (ins-of  dst)))
      (set! *edge-count* (- *edge-count* 1)))))

(define (filter pred lst)
  (cond ((null? lst) '())
        ((pred (car lst)) (cons (car lst) (filter pred (cdr lst))))
        (else (filter pred (cdr lst)))))

(define (substrate-edge?)
  (let* ((dst (pop!)) (src (pop!)))
    (push! (if (member dst (outs-of src)) 1 0))))

(define (substrate-out)
  (let ((n (pop!))) (push! (length (outs-of n)))))

(define (substrate-in)
  (let ((n (pop!))) (push! (length (ins-of n)))))

(define (substrate-next)
  (let ((n (pop!)))
    (push! (if (null? (outs-of n)) 0 (car (outs-of n))))))

(define (substrate-prev)
  (let ((n (pop!)))
    (push! (if (null? (ins-of n)) 0 (car (ins-of n))))))

(define (substrate-nodes-count) (push! *next-node-id*))
(define (substrate-edges-count) (push! *edge-count*))

(define (substrate-step) (set! *step-counter* (+ *step-counter* 1)))
(define (substrate-now)  (push! *step-counter*))

(define *assert-pass* 0)
(define *assert-fail* 0)

(define (substrate-assert)
  (let ((v (pop!)))
    (if (or (not (number? v)) (= v 0))
        (begin (set! *assert-fail* (+ *assert-fail* 1))
               (display "✗ ASSERT FAIL at step ")
               (display *step-counter*)
               (display "  value=") (display v) (newline))
        (begin (set! *assert-pass* (+ *assert-pass* 1))
               (display "✓ assert@") (display *step-counter*)
               (display " (val=") (display v) (display ")") (newline)))))

(define (substrate-report)
  (display "─────────────────────────────────") (newline)
  (display "REPORT  nodes=") (display *next-node-id*)
  (display "  edges=") (display *edge-count*)
  (display "  steps=") (display *step-counter*)
  (display "  pass=") (display *assert-pass*)
  (display "  fail=") (display *assert-fail*) (newline))

;; ---------- tokenize / dispatch (extended) ----------

(define (tokenize str)
  (define (char-whitespace? c)
    (or (char=? c #\space) (char=? c #\tab)
        (char=? c #\newline) (char=? c #\return)))
  (define (split str)
    (let ((len (string-length str)) (result '()) (current ""))
      (let loop ((i 0))
        (cond ((>= i len)
               (if (> (string-length current) 0)
                   (reverse (cons current result))
                   (reverse result)))
              ((char-whitespace? (string-ref str i))
               (when (> (string-length current) 0)
                 (set! result (cons current result))
                 (set! current ""))
               (loop (+ i 1)))
              (else
               (set! current
                     (string-append current (string (string-ref str i))))
               (loop (+ i 1)))))))
  ;; backslash comments: \ to end of line
  (define (strip-comments str)
    (let loop ((i 0) (out ""))
      (cond ((>= i (string-length str)) out)
            ((and (char=? (string-ref str i) #\\)
                   (or (= i 0)
                       (char-whitespace? (string-ref str (- i 1)))))
             (let skip ((j i))
               (cond ((>= j (string-length str)) out)
                      ((char=? (string-ref str j) #\newline)
                       (loop (+ j 1) (string-append out (string #\newline))))
                      (else (skip (+ j 1))))))
            (else (loop (+ i 1)
                         (string-append out (string (string-ref str i))))))))
  (map (lambda (token)
         (cond ((string->number token) => values) (else token)))
       (split (strip-comments str))))

(define (execute-token token)
  (cond ((number? token) (push! token))
        ((string? token)
         (cond
          ;; base sixth
          ((string=? token "dup") (sixth-dup))
          ((string=? token "drop") (sixth-drop))
          ((string=? token "swap") (sixth-swap))
          ((string=? token "over") (sixth-over))
          ((string=? token "+") (sixth-+))
          ((string=? token "-") (sixth--))
          ((string=? token "*") (sixth-*))
          ((string=? token "/") (sixth-/))
          ((string=? token "mod") (sixth-mod))
          ((string=? token "=") (sixth-=))
          ((string=? token "<") (sixth-<))
          ((string=? token ">") (sixth->))
          ((string=? token "store") (sixth-store))
          ((string=? token "load") (sixth-load))
          ((string=? token ".") (display (pop!)) (display " "))
          ((string=? token "cr") (newline))
          ;; substrate
          ((string=? token "MARK")  (substrate-mark))
          ((string=? token "EDGE+") (substrate-edge+))
          ((string=? token "EDGE-") (substrate-edge-))
          ((string=? token "EDGE?") (substrate-edge?))
          ((string=? token "OUT")   (substrate-out))
          ((string=? token "IN")    (substrate-in))
          ((string=? token "NEXT")  (substrate-next))
          ((string=? token "PREV")  (substrate-prev))
          ((string=? token "NODES") (substrate-nodes-count))
          ((string=? token "EDGES") (substrate-edges-count))
          ((string=? token "STEP")  (substrate-step))
          ((string=? token "NOW")   (substrate-now))
          ((string=? token "BORN")  (substrate-born))
          ((string=? token "EACH")  (substrate-each))
          ((string=? token "EACH-EDGE") (substrate-each-edge))
          ((string=? token "EACH-2PATH") (substrate-each-2path))
          ((string=? token "NSET") (substrate-nset))
          ((string=? token "NGET") (substrate-nget))
          ((string=? token "NSUM") (substrate-nsum))
          ((string=? token "STEP-CA") (substrate-step-ca))
          ((string=? token "ASSERT") (substrate-assert))
          ((string=? token "RESET") (substrate-reset))
          ((string=? token "REPORT") (substrate-report))
          ;; user words
          ((hash-table-exists? *words* token)
           (eval-string (hash-table-ref *words* token)))
          (else (push! token))))))

(define (eval-string str)
  (process-tokens (tokenize str)))

(define (number->str x) (if (number? x) (number->string x) x))

(define (parse-definition tokens)
  (let ((name (car tokens)))
    (let loop ((rest (cdr tokens)) (body '()))
      (cond ((null? rest) (error "Missing ;"))
            ((and (string? (car rest)) (string=? (car rest) ";"))
             (let ((def-str (string-join
                              (reverse (map number->str body)) " ")))
               (hash-table-set! *words* name def-str)
               (cdr rest)))
            (else (loop (cdr rest) (cons (car rest) body)))))))

(define (parse-if tokens)
  (let loop ((rest tokens) (if-part '()) (else-part '()) (in-else? #f) (depth 0))
    (cond ((null? rest) (error "Missing then"))
          ((and (string? (car rest)) (string=? (car rest) "if"))
           (if in-else?
               (loop (cdr rest) if-part (cons (car rest) else-part) #t (+ depth 1))
               (loop (cdr rest) (cons (car rest) if-part) else-part #f (+ depth 1))))
          ((and (string? (car rest)) (string=? (car rest) "then")
                (> depth 0))
           (if in-else?
               (loop (cdr rest) if-part (cons (car rest) else-part) #t (- depth 1))
               (loop (cdr rest) (cons (car rest) if-part) else-part #f (- depth 1))))
          ((and (string? (car rest)) (string=? (car rest) "then"))
           (let ((condition (pop!)))
             (if (and (number? condition) (> condition 0))
                 (eval-string (string-join (reverse (map number->str if-part)) " "))
                 (eval-string (string-join (reverse (map number->str else-part)) " "))))
           (cdr rest))
          ((and (string? (car rest)) (string=? (car rest) "else")
                (= depth 0))
           (loop (cdr rest) if-part else-part #t depth))
          (in-else?
           (loop (cdr rest) if-part (cons (car rest) else-part) #t depth))
          (else
           (loop (cdr rest) (cons (car rest) if-part) else-part #f depth)))))

(define (string-join lst delim)
  (if (null? lst) ""
      (let loop ((acc (car lst)) (rest (cdr lst)))
        (if (null? rest) acc
            (loop (string-append acc delim (car rest)) (cdr rest))))))

(define (process-tokens tokens)
  (cond ((null? tokens) #f)
        ((and (string? (car tokens)) (string=? (car tokens) ":"))
         (process-tokens (parse-definition (cdr tokens))))
        ((and (string? (car tokens)) (string=? (car tokens) "if"))
         (process-tokens (parse-if (cdr tokens))))
        ((and (string? (car tokens)) (string=? (car tokens) "'"))
         (when (not (null? (cdr tokens)))
           (push! (number->str (cadr tokens))))
         (process-tokens (cddr tokens)))
        ((and (string? (car tokens)) (string=? (car tokens) "loadfile"))
         (when (not (null? (cdr tokens)))
           (load-file (cadr tokens)))
         (process-tokens (cddr tokens)))
        (else (execute-token (car tokens)) (process-tokens (cdr tokens)))))

(define (load-file filename)
  (when (file-exists? filename)
    (call-with-input-file filename
      (lambda (port)
        (let ((content (read-all-chars port)))
          (eval-string content))))))

(define (read-all-chars port)
  (let ((chars '()))
    (let loop ()
      (let ((c (read-char port)))
        (if (eof-object? c)
            (list->string (reverse chars))
            (begin (set! chars (cons c chars)) (loop)))))))

(define (repl)
  (display "SIXTH-SUBSTRATE v1  (hypergraph + rewrite primitives)\n")
  (let loop ()
    (display "subst> ")
    (let ((input (read-line)))
      (cond ((eof-object? input) (newline))
            ((string=? input "quit") (display "Goodbye!\n"))
            (else (with-exception-handler
                    (lambda (e) (display "Error: ") (display e) (newline))
                    (lambda () (process-tokens (tokenize input))))
                  (loop))))))

(repl)
