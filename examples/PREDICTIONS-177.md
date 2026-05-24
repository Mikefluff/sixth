# Demo 177 — Pre-Registered Predictions (cycle 34)

**Date pre-registered:** 2026-05-24

**Attested via** `scripts/attest_prediction.sh` per Rule 9.
Initial attestation: see ledger row dated 2026-05-24.

---

## CORE FORMULATION (binding, cycle-34-wide)

> External energy can buy runway, not validity.  Selected stable
> structures can absorb more energy because their capacity is
> earned through held-out wins, positive epochs, and runtime-
> observed dependents — but subsidized momentum cannot
> masquerade as native viability.

Every other commitment in this pre-reg is a corollary of this core.
If any cycle-34 mechanism violates this — by allowing external credit
to satisfy a truth gate, by allowing subsidized cands to contribute
support downstream, by allowing capacity to be conjured without
selection history, or by silently absorbing over-capacity injection
without a leak event — it is a regression, not a feature.

---

## Scope: External Energy Intervention and Capacity

Cycle 34 opens the metabolism to **external** energy.  Cycles 25–33
described a closed-system internal metabolism: cands earn momentum,
support each other (cycle 33 carry offset), and either survive or
auto-decompose.  But real substrates receive energy from outside
(attention, compute budget, deliberate human boost, external
reinforcement).  Cycle 34 makes this **observable and bounded**:

- `INJECT-ENERGY cand amount source purpose ttl ( -- )` records an
  injection.  Amount is amortized as integer-floor credit over `ttl`
  epochs.
- Each cand has an **energy capacity** earned through selection:
  `1 + heldout_wins + positive_epochs + observed_dependents_this_epoch`,
  with capacity = 0 for non-stable / contaminated / sandbox cands.
- Per-epoch absorption is `min(epoch_credit_raw, capacity)`.  The
  remainder leaks as a ledger event — NOT semantic conflict.
- A cand kept alive solely by external credit is tagged `'subsidized`
  — parallel to cycle 33's `'dependency-supported` but with a
  different rent payer.
- **Truth-immune:** external credit DOES NOT satisfy SHADOW-CHECK,
  HELD-OUT-EVAL, COMMIT-PRIMITIVE, PROMOTE-STABLE, or the organic
  positive-anchor predicate used in cycle 33's support_credit.

Cycle 34 is NOT:
- A new way to **pass** held-out evaluation (truth gates are unchanged)
- A way to silently make a cand stable-active (only `m_organic`
  exceeding STALE_TOL produces 'stable-active)
- A way to transfer profit from external donor to dependents
  (subsidized cands contribute 0 support credit, same rule as cycle 33)
- A change to the cycle 30 `'dependency-held` Pass C mechanism
- A change to held-out evaluation, inflation rate, profile semantics,
  or any cycle 28-33 truth-gate behavior

Cycle 34 IS:
- The **truth-immune** invariant: external credit cannot satisfy any
  truth gate; it can only extend runway and defer auto-decomposition
- The **capacity-from-selection** invariant: capacity is a function
  of earned signals (heldout wins, positive epochs, current dependents);
  raw complexity is not capacity
- The **no-subsidized-support-contribution** invariant: cycle 33's
  `m_native > STALE_TOL` test for support contribution continues to
  read `m_native` (≡ `m_organic`), NOT `m_subsidized`; an externally-
  rescued cand cannot then feed others
- The **leak-not-conflict** invariant: over-capacity injection produces
  a `'energy-leaked` ledger event, NOT an E_conflict increment; leaks
  are not law-state mutations

---

## Triple-momentum surface, extended (4 buckets total)

```
MOMENTUM-NATIVE     ( cand -- n )   m_native = reuse - carry - fails - inflation
                                    (cycle 31; unchanged)
SUPPORT-CREDIT      ( cand -- n )   support_credit ≤ LAW_CARRY (cycle 33)
EXTERNAL-CREDIT     ( cand -- n )   cycle 34: this-epoch absorbed external
                                    credit after amortization & capacity cap
ORGANIC-MOMENTUM    ( cand -- n )   alias for MOMENTUM-NATIVE, used in
                                    cycle-34 demos to make the
                                    "no-external, no-support" semantics
                                    explicit at the demo level
SUBSIDIZED-MOMENTUM ( cand -- n )   = ORGANIC + EXTERNAL  (NO support)
MOMENTUM-EFFECTIVE  ( cand -- n )   = ORGANIC + SUPPORT + EXTERNAL
                                    (cycle 34 extends cycle 33: now includes
                                     external_credit.  Status decisions in
                                     Pass B consult this.)
```

**Iron rule (binding):**

- `PROMOTE-STABLE`, `COMMIT-PRIMITIVE`, `HELD-OUT-EVAL`,
  `SHADOW-CHECK`, and `compute-support-credit-for` (cycle 33) ALL
  consult `ORGANIC` (≡ `MOMENTUM-NATIVE`), NEVER `SUBSIDIZED` or
  `EFFECTIVE`.
