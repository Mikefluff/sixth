#!/usr/bin/env python3
"""
EICS scaling for cycle-substrate (cycle 15).

Pre-registered: PREDICTIONS-134.md (commit ce5aa80).

Tests:
1. Scaling — cycle_n at n ∈ {5, 10, 20, 50, 100} vs k=2-regular baseline
2. Chord-breaking — cycle_10 + {0, 1, 2, 5} chords vs k=2-regular

Reuses eics() from cycle 13's scripts/eics_sixth.py.
"""

import math
import statistics
import sys
import os

import networkx as nx
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from eics_sixth import eics


def cycle_substrate(n: int, self_loops: bool = True) -> tuple:
    """Build cycle_n graph adjacency with optional self-loops on all
    nodes (matching Sixth canonical substrate pattern).

    Returns (adjacency, activations) where activations = out-degree.
    """
    A = np.zeros((n, n))
    for v in range(n):
        A[v, (v + 1) % n] = 1
        A[(v + 1) % n, v] = 1  # undirected cycle = symmetric
        if self_loops:
            A[v, v] = 1
    a = A.sum(axis=1)
    return A, a


def cycle_with_chords(n: int, num_chords: int, seed: int = 0) -> tuple:
    """Cycle_n + num_chords additional bi-edges between non-adjacent nodes.

    Chord placement is deterministic (max-spread): chord i connects
    node 0 to node n/(num_chords+1) * (i+1) for i=0..num_chords-1.
    """
    A, _ = cycle_substrate(n, self_loops=True)
    if num_chords > 0:
        for i in range(num_chords):
            target = int(n * (i + 1) / (num_chords + 1)) % n
            if target != 0 and target != 1 and target != n - 1:
                A[0, target] = 1
                A[target, 0] = 1
    a = A.sum(axis=1)
    return A, a


def random_2regular(n: int, seed: int) -> tuple:
    """Random k=2 regular graph + observer self-loop on node 0."""
    try:
        g = nx.random_regular_graph(2, n, seed=seed)
    except nx.NetworkXError:
        # n*2 must be even — should always succeed for k=2.
        g = nx.cycle_graph(n)
    g = g.to_directed()
    g.add_edge(0, 0)
    A = nx.to_numpy_array(g)
    a = np.array([g.out_degree(v) for v in range(n)], dtype=float)
    return A, a


def measure_r(substrate_adj: np.ndarray, substrate_act: np.ndarray,
              baseline_n: int, M: int = 200) -> tuple:
    """Compute R = EICS(substrate) / mean(EICS(random k=2 baselines))."""
    eics_sub = eics(substrate_adj, substrate_act, T=10)
    eics_baselines = []
    for seed in range(1, M + 1):
        A_b, a_b = random_2regular(baseline_n, seed=seed)
        eics_baselines.append(eics(A_b, a_b, T=10))
    mean_b = statistics.mean(eics_baselines)
    stddev_b = statistics.stdev(eics_baselines) if len(eics_baselines) > 1 else 0.0
    if mean_b > 1e-9:
        R = eics_sub / mean_b
    elif eics_sub > 1e-9:
        R = float("inf")
    else:
        R = 1.0
    return R, eics_sub, mean_b, stddev_b


def main():
    print("Cycle-substrate EICS scaling + chord-breaking (cycle 15)")
    print("Pre-reg: PREDICTIONS-134.md (commit ce5aa80)")
    print("=" * 70)
    print()

    M = 200

    # ---------- SCALING TEST ----------
    print("SCALING TEST: cycle_n with all-self-loops, n ∈ {5, 10, 20, 50, 100}")
    print("-" * 70)
    scaling_results = {}
    for n in [5, 10, 20, 50, 100]:
        A, a = cycle_substrate(n)
        R, eics_sub, mean_b, stddev_b = measure_r(A, a, n, M=M)
        scaling_results[n] = R
        print(f"  n={n:3d}: EICS_cycle={eics_sub:.6f}  "
              f"EICS_random={mean_b:.6f}±{stddev_b:.6f}  R={R:.4f}")
    print()

    # Determine scaling regime.
    R_values = [scaling_results[n] for n in [5, 10, 20, 50, 100]]
    is_monotone_growing = all(R_values[i] <= R_values[i + 1] for i in range(4))
    is_monotone_shrinking = all(R_values[i] >= R_values[i + 1] for i in range(4))
    R_at_100 = scaling_results[100]
    R_mean_scaling = statistics.mean(R_values)

    if is_monotone_growing and R_at_100 > 1.5:
        regime_scaling = ("X", "R grows with n, R(100) > 1.5 — scaling substrate signal")
    elif (abs(max(R_values) - min(R_values)) < 0.5
          and 1.7 < R_mean_scaling < 2.5):
        regime_scaling = ("Y", "R approximately constant ≈ 2.0 — scale-invariant")
    elif is_monotone_shrinking and R_at_100 < 1.2:
        regime_scaling = ("Z", "R shrinks with n — small-n artifact")
    else:
        regime_scaling = ("AA", "non-monotone or hybrid pattern")

    print(f"Scaling regime: {regime_scaling[0]}")
    print(f"  {regime_scaling[1]}")
    print(f"  R values: {[round(r, 3) for r in R_values]}")
    print(f"  R_mean: {R_mean_scaling:.4f}")
    print()

    # ---------- CHORD-BREAKING TEST ----------
    print("CHORD-BREAKING TEST: cycle_10 + {0, 1, 2, 5} chords")
    print("-" * 70)
    chord_results = {}
    for num_chords in [0, 1, 2, 5]:
        A, a = cycle_with_chords(10, num_chords)
        R, eics_sub, mean_b, stddev_b = measure_r(A, a, 10, M=M)
        chord_results[num_chords] = R
        print(f"  chords={num_chords}: EICS={eics_sub:.6f}  R={R:.4f}")
    print()

    R_base = chord_results[0]
    R_5chord = chord_results[5]
    R_decay = R_5chord / R_base if R_base > 1e-9 else float("nan")

    if R_decay < 0.5:
        regime_chord = ("BB", "signal FRAGILE — chord destroys cycle distinctiveness")
    elif 0.5 <= R_decay <= 1.5:
        regime_chord = ("CC", "signal ROBUST — survives perturbation")
    elif R_decay > 1.5:
        regime_chord = ("DD", "chord ENHANCES signal — surprising")
    else:
        regime_chord = ("?", "undefined")

    print(f"Chord-breaking regime: {regime_chord[0]}")
    print(f"  {regime_chord[1]}")
    print(f"  R_decay = R(5 chords) / R(0 chords) = {R_decay:.4f}")
    print()

    # Combined outcome.
    print("=" * 70)
    print(f"COMBINED OUTCOME: regime ({regime_scaling[0]} + {regime_chord[0]})")

    if regime_scaling[0] == "X" and regime_chord[0] == "CC":
        print("  BEST CASE: scaling + robust — substantial substrate finding")
    elif regime_scaling[0] == "Z" and regime_chord[0] == "BB":
        print("  WORST CASE: small-n artifact + fragile — retract cycle 14")
    elif regime_scaling[0] == "Y" and regime_chord[0] == "CC":
        print("  GOOD CASE: scale-invariant + robust — substantial finding at moderate magnitude")
    else:
        print("  MIXED: narrow scope claim required")


if __name__ == "__main__":
    main()
