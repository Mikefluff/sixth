# Demo 155 — Pre-Registered Predictions (cycle 28)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Scope: NARROW (held-out generalization)

Cycle 28 tests ONE thing: **can a Tier 1 committed candidate survive
held-out evaluation and pass through PROMOTE-STABLE?**

Cycle 28 is NOT:
- a test of the full energy-momentum lifecycle (`active_balance`,
  `E_WINDOW`, `E_MOMENTUM`, decay, demotion — those are cycle 29)
- a test of automated rediscovery on held-out (we use the cycle 27
  flow + cycle 26 hand-crafted as input candidate)
- a claim about cognition or substrate-of-meaning

Cycle 28 IS:
- the first generalization test: candidate works on train substrates
  AND also produces net energy gain on held-out
- the first time `PROMOTE-STABLE` is NOT a gate-closed stub —
  it can actually succeed
- the third operational layer:
  - 25: law can change
  - 26: law can commit by price
  - 27: candidate can be auto-discovered
  - **28: committed candidate can be promoted to stable IF it
    generalizes energetically to held-out**

---

## Primary claim

> A Tier 1 committed candidate can be promoted to `'stable-active`
> via `PROMOTE-STABLE` if and only if it satisfies
> `HELD-OUT-EVAL wins ≥ 4 / 6` (per-held-out-substrate net energy
> gain), AND the existing coupling + energy gates already
> satisfied by COMMIT-PRIMITIVE.

---

## Implementation contract (cycle 28B will conform)

### `HELD-OUT-EVAL ( cand-sym -- wins )` — real implementation

Replaces cycle 25B stub (which returned 0 unconditionally).

Algorithm (frozen per this pre-reg):

```
for each substrate-word in HELD-OUT-SUBSTRATES (6 names):
    1. Substrate-RESET (clears world; preserves env-words / law-state)
    2. Invoke substrate-word via env-lookup-word + run!  (loads
       held-out substrate; trailing pushed signature is dropped)
    3. Snapshot E-REUSE-GAIN before
    4. Loop K_HELDOUT = 5 times:
         try-dispatch cand-sym
         on exception → break (this substrate counts as LOSE)
    5. Snapshot E-REUSE-GAIN after
    6. WIN this substrate iff:
         all K_HELDOUT calls completed without exception, AND
         (E-REUSE-GAIN delta) >= K_HELDOUT * (expansion-length - 1)
return wins
```

`HELD-OUT-SUBSTRATES`: frozen list of 6 manifest-word symbols
(per cycle 25B `substrates/manifest.6th`):

```
heldout-path-n12
heldout-cycle-n12
heldout-er-n10-p30
heldout-er-n20-p15
heldout-motif-wedges
heldout-hidden-family-n24
```

### `PROMOTE-STABLE ( cand-sym -- status )` — real gate

Replaces cycle 25B stub (which returned `'rejected-no-heldout-in-25D`).

Cycle 28 gate (refusal cases first):

```
if status not 'committed:
    return 'rejected-not-committed
heldout_wins = HELD-OUT-EVAL cand-sym
if heldout_wins < 4:
    return 'rejected-heldout-insufficient
status -> 'stable-active
write attestation: (cand-sym, heldout_wins, law-hash, session-id,
                    cumulative-uses, cumulative-reuse-gain, exp-length)
return cand-sym
```

