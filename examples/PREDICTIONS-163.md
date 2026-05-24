# Demo 163 — Pre-Registered Predictions (cycle 31)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Scope: TWO INTERLOCKED LAYERS (discovery profiles + law inflation)

Cycle 31 introduces TWO architectural additions that change the
*class* of the system, not just deepen an existing mechanism:

1. **Discovery profiles** — `'conservative` (default, current behavior)
   vs `'liberal` (sandbox-only).  Liberal-induced cands live on a
   separate status track (`'experimental` → `'sandbox-stable`) and
   cannot enter stable `law_hash` without re-passing through the
   conservative pipeline.
2. **Law inflation** — every active primitive pays a uniform
   per-epoch cost (1 unit) on top of its expansion-length carry.
   Inflation folds into `compute-momentum-for`.  Even formerly
   stable primitives must keep earning, or they descend into
   `'stale` → `'demotion-candidate` → auto-decompose (cycle 30 gate).

Cycle 31 is NOT:
- A claim that conservative is always "right" and liberal "wrong" —
  liberal exists precisely to break out of local maxima that
  conservative gates would forbid
- A claim that inflation rate=1 is principled — it's the simplest
  uniform pressure that exposes the metabolic dynamic
- A model of biological selection — profiles are gate policies,
  inflation is bookkeeping
- A search-engine improvement — cycle 31 doesn't claim discovery
  *quality* changes, only that two regimes exist with structural
  separation

Cycle 31 IS:
- The **integrity gate** at discovery time: liberal modifications
  cannot corrupt the stable law-state's hash
- The **non-immortality** invariant: no stable primitive can sit
  forever without contributing; inflation forces ongoing payment
- The **scope contract**: liberal-discovered cands are quarantined
  in a sandbox track until a conservative re-pass certifies them
- The symmetric pair to cycle 28's entry gate: cycle 31 adds the
  *profile-aware* entry gate (cycle 28 was profile-blind)

---

## Primary claims (two)

### Claim A — Discovery profile integrity

> Under `'liberal` profile, `INDUCE-RUNTIME` produces a cand with
> status `'experimental` that lives in `env-words` (callable) but
> is filtered out of `STABLE-LAW-HASH`.  `COMMIT-PRIMITIVE` on an
> `'experimental` cand raises `rejected-not-conservative`.
> `PROMOTE-STABLE` on an `'experimental` or `'sandbox-stable` cand
> raises `rejected-sandbox-cand`.
>
> `PROMOTE-EXPERIMENTAL` is the only transition out of `'experimental`
> within the sandbox track: it produces `'sandbox-stable`, which is
> callable + participates in `NEW-EPOCH` metabolism + can auto-decompose,
> but never enters `STABLE-LAW-HASH`.
>
> Therefore: any liberal-mode activity leaves `STABLE-LAW-HASH`
> unchanged.  Only conservative-mode activity can mutate it.

### Claim B — Law inflation as carrying tax

> `compute-momentum-for(cand) := recent_reuse - carry_cost -
> recent_failures - INFLATION_COST_PER_CAND`
>
> where `INFLATION_COST_PER_CAND = 1` (hardcoded, no tuning).
>
> Applies to all cands in `ACTIVE-METAB-STATUSES` (now extended
> to include `'sandbox-stable`).  A primitive that earns
> `recent_reuse > carry + 1` per epoch remains stable; one that
> earns less drifts negative and eventually descends through
> `'stale` → `'demotion-candidate` → (cycle 30) auto-decompose
> unless protected by `'dependency-held`.
>
> Inflation does NOT apply to `'ephemeral-active` or `'committed`
> (pre-promotion pipeline) — those cands haven't entered the
> metabolic track yet.

---

## Backward-compatibility contract

Cycle 29 / 30 demos (158–162) **must continue passing** with no
modifications.  Analytical verification:

| Demo | cand | uses/epoch | L | old m | new m (=old − 1) | status delta? |
|------|------|------------|---|-------|------------------|---------------|
| 158 Ph1 | c1 | 6 | 3 | +9 | +8 | stable-active (m>1) |
| 158 Ph2 | c1 | 0 | 3 | −3 | −4 | stale (m<−1, hist len 1) |
| 158 Ph3 | c1 | 0 | 3 | −3 | −4 | dec-cand → auto-decompose |
| 159 ×5 | c1 | 4 | 3 | +5 | +4 | stable-active |
| 161 P1 c1 | c1 | 0 | 2 | −2 | −3 | stale (hist len 1) |
| 161 P1 c2 | c2 | 4 | 3 | +5 | +4 | stable-active |
| 161 P2 c1 | c1 | 0 | 2 | −2 | −3 | dec-cand → DH (c2 pos) |
| 161 P3 c1 | c1 | 0 | 2 | −2 | −3 | dec-cand → auto-decompose |
| 162 final c2 | c2 | 4 | 3 | +5 | +4 | stable-active |

