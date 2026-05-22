# Changelog

All notable changes to Sixth between tagged releases.  Format
follows the [Keep a Changelog](https://keepachangelog.com/) style.
Pre-v0.8 changes are reconstructed from git log; v0.8 is the first
release with a maintained changelog from the next version forward.

---

## [Unreleased]

Tracks `main@HEAD` development past v0.8.  Currently:

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
