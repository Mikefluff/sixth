# META-SEMANTICS — Runtime Primitive Induction Protocol

**Status:** Cycle 24 deliverable. Specification document. NO code, NO test.

**Date:** 2026-05-23

**Provenance:** Authored in response to user spec 2026-05-23 after
loss-family arc closed in C19–C23A (4 substrate-derived negatives on
NSUM benchmark).  Establishes the protocol BEFORE any primitive
induction code is written, so the rules of the game are fixed
independent of any specific candidate primitive.

This document is normative: future cycles 25+ MUST conform to it.
Modifications to this protocol require explicit deprecation cycle
and re-attestation; quiet changes are protocol violations.

---

## 1. Core Thesis

> Sixth primitives are not eternal axioms. They are promoted,
> attested, rollbackable operational compressions of repeated
> successful patterns.

The fixed-primitive substrate of C19–C23A was insufficient because
*any* loss function on degree-biased NSUM dynamics is dominated by
degree.  This document defines the architectural alternative:
**substrate that evolves its own alphabet** under a formal,
falsifiable protocol.

The protocol's purpose is not to *make* Sixth pass benchmarks.  Its
purpose is to make the question "does primitive induction beat fixed
primitives" *answerable* without human curation cheating.

---

## 2. Two-Level Primitive System

Critical architectural distinction.  Mixing levels destroys
protocol meaning.

### Object-level primitives
Operate on substrate state (hypergraph nodes/edges/hedges, marks,
activations).

- Examples: `MARK`, `EDGE+`, `bi-edge`, `NSUM-UPDATE`, `STEP-CA`
- Effect: change world-state
- Invariants: bounded by hypergraph axioms; deterministic given seed
- Promotion authority: subject to discovery protocol (§4)

### Meta-level primitives
Operate on engine state (active dictionary, ledger, version, costs).

- Examples: `PROMOTE`, `ATTEST-PRIMITIVE`, `ROLLBACK`, `HELD-OUT-EVAL`
- Effect: change law-state (what object-level operations exist)
- Invariants: append-only ledger; immutable provenance; explicit
  versioning
- Promotion authority: **meta-primitives themselves are NOT subject
  to discovery protocol.**  They are hand-crafted, attested at
  cycle 25, and never auto-induced.  Self-modifying-meta would
  collapse the protocol.

**Aphorism:** `MARK` changes the world.  `PROMOTE` changes the laws
by which the world can be changed.  Without that distinction there
is no protocol, only drift.

---

## 3. Lifecycle Protocol

Every candidate primitive passes through this state machine in order.
Skipping a state OR re-entering a previous state after the fact OR
mutating candidate after held-out exposure are all **contamination
events** (§9).

```
                         (ROLLBACK)
                              ↑
                              │
DISCOVER → SPECIFY → FREEZE → TRAIN-EVAL → HELD-OUT-EVAL → PROMOTE
                                                              ↓
                                                         RETEST → ATTEST
```

### DISCOVER
Mining algorithm scans logged successful trajectories on **train
substrates only**.  Algorithm is a separate module with its own
hash; its only inputs are train data and the FROZEN mining
hyperparameters.  Held-out and challenge sets MUST NOT be loaded by
the discovery module.

Output: ordered list of `cand_NNN` candidates with provenance:
- pattern (subgraph / operation sequence)
- support_count (frequency in train trajectories)
- train_score (training-set gain proxy)
- discovery_seed

**Blind naming:** candidates are named `cand_001`, `cand_002`, ….
Pretty names (`GROUP-BY-DEGREE`, `MOTIF-FOLD`) are assigned ONLY
after final promotion decision.  This blunts cherry-pick at the
interpretation level.

### SPECIFY
For each candidate, write a machine-readable record:

- `name`: cand_NNN (no pretty name yet)
- `expansion`: macro body in BOOTSTRAP primitives only (§5)
- `preconditions`: stack/state shape required for application
- `postconditions`: stack/state shape produced
- `cost_model`: expected operation count per invocation (closed-form
  or empirical bound)
- `discovery_provenance`: train_set_hash, mining_algo_hash,
  discovery_seed, support_count, train_score

### FREEZE
Compute `candidate_hash = sha256(name || expansion || preconditions ||
postconditions || cost_model || discovery_provenance)`.

Append `(cycle, timestamp, candidate_hash, status=frozen)` to
`attestations/primitives-ledger.txt`.

After freeze, candidate source code is read-only.  Any modification
voids candidate; modified version requires new `cand_NNN+1` id
AND new held-out rotation (the original held-out is now
contaminated for the modified candidate).

