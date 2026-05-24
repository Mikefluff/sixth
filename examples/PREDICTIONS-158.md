# Demo 158 — Pre-Registered Predictions (cycle 29)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Scope: NARROW (law metabolism)

Cycle 29 tests ONE thing: **can Sixth retire a stable primitive
that stops paying its carrying cost?**

Cycle 29 is NOT:
- a test of cognition or substrate-of-meaning
- a test of automatic decomposition triggering (humans / tests still
  invoke DECOMPOSE-PRIMITIVE explicitly — auto-decompose is cycle 30+)
- a model of biological metabolism (the analogy is rhetorical;
  formula is bookkeeping)

Cycle 29 IS:
- the lifecycle layer: stable-active → stale → demotion-candidate
  → decomposed, driven by `law_momentum`
- the **non-stagnation** invariant: a law that stops paying its
  carrying cost cannot stay stable-active indefinitely
- the symmetric counterpart to demo 28 — gate at the EXIT of
  stable-active, not just the entry

---

## Primary claim

> A stable-active primitive transitions to `'demotion-candidate`
> when its `law_momentum` is negative across `MOMENTUM_NEGATIVE_THRESHOLD`
> consecutive epochs.  Only `'demotion-candidate` primitives can be
> `DECOMPOSE-PRIMITIVE`d.  Decomposition removes the primitive from
> the active dictionary, mutates `law_hash`, preserves the expansion
> body for potential `RESTORE-PRIMITIVE` rollback, and leaves
> `world_hash` unchanged.

---

## Implementation contract (cycle 29B will conform)

### Per-primitive lifecycle fields

Maintained in env-memory (extending cycle 25E energy counters):

```
_cand-recent-uses          alist (cand-sym . recent_use_count)
_cand-recent-reuse-gain    alist (cand-sym . recent_reuse_gain)
_cand-recent-failures      alist (cand-sym . recent_failure_count)
_cand-momentum-history     alist (cand-sym . list-of-recent-momenta)
_epoch-counter             box int (starts at 0)
```

`carry_cost(cand) = expansion_length(cand)` — constant per cand,
derived on demand from `_cand-bodies`.

`law_momentum(cand)` = recent_reuse_gain - carry_cost -
                       recent_failure_count

### Frozen hyperparameters

```
MOMENTUM_NEGATIVE_THRESHOLD = 2   epochs of negative momentum
                                   before status → 'demotion-candidate
MOMENTUM_STALE_TOLERANCE    = 1   |momentum| ≤ this counts as 'stale
MOMENTUM_HISTORY_WINDOW     = 3   last K momenta kept for analysis
```

### Status transitions (after `NEW-EPOCH`)

Per stable-active or stale or demotion-candidate primitive:

```
m = law_momentum(cand)  computed for the EPOCH that just ended
push m onto momentum_history (truncate to WINDOW)

if m > MOMENTUM_STALE_TOLERANCE:
    status → 'stable-active   (or stays so)
elif abs(m) ≤ MOMENTUM_STALE_TOLERANCE:
    status → 'stale
else:  (m negative beyond stale tolerance)
    if last MOMENTUM_NEGATIVE_THRESHOLD momenta all < -STALE_TOLERANCE:
        status → 'demotion-candidate
    else:
        status → 'stale (single bad epoch isn't enough)
```

Reset counters: recent_use_count, recent_reuse_gain,
recent_failure_count all reset to 0 on `NEW-EPOCH`.

### New Tier 1 primitives

```
NEW-EPOCH               ( -- )        advance epoch counter,
                                      apply transitions to all active
                                      primitives, reset recent counters
LAW-MOMENTUM            ( cand -- n ) compute current epoch momentum
                                      (no transition trigger)
MARK-STALE              ( cand -- )   force status → 'stale (testing)
DEMOTE-PRIMITIVE        ( cand -- )   force status → 'demotion-candidate
                                      (testing; raises if cand status
                                      not in {stable-active, stale})
DECOMPOSE-PRIMITIVE     ( cand -- )   remove from active dict;
                                      status → 'decomposed;
                                      law_hash mutates;
                                      requires status = 'demotion-candidate
RESTORE-PRIMITIVE       ( cand -- )   re-add to active dict from
                                      preserved body; status → 'stable-active;
                                      requires status = 'decomposed
```

