# Demo 171 — Pre-Registered Predictions (cycle 33)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
Initial attestation: sha256:769eb89726ab... (commit 8d64c7a).
Addendum re-attestation: see ledger row dated 2026-05-23 (commit 3a1b308+).

---

## CORE FORMULATION (binding, cycle-33-wide)

> Dependent momentum allocation is **carry-offset only, not profit
> inheritance**.  It can prevent decomposition but cannot make a
> primitive native-positive or allow it to subsidize others.

Every other commitment in this pre-reg is a corollary of this core.
If any cycle-33 mechanism violates this — by allowing a supported
cand to contribute to another's support_credit, by allowing support
to push m_native upward, or by allowing support_credit to exceed
LAW_CARRY in any aggregation order — it is a regression, not a feature.

---

## Addendum 2026-05-23 — Three-primitive momentum separation

The pre-reg originally specified two new inspection primitives
(`SUPPORT-CREDIT` and `DEPENDENCY-COUNT`).  Per user feedback before
implementation, cycle 33 instead exposes the full triplet so that
"native" and "effective" momentum are independently observable from
Sixth-level code:

```
MOMENTUM-NATIVE     ( cand -- n )   m_native = reuse - carry - fails - inflation
                                    (alias for LAW-MOMENTUM; the canonical
                                    name going forward.  LAW-MOMENTUM remains
                                    callable as a back-compat alias.)
SUPPORT-CREDIT      ( cand -- n )   support_credit, bounded by LAW_CARRY
MOMENTUM-EFFECTIVE  ( cand -- n )   m_eff = m_native + support_credit
```

This makes the carry-offset semantics machine-checkable: a demo can
assert that `MOMENTUM-NATIVE cand_X` is unchanged across any sequence
of dependent activity, because support only enters `MOMENTUM-EFFECTIVE`.
"Native" momentum is intrinsic to the cand; "effective" is what the
status machine consults for transitions.

Specifically, demo 171 (and all subsequent demos that probe support)
will assert:
- `MOMENTUM-NATIVE cand_001` returns the same value with or without
  cand_002 being active, dispatched, or supportive.
- Status transitions of cand_001 (via Pass B in NEW-EPOCH) depend on
  `MOMENTUM-EFFECTIVE`, not `MOMENTUM-NATIVE`.

This protects against the future failure mode where someone could
quietly redefine momentum to inherit dependent surplus.  The separation
is now in the public surface area; any drift would be observable
externally.

---

## Scope: Dependent Momentum Allocation as CARRY OFFSET

Cycle 33 adds a single mechanism: a primitive `A` whose active
dependent `B` is itself natively-positive may apply a bounded
**support credit** that offsets `A`'s carry cost in the per-epoch
momentum equation.  The credit is bounded such that `A` can be
KEPT ALIVE by `B` but cannot be MADE PROFITABLE.  The credit is
**rented per-epoch, not owned across epochs**.

This is explicitly NOT a profit-transfer mechanism.  If `B` is wildly
positive, `A` does NOT inherit any of `B`'s surplus beyond the bound
`LAW_CARRY(A)`.  This prevents the parasitic-economy failure mode
where one productive cand sustains an arbitrarily large set of
non-productive dependents.

Cycle 33 is NOT:
- A claim about "fair distribution" — the split formula
  `floor(m_pos(B) / dep_count(B))` is the simplest defensible
  apportionment, not an optimum
- A change to held-out evaluation, inflation rate, profile semantics,
  or any cycle 28-32 mechanism (those remain identical)
- An introduction of cross-epoch credit accumulation — support is
  RECOMPUTED EVERY EPOCH; there is no savings account
- A modification of `'dependency-held` (cycle 32 chain protection
  remains the LAST-RESORT mechanism for cands that descend through
  demotion-candidate without sufficient support)

Cycle 33 IS:
- The **carry-offset** invariant: `support_credit(A) ≤ LAW_CARRY(A)`,
  full stop, no exceptions, no aggregation across multiple supporters
  beyond this cap
- The **no-profit-inheritance** invariant: only cands with
  `m_native > STALE_TOLERANCE` count as supporters; supported cands
  do NOT themselves propagate support
