# mining_protocol.md — Frozen Mining Algorithm Specification

**Status:** Cycle 25C deliverable.  Normative specification.  NO code.

**Frozen:** 2026-05-23

**Per docs/META-SEMANTICS.md v2 §9 / §12 cheating defense (pre-discovery):**
> Mining algorithm hash and hyperparameters MUST be frozen at cycle 25
> BEFORE any candidate enters DISCOVER.  Modifications post-freeze are
> contamination events per META-SEMANTICS.md v2 §11.

**Scope:** This document fixes the parameters and policy for AUTOMATED
discovery of candidate primitives via mining of runtime traces.  It
does NOT specify the mining algorithm's source code yet (that lands
in cycle 27).  It fixes the contractual surface against which the
cycle-27 implementation must conform.

---

## §1. Why freeze now?

User critique (2026-05-23):

> Cycle 26 покажет, где слабые места, и потом mining protocol "случайно"
> станет удобнее.  Даже если ты не будешь мухлевать, внешний критик это
> сразу увидит.

Freezing the protocol before cycle 26 (manual induction) ensures that
any parameter tuning to fit observed cycle 26 behavior is mechanically
detectable.  The freeze does NOT claim the parameters are optimal —
it claims they are committed.

A reviewer in 2027 comparing cycle 25C parameters to cycle 27 mining
output can verify nothing changed in between.  If anything did
change, the deprecation cycle (§10) must show why.

---

## §2. Motif Definition

**Motif** = a finite, ordered sequence of word/primitive names that
appeared as consecutive top-level dispatch events in the runtime trace.

Formally:
```
motif := [name_1, name_2, …, name_L]
where:
  name_i is a SYM appearing as op-CALL or op-PRIM arg
  consecutive top-level (rstack empty or halt-sentinel only — see
                          sixth/vm.rkt trace-append! filter)
  L = length, bounded by §3
```

Word-body internal expansion is NOT motif material (Tier 1 trace
filter excludes it; see cycle 25A implementation).

---

## §3. Mining Hyperparameters (FROZEN)

These values are committed.  Modification requires deprecation cycle.

| parameter | value | meaning |
|-----------|-------|---------|
| `WINDOW_K` | 20 | trace tail length scanned per DETECT-MOTIF call |
| `REPEAT_R` | 3 | minimum non-overlapping occurrences for candidate eligibility |
| `MIN_LEN` | 2 | minimum motif length (1-grams = single primitives, excluded) |
| `MAX_LEN` | 5 | maximum motif length (longer needs separate justification) |
| `COUPLING_N` | 5 | minimum USE-RUNTIME invocations across runs to qualify for COMMIT-PRIMITIVE |
| `COUPLING_M` | 3 | minimum number of distinct runs in which the ephemeral fired USE-RUNTIME with no ROLLBACK |
| `EVAL_TOP_K` | 10 | top-K candidates from a discovery batch evaluated through Tier 2; rest discarded |
| `DEDUP_HASH_DEPTH` | full | identical candidate motifs (same name sequence) deduplicate by hash; no fuzzy matching |
| `RNG_SEED_POLICY` | per-run seeded from `seed-of-run` ledger field | NO global mutable seed; reproducibility per attestation |

Cycle 25A code currently uses `WINDOW_K=20`, `REPEAT_R=3`, `MIN_LEN=2`,
`MAX_LEN=5` (see sixth/meta/tier1.rkt constants).  Cycle 27 mining
algorithm MUST use the same values.

`COUPLING_N=5` and `COUPLING_M=3` are the Tier 1 → Tier 2 bridge gate
defined in META-SEMANTICS.md v2 §2.  Code enforcement deferred to
cycle 26.

---

## §4. Allowed Candidate Primitive Shape

A candidate primitive MUST:

1. Be macro-expansible to bootstrap + fixed stdlib (META-SEMANTICS
   v2 §6 expressivity bound).
2. Have stack effect computable purely from its expansion (no
   hidden side effects beyond `store`/`load` and substrate axioms).
3. Have name `cand_NNN` where NNN is a zero-padded 3-digit integer
   counter (per cycle 25A implementation).  No semantic name
   permitted at discovery time (META-SEMANTICS.md v2 §12 blind
   naming).
4. Have an expansion length within `[MIN_LEN, MAX_LEN]` from §3.

A candidate primitive MUST NOT:

- Invoke meta-primitives (`PROMOTE-*`, `INDUCE-*`, `ROLLBACK-*`,
  `HASH-WORLD`, `LAW-HASH`, `ATTEST-PRIMITIVE`, `HELD-OUT-EVAL`)
  in its expansion.  Mining filter rejects such candidates as
  protocol violations (would allow self-modifying-meta loops).
- Invoke `RESET` (would erase substrate state mid-evaluation,
  breaking causality of any subsequent measurement).
- Refer to other `cand_*` not currently in dictionary (no forward
  references, no orphan refs).

---

## §5. Train-Only Discovery

Discovery module:

- Loads ONLY substrates listed in `substrates/manifest.6th` train set
  (rows starting `train-*`).
- Held-out (`heldout-*`) and challenge substrates MUST NOT be loaded
  by mining code.  Enforcement at cycle 27: discovery module is in a
  separate Racket sub-collection that cannot `require` the held-out
  loader.
- Trace produced during discovery is annotated with the train
  substrate id at each step (for forensic verification that no
  held-out leakage occurred).

---

## §6. Held-out Access Rule