### Carrying cost mechanic

`carry_cost(cand) = expansion_length(cand)`.

Each `NEW-EPOCH`: for each stable-active / stale primitive,
the carry cost is "deducted" from recent_reuse_gain in the
momentum computation.  No separate "balance" account — the
metabolism is the difference, not an accumulating deficit.

This is intentionally simple: a primitive used 0 times in an
epoch has momentum = -carry_cost (always negative).  Used N times
where N × (L-1) > L, momentum > 0.

Threshold use count for break-even per epoch:
- L=2: N × 1 > 2 → N ≥ 3
- L=3: N × 2 > 3 → N ≥ 2
- L=5: N × 4 > 5 → N ≥ 2

So a length-3 primitive needs to be used ≥2 times per epoch
to maintain stable-active status.

---

## Demo 158 — happy decomposition flow

### Setup
- Reuse cycle 28 demo 155 setup: discover (MARK MARK bi-edge) via
  DETECT-MOTIF-AUTO, INDUCE, commit (cycle 26), HELD-OUT pass +
  PROMOTE-STABLE → status `'stable-active`.
- This is the input state for cycle 29.

### Lifecycle phases (each `NEW-EPOCH` advances 1 epoch)

**Phase 1 — productive epoch:**
- Use cand_001 6 times (above break-even)
- NEW-EPOCH
- Momentum = 6×2 - 3 - 0 = +9 → status stays `'stable-active`

**Phase 2 — first idle epoch:**
- No use of cand_001
- NEW-EPOCH
- Momentum = 0 - 3 - 0 = -3 < -STALE_TOLERANCE → potential demotion
  but only 1 epoch of negative; status → `'stale`

**Phase 3 — second idle epoch:**
- No use of cand_001
- NEW-EPOCH
- Momentum = 0 - 3 - 0 = -3.  History has 2 consecutive negatives
  → status → `'demotion-candidate`

**Phase 4 — decompose:**
- DECOMPOSE-PRIMITIVE cand_001
- Word removed from active dictionary
- Status → `'decomposed`
- law_hash mutates
- world_hash unchanged

**Phase 5 — restore:**
- RESTORE-PRIMITIVE cand_001
- Word re-added from preserved body
- Status → `'stable-active`
- law_hash returns to pre-decomposition value

### Pass conditions (demo 158)

| pass | condition |
|------|-----------|
| `c-1` initial promote succeeds | status='stable-active after PROMOTE-STABLE |
| `c-2` productive epoch stays stable | after phase 1, status='stable-active |
| `c-3` single idle epoch → stale | after phase 2, status='stale |
| `c-4` second idle epoch → demotion-candidate | after phase 3, status='demotion-candidate |
| `c-5` decompose succeeds | DECOMPOSE-PRIMITIVE returns; status='decomposed |
| `c-6` law_hash mutated on decompose | law_hash differs from pre-decompose |
| `c-7` world_hash unchanged on decompose | world_hash before/after decompose equal |
| `c-8` restore succeeds | RESTORE-PRIMITIVE returns; status='stable-active |
| `c-9` law_hash restored | law_hash returns to pre-decompose value |
| `c-10` regression green (external) | full raco test passes |

---

## Demo 159 — negative: high-use primitive resists decomposition

