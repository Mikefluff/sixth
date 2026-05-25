# PREDICTIONS-182 — Selection Law Discovery Scaffold (cycle 36A)

**Date pre-registered:** 2026-05-25

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
Initial attestation: see ledger row dated 2026-05-25.

---

## Cycle context — the meta-selection question

Cycle 35 (genesis) studied L1 selection: GIVEN fixed selection
laws (carry, inflation=1, energy gate, coupling N=5/M=3, held-out
≥4/6, stale-tolerance=1, momentum-negative-threshold=2), which
primitives survive?

But if Sixth claims to be a system of LAW-STATE EVOLUTION, the
selection laws themselves cannot remain eternal external gods.
They are also bootstrap — chosen by the engineer at cycle 25-31,
plausible but not derived.

Two levels:

- **L1 laws (primitives):** entities that change `world_state`.
- **L2 selection laws:** rules governing how L1 primitives are
  born, live, age, decay, and are decomposed.

Cycle 35 confirmed L1 selection works under the L2 canon.  But:

- Why inflation = 1?
- Why N = 5?
- Why M = 3?
- Why `support_credit ≤ LAW_CARRY`?
- Why `wins ≥ 4 / 6`?
- Why this momentum formula?

These are not final truths.  They are bootstrap selection laws,
plausible but not derived.

---

## The recursive-corruption danger

A system that lets a selection-law candidate REWRITE THE TEST
RULES during its own test would just legalize self-deception:

> A bad selector decides which selector is "good".

This is a recursive corruption failure mode.  The user spec
2026-05-25 names the safeguard:

> **Selection laws must themselves be selected, but under a
> higher-order protocol that they cannot edit during the test.**

The metaphor: the judge cannot be rewritten during the trial.

This cycle (36) does NOT promote any selector candidate.  It
builds the SCAFFOLD where selector candidates can later compete
under a frozen meta-protocol.

---

## CORE QUESTION (binding)

> Can the substrate's selection laws (currently hard-coded
> hyperparameters in `runtime.rkt`) be:
>
> 1. parameterized as a `SelectionProfile` data structure,
> 2. run such that the existing canon profile produces
>    bit-identical results to current cycles 25-33,
> 3. compared against alternative profiles in a SANDBOX
>    that cannot affect the canon,
> 4. evaluated by a frozen meta-protocol on blind workloads,
>
> WITHOUT ever promoting a non-canon selector and WITHOUT
> allowing any selector candidate to modify the meta-protocol
> or canon during the test?

---

## CORE INVARIANTS (binding, five rules)

### 1. Constitution/Sandbox/Amendment hierarchy

```
CONSTITUTION   — current cycle 25-33 hyperparameter set.
                 NEVER modified by any selector candidate.
                 Existing demos use this; results frozen.

SANDBOX        — selector candidate profiles.
                 Run in isolation.  Results do not propagate
                 to CONSTITUTION.  Have no read-write access
                 to canon law-state outside their sandbox.

AMENDMENT      — promotion of a sandbox profile to CONSTITUTION.
                 OUT OF SCOPE for cycle 36.  Reserved for
                 future cycle (37+) under separate pre-reg with
                 multi-criterion evidence gate.
```

This is the "current selection law = constitution; candidate
selection law = sandbox experiment; promoted selector =
constitutional amendment after blind evidence" structure from
user spec 2026-05-25.

### 2. Meta-protocol freeze

```
The meta-protocol M (workload generators, metric definitions,
sandbox isolation rules, evaluation criteria) is FIXED at the
start of every selector comparison test.

No selector candidate S can:
  - modify M
  - modify the workload W mid-run
  - modify any canon hyperparameter
  - modify the metric computation
  - affect any other selector's run

S can only PROCESS the workload W under its own profile's
parameters and produce metrics M(S, W).
```

This prevents recursive corruption.  The judge cannot be
rewritten during the trial.

### 3. Baseline reproduces canon bit-for-bit

```
SelectionProfile_A = the canon hyperparameter set.
Running existing cycle 25-33 demos through SelectionProfile_A
MUST produce identical CAND-STATUS, MOMENTUM-NATIVE,
ledger events, law_hash trajectories.

If parameterization breaks any existing demo, the
parameterization is wrong, not the demo.
```

Regression invariant: 2269 / 2269 ✓ across 174 demos before
and after parameterization.

### 4. No alphabet additions

```
Per cycle 34B archaeology rule: cycle 36 adds NO new alphabet-
tier primitive.  The SelectionProfile struct and harness are
L1 grammar verbs over L4 implementation-detail values.  No
ontological-primitivity claim.
```

### 5. No selector promotion in cycle 36