Note: `wins ≥ 4 / 6` mirrors META-SEMANTICS.md v2.1 §9 stable gate.
Cycle 28 doesn't add `runtime_overhead ≤ 1.5×` or `random_relabeling_
invariance` from §9 — those gates need substrate-snapshot
infrastructure deferred to cycle 29+.

### Energy momentum DEFERRED to cycle 29

Per user spec 2026-05-23:
- `active_balance` (decay-adjusted historical) — cycle 29
- `E_WINDOW` (rolling) — cycle 29
- `E_MOMENTUM` (slope) — cycle 29
- Demotion / deprecation states (`stable_degraded`,
  `needs_revalidation`, `inactive_candidate`, `deprecated_law`)
  — cycle 29

Cycle 28 freezes the simpler invariant:

> Promotion depends on `wins ≥ 4/6` on held-out at promotion time.
> Cumulative energy from train (already negative by COMMIT
> precondition) is recorded but is NOT the held-out gate.
> Lifecycle governance (demotion, decay) is cycle 29's job.

---

## Pre-registered measurements (per demo)

| measurement | how |
|-------------|-----|
| `wins` | HELD-OUT-EVAL on candidate after COMMIT |
| `expected_wins_for_happy` | 6 (MARK MARK bi-edge fires on all held-out) |
| `expected_wins_for_overfit` | 0 (stack-hungry cand underflows on fresh substrate) |
| `promote_result` | symbol returned by PROMOTE-STABLE |
| `final_status` | CAND-STATUS post-promote |
| `held_out_substrate_count` | 6 |

---

## Demo 155 — happy path (PROMOTE-STABLE succeeds)

### Setup
- Workload pre-discovery: 4 × `MARK MARK bi-edge` with `NODES drop`
  noise (cycle 27 happy-path style)
- Mining via DETECT-MOTIF-AUTO → cand_001 = (MARK MARK bi-edge)
- N=5 uses across M=3 sessions → COMMIT succeeds (cycle 26 gates)
- HELD-OUT-EVAL: run cand_001 K=5 times on each of 6 held-out
  substrates.  Per-substrate expected save = 5 × (3-1) = 10.
- All 6 substrates have empty stack at start, candidate consumes
  none and produces nodes/edges — runs cleanly on all 6.
- `wins` = 6
- PROMOTE-STABLE succeeds → status `'stable-active`

### Pass conditions (demo 155)

- `c-1` cand discovered + committed (carry over from cycle 27 demo 149)
- `c-2` HELD-OUT-EVAL returns 6
- `c-3` PROMOTE-STABLE returns the cand-sym
- `c-4` CAND-STATUS = `'stable-active`
- `c-5` ledger contains promote-stable attestation event
- `c-6` regression green (external)

---

## Demo 156 — train-overfit negative (PROMOTE-STABLE rejects)

### Setup
- Hand-construct a "stack-hungry" candidate via `WRAP-MOTIF` +
  `INDUCE-RUNTIME`.  Motif = `(bi-edge drop)` — length-2 that
  consumes 2+1 stack items per invocation.
- Train usage: demo manually pushes pairs of node ids to stack
  before each use.  Coupling N=5, M=3 satisfied on train.
  COMMIT succeeds (energy passes for length-2: net = 2 - 5×1 = -3).
- HELD-OUT-EVAL: each held-out substrate-word is loaded; the
  substrate state has nodes/edges but candidate dispatch starts
  with empty stack.  First `bi-edge` call underflows → exception
  → substrate counts as LOSE.
- All 6 substrates LOSE → wins = 0
- PROMOTE-STABLE returns `'rejected-heldout-insufficient`
- Status stays `'committed` (not promoted to stable)

### Pass conditions (demo 156)

- `nc-1` cand was committed (Tier 1 succeeded on train)
- `nc-2` HELD-OUT-EVAL returns 0 (cand underflows on every
  held-out substrate)
- `nc-3` PROMOTE-STABLE returns `'rejected-heldout-insufficient`
- `nc-4` CAND-STATUS remains `'committed` (not advanced to
  `'stable-active`)
- `nc-5` cleanup rollback restores law_hash

---

## Demo 157 — held-out-absent negative (PROMOTE-STABLE rejects)

### Setup
- Hand-construct another candidate via `WRAP-MOTIF` + `INDUCE-
  RUNTIME`.  Motif = `(NODES drop)` — uses INSPECTION-OPS
  (`NODES` is in INSPECTION-OPS).  Wait — INSPECTION-OPS check
  applies at SHADOW-CHECK via FORBIDDEN-IN-MOTIF filter.  Let me
  use a different motif: `(EDGE? drop)` — length-2, consumes 2 stack
  items returning a bool then drop.  `EDGE?` is a substrate
  query, not in FORBIDDEN-IN-MOTIF.
- On held-out: substrate loaded but stack empty → `EDGE?` underflows
  → same as 156 mechanism.
