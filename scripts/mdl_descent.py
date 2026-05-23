#!/usr/bin/env python3
"""
MDL-descent on Sixth substrate (cycle 19).

Pre-registered: PREDICTIONS-138.md (commit 750789c).

L(state) = |unique out-neighbor patterns across nodes|
STEP-CA-MIN: greedy edge-toggle minimizing L at each step.

Tests if substrate dynamics minimize L (substrate-as-energetic-system
hypothesis).  Compares to random rewrite baseline.

Pre-reg regimes:
  AA: monotone descent in ALL 6 cases AND mean(R_descent) > 1.5
  BB: monotone in ≥4/6 OR R ∈ [1.1, 1.5]
  CC: monotone ≤3/6 AND R < 1.1
"""

import statistics
import numpy as np
import networkx as nx


def L_mdl(adjacency: np.ndarray) -> int:
    """L = number of distinct row-vectors in adjacency matrix."""
    return len(np.unique(adjacency, axis=0))


def step_ca_min(A: np.ndarray) -> tuple:
    """Greedy edge toggle minimizing L.  Returns (new_A, new_L).

    Enumerates n^2 candidate toggles, picks one with lowest L
    (ties broken by (i, j) lexicographically lowest).
    Returns same A if no improvement possible (local min).
    """
    n = A.shape[0]
    current_L = L_mdl(A)
    best_L = current_L
    best_ij = None

    for i in range(n):
        for j in range(n):
            A_new = A.copy()
            A_new[i, j] = 1 - A_new[i, j]
            new_L = L_mdl(A_new)
            if new_L < best_L:
                best_L = new_L
                best_ij = (i, j)

    if best_ij is None:
        return A, current_L  # local min

    i, j = best_ij
    A[i, j] = 1 - A[i, j]
    return A, best_L


def random_rewrite_step(A: np.ndarray, rng: np.random.Generator) -> tuple:
    """Random edge toggle (baseline)."""
    n = A.shape[0]
    i = rng.integers(0, n)
    j = rng.integers(0, n)
    A[i, j] = 1 - A[i, j]
    return A, L_mdl(A)


def descent_trajectory(A_init: np.ndarray, T: int = 50,
                        random_baseline: bool = False,
                        seed: int = 0) -> dict:
    """Run T steps of STEP-CA-MIN (or random baseline).  Return trajectory."""
    A = A_init.copy()
    L_trajectory = [L_mdl(A)]
    monotone = True
    rng = np.random.default_rng(seed) if random_baseline else None

    for t in range(T):
        if random_baseline:
            A, new_L = random_rewrite_step(A, rng)
        else:
            A, new_L = step_ca_min(A)

        if new_L > L_trajectory[-1]:
            monotone = False
        L_trajectory.append(new_L)

    return {
        "L_initial": L_trajectory[0],
        "L_final": L_trajectory[-1],
        "L_descent_total": L_trajectory[0] - L_trajectory[-1],
        "L_trajectory": L_trajectory,
        "monotone": monotone,
    }


def test_substrates() -> list:
    """6 deterministic test cases per PREDICTIONS-138.md."""
    substrates = []

    # 1. ER(n=10, p=0.30) seed 1
    g = nx.erdos_renyi_graph(10, 0.30, seed=1, directed=True)
    A = nx.to_numpy_array(g, dtype=int)
    substrates.append(("ER_n10_p30_seed1", A))

    # 2. ER(n=20, p=0.20) seed 2
    g = nx.erdos_renyi_graph(20, 0.20, seed=2, directed=True)
    A = nx.to_numpy_array(g, dtype=int)
    substrates.append(("ER_n20_p20_seed2", A))

    # 3. ER(n=15, p=0.40) seed 3
    g = nx.erdos_renyi_graph(15, 0.40, seed=3, directed=True)
    A = nx.to_numpy_array(g, dtype=int)
    substrates.append(("ER_n15_p40_seed3", A))

    # 4. Path n=10
    A = np.zeros((10, 10), dtype=int)
    for i in range(9):
        A[i, i + 1] = 1
        A[i + 1, i] = 1
    substrates.append(("path_n10", A))

    # 5. Cycle n=10
    A = np.zeros((10, 10), dtype=int)
    for i in range(10):
        A[i, (i + 1) % 10] = 1
    substrates.append(("cycle_n10", A))

    # 6. Random n=15 seed 4
    g = nx.erdos_renyi_graph(15, 0.25, seed=4, directed=True)
    A = nx.to_numpy_array(g, dtype=int)
    substrates.append(("ER_n15_p25_seed4", A))

    return substrates


def classify_regime(monotone_count: int, R_descent: float) -> tuple:
    if monotone_count == 6 and R_descent > 1.5:
        return ("AA", "substrate dynamics MINIMIZE L; energetic behavior CONFIRMED")
    if monotone_count >= 4 or (1.1 <= R_descent <= 1.5):
        return ("BB", "partial; substrate descends with noise OR modest advantage")
    return ("CC", "substrate doesn't reliably minimize L; wrong L OR broken dynamics")


def main():
    print("MDL-descent on Sixth substrate (cycle 19)")
    print("Pre-reg: PREDICTIONS-138.md (commit 750789c)")
    print("=" * 70)
    print()

    T = 50
    substrates = test_substrates()

    descent_results = {}
    baseline_results = {}

    for (name, A_init) in substrates:
        print(f"Substrate: {name}  (n={A_init.shape[0]})")

        # STEP-CA-MIN descent.
        sub_res = descent_trajectory(A_init.copy(), T=T, random_baseline=False)
        descent_results[name] = sub_res

        # Random baseline.
        base_res = descent_trajectory(A_init.copy(), T=T, random_baseline=True, seed=42)
        baseline_results[name] = base_res

        print(f"  STEP-CA-MIN:  L {sub_res['L_initial']} → {sub_res['L_final']}  "
              f"(descent={sub_res['L_descent_total']}, monotone={sub_res['monotone']})")
        print(f"  random rewr:  L {base_res['L_initial']} → {base_res['L_final']}  "
              f"(descent={base_res['L_descent_total']})")
        print()

    # Aggregate.
    monotone_count = sum(1 for r in descent_results.values() if r["monotone"])
    descent_totals = [r["L_descent_total"] for r in descent_results.values()]
    baseline_totals = [r["L_descent_total"] for r in baseline_results.values()]
    sum_descent = sum(descent_totals)
    sum_baseline = sum(baseline_totals)

    if sum_baseline > 0:
        R_descent = sum_descent / sum_baseline
    elif sum_descent > 0:
        R_descent = float("inf")
    else:
        R_descent = 1.0

    print("=" * 70)
    print(f"Monotone non-increasing: {monotone_count} / 6 substrates")
    print(f"Total L-descent (STEP-CA-MIN): {sum_descent}")
    print(f"Total L-descent (random):       {sum_baseline}")
    print(f"R_descent = STEP-CA-MIN / random = {R_descent:.4f}")
    print()

    regime, meaning = classify_regime(monotone_count, R_descent)
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")


if __name__ == "__main__":
    main()
