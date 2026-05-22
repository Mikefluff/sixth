# EICS Application to Sixth Substrate

**Date:** 2026-05-22 (cycle 13B)

**Source method:** Krasnovsky, "Measuring Uncertainty in Transformer
Circuits with Effective Information Consistency", arXiv:2509.07149
(September 2025).

**Purpose:** apply the only published computational-consciousness
measurement methodology (EICS) to Sixth hypergraph rewriting
substrate.  This is cycle 13's final attempt to find a
substrate-distinguishing measurement; if EICS also reduces to
classical, Sixth finalizes as engineering contribution.

---

## EICS algorithm (extracted from arXiv 2509.07149)

EICS combines two components on a computational circuit
(V, E, activations a, Jacobians ρ):

### 1. Sheaf inconsistency C_sh

Cellular sheaf 𝓕 on undirected skeleton:
- Stalks 𝓕(v) = ℝ^(d_v) (activation space at node v)
- Restriction maps (Jacobians) ρ_(u→v) = ∂f_v / ∂a_u |_a

Coboundary on 0-cochain {s_v}:
```
(δ⁰s)_(u→v) = ρ_(u→v) s_u - s_v
```

Normalized inconsistency energy:
```
C_sh = √(Σ_(u→v)∈E ‖ρ_(u→v) a_u - a_v‖²) / 
       √(Σ_(u→v)∈E ‖a_u‖² + ‖a_v‖²)
```

Zero iff activations are a globally consistent section under
local linearizations.

### 2. Gaussian EI proxy

Linear Gaussian model:  y = J·x + ξ, with α := σ_x² / σ_ξ²

```
EI_G(J) := (1/2) log det(I + α J^T J)
```

Δ_EI captures circuit-level emergence vs sum of local:
```
Δ_EI := EI_G(J_macro) - Σ_v EI_G(J_v)
Δ̃_EI := max(0, Δ_EI) / (ε + EI_G(J_macro))    ∈ [0, 1)
```

### 3. Combination

```
EICS = Δ̃_EI / (1 + C_sh)
```

Higher EICS = strong circuit-level emergence + low internal
inconsistency = coherent circuit.

---

## Adaptation for Sixth substrate

Sixth substrate is symbolic-rewrite, not differentiable.  Three
adaptation choices needed:

### A1. Jacobian definition

For Sixth substrate (V, E_bi, H_3) with feature vector
a ∈ ℝ^|V| (NSET features), define linear "Jacobian" via
substrate's NSUM-update rule:

```
J[u, v] = 1 if (u, v) ∈ E_bi (bi-edge contribution)
       = 1 if (u, v, _) ∈ H_3 (any HEDGE3 with v as 1st arg, u as some leg)
       = 0 otherwise
```

This is the adjacency matrix (directed sum) of substrate's
out-edge structure.  NSUM_v(features) = Σ_u J[u,v] × features[u] —
the EICS Jacobian corresponds exactly to substrate's NSUM.

### A2. Activations a

Use NSET features at evaluation time.  For canonical-substrate
tests: features set to OUT(v) (matches cycle 10C/11A
phi-integ semantics).

### A3. Circuit topology

Sixth substrates are directed graphs (bi-edges + HEDGE3).
EICS expects DAG; we relax to general directed graph.  This is
non-standard but defensible because EICS formula doesn't
explicitly require acyclicity — it requires Jacobian-and-
activation pair, computable on any directed graph.

---

## Cycle 13C target metrics

For each test substrate S:
- compute C_sh(S, a)
- compute EI_G(J_macro) where J_macro = adjacency
- compute Σ_v EI_G(J_v) where J_v = "local Jacobian" = row/column for v
- compute Δ̃_EI and EICS

For comparison: matched random ER baselines of same n, p.

---

## Pre-registered prediction approach (PREDICTIONS-132.md)

To make this falsifiable: pre-register `R = EICS_substrate / EICS_random_baseline`
ratio expectations.

If R ≈ 1.0 across many substrate configurations: substrate EICS
indistinguishable from random.  Conjecture 1 (Φ-family classical)
extended to EICS — null finding.

If R > 1.5: substrate has higher EICS than random — first
substrate-distinguishing signal found by Sixth project.

If R < 0.5: substrate has lower EICS than random — substrate
is LESS coherent than random graphs, surprising and worth
investigating.

Exact regime boundaries committed in PREDICTIONS-132.md.

---

## Implementation plan

`scripts/eics_sixth.py`:
- Functions: `compute_sheaf_inconsistency`, `compute_ei_proxy`,
  `compute_eics` (all per Krasnovsky 2509.07149 formulas)
- Substrate input: JSON-serialized Sixth substrate state (n_nodes,
  edges as adjacency, NSET features)
- Run on canonical substrates (10 hand-designed) + random ER
  baselines (M=1000) of matched size
- Report mean EICS per substrate class, regime classification

Reproducible: numpy random seed = 12345.

---

## What this CANNOT establish

Even if EICS shows substrate-distinguishing signal at small n,
this does not establish consciousness measure validity.  EICS
is a coherence-of-computation measure, not a consciousness
measure.  Krasnovsky's paper proposes EICS as a circuit
uncertainty quantification tool — not as Φ.

Cycle 13C result interpretation:
- EICS_substrate > EICS_random → substrate has more coherent
  computational structure than random graph; INFORMATIVE
- ≠ → "substrate is conscious"

---

## Methodological compliance

- Rule 1: this doc before script
- Rule 2: Krasnovsky 2509.07149 cited
- Rule 3: M ≥ 1000 baseline ensembles
- Rule 4: regimes partition without gap (per PREDICTIONS-132.md)
- Rule 5: cycle 14+ should cross-validate at larger n
- Rule 6: aggregate count updated post-result
- Rule 7: EICS is NOT a tautology — it's derived from sheaf
  theory + Gaussian information geometry; output values are NOT
  predictable from substrate adjacency alone (depend on activations)
- Rule 8: scope claim limited to n ≤ 20 canonical + random ER
- Rule 9: attestation via attest_prediction.sh BEFORE commit
