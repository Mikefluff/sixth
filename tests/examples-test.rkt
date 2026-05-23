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
    ("119-k3-rule-enumeration.6th"                6)
    ;; --- Cycle 6: statistical infrastructure + retract ---
    ;; 120: stats stdlib verification (isqrt, mean, var, stddev).
    ;; 121: REAL multi-seed ensemble percolation (M=10 seeds ×
    ;;      K=20 samples per (seed, p) = 200 samples per p).
    ;;      RETRACTS demo 116's claim of sharp phase transition
    ;;      at p=15-20%.  Real ensemble curve is SMOOTH MONOTONIC
    ;;      (16600 → 28950 → 46250 → 64050 → 88700), with stddev
    ;;      22-32K peaking in transition region.  No sharp
    ;;      transition at n=10 — finite-size smearing dominates.
    ;;      First measurement in catalogue with proper error bars.
    ("120-stats-verification.6th"                24)
    ("121-multiseed-ensemble.6th"                18)
    ;; --- Cycle 7: multi-observer + theory-driven prediction ---
    ;; 122: multi-observer ensemble — phi-perc averaged across
    ;;      all n observers per graph + multi-seed.  Confirms
    ;;      single-observer and multi-observer give close means
    ;;      at n=10 (within 1σ for all p).
    ;; 123: FIRST predict-THEN-measure cycle in catalogue.
    ;;      Theory: at deep supercritical p, ratio ⟨phi-perc⟩(n=20)
    ;;      / ⟨phi-perc⟩(n=10) ∈ [2.0, 2.2].  Measured: 217%,
    ;;      intensive ratio 108%.  Substrate extensivity CONFIRMED.
    ("122-multiobserver-ensemble.6th"            18)
    ("123-theory-extensivity.6th"                14)
    ;; --- Cycle 8: pre-registered substrate-vs-classical-ER test ---
    ;; 124: FIRST cycle with binding pre-registration in git
    ;;      (PREDICTIONS-124.md committed b0fcccd before demo source).
    ;;      Result: 3/4 tight-bound matches.  Substrate phi-perc at
    ;;      n=20, p=10% (near-critical) APPEARED to exceed classical
    ;;      ER prediction by 21% — but cycle 9 (demo 125) shows the
    ;;      "classical" baseline was a wrong asymptotic formula, not
    ;;      true classical.  Substrate values are correct; finding
    ;;      RETRACTED by cycle 9 — see demo 125 and RESULTS.md.
    ("124-substrate-vs-classical-er.6th"         25)
    ;; --- Cycle 9: independent classical reference retracts cycle-8 ---
    ;; 125: networkx Monte Carlo (n=20, M=10000, Mersenne Twister via
    ;;      scripts/ref_ergraph_125.py) gives true classical reference
    ;;      126,549 at p=10% (cf. asymptotic formula's 108,400 and
    ;;      substrate's 130,900).  Substrate WITHIN 1σ of true
    ;;      classical.  Cycle-8 "substrate-derived deviation"
    ;;      RETRACTED as theory-side error.  Substrate phi-perc tracks
    ;;      true classical ER faithfully at finite n=20.
    ;;      Pre-registered: PREDICTIONS-125.md (commit 99f33f0).
    ("125-classical-ref-vs-formula.6th"          11)
    ;; --- Cycle 10A: substrate M=1000 cross-validates cycle-9 claim ---
    ;; 126: M=50 × K=20 = 1000 graphs at n=20, p=10%.  Substrate
    ;;      mean 125,120 ± SEM 2,170 vs reference 126,549.
    ;;      |diff| = 1,429 = 0.66σ_1000.  REGIME D fired
    ;;      (faithful within ±1σ of reference).  Cycle 9 weak claim
    ;;      ("within 1σ at M=100") cross-validated at 10× tighter
    ;;      precision; substrate IS a faithful classical-ER
    ;;      reachability implementation at n=20 p=10%.
    ;;      Pre-registered: PREDICTIONS-126.md (commit f31ba43).
    ("126-substrate-m1000.6th"                   13)
    ;; --- Cycle 10C: phi-integ pivot beyond tautology ---
    ;; 127: phi-integ ensemble on feature-loaded ER at n=20, p=10%,
    ;;      M=1000.  Pre-registered (PREDICTIONS-127.md, commit
    ;;      b482dc7, attested via ledger): regime D match means
    ;;      substrate reproduces correlation-corrected analytic
    ;;      303,400; regime E means substrate misses correlation.
    ;;      Measurement: 297,650 → REGIME D (correlation-corrected
    ;;      match within 2%).  Substrate validates classical
    ;;      second-moment ER theory — BUT see demo 128 for cycle
    ;;      11A networkx cross-check which fires regime F'.
    ("127-feature-loaded-phi-integ.6th"          14)
    ;; --- Cycle 11A: phi-integ ref cross-check (regime F' fires) ---
    ;; 128: networkx M=10000 reference for phi-integ semantics.
    ;;      Reference 310,577 vs substrate cycle 10C 297,650 vs
    ;;      analytic 303,400.  |ref - substrate| = 12,927 > pre-reg
    ;;      threshold 5,000 → REGIME F' (substrate deviates).
    ;;      |ref - analytic| = 7,177 ≤ 9,000 → analytic OK.
    ;;      Per pre-reg PREDICTIONS-128.md (commit 6a1fd73): cycle
    ;;      10C TECHNICALLY RETRACTED.  Cycle 11A.1 (demo 129)
    ;;      shows the deviation was MOSTLY sampling (halved at
    ;;      M=10000); residual ~2% remains within combined 1.29σ.
    ("128-phi-integ-ref-crosscheck.6th"           7)
    ;; --- Cycle 11A.1: substrate M=10000 resolves F' (regime I) ---
    ;; 129: substrate phi-integ M=500 × K=20 = 10000 graphs.
    ;;      Mean 304,701 ± SEM 3,165 vs ref 310,577 ± SEM 3,275.
    ;;      |diff| = 5,876 → REGIME I (just over H=5000 boundary,
    ;;      well under J=12000).  Cycle 11A regime F' was MOSTLY
    ;;      sampling artifact (M=1000 diff 12,927 → M=10000 diff
    ;;      5,876 = halved).  Residual ~2% may be small real bias
    ;;      worth cycle 12 investigation, but within combined
    ;;      1.29σ — not significant.  Substrate APPROXIMATELY
    ;;      faithful at second-moment level.
    ;;      Pre-registered: PREDICTIONS-129.md (commit c0ee1a8).
    ("129-substrate-phi-integ-m10k.6th"          12)
    ;; --- Cycle 11B: iterated NSUM dynamics (regime L — axiom falsified) ---
    ;; 130: substrate-axiomatic experiment.  Init NGET=1 for all
    ;;      nodes; STEP-CA-iterate NSET v ← NSUM(v); measure
    ;;      phi-integ(1) at t=0, t=1, t=2.  M=20 × K=5 = 100 graphs.
    ;;      Pre-registered (PREDICTIONS-130.md, attested, first
    ;;      cycle under active pre-commit hook): r10=phi_t1/phi_t0
    ;;      should be in [2.5, 3.8] AND r21≥r10 (PA "feature
    ;;      integration" axiom: monotone non-decreasing toward λ₁).
    ;;      Measurement: r10=3.05 (in bound), r21=3.02 < r10 →
    ;;      REGIME L (axiom FALSIFIED per pre-reg rule).
    ;;      RETRACTED in cycle 12A: coin-flip pre-reg rule, strawman
    ;;      axiom, 1% effect within sampling SEM.  See demo header.
    ("130-iterated-nsum-dynamics.6th"            13)
    ;; --- Cycle 12C: HEDGE3 storage counter-example search ---
    ;; 131: enumeration of n=3..6 HEDGE3 configurations (99,497 configs).
    ;;      max R(S) = HEDGE3-cost / min-binary-cost = 1.500
    ;;      min R(S) = 1.000; mean R decreases 1.231→1.137 with n.
    ;;      Pre-registered regime O fires (R_max ∈ [1.5, 2.0]).
    ;;      HONEST interpretation: R > 1 means HEDGE3 takes MORE
    ;;      storage than optimized binary (formula direction).
    ;;      Substrate finding (NEGATIVE direction): HEDGE3 has NO
    ;;      storage advantage at n=3..6; demo 105's "5× advantage"
    ;;      RETRACTED.  Pre-registered: PREDICTIONS-131.md (8adbdee).
    ("131-hedge3-storage-counterexample.6th"     11)
    ;; --- Cycle 13C/D: EICS application — FIRST POSITIVE SIGNAL ---
    ;; 132: Krasnovsky (2025) EICS applied to Sixth substrate.
    ;;      Method: macro-Jacobian = adjacency^T (T=10 iterations),
    ;;      local Jacobian = per-row, sheaf inconsistency from
    ;;      adjacency-as-linearization.  Compared 10 canonical
    ;;      substrates vs M=1000 ER random baselines.
    ;;      R_overall = 1.795 → REGIME R.  Cycle 14 (demo 133)
    ;;      shows this signal was mostly sparse-ER baseline artifact;
    ;;      only cycle_n10 survives at degree-matched k-regular
    ;;      baseline.
    ;;      Pre-registered: PREDICTIONS-132.md (commit e50ae0f).
    ("132-eics-application.6th"                   7)
    ;; --- Cycle 14: EICS regular-baseline cross-validation ---
    ;; 133: same EICS as cycle 13 but baseline = random k-regular
    ;;      graphs (degree-matched to each substrate).  Tests if
    ;;      cycle 13's signal survives tighter control.
    ;;      M=500 random regular baselines per substrate.
    ;;      Result: R_overall_regular = 0.815 → REGIME V.
    ;;      Surviving signal: cycle_n10 R=2.00.  Cycle 15 (demo 134)
    ;;      reveals this was mean-degree mis-calc (k=1 baseline).
    ;;      Pre-registered: PREDICTIONS-133.md (commit 50ceb60).
    ("133-eics-regular-baseline.6th"              8)
    ;; --- Cycle 15: cycle-topology scaling + chord-breaking ---
    ;; 134: cycle_n at n ∈ {5, 10, 20, 50, 100} vs proper k=2
    ;;      regular baseline; cycle_10 + {0, 1, 2, 5} chords.
    ;;      Result: REGIME Z + CC.  Cycle 14's R=2.00 reduced to
    ;;      R=1.14 at n=10 (proper baseline), R=1.04 at n=100
    ;;      (vanishing at scale).  Honest surviving claim: cycle
    ;;      has ~14% EICS edge at small n only.
    ;;      Pre-registered: PREDICTIONS-134.md (commit ce5aa80).
    ("134-eics-cycle-scaling.6th"                 7)
    ;; --- Cycle 16: DMBD (Beck-Ramstead 2025) on Sixth ---
    ;; 135: Dynamic Markov Blanket Detection via pyDMBD applied to
    ;;      Sixth substrate trajectories.  Primary R_objects=0.736
    ;;      (REGIME FF, null).  Secondary R_ELBO=1.489 (+49% MB-fit).
    ;;      Cycle 17 (demo 136) tests under degree-matched baseline.
    ;;      Pre-registered: PREDICTIONS-135.md (commit e3d0537).
    ("135-dmbd-substrate.6th"                     8)
    ;; --- Cycle 17: DMBD degree-matched baseline (retracts cycle 16) ---
    ;; 136: same DMBD pipeline as cycle 16 but baseline = random
    ;;      k-regular graphs matching substrate mean degree.
    ;;      Result: R_ELBO_regular = 1.013 (cycle 16 was 1.489).
    ;;      REGIME II (∈ [0.9, 1.3]) — aggregate signal VANISHED.
    ;;      Cycle 16's 49% advantage was sparse-baseline artifact;
    ;;      same exact pattern as cycle 13→14 (R=1.795 → 0.815).
    ;;      Surviving narrow claim: structured topology class (cycle,
    ;;      path, complete, bipartite, star) individually retains
    ;;      modest signal at MB level; ER substrates don't.
    ;;      Cycle 16 broad "49% better MB fit" claim RETRACTED.
    ;;      Pre-registered: PREDICTIONS-136.md (commit 33cef9a).
    ("136-dmbd-regular-baseline.6th"              9)))

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
  (check-equal? total-pass 1964
                (format "cumulative ✓ count: ~a (expected 1964)" total-pass)))

(displayln (format "examples regression: ~a / 1964 ✓ across ~a demos"
                   total-pass (length expected)))
