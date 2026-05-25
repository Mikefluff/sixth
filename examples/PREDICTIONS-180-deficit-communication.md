# PREDICTIONS-180 — Deficit-Driven Composite Communication (cycle 35, retitled)

**Date pre-registered:** 2026-05-25

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
Initial attestation: see ledger row dated 2026-05-25.

---

## Cycle context

PREDICTIONS-179 (persistence layer + source-tag firewall) was
attested and accepted as design but **DEFERRED** per user spec
2026-05-25.  Reason: the source-tag firewall is a compliance /
gate-keeping concern that becomes load-bearing only once durable
L2 persistence exists; without occupants in L2, it guards an
empty warehouse.

The main line of Sixth is runtime mutation / evolution:

```
runtime sees a deficit
  → runtime mutates law-state
  → runtime verifies the new law
  → runtime pays / does not pay energy
  → runtime sustains / decays / supports / mutates further
```

Cycles 25-33 built the protocol for **individual cand promotion**
(detect, induce, shadow, couple, energy, held-out, promote) and
**individual cand metabolism** (decay, demote, decompose,
dependency-held, support).  These are single-cand dynamics.

Cycle 35 (retitled) opens the next qualitative layer: **behavior
BETWEEN cands**.  Composites become structural counterparts —
they can hold capabilities, they can have measurable deficits,
they can emit requests and field offers, they can match each
other up.  Crucially, none of this is "consciousness" or
"agency."  Every event is mechanically grounded in a measurable
predicate over existing law-state.

---

## CORE CLAIM (binding)

> Composites do not "consciously request" services.  They emit
> requests when their **measurable deficit** crosses a
> threshold.  Other composites can declare and offer
> **capabilities**.  A match can trigger runtime law-state
> interaction WITHOUT corrupting any stable gate.

Composites = promoted cand_NNN (whatever source-tag, since
persistence is deferred).  In the current substrate this means
fixture-promoted cands in a single test run.  The communication
protocol is intra-session for now.  Adding cross-session
communication waits for persistence (deferred cycle).

---

## CORE INVARIANTS (binding, five rules)

1. **Deficit-driven.**  A request can be emitted ONLY when a
   measurable deficit predicate over current law-state evaluates
   true.  Callers cannot emit requests "because they feel like
   it"; the predicate gates the emission.

2. **Capability-bound.**  An offer can be made ONLY by a cand
   that has previously declared the matching capability via
   `DECLARE-CAPABILITY`.  Undeclared capabilities cannot be
   offered.  This prevents "everyone can do everything" surface
   inflation.

3. **Gate-preserving.**  A matched offer DOES NOT bypass
   `SHADOW-CHECK`, `HELD-OUT-EVAL`, `PROMOTE-STABLE`,
   `COMMIT-PRIMITIVE`, or `compute-support-credit-for` positive-
   anchor check.  Communication can SUGGEST a mutation;
   the existing lawful gates still decide if it happens.

4. **Sandbox-isolated.**  A sandbox-track provider
   (`'experimental`, `'sandbox-stable`) cannot serve a
   stable-track consumer.  A contaminated provider cannot serve
   any consumer.  Status segregation from cycle 31 carries into
   communication.

5. **Ledger-recorded.**  Every communication event (declare,
   emit, offer, match, accept, reject, unresolved) writes to
   `COMM-LEDGER` (a new observation channel, separate from the
   meta-ledger and the trace).  Communication is fully auditable.
   Per cycle-25E observational-only rule, `COMM-LEDGER` does
   NOT enter `law_hash` or `world_hash`.

---

## What cycle 35 is NOT (binding)

- **Not agents.**  Cands do not have intentions, goals, or
  decision logic.  Every request and offer is a mechanical
  emission tied to a measurable predicate.
- **Not consciousness.**  "Composite communication" is shorthand
  for "two cands interacting through a deficit-and-capability
  protocol" — no claim about awareness.
- **Not "let me request."**  Callers do not request on behalf
  of cands.  The runtime, evaluating deficit predicates, emits.
- **Not new ontological primitives.**  Per cycle 34B archaeology:
  all cycle-35 surface additions are L1 grammar verbs
  (DECLARE-CAPABILITY, EMIT-REQUEST, OFFER-CAPABILITY,
  MATCH-OFFER, ACCEPT-OFFER) and L3 inspection (COMM-LEDGER,
  CAPABILITY?).  None claims primitive-alphabet status without
  separate archaeology evidence.
