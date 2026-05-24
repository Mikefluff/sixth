# PREDICTIONS-178 — Alphabet Archaeology (cycle 34B)

**Date pre-registered:** 2026-05-24

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
Initial attestation: see ledger row dated 2026-05-24.

---

## SCOPE CLARIFICATION (post-execution addendum 2026-05-24)

This pre-reg's scope is **bootstrap alphabet** — the hand-written
engineering foundation of the system — NOT the substrate-discovered
alphabet (cand_NNN entities the system itself auto-detected and
promoted through the protocol).

Per user clarification mid-cycle (after 34C execution):

> We don't count primitives you added by hand — only those that
> were found in the process.

The 32-entity candidate list in this pre-reg includes hand-authored
meta-primitives (commit, shadow-check, held-out-eval, etc.) and
substrate axioms (distinction, boundary, trace, collapse) plus the
later-added statuses and counters.  All 32 are engineer-introduced;
none was discovered by the substrate.

**Renamed deliverable:** `RESULTS-178-bootstrap-alphabet-archaeology.md`
(was `RESULTS-178-alphabet-archaeology.md`).

**Result status:**
- PASS as bootstrap audit
- NOT PASS as substrate-discovered audit

A separate substrate-discovered audit is performed under cycle 34C-bis,
output `RESULTS-179-substrate-discovered-alphabet.md`.

### Five-layer ontological architecture (binding for future cycles)

| layer | content | source |
|-------|---------|--------|
| **L0 — Substrate axioms** | distinction, boundary, trace, collapse | bootloader (engineer) |
| **L1 — Protocol grammar** | commit, shadow-check, contaminate, promote-stable, held-out-eval | machinery (engineer) |
| **L2 — Discovered candidates** | cand_NNN that passed full pipeline AND persisted | SYSTEM (via DETECT-MOTIF-AUTO + protocol) |
| **L3 — Diagnostics** | stale, subsidized, dependency-supported, etc. | engineer |
| **L4 — Implementation** | counters, ttl, credit, thresholds | engineer |

**Binding rules:**

1. Hand-authored machinery (L0/L1/L3/L4) **cannot be counted as
   discovered primitive.**  This pre-reg's audit covers L0/L1/L3/L4
   classification only.
2. A discovered primitive (L2) must have a **lineage**: AUTO-DETECTED
   via DETECT-MOTIF-AUTO, passed SHADOW-CHECK, passed coupling gate
   (N=5, M=3), passed energy gate, passed HELD-OUT-EVAL, got
   PROMOTE-STABLE, persisted in active dictionary across metabolism
   cycles, NOT fixture-only.
3. **No lineage, no discovery.**
4. Bootstrap and discovered alphabets are tracked separately;
   conflating them obscures whether the system has produced any
   genuine alphabet of its own.

These rules supersede the original pre-reg's "primitive" language
where ambiguous.  The original schema remains valid; only the SCOPE
INTERPRETATION is clarified.

---

## This is NOT a feature cycle

Cycles 25–34A added mechanism after mechanism: laws, metabolism,
inflation, dependency-supported, subsidized, capacity, leak.  Each
addition was operationally justified, but operational utility is
**not** the same as alphabet-level primitivity.  This cycle steps
back and performs an **ontological audit**: which of the entities
now in circulation are genuine primitive distinctions of the system,
and which are derived constructs, diagnostic labels, or
implementation conveniences that crept in late and are pretending
to be alphabet?

The deliverable is not a new feature.  It is a classification table,
backed by archaeological evidence from cycles 25–34, that demotes
late conveniences from "primitive" to whichever lower tier they
actually belong to.

The success condition is **a smaller alphabet, not a larger one.**

---

## CORE QUESTION (binding)

> Which of the entities currently in circulation in cycles 25–34
> can be traced back — by their underlying *distinction*, not by
> their current *name* — to an early cycle?  Which entities are
> derivable from a smaller alphabet?  Which are diagnostic labels
> rather than primitives?