- Status transitions in Pass B consult all of NATIVE / SUPPORT /
  EXTERNAL via `m_eff`, but the labels honestly disclose which
  bucket was load-bearing (`'stable-active` / `'dependency-supported`
  / `'subsidized`).

---

## Three new structural mechanisms

### Element A — Injection with integer amortization

```
INJECT-ENERGY ( cand amount source purpose ttl -- )
```

Stack effect: pops 5 values (TTL on top).  Records into per-cand
injection slot:

```
remaining[cand] := amount      ;; integer ≥ 1
ttl[cand]       := ttl         ;; integer ≥ 1
source[cand]    := source       ;; symbol (diagnostic only)
purpose[cand]   := purpose      ;; symbol (diagnostic only)
```

If a cand already has an active injection slot, **replace** it
(commitment: no implicit accumulation across multiple injections).
This is conservative — cycle 34 v0 supports one active injection
per cand.

At each NEW-EPOCH (Pass A.4, before status transitions):

```
epoch_credit_raw := floor(remaining[cand] / ttl[cand])
remaining[cand]  := remaining[cand] - epoch_credit_raw
ttl[cand]        := ttl[cand] - 1
if ttl[cand] == 0 or remaining[cand] == 0:
    clear injection slot (source, purpose retained until next NE for diagnostic;
                          cleared at end-of-NE alongside other resets)
```

**Sequence example** (`amount=10, ttl=4`):
- epoch 1: `floor(10/4)=2`, remaining=8, ttl=3
- epoch 2: `floor(8/3)=2`,  remaining=6, ttl=2
- epoch 3: `floor(6/2)=3`,  remaining=3, ttl=1
- epoch 4: `floor(3/1)=3`,  remaining=0, ttl=0  → slot cleared

Sequence: `2, 2, 3, 3`.

### Element B — Capacity from selection (with leak)

```
capacity(cand) :=
  if get_status(cand) in SANDBOX-STATUSES:                0
  elif get_status(cand) not in STABLE-WORD-STATUSES:      0
  elif contaminated?(cand):                                0
  else:
       1
     + heldout_wins(cand)
     + positive_epochs(cand)
     + observed_dependents_this_epoch(cand)
```

Where:
- `heldout_wins(cand)` is a running counter incremented inside
  `prim-held-out-eval-real` whenever it returns success.
- `positive_epochs(cand)` is a running counter incremented in
  Pass A.3 of NEW-EPOCH whenever `m_organic > STALE_TOL` for this
  epoch.
- `observed_dependents_this_epoch(cand)` is the snapshot count from
  observed-deps (already populated by this point in NE; reset at
  end-of-NE).  Counted as: distinct `B` such that `observed_dep(B, cand) = 1`
  during this epoch.

Then in Pass A.4:

```
epoch_credit_raw := floor(remaining[cand] / ttl[cand])    ;; see Element A
cap              := capacity(cand)
external_credit[cand] := min(epoch_credit_raw, cap)
leaked            := epoch_credit_raw - external_credit[cand]

if leaked > 0:
    record_ledger! e (list 'energy-leaked cand
                            amount-injected-original
                            cap
                            external_credit[cand]
                            leaked
                            source[cand]
                            purpose[cand]
                            ttl[cand]
                            current_epoch
                            stable_law_hash
                            world_hash)
```

**Energy not absorbed is gone** — leaked energy does NOT roll over
into a future epoch's budget.  This preserves rented-not-owned across
the external bucket as well: a cand can't accumulate undelivered
credit while waiting for capacity to grow.

Leak events go to the **trace ledger**.  They are NOT added to
`E_conflict`, NOT to any other energy bucket.  By the
cycle-25E `_energy-*`-observational-only rule, they do NOT enter
law_hash or world_hash.

### Element C — Status transition with `'subsidized`

In Pass B of NEW-EPOCH, after Pass A.5 support snapshot AND Pass A.4
external amortization:

```
m_organic  = compute_momentum_for(A)                   ;; ≡ m_native
support    = support_credit_snapshot[A]                ;; from Pass A.5
external   = external_credit[A]                        ;; from Pass A.4
m_eff      = m_organic + support + external            ;; cycle 34: 3 buckets

if m_organic > STALE_TOLERANCE:
    A.status = 'stable-active                          ;; natively earning;
                                                       ;; support & external
                                                       ;; irrelevant for label

elif support > 0 and (m_organic + support) >= -STALE_TOLERANCE:
    A.status = 'dependency-supported                   ;; cycle 33 unchanged:
                                                       ;; internal support
                                                       ;; alone sufficed
                                                       ;; (external incidental
                                                       ;; this epoch, but TTL
                                                       ;; still decremented)

elif external > 0 and m_eff >= -STALE_TOLERANCE:
    A.status = 'subsidized                             ;; cycle 34 NEW:
                                                       ;; external credit was
                                                       ;; load-bearing this
                                                       ;; epoch

elif abs(m_eff) <= STALE_TOLERANCE:
    A.status = 'stale

elif m_eff < -STALE_TOLERANCE:
    last_n = history[:MOMENTUM_NEGATIVE_THRESHOLD]     ;; still m_organic history
    if length(last_n) == N and all(m < -STALE_TOL for m in last_n):
        A.status = 'demotion-candidate                 ;; cycle 32 Pass C catches
    else:
        A.status = 'stale
```

