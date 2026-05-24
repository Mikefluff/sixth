# META-SEMANTICS — Runtime Primitive Induction Protocol (v2)

**Status:** Cycle 24 deliverable, revision 2.  Specification document.
NO code, NO test.

**Date:** 2026-05-23

---

## §0. Revision History & Deprecation Notice

### v2.1 amendment — Energy Accounting added (cycle 25E)

Date: 2026-05-23 (same authorship period as v2).

Per user spec 2026-05-23: §17 Energy Accounting v0 appended as an
**additive** amendment.  Energy is observational, NOT a gate in
cycle 25.  Cycle 26 will activate `COMMIT-PRIMITIVE` energy
enforcement.

No existing constraint modified; all §1–§16 retain v2 semantics.
Additive amendments are permitted without full deprecation cycle
when:
- they do not change the behavior of existing primitives in
  ways that affect already-passed protocol tests
- they introduce new observables only, not new gates
- they are explicitly marked as additive in revision history

v2.1 satisfies all three conditions.  The energy counters live in
`_energy-*` env-memory keys with the iron constraint **observational
only**: they do not enter `law_hash`, do not enter `world_hash`,
do not affect SHADOW-CHECK equivalence outside of explicit energy
tests.  Without this constraint, the measurer would alter the
measured (Heisenberg trap).

### v1 → v2 transition (same authorship session)

**v1** committed at `ec7370f` (2026-05-23 03:44Z, ledger row sha
`096d2902`).  v1 described a controlled deployment pipeline:
DISCOVER → SPECIFY → FREEZE → TRAIN-EVAL → HELD-OUT-EVAL → PROMOTE →
RETEST → ATTEST.  This is governance machinery.

**v1 deprecation reason** (user critique 2026-05-23): v1 missed the
runtime-evaluation requirement.  In v1, candidates are prepared
offline and loaded into the dictionary between runs.  This is NOT
Sixth's thesis.  Sixth's thesis is that the runtime ITSELF mutates
its law-state during execution — the substrate observes its own
patterns and promotes them WHILE running, not as an external CI/CD
pipeline.

**v1 was never used as basis for any cycle 25+ test** before
deprecation.  No contamination.  Audit trail in git history (`git
show ec7370f`) and ledger row `096d2902`.

**v2 supersedes v1** in entirety.  v2 introduces **two-tier
primitive lifecycle**:

- **Tier 1 (ephemeral, in-run)**: `INDUCE-RUNTIME` mutates law-state
  during evaluation; cheap local equivalence check; rollback within
  run.  This is the Sixth thesis.
- **Tier 2 (stable, cross-run)**: `COMMIT-PRIMITIVE` → held-out
  protocol → `PROMOTE-STABLE`.  This is the governance layer (v1's
  content).

