# Demo 149 — Pre-Registered Predictions (cycle 27)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Scope: NARROW

Cycle 27 tests ONE thing: **can Sixth automatically discover a
runtime law candidate from execution traces without being told what
to look for, and process it through the full meta-semantics pipeline
to commit?**

Cycle 27 is NOT:
- a test of cognition or substrate-of-consciousness
- a claim about general scientific discovery
- a Tier 2 stable promotion test (held-out infrastructure deferred
  to cycle 28+)
- a test that automated discovery generalizes useful structure

Cycle 27 IS:
- a plumbing demonstration that the discovery layer above SHADOW-
  CHECK works
- a falsification opportunity: if mining finds no candidate that
  passes all gates, the protocol fails honestly without parameter
  changes

---

## Single primary claim

> Sixth can automatically discover and commit an energetically
> justified runtime law candidate from execution traces under a
> frozen mining protocol (`docs/mining_protocol.md` commit
> `b660eb5`).

The mining protocol is FROZEN.  Any parameter modification post-cycle
would be a contamination event per
[META-SEMANTICS.md v2.1 §11](../docs/META-SEMANTICS.md) and the
mining_protocol.md §10 deprecation cycle.

---

## Implementation contract (cycle 27B will conform)

### `DETECT-MOTIF-AUTO ( -- motif )`

New Tier 1 primitive that consumes nothing and pushes either a
non-empty motif list or `()` if no candidate qualifies.  Semantics
per frozen `docs/mining_protocol.md`:

1. Scan recent trace window of length `WINDOW_K = 20`.
2. Enumerate all contiguous n-grams of length `[MIN_LEN, MAX_LEN] = [2, 6]`.
3. Exclude any n-gram containing a symbol from
   `FORBIDDEN-IN-MOTIF` (meta-prims + RESET) or `INSPECTION-OPS`.
4. Count non-overlapping occurrences per distinct n-gram.
5. Keep n-grams with occurrence count `>= REPEAT_R = 3`.
6. Sort by `(frequency desc, length desc, motif-hash asc)` —
   deterministic tiebreak.
7. Return TOP-1 (or `()`).

**Distinct from `DETECT-MOTIF`** (tail-anchored heuristic): AUTO
does global search with deterministic ranking, no positional bias.

### Naming discipline

The miner returns a motif (sequence of symbols) but does NOT name
it.  Naming happens at `INDUCE-RUNTIME` via the existing
`cand_NNN` counter (blind, no semantic name).  Per
META-SEMANTICS §12 cheating defence: pretty names are assigned
only after final promotion decision.

---

## Workload constraint (binding)

No "look for `MARK MARK bi-edge`" code anywhere.  The workload is
written as a sequence of substrate-building operations that
naturally produces top-level trace repetition.  The discovery is
made by the miner alone.

To make the discovery falsifiable: the workload must produce
**multiple** competing candidate patterns, and the miner's
deterministic ranking must select among them.  A workload with
only one possible repeat is too easy.

Workload spec for demo 149:
- Inline source builds five small "diamond" structures
- Each diamond uses: `MARK MARK bi-edge MARK rot bi-edge`
  (length 6 — captures one possible candidate)