### Setup
- Same initial promotion as demo 158 (status='stable-active).

### Lifecycle phases

**Phase 1-5 — productive epochs:**
- Each epoch: use cand_001 4 times (above break-even threshold of 2)
- NEW-EPOCH after each
- Momentum every epoch = 4×2 - 3 - 0 = +5 → status stays
  `'stable-active`

**Phase 6 — attempt forced demotion:**
- Try DEMOTE-PRIMITIVE — should succeed because cand is stable-active
  (DEMOTE allows {stable-active, stale} → demotion-candidate)
- Then DECOMPOSE-PRIMITIVE — succeeds (status is demotion-candidate)
- Then RESTORE-PRIMITIVE — succeeds
- Then 5 more productive epochs
- Status STAYS stable-active (high momentum survives)

### Pass conditions (demo 159)

| pass | condition |
|------|-----------|
| `nc-1` productive epoch stable | after each phase 1-5 NEW-EPOCH, status='stable-active |
| `nc-2` momentum positive each epoch | LAW-MOMENTUM > 0 in each productive phase |
| `nc-3` age doesn't trigger demotion | after 5 consecutive productive epochs, status remains stable |
| `nc-4` forced demote works | DEMOTE-PRIMITIVE explicit → status='demotion-candidate |
| `nc-5` post-restore productive resumes | after RESTORE + 5 more productive epochs, status='stable-active |

This validates: **age alone doesn't kill; negative energy momentum
kills**.

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. Hyperparameters MOMENTUM_NEGATIVE_THRESHOLD=2,
   MOMENTUM_STALE_TOLERANCE=1, MOMENTUM_HISTORY_WINDOW=3 fixed
   at this commit.  Modifications require deprecation cycle.
3. DECOMPOSE-PRIMITIVE requires status='demotion-candidate.
   No back-door.
4. RESTORE-PRIMITIVE requires status='decomposed.  Restores from
   preserved body in _cand-bodies (preserved even after decompose
   — body is removed from dict but kept in metadata for restore).
5. NEW-EPOCH resets ALL per-cand recent counters atomically.
6. Auto-decompose (without explicit DECOMPOSE-PRIMITIVE invocation)
   is DEFERRED to cycle 30+.  Cycle 29 only auto-transitions
   status; the actual decomposition is human/test-triggered.
7. Dependent-primitive cascade (when a decomposed primitive is
   used by another stable primitive) is DEFERRED to cycle 30+.
   Cycle 29 only has single-level primitives.
8. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25-28 commits as frozen reference; META-SEMANTICS
      v2.1 §17 energy accounting; user spec (2026) 2026-05-23
      lifecycle governance; Lakatos (1970) protective belt
- [x] Rule 3: deterministic given fixed seeds + NEW-EPOCH calls
- [x] Rule 4: pass / fail conditions partition outcome space
- [x] Rule 5: known-input lifecycle test (NOT empirical signal)
- [x] Rule 6: regression count update post-result
- [x] Rule 7: demo 159 falsifies age-based decomposition
      (negative control)
- [x] Rule 8: scope = 2 demos, 5 new primitives, fixed thresholds
- [x] Rule 9: attestation pending

---

## What cycle 29 does NOT claim

- It does NOT claim Sixth knows when to decompose (humans/tests
  invoke DECOMPOSE-PRIMITIVE).
- It does NOT claim the carry_cost formula is "right" — it mirrors
  expansion_length as a structurally honest first proxy.
- It does NOT claim automatic decomposition is safe (auto-trigger
  is cycle 30+).
- It does NOT model biological metabolism — the analogy is
  rhetorical; the formula is bookkeeping.

It claims only: **a stable primitive that stops paying its carrying
cost transitions to demotion-candidate after a frozen number of
negative-momentum epochs, and decomposition cleanly removes it
while preserving restorability.**

If demo 158 passes (lifecycle transitions work as specified)
and demo 159 passes (high-use primitive resists decomposition),
then law metabolism is operational.

---

## References

- META-SEMANTICS.md v2.1 §17 (commit 67cab83) — energy accounting
  formula; cycle 29 extends with momentum
- Cycle 26 (commit 2e1edbf) — energy gate active
- Cycle 28 (commit aa5842d) — stable promotion baseline
- User spec (2026) 2026-05-23 — energy momentum, not static
  balance; carry cost; decomposition not deletion
- Lakatos (1970) — research programme protective belt; a law
  retired without being "wrong" is a planned obsolescence event,
  not a falsification
