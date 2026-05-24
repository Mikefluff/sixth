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
    ;;      REGIME II — aggregate signal VANISHED; same exact pattern
    ;;      as cycle 13→14 (R=1.795→0.815).  Cycle 16 broad claim
    ;;      RETRACTED.  Pre-registered: PREDICTIONS-136.md (33cef9a).
    ("136-dmbd-regular-baseline.6th"              9)
    ;; --- Cycle 18: matryoshka storage compression — FIRST CLEAN POSITIVE ---
    ;; 137: Pre-registered (PREDICTIONS-137.md commit 04f2196) test
    ;;      of observer-grouping compression using existing MARK +
    ;;      bi-edge primitives via stdlib/group.6th.
    ;;      For 6 (N,K) test points: predicted R(N,K)=(N×K)/(N+K),
    ;;      observed R EXACTLY matches predicted at ALL 6 points
    ;;      (MARE = 0).  REGIME KK fires (MARE < 0.10 within tolerance).
    ;;      First substrate-derived ENGINEERING FINDING in catalogue
    ;;      that doesn't suffer cycle-14 pattern retraction:
    ;;        - Pre-registered before source
    ;;        - Algebraic prediction with deterministic test
    ;;        - Uses EXISTING substrate primitives (38 unchanged)
    ;;        - Exhaustive verification (every point exact match)
    ;;      Addresses cycle 12 retraction: HEDGE3 "no storage
    ;;      advantage" was because test treated edges as isolated;
    ;;      observer-grouping pattern reveals genuine compression.
    ("137-matryoshka-storage.6th"                 7)
    ;; --- Cycle 19: MDL-descent energetic substrate dynamics ---
    ;; 138: L(state) = unique out-neighbor patterns; STEP-CA-MIN
    ;;      greedy descent.  6 substrates: monotone 6/6, total
    ;;      descent=6, baseline=0.  REGIME AA fires per pre-reg
    ;;      (PREDICTIONS-138.md commit 750789c).  Honest caveat:
    ;;      4/6 stuck at initial — greedy insufficient for active
    ;;      descent on random ER; substrate L-monotonic in weak
    ;;      sense (L never increases) but rarely actively descends.
    ;;      Cycle 20 needs stronger search (2-edge moves, SA).
    ("138-mdl-descent.6th"                        4)
    ;; 139. Cycle 20 — STEP-CA-MIN-STRONG (2-edge moves + SA) tests
    ;;      H_search vs H_landscape: does cycle 19 4/6-stuck reflect
    ;;      weak optimizer or genuine L-plateau?  Result: AA' fires
    ;;      (n_unstuck=5/6, R_strong/greedy=4.0).  H_search WINS.
    ;;      cycle_n10 dropped L 10->1 (SA found symmetric attractor).
    ;;      Substrate L-monotonic in STRONG sense.  Honest scope:
    ;;      MDL is ONE of 7 candidate losses; cycle 21 = MDL + pred.
    ("139-mdl-descent-strong.6th"                 5)
    ;; 140. Cycle 21 — MDL groups vs predictive quality.  Tests
    ;;      user reframe: objecthood needs compression AND prediction.
    ;;      Result: REGIME CCC.  Substrate MDL groups beat random
    ;;      marginally (+0.0077) but LOSE to degree baseline on 5/5
    ;;      non-tie substrates (mean delta -0.0045).  Pure MDL = wrong
    ;;      loss for substrate-of-cognition.  Substrate-derived
    ;;      NEGATIVE — strongest possible falsification.  Cycle 22
    ;;      operationalizes combined L = MDL + lambda*pred_error.
    ("140-mdl-prediction.6th"                     4)
    ;; 141. Cycle 22 — STEP-CA-MIN-COMBINED with L = MDL_norm +
    ;;      lambda*Pred_norm + mu*DegeneracyPenalty.  Dynamics
    ;;      chooses moves by Delta(L_combined) not Delta(MDL).
    ;;      Result: REGIME CCCC.  Best lambda=1.0 wins only 2/6
    ;;      against degree baseline (need >=3 for BBBB pass).
    ;;      DegeneracyPenalty PREVENTED K=1 collapse (good — cycle_n10
    ;;      went to K=3 not K=1).  But high-K saddle blocks search.
    ;;      Substrate-derived NEGATIVE #3.  MDL family CLOSED.
    ;;      Cycle 23 pivots to Information Bottleneck or Predictive
    ;;      Processing per pre-registered consequence.
    ("141-mdl-combined.6th"                       6)
    ;; 142. Cycle 23 Phase A — STEP-CA-PRED: L = PredError +
    ;;      alpha*(K/n) + gamma*DegPenalty.  Predictive-only loss
    ;;      WITHOUT MDL as primary driver.  Result: REGIME CCCCC.
    ;;      Best alpha=0.01 wins 2/6 against degree, but CONCENTRATED
    ;;      (winners = path + ER_n10, same as C22 winners).
    ;;      Three loss families (MDL c21, MDL+Pred c22, Pred-only c23A)
    ;;      all FAIL vs degree on NSUM benchmark.  delta_spread across
    ;;      alphas non-trivial -> landscape has structure but degree
    ;;      IS oracle for NSUM dynamics; no fixed-primitive STEP-CA
    ;;      optimizer can beat it on these substrates.
    ;;      Loss-family arc EXHAUSTED.  Cycle 24+ pivots to runtime
    ;;      primitive induction (engine evolves own primitive alphabet).
    ("142-pred-objecthood.6th"                    6)
    ;; 143. Cycle 25A — Tier 1 runtime law-state mutation smoke test
    ;;      per META-SEMANTICS.md v2 §13.  NO scientific claim; tests
    ;;      runtime mechanics only.  Motif MARK MARK bi-edge x3
    ;;      detected via DETECT-MOTIF; SHADOW-CHECK passes;
    ;;      INDUCE-RUNTIME creates cand_001 and mutates law_hash;
    ;;      cand_001 invoked successfully (USE-RUNTIME);
    ;;      ROLLBACK-RUNTIME restores law_hash.
    ;;      Demonstrates law-state mutation INSIDE a single run —
    ;;      the architectural minimum that distinguishes runtime
    ;;      self-modification from offline deployment pipeline.
    ("143-runtime-promotion.6th"                  7)
    ;; 144. Cycle 25B — substrate signature verification (12 frozen
    ;;      train+heldout substrates from substrates/manifest.6th
    ;;      generated by stdlib/substrate-gen.6th using deterministic
    ;;      seeds) + Tier 2 stub smoke (8 meta-primitives FREEZE-
    ;;      CANDIDATE, TRAIN-EVAL, HELD-OUT-EVAL, PROMOTE-STABLE,
    ;;      RETEST, ATTEST-PRIMITIVE, ROLLBACK-STABLE, ACTIVE-
    ;;      DICTIONARY).  Stubs deliberately gate-closed (HELD-OUT
    ;;      returns 0, PROMOTE returns 'rejected) to prevent
    ;;      over-promotion during plumbing cycle.  Real implementations
    ;;      land in cycle 26+ alongside discovery integration.
    ;;      Architectural completion of 14-meta-primitive set per
    ;;      META-SEMANTICS.md v2 §6.
    ("144-substrate-signatures.6th"              15)
    ;; 145. Cycle 25D — hardening suite verifying 15 invariants per
    ;;      user spec (2026-05-23) before Cycle 26:
    ;;        1  law_hash sensitivity (incl word body)
    ;;        2  world_hash / law_hash separation
    ;;        3  SHADOW-CHECK pass + cert recording
    ;;        4  INDUCE-RUNTIME requires cert
    ;;        5  ROLLBACK transactionally clears cert
    ;;        6  status persists as rolled-back (non-deletion)
    ;;        7  use counter increments on cand dispatch
    ;;        8  CONTAMINATE! sets first-class status
    ;;        9  ledger grows on each meta event
    ;;       10  USE-RUNTIME actually executes (counter side effect)
    ;;       11  PROMOTE-STABLE refusal paths (per-status reasons)
    ;;       12  substrate generator determinism on re-run
    ;;       13  no hidden entropy in law_hash
    ;;       14  regression isolation (verified externally)
    ;;       15  failure recovery — DOCUMENTED GAP cycle 26
    ;;      Plus session id stability sanity.
    ;;      21 asserts.  Documented gaps: 14 (external) + 15 (c26).
    ("145-hardening-suite.6th"                   22)
    ;; 146. Cycle 25E — energy accounting v0 hardening items 16-20.
    ;;        16 _energy-* observation does NOT mutate law_hash or
    ;;           world_hash (measurer-changes-measured trap defended)
    ;;        17 commit-primitive writes energy components to ledger;
    ;;           commit itself does NOT bump energy counters
    ;;        18 demo 143 still passes (no energy gate, only reports)
    ;;        19 COMMIT writes would_pass_energy_gate but does NOT
    ;;           block — gate enforcement deferred to cycle 26
    ;;        20 contamination flag + manual rollback path (auto-
    ;;           rollback on energy regression deferred to cycle 26)
    ;;      Plus E-SNAPSHOT 10-tuple format sanity.  10 asserts.
    ;;      Energy v0 formula: E_total = E_world + E_law + E_trace
    ;;        + E_conflict + E_search - E_reuse_gain
    ("146-energy-accounting.6th"                 10)
    ;; 147. Cycle 26B — happy-path runtime promotion.  MARK MARK
    ;;      bi-edge motif (L=3), N=5 uses across M=3 distinct
    ;;      sessions (via NEW-SESSION), net delta_e = -7 < 0.
    ;;      COMMIT-PRIMITIVE passes BOTH coupling + energy gates
    ;;      (cycle 26 activates energy gate enforcement, was dry-run
    ;;      in cycle 25E).  FREEZE-CANDIDATE stub accepts.  HELD-OUT
    ;;      stub stays conservative.  12 asserts cover pass conditions
    ;;      c-1..c-9, c-11 per PREDICTIONS-147.md.
    ("147-runtime-promotion-happy.6th"           12)
    ;; 148. Cycle 26C — negative path: length-1 motif via WRAP-MOTIF.
    ;;      Coupling met (N=5, M=3) but reuse_gain = 0 because
    ;;      expansion length 1 saves 0 ops per use.  Energy gate
    ;;      rejects via TRY-COMMIT → 'rejected-energy.  Cand
    ;;      stays 'ephemeral-active.  Validates that the gate
    ;;      ACTUALLY gates (not just reports).  7 asserts.
    ("148-runtime-promotion-energy-fail.6th"      7)
    ;; 149. Cycle 27C — automated runtime motif discovery (happy).
    ;;      Workload produces natural top-level trace repetition;
    ;;      DETECT-MOTIF-AUTO selects via frozen mining_protocol
    ;;      ranking (freq desc, len desc, hash asc); full pipeline
    ;;      through SHADOW-CHECK + INDUCE + N=5/M=3 + COMMIT (with
    ;;      energy gate ACTIVE) + ATTEST-PRIMITIVE stub.
    ;;      10 asserts cover pre-reg c-1..c-10; c-11 (regression)
    ;;      verified by raco test.
    ("149-runtime-discovery-happy.6th"           10)
    ;; 150. Cycle 27D — negative: trace without sufficient repeats.
    ;;      Workload has no 2-gram or longer appearing >= R=3 times.
    ;;      Miner returns empty list; no cand_001 induced; ledger
    ;;      stays empty.  Validates that mining respects frequency
    ;;      threshold.  2 asserts.
    ("150-discovery-no-repeats.6th"               2)
    ;; 151. Cycle 27D — negative: single-occurrence motif (R<3).
    ;;      Even a distinctive motif that appears only 2 times is
    ;;      rejected.  Same expectations as demo 150.  2 asserts.
    ("151-discovery-single-use.6th"               2)
    ;; 152. Cycle 27D — negative: forbidden-op-laced trace.
    ;;      Workload contains 3-gram with LAW-HASH (INSPECTION-OPS);
    ;;      miner filters out forbidden-laced n-grams and returns
    ;;      only a clean alternative (length-2 MARK MARK).  Validates
    ;;      mining_protocol §4 filter.  2 asserts.
    ;;      Demos 153 (world-mismatch, needs substrate snapshot) and
    ;;      154 (energy-fail-auto, structurally impossible under
    ;;      MIN_LEN=2 frozen protocol) DEFERRED to cycle 28.
    ("152-discovery-forbidden-laced.6th"          2)
    ;; 155. Cycle 28B — held-out generalization happy path.
    ;;      Auto-discovered (MARK MARK bi-edge) candidate is run
    ;;      through full cycle 26 pipeline (COMMIT) THEN cycle 28
    ;;      held-out evaluation: wins 6/6 → PROMOTE-STABLE succeeds,
    ;;      status 'stable-active.  First non-stub stable promotion.
    ;;      5 asserts.
    ("155-stable-promotion-happy.6th"             5)
    ;; 156. Cycle 28C — train-overfit negative.  Stack-hungry motif
    ;;      (bi-edge drop) discovered + committed on train (workload
    ;;      feeds stack args).  On held-out: cand_001 underflows on
    ;;      empty stack → wins 0/6 → PROMOTE-STABLE returns
    ;;      'rejected-heldout-insufficient.  Status stays 'committed,
    ;;      not advanced to 'stable-active.  5 asserts.
    ("156-stable-promotion-train-overfit.6th"     7)
    ;; 157. Cycle 28D — second negative with different stack-hungry
    ;;      motif (EDGE+ drop).  Same outcome: wins 0/6, rejected.
    ;;      Demonstrates held-out gate is general across stack-hungry
    ;;      motif shapes.  5 asserts.
    ("157-stable-promotion-heldout-absent.6th"    7)
    ;; 158. Cycle 29C — law metabolism happy path.  Stable-active →
    ;;      stale (1 idle epoch) → demotion-candidate (2nd idle) →
    ;;      decomposed → restored.  Verifies law_hash mutates on
    ;;      decompose, world_hash unchanged, law_hash restores on
    ;;      RESTORE-PRIMITIVE.  9 asserts.
    ("158-law-metabolism-decompose.6th"           9)
    ;; 159. Cycle 29D — age-resistance negative.  5 productive
    ;;      epochs (4 uses each, momentum +5) keep status
    ;;      'stable-active.  Validates: age alone doesn't kill;
    ;;      only negative momentum does.  7 asserts.
    ("159-law-metabolism-age-resistance.6th"      7)
    ;; 160. Cycle 30A — happy AUTO-DECOMPOSE.  Stale primitive with
    ;;      no dependents is auto-decomposed by NEW-EPOCH itself
    ;;      via the dependency-aware gate.  AUTO-DECOMPOSE-SAFE?
    ;;      predicate is 0 during productive use and 1 after one
    ;;      idle epoch.  law_hash mutates on auto-decompose;
    ;;      world_hash unchanged; RESTORE returns law_hash.  8 asserts.
    ("160-auto-decompose-safe.6th"                8)
    ;; 161. Cycle 30B — dependency-held protection.  cand_002
    ;;      depends on cand_001.  When cand_001 reaches
    ;;      demotion-candidate with cand_002 still bearing positive
    ;;      momentum, cand_001 transitions to 'dependency-held
    ;;      instead of 'decomposed.  When cand_002 fades,
    ;;      cand_001 auto-decomposes next epoch.  8 asserts.
    ("161-dependency-held.6th"                    8)
    ;; 162. Cycle 30C — cascade restore.  After cand_001 is
    ;;      auto-decomposed, cand_002 dispatches fault (call into
    ;;      missing reference).  RESTORE cand_001 returns law_hash
    ;;      to pre-decompose value AND re-wires cand_002 callability.
    ;;      Cycle 30 does NOT auto-promote the dependent; cand_002
    ;;      must earn momentum back through its own productive use.  6 asserts.
    ("162-cascade-restore.6th"                    6)
    ;; 163. Cycle 31A — THE corruption-attempt demo.  Liberal-mode
    ;;      INDUCE produces 'experimental cand; COMMIT-PRIMITIVE
    ;;      rejects with 'rejected-not-conservative; PROMOTE-STABLE
    ;;      rejects with 'rejected-sandbox-cand; PROMOTE-EXPERIMENTAL
    ;;      transitions to 'sandbox-stable.  STABLE-LAW-HASH unchanged
    ;;      throughout the entire liberal episode.  9 asserts.
    ("163-liberal-stable-corruption-attempt.6th"  9)
    ;; 164. Cycle 31B — inflation forces ongoing payment.  A promoted
    ;;      primitive with no recent use sees m=-3 (L=2 + inflation=1)
    ;;      after one NEW-EPOCH and descends through 'stale →
    ;;      auto-decompose in two consecutive idle epochs.  The
    ;;      cycle 31 fingerprint is the exact m=-3 vs the cycle 30
    ;;      m=-2 for the same primitive.  7 asserts.
    ("164-inflation-no-free-immortality.6th"      7)
    ;; 165. Cycle 31C — connector: inflation + cycle 30 protection.
    ;;      Load-bearing cand_001 hits demotion-candidate faster
    ;;      under inflation, but Pass C still routes it to
    ;;      'dependency-held while cand_002 has positive momentum.
    ;;      Once cand_002 fades, auto-decompose fires.  5 asserts.
    ("165-load-bearing-survives-inflation.6th"    5)
    ;; 166. Cycle 31D — sandbox isolation under rollback.  Conservative
    ;;      cand_001 promoted; liberal cand_002 induced + rolled back.
    ;;      STABLE-LAW-HASH bit-for-bit identical across the entire
    ;;      liberal episode.  7 asserts.
    ("166-sandbox-rollback-untouched.6th"         7)
    ;; 167. Cycle 32A — multi-level cascade chain protection.  Three-
    ;;      cand chain cand_003 → cand_002 → cand_001; only cand_003
    ;;      dispatched externally.  has-recent-load-bearing? walks
    ;;      transitively through the chain to find cand_003 as positive
    ;;      anchor.  Both intermediates → 'dependency-held.  10 asserts.
    ("167-multi-level-cascade.6th"               10)
    ;; 168. Cycle 32B — negative: static dependency alone does NOT save
    ;;      a primitive.  cand_002 statically depends on cand_001 but
    ;;      neither is dispatched in the test phase.  Without runtime
    ;;      observation, has-recent-load-bearing? returns FALSE and
    ;;      both auto-decompose.  9 asserts.
    ("168-static-only-does-not-save.6th"          9)
    ;; 169. Cycle 32C — chain collapse: once the external positive
    ;;      anchor stops being driven, the multi-level protection chain
    ;;      unwinds.  Both intermediates lose runtime observation,
    ;;      load-bearing returns FALSE, Pass C auto-decomposes them.
    ;;      7 asserts.
    ("169-chain-collapse.6th"                     7)
    ;; 170. Cycle 32D — anti-immortal-cycle invariant.  Two cands
    ;;      mutually statically dependent (A→B and B→A constructed via
    ;;      gated REBIND-CAND-BODY test harness) cannot mutually
    ;;      protect each other forever.  visited-set DFS terminates
    ;;      cleanly with FALSE; both auto-decompose.  8 asserts.
    ("170-cycle-without-anchor.6th"               8)))

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
  (check-equal? total-pass 2204
                (format "cumulative ✓ count: ~a (expected 2204)" total-pass)))

(displayln (format "examples regression: ~a / 2204 ✓ across ~a demos"
                   total-pass (length expected)))