- **Not a bypass for existing gates.**  Any cand-state mutation
  triggered by a matched offer must STILL pass the gate that
  governs that mutation type.  Communication can only TRIGGER;
  existing gates DECIDE.
- **Not persistence.**  Communication is intra-session in cycle
  35.  Cross-session communication waits for persistence cycle.
- **Not source-tag enforcement.**  Source-tag is deferred to
  the persistence cycle.

---

## Five deficit types (binding initial set)

A **deficit** is a predicate over current law-state that evaluates
to `(deficit-kind cand_id magnitude)` or `#f`.

### D1 — energy-deficit

```
energy-deficit?(c) ≡ MOMENTUM-NATIVE(c) < -STALE_TOLERANCE
                      AND status(c) ∈ ACTIVE-METAB-STATUSES
                      AND status(c) ∉ {'decomposed, 'contaminated}
```

Magnitude: `|MOMENTUM-NATIVE(c)| - STALE_TOLERANCE`.

### D2 — validation-deficit

```
validation-deficit?(c) ≡ recent_shadow_fails(c) ≥ SHADOW-FAIL-THRESHOLD
                          (e.g., 3 fails in last K dispatches)
```

Magnitude: `recent_shadow_fails(c)`.

### D3 — support-deficit

```
support-deficit?(c) ≡ status(c) = 'dependency-held
                       AND active-dependents-of(c) is non-empty
                       AND no positive-anchor in transitive chain
```

Magnitude: `count(active-dependents-of(c))`.

### D4 — decomposition-deficit

```
decomposition-deficit?(c) ≡ status(c) ∈ {'stale, 'demotion-candidate}
                             AND motif(c) contains reusable cand fragment
```

Magnitude: `length(reusable fragment)`.

### D5 — prediction-deficit (placeholder)

```
prediction-deficit?(c) ≡ deferred — requires a notion of expected
                         vs observed substrate outcome that does
                         not yet exist in the substrate
```

Cycle 35 declares D5 as a NAME ONLY.  Implementation deferred.
Future cycles may populate.

---

## Seven primitives (binding L1 grammar; per archaeology rule, NOT alphabet)

```
DECLARE-CAPABILITY  ( cand cap -- )
  Records cap (a symbol from a closed set) as offered by cand.
  Cap-set is fixed pre-commit:
    'support-anchor     : cand can serve as positive anchor for support_credit
    'validation         : cand can re-shadow-check a sibling's motif
    'decomposition-aid  : cand can provide a reusable fragment
    'energy-source      : (deferred — would map to external_credit; needs cycle 34A)
  Stores in env-memory under _capabilities alist (cand . list-of-caps).

CAPABILITY?         ( cand cap -- 0|1 )
  Inspection: does cand have cap declared?

EMIT-REQUEST        ( cand cap budget reason -- request-id )
  Called by runtime AT NEW-EPOCH after Pass C, scanning all active
  cands for active deficit predicates.  budget is in momentum units
  (max cost the request can pay).  reason is a deficit-kind symbol.
  Creates an open-request record:
    (request-id, cand, cap, budget, reason, timestamp, status='open)
  Records in _open-requests alist.  COMM-LEDGER event 'request-emitted.
  Cannot be called by user code; runtime-only.

OFFER-CAPABILITY    ( provider cap cost -- offer-id )
  Called by runtime AT NEW-EPOCH after EMIT-REQUEST scan, for each
  cand that has declared cap.  cost is the momentum the provider
  would charge.  Creates offer record:
    (offer-id, provider, cap, cost, timestamp, status='open)
  Records in _open-offers alist.  COMM-LEDGER event 'offer-emitted.
  Cannot be called by user code; runtime-only.

MATCH-OFFER         ( -- match-count )
  Called by runtime AT NEW-EPOCH after both scans.  For each open
  request, find the cheapest open offer satisfying cap and cost ≤
  budget; create match record; mark request + offer 'matched.
  COMM-LEDGER event 'match-formed per match.  Returns count of
  matches.  Cannot be called by user code; runtime-only.

ACCEPT-OFFER        ( match-id -- decision )
  For each match, check gate-preservation invariant 3:
  the matched action (e.g., support-credit boost, validation re-run)
  must STILL pass its existing lawful gate.  If passes: 'accepted.
  If fails: 'rejected-by-gate.  In either case COMM-LEDGER records
  the decision.  No law_hash mutation occurs from comm alone; the
  underlying lawful mechanism (e.g., support_credit at next NE)
  is what mutates state if anything.

COMM-LEDGER         ( -- alist )
  Inspection only.  Returns full sequence of communication events
  this session.  NOT included in law_hash / world_hash (cycle-25E
  observational-only rule extended).
```

