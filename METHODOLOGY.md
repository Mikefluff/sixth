# Substrate Research Methodology

Methodological commitments for the research-track demos (105–
N).  Built incrementally from CS-doctor retrospectives across
cycles 1–9; consolidated here after cycle 10A.

This file is **binding for all PREDICTIONS-N.md and demo N
authoring** going forward.  Violations of these rules must be
called out in the cycle's RESULTS.md section.

---

## Rule 1 — Pre-registration in git BEFORE source

For any cycle making a quantitative claim against an external
reference (classical theory, independent implementation):

1. Write `examples/PREDICTIONS-N.md` with:
   - Theoretical basis with literature citations (Rule 2)
   - Specific predicted values with quantitative bounds
   - Hypothesis structure (H0 / H1 explicit)
   - Falsification rules (what each outcome would mean)
   - Author guess (subjective, recorded for honesty)
2. **Commit this file alone.**  Note its commit hash.
3. Then write the demo source.  Commit demo source alone.
4. Then run the demo.  Commit measurement results + pins.

Git timestamps prove the chronology to any reader who clones
the repo.  Force-pushing this branch is forbidden after a
pre-registration cycle starts; if a force-push is required, an
`attestations/` entry with the original hash must remain.

**Why:** verified by cycle 8 → cycle 9 → cycle 10A.  Discipline
caught real bugs (cycle 8 formula error, cycle 9 weak claim).
Without it, retracts would be invisible.

## Rule 2 — Literature review BEFORE pre-registration

Cycle 8 failed this rule and produced a retracted "finding".
Lesson: any PREDICTIONS-N.md formula must cite at least one
peer-reviewed reference confirming the formula's validity in
the tested regime.

For random-graph / percolation work:
- Bollobás, *Random Graphs* (2nd ed., 2001)
- Janson, Łuczak, Ruciński, *Random Graphs* (2000)
- Newman, Strogatz, Watts (2001) — generating functions
- van der Hofstad, *Random Graphs and Complex Networks*
  (2017, vol. 1)

For percolation / phase transitions:
- Grimmett, *Percolation* (2nd ed., 1999)
- Stauffer, Aharony, *Introduction to Percolation Theory*
  (2nd ed., 1994)

For asymptotic formulas: explicitly note whether tested regime
(n, c) is within the formula's domain of validity.  Specifically
for `E[|C(v)|] = n·f² + (1-f)/(1-c(1-f))`: valid for n → ∞;
near c = 1 (critical), finite-n corrections are large (O(n^(-1/3))
fluctuations per Bollobás Ch. 6).

If the tested regime is OUTSIDE a formula's validity, use an
independent Monte Carlo reference (cycle 9 pattern) instead of
the asymptotic formula.

**Why:** cycle 8's asymptotic-formula was a textbook mistake
caught by cycle 9's independent reference.  A 5-minute lit
check would have prevented it.

## Rule 3 — Sample size discipline

Single-cycle measurements at M < 1000 produce SEM too wide to
detect small (3–10%) systematic deviations.  Any claim of
"within 1σ" using M < 1000 must explicitly note that the test
is sample-size-limited.

For substrate-vs-reference fidelity tests at the precision of
~3%, **M ≥ 1000 substrate samples are required**.

Reference Monte Carlo (Python / networkx) should run at M ≥ 10×
the substrate's M (cycle 9 pattern: substrate M=100 → reference
M=1000–10000).  This makes the reference statistical noise
negligible compared to substrate noise.

When sub-prediction SEM bound is violated, **pre-registration
must include an escalation rule** (cycle 9 pattern: SEM > 2000
at M=1000 → escalate to M=10000).  No post-hoc escalation.

**Why:** cycle 9 claimed "substrate within 1σ" at M=100 — the
1σ was 6,270 wide, easily hiding a real 4,351 systematic bias.
Cycle 10A at M=1000 cross-validated by shrinking SEM to 2,170
and confirming the difference (1,429) was indeed noise.

## Rule 4 — Regime partitions without gaps

`PREDICTIONS-N.md` regime classifiers must **partition** the
outcome space without gaps.  Any "regime C — other" allowing
ambiguous outcomes creates an unintentional escape hatch.

Cycle 9 used gap of 5,000 between regimes A and B (115k–120k),
giving me a partial escape if reference landed there.  Cycle 10A
fixed this with adjacent boundaries (D: ≤128,500; E: > 128,500;
F: < 124,500 with D taking the joint boundary).

**Why:** ambiguous-outcome zones encourage post-hoc rationalisation.
Hard partitions force a regime call.

## Rule 5 — Cross-validation at higher precision

A finding that survives at M=100 must be re-tested at M ≥ 1000
in a subsequent cycle BEFORE being elevated to a "cross-validated"
finding in RESULTS.md.