If an entity cannot be located in an early cycle even as an
**unnamed distinction**, it cannot be primitive.  It is either
derived (assembled from earlier primitives), diagnostic (a
monitoring label introduced for operational convenience), or
implementation detail (a code-level mechanism that does not enter
the system's ontology).

---

## CORE INVARIANT (binding)

> **A primitive is not something useful.  A primitive is a
> distinction that cannot be removed without destroying the
> system's ability to make distinctions.**

Restated negatively, for the avoidance of post-hoc rationalization:

> **No entity earns primitive status by virtue of being convenient
> in late cycles.  No entity earns primitive status by virtue of
> having a name.  No entity earns primitive status by virtue of
> appearing in the type system or the dispatch table.**

The archaeological test is **necessity**, not utility.

---

## Four-tier separation (no entity belongs to more than one)

The audit will classify every candidate entity into exactly one of
four layers:

| Layer | What it contains | Test |
|-------|------------------|------|
| **Alphabet** | Minimal distinctions the system makes | If removed, system can no longer distinguish anything |
| **Grammar** | Operations over distinctions (verbs) | If removed, distinctions still exist but cannot combine |
| **Diagnostics** | Observation states (status labels) | If removed, system runs unchanged; only inspectability suffers |
| **Implementation** | Code-level parameters and counters | If removed, the same algorithm could be expressed without it (constants, knobs) |

**Provisional working candidates** (these are hypotheses, NOT a
pre-accepted answer):

| Layer | Provisional members | Status |
|-------|--------------------|--------|
| Alphabet (5) | distinction, boundary, trace, pressure, flow | To be tested |
| Grammar (5) | resolve, commit, repair, decay, adapt | To be tested |
| Diagnostics (4+) | stale, subsidized, dependency-supported, demotion-candidate | To be tested |
| Implementation (4+) | ttl, thresholds, counters, tolerances, epoch windows | To be tested |

Audit may reclassify, demote, or remove any of these.

---

## Candidate entities to classify (binding list — minimum)

Every entity in this list must receive exactly one classification.
The audit may extend the list (e.g., if early cycles reveal an
unnamed distinction not in this list).  It may not omit entries.

```
distinction
boundary
trace
persistence
pressure
flow
metabolism
energy_balance
support_credit
external_credit
capacity
inflation
dependency-supported
subsidized
stale
demotion-candidate
auto-decompose
decay
repair
adaptation
commit
resolve
held-out-eval
shadow-check
promote-stable
law-momentum
observed-dep
dependency-held
inscribe
forget
collapse
contaminate
```

Total: 32 entities (minimum binding).  Extension permitted; omission
is not.

---

## Classification taxonomy (5 categories)

Each entity receives exactly one of:

### `primitive`

Genuine alphabet-level distinction.  Removal destroys the system's
ability to make distinctions.

**Acceptance criteria (all required):**
- First UNNAMED occurrence is in cycle 25 or earlier (the foundational
  layer).
- Cannot be expressed as a combination of other primitives in the
  audit.
- Distinction holds without reference to operational utility (i.e.,
  it would still be a distinction in an empty substrate with no
  workload).
- At least one currently-used mechanism would lose its meaning if
  this primitive were removed.

### `derived`

Composite of more basic primitives.

**Acceptance criteria (all required):**
- Can be expressed as a deterministic function over `primitive`
  entries.
- The decomposition formula is given in the classification.
- The derived entity may have a useful name and a useful operational
  surface, but its existence reduces to its components.

### `diagnostic_label`

Status label introduced for monitoring or inspectability.  System
behavior would be unchanged (operationally) if the label were
omitted.

**Acceptance criteria (all required):**
- First appearance was in a cycle introducing a new STATUS, not a
  new mechanism.
- The underlying state transition exists without the label.
- Renaming or removing the label would not change the metabolism's
  outcomes; only the ledger / inspection surface would change.

### `implementation_detail`

Code-level parameter, counter, or tolerance.  Necessary for the
algorithm to terminate, but does not enter the ontology.

**Acceptance criteria (all required):**
- Is a numeric constant, tuning knob, or per-cand counter (NOT a
  qualitative state).
- A reasonable alternative implementation could express the same
  algorithm without it (with different specific knobs).
- The constant's specific value is arbitrary at the level of
  classification (the audit notes the value but does not defend it
  as principled).

### `reject`

Entity is unnecessary or duplicates an existing distinction.

**Acceptance criteria (all required):**
- Either: (a) duplicates an entity already classified as primitive
  or derived; or (b) was introduced speculatively and no current
  mechanism depends on its distinction.
- Removal would not regress any active demo.

---

## Required method (binding schema per entity)

For each entity in the candidate list, produce a record with these
fields:

```
entity:                       <string, name as currently used>

first_named_occurrence:
  cycle:                      <int — first cycle where this exact name appears>
  artifact:                   <file path>
  commit:                     <short sha>

first_unnamed_occurrence:
  cycle:                      <int — first cycle where this distinction is
                              implicitly drawn, even without the current name>
  artifact:                   <file path>
  commit:                     <short sha>
  evidence:                   <quote or paraphrase showing the implicit distinction>
  OR
  result:                     "not_found_before_naming"   # critical signal

minimal_distinction:
  <single-sentence statement of the qualitative difference this entity makes>

depends_on:
  <list of other entities in the candidate list that must already
   exist for this entity to be meaningful>

classification:
  primitive | derived | diagnostic_label | implementation_detail | reject

reason:
  <2-4 sentences citing first_unnamed_occurrence (or its absence)
   and depends_on chain.  May not cite "useful for cycle N" as
   justification for primitive status.>

evidence:
  - <file:line or commit reference>
  - <quote, ledger event, or test assertion that shows the distinction>

keep_as_alphabet:
  yes | no | already-derived
```

Records are aggregated into a single output table (see "Expected
output" below).

---

## Archaeology rule (binding — anti-post-hoc-rationalization)

**Forbidden form of argument:**

> Entity X is primitive because it is convenient in cycle N
> (where N > first naming cycle).

**Required form:**

> The DISTINCTION underlying entity X (described as
> `<minimal_distinction>`) is present in cycle M (where M is small),
> in the form of `<evidence>`.  Therefore X may be classified as
> primitive (if M ≤ 25 and the distinction is irreducible) or as
> derived (if the distinction is reducible to entities already
> present in cycle M).  OR: the distinction is NOT present before
> cycle N; X cannot be primitive.

Specifically banned reasoning patterns:
- "Without subsidized we couldn't tell why a cand was kept alive
  in cycle 34" — circular: it asserts primitivity from late
  diagnostic need.
- "Energy_balance is fundamental because metabolism requires it" —
  circular: it asserts primitivity from a more recent derived
  concept.
- "The dispatch table contains this primitive" — circular: dispatch
  table membership is a result of implementation choice, not
  evidence of ontological primitivity.
- "It has a Tier 1 primitive entry, therefore it's primitive" —
  conflates the engineering tier system with ontological tier.

---

## Hypotheses (binding — to be tested by the research)

Each hypothesis will be evaluated CONFIRMED or REFUTED based on the
classification records, with reference to the evidence cited there.

### H1 — Low-level alphabet is smaller than current primitive set

**Claim:** the genuine alphabet is at most 7 entries; current
mechanism count (cycles 25–34) is much larger; therefore most
current "primitives" must demote.

**Refutation condition:** more than 10 entities receive `primitive`
classification with valid evidence.

**Probable primitive candidates** (testable subset of the candidate
list):
```
distinction, boundary, trace, persistence, pressure, flow,
decay, repair, commit, resolve
```

H1 confirmed iff: at most 7 of the 32 candidate entities receive
`primitive` after audit.

### H2 — Most operational statuses are derived

**Claim:** the following entities are derived or diagnostic, not
primitive:
```
stale, demotion-candidate, dependency-supported, subsidized, auto-decompose
```

Each must reduce to a combination of more basic distinctions in
the audit.

**Refutation condition:** any of the above five receives `primitive`
classification with valid evidence.

H2 confirmed iff: all five are demoted to `derived` or
`diagnostic_label`.

### H3 — Energy balance is not quantity, but flow constraint

**Claim:** `energy_balance` is NOT a simple numeric counter.  The
correct underlying distinction is:

> `energy_balance` ≡ a structure's ability to receive, hold,
> redistribute, and release pressure without boundary collapse
> or metabolic stagnation.

**Refutation condition:** the audit finds that all uses of energy
in cycles 25–34 reduce to a single integer counter with no flow
semantics.

H3 confirmed iff: the audit records demonstrate that energy
distinctions in early cycles (the cycle 25E observational-only
constraint, the cycle 31 inflation-cost, the cycle 33 carry-offset)
are best read as flow-and-capacity primitives, not as counter
arithmetic.

### H4 — External credit is not life

**Claim:** a structure that survives only via `external_credit`
is **not alive**; it is externally maintained.

**Refutation condition:** the audit finds an early cycle in which
external support was treated as evidence of intrinsic viability.

H4 confirmed iff: the cycle 34A invariants (truth-immune,
no-subsidized-support-contribution) reduce to an EARLY distinction
between self-sustained and externally-supported, where the
distinction can be located in cycle 25 (substrate-internal
metabolism) or 28 (inflation gate against ineffective laws).

### H5 — Metabolism requires throughput

**Claim:** `metabolism` ≠ accumulation.  A live structure must
transform and pass through pressure, not merely hoard it.

**Refutation condition:** the audit finds that the only operational
signature of metabolism in cycles 25–34 is the **count** of
operations, not the **flow** through them.

H5 confirmed iff: cycle 29's momentum formula (`reuse - carry -
fails - inflation`) can be read as a flow-balance equation, not
a counter-difference.  Inflation in particular is the "passing
through" tax.

---

## Negative tests (binding)

The audit must explicitly verify these negative conditions.  Each
NEG case is a guard against a tempting category error.

### NEG-1 — Late convenience is not primitive

If an entity is operationally useful only after cycle 30 AND its
underlying distinction cannot be located before cycle 30, it
CANNOT receive `primitive` classification.

**Required output:** at least one entity in the candidate list
that fits this pattern must be classified `diagnostic_label` or
`implementation_detail`.  Likely candidates:
`subsidized`, `dependency-supported`, `dependency-held`,
`auto-decompose`.

### NEG-2 — External support does not imply life

The classification of `subsidized` MUST mark it as NOT-ALIVE
distinction.  If the audit classifies `subsidized` as `alive` or
treats it as evidence of self-sustenance, the cycle fails.

**Required output:** `subsidized` decomposition must include the
distinction `held-by-external-pressure` as separate from
`self-sustaining`.

### NEG-3 — Accumulated energy does not imply metabolism

Pure accumulation without throughput must be distinguishable from
metabolism.  If the audit treats them as the same, the cycle
fails.

**Required output:** the classification of `metabolism` (or its
demotion to `derived`) must explicitly cite throughput / passing
through, not just integration over time.

### NEG-4 — Stale is not dead

The distinction `stale` (trace persists, refresh fails) must remain
distinct from `decomposed` (trace removed).  If the audit collapses
them, the cycle fails.

**Required output:** classification of `stale` must include
`trace_persists = true` and distinguish it from `decomposed` where
`trace_persists = false`.

### NEG-5 — Diagnostic labels cannot become alphabet by naming

If the audit promotes a status label to `primitive` solely because
it has acquired a name and a dispatch entry, the cycle fails.

**Required output:** the cycle 34A status `subsidized` and the
cycle 33 status `dependency-supported` must both NOT be classified
`primitive`.  If they are, this NEG fires.

---

## Pass / fail criteria (binding)

### PASS (all required)

1. **Coverage:** every candidate entity (≥ 32 listed) has a record
   with all schema fields filled.
2. **Evidence:** every classification cites at least one
   `first_unnamed_occurrence` or `first_named_occurrence` with a
   concrete file:line, ledger event, or commit reference.  Unfindable
   occurrences must be honestly marked `not_found_before_naming`.
3. **Smaller alphabet:** AT MOST 10 entities classified `primitive`
   (H1 corollary).  Strict goal: ≤ 7.
4. **Five demotions:** AT LEAST 5 entities currently treated as
   primitive in the engineering surface are demoted to `derived`
   or `diagnostic_label`.
5. **Decompositions:** `energy_balance`, `external_credit`,
   `subsidized` each have a rigorous decomposition into more basic
   distinctions (NOT into "it's a counter / it's a status").
6. **No new entities:** the audit does NOT introduce any new
   primitive that did not appear in cycles 25–34 (this cycle does
   not invent; it audits).
7. **Anti-circular:** no classification cites operational utility
   in a cycle later than the entity's first_unnamed_occurrence as
   the primary justification.

### FAIL (any one triggers)

1. New entities are added as features.
2. Late-introduced status labels are declared primitive only because
   they are convenient.
3. Records lack `first_unnamed_occurrence` evidence (audit accepts
   first_named without searching for earlier unnamed forms).
4. `energy_balance` is reduced to a single numeric counter (H3
   refuted, but reduction trivialized).
5. `subsidized` is conflated with `alive` or `dependency-supported`
   (NEG-2 violated).
6. The classified `primitive` set is LARGER than the entities
   currently in the dispatch tables (the audit failed to demote
   anything).

---

## Expected output (binding — format)

The cycle 34C research will produce a single document
`docs/ALPHABET-ARCHAEOLOGY.md` (or `RESULTS-178-alphabet-archaeology.md`
at repo root) containing:

### Section 1 — Summary table

```
| entity | first_unnamed_occurrence | first_named_occurrence | minimal_distinction | classification | depends_on | keep_as_alphabet |
|--------|--------------------------|------------------------|---------------------|----------------|------------|------------------|
| distinction | ... | ... | ... | primitive | ∅ | yes |
| boundary    | ... | ... | ... | primitive | distinction | yes |
| stale       | ... | ... | trace exists but refresh fails | derived | trace, decay, metabolism | no (label only) |
| subsidized  | ... | ... | form held by external pressure | diagnostic_label | boundary, pressure, external_credit | no |
| ...         | ... | ... | ... | ... | ... | ... |
```

### Section 2 — Per-entity records

One record per entity, in the binding schema.

### Section 3 — Hypothesis evaluation

For each of H1–H5: CONFIRMED or REFUTED, with cited records.

### Section 4 — Negative-test verification

For each of NEG-1 through NEG-5: PASSED or FAILED, with citations.

### Section 5 — Demotion list

Explicit list of entities demoted from current engineering-tier
status to lower ontological tier.  This is the operational
deliverable: "these N entities, while remaining in the dispatch
table as Tier 1 primitives, are ontologically NOT primitive."

### Section 6 — Confirmed alphabet

The final primitive set, expected to be smaller than the current
~38 engineering primitives.  Each member listed with:
- minimal_distinction (single sentence)
- earliest cycle of occurrence (named or unnamed)
- one or two key dependents (what would lose meaning without it)

### Section 7 — Open questions

Entities the audit could not classify confidently.  These remain
open for cycle 34D+ resolution.

---

## Methodological commitments (binding)

1. The research (cycle 34C) will:
   - Read every cycle's PREDICTIONS file (`examples/PREDICTIONS-1*.md`
     and `PREDICTIONS-NN.md` series), focused on cycles 25, 26, 27,
     28, 29 (the foundational layer).
   - Read META-SEMANTICS.md, mining_protocol.md, SUBSTRATE-EQUIV-
     CONJECTURE.md, CLAIMS.md.
   - Read sixth-substrate.scm legacy notes from the legacy/ directory
     (cycle 0 distinctions).
   - Read at least 6 of the cycle 25–29 demo .6th files (the
     earliest empirical surface).
   - grep each candidate entity name across all cycle artifacts to
     locate its first appearance both NAMED and UNNAMED.
2. Naming convention for "unnamed distinction": the research
   identifies the distinction by paraphrase ("the difference
   between a law that earns and a law that decays") and then
   shows where that distinction is operationally drawn, regardless
   of the words used.
3. No mechanism added.  No new VM behavior, no new primitive, no
   new test demo, no new env-memory key.  Cycle 34B/C is purely
   classificatory.
4. If the audit demotes an entity from primitive to derived /
   diagnostic_label, the entity does **NOT** get removed from
   the engineering surface (that would be a separate refactor
   cycle).  It gets RECLASSIFIED in `docs/CLAIMS.md` and
   `docs/META-SEMANTICS.md` only.
5. The audit may extend the candidate list if it finds an unnamed
   distinction in early cycles that was never given a name.  Such
   entries are flagged `discovered_during_audit`.
6. The audit cycle ends with one of:
   - Smaller alphabet (PASS) — cycle 34D is documentation update.
   - Larger or equal alphabet (FAIL) — cycle 34D is failure post-mortem.
7. Attestation BEFORE research.

---

## What cycle 34B/C does NOT claim

- That the demoted entities are unimportant — they remain
  operationally critical; the audit only reclassifies their
  ontological status.
- That the audit's classification is final — it is the best
  current archaeology; later cycles may refine.
- That the alphabet is "the truth" — it is the minimal set of
  distinctions the SYSTEM currently makes.  A different system
  might draw different distinctions.
- That the classification predicts future architecture — it
  describes the current ontology; future cycles may force
  reclassification.
- That removing diagnostic labels would be desirable — they are
  useful for inspection.  The audit only denies them primitive
  status, not engineering value.

It claims only:

1. **Necessity is the test for primitivity, not utility.**
2. **First-unnamed-occurrence is the archaeological method.**
3. **Late conveniences cannot retroactively become primitives.**
4. **The classification table is auditable** — every record cites
   evidence.

If the cycle 34C audit produces a smaller alphabet with full
evidence per the binding schema, **the system's ontology is
genuinely cleaner**, even though the engineering surface is
unchanged.

---

## References

- METHODOLOGY.md v2.1 §17
- CLAIMS.md (current dispatch tier definitions — what to audit against)
- META-SEMANTICS.md (current operational vocabulary)
- mining_protocol.md (cycle 27 mining definition — early candidate
  for primitive `discovery`)
- PREDICTIONS-* series (cycles 25–34A)
- legacy/sixth-substrate.scm (cycle 0 substrate operations — true
  alphabet floor)
- Cycle 25E energy-observational-only constraint (runtime.rkt:125)
- User spec 2026-05-24 — alphabet archaeology, anti-post-hoc-rationalization,
  five demotions minimum, no new entities

---

## CYCLE 34B/C/D PHASE BREAKDOWN (intended)

- **34B (this pre-reg):** method + hypotheses + classification taxonomy
  + pass/fail + negative tests + binding schema.  No research yet.
- **34C:** the actual archaeology.  grep + read + per-entity records
  + summary table.  Output: `RESULTS-178-alphabet-archaeology.md`.
- **34D:** synthesis.  CLAIMS.md update reclassifying demoted entries.
  META-SEMANTICS.md update with four-tier separation explicit.  No
  code change.

If 34C/D reveal that the current engineering surface assumes a
larger alphabet than the audit confirms, that constitutes evidence
for a future refactor (35+) but is NOT acted on inside cycle 34.
