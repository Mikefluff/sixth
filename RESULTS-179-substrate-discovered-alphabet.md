# RESULTS-179 — Substrate-Discovered Alphabet Audit (cycle 34C-bis)

**Date executed:** 2026-05-24
**Companion to:** `RESULTS-178-bootstrap-alphabet-archaeology.md`
**Pre-reg lineage:** `examples/PREDICTIONS-178-alphabet-archaeology.md`
(post-execution addendum 2026-05-24 clarifies the bootstrap-vs-discovered
scope split)
**Method:** evidence-first, lineage-required.  For each candidate
cand_NNN, verify all 10 criteria for substrate-discovered primitive.

---

## CORE QUESTION

> Which cand_NNN entities were **not written by the engineer's hand**
> but were instead **found by the system's own process** — passed the
> full pipeline (DETECT-MOTIF-AUTO → SHADOW-CHECK → coupling gate →
> energy gate → HELD-OUT-EVAL → PROMOTE-STABLE) AND persisted in
> the active dictionary across metabolism cycles AND are not
> fixture-only?

---

## CORE INVARIANT (binding)

> **A discovered primitive must have a lineage.  No lineage, no
> discovery.**

> **Hand-authored machinery (Layers 0/1/3/4) cannot be counted as
> discovered primitive.**

This audit covers Layer 2 only: cand_NNN entries that survived the
full protocol.

---

## Ten criteria for substrate-discovered primitive (per user spec)

A candidate qualifies only if ALL ten criteria are met:

1. auto-detected (not hand-authored motif)
2. has cand_NNN identity
3. passed SHADOW-CHECK
4. passed coupling gate (N=5 uses across M=3 distinct sessions)
5. passed energy gate (net_delta_e < 0)
6. passed HELD-OUT-EVAL (wins ≥ 4/6)
7. got PROMOTE-STABLE
8. persisted in active dictionary across metabolism cycles
9. not fixture-only
10. not demo-only unless explicitly marked as demo result

---

## Section 1 — Search method and results

### Search 1 — persistent promoted dictionary

```
ls stdlib/promoted/
```

**Result:** `No such file or directory`

META-SEMANTICS.md §6 (cycle 25 spec) promised:

> **Stable (Tier 2)**: stored as `stdlib/promoted/<cycle>/
> cand_NNN.6th` with full provenance comment.  Loaded into every
> runtime via standard `use` mechanism.

**The directory was never created.**  No cand_NNN has ever been
written to a persistent stdlib location.

### Search 2 — cand_NNN references in persistent stdlib

```
grep -rn "cand_[0-9]" stdlib/
```

**Result:** zero matches.  The shipped stdlib (`prelude.6th`,
`peano.6th`, `graph.6th`, `bfs.6th`, `ca.6th`, `debug.6th`,
`hedge.6th`, etc.) contains no cand_NNN.

### Search 3 — attestation ledger for promotion events

```
attestations/ledger.txt
```

42 lines, all of which are PREDICTIONS-NNN.md pre-reg attestations
(or META-SEMANTICS.md / mining_protocol.md attestations).  Zero
entries are `'promote-stable` events for any cand_NNN.

(`COMMIT-PRIMITIVE` and `PROMOTE-STABLE` write to the runtime
ledger inside an active engine session — a different ledger from
the pre-reg attestation file — but that runtime ledger is in-memory
and per-session.  Nothing persists.)

### Search 4 — cand_NNN occurrences in examples/

```
grep -l "PROMOTE-STABLE\|cand_001\|cand_002\|DETECT-MOTIF-AUTO" examples/*.6th
```

Many matches.  All are in `examples/*.6th` demo files (143-176+).
Each demo:
- starts with `RESET` (fresh state)
- hand-constructs a motif (e.g., `MARK MARK bi-edge` or
  `MARK drop` repeated)
- INDUCEs cand_001 / cand_002 from the construction
- drives the protocol within a single test run
- asserts pass conditions
- ends with `REPORT`

**No cand_NNN survives beyond `REPORT`.**  Each demo is a closed
deterministic test fixture.

---

## Section 2 — Per-criterion verification (binding)

For each of the 10 criteria, where do candidates stand?