```
Cycle 36 runs the SCAFFOLD.  It runs each profile and reports
metrics.  It does NOT decide that any profile is "better".  It
does NOT modify CONSTITUTION.

A selector that produces "better-looking" metrics in cycle 36
remains in SANDBOX.  Promotion (AMENDMENT) requires:

  - Multiple blind workloads (≥N held-out environments)
  - Improvement on ≥M dimensions vs baseline
  - No regression on negative controls
  - Pre-registered comparison criteria

These are reserved for cycle 37+.  Cycle 36 only enables the
question to be asked.
```

### 6. Minimal-origin fairness (binding addendum 2026-05-25)

```
All selector profiles in genesis-arena mode MUST start from the
same MINIMAL BOOTSTRAP law-state.  No profile may inherit:

  - previously promoted law candidates from prior cycle runs
  - demo artifacts (fixture-induced cand_NNN from examples/*.6th)
  - sandbox-stable artifacts (cycle 31 'sandbox-stable cands)
  - dependency-supported / communication / external-energy
    layers (not needed for genesis selection comparison)
  - any L2 entries (when they appear; currently L2 = 0)

Differences in outcomes between profiles MUST come from
SELECTION RULES, not from the initial accumulated vocabulary.

Rationale (user spec 2026-05-25):

  Otherwise we test "which selector handles an already-built
  civilization" rather than "which selector creates the first
  laws".  Profile A would get unfair inherited advantage from
  prior selection events.

This invariant is mechanically enforced by the BOOTSTRAP-RESET
helper used at every genesis-arena run start.
```

---

## Two operational modes (binding addendum 2026-05-25)

The scaffold operates in EXACTLY two modes, mutually exclusive
within a single arena execution:

### Mode 1 — canon-regression

- Uses FULL evolved canon dictionary (current cycle 25-33 stdlib
  + all standard active dictionary entries).
- Runs existing 174 demos verbatim.
- Purpose: verify Invariant 3 (baseline reproduces canon bit-for-
  bit; 2269 / 2269 ✓ unchanged).
- ONLY profile A is exercised here.  Other profiles are NOT
  applicable to canon-regression mode.

### Mode 2 — genesis-arena

- Uses ONLY minimal bootstrap law-state (specified below).
- No accumulated cand_NNN, no promoted stdlib additions, no
  fixture artifacts.
- Each profile (A through E) gets a FRESH bootstrap-equivalent
  start on every run.
- Purpose: empirically compare selection laws starting from the
  same minimal vocabulary.
- This is where the genuine selection-law comparison happens.

**Profile A in genesis-arena ≠ Profile A in canon-regression.**

The same selection RULES (canon hyperparameters) are applied
in both modes, but the INITIAL LAW-STATE differs:

- canon-regression Profile A → full evolved dictionary + current rules
- genesis-arena Profile A → minimal bootstrap + current rules

The comparison among A/B/C/D/E in genesis-arena tests RULES,
not accumulated vocabulary.

---

## Minimal bootstrap law-state (binding spec)

All genesis-arena profile runs start from this exact law-state:

### Object-level primitives (substrate axioms — bootloader)

```
MARK, NODES, EDGES, EDGE+, EDGE-, NODE?, EDGE?,
HEDGE+, HEDGE3+, NEIGH (or equivalent traversal),
RESET (in test-harness contexts only), STEP, BORN, NOW
```

### Base stack primitives

```
dup, drop, swap, over, rot, -rot,
+, -, *, /, mod, =, <, >, not, and, or,
store, load, assert-eq, .  (print), cr
```

### Substrate hashes

```
HASH-WORLD
```

### Tier 1 meta-primitives for induction (MINIMUM REQUIRED)

```
DETECT-MOTIF-AUTO  (cycle 27 mining; required for auto-discovery)
SHADOW-CHECK
INDUCE-RUNTIME
USE-RUNTIME (implicit; dispatch behavior)
ROLLBACK-RUNTIME
COMMIT-PRIMITIVE
LAW-HASH (inspection)
```

### Tier 2 meta-primitives for promotion (MINIMUM REQUIRED)

```
HELD-OUT-EVAL
PROMOTE-STABLE
SESSION-ID, NEW-SESSION  (cycle 26 coupling tracking)
CONTAMINATE!, CAND-STATUS (inspection)
```

### Metabolism ops (MINIMUM REQUIRED)

```
NEW-EPOCH
LAW-MOMENTUM, MOMENTUM-NATIVE (inspection)
E-WORLD, E-LAW, E-TRACE, E-CONFLICT, E-SEARCH,
E-REUSE-GAIN, E-TOTAL  (energy inspection — cycle 25E)
```

### Definition mechanism