- The **rented-not-owned** invariant: `_support-credit` is
  recomputed from current observed_deps + current m_native at every
  NEW-EPOCH; no persistence
- The **runtime-observed** requirement (inherited from cycle 32):
  static dependency alone gives zero credit

---

## Three new mechanism elements

### Element A — Per-supporter contribution

For each active dependent `B` of `A`:
```
contribution(B, A) :=
  if not observed_dep(B, A):                  0
  elif m_native(B) <= STALE_TOLERANCE:        0
  else:                                       floor(m_native(B) / dep_count(B))
```

where `dep_count(B)` is the count of DISTINCT cand symbols in `B`'s
motif body.  Multiple occurrences of the same cand do not multiply
the count; this prevents `B = (X X X X X)` from inflating its
dependency to dilute support to X arbitrarily.

### Element B — Capped aggregation

```
support_credit(A) := min(LAW_CARRY(A),
                          sum over B in active_dependents_of(A): contribution(B, A))
```

The bound `LAW_CARRY(A)` enforces the no-profit-inheritance invariant:
the credit can cancel A's structural carry but cannot exceed it.

### Element C — Status transition with support

In Pass B of NEW-EPOCH:
```
m_native  = compute_momentum_for(A)            # cycle 31 formula unchanged
support   = support_credit(A)                  # cycle 33 new
m_eff     = m_native + support

if m_native > STALE_TOLERANCE:
    A.status = 'stable-active                  # natively earning, support irrelevant

elif support > 0 and m_eff >= -STALE_TOLERANCE:
    A.status = 'dependency-supported           # NEW (cycle 33): support kept it
                                                # in/above the safe zone

elif abs(m_eff) <= STALE_TOLERANCE:
    A.status = 'stale                          # neither natively earning nor supported

elif m_eff < -STALE_TOLERANCE:
    # Check m_native history (intrinsic; support is not history)
    last_n = history[:MOMENTUM_NEGATIVE_THRESHOLD]
    if length(last_n) == N and all(m < -STALE_TOLERANCE for m in last_n):
        A.status = 'demotion-candidate         # cycle 32 Pass C handles next
    else:
        A.status = 'stale
```

`'dependency-supported` does NOT trigger Pass C — that's only for
`'demotion-candidate`.  Support saves cands EARLIER in the gradient,
before they reach the demotion gate.

History tracks `m_native`, not `m_eff`.  This enforces "rented not
owned" — chronic non-productivity still accumulates in the history,
so a cand permanently surviving via support could (eventually, with
weakened support) still descend to demotion-candidate.

---

## New env-memory key

```
_support-credit   alist (cand-sym . int)
                  Recomputed at end of Pass A (after history push,
                  before Pass B status transitions).  Reset on
                  NEW-EPOCH along with other recent counters.
```

This key is INSPECTION-friendly so demos can read it via
`SUPPORT-CREDIT ( cand -- n )` primitive.

## New Tier 1 primitives (4, per addendum)

```
MOMENTUM-NATIVE    ( cand -- n )    m_native (intrinsic, no support).
                                    Canonical alias for LAW-MOMENTUM.
                                    Cycle 33 demos use this name to
                                    make carry-offset semantics explicit.

SUPPORT-CREDIT     ( cand -- n )    current support_credit for cand
                                    (computed at end of Pass A; reset
                                    at end of NEW-EPOCH).

MOMENTUM-EFFECTIVE ( cand -- n )    m_eff = m_native + support_credit.
                                    The value Pass B status transition
                                    branches consult.

DEPENDENCY-COUNT   ( cand -- n )    distinct-cand count of cand's motif
                                    (e.g., for motif (A A B): 2;
                                    for (A B C D): 4)
```

All four are INSPECTION-OPS.

## New status (1)

```
'dependency-supported   carry offset applied; cand kept above
                        decomposition threshold via support_credit;
                        callable; participates in metabolism; in
                        STABLE-WORD-STATUSES (counted in STABLE-LAW-HASH)
```

`SANDBOX-STATUSES` unchanged.  `ACTIVE-METAB-STATUSES` extended to
include `'dependency-supported`.

## NO new hyperparameter

