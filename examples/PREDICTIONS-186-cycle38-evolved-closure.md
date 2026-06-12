# PREDICTIONS-186 — Cycle 38: Evolved Closure (Discovered Bindings)

**Date pre-registered:** 2026-06-12
**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Cycle context

Cycle 37 (RESULTS-185) established FIRST CLOSURE: a law bound to a
world pattern sustained its own metabolism after external cutoff,
and the closure was non-trivial (parasites starve).  But the
binding was HAND-WIRED: the engineer told the law which pattern
feeds it.

Cycle 38 asks: can the substrate DISCOVER the binding itself?

A closure that is FOUND, not built, is the first evolved presence:
the (pattern, law) coupling emerges from the system's own history
rather than from design.

## Core claim (machine-verifiable; no cognition/agency claims)

> CLAIM-38: With co-occurrence mining — counting, for each
> promoted law, how often each v0 pattern was PRESENT in the world
> at the law's dispatch — and a threshold gate, the substrate
> proposes (pattern, law) bindings WITHOUT engineer wiring; and a
> law so bound exhibits closure (≥3 post-cutoff epochs) under the
> unchanged cycle 37 physics.  Discovery is deliberately
> permissive; the metabolism is the filter: a discovered binding
> for a non-rebuilding law still starves and decomposes.

Operational terms only.  "Discovery" = threshold-crossing of an
observed co-occurrence counter.  No claims of learning, intention,
or understanding.

## Discovery mechanism (binding spec)

### Ecological observation

On every top-level dispatch of a cand law (the existing
cand-dispatch-hook path), the engine checks which v0 patterns
(`'edge`, `'path2`, `'selfloop`) are currently PRESENT in the
world (cheap early-exit scans, no consumption) and bumps a
per-(cand, pattern) co-occurrence counter `_binding-cooccur`.

This mirrors the epistemology of DETECT-MOTIF-AUTO exactly: motifs
are mined from repetition in the trace; bindings are mined from
repetition of (world-state, dispatch) coincidence.  Same honesty
discipline: the engine observes, it does not interpret.

### Test-chamber exclusion (binding)

Dispatches that occur INSIDE `HELD-OUT-EVAL` do NOT contribute to
co-occurrence.  The held-out substrates are an evaluation chamber,
not the law's ecology; counting them would let every promoted law
"discover" an `'edge` binding merely because the test worlds
contain edges.  Implemented as a suspension flag set for the
dynamic extent of held-out evaluation.

### Threshold gate

```
DETECT-BINDING-AUTO ( -- new-bindings-count )
BINDING-COOCCUR     ( pattern-sym cand-sym -- n )
BINDING-COOCCUR-N = 5    (frozen; mirrors COUPLING-N)
```

DETECT-BINDING-AUTO scans `_binding-cooccur` and, for every
(cand, pattern) with count ≥ BINDING-COOCCUR-N where:
  - the cand's current status is `'stable-active`, and
  - the binding is not already registered,
appends the binding to `_triggers` (identical structure to a
hand-wired BIND-TRIGGER) and records ledger event `'auto-bind`.
Idempotent: a second call discovers nothing new.

Session-coupling for bindings (distinct-session requirement,
mirroring COUPLING-M) is NOT in v0 — documented simplification;
hardening candidate for a later cycle if single-burst flukes are
observed in practice.

### What discovery does NOT do

- It does not check whether the law REBUILDS the pattern.
  Discovery is correlation-only and deliberately dumb.  The
  cycle 37 metabolism decides which discovered bindings are loops
  and which are leaks.  Selection is the filter, not the proposer
  (Kauffman-style: permissive generation + strict selection).
- It does not create new patterns (vocabulary stays frozen v0).
- It does not bind non-promoted laws.

## Hypotheses

