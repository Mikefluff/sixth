# RESULTS-178 — **Bootstrap** Alphabet Archaeology (cycle 34C)

**Date executed:** 2026-05-24
**Pre-reg:** `examples/PREDICTIONS-178-alphabet-archaeology.md`
**Pre-reg sha256:** `6881b9079a6a48aee6a0bed0ba95ec8d880335149466252f4853c379d38aca93`
**Method:** evidence-first, classification-last.  For each entity:
named occurrence → unnamed occurrence (or NOT_FOUND) → minimal
distinction → dependencies → classification.

---

## CRITICAL SCOPE CORRECTION (2026-05-24, post-execution)

This audit was originally framed as "the system's alphabet."
**That framing was wrong.**  The audit's actual scope was the
hand-written engineering bootstrap, NOT the substrate-discovered
alphabet.

Per user clarification mid-cycle:

> We don't count primitives you added by hand — only those that
> were found in the process.

All 7 entities classified `primitive` in this audit
(distinction, boundary, trace, commit, shadow-check, collapse,
contaminate) are either substrate axioms provided by the
bootloader (cycle 0 legacy) or hand-written meta-primitives
introduced in cycle 25 META-SEMANTICS.  None was AUTO-DETECTED
via `DETECT-MOTIF-AUTO`, INDUCEd through `INDUCE-RUNTIME`, or
promoted via the cycle-28 PROMOTE-STABLE protocol.

The substrate-discovered alphabet is audited separately in
`RESULTS-179-substrate-discovered-alphabet.md`.

### Status reclassification

- **PASS** as bootstrap / engineering-foundation audit.
- **NOT PASS** as substrate-discovered audit.

The audit's findings remain valid in their original scope:
the engineering surface has 7 irreducible bootstrap primitives
(3 alphabet nouns + 4 grammar verbs) and 25 non-primitive entries
that are derived / diagnostic / implementation / rejected.  But
calling these "the system's alphabet" without qualification
would conflate bootstrap-axioms with substrate-discoveries.

### Five-layer ontological architecture (post-correction)

| layer | what it contains | who put it there |
|-------|------------------|-------------------|
| **Layer 0 — Substrate axioms** | distinction, boundary, trace, collapse | bootloader (engineer, pre-cycle-25) |
| **Layer 1 — Protocol grammar** | commit, shadow-check, contaminate, promote-stable, held-out-eval | machinery (engineer, cycle 25-26 spec) |
| **Layer 2 — Discovered candidates** | cand_NNN that passed pipeline AND persisted | SYSTEM (via DETECT-MOTIF-AUTO + protocol) |
| **Layer 3 — Diagnostics** | stale, subsidized, dependency-supported, etc. | engineer (cycles 29+) |
| **Layer 4 — Implementation** | counters, ttl, credit, thresholds | engineer (cycles 25-34) |

**Hard rule:** **hand-authored machinery (Layers 0/1/3/4) cannot
be counted as discovered primitive.**  Only Layer 2 entries qualify.

> **A discovered primitive must have a lineage.  No lineage, no discovery.**

This audit's 7 primitives are Layer 0 (distinction, boundary,
trace, collapse) and Layer 1 (commit, shadow-check, contaminate).
It does NOT cover Layer 2.

---

## Section 1 — Summary table

| # | entity | first_unnamed_cycle | first_named_cycle | classification | depends_on | keep_as_alphabet |
|---|--------|---------------------|-------------------|----------------|------------|-------------------|
| 1 | distinction | 0 | 0 | primitive | ∅ | yes (alphabet) |
| 2 | boundary | 0 | 0 | primitive | distinction | yes (alphabet) |
| 3 | trace | 0 | 0 | primitive | ∅ | yes (alphabet) |
| 4 | persistence | 0 | 0 | derived | trace, world_state, ledger | already-derived |
| 5 | pressure | 25 | 25 | derived | shadow-check, held-out-eval, inflation | already-derived |
| 6 | flow | not_found | 34B | reject | — | no |
| 7 | metabolism | 29 | 29 | derived | law-momentum, decay, inflation | already-derived |
| 8 | energy_balance | not_found | 34B | reject | — | no |
| 9 | support_credit | 30 | 33 | implementation_detail | law-momentum, observed-dep, dependency-held | no |
| 10 | external_credit | not_found | 34A | implementation_detail | (no precursor — invented at 34A) | no |
| 11 | capacity | 28 | 34A | derived | held-out-eval, positive-epochs-counter, observed-dep | already-derived |
| 12 | inflation | not_found | 31 | implementation_detail | (constant INFLATION-COST-PER-CAND=1) | no |
| 13 | dependency-supported | 30 | 33 | diagnostic_label | support_credit, dependency-held | no |
| 14 | subsidized | not_found | 34A | diagnostic_label | external_credit | no |
| 15 | stale | 28 | 29 | diagnostic_label | law-momentum, STALE_TOLERANCE | no |
| 16 | demotion-candidate | 29 | 29 | diagnostic_label | law-momentum-history | no |
| 17 | auto-decompose | 29 | 30 | derived | decay, dependency-aware ROLLBACK-RUNTIME | already-derived |
| 18 | decay | 25E | 29 | derived | law-momentum trending negative | already-derived |
| 19 | repair | not_found | 34B | reject | — | no |
| 20 | adaptation | 25 | 0 | derived | INDUCE-RUNTIME, law_state | already-derived |
| 21 | commit | 25 | 25 | primitive (grammar) | trace, law_state, ledger | no (grammar) |
| 22 | resolve | not_found | 34B | reject | — | no |
| 23 | held-out-eval | 25 | 28 | derived | shadow-check, iron-rule governance | already-derived |
| 24 | shadow-check | 25 | 25 | primitive (grammar) | world_state, equivalence | no (grammar) |
| 25 | promote-stable | 25 | 28 | derived | held-out-eval, attest | already-derived |
| 26 | law-momentum | 25E | 29 | derived | E-REUSE-GAIN, carry, fails, inflation | already-derived |
| 27 | observed-dep | 32 | 32 | derived | nested-call hook, runtime trace | already-derived |
| 28 | dependency-held | 30 | 30 | diagnostic_label | static dependency graph | no |
| 29 | inscribe | not_found | 34B | reject | — | no |
| 30 | forget | not_found | 34B | reject | — | no |
| 31 | collapse | 0 | 0 | primitive (grammar) | distinction, boundary | no (grammar) |
| 32 | contaminate | 26 | 26 | primitive (grammar) | trace, ledger | no (grammar) |

**Totals:**
- primitive: 7  (3 alphabet + 4 grammar) — strict H1 goal MET
- derived: 13
- diagnostic_label: 7
- implementation_detail: 3
- reject: 6 (5 are `not_found_before_naming`)