The `floor(m / dep_count)` split is structural.  The `LAW_CARRY(A)`
cap is structural.  No new tuning knob.

---

## Behavioral change to existing demos (acknowledged)

Cycle 33 introduces `'dependency-supported`, which CHANGES the
expected status of some cands in cycle 32 demos that previously
reached `'dependency-held` via Pass C.  Specifically:

| Demo | cand | cycle 32 expected | cycle 33 expected | reason |
|------|------|-------------------|--------------------|--------|
| 161 | cand_001 phase 2 | 'dependency-held | 'dependency-supported | cand_002 natively positive; support_credit > 0 → caught in Pass B before reaching demotion-candidate |
| 162 | cand_001 (during build) | 'dependency-held intermediate | 'dependency-supported | same |
| 165 | cand_001 phase 2 | 'dependency-held | 'dependency-supported | same |
| 167 | cand_002 phase 2 | 'dependency-held | 'dependency-supported | cand_003 natively positive supports cand_002 directly |
| 167 | cand_001 phase 2 | 'dependency-held | **'dependency-held UNCHANGED** | cand_002 NOT natively positive (m_native=-3) → contributes 0 → cand_001 still descends to demotion-candidate → Pass C transitive chain catches |
| 169 | cand_002 build phase | 'dependency-held | 'dependency-supported | same as 167 |
| 169 | cand_001 build phase | 'dependency-held | **'dependency-held UNCHANGED** | same as 167 |

The cycle 32 invariants (cycle 32 transitive load-bearing, anti-immortal-
cycle) remain TRUE.  The labels shift because the new earlier
intervention catches some cases before they reach the cycle-32 gate.

Demos 158, 159, 160, 163, 164, 166, 168, 170 unaffected (their cand_001
in idle phases has no natively-positive supporter, so support_credit=0,
status path identical to cycle 32).

The four affected demos (161, 162, 165, 167, 169) will be UPDATED as part
of cycle 33 implementation, with status labels switched to the new
expected values.  Failure to update them constitutes a regression
under cycle 33's pre-reg.

---

## Implementation contract (cycle 33B will conform)

### env-memory key (1 new)

```
_support-credit   box of alist (cand-sym . int)
                  Populated at end of Pass A in NEW-EPOCH.
                  Reset to '() at end of NEW-EPOCH (rented, not owned).
```

### runtime.rkt changes

- Add `MEM_SUPPORT_CREDIT '_support-credit` key
- Initialize in install-meta-runtime!
- Add accessor `support-credit-of`
- Add `'dependency-supported` to `ACTIVE-METAB-STATUSES`
- Add `'dependency-supported` to `STABLE-WORD-STATUSES`
- Export the new symbols

### tier1.rkt changes

- Add `dep-count-of` helper: distinct cands in motif
- Add `compute-support-credit-for` helper: per-cand calculation
- Modify `prim-new-epoch`:
  * After Pass A history push, compute support_credit for all active cands.
    Store in `_support-credit` alist.
  * Pass B uses m_eff = m_native + support for status transition (new
    branches for `'dependency-supported`)
  * Pass C unchanged from cycle 32
  * At end, reset `_support-credit` to '()
- Add primitives `SUPPORT-CREDIT`, `DEPENDENCY-COUNT`
- Register in TIER1-TABLE
- Update INSPECTION-OPS list (runtime.rkt) with the two new inspections

### NO VM changes

Cycle 32's VM hook is sufficient.  Cycle 33 only adds bookkeeping at
the meta-runtime level.

---

## Demo 171 — support-offset (happy)

### Setup
- Promote cand_001 = (MARK drop), L=2
- Promote cand_002 = (cand_001 NODES drop), L=3
- Baseline NEW-EPOCH

### Lifecycle
- Phase 1: drive cand_002 productively (4 dispatches).
  - cand_002 m_native = 4×2 - 3 - 0 - 1 = +4.
  - cand_001 m_native = 0 - 2 - 0 - 1 = -3.
  - support_credit(cand_001) = min(LAW_CARRY=2, floor(4/1)) = 2.
  - m_eff(cand_001) = -3 + 2 = -1.
  - Pass B for cand_001: m_native ≤ STALE_TOL; support>0; m_eff>=-STALE_TOL
    → 'dependency-supported.
  - Pass B for cand_002: m_native=+4 > STALE_TOL → 'stable-active.