---

## COMM-LEDGER event schema

```
(timestamp event-kind cand-or-provider extras)
```

Event kinds:
- `'declare-capability   cand cap`
- `'request-emitted      cand cap budget reason`
- `'offer-emitted        provider cap cost`
- `'match-formed         request-id offer-id cap`
- `'accept-offer         match-id decision`  ; decision ∈ {'accepted, 'rejected-by-gate, 'rejected-sandbox-isolation, 'rejected-cost}
- `'request-unresolved   request-id reason`
- `'offer-unused         offer-id`

Schema is binding.  Any new event kind requires deprecation cycle.

---

## NE-pass integration

Cycle 35 adds two new passes to NEW-EPOCH, after existing Pass C:

```
Pass A      compute m_organic, push history          (cycle 29 unchanged)
Pass A.3    increment positive_epochs counter        (cycle 34A — still deferred)
Pass A.4    energy amortization & leak               (cycle 34A — still deferred)
Pass A.5    support_credit snapshot                  (cycle 33 unchanged)
Pass B      status transitions                       (cycle 29/33 unchanged)
Pass C      AUTO-DECOMPOSE gate                      (cycle 30/32 unchanged)
Pass D NEW  deficit scan + EMIT-REQUEST              (cycle 35 NEW)
Pass E NEW  capability scan + OFFER-CAPABILITY       (cycle 35 NEW)
Pass F NEW  MATCH-OFFER + ACCEPT-OFFER + ledger      (cycle 35 NEW)
Reset       per-epoch state, observed deps, etc.
```

Pass D / E / F happen AFTER all status transitions and
decomposition gates.  Communication observes the post-metabolism
state of the epoch and emits requests/offers for the NEXT epoch's
predicates.

**Crucially:** `'open` requests/offers/matches that don't resolve
this epoch carry over to the next NE (subject to TTL — see
hyperparameter section).  After TTL expires, they become
`'expired` and are recorded in COMM-LEDGER as such.

---

## New env-memory keys (5)

```
_capabilities      alist (cand-sym . list-of-cap-syms)        ; persistent within session
_open-requests     alist (request-id . request-record)         ; per-NE rolling
_open-offers       alist (offer-id   . offer-record)           ; per-NE rolling
_matches           alist (match-id   . match-record)           ; per-NE rolling
_comm-ledger       box of list of event-records                ; cumulative session
```

All five are underscore-prefixed, protected by existing store-to-
underscore guard.

---

## Hyperparameters (fixed pre-commit)

```
SHADOW-FAIL-THRESHOLD     = 3        ; D2 deficit trigger
REQUEST-TTL-EPOCHS        = 3        ; open request lifetime
OFFER-TTL-EPOCHS          = 3        ; open offer lifetime
CAPABILITY-CAP-SET        = '(support-anchor validation decomposition-aid)
                                       ; 'energy-source deferred until 34A unblocks
COMM-LEDGER-MAX-ENTRIES   = 10000   ; per-session bound
```

NO new tunable knob.  These are structural pre-commits.

---

## Six demos (binding)

### Demo 180 — happy: energy-deficit met by support-anchor offer

Setup:
- Promote cand_001 (L=2) and cand_002 (cand_001 NODES, L=3) as fixtures.
- cand_002 declares `'support-anchor` capability.
- Drive cand_001 to energy-deficit (idle for K epochs, m_native = -3).
- NE triggers Pass D: cand_001 has D1 deficit → EMIT-REQUEST 'support-anchor.
- Pass E: cand_002 declared cap → OFFER-CAPABILITY 'support-anchor cost=0 (already serving as anchor).
- Pass F: MATCH → ACCEPT (no gate violation; gate is cycle-33 support_credit which already passes for natively-positive cand_002).

Pass conditions:
- cand_001 status = 'dependency-supported (cycle 33 mechanism)
- COMM-LEDGER contains: 'declare-capability, 'request-emitted (D1), 'offer-emitted, 'match-formed, 'accept-offer 'accepted

### Demo 181 — neg: no capability declared → request unresolved

Setup: same as 180 but cand_002 does NOT declare `'support-anchor`.

Pass conditions:
- request emitted but no matching offer
- COMM-LEDGER: 'request-emitted, 'request-unresolved
- after REQUEST-TTL-EPOCHS: request expired