Both tiers required.  Tier 1 alone has no scientific filter (would
admit any pattern that happens to repeat).  Tier 2 alone is not
self-modifying runtime (it's offline pipeline).  Together they
realize "engine evolves its own alphabet under both fast local
fitness AND slow attestation pressure."

This document is normative for cycles 25+.  Any further
modification requires explicit deprecation cycle and new
attestation; quiet changes are protocol violations.

---

## §1. Core Thesis (revised)

> Sixth primitives are not eternal axioms.  They are promoted,
> attested, rollbackable operational compressions of repeated
> successful patterns — discovered AND promoted **during runtime
> execution**, with a separate slow-track attestation pipeline that
> elevates proven-useful ephemerals into permanent law.

The fixed-primitive substrate of C19–C23A was insufficient because
*any* loss function on degree-biased NSUM dynamics is dominated by
degree (cycle 23A, REGIME CCCCC).

The architectural alternative is **substrate-that-evolves-its-own-
alphabet** with two coupled lifecycles:

| tier | timescale | mechanism | filter |
|------|-----------|-----------|--------|
| Tier 1 ephemeral | within single run | `INDUCE-RUNTIME` at eval-loop motif detection | local shadow-world equivalence + cheap predictive gain |
| Tier 2 stable | across runs | `COMMIT-PRIMITIVE` → held-out eval → `PROMOTE-STABLE` | formal multi-criterion gate, append-only ledger |

The protocol's purpose is to make the question "does runtime
primitive induction beat fixed primitives" *answerable* without
human curation cheating — at BOTH tiers.

---

## §2. Two-Tier Primitive Lifecycle (NEW vs v1)

```
                          ┌──────────────────────────────┐
                          │  TIER 1: EPHEMERAL (in run)  │
                          ├──────────────────────────────┤
                          │                              │
   STEP t  ───►  eval()  ─┤  DETECT-MOTIF                │
     │                    │       │                      │
     │                    │       ▼                      │
     │                    │  SHADOW-CHECK (equivalence)  │
     │                    │       │                      │
     │                    │       ▼ (passes)             │
     │                    │  INDUCE-RUNTIME cand_NNN     │
     │                    │       │                      │
     │                    │       ▼ (law_hash mutates)   │
     │                    │  USE-RUNTIME (subsequent     │
     │                    │             steps may call)  │
     │                    │       │                      │
     │                    │       ▼ (invariant violation)│
     │                    │  ROLLBACK-RUNTIME            │
     │                    │                              │
   STEP t+1 ◄─── continue ┘                              │
                          │  (optional, post-run)        │
                          │  COMMIT-PRIMITIVE  ──────────┼──┐
                          └──────────────────────────────┘  │
                                                            │
                          ┌──────────────────────────────┐  │
                          │  TIER 2: STABLE (cross-run)  │◄─┘
                          ├──────────────────────────────┤
                          │  SPECIFY   (machine record)  │
                          │       │                      │
                          │       ▼                      │
                          │  FREEZE  (immutable hash)    │
                          │       │                      │
                          │       ▼                      │
                          │  TRAIN-EVAL  (sanity)        │
                          │       │                      │
                          │       ▼                      │
                          │  HELD-OUT-EVAL  (iron rule)  │
                          │       │                      │
                          │       ▼                      │
                          │  PROMOTE-STABLE              │
                          │       │                      │
                          │       ▼                      │
                          │  RETEST  (full regression)   │
                          │       │                      │
                          │       ▼                      │
                          │  ATTEST  (ledger append)     │
                          │       │                      │
                          │       ▼ (regression breaks)  │
                          │  ROLLBACK-STABLE             │
                          └──────────────────────────────┘
```

**Coupling rule**: a Tier 1 ephemeral becomes a Tier 2 candidate
ONLY via `COMMIT-PRIMITIVE`, which requires:
- ephemeral was used successfully ≥ N times within ≥ M distinct
  runs (N=5, M=3 — fixed pre-commit at cycle 25)
- no `ROLLBACK-RUNTIME` was issued against the ephemeral in any
  of those runs
- no run hit invariant-violation traceable to the ephemeral

This filter ensures Tier 2 evaluation is not flooded with
single-occurrence motifs.

---

## §3. Runtime State and Law-State Mutation (NEW)

Sixth runtime is a 4-tuple, not the previous 1-tuple
("substrate state"):

```
Runtime = { world_state, law_state, trace, ledger }

world_state  : hypergraph (nodes, edges, hedges, marks, activations)
law_state    : active dictionary (bootstrap ∪ stdlib ∪ ephemeral ∪ stable)
trace        : append-only log of {step, op, law_hash_before,
                                   law_hash_after, world_delta}
ledger       : append-only log of {timestamp, event, candidate_hash,
                                   provenance}
```

Each evaluation step `STEP(runtime, op)`:

```
1. record trace.law_hash_before = hash(runtime.law_state)
2. if op is object-level primitive:
     world_state' = apply_object(op, world_state, law_state)
     world_delta = world_state' - world_state
     law_hash_after = law_hash_before  (unchanged)
3. else if op is meta-level primitive (Tier 1 or Tier 2):
     law_state' = apply_meta(op, law_state, world_state)
     law_hash_after = hash(law_state')
     world_delta = ∅  (world unchanged by meta ops)
     ledger.append(meta-event)
4. trace.append({step, op, law_hash_before, law_hash_after, world_delta})
5. return updated runtime
```

**Critical invariant**: `law_hash` is a first-class observable in
trace.  Any law-state mutation is visible to outside reviewer
without needing to reconstruct dictionary contents — the hash
mutation itself is the evidence that law changed at step t.

**Aphorism (v1 §2 retained)**: `MARK` changes world.  `PROMOTE`
changes the laws.  v2 adds: **and you can see the moment of the
change in the trace, not in some external manifest.**

---

## §4. Meta-primitives — Tier 1 (Ephemeral, NEW)

These live alongside object-level primitives in the runtime.  They
operate on `law_state` and `trace`.  They are hand-crafted bootstrap
(per §6), never auto-induced (self-modifying-meta would collapse the
protocol).

### `DETECT-MOTIF`
Scans recent trace window (fixed pre-commit: last K=20 steps) for
operation subsequences appearing ≥ R times (fixed pre-commit:
R=3).  Returns list of candidate motifs with positions.

```
( -- motif-list )   \ stack: nothing in, list of motifs out
```

### `SHADOW-CHECK`
Given a candidate motif (operation sequence), applies it on a
forked copy of `world_state` and compares to applying the original
expansion.  Pass = identical world_state delta AND runtime cost
≤ expanded cost.  Cheap (forks at primitive granularity, not full
trace replay).

```
( motif -- pass? )
```

### `INDUCE-RUNTIME`
Promotes a passed motif as ephemeral primitive `cand_NNN`.  Mutates
`law_state` by adding new word to dictionary with status
`ephemeral_active`.  Records ledger event with candidate hash and
trace position of induction.

```
( motif -- cand-id )   \ pushes new candidate id
```

Triggers `law_hash` mutation visible in trace.

### `USE-RUNTIME`
Implicit: any subsequent eval step that matches the motif now
resolves through the ephemeral word instead of expanding to base
primitives.  No explicit user invocation needed; this is dispatch
behavior.

### `ROLLBACK-RUNTIME`
Removes ephemeral primitive from active dictionary.  Triggered by:
- Invariant violation detected during subsequent steps
- Explicit user/test request
- Coupling-rule timeout (ephemeral was never `USE-RUNTIME`d after
  induction within configurable window)

```
( cand-id -- )   \ ephemeral removed; law_hash mutates back
```

If `ROLLBACK-RUNTIME` is called on a Tier 2 stable primitive, it
errors — stable primitives are immutable from runtime path.

### `COMMIT-PRIMITIVE`
Bridge from Tier 1 to Tier 2.  Called after run completes; takes an
ephemeral that satisfies coupling rule (§2) and produces a frozen
candidate record suitable for Tier 2 held-out evaluation.

```
( cand-id -- candidate-record )
```

Once `COMMIT-PRIMITIVE` is called, the candidate's expansion and
metadata are sealed.  Iron rule of v1 §9 still applies post-commit:
no mutation after held-out exposure.

---

## §5. Meta-primitives — Tier 2 (Stable, was v1 §3)

Tier 2 lifecycle is essentially v1's protocol, but reframed as
follow-on to Tier 1 rather than as standalone deployment pipeline.

### `SPECIFY`
Takes a `COMMIT-PRIMITIVE` output and produces machine-readable
candidate record with full metadata (expansion, preconditions,
postconditions, cost_model, discovery_provenance — including
ephemeral usage history from Tier 1).

### `FREEZE`
Computes `candidate_hash` and appends `(cycle, timestamp, hash,
status=frozen)` to `attestations/primitives-ledger.txt`.  After
freeze, candidate source is read-only.

### `TRAIN-EVAL` (informational)
Runs candidate on train substrates.  Result is NOT promotion
authority; only sanity (catch obvious bugs).

### `HELD-OUT-EVAL`
Iron rule: result is append-only.  First eval fixes held-out score
forever.  Implemented as separate command
`scripts/heldout_eval.sh cand_NNN` which writes to ledger and
cannot be invoked twice on same candidate.

### `PROMOTE-STABLE`
Applies promotion gate (§9).  Three outcomes:
`promoted_stable` (eligible for E1/E2), `promoted_experimental`
(E2-experimental only), `rejected`.

Status appended to ledger.  Stable promotion adds word to permanent
dictionary as `stable_active`.

### `RETEST`
Full `raco test tests/examples-test.rkt` MUST pass unchanged after
stable promotion.  If regression breaks, automatic
`ROLLBACK-STABLE` for entire promotion batch.

### `ATTEST-PRIMITIVE`
Final ledger append with full provenance bundle (candidate_hash,
expansion_hash, train_set_hash, heldout_set_hash, metric_hash,
threshold_hash, result_hash, engine_version, decision).

### `ROLLBACK-STABLE`
Removes stable primitive from permanent dictionary.  Triggered
only by retest failure or explicit deprecation cycle.  Cascade
rules per §10.

---

## §6. Bootstrap Boundary (revised v1 §4)

Three tiers; membership locked at cycle 25.  Promoted words from
EITHER tier MUST be macro-expansible to bootstrap.

### Bootstrap (object-level)
Unchanged from v1.  Cannot enter promotion protocol of either tier.
Stack ops, arithmetic, memory, control, substrate axioms.

### Bootstrap (meta-level) — EXPANDED in v2
Added at cycle 25.  Cannot be removed, cannot be redefined.  Cannot
enter promotion protocol.

**Tier 1 ephemeral machinery (NEW v2):**
- `DETECT-MOTIF`
- `SHADOW-CHECK`
- `INDUCE-RUNTIME`
- `ROLLBACK-RUNTIME`
- `COMMIT-PRIMITIVE`
- `LAW-HASH` (returns current law_state hash)

**Tier 2 stable machinery (v1 carryover):**
- `SPECIFY`
- `FREEZE`
- `HELD-OUT-EVAL` (technically a script wrapper, but invokable as
  meta-primitive in test harnesses)
- `PROMOTE-STABLE`
- `ATTEST-PRIMITIVE`
- `ROLLBACK-STABLE`
- `DICTIONARY-SNAPSHOT`
- `LEDGER-APPEND`

Total: 14 meta-primitives added at cycle 25 (6 Tier 1 + 8 Tier 2).

### Fixed stdlib
Unchanged: `stdlib/*.6th` hand-written, version-controlled, counts
as bootstrap for macro expansion purposes.

### Promoted words
- **Ephemeral (Tier 1)**: live only in `law_state` of current
  runtime session.  NOT persisted across processes.  Removed on
  session end or `ROLLBACK-RUNTIME`.
- **Stable (Tier 2)**: stored as `stdlib/promoted/<cycle>/
  cand_NNN.6th` with full provenance comment.  Loaded into every
  runtime via standard `use` mechanism.

**Expressivity bound (unchanged)**: both tiers require
macro-expansibility to bootstrap + fixed stdlib.  No new
Racket-level opcode at either tier.  No hidden evaluator behavior.
No side-effect outside `store`/`load` or substrate axioms.

---

## §7. Engine Classes (revised v1 §5 with ephemeral consideration)

| class | dictionary at runtime end | publishable | use |
|-------|--------------------------|-------------|-----|
| **E0** | bootstrap + fixed stdlib | yes | baseline; all C19–C23A |
| **E1** | E0 + ≥1 attested **stable** primitive | yes | post-cycle-27 minimum |
| **E2** | E0 + batch of attested **stable** primitives | yes | post-cycle-27 target |
| **E1_ephemeral** | E0 + ≥1 ephemeral (Tier 1 only, not committed) | yes for "runtime mutation demonstrated", **NO** for stable claims | cycle 26 demo |
| **E_bad** | any dictionary with non-attested OR contaminated primitives | **NO** | development-only |

`E1_ephemeral` is a publishable class for the narrow claim "law-state
mutated during runtime and trace recorded it" — i.e. that the engine
demonstrably self-modifies.  It is NOT publishable as claim about
generalization (no held-out evidence), only as architectural
demonstration.

Cycle 26 (manual ephemeral) produces an `E1_ephemeral` artifact.
Cycle 27 (automated discovery + Tier 2 promotion) produces `E1` or
`E2` artifact, conditional on held-out pass.

---

## §8. Substrate Set Policy (unchanged from v1 §6)

12 substrates total (6 train + 6 held-out same families different
graphs) + 4 challenge substrates.  All generated by deterministic
seeded generators; hashes committed at cycle 25 before any
candidate enters discovery.

Train: `train_ER_n10_p30`, `train_ER_n20_p15`, `train_path_n10`,
`train_cycle_n10`, `train_motif_triads`, `train_hidden_family_n18`.

Held-out: corresponding `heldout_*` with disjoint seeds.

Challenge: `degree_trap`, `mega_group_trap`,
`motif_vs_degree_conflict`, `random_relabeling_invariance`.

**Old C19–C23A substrates remain DEPRECATED for primitive
induction.**  Usable only for regression of existing demos.

**Tier 1 ephemeral induction (cycle 26) MAY use train substrates
freely** since Tier 1 has no held-out claim.  The held-out
discipline kicks in only at Tier 2 transition.

---

## §9. Promotion Gates (Tier 2 only; v1 §7 essentially unchanged)

Both gates evaluated on held-out + challenge results.

### Stable gate (E1/E2 eligible) — ALL of:
- `mean_PE_reduction_heldout ≥ 0.05`
- `wins_heldout ≥ 4/6`
- `runtime_overhead ≤ 1.5×`
- `no_degeneracy_flag` on any held-out
- `passes_random_relabeling_invariance` (challenge)
- `wins_on_at_least_2_challenge` of remaining 3

### Experimental gate (E2-experimental only) — ALL of:
- `mean_PE_reduction_heldout ≥ 0.03`
- `wins_heldout ≥ 3/6`
- `runtime_overhead ≤ 2.0×`
- `no_degeneracy_flag`

### Tier 1 ephemeral has NO formal gate
Tier 1 acceptance is `SHADOW-CHECK` pass only (cheap local
equivalence + runtime cost bound).  No predictive-quality
requirement — Tier 1 is for fast local pattern caching, not
scientific evidence.  Tier 1 failures `ROLLBACK-RUNTIME` silently
without ceremony.

Coupling rule (§2) is the bridge: only ephemerals that proved
useful across multiple runs even reach Tier 2 evaluation.  This
filters most ephemerals before they consume held-out attention.

---

## §10. Rollback — Ephemeral AND Stable (extends v1 §8)

### Tier 1 (`ROLLBACK-RUNTIME`)
Single ephemeral removed within run.  Cheap, no ceremony.  Logged
in trace (not ledger — trace is the right level since ephemeral
lifetime is in-run).

If ephemeral's own usage caused world_state inconsistency
(detected by post-condition violation or runtime invariant break),
auto-rollback fires.  Subsequent retry of motif gets a fresh
ephemeral id (`cand_NNN+1`) — the failed id is permanently marked
contaminated for THAT run.

### Tier 2 (`ROLLBACK-STABLE`)
Inherits v1 §8 transactional batch rule.  Stable primitives are
immutable until explicit deprecation cycle.  Cascade rollback for
non-stable dependents.  Cascade BLOCKED on stable_active dependents
(orphaning a stable primitive is protocol error requiring human
review).

### Cross-tier interaction
If Tier 2 `ROLLBACK-STABLE` removes a primitive `cand_K` that was
also being used as ephemeral in some active runtime session, the
session's law_state is invalidated; trace logs the invalidation
event and any in-flight `USE-RUNTIME` of `cand_K` causes the next
step to fall back to expanded form.  This is explicit, not silent.

---

## §11. Contamination Rules (extends v1 §9)

All v1 §9 rules retained:
- Candidate mutation after held-out exposure → voided
- Held-out substrate leak into discovery → batch voided
- Threshold mining → subsequent promotions voided
- Result mining via cand_NNN cherry-pick → voided
- Hidden opcode injection → voided
- Post-result metric replacement → voided
- Post-hoc challenge substrate addition → voided

NEW v2 contamination events specific to runtime tier:

### Event: ephemeral re-used across processes without commit
An ephemeral in one runtime session cannot be invoked in another
session as if it were stable.  If a test or script attempts to
"warm-start" a new runtime with old ephemerals, it is a contamination
event — the result cannot be cited.

Enforcement: `law_state` is serialized only via stable primitives;
ephemerals are NOT included in any persistence format.  This is a
mechanical guarantee, not just a rule.

### Event: SHADOW-CHECK bypass
If runtime trace shows `INDUCE-RUNTIME` event without preceding
`SHADOW-CHECK` event (or `SHADOW-CHECK` event with pass=false),
the resulting ephemeral is contaminated.  Any `COMMIT-PRIMITIVE`
on contaminated ephemeral fails at SPECIFY stage of Tier 2.

### Event: COMMIT-PRIMITIVE without coupling rule
Coupling rule (§2: N=5 uses, M=3 distinct runs) is mechanical
gate at `COMMIT-PRIMITIVE`.  Bypassing it (e.g., by `COMMIT`
on a freshly-induced ephemeral with usage_count=1) fails at
commit time with explicit error.  Manual override of coupling
rule = contamination.

---

## §12. Cheating Defense — Summary (extends v1 §10)

All v1 layers retained.  v2 adds runtime-tier defenses:

**Pre-discovery (frozen at cycle 25):**
- v1 layer + DETECT-MOTIF window size (K=20), repetition threshold
  (R=3), coupling rule (N=5, M=3)
- SHADOW-CHECK cost-bound parameters
- Trace format (so reviewers can re-parse)

**During runtime (Tier 1):**
- `INDUCE-RUNTIME` requires preceding `SHADOW-CHECK` pass — no
  bypass
- `law_hash` mutation visible in trace at every step
- Ephemerals NEVER persisted across processes
- All Tier 1 events logged to trace with timestamps

**At Tier 1 → Tier 2 bridge:**
- `COMMIT-PRIMITIVE` enforces coupling rule mechanically
- Tier 2 SPECIFY records ephemeral usage history from Tier 1 trace
  as required provenance

**During Tier 2 (unchanged from v1):**
- Iron rule on post-held-out mutation
- Blind naming
- Append-only results
- Multi-criterion gates

The added defenses make the **runtime claim itself auditable**: a
reviewer reading the trace can verify that `law_hash` mutated at
the right step, that `SHADOW-CHECK` preceded `INDUCE-RUNTIME`, and
that the ephemeral was actually used before any `COMMIT-PRIMITIVE`.
This is the architectural correctness check that v1 lacked.

---

## §13. Cycle Roadmap (revised v1 §11)

### Cycle 25 — Runtime Law-State Mutation Plumbing
**Goal (revised):** add 14 meta-primitives (6 Tier 1 + 8 Tier 2)
and 4-tuple runtime model (`world_state`, `law_state`, `trace`,
`ledger`).  Freeze substrate set, freeze mining protocol parameters,
freeze coupling rule.

Deliverables:
- `sixth/meta/tier1/{detect_motif,shadow_check,induce_runtime,
  rollback_runtime,commit_primitive,law_hash}.rkt`
- `sixth/meta/tier2/{specify,freeze,heldout,promote_stable,
  attest_primitive,rollback_stable,dictionary_snapshot,
  ledger_append}.rkt`
- `sixth/runtime/state.rkt` — 4-tuple runtime model with trace
  recording every step's law_hash_before/after
- `attestations/primitives-ledger.txt` — initialized
- `substrates/{train,heldout,challenge}/*` — 16 substrate generators
  + hash commits
- `mining_protocol.md` — algorithm spec, K=20, R=3, N=5, M=3, eval
  order, forbidden features
- Demo 143 (smoke test): runtime executes a sequence; trace contains
  `INDUCE-RUNTIME` event; `law_hash` mutates at expected step;
  subsequent step uses the ephemeral; trace shows that exactly;
  `ROLLBACK-RUNTIME` cleanly restores `law_hash`

NO scientific claim from cycle 25.  Pure plumbing.

Regression invariant: 1996/1996 with meta-primitives loaded but
demo 143 NOT YET registered (it's net-new); 2NNN with demo 143
registered, where NNN reflects new pass count.

### Cycle 26 — Manual Tier 1 Demonstration (Protocol Validation)
**Goal:** validate runtime-induction works end-to-end on a
hand-crafted candidate motif.  Produces `E1_ephemeral` artifact —
publishable as architectural demonstration ONLY ("engine
demonstrably mutates own law-state during runtime"), NOT as
scientific predictive claim.

Pre-reg PREDICTIONS-144.md must commit:
- Hand-crafted motif (e.g., `MATCH-PATTERN EDGE+ EDGE+ MARK`
  three-repetition trigger)
- Expected `law_hash` sequence (before / at-induction / after-use)
- Expected world_state equivalence between induced-path and
  expanded-path
- Forbid mutation of motif spec after run begins
- Acceptance: trace contains required events in required order;
  world equivalence holds; `ROLLBACK-RUNTIME` restoration verified

Cycle 26 PASS ⇒ Tier 1 machinery works on known input.
Cycle 26 FAIL ⇒ runtime model broken; cycle 25 had subtle bug;
no progression to cycle 27.

### Cycle 27 — Automated Discovery → Tier 2 Promotion (Real Test)
**Goal:** mining algorithm produces ephemerals during runtime on
train substrates WITHOUT human curation.  Those satisfying coupling
rule auto-promote via `COMMIT-PRIMITIVE` to Tier 2.  Top-K candidates
run through held-out protocol.  E1/E2 vs E0 held-out comparison is
publishable signal.

Pre-reg PREDICTIONS-145.md must commit:
- Mining algorithm hash (frozen at cycle 25)
- K (top candidates evaluated)
- Evaluation order rule
- Acceptance: ≥1 candidate passes stable gate AND E2 beats E0 on
  held-out PredError by ≥10% mean

Cycle 27 PASS ⇒ first true substrate-derived positive of cognition
direction.  Catalogue addition: "substrate engine self-extends its
alphabet at runtime in a way that beats fixed-alphabet engine on
held-out predictive task."

Cycle 27 FAIL ⇒ honest negative: runtime primitive induction (as
currently specified) does not beat fixed primitives on these
substrates.  Cycle 28+ either revises mining algorithm with new
pre-reg, or declares substrate-of-cognition under current Sixth
architecture unsupported and pivots to next architectural test.

---

## §14. What This Document Does NOT Claim (v1 §12 unchanged)

- It does NOT claim primitive induction will succeed.
- It does NOT claim Sixth is a substrate of cognition.
- It does NOT prove the protocol is bias-free; it only makes bias
  auditable AT BOTH TIERS.
- It does NOT make any empirical prediction (that is cycle 26+'s
  job).

It claims only: **here is a falsifiable two-tier protocol for
evaluating whether Sixth can self-modify during runtime (Tier 1)
AND whether such self-modifications generalize beyond their
discovery context (Tier 2); if cycle 27 fails under this protocol,
primitive induction in this form is a substrate-derived negative.**

---

## §15. References

- Cycle 23A (commit 36fb9ee) — closes loss-family arc with CCCCC
  (4th substrate-derived negative)
- v1 META-SEMANTICS.md (commit ec7370f, deprecated 2026-05-23 same
  session, ledger row 096d2902) — controlled deployment pipeline;
  superseded for missing runtime-evaluation requirement
- User spec 2026-05-23 (initial) — primitive-evolving substrate;
  meta vs object-level; promotion gates; cheating defense
- User spec 2026-05-23 (v2-trigger) — runtime self-modification as
  Sixth's core thesis; INDUCE-RUNTIME inside eval loop;
  ephemeral/stable two-tier; law_hash visible in trace
- METHODOLOGY.md — Rules 1–9 (pre-registration discipline)
- Lakatos (1970) — hardcore/protective belt
- Goodhart (1975) — measure-target degeneration; protocol's
  threshold freeze and append-only ledger are Goodhart defense

---

## §16. Attestation

v2 attested via `scripts/attest_prediction.sh docs/META-SEMANTICS.md`
and committed in cycle 24 (same session as v1 deprecation).

v1 deprecation event itself recorded in ledger row immediately
prior to v2 attestation, establishing audit trail:
1. v1 written, attested (ec7370f, ledger sha 096d2902)
2. v1 deprecated within session (no test ever relied on v1)
3. v2 written replacing v1 in entirety
4. v2 attested (this commit, new ledger sha)

Future modifications require new attestation and explicit
deprecation cycle.  Quiet modifications are protocol violations
and contaminate all subsequent cycles relying on the modified spec.

---

## §17. Energy Accounting v0 (added cycle 25E)

Per user spec 2026-05-23.  Additive amendment per §0 — no existing
constraint modified.

### Thesis

> Energy in Sixth is not physical energy.  It is the internal cost
> of maintaining, transforming, explaining, and extending the
> runtime.  A primitive is energetically justified when its
> promotion reduces long-run runtime energy without violating
> invariants.

### Runtime tuple extension

```
Runtime = { world_state, law_state, trace, ledger, energy_state }
```

`energy_state` lives in `_energy-*` env-memory keys.  **Iron
constraint:** observational only.  Does NOT enter `law_hash`, does
NOT enter `world_hash`, does NOT affect SHADOW-CHECK equivalence
outside of explicit energy tests.

### Components (v0)

```
E_total = E_world + E_law + E_trace + E_conflict + E_search
        - E_reuse_gain
```

| component | definition (v0) |
|-----------|-----------------|
| `E_world` | `node_count + edge_count` (computed on demand) |
| `E_law` | sum of expansion lengths for all currently-active `cand_*` |
| `E_trace` | semantic-trace event count (NON-inspection top-level dispatches) |
| `E_conflict` | `shadow_failures × 100 + invariant_violations × 1000` |
| `E_search` | `Σ motif_length` per SHADOW-CHECK invocation |
| `E_reuse_gain` | `Σ (expansion_length - 1)` per cand_* dispatch |

For motif of length 3 promoted to `cand_001`:
- `E_law` delta on INDUCE: +3
- `E_reuse_gain` per USE: +2 (saves 2 ops vs inline expansion)
- At N=5 uses: gain=10, cost=3, **net = -7** → energetically justified.
- Length-1 motif: gain=0 per use → never justified. Defends against
  NOP-like promotions.
- Length-0 motif: rejected at INDUCE-RUNTIME (empty motif error).

### Inspection-vs-semantic separation

`E_trace` counts only **semantic** top-level dispatches.  The set
`INSPECTION-OPS` (defined in `sixth/meta/runtime.rkt`) is excluded:
- All `E-*` primitives + `E-SNAPSHOT`
- `LAW-HASH`, `HASH-WORLD`
- `LEDGER-COUNT`, `LEDGER-LAST`, `CAND-USES`, `CAND-STATUS`,
  `SHADOW-CERT-OF`, `SESSION-ID`, `ACTIVE-DICTIONARY`,
  `CONTAMINATE!`

Without this exclusion, inspection events bloat their own measure
(Heisenberg trap).

### 8 inspection primitives (Tier 1, object-level reads)

```
E-WORLD       ( -- n )    node_count + edge_count
E-LAW         ( -- n )    sum of cand body lengths
E-TRACE       ( -- n )    semantic-trace count
E-CONFLICT    ( -- n )    accumulated penalty
E-SEARCH      ( -- n )    accumulated SHADOW-CHECK cost
E-REUSE-GAIN  ( -- n )    accumulated saved ops
E-TOTAL       ( -- n )    full sum per formula
E-SNAPSHOT    ( -- list ) 10-tuple:
                          (world law trace conflict search reuse_gain
                           total world_hash law_hash session_id)
```

### COMMIT-PRIMITIVE dry-run (cycle 25E)

`COMMIT-PRIMITIVE` writes an energy dry-run record to ledger but
does NOT block on energy in cycle 25:

```
('commit-primitive cand-sym uses law-hash session-id
 'energy-dry-run
 ('law-cost L  'reuse-gain R  'net-delta-e D  'would-pass-energy-gate B))
```

Cycle 26 activates the gate: COMMIT requires `coupling_pass AND
cumulative_delta_e < 0`.

### Item 18 — Demo 143 unaffected

Demo 143 was specified pre-cycle-25E.  Adding energy must not break
it; energy is observational only.  Verified by regression
(2051 / 2051 ✓).

### Item 20 — Manual rollback flag on energy regression

If a primitive shows positive long-run ΔE after promotion, it gets
a rollback **flag** via `CONTAMINATE!` with reason
`'energy-regression`.  Auto-rollback deferred to cycle 26 (would
require infrastructure for "long-run" measurement, not just snapshot).

### What §17 does NOT claim

- Energy as defined here is NOT physical energy.
- Energy v0 is intentionally crude (count-based).  More
  sophisticated formulations (Kolmogorov complexity, MDL gain,
  prediction information bottleneck) belong to later cycles, not
  cycle 25E.
- v0 does NOT prove primitive induction will discover
  energetically-justified candidates.  It only provides the
  measurement substrate for cycle 26 to enforce.

### Cross-references

- Cycle 25E implementation: commit pending (this file's commit)
- `sixth/meta/runtime.rkt` — energy counters, hooks, helpers
- `sixth/meta/tier1.rkt` — 8 inspection primitives, SHADOW/COMMIT
  energy integration
- Demo 146 `examples/146-energy-accounting.6th` — items 16-20
  asserts (10 passes)

---

## §18. Ontological Five-Layer Separation (added cycle 34D, 2026-05-24)

Sections §1–§17 specify what the runtime DOES.  This section
specifies what the system's vocabulary IS, separated by ontological
origin.  The two are orthogonal: operational primitives (Tier 1 /
Tier 2 dispatch entries) are an engineering surface; ontological
classification distinguishes who placed each entity into the system
and what kind of thing it is.

Sources: cycle 34C bootstrap-alphabet archaeology
(`RESULTS-178-bootstrap-alphabet-archaeology.md`) and cycle 34C-bis
substrate-discovered audit
(`RESULTS-179-substrate-discovered-alphabet.md`).  Pre-reg:
`examples/PREDICTIONS-178-alphabet-archaeology.md`.

### §18.1 The five layers

| layer | content | source |
|-------|---------|--------|
| **L0 — Substrate axioms** | distinction, boundary, trace, collapse | bootloader (engineer, pre-cycle-25) |
| **L1 — Protocol grammar** | commit, shadow-check, contaminate (irreducible) + promote-stable, held-out-eval (derived from L1 primitives + governance) | machinery (engineer, cycle 25-26 spec) |
| **L2 — Discovered candidates** | cand_NNN that passed full pipeline AND persisted | SYSTEM (via DETECT-MOTIF-AUTO + protocol) |
| **L3 — Diagnostics** | `'stale`, `'demotion-candidate`, `'dependency-held`, `'dependency-supported`, `'subsidized` (proposed) | engineer (cycles 29+) |
| **L4 — Implementation** | counters, ttl, thresholds, credit, specific arithmetic | engineer (cycles 25-34) |

### §18.2 L2 occupancy: current count = 0

Per the substrate-discovered audit (cycle 34C-bis, 2026-05-24):

> The system currently has a bootstrap alphabet but NO durable
> substrate-discovered alphabet.  Every cand_NNN entity in the
> codebase is a test fixture inside an isolated demo file.  None
> has been auto-detected over an engineer-blind workload.  None
> has been persisted across runs.  None has been loaded by any
> production substrate use.

Verifiable by:
- `ls stdlib/promoted/` → directory does not exist
- `grep -rn "cand_[0-9]" stdlib/` → zero matches
- `attestations/ledger.txt` → zero `'promote-stable` events

This is **not a failure**.  It is the honest current state.  The
protocol for discovery (verified by demos 143-157) and the
INSTANCES OF DISCOVERY (zero so far) are different claims.

### §18.3 Binding archaeology rule (cycle 34B)

> **A primitive is not something useful.  A primitive is a
> distinction that cannot be removed without destroying the
> system's ability to make distinctions.**

> **A discovered primitive must have a lineage.  No lineage,
> no discovery.**

> **Hand-authored machinery (L0/L1/L3/L4) cannot be counted as
> discovered primitive.**

### §18.4 Hard rules for future cycles

1. **No new primitive without archaeology evidence.**  Any cycle
   proposing a new entity for L0 or L1 must produce per-entity
   records per the cycle 34B binding schema (named occurrence,
   unnamed occurrence, minimal distinction, dependencies,
   classification, anti-circular reason, evidence).
2. **No diagnostic label may participate in any truth gate.**
   L3 labels (`'stale`, `'subsidized`, etc.) are inspectable in
   the ledger and via `CAND-STATUS`; they have no role in
   `PROMOTE-STABLE`, `HELD-OUT-EVAL`, `COMMIT-PRIMITIVE`,
   `SHADOW-CHECK`, or `compute-support-credit-for`.
3. **No implementation_detail may be cited as ontology.**  L4
   entries (constants, counters, specific formulas) are
   engineering knobs.  A claim "the system has support_credit"
   is a claim about *the current implementation's arithmetic*,
   not about the substrate's ontology.
4. **Folk terms are rejected.**  `flow`, `energy_balance`,
   `repair`, `resolve`, `inscribe`, `forget` are not substrate
   concepts.  Naming does not create them.

### §18.5 Promotion remains organic-only (reinforced invariant)

> **`PROMOTE-STABLE`, `COMMIT-PRIMITIVE`, `HELD-OUT-EVAL`,
> `SHADOW-CHECK`, and `compute-support-credit-for` ALL consult
> only `MOMENTUM-NATIVE` (≡ `ORGANIC-MOMENTUM`).  Never
> `MOMENTUM-EFFECTIVE`.  Never `SUBSIDIZED-MOMENTUM`.  Never any
> sum that includes external_credit or support_credit.**

Ontologically: only `m_native` measures intrinsic productivity.
External support can preserve form (delay auto-decompose) but
cannot prove life (cannot pass any truth gate).

### §18.6 Cycle 34A status: BLOCKED

PREDICTIONS-177 (external energy + capacity + subsidized) was
attested as pre-reg (commit `2aef3f7`) but **implementation is
blocked**.

Reason: 34A proposes mechanisms to modulate survival of L2
entities.  L2 is currently empty.  Implementing 34A now would
only add machinery around fixtures and demo-only cand_NNN.

34A unblocks AFTER cycle 35 (proposed) builds the persistence
layer that allows L2 to be non-empty.

### §18.7 Cycle 35 (proposed): persistence layer for L2

See `docs/CYCLE-35-PROPOSAL-persistence.md`.

Minimum scope:
- `stdlib/promoted/<cycle>/cand_NNN.6th` file-write step in
  `PROMOTE-STABLE` (already promised in §6, never built)
- `'promote-stable` event in `attestations/ledger.txt`
- per-cand lineage record (workload hash, discovery cycle,
  motif body, held-out result, attestation row)
- cross-run dictionary persistence (load promoted cands at
  engine boot via standard `use` mechanism)
- metabolism survival check across sessions (preserved or
  reset on identity?)
- fixture / demo / production source tagging on every cand_NNN

Without these, L2 cannot ever be non-empty regardless of how
many demos pass.

### §18.8 What §18 does NOT claim

- That non-primitive entities should be removed from the dispatch
  table.  They remain operationally critical; the reclassification
  is ontological, not engineering.
- That the bootstrap is "small."  L0 + L1 + L3 + L4 are large.
  Only L2 — substrate-discovered — is small (currently empty).
- That cycle 35 is the immediate next cycle by default.  It is
  the proposed next cycle iff the team agrees that populating L2
  is the right priority before adding more mechanism over an
  empty L2.
- That the engineering Tier 1 / Tier 2 separation in
  `CLAIMS.md` should change.  §18 adds a parallel ontological
  taxonomy, not a replacement.

### §18.9 Cross-references

- `examples/PREDICTIONS-178-alphabet-archaeology.md` — pre-reg
- `RESULTS-178-bootstrap-alphabet-archaeology.md` — bootstrap audit
- `RESULTS-179-substrate-discovered-alphabet.md` — L2 audit
  (count = 0)
- `CLAIMS.md` — Ontological Classification section (mirror)
- `docs/CYCLE-35-PROPOSAL-persistence.md` — forward design
- `attestations/ledger.txt` — pre-reg attestation log
- User spec 2026-05-24 — bootstrap-vs-discovered separation;
  no lineage no discovery; L2 empty
