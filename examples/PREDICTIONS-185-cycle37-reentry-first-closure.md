# PREDICTIONS-185 — Cycle 37: Re-entry / First Closure

**Date pre-registered:** 2026-06-12
**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Cycle context

Cycle 36R (RESULTS-184 corrected) established outcome #1: the
canon's fixed physics discriminates on productivity, not shape.
The selection environment works.

But every surviving law is on life support: cands receive reuse
ONLY from externally-authored workload dispatches.  Cut the
workload and everything decays within MOMENTUM-NEGATIVE-THRESHOLD
epochs.  The substrate has **distinction** (MARK) and **selection**
(metabolism) but no **presence**: nothing exists by itself.

Root architectural cause: law evolution listens to the TRACE
(syntactic operation stream, written by the engineer) while law
execution writes to the WORLD (hypergraph).  The output channel of
a law and the input channel of law-activation never meet, so no
loop can close.

Cycle 37 builds the missing bridge: **pattern-triggered laws** —
a promoted law can be bound to a graph pattern; when the pattern
is PRESENT in the world, the law fires.  A law whose execution
reproduces the conditions of its own (or its partners') firing is
re-entry in the Spencer-Brown sense: a distinction that feeds
itself.  Operationally: a law-set that maintains its own reuse
without external dispatches.

## Core claim (machine-verifiable; no cognition/agency claims)

> CLAIM-37: Under the extended physics (pattern-triggered dispatch
> with consume semantics), there EXISTS a configuration of
> promoted laws that maintains positive metabolism for ≥ 3 epochs
> after ALL external workload dispatches stop — and this closure
> is NON-TRIVIAL: configurations that consume without rebuilding
> starve and decay under the same physics.

Scope honesty: cycle 37 proves closure is POSSIBLE and non-trivial
under the physics, with hand-wired trigger bindings (analogous to
cycle 35 genesis fixtures).  EVOLVED closure — where the bindings
themselves are discovered by the substrate — is cycle 38+, a
separate pre-reg.  No claim that hand-wired closure constitutes
autonomy, life, or cognition.  The operational term is "closure":
self-maintained reuse, nothing more.

## Physics extension (the ONLY one; everything else is existing machinery)

### New layer: trigger bindings

```
BIND-TRIGGER   ( pattern-sym cand-sym -- )
UNBIND-TRIGGER ( cand-sym -- )
WORLD-TICK     ( -- fired-count )
TRIGGER-COUNT  ( -- n )
```

**Pattern vocabulary v0 (fixed, frozen):**

| pattern-sym | matches | consume semantics |
|-------------|---------|-------------------|
| `'edge` | any directed edge (a,b) | delete that edge |
| `'path2` | edges (a,b),(b,c) | delete both edges |
| `'selfloop` | edge (a,a) | delete it |
| `'isolated-node` | node with in-degree 0 and out-degree 0 | delete the node |

General unification / variable patterns deferred to a future
cycle.  v0 vocabulary is deliberately small: enough to express
autocatalysis (edge → consumes edge, body recreates an edge) and
parasitism (consumes edge, body creates nothing connective).

### WORLD-TICK semantics (binding)

1. Iterate trigger bindings in binding order (deterministic).
2. A binding fires only if its cand's CURRENT status is
   `'stable-active` (laws of the world must be actual laws;
   decomposed/stale cands do not fire).
3. Pattern matched against current graph, deterministic order
   (lowest node ids first).  On match: CONSUME (delete matched
   elements) THEN dispatch the cand through the NORMAL dispatch
   path (`try-dispatch-cand!`) so reuse counters bump exactly as
   for an external call.  No special crediting.
4. Per-tick firing budget: `WORLD-TICK-BUDGET = 8` (hard cap,
   frozen).  Prevents runaway cascades within one tick.
5. A failed dispatch (exception in cand body) counts as a recent
   failure (existing cycle 30 semantics) AND the consumed elements
   are NOT restored — failure has a real cost.
6. Returns the number of successful firings.

### Why consume semantics is load-bearing

Without consumption, one static match would fire every tick
forever: a perpetual-motion law with zero maintenance cost — fake
presence.  With consumption, every firing destroys its own
trigger; persistence requires that SOMETHING (the fired law's own
body, or a partner law) rebuilds trigger conditions.  Presence
must be PAID FOR in world-structure.  This is the operational
content of "от различия к наличию": a distinction that persists
only if it keeps re-creating itself.

### Metabolism is unchanged

All cycle 25-33 taxes still apply: carry, inflation=1, momentum
window, stale tolerance, auto-decompose.  World-driven reuse
counts exactly like external reuse — no separate economy.  For a
law with expansion length L fired K times per epoch:
m = K·(L−1) − L − 1, same formula.  Closure requires the firing
rate sustained by the world to clear the same bar external
workloads had to clear.

## Closure criterion (binding, machine-verifiable)

A set S of promoted laws exhibits closure over epochs [t, t+N] iff:

1. Zero external cand dispatches occur in [t, t+N] (workload cut).
2. Every member of S retains status `'stable-active` through t+N.
3. Every member's per-epoch reuse in [t, t+N] comes exclusively
   from WORLD-TICK firings (verifiable: ledger + use counters).
4. N ≥ 3 (strictly more than MOMENTUM-NEGATIVE-THRESHOLD = 2, so
   survival cannot be explained by metabolic latency).

## Hypotheses

- **H1 (closure existence):** a single law (body: MARK MARK
  bi-edge, L=3) bound to `'edge` survives ≥ 3 post-cutoff epochs:
  each firing consumes one edge and creates one new edge —
  trigger-neutral, reuse-positive at sufficient tick rate.
- **H2 (no perpetual motion):** a law (body: MARK drop, L=2)
  bound to `'edge` consumes edges without rebuilding any; the
  graph's edge supply drains, firings stop, momentum goes
  negative, the law decays to `'decomposed` — under the SAME
  physics, same tick schedule.
- **H3 (tick-rate threshold):** for the H1 law, K firings/epoch
  with K·2 ≤ 4 (i.e. K ≤ 2) is below break-even (m = 2K−4 ≤ 0):
  insufficient tick rate → decay despite a working loop.
  Presence has a metabolic price, not just a topological one.
- **H4 (cutoff control):** the same H1 law WITHOUT a trigger
  binding, after workload cut, decays within 2 epochs (existing
  physics, sanity control).

## What cycle 37 is NOT

- Not evolved/discovered bindings (hand-wired; discovery = 38+).
- Not multi-species ecosystems (single-law closure only; 38+).
- Not general pattern unification (fixed v0 vocabulary).
- Not new alphabet primitives in the bootstrap sense — triggers
  are L1-grammar machinery, like DETECT-MOTIF-AUTO.
- Not a claim of life, autonomy, agency, or cognition.  "Closure"
  = self-maintained reuse under cutoff.  Period.
- Not modification of any cycle 25-33 metabolism constant.

## Negative tests (binding)

- **NEG-1 (perpetual motion impossible):** H2 demo — consuming
  parasite drains the world and dies.
- **NEG-2 (no free firing):** WORLD-TICK with zero bindings → 0
  fired; WORLD-TICK with binding whose pattern is absent → 0.
- **NEG-3 (status gate):** binding for a cand that has decomposed
  does not fire; no resurrection via trigger path.
- **NEG-4 (honest accounting):** every WORLD-TICK firing goes
  through try-dispatch-cand! — verified by use-counter deltas
  matching fired-count exactly.
- **NEG-5 (budget cap):** a world saturated with matches fires at
  most WORLD-TICK-BUDGET per tick.
- **NEG-6 (canon preservation):** full regression unchanged
  (2305 ✓ baseline before registering new demos).
- **NEG-7 (reset hygiene):** BOOTSTRAP-RESET clears all trigger
  bindings; _triggers is a checked empty-state axis.

## Implementation contract (cycle 37B will conform)

1. `sixth/meta/triggers.rkt`: trigger registry as `_triggers`
   box-alist in env-memory; pattern matcher over substrate
   out-edges (deterministic order); the four primitives.
2. `_triggers` added to install-meta-runtime! AND reset-meta-state!
   (field-parallel, per audit discipline) AND
   bootstrap-state-clean? axis list.
3. Primitives registered as inspection-ops EXCEPT WORLD-TICK
   (it mutates the world and dispatches laws — it is a world
   operation and must bump semantic-trace like any other).
4. Demos: H1 closure happy path, H2 starvation NEG, H3 threshold,
   H4 cutoff control, NEG-2/3/4/5/7 (combined where natural).
5. RESULTS-185 records which hypotheses held.

## PASS / FAIL

PASS requires: H1, H2, H4 confirmed; all NEG behaviors observed;
regression green.  H3 is directional (expected confirmed; a
surprise here is a finding, not a failure).

FAIL: any perpetual-motion configuration survives cutoff with
zero world-structure cost; or any regression breaks; or trigger
path credits reuse without try-dispatch-cand!.

## References

- RESULTS-184 (corrected) — outcome #1, physics validated
- PREDICTIONS-184 — fixed-physics framing (this cycle extends
  the physics by exactly one layer and freezes it)
- Spencer-Brown, Laws of Form — re-entry (conceptual anchor only;
  no formal claim of equivalence)
- Maturana/Varela autopoiesis; Kauffman autocatalytic sets —
  conceptual anchors for the closure criterion (operational
  definition above is self-contained and machine-checkable)
