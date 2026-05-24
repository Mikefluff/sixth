# Demo 160 — Pre-Registered Predictions (cycle 30)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Scope: NARROW (auto-decompose with dependency-cascade safety)

Cycle 30 tests ONE thing: **can Sixth retire a stale primitive
automatically WITHOUT killing dependent active laws?**

Cycle 30 is NOT:
- a test of cognition or substrate-of-meaning
- a fully automatic mining-and-pruning loop (auto-MINING already done
  in cycle 27; AUTO-DECOMPOSE is the symmetric exit, not a full
  evolutionary loop)
- a claim that the dependency graph is correct in a category-theoretic
  sense (it is a usage graph: `A depends-on B` iff B's expansion
  contains a call to A)
- a model of ecological co-evolution (the analogy is rhetorical;
  the gate is bookkeeping)

Cycle 30 IS:
- the automation layer over cycle 29 decompose: `NEW-EPOCH` now MAY
  invoke `DECOMPOSE-PRIMITIVE` on demotion-candidate cands, but only
  after passing the **cascade-safety gate**
- the **dependency-aware** invariant: a primitive that another active
  primitive structurally depends on cannot be auto-decomposed even if
  its local momentum is negative
- the symmetric counterpart to cycle 28 generalization: cycle 28
  protects laws at entry (`PROMOTE-STABLE` gate); cycle 30 protects
  the dependency closure at exit (`AUTO-DECOMPOSE` gate)

---

## Primary claim

> A `'demotion-candidate` primitive is auto-decomposed by
> `NEW-EPOCH` only when the **dependency-cascade safety predicate**
> holds:
>
> ```
> auto_decompose_safe(cand) :=
>   local_momentum(cand) < -STALE_TOLERANCE
>   AND no_active_dependent_with_positive_momentum(cand)
> ```
>
> If `auto_decompose_safe(cand)` is true, cycle 30 performs the
> same operation cycle 29 exposes manually: removes cand from
> the active dictionary, preserves expansion in `_cand-preserved-bodies`,
> mutates `law_hash`, leaves `world_hash` unchanged, transitions
> status to `'decomposed`.
>
> If `auto_decompose_safe(cand)` is false because of an active
> dependent with positive momentum, status transitions to
> `'dependency-held` (new status; protected-stale) instead of
> `'decomposed`. The primitive stays in the active dictionary,
> still callable, but flagged as "kept alive only by dependents."
>
> A `RESTORE-PRIMITIVE` on an auto-decomposed cand whose dependent
> has since broken (because its calls into the missing cand now
> fault) restores BOTH: the primitive and its dependent's working
> state. This is the **cascade restore** half.

---

## Implementation contract (cycle 30B will conform)

### Dependency graph

Maintained in env-memory as a derived index:

