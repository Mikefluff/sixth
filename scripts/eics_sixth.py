#!/usr/bin/env python3
"""
EICS (Effective Information Consistency Score) applied to Sixth substrate.

Cycle 13C / PREDICTIONS-132.md (commit pending), EICS-HOOK.md.

Method: Krasnovsky (2025), arXiv:2509.07149.  Adapted for Sixth's
directed hypergraph substrate by using NSUM-adjacency as Jacobian
and NSET features as activations.

Pre-registered comparison:
  R_overall = mean(EICS_substrate) / mean(EICS_random)
  averaged across 10 canonical Sixth substrates vs matched ER baselines.

Regime classifier:
  R > 1.5      → REGIME R (substrate has substantially higher EICS)
  R ∈ [0.8, 1.5] → REGIME S (indistinguishable, substrate ≡ classical)
  R < 0.8      → REGIME T (substrate LESS coherent than random)
"""

import math
import statistics
from typing import Optional

import networkx as nx
import numpy as np


# ---------------------------------------------------------------
# EICS components per Krasnovsky (2025) formulas
# ---------------------------------------------------------------

def sheaf_inconsistency(adjacency: np.ndarray, activations: np.ndarray,
                         eps: float = 1e-8) -> float:
    """C_sh per arXiv:2509.07149 eq:

    C_sh = sqrt(Σ_(u→v)∈E ||ρ_(u→v) a_u - a_v||²) /
           (eps + sqrt(Σ_(u→v)∈E ||a_u||² + ||a_v||²))

    For Sixth: ρ_(u→v) = 1 if directed edge u→v exists, else 0.
    So ρ_(u→v) a_u = a_u when edge exists.  Residual = a_u - a_v.
    """
    n = len(activations)
    numer_sq = 0.0
    denom_sq = 0.0
    for u in range(n):
        for v in range(n):
            if adjacency[u, v] > 0:
                # ρ_(u→v) a_u - a_v = a_u - a_v (since ρ=1 when edge exists)
                residual = activations[u] - activations[v]
                numer_sq += residual * residual
                denom_sq += activations[u] ** 2 + activations[v] ** 2
    numer = math.sqrt(numer_sq)
    denom = eps + math.sqrt(denom_sq)
    return numer / denom


def ei_proxy(jacobian: np.ndarray, alpha: float = 1.0) -> float:
    """EI_G(J) = (1/2) log det(I + α J^T J).

    For square matrices use log det directly via eigenvalues.
    """
    n = jacobian.shape[1]
    M = np.eye(n) + alpha * (jacobian.T @ jacobian)
    # log det via slogdet for numerical stability
    sign, logdet = np.linalg.slogdet(M)
    if sign <= 0:
        return 0.0  # degenerate, treat as no information
    return 0.5 * logdet


def local_jacobian(adjacency: np.ndarray, node: int) -> np.ndarray:
    """For node v, local Jacobian is the row of adjacency for v's
    incoming edges (how v depends on its in-neighbors).  Returns
    a 1×n matrix.
    """
    return adjacency[:, node:node+1].T  # 1 × n


def eics(adjacency: np.ndarray, activations: np.ndarray,
         alpha: float = 1.0, eps: float = 1e-8) -> float:
    """EICS = Δ̃_EI / (1 + C_sh).

    Δ̃_EI = max(0, EI(J_macro) - Σ_v EI(J_v)) / (eps + EI(J_macro))
    """
    n = len(activations)
    if n == 0:
        return 0.0

    J_macro = adjacency.astype(float)
    ei_macro = ei_proxy(J_macro, alpha)
    if ei_macro < eps:
        return 0.0  # no macro-information; can't compute emergence

    ei_local_sum = sum(ei_proxy(local_jacobian(adjacency, v), alpha)
                       for v in range(n))

    delta_ei = ei_macro - ei_local_sum
    delta_ei_norm = max(0.0, delta_ei) / (eps + ei_macro)

    c_sh = sheaf_inconsistency(adjacency, activations, eps)

    return delta_ei_norm / (1.0 + c_sh)


# ---------------------------------------------------------------
# Substrate generators (canonical Sixth substrates)
# ---------------------------------------------------------------

