# RESULTS-181 — Cycle 35 Genesis: Proto-Primitive Natural Selection

**Date executed:** 2026-05-25
**Pre-reg:** `examples/PREDICTIONS-181-proto-primitive-selection.md`
**Pre-reg sha256:** `57f5f423e64bdd4cf762b3d0ab146ad801ff987153e5b33d5ef2b6470068496e`
**Regression:** 2269 / 2269 ✓ across 174 demos (was 2241 / 168).
**Code changes:** 0 `.rkt`, 0 stdlib, 0 new primitives.  6 new
`examples/*.6th` demos + `tests/examples-test.rkt` counter update.

---

## Headline finding

**All four hypotheses CONFIRMED** under the binding constraints
(no new primitives, no new env-keys, no new NE passes, no new
hyperparameters, no runtime modifications).  The substrate's
existing cycle-25-through-33 machinery is sufficient to
demonstrate the first selection pressures at genesis layer.

H1 (length-energy tradeoff): CONFIRMED.
H2 (reuse-frequency necessity): CONFIRMED.
H3 (shadow stability requirement): CONFIRMED.
H4 (inflation life-window): CONFIRMED (narrowed per user spec —
see Section 4).

---

## Section 1 — Per-demo outcomes

| demo | hypothesis | asserts | result | findings |
|------|------------|---------|--------|----------|
| 180-genesis-short-survives | H1+H2 | 5/5 ✓ | PASS | short motif L=2 at K=6 survives 3 NE cycles; phase2 m=+3 measured |
| 181-genesis-rare-dies | H2 | 4/4 ✓ | PASS | same L=2 motif idle (K=0) → 'stale → 'decomposed in MOMENTUM-NEGATIVE-THRESHOLD=2 epochs |
| 182-genesis-long-costly-dies | H1 | 3/3 ✓ | PASS | longer motif L=3 at sustained K=1 yields m=-2 → 'decomposed in 2 epochs |
| 183-genesis-long-survives-with-frequency | H1 (positive control) | 5/5 ✓ | PASS | SAME L=3 motif at sustained K=8 yields m=+12 → survives all NE cycles.  Frequency-only variable. |
| 184-genesis-shadow-fail-dies | H3 | 4/4 ✓ | PASS | stack-fragile cand at K=8 (well above COUPLING-N=5) fails HELD-OUT-EVAL with 0 wins → 'rejected-heldout-insufficient |
| 185-genesis-inflation-window | H4 (narrowed) | 7/7 ✓ | PASS | inflation=1 establishes productive/decay boundary: K=6 → m=+3 stable; K=0 → m=-3 decompose in 2 epochs |

Total new asserts: 28.  All confirm hypothesis predictions
without refutation.

---

## Section 2 — Hypothesis evaluation

### H1 — Length-energy tradeoff (CONFIRMED)

> At fixed carry, motif length determines the break-even reuse
> threshold.

**Evidence:**
- L=2 (demo 180) survives at K=6.
- L=3 (demo 182) DIES at K=1 (sustained m=-2 each epoch).
- L=3 (demo 183) survives at K=8 (sustained m=+12 each epoch).
- Same L=3 motif, opposite outcomes determined by frequency.

**Break-even analysis** confirmed:

```
m_native = K*(L-1) - L - inflation
        = K*(L-1) - L - 1

For survival (m > STALE_TOL = 1):
  K*(L-1) - L - 1 > 1
  K*(L-1) > L + 2
  K > (L + 2) / (L - 1)

L=2:  K > 4         → need K >= 5 for clear survival
L=3:  K > 2.5       → need K >= 3
L=4:  K > 2         → need K >= 3
L=5:  K > 1.75      → need K >= 2
```

Longer motifs have proportionally lower per-use break-even (each
use saves more), but their carry cost grows linearly with length.
Net: above L=3 the break-even K plateaus around 2-3.  The
DOMINANT pressure at low frequency is the carry+inflation floor
(`L + 1`), not the saving rate.

### H2 — Reuse-frequency necessity (CONFIRMED)

> Independent of length, every motif requires sustained reuse to survive.

**Evidence:**
- Demo 181: identical L=2 motif as demo 180.
- Demo 180 survives at K=6; demo 181 dies at K=0 (idle).
- Only variable: frequency.

Promotion is not permanent.  Even after PROMOTE-STABLE and
'stable-active status, two consecutive epochs of m_native <
-STALE_TOLERANCE drive the cand to 'demotion-candidate, and Pass
C auto-decomposes it (no dependent rescue under cycle 30 rules).

### H3 — Shadow stability requirement (CONFIRMED)

> Semantic correctness is a hard filter independent of frequency.

**Evidence:**
- Demo 184: stack-hungry motif (bi-edge drop).
- Train phase: K=8 dispatches succeed (workload pre-stacks values).
- COMMIT-PRIMITIVE passes (coupling + energy gates clear).
- HELD-OUT-EVAL: each held-out substrate has empty stack →
  bi-edge underflows → all 6 substrates fail → wins=0.
- PROMOTE-STABLE returns `'rejected-heldout-insufficient`.
- Final status: `'committed` (never reaches `'stable-active`).