### TRAIN-EVAL
Evaluate candidate on train substrates via standard benchmark
(PredError vs degree baseline).  Result is informational only —
train evaluation is for sanity, not promotion authority.

If candidate fails train (PredError improvement < 1% mean on train),
mark `status=train_failed`, skip held-out.

### HELD-OUT-EVAL
Evaluate candidate on **held-out substrates** via separate command
(`scripts/heldout_eval.sh cand_NNN`).

Output: per-substrate (PredError_with, PredError_without, runtime).

**Iron rule:** result of held-out eval is APPEND-ONLY.  Once
evaluated, the candidate's held-out score is fixed for its lifetime.
Any attempt to re-run on same candidate is logged as duplicate
evaluation; only first counts.

### PROMOTE
Apply promotion gate (§7).  Three outcomes:
- `promoted_stable` — passes stable gate
- `promoted_experimental` — passes experimental gate only
- `rejected` — fails both gates

`PROMOTE` is a meta-primitive that updates the active dictionary:

```
PROMOTE cand_NNN status
  → adds cand_NNN's expansion as a callable word in active dictionary
  → records (cand_NNN, status, ledger_row, timestamp)
  → ON FAILURE: dictionary unchanged
```

### RETEST
After promotion, full regression suite (`raco test`) MUST pass
unchanged.  If regression breaks, automatic `ROLLBACK` of this
candidate and ALL candidates in same promotion batch.

Pre-promotion regression count: stored as `pre_promote_pass_count`.
Post-promotion regression count: must equal `pre_promote_pass_count`.

### ATTEST
Append final entry to ledger:
```
(cycle, timestamp, candidate_hash, expansion_hash, train_set_hash,
 heldout_set_hash, metric_hash, threshold_hash, result_hash,
 engine_version, decision)
```

This entry is permanent.  Even if candidate is later rolled back,
the attestation row remains as historical record of what was tested
and decided.

### ROLLBACK
Removes candidate from active dictionary.  Triggered by:
- Failed retest after PROMOTE
- Manual cycle (deprecation)
- Cascade from dependency rollback (§8)

Rollback appends `(cycle, timestamp, candidate_hash, status=rolled_back,
reason)` to ledger.  Provenance of why rollback happened is permanent.

---

## 4. Bootstrap Boundary

Three tiers.  Membership in each tier is established at cycle 25 and
modifying tier membership requires explicit deprecation cycle.

### Bootstrap (object-level)
Cannot be removed, cannot be redefined, never enter promotion protocol.
- Stack ops: `dup`, `drop`, `swap`, `over`, `rot`, `-rot`, `nip`, `tuck`
- Arithmetic: `+`, `-`, `*`, `/`, `mod`, `=`, `<`, `>`
- Memory: `store`, `load`
- I/O: `.`, `cr`, `emit`
- Control: `:`, `;`, `if`, `else`, `then`, `'` (quote)
- Substrate axioms: `MARK`, `EDGE+`, `HEDGE+`, `bi-edge`, `MARK-COUNT`,
  `EDGE-COUNT`, `HEDGE-COUNT`, `STEP-CA`, `RESET`, `REPORT`,
  `EACH`, `EACH-EDGE`, `EACH-2PATH`, `MATCH`

### Bootstrap (meta-level)
Added at cycle 25.  Cannot be removed, cannot be redefined.  Cannot
themselves enter promotion protocol (self-modifying-meta = collapse).
- `PROMOTE`, `ATTEST-PRIMITIVE`, `ROLLBACK`, `HELD-OUT-EVAL`,
  `DICTIONARY-SNAPSHOT`, `LEDGER-APPEND`

### Fixed stdlib
Currently in `stdlib/*.6th`.  Hand-written, version-controlled,
counts as bootstrap for the purpose of macro expansion (candidate
primitives may invoke stdlib words).

### Promoted words
Output of induction protocol.  Stored in `stdlib/promoted/<cycle>/
cand_NNN.6th` with full provenance comment.  Removable via rollback.

**Constraint:** promoted words MUST be macro-expansible to bootstrap
(object + meta) + fixed stdlib.  No new Racket-level opcode.  No
new hidden evaluator behavior.  No side-effect outside `store`/`load`
or substrate axioms.  No internal metric not exposable via
expansion.

This is the **expressivity bound**: induction is reorganization of
existing computational power, not extension of it.  A later
optimization phase may compile a stable promoted word to native
opcode for performance, but only as compilation, not as scientific
recognition of new capability.

---

## 5. Engine Classes