All transitions identical; only the magnitudes shift by 1.  No
demo asserts on exact momentum value, so this is safe.

If any demo regresses, cycle 31 is a hyperparameter-breaking change
and must be re-pre-registered.

---

## Implementation contract (cycle 31B/C will conform)

### Statuses (new)

```
'experimental       liberal-INDUCE result; callable; NOT in STABLE-LAW-HASH
'sandbox-stable     PROMOTE-EXPERIMENTAL result; metabolism participant;
                    NOT in STABLE-LAW-HASH; eligible for auto-decompose
```

### env-memory keys (new)

```
_discovery-profile    box of 'conservative | 'liberal (default 'conservative)
```

### New Tier 1 primitives

```
SET-DISCOVERY-PROFILE  ( sym -- )       sym ∈ {'conservative, 'liberal}
DISCOVERY-PROFILE      ( -- sym )       inspection
PROFILE-BUDGET         ( -- n )         conservative=100, liberal=1000 (illustrative;
                                          no budget enforcement in cycle 31, inspection only)
PROFILE-SCOPE          ( -- sym )       'stable | 'sandbox derived from profile
PROMOTE-EXPERIMENTAL   ( cand -- )      'experimental → 'sandbox-stable;
                                          raises if cand status ≠ 'experimental
STABLE-LAW-HASH        ( -- n )         hash of env-words EXCLUDING cands in
                                          {'experimental, 'sandbox-stable}
SANDBOX-LAW-HASH       ( -- n )         hash of cands in
                                          {'experimental, 'sandbox-stable} only
LAW-CARRY              ( cand -- n )    expansion_length of cand
                                          (== current carry_cost; inspection)
```

### Modified existing primitives

```
INDUCE-RUNTIME    branches on profile:
                  conservative → status = 'ephemeral-active (current)
                  liberal      → status = 'experimental
COMMIT-PRIMITIVE  raises 'rejected-not-conservative if cand status = 'experimental
PROMOTE-STABLE    raises 'rejected-sandbox-cand if cand status ∈ {'experimental, 'sandbox-stable}
LAW-HASH          unchanged (full env-words hash; stays the canonical aggregate)
```

### Modified `compute-momentum-for`

```
m = recent_reuse - carry - recent_failures - INFLATION_COST_PER_CAND
  where INFLATION_COST_PER_CAND = 1
```

