# Demo 147 — Pre-Registered Predictions (cycle 26)

**Date pre-registered:** 2026-05-23

**Attested via** `scripts/attest_prediction.sh` per Rule 9.

---

## Numbering note

Per convention `PREDICTIONS-N.md` ↔ `demo-N.6th`.  Cycle 26 produces
TWO demos (happy + negative), so this pre-reg covers both: demo 147
(happy path) and demo 148 (negative path).  The user-spec earlier
referenced "PREDICTIONS-145" but those numbers were taken by cycles
25D (demo 145) and 25E (demo 146).  Re-numbered to next available.

---

## Cycle 26 claim

> A hand-crafted motif of expansion length 3 can be induced at
> runtime, used across N=5 successful dispatches **AND** M=3
> distinct runs, committed only after cumulative ΔE < 0, then
> passed through Tier 2 protocol as a known-input validation of
> meta-semantics plumbing.

This is **NOT** scientific signal about cognition.  It is
end-to-end validation of the protocol on a known input.  The
candidate is hand-chosen (`MARK MARK bi-edge` — same motif as
demos 143/145 for continuity).

Negative test ensures the energy gate actually GATES, not just
reports — a length-1 candidate must be rejected at COMMIT.

---

## Implementation activation (cycle 26 enables)

These cycle-25 gaps are now enforced in code:

1. **Energy gate enforcement** (was dry-run in cycle 25E):
   `COMMIT-PRIMITIVE` raises when `net_delta_e >= 0`.  Pre-commit
   continues to write the dry-run record to ledger for forensic.

2. **M=3 distinct runs** (was in-process only):
   Per-cand tracks distinct `session_id`s seen by the dispatch hook.
   `COMMIT-PRIMITIVE` checks `len(distinct_sessions) >= COUPLING-M`.

3. **`NEW-SESSION` testing primitive**:
   Increments stored session_id deterministically.  Used to
   simulate "process restart" within one demo run.  Marked
   test-only via comment (cycle 27+ replaces with cross-process
   persistence layer).

4. **`WRAP-MOTIF` helper**:
   `( sym -- list )` — single-symbol motif construction for negative
   demo (DETECT-MOTIF requires MIN_LEN=2; we bypass for known-input
   negative test).

---

## Happy-path demo (demo 147)

### Setup
- Motif: `MARK MARK bi-edge` (expansion length L=3)
- Required coupling: N=5 uses, M=3 distinct sessions
- Required energy: cumulative net_delta_e < 0

### Trace

```
RESET
LAW-HASH "h0" store
\ Session 1: detect + induce
MARK MARK bi-edge × 3
DETECT-MOTIF → motif (MARK MARK bi-edge)
SHADOW-CHECK → 1, cert recorded
INDUCE-RUNTIME → cand_001
LAW-HASH "h1" store, must differ from h0
NEW-SESSION
\ Session 2: 2 uses
cand_001 cand_001
NEW-SESSION
\ Session 3: 3 uses → total N=5
cand_001 cand_001 cand_001
\ Check coupling + energy
CAND-USES → 5
CAND-DISTINCT-SESSIONS → 3
E-REUSE-GAIN bumped by 5 × (3-1) = 10
E-LAW = 3 (one active cand body length 3)
net_delta_e = E_law_at_induce(3) - reuse_gain(10) = -7
COMMIT-PRIMITIVE → cand_001 (success), status 'committed
FREEZE-CANDIDATE → cand_001 (stub passes)
```

### Pass conditions (ALL must hold)

| condition | predicate |
|-----------|-----------|
| `c-1` motif detected | DETECT-MOTIF returned `(MARK MARK bi-edge)` |
| `c-2` shadow cert | SHADOW-CHECK = 1; SHADOW-CERT-OF = 'pass |
| `c-3` law mutation | LAW-HASH differs after INDUCE |
| `c-4` use counter N=5 | CAND-USES = 5 after 5 dispatches |
| `c-5` distinct sessions M=3 | CAND-DISTINCT-SESSIONS = 3 |
| `c-6` ΔE < 0 | net_delta_e = 3 - 10 = -7 |
| `c-7` COMMIT succeeds | COMMIT-PRIMITIVE returns cand-sym, status 'committed |
| `c-8` FREEZE stub passes | FREEZE-CANDIDATE returns cand-sym |
| `c-9` no contamination | CAND-STATUS != 'contaminated |
| `c-10` ledger has commit | LEDGER-LAST starts with 'commit-primitive |
| `c-11` HELD-OUT stays conservative | HELD-OUT-EVAL = 0 (stub gate still closed) |
| `c-12` regression green | tests/examples-test.rkt 2NNN/2NNN passes |

### Fail conditions (ANY of these = test failure)

| condition | meaning |
|-----------|---------|
| `f-1` COMMIT succeeds with N<5 | coupling broken |
| `f-2` COMMIT succeeds with M<3 | distinct-session check broken |
| `f-3` COMMIT succeeds with ΔE >= 0 | energy gate broken |
| `f-4` LAW-HASH unchanged after INDUCE | runtime mutation broken |
| `f-5` WORLD-HASH changed by pure law mutation | separation broken |
| `f-6` USE counter bumps without real dispatch | hook broken |
| `f-7` E-* call mutates law_hash or world_hash | inspection trap |
| `f-8` PROMOTE-STABLE succeeds without held-out | stable gate broken |

