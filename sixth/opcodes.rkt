#lang racket/base

;; sixth/opcodes.rkt — opcode enum + struct.
;;
;; The compiler lowers AST nodes to a flat vector of `op` structs.
;; Each op has a numeric tag (see `op-codes`), an optional argument
;; (literal value, word name, branch target), and a source location.
;;
;; Status: Phase A skeleton — full set lands in Phase C.

(provide
  (struct-out op)
  op-LIT
  op-CALL
  op-JZ
  op-JMP
  op-RET
  op-PRIM
  op-name)

(struct op (code arg srcloc) #:transparent)

;; Opcode constants
(define op-LIT  0)  ; arg = literal value
(define op-CALL 1)  ; arg = word name (symbol) → lookup + push frame
(define op-JZ   2)  ; arg = target offset; pop, if 0 jump
(define op-JMP  3)  ; arg = target offset; unconditional
(define op-RET  4)  ; arg = #f; return from word
(define op-PRIM 5)  ; arg = primitive name (symbol)

(define (op-name code)
  (case code
    [(0) 'LIT]
    [(1) 'CALL]
    [(2) 'JZ]
    [(3) 'JMP]
    [(4) 'RET]
    [(5) 'PRIM]
    [else 'UNKNOWN]))
