# Demo 167 — Pre-Registered Predictions (cycle 32)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Scope: TWO LAYERS (multi-level cascade + runtime-observed dependency)

Cycle 32 strengthens the load-bearing predicate from cycle 30 in two
mutually-reinforcing ways:

1. **Runtime-observed dependency** replaces the pure static motif scan.
   A cand `cand_A` is considered "observed-by" `cand_B` only if
   during the just-ended epoch `cand_B`'s body was actually executed
   and inside that execution `cand_A` was actually invoked nested.
   Static dependency (motif contains symbol) is necessary but not
   sufficient.
2. **Multi-level cascade**: the chain of protection traverses through
   `'dependency-held` cands as long as the chain terminates in at
   least one cand with positive momentum.  Cycles without an external
   positive-momentum anchor collapse rather than producing immortal
   loops.

Cycle 32 is NOT:
- A claim about what runtime observation "means" semantically — it's
  just bookkeeping at op-CALL time
- A claim that the chain-walk is "smart" about partial chains — the
  formula is structural (visited-set DFS with positive-momentum
  termination)
- A claim that cycle-32 mechanics improve emergent system behavior —
  only that they prevent pathological cases (immortal cycles, static-
  only zombie protection)
- A change to inflation, profile, or any cycle-31 mechanism — those
  remain identical

Cycle 32 IS:
- The **observed dependency** invariant: `cand_B` cannot protect
  `cand_A` unless `cand_B` actually invoked `cand_A` this epoch
- The **transitive chain** invariant: protection propagates through
  active dependents to find an externally-productive anchor
- The **anti-immortal-cycle** invariant: a closed cycle of cands
  none of which is externally productive cannot mutually protect
  each other forever — without an external positive anchor, all
  cands in the cycle eventually auto-decompose

---

## Three-tier dependency model

```
static_dependency(A, B)        ≡ symbol B appears in A's motif body
observed_dependency(A, B)      ≡ A's body executed this epoch AND
                                  during that execution B was invoked nested
recent_load_bearing(A)         ≡ ∃ B ∈ active_dependents_of(A) such that
                                  observed_dependency(B, A) holds
                                  AND (B has positive momentum
                                       OR has_recent_load_bearing(B)
                                          [recursive, with cycle guard])
```

Cycle 30/31 used `has_positive_dependent_momentum` which is equivalent
to:
```
∃ B ∈ active_dependents_of(A). momentum(B) > STALE_TOLERANCE
```
This is purely static + direct.  Cycle 32 replaces it with
`has_recent_load_bearing` which is observed + transitive.

---

## Primary claims (three)

### Claim A — Observed dependency required

> `cand_A` is auto-decomposed by NEW-EPOCH Pass C unless some active
> dependent `cand_B` BOTH appears as a static dependent (motif-scan)
> AND was actually observed dispatching `cand_A` nested during the
> just-ended epoch.  A static-only dependent whose body did NOT execute
> this epoch does NOT protect.

### Claim B — Transitive chain protection