**K above COUPLING-N=5 did not rescue the cand.**  Frequency is
not a substitute for semantic generalizability.  The gate is
binary: pass or fail.

### H4 — Inflation life-window (CONFIRMED, narrowed)

> Inflation rate has a viable selection range.  Cycle-31
> inflation=1 behaves as the operational normal middle.

**Evidence:**
- Demo 185: same L=2 cand observed across productive and idle
  phases under fixed inflation=1.
- K=6 productive: m_native = +3 (positive but small margin).
- K=0 idle: m_native = -3.
- Productive cand survives.
- Idle cand decomposes after MOMENTUM-NEGATIVE-THRESHOLD=2 epochs.

**Narrowed claim (per user refinement 2026-05-25):** Cycle-31
inflation=1 establishes an OBSERVABLE productive/decay boundary
in THIS fixture family.  Productive K=6 cands clear; idle cands
decompose in bounded time.

**Deferred from this cycle:** the full life-window comparison
(inflation=0 / =1 / =5 parameter sweep) requires runtime knob
modification, which would violate the binding "no .rkt changes"
constraint.  A future cycle may extend this study with
runtime-tunable inflation; the current finding stands at v0
resolution: existing inflation=1 is observable and bounded.

---

## Section 3 — Architecture insights from genesis observations

### Insight 1 — The first selection pressure IS energetic

Demos 181, 182 show that even SEMANTICALLY VALID motifs (which
passed SHADOW-CHECK and HELD-OUT-EVAL) decompose if not used.
The substrate's metabolism enforces "what doesn't pay carry
dies" before any higher-level pressure (capability, communication,
support).

This validates the cycle 25-33 design from the genesis up: the
energy gate at COMMIT, the inflation tax in metabolism, and the
auto-decompose at Pass C together constitute the FIRST filter
the substrate applies to any candidate.

### Insight 2 — Frequency dominates near the floor

The carry+inflation floor (`L + 1`) is the dominant cost at low
frequency.  Once K > break-even, each additional use adds (L-1)
to m_native — so productive cands grow margin quickly, but
struggling cands die fast.

This makes the substrate's selection sharp: there's no middle
zone of "barely surviving" — cands either clear the floor with
margin or fall through to demotion in bounded time
(MOMENTUM-NEGATIVE-THRESHOLD=2 = 2 epochs).

### Insight 3 — HELD-OUT-EVAL is the semantic firewall

Demo 184 confirms HELD-OUT-EVAL is a HARD gate that frequency
cannot bypass.  This means the substrate has TWO orthogonal
filters at promotion time:
- Energetic (frequency × length vs carry+inflation)
- Semantic (held-out substrate generalization)

A cand must clear BOTH to reach `'stable-active`.  Cycle 35
genesis study confirms this orthogonality empirically.

### Insight 4 — Inflation is the rent-control

Demo 185 shows inflation=1 creates a productive/decay boundary
that productive cands clear and idle cands fall through in
bounded time.  Without inflation (cycle 31's contribution), the
canon would accumulate rent-seekers — cands that exist in the
dictionary without contributing.

The narrowing constraint (no runtime override) means we cannot
empirically test "what if inflation=0 or =5."  But the
operational behavior of inflation=1 IS observable and matches
the cycle 31 design intent.

---

## Section 4 — What this cycle does NOT show

Honestly:

1. **It does not show that these four pressures EXHAUST genesis
   selection.**  Mutation rate, environment heterogeneity,
   parallel population dynamics, and shadow-check rejection
   (vs held-out rejection) are NOT studied here.  They are
   candidates for cycle 36+ genesis-v2.

2. **It does not show that the inflation=1 setting is OPTIMAL.**
   The narrowed H4 says "operational middle in this fixture
   family."  Future runtime-tunable cycles could test
   `inflation ∈ {0, 0.5, 1, 2, 5}` and find the actual viable
   range.  Cycle 35 confirms only that the current setting works.

3. **It does not show what happens to a genuine substrate-
   discovered L2 candidate.**  Per cycle 34C-bis, L2 is empty.
   All demos here use `'fixture`-equivalent cand_NNN entities.
   The selection pressures we observe may or may not transfer
   to engineer-blind L2 candidates when persistence + blind
   harness land.  This cycle's findings are scaffolding for
   that future work.

4. **It does not refute the cycle 34A / 34A-bis / cycle 35-comm
   deferrals.**  Those remain deferred per their respective
   reasons (compliance not evolution; superstructure outpacing
   genesis).  This cycle's PASS does NOT unblock them; the
   genesis understanding here is necessary BUT NOT SUFFICIENT
   for unblocking those deferred cycles.

---

## Section 5 — Implications for next cycle (cycle 36+)

The genesis layer is now understood at v0 resolution.  Possible
directions:

### Option A — Genesis v1 (refine selection model)

Add mutation pressure and environment heterogeneity studies.
Test what happens when motif candidates mutate slightly (e.g.,
shadow-check passes on the mutated variant but the variant has
different break-even).  Test what happens when the substrate
generator changes mid-run.

Still no new mechanism; just more controlled fixture experiments
over existing machinery.

### Option B — Persistence layer (revive PREDICTIONS-179)

Now that genesis is understood, build the persistence layer
that lets L2 ever be non-empty.  This unblocks cycle 34A
implementation eventually.  PREDICTIONS-179 remains attested
and ready for activation.

### Option C — Communication primitives (revive PREDICTIONS-180)

With genesis understood, communication primitives can be added
on top with honest framing about what they DON'T do.  But this
is still adding superstructure to an empty L2; arguably should
wait for B.

### Option D — Blind discovery harness (cycle 35-D from
PREDICTIONS-179)