---

## Section 2 — Per-entity records

### 1. distinction

- **first_named_occurrence:** docs/TOUR.md:42 — "void → first distinction → second distinction →"
- **first_unnamed_occurrence:** legacy substrate (pre-cycle-25) — `MARK` operation on a node creates the marked/unmarked distinction; `legacy/sixth-substrate.scm` substrate axioms.
- **minimal_distinction:** A substrate atom (node) either bears a mark or does not.  This is the atomic difference the system makes.
- **depends_on:** ∅
- **classification:** primitive
- **reason:** Removing the mark/no-mark distinction collapses the substrate's primary operation (`MARK`).  Every higher distinction (boundary, persistence, edge-existence) ultimately reduces to "this atom is differentiable from that atom."  Found unnamed in cycle 0; first formally named in TOUR.md (cycle 24+).
- **evidence:** `legacy/sixth-substrate.scm` substrate axiom for `MARK`; `docs/TOUR.md:42`.
- **keep_as_alphabet:** yes

### 2. boundary

- **first_named_occurrence:** `legacy/demo-glider.6th:74` — "step 4: c6 → c7 (last position before boundary)"
- **first_unnamed_occurrence:** cycle 0 — the closed `world_state` is itself a boundary; CA demos draw boundary semantics in cycle 0.
- **minimal_distinction:** The substrate has a defined extent; some atoms are inside, others outside (or non-existent).  Without boundary, mutations have no location.
- **depends_on:** distinction
- **classification:** primitive
- **reason:** Closed-extent world_state is required for any equivalence check (shadow-check) to be meaningful.  Boundary is the second-tier alphabet element after distinction; depends on distinction but adds the irreducible spatial-containment fact.
- **evidence:** `legacy/demo-glider.6th:74,109`, `legacy/demo-conservation.6th:95`.
- **keep_as_alphabet:** yes

### 3. trace

- **first_named_occurrence:** `legacy/meta.6th:40` — `": trace-on \"Tracing enabled\" . cr ;"`
- **first_unnamed_occurrence:** cycle 0 — every legacy demo implicitly records operation history (Forth-style stack ops are inherently time-ordered).  Elevated to first-class runtime tuple component in cycle 25 (META-SEMANTICS §3).
- **minimal_distinction:** Operations are time-ordered; the past is append-only and observable.  Without trace, law mutations are invisible to reviewers (and to the system itself).
- **depends_on:** ∅
- **classification:** primitive
- **reason:** Time-ordered append-only operation log is irreducible.  Cycle 25's two-tier protocol depends on trace being a first-class observable (law_hash mutation visible at step t).  Removing trace removes the entire audit substrate.
- **evidence:** `legacy/meta.6th:40`; `docs/META-SEMANTICS.md:177`.
- **keep_as_alphabet:** yes

### 4. persistence