| class | dictionary | publishable | use |
|-------|------------|-------------|-----|
| **E0** | bootstrap + fixed stdlib | yes | baseline; all C19–C23A used this |
| **E1** | E0 + ≥1 attested primitive | yes | post-cycle-26 minimum |
| **E2** | E0 + batch of attested primitives | yes | post-cycle-27 target |
| **E_bad** | any dictionary with non-attested or contaminated primitives | **NO** | development-only; results not for catalogue |

Any benchmark result must report the engine class that produced it.
Result from E_bad cannot be cited as evidence in catalogue updates
or papers.

---

## 6. Substrate Set Policy

12 substrates total (6 train + 6 held-out) plus 4 challenge
substrates.  Generated at cycle 25 via deterministic seeded
generators; substrate hash committed before any candidate enters
DISCOVER.

### Train (6)
- `train_ER_n10_p30` — seed 100
- `train_ER_n20_p15` — seed 101
- `train_path_n10` — deterministic
- `train_cycle_n10` — deterministic
- `train_motif_triads` — n=12, triadic motif planted, seed 102
- `train_hidden_family_n18` — SBM 3-community, degree-matched,
  seed 103

### Held-out (6)
Same family as train, different graphs.  Seeds disjoint from train.
- `heldout_ER_n10_p30` — seed 200
- `heldout_ER_n20_p15` — seed 201
- `heldout_path_n12`
- `heldout_cycle_n12`
- `heldout_motif_wedges` — n=12, wedge motif planted, seed 202
- `heldout_hidden_family_n24` — SBM 4-community, seed 203

### Challenge (4)
Reserved for promotion-time invariance check.  NOT used for
training, NOT used for held-out eval.  Used ONCE at promotion
decision per candidate to filter out exploits.
- `challenge_degree_trap` — substrate where degree-based grouping
  catastrophically fails (planted hidden community with
  uniform degree)
- `challenge_mega_group_trap` — substrate where merging into single
  group looks attractive on prediction but breaks structural metrics
- `challenge_motif_vs_degree_conflict` — substrate where motif
  grouping and degree grouping give opposite winners
- `challenge_random_relabeling_invariance` — same graph as
  `train_hidden_family_n18` but node ids relabeled; primitive
  result must be invariant

The 6 OLD substrates from C19–C23A (ER_n10_p30 seed=1, etc.) are
**deprecated for primitive-induction work**.  They are
contaminated by exposure to manual loss-family iteration; using
them for promotion decisions would conflate substrate variance with
protocol gain.  They remain usable only for regression tests of
existing demos (C19–C23A pin values).

---

## 7. Promotion Gates

Both gates evaluated on held-out + challenge results.  Train results
do NOT figure into promotion decision (they are sanity-only per §4
TRAIN-EVAL).

### Stable gate (E1/E2 eligible)
ALL of:
- `mean_PE_reduction_heldout ≥ 0.05` (5% across 6 held-out)
- `wins_heldout ≥ 4/6` (substrate beats E0 baseline)
- `runtime_overhead ≤ 1.5×` (candidate invocation cost vs equivalent
  bootstrap composition)
- `no_degeneracy_flag` on any held-out substrate (K=1, mega-group,
  singleton-dominant)
- `passes_random_relabeling_invariance` on `challenge_random_
  relabeling_invariance` (output equivalent up to relabeling)
- `wins_on_at_least_2_challenge` of 4 (excluding relabel invariance,
  which is binary pass/fail)

### Experimental gate (E2-experimental only; not stable-active)
ALL of:
- `mean_PE_reduction_heldout ≥ 0.03`
- `wins_heldout ≥ 3/6`
- `runtime_overhead ≤ 2.0×`
- `no_degeneracy_flag`
- (challenge tests informational only)

Candidate that fails experimental gate → `rejected`.  Ledger entry
records why.  Rejected candidates cannot be re-evaluated unless
SPECIFY produces a structurally different `cand_NNN+1`.

### Promotion batch
DISCOVER produces N candidates; SPECIFY/FREEZE/EVAL run in batch;
PROMOTE decision is per-candidate but RETEST is on whole batch.
If batch retest fails, ALL batch promotions roll back transactionally
(§8).

---

## 8. Rollback and Dependency Graph

Primitive lifecycle states:
- `candidate` — specified, not yet evaluated
- `frozen` — locked, ready for held-out
- `experimental_active` — passed experimental gate; in E2-experimental
- `stable_active` — passed stable gate; in E1/E2-stable
- `rolled_back` — removed from dictionary; ledger row remains
- `deprecated` — explicitly retired via deprecation cycle

