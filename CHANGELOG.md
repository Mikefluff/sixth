# Changelog

All notable changes to Sixth between tagged releases.  Format
follows the [Keep a Changelog](https://keepachangelog.com/) style.
Pre-v0.8 changes are reconstructed from git log; v0.8 is the first
release with a maintained changelog from the next version forward.

---

## [Unreleased]

Tracks `main@HEAD` development past v0.8.  Currently:

### Added (cycle 7 — explicit retract markers + multi-observer + first valid predict-then-measure)

- **Explicit retract notices added to demos 116, 117, 118, 119**
  (box-style headers at top of each file pointing to RESULTS.md
  "CYCLE 6" section).  Demos retained as regression tests but
  research interpretations explicitly superseded.
- **Demo 122** (18 ✓) — multi-observer ensemble.  Averages
  phi-perc across all n observers per graph + multi-seed
  (M=5×K=10×n = 500 samples per p).  Confirms single-observer
  and multi-observer give means within 1σ at every p tested.
  Observer choice does not significantly bias ensemble at n=10.
- **Demo 123** (14 ✓) — **FIRST valid predict-then-measure
  cycle in catalogue**.  Theory derived analytically from
  substrate model BEFORE running: at deep supercritical p,
  ratio ⟨phi-perc⟩(n=20)/⟨phi-perc⟩(n=10) ∈ [2.0, 2.2].
  Measured 217%, intensive ratio 108%.  **CONFIRMED within
  predicted bounds.**  Substrate extensivity verified.  First
  substantive substrate-derived research finding that survives
  CS-doctor scrutiny.
- **companion-1-pythia/** scaffold directory — README, DESIGN.md
  (pre-registered encoding + metrics + predictions + falsifiers),
  requirements.txt, extract.py stub.  Long-term: F5.1 datestamp
  2027-06-30 for substrate-monism Pythia attention validation.

### Fixed (engine bug surfaced by cycle 7 stack enforcement)

- **`stdlib/phi.6th phi-perc`** had silent stack leak.  Documented
  signature `( O -- phi )` but actually `( O -- O phi )` — bfs-init
  preserves O on stack instead of consuming it.  Cycle 4-5 demos
  using phi-perc inside recursive K-loop silently accumulated
  hundreds of leftover values; demos passed because top-of-stack
  asserts ignored the leak.  Demo 122 (multi-observer) calls
  phi-perc inside EACH (which has stack-balance enforcement from
  cycle 1 S2), surfacing the leak immediately.  Fixed with
  explicit `drop` after bfs-init.  Demos 111/121 still pass.
  **Cycle-1 stack-balance enforcement (S2) retroactively earned
  its keep by finding stdlib bug.**

### Added (cycle 6 — statistical infrastructure + honest retract)

CS-doctor #3 retrospective on cycles 4-5 (in RESULTS.md): single-
seed K=4-8 "ensembles" are deterministic LCG traces, not
statistically defensible measurements.  No error bars, no multi-
seed validation.  "Substrate-derived findings" of 117/119 were
author tracing errors of documented engine set-semantics.

- **stdlib/stats.6th** (new) — basic statistical primitives.
  isqrt via binary search.  Streaming aggregator with mean,
  variance ((n·sumsq - sum²)/n²), stddev (isqrt of variance),
  sample count.  Memory cells: stat-sum, stat-sumsq, stat-n.
  Required for honest ensemble measurements.
- **Demo 120** (24 ✓) — stats stdlib verification.  isqrt
  on 12 cases; streaming aggregator on canonical samples
  ({2,4,6,8,10} → mean=6/var=8/stddev=2; constant 42 → var=0;
  1..10 → mean=5/var=8/stddev=2).
- **Demo 121** (18 ✓) — **FIRST statistically-defensible
  substrate measurement in catalogue**.  Multi-seed ensemble
  percolation: M=10 seeds × K=20 samples per (seed, p) =
  200 samples per data point.  Reports mean ± stddev per p.

  **RETRACTS demo 116's sharp phase transition claim.**  Real
  ensemble curve at n=10 is smooth monotonic (16600 → 28950 →
  46250 → 64050 → 88700, max single-step jump 17300), not
  sharp.  Stddev peaks in transition region (sd15=30190,
  sd20=32358) — broad smearing, not criticality.  Demo 116's
  apparent "jump 41250 → 82500" was seed-42 artifact.

  Substrate-monism revised prediction: at n=10, phi-perc does
  NOT exhibit classical Erdős-Rényi sharp transition.  Finite-
  size smearing dominates completely.  Real critical-behaviour
  validation requires n ≥ 50 (compute challenge).

### Changed (RESULTS.md retracts and re-classifications)
- **Demo 116 sharp-transition claim RETRACTED** (per demo 121).
- **Demo 118 scaling exponent claim DOWNGRADED** to "preliminary
  single-seed observation pending multi-seed validation" (2 data
  points cannot fit exponent; K=4 too small).
- **Demos 117/119 surprises RECLASSIFIED** from "substrate-derived
  findings" to "documentation-completeness gaps in engine docs".
  Both follow from careful counting through documented set-
  semantics; author tracing errors, not substrate research.
- **RESULTS.md aggregate** now states honestly: "0 statistically-
  defensible substrate-derived findings to date; engineering
  infrastructure complete enough to attempt real measurements at
  scale (deferred: K ≥ 100, n ≥ 50)".
- This is the **first cycle in the catalogue that retracts prior
  overclaims with honest error bars**.  Catalogue is now an
  honest research artifact about what works (engine, tests,
  stdlib) and what has been retracted.

### Added (research-track demos — fifth cycle, real measurements + 2nd substrate surprise)
- **Demo 118** (24 ✓) — ensemble p_c scaling across n ∈ {10, 20}.
  Empirical measurement (not analytic shortcut of demo 114).
  Substrate-derived p_c(10)=15%, p_c(20)=10%, ratio 0.66 vs
  classical 0.50.  Same scaling direction, factor 1.3 deviation.
  Notable secondary finding: **n=20 transition SHARPENS** vs n=10
  (jump 22,500 → 127,500 in single p-grid step at n=20), matching
  classical finite-size scaling signature.
- **Demo 119** (6 ✓) — K=3 rule-space enumeration (27 variants).
  **SECOND SUBSTRATE-DERIVED SURPRISE in cycle 5**: all 6 K_eff=3
  rules give 15 edges, not naive 16.  Second-order substrate
  degeneracy: K_eff=3 rules include «c» as source position,
  creating (c,c) self-loop on iter 1; iter 2 applies rule to that
  self-loop (a=b), generating two duplicate (s_i, c-new) edges
  that substrate set-semantics deduplicates.  **K_eff =
  #unique-sources is first-order only**; K=3 surfaces second-order
  correction K=2 missed.  Second demo in catalogue where author's
  prior prediction was wrong and substrate corrected it.

### Added (research-track demos — fourth cycle, infrastructure + first non-engineered findings)

CS-doctor #2 retrospective: cycles 1-3 produced 10 demos with
near-zero non-tautological substrate findings (mostly author-
verified formulas and engineered constructions).  Root cause:
no RNG, no ensemble, no enumeration — every "experiment" was
deterministic with author-known answer.  Cycle 4 attacks the
infrastructure gap.

- **stdlib/rand.6th** (new) — LCG-based RNG via memory cell
  `rng-state`.  Words: `srand`, `rand`, `rand-bit`.  Substrate
  primitive count UNCHANGED (48) — pure stdlib addition.
  Unlocks ensemble experiments without engine modification.
- **Demo 115** (7 ✓) — stdlib RNG verification.  Reproducibility
  (same seed → same sequence), range correctness, seed
  independence, distribution sanity (100-sample mean ≈ 54 ≈
  expected 50; 200-bit fraction 100/200 ≈ expected).
- **Demo 116** (15 ✓) — **FIRST non-engineered ensemble experiment**.
  Random Erdős-Rényi G(n=10, p) with K=8 samples per p, sweep
  p ∈ {5, 10, 15, 20, 25, 30, 35, 40, 50}%.  Substrate-derived
  empirical curve (seed=42 pinned for reproducibility):
  ⟨phi-perc⟩ jumps from 41,250 at p=15% to 82,500 at p=20%,
  identifying empirical p_c ≈ 15-20%.  Classical Erdős-Rényi
  p_c = 1/n = 10%; substrate measurement within factor 1.5-2
  due to finite-size + K=8 noise.  All 9 means pinned.  The
  jump location was NOT predicted in advance.
- **Demo 117** (11 ✓) — **REAL substrate-derived SURPRISE finding**.
  Enumerated all 9 K=2 rules of form (a,b) → MARK c, add
  (s1,c), (s2,c).  Result: 3/9 rules (s1=s2 = duplicate sources)
  collapse to K_eff=1 due to substrate set-semantics on
  hyperedges — produce 4 edges at k=2 instead of naive 9.  The
  (1+K) law of demo 109 holds only on the non-degenerate
  subspace.  Rule-space topology is bimodal (growth=4 or
  growth=9), not single-class.  Author predicted all 9 = 9;
  substrate refuted.  **First demo in catalogue where author's
  prior prediction was wrong and substrate corrected it.**

### Added (research-track demos — third cycle, code-focused)
- **Demo 112** (36 ✓) — phi-perc read-only contract via snap/
  restore wrapper.  Uses negative-int memory keys to namespace
  the BFS snapshot away from engine-reserved underscore-prefixed
  and user string/symbol keys.  Eliminates the cycle-2 NGET-
  mutation caveat; phi-perc now functionally pure.  Verified
  across 6-node and 10-node substrates with distinct features,
  interleaved phi-perc/phi-pa calls, idempotent re-calling.
- **Demo 113** (19 ✓) — Track 4.1 Φ-family combination laws for
  nested observers.  **POSITIVE THEORETICAL FINDING**:
  - phi-pa(M) = (K+1)·L_max — structurally INDEPENDENT of
    children's Φ_PA values (verified across 10× scope range,
    20000 to 200000)
  - phi-perc(M) ~ Σ comp-size(O_i) — connectivity-INHERITED
  Rejects additive and maximal panpsychism for phi-pa; supports
  connectivity-aggregation panpsychism for phi-perc.  Substrate-
  derived dual-law: combination problem is MEASURE-DEPENDENT,
  not absolute.  Real contribution to philosophy-of-mind
  combination problem.
- **Demo 114** (16 ✓) — Track 2.2c percolation critical-exponent
  scaling.  Measure phase transition across n ∈ {10, 20, 30}:
  jump-size = (n-2)·L_max linear in n; pre-bridge edge count
  = 2(n-2)+3 linear in n; critical edge-fraction = 2/(n-1) →
  2/n.  **Substrate-derived scaling exponent: -1**, same
  universality class as classical Erdős-Rényi p_c = 1/n within
  factor 2.  First quantitative substrate-derived critical
  exponent in catalogue.

### Changed (stdlib)
- **`stdlib/phi.6th`**: phi-perc upgraded to read-only via
  snap/restore wrapper.  No more NGET-mutation caveat.

### Added (research-track demos — second cycle, code-focused)
- **Demo 108** (24 ✓) — Track 2.1b phi-integ density sweep.
  **PARTIAL POSITIVE**: two-regime piecewise-linear response
  (observer-saturation + neighbour-saturation), smooth crossover
  at observer's full-scope point.  Still no critical exponent, but
  richer than phi-pa.  Completes Track 2.1 result map across
  Φ_PA-family.
- **Demo 109** (23 ✓) — Track 2.3b Wolfram-style rewrite
  universality.  **POSITIVE**: substrate-derived growth law
  E_k = E_0 · (1+K)^k verified across 4 rules with K ∈ {1, 2, 3}
  and across multiple initial conditions.  Substrate identifies
  K-equivalence classes of rewrite rules.
- **Demo 110** (22 ✓) — Track 2.2 substrate-readable percolation
  order parameter.  **POSITIVE (major)**: largest-component-size
  containing observer (BFS-based) exhibits classical percolation
  phase transition — observer's component-size jumps from 2 → 10
  on single bridging edge.  Reversible under EDGE-.  FIRST
  substrate-readable measure in catalogue with genuine critical
  behaviour.
- **Demo 111** (9 ✓) — phi-perc stdlib member verification.
  Materialises demo 110 finding.  Comparison: phi-pa UNCHANGED
  across non-incident bridge edge, phi-perc JUMPS — orthogonal
  discriminating signal.
- **`stdlib/phi.6th`**: new `phi-perc(O) = comp-size(O) · self-ref
  · L_max` member, the fifth Φ-family measure and the only one
  with phase-transition behaviour.  Caveat: mutates NGET during
  BFS (callers must restore feature state if NGET load-bearing).

### Added (research-track demos — first cycle)
- **RESULTS.md** — new top-level document tracking ongoing research-
  track outputs.  Each entry: hypothesis → method → outcome →
  consequence.  Both positive and negative results catalogued — null
  results are research output.
- **Demo 105** (21 ✓) — Track 1.3 HEDGE3 expressivity benchmark.
  **NEGATIVE RESULT**: no complexity-class separation between HEDGE3-
  native and binary-encoded triadic queries.  Both O(N).  Falsifies
  «substrate-level realisation of Peirce's reduction thesis» as
  expressivity claim.  Downgrade to «ergonomic surface for triadic
  patterns» recommended in SUBSTRATE.md / README.md / preprint.
- **Demo 106** (25 ✓) — Track 2.1 Φ_PA family parametric sweep.
  **NEGATIVE RESULT**: phi-pa is exactly linear in scope across
  k=0..9 sweep; first-difference is constant L_max=10000 with zero
  variance.  Self-ref switch is binary STEP, not phase transition.
  Substrate-derived BOUND on current Φ_PA expressive power —
  Tononi-IIT-style Φ-criticality (Mediano 2019) NOT replicated.
  Future measures requiring phase-transition signatures must
  introduce genuine nonlinearity (MI, KL-divergence, percolation
  order parameters).
- **Demo 107** (18 ✓) — Track 2.3 open-ended Wolfram-style rewrite.
  **POSITIVE RESULT**: substrate-derived growth law `edges_k = 3^k`
  verified at k=1..4 with growth-ratio UNIVERSALITY (invariant under
  initial-condition perturbation).  First honest cosmogenesis
  demonstration in the catalogue — no halting predicate, no
  target-min, no author tuning of output topology.  Counter to the
  «Pilot D cosmogenesis is hand-coded» critique.

### Added
- `HEDGE3-VALID?` substrate primitive: predicate-only structural
  validation, no insertion, no exception.  Lets demos test kind
  invariants without triggering the insert-time exn:fail:sixth:substrate.
- Per-kind structural invariants enforced at `HEDGE3+` insertion:
  WITNESS requires `w ≠ src ∧ w ≠ dst`; MEDIATOR requires
  `mid ≠ src ∧ mid ≠ dst`; SIMPLEX requires all three distinct;
  CONTEXT rejects only the fully-degenerate `a == b == c` case.
- Demo 103 (27 ✓): cycles through each kind's invariant via
  HEDGE3-VALID?; verifies VALID and INVALID cases.
- **Node-id validation on mutators** (`substrate-core.rkt`
  `validate-node!`): `EDGE+`, `HEDGE3+` now raise
  `exn:fail:sixth:substrate` when any positional id is not in
  `[1, next-id]`.  Previously phantom-id edges (`999 1000 EDGE+`)
  were silently accepted, creating latent inconsistency between
  `EACH` (which iterates 1..node-count and skips phantoms) and
  `EACH-EDGE`/`EACH-HEDGE3` (which snapshot the hash and visit
  phantoms).  Read primitives (`NGET`, `OUT`, `IN`, `NEXT`,
  `PREV`, `BORN`, `EDGE-`, `HEDGE3-`) remain lax — they return
  sentinel defaults / no-op on phantom ids by design (so
  defensive cleanup code doesn't have to pre-check).  The
  asymmetry is documented inline at the `validate-node!`
  definition.
- **Stack-balance enforcement in iteration primitives** (6
  primitives in `sixth/primitives/substrate.rkt`): `EACH`,
  `EACH-EDGE`, `EACH-2PATH`, `EACH-HEDGE3`, `EACH-HEDGE3-KIND`
  now snapshot stack depth before pushing the rule's arguments
  and assert net delta 0 after the rule returns; `STEP-CA`
  asserts net delta +1 (rule must produce one result for
  collection).  Surface contract: each rule signature documents
  what it consumes and produces; a mis-balanced rule now raises
  immediately at the iteration site with the rule name +
  observed-vs-expected depth, instead of corrupting the stack
  several iterations later.  See `assert-stack-delta!`.
- **Inline design-asymmetry note** at `substrate-core.rkt` HEDGE3
  block (line ~135): explains why binary edges accept all four
  "degenerate" configurations (self-loops are semantically
  load-bearing for own-Φ_PA) while three of four HEDGE3 kinds
  enforce Peirce-style strict distinctness.  Was an implicit
  inconsistency; now documented design choice.
- 23 new `tests/substrate-test.rkt` / `tests/vm-test.rkt` cases:
  node-id validation (EDGE+/HEDGE3+ phantom raises, self-loop
  legitimate, EDGE- on phantom lax); stack-balance enforcement
  (EACH/EACH-EDGE/EACH-2PATH/EACH-HEDGE3/STEP-CA all raise on
  wrong delta); STEP-CA atomicity (two new cases on mutual
  cycle 1↔2 prove rule reads PRE-step neighbour values — the
  substrate invariant that prevents serial-bias artefacts in
  Conway/Rule-90/etc.); ASSERT type matrix (`0.0` boxed-float
  zero fails, negative ints pass per Forth convention, strings
  fail); HEDGE3-KIND counter consistency across insert/remove/
  insert cycles; self-loop NSUM semantics (own-feature included);
  EACH-2PATH self-cycle visits (mutual 1↔2 yields two 2-paths);
  REPORT output contract (always emits hedges= column); VM TCO
  through if-branch (100 000-deep recursion completes); STEP-CA
  on empty substrate / EACH-HEDGE3 on no hedges / HEDGES3-KIND
  on never-used kind (boundary no-ops); NEXT returns most-
  recently-added out-edge (pins implicit ordering); tick with
  numeric arg raises type-error; STEP-CA rule side-effects
  (HEDGE3+) are immediate, not batched with NSET (pins contract);
  mixed INT/FLOAT equality + symbol equal?-fallback.
- CHANGELOG.md (this file).

### Changed
- **Primitive-count doc/code divergence fixed**: documentation
  consistently said "40 primitives" while `sixth/primitives/*.rkt`
  exposes 48 (17 base + 23 substrate-core + 8 HEDGE3 trivalent).
  Updated CLAIMS.md Tier-1 statement #1 (which was mechanically
  refutable by `grep -E "^\s*\(cons '" sixth/primitives/*.rkt`),
  README.md (×6 mentions including layout block), SUBSTRATE.md
  Layer 0/1/2 catalog (Layer 0 header was "(15)" but body listed
  17 items; Layer 2 HEDGE3 was missing entirely), docs/TOUR.md,
  examples/README.md.  CLAIMS.md Tier-1 statement #1 now carries
  the exact grep command for reviewer fact-check.
- **CLAIMS.md demo enumeration extended to 104**: previously
  enumeration in Tier-1 statement #2 stopped at the stress-test
  track (79–81) and ended mid-sentence, while the count "98
  demonstrations pass" was correct.  Now enumerates nine tracks
  through demo 104 (HEDGE3) and notes the intentional cuts at
  95–97, 99, 101–102.
- `README.md` reproducibility section: now explicitly scopes the
  evidence as two-tier — assertion gate covers all 98 demos;
  byte-identical forensic traces cover 23 of 98 (trace block
  55–78 + long-epoch growth 54).  Previously implied "fully
  reproducible" without distinguishing evidence quality.
- `README.md` repository-layout block: replaced stale demo-index
  prose (which referenced non-existent "00 hello" / 21–63
  numbering from a pre-reorg era) with current nine-track summary.
- `tests/examples-test.rkt` header comment: "74 demos" → "98
  demos" with full nine-track breakdown and gap-note.
- `scripts/verify.sh` header sample output: "1180 / 1180 ✓ across
  86 demos" → "1469 / 1469 ✓ across 98 demos".
- `docs/TOUR.md`: attribution updated from "author's pick" to
  "curated pick assembled jointly by Mikhail Savchenko and the AI
  collaborator that helped write the demos"; honest AI co-authorship.
- `docs/TOUR.md`: tour entry 4 (cosmogenesis bootstrap) adds a
  naming-caveat paragraph clarifying that "cosmogenesis" is a
  v9.0-era codename for substrate-construction-from-one-distinction,
  not a quantitative claim about cosmology on a 13-node graph.
- Demo 104 (emergent causal time) prose lowered: framing was
  "Substrate-monism extends from STATE to TIME / Wolfram-aligned
  causal invariance"; now honestly describes the algorithm as
  Bellman-Ford-style longest-path relaxation on a DAG, with
  DAG-ness flagged as a precondition (cycles would diverge).
  The substantive claim — substrate carries enough structure
  (MEDIATOR + NGET + EACH-MEDIATOR) to compute longest-path
  without host help — remains intact.
- `stdlib/phi.6th`: `phi-pa-witness` retained because the PA v9.0
  preprint references it as a fourth candidate measure, but its
  block comment now flags Tier-3 status and notes the cut of
  demo 102 (its only consumer) without replacement coverage.

### Removed
- Demo 104 cleanup: removed dead first definition of
  `propagate-time` plus the theatrical `exit-when-rule-src` /
  `exit-when-rule-dst` placeholder words that documented an
  earlier (rejected) early-return attempt.  Single clean
  definition with a comment explaining the nested-IF guard.

### Fixed (engine — mixed INT/FLOAT equality)
- `prim-=` now uses numeric `=` when both operands are numbers,
  falling back to `equal?` only for non-numeric cases (symbols,
  strings, nodes).  Previously `1 1.0 =` returned 0 because
  `(equal? 1 1.0)` is `#f` in Racket — surprising for any FFI/
  torch-bridge result that produces a flonum, and inconsistent
  with the just-fixed shared `zero-ish?` semantics in `ASSERT`
  and VM JZ.  Symbol-equality (`' foo ' foo =`) regression-pinned
  in a new vm-test case.

### Fixed (engine — VM TCO defect + REPORT output contract)
- **VM tail-call detection now sees through JMP-to-RET** (`vm.rkt`
  `tail-call?`).  Previously only the exact pattern `CALL ... RET`
  was TCO'd; the more common pattern `CALL ... JMP target ...
  target: RET` (a tail call inside an `if/then/else` branch, where
  the compiler emits a JMP over the alternative branch to the
  trailing RET) silently fell through to non-TCO and grew the
  rstack linearly in recursion depth.  Every recursive Sixth word
  whose recursion lives inside an `if`-branch — `peano-add`,
  `peano-mul`, `countdown`, anything matching `if ... rec then` —
  was affected; the manual claim "recursive Sixth words run
  arbitrarily deep" was effectively false.  Now passes a 100 000-
  deep `countdown` test (was previously bounded by host stack
  size, typically ≤10⁴–10⁵).
- `substrate-report` now always emits the `hedges=N` column, even
  when zero.  Previously the column collapsed when no HEDGE3s
  existed, so the REPORT line shape silently changed the day a
  demo started using HEDGE3 — breaking any grep-based external
  parser.  Stable output contract.

### Fixed (engine + hidden demo bug surfaced by new enforcement)
- `substrate-assert!` now uses the shared `zero-ish?` predicate
  from `sixth/values.rkt` (previously copy-pasted with subtly
  different boxed-flonum handling: `(eq? v 0.0)` is
  implementation-dependent for `(- 1.0 1.0)`).  `vm.rkt` JZ
  branching and `ASSERT` pass/fail now agree on falsy-ness for
  all numeric value types, including FFI/torch-bridge results.
- **Demo 33 (`observer-collapse`) hidden stack-leak**: the
  STEP-CA rule `rule-grow` was `dup NGET 1 +` — the `dup`
  meant the rule left BOTH the next-state value AND the
  original node id on the stack.  STEP-CA was popping only the
  top (correct next-state) and silently leaking node ids per
  iteration; subsequent code happened to not notice.  Surfaced
  immediately by the new stack-delta enforcement; fixed to
  `NGET 1 +`.  Regression unchanged at 1469 ✓.

### Fixed
- CI `raco pkg install` regression: `.` is no longer accepted as a
  package source by current raco ("ending path element is not a
  name").  Workflow now passes `--name sixth $GITHUB_WORKSPACE`
  explicitly.  CI had been failing on every push since the
  v9.0-era setup-racket version drift.
- CI actions bumped to Node.js 24-compatible versions:
  `actions/checkout` v4 → v5, `Bogdanp/setup-racket` v1.11 → v1.15,
  `actions/setup-python` v5 → v6.  Clears the GitHub-side
  deprecation warning.

---

## [v0.8] — 2026-05-21

First annotated release.  Defendable artifact state for citations
in the Pointer Architecture v9.0 preprint and the companion
efficiency-of-simulation preprint.

### Added

- **HEDGE3 typed trivalent hyperedge primitive family.** 7 new
  substrate primitives (`HEDGE3+ / HEDGE3- / HEDGE3? / HEDGES3 /
  HEDGES3-KIND / EACH-HEDGE3 / EACH-HEDGE3-KIND`) coexisting with
  binary edges.  Storage as 4-tuples `(kind, a, b, c)` with strict
  type discipline by `kind` enum.
- **`stdlib/hedge.6th`** with four canonical kinds:
  - `WITNESS=0`  `(src, dst, witness)`  ground of validity
  - `MEDIATOR=1` `(src, mid, dst)`      topological channel
  - `CONTEXT=2`  `(in, ctx, out)`       rewrite-rule firing
  - `SIMPLEX=3`  `(a, b, c)`            undirected triadic form
  - per-kind constructors/queries/iterators
- **`stdlib/phi.6th` fourth candidate measure** `phi-pa-witness`:
  Φ_PA^W(O) = (OUT(O) + W(O)) · 1[O EDGE? O] · L_max where W(O)
  counts WITNESS hyperedges with O as third leg.  Reduces to Φ_PA
  when W(O) = 0 (backward compat).
- **Honest-emergence track** (demos 85-92): substrate composites
  EMERGE from rule applications on minimal initial state, instead
  of being hand-placed.  Corrects the "static-composites"
  framing of Pilots G/H/I/L/M/K.
- **Long-epoch parametric pilots** (demos 53-54): TCO-safe runs
  of arbitrary cycle count.
- **Visual-trace track** (demos 55-74): DOT-snapshot companions
  for every numerical pilot.
- **Pilots G-M composite/particle pilots** (demos 48-52, 75-78):
  composite distinction via meta-self-loop, mutation+selection,
  multi-level hierarchy, charge conservation, spontaneous
  coalition assembly, particle interaction (binding), bound-state
  decay.
- **Stress-test track** (demos 79-84): parametric long-run versions
  of every dynamic pilot, max-drift assertion at every cycle,
  scales to 10⁶ cycles via `-D max-cycles=N`.
- **Peircean trit observer classifier** (demo 90): substrate
  classifier tagging every node into balanced trit {−1, 0, +1}
  corresponding to Peirce's firstness/secondness/thirdness.
- **HEDGE3 in-depth demos** (93-98): each canonical kind exercised
  as a primary use case, plus a wobble-at-position-3 demo
  showcasing DNA-codon-style 4× compression.
- **Substantive HEDGE3 applications** (99-102):
  - 99: substrate-self-modification via CONTEXT history (rule
    reads its own past firings, saturates)
  - 100: MEDIATOR as Wolfram-style causal hypergraph (forward
    cone, backward antecedents, per-rule firing counts)
  - 101: WITNESS belief revision + meta-arbitration
  - 102: Φ_PA^W rank divergence vs Φ_PA
- **`docs/TOUR.md`**: curated 10-demo reading path for new
  readers (~40 min end-to-end), with explicit "Why these 10 and
  not the other 92" inventory.

### Changed

- Demo numbering: full re-numbering applied to put demos in
  conceptual order (Spencer-Brown ladder 01-11 at the bottom,
  HEDGE3 extensions at the top).  Filenames are stable from v0.8
  forward.
- Cumulative test gate: 1180 ✓ (40 v9.0-era demos) → 1535 ✓
  (102 demos at v0.8 tag), then 1562 ✓ (103 demos with
  strict-validation addition in `[Unreleased]`).

### Companion-preprint anchoring (in `/Users/mikefluff/Documents/godacademy/`)

- PA preprint pass 21: Filioque controversy paragraph in
  `sec:related-hard-problem` anchors substrate's first-class
  triadic structure on Peirce's reduction thesis.
- PA preprint pass 22: HEDGE3 paragraph in
  `sec:38-primitives`; Filioque paragraph cites concrete HEDGE3
  demos (93-96).
- PA preprint pass 23: Φ_PA^W as fourth candidate measure in
  `sec:phi-pa-alternatives`.
- efficiency-of-simulation preprint: HEDGE3 wobble compression as
  empirical motif-dictionary evidence (4× compression matches
  Crick 1966 wobble degeneracy).

### Backward compatibility

The 38-primitive bootstrap claim for the original 40-demo ascent
is preserved.  HEDGE3 is an OPTIONAL substrate extension required
only by demos 93-103.  Existing demos that do not `use hedge` see
no behavioural change.  Existing reproducibility evidence (23
forensic JSONL traces of v9.0-era demos) continues to byte-match.

---

## Pre-v0.8 history

Reconstruct from git log if needed.  The artifact existed before
v0.8 as `main@HEAD` releases without semantic version tags; the
40-demonstration v9.0 ascent (commits ~deadbeef0–360a872) is the
historical baseline for citations.
