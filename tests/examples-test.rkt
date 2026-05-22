#lang racket/base

;; tests/examples-test.rkt — regression gate.
;;
;; Runs each of the 98 emergence demos and asserts the cumulative
;; ✓ pass count is unchanged at 1469.  Each demo's expected pass
;; count is listed in the `expected` table below; the sum must
;; equal the gate constant.  Counting ✓ marks printed during the
;; run (engine prints ✓ for every successful ASSERT, including
;; post-RESET ones the REPORT line does not cumulate).
;;
;; The 98 demos are organised conceptually:
;;
;;   01–11   Canonical Spencer-Brown ladder (void → measurement)
;;   12–31   Applications (Peano, time, CA, BFS, conservation,
;;           morphism, Conway, Wolfram)
;;   32–36   Pilot A — substrate-native autopoiesis
;;   37–40   Pilot B — observer-driven conscious evolution
;;   41–42   Pilots C–D — cosmogenesis
;;   43      Pilot E — substrate-internal Φ_PA measurement
;;   44–47   Pilot F — encoding-map pilots
;;   48–52   Pilots G–K — composite/particle pilots
;;   53–54   Long-epoch parametric
;;   55–74   Visual-trace track (DOT-snapshot companions)
;;   75–78   Pilots L/M — particle interaction + decay
;;   79–84   Stress-test track (parametric long-run invariants)
;;   85–92   Honest-emergence track (composites EMERGE from rules)
;;   90      Peircean trit observer
;;   93–104  HEDGE3 typed trivalent hyperedges
;;
;; Gaps 95–97, 99, 101–102 are intentional cuts of fake-deep
;; hash-table demos (see CHANGELOG.md for rationale).

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
    ("78-trace-particle-decay.6th"          5)
    ;; --- Stress-test track (parametric via -D max-cycles=N) ---
    ;; Default N=1000 keeps the gate CI-fast; user-facing showcase
    ;; via `make stress-test CYCLES=1000000`.
    ("79-stress-charge-conservation.6th"    8)
    ("80-stress-bind-decay-cycle.6th"      17)
    ("81-stress-autopoiesis-stability.6th" 11)
    ("82-stress-conway-blinker-periodicity.6th"  8)
    ("83-stress-sprout-linear-growth.6th"   7)
    ("84-stress-rule184-ring-conservation.6th"   8)
    ;; --- Honest emergent track — composites EMERGE from rules ---
    ;; (corrective to G/H/I/K/L which hand-place the answer; here the
    ;; rule SCANS the substrate and spawns composites in response)
    ("85-emergent-composite-from-scan.6th"  19)
    ("86-emergent-composite-from-chain.6th" 21)
    ("87-emergent-selection.6th"            30)
    ("88-emergent-hierarchy-from-chain.6th" 25)
    ("89-emergent-binding.6th"              22)
    ;; --- Peircean trit observer (research-informed) ---
    ("90-peircean-trit-observer.6th"        21)
    ;; --- Honest emergent track (continued) ---
    ;; 91: honest Pilot M (decay scanner).  92: recursive N-tier
    ;; hierarchy iterated to fixed point.
    ("91-emergent-decay.6th"                23)
    ("92-recursive-hierarchy-fixed-point.6th" 20)
    ;; --- HEDGE3 typed trivalent hyperedges (R3 from ternary-v2) ---
    ;; 93: WITNESS (substrate-native provenance).  94: all four kinds
    ;; coexisting (WITNESS / MEDIATOR / CONTEXT / SIMPLEX) under strict
    ;; type discipline.
    ;; --- HEDGE3 primitive coverage (introductory) ---
    ;; 93 (witness) + 94 (four-kinds coexistence) — exercise the
    ;; primitive surface.  Useful for learning HEDGE3; substrate-
    ;; emergent content is in 98/100/104 below.
    ("93-hedge3-witness.6th"                16)
    ("94-hedge3-four-kinds.6th"             23)
    ;; --- HEDGE3 substantive applications ---
    ;; 98: substrate-readable simplicial complex (Euler χ = V-E+F
    ;;     computed from substrate state, topology transitions).
    ;; 100: MEDIATOR causal hypergraph + fixpoint reachability
    ;;      (forward cone, backward antecedents).
    ;; 103: strict-validation integration test.
    ;; 104: emergent causal time from MEDIATOR DAG —
    ;;      substrate computes substrate-time as longest-path
    ;;      via fixpoint iteration; branching/joining/monotonic
    ;;      extension/causality verified.
    ("98-hedge3-simplex-complex.6th"         24)
    ("100-mediator-causal-graph.6th"         24)
    ("103-hedge3-strict-validation.6th"      27)
    ;; NOTE: demos 95, 96, 97, 99, 101, 102 were cut as fake-deep
    ;; "hash-table dressed up as substrate emergence" per critic
    ;; sweep — see CHANGELOG entry for cut rationale.  The HEDGE3
    ;; primitive surface and substrate-enforced strict typing
    ;; remain; only the storage-and-filter use-case demos were
    ;; removed.
    ("104-emergent-causal-time.6th"          34)
    ;; --- Research-track demos (formal results, may be null/negative) ---
    ;; 105: Track 1.3 — HEDGE3 expressivity benchmark vs binary
    ;;      encoding.  Negative result: no complexity-class
    ;;      separation; HEDGE3 = ergonomic surface, not Peirce-
    ;;      reduction-thesis realisation.  See RESULTS.md.
    ;; 106: Track 2.1 — Φ_PA family parametric sweep.  Negative
    ;;      result: phi-pa exactly linear in scope, no phase
    ;;      transition / critical exponent.  Substrate-derived
    ;;      BOUND on current Φ_PA expressive power.
    ;; 107: Track 2.3 — open-ended Wolfram-style rewrite, no
    ;;      halting predicate.  Positive result: substrate-derived
    ;;      growth law edges_k = 3^k, invariant under initial-
    ;;      condition perturbation.  Honest cosmogenesis in
    ;;      substrate-monism sense.
    ;; 108: Track 2.1b — phi-integ deferred density sweep.
    ;;      Partial positive: two-regime piecewise-linear response
    ;;      (observer-saturation + neighbour-saturation).  Still
    ;;      no critical exponent, but richer than phi-pa.
    ;; 109: Track 2.3b — Wolfram-style rewrite-rule universality
    ;;      across 4 rules with K ∈ {1, 2, 3}.  Verified growth-
    ;;      ratio law E_k = E_0 · (1+K)^k as substrate-derived
    ;;      universality across initial conditions and topology.
    ;; 110: Track 2.2 — substrate-readable percolation order
    ;;      parameter (largest-component-size containing observer
    ;;      via BFS).  POSITIVE: first substrate-readable measure
    ;;      in catalogue exhibiting genuine phase-transition
    ;;      behaviour (discontinuous jump from 2 → 10 at bridge
    ;;      edge, reversible under EDGE-).
    ;; 111: Track 2.2 follow-up — phi-perc stdlib member
    ;;      verification.  Materialises demo 110 finding into
    ;;      stdlib/phi.6th as a new Φ-family member with phase-
    ;;      transition behaviour.  Comparison: phi-pa UNCHANGED
    ;;      across bridge edge, phi-perc JUMPS — orthogonal
    ;;      discriminating signal.
    ;; 112: phi-perc read-only contract verification.  Snap/
    ;;      restore wrapper via negative-int memory keys preserves
    ;;      pre-call NGET state across phi-perc invocations.
    ;;      Eliminates the cycle-2 caveat about NGET mutation.
    ;; 113: Track 4.1 — Φ-family combination laws for nested
    ;;      observers.  phi-pa(M) = (K+1)·L_max structurally
    ;;      independent of children's Φ_PA; phi-perc(M) ~ Σ
    ;;      comp-size(O_i) connectivity-inherited.  Substrate-
    ;;      monist combination problem is MEASURE-DEPENDENT.
    ;; 114: Track 2.2c — percolation critical-exponent measurement
    ;;      across n ∈ {10, 20, 30}.  Substrate-derived scaling
    ;;      exponent -1, same universality class as classical
    ;;      Erdős-Rényi p_c = 1/n within factor 2 (deterministic-
    ;;      chain vs random construction).
    ;; --- Infrastructure (RNG) + REAL non-engineered experiments ---
    ;; 115: stdlib RNG via LCG, verified reproducibility + distribution
    ;;      sanity.  Unlocks ensemble experiments without engine
    ;;      modification.
    ;; 116: FIRST non-engineered ensemble experiment — random Erdős-
    ;;      Rényi G(n=10, p) with K=8 samples per p, sweep p=5..50%.
    ;;      Substrate-derived empirical p_c ≈ 15-20% within factor 2
    ;;      of classical 1/n = 10%.  Outcome NOT predicted by author,
    ;;      pinned by seed=42.
    ;; 117: Rule-space enumeration of ALL 9 K=2 rules.  SURPRISE
    ;;      finding: 3/9 rules (s1=s2 duplicates) collapse to K_eff=1
    ;;      due to substrate set-semantics, producing 4 edges instead
    ;;      of naive 9.  The (1+K) law of demo 109 holds only on the
    ;;      non-degenerate subspace.  First open-ended exploration to
    ;;      surface substrate behaviour not predicted by author.
    ("105-hedge3-expressivity-vs-binary.6th"     21)
    ("106-phi-pa-parametric-sweep.6th"           25)
    ("107-open-ended-rewrite.6th"                18)
    ("108-phi-integ-density-sweep.6th"           24)
    ("109-rewrite-rule-universality.6th"         23)
    ("110-substrate-percolation.6th"             22)
    ("111-phi-perc-verification.6th"              9)
    ("112-phi-perc-readonly.6th"                 36)
    ("113-phi-combination-law.6th"               19)
    ("114-percolation-critical-exponent.6th"     16)
    ("115-rand-stdlib.6th"                        7)
    ("116-ensemble-percolation.6th"              15)
    ("117-rule-space-enumeration.6th"            11)
    ;; --- Cycle 5: real measurements + 2nd substrate surprise ---
    ;; 118: ensemble p_c(n) scaling across n ∈ {10, 20, 30}.
    ;;      Substrate-derived empirical p_c with sharpening
    ;;      transition at n=20 (jump 22500 → 127500 in single
    ;;      p-step).  Ratio p_c(20)/p_c(10) = 0.66 vs classical
    ;;      0.50.  Same scaling direction, factor ~1.3 deviation.
    ;; 119: K=3 rule enumeration (27 variants).  2ND SURPRISE:
    ;;      all 6 K_eff=3 rules give 15 edges, not naive 16.
    ;;      Second-order substrate degeneracy from self-loops in
    ;;      iter-1 output (c-source rules create (c,c) self-loop
    ;;      that degenerates at iter 2).  K_eff = #unique-sources
    ;;      is first-order only; K=3 surfaces second-order
    ;;      correction K=2 enumeration missed.
    ("118-ensemble-pc-scaling.6th"               24)
    ("119-k3-rule-enumeration.6th"                6)))

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
  (check-equal? total-pass 1745
                (format "cumulative ✓ count: ~a (expected 1745)" total-pass)))

(displayln (format "examples regression: ~a / 1745 ✓ across ~a demos"
                   total-pass (length expected)))
