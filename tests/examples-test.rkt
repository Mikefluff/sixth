#lang racket/base

;; tests/examples-test.rkt — regression gate.
;;
;; Runs each of the 78 emergence demos and asserts the cumulative
;; ✓ pass count is unchanged at 1081.  Each demo's expected pass
;; count is listed in the `expected` table below; the sum must
;; equal the gate constant.  Counting ✓ marks printed during the
;; run (engine prints ✓ for every successful ASSERT, including
;; post-RESET ones the REPORT line does not cumulate).
;;
;; The 74 demos are organised conceptually:
;;
;;   01–11  Canonical Spencer-Brown ladder (void → measurement)
;;   12–31  Applications of the substrate (Peano, time, CA, BFS,
;;          conservation, consensus, morphism, Conway, Wolfram)
;;   32–36  Pilot A — substrate-native autopoiesis
;;   37–40  Pilot B — observer-driven conscious evolution
;;   41–42  Pilots C–D — cosmogenesis (bootstrap + substrate-monist)
;;   43     Pilot E — substrate-internal Φ_PA measurement
;;   44–47  Pilot F — encoding-map pilots (transformer / brain /
;;                                         split-brain / colony)
;;   48–52  Pilots G–K — composite distinction, mutation+selection,
;;                       multi-level hierarchy, charge conservation,
;;                       spontaneous coalition assembly
;;   53–54  Long-epoch parametric pilots
;;   55–74  Visual-trace track (every numerical pilot's DOT-snapshot
;;          companion, consolidated at the end of the catalogue)

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
  '(;; --- Canonical Spencer-Brown ladder (11 rungs) ---
    ("01-void.6th"                          2)
    ("02-first-distinction.6th"             5)
    ("03-second-distinction.6th"            5)
    ("04-first-pointer.6th"                 8)
    ("05-self-pointer.6th"                  5)
    ("06-mutual-pointing.6th"               8)
    ("07-observer-state.6th"                5)
    ("08-i-not-i.6th"                       6)
    ("09-recognition.6th"                   6)
    ("10-closure-of-not-i.6th"              8)
    ("11-measurement.6th"                   6)
    ;; --- Applications (substrate as foundation for Peano / time /
    ;;     CA / BFS / conservation / morphism / Conway / Wolfram) ---
    ("12-numbers.6th"                      11)
    ("13-time.6th"                         13)
    ("14-stable.6th"                       14)
    ("15-conflict.6th"                     12)
    ("16-loop.6th"                         11)
    ("17-observers.6th"                    14)
    ("18-rewrite-tc.6th"                   23)
    ("19-distance-1d.6th"                  16)
    ("20-ca-rule90.6th"                    25)
    ("21-self-model.6th"                   20)
    ("22-energy.6th"                       13)
    ("23-wolfram.6th"                      14)
    ("24-conservation.6th"                 19)
    ("25-grid-2d.6th"                      20)
    ("26-glider-1d.6th"                    22)
    ("27-rule110.6th"                      22)
    ("28-consensus.6th"                    16)
    ("29-morphism.6th"                     11)
    ("30-conway-blinker.6th"               25)
    ("31-conway-glider.6th"                38)
    ;; --- Pilot A: substrate-native autopoiesis ---
    ("32-autopoietic-ring.6th"             29)
    ("33-observer-collapse.6th"             6)
    ("34-self-maintaining-observer.6th"    11)
    ("35-growing-observer.6th"             18)
    ("36-substrate-genesis.6th"            16)
    ;; --- Pilot B: observer-driven conscious evolution ---
    ("37-symbiosis.6th"                    18)
    ("38-reproduction.6th"                 31)
    ("39-conscious-mutation.6th"           18)
    ("40-goal-directed-observer.6th"       23)
    ;; --- Pilots C–D: cosmogenesis ---
    ("41-cosmogenesis-bootstrap.6th"       21)
    ("42-observer-driven-cosmogenesis.6th" 17)
    ;; --- Pilot E: substrate-internal Φ_PA measurement ---
    ("43-phi-pa-measurement.6th"           12)
    ;; --- Pilot F: encoding-map pilots ---
    ("44-phi-pa-transformer-toy.6th"       10)
    ("45-phi-pa-brain-toy.6th"             12)
    ("46-phi-pa-split-brain-toy.6th"       14)
    ("47-phi-pa-ant-colony-toy.6th"        10)
    ;; --- Pilots G–K: composite distinction and its extensions ---
    ("48-composite-distinction-meta-observer.6th"  21)
    ("49-mutation-selection-particle-zoo.6th"      29)
    ("50-particle-families-hierarchy.6th"          35)
    ("51-charge-conservation.6th"                  56)
    ("52-spontaneous-coalition-assembly.6th"       32)
    ;; --- Long-epoch parametric pilots ---
    ("53-long-epoch-autopoiesis.6th"       11)
    ("54-long-epoch-growth.6th"             8)
    ;; --- Visual-trace track (consolidated at end) ---
    ("55-trace-pilot-d.6th"                 6)
    ("56-trace-pilot-c.6th"                 6)
    ("57-trace-split-brain.6th"             6)
    ("58-trace-conway-blinker.6th"         15)
    ("59-trace-conway-glider.6th"          11)
    ("60-trace-rule110.6th"                 6)
    ("61-trace-rule90.6th"                  6)
    ("62-trace-glider-1d.6th"               7)
    ("63-trace-atomic-pilot-d.6th"          5)
    ("64-trace-atomic-hello.6th"            5)
    ("65-trace-pa-ontological-shell.6th"    5)
    ("66-trace-pilot-e-phi-pa.6th"          9)
    ("67-trace-pilot-f1-transformer.6th"    9)
    ("68-trace-pilot-f2-brain.6th"         10)
    ("69-trace-pilot-f4-colony.6th"         8)
    ("70-trace-composite-distinction.6th"   5)
    ("71-trace-mutation-selection.6th"      4)
    ("72-trace-particle-families.6th"       4)
    ("73-trace-charge-conservation.6th"     4)
    ("74-trace-spontaneous-assembly.6th"    4)
    ;; --- Pilot L (extension) — particle interaction / bound state ---
    ("75-particle-interaction.6th"         28)
    ("76-trace-particle-interaction.6th"    5)
    ;; --- Pilot M (extension) — bound-state decay (inverse of L) ---
    ("77-particle-decay.6th"               27)
    ("78-trace-particle-decay.6th"          5)))

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
  (check-equal? total-pass 1081
                (format "cumulative ✓ count: ~a (expected 1081)" total-pass)))

(displayln (format "examples regression: ~a / 1081 ✓ across ~a demos"
                   total-pass (length expected)))
