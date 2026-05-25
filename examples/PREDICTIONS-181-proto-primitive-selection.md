# PREDICTIONS-181 — Proto-Primitive Natural Selection (cycle 35, retitled #2)

**Date pre-registered:** 2026-05-25

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
Initial attestation: see ledger row dated 2026-05-25.

---

## Cycle context — two deferrals, one drill-down

The original cycle 35 (PREDICTIONS-179, persistence layer + source-
tag firewall) was deferred (compliance, not evolution).  The
replacement cycle 35 (PREDICTIONS-180, deficit-driven composite
communication) was also deferred (vocabulary inflating faster than
understanding of primary selection).

This pre-reg drills back to genesis:

> Before law.  Before capability.  Before request.  Before support.
> Before stable.  Before communication.

Bare question:

> Given a minimal self-modifying runtime with induction, energy
> gate, carry, inflation, and decomposition, **what pattern
> survives first?**  Under what energetic conditions does the
> very first stable primitive emerge from a noisy stream of
> operations?

This is **science**, not engineering.  We add no new primitives.
We use existing cycle-25-through-33 machinery and study how it
behaves at the earliest selection layer.

---

## CORE CLAIM (binding)

> Given a minimal self-modifying runtime with induction
> (`DETECT-MOTIF-AUTO`, `INDUCE-RUNTIME`), an energy gate
> (`net_delta_e < 0` at `COMMIT-PRIMITIVE`), carry costs,
> inflation tax (cycle 31), and decomposition (cycle 29's
> metabolism gate plus cycle 30's auto-decompose):
>
> **Proto-primitives survive only when repeated use repays
> their law cost before decay.  The first selection pressure
> is energetic, not semantic.**

Semantic correctness (`SHADOW-CHECK`) is a NECESSARY but not
SUFFICIENT filter.  Many semantically valid motifs die before
becoming stable because they don't pay their carry under the
local repetition regime.

---

## What this cycle is NOT (binding)

- **Not new mechanism.**  No new primitives.  No new env-keys.
  No new NE passes.  No new dispatch hooks.
- **Not new ontology.**  No new alphabet, grammar, diagnostics,
  or implementation entries (per cycle 34B archaeology rule).
- **Not engineering.**  This is a scientific study of existing
  machinery's selection behavior.
- **Not a discovery claim.**  L2 remains empty (per cycle
  34C-bis); demos use `'fixture`-tagged INDUCE so the runtime
  context is honest.  We are NOT claiming to discover anything.
- **Not communication-enabled.**  Cycle 35-comm primitives
  (DECLARE-CAPABILITY, EMIT-REQUEST, etc.) are NOT present
  in this cycle.  Communication remains deferred.
- **Not persistence-enabled.**  `stdlib/promoted/` still does
  not exist.  Cands die at session end.  This cycle studies
  intra-session selection only.

---

## CORE INVARIANTS (binding, three)

1. **No new primitive introduced.**  Demos use existing
   `DETECT-MOTIF-AUTO`, `SHADOW-CHECK`, `INDUCE-RUNTIME`,
   `COMMIT-PRIMITIVE`, `HELD-OUT-EVAL`, `PROMOTE-STABLE`,
   `NEW-EPOCH`, `MOMENTUM-NATIVE`, `LAW-MOMENTUM`,
   `CAND-STATUS`, `LEDGER-LAST`.

2. **All cands are `'fixture`-tagged.**  This cycle is intra-
   session science.  No cand persists across runs.  (Tag
   semantics formally arrive with the deferred persistence
   cycle; until then, ALL cands are de-facto fixtures.)

3. **Hypothesis-driven, not feature-driven.**  Each demo tests
   a specific hypothesis about selection pressure.  Pass =
   hypothesis confirmed.  Failure of a demo refutes a
   hypothesis — also a valid scientific result, but means
   our model of genesis is incomplete and needs revision
   before any feature work resumes.

---

## Four binding hypotheses

### H1 — Length-energy tradeoff

> At fixed carry, motif length determines the **break-even
> reuse threshold**: longer motifs save more per use but cost
> more to maintain (carry is proportional to motif length plus
> a fixed per-cand inflation tax).  Selection therefore favors
> motifs whose length matches the available repetition rate.

Predicted observations:
- A length-3 motif with K=5 reuses survives.
- A length-5 motif with K=5 reuses dies (carry > total saved ops).
- A length-5 motif with K=10 reuses survives (now carry repaid).

### H2 — Reuse-frequency necessity

> Independent of length, every motif requires a minimum reuse
> count per metabolism cycle to survive.  Rare motifs decay
> regardless of semantic validity.

Predicted observation:
- A semantically valid motif INDUCEd once and never repeated
  decays to `'stale` then `'demotion-candidate` then
  `'decomposed` within MOMENTUM-NEGATIVE-THRESHOLD epochs.

### H3 — Shadow stability requirement

> Semantic correctness is a hard filter.  Even a frequent motif
> with high reuse fails to PROMOTE-STABLE if its behavior
> doesn't match equivalent expansion.  The energy gate alone is
> insufficient.

Predicted observation:
- A motif that consistently fails `SHADOW-CHECK` is rejected
  at INDUCE-RUNTIME regardless of frequency.

### H4 — Inflation life-window

> Inflation rate has a **viable selection range**.
> Too low (=0): even unproductive primitives accumulate
> indefinitely; the canon fattens with rent-seekers.
> Too high (>>1): even productive primitives can't repay carry
> in time; no primitive survives.
> Normal (=1 per cand per epoch, cycle 31): productive
> primitives survive; unproductive ones decay in bounded time.

Predicted observation:
- Same motif under inflation = 0: survives indefinitely even
  when reuse drops, eventually becomes infrastructure-bloat.
- Same motif under normal inflation = 1: survives when
  productive, decays when productive drops.
- Same motif under inflation = 5: dies even when normally
  productive (carry repayment window too tight).

---

## Six demos (binding)

### Demo 180 — genesis-short-survives (H1 + H2)

Setup: blind-ish workload generator emits `MARK drop` 6 times
within window K=20.  No prior cand.

Expected:
- `DETECT-MOTIF-AUTO` finds `(MARK drop)`, length 2.
- `SHADOW-CHECK` passes.
- `INDUCE-RUNTIME` creates cand_001.
- COMMIT-PRIMITIVE passes (5 uses, 3 sessions, delta_e < 0).
- After multiple NE cycles with continued workload, cand_001
  remains `'stable-active`.

Pass: cand_001 ends in `'stable-active` after N=3 NE cycles
with continued reuse.

### Demo 181 — genesis-rare-dies (H2)

Setup: workload emits `MARK drop` 6 times (induces cand_001),
then idle for 3 NE cycles.

Expected:
- cand_001 INDUCEd as in 180.
- Without continued reuse, momentum drops.
- After 1 idle NE: `'stale`.
- After 2 idle NEs: history `(-3 -3)` → `'demotion-candidate`.
- After Pass C: no active dependents → `'decomposed`.

Pass: cand_001 ends `'decomposed` after 3 idle NE cycles.

### Demo 182 — genesis-long-costly-dies (H1)

Setup: workload that contains a length-5 motif repeated K=3 times
in the window.  Workload also has noise so the motif barely meets
COUPLING-N=5 threshold (achieved over multiple sessions).

Expected:
- DETECT finds length-5 motif.
- INDUCE creates cand_001.
- COMMIT may pass marginally.
- carry = 5 (length proportional); cycle 31 inflation = 1.
- m_native per epoch = K×4 - 5 - inflation = 3×4 - 5 - 1 = +6
  while running productively, but K drops to 1 after the seeded
  workload: m_native = 1×4 - 5 - 1 = -2.
- After 2 idle epochs of m_native = -3 (no use, just carry+inflation):
  `'demotion-candidate` → `'decomposed`.

Pass: cand_001 ends `'decomposed` after the seeded burst exhausts.

### Demo 183 — genesis-long-survives-with-frequency (H1)

Setup: same length-5 motif as 182 but the workload continues
emitting it at K=8 per epoch indefinitely.

Expected:
- m_native per epoch = 8×4 - 5 - 1 = +26.  Comfortably positive.
- cand_001 stays `'stable-active` across N=3 NE cycles.

Pass: cand_001 ends `'stable-active` after N=3 NE cycles with
continued K=8 reuse.

### Demo 184 — genesis-shadow-fail-dies (H3)

Setup: workload that LOOKS like it has a recurring motif (e.g.,
`MARK drop` 6 times) but the motif is actually contextual —
running the motif in isolation produces a different world_delta
than running it inline.

Concretely: use a workload where the motif `(NODES drop)` is
emitted in a context with marked nodes; the motif in isolation
on a fresh substrate behaves differently because NODES iterates
all nodes.  This is a SHADOW-CHECK fail because expansion
context differs from inline context.

Expected:
- DETECT finds the motif.
- SHADOW-CHECK FAILS (world_delta mismatch).
- INDUCE-RUNTIME REJECTS the candidate (cycle 25 spec — INDUCE
  requires preceding SHADOW pass).
- No cand_NNN created.
- LEDGER records `'shadow-fail` event.

Pass: no cand_NNN created; LEDGER contains shadow-fail event.

### Demo 185 — genesis-inflation-window (H4)

Setup: three sub-runs (or one run with three parameter sweeps if
the implementation makes inflation per-call tunable; otherwise
three sequential demos 185a/b/c sharing setup):

(a) inflation = 0 (synthetic; would require local override since
    cycle 31 fixed it to 1).
(b) inflation = 1 (normal — what the system actually uses).
(c) inflation = 5 (synthetic high).

For each sub-run: same length-3 motif, same K=4 reuse rate for
3 epochs, then K=0 for 3 epochs.

Expected:
- (a) inflation=0: m_native = K×2 - 2 - 0 - 0 = +6 productive,
  -2 idle.  Decays slowly but eventually decomposes after long
  idle (MOMENTUM-NEGATIVE-THRESHOLD epochs of m<-STALE_TOL).
  Without inflation, the cand persists longer than with normal
  inflation — visible in epoch-count-to-decompose.
- (b) inflation=1: m_native = K×2 - 2 - 0 - 1 = +5 productive,
  -3 idle.  Decomposes in standard 2 idle epochs.
- (c) inflation=5: m_native = K×2 - 2 - 0 - 5 = +1 productive,
  -7 idle.  Productive m is barely positive; idle m is very
  negative.  Decomposes essentially immediately on first idle
  epoch (already at demotion threshold).

Pass:
- (a) survives longer than (b) under idle conditions (rent-seeking
  visible).
- (c) decomposes faster than (b) under idle conditions
  (over-pressure visible).
- (b) is the operationally normal middle.

NB: if implementing inflation override is too invasive, (a) and
(c) can be approximated by adjusting carry temporarily, or
demo 185 can be reduced to comparing (b) against a single
alternative.  The PASS criterion adapts: as long as the
INFLATION-WINDOW concept is empirically illustrated by at least
one comparison, H4 is confirmed.

---

## Pass / fail criteria (binding)

### PASS (all required)

1. All 6 demos execute deterministically (existing cycle 25-33
   regression unchanged: 2241 / 2241 ✓ before and after).
2. Demos 180-185 PASS their assertions per the per-demo spec.
3. The four hypotheses H1-H4 are each confirmed by at least one
   demo.
4. No new primitive is added.
5. No new env-key is added.
6. No existing NE pass is modified.

### FAIL (any one triggers)

1. Any cycle 25-33 demo regresses.
2. A new mechanism (primitive, env-key, NE pass, dispatch hook)
   sneaks in.  This cycle must remain pure science using existing
   machinery.
3. A hypothesis demo passes its assertion but for the WRONG
   reason — e.g., demo 180 passes because the workload's
   structure is so contrived that selection isn't being tested.
   (This is checked by human review of demo workload during
   commit.)
4. Demo 185 cannot illustrate the inflation window even with
   careful setup, suggesting our parametric model of selection
   is incomplete.

### VALID NEGATIVE RESULT

If a demo's hypothesis is REFUTED by the actual mechanism —
e.g., H4 turns out to be wrong because cycle-31 inflation
doesn't behave like a life-window — that is a SCIENTIFIC FINDING,
not a failure of the cycle.  It must be recorded in
`RESULTS-181-cycle35-genesis.md` and the cycle's understanding
of the substrate updated.  A refuted hypothesis with honest
documentation is a PASS for the cycle (we learned something).

---

## Optional inspection helpers (NOT primitives)

If diagnostics require additional reporting, implement them in
`stdlib/genesis-report.6th` using existing inspection primitives:

```
\ stdlib/genesis-report.6th — NOT new primitive; pure Sixth
\ composition over MOMENTUM-NATIVE / CAND-STATUS / LEDGER-LAST

: report-cand-state ( cand -- )
    dup CAND-STATUS . space
    dup MOMENTUM-NATIVE . space
    cr ;

: report-population ( -- )
    \ Iterate ACTIVE-METAB-STATUSES, report each cand.
    ... ;
```

This keeps the alphabet untouched while making demos readable.

---

## Methodological commitments (binding)

1. Implementation = 6 demos in `examples/`.  No `.rkt` changes.
2. Demos use existing primitives only.  No new dispatch entries.
3. If a demo's setup requires inflation override, the override
   is done via local parameter binding in the demo (test-only,
   not core mechanism change).  Demo 185 specifically may
   require this; the override is documented in the demo header.
4. Each demo's setup workload is honest — not contrived to make
   the hypothesis trivially pass.  Workload notes are required
   in demo file header.
5. Pass conditions are partition: each demo's hypothesis is
   either confirmed (pass) or refuted (valid negative result).
6. Per cycle 34B archaeology: nothing in this cycle is claimed
   as primitive.  If `stdlib/genesis-report.6th` is added, it
   is Sixth-stdlib composition, NOT new alphabet.
7. Per cycle 34C-bis: cand_NNN in these demos are explicitly
   fixture-equivalent.  No L2 occupancy claim.
8. Attestation BEFORE source code (`.6th`).

---

## What cycle 35-genesis does NOT claim

- That these four hypotheses exhaust the selection pressures.
  There are likely more (mutation rate, environment heterogeneity,
  parallel population effects); they are out of scope here.
- That the demos prove anything about real-world primitive
  discovery.  They show how the substrate's selection mechanism
  behaves under controlled toy workloads.
- That genesis can be reduced to these four pressures.  This is
  v0 of a genesis study; refinements will come.
- That this cycle resolves the L2-empty finding from cycle
  34C-bis.  L2 remains empty until persistence + blind harness
  cycles land.
- That communication or external energy are no longer needed.
  Both remain deferred.  Cycle 35-genesis is about whether they
  even should be built on the existing substrate, or whether the
  substrate's selection layer needs revision first.

It claims only:

1. **Four selection pressures (length, frequency, stability,
   inflation) are testable on the existing substrate.**
2. **Existing mechanisms (cycles 25-33) suffice to study them**
   without new features.
3. **The first selection pressure is energetic** — repetition
   must repay carry cost before decay; everything else (capability,
   communication, support) is downstream of this filter.

If demos 180-185 all PASS with hypotheses confirmed AND
existing 168+ demos still pass unchanged, **the substrate's
genesis layer is understood at v0 resolution**, and we have
honest grounds to decide what cycle 36+ should be.

If any hypothesis is REFUTED by an honest valid-negative result,
that's the most important finding — we don't yet understand
genesis, and adding more superstructure would be malpractice.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25-33 frozen; user spec 2026-05-25
      (back to genesis; no new primitives; study existing
      machinery; four selection pressures)
- [x] Rule 3: deterministic — demo workloads are seeded,
      reproducible
- [x] Rule 4: pass/fail partition outcome space across 6 demos
- [x] Rule 5: real intra-session selection runs
- [x] Rule 6: results file `RESULTS-181-cycle35-genesis.md` will
      record outcomes and any refuted hypotheses
- [x] Rule 7: demos 181, 182, 184 are negative-control variants
      (rare dies / long costly dies / shadow-fail dies)
- [x] Rule 8: scope = 6 demos, 0 new primitives, 0 new env-keys,
      0 new NE passes, 0 new hyperparameters, 0 alphabet additions
- [x] Rule 9: attestation pending

---

## Phase breakdown (intended)

- **35A (this pre-reg):** hypothesis-driven method + 6 demos
  specified.  No code.
- **35B:** write the 6 demo files using existing primitives only.
  Optional `stdlib/genesis-report.6th` as composition helper.
  Update `tests/examples-test.rkt` expected pass count.
- **35C:** run.  Record outcomes in
  `RESULTS-181-cycle35-genesis.md`, including any refuted
  hypotheses with diagnostic detail.
- **35D:** if all confirmed → cycle closes; team decides cycle
  36+ direction with genesis-layer understanding.  If any
  refuted → cycle closes with documented "we don't understand
  X" finding; cycle 36 must address the gap before any
  superstructure work resumes.

---

## References

- METHODOLOGY.md v2.1 §17
- `examples/PREDICTIONS-179-persistence-layer.md` — DEFERRED
  (compliance, awaits durable L2)
- `examples/PREDICTIONS-180-deficit-communication.md` — DEFERRED
  (superstructure, awaits genesis understanding)
- `RESULTS-179-substrate-discovered-alphabet.md` — L2 = 0 finding
  (motivates this drill-down)
- `CLAIMS.md` — CLAIM-2 (working discovery pipeline) and
  CLAIM-3 (no durable discoveries yet)
- `docs/META-SEMANTICS.md` §6 (Tier 1 ephemeral lifecycle —
  the machinery we study here), §18 (no-new-primitive rule
  this cycle respects)
- `sixth/meta/tier1.rkt` — compute-momentum-for,
  MOMENTUM-STALE-TOLERANCE, INFLATION-COST-PER-CAND
- User spec 2026-05-25 — "before composite communication,
  metabolism; before composite metabolism, selection of proto-
  primitives; the first selection pressure is energetic"
