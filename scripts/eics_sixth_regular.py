#!/usr/bin/env python3
"""
EICS on Sixth substrate vs RANDOM REGULAR baseline + spectral comparisons.

Cycle 14 (PREDICTIONS-133.md attested at commit 50ceb60).

CS-doctor follow-up to cycle 13C/D: replace ER baseline with
random k-regular graphs matching substrate's degree distribution.
If EICS signal survives, substrate distinction is real; if vanishes,
cycle 13 reduces to "structured vs random topology" tautology.

Also computes spectral gap and von Neumann entropy on each substrate
for cross-measure comparison (sub-prediction in PREDICTIONS-133).
"""

import math
import statistics
from typing import Optional

import networkx as nx
import numpy as np

# Re-use EICS implementation from cycle 13.
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from eics_sixth import (
    eics, ei_proxy, sheaf_inconsistency, local_jacobian,
    canonical_substrates, estimate_substrate_params,
)


# ---------------------------------------------------------------
# Spectral comparison measures
# ---------------------------------------------------------------

def spectral_gap(adjacency: np.ndarray) -> float:
    """Spectral gap = |λ_1| - |λ_2| of adjacency matrix.

    Larger gap = more "expander-like" / well-mixed dynamics.
    For periodic structures (cycle), gap is small.
    """
    eigs = np.abs(np.linalg.eigvals(adjacency))
    eigs.sort()
    if len(eigs) < 2:
        return 0.0
    return float(eigs[-1] - eigs[-2])


def von_neumann_entropy(adjacency: np.ndarray) -> float:
    """Von Neumann entropy of normalized adjacency (as density matrix).

    S(ρ) = -Σ p_i log p_i where p_i = λ_i / tr(ρ).
    Captures spectral diversity.
    """
    eigs = np.abs(np.linalg.eigvals(adjacency))
    total = eigs.sum()
    if total <= 0:
        return 0.0
    probs = eigs / total
    # Filter zeros for log.
    probs = probs[probs > 1e-12]
    return float(-(probs * np.log(probs)).sum())


# ---------------------------------------------------------------
# Random regular baseline generation
# ---------------------------------------------------------------

def random_regular_baseline(n: int, mean_degree: float, seed: int) -> tuple:
    """Generate random k-regular graph with k = round(mean_degree)
    on n nodes, plus observer self-loop on node 0 (matching Sixth pattern).

    networkx.random_regular_graph requires n*k even, so we adjust if
    needed and document.
    """
    k = max(1, int(round(mean_degree)))
    # Ensure n*k is even (required by networkx).
    if (n * k) % 2 != 0:
        # Try k-1 or k+1.
        if (n * (k - 1)) % 2 == 0 and k - 1 >= 1:
            k = k - 1
        elif (n * (k + 1)) % 2 == 0:
            k = k + 1
        else:
            # Fallback: use ER at same density.
            p = mean_degree / max(n - 1, 1)
            g = nx.erdos_renyi_graph(n, p, seed=seed, directed=True)
            g.add_edge(0, 0)
            A = nx.to_numpy_array(g)
            a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
            return A, a

    if k >= n:
        k = n - 1
        if (n * k) % 2 != 0:
            k -= 1
    if k < 1:
        # Trivial: empty graph + observer self-loop.
        A = np.zeros((n, n))
        A[0, 0] = 1
        a = np.zeros(n)
        a[0] = 1.0
        return A, a

    try:
        g = nx.random_regular_graph(k, n, seed=seed)
    except nx.NetworkXError:
        # Fallback to ER.
        p = mean_degree / max(n - 1, 1)
        g = nx.erdos_renyi_graph(n, p, seed=seed, directed=True)

    # Convert to directed adjacency.
    if not g.is_directed():
        g = g.to_directed()

    g.add_edge(0, 0)  # observer self-loop
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    return A, a


# ---------------------------------------------------------------
# Main analysis
# ---------------------------------------------------------------