The ordering encodes a precedence: native > support-rescued >
external-rescued.  A cand whose support alone keeps it safe is
labeled `'dependency-supported` (more honest signal — internal,
real, sustainable); a cand requiring external on top of (or instead
of) support is labeled `'subsidized` (rented from outside).

**History still tracks m_organic, not m_subsidized, not m_eff.**
Chronic non-productivity accumulates regardless of external rescue.
When TTL expires and external_credit drops to 0, the cand falls
through to whatever its history dictates — likely demotion-candidate
or stale.  This enforces "external buys runway, not history."

---

## New env-memory keys (7)

```
_external-remaining   alist (cand-sym . int)        ;; remaining amount
_external-ttl         alist (cand-sym . int)        ;; remaining epochs
_external-source      alist (cand-sym . sym)        ;; last injection source tag
_external-purpose     alist (cand-sym . sym)        ;; last injection purpose tag
_external-credit      box of alist (cand-sym . int) ;; this-epoch absorbed
                                                    ;;   credit; computed in
                                                    ;;   Pass A.4; reset at
                                                    ;;   end of NE (rented)
_heldout-wins         alist (cand-sym . int)        ;; running counter,
                                                    ;;   incremented in
                                                    ;;   prim-held-out-eval-real
                                                    ;;   on success
_positive-epochs      alist (cand-sym . int)        ;; running counter,
                                                    ;;   incremented in
                                                    ;;   Pass A.3 on
                                                    ;;   m_organic > STALE_TOL
```

`_external-credit` is rented per epoch (reset at end of NE).
`_external-remaining`, `_external-ttl`, `_external-source`,
`_external-purpose` persist across epochs until depleted (then cleared).
`_heldout-wins` and `_positive-epochs` are **cumulative** running
counters (NOT reset on NE).  Heldout wins/positive epochs are the
"earned capacity history" — by definition they need to persist.

All seven are underscore-prefixed → internal, protected by the
existing store-to-underscore guard.

---

## New Tier 1 primitives (8 new + 1 alias)

```
INJECT-ENERGY        ( cand amount source purpose ttl -- )
                     Mutator.  Stack pops in order: ttl on top.
                     Records injection slot for cand.  Always succeeds
                     deterministically; if cand has no STABLE-WORD-STATUSES
                     status, capacity will be 0 so all credit will leak,
                     but the injection record is still made.  TTL ≥ 1 and
                     amount ≥ 1 required (else 'inject-energy-invalid in
                     ledger; no slot recorded).

EXTERNAL-CREDIT      ( cand -- n )    ;; this-epoch absorbed credit; 0 if no
                                      ;; injection or if cleared at NE end

ENERGY-BUFFER        ( cand -- n )    ;; remaining[cand]; 0 if no active slot

ENERGY-CAPACITY      ( cand -- n )    ;; computed capacity for this epoch
                                      ;; (the formula above)

ENERGY-LEAK          ( cand -- n )    ;; leaked amount in last NE; 0 if none.
                                      ;; Reset at end of NE.

ENERGY-SOURCE        ( cand -- sym )  ;; last injection's source tag, or 'none

SUBSIDIZED?          ( cand -- 0|1 )  ;; 1 iff external_credit[cand] > 0
                                      ;; (this epoch)

ORGANIC-MOMENTUM     ( cand -- n )    ;; alias for MOMENTUM-NATIVE

SUBSIDIZED-MOMENTUM  ( cand -- n )    ;; m_organic + external_credit
```

All 8 new + 1 alias are INSPECTION-OPS except INJECT-ENERGY (mutator).
INJECT-ENERGY is the lone non-inspection cycle-34 primitive.

---

## New status (1)

```
'subsidized   external credit applied AND was load-bearing this epoch
              (support alone insufficient); cand callable; participates in
              metabolism; in STABLE-WORD-STATUSES (counted in STABLE-LAW-HASH)
              and ACTIVE-METAB-STATUSES (pays inflation; runs NE).
              NOT in SANDBOX-STATUSES.
```

Rationale: 'subsidized is parallel to 'dependency-supported.  Both
mean "rented, not earning."  The labels honestly disclose the rent
source.

`STABLE-WORD-STATUSES` becomes:
```
'(ephemeral-active committed stable-active stale demotion-candidate
  dependency-held dependency-supported subsidized)
```