### Demo 182 — neg: offer cost exceeds budget → match rejected

Setup: cand_001 emits request with budget=1.  A third cand_003 declares the cap with cost=5.

Pass conditions:
- MATCH-OFFER finds cand_003 but cost > budget
- match not formed
- COMM-LEDGER: 'offer-emitted, no 'match-formed for this request
- (or 'match-formed then 'accept-offer 'rejected-cost — depends on whether MATCH-OFFER filters by cost first or ACCEPT does; design decision in 35B)

### Demo 183 — neg: sandbox provider cannot serve stable consumer

Setup: cand_001 stable-active; cand_002 INDUCEd under `'liberal` profile → status `'experimental` or `'sandbox-stable`.  cand_002 declares the cap.

Pass conditions:
- offer emitted by cand_002
- match formed (initially)
- ACCEPT-OFFER returns 'rejected-sandbox-isolation
- cand_001 does NOT receive any support from cand_002
- COMM-LEDGER records the rejection

### Demo 184 — neg: contaminated provider cannot serve

Setup: cand_002 hit with `CONTAMINATE!`.

Pass conditions:
- cand_002 cannot offer (no offer emitted, OR offer emitted then rejected at ACCEPT)
- COMM-LEDGER reflects this
- cand_001 request unresolved

### Demo 185 — neg: request cannot bypass SHADOW-CHECK

Setup: a request whose accepted path would require cand_001 to take on a new motif (e.g., decomposition-aid offering to replace a fragment).  The decomposition path goes through normal substrate operations that include shadow-check.  Construct a scenario where the offered substitution would fail shadow-check.

Pass conditions:
- match formed
- ACCEPT-OFFER returns 'rejected-by-gate (shadow-check failed)
- cand_001 motif unchanged
- law_hash unchanged
- COMM-LEDGER records the rejection

---

## Pass / fail criteria (binding)

### PASS (all required)

1. All 7 new primitives implemented and behave per spec.
2. NE Pass D/E/F integrate without breaking cycles 25-33 demos.
3. Existing 168+ demos pass unchanged (regression invariant).
4. 6 new demos (180-185) pass.
5. COMM-LEDGER is observational only; does not enter law_hash or
   world_hash.
6. All five core invariants verified by at least one demo each:
   - Deficit-driven: 180 (D1 triggers emission)
   - Capability-bound: 181 (no declaration → no offer)
   - Gate-preserving: 185 (shadow-check still gates)
   - Sandbox-isolated: 183
   - Ledger-recorded: 180 (full event chain visible)

### FAIL (any one triggers)

1. Any cycle 25-33 demo regresses.
2. COMM-LEDGER enters law_hash or world_hash.
3. A cand without declared capability emits an offer.
4. A request fires without a deficit predicate evaluating true.
5. A matched offer mutates law-state WITHOUT passing the
   corresponding existing gate.
6. A sandbox / contaminated provider successfully serves a
   stable consumer.
7. User code can call EMIT-REQUEST or OFFER-CAPABILITY directly
   (these are runtime-only; user-callable would violate
   deficit-driven invariant).
8. A new tunable hyperparameter is added beyond the fixed
   pre-commit set.

---

## Negative tests (binding — covered by demos 181-185)

| NEG | demo | enforces invariant |
|-----|------|---------------------|
| NEG-1 | 181 | capability-bound (no cap → no offer → unresolved) |
| NEG-2 | 182 | budget-bound (cost > budget → no match) |
| NEG-3 | 183 | sandbox-isolated |
| NEG-4 | 184 | contamination-isolated |
| NEG-5 | 185 | gate-preserving (shadow-check not bypassed) |

---

## Implementation contract (cycle 35B will conform)

### runtime.rkt changes
- Add 5 new MEM_* keys (capabilities, open-requests, open-offers,
  matches, comm-ledger)
- Initialize in install-meta-runtime!
- Add `'energy-source` to CAPABILITY-CAP-SET only when cycle 34A
  unblocks (currently deferred)
- Export new symbols

### tier1.rkt changes
- Add 7 new primitives: DECLARE-CAPABILITY, CAPABILITY?,
  EMIT-REQUEST, OFFER-CAPABILITY, MATCH-OFFER, ACCEPT-OFFER,
  COMM-LEDGER
- EMIT-REQUEST and OFFER-CAPABILITY are RUNTIME-ONLY (gated by
  current-call-context predicate; user code raises)
- Add deficit predicates D1, D2, D3, D4 (D5 deferred)
- Add capability cap-set whitelist
- Add Pass D/E/F to prim-new-epoch (in this order, after Pass C,
  before per-epoch resets)
- At end of NE: prune expired requests/offers via TTL counter

### NO VM changes
Communication is meta-runtime layer; no new VM hooks needed.

### Inspection
- COMM-LEDGER, CAPABILITY? added to INSPECTION-OPS
- EMIT-REQUEST / OFFER-CAPABILITY / MATCH-OFFER / ACCEPT-OFFER
  are NOT inspection (they are mutators of comm state, recorded
  in COMM-LEDGER not the regular ledger)

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. No new tunable hyperparameter beyond the fixed set.
3. EMIT-REQUEST and OFFER-CAPABILITY are runtime-only.  User code
   calling them raises an error.  This enforces deficit-driven
   invariant mechanically.
4. COMM-LEDGER is observational only.  Cycle-25E `_energy-*` rule
   extends: `_capabilities`, `_open-requests`, `_open-offers`,
   `_matches`, `_comm-ledger` all NOT in law_hash / world_hash.
5. Any cand-state mutation triggered via communication MUST
   route through the existing lawful gate for that mutation
   type.  Communication never bypasses; it only triggers.
6. Capability declarations are persistent within session, reset
   at session boundary (no cross-session persistence in cycle 35;
   awaits persistence cycle).
7. Status segregation from cycle 31 (sandbox vs stable) is
   enforced in MATCH and ACCEPT phases.
8. The 5 deficit predicates D1-D5 are the closed initial set.
   New predicates require deprecation cycle.
9. Per cycle 34B archaeology: NONE of the 7 new primitives is
   claimed as alphabet primitive.  They are all L1 grammar
   verbs over L3/L4 surfaces.  Any archaeology-promotion
   requires separate evidence per cycle 34B binding schema.
10. Attestation BEFORE source code.

---

## What this cycle does NOT claim

- That composites have intentions, goals, or decision logic.
- That communication is "emergence" or "self-organization."
- That a matched request constitutes successful prediction.
- That deficit predicates are exhaustive.
- That the seven primitives are alphabet-tier (per cycle 34B —
  they are grammar / inspection, not primitive distinctions).
- That this enables persistence (it doesn't; persistence remains
  deferred).
- That this provides a substrate-discovered L2 entry (the L2
  count remains 0 per cycle 34C-bis).

It claims only:

1. Cands can declare structural capabilities.
2. Runtime can scan deficits and emit requests mechanically.
3. Runtime can match requests with capability-bound offers.
4. Matched offers route through existing gates (no bypass).
5. The full chain is observable via COMM-LEDGER.

If demos 180-185 all pass AND existing 168+ demos still pass
unchanged, **deficit-driven composite communication is
operational** without introducing agency claims, gate bypasses,
or status pollution.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25-34 frozen; user spec 2026-05-25
      (composites do not consciously request; deficit-driven
      emission; capability-bound offer; gate-preserving; sandbox-
      isolated; ledger-recorded)
- [x] Rule 3: deterministic — deficit predicates, offer cost
      ordering, match priority, gate routing all explicit
- [x] Rule 4: pass/fail partition outcome space across 6 demos
- [x] Rule 5: real intra-session interactions; not toy
- [x] Rule 6: results file `RESULTS-180-cycle35-comm.md` will
      record final pass count update
- [x] Rule 7: 5 negative-test demos (181-185)
- [x] Rule 8: scope = 7 primitives, 5 env-keys, 3 new NE passes,
      0 new tunable hyperparameter, 0 new alphabet primitives
- [x] Rule 9: attestation pending

---

## References

- METHODOLOGY.md v2.1 §17
- `examples/PREDICTIONS-179-persistence-layer.md` — DEFERRED
  cycle (source-tag firewall awaits durable L2)
- `RESULTS-178-bootstrap-alphabet-archaeology.md` — bootstrap
  audit (7 primitives, no new ones in this cycle)
- `RESULTS-179-substrate-discovered-alphabet.md` — L2 = 0
- `CLAIMS.md` — CLAIM-1 through CLAIM-5, ontological five-layer
- `docs/META-SEMANTICS.md` §18 — no-new-primitive-without-archaeology
- User spec 2026-05-25 — runtime mutation/evolution main line;
  deficit-driven composite communication; five invariants; five
  deficit kinds; seven primitives; six demos
