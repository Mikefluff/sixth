# RESULTS-186 — Cycle 38: Evolved Closure (Discovered Bindings)

Pre-reg: `examples/PREDICTIONS-186-cycle38-evolved-closure.md`
Demos: 194 (16 asserts), 195 (17 asserts)
Long-run: `experiments/longrun-closure.6th` (manual, not in suite)
Regression: **2373 / 2373 ✓** across 184 demos

---

## Headline

**CLAIM-38 CONFIRMED.** The substrate discovered its own
(pattern, law) bindings from co-occurrence statistics accumulated
during ordinary life — zero hand-wiring — and the law survived
external cutoff on those discovered bindings.  The first closure
that was FOUND, not built.

And the long-run: **the evolved closure survived 500 consecutive
epochs** of world-driven metabolism (1.8 s wall-clock), growing
the world from 2 edges to 4002 while paying full canon taxes
every epoch.

Operational terms only.  "Discovery" = threshold-crossing of an
observed co-occurrence counter.  No claims of learning, intention,
cognition, or life.

## H1 — evolved closure: CONFIRMED (demo 194)

The elegant part: **the genesis pipeline itself is the discovery
data.**  The law (MARK MARK bi-edge) was coupled (5 dispatches) in
a world its own induction workload had filled with edges.  The
ecological observer counted:

```
cooccur (cand_001, 'edge)  = 5
cooccur (cand_001, 'path2) = 5    (a bidirectional pair is a→b→a)
```

DETECT-BINDING-AUTO then proposed BOTH bindings — no BIND-TRIGGER
anywhere in the demo.  After external cutoff: 3 epochs, fired=8,
m=+12, stable-active.  Idempotence (NEG-4) and reset hygiene
(NEG-5) verified.

## H2 — no spurious discovery: CONFIRMED (demo 195)

| evidence | discovered |
|---|---|
| 0 co-occurrences (pattern-free ecology) | 0 |
| 3 co-occurrences (sub-threshold) | 0 |
| 5 co-occurrences (threshold) | 2 |

The gate responds to accumulating evidence, not single events.

## H3 — selection filters dumb discovery: CONFIRMED (demo 195)

The parasite (MARK drop) earned its binding honestly (5 ecological
co-occurrences with edges present) — and then the unchanged
physics did its job: 8 stocked edges eaten in one tick, zero
rebuild, m=−3, stale, decomposed.

**Discovery is permissive; metabolism is the filter.**  This is
the Kauffman division of labor: generation can afford to be dumb
because selection is strict.  No binding-quality heuristics were
needed, and none were added.

## H4 — test-chamber exclusion: CONFIRMED (demo 195)