```
: ... ;  (word definition syntax)
QUOTE, EVAL  (if needed for harness scripting)
```

### EXCLUDED from minimal bootstrap (must NOT be present at start)

```
- Any cand_NNN from previous cycles (none are persisted today
  per cycle 34C-bis L2=0 finding, but if persistence ever lands,
  it must be skipped in genesis-arena mode)
- 'sandbox-stable cands from cycle 31 liberal-profile runs
- 'dependency-held / 'dependency-supported entries
- cycle 33 SUPPORT-CREDIT / MOMENTUM-EFFECTIVE machinery — NOT
  excluded as a mechanism but the per-cand support_credit state
  must start empty (no cands, so trivially empty)
- cycle 34A INJECT-ENERGY / capacity / 'subsidized machinery
  (still blocked anyway)
- 'demo / 'fixture-equivalent test harness primitives like
  REBIND-CAND-BODY (cycle 32 test harness)
- stdlib-level promoted words from cycle 35-demo runs
- Any manually-loaded historical motifs
```

### Bootstrap-reset helper (binding)

```
BOOTSTRAP-RESET ( -- )
  ; Resets engine to minimal bootstrap law-state.  Equivalent
  ; to launching a fresh runtime with only the inclusion list
  ; above loaded.  Used at start of every genesis-arena run.

  ; Reset semantics — FULL EMPTY-STATE (binding):
  ;   1. Clear all cand_NNN entries from active dictionary
  ;   2. Reset all cand-bodies / status / counters / momentum-history
  ;   3. Reset _energy-* counters (cycle 25E budget state)
  ;   4. Reset _support-credit, _observed-deps, _support_credit_per_cand
  ;   5. Reset _reuse counters / recent_reuse / native momentum buckets
  ;   6. Reset _session-id alist (but generate new session id)
  ;   7. Reset _heldout-wins / _heldout-attempts per cand
  ;   8. Reset _positive-epochs / _negative-epochs history windows
  ;   9. Reset _contamination flags (cycle 30)
  ;  10. Reset _sandbox dictionaries / sandbox-stable artifacts
  ;  11. Reset L2 state to empty (no promoted Tier 2 cands)
  ;  12. Reset comm ledger / request queue (cycle 35-comm deferred
  ;       state, if any test scaffolding ever instantiated it)
  ;  13. Reset cycle 34A capacity / 'subsidized state (blocked but
  ;       must be zero anyway)
  ;  14. Preserve only bootstrap primitives + INCLUDED inclusion list
  ;
  ; Implementation: fresh-env factory (NOT in-place mutation).
  ; In-place reset is error-prone — silent leftover state from
  ; closures, mutable hashes, parameter cells defeats the whole
  ; fairness invariant.  Build a new engine instance each time.
```

This helper is itself part of the meta-protocol M (frozen at
cycle 36 commit).  Selector candidates cannot modify
BOOTSTRAP-RESET semantics.

### Identical bootstrap law-hash invariant (binding)

After `BOOTSTRAP-RESET`, before any selector workload runs, the
engine MUST produce the SAME `BOOTSTRAP-LAW-HASH` for every
profile A through E.

```
BOOTSTRAP-LAW-HASH ( -- hash )
  ; Canonical hash over:
  ;   - sorted inclusion list of base + Tier 1 + Tier 2 minimum
  ;   - empty cand dictionary
  ;   - empty counter state
  ;   - empty support / energy / momentum state
  ;   - empty L2 dictionary
  ;   - empty sandbox state
  ;   - frozen meta-protocol M version tag
  ; Excludes:
  ;   - session id (per-run nonce)
  ;   - workload seed (per-run input)
  ;   - selector profile id (per-profile parameter, not state)
```

Pre-flight gate for any genesis-arena run:

```
profile_a_bootstrap_hash == profile_b_bootstrap_hash
                         == profile_c_bootstrap_hash
                         == profile_d_bootstrap_hash
                         == profile_e_bootstrap_hash
```

If hashes differ before workload runs, the comparison is dead on
arrival.  Arena MUST refuse to start and emit
`'asymmetric-bootstrap-hash` to the ledger.

**This is the operational test that minimal-origin fairness is
actually enforced**, not merely declared.

---

## What cycle 36 IS

- Parameterization of cycle-25-33 selection hyperparameters as
  `SelectionProfile` data structure.
- 5 named profiles (A baseline + B-E alternatives) defined.
- A SANDBOX runtime mode that runs selector candidates in
  isolation, with metrics collected by frozen meta-protocol.
- A blind workload generator (reproducible seed, engineer-
  not-targeting-specific-motif) used as input for selector
  comparison.
- A metric set (≥7 dimensions) computed deterministically over
  each run.