### Dependency graph
Stored as ledger metadata on each promoted primitive:
```
primitive_id: cand_NNN
depends_on: [cand_MMM, cand_KKK, ...]   (other promoted words
                                          used in expansion; empty
                                          for direct-bootstrap-only
                                          candidates)
introduced_in_cycle: NN
status: ...
```

### Rollback rules

| trigger | scope |
|---------|-------|
| Retest fails post-promotion | Entire promotion batch, transactionally |
| Manual deprecation | Single primitive, cascade-rollback anything that depends_on it AND is not stable_active |
| Cascade from dependency rollback | All primitives transitively depending on rolled-back one AND not stable_active |

**Stable primitives are immutable** until explicit deprecation cycle
(requires new pre-reg explaining why deprecation, attested).
Cascade rollback CANNOT touch a stable_active primitive — if a
non-stable rollback would orphan a stable primitive, the rollback is
blocked and surfaces as a protocol error requiring human review.

---

## 9. Contamination Rules

Once any of these events occur, the affected candidate is
contaminated and cannot be cited as positive evidence in catalogue
updates regardless of subsequent results.

### Event: candidate mutated after held-out exposure
Iron rule.  Even single-character edit to expansion/preconditions/
postconditions/cost_model after first HELD-OUT-EVAL run = candidate
voided.  Modified version requires new cand_id AND new held-out
rotation (the substrate hashes change for the new candidate).

### Event: held-out substrate leaked into discovery
If discovery module logs show access to held-out or challenge
substrate hashes, all candidates produced in that DISCOVER run are
contaminated.  Discovery must re-run with fresh seeded train-only
loader.

### Event: threshold mining
If promotion gate parameters (5%, 4/6, 1.5×) are adjusted *after*
seeing any candidate's held-out score, all subsequent promotions
under modified parameters are contaminated.  Gates can be modified
ONLY in explicit deprecation cycle, never silently.

### Event: result mining via cand_NNN cherry-pick
Discovery produces an ordered candidate list with provenance.
Evaluating only "interesting-looking" candidates is contamination.
Either evaluate top-K with K fixed pre-discovery, OR evaluate ALL
candidates produced by mining run (no skipping).  K and evaluation
order are committed at cycle 25 in mining_protocol.md and
attested.

### Event: hidden opcode injection
Promoted primitive uses Racket-level behavior not expressible in
bootstrap + fixed stdlib.  Caught by macro-expansion test
(`scripts/verify_expansion.sh cand_NNN` must reduce candidate to a
proof tree of bootstrap calls).  Failure → contamination,
candidate voided.

### Event: metric replacement
Switching from declared metric (PredError vs degree baseline) to a
substitute metric ("alternative comparison") after seeing
unfavorable results = contamination.  Metric is committed at
cycle 25 and modifications require deprecation cycle.

### Event: post-hoc challenge substrate
Adding challenge substrates AFTER candidates have been evaluated =
contamination.  Challenge set is locked at cycle 25 along with
train/held-out.  Adding more challenges requires new pre-reg and
restarts the evaluation count.

---

## 10. Cheating Defense — Summary

Multi-layer.  Each layer alone is insufficient; combined they make
human cherry-pick auditable.

**Pre-discovery (frozen at cycle 25):**
- Substrate set hashes
- Metric definitions
- Promotion gate thresholds
- Mining algorithm code hash
- Mining hyperparameters (incl. K, evaluation order)
- Random seed policy
- Forbidden features list (e.g., direct degree access)

**During discovery:**
- Discovery module loads ONLY train substrate hashes
- Held-out command (`scripts/heldout_eval.sh`) is separate binary;
  emits append-only entries
- Blind candidate naming `cand_NNN`
- No human inspection of mining output before SPECIFY locks

**After held-out exposure:**
- Iron rule: no candidate mutation
- All thresholds frozen
- Results append-only
- Result_hash recorded in ATTEST

**Post-promotion:**
- Engine version bumped
- Full regression retest mandatory
- Ledger entry permanent
- Rollback fully provenance-tracked

The protocol does not assume the human is malicious.  It assumes the
human will be biased (we all are) and provides a paper trail that
makes the bias visible to outside reviewers.  A reviewer reading
the ledger should be able to reconstruct every promotion decision
and detect any rule violation.

---

## 11. Cycle Roadmap (post-cycle-24)

### Cycle 25 — Bootstrap Extension
**Goal:** add 6 meta-level primitives + freeze substrate set +
freeze mining protocol.  All hand-crafted, no induction yet.