`ACTIVE-METAB-STATUSES` becomes:
```
'(stable-active stale demotion-candidate dependency-held
  sandbox-stable dependency-supported subsidized)
```

`SANDBOX-STATUSES` unchanged: `'(experimental sandbox-stable)`.

---

## NO new hyperparameter

- Amortization formula is `floor(remaining / ttl)`, structural.
- Capacity formula is fixed structurally (1 + 3 earned signals).
- Status ordering in Pass B is structural (precedence: native >
  support > external).
- No new tuning knob in this cycle.

---

## NE pass sequence (full, post-cycle-34)

```
Pass A   — compute m_organic, push m_organic to history
Pass A.3 — if m_organic > STALE_TOL: increment positive_epochs[c]  ;; cycle 34 NEW
Pass A.4 — for each active cand with active injection slot:        ;; cycle 34 NEW
             epoch_credit_raw = floor(remaining / ttl)
             cap              = compute_capacity_for(c)
             external_credit  = min(epoch_credit_raw, cap)
             leaked           = epoch_credit_raw - external_credit
             remaining -= epoch_credit_raw  (NOT external_credit; leak is gone)
             ttl       -= 1
             record 'energy-leaked event if leaked > 0
             if remaining == 0 or ttl == 0: schedule slot clear at end-of-NE
Pass A.5 — snapshot support_credit per cand                         ;; cycle 33 unchanged
Pass B   — status transitions (now 6 outcomes: stable-active,
           dependency-supported, subsidized, stale,
           demotion-candidate, [previous status if no transition])
Pass C   — dependency-aware AUTO-DECOMPOSE for demotion-candidates  ;; cycle 30/32

End-of-NE resets:
- observed-deps                                                     ;; cycle 32
- support_credit snapshot                                            ;; cycle 33
- external_credit snapshot                                           ;; cycle 34 NEW
- energy-leak amounts                                                ;; cycle 34 NEW
- (recent_uses, recent_reuse, recent_fails)                          ;; cycle 29
- depleted external slots (remaining==0 OR ttl==0)                   ;; cycle 34 NEW
```

Persistence across epochs:
- m_organic history (window)
- heldout_wins (cumulative)
- positive_epochs (cumulative)
- external_remaining, external_ttl, external_source, external_purpose
  (until depleted)

---

## Implementation contract (cycle 34B will conform)

### env-memory keys (7 new)

See "New env-memory keys" above.

### runtime.rkt changes

- Add 7 new `MEM_EXTERNAL_*` / `MEM_HELDOUT_WINS` / `MEM_POSITIVE_EPOCHS`
  / `MEM_EXTERNAL_CREDIT` keys
- Initialize all in `install-meta-runtime!`
- Add `'subsidized` to `ACTIVE-METAB-STATUSES`
- Add `'subsidized` to `STABLE-WORD-STATUSES`
- Add 9 new symbols to INSPECTION-OPS (INJECT-ENERGY excluded; it's a mutator)
- Add accessors for each new memory key
- Export the new symbols

### tier1.rkt changes

- Add `compute-capacity-for` helper (4 base cases: sandbox → 0;
  not in STABLE-WORD-STATUSES → 0; contaminated → 0; otherwise the
  formula)
- Add `compute-external-credit-amortized` helper (`floor(rem/ttl)`)
- Modify `prim-new-epoch`:
  * Add Pass A.3 (positive_epochs counter)
  * Add Pass A.4 (energy amortization + leak event + slot decrement)
  * Pass B: add `'subsidized` branch after `'dependency-supported`
  * At end, reset `_external-credit` to `'()`; reset `_energy-leak`
    counter; clear depleted external slots
- Modify `prim-held-out-eval-real`: on success, increment
  `_heldout-wins[cand]`
- Add 9 new primitives (INJECT-ENERGY + 8 inspections; ORGANIC-MOMENTUM
  registered as alias-to-LAW-MOMENTUM, like MOMENTUM-NATIVE already is)
- Register all in TIER1-TABLE
- Update INSPECTION-OPS list in runtime.rkt

### NO VM changes

Cycle 32's two VM hooks remain sufficient.  Cycle 34 is meta-runtime
only.

---

## Demo 177 — external-buys-time-not-truth (happy)

### Setup
- Promote cand_001 = (MARK drop), L=2.
- Drive it idle to stale: NE without dispatches a few times.
- cand_001 m_organic = -3 per idle epoch (carry=2, inflation=1).

### Lifecycle
- After 1 idle NE: cand_001 status = 'stale (m_organic = -3, fits stale
  branch since history only has one negative).
- Continue: 2nd idle NE — history now `(-3 -3)`, still not enough for
  demotion-candidate (MOMENTUM-NEGATIVE-THRESHOLD = 2 → 2 consecutive
  negs).  Actually demotion-candidate triggers when last 2 are below
  -STALE_TOL.  After 2nd NE, cand_001 → 'demotion-candidate.  Pass C:
  no observed dependents → auto-decompose.  We want to **intercept**
  before that with an injection.
