# Cycle 35 Proposal — Persistence Layer for Discovered Candidates

**Status:** PROPOSAL (not yet pre-registered).
**Date drafted:** 2026-05-24.
**Source:** cycle 34D synthesis, after audits
`RESULTS-178-bootstrap-alphabet-archaeology.md` and
`RESULTS-179-substrate-discovered-alphabet.md` established that
**L2 (substrate-discovered candidates) is empty**.

This document is a forward-design sketch.  It is NOT a pre-reg.
Pre-reg would be `PREDICTIONS-NN.md` written after the team
confirms cycle 35 as the next direction.

---

## Why this cycle exists

Cycle 34D establishes:

> Sixth currently has a working discovery protocol, verified on
> fixtures and demo runs, but has zero durable substrate-discovered
> primitives persisted across real cross-run metabolism.

The reason is structural: META-SEMANTICS.md §6 (cycle 25 spec)
promised that `PROMOTE-STABLE` would write to `stdlib/promoted/
<cycle>/cand_NNN.6th`, and that those files would be loaded by
every subsequent runtime.  **This persistence step was never
built.**  Without it, every `PROMOTE-STABLE` is a within-test
event; the cand dies at process exit.

Until persistence exists, **L2 cannot have occupants**.  Every
mechanism the engineering surface has added (cycles 29–34A) that
operates on L2 — metabolism, decay, inflation, dependency tracking,
support credit, external energy, capacity, subsidized status — is
operating on **fixtures**.  This is not wasted work (the protocol
mechanics were verified), but it is not the system actually
producing alphabet for itself.

**Cycle 35 turns L2 from a category-without-members into a
category-that-can-have-members.**

---

## Core principle

> Discovery without persistence is theatre.  A cand that doesn't
> survive process exit was not really discovered; it was rehearsed.

> A discovered primitive is one with a **lineage** that the
> system itself can reload and re-use in a future run.

---

## Minimum scope

The following are the irreducible deliverables.  Any sub-set
short of this would still leave L2 empty.

### 1. `stdlib/promoted/` directory + file-write step

`PROMOTE-STABLE` must, on success, write a new file:

```
stdlib/promoted/<cycle>/cand_<NNN>.6th
```

The file contains:
- header comment block: provenance (discovery cycle, workload
  hash, motif body, held-out wins, attestation row)
- the cand's motif as a Sixth definition:
  `: cand_<NNN>  <motif body> ;`

Once written, the file is **immutable**.  Any later
`ROLLBACK-STABLE` writes a sibling marker, not edits.

### 2. Promote events in attestation ledger

Currently `attestations/ledger.txt` records only pre-reg
attestations.  Cycle 35 extends the format to also record:

```
<iso-timestamp>  promote-stable  cand_<NNN>  <provenance-sha>  <git-head>
```

This makes a substrate-discovered primitive externally auditable —
the lineage row in the ledger is what a reviewer reads to
verify "yes, this cand was promoted, not hand-written."

### 3. Per-cand lineage records

Each promoted cand_NNN gets a record in
`stdlib/promoted/<cycle>/cand_<NNN>.lineage.json`:

```json
{
  "cand_id": "cand_042",
  "discovery_cycle": 35,
  "discovered_at": "2026-NN-NNT...Z",
  "workload_source": "stress-test|application|exploration|...",
  "workload_hash": "sha256:...",
  "motif_body": ["MARK", "drop", "NODES"],
  "motif_length": 3,
  "shadow_check_pass": true,
  "coupling": {"uses": 7, "sessions": 4},
  "energy_gate": {"delta_e": -12, "passed": true},
  "held_out_eval": {"wins": 5, "total": 6, "passed": true},
  "promote_stable_ledger_row": "2026-NN-NNT...Z|...",
  "attestation_anchor": "tag-NNN or ots-...",
  "tag": "production"
}
```

Tag field is one of `fixture`, `demo`, `production` — explicit
provenance so future audits can filter "show me only
production-tagged cands."

### 4. Cross-run dictionary persistence

Engine boot loads `stdlib/promoted/**/cand_*.6th` via the
standard `use` mechanism.  Once loaded, the cand is callable
exactly as any other word.  Its lineage record is loaded into
`law_state` metadata so `CAND-STATUS` / `CAND-LINEAGE`
inspections return the full provenance.

### 5. Cross-run metabolism

Promoted cands need cross-run metabolism counters.  Open
question: does `m_native` history reset at engine boot, or
persist?

**Proposal:** persist last `MOMENTUM-HISTORY-WINDOW` epochs as
part of the `.lineage.json` (or sibling `.metabolism.json`).
On boot, history is loaded so the metabolism gate can fairly
assess "has this cand been productive recently or is it stale?"

This makes a `'demotion-candidate` status that crosses runs
meaningful: a cand that's been stale for N epochs is auto-
decomposed on the (N+1)th boot.  `ROLLBACK-STABLE` deletes the
`.lineage.json` (or moves to `.rolled-back.json` for audit).

### 6. Fixture / demo / production tagging

