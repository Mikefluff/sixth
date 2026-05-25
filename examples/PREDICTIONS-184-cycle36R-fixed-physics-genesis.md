# PREDICTIONS-184 — Cycle 36R: Fixed-Physics Genesis Runs

Pre-reg replaces (NOT extends) cycle 36D's selector-arena framing.
User direction 2026-05-25: "Не нужно делать селекторы-кандидаты,
арену селекторов, конституционные поправки. Нужны базовые
критерии среды. А дальше система эволюционирует внутри них."

Status of cycle 36B/C/D selector-arena scaffold (`81e772e..d4d056e`):
- **Floor primitives preserved**: BOOTSTRAP-RESET, BOOTSTRAP-LAW-HASH,
  BOOTSTRAP-EMPTY?, BOOTSTRAP-RESIDUAL, PREFLIGHT-ARENA.  These
  remain useful for clean-start guarantees in any future cycle.
- **SelectionProfile / PROFILE-SET / 5 named profiles / RUN-WORKLOAD-
  PROFILE**: deferred as over-engineered.  Not deleted (regression
  green, code working) but explicitly off the active development
  track.  Arena was answering the wrong question: "which selection
  law beats baseline" before establishing that any law-set
  actually produces durable repeatable primitives under blind
  evolution.
- **Cycle 37+ amendment protocol**: explicitly NOT on the roadmap
  until 36R produces an observable need.

---

## Core claim

> Given fixed minimal environmental criteria — equivalence, energy
> repayment, aging, held-out transfer, decomposition, and trace —
> the system can evolve candidate laws WITHOUT additional hand-
> authored selection profiles.
>
> Base criteria are physics, not candidates.
> Candidates are primitives evolving under that physics.

## What this cycle IS

- 3 to 5 seeded blind genesis runs from `BOOTSTRAP-RESET`.
- One single fixed rule-set = the current canon (cycle 25-33),
  unchanged.
- No profile switching.  No PROFILE-SET.  No A–E comparison.
- No new primitives.  All evolution happens inside existing
  cycle 25-33 machinery.
- Auto-mining via DETECT-MOTIF-AUTO; no hand-picked motifs.
- Full metabolism: SHADOW-CHECK, COMMIT, HELD-OUT-EVAL,
  PROMOTE-STABLE, momentum, inflation, decay, auto-decompose.
- Per-run forensic capture: survivors, decompositions, shadow
  fails, held-out fails, energy expenditure.
- Across-run analysis: do the same classes of primitives appear?
  Do certain motif shapes consistently survive while others
  consistently die?

## What this cycle is NOT

- Not a selection-law tournament.
- Not a search for "the right inflation cost".
- Not promotion of any selector profile.
- Not modification of canon hyperparameters.
- Not introduction of new primitives outside the canon.
- Not multi-process / parallel evolution.
- Not a verdict on whether the canon's selection laws are
  "correct" — only on whether they produce REPEATABLE evolution.

## Fixed physics (binding base criteria)

The seven environmental criteria below are **physics**, not
candidates.  They are the unchanged canon rule-set.

### 1. Equivalence

> A new primitive cannot lie about its behavior.

`SHADOW-CHECK` is mandatory before INDUCE-RUNTIME finalizes a
cand.  Behavioral divergence between motif body and proposed cand
expansion is detected and rejected.

### 2. Energy

> A primitive must repay the cost of its body.

`reuse_gain > law_cost + carry` for survival.  Energy gate at
COMMIT-PRIMITIVE; momentum at LAW-MOMENTUM.

### 3. Time (aging)

> A primitive ages if not used.

Inflation cost = 1 per epoch per active cand (cycle 31).  Carry
per epoch = expansion-length (cycle 33).  Both subtract from
momentum.

### 4. Transfer

> A local trick does not become law.

`HELD-OUT-EVAL` must pass on held-out workload before
PROMOTE-STABLE.  Frequency above coupling-N does not bypass.

### 5. Decay

> What does not repay is decomposed.

`AUTO-DECOMPOSE` after MOMENTUM-NEGATIVE-THRESHOLD=2 consecutive
negative epochs (cycle 29).  Decomposition is dependency-aware
(cycle 30).

### 6. Memory

> Everything significant leaves trace / ledger.

`_trace` records every top-level dispatch.  `_ledger` records
every meta-event with full forensic context.

### 7. Canon boundary

> Sandbox does not touch stable.

Cycle 31 sandbox-stable status partition; STABLE-LAW-HASH and
SANDBOX-LAW-HASH never mix.

## Protocol