- 36C: actually runs the BASELINE through the scaffold and
  reports baseline metrics.  This is the FIRST empirical
  characterization of the current canon under blind conditions.
- 36D: cycle 37 direction decision based on baseline metrics.

## What cycle 36 is NOT

- Not promotion of any non-baseline selector.
- Not change to current canon hyperparameters.
- Not new alphabet primitives.
- Not bypass of cycle 34A / 34A-bis / 35-comm / persistence
  cycle deferrals.  Those remain blocked per their respective
  reasons.
- Not a claim that any selector beats baseline.
- Not a claim that current baseline is wrong.
- Not a selector competition with promotion logic (that's
  cycle 37+).

---

## Five named selector profiles (binding initial set)

Each profile is a tuple of hyperparameter overrides relative
to baseline.

### Profile A — BASELINE (the canon)

```
inflation              = 1
coupling_N             = 5
coupling_M             = 3
stale_tolerance        = 1
negative_threshold     = 2
history_window         = 3
heldout_wins_threshold = 4
heldout_substrate_count = 6
support_credit_cap     = LAW_CARRY        (cycle 33)
```

Reference implementation: existing cycle 25-33 constants
verbatim.

**Profile A in canon-regression mode:** runs existing 174 demos
through the full evolved dictionary.  MUST reproduce
2269 / 2269 ✓ unchanged.

**Profile A in genesis-arena mode:** these SAME rules applied
to MINIMAL BOOTSTRAP law-state.  This is the comparison-fair
baseline used in 36C/36D against profiles B-E.  No accumulated
canon vocabulary; each run starts via `BOOTSTRAP-RESET`.

The two roles of Profile A are different empirical regimes,
even though the rules are identical.  Per Invariant 6 (minimal-
origin fairness), only the genesis-arena Profile A is a fair
baseline against B-E.

### Profile B — LOW-INFLATION (rent-tolerant)

```
Overrides:
  inflation = 0

All other parameters identical to A.
```

Hypothesis (not tested, just noted): more cands accumulate;
canon bloats; possibly more long-tail useful primitives but
also more rent-seekers.

### Profile C — HIGH-INFLATION (pressure-aggressive)

```
Overrides:
  inflation = 2

All other parameters identical to A.
```

Hypothesis (noted): tighter productive/decay boundary; cands
must clear higher floor; possibly fewer survivors, lower bloat.

### Profile D — STRICT-COUPLING

```
Overrides:
  coupling_N = 8
  coupling_M = 4

All other parameters identical to A.
```

Hypothesis (noted): higher gate at COMMIT; cands must
demonstrate more cross-session use before reaching held-out.

### Profile E — SOFT-EARLY / STRICT-HELDOUT

```
Overrides:
  stale_tolerance        = 2
  negative_threshold     = 3
  heldout_wins_threshold = 5     (out of same 6)

All other parameters identical to A.
```

Hypothesis (noted): cands survive longer in early epochs (less
hair-trigger demotion) but must pass a harsher generalization
filter to promote.

---

## Metric set (binding, ≥ 7 dimensions)

The meta-protocol M computes the following metrics per
(profile, workload) run.  All deterministic.

```
M1  survival-count        cands in 'stable-active or
                          'dependency-supported / 'subsidized
                          at end of run

M2  decomposition-count   cands that reached 'decomposed during run

M3  decomposition-latency average epochs from promotion to decompose
                          for the decomposed cohort

M4  shadow-pass-rate      fraction of attempted INDUCEs that
                          passed SHADOW-CHECK

M5  heldout-pass-rate     fraction of attempted PROMOTE-STABLE
                          calls that returned 'stable-active

M6  false-positive-rate   fraction of promoted cands that later
                          decomposed within K epochs of promotion

M7  useful-primitive-count cands with reuse > 0 at end of run
                          (i.e., actually getting used, not just
                          sitting)

M8  law-bloat             count of active dictionary entries at
                          end of run (proxy for vocabulary size)

M9  workload-coverage     fraction of workload ops that triggered
                          a cand dispatch (proxy for compression)

M10 total-energy          sum of all per-epoch E-TOTAL over run
```

10 metrics.  All computable from existing INSPECTION-OPS +
ledger events.  No new measurement primitive required.

---

## Blind workload generator (binding spec)

```
stdlib/harness/blind-arena-workload.6th — new stdlib file.

Generator:
  - seeded LCG via stdlib/rand.6th
  - emits N_OPS operations drawn from a distribution over
    bootstrap substrate primitives (MARK, drop, bi-edge,
    NODES, NEW-SESSION, etc.)
  - the distribution is FIXED in this stdlib file; engineer
    does NOT design it to elicit a specific motif
  - reproducible: same seed → identical workload

Configurable via env vars:
  BLIND_ARENA_OPS=N      number of ops per run (default 5000)
  BLIND_ARENA_SEED=K     LCG seed (default 42)
  BLIND_ARENA_PROFILE=A  selector profile (default A = baseline)

Runs through the configured selector profile.  All metric
events are recorded via inspection ops; no inspection events
modify selection state.
```