The parasite's promotion involved ~30 held-out dispatches inside
edge-rich test substrates.  Co-occurrence after genesis: **0**.
The suspension flag (set for HELD-OUT-EVAL's dynamic extent)
cleanly separates evaluation from ecology.  Without it, every
promoted law would trivially "discover" an 'edge binding from the
test worlds — the control would be impossible.

## Long-run probe: 500 epochs (experiments/longrun-closure.6th)

| epoch | status | nodes | edges |
|---|---|---|---|
| 0 | stable-active | 2 | 2 |
| 100 | stable-active | 1602 | 802 |
| 200 | stable-active | 3202 | 1602 |
| 300 | stable-active | 4802 | 2402 |
| 400 | stable-active | 6402 | 3202 |
| 500 | stable-active | 8002 | 4002 |

Wall-clock: **1.8 seconds** (single CPU core).  Perfectly linear
growth (+16 nodes, +8 edges per epoch — budget-limited steady-state
metabolism).  The law survived every one of 500 epochs on
discovered bindings, paying carry + inflation each time.

## Scaling series (experiments/longrun-scaling.6th, measured)

| epochs | nodes | edges | wall-clock | ratio vs prev |
|---|---|---|---|---|
| 500 | 8 002 | 4 002 | 1.6 s | — |
| 1 000 | 16 002 | 8 002 | 3.9 s | ×2.5 |
| 2 000 | 32 002 | 16 002 | 14.3 s | ×3.6 |
| 4 000 | 64 002 | 32 002 | 50.5 s | ×3.5 |
| 10 000 | 160 002 | 80 002 | 321.4 s | (quadratic fit: predicted 315 s) |

Survival: `'stable-active` at every horizon.  World growth exactly
linear (+16 nodes, +8 edges per epoch).  Wall-clock approaches ×4
per doubling — **quadratic, as predicted by matcher locality
drift**: `find-edge` scans from node id 1 on every match, but
consumption eats the lowest edges while production creates the
highest, so the dead-prefix of empty nodes grows linearly and the
scan re-walks it every firing.  Cost ≈ O(age of world) per match.

Consequences:
- 10K epochs measured at 5.4 min, `'stable-active`, 160 002 nodes /
  80 002 edges — the quadratic fit predicted 315 s vs measured
  321 s (2% error).  The cost model is confirmed, not conjectured.
- ~100K epochs ≈ hours — requires a matcher frontier cursor.
  That optimization CHANGES the observable match order in the
  general case (a rule may re-edge a low node), i.e. it is physics
  semantics, not just engineering — so it needs its own pre-reg
  (cycle 39 candidate).
- GPU/Metal is NOT the answer to this bottleneck: the scan is a
  sequential pointer chase, not parallel arithmetic.  Metal/MPS
  remains relevant only for massively parallel independent worlds
  (better served first by Racket places across CPU cores) or the
  libtorch bridge demos (torch MPS backend, already available).

## Limitation: monoclone replication (post-publication note)

The scaling series above shows EXACTLY +16 nodes / +8 edges per
epoch over four orders of magnitude.  This is suspicious, and it
is suspicious for a reason: the long-run is NOT a rich evolution,
it is a counter incrementing in disguise.

Mechanism (verified by tracing the demo):

1. Two bindings were discovered: `(cand_001, 'edge)` and
   `(cand_001, 'path2)`, in that order (the order discovery
   registered them).
2. WORLD-TICK iterates bindings in order; each binding fires
   repeatedly while its pattern matches and the per-tick budget
   has not been spent.
3. The first binding therefore consumes the ENTIRE budget=8 every
   tick.  The second binding never fires — not once, across 10K
   epochs.
4. The active law's body, `MARK MARK bi-edge`, monotonically adds
   two fresh nodes and one bi-edge pair per firing; consumption
   removes one edge.  Net: +2 nodes, +1 edge per firing.  Times 8
   firings/tick: exactly +16 nodes, +8 edges.  Period.

What cycle 38 demonstrated, accurately rephrased:

- A binding can be DISCOVERED.  Yes.
- A discovered binding can sustain a law's metabolism after
  external cutoff.  Yes.
- The discovered closure represents rich emergent behavior.  **No.**
  It is a stable replication of one pattern by one law forever.
  Monoclonal.

This does not invalidate the closure claim — survival on
discovered bindings is a real machine-verifiable property — but
it bounds it.  The headline "first closure that was FOUND, not
built" stands.  The implied step toward rich evolution does not.

Two distinct mechanisms collaborate to produce the monoclone:
greedy budget allocation in WORLD-TICK (one binding eats the
ration), and a homogeneous law body that creates fresh structure
disjoint from existing structure (firings never interfere).  The
first is an engineering choice masquerading as physics; the
second is a property of the specific law that promoted, not of
the substrate.

Disentangled in PREDICTIONS-187 / RESULTS-187 (round-robin probe,
cycle 39A): if greedy is the cause, round-robin breaks linearity;
if the law's body is the cause, round-robin only changes the
ratio.  The probe distinguishes.

---

## NEG coverage — all 7

| NEG | covered by |
|---|---|
| NEG-1 no correlation, no binding | demo 195 (cooccur 0 → 0) |
| NEG-2 threshold honest | demo 195 (3 → 0; 5 → discovery) |
| NEG-3 status gate | by construction (DETECT-BINDING-AUTO filters non-stable-active) + demo 195 H3 (decomposed law's bindings inert) |
| NEG-4 idempotence | demo 194 (second call → 0) |
| NEG-5 reset hygiene | demo 194 (_binding-cooccur + triggers cleared; new axis) |
| NEG-6 test-chamber exclusion | demo 195 (heldout dispatches → 0 counts) |
| NEG-7 canon preservation | regression 2373/2373 ✓ |

## Cycle 38 status — CLOSED

| item | status |
|---|---|
| PREDICTIONS-186 pre-reg | attested before source |
| Ecological observer (runtime.rkt hook) | ✓ |
| Test-chamber suspension (tier1.rkt) | ✓ |
| DETECT-BINDING-AUTO / BINDING-COOCCUR (triggers.rkt) | ✓ |
| H1 evolved closure | ✓ confirmed |
| H2 no spurious discovery | ✓ confirmed |
| H3 selection filters discovery | ✓ confirmed |
| H4 test-chamber exclusion | ✓ confirmed |
| 500-epoch long-run survival | ✓ |
| Regression | 2373/2373 ✓ |

## The chain so far

различие → отбор → наличие → **найденное наличие**:

- Cycle 35-36R: fixed physics selects productive laws.
- Cycle 37: a law bound to a world pattern exists by itself
  (closure), and parasites starve (non-trivial).
- Cycle 38: the binding itself emerges from the system's history.
  Nobody told the law what feeds it; it was dispatched in a world
  it had filled with edges, the coincidence was counted, the
  threshold crossed, the loop closed — and held for 500 epochs.

## Cycle 39 directions (informational, each needs its own pre-reg)

1. **Multi-law ecosystems:** two laws whose discovered bindings
   cross-feed (one's output is the other's trigger) — mutualism,
   competition for the tick budget, niche formation.
2. **Binding metabolism:** bindings that stop firing for N epochs
   accrue their own decay (currently inert bindings persist
   harmlessly; an economy of bindings would prune them).
3. **Longer-horizon long-runs:** 10K-100K epochs, watching for
   late-emerging dynamics (matcher locality drift, momentum
   oscillations) — cheap on CPU per the performance note.
4. **Pattern vocabulary growth:** mined patterns (the world-side
   analog of DETECT-MOTIF-AUTO) — the natural next rung after
   mined laws and mined bindings.