Applies to cands queried via `LAW-MOMENTUM` and to the per-cand
computation inside `prim-new-epoch`.  Does NOT apply to ephemeral
or committed cands (they are not in `ACTIVE-METAB-STATUSES` so
they're not iterated in NEW-EPOCH; inspection via LAW-MOMENTUM on
them returns the formula result but isn't acted upon).

### Modified `ACTIVE-METAB-STATUSES`

Add `'sandbox-stable` to the list (so it participates in NEW-EPOCH
metabolism).  `'experimental` is NOT added — experimental cands are
pre-metabolism analogous to ephemeral/committed.

### INSPECTION-OPS extended

`DISCOVERY-PROFILE`, `PROFILE-BUDGET`, `PROFILE-SCOPE`,
`STABLE-LAW-HASH`, `SANDBOX-LAW-HASH`, `LAW-CARRY` are inspection
ops (read-only on state).  `SET-DISCOVERY-PROFILE` and
`PROMOTE-EXPERIMENTAL` mutate state and are NOT inspection ops.

---

## Frozen hyperparameters (cycle 31 adds exactly one)

```
INFLATION_COST_PER_CAND = 1   per cand per epoch, hardcoded.
                              No tuning knob exposed.  Modifications
                              require deprecation cycle.

PROFILE_BUDGET_CONSERVATIVE = 100   inspection value, not enforced
PROFILE_BUDGET_LIBERAL      = 1000  inspection value, not enforced
```

The two PROFILE_BUDGET values are illustrative — they expose the
intended search-budget asymmetry between profiles but are not
checked by any gate in cycle 31.  Actual budget enforcement is
DEFERRED to cycle 32+.

---

## Demo 163 — discovery profile integrity (happy + negative)

### Setup
- Default profile = 'conservative
- Capture baseline `STABLE-LAW-HASH`

### Lifecycle
- Switch to liberal: `'liberal SET-DISCOVERY-PROFILE`
- Discover + INDUCE under liberal → cand status = 'experimental
- Try `COMMIT-PRIMITIVE` on it → must reject ('rejected-not-conservative)
- Try `PROMOTE-STABLE` on it → must reject ('rejected-sandbox-cand)
  (need wrapper similar to TRY-COMMIT — add TRY-PROMOTE-STABLE or
  use with-handlers in demo via TRY-COMMIT pattern)
- `PROMOTE-EXPERIMENTAL` works → status = 'sandbox-stable
- Inspect: `STABLE-LAW-HASH` unchanged from baseline
- Inspect: `SANDBOX-LAW-HASH` changed (now non-zero)
- `LAW-HASH` (aggregate) changed too (it sees everything)

### Pass conditions (demo 163)

| pass | condition |
|------|-----------|
| `p-1` | `'conservative` is the default profile |
| `p-2` | Liberal INDUCE produces 'experimental status |
| `p-3` | `COMMIT-PRIMITIVE` rejects 'experimental cand |
| `p-4` | `PROMOTE-STABLE` rejects 'sandbox-stable cand |
| `p-5` | `PROMOTE-EXPERIMENTAL` succeeds: 'experimental → 'sandbox-stable |
| `p-6` | `STABLE-LAW-HASH` unchanged by liberal activity |
| `p-7` | `SANDBOX-LAW-HASH` reflects the new sandbox cand |

---

## Demo 164 — law inflation forces ongoing payment

### Setup
- Conservative profile (default); promote cand_001 normally.

### Lifecycle
- Capture status = 'stable-active.
- Several `NEW-EPOCH` calls with NO use of cand_001.
- Each NEW-EPOCH: m = 0 − carry − 0 − 1 = −(carry+1).
- After 1 epoch: 'stale.
- After 2 consecutive negs: 'demotion-candidate → auto-decompose
  (no dependents).
- Status transitions match cycle 30 mechanics; inflation makes
  the negativity slightly deeper (m = −(L+1) vs old m = −L).

### Pass conditions (demo 164)

| pass | condition |
|------|-----------|
| `i-1` | cand_001 promoted (stable-active) |
| `i-2` | After 1 idle NEW-EPOCH → 'stale |
| `i-3` | After 2 idle NEW-EPOCHs → 'decomposed (Pass C auto-decompose) |
| `i-4` | `LAW-CARRY cand_001` returns expansion_length (==2 for our motif) |
| `i-5` | `PRIMITIVE-MOMENTUM` returns negative number reflecting inflation |
| `i-6` | `law_hash` mutated by auto-decompose (cycle 30 mechanics intact) |

---

## Demo 165 — inflation respects load-bearing protection

### Setup
- Conservative profile; promote two cands: cand_001=(NODES drop)
  and cand_002=(cand_001 MARK drop) (same setup as demo 161).

### Lifecycle
- Drive cand_002 productively each epoch; never call cand_001 directly.
- Per-epoch m for cand_001 = 0 − 2 − 0 − 1 = −3 (was −2 in cycle 30)
- Per-epoch m for cand_002 = 8 − 3 − 0 − 1 = +4 (was +5)
- cand_001 hits 'demotion-candidate by epoch 2 (faster with inflation).
- Pass C: cand_002 still has positive m (+4 > 1) → cand_001 → 'dependency-held.
- Confirm: inflation alone did NOT kill the load-bearing primitive.

### Pass conditions (demo 165)

| pass | condition |
|------|-----------|
| `lb-1` | both promoted (stable-active) |
| `lb-2` | cand_002 still has positive momentum despite inflation |
| `lb-3` | cand_001 transitions to 'dependency-held (NOT 'decomposed) |
| `lb-4` | cand_002 status stays 'stable-active during cand_001 DH |
| `lb-5` | Stopping cand_002 → cand_001 auto-decomposes (cycle 30) |

---

## Demo 166 — liberal sandbox bad cand rolled back, stable untouched

### Setup
- Conservative profile; promote cand_001 normally → stable-active.
- Capture `STABLE-LAW-HASH "l-stable-pre" store`.

### Lifecycle
- Switch to liberal: `'liberal SET-DISCOVERY-PROFILE`.
- Try to discover something problematic — minimal test: discover
  a short motif via DETECT-MOTIF-AUTO + INDUCE under liberal.
- Status = 'experimental.
- `ROLLBACK-RUNTIME` on the experimental cand — must succeed
  (rollback works regardless of profile; the gate is on
  COMMIT/PROMOTE, not INDUCE/ROLLBACK).
- Capture `STABLE-LAW-HASH "l-stable-post" store`.
- Verify: `l-stable-pre == l-stable-post` (sandbox activity left
  stable hash untouched throughout).

### Pass conditions (demo 166)

| pass | condition |
|------|-----------|
| `r-1` | cand_001 stable-promoted under conservative |
| `r-2` | Switch to liberal succeeds |
| `r-3` | Liberal INDUCE produces 'experimental cand |
| `r-4` | ROLLBACK-RUNTIME on experimental cand succeeds (status='rolled-back) |
| `r-5` | `STABLE-LAW-HASH` unchanged across the whole liberal episode |

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. Inflation rate = 1 hardcoded.  Modifications require deprecation
   cycle.  Profile budget values (100/1000) are illustrative; budget
   enforcement is DEFERRED to cycle 32+.
3. Liberal profile cannot mutate `STABLE-LAW-HASH` under any
   sequence of cycle 31 primitives.  This is THE integrity
   invariant.  Any cycle 31 demo that mutates STABLE-LAW-HASH
   under liberal profile is a BUG, not a feature.
4. `'experimental` cands DO NOT participate in `NEW-EPOCH`
   metabolism (analogous to 'ephemeral-active/'committed).
   `'sandbox-stable` cands DO participate.  Both are filtered
   out of `STABLE-LAW-HASH`.
5. Conservative-mode behavior is functionally IDENTICAL to cycle 30:
   default profile is 'conservative; all existing demos pass without
   modification (verified analytically; see Backward-compatibility
   contract above).
6. `LAW-HASH` (the canonical aggregate including both tracks)
   remains the existing definition.  `STABLE-LAW-HASH` and
   `SANDBOX-LAW-HASH` are new filtered views — the union of their
   contributing word sets equals `env-words`.
7. Multi-level cascades + runtime-observed load-bearing remain
   DEFERRED to cycle 32.  Cycle 31 only adds profiles + inflation.
8. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 26-30 commits as frozen reference; user spec
      (2026) 2026-05-23 conservative/liberal split + inflation;
      Lakatos (1970) on protective belt
- [x] Rule 3: deterministic given fixed seeds + profile + NEW-EPOCH
- [x] Rule 4: pass / fail conditions partition outcome space across
      four demos (gate integrity, inflation pressure, inflation +
      load-bearing interaction, sandbox isolation)
- [x] Rule 5: known-input lifecycle test (NOT empirical signal)
- [x] Rule 6: regression count update post-result; backward-
      compatibility contract analytically verified above
- [x] Rule 7: demos 163 (negative: liberal cannot commit/promote-stable)
      and 166 (negative: stable unchanged by liberal activity) are
      explicit falsification tests for the integrity invariant
- [x] Rule 8: scope = 4 demos, 1 new hyperparameter (inflation=1),
      8 new primitives + 2 new statuses
- [x] Rule 9: attestation pending

---

## What cycle 31 does NOT claim

- It does NOT claim liberal-mode discovery FINDS more useful
  primitives — it only claims liberal-mode cannot CORRUPT
  stable law-state.
- It does NOT claim inflation rate=1 is "right" — it's the
  minimal uniform pressure that breaks the immortal-primitive
  trap.  Tuning is deferred.
- It does NOT model search-budget enforcement (PROFILE-BUDGET
  is inspection-only in cycle 31).
- It does NOT claim sandbox primitives are useful — they're
  isolated, not evaluated for quality.
- It does NOT introduce drawdown tolerance for liberal cands —
  rollback semantics in cycle 31 match cycle 25 (immediate
  ROLLBACK-RUNTIME, no drawdown bound).

It claims only:
1. **Profile integrity**: liberal-mode activity leaves
   `STABLE-LAW-HASH` unchanged.
2. **Sandbox quarantine**: experimental + sandbox-stable cands
   live on a parallel track that cannot enter stable law-state
   without re-INDUCEing under conservative.
3. **Metabolic tax**: every active primitive pays 1 unit per
   epoch on top of carry; no stable primitive can sit forever
   without contributing.

If demo 163 passes (profile gates work), demo 164 passes (inflation
forces descent of unused primitives), demo 165 passes (inflation
respects cycle 30 dependency protection), and demo 166 passes
(stable unchanged by liberal activity), then **law ecology has
both selective and inflationary pressure**.

---

## References

- META-SEMANTICS.md v2.1 §17 (commit 67cab83) — energy accounting
- Cycle 26 (commit 2e1edbf) — energy gate (entry)
- Cycle 28 (commit aa5842d) — held-out generalization (entry, conservative)
- Cycle 29 (commit 41d548c) — law metabolism baseline
- Cycle 30 (commit 7d1bc8c) — dependency-aware AUTO-DECOMPOSE + cascade restore
- User spec (2026) 2026-05-23 — conservative/liberal split +
  law inflation as carrying tax
- Lakatos (1970) — protective belt: cycle 31's conservative gate
  is the protective belt; liberal is the heuristic exploration zone;
  inflation prevents the protective belt from ossifying
- Popper falsifiability: liberal profile is the "bold conjectures"
  zone; conservative is the "severe testing" zone; cycle 31 makes
  the distinction architectural rather than methodological