### Pass conditions

| pass | condition |
|------|-----------|
| `o-1` | both initial 'stable-active |
| `o-2` | SUPPORT-CREDIT cand_001 = 2 after phase 1 (within bound LAW_CARRY=2) |
| `o-3` | DEPENDENCY-COUNT cand_002 = 1 (only cand_001 distinct in motif) |
| `o-4` | MOMENTUM-NATIVE cand_001 = -3 (unchanged by support — carry-offset invariant) |
| `o-5` | MOMENTUM-EFFECTIVE cand_001 = -1 (= native + support = -3 + 2) |
| `o-6` | after phase 1 NE: cand_001 status = 'dependency-supported (NEW status) |
| `o-7` | after phase 1 NE: cand_002 status = 'stable-active |
| `o-8` | cand_001 still callable (TRY-DISPATCH = 1 after NE) |

---

## Demo 172 — no-profit-inheritance (cap enforced)

### Setup
- Promote cand_001 (L=2) and cand_002 (L=3) like demo 171.

### Lifecycle
- Phase 1: drive cand_002 HEAVILY (10 dispatches).
  - cand_002 m_native = 10×2 - 3 - 0 - 1 = +16. Huge surplus.
  - cand_001 supporter contribution = floor(16/1) = 16.
  - support_credit(cand_001) = min(LAW_CARRY=2, 16) = **2** (cap).
  - m_eff(cand_001) = -3 + 2 = -1.

### Pass conditions

| pass | condition |
|------|-----------|
| `p-1` | both promoted |
| `p-2` | SUPPORT-CREDIT cand_001 = 2 (capped, NOT 16) |
| `p-3` | LAW-CARRY cand_001 = 2 (the cap) |
| `p-4` | after NE: cand_001 status = 'dependency-supported (NOT 'stable-active!) |
| `p-5` | after NE: cand_002 status = 'stable-active (surplus stays with B) |

---

## Demo 173 — multi-dependency-split

### Setup
- Promote cand_001 (L=2), cand_002 (L=2), AND cand_003 (L=3) where:
  - cand_003 = (cand_001 cand_002 NODES) — depends on BOTH cand_001 AND cand_002
  - dep_count(cand_003) = 2

### Lifecycle
- Phase 1: drive cand_003 productively (e.g., 4 dispatches).
  - cand_003 m_native = 4×2 - 3 - 0 - 1 = +4.
  - For each of cand_001, cand_002:
    - contribution from cand_003 = floor(4/2) = 2 (split between two deps)
    - capped at LAW_CARRY = 2.
    - support_credit = 2.
  - m_eff(cand_001) = -3 + 2 = -1. → 'dependency-supported.
  - m_eff(cand_002) = -3 + 2 = -1. → 'dependency-supported.

### Pass conditions

| pass | condition |
|------|-----------|
| `d-1` | all three promoted |
| `d-2` | DEPENDENCY-COUNT cand_003 = 2 (distinct cands in motif) |
| `d-3` | SUPPORT-CREDIT cand_001 = 2 (split contribution, capped) |
| `d-4` | SUPPORT-CREDIT cand_002 = 2 (split contribution, capped) |
| `d-5` | after NE: cand_001 = 'dependency-supported |
| `d-6` | after NE: cand_002 = 'dependency-supported |
| `d-7` | after NE: cand_003 = 'stable-active |

---

## Demo 174 — dead-dependent gives no credit

### Setup
- Same as demo 171.

### Lifecycle
- Phase 1: drive cand_002 to make it 'stable-active, then several idle
  epochs to push it into 'stale.