```
_cand-deps   alist (cand-sym . set-of-callers)
             A entry `(B . #{C D})` means C and D's expansion
             contains a call to B; conversely C depends-on B.
```

Built/refreshed lazily: on each `COMMIT-PRIMITIVE` and on each
`DECOMPOSE-PRIMITIVE`/`RESTORE-PRIMITIVE`, the index is rebuilt
from `_cand-bodies` by scanning each body's opcode vector for
calls to other cands.

`dependents_of(cand)` := `lookup(_cand-deps, cand)`, filtered to
those whose `CAND-STATUS` ∈ {`'stable-active`, `'stale`,
`'dependency-held`}.

`has_positive_dependent_momentum(cand)` :=
`∃ d ∈ dependents_of(cand). law_momentum(d) > MOMENTUM_STALE_TOLERANCE`.

### New status: `'dependency-held`

Semantically: "would have been auto-decomposed this epoch, but a
dependent is keeping it alive." Behaves like `'stable-active` for
dispatch purposes (callable, body in active dict) but is flagged
in `CAND-STATUS` and may auto-decompose in a later epoch if the
dependent later loses positive momentum.

Transitions IN: from `'demotion-candidate` when AUTO-DECOMPOSE
gate fails due to active dependents.

Transitions OUT:
- To `'decomposed` (next NEW-EPOCH, if dependents are no longer
  positive-momentum AND local momentum still negative)
- To `'stable-active` (next NEW-EPOCH, if local momentum recovers
  above STALE_TOLERANCE — promotion back through normal channel)

### Modified `NEW-EPOCH` semantics

After cycle 29's per-cand momentum computation and status transition,
add a second pass:

```
for each cand with status='demotion-candidate:
    if has_positive_dependent_momentum(cand):
        status → 'dependency-held
    else:
        auto-invoke DECOMPOSE-PRIMITIVE on cand
        # status → 'decomposed
        # law_hash mutates
        # world_hash unchanged
        # body preserved in _cand-preserved-bodies

for each cand with status='dependency-held:
    if local_momentum(cand) > MOMENTUM_STALE_TOLERANCE:
        status → 'stable-active
    elif not has_positive_dependent_momentum(cand):
        if local_momentum(cand) < -STALE_TOLERANCE:
            auto-invoke DECOMPOSE-PRIMITIVE on cand
        else:
            status → 'stale
```

### Cascade restore

`RESTORE-PRIMITIVE` on a `'decomposed` cand additionally triggers a
**dependent walk**: for each cand `d` that had `cand` in its
expansion at the time of decompose (stored in
`_cand-decompose-snapshot`), if `d`'s `CAND-STATUS` ∈
{`'stale`, `'demotion-candidate`, `'dependency-held`} because its
calls to `cand` were faulting, attempt to advance `d` back to
`'stable-active` on the next `NEW-EPOCH`. Cycle 30 does NOT
auto-promote `d`; it only restores callability so the dependent's
next epoch can earn positive momentum.

### New Tier 1 primitives

```
AUTO-DECOMPOSE-SAFE?  ( cand -- 0|1 )  predicate: does cascade-safety
                                       hold for cand right now?
CAND-DEPENDENTS       ( cand -- list ) list of currently-active
                                       cands whose expansion contains
                                       a call to cand
LAW-DEPENDS-ON?       ( cand-a cand-b -- 0|1 )  does cand-a's expansion
                                                contain a call to cand-b?
```

`DECOMPOSE-PRIMITIVE` itself is unchanged from cycle 29 (still
gated on `'demotion-candidate`). Cycle 30 adds the auto-invocation
path through `NEW-EPOCH` and the cascade restore path through
`RESTORE-PRIMITIVE`.

### Frozen hyperparameters (cycle 30 adds none)

All cycle 29 thresholds carry over unchanged:

```
MOMENTUM_NEGATIVE_THRESHOLD = 2
MOMENTUM_STALE_TOLERANCE    = 1
MOMENTUM_HISTORY_WINDOW     = 3
```

Cycle 30 introduces no new tunable hyperparameter. The
cascade-safety predicate is structural (existence quantifier over
dependents), not threshold-tuned. This is intentional: cycle 30
must not smuggle in a "dependent strength multiplier" that we'd
then have to defend.

---

## Demo 160 — happy auto-decompose

### Setup
- Reuse cycle 29 demo 158 promotion flow: discover, INDUCE, COMMIT,
  HELD-OUT pass, PROMOTE-STABLE → status `'stable-active`.
- This cand has NO dependents (single-level primitive, like cycle 29).

### Lifecycle
- Phase 1: productive epoch (6 uses, m=+9, status stays stable-active)
- Phase 2: idle epoch (m=-3, status → stale)
- Phase 3: second idle epoch (m=-3, status → demotion-candidate)
- Phase 4: third NEW-EPOCH with no dependents
  - `auto_decompose_safe(cand_001)` = TRUE (no active dependents)
  - AUTO-DECOMPOSE invoked by NEW-EPOCH (not manually)
  - law_hash mutates; world_hash unchanged
  - status → `'decomposed`
  - body preserved in `_cand-preserved-bodies`

### Pass conditions (demo 160)

| pass | condition |
|------|-----------|
| `c-1` initial promote succeeds | status='stable-active after PROMOTE-STABLE |
| `c-2` reaches demotion-candidate by epoch 3 | status='demotion-candidate after phase 3 |
| `c-3` AUTO-DECOMPOSE-SAFE? returns 1 | predicate true when no active dependents |
| `c-4` auto-decompose happens on NEW-EPOCH | status='decomposed after phase 4 NEW-EPOCH (no manual DECOMPOSE) |
| `c-5` law_hash mutated by auto-decompose | law_hash differs from pre-decompose |
| `c-6` world_hash unchanged by auto-decompose | world_hash before/after equal |
| `c-7` preserved body recoverable | RESTORE-PRIMITIVE returns status='stable-active and law_hash returns |

---

## Demo 161 — negative: active dependent blocks auto-decompose

### Setup
- Promote TWO cands:
  - `cand_001` = (bi-edge drop) — base cand, length 2
  - `cand_002` = (cand_001 NODES drop) — depends on cand_001, length 3
- Both reach `'stable-active`.

### Lifecycle
- Phase 1-3: use cand_002 productively each epoch (above break-even),
  do NOT use cand_001 directly.
  - cand_002 momentum positive (it earns its own reuse)
  - cand_001 local momentum negative (no direct uses), BUT each
    cand_002 call internally dispatches through cand_001
  - **CRITICAL**: the dispatch hook for cand_001 counts the internal
    call as a use only if dispatched as a top-level token, NOT as a
    nested expansion call. This makes cand_001's LOCAL momentum
    negative even though it is structurally load-bearing.
  - After phase 3: cand_001 status='demotion-candidate;
    cand_002 status='stable-active.
- Phase 4: NEW-EPOCH
  - `auto_decompose_safe(cand_001)` = FALSE
    (cand_002 is active dependent with positive momentum)
  - cand_001 status → `'dependency-held` (NOT decomposed)
  - cand_001 stays in active dictionary, still callable
  - law_hash unchanged
- Phase 5: stop using cand_002 for 3 idle epochs
  - cand_002 momentum goes negative; status → stale → demotion-candidate
  - cand_001 still 'dependency-held' (cand_002 not positive anymore)
- Phase 6: next NEW-EPOCH
  - cand_001: dependents no longer positive; local momentum still
    negative → AUTO-DECOMPOSE invoked → status='decomposed
  - cand_002 next epoch: dispatching cand_002 hits a missing
    cand_001 reference; cand_002 status moves toward stale.

### Pass conditions (demo 161)

| pass | condition |
|------|-----------|
| `n-1` both cands promote | both reach status='stable-active |
| `n-2` cand_001 hits demotion-candidate by epoch 3 | status='demotion-candidate |
| `n-3` AUTO-DECOMPOSE-SAFE? returns 0 for cand_001 | dependent cand_002 has positive momentum |
| `n-4` cand_001 goes to dependency-held NOT decomposed | status='dependency-held after phase 4 NEW-EPOCH |
| `n-5` cand_001 still callable | direct invocation of cand_001 still dispatches |
| `n-6` law_hash unchanged | no decompose happened in phase 4 |
| `n-7` after dependent fades, auto-decompose proceeds | status='decomposed after phase 6 NEW-EPOCH |

---

## Demo 162 — cascade restore reactivates dependent

### Setup
- Same two cands as demo 161 (cand_001, cand_002 with cand_002
  depending on cand_001).
- Force cand_001 to `'demotion-candidate` AND wait for cand_002 to
  also become non-positive (so auto-decompose can fire).
- Auto-decompose cand_001.
- cand_002's next call faults (cand_001 missing).

### Lifecycle
- Phase 1: setup as in demo 161, but accelerate cand_002 fade so
  both cands reach decomposable state.
- Phase 2: NEW-EPOCH triggers auto-decompose of cand_001.
- Phase 3: attempt to use cand_002 — call into missing cand_001
  raises an error caught by `try-dispatch-cand!` rollback. cand_002
  status moves to `'stale` (recent_failure_count += 1 per attempt).
- Phase 4: `RESTORE-PRIMITIVE cand_001`
  - cand_001 status → `'stable-active`
  - law_hash returns to pre-decompose value
  - cascade walk identifies cand_002 had cand_001 in its expansion
    at decompose time
  - cand_002 callability restored (its body still references cand_001
    by name — now resolvable again).
- Phase 5: use cand_002 productively for an epoch.
  - cand_002 momentum recovers
  - NEW-EPOCH: cand_002 status → `'stable-active`

### Pass conditions (demo 162)

| pass | condition |
|------|-----------|
| `r-1` cand_001 auto-decomposed | status='decomposed via NEW-EPOCH, not manual |
| `r-2` cand_002 calls fault while cand_001 gone | call-error counter incremented; stack rolled back |
| `r-3` RESTORE cand_001 succeeds | cand_001 status='stable-active; law_hash restored |
| `r-4` cand_002 callable after restore | direct invocation no longer faults |
| `r-5` cand_002 recovers to stable-active | after one productive epoch + NEW-EPOCH, status='stable-active |
| `r-6` law_hash matches pre-decompose snapshot | full round-trip integrity |

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. No new tunable hyperparameter introduced. The cascade-safety
   predicate is structural (`∃ dependent. positive momentum`).
3. `DECOMPOSE-PRIMITIVE` signature unchanged from cycle 29. Cycle 30
   adds only the auto-invocation path and the cascade-restore path.
4. `'dependency-held` is the only new status. It is callable but
   flagged. No silent demotion / no silent promotion.
5. Dependency graph is built from opcode-vector scan of cand bodies,
   not from runtime tracing. Static, deterministic, rebuildable.
6. AUTO-DECOMPOSE fires ONLY inside `NEW-EPOCH`. No mid-program
   surprise removal of laws.
7. Cascade restore is one-level only in cycle 30 (`RESTORE cand_001`
   makes cand_002 callable again; it does NOT recursively restore
   cand_003 if cand_003 depended on cand_002). Multi-level cascade
   is DEFERRED to cycle 31+.
8. Dependent dispatch counting: a call to cand_002 that internally
   dispatches cand_001 does NOT count as a top-level use of cand_001
   for momentum purposes. This is the design choice that makes
   cycle 30 nontrivial (otherwise dependents would inflate the
   protected primitive's local momentum and the gate would never
   fire). The cascade gate replaces direct-momentum inheritance.
9. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25-29 commits as frozen reference; META-SEMANTICS
      v2.1 §17 energy accounting; cycle 29 PREDICTIONS-158.md
      lifecycle baseline; user spec (2026) 2026-05-23 dependency-aware
      decompose
- [x] Rule 3: deterministic (NEW-EPOCH-driven; static dependency graph)
- [x] Rule 4: pass / fail conditions partition outcome space across
      three demos (happy / blocked / cascade-restore)
- [x] Rule 5: known-input lifecycle test (NOT empirical signal)
- [x] Rule 6: regression count update post-result
- [x] Rule 7: demo 161 falsifies "always auto-decompose when local
      momentum negative" (negative control); demo 162 falsifies
      "dependent loss is permanent" (negative control on restore)
- [x] Rule 8: scope = 3 demos, 3 new primitives + 1 new status,
      no new hyperparameters
- [x] Rule 9: attestation pending

---

## What cycle 30 does NOT claim

- It does NOT claim the dependency graph is semantically correct in
  a categorical / type-theoretic sense. It is a USAGE graph derived
  from opcode bodies.
- It does NOT claim multi-level cascade restoration. Only one-level
  (a → b). Multi-level deferred.
- It does NOT claim AUTO-DECOMPOSE is "ecologically wise" — only
  that it respects the structural safety predicate.
- It does NOT claim `'dependency-held` is biologically meaningful.
  The status is operational: "would-have-decomposed but a structural
  dependent saved it this round."
- It does NOT introduce reward/punishment dynamics for dependents
  (cycle 30 does NOT transfer dependent's positive momentum to
  the protected cand's own balance — would muddle the gate).

It claims only: **a stale primitive that has at least one
positive-momentum active dependent cannot be auto-decomposed;
when the dependents fade, auto-decompose proceeds; RESTORE returns
both the primitive and its dependent's callability.**

If demo 160 passes (auto-decompose fires when safe), demo 161 passes
(active dependent blocks auto-decompose), and demo 162 passes
(cascade restore reactivates dependent), then law ecology is
operational.

---

## References

- META-SEMANTICS.md v2.1 §17 (commit 67cab83) — energy accounting
- Cycle 26 (commit 2e1edbf) — energy gate (entry)
- Cycle 28 (commit aa5842d) — held-out generalization (entry)
- Cycle 29 (commit 41d548c) — manual decompose / restore baseline
- User spec (2026) 2026-05-23 — dependency-aware AUTO-DECOMPOSE
  with `'dependency-held` status; cascade restore
- Lakatos (1970) — protective belt: cycle 30 is the dependency-aware
  exit gate symmetric to cycle 28's dependency-blind entry gate