Deliverables:
- `sixth/meta/promote.rkt` — `PROMOTE`, `ROLLBACK` implementations
- `sixth/meta/attest.rkt` — `ATTEST-PRIMITIVE`, `LEDGER-APPEND`
- `sixth/meta/heldout.rkt` — `HELD-OUT-EVAL`, `DICTIONARY-SNAPSHOT`
- `attestations/primitives-ledger.txt` — initialized
- `substrates/train/*.6th`, `substrates/heldout/*.6th`,
  `substrates/challenge/*.6th` — 16 substrate files generated and
  committed (12 main + 4 challenge)
- `mining_protocol.md` — frozen mining algorithm spec, K, eval order
- Smoke test: hand-craft NOP candidate, run through full lifecycle,
  verify ledger entries, verify dictionary mutation, verify rollback
  restores
- Full regression 1996/1996 must pass with new meta-primitives loaded

NO scientific claim from cycle 25.  This is plumbing.

### Cycle 26 — Manual Primitive Induction (Protocol Validation)
**Goal:** validate the protocol works end-to-end on ONE hand-crafted
candidate.  Honest framing: this is NOT scientific signal — the
human chose the candidate.  This cycle answers "does the protocol
correctly route a known candidate to its honest verdict?".

Pre-reg PREDICTIONS-144.md must commit:
- Specific candidate expansion (e.g., a `MERGE-IDENTICAL-ROWS`
  candidate)
- Predicted result regime (likely promoted_experimental or rejected
  given C21–C23A history — degree dominance suggests rejection
  is plausible)
- Forbid mutation of candidate after held-out

If candidate passes stable gate → protocol can promote stable
primitives correctly.
If candidate fails experimental → protocol's rejection mechanism
works.
If candidate passes experimental but fails stable → boundary
behavior validated.

This cycle's success is NOT "primitive helped"; it is "protocol
behaved according to spec on a known-input case".

### Cycle 27 — Automated Discovery (The Real Test)
**Goal:** mining algorithm produces N candidates from train
trajectories WITHOUT human curation.  Top-K run through protocol.
If any pass stable gate, E2 vs E0 comparison is the publishable
signal.

Pre-reg PREDICTIONS-145.md must commit:
- Mining algorithm hash (fixed at cycle 25)
- K (number of top candidates to evaluate)
- Evaluation order rule
- Acceptance: ≥1 candidate passes stable gate AND E2 beats E0
  on held-out PredError by ≥10% mean

If pass → first true substrate-derived positive of cognition
direction.  Catalogue: "substrate engine self-extends its alphabet
in a way that beats fixed-alphabet engine on held-out predictive
task."  Publishable.

If fail → primitive induction (as currently specified) does not
beat fixed primitives on these substrates.  Honest negative.
Cycle 28+ either: (a) revisit mining algorithm with new pre-reg,
or (b) declare substrate-of-cognition under current Sixth
architecture unfalsified-but-unsupported and pivot to next
architectural test.

---

## 12. What This Document Does NOT Claim

- It does NOT claim primitive induction will succeed.
- It does NOT claim Sixth is a substrate of cognition.
- It does NOT prove the protocol is bias-free; it only makes bias
  auditable.
- It does NOT make any empirical prediction (that is cycle 25+'s job).

It claims only: **here is a falsifiable protocol for evaluating
whether Sixth can extend its own alphabet under predictive pressure;
if cycle 27 fails under this protocol, primitive induction in this
form is a substrate-derived negative.**

---

## References

- Cycle 23A (commit 36fb9ee) — closes loss-family arc with CCCCC
  on NSUM benchmark (4th substrate-derived negative)
- User spec 2026-05-23 — primitive-evolving substrate; meta-level
  vs object-level distinction; train/held-out/challenge split;
  cost-aware promotion; macro-expansibility constraint;
  transactional rollback; multi-layer cheating defense including
  blind naming and iron rule on post-held-out mutation
- METHODOLOGY.md — Rules 1–9 (pre-registration discipline)
- Lakatos (1970) "Falsification and the methodology of scientific
  research programmes" — hardcore/protective belt distinction;
  the protocol here is the substrate research programme's hardcore
- Goodhart (1975) — "when a measure becomes a target, it ceases to
  be a good measure"; the protocol's threshold-freeze and append-only
  ledger are explicit Goodhart-defense

---

## Attestation

This document is attested via `scripts/attest_prediction.sh
docs/META-SEMANTICS.md` and committed in cycle 24.  Future
modifications require new attestation and explicit deprecation
cycle.  Quiet modifications are protocol violations and contaminate
all subsequent cycles relying on the modified spec.