- **H1 (evolved closure):** for the autocatalytic law
  (MARK MARK bi-edge), the standard genesis pipeline ITSELF
  provides the discovery data — its coupling dispatches occur in a
  world that its own workload filled with edges.  After promotion,
  DETECT-BINDING-AUTO discovers at least ('edge, cand); the
  bidirectional pair also forms a→b→a, so ('path2, cand) may
  co-occur as well.  After external cutoff the law survives ≥ 3
  epochs on discovered bindings only — evolved closure.
- **H2 (no spurious discovery):** a law whose dispatches occur in
  a pattern-free world accumulates zero co-occurrence and gets no
  bindings (NEG-1); sub-threshold co-occurrence (< 5) gets none
  (NEG-2); crossing the threshold with further ecological
  dispatches then triggers discovery — the gate responds to
  accumulating evidence, not to single events.
- **H3 (selection filters dumb discovery):** a DISCOVERED binding
  for the parasite law (MARK drop) — which consumes edges and
  rebuilds nothing — still leads to drain, starvation, and
  decomposition under unchanged physics.  Discovery being
  permissive is safe because metabolism is strict.
- **H4 (test-chamber exclusion):** held-out dispatches contribute
  nothing to co-occurrence: a law promoted in a pattern-free
  ecology has zero counts despite ~30 held-out dispatches in
  edge-rich test worlds.

## What cycle 38 is NOT

- Not new patterns or pattern evolution (vocabulary frozen v0).
- Not multi-law ecosystems (single-law closures; next cycles).
- Not causal inference: co-occurrence is correlation, and that is
  the point — metabolism supplies the causal filter.
- Not modification of cycle 37 trigger physics or cycle 25-33
  metabolism constants.
- Not claims of learning, intention, cognition, or life.

## Negative tests (binding)

- **NEG-1 (no correlation, no binding):** pattern-free ecology →
  zero co-occurrence → DETECT-BINDING-AUTO finds 0.
- **NEG-2 (threshold honest):** co-occurrence 1..4 → 0 bindings;
  the 5th ecological co-occurring dispatch enables discovery.
- **NEG-3 (status gate):** co-occurrence above threshold for a law
  that is NOT 'stable-active produces no binding.
- **NEG-4 (idempotence):** repeated DETECT-BINDING-AUTO does not
  duplicate bindings.
- **NEG-5 (reset hygiene):** BOOTSTRAP-RESET clears
  `_binding-cooccur` and auto-bindings; `_binding-cooccur` is a
  checked empty-state axis.
- **NEG-6 (test-chamber exclusion):** = H4.
- **NEG-7 (canon preservation):** full regression unchanged
  (2340 ✓ baseline before new demo registration).

## Implementation contract (cycle 38B will conform)

1. `runtime.rkt`: pattern-presence checks (edge/path2/selfloop,
   early-exit, no consumption) + `_binding-cooccur` bump inside
   make-cand-dispatch-hook's cand branch; suspension parameter
   `current-binding-observation-suspended`; `_binding-cooccur` in
   install-meta-runtime! AND reset-meta-state! (parity).
2. `tier1.rkt`: prim-held-out-eval-real parameterizes the
   suspension flag for its full extent.
3. `triggers.rkt`: DETECT-BINDING-AUTO + BINDING-COOCCUR,
   BINDING-COOCCUR-N = 5 frozen; auto-bindings land in the same
   `_triggers` registry as hand-wired ones (cycle 37 physics
   applies unchanged).
4. `bootstrap.rkt`: `_binding-cooccur` empty-state axis.
5. INSPECTION-OPS: DETECT-BINDING-AUTO + BINDING-COOCCUR (mining /
   inspection, same class as DETECT-MOTIF-AUTO).
6. Demos: H1 evolved-closure happy path; H2+H3 control arc
   (pattern-free genesis → no binding → sub-threshold → threshold
   crossing → discovered parasite starves).
7. RESULTS-186 records outcomes.

## PASS / FAIL

PASS: H1, H2, H3, H4 confirmed; NEG-1..7 observed; regression
green.

FAIL: any binding discovered without threshold crossing; heldout
dispatches leak into co-occurrence; discovered binding bypasses
any cycle 37 honesty mechanic (status gate, budget, consume,
honest accounting); regression breaks.

## References

- PREDICTIONS-185 / RESULTS-185 — cycle 37 trigger physics (frozen)
- PREDICTIONS-184 / RESULTS-184 (corrected) — fixed-physics framing
- docs/mining_protocol.md — DETECT-MOTIF-AUTO epistemology this
  cycle mirrors at the binding level