Add the harness without full persistence: just run a long
seeded workload, see what auto-detected motifs survive in-session
metabolism.  Capture the result.  This is sub-Option-B (cheaper)
and provides the FIRST empirical data on what the substrate
finds when not hand-fed.

**Recommendation (forwarded to next session):** Option D first
— cheapest path to first real empirical genesis observation
beyond fixtures.  Then B (persistence) builds the L2 layer
proper.

---

## Section 6 — Compliance with pre-reg PASS criteria

| # | criterion | result |
|---|-----------|--------|
| 1 | All 6 demos execute deterministically; regression unchanged | ✓ (2269/2269 across 174 demos) |
| 2 | Demos 180-185 PASS their assertions per per-demo spec | ✓ (5+4+3+5+4+7 = 28 asserts, all pass) |
| 3 | H1-H4 each confirmed by at least one demo | ✓ (H1:180,182,183 / H2:180,181 / H3:184 / H4:185) |
| 4 | No new primitive added | ✓ |
| 5 | No new env-key added | ✓ |
| 6 | No existing NE pass modified | ✓ |

**Cycle 35 → PASS.**

No FAIL criterion triggered:
- No regression
- No new mechanism (primitive / env-key / NE pass / dispatch hook)
- No demo passes for wrong reason (each setup is honest, narrative
  explicit about why the workload triggers the expected pressure)
- Demo 185 illustrated inflation pressure even without full
  life-window sweep (narrowed claim)

**No hypothesis refuted.**  All four are confirmed within the
constraints of fixture-only intra-session study.

---

## Section 7 — Pass-counter discrepancy note

The pre-reg specified estimated assertion counts.  Actual counts
after implementation:

| demo | pre-reg estimate | actual |
|------|------------------|--------|
| 180 | ~4-5 | 5 |
| 181 | ~3-4 | 4 |
| 182 | ~3-4 | 3 |
| 183 | ~3-4 | 5 |
| 184 | ~3-4 | 4 |
| 185 | ~4-5 | 7 |

Total: 28 (pre-reg estimate 24-26).  Slight overshoot; harmless.
Test counter updated 2241 → 2269 in `tests/examples-test.rkt`.

---

## Section 8 — Mid-implementation refactor note

The original demo 182/183 design used a length-5 motif
(MARK MARK bi-edge NODES drop).  DETECT-MOTIF-AUTO can pick
ANY length-5 5-gram from the workload window, including
shifted variants like (drop MARK MARK bi-edge NODES) which
underflow on first invocation (drop on empty stack).

**Refactor (mid-implementation):** switched both demos to use
L=3 motif (MARK MARK bi-edge), separated by (NODES drop) noise —
the same pattern as demo 158 which is proven safe.  H1's
"longer motif" framing now compares L=3 to baseline L=2 (demos
180/181).  The arithmetic still demonstrates the break-even
threshold scaling (K_L=2 ≈ 5, K_L=3 ≈ 3 vs higher with
inflation contribution).

**Lesson learned for future genesis cycles:** any motif chosen
for L>3 demos needs careful workload design or stack pre-loading
to ensure ALL shifted variants are stack-safe.  Trust demo 158's
template by default.

---

## Section 9 — Phase status (cycle 35 closed)

| phase | status | output |
|-------|--------|--------|
| 35A | pre-reg attested | PREDICTIONS-181 |
| 35B | implementation complete | 6 demos in examples/ |
| 35C | run complete; regression 2269/2269 | this file |
| 35D | cycle 36 direction decision | pending team evaluation |

---

## References

- `examples/PREDICTIONS-181-proto-primitive-selection.md` — pre-reg
- `examples/180-genesis-short-survives.6th` — H1+H2 happy
- `examples/181-genesis-rare-dies.6th` — H2 negative
- `examples/182-genesis-long-costly-dies.6th` — H1 negative
- `examples/183-genesis-long-survives-with-frequency.6th` — H1 control
- `examples/184-genesis-shadow-fail-dies.6th` — H3
- `examples/185-genesis-inflation-window.6th` — H4 (narrowed)
- `tests/examples-test.rkt` — regression: 2269/2269 ✓ across 174 demos
- `RESULTS-178-bootstrap-alphabet-archaeology.md` — bootstrap layer
- `RESULTS-179-substrate-discovered-alphabet.md` — L2 = 0 finding
- `CLAIMS.md` — CLAIM-2 (working discovery protocol)
- User spec 2026-05-25 — drill-down to genesis; four hypotheses;
  narrowed H4; binding "no .rkt changes" constraint