- ALTERNATIVE setup for 157 to be DISTINCT from 156: use a candidate
  that requires preexisting bi-edges in the substrate to be
  meaningful — e.g., `(OUT drop)` which queries out-edges of a
  node id.  On a substrate with NO edges, `OUT` returns empty
  list which can't be cleanly handled.

For simplicity, demo 157 reuses the underflow mechanism but with
a different candidate length-3 motif `(NODES drop NODES)` filtered
at SHADOW-CHECK to confirm shadow gate also catches some cases
before they reach held-out — wait, NODES would be FORBIDDEN.

REVISED demo 157: same mechanism as 156 (stack underflow on
held-out) but with a different motif construction to show that
the gate isn't ad-hoc per candidate.  Motif = `(2dup drop)`.
Underflows on empty stack.

### Pass conditions (demo 157)

- `nc'-1` cand was committed
- `nc'-2` HELD-OUT-EVAL returns 0
- `nc'-3` PROMOTE-STABLE returns `'rejected-heldout-insufficient`
- `nc'-4` CAND-STATUS remains `'committed`

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.  No post-hoc K_HELDOUT
   change.
2. HELD-OUT-SUBSTRATES list frozen here = the 6 names above.
   Cannot extend without deprecation cycle (per
   META-SEMANTICS.md §11 / mining_protocol.md §10).
3. Demos 155, 156, 157 use the same HELD-OUT-EVAL implementation.
4. Cycle 28 does NOT modify META-SEMANTICS.md or
   mining_protocol.md (no rule changes).
5. The `runtime_overhead ≤ 1.5×`,
   `passes_random_relabeling_invariance`, and
   `wins_on_at_least_2_challenge` conditions from
   META-SEMANTICS §9 stable gate are DEFERRED to cycle 29+
   (substrate-snapshot needed).  Cycle 28 implements a
   simplified gate.  Documented gap.
6. Cycle 28 PROMOTE-STABLE does NOT also require cumulative E < 0
   beyond what COMMIT-PRIMITIVE already enforced.  By construction,
   if cand reached `'committed` via COMMIT-PRIMITIVE, its
   train-side cumulative E was already negative.  Held-out gate
   is the NEW check.
7. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25-27 commits (`34cad87`, `2421e0f`, `b660eb5`,
      `78143cf`, `67cab83`, `2e1edbf`, `7664dd9`) as frozen
      reference; META-SEMANTICS.md v2.1 §9 stable gate; user spec
      (2026) 2026-05-23; Lakatos (1970) hardcore/protective belt
- [x] Rule 3: deterministic given frozen seeds
- [x] Rule 4: pass / fail conditions partition outcome space
- [x] Rule 5: first generalization test (NOT just plumbing)
- [x] Rule 6: regression count update post-result
- [x] Rule 7: negative demos provide falsification of the gate
- [x] Rule 8: scope = 3 demos, 1 gate, frozen substrate set
- [x] Rule 9: attestation pending

---

## What cycle 28 does NOT claim

- That the promoted stable candidate is useful for cognition.
- That `wins ≥ 4/6` is the right threshold (it mirrors §9 spec
  but is itself testable).
- That a candidate failing held-out is "wrong" in any deep sense;
  it's only "doesn't generalize under this specific test set".
- That lifecycle governance is solved (demotion / decay /
  deprecation deferred to cycle 29).

It claims only: **PROMOTE-STABLE distinguishes candidates that
work only on train-context from candidates that produce
net-positive energy gain on the frozen held-out substrate set.**

If demo 155 passes and demos 156, 157 both fail PROMOTE-STABLE,
the gate is operational.

---

## References

- META-SEMANTICS.md v2.1 (commit 67cab83), §9 stable gate
- mining_protocol.md (commit b660eb5), §6 held-out access rule
- substrates/manifest.6th (commit 2421e0f), 6 held-out substrates
- Cycle 26 (commit 2e1edbf), energy gate active
- Cycle 27 (commit 7664dd9), automated discovery → COMMIT
- User spec (2026) 2026-05-23 — held-out energy must be active
  balance; lifecycle governance deferred to cycle 29
- Lakatos (1970) — held-out test = stricter falsification layer