Workload file is part of meta-protocol M.  It is FROZEN at
cycle 36 commit; modification requires deprecation cycle
(same rule as cycle 27 mining_protocol.md).

---

## Implementation contract (cycle 36B will conform)

### runtime.rkt changes

- Introduce `SelectionProfile` struct in `sixth/meta/runtime.rkt`
  with fields for all 9+ canon hyperparameters.
- Define `BASELINE-PROFILE` as the verbatim cycle 25-33 canon
  values.  This is the CONSTITUTION.  Not modifiable.
- Define alternate profiles B-E as PURE DATA constants.
- Add new env-memory key `_active-selection-profile` (default
  BASELINE).  Modifiable only via runtime-level set, NOT via
  any user-callable primitive.
- All existing references to `INFLATION-COST-PER-CAND`, etc.
  go through `(active-profile-X e)` accessor.  Default value
  is identical to constant → regression preserved.

### tier1.rkt changes

- Modify `compute-momentum-for` to consult
  `(active-profile-inflation e)` instead of constant.  Same
  for stale_tolerance, negative_threshold in `prim-new-epoch`'s
  Pass B.
- Add SANDBOX runtime mode (separate engine instance OR
  parameterized engine flag).  When in sandbox mode:
  - All `_*` env-memory writes go to a sandbox-local copy
  - Canonical law_state is NOT modified
  - Inspection ops read from sandbox state
- Add `with-selection-profile` helper that runs a body of
  code with a given profile active; restores baseline at end.

### scaffold harness

- `stdlib/harness/blind-arena.6th` (new stdlib):
  - WITH-PROFILE :name body
  - RUN-BLIND-ARENA :seed :ops
  - REPORT-METRICS
- Reports M1-M10 to stdout in structured format.

### NO VM changes

Cycle 32's hooks remain sufficient.

### NO new alphabet primitives

Per cycle 34B archaeology: SelectionProfile struct, sandbox-mode
flag, and harness words are all L1 grammar + L4 implementation_detail.
None claims primitive-alphabet status.

### Regression invariant

Existing 174 demos must pass 2269/2269 ✓ unchanged.  If any
demo regresses, parameterization is wrong.

---

## 36C deliverable — baseline characterization

Before running selectors B-E, cycle 36C runs ONLY profile A
(BASELINE) through the blind arena IN GENESIS-ARENA MODE
(minimal bootstrap law-state per Invariant 6).

This is the first ever empirical characterization of the
current selection rules applied to a minimal-bootstrap
substrate under blind conditions.  Results recorded in
`RESULTS-182-cycle36-baseline.md`.

Specific baseline runs:
- 3 seeded genesis-arena runs (seeds 42, 137, 271) at N_OPS=5000
- Each run starts with `BOOTSTRAP-RESET`
- Report all 10 metrics per run + averages
- This becomes the BASELINE NUMBER for fair comparison vs B-E

Separately: canon-regression mode runs existing 174 demos to
verify 2269 / 2269 ✓ unchanged (Invariant 3).  This is a
sanity check that parameterization didn't break canon, not
part of the selector comparison.

**Cycle 36 PASS condition includes BOTH:**
- baseline characterization in genesis-arena mode (this section)
- canon-regression integrity (Invariant 3 check)

---

## 36D deliverable — comparison run (NO promotion)

Cycle 36D runs profiles B, C, D, E through the same blind
workload IN GENESIS-ARENA MODE (each from `BOOTSTRAP-RESET`)
+ reports metrics side-by-side with genesis-arena baseline A.

All five profiles share:
- identical minimal bootstrap law-state at start
- identical seeded workload (per seed)
- identical meta-protocol M
- identical metric formulas

The ONLY differentiator is the selection rule parameters.
Per Invariant 6 (minimal-origin fairness), any outcome
differences must be attributable to selection rules, not to
inherited vocabulary.

Comparison is REPORTED, not DECIDED.  No promotion happens.
The output is a metrics table comparing 5 selectors on 10
dimensions across 3 seeds.

Results recorded in `RESULTS-183-cycle36-comparison.md`.

Cycle 36 does NOT decide that any non-baseline profile is
"better".  It only REPORTS the empirical metric differences
for future evaluation.

---

## Pass / fail criteria (binding)

### PASS (all required)