- Phase 2: idle epoch — cand_002 NOT productive (status='stale or worse).
  - cand_002 m_native ≤ STALE_TOL → contribution to cand_001 = 0.
  - support_credit(cand_001) = 0.
  - cand_001 m_eff = -3.
  - cand_001 descends through 'stale → 'demotion-candidate (history).
  - Pass C: has-recent-load-bearing?(cand_001) — cand_002 not observed nested-calling cand_001 this epoch (cand_002 idle) → FALSE → auto-decompose.

### Pass conditions

| pass | condition |
|------|-----------|
| `dd-1` | cand_002 in 'stale or worse by end of idle phase |
| `dd-2` | SUPPORT-CREDIT cand_001 = 0 (dead dependent) |
| `dd-3` | cand_001 eventually 'decomposed (no support could save) |

---

## Demo 175 — cycle without anchor gives no mutual credit

### Setup
- Reuse demo 170's REBIND-CAND-BODY cycle construction:
  cand_001 ↔ cand_002 static cycle, no external positive driver.

### Lifecycle
- Phase 1+: idle.  Neither natively positive.
  - contribution(cand_001 ↔ cand_002, ...) = 0 (neither m_native > STALE_TOL).
  - support_credit for both = 0.
  - m_eff = m_native = -3 (or -4) for both.
  - Both descend to demotion-candidate.
  - Pass C: cycle 32 visited-set DFS → FALSE → auto-decompose.

### Pass conditions

| pass | condition |
|------|-----------|
| `cy-1` | cycle established via REBIND (LAW-DEPENDS-ON? both = 1) |
| `cy-2` | SUPPORT-CREDIT cand_001 = 0 (no positive in cycle) |
| `cy-3` | SUPPORT-CREDIT cand_002 = 0 (no positive in cycle) |
| `cy-4` | cand_001 → 'decomposed (cycle 32 visited-set + cycle 33 no support) |
| `cy-5` | cand_002 → 'decomposed (same) |

---

## Demo 176 — runtime-observation required for support

### Setup
- Promote cand_001 (L=2), cand_002 (L=3, statically depends on cand_001).

### Lifecycle
- Phase 1: do NOT dispatch either externally.  cand_002 has zero
  observed_deps this epoch.
  - cand_002 m_native = -4.  Not positive → contribution = 0 anyway.

  Let's strengthen: drive cand_002 in PRIOR epoch to baseline-warm, then
  this epoch leave it alone.  cand_002 m_native(prev) = +4 → 'stable-active.
  After baseline NEW-EPOCH, this epoch cand_002 NOT dispatched →
  observed_dep(cand_002, cand_001) THIS epoch = 0.
  
  For support, the contribution requires observed_dep(B, A) = 1.  Even
  if cand_002 is currently 'stable-active (lingering from past epoch),
  contribution = 0 because not observed this epoch.

### Pass conditions

| pass | condition |
|------|-----------|
| `ro-1` | after baseline NE: cand_002 = 'stable-active (warmed up) |
| `ro-2` | OBSERVED-DEP? cand_002 cand_001 = 0 (this epoch no dispatch) |
| `ro-3` | SUPPORT-CREDIT cand_001 = 0 (no observed support, even though static dep exists) |
| `ro-4` | cand_001 path = stale (no support, but no decompose yet — just 1 idle epoch) |

---

## Updated existing demos (mandatory pre-reg commitment)

| Demo | Cand | Old status | New status |
|------|------|------------|------------|
| 161 | cand_001 phase 2 | 'dependency-held | 'dependency-supported |
| 162 | (none asserted intermediate-DH; might still pass without change) | — | — |
| 165 | cand_001 phase 2 | 'dependency-held | 'dependency-supported |
| 167 | cand_002 phase 2 | 'dependency-held | 'dependency-supported |
| 169 | cand_002 build phase | 'dependency-held | 'dependency-supported |

Updates are mechanical: change `'dependency-held` to `'dependency-supported`
on the specified lines.  cand_001 in 167/169 stays `'dependency-held` (via
transitive chain — its immediate dependent cand_002 is NOT natively
positive, so contributes no support; cycle 32 catches it later).

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. No new hyperparameter introduced.  Cap is `LAW_CARRY(A)`, split is
   `floor(m_pos(B) / dep_count(B))`, both structural.
3. `_support-credit` is per-epoch (reset on NEW-EPOCH, computed fresh
   inside Pass A's tail).  "Rented, not owned."
4. Only `m_native > STALE_TOLERANCE` cands contribute support.
   Supported cands (status `'dependency-supported`) do NOT propagate
   support (no chain inheritance — they themselves are not natively
   positive).
5. `dep_count(B)` counts DISTINCT cand symbols in B's motif.
6. History tracks `m_native`, not `m_eff`.  Chronic non-productivity
   accumulates even when temporarily supported.
7. Demos 161, 165, 167, 169 will be UPDATED with the table above as
   part of cycle 33's implementation.  All other cycle 28-32 demos
   unchanged.
8. `'dependency-supported` is in `STABLE-WORD-STATUSES` (contributes
   to `STABLE-LAW-HASH`) and `ACTIVE-METAB-STATUSES` (pays inflation,
   participates in NEW-EPOCH).  NOT in `SANDBOX-STATUSES`.
9. Cycle 32's `has-recent-load-bearing?` predicate is UNCHANGED.
   Cycle 33's support is a separate Pass A.5 computation that affects
   only Pass B status decisions; Pass C still receives whatever cands
   make it to `'demotion-candidate`.
10. **Triple-momentum observability:** `MOMENTUM-NATIVE` returns the
    intrinsic momentum value (reuse − carry − fails − inflation) and
    is NEVER modified by support computation.  `SUPPORT-CREDIT` is the
    per-epoch carry offset.  `MOMENTUM-EFFECTIVE` returns native + support.
    Status transitions consult MOMENTUM-EFFECTIVE; contribution
    calculations consult MOMENTUM-NATIVE.  Any drift between these
    two surfaces would be a regression.
11. **Future-risk acknowledgment (NOT in scope):** multi-dependent
    support can in principle create infrastructure-reservoir patterns
    ("too-big-to-decompose").  Cycle 33 does NOT introduce an
    infrastructure_status or any anti-reservoir mechanism.  If such
    a class emerges empirically, it becomes cycle 34+ work.
12. Attestation BEFORE commit (initial + addendum both recorded).

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 26-32 commits frozen; user spec (2026) 2026-05-23
      carry-offset-not-transfer; rented-not-owned
- [x] Rule 3: deterministic — support is a pure function of current
      state at NEW-EPOCH time
- [x] Rule 4: pass/fail partition outcome space across six demos
- [x] Rule 5: known-input lifecycle test
- [x] Rule 6: regression count update post-result; existing demo
      update table explicit
- [x] Rule 7: demos 172 (cap), 174 (dead dependent), 175 (cycle),
      176 (no observation) are all negative-control variants
- [x] Rule 8: scope = 6 new demos, 2 new primitives, 1 new status,
      1 new env key, 0 new hyperparameter
- [x] Rule 9: attestation pending

---

## What cycle 33 does NOT claim

- Support is "ecologically meaningful" — it's bookkeeping.
- The `floor / dep_count` apportionment is optimal — it's the
  simplest defensible split.
- Support enables dependent momentum allocation (the user-spec
  phrase) in a profit-sharing sense — explicitly NO profit transfer.
- Cycle 33 makes any new emergent dynamic possible — it tightens
  the metabolic gradient at the safe end, but does not change the
  decomposition gate's structural behavior.
- Support credit can replace cycle 32's `'dependency-held`
  protection — it doesn't; the two coexist and catch different
  cases.

It claims only:
1. **Carry offset, not transfer**: support_credit ≤ LAW_CARRY.
2. **No profit inheritance**: only natively-positive cands contribute.
3. **Rented per-epoch**: support computed fresh each NEW-EPOCH.
4. **Runtime-observed required**: static-only dependents give zero
   support.
5. **Fair split**: when one supporter has multiple deps, contribution
   is divided by dep_count.

If demos 171-176 all pass AND demos 161/165/167/169 still pass after
the documented status-label updates, then **dependent momentum
allocation as carry offset is operational** without enabling the
parasitic-economy failure mode.

---

## References

- META-SEMANTICS.md v2.1 §17
- Cycle 30 (commit 7d1bc8c)
- Cycle 31 (commit f5760a0)
- Cycle 32 (commit 9009f8d)
- CLAIMS.md freeze commit `8d64c7a` (post-cycle-32 stable definition)
- User spec (2026) 2026-05-23 — carry offset, not transfer; rented
  not owned; no profit inheritance