def classify_regime(r_overall: float) -> tuple:
    if r_overall > 1.5:
        return ("U", "signal SURVIVES tighter baseline — real substrate-distinguishing finding")
    if 0.7 <= r_overall <= 1.5:
        return ("V", "partial signal; substrate has subtle distinction")
    return ("W", "signal VANISHES — cycle 13 was tautological 'structured vs sparse'")


def main():
    print("EICS vs random-regular baseline + spectral comparison")
    print("Cycle 14 / PREDICTIONS-133.md (commit 50ceb60)")
    print("=" * 70)
    print()

    substrates = canonical_substrates()
    M = 500

    r_regular = {}
    eics_values = {}
    spectral_gap_values = {}
    vn_entropy_values = {}

    for (name, A_sub, a_sub) in substrates:
        n_sub = A_sub.shape[0]
        # Mean degree from substrate (count non-self-loop directed edges).
        n_edges = int(A_sub.sum() - np.trace(A_sub))
        mean_deg = n_edges / max(n_sub, 1)

        eics_sub = eics(A_sub, a_sub, T=10)
        eics_values[name] = eics_sub

        # Random regular baseline at matched mean degree.
        eics_random_samples = []
        for seed in range(1, M + 1):
            A_r, a_r = random_regular_baseline(n_sub, mean_deg, seed=seed)
            eics_random_samples.append(eics(A_r, a_r, T=10))

        mean_random = statistics.mean(eics_random_samples)
        stddev_random = statistics.stdev(eics_random_samples) if len(eics_random_samples) > 1 else 0.0

        if mean_random > 1e-9:
            R = eics_sub / mean_random
        elif eics_sub > 1e-9:
            R = float("inf")
        else:
            R = 1.0
        r_regular[name] = R

        # Spectral measures.
        sg = spectral_gap(A_sub)
        vn = von_neumann_entropy(A_sub)
        spectral_gap_values[name] = sg
        vn_entropy_values[name] = vn

        print(f"{name}")
        print(f"  n={n_sub}  mean_deg={mean_deg:.2f}  k_regular={int(round(mean_deg))}")
        print(f"  EICS_substrate          = {eics_sub:.6f}")
        print(f"  EICS_regular mean (M={M})= {mean_random:.6f} ± {stddev_random:.6f}")
        print(f"  R = EICS_sub / EICS_reg = {R:.4f}")
        print(f"  spectral_gap            = {sg:.4f}")
        print(f"  von_neumann_entropy     = {vn:.4f}")
        print()

    # Aggregate.
    valid_R = [r for r in r_regular.values() if math.isfinite(r)]
    r_overall = statistics.mean(valid_R) if valid_R else float("nan")

    print("=" * 70)
    print(f"R_overall_regular (mean across {len(valid_R)} substrates): {r_overall:.4f}")

    regime, meaning = classify_regime(r_overall)
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")
    print()

    # Correlation analysis (sub-prediction).
    names = list(r_regular.keys())
    eics_vec = np.array([eics_values[n] for n in names])
    inv_sg_vec = np.array([
        1.0 / max(spectral_gap_values[n], 1e-6) for n in names
    ])
    vn_vec = np.array([vn_entropy_values[n] for n in names])

    def pearson(x, y):
        if np.std(x) < 1e-9 or np.std(y) < 1e-9:
            return float("nan")
        return float(np.corrcoef(x, y)[0, 1])

    r_eics_invsg = pearson(eics_vec, inv_sg_vec)
    r_eics_vn = pearson(eics_vec, vn_vec)

    print("Cross-measure correlations:")
    print(f"  Pearson(EICS, 1/spectral_gap):    {r_eics_invsg:.4f}")
    print(f"  Pearson(EICS, von_Neumann_entropy): {r_eics_vn:.4f}")
    print()

    if abs(r_eics_invsg) > 0.7:
        print("  → EICS is essentially measuring 1/spectral_gap (over-engineered wrapper)")
    elif abs(r_eics_invsg) >= 0.3:
        print("  → EICS captures spectral structure PLUS additional information")
    else:
        print("  → EICS captures something fundamentally different from spectral gap")


if __name__ == "__main__":
    main()