---

## Negative-path demo (demo 148)

### Setup
- Motif: single symbol `MARK` (expansion length L=1)
- Constructed via `' MARK WRAP-MOTIF` (single-element list)
- Required coupling: still N=5, M=3
- Expected energy: reuse_gain = 5 × (1-1) = 0; net = 1 - 0 = 1 ≥ 0

### Trace

```
RESET
' MARK WRAP-MOTIF "m-len1" store
"m-len1" load SHADOW-CHECK → 1 (single MARK is allowed; not in FORBIDDEN-IN-MOTIF)
"m-len1" load INDUCE-RUNTIME → cand_NNN
\ Spread N=5 uses across M=3 sessions
cand_NNN
NEW-SESSION cand_NNN cand_NNN
NEW-SESSION cand_NNN cand_NNN
\ Coupling now passes BUT energy fails
COMMIT-PRIMITIVE → must RAISE (caught at top level)
\ Test that the raise happened: status is still 'ephemeral-active
\ (not promoted to 'committed)
```

### Pass conditions (ALL must hold)

| condition | predicate |
|-----------|-----------|
| `nc-1` length-1 motif induces | INDUCE-RUNTIME succeeds (motif is non-empty) |
| `nc-2` coupling reached | CAND-USES = 5, CAND-DISTINCT-SESSIONS = 3 |
| `nc-3` reuse_gain = 0 | E-REUSE-GAIN delta = 0 (length 1 saves nothing) |
| `nc-4` COMMIT raises | wrapped in handler; status remains 'ephemeral-active |
| `nc-5` ledger records rejection | dry-run row written with would-pass=false |
| `nc-6` clean rollback | ROLLBACK-RUNTIME restores law_hash |

### Fail conditions

| condition | meaning |
|-----------|---------|
| `nf-1` COMMIT succeeds with length-1 | energy gate inactive |
| `nf-2` length-1 INDUCE fails | over-aggressive filter |
| `nf-3` reuse_gain != 0 | reuse_gain formula wrong |

---

## Methodological commitments (binding)

1. Scripts written AFTER this file committed.
2. Run AFTER both committed.
3. Result reported regardless of outcome.
4. Hyperparameters frozen at cycle 25C (mining_protocol.md):
   `COUPLING-N=5`, `COUPLING-M=3`, `MOTIF_MAX_LEN=5`.
5. Energy formula frozen at cycle 25E (META-SEMANTICS.md §17).
6. `NEW-SESSION` is test-only primitive (not part of production
   discovery flow).  Cycle 27 replaces with cross-process
   session persistence and removes NEW-SESSION from the API.
7. `WRAP-MOTIF` is test-only primitive for known-input negative
   construction (DETECT-MOTIF cannot produce length-1 motifs per
   MIN_LEN=2).  Stays in the API as a generic motif-construction
   helper.
8. Attestation BEFORE commit.

---

## Compliance with METHODOLOGY.md

- [x] Rule 1: file BEFORE source
- [x] Rule 2: cycle 25A-E (commits 34cad87, 2421e0f, b660eb5, 78143cf,
      67cab83) frozen reference; META-SEMANTICS.md v2.1 (commit
      67cab83) sets energy formula; mining_protocol.md (commit b660eb5)
      sets coupling N=5, M=3
- [x] Rule 3: deterministic given fixed PRNG and session policy
- [x] Rule 4: pass/fail partition specified per demo
- [x] Rule 5: known-input validation (NOT empirical signal)
- [x] Rule 6: regression count update post-result
- [x] Rule 7: negative demo provides falsification of the gate
- [x] Rule 8: scope = TWO demos, single motif each, fixed coupling
      + energy parameters; no tuning post-hoc
- [x] Rule 9: attestation pending

---

## What this cycle does NOT claim

- It does NOT claim Sixth discovered a useful primitive.
- It does NOT claim the protocol generalizes to automated discovery
  (that is cycle 27).
- It does NOT claim energy v0 is the right loss for cognition.
- It does NOT make any empirical scientific claim.

It claims only: **the protocol, end-to-end, accepts a hand-crafted
candidate that meets coupling + energy gates AND rejects a
hand-crafted candidate that meets coupling but fails the energy
gate.**

If both demos pass per their pass-conditions, the meta-semantics
plumbing is end-to-end validated.  If either fails, that's a bug
in cycle 25 implementation that must be fixed before cycle 27
automated discovery becomes meaningful.

---

## References

- META-SEMANTICS.md v2.1 (commit 67cab83) — protocol normative spec
- mining_protocol.md (commit b660eb5) — frozen hyperparameters
- Cycle 25A-E commits — runtime plumbing
- User spec (2026) 2026-05-23 — cycle 26 must be narrow, hand-crafted
  validation with both happy and negative paths
- Lakatos (1970) — protocol changes here use "additive amendment"
  rule from META-SEMANTICS §0 modeled on Lakatos's distinction
  between hardcore and protective belt of a research programme
- Goodhart (1975) — energy gate enforcement is the operational
  Goodhart defense for "primitive should reduce runtime cost"