| # | criterion | status across ALL examined cand_NNN |
|---|-----------|--------------------------------------|
| 1 | auto-detected (not hand-authored motif) | **PARTIAL** — demos 149-152 use `DETECT-MOTIF-AUTO`, but the **workload that produces the motif is itself hand-crafted** by the demo (e.g., `MARK drop` repeated 4 times to ensure the auto-detector finds it).  No demo runs auto-detection over a substrate workload that the engineer did NOT explicitly design to trigger discovery. |
| 2 | cand_NNN identity | YES — all promoted cands get cand_001 / cand_002 / etc. identifiers |
| 3 | passed SHADOW-CHECK | YES — demo 155 etc. |
| 4 | coupling gate (N=5, M=3) | YES — demo 155 drives 5 uses across 3 NEW-SESSIONs |
| 5 | energy gate (delta_e < 0) | YES — demos 147 (happy), 148 (rejects length-1) |
| 6 | HELD-OUT-EVAL ≥ 4/6 wins | YES — demo 155 demonstrates pass; demo 156 demonstrates fail; demo 157 demonstrates absent-substrate rejection |
| 7 | PROMOTE-STABLE | YES — demo 155 returns `'stable-active` status |
| 8 | persisted across metabolism cycles | **NO — there is no persistence layer.** `stdlib/promoted/` does not exist; cand_NNN dies at session end. |
| 9 | not fixture-only | **NO — every cand_NNN occurrence is a test fixture.** |
| 10 | not demo-only | **NO — every cand_NNN occurrence is demo-only.** |

---

## Section 3 — Lineage check

For each cand_NNN in the demo corpus, does the lineage trace pass
all 10 criteria?

| cand_NNN | criteria 1-7 pass | criterion 8 | criterion 9 | criterion 10 | discovered? |
|----------|-------------------|-------------|-------------|--------------|-------------|
| cand_001 in demo 143 (runtime-promotion smoke test) | YES | NO | NO | NO | **no** |
| cand_001 in demo 147 (energy-gate happy) | YES | NO | NO | NO | **no** |
| cand_001 in demo 149 (auto-discovery happy) | YES (auto-detected via DETECT-MOTIF-AUTO) | NO | NO | NO | **no** |
| cand_001 in demo 155 (stable-promotion happy) | YES | NO | NO | NO | **no** |
| cand_001/002 in demos 158-176 (metabolism arc) | YES | NO (resets at end of each test) | NO | NO | **no** |

**Discovered alphabet count: 0.**

---

## Section 4 — Finding (binding)

> **The system currently has a bootstrap alphabet but NO durable
> substrate-discovered alphabet.**

Every cand_NNN entity in the codebase is a test fixture inside an
isolated demo file.  None has been auto-detected over an
engineer-blind workload.  None has been persisted across runs.
None has been loaded by any production substrate use.

This is **not a failure**.  It is the honest current state.

Reasons (descriptive, not justificatory):

1. **No persistence layer was ever implemented.**  META-SEMANTICS.md
   §6 promised `stdlib/promoted/<cycle>/cand_NNN.6th`; it was never
   built.  Without it, even a perfectly-promoted cand_001 evaporates
   at process exit.

2. **No engineer-blind workload exists.**  All demos using
   `DETECT-MOTIF-AUTO` (149-152) seed the workload by hand to ensure
   the auto-detector finds something.  This is a protocol test, not
   a discovery experiment.

3. **The metabolism arc (cycles 29-33) tested STAYING-PROMOTED
   semantics for cand_NNN fixtures, not WHETHER any substrate-
   discovered cand emerges in practice.**  The demos demonstrate
   that PROMOTE-STABLE → persistent-active works in principle within
   one test run, but no test runs the system end-to-end across
   sessions, mines from non-trivial substrate workloads, and tracks
   what survives.

4. **The cycle 34A external-energy proposal extends mechanisms over
   a layer that has no occupants.**  If Layer 2 is empty, then
   external_credit / capacity / subsidized are being designed to
   modulate the survival of entities that don't exist yet.

---

## Section 5 — Implication for ontology and for cycle 34D

### For ontology

The system's true "alphabet" — in the user's sense of "what was
found in the process" — has size **zero**.

The 7 entries classified `primitive` in RESULTS-178 are bootstrap.
They are necessary; the substrate cannot operate without them.  But
they were placed by the engineer, not discovered by the substrate.

To honestly describe the system in the cycle 34D ontology synthesis:

> The system has a **bootstrap alphabet of 7 entries** (3 Layer-0
> substrate axioms + 4 Layer-1 protocol verbs).  It has a
> **discovered alphabet of 0 entries** (Layer 2 currently empty).
> Layers 3 and 4 are populated with engineer-introduced diagnostics
> and implementation knobs.
>
> The system has demonstrated the PROTOCOL by which discovery would
> populate Layer 2 (demos 143-157) but has not yet RUN that protocol
> against an engineer-blind workload with cross-session persistence
> enabled.

### For cycle 34D synthesis

CLAIMS.md and META-SEMANTICS.md must reflect:

1. **The bootstrap alphabet is 7 (per RESULTS-178), not 38.**
   The engineering surface (~38 Tier 1 entries) is a mix of
   bootstrap primitives (7), diagnostics (status labels), and
   implementation (counters, knobs).

