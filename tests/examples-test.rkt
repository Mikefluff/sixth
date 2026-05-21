#lang racket/base

;; tests/examples-test.rkt — regression gate.
;;
;; Runs each of the 60 emergence demos and asserts the cumulative
;; ✓ pass count is unchanged at 867.  Each demo's expected pass
;; count is listed in the `expected` table below; the sum must
;; equal the gate constant.  Counting ✓ marks printed during the
;; run (engine prints ✓ for every successful ASSERT, including
;; post-RESET ones the REPORT line does not cumulate).

(require rackunit
         racket/file
         racket/port
         racket/system
         racket/path
         racket/string)

(define examples-root
  (simplify-path
   (build-path (path-only (or (syntax-source #'here)
                              (current-load-relative-directory)))
               'up "examples")))

(define expected
  '(;; Sacred hello world — the first distinction
    ("00-first-distinction.6th"        11)
    ("01-numbers.6th"                  11)
    ("02-time.6th"                     13)
    ("03-stable.6th"                   14)
    ("04-conflict.6th"                 12)
    ("05-loop.6th"                     11)
    ("06-observers.6th"                14)
    ("07-rewrite-tc.6th"               23)
    ("08-distance-1d.6th"              16)
    ("09-ca-rule90.6th"                25)
    ("10-self-model.6th"               20)
    ("11-energy.6th"                   13)
    ("12-wolfram.6th"                  14)
    ("13-conservation.6th"             19)
    ("14-grid-2d.6th"                  20)
    ("15-glider-1d.6th"                22)
    ("16-rule110.6th"                  22)
    ("17-consensus.6th"                16)
    ("18-morphism.6th"                 11)
    ("19-conway-blinker.6th"           25)
    ("20-conway-glider.6th"            38)
    ;; Phase J' — substrate-native autopoiesis
    ("21-autopoietic-ring.6th"         29)
    ("22-observer-collapse.6th"         6)
    ("23-self-maintaining-observer.6th" 11)
    ("24-growing-observer.6th"         18)
    ("25-substrate-genesis.6th"        16)
    ;; Phase K — conscious evolution toward cosmogenesis
    ("26-symbiosis.6th"                18)
    ("27-reproduction.6th"             31)
    ("28-conscious-mutation.6th"       18)
    ("29-goal-directed-observer.6th"   23)
    ("30-cosmogenesis-bootstrap.6th"   21)
    ;; Phase L — observer-driven cosmogenesis (substrate-monist)
    ("31-observer-driven-cosmogenesis.6th" 17)
    ;; Phase M — substrate-internal Phi_PA measurement (Pilot E)
    ("32-phi-pa-measurement.6th"           12)
    ;; Phase N — encoding-map pilots (Pilot F)
    ("33-phi-pa-transformer-toy.6th"       10)
    ("34-phi-pa-brain-toy.6th"             12)
    ("35-phi-pa-split-brain-toy.6th"       14)
    ("36-phi-pa-ant-colony-toy.6th"        10)
    ;; Phase O — visual trace pilots
    ("37-trace-pilot-d.6th"                 6)
    ("38-trace-pilot-c.6th"                 6)
    ("39-trace-split-brain.6th"             6)
    ;; Phase P — long-epoch / parametric (CLI --define)
    ("40-long-epoch-autopoiesis.6th"       11)
    ("41-long-epoch-growth.6th"             8)
    ;; Phase Q — foundation visual traces (state-aware)
    ("42-trace-conway-blinker.6th"         15)
    ("43-trace-conway-glider.6th"          11)
    ("44-trace-rule110.6th"                 6)
    ("45-trace-rule90.6th"                  6)
    ("46-trace-glider-1d.6th"               7)
    ;; Phase R — atomic-build traces (one primitive per frame)
    ("47-trace-atomic-pilot-d.6th"          5)
    ("48-trace-atomic-hello.6th"            5)
    ;; Phase S — PA-ontological decomposition trace
    ("49-trace-pa-ontological-shell.6th"    5)
    ;; Phase T — Pilot E and Pilot F.1/F.2/F.4 visual traces
    ("50-trace-pilot-e-phi-pa.6th"          9)
    ("51-trace-pilot-f1-transformer.6th"    9)
    ("52-trace-pilot-f2-brain.6th"         10)
    ("53-trace-pilot-f4-colony.6th"         8)
    ;; Phase U — Pilot G: composite distinction via meta-self-loop
    ("54-composite-distinction-meta-observer.6th"  21)
    ("55-trace-composite-distinction.6th"           5)
    ;; Phase V — Pilot H: mutation + substrate-readable selection
    ("56-mutation-selection-particle-zoo.6th"      29)
    ("57-trace-mutation-selection.6th"              4)
    ;; Phase W — Pilot I: multi-level particle hierarchy
    ("58-particle-families-hierarchy.6th"          35)
    ("59-trace-particle-families.6th"               4)))

(define (run-demo file)
  (define out
    (with-output-to-string
      (lambda ()
        (system* (find-executable-path "racket")
                 "-l" "sixth/cli" "--" "run"
                 (path->string (build-path examples-root file))))))
  (define lines (string-split out "\n"))
  (define passes (length (filter (lambda (l) (regexp-match? #px"^✓" l)) lines)))
  (define fails  (length (filter (lambda (l) (regexp-match? #px"^✗" l)) lines)))
  (values passes fails))

(define total-pass
  (for/sum ([row (in-list expected)])
    (define-values (passes fails) (run-demo (car row)))
    (test-case (string-append "demo " (car row))
      (check-equal? fails 0   (format "~a had ~a failed asserts" (car row) fails))
      (check-equal? passes (cadr row)
                    (format "~a expected ~a passes, got ~a"
                            (car row) (cadr row) passes)))
    passes))

(test-case "cumulative regression gate"
  (check-equal? total-pass 867
                (format "cumulative ✓ count: ~a (expected 867)" total-pass)))

(displayln (format "examples regression: ~a / 867 ✓ across ~a demos"
                   total-pass (length expected)))
