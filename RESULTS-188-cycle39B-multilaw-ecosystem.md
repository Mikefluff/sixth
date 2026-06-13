# RESULTS-188 — Cycle 39B: Multi-Law Ecosystem (OUT-EQ confirmed)

Pre-reg: `examples/PREDICTIONS-188-cycle39B-multilaw-ecosystem.md`
Demo: `examples/196-multilaw-ecosystem.6th` (25 asserts)
Long-run: `experiments/longrun-multilaw.6th` (manual, 500/2000 epochs)
Regression: **2398 / 2398 ✓** across 185 demos

---

## Headline

**OUT-EQ confirmed.** Two laws with interfering bodies, both
promoted and bound, reach a stable non-zero edge equilibrium and
hold it for thousands of epochs.  The edge count stays at exactly
the seed value (2) — not because the laws are dormant, but
because they fire continuously at compensating rates and undo
each other's edge work tick after tick.

This is the first time the substrate's world growth is NOT
linear: edges are flat, not climbing.  The cycle-38 monoclone
shape is broken precisely where the probe predicted —
interference between law bodies — and broken into the cleanest of
the four possible outcomes.

Operational claims only.  "Equilibrium" = constant observed count
under continuous activity.  No claims of homeostasis, agency, or
biological analogy.

## Construction

Two laws, both promoted through the standard canon pipeline:

| law | motif body | bound to | firing effect |
|---|---|---|---|
| A | `MARK MARK bi-edge` | `'edge` | consume 1, body +2 → **+1 edge, +2 nodes** |
| B | `MARK MARK EDGE+`   | `'path2` | consume 2, body +1 → **−1 edge, +2 nodes** |

Promotion: sequential genesis with `RESET` between phases (no
`NEW-EPOCH` between — see "Implementation lesson" below).  Both
reach `'stable-active` cleanly.

Bindings: hand-wired per pre-reg fallback (mining co-occurrence
report below).  Cycle 37/38/39A physics unchanged.

## Per-epoch trace (demo 196 — first eight epochs)

| epoch | fired_A | fired_B | nodes | edges | status_A | status_B |
|---|---|---|---|---|---|---|
| 1 | 4 | 4 | 18 | 2 | stable-active | stable-active |
| 2 | 4 | 4 | 34 | 2 | stable-active | stable-active |
| 3 | 4 | 4 | 50 | 2 | stable-active | stable-active |
| 4 | 4 | 4 | 66 | 2 | stable-active | stable-active |
| 5 | 4 | 4 | 82 | 2 | stable-active | stable-active |
| 6 | 4 | 4 | 98 | 2 | stable-active | stable-active |
| 7 | 4 | 4 | 114 | 2 | stable-active | stable-active |
| 8 | 4 | 4 | 130 | 2 | stable-active | stable-active |

Round-robin splits the budget exactly 4/4.  A nets +4 edges per
tick (4 firings × +1), B nets −4 edges per tick (4 × −1), they
cancel.  Edges sit at the seed value of 2 forever — but A and B
continuously rebuild and dismantle each other's structure inside
that constant count.  This is a control loop with **gain ≠ 0**
that the metabolism prices as productive: m_A = 4·(L−1) − L − 1 =
+4 per epoch, same for B.

## Long-run (experiments/longrun-multilaw.6th)

| epochs | nodes | edges | status_A | status_B | wall-clock |
|---|---|---|---|---|---|
| 500 | 8 002 | **2** | stable-active | stable-active | 1.6 s |
| 2 000 | 32 002 | **2** | stable-active | stable-active | 16.4 s |

Edges hold at exactly 2 across two thousand epochs.  Node growth
tracks budget (+16 / epoch), confirming H3: bodies remain
constant emitters of fresh nodes; interference operates on edges
only.  Wall-clock scaling is the same matcher-locality quadratic
as cycle 38 — independent of the dynamics question.

## Hypotheses outcomes

- **H1 (both promote):** ✓ both `'stable-active` after standard
  pipeline.
- **H2 (one of four outcomes):** ✓ **OUT-EQ** observed.  Not
  OSC (no oscillation; perfect constancy), not STARVE (both
  alive at 2000 epochs), not SUICIDE (no extinction).
- **H3 (node growth tracks budget):** ✓ exactly +16 / epoch
  through 2000 epochs.