def canonical_substrates() -> list:
    """10 hand-designed Sixth-style substrates for comparison.
    Each: (name, adjacency, activations).
    """
    substrates = []

    # 1. Small sparse ER, observer with self-loop
    n = 10
    g = nx.erdos_renyi_graph(n, 0.10, seed=1, directed=True)
    g.add_edge(0, 0)  # observer self-loop
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    substrates.append(("ER_n10_p10_observer-loop", A, a))

    # 2. Same but n=20
    n = 20
    g = nx.erdos_renyi_graph(n, 0.10, seed=2, directed=True)
    g.add_edge(0, 0)
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    substrates.append(("ER_n20_p10_observer-loop", A, a))

    # 3. Dense ER n=10, p=0.30
    n = 10
    g = nx.erdos_renyi_graph(n, 0.30, seed=3, directed=True)
    g.add_edge(0, 0)
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    substrates.append(("ER_n10_p30_observer-loop", A, a))

    # 4. All nodes have self-loops (Sixth STEP-CA setup)
    n = 10
    g = nx.erdos_renyi_graph(n, 0.20, seed=4, directed=True)
    for v in range(n):
        g.add_edge(v, v)
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    substrates.append(("ER_n10_p20_all-self-loops", A, a))

    # 5. Same but n=20
    n = 20
    g = nx.erdos_renyi_graph(n, 0.20, seed=5, directed=True)
    for v in range(n):
        g.add_edge(v, v)
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    substrates.append(("ER_n20_p20_all-self-loops", A, a))

    # 6. Star graph (one center, rays out)
    n = 10
    A = np.zeros((n, n))
    A[0, 0] = 1  # center self-loop
    for v in range(1, n):
        A[0, v] = 1  # center → leaf
        A[v, v] = 1  # leaf self-loop
    a = A.sum(axis=1)
    substrates.append(("star_n10_center-observer", A, a))

    # 7. Cycle graph (ring)
    n = 10
    A = np.zeros((n, n))
    for v in range(n):
        A[v, (v + 1) % n] = 1
        A[v, v] = 1  # all self-loops
    a = A.sum(axis=1)
    substrates.append(("cycle_n10_all-self-loops", A, a))

    # 8. Complete graph K_5
    n = 5
    A = np.ones((n, n))  # all pairs including self-loops
    a = A.sum(axis=1)
    substrates.append(("complete_K5_full", A, a))

    # 9. Bipartite K_{3,3}
    n = 6
    A = np.zeros((n, n))
    for u in range(3):
        for v in range(3, 6):
            A[u, v] = 1
            A[v, u] = 1
    for v in range(n):
        A[v, v] = 1
    a = A.sum(axis=1)
    substrates.append(("bipartite_K33_self-loops", A, a))

    # 10. Path graph (linear chain)
    n = 10
    A = np.zeros((n, n))
    for v in range(n - 1):
        A[v, v + 1] = 1
        A[v + 1, v] = 1
    for v in range(n):
        A[v, v] = 1
    a = A.sum(axis=1)
    substrates.append(("path_n10_self-loops", A, a))

    return substrates


def random_baseline(n: int, p: float, seed: int) -> tuple:
    """Generate matched ER baseline: same n, edge probability p,
    self-loop on node 0 (matching Sixth observer pattern).
    """
    g = nx.erdos_renyi_graph(n, p, seed=seed, directed=True)
    g.add_edge(0, 0)
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    return (A, a)


# ---------------------------------------------------------------
# Main analysis
# ---------------------------------------------------------------

def estimate_substrate_params(adjacency: np.ndarray) -> tuple:
    """Estimate n and edge density from substrate for baseline match."""
    n = adjacency.shape[0]
    n_edges = int(adjacency.sum() - np.trace(adjacency))  # exclude self-loops
    max_possible_edges = n * (n - 1)
    p = n_edges / max_possible_edges if max_possible_edges > 0 else 0.0
    return n, p


def classify_regime(r_overall: float) -> tuple:
    if r_overall > 1.5:
        return ("R", "substrate has substantially higher EICS — substrate-distinguishing signal")
    if 0.8 <= r_overall <= 1.5:
        return ("S", "substrate ≈ random — Conjecture confirmed for EICS too")
    return ("T", "substrate LESS coherent than random — unexpected")


def main():
    print("EICS application to Sixth substrate (cycle 13C / PREDICTIONS-132.md)")
    print("=" * 70)
    print()

    substrates = canonical_substrates()
    M_baseline = 1000

    eics_values = {}
    r_values = {}

    for (name, A_sub, a_sub) in substrates:
        n_sub, p_sub = estimate_substrate_params(A_sub)
        eics_sub = eics(A_sub, a_sub)
        eics_values[name] = eics_sub

        # Generate M_baseline random graphs of matched (n, p)
        eics_random_samples = []
        for seed in range(1, M_baseline + 1):
            A_rand, a_rand = random_baseline(n_sub, max(p_sub, 0.05), seed=seed)
            eics_random_samples.append(eics(A_rand, a_rand))

        mean_random = statistics.mean(eics_random_samples)
        stddev_random = statistics.stdev(eics_random_samples) if len(eics_random_samples) > 1 else 0.0

        if mean_random > 1e-9:
            R = eics_sub / mean_random
        elif eics_sub > 1e-9:
            R = float("inf")
        else:
            R = 1.0

        r_values[name] = R

        print(f"{name}")
        print(f"  n={n_sub}  p~={p_sub:.3f}")
        print(f"  EICS_substrate         = {eics_sub:.6f}")
        print(f"  EICS_random mean       = {mean_random:.6f} ± {stddev_random:.6f}")
        print(f"  R = EICS_sub / EICS_random_mean = {R:.4f}")
        print()

    # Aggregate
    valid_R = [r for r in r_values.values() if math.isfinite(r)]
    if valid_R:
        r_overall = statistics.mean(valid_R)
    else:
        r_overall = float("nan")

    print("=" * 70)
    print(f"R_overall (mean across {len(valid_R)} valid substrates): {r_overall:.4f}")
    print()

    regime, meaning = classify_regime(r_overall)
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")
    print()

    # Distribution summary
    print("EICS distribution summary:")
    print(f"  substrate EICS range: [{min(eics_values.values()):.4f}, "
          f"{max(eics_values.values()):.4f}]")
    print(f"  R range:              [{min(valid_R):.4f}, {max(valid_R):.4f}]")


if __name__ == "__main__":
    main()