- **first_named_occurrence:** `legacy/demo-glider.6th:109` — "persistence: the single live cell maintains its singularity"
- **first_unnamed_occurrence:** cycle 0 — CA demos demonstrate persistence (structure preserved across step transitions) without needing the word.
- **minimal_distinction:** Some structure remains across time-steps (mutations don't destroy it).
- **depends_on:** trace (to observe across time), world_state (to be preserved), law_state + ledger (for cross-run persistence).
- **classification:** derived
- **reason:** Persistence is a PROPERTY realized by the system's preservation of state across operations.  The substrate's actual primitives are the storage layers (trace, law_state, ledger).  "Persistence" qua noun is a derived observation: "structure exists in storage layer X across time-points t and t+k."
- **evidence:** `docs/META-SEMANTICS.md:519` (cross-tier persistence); CA demos.
- **keep_as_alphabet:** already-derived

### 5. pressure

- **first_named_occurrence:** `docs/META-SEMANTICS.md:69` — "fitness AND slow attestation pressure"
- **first_unnamed_occurrence:** cycle 25 — pressure as a metaphor for selection gates emerges with the two-tier protocol.
- **minimal_distinction:** Selective force admitting some candidates and rejecting others.
- **depends_on:** shadow-check, held-out-eval, inflation, contamination
- **classification:** derived
- **reason:** "Pressure" is a folk-philosophical term for "composition of selection gates."  No mechanism in the substrate is literally called "pressure" or computes a "pressure value."  The selective force is realized by the conjunction of separate gates.  Alphabet inclusion would require a distinct primitive; derived from existing gates.
- **evidence:** `docs/META-SEMANTICS.md:69`; `RESULTS.md:2302`.
- **keep_as_alphabet:** already-derived

### 6. flow

- **first_named_occurrence:** `legacy/README.md:15` — "debug-instrumented variant (unused in main flow)"
- **first_unnamed_occurrence:** **not_found_before_naming.**  No mechanism in cycles 0–34 computes a flow.  Counter arithmetic is not flow semantics.
- **minimal_distinction:** Movement of pressure/energy through structure.
- **depends_on:** would require pressure + throughput primitives, neither of which exists as alphabet.
- **classification:** reject
- **reason:** The substrate's energy machinery (cycle 25E) is per-bucket counters with `delta_e = sum_of_increments`.  No flow primitive exists.  "Main flow" in legacy/README is narrative usage (program flow control), not a substrate concept.  Per binding rule: not_found → cannot be primitive.
- **evidence:** `legacy/README.md:15`; `RESULTS.md:1992` (both narrative-only).
- **keep_as_alphabet:** no

### 7. metabolism

- **first_named_occurrence:** `CLAIMS.md:180` — "Tier 1 additions from law-metabolism arc (cycles 27-32)"
- **first_unnamed_occurrence:** cycle 29 — `prim-new-epoch` introduces the per-epoch decay-demote-decompose lifecycle.
- **minimal_distinction:** Per-epoch reuse-vs-cost balance for law candidates with lifecycle (active → stale → demotion-candidate → decomposed).
- **depends_on:** law-momentum, decay, inflation, demotion-candidate
- **classification:** derived
- **reason:** Metabolism is the composite of momentum arithmetic + status transitions + decomposition gates.  Not a single distinction.  The name appeared (cycle 29 RESULTS) to describe the existing composite mechanism, not to introduce a new primitive.
- **evidence:** `CLAIMS.md:180,198`; `RESULTS.md:1957,2156`.
- **keep_as_alphabet:** already-derived

### 8. energy_balance

- **first_named_occurrence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:105` (this audit's pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  Cycle 25E §17 introduces `E_world`, `E_law`, `E_trace`, `E_conflict`, `E_search`, `E_reuse_gain` as per-bucket counters with arithmetic `delta_e = sum`.  No "balance" or "flow" concept.
- **minimal_distinction:** (proposed in 178 pre-reg) "ability to receive, hold, redistribute, and release pressure without boundary collapse or metabolic stagnation."
- **depends_on:** would require pressure, flow, throughput — none of which is alphabet.
- **classification:** reject
- **reason:** The proposed minimal_distinction is not realized by any existing mechanism.  The substrate's energy is counter-arithmetic, not flow-balance.  "energy_balance" is a folk-philosophical term invented in this audit's pre-reg.  Per binding rule: cannot earn primitive status.
- **evidence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:105`; `docs/META-SEMANTICS.md:738-752` (per-bucket arithmetic).
- **keep_as_alphabet:** no

### 9. support_credit

- **first_named_occurrence:** `RESULTS.md:2539` — "carry-offset: support_credit(A) ≤ LAW_CARRY(A)"
- **first_unnamed_occurrence:** cycle 30 — `'dependency-held` already distinguished "primitive alive only because dependents use it."  Cycle 33 adds the per-epoch arithmetic carry-offset, but the underlying distinction predates the name.
- **minimal_distinction:** Per-epoch bounded carry-offset arithmetic: `min(LAW_CARRY(A), Σ floor(m_native(B)/dep_count(B)))`.
- **depends_on:** law-momentum, observed-dep, dependency-held, LAW_CARRY constant
- **classification:** implementation_detail
- **reason:** A specific arithmetic formula with a specific cap.  The DISTINCTION it realizes (cand survives via dependent's productivity) exists from cycle 30 as `dependency-held`; cycle 33 only adds the quantitative apportionment.  An alternative implementation (e.g., binary support indicator) would express the same distinction with different arithmetic.  Not alphabet.
- **evidence:** `RESULTS.md:2539,2542,2554`; `sixth/meta/runtime.rkt:158`; `sixth/meta/tier1.rkt:899-922`.
- **keep_as_alphabet:** no

### 10. external_credit

- **first_named_occurrence:** `examples/PREDICTIONS-177.md:19` (cycle 34A pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  Pre-cycle-34A the substrate has no external-energy axis.  Every primitive's survival is intrinsic (m_native) or via internal dependent (support_credit).  External support is invented at cycle 34A.
- **minimal_distinction:** Per-cand absorbed credit from external `INJECT-ENERGY`, amortized as `floor(remaining/ttl)` capped at capacity.
- **depends_on:** would require external-injection primitive (only exists from cycle 34A onward), capacity, energy buckets.
- **classification:** implementation_detail
- **reason:** A specific arithmetic for a mechanism introduced in cycle 34A pre-reg.  The "external vs internal" axis was not drawn before 34A.  The distinction `not-self-sustaining` (cycle 30 'dependency-held) does not by itself imply external vs internal source — that finer split is 34A.  Strict reading: not_found → could be `reject`.  Lenient reading: `implementation_detail` (it's specific arithmetic for a real proposed mechanism).  Chosen: implementation_detail.
- **evidence:** `examples/PREDICTIONS-177.md:19,44,62`.
- **keep_as_alphabet:** no

### 11. capacity

- **first_named_occurrence:** `examples/PREDICTIONS-177.md:13` (cycle 34A pre-reg)
- **first_unnamed_occurrence:** cycle 28 — the held-out gate is itself a "capacity" check (the candidate has earned the right to be stable).  Cycle 31 inflation establishes "earned right to survive" via positive m_native epochs.  Cycle 34A quantifies it as a counter.
- **minimal_distinction:** Earned right to absorb external energy, computed as `1 + heldout_wins + positive_epochs + observed_dependents`.
- **depends_on:** held-out-eval (counter), law-momentum positivity (counter), observed-dep (counter)
- **classification:** derived
- **reason:** Capacity is the sum of three already-existing earned signals.  Each component is itself derived or implementation_detail.  No new distinction beyond "we are now counting these three previously-existing signals together."
- **evidence:** `examples/PREDICTIONS-177.md:13,39,64`.
- **keep_as_alphabet:** already-derived

### 12. inflation

- **first_named_occurrence:** `CLAIMS.md:215` — "Two discovery profiles + law inflation (cycle 31)"
- **first_unnamed_occurrence:** **not_found** as a distinct concept before cycle 31.  Cycle 29 has `carry` cost, but inflation is an additive fixed-per-cand cost separate from per-cand carry.  Invented at cycle 31 (`INFLATION-COST-PER-CAND = 1`).
- **minimal_distinction:** Fixed per-cand per-epoch additive cost in the momentum formula.
- **depends_on:** law-momentum
- **classification:** implementation_detail
- **reason:** A numeric constant (1) added to the carry formula.  An alternative implementation could use different numerics, multiplicative scaling, or per-cand variable inflation.  The DISTINCTION inflation realizes ("law candidates cost something to maintain") existed at cycle 25E (carry, E_law).  Inflation is a specific knob, not a new distinction.
- **evidence:** `sixth/meta/runtime.rkt:419`; `CLAIMS.md:215,224`; `examples/PREDICTIONS-163.md` (cycle 31 pre-reg).
- **keep_as_alphabet:** no

### 13. dependency-supported

- **first_named_occurrence:** `RESULTS.md:2527` (cycle 33)
- **first_unnamed_occurrence:** cycle 30 — `'dependency-held` already labeled cands kept alive via dependent activity, even though that label fires later (Pass C) and via different arithmetic (static-only).  The distinction "alive due to dependent" predates the cycle 33 label.
- **minimal_distinction:** Pass-B status label: cand survives this epoch because `support_credit > 0` pulled `m_eff` into safe zone.
- **depends_on:** support_credit, law-momentum, observed-dep
- **classification:** diagnostic_label
- **reason:** Status label introduced in cycle 33 for monitoring purposes.  Removing the label would NOT change the metabolism's outcomes (the cand still survives); only the ledger would lose this status differentiation.  Per NEG-5: cannot be promoted to primitive by virtue of having a name.
- **evidence:** `RESULTS.md:2527,2568,2574`; `sixth/meta/runtime.rkt:397-399`; `sixth/meta/tier1.rkt:1057`.
- **keep_as_alphabet:** no

### 14. subsidized

- **first_named_occurrence:** `examples/PREDICTIONS-177.md:15` (cycle 34A pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  No pre-34A mechanism distinguishes "externally rescued" from any other survival path.  Invented at cycle 34A.
- **minimal_distinction:** Pass-B status label: cand survives this epoch because `external_credit > 0` pulled `m_eff` into safe zone (and support alone was insufficient).
- **depends_on:** external_credit, law-momentum
- **classification:** diagnostic_label
- **reason:** Status label introduced (pending implementation) in cycle 34A pre-reg.  Cannot be primitive: NEG-2 explicitly bans equating subsidized with alive; NEG-5 bans diagnostic-label promotion by naming.  The underlying distinction (external rent payer) is itself dependent on a mechanism (`INJECT-ENERGY`) that is not yet implemented.
- **evidence:** `examples/PREDICTIONS-177.md:15,44,56`.
- **keep_as_alphabet:** no

### 15. stale

- **first_named_occurrence:** `RESULTS.md:1983` — "|m| ≤ 1 → stale" (cycle 29)
- **first_unnamed_occurrence:** cycle 28 — held-out-eval already drew "candidate active" vs "candidate inactive."  Cycle 29 introduces the explicit intermediate label between active and decomposed.
- **minimal_distinction:** Pass-B status label: `|m_eff| ≤ STALE_TOLERANCE`; trace persists but cand is not productive this epoch.
- **depends_on:** law-momentum, STALE_TOLERANCE constant
- **classification:** diagnostic_label
- **reason:** Status label for monitoring.  `trace_persists = true` and `m_native = 0` together suffice to describe the state.  The label is operationally useful (Pass B branch differentiation) but adds no new distinction beyond the boolean conjunction of pre-existing facts.
- **evidence:** `RESULTS.md:1983,1993,2004`; `sixth/meta/runtime.rkt:398`; `sixth/meta/tier1.rkt:1061`.
- **keep_as_alphabet:** no

### 16. demotion-candidate

- **first_named_occurrence:** `CLAIMS.md:200` (cycle 29)
- **first_unnamed_occurrence:** cycle 29 — same cycle.  The label is introduced together with the underlying threshold (`MOMENTUM-NEGATIVE-THRESHOLD = 2`).
- **minimal_distinction:** Pass-B status: last N epochs all had `m_native < -STALE_TOL`.
- **depends_on:** law-momentum history, MOMENTUM-NEGATIVE-THRESHOLD constant
- **classification:** diagnostic_label
- **reason:** Status label.  The transition logic (Pass C dependency-check) operates on this label, but the label itself is a derived predicate over the m_native history.  Could be expressed as `forall i in 0..N: hist[i] < -STALE_TOL` without the label.
- **evidence:** `CLAIMS.md:200,207`; `RESULTS.md:1964`; `sixth/meta/tier1.rkt:1071-1074`.
- **keep_as_alphabet:** no

### 17. auto-decompose

- **first_named_occurrence:** `CLAIMS.md:206` (cycle 30)
- **first_unnamed_occurrence:** cycle 29 — `prim-new-epoch` already auto-decomposed cands at end of metabolism gate.  Cycle 30 adds dependency-awareness (skip if held by active dep).
- **minimal_distinction:** Automatic invocation of `ROLLBACK-RUNTIME` (or stable equivalent) when metabolism gate triggers AND no dependent saves the cand.
- **depends_on:** decay/demotion-candidate gate, dependency-held check, ROLLBACK-RUNTIME
- **classification:** derived
- **reason:** A specific composition of pre-existing primitives.  Cycle 30 added the dependency check; cycle 29 added the metabolism trigger; cycle 25 provided ROLLBACK-RUNTIME.  Auto-decompose = trigger + check + rollback.  Derived.
- **evidence:** `CLAIMS.md:206,208`; `RESULTS.md:2040`; `sixth/meta/tier1.rkt:1078-1091`.
- **keep_as_alphabet:** already-derived

### 18. decay

- **first_named_occurrence:** `RESULTS.md:1957` — "Cycle 29 — Law Metabolism (decay, demote, decompose)"
- **first_unnamed_occurrence:** cycle 25E — energy formulation has `E_REUSE_GAIN < cost` describing primitives that fail to justify their carry cost; the concept of "value decays over time" is implicit there.
- **minimal_distinction:** Law-momentum trending negative across epochs.
- **depends_on:** law-momentum, time-ordering (trace)
- **classification:** derived
- **reason:** A trend descriptor over a counter sequence.  Not a new distinction; a reading of existing m_native history.
- **evidence:** `RESULTS.md:1957`; `examples/PREDICTIONS-178-alphabet-archaeology.md:83` (proposed as grammar).
- **keep_as_alphabet:** already-derived

### 19. repair

- **first_named_occurrence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:83` (this audit's pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  The substrate has no mechanism for repairing a broken cand.  Candidates either survive metabolism or auto-decompose.  ROLLBACK-RUNTIME is removal, not repair.
- **minimal_distinction:** (proposed) restoration of a degraded structure.
- **depends_on:** would require a degradation distinction + a restoration primitive, neither of which exists.
- **classification:** reject
- **reason:** Not_found, not realized.  Possibly desirable future mechanism, but cannot be classified as primitive in current substrate.  Per binding rule.
- **evidence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:83,307`.
- **keep_as_alphabet:** no

### 20. adaptation

- **first_named_occurrence:** `docs/EICS-HOOK.md:70` — "adaptation choices needed:"
- **first_unnamed_occurrence:** cycle 25 — the entire two-tier protocol IS adaptation: substrate evolves its own alphabet via INDUCE-RUNTIME + COMMIT-PRIMITIVE + PROMOTE-STABLE.  The substrate's ability to adapt predates the name.
- **minimal_distinction:** Substrate's law_state mutates in response to operational history.
- **depends_on:** law_state, INDUCE-RUNTIME, trace, COMMIT-PRIMITIVE
- **classification:** derived
- **reason:** Adaptation is the OVERALL BEHAVIOR realized by the two-tier protocol, not a primitive.  Removing INDUCE-RUNTIME would remove the substrate's ability to adapt; "adaptation" as a noun describes the collective.
- **evidence:** `docs/EICS-HOOK.md:70`; META-SEMANTICS §1 (core thesis on substrate-that-evolves-its-own-alphabet).
- **keep_as_alphabet:** already-derived

### 21. commit

- **first_named_occurrence:** `docs/META-SEMANTICS.md:127,274` (cycle 25) — `COMMIT-PRIMITIVE`
- **first_unnamed_occurrence:** cycle 25 — same cycle.  Tier1→Tier2 bridge introduced as foundational meta-primitive.
- **minimal_distinction:** Atomic transition operation that promotes an ephemeral candidate to a frozen-for-tier2-evaluation candidate record.  Adds ledger event with full provenance.
- **depends_on:** trace (provenance source), law_state (ephemeral source), ledger (destination)
- **classification:** primitive (grammar)
- **reason:** Irreducible verb.  Without `commit` there is no way to bridge ephemeral runtime mutation to cross-run stable promotion.  The two-tier lifecycle structure depends on this primitive operation.  Belongs to grammar layer (it's a verb), not alphabet (which is distinctions/nouns).
- **evidence:** `docs/META-SEMANTICS.md:127,274-285`; `CLAIMS.md:155`.
- **keep_as_alphabet:** no (grammar, not alphabet)

### 22. resolve

- **first_named_occurrence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:83` (this audit's pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  No mechanism named "resolve" in cycles 25-34.  Closest: contamination handling, but it's `CONTAMINATE!` (mark), not resolution.
- **minimal_distinction:** (proposed) operation that brings a contested state to a definite conclusion.
- **depends_on:** would require contestation/conflict primitives.
- **classification:** reject
- **reason:** Not_found.  Could be a desired future verb (e.g., resolve E_conflict events into substrate-level corrections), but not realized.
- **evidence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:83,119,307`.
- **keep_as_alphabet:** no

### 23. held-out-eval

- **first_named_occurrence:** `CLAIMS.md:191` (cycle 28); META-SEMANTICS:142 introduces the spec at cycle 25.
- **first_unnamed_occurrence:** cycle 25 — META-SEMANTICS §2 specifies HELD-OUT-EVAL as Tier 2 foundational gate.  Cycle 28 makes it real.
- **minimal_distinction:** Equivalence check on a held-out substrate (never seen during discovery) with iron-rule append-only result.
- **depends_on:** shadow-check (equivalence verification primitive), held-out corpus, iron-rule governance (append-only ledger)
- **classification:** derived
- **reason:** held-out-eval = shadow-check applied to a previously-unseen substrate + governance constraint (append-only).  Both components pre-exist.  Iron-rule is procedural/methodological, not a substrate primitive.  Therefore derived.
- **evidence:** `docs/META-SEMANTICS.md:142,309-313`; `CLAIMS.md:191`; `RESULTS.md:1703`.
- **keep_as_alphabet:** already-derived

### 24. shadow-check

- **first_named_occurrence:** `docs/META-SEMANTICS.md:113,231` (cycle 25)
- **first_unnamed_occurrence:** cycle 25 — same.  Tier 1 foundational meta-primitive: fork world_state, apply motif vs expansion, compare.
- **minimal_distinction:** Atomic equivalence verification on a forked world_state copy.  Returns pass/fail based on world_delta match AND runtime cost bound.
- **depends_on:** world_state (forkable), trace (cost measurement)
- **classification:** primitive (grammar)
- **reason:** Irreducible verb.  Without shadow-check, INDUCE-RUNTIME cannot be safely gated and law_state corrupts.  This is the equivalence-verification atom.  Grammar (verb).
- **evidence:** `docs/META-SEMANTICS.md:113,231-240`; `CLAIMS.md:133`.
- **keep_as_alphabet:** no (grammar)

### 25. promote-stable

- **first_named_occurrence:** `CLAIMS.md:190` (cycle 28); META-SEMANTICS:145 (cycle 25 spec)
- **first_unnamed_occurrence:** cycle 25 — META-SEMANTICS §5 specifies PROMOTE-STABLE as the gate that adds a passed candidate to the permanent dictionary.
- **minimal_distinction:** Operation that on held-out pass adds the candidate to permanent law_state + appends attestation to ledger.
- **depends_on:** held-out-eval (gate), attest (ledger), law_state (mutation target)
- **classification:** derived
- **reason:** Promote-stable = held-out-pass check + dictionary mutation + ledger attestation.  Each component pre-exists.  Derived composite.
- **evidence:** `docs/META-SEMANTICS.md:145,315-321`; `CLAIMS.md:190`.
- **keep_as_alphabet:** already-derived

### 26. law-momentum

- **first_named_occurrence:** `RESULTS.md:1989` — `LAW-MOMENTUM` primitive (cycle 29)
- **first_unnamed_occurrence:** cycle 25E — energy formula `E_REUSE_GAIN > carrying_cost` is the original "net-positive" check; cycle 29 generalizes to `m = reuse - carry - fails - inflation` (inflation added cycle 31).
- **minimal_distinction:** Per-epoch arithmetic sum: reuse income minus structural costs.
- **depends_on:** E-REUSE-GAIN, carry constant, recent-fails counter, inflation constant
- **classification:** derived
- **reason:** Arithmetic combination of pre-existing counters and constants.  Not a new distinction; a calculator.
- **evidence:** `RESULTS.md:1989`; `CLAIMS.md:222`; `sixth/meta/tier1.rkt:783` (LAW-MOMENTUM); `sixth/meta/tier1.rkt:770-779` (compute-momentum-for).
- **keep_as_alphabet:** already-derived

### 27. observed-dep

- **first_named_occurrence:** `RESULTS.md:2390` (cycle 32) — `_observed-deps`
- **first_unnamed_occurrence:** cycle 32 — same; introduced together with the nested-call hook.  No precursor concept exists.  (Cycle 25-31 had only static dependency via motif-graph, not runtime-observed.)
- **minimal_distinction:** Recorded edge `(caller, callee)` in the per-epoch nested-call snapshot.
- **depends_on:** VM nested-call hook, trace, per-epoch reset
- **classification:** derived
- **reason:** A recorded observation, not a new distinction.  The atom (one observed call) is `(caller, callee)`; the collection is a multi-set.  Derived from VM hook + trace.
- **evidence:** `RESULTS.md:2390,2399`; `sixth/meta/runtime.rkt:155-156`; `sixth/meta/tier1.rkt:active-dependents-of`.
- **keep_as_alphabet:** already-derived

### 28. dependency-held

- **first_named_occurrence:** `CLAIMS.md:209` (cycle 30)
- **first_unnamed_occurrence:** cycle 30 — same.  Introduced as Pass C status label.
- **minimal_distinction:** Pass-C status label: cand is demotion-candidate but has at least one active dependent (static or transitively-load-bearing).
- **depends_on:** demotion-candidate, dependency graph (static + observed)
- **classification:** diagnostic_label
- **reason:** Status label introduced for monitoring.  The system would still skip auto-decompose without the label; only the ledger surface would lose this differentiation.
- **evidence:** `CLAIMS.md:209`; `RESULTS.md:2065`; `sixth/meta/tier1.rkt:1086-1089`.
- **keep_as_alphabet:** no

### 29. inscribe

- **first_named_occurrence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:126` (this audit's pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  Closest substrate verb is MARK (cycle 0).  "inscribe" as a separate primitive does not exist.
- **minimal_distinction:** (proposed) operation creating a persistent mark/record.
- **depends_on:** would duplicate MARK + trace + ledger append.
- **classification:** reject
- **reason:** Not_found.  If the intended semantics is "MARK with persistence guarantee," the existing combination MARK + ledger-append already provides it.  Adding "inscribe" as a separate primitive would duplicate existing capability.
- **evidence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:126,307`.
- **keep_as_alphabet:** no

### 30. forget

- **first_named_occurrence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:127` (this audit's pre-reg)
- **first_unnamed_occurrence:** **not_found_before_naming.**  The substrate has rollback (ROLLBACK-RUNTIME, ROLLBACK-STABLE) and auto-decompose, but no explicit "forget" semantics (which would imply selective deletion from trace/ledger — both are append-only).
- **minimal_distinction:** (proposed) operation removing structure from a persistence layer.
- **depends_on:** would conflict with append-only trace/ledger invariant.
- **classification:** reject
- **reason:** Not_found.  Trace and ledger are explicitly append-only (iron rule for ledger).  A "forget" primitive would violate the audit invariant.  Rollback removes from law_state without removing trace/ledger records.  No coherent "forget" primitive in current substrate.
- **evidence:** `examples/PREDICTIONS-178-alphabet-archaeology.md:127,307`.
- **keep_as_alphabet:** no

### 31. collapse

- **first_named_occurrence:** `RESULTS.md:488` — "(a,c)(a,c) | **4** | NO — duplicate collapse" (cycle 0)
- **first_unnamed_occurrence:** cycle 0 — substrate set-semantics for edges: duplicate edges coalesce.
- **minimal_distinction:** Substrate coalescence: two identical structures become one (set semantics).  Also used to describe `ROLLBACK-RUNTIME`/`auto-decompose` outcomes ("law collapses out of dictionary").
- **depends_on:** distinction (to identify equality), boundary (to scope coalescence)
- **classification:** primitive (grammar)
- **reason:** Atomic substrate axiom from cycle 0.  Removal of `collapse` would change the substrate's set-semantics (duplicates would persist) and would break the equivalence checks.  Irreducible verb at substrate level.  Grammar.
- **evidence:** `RESULTS.md:488,539`; `CHANGELOG.md:285`.
- **keep_as_alphabet:** no (grammar)

### 32. contaminate

- **first_named_occurrence:** `RESULTS.md:1632` (cycle 26)
- **first_unnamed_occurrence:** cycle 25 — META-SEMANTICS §11 specifies contamination rules; the concept "this candidate's result cannot be cited" is foundational to the iron rule.
- **minimal_distinction:** Atomic action that marks a candidate as poisoned (cannot enter any further evaluation/promotion).  Adds ledger event tagged with reason.
- **depends_on:** trace, ledger, status flag
- **classification:** primitive (grammar)
- **reason:** Irreducible verb.  Without `contaminate`, the iron rule cannot be enforced — there is no way to mark a candidate's lineage as poisoned.  The contamination distinction is foundational to the protocol's epistemic guarantees.  Grammar (verb).
- **evidence:** `docs/META-SEMANTICS.md:499-533`; `RESULTS.md:1632,1878`; `sixth/meta/runtime.rkt:123`.
- **keep_as_alphabet:** no (grammar)

---

## Section 3 — Hypothesis evaluation

### H1 — Low-level alphabet is smaller than current primitive set

**Claim:** ≤7 primitive classifications.

**Result:** 7 primitives (3 alphabet + 4 grammar).  **CONFIRMED (strict goal met).**

Breakdown:
- Alphabet (3): distinction, boundary, trace
- Grammar (4): commit, shadow-check, collapse, contaminate

Current engineering surface has ~38 Tier 1 primitives + 15 base; this audit demotes the vast majority to derived/diagnostic_label/implementation_detail/reject.  The ratio is roughly 7/53 ≈ 13% of the engineering surface is genuinely primitive at the ontological level.

### H2 — Most operational statuses are derived

**Claim:** stale, demotion-candidate, dependency-supported, subsidized, auto-decompose all demote.

**Result:** **CONFIRMED.**
- stale → diagnostic_label
- demotion-candidate → diagnostic_label
- dependency-supported → diagnostic_label
- subsidized → diagnostic_label
- auto-decompose → derived

All five demoted.  None received primitive status.

### H3 — Energy balance is not quantity, but flow constraint

**Claim:** energy_balance is a flow-and-capacity primitive, not a numeric counter.

**Result:** **WEAKLY REFUTED.**

The substrate's actual energy machinery (cycle 25E §17) is per-bucket counter arithmetic:
```
E_world = node_count + edge_count
E_law = sum of cand body lengths
E_trace = semantic-trace count
E_conflict = shadow_failures × 100 + invariant_violations × 1000
E_search = Σ motif_length per SHADOW-CHECK
E_reuse_gain = Σ (expansion_length - 1) per cand dispatch
```

There is no flow primitive.  `delta_e` is a sum, not a flow rate.  The user's intuition about energy-as-flow is a desirable design goal, not a present property of the substrate.

**Honest finding:** the proposed flow-balance semantics for energy_balance does not correspond to existing substrate mechanics.  energy_balance is REJECTED (`not_found_before_naming`); the substrate's energy is counter-arithmetic.

H3 stands as a DESIGN PROPOSAL for a future cycle, but as an archaeological claim about the present substrate, it is refuted.

### H4 — External credit is not life

**Claim:** A structure surviving only via external_credit is not alive; it is externally maintained.

**Result:** **CONFIRMED.**
- subsidized classified as diagnostic_label (NEG-2 reinforces: subsidized ≠ alive)
- external_credit classified as implementation_detail (specific arithmetic)
- The cycle 34A "truth-immune" invariant aligns: external credit cannot satisfy any truth gate (PROMOTE-STABLE, HELD-OUT-EVAL, etc.)

The audit confirms: an externally-rescued cand is not classified as alive at the ontological level.  Its status label honestly marks it as rent-paid-from-outside.

### H5 — Metabolism requires throughput

**Claim:** metabolism ≠ accumulation; living structure must transform and pass through, not merely hoard.

**Result:** **PARTIALLY CONFIRMED.**

The formal mechanism (`m = reuse - carry - fails - inflation`) IS counter-arithmetic.  But its interpretation as a flow-balance equation is consistent:
- `reuse` is the income flow (operations saved by using the cand)
- `carry`, `fails`, `inflation` are the cost outflows
- `m_native > 0` means net throughput is positive

So the FORMULA reads as flow-balance, but the IMPLEMENTATION is counter-arithmetic.  This is partial support for H5: throughput-language is interpretively valid; throughput-mechanism is not yet distinct from counter-arithmetic.

Closer reading: the cycle 33 invariant "rented-not-owned" (support_credit reset per epoch) IS a throughput principle — credit doesn't accumulate.  But that's one mechanism in one cycle, not a substrate-wide throughput primitive.

**Conclusion:** H5 confirmed as an interpretive framework, partially confirmed as substrate mechanism (cycle-33 rented-not-owned), refuted as universal substrate primitive (most counters are still purely additive).

---

## Section 4 — Negative-test verification

### NEG-1 — Late convenience is not primitive

**Required:** at least one late-convenience entity demoted to diagnostic_label or implementation_detail.

**Result:** **PASSED.**  Demoted: subsidized (DL), dependency-supported (DL), dependency-held (DL), capacity (derived), support_credit (implementation_detail), external_credit (implementation_detail).

### NEG-2 — External support does not imply life

**Required:** subsidized NOT classified as alive; explicitly distinguished from self-sustaining.

**Result:** **PASSED.**  subsidized = diagnostic_label.  Per record #14: "Cannot be primitive: NEG-2 explicitly bans equating subsidized with alive."  The status label honestly marks rent-paid-from-outside; alive ≠ rented.

### NEG-3 — Accumulated energy does not imply metabolism

**Required:** accumulation distinguished from metabolism (throughput required).

**Result:** **PASSED.**  metabolism = derived (composite of momentum + decay + inflation).  Cycle 33's "rented-not-owned" support_credit is the closest the substrate has to a throughput primitive: credit is recomputed each epoch, never accumulated.  Pure counter accumulation (E_world growing monotonically as substrate grows) is NOT metabolism — it's just substrate inflation.

### NEG-4 — Stale is not dead

**Required:** stale state retains `trace_persists = true`, distinct from decomposed.

**Result:** **PASSED.**  stale = diagnostic_label.  Record #15 explicitly: "`trace_persists = true` and `m_native = 0`."  stale ≠ decomposed.  Auto-decompose removes from law_state; stale only relabels.

### NEG-5 — Diagnostic labels cannot become alphabet by naming

**Required:** dependency-supported and subsidized must NOT be primitive.

**Result:** **PASSED.**  Both classified as diagnostic_label.  Neither receives primitive or keep_as_alphabet status.

---

## Section 5 — Demotion list

The following entities are demoted from their engineering-surface treatment to a lower ontological tier.  All remain operationally in the dispatch table; the demotion is ONTOLOGICAL, not engineering.

| entity | engineering treatment | ontological reclassification |
|--------|----------------------|------------------------------|
| stale | Tier-1 status label (cycle 29) | diagnostic_label |
| demotion-candidate | Tier-1 status label (cycle 29) | diagnostic_label |
| dependency-held | Tier-1 status label (cycle 30) | diagnostic_label |
| dependency-supported | Tier-1 status label (cycle 33) | diagnostic_label |
| subsidized | Tier-1 status label (cycle 34A, proposed) | diagnostic_label |
| auto-decompose | Tier-1 primitive (cycle 30) | derived (decay + dep-check + ROLLBACK-RUNTIME) |
| inflation | Tier-1 constant (cycle 31) | implementation_detail (specific knob) |
| capacity | Tier-1 primitive (cycle 34A, proposed) | derived (sum of 3 earned signals) |
| support_credit | Tier-1 primitive (cycle 33) | implementation_detail (specific arithmetic) |
| external_credit | Tier-1 primitive (cycle 34A, proposed) | implementation_detail (specific arithmetic) |
| metabolism | named conceptual layer (cycle 29) | derived (composite) |
| decay | named conceptual layer (cycle 29) | derived (m-trend) |
| pressure | folk-philosophical term (cycle 25 META) | derived (selection-gate composition) |
| law-momentum | Tier-1 primitive (cycle 29) | derived (arithmetic over counters) |
| observed-dep | Tier-1 mechanism (cycle 32) | derived (recorded observations) |
| held-out-eval | Tier-2 primitive (cycle 25/28) | derived (shadow-check + iron-rule governance) |
| promote-stable | Tier-2 primitive (cycle 25/28) | derived (gate composition) |
| persistence | conceptual layer | derived (cross-time observation) |
| adaptation | conceptual layer | derived (substrate-wide behavior) |

**Total demoted: 19 entities.**  Pre-reg PASS criterion required ≥5.  Greatly exceeded.

### Rejected entities (6, all `not_found_before_naming` or substrate-absent)

| entity | reason |
|--------|--------|
| flow | not_found in substrate semantics (narrative-only in legacy/README) |
| energy_balance | not_found_before_naming; substrate energy is counter-arithmetic |
| repair | not_found_before_naming; no repair mechanism in substrate |
| resolve | not_found_before_naming; no resolution verb in substrate |
| inscribe | not_found_before_naming; MARK + ledger-append covers intended semantics |
| forget | not_found_before_naming; conflicts with append-only trace/ledger invariant |

**These 6 are folk-philosophical terms introduced by 178 pre-reg or earlier narrative; they are NOT substrate concepts.**  Naming them does not create them.

---

## Section 6 — Confirmed alphabet (post-archaeology)

The minimal set of distinctions and operations the substrate cannot do without:

### Alphabet (3 — pure distinctions / nouns)

| # | name | minimal distinction | first cycle |
|---|------|---------------------|-------------|
| 1 | distinction | substrate atom either bears a mark or does not | 0 |
| 2 | boundary | substrate has defined extent; atoms are inside or outside | 0 |
| 3 | trace | operations are time-ordered append-only | 0 |

### Grammar (4 — primitive operations / verbs)

| # | name | minimal operation | first cycle |
|---|------|-------------------|-------------|
| 4 | commit | atomic transition from ephemeral to evaluable record (Tier1→Tier2 bridge) | 25 |
| 5 | shadow-check | atomic equivalence verification on forked world_state | 25 |
| 6 | collapse | atomic substrate coalescence (set-semantics; also law-removal under rollback) | 0 |
| 7 | contaminate | atomic poisoning of a candidate's lineage (iron-rule enforcement primitive) | 25 (spec) / 26 (impl) |

**Total alphabet: 7 (strict H1 goal met).**

### What is NOT in the alphabet (and why)

- **No specific status labels** (stale, demotion-candidate, dependency-held, dependency-supported, subsidized) — diagnostic.
- **No specific counters** (support_credit, external_credit, capacity, inflation, law-momentum, observed-dep) — implementation_detail or derived.
- **No composite mechanisms** (metabolism, decay, pressure, persistence, adaptation, auto-decompose, held-out-eval, promote-stable) — derived.
- **No imagined verbs/nouns** (flow, energy_balance, repair, resolve, inscribe, forget) — not_found_before_naming.

### Implicit primitives the audit surfaced but didn't formally add

The 4-tuple runtime (cycle 25) implies four foundational distinctions: `world_state`, `law_state`, `trace`, `ledger`.  Of these:
- `trace` is in the alphabet (listed above).
- `world_state` is implicit in `boundary` (closed extent).
- `law_state` and `ledger` were NOT in the 32-entity candidate list.  They could be added as discovered_during_audit entries.

**Recommended extension (cycle 34D or later):** add `law_state` and `ledger` as additional alphabet entries.  This would expand alphabet to 5, still within H1.

---

## Section 7 — Open questions

1. **law_state and ledger as separate alphabet entries.**  Not in the 32-entity candidate list but implied by cycle 25's 4-tuple model.  Audit recommendation: add via discovered_during_audit mechanism in cycle 34D.

2. **Distinction between `world_state` and `boundary`.**  Currently boundary is classified as primitive with depends_on=distinction; world_state is implicit.  These could be split: world_state = primitive container; boundary = primitive structural property.  Marginal call.

3. **Inflation as implementation_detail vs derived.**  Classified as implementation_detail (specific constant), but the act of "paying a per-cand-per-epoch cost" could be seen as derived from `metabolism` or as a primitive cost-mechanism.  Marginal call.

4. **Held-out-eval governance vs substrate mechanism.**  Iron-rule (append-only) is procedural/methodological, not substrate-mechanical.  Held-out-eval-as-derived rests on this.  If iron-rule were promoted to substrate primitive (the substrate enforces append-only by mechanical guarantee), held-out-eval could be reclassified as primitive.  Currently the iron-rule is enforced by external script (`scripts/heldout_eval.sh`), so substrate-mechanical primitivity is not yet earned.

5. **External_credit: implementation_detail or reject?**  Classified as implementation_detail (lenient).  Strict reading would reject it as not_found_before_naming (cycle 34A pre-reg only).  Marginal call; if 34A is implemented, the classification should be revisited.

6. **Capacity as composite of counters: is this really derived, or is it a primitive measurement axis?**  Classified as derived (sum of 3 earned signals).  But "earned capacity" could be argued as a distinct axis from any of its components.  Marginal call.

---

## Section 8 — Impact note on delayed cycle 34A

**Cycle 34A implementation (PREDICTIONS-177, external energy + capacity + subsidized) remains blocked pending this audit's conclusions.**

This audit has now classified:
- `external_credit` as **implementation_detail** (specific arithmetic for cycle 34A's not-yet-implemented mechanism)
- `capacity` as **derived** (sum of pre-existing earned signals)
- `subsidized` as **diagnostic_label** (Pass B status differentiation)
- `INJECT-ENERGY` (not in 32 list, implied by 177 pre-reg) would likely classify as primitive (grammar) — a new atomic operation that creates the external_credit/source/purpose/ttl record.

**Implication for cycle 34A implementation:**

1. The proposed 9 new Tier 1 primitives include only ONE genuine primitive operation (`INJECT-ENERGY`).  The other 8 (`EXTERNAL-CREDIT`, `ENERGY-BUFFER`, `ENERGY-CAPACITY`, `ENERGY-LEAK`, `ENERGY-SOURCE`, `SUBSIDIZED?`, `ORGANIC-MOMENTUM`, `SUBSIDIZED-MOMENTUM`) are inspections of derived/implementation_detail values.  Implementing them is fine (engineering convenience), but they should NOT be claimed as alphabet primitives in `CLAIMS.md`.

2. The proposed 1 new status `'subsidized` is diagnostic_label by classification.  Adding it to `STABLE-WORD-STATUSES` is fine for monitoring; claiming it as a fundamental life-state distinction would violate NEG-2.

3. The proposed Pass A.3 (positive_epochs counter) is itself a counter persistence mechanism.  Earned-capacity reading requires it.

4. **Cycle 34A may proceed to implementation, but `CLAIMS.md` updates must reflect this audit:**
   - `INJECT-ENERGY` → **new Tier 1 grammar operation candidate, NOT alphabet primitive without separate archaeology evidence.**  It may be implemented as a controlled operation over implementation_detail values (external_credit, ttl, capacity), but cannot claim primitivity by virtue of being a new verb in the dispatch table.  Per the binding rule from cycle 34B: naming does not create primitives.  If `INJECT-ENERGY` is to be classified as primitive in a future audit, it must independently survive the same evidence-first archaeology applied to the 32 candidates here.
   - All other 8 cycle-34A primitives → Tier 1 INSPECTION-OP entries with no ontological-primitivity claim
   - `'subsidized` → status label, not primitive distinction
   - `capacity`, `external_credit` → implementation knobs, not primitive distinctions

5. **The truth-immune invariant of 34A** (PROMOTE-STABLE consults only ORGANIC, never SUBSIDIZED/EFFECTIVE) **is reinforced by this audit**: ontologically, only ORGANIC measures intrinsic productivity; the other momentum buckets are derived.

---

## Section 9 — Compliance with pre-reg PASS criteria

| # | criterion | result |
|---|-----------|--------|
| 1 | Coverage: every 32 entity has a record | 32/32 ✓ |
| 2 | Evidence: every classification cites file:line, ledger event, or commit | 32/32 ✓ |
| 3 | Smaller alphabet: ≤10 primitive (strict ≤7) | **7 ✓ (strict goal met)** |
| 4 | At least 5 demotions from current engineering "primitive" surface | **19 demotions ✓** |
| 5 | Rigorous decomposition for energy_balance, external_credit, subsidized | ✓ (all three have explicit reduction in records 8/10/14) |
| 6 | No new entities added | ✓ (audit only classifies; no new mechanism proposed) |
| 7 | No classification cites late-cycle utility as primary justification | ✓ (every primitive cites first_unnamed_occurrence in cycle 0 or 25) |

**PASS criteria: 7/7 met.  Cycle 34C → PASS.**

---

## Section 10 — Summary

**Before archaeology:** ~38 Tier 1 primitives, multiple proposed cycle 34A primitives, expanding engineering surface.

**After archaeology:** 7 genuine primitives (3 alphabet + 4 grammar).  19 entities demoted to derived / diagnostic_label / implementation_detail.  6 entities rejected as `not_found_before_naming`.

**The alphabet is smaller.  The substrate's ontology is cleaner.  The engineering surface is unchanged.**

The cycle 34A external-energy implementation is now positioned to proceed with HONEST labels: `INJECT-ENERGY` is a genuine new primitive operation, the rest are inspections of derived values.  No false primitive promotion via naming.

Cycle 34D (next): synthesis — update `CLAIMS.md` and `META-SEMANTICS.md` with the four-tier separation explicit and the demotion list applied.

---

## References

- `examples/PREDICTIONS-178-alphabet-archaeology.md` — pre-reg
- `attestations/ledger.txt` — attestation record (`daccffc269...`)
- `docs/META-SEMANTICS.md` v2.1 — cycle 25 foundational primitive spec + cycle 25E energy
- `docs/mining_protocol.md` — cycle 27 mining
- `CLAIMS.md` — current engineering surface
- `RESULTS.md` — cycle-by-cycle event chronology
- `legacy/sixth-substrate.scm`, `legacy/meta.6th`, `legacy/demo-glider.6th` — cycle 0 substrate axioms
- `sixth/meta/runtime.rkt`, `sixth/meta/tier1.rkt` — current implementation surface
- User spec 2026-05-24 — evidence-first, classification-last, strict H1 cap of 7