Held-out evaluation is performed by a separate command:
`scripts/heldout_eval.sh cand_NNN` (to be implemented in cycle 26).

- Invocation appends one row to `attestations/primitives-ledger.txt`.
- Result (per-substrate PE-with, PE-without, runtime) recorded
  append-only.
- Second invocation on the same `cand_NNN` returns the FIRST recorded
  result and logs a `duplicate-heldout-attempt` event in the ledger.
  Multiple iterations of held-out for the same candidate are
  contamination per META-SEMANTICS.md v2 §11.

---

## §7. No Mutation After Held-out Exposure

After `HELD-OUT-EVAL` is invoked on `cand_NNN`:
- The candidate's expansion is **immutable**.
- Any edit to `expansion`, `preconditions`, `postconditions`, or
  `cost_model` voids the candidate.
- A "fixed" version requires a NEW `cand_MMM` (next counter id) AND
  a NEW held-out rotation against fresh seeds derived from
  `seed-of-run + cand_MMM_id`.
- The original cand_NNN status changes to `voided_post_heldout`;
  ledger row recorded permanently.

---

## §8. Evaluation Order

For a discovery batch producing N candidates, where N may exceed
`EVAL_TOP_K` (§3):

1. Candidates ordered by `(support_count desc, candidate_id asc)`.
   `support_count` = number of times the motif appeared in train
   trace.  Tiebreak on cand id is deterministic.
2. Top `EVAL_TOP_K` candidates pass through SPECIFY → FREEZE → TRAIN-
   EVAL → HELD-OUT-EVAL → PROMOTE-STABLE.
3. Remaining candidates marked `not_evaluated` with reason
   `top_k_overflow`.  Cannot be later promoted to evaluation queue
   without new pre-reg.

**Exception:** if a candidate from the discarded tail is INDEPENDENTLY
re-discovered in a later run (different `seed-of-run`), it receives
a new `cand_MMM` id and enters fresh evaluation.  Re-discovery counter
is informational, not promotion authority.

---

## §9. Engine Version Hash

Each ledger row includes `engine_version` = sha256 of a tuple over:

- git commit hash at evaluation time (`git rev-parse HEAD`)
- list of (name, expansion-hash) of all stable_active primitives in
  current dictionary
- substrate manifest hash (sha256 of `substrates/manifest.6th`)
- mining_protocol hash (sha256 of THIS document)

Engine version mutation between PROMOTE and ATTEST = contamination.
The full bundle (candidate_hash + engine_version + train_set_hash +
heldout_set_hash + metric_hash + threshold_hash + result_hash) makes
a reproducibility receipt: any reviewer with the same engine version
and seeds must obtain identical results.

---

## §10. Deprecation Cycle

Modification of this document or its parameters requires:

1. New cycle (`Cycle 28A: mining_protocol deprecation`).
2. Pre-reg PREDICTIONS-NNN.md naming the parameter, justifying the
   change, and committing to the new value.
3. Attestation of both the old and new versions in the primitives
   ledger.
4. ALL stable_active primitives promoted under the old protocol
   marked `deprecated_old_protocol`.  They remain in the dictionary
   but are flagged in version reports.  Re-promotion under new
   protocol requires fresh held-out evaluation against new
   parameters.

Quiet edits (e.g., a typo fix) are NOT permitted without deprecation
cycle.  This is the same iron rule applied to META-SEMANTICS.md.

---

## §11. Contamination Inventory (specific to mining)

In addition to META-SEMANTICS.md v2 §11 events:

| event | mining-specific consequence |
|-------|------------------------------|
| held-out substrate hash appears in discovery trace | entire discovery batch voided |
| MAX_LEN raised after seeing candidate that exceeded old limit | future promotions until deprecation cycle voided |
| `EVAL_TOP_K` raised after seeing rank-K+1 candidate | same |
| candidate re-ranked between SPECIFY and FREEZE | candidate voided |
| support_count recomputed after FREEZE | candidate voided |
| `seed-of-run` reused across runs without explicit attestation | resulting candidates contaminated; force re-discovery with fresh seed |

---

## §12. What This Document Does NOT Promise

- It does NOT promise the mining algorithm will find useful
  candidates.
- It does NOT promise the parameters are optimal — only committed.
- It does NOT specify the algorithm's implementation; only the
  contract (inputs, outputs, hyperparameters, contamination rules).
- It does NOT enforce execution semantics — those are in the meta-
  primitives (cycle 25A/B) and held-out infrastructure (cycle 26).

The cycle 27 implementation is judged against this document.  Any
discrepancy = code bug, not protocol bug.

---

## §13. Cross-references

- docs/META-SEMANTICS.md v2 (commit 360604d, ledger sha 9f43e3a8)
- sixth/meta/tier1.rkt (cycle 25A, commit 34cad87) — current
  `WINDOW_K=20`, `REPEAT_R=3`, `MIN_LEN=2`, `MAX_LEN=5` constants
- sixth/meta/tier2.rkt (cycle 25B, commit 2421e0f) — Tier 2 stubs
  (FREEZE-CANDIDATE, HELD-OUT-EVAL, PROMOTE-STABLE, etc.) gate
  closed in plumbing cycle
- substrates/manifest.6th (cycle 25B) — frozen train+heldout set
  (12 substrates total)

---

## §14. Attestation

This document is attested via
`scripts/attest_prediction.sh docs/mining_protocol.md` and committed
in cycle 25C.  Future modifications require new attestation and
explicit deprecation cycle per §10.
