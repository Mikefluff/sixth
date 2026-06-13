# PREDICTIONS-188 — Cycle 39B: Multi-Law Ecosystem (Interfering Bodies)

**Date pre-registered:** 2026-06-13
**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Cycle context

Cycle 39A (RESULTS-187) localized the cycle 38 monoclone: the
single law's body `MARK MARK bi-edge` reads nothing from the
world, so every firing acts on a fresh disjoint region — no
firing can interfere with another, and any scheduler reproduces a
straight line.

The probe pointed the next move at INTERFERENCE.  Cycle 39B
attempts the smallest construction where interference can occur:
two distinct promoted laws whose firings touch the same edges.

Honesty up front: this cycle does NOT modify physics.  It tests
whether the existing cycle 25-39A machinery, given two laws
instead of one, produces dynamics qualitatively different from
the monoclone — and if so, of which kind.

## Core claim (machine-verifiable; no agency claims)

> CLAIM-39B: There exists a pair of canon-promoted laws (A, B)
> with discovered bindings (via cycle 38 mining) such that under
> the unchanged round-robin physics the world's EDGE COUNT does
> not grow linearly with epoch — it either oscillates, finds a
> non-monotone equilibrium, or one law starves the other.  The
> NODE count may continue to grow linearly (it tracks the budget,
> not the bodies' net edge balance).

The four possible outcomes (each is a finding):

- **OUT-OSC** edges oscillate within bounded range; both laws
  alternately have/lose matches; ecosystem persists indefinitely.
- **OUT-EQ** edges converge to a non-zero equilibrium count;
  both laws fire at compensating rates.
- **OUT-STARVE** one law drains the world's pattern supply
  faster than the other rebuilds it; the loser decays to
  `'decomposed` while the winner reverts to monoclone behavior.
- **OUT-SUICIDE** both laws collapse the pattern supply together;
  ecosystem extinct within a few epochs.

Linearity = monoclone, when exposed to interference, must break
into one of OUT-OSC / OUT-EQ / OUT-STARVE / OUT-SUICIDE.
"Same +8 edges per epoch as before, just two laws doing it" is
NOT among the possible findings.  If observed it is a bug.

## Construction (binding spec)

Two laws, both promoted through the standard canon pipeline:

| law | body | L | per-firing substrate effect |
|---|---|---|---|
| A (emitter) | `MARK MARK bi-edge` | 3 | +2 nodes, +2 edges (one bi-pair) |
| B (consumer-emitter) | `MARK MARK EDGE+` | 3 | +2 nodes, +1 edge (one directed) |

Bindings:

- A bound to `'edge` (consume 1 edge → net +1 edge per firing)
- B bound to `'path2` (consume 2 edges → net **−1** edge per firing)

The interference: A nets +1 edge, B nets −1 edge.  Round-robin
budget=8 splits 4/4 → net edges per tick = 0 IF both fire 4 times.
The world's edge count therefore depends on which patterns are
present each round, which depends on what the LAST tick's
firings did to the world.  The control loop has gain ≠ 0.

For discovery: A's coupling-dispatches occur in a world its own
workload filled with edges; B's coupling-dispatches occur after a
substrate-RESET + fresh workload that creates bi-edges (because
its body `MARK MARK EDGE+` alone produces only directed singletons
which lack `'path2` — to discover the `'path2` binding B must be
dispatched while the world DOES contain `'path2` matches; the
demo arranges this by inducing B after the genesis of A leaves
bi-edges in place).

If standard mining fails to promote BOTH laws from a single demo
flow (likely: DETECT-MOTIF-AUTO returns one motif per call), the
demo PHASE 1 and PHASE 2 each runs its own induce-couple-commit-
promote sequence sequentially.  This is not new physics — it is
the same pipeline running twice.  Documented as fallback path.

If discovered bindings turn out NOT to be the (A,'edge) +
(B,'path2) we want — because mining could legitimately also
discover other co-occurring patterns — the demo will:

1. Report what was actually discovered (the finding).
2. If the wanted pair was NOT discovered, fall back to a SECOND
   sub-demo where the bindings are hand-wired with `BIND-TRIGGER`
   (cycle 37 mechanic, unchanged).  This sub-demo answers the
   "interference dynamics" question independently of the
   "can mining find this pair?" question.

## Hypotheses

- **H1 (both promote):** the sequential genesis (A then B)
  produces two `'stable-active` cands.  If H1 fails, the demo
  documents WHY (which gate rejected) and continues with
  hand-wired bindings for the dynamics observation.

- **H2 (one of four outcomes observed):** the post-cutoff
  multi-law system exhibits one of OUT-OSC / OUT-EQ / OUT-STARVE
  / OUT-SUICIDE.  The demo reports which.

- **H3 (node growth still tracks budget):** while edges may do
  anything, the node count grows by `2 × fired-per-tick` ≤ 16
  per epoch, because both bodies emit 2 fresh nodes per firing.
  Node growth is NOT interesting; it is the constant emitter
  signature of any non-state-reading body.

- **H4 (no perpetual motion):** if edges go to zero and stay,
  both laws starve (NEG-equivalent to cycle 37 H2).  The
  metabolism still bites at the law level even when interference
  is present at the world level.

## NEG (binding)

- **NEG-1:** total firings per tick ≤ budget=8 (round-robin cap
  unchanged).
- **NEG-2:** any law that starves decays to `'decomposed` under
  unchanged metabolism (cycle 25-33 mechanics intact).
- **NEG-3:** regression 2373 ✓ unchanged.
- **NEG-4:** if discovery does NOT find (A,'edge)+(B,'path2),
  this is reported, not papered over.
- **NEG-5:** the hand-wired fallback sub-demo (if used) explicitly
  invokes `BIND-TRIGGER` and is so labeled.
- **NEG-6:** identical seed and runtime → identical numbers
  across re-runs (in-process determinism, as before).

## What this cycle is NOT

- Not a third law or larger ecosystem (two-body interference
  first; richer systems are downstream).
- Not modification of round-robin scheduling, of budget=8, of
  pattern vocabulary, or of metabolism constants.
- Not pattern mining (vocabulary stays v0).
- Not a claim of richness or ecology in the biological sense.
  "Interference" here means "non-disjoint world effects between
  two laws' firings" — operational only.

## Implementation contract

1. `examples/196-multilaw-ecosystem.6th`: sequential genesis of
   A and B; observe what was discovered; if needed, fall back
   to hand-wired bindings; run 8 post-cutoff epochs reporting
   per-epoch (fired-A, fired-B, edges, nodes, status-A, status-B);
   classify outcome.
2. `experiments/longrun-multilaw.6th`: same flow but 500 epochs,
   reports edge count at 100/200/300/400/500 epochs.  Manual,
   not in regression suite.
3. RESULTS-188 records which outcome occurred and the
   implications for cycle 40+.

## PASS / FAIL

PASS: H3 confirmed (nodes track budget); H4 confirmed (no
perpetual motion); the demo classifies the outcome unambiguously
as one of OUT-OSC/EQ/STARVE/SUICIDE; NEG-1..6 observed; regression
green.

FAIL: edges grow strictly linearly (the cycle 38 monoclone
pattern survived interference — would mean the construction
does not actually produce interference and the cycle is invalid
in its current form); or NEG-3 broken; or H4 violated
(perpetual-motion configuration).

## References

- PREDICTIONS-185 / RESULTS-185 — cycle 37 closure
- PREDICTIONS-186 / RESULTS-186 — cycle 38 evolved closure +
  monoclone limitation
- PREDICTIONS-187 / RESULTS-187 — cycle 39A localization of
  the monoclone to homogeneous-body, not greedy-budget
