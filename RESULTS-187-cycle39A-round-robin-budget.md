# RESULTS-187 — Cycle 39A: Round-Robin Budget Probe

Pre-reg: `examples/PREDICTIONS-187-cycle39A-round-robin-budget.md`
Implementation: `sixth/meta/triggers.rkt` `prim-world-tick` (one rule rewritten)
Regression: **2373 / 2373 ✓** across 184 demos (192/193 untouched per H1)

---

## Headline

**H3-B confirmed; H3-G rejected.**  The monoclone is a property
of the law's body, not of greedy budget allocation.  Round-robin
changed which bindings act, but the world's growth stays exactly
linear — only the coefficient moved.

This localizes the source of the cycle-38 linearity precisely:
not engineering, but the structural decision that the only law to
promote (under this workload family) is `MARK MARK bi-edge`,
whose body creates fresh structure independent of every existing
structure.  Eight firings per tick make eight disjoint copies.
Round-robin redistributes them; it cannot make them interfere.

The right next move is therefore multi-law ecosystems with
interfering bodies, not better schedulers.

## Hypotheses — outcomes

- **H1 (single-binding neutrality):** ✓ confirmed.  Demos 192 (19
  asserts) and 193 (16 asserts) pass byte-identically under
  round-robin.  Their single binding makes round-robin degenerate
  into greedy by construction.
- **H2 (dormant binding wakes):** ✓ confirmed.  In demo 195 the
  parasite's second discovered binding `('path2, cand_001)` now
  fires.  In a fully fed world its firing rate equals `'edge`'s
  by round structure.
- **H3-B (homogeneous body is the linearity source):** ✓
  confirmed by scaling series below.
- **H4 (closure survives):** ✓ confirmed.  Demo 194 still
  promotes, still discovers, still survives ≥3 post-cutoff epochs.

## Scaling series under round-robin

| epochs | nodes | edges | wall-clock | nodes vs greedy | edges vs greedy |
|---|---|---|---|---|---|
| 500 | 8 002 | **2 002** | 1.5 s | same | **−50%** |
| 1 000 | 16 002 | **4 002** | 3.9 s | same | **−50%** |
| 2 000 | 32 002 | **8 002** | 13.5 s | same | **−50%** |
| 4 000 | 64 002 | **16 002** | 53.5 s | same | **−50%** |

Two things to read here:

1. **Node growth is identical to greedy.**  Budget = 8 firings
   per tick, body = `MARK MARK bi-edge` creates 2 fresh nodes per
   firing, both bindings call the same body.  +16 nodes per epoch
   regardless of who fires.

2. **Edge growth halved.**  Under greedy, `'edge` (consume 1
   edge, body creates 2) fires all 8 → +8 edges/epoch.  Under
   round-robin the budget splits 4/4: four `'edge` firings
   (+4 net) and four `'path2` firings (consume 2, build 2, net 0)
   → +4 edges/epoch.  Exactly observed.

Linearity itself — the suspicious thing — survived.  The world
still grows monotonically with no fluctuation, just with half the
edges per node.  Two bindings doing the same thing in different
fresh regions of the graph make exactly twice the boring world.

## Mechanism, post-probe

The cycle-38 monoclone has TWO orthogonal contributors:

| factor | does it cause the boring linearity? |
|---|---|
| greedy budget (cycle 37 scheduling choice) | **no** — round-robin gives the dormant binding airtime but produces a different boring linearity |
| homogeneous law body (`MARK MARK bi-edge` creates disjoint structure) | **yes** — every firing acts on a fresh part of the graph; no firing observes or modifies the work of another firing |

The law's body has no `NEIGH`/`STEP`/`NSUM`/`EDGE?` — no read of
world state at all.  It is a constant emitter.  No scheduler can
manufacture interference where the bodies don't ask for any.

## What this rules in and out

- **In:** richness needs bodies that READ the world.  Either
  (a) the same workload promotes multiple competing laws with
  different bodies, or (b) a future cycle relaxes promotion to
  admit state-reading laws (this changes promotion semantics → its
  own pre-reg).
- **In:** multi-law ecosystems with interfering bodies are the
  honest next experiment.  One creates edges in one region; the
  other consumes from that same region.  Niche, mutualism,
  competition for budget — all of it needs interference, and
  interference needs reading.
- **Out:** scheduler complexity (priority queues, weighted
  budget, learned scheduling).  None of it helps a constant
  emitter.

## Cycle 39A status — CLOSED

| item | status |
|---|---|
| PREDICTIONS-187 pre-reg | attested before source |
| `prim-world-tick` round-robin rewrite | ✓ (single-rule change) |
| 192 / 193 H1 neutrality | ✓ byte-identical |
| 194 closure under round-robin | ✓ |
| 195 H2/H3 confirmation | ✓ (assert updated 8 → 6 fired with traced explanation) |
| Scaling 500-4K probe | ✓ |
| Regression | 2373 / 2373 ✓ |

## Cycle 39B direction (own pre-reg required)

Multi-law ecosystem on a single fixed workload.  Goal: PROMOTE
two distinct laws — one whose body emits edges, one whose body
modifies existing edges — and let their discovered bindings
compete for the same budget on the same world.  The hypothesis to
test: with body-level interference, the steady-state stops being
linear; the system either oscillates, finds a non-monotone
equilibrium, or one law starves the other.  Any of those would
constitute the first non-monoclone closure observed in this
substrate.

A subordinate question for the same cycle: can the genesis
workload itself BE DESIGNED so the standard mining promotes both
laws together?  Or is a structural change to DETECT-MOTIF-AUTO
needed?  Current evidence (cycle 35 fixtures and cycle 38
discovery) suggests one-law-per-workload is the default outcome,
and engineering a two-law genesis without changing physics is
non-trivial.  That subordinate question is part of the cycle 39B
pre-reg.