- Between diamonds: interleave `NODES drop` (forces some
  non-motif noise but acceptable since `NODES`/`drop` are not
  inspection per FORBIDDEN_IN_MOTIF blacklist — wait, NODES is
  in INSPECTION_OPS so won't enter motif; drop is base, included)
- The miner should select the longest highest-frequency clean motif
  among the natural top-level sequence

The exact motif the miner discovers is **NOT pre-specified**.  The
demo asserts: a motif is found, it passes all gates, candidate is
committed.

---

## Pre-registered measurements (demo 149 happy path)

| measurement | how |
|-------------|-----|
| `mining_returned_motif` | DETECT-MOTIF-AUTO non-empty |
| `motif_length` | length of returned list, in [2, 6] |
| `shadow_passed` | SHADOW-CHECK = 1 on returned motif |
| `induce_succeeded` | cand_NNN added to dictionary |
| `law_hash_mutated` | LAW-HASH differs before/after INDUCE |
| `uses_count` | CAND-USES after workload's use loop = N (>= 5) |
| `distinct_sessions` | CAND-DISTINCT-SESSIONS = M (>= 3) |
| `net_delta_e` | `motif_length - uses * (motif_length - 1)` |
| `commit_succeeded` | COMMIT-PRIMITIVE returns cand-sym |
| `status_committed` | CAND-STATUS = 'committed |
| `attest_recorded` | LEDGER-COUNT grew by attest event |
| `regression_green` | tests/examples-test.rkt 2NNN/2NNN |

---

## Pass conditions for HAPPY PATH (demo 149)

All of:
- `c-1` DETECT-MOTIF-AUTO returns a non-empty list
- `c-2` motif length in [2, 6]
- `c-3` SHADOW-CHECK passes
- `c-4` INDUCE-RUNTIME mutates law_hash
- `c-5` workload reaches N=5 uses
- `c-6` workload spans M=3 distinct sessions
- `c-7` net_delta_e < 0
- `c-8` COMMIT-PRIMITIVE succeeds
- `c-9` status becomes 'committed
- `c-10` ATTEST-PRIMITIVE stub records ledger event
- `c-11` regression green (external)

## Strong pass (informational, not gating)

- ≥2 distinct candidates discovered across runs (each via separate
  workload)
- candidate survives randomized relabel control (deferred to cycle 28)

## Fail conditions for HAPPY PATH

ANY of:
- `f-1` no candidate found
- `f-2` candidate found but SHADOW-CHECK rejects (shouldn't happen
  if miner respects forbidden list)
- `f-3` candidate found but uses < N=5 (workload bug; not protocol)
- `f-4` candidate found but distinct sessions < M=3
- `f-5` energy gate rejects (would mean miner returned too-short
  motif for the use count — protocol design bug)
- `f-6` any contamination event during run
- `f-7` any post-hoc mining parameter change

---

## Negative control demos (cycle 27D)

Each negative demo asserts the miner correctly REJECTS / does NOT
commit a candidate that should not pass.

### demo 150 — randomized trace order
- Workload: long sequence of base+substrate ops with NO repeated
  subsequences (pseudo-shuffled via PRNG-driven dispatch).
- Expected: `DETECT-MOTIF-AUTO` returns `()` OR returns a
  low-frequency motif that fails coupling (workload doesn't
  invoke it N=5 times).
- Pass: no `'committed` status anywhere.

### demo 151 — single-use motif
- Workload: contains a long distinctive motif but invokes it
  only ONCE.
- Expected: miner doesn't return it (frequency < R=3).
- Pass: `DETECT-MOTIF-AUTO` returns `()`.

### demo 152 — forbidden-op-laced
- Workload: builds a repeated sequence that contains RESET (or
  another FORBIDDEN-IN-MOTIF symbol).
- Expected: miner skips n-grams containing RESET.  Either returns
  `()` or returns an alternative motif that doesn't include RESET.
- Pass: any returned motif does NOT contain FORBIDDEN-IN-MOTIF
  symbols.

### demos 153 + 154 — DEFERRED (documented gaps)

**153 world-mismatch**: requires substrate-snapshot infrastructure
to compare candidate's behavior vs expansion's behavior beyond
symbol-level check.  Substrate-snapshot deferred to cycle 28.

**154 energy-fail-auto**: structurally impossible under frozen
protocol — `MIN_LEN = 2` already prevents length-1 motifs from
being discovered, so the energy gate cannot fire "too late" at
COMMIT for auto-discovered candidates.  This is the *defence
hierarchy* working as designed: MIN_LEN at mining (first defence)
preempts the energy gate at commit (last defence).  Cycle 26's
demo 148 already verified the energy gate works for hand-crafted
length-1.  Adding 154 would test nothing new.

---

## Methodological commitments (binding)

1. PREDICTIONS-149.md attested BEFORE any cycle 27 source written.
2. Implementation conforms to frozen `docs/mining_protocol.md`
   (commit `b660eb5`).  No parameter changes.
3. Workload for demo 149 must NOT name the candidate motif in
   any way (no `' MARK MARK bi-edge WRAP-MOTIF` style).
4. The miner's deterministic ranking selects among multiple
   competing candidates — workload must produce ≥2 valid n-gram
   patterns to exercise tiebreak.
5. Demos 150, 151, 152 use distinct workloads each.
6. If demo 149 fails any pass condition, RESULTS.md records the
   failure honestly with no protocol modification.
7. Tier 2 stable promotion remains gate-closed in cycle 27.
   PROMOTE-STABLE still returns `'rejected-no-heldout-in-25D`
   (gate stays closed; cycle 28+ wires held-out).
8. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25-26 commits (`34cad87`, `2421e0f`, `b660eb5`,
      `78143cf`, `67cab83`, `2e1edbf`) as frozen reference;
      Lakatos (1970) protocol-research-programme distinction;
      Goodhart (1975) measure-target degeneration → mining_protocol
      freeze defends against parameter mining; user spec 2026-05-23
- [x] Rule 3: deterministic given fixed seeds and frozen workloads
- [x] Rule 4: pass / fail conditions partition outcome space per
      demo
- [x] Rule 5: known-input plumbing validation, NOT empirical claim;
      cycle 28 extends to held-out
- [x] Rule 6: regression count update post-result
- [x] Rule 7: ANY pass condition fail = honest negative result; no
      protocol modification permitted
- [x] Rule 8: scope = TWO experiments (1 happy + 3 negative + 2
      deferred), no general-cognition claims
- [x] Rule 9: attestation pending

---

## What cycle 27 does NOT claim

- The discovered candidate is useful for any task.
- Sixth has discovered "a useful law".
- The miner is a real cognitive discovery mechanism.
- Stable promotion has been validated (it has not; PROMOTE-STABLE
  still rejected in cycle 27).
- Cycle 27 = cycle 28 (Tier 2 stable promotion is the next big
  test, not this one).

It claims only: **the discovery → SHADOW → INDUCE → USE → COMMIT
pipeline runs end-to-end without human choosing the candidate,
under a frozen mining protocol, on a known-workload test.**

If this passes, automated Tier 1 discovery is demonstrated.
If it fails, the failure is informative: either mining protocol
parameters are wrong (but cannot be tuned post-hoc), the miner
implementation has a bug, or the workload doesn't naturally
produce discoverable patterns.

---

## References

- META-SEMANTICS.md v2.1 (commit 67cab83), §0 supersession
- mining_protocol.md (commit b660eb5), §3 hyperparameters
- Cycle 26 (commit 2e1edbf) — energy gate activated, baseline
  for cycle 27
- Cycle 25E (commit 67cab83) — energy v0 formula
- User spec (2026) 2026-05-23 — cycle 27 must be narrow, automated
  discovery only, honest fail without protocol modification
- Lakatos (1970) — hardcore / protective belt distinction
- Goodhart (1975) — measure-target degeneration; mining_protocol
  freeze defends against parameter mining