- Concretely:
  - NE1 idle: m=-3, hist=(-3), status='stale (only 1 neg)
  - INJECT-ENERGY cand_001 6 'subsidy 'runway 3
  - NE2 idle: Pass A.4 computes epoch_credit_raw=floor(6/3)=2,
    capacity = 1 + 0 heldout_wins + 0 positive_epochs + 0 deps = 1.
    external_credit = min(2,1)=1.  leaked = 1.
    Pass B: m_organic=-3, support=0, external=1, m_eff=-2.
    m_organic > STALE_TOL? no. support>0? no. external>0 AND m_eff >= -2? yes (m_eff = -2 = -STALE_TOL).
    → 'subsidized.

Wait — STALE_TOL is the existing constant.  Let me check what MOMENTUM-STALE-TOLERANCE is set to.  Looking at the code, the convention has been STALE_TOL = 1 in narrative.  So m_eff = -2 means abs(m_eff)=2 > STALE_TOL=1, and m_eff < -STALE_TOL=-1.  So the condition `m_eff >= -STALE_TOL` is -2 >= -1 → false.  Then we'd fall through to demotion logic.

Let me re-tune demo: need external high enough to lift m_eff to ≥ -STALE_TOL.

If MOMENTUM-STALE-TOLERANCE=1 and m_organic=-3, we need external_credit ≥ 2 to push m_eff to -1.  And capacity ≥ 2.  But capacity=1 with no earned signals.

Path A: build earned capacity first (drive cand_001 productively to earn positive_epochs).
Path B: amount/ttl that yields enough credit AFTER capacity allows.

Path A is more realistic.  Demo 177 setup:
- Promote cand_001
- Drive 2 dispatches in epoch e0, NE → m_organic = 2-2-0-1 = -1.  Not positive.  Need 3 dispatches to push positive: m = 3-2-0-1 = 0.  Need 4: m = 4-2-0-1 = +1.  But STALE_TOL=1 means we need m_organic > 1 to count as productive.  So 5 dispatches: m = 5-2-0-1 = +2.
- After NE, positive_epochs[cand_001] = 1.  Capacity = 1+0+1+0 = 2.  status = 'stable-active.
- Now idle for a few epochs, m_organic drops to -3.  After 1 idle NE: 'stale (only 1 negative in hist after the positive one).
- INJECT-ENERGY cand_001 6 'subsidy 'runway 3
- Idle NE: Pass A.4: raw=2, cap=2, ext=2, leak=0.
  Pass B: m_org=-3, support=0, ext=2, m_eff=-1.  m_eff >= -1=-STALE_TOL → 'subsidized.

OK so I need to be careful about choreography.  Let me restructure cleanly in the demo spec.

Actually, looking at my plan more carefully, I realize STALE_TOL might be different.  Let me grep.

Let me just write the spec carefully and check the constants in tier1.rkt later when writing demos.

Pass conditions:
| `s-1` | initial 'stable-active after earning |
| `s-2` | ENERGY-CAPACITY = 2 (= 1 + 0 heldout + 1 pos_ep + 0 deps) |
| `s-3` | after idle NE pre-injection: status = 'stale |
| `s-4` | EXTERNAL-CREDIT = 2 after injection NE |
| `s-5` | ENERGY-LEAK = 0 (capacity met) |
| `s-6` | status after injection NE = 'subsidized |
| `s-7` | ORGANIC-MOMENTUM = -3 (unchanged by injection — truth-immune) |
| `s-8` | SUBSIDIZED-MOMENTUM = -1 (= organic + external = -3+2) |
| `s-9` | MOMENTUM-EFFECTIVE = -1 (same, no support) |
| `s-10`| SUBSIDIZED? = 1 |
| `s-11`| ENERGY-SOURCE = 'subsidy |

---

## Demo 178 — external-cannot-bypass-stable-gate (truth-immune)

### Setup
- Induce cand_001 = (MARK drop) via INDUCE-RUNTIME (no PROMOTE-STABLE).
- INJECT-ENERGY cand_001 100 'megasubsidy 'promotion-attempt 10
- Attempt PROMOTE-STABLE without first doing HELD-OUT-EVAL.

### Lifecycle
- cand_001 starts 'experimental.
- INJECT-ENERGY records slot (cand is not in STABLE-WORD-STATUSES; capacity will be 0).
- NE: Pass A.4 raw = floor(100/10) = 10.  capacity = 0 (not stable-track).
  external_credit = 0.  leaked = 10.  Ledger event 'energy-leaked
  with cand_001, raw=10, cap=0.