Every `INDUCE-RUNTIME` call gets a source tag:

```
INDUCE-RUNTIME ( motif source-tag -- cand-id )
```

Where `source-tag` is one of `'fixture`, `'demo`, `'production`.

- `'fixture` cands die at `REPORT` (current behavior); never
  promoted to `stdlib/promoted/`.
- `'demo` cands may be promoted but are tagged in lineage as
  demo-derived; not counted for L2 substrate-discovered tally.
- `'production` cands are the only ones counted as genuine L2
  discoveries.

This makes the L2 counter unambiguous: the system can answer
"how many production-tagged cands have you persisted?" with a
simple ls + filter.

Backwards compatibility: existing demos default to
`source-tag = 'fixture` if the tag is omitted (so cycle 25-34
demos keep passing without modification).

### 7. Discovery harness (substrate workload that is engineer-blind)

Currently every demo seeds a hand-crafted workload to ensure
auto-detection finds something.  Cycle 35 adds at minimum one
**discovery harness**: a workload generator that the engineer
does NOT design around any specific motif, with cross-session
persistence enabled.

Example: a randomized stress-test runs N=10000 substrate ops
drawn from a generator with controlled distribution; after the
run, the engine reports any cand_NNN that auto-detected, passed
all gates, and persisted.  If the answer is "zero in N=10000,"
that's still an honest data point.  If the answer is "cand_004
with motif (MARK NODES drop) persisted with held-out wins 5/6,"
that's the **first real L2 entry**.

---

## What cycle 35 is NOT

- Not a new mechanism over L2 — that's cycle 34A (still blocked)
  or future cycles.
- Not a tuning of existing thresholds (cycle 31 inflation,
  cycle 28 wins threshold, etc.).  Those are L4 knobs, separate
  concern.
- Not a discovery-quality claim.  Cycle 35 only enables L2 to be
  non-empty; whether the discoveries are "good" is a separate
  evaluation.
- Not a deprecation of fixture demos.  Demos 143-176 remain
  valid as protocol tests under the `'fixture` tag.

---

## Expected outcomes

After cycle 35 lands, the following questions become answerable
mechanically:

1. **How many production-tagged cand_NNN have ever been
   promoted?**  `ls stdlib/promoted/*/cand_*.6th | filter
   .lineage.json tag=production | wc -l`
2. **How many of those are still callable at the next engine
   boot?**  Compare load-time dictionary against persisted lineage.
3. **What is the survival rate over N boots?**  Trace each
   cand_NNN across boot histories.
4. **Which workload sources have produced the most surviving
   cands?**  Group by `.lineage.json workload_source`.
5. **What does the discovered alphabet look like over time?**
   Time-series of L2 occupancy.

These metrics are what would let cycle 36+ make substantive
claims about discovery quality, not just protocol verification.

---

## Pre-conditions before cycle 35 starts

1. CLAIMS.md updated with CLAIM-1 through CLAIM-5 (cycle 34D — done).
2. META-SEMANTICS.md §18 in place (cycle 34D — done).
3. Team agreement that populating L2 is the right priority over
   adding more mechanism (cycle 34A external energy) over an
   empty L2.

---

## Pre-conditions before cycle 34A unblocks

Cycle 34A (external energy + capacity + subsidized) implementation
unblocks AFTER cycle 35 lands, AND AFTER at least one production-
tagged cand_NNN has persisted across at least one engine boot.

Until both conditions hold, 34A would only modulate fixtures.

---

## Open design questions

1. **Where does cross-run metabolism state live?**  In
   `.metabolism.json` sibling files, or in a single
   `stdlib/promoted/_metabolism-state.json`?
2. **What happens to a cand_NNN promoted in cycle 35 if a later
   cycle's metabolism rules decompose it?**  Move to
   `stdlib/promoted/_decomposed/` for audit, or delete entirely?
3. **Should `'production` cands be loadable across forks of the
   repo?**  E.g., if I clone the repo, do I inherit the prior
   discoveries?  Probably yes for reproducibility, but lineage
   tags should make this explicit.
4. **Does cross-run persistence interact with the iron rule on
   held-out evaluation?**  A cand can only be HELD-OUT-EVAL'd
   once; cycle 35 must ensure boot-time loading does NOT trigger
   re-evaluation.
5. **Migration path: should existing fixture-demo cands be retro-
   tagged as `'fixture` in their .6th files?**  Mechanical change
   to demos 143-176, but it would make the tag-system explicit.

---

## References

- `RESULTS-179-substrate-discovered-alphabet.md` — the L2=0 finding
- `RESULTS-178-bootstrap-alphabet-archaeology.md` — bootstrap alphabet
- `CLAIMS.md` — CLAIM-1 through CLAIM-5, Ontological five-layer
- `docs/META-SEMANTICS.md` §6 — the original (unfulfilled)
  persistence promise; §18 — five-layer separation
- `examples/PREDICTIONS-177.md` — cycle 34A (blocked) pre-reg
- User spec 2026-05-24 — "сначала орган, потом метаболизм"