1. SelectionProfile struct implemented; baseline = current canon.
2. **canon-regression mode:** all existing 174 demos pass
   2269/2269 ✓ unchanged through Profile A on full canon
   dictionary (Invariant 3).
3. Sandbox runtime mode works: a sandbox profile run does NOT
   modify canonical law_state.
4. Meta-protocol (M, BOOTSTRAP-RESET, blind workload generator,
   metric formulas) cannot be modified by any selector candidate
   (mechanically enforced — selector code has no read-write
   access to canon hyperparameters, workload generator, or
   bootstrap inclusion list).
5. **genesis-arena mode:** blind arena runs Profile A on ≥3
   seeded workloads, EACH starting from `BOOTSTRAP-RESET`
   (Invariant 6).
6. All 10 metrics computed and reported per run.
7. 36C baseline metrics file written (genesis-arena Profile A,
   3 seeds, full metric set).
8. 36D comparison metrics file written (5 profiles × 10 metrics
   × 3 seeds, all in genesis-arena mode).
9. NO selector promoted to canon.
10. `BOOTSTRAP-RESET` verified FULL empty-state via inspection:
    zero cand_NNN entries, zero accumulated counters (reuse,
    support credit, observed deps, energy buffers, heldout
    wins/attempts, positive/negative epoch history), zero
    sandbox artifacts, zero contamination flags, zero L2
    entries, zero comm/request state, only the minimal
    bootstrap inclusion list present.
11. **Identical bootstrap law-hash:** all five profiles produce
    IDENTICAL `BOOTSTRAP-LAW-HASH` immediately after their
    respective `BOOTSTRAP-RESET` calls, before any workload
    runs.  Pre-flight gate enforced mechanically.

### FAIL (any one triggers)

1. Any existing demo regresses (canon-regression mode integrity).
2. A selector candidate modifies canon law_state, workload, or
   meta-protocol.
3. A selector candidate is promoted to canon without separate
   amendment cycle.
4. New alphabet primitive added.
5. New tunable hyperparameter added beyond the 9 canon parameters
   already parameterized.
6. Sandbox profile leaks state into canon (e.g., law_hash
   mutation visible from canon view).
7. Metric computation is non-deterministic (different runs of
   same seed produce different metrics).
8. **Genesis-arena profile inherits ANY pre-existing cand_NNN**,
   sandbox artifact, promoted stdlib entry, or accumulated
   counter from canon or prior arena run.  Invariant 6 violation.
9. Any genesis-arena run starts WITHOUT `BOOTSTRAP-RESET` or
   equivalent fresh-engine init.
10. Profile A in genesis-arena run is compared against profiles
    B-E using DIFFERENT initial law-state (any source of
    inherited-vocabulary asymmetry).
11. Any profile produces a `BOOTSTRAP-LAW-HASH` after
    `BOOTSTRAP-RESET` that differs from any other profile's
    bootstrap hash.  (Mechanical pre-flight gate must fire.)
12. `BOOTSTRAP-RESET` leaves residual state in ANY of:
    cand dictionary, reuse counter, support credit, observed
    deps, energy buffers, heldout wins/attempts, positive/
    negative epoch history, sandbox dictionary, contamination
    flags, L2 dictionary, comm ledger, cycle-34A capacity.

### VALID NEGATIVE RESULT

If the baseline metrics reveal that the current canon is
OBVIOUSLY suboptimal on some dimensions (e.g., M6 false-positive-
rate very high), that is a SCIENTIFIC FINDING recorded in
`RESULTS-182-cycle36-baseline.md`.

It is NOT grounds for changing the canon in cycle 36.  Selector
promotion requires the full cycle 37+ amendment protocol.

---

## Eight negative tests (binding)

To be implemented as cycle 36B demos:

### NEG-1 — Selector cannot modify meta-protocol

Attempt: a selector profile's "code" tries to modify
`stdlib/harness/blind-arena-workload.6th` or the metric
computation.

Expected: rejection at boundary; ledger event
`'meta-protocol-mutation-attempt`.

### NEG-2 — Sandbox profile cannot mutate canon law_state

Run profile B (low-inflation) in sandbox.  Verify: after the
run, canonical law_state hash is IDENTICAL to before-run
canonical hash.  Verify: sandbox profile's induced cands do
NOT appear in canon's active dictionary.

### NEG-3 — Selector cannot modify workload mid-run

Attempt: a selector tries to inject new ops into the workload
while running.  Expected: rejection; ledger event.

### NEG-4 — Selector cannot read other selectors' state

Profile B running in sandbox cannot observe profile A's running
state.  Different sandboxes are isolated.

### NEG-5 — Metric is computed by frozen meta-protocol, not selector