- **H4 (no perpetual motion):** ✓ if seeded with zero edges (no
  match), no firings occur (verified by the failure mode in the
  first attempt, where A was decomposed before WORLD-TICK began).

## Mining outcome (informational; not the question this cycle answers)

DETECT-BINDING-AUTO discovered THREE bindings:
- (`cand_001`, `'edge`) — wanted, found
- (`cand_001`, `'path2`) — A also accumulated path2 co-occurrence
  during its genesis (bi-edges form a→b→a)
- (`cand_002`, `'edge`) — B saw edges during its phase 2
  workload

The wanted pair `(cand_002, 'path2)` was **not** discovered: B's
genesis workload produces only directed singletons, so 'path2 was
never present at B's coupling-dispatches.  Per pre-reg, the demo
unbinds the mined set and hand-wires the intended bindings,
labeling the dependency clearly.  The dynamics question is
answered cleanly; the mining question (can B's intended binding
be DISCOVERED rather than wired?) requires a more sophisticated
genesis workload and is left to a future cycle if needed.

## Implementation lesson (worth its own paragraph)

The first attempt at the demo placed `NEW-EPOCH` after each
promotion phase.  This pushed `cand_001`'s momentum negative
**before** the first `WORLD-TICK` could feed it — A had only its
genesis-coupling reuse on the books and got hit with carry +
inflation = −4 per idle epoch.  By the time WORLD-TICK began, A
was already decomposed.

The fix is to perform no `NEW-EPOCH` between promotion phases
and `WORLD-TICK` startup.  The first WORLD-TICK feeds both laws
their first tick of reuse, then the first NEW-EPOCH prices the
combined activity.  Documented inline in the demo with a comment;
flagged here as a general lesson for any multi-law setup:
**metabolic clock starts when the laws start eating**.

## NEG coverage — all six

| NEG | covered by |
|---|---|
| NEG-1 budget cap | demo 196 (spot-checks: total/tick ≤ 8 every epoch) |
| NEG-2 starving law decomposes | the first failed attempt demonstrated cleanly (A decomposed when starved between phases) |
| NEG-3 regression unchanged | 2398/2398 ✓ |
| NEG-4 honest discovery report | reported above; 3 bindings found, wanted pair only partially overlaps |
| NEG-5 hand-wiring labeled | demo comments name the fallback explicitly |
| NEG-6 determinism | re-runs yield identical numbers (in-process equal-hash-code) |

## What this cycle ESTABLISHES

- Linearity of world growth was a property of the SINGLE-BODY
  configuration, not of the substrate.  Two laws with non-
  matching net-edge effects produce a flat edge count, not a
  monotone one.
- A non-trivial closure (in the cycle-37 sense: self-sustained,
  parasite-immune) can be a TWO-PARTY closure: each law alone
  would either monoclone (A) or starve (B); together they hold
  each other in place.
- The promotion gate (held-out, coupling, metabolism) accepts
  both laws.  The interference dynamics emerge from physics
  unmodified — no new scheduling, no new patterns, no new
  metabolism.

## What this cycle does NOT establish

- That the wanted binding pair can be DISCOVERED end-to-end from
  ordinary mining (current evidence: only partially — needs a
  workload that exposes `'path2` to B during coupling).
- That richer outcomes (OUT-OSC, partial OUT-STARVE) are
  reachable.  OUT-EQ was the first dynamics regime; finding the
  others requires choosing law pairs whose net-edge effects don't
  divide budget evenly.
- That the seed quantity is the equilibrium it MUST converge to,
  rather than the seed quantity it HAPPENS to start at.  This
  cycle held the seed steady; the question of basins of attraction
  is a separate observation.

## Cycle 40 directions (each needs its own pre-reg)

- **Non-symmetric body pairs**: A nets +2, B nets −1 — round-robin
  would split 8 → 4/4 firings, predicted net +4 edges / tick (not
  zero).  Does the world drift up, stabilize at a higher count,
  or get one of the asymmetric outcomes (STARVE / OSC)?
- **Three-law systems with cyclic interference**: A makes B's
  trigger, B makes C's, C makes A's.  Does the steady state
  rotate phase?
- **Discovered pair**: a genesis workload designed so that
  ordinary mining finds the wanted B binding.  This is the missing
  half of "evolved closure with interfering bodies".
- **Basins of attraction**: same construction, vary seed
  quantity (1, 5, 20, 100 edges) and observe where the system
  lands.