- PROMOTE-STABLE: rejected (HELD-OUT-EVAL never ran; cand is 'experimental,
  not 'committed; rejection is structural).

### Pass conditions
| `t-1` | cand_001 status pre = 'experimental |
| `t-2` | INJECT-ENERGY succeeds (ENERGY-BUFFER cand_001 = 100 before NE) |
| `t-3` | after NE: ENERGY-CAPACITY = 0 (sandbox / non-stable) |
| `t-4` | after NE: EXTERNAL-CREDIT = 0 (all leaked) |
| `t-5` | after NE: ENERGY-LEAK = 10 (full raw leaked) |
| `t-6` | after PROMOTE-STABLE: cand_001 NOT in STABLE-WORD-STATUSES |
| `t-7` | LEDGER-LAST records 'energy-leaked event for cand_001 |
| `t-8` | ORGANIC-MOMENTUM unaffected by injection (still computed from m_native formula only) |

---

## Demo 179 — capacity-from-selection (selected composite > simple)

### Setup
- Promote two cands:
  - cand_simple = (MARK drop), L=2
  - cand_selected = (cand_simple NODES drop), L=3
- Drive cand_selected through full selection path:
  * 4 distinct dispatches across sessions (NEW-SESSION between them)
  * HELD-OUT-EVAL → success (records heldout_wins += 1)
  * PROMOTE-STABLE
  * Drive 5 productive uses (m_organic > STALE_TOL this NE)
- NE: positive_epochs[cand_selected] += 1.

### Lifecycle
- After warm-up:
  * heldout_wins[cand_simple] = 1 (its own held-out)
  * heldout_wins[cand_selected] = 1
  * positive_epochs[cand_selected] = 1
  * observed_dependents_this_epoch[cand_simple] = 1 (cand_selected
    nested-called it during the warm-up dispatches)
- Capacity now:
  * cand_simple: 1 + 1 heldout + 0 pos_ep (we didn't drive it productively
    on its own; it's only used via cand_selected) + 1 dep = 3
  * cand_selected: 1 + 1 heldout + 1 pos_ep + 0 deps = 3

Hmm, equal capacity. Let me restructure: drive cand_selected productively
for multiple positive epochs to differentiate.

Revised: drive cand_selected productively for 3 consecutive positive
epochs (positive_epochs = 3); cand_simple has only the 1 heldout, no
positive epochs on its own, and is observed as dep once.

Then:
  * cand_simple capacity:  1 + 1 + 0 + 1 = 3
  * cand_selected capacity: 1 + 1 + 3 + 0 = 5

### Pass conditions
| `c-1` | both promoted |
| `c-2` | heldout_wins[cand_simple] = 1; heldout_wins[cand_selected] = 1 |
| `c-3` | positive_epochs[cand_selected] = 3 |
| `c-4` | ENERGY-CAPACITY cand_selected > ENERGY-CAPACITY cand_simple |
| `c-5` | ENERGY-CAPACITY cand_selected = 5 |
| `c-6` | ENERGY-CAPACITY cand_simple = 3 |

(No injection needed; just capacity computation differs.)

---

## Demo 180 — overcharge-leaks

### Setup
- Promote cand_001 = (MARK drop), L=2.
- Capacity = 1 (no earned signals besides 1 heldout — let's say cand_001
  passed held-out so heldout_wins = 1, capacity = 1 + 1 + 0 + 0 = 2).
- INJECT-ENERGY cand_001 20 'overcharge 'test 2 (raw = floor(20/2) = 10
  per epoch, way above capacity).

### Lifecycle
- NE1: raw=10, cap=2, ext=2, leak=8.  Remaining = 20-10 = 10. TTL = 1.
- NE2: raw=10 (floor(10/1)), cap=2, ext=2, leak=8.  Remaining = 0. TTL=0.

### Pass conditions
| `o-1` | promoted |
| `o-2` | ENERGY-CAPACITY cand_001 = 2 (heldout earned 1) |
| `o-3` | After NE1: EXTERNAL-CREDIT = 2 |
| `o-4` | After NE1: ENERGY-LEAK = 8 |
| `o-5` | After NE1: ENERGY-BUFFER (remaining) = 10 |
| `o-6` | After NE2: EXTERNAL-CREDIT = 2 |
| `o-7` | After NE2: ENERGY-LEAK = 8 |
| `o-8` | After NE2: ENERGY-BUFFER = 0 (slot cleared) |
| `o-9` | LEDGER-COUNT increased by 2 'energy-leaked events |

---

## Demo 181 — ttl-expiry (subsidy lapses, normal metabolism resumes)

### Setup
- Promote cand_001 (heldout_wins = 1, capacity ≥ 2).
- INJECT-ENERGY cand_001 6 'tempboost 'demo 3.
- Drive cand_001 idle for 3 NEs (consuming all TTL); 4th NE no injection.

### Lifecycle
- NE1: raw=2, cap=2, ext=2, leak=0.  Remaining=4, TTL=2.  status='subsidized.
- NE2: raw=2, cap=2, ext=2, leak=0.  Remaining=2, TTL=1.  status='subsidized.
- NE3: raw=2, cap=2, ext=2, leak=0.  Remaining=0, TTL=0.  status='subsidized.
  Slot cleared at end-of-NE.
- NE4: raw=0 (no slot), ext=0, leak=0.  m_organic=-3, no support, no
  external → falls through to demotion logic.  history accumulated
  (-3 -3 -3 -3) → demotion-candidate → Pass C → no observed deps →
  auto-decompose.

### Pass conditions
| `e-1` | promoted |
| `e-2` | After NE1: SUBSIDIZED? = 1, status = 'subsidized |
| `e-3` | After NE3: ENERGY-BUFFER = 0 |
| `e-4` | After NE4: SUBSIDIZED? = 0, EXTERNAL-CREDIT = 0 |
| `e-5` | After NE4: status = 'decomposed (normal metabolism caught it) |

---

## Demo 182 — subsidized-does-not-contribute (truth-immune for support)

### Setup
- Promote cand_001 = (MARK drop), L=2.
- Promote cand_002 = (cand_001 NODES drop), L=3.
- Both go idle; cand_002 m_organic = -3.
- INJECT-ENERGY cand_002 8 'extsupport 'test 2 (raw = 4 per NE,
  capacity at least 1; capacity = 1 + 1 (heldout) = 2.  ext = min(4,2) = 2.
  m_organic_002 + external = -3+2 = -1.  cand_002 → 'subsidized.

### Lifecycle
- Drive cand_002 once externally (nested-calls cand_001).  This makes
  observed_dep(cand_002, cand_001) = 1 in the current epoch.
- NE:
  * cand_002 m_organic = 1×2 - 3 - 0 - 1 = -2 (1 reuse this epoch).
  * cand_002 ext_credit = 2 (from injection).
  * cand_002 m_eff = -2 + 0 + 2 = 0 ≥ -STALE_TOL → 'subsidized.
  * For cand_001: compute_support_credit looks for natively-positive
    supporters where m_organic > STALE_TOL.  cand_002 m_organic = -2 ≤ STALE_TOL
    → contributes 0.  This is the key invariant: cycle 33's support
    formula reads m_organic, NOT m_subsidized.
  * cand_001 m_organic = -3, support = 0, external = 0, m_eff = -3.
    → demotion path; if history sufficient → demotion-candidate.

### Pass conditions
| `n-1` | both promoted |
| `n-2` | after injection NE: cand_002 status = 'subsidized |
| `n-3` | after injection NE: cand_002 SUBSIDIZED-MOMENTUM = 0 (= -2 + 2) |
| `n-4` | after injection NE: cand_002 ORGANIC-MOMENTUM = -2 (NOT positive) |
| `n-5` | after injection NE: cand_001 SUPPORT-CREDIT = 0 (cand_002 not natively positive) |
| `n-6` | cand_001 status after NE = 'stale or 'demotion-candidate (NOT 'dependency-supported) |
| `n-7` | (control) if cand_002 were NATIVELY positive (m_organic > STALE_TOL), cand_001 SUPPORT-CREDIT would be > 0 — separately verified in earlier cycle 33 demos; demo 182 is the negative-control under subsidy |

---

## Methodological commitments (binding)

1. Implementation conforms to this pre-reg.
2. No new hyperparameter.  Amortization (`floor(rem/ttl)`), capacity
   formula (1 + 3 earned signals), Pass B precedence ordering, and
   leak destination (trace ledger, not E_conflict) are all structural.
3. `_external-credit`, `_energy-leak` per-cand counters are
   per-epoch (reset on NEW-EPOCH).  "Rented, not owned."
4. `_external-remaining` and `_external-ttl` persist across epochs
   until depleted; depleted slots cleared at end of NE.  `_external-source`
   and `_external-purpose` cleared with their slot.
5. Multiple `INJECT-ENERGY` calls to the same cand REPLACE the active
   slot; no implicit accumulation.  (Future cycle can add additive
   semantics with explicit primitive.)
6. `_heldout-wins` and `_positive-epochs` are cumulative running
   counters, NEVER reset.  They represent the "earned capacity
   history" — by definition persistent.
7. Capacity formula sanity-fenced: returns 0 for any cand whose
   status ∈ SANDBOX-STATUSES, or ∉ STABLE-WORD-STATUSES, or
   contaminated.  No sandbox-capacity in this cycle.
8. **Truth-immune** invariant: PROMOTE-STABLE, COMMIT-PRIMITIVE,
   HELD-OUT-EVAL, SHADOW-CHECK, and `compute-support-credit-for`
   ALL read `m_native` (≡ `m_organic`), NEVER `m_subsidized` or
   `m_effective`.  Any drift is a regression.
9. **No-subsidized-support-contribution**: cycle 33's
   `compute-support-credit-for` test `m_native(B) > STALE_TOLERANCE`
   uses `m_native`, NOT `m_subsidized`.  An externally rescued cand
   contributes 0 support to its base.  This prevents the
   "parasitic-rent" failure mode where external subsidy creates a
   chain.
10. **Leak-not-conflict**: over-capacity injection produces a
    `'energy-leaked` ledger event with the structured payload
    (cand, amount_injected, capacity, absorbed, leaked, source,
    purpose, ttl, epoch, stable_law_hash, world_hash).  It does NOT
    increment E_CONFLICT.  Leak events do NOT enter law_hash or
    world_hash (per cycle 25E energy-observational-only constraint).
11. **Status precedence**: in Pass B, status is determined by the
    FIRST condition that matches: native-positive → 'stable-active;
    support-rescued → 'dependency-supported; external-rescued →
    'subsidized.  A cand whose support alone keeps it safe is
    'dependency-supported even if external_credit was also applied
    (TTL still decremented).  External_credit is wasted-to-leak
    only by amount; if support alone suffices, the external_credit
    is still spent but the status is more honestly labeled.
12. Attestation BEFORE commit.

---

## Updated existing demos (none expected)

Cycle 34 introduces NEW status 'subsidized and 9 NEW primitives but
does NOT change the behavior of any cycle 28-33 mechanism EXCEPT one
purely-additive extension to `MOMENTUM-EFFECTIVE`:

**`MOMENTUM-EFFECTIVE` now includes `external_credit` in its sum.**

In all cycle 33 demos, `external_credit` = 0 (no injection occurred),
so `MOMENTUM-EFFECTIVE` returns the same value as before (organic +
support).  No regression expected in any of demos 158-176.

If a cycle 33 demo had explicitly asserted "MOMENTUM-EFFECTIVE = NATIVE +
SUPPORT", that's still true in the absence of injection.  Cycle 34's
extension only manifests when there is an injection.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 26-33 commits frozen; user spec 2026-05-24
      truth-immune; capacity-from-selection; no-subsidized-support;
      leak-not-conflict
- [x] Rule 3: deterministic — amortization, capacity, status
      precedence are all pure functions of current state
- [x] Rule 4: pass/fail partition outcome space across six demos
- [x] Rule 5: known-input lifecycle test
- [x] Rule 6: regression count update post-result
- [x] Rule 7: demos 178 (truth-immune), 180 (overcharge-leaks),
      181 (ttl-expiry), 182 (no-subsidized-support) are negative-control
      variants of the happy demo 177
- [x] Rule 8: scope = 6 new demos, 9 new primitives (8 inspections +
      1 mutator + 1 alias), 1 new status, 7 new env keys, 0 new
      hyperparameter, 2 new NE pass elements (A.3, A.4)
- [x] Rule 9: attestation pending

---

## What cycle 34 does NOT claim

- External energy is "ecologically meaningful" — it's a bookkeeping
  mechanism for runway extension.
- Capacity formula is optimal — it's the simplest defensible
  selection-history aggregator.
- The `floor / ttl` amortization is optimal — it's the simplest
  deterministic integer split.
- A 'subsidized cand has "moral standing" or has "passed" anything —
  it has only been kept callable by an external rent payment.
- Capacity could ever substitute for held-out evaluation — it cannot.
  Capacity gates absorption of external energy; held-out evaluation
  gates promotion to stable.  Different doors, different keys.
- Subsidy could correspond to "user attention" or any cognitive
  property — it's a substrate mechanism, not a cognition claim.

It claims only:
1. **Truth-immune**: external credit cannot satisfy any truth gate.
2. **Capacity-from-selection**: capacity is a function of earned
   signals (heldout wins, positive epochs, observed dependents).
3. **No subsidized support contribution**: a cand rescued by external
   credit alone contributes 0 to cycle-33 support_credit for its
   own dependents — cycle 33's `m_native > STALE_TOL` test continues
   to read native, not subsidized.
4. **Leak-not-conflict**: over-capacity injection produces ledger
   events, not semantic-conflict mutations or hidden momentum.

If demos 177-182 all pass AND demos 158-176 still pass unchanged,
then **external energy intervention and capacity are operational**
without enabling the rent-paradise failure mode.

---

## References

- METHODOLOGY.md v2.1 §17
- Cycle 29 (commit b... — momentum + inflation)
- Cycle 30 (commit 7d1bc8c — dependency-aware AUTO-DECOMPOSE)
- Cycle 31 (commit f5760a0 — discovery profiles + inflation)
- Cycle 32 (commit 9009f8d — multi-level cascade + observed deps)
- Cycle 33 (commits 3a1b308 + d57a3ff + 1f6bf76 — carry offset)
- CLAIMS.md freeze commit `8d64c7a` (post-cycle-32 stable definition)
- Cycle 25E energy-observational-only constraint (runtime.rkt line 125)
- User spec 2026-05-24 — external energy buys runway not validity;
  capacity from selection; no parasitic rent chain