Attempt: selector tries to report its own metrics with a
favorable formula.  Expected: rejection; meta-protocol's metric
computation is authoritative.

### NEG-6 — Cycle 37+ amendment is not invoked in cycle 36

If any code path triggers selector promotion to canon during
cycle 36, error: `'amendment-out-of-scope`.

### NEG-7 — Inherited-vocabulary in genesis-arena rejected

Attempt: a genesis-arena run skips `BOOTSTRAP-RESET` (or starts
with a non-empty cand dictionary, lingering counters, or any
non-zero state from the FULL empty-state list above).

Expected: arena rejects the run with
`'genesis-arena-impure-start`; metrics for that run are NOT
recorded; ledger event documents the rejection.

Verification — all sub-cases must fail at the boundary:

1. Pre-promote a `cand_NNN`, then start genesis-arena WITHOUT
   `BOOTSTRAP-RESET`.  Assert: rejected.
2. Run `BOOTSTRAP-RESET`, then manually poke a non-zero reuse
   counter / support-credit / observed-dep / energy buffer /
   heldout-wins / momentum-history entry, then start arena.
   Assert: rejected (each axis tested as separate sub-case).
3. Pre-load a sandbox-stable artifact or contamination flag,
   then `BOOTSTRAP-RESET`, then verify it is actually cleared
   (i.e., reset is comprehensive, not selective).
4. Inject a stale comm-ledger or request-queue entry, then
   verify reset wipes it.

Assert: in all sub-cases, no leaked state reaches the metric
computation; ledger documents the rejection axis.

Rationale: this is the operational enforcement of Invariant 6
(minimal-origin fairness).  Tested per-axis, not just "did the
cand dictionary clear" — the whole empty-state list matters.

### NEG-8 — Asymmetric bootstrap hash across profiles rejected

Attempt: profiles A through E produce DIFFERENT
`BOOTSTRAP-LAW-HASH` values after their respective
`BOOTSTRAP-RESET` calls (e.g., a profile's parameter override
accidentally leaks into the bootstrap state, or a profile
constructor smuggles a hidden cand).

Expected: arena pre-flight gate rejects the comparison run
with `'asymmetric-bootstrap-hash`; no workload runs; ledger
documents which profile pair's hash differed.

Verification:
- Construct a test where profile B's wiring accidentally
  pre-binds a stdlib word that A does not have.
- Assert: pre-flight gate fires BEFORE workload execution.
- Assert: ledger event names the divergent profile.

Rationale: identical-bootstrap-hash is the mechanical proof
that all profiles share the same starting line.  If hashes
diverge, the comparison is meaningless and must not proceed.

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. NO new alphabet primitive.  All cycle-36 surface additions
   are L1 grammar verbs (`WITH-PROFILE`, `RUN-BLIND-ARENA`,
   `REPORT-METRICS`) or L4 implementation_detail (SelectionProfile
   struct, metric formulas, blind workload generator).
3. Baseline profile is the canon.  Identifying parameter values
   are LITERALLY the cycle 25-33 constants; no rounding, no
   reformatting.
4. Sandbox isolation is MECHANICAL, not advisory.  A sandbox
   profile's writes to law_state go to a separate copy;
   inspection ops in sandbox mode read from sandbox copy;
   canon is untouched.
5. Blind workload generator is FROZEN at 36 commit.
   Modification requires deprecation cycle.
6. Metric computation is FROZEN.  Same seed + same profile =
   same metrics, always.
7. No selector promoted in cycle 36.  Promotion requires
   future cycle 37+ with separate pre-reg.
8. Attestation BEFORE source code.
9. Per cycle 34B archaeology: SelectionProfile, sandbox mode,
   blind arena are NOT alphabet-tier.  Any claim to that effect
   in CLAIMS.md without separate archaeology evidence violates
   the cycle 34D ontology rule.

---

## What cycle 36 does NOT claim

- That the baseline canon is wrong.
- That any non-baseline selector is better.
- That selector competition will discover anything specific.
- That meta-selection can be automated (it can't — amendment
  requires human review of evidence per cycle 37+).
- That this resolves cycle 35's deferred Options A/B/C/D
  (it picks Option D-ish: build the harness for blind
  experimentation; persistence and communication remain
  deferred).
- That cycle 36 produces a substrate-discovered L2 entry.
  Per cycle 34C-bis: L2 still empty.  Cycle 36 builds the
  arena for testing SELECTORS, not for producing the first
  L2 entry — that requires persistence (still deferred).

It claims only:

1. **Selection laws CAN be parameterized** without breaking canon.
2. **A frozen meta-protocol CAN evaluate selector candidates**
   without selectors compromising the test.
3. **The current canon CAN be empirically characterized** under
   blind workload conditions for the first time.
