# RESULTS-185 — Cycle 37: Re-entry / First Closure

Pre-reg: `examples/PREDICTIONS-185-cycle37-reentry-first-closure.md`
Implementation: `sixth/meta/triggers.rkt` + demos 192, 193
Regression: **2340 / 2340 ✓** across 182 demos

---

## Headline

**CLAIM-37 CONFIRMED.** Under pattern-triggered dispatch with
consume semantics, a promoted law sustained its own metabolism for
3 epochs after ALL external dispatches stopped — and the closure is
non-trivial: a law that consumes without rebuilding starves and
decomposes under the same physics.

This is the first time anything in the substrate **exists by
itself**: maintains positive momentum with zero externally-authored
activity, paying full canon taxes (carry + inflation), funded
exclusively by world-structure its own firings rebuild.

Operational claim only: "closure" = self-maintained reuse under
external cutoff.  No claims of life, autonomy, agency, cognition.

## The physics extension (one layer, frozen)

`BIND-TRIGGER / UNBIND-TRIGGER / WORLD-TICK / TRIGGER-COUNT`
(sixth/meta/triggers.rkt).  Pattern vocabulary v0: `'edge`,
`'path2`, `'selfloop` — with consume semantics (matching deletes
the matched elements).  `'isolated-node` deferred: substrate nodes
are never deleted by design (documented pre-reg deviation).

Honesty mechanics, all verified by demo asserts:
- Only `'stable-active` laws fire (status gate).
- Dispatch via `try-dispatch-cand!` — the same counters as external
  calls; use-counter delta == fired count exactly (NEG-4).
- `WORLD-TICK-BUDGET = 8` successful firings per tick, hard cap
  (NEG-5: saturated world with 20 matches fires exactly 8).
- Consumed elements are not restored on dispatch failure.
- `_triggers` cleared by BOOTSTRAP-RESET and checked as an
  empty-state axis (NEG-7).

## H1 — closure existence: CONFIRMED (demo 192, 19 asserts)

Law: `(MARK MARK bi-edge)`, L=3, promoted through the full canon
pipeline, bound to `'edge`.  World wiped after genesis, seeded with
exactly ONE bidirectional pair (2 edges).

| epoch (post-cutoff) | fired | momentum | status |
|---|---|---|---|
| 1 | 8 | +12 | stable-active |
| 2 | 8 | +12 | stable-active |
| 3 | 8 | +12 | stable-active |

**Rebuild proof:** 2 seed edges → 10 edges after one tick
(each firing consumes 1, the body creates 2).  24 firings over 3
epochs cannot be explained by 2 edges of capital — the loop grows
its own trigger supply.  Self-funded, not capital-funded.

**Unbind control (H4):** cutting the binding ends the persistence —
'stale after one epoch, 'decomposed after two.  Presence requires
the loop; nothing here is special-cased.

## H2 — no perpetual motion: CONFIRMED (demo 193, 16 asserts)

Law: `(MARK drop)`, L=2 — consumes an edge per firing, builds only
isolated nodes.  World stocked with exactly 20 edges, then cutoff.

| epoch | fired | edges left | status |
|---|---|---|---|
| 1 | 8 | 12 | stable-active |
| 2 | 8 | 4 | stable-active |
| 3 | 4 | 0 | **stale** (m=+1 ≤ tolerance) |
| 4 | 0 | 0 | stale (m=−3) |
| 5 | 0 | 0 | **decomposed** |

Post-mortem: world refilled with fresh edges → fired = 0.  A
decomposed law does not fire (NEG-3, no resurrection).

**Finer than predicted:** the physics marked the half-starved state
(4 firings → m=+1 → 'stale) before death.  The pre-reg predicted
binary starvation; the metabolism resolved the gradient.

## H3 — tick-rate threshold: PARTIALLY OBSERVED

No dedicated demo.  However demo 193 epoch 3 directly exhibits the
phenomenon: a working loop firing below break-even (4 × 1 = 4
reuse vs 3 tax) lands at m=+1 → 'stale.  Presence has a metabolic
price, not just a topological one.  A dedicated sub-replacement
demo (`'path2` consuming 2, building 1) remains available as
follow-up; H3 was pre-registered as directional, and the direction
is confirmed by the 193 gradient.

## NEG coverage

| NEG | covered by |
|---|---|
| NEG-1 perpetual motion impossible | demo 193 (drain → starve → decompose) |
| NEG-2 no free firing | demo 192 (0 bindings → 0 fired) |
| NEG-3 status gate / no resurrection | demo 193 post-mortem (refilled world, 0 fired) |
| NEG-4 honest accounting | demo 192 (use-counter delta == 8 == fired) |
| NEG-5 budget cap | demo 193 e1 (20 matches, exactly 8 fired) |
| NEG-6 canon preservation | regression 2340/2340 ✓ |
| NEG-7 reset hygiene | demo 192 (bind → BOOTSTRAP-RESET → TRIGGER-COUNT 0) |

## Incidental finding (worth its own note)

HELD-OUT-EVAL leaves the last held-out substrate's graph (~116
edges) in the world after promotion.  Both demos initially fed on
this startup capital, masking their intended dynamics (the parasite
looked immortal).  Fixed in-demo with RESET + explicit seeding;
flagged as a candidate engine cleanup (HELD-OUT-EVAL could restore
the pre-eval world) for a future cycle — it touches heldout
semantics, so it needs its own pre-reg.

## What "от различия к наличию" means here, precisely

- **Различие**: MARK creates a distinction; a law is a frozen
  distinction-pattern.
- **Наличие**: demo 192's law persists with no one running it.
  Its firings consume the condition of their own firing and
  re-create it — Spencer-Brown re-entry, implemented as graph
  dynamics, paid for at canon metabolic rates, machine-verified
  by 35 assertions.
- The difference between the two demos is exactly the difference
  between a loop and a leak.  The physics distinguishes them
  without being told which is which.

## Cycle 37 status — CLOSED

| item | status |
|---|---|
| PREDICTIONS-185 pre-reg | attested (incl. isolated-node deferral patch) |
| triggers.rkt physics layer | ✓ frozen |
| H1 closure existence | ✓ confirmed |
| H2 no perpetual motion | ✓ confirmed |
| H3 tick-rate threshold | directionally observed (193 e3) |
| H4 cutoff/unbind control | ✓ confirmed |
| NEG 1-7 | ✓ all covered |
| Regression | 2340/2340 ✓ |

## Cycle 38 direction (informational, needs its own pre-reg)

**Evolved closure.**  Cycle 37's bindings are hand-wired.  The
next question: can the substrate DISCOVER bindings — e.g., a
mining pass that proposes (pattern, law) pairs from observed
co-occurrence of world-states and productive dispatches, with the
same promote/decay economics applied to bindings themselves?
Closure that is found, not built, would be the first evolved
presence.  Multi-law ecosystems (mutualism via `'path2`/`'selfloop`
cross-feeding) are the second axis.