> The protection check terminates only when it finds a chain
>   `A → B₁ → B₂ → … → Bₙ`
> such that every link is observed (each Bᵢ₊₁ was nested-invoked from
> Bᵢ's body this epoch) AND Bₙ has positive momentum.  Intermediate
> Bᵢ's may themselves be `'dependency-held` (not positive) as long as
> the chain ultimately anchors in a positive cand.

### Claim C — Anti-immortal-cycle

> A closed cycle `A ↔ B` (each statically depends on the other) with
> NO external positive-momentum anchor cannot protect either cand.
> The visited-set guard breaks the recursion; both cands auto-decompose
> the same epoch they enter `'demotion-candidate`.

---

## Backward-compatibility contract

Cycle 30/31 demos (158–166) MUST continue passing with no modifications.

Analytical verification:

| Demo | dependent pattern | observed during epoch? | chain anchor |
|------|-------------------|------------------------|--------------|
| 158/159 | none | N/A | N/A |
| 160 | none | N/A | N/A |
| 161 | cand_002 → cand_001 (static, len 1) | yes (cand_002 dispatched 4× per epoch in DH phase) | cand_002 itself positive |
| 162 | same | same | same |
| 163-166 | none / single (cand_001) | N/A or same | N/A or self |

Every cycle 30/31 demo's protection check works the same way under
cycle 32 because the dependent IS observed and IS positive — exactly
the cycle 30 case.

Cycle 32 adds *strictness* in two cases:
1. Static dependent never executed → no longer protects (cycle 30 would
   have protected; cycle 32 will not).  This is the new demo 168.
2. Chain of length ≥ 2 with intermediate non-positive deps → cycle 30
   would NOT have protected; cycle 32 WILL (transitive walk).  This
   is the new demo 167.

No cycle 30/31 demo hits the strictness changes.

---

## Implementation contract (cycle 32B will conform)

### env-memory keys (new)

```
_observed-deps           box of alist ((containing-cand . called-cand) . int-count)
                          recorded by nested hook; reset on NEW-EPOCH
_opcodes-to-cand         hash from word-opcodes (eq) to cand-sym
                          populated by INDUCE-RUNTIME and RESTORE-PRIMITIVE
                          purged on ROLLBACK-RUNTIME and DECOMPOSE-PRIMITIVE
```

### New VM hook parameter (vm.rkt)

```racket
(define current-cand-nested-hook (make-parameter #f))
```

`trace-append!` modified:
- On `top-level?`: unchanged (cycle 25-31 path — fires
  current-cand-dispatch-hook, appends to trace box)
- On NOT `top-level?`: fires current-cand-nested-hook (cycle 32
  addition) — does NOT append to user-visible trace, does NOT fire
  the top-level hook

### New observed-dep recording hook (runtime.rkt)

```racket
(define (make-cand-nested-hook)
  (lambda (e kind name)
    (when (cand-name? name)
      (define caller (find-current-cand e))
      (when (and caller (not (eq? caller name)))
        (alist-bump-pair! (observed-deps-of e) (cons caller name) 1)))))
```

`find-current-cand`: walks rstack frames from most-recent, returns the
cand-sym whose opcode-vector matches the top frame's program (via
`_opcodes-to-cand` reverse-lookup).  Returns `#f` if no cand frame
found (e.g., we're inside a non-cand user word).

### New Tier 1 primitives

```
OBSERVED-DEP?         ( a b -- 0|1 )    was b invoked from a's body this epoch?
RECENT-LOAD-BEARING?  ( cand -- 0|1 )   transitive chain protection check
CAND-OBSERVES?        ( a b -- 0|1 )    alias / convenience for OBSERVED-DEP?
```

### Modified Pass C in prim-new-epoch

Replace:
```
[(has-positive-dependent-momentum? e c) → 'dependency-held]
```
with:
```
[(has-recent-load-bearing? e c) → 'dependency-held]
```

`has-recent-load-bearing?` implementation:

```
(define (has-recent-load-bearing? e cand)
  (let walk ([c cand] [visited (set cand)])
    (define deps (active-dependents-of e c))
    (for/or ([d (in-list deps)])
      (cond
        [(set-member? visited d) #f]   ; cycle guard
        [(not (observed-dep? e d c)) #f]
        [(and (memq (get-status e d) '(stable-active sandbox-stable))
              (> (compute-momentum-for e d) MOMENTUM-STALE-TOLERANCE))
         #t]
        [else (walk d (set-add visited d))]))))
```

### NEW-EPOCH reset extension

At end of `prim-new-epoch`, reset `_observed-deps` to `'()` along
with the other per-epoch counters.

### Reset on cand removal

`ROLLBACK-RUNTIME` and `do-decompose!` (manual + auto) remove the
cand's entry from `_opcodes-to-cand`.

### INSPECTION-OPS extended

Add `OBSERVED-DEP?`, `RECENT-LOAD-BEARING?`, `CAND-OBSERVES?` to
inspection list.

---

## Demo 167 — multi-level cascade (3-level chain)

### Setup
- Promote three cands:
  - `cand_001 = (MARK drop)`, L=2
  - `cand_002 = (cand_001 cand_001)`, L=2 (calls cand_001 twice nested)
  - `cand_003 = (cand_002 cand_002)`, L=2 (calls cand_002 twice nested)

### Lifecycle
- Baseline NEW-EPOCH (resets all setup-phase counters).
- Drive cand_003 productively (4×).
  - cand_003 top-level m = 4×(L-1=1) − 2 − 0 − 1 = +1.  Above STALE_TOL=1?
    Exactly 1, not strictly greater.  → 'stale (|m|<=STALE_TOL).
  - Hmm, need m strictly > STALE_TOL for stable-active.  Use 6 dispatches:
    m = 6×1 − 2 − 1 = +3 > 1 → stable-active.
- After NEW-EPOCH:
  - cand_003: m=+3, stable-active.
  - cand_002: nested-only, m=-3.  'stale (1st neg) but observed by cand_003.
  - cand_001: nested-only, m=-3.  'stale.

The first NEW-EPOCH gives stale, not demotion-candidate.  Need a
second productive epoch to get cand_002/001 to demotion-candidate
(2 consecutive negs).

- Phase 2: drive cand_003 productively again (6×).
  - After NEW-EPOCH:
    - cand_003 m=+3, stable-active.
    - cand_002: history=[-3, -3].  Pass B: 2 consecutive negs → demotion-candidate.
      Pass C: cand_002's dependents=[cand_003].  observed_dep(cand_003, cand_002)
      this epoch? YES.  cand_003 positive (m=+3) → has_recent_load_bearing TRUE
      → 'dependency-held.
    - cand_001: history=[-3, -3].  Pass B: → demotion-candidate.
      Pass C: cand_001's dependents=[cand_002].  observed_dep(cand_002, cand_001)
      this epoch? YES (cand_002 was nested-invoked from cand_003, and cand_002
      then nested-invoked cand_001).  cand_002 status='demotion-candidate
      (not positive).  Recurse has_recent_load_bearing(cand_002, visited={cand_001}).
      cand_002's dependents=[cand_003].  observed_dep(cand_003, cand_002)? YES.
      cand_003 status='stable-active, m=+3 > STALE_TOL → return TRUE.
      → cand_001 → 'dependency-held (transitively protected through cand_002 to cand_003).

### Pass conditions (demo 167)

| pass | condition |
|------|-----------|
| `m-1` | all three promoted (stable-active) |
| `m-2` | `OBSERVED-DEP? cand_003 cand_002 = 1` after a phase-2 dispatch |
| `m-3` | `OBSERVED-DEP? cand_002 cand_001 = 1` after a phase-2 dispatch |
| `m-4` | `RECENT-LOAD-BEARING? cand_002 = 1` (direct, via cand_003) |
| `m-5` | `RECENT-LOAD-BEARING? cand_001 = 1` (transitive via cand_002 → cand_003) |
| `m-6` | After phase 2 NEW-EPOCH: cand_001 status='dependency-held |
| `m-7` | After phase 2 NEW-EPOCH: cand_002 status='dependency-held |
| `m-8` | After phase 2 NEW-EPOCH: cand_003 status='stable-active |

---

## Demo 168 — static-only dependency does not save

### Setup
- Promote `cand_001 = (MARK drop)`, L=2.
- Promote `cand_002 = (cand_001 NODES drop)`, L=3, statically depends on cand_001.
- After baseline NEW-EPOCH.

### Lifecycle
- Do NOT call cand_002 at all in the test phase.  cand_002 just sits.
- Do NOT call cand_001 at all either.
- After 1 NEW-EPOCH:
  - cand_002 m=-4 (carry 3 + inflation 1).  'stale (1 neg).
  - cand_001 m=-3.  'stale (1 neg).
- After 2nd NEW-EPOCH:
  - cand_002 m=-4 again.  history=[-4,-4].  'demotion-candidate.
  - cand_001 m=-3 again.  history=[-3,-3].  'demotion-candidate.
  - Pass C cand_002: dependents=[].  Empty → auto-decompose.  ('decomposed)
  - Pass C cand_001: dependents=[cand_002].  observed_dep(cand_002, cand_001)
    this epoch? NO (cand_002 didn't run).  Skip cand_002.  Loop done →
    no recent load bearing → AUTO-DECOMPOSE.  ('decomposed)

The contrast with cycle 30/31: under those rules, cand_001 would have
been protected by static dependency on cand_002 (cand_002 had positive
momentum from setup activity).  Under cycle 32, observed check fails.

### Pass conditions (demo 168)

| pass | condition |
|------|-----------|
| `s-1` | both promoted |
| `s-2` | After 1 idle NEW-EPOCH: both 'stale |
| `s-3` | `OBSERVED-DEP? cand_002 cand_001 = 0` after 2 idle epochs (no execution) |
| `s-4` | `RECENT-LOAD-BEARING? cand_001 = 0` (static-only is insufficient) |
| `s-5` | After 2 idle NEW-EPOCHs: cand_001 status='decomposed |
| `s-6` | After 2 idle NEW-EPOCHs: cand_002 status='decomposed |

---

## Demo 169 — chain collapse

### Setup
Same as demo 167: three cands cand_001 → cand_002 → cand_003 (cand_003 is the
externally-driven one).

### Lifecycle
- Phase 1+2: drive cand_003 productively.  Reach state where
  cand_001=DH, cand_002=DH, cand_003=stable.
- Phase 3: STOP using cand_003.  All three momenta go negative.
  - cand_003 m=-3.  Pass B: history=[-3, +3, +3].  Only 1 recent neg → 'stale.
  - cand_002 m=-3.  Pass B: history=[-3, -3, -3].  3 consecutive negs → still
    demotion-candidate.
  - cand_001 same → demotion-candidate.

  Pass C:
  - cand_002 demotion-candidate.  dependents=[cand_003].  observed_dep(cand_003,
    cand_002) this epoch? NO (cand_003 didn't run).  No recent load bearing.
    → AUTO-DECOMPOSE.
  - cand_001 demotion-candidate.  dependents=[cand_002].  observed_dep(cand_002,
    cand_001) this epoch? NO.  → AUTO-DECOMPOSE.

  Result after phase 3: cand_001='decomposed, cand_002='decomposed,
  cand_003='stale.

### Pass conditions (demo 169)

| pass | condition |
|------|-----------|
| `c-1` | All three reach `'stable-active` / `'dependency-held` / `'stable-active` after phase 2 |
| `c-2` | After phase 3 NEW-EPOCH: cand_001 status='decomposed |
| `c-3` | After phase 3 NEW-EPOCH: cand_002 status='decomposed |
| `c-4` | After phase 3 NEW-EPOCH: cand_003 status='stale |
| `c-5` | law_hash mutated by the chain collapse |

---

## Demo 170 — cycle without external anchor decomposes

### Setup
- Promote `cand_001 = (MARK drop)`, L=2.
- Promote `cand_002 = (cand_001 MARK drop)`, L=3, depends on cand_001.
- Promote `cand_003 = (cand_002 MARK drop)`, L=3, depends on cand_002.
  Wait — cycle requires mutual dependency.  Easier: two-cand cycle.

Actually building a true static cycle in Sixth is hard: a cand body
must reference symbols that exist at INDUCE time.  cand_002 = (cand_001
…) requires cand_001 already exists.  cand_001 = (cand_002 …) would
require cand_002 already exists.  Chicken-and-egg.

Resolution: a cand can be redefined in env-words via env-register-word!.
We can:
1. INDUCE cand_001 from (NODES drop), promote.
2. INDUCE cand_002 from (cand_001 NODES drop), promote.
3. Manually REPLACE cand_001's body with one that references cand_002,
   via a helper primitive added in cycle 32 for the test (`REBIND-CAND-BODY`).

Adding a test-only primitive is acceptable per cycle 26 precedent
(NEW-SESSION).  But it muddles the invariant.  Alternative: skip the
explicit cycle demo and rely on demo 168 + 169 to cover the protection
semantics.

**DECISION (commitment 11 below):** Demo 170 is RECOMMENDED but
OPTIONAL for cycle 32.  If implementing requires a test-only primitive
that doesn't reflect any production use case, skip demo 170 and
pre-register the cycle case as a known limitation to be revisited if
a natural use case emerges.  Cycle 32 ships with demos 167/168/169
as the core acceptance bar.

If demo 170 is included:

### Lifecycle
- Re-bind cand_001 body to `(cand_002 MARK drop)` so cand_001 ↔ cand_002
  cycle exists statically.
- Stop calling either externally.
- Each epoch: neither m is positive.  Both descend to demotion-candidate.
- Pass C cand_001: dependents=[cand_002].  observed_dep(cand_002, cand_001)
  this epoch? Maybe yes from prior phase, but in the "stop calling"
  phase, no.  → AUTO-DECOMPOSE.
- Pass C cand_002 same outcome.

### Pass conditions (if demo 170 included)

| pass | condition |
|------|-----------|
| `y-1` | cycle established (LAW-DEPENDS-ON? both directions = 1) |
| `y-2` | after idle epochs, cand_001 AUTO-DECOMPOSED |
| `y-3` | after idle epochs, cand_002 AUTO-DECOMPOSED |
| `y-4` | visited-set cycle guard prevented infinite recursion (test via timing or RECENT-LOAD-BEARING? returns 0 cleanly without hang) |

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. No new hyperparameter introduced.  Cycle 32 changes the EVALUATION
   of the existing protection check; thresholds (STALE_TOLERANCE,
   NEGATIVE_THRESHOLD, HISTORY_WINDOW, INFLATION_COST) stay frozen.
3. `'dependency-held` status transition rule replaces `has_positive_
   dependent_momentum` with `has_recent_load_bearing?`.
4. `_observed-deps` is per-EPOCH (reset on NEW-EPOCH).  An older
   window (last K epochs) is DEFERRED to cycle 33+.
5. Cycle guard is implemented via visited-set during DFS.  A cycle
   with no external positive anchor returns FALSE cleanly (no
   infinite recursion).
6. VM modification: `trace-append!` adds a second hook fire path
   for nested calls.  No semantic change to existing top-level
   path.  Existing `current-cand-dispatch-hook` callers unaffected.
7. Static-only dependency (motif contains symbol but body did not
   execute) does NOT protect.  This is a behavioral DIVERGENCE
   from cycle 30/31 in the never-happens-in-existing-demos case.
8. Transitive walk only follows ACTIVE dependents (status in
   ACTIVE-METAB-STATUSES, which includes 'dependency-held).
9. Multi-level cascade RESTORE (cycle 31 deferred) remains DEFERRED.
   Cycle 32 only fixes the DOWNWARD chain check.  Cascade restore
   (re-promote chain on RESTORE) is cycle 33+.
10. Dependent momentum allocation (cycle 33 candidate) is NOT touched.
11. Demo 170 OPTIONAL per the design issue documented above.
12. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 26-31 commits as frozen reference; cycle 30
      direct-dep predicate as the v0 to refine; user spec (2026)
      2026-05-23 multi-level + observed deps
- [x] Rule 3: deterministic — nested hook fires on op-CALL events,
      env-state is the only mutator
- [x] Rule 4: pass / fail conditions partition outcome space across
      three (or four) demos
- [x] Rule 5: known-input lifecycle test (NOT empirical signal)
- [x] Rule 6: regression count update post-result
- [x] Rule 7: demo 168 is the negative control (static-only doesn't
      save); demo 170 (if included) is the cycle-without-anchor
      negative control
- [x] Rule 8: scope = 3-4 demos, 3 new primitives + 1 new VM hook
      parameter + 2 new env-memory keys, no new hyperparameter
- [x] Rule 9: attestation pending

---

## What cycle 32 does NOT claim

- It does NOT claim observed dependency is a "right" semantic — it
  is bookkeeping at op-CALL time.
- It does NOT claim the chain walk is computationally cheap — DFS
  over active cands is O(N×D) worst case where N is cand count and
  D is dep-graph depth.
- It does NOT introduce dependent momentum allocation (cycle 33).
- It does NOT model causal force or "real" dependency — only that
  cand_B's opcode vector dispatched cand_A during this epoch's runtime.
- It does NOT change the cycle 30 cascade-restore semantics.

It claims:
1. **Observed dependency**: cand_B only protects cand_A if cand_B's
   body actually executed cand_A this epoch.
2. **Transitive chain**: protection walks through `'dependency-held`
   intermediates to find a positive anchor.
3. **Anti-immortal-cycle**: closed cycles without external positive
   anchor collapse via visited-set DFS.

If demos 167 (multi-level chain protects), 168 (static-only fails),
169 (chain collapses when anchor disappears) all pass, then
**runtime-observed load-bearing is operational**.  Demo 170
(cycle-without-anchor) is optional confirmation.

---

## References

- META-SEMANTICS.md v2.1 §17
- Cycle 30 (commit 7d1bc8c) — direct-dep load-bearing (static, v0)
- Cycle 31 (commit f5760a0) — discovery profiles + inflation
- User spec (2026) 2026-05-23 — three-tier dep model;
  cycle-without-anchor must collapse; multi-level cascade