For each seed s in {seed_1, seed_2, ..., seed_K} (K = 3 minimum,
5 preferred):

1. `BOOTSTRAP-RESET` (full empty-state via the floor primitives).
2. Run blind workload `genesis-seed-K.6th` — a structurally
   varied workload that does NOT hand-pick motifs.  Each seed
   produces a different opcode stream from a deterministic
   generator (Lehmer / linear-congruential with fixed mod).
3. Throughout the run: log every commit/promote/decompose/
   shadow-fail/held-out-fail event with seed id, epoch, cand,
   reason.
4. At end of run, capture:
   - List of cand_NNN that reached 'stable-active.
   - List of decomposed cands (with reason).
   - Aggregate energy: E_world, E_law, E_total.
   - Motif-shape census: length distribution of surviving cands.

After all K seeds:

- Cross-seed comparison: do the same MOTIF SHAPES (not specific
  cand symbols) appear across seeds?  Length-2 vs length-3
  dominance?  Specific opcode patterns recurring?
- Survivor longevity: do promoted cands stay 'stable-active for
  the entire post-promotion run, or oscillate?
- Failure modes: dominant rejection reason — shadow-fail,
  held-out-fail, decompose, or never reaching coupling?

## Pass / fail

This cycle DOES NOT have a binary pass/fail in the comparison-
of-laws sense.  It produces a forensic record.  The relevant
questions:

### PASS conditions

1. ≥3 seeds complete without engine error.
2. Each seed produces ≥1 promote OR provides documented forensic
   reason for zero promotions.
3. Per-seed log is reproducible (re-running same seed → same
   events).
4. Cross-seed analysis is computable (motif-shape census,
   survivor count).
5. No regression in 2297 ✓ baseline.

### FAIL conditions

1. Engine crashes on any seed.
2. Same seed produces different events across runs (non-
   determinism = bug, not finding).
3. Any cand from one seed leaks into another seed's run (sandbox
   violation).
4. Cycle 25-33 demos regress (canon mutation).

### What this cycle WILL find

One of three outcomes, each is information:

- **Convergent shapes**: same motif-LENGTH classes survive across
  seeds → physics is sufficient to channel evolution; selection
  laws not the bottleneck.
- **Divergent shapes**: different seeds yield wildly different
  survivor sets with no consistent class → physics under-determined;
  motif birth is too noisy.
- **Universal decay**: nothing survives across most seeds →
  physics too hostile; inflation/carry too aggressive.

Each outcome informs the next cycle direction WITHOUT requiring
prior selector-law commitment.

## Implementation contract

Cycle 36R-impl will conform:

1. New harness file `stdlib/harness/seeded-workload.6th` —
   deterministic linear-congruential opcode generator parameterized
   by seed.  Frozen (modifications require deprecation cycle).
2. New Sixth primitives:
   - `WITH-SEED ( int -- )` — sets the seeded workload generator
     state.  Test-only API per cycle 27 pattern.
   - `RUN-GENESIS-SEED ( seed -- promoted_count decomposed_count )`
     — runs one full seeded workload from BOOTSTRAP-RESET and
     reports two summary metrics.  Detailed per-event log goes
     to `_ledger`.
3. Cycle 36R demo: 3 seeds × `RUN-GENESIS-SEED` with cross-seed
   forensic comparison.
4. RESULTS-184 writeup documenting which of the three outcomes
   actually occurred.

## Six negative tests (binding)

NEG-1 Seed determinism: same seed → identical event sequence.
NEG-2 Seed independence: seed K's cands do not appear in seed
      L's pre-INDUCE state.
NEG-3 Canon preservation: 2297 ✓ regression unchanged.
NEG-4 No new primitive: ACTIVE-DICTIONARY count returns to
      pre-cycle baseline after RESET.
NEG-5 Forensic completeness: every PROMOTE / DECOMPOSE event
      appears in `_ledger` with seed id + epoch.
NEG-6 No selector profile path: PROFILE-SET / RUN-WORKLOAD-
      PROFILE not invoked in cycle 36R.  (Mechanically: 36R
      demos do not use those primitives.)

## References

- METHODOLOGY.md v2.1
- PREDICTIONS-182 (cycle 36 selector-arena — DEPRECATED for
  active track, scaffold preserved for future amendment cycles)
- RESULTS-181 (cycle 35 genesis layer v0)
- RESULTS-183 (cycle 36D 5-profile comparison — last entry on
  selector-arena track; sets context for the pivot)

## Re-attestation

Attest this pre-reg before cycle 36R implementation begins.