2. **The discovered alphabet is 0 (per this audit).**  No claim
   like "Sixth discovers its own primitives" can be made as Tier 1
   fact today.  The architectural CAPABILITY for discovery exists
   (protocol demos pass); the EVIDENCE OF DISCOVERY in production
   does not.

3. **A clean separation between protocol-verification (demos pass)
   and discovery-claims (cands persisted) must be added to CLAIMS.md.**
   It is one thing to claim "the promotion gate works" (demo 155
   verifies this); it is another to claim "the system has alphabet
   it discovered for itself" (RESULTS-179 refutes this).

4. **Cycle 34A (external energy) remains correctly blocked.**
   Adding mechanisms over an empty Layer 2 would be premature.
   The cycle 34A pre-reg presupposes a population of cand_NNN
   to apply external energy to; in practice the only candidates
   are fixtures.

### For future cycles

If the discovered alphabet is to become non-empty, the system needs:

1. **`stdlib/promoted/` directory and the file-write step in
   PROMOTE-STABLE that META-SEMANTICS §6 already specified.**
   Without it, no persistence is possible.

2. **A discovery harness:** a substrate workload generator that the
   engineer does NOT design to trigger a specific motif, run for
   long enough that auto-detection has something to find, with
   cross-session persistence enabled.

3. **A discovered-cand ledger:** an attestation file listing every
   cand_NNN ever promoted-and-persisted, with provenance (workload
   hash, discovery cycle, motif body, held-out result, attestation
   row).  This would BE the discovered alphabet.

4. **A metabolism log that survives across runs.**  Currently the
   metabolism counters reset at every `RESET`; a persisted cand
   would need persisted metabolism state too.

These are not in scope for cycle 34D synthesis — they are
proposals for a future cycle (35+).  Cycle 34D documents the
current state honestly: bootstrap 7, discovered 0.

---

## Section 6 — Compliance with pre-reg PASS criteria (adapted)

The original pre-reg's PASS criteria (PREDICTIONS-178) were
designed for the bootstrap audit and do not all transfer cleanly.
The adapted criteria for this substrate-discovered audit:

| # | adapted criterion | result |
|---|-------------------|--------|
| 1 | Every cand_NNN in scope is examined against 10 criteria | ✓ |
| 2 | Each criterion check cites file:line or directory state | ✓ |
| 3 | If discovered count > 0, each entry has full lineage record | n/a — count is 0 |
| 4 | If discovered count = 0, that finding is documented honestly | ✓ — Section 4 |
| 5 | No new cands are claimed without lineage | ✓ |
| 6 | The audit does not retroactively rename fixtures as discoveries | ✓ |
| 7 | Implications for CLAIMS.md / META-SEMANTICS.md / cycle 34A are stated | ✓ — Section 5 |

**PASS as substrate-discovered audit.**

---

## Section 7 — Honest summary

```
Bootstrap alphabet (engineer-placed, RESULTS-178):  7 entries
  Layer 0 (substrate axioms):  distinction, boundary, trace, collapse (4)
  Layer 1 (protocol grammar):  commit, shadow-check, contaminate     (3)
  [Note: RESULTS-178 placed collapse as Layer 0 grammar; counted there.]

Discovered alphabet (system-found, RESULTS-179):    0 entries

Diagnostics layer (engineer-placed):                5 status labels
  'stale, 'demotion-candidate, 'dependency-held,
  'dependency-supported, 'subsidized (proposed)

Implementation layer (engineer-placed):             many constants and counters
  INFLATION-COST-PER-CAND=1, MOMENTUM-STALE-TOLERANCE=1,
  MOMENTUM-NEGATIVE-THRESHOLD=2, MOMENTUM-HISTORY-WINDOW=3,
  STABLE-WINS-THRESHOLD=4, support_credit, external_credit, etc.
```

**The system has a working protocol for discovery, no instances of
discovery, a rich engineering bootstrap, and a growing diagnostic
surface.**

Honestly describing this is what the cycle 34D synthesis should
accomplish.

---

## References

- `RESULTS-178-bootstrap-alphabet-archaeology.md` — companion bootstrap audit
- `examples/PREDICTIONS-178-alphabet-archaeology.md` — pre-reg (with
  post-execution scope addendum)
- `docs/META-SEMANTICS.md` §6 — Tier 2 promotion spec (promised
  `stdlib/promoted/` persistence)
- `stdlib/` — current shipped stdlib (no cand_NNN entries)
- `attestations/ledger.txt` — pre-reg attestation log (no promote events)
- `examples/143-152, 155-157, 158-176*.6th` — fixture-only cand_NNN demos
- User spec 2026-05-24 — "discovered primitive must have a lineage; no
  lineage, no discovery"