Cycle 8 → cycle 10A pattern:
- Cycle 8: weak claim at M=100 with wide SEM
- Cycle 9: independent reference catches theory-side error
- Cycle 10A: substrate cross-validated at M=1000

**Two passes minimum** before a finding is "stable".  The
catalogue's reliability metric counts only cross-validated
findings.

## Rule 6 — Honest aggregate accounting

Each cycle must update an aggregate count in `RESULTS.md`:

- **Total claims made:** N
- **Survived cross-validation:** k
- **Retracted in subsequent cycle:** r
- **Pending cross-validation:** N − k − r

As of cycle 10A (this file's creation):
- Total claims: 9 (one per cycle 1–9)
- Cross-validated (survived ≥ 1 follow-up): 2
  (cycle 7 extensivity, cycle 10A substrate fidelity at n=20 p=10%)
- Retracted: 4 (cycle 1-3 demos by cycle 6, cycle 4-5 by cycle 6,
  cycle 7 phi-perc leak by self, cycle 8 deviation by cycle 9)
- Pending: 3 (cycle 6 infrastructure, cycle 9 ladder, cycle 10A
  itself not yet re-validated by a later cycle)

**Why:** without explicit accounting, the catalogue accretes
weak claims that read as strong (cf. cycle 8 RESULTS.md text
which read as "first binding finding" until cycle 9 retracted it).

## Rule 7 — Tautology detection

Before reporting a "positive finding", ask: is this a
substantive result or merely an implementation cross-check?

Cycle 9 reported "substrate is a faithful classical-ER
reachability implementation" — but phi-perc on bare ER graphs
is by construction `|connected_component(observer)| × L_max`
(per stdlib/phi.6th), and networkx computes the same logical
object.  Their agreement is a unit test of our BFS, not a
research finding.

This kind of result belongs in `tests/`, not in `RESULTS.md`'s
findings section.

A genuine substrate finding requires:
- Substrate computes something classical theory cannot easily
  predict (e.g. NSET-loaded substrate, multi-substrate composition)
- OR substrate diverges from classical reference (cycle 8's
  hoped-for outcome, which did not materialise)

## Rule 8 — Scope claims correctly

If only `n=20, p=10%` was measured, the claim is `n=20, p=10%`
— not "at finite n" or "across regimes".  Cycle 9 RESULTS.md
overstated this; cycle 10A constrains scope explicitly.

## Rule 9 — External attestation

Git-only pre-registration is verifiable by anyone who clones,
but force-push remains possible.  For external scientific
credibility:

1. Run `scripts/attest_prediction.sh PREDICTIONS-N.md` which
   appends a (timestamp, file, sha256) row to
   `attestations/ledger.txt`.
2. After each cycle, anchor the cumulative
   `attestations/ledger.txt` hash to an external timestamp
   authority (OpenTimestamps, public tweet, etc.).
3. The README links to the ledger and the latest anchor.

This makes force-push detectable: changing any pre-registration
would change a ledger hash that was externally anchored, and the
anchor proves the original content.

**Why:** required for "external pre-registration" status in
scientific publication.  Without it, our pre-registration is
psychological discipline, not credible-to-strangers commitment.

---

## Application checklist (use for every new PREDICTIONS-N.md)

- [ ] Rule 1: file committed before demo source, demo source
      committed before measurement
- [ ] Rule 2: at least one literature citation per formula
- [ ] Rule 2: explicit note on regime validity
- [ ] Rule 3: M ≥ 1000 for substrate; reference M ≥ 10× substrate M
- [ ] Rule 3: escalation rule for SEM bound violation
- [ ] Rule 4: regimes partition outcome space without gaps
- [ ] Rule 5: states whether this is first measurement or
      cross-validation of prior finding
- [ ] Rule 6: post-cycle RESULTS.md update includes aggregate
      claim count
- [ ] Rule 7: explicit "is this a tautology?" check
- [ ] Rule 8: claim scope matches measurement scope
- [ ] Rule 9: `scripts/attest_prediction.sh` run, ledger entry
      added

---

## Anti-patterns flagged in past cycles

| Pattern                                       | Cycle  | Resolution            |
|-----------------------------------------------|--------|-----------------------|
| Asymptotic formula at near-critical finite n  | 8      | Rule 2 (lit check)    |
| M=100 SEM claimed to "validate" 3% deviation  | 9      | Rule 3 (M ≥ 1000)     |
| Gap in regime partition                       | 9      | Rule 4 (no gap)       |
| "First finding" before cross-validation       | 8 → 9  | Rule 5 (two passes)   |
| "Faithful implementation" of own definition   | 9      | Rule 7 (tautology)    |
| "At finite n" from one n value                | 9      | Rule 8 (scope claim)  |
| Git-only pre-reg                              | all    | Rule 9 (attestation)  |

This list grows.  Each new anti-pattern observed in a CS-doctor
retrospective is added here AND incorporated as a Rule above.