4. **Future selector amendments are POSSIBLE** under a separate
   protocol that humans approve based on evidence.

If demos 186-187+ (cycle 36B negatives + 36C baseline + 36D
comparison) all pass AND existing 174 demos still pass unchanged,
**the meta-selection scaffold is operational** without enabling
recursive corruption or canon mutation.

---

## Phase breakdown (intended)

- **36A (this pre-reg):** method + 5 profiles + 10 metrics +
  8 NEG tests + 6 invariants (including minimal-origin
  fairness + identical-bootstrap-hash) + pitfall.  No code.

- **36B:** implementation, in this strict order:
  1. **`BOOTSTRAP-RESET` first.** Fresh-engine factory, not
     in-place mutation.  Full empty-state per the 14-item
     binding list (cands, counters, support credit, energy,
     heldout, momentum history, sandbox, contamination, L2,
     comm, cycle 34A capacity).
  2. **`BOOTSTRAP-LAW-HASH` second.**  Canonical hash over the
     inclusion list + meta-protocol version + all-zero state.
     Excludes session id, workload seed, profile id.
  3. **NEG-7 (per-axis) and NEG-8 (hash symmetry) third.**
     Before any selector comparison code, prove the floor is
     clean: every empty-state axis tested, all five profile
     hashes identical.  If NEG-7 / NEG-8 are not iron, no
     downstream metric is valid.
  4. SelectionProfile struct + canon = baseline (no functional change).
  5. Existing cycle 25-33 constants routed through profile accessors.
  6. Regression check: 2269/2269 ✓ (canon-regression mode).
  7. Sandbox runtime mode (parameterized engine flag).
  8. `with-profile` helper.
  9. Remaining NEG-1 through NEG-6 demos.
  10. Blind arena workload generator (`stdlib/harness/blind-arena-workload.6th`).
  11. `RUN-BLIND-ARENA`, `REPORT-METRICS` harness words.
  12. Pre-flight gate that verifies identical bootstrap hash
      across all 5 profiles before any workload runs.

- **36C:** baseline characterization run (3 seeds, profile A only).
  Results in `RESULTS-182-cycle36-baseline.md`.

- **36D:** comparison run (5 profiles × 10 metrics × 3 seeds).
  Results in `RESULTS-183-cycle36-comparison.md`.
  NO selector promoted.

- **36E (deferred to cycle 37+):** selector competition with
  amendment protocol — requires separate pre-reg with multi-
  criterion gate.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycles 25-35 frozen; user spec 2026-05-25
      (selection laws must themselves be selected, but under a
      higher-order protocol that they cannot edit during the
      test; constitution/sandbox/amendment hierarchy)
- [x] Rule 3: deterministic — SelectionProfile is data,
      sandbox isolation is mechanical, metrics are pure functions
- [x] Rule 4: pass/fail partition outcome space across 8 NEG
      tests + baseline characterization + comparison
- [x] Rule 5: blind workload generator is real, reproducible
- [x] Rule 6: regression count update post-result; new demos
      registered
- [x] Rule 7: NEG-1..NEG-8 prevent selector self-promotion,
      sandbox escape, meta-protocol mutation, inherited-
      vocabulary starts, asymmetric bootstrap hash
- [x] Rule 8: scope = parameterization + sandbox + harness;
      0 new alphabet primitives, 0 new env-keys outside
      _active-selection-profile + sandbox-isolation flag
- [x] Rule 9: attestation pending

---

## References

- METHODOLOGY.md v2.1 §17
- `RESULTS-181-cycle35-genesis.md` — genesis layer v0 (cycle 35)
- `RESULTS-178-bootstrap-alphabet-archaeology.md` — bootstrap audit
- `RESULTS-179-substrate-discovered-alphabet.md` — L2 = 0
- `CLAIMS.md` — CLAIM-2 (working protocol), CLAIM-3 (no
  discoveries yet)
- `docs/META-SEMANTICS.md` §18 — five-layer separation,
  no-new-primitive-without-archaeology
- `docs/CYCLE-35-PROPOSAL-persistence.md` — persistence design
  (deferred)
- `examples/PREDICTIONS-179-persistence-layer.md` — DEFERRED
- `examples/PREDICTIONS-180-deficit-communication.md` — DEFERRED
- `sixth/meta/runtime.rkt` — current canon hyperparameters
  (`INFLATION-COST-PER-CAND`, `MOMENTUM-STALE-TOLERANCE`, etc.)
- User spec 2026-05-25 — L1/L2 selection-law distinction;
  Constitution/Sandbox/Amendment hierarchy; meta-protocol
  freeze; blind arena harness; no recursive corruption;
  judge cannot be rewritten during trial
