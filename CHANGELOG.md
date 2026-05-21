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
- CHANGELOG.md (this file).

### Changed
- `README.md` reproducibility section: now explicitly scopes the
  evidence as two-tier — assertion gate covers all 103 demos;
  byte-identical forensic traces cover 23 of 103.  Previously the
  framing implied "fully reproducible" without distinguishing
  evidence quality.
- `docs/TOUR.md`: attribution updated from "author's pick" to
  "curated pick assembled jointly by Mikhail Savchenko and the AI
  collaborator that helped write the demos"; honest AI co-authorship.
- `docs/TOUR.md`: tour entry 4 (cosmogenesis bootstrap) adds a
  naming-caveat paragraph clarifying that "cosmogenesis" is a
  v9.0-era codename for substrate-construction-from-one-distinction,
  not a quantitative claim about cosmology on a 13-node graph.

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
