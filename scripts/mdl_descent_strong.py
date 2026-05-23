#!/usr/bin/env python3
"""
STEP-CA-MIN-STRONG on Sixth substrate (cycle 20).

Pre-registered: PREDICTIONS-139.md (commit 5d9a979).

Stronger optimizer to test cycle 19's 4/6-stuck:
  - single-edge toggles (n^2)
  - two-edge toggles (200 random pairs / step, RNG seeded)
  - simulated annealing acceptance T(t) = 2.0 * 0.95^t

Compares to cycle 19 greedy reference (frozen).

Pre-reg regimes:
  AA': n_unstuck >= 5 AND R_strong/greedy > 2.0  (H_search wins)
  BB': n_unstuck in {3,4} OR R in [1.3, 2.0]      (mixed)
  CC': n_unstuck <= 2 AND R < 1.3                  (H_landscape; L wrong loss)
"""

import math
import numpy as np
import networkx as nx


SEED_RNG = 42
T_STEPS = 200
T0 = 2.0
ALPHA = 0.95
TWO_EDGE_SAMPLE = 200


def L_mdl(A: np.ndarray) -> int:
    return len(np.unique(A, axis=0))


def candidate_single_best(A: np.ndarray) -> tuple:
    """Best single-edge toggle. Returns (delta_L, [(i,j)])."""
    n = A.shape[0]
    base_L = L_mdl(A)
    best_delta = math.inf
    best_move = None
    for i in range(n):
        for j in range(n):
            A[i, j] ^= 1
            d = L_mdl(A) - base_L
            A[i, j] ^= 1
            if d < best_delta:
                best_delta = d
                best_move = [(i, j)]
    return best_delta, best_move


def candidate_two_edge_best(A: np.ndarray, rng: np.random.Generator) -> tuple:
    """Best two-edge toggle from 200 random pairs. Returns (delta_L, [(i,j),(k,l)])."""
    n = A.shape[0]
    base_L = L_mdl(A)
    best_delta = math.inf
    best_move = None
    seen = set()
    tries = 0
    while len(seen) < TWO_EDGE_SAMPLE and tries < TWO_EDGE_SAMPLE * 10:
        tries += 1
        i, j, k, l = rng.integers(0, n, size=4)
        # Canonical ordering to dedupe.
        a, b = (int(i), int(j)), (int(k), int(l))
        if a == b:
            continue
        key = tuple(sorted([a, b]))
        if key in seen:
            continue
        seen.add(key)
        A[i, j] ^= 1
        A[k, l] ^= 1
        d = L_mdl(A) - base_L
        A[i, j] ^= 1
        A[k, l] ^= 1
        if d < best_delta:
            best_delta = d
            best_move = [(int(i), int(j)), (int(k), int(l))]
    return best_delta, best_move


def apply_move(A: np.ndarray, move: list) -> None:
    for (i, j) in move:
        A[i, j] ^= 1


def step_strong(A: np.ndarray, t: int, rng: np.random.Generator) -> tuple:
    """One STEP-CA-MIN-STRONG step. Returns (new_L, accepted_class)."""
    # Best single.
    d1, m1 = candidate_single_best(A)
    # Best two.
    d2, m2 = candidate_two_edge_best(A, rng)
    # Pick lower delta.
    if d1 <= d2:
        delta, move, cls = d1, m1, "1edge"
    else:
        delta, move, cls = d2, m2, "2edge"
    # SA acceptance.
    if delta <= 0 or move is None:
        if move is not None:
            apply_move(A, move)
        return L_mdl(A), cls
    T_now = T0 * (ALPHA ** t)
    if T_now > 1e-9:
        p = math.exp(-delta / T_now)
        if rng.random() < p:
            apply_move(A, move)
            return L_mdl(A), cls + "+SA"
    return L_mdl(A), "reject"


def descent_strong(A_init: np.ndarray, seed: int = SEED_RNG) -> dict:
    A = A_init.copy()
    rng = np.random.default_rng(seed)
    L_traj = [L_mdl(A)]
    cls_counts = {}
    L_min_seen = L_traj[0]
    for t in range(T_STEPS):
        new_L, cls = step_strong(A, t, rng)
        cls_counts[cls] = cls_counts.get(cls, 0) + 1
        L_traj.append(new_L)
        L_min_seen = min(L_min_seen, new_L)
    return {
        "L_initial": L_traj[0],
        "L_final": L_traj[-1],
        "L_min": L_min_seen,
        "L_descent_total": L_traj[0] - L_min_seen,
        "trajectory": L_traj,
        "classes": cls_counts,
    }


def test_substrates() -> list:
    """Same 6 substrates as cycle 19 / PREDICTIONS-138."""
    out = []

    g = nx.erdos_renyi_graph(10, 0.30, seed=1, directed=True)
    out.append(("ER_n10_p30_seed1", nx.to_numpy_array(g, dtype=int)))

    g = nx.erdos_renyi_graph(20, 0.20, seed=2, directed=True)
    out.append(("ER_n20_p20_seed2", nx.to_numpy_array(g, dtype=int)))

    g = nx.erdos_renyi_graph(15, 0.40, seed=3, directed=True)
    out.append(("ER_n15_p40_seed3", nx.to_numpy_array(g, dtype=int)))

    A = np.zeros((10, 10), dtype=int)
    for i in range(9):
        A[i, i + 1] = 1
        A[i + 1, i] = 1
    out.append(("path_n10", A))

    A = np.zeros((10, 10), dtype=int)
    for i in range(10):
        A[i, (i + 1) % 10] = 1
    out.append(("cycle_n10", A))

    g = nx.erdos_renyi_graph(15, 0.25, seed=4, directed=True)
    out.append(("ER_n15_p25_seed4", nx.to_numpy_array(g, dtype=int)))

    return out


# Cycle 19 greedy reference (frozen).
GREEDY_DESCENT = {
    "ER_n10_p30_seed1": 4,
    "ER_n20_p20_seed2": 0,
    "ER_n15_p40_seed3": 0,
    "path_n10":         2,
    "cycle_n10":        0,
    "ER_n15_p25_seed4": 0,
}


def classify_regime(n_unstuck: int, R: float) -> tuple:
    if n_unstuck >= 5 and R > 2.0:
        return ("AA'", "H_search WINS: stronger optimizer unstuck plateaus")
    if (3 <= n_unstuck <= 4) or (1.3 <= R <= 2.0):
        return ("BB'", "mixed: SA helps but plateau partially fundamental")
    return ("CC'", "H_landscape WINS: L is wrong loss function")


def main():
    print("STEP-CA-MIN-STRONG on Sixth substrate (cycle 20)")
    print("Pre-reg: PREDICTIONS-139.md (commit 5d9a979)")
    print("=" * 72)
    print(f"T_STEPS={T_STEPS}  T0={T0}  alpha={ALPHA}  2-edge_sample={TWO_EDGE_SAMPLE}")
    print(f"RNG_seed={SEED_RNG}")
    print()

    strong_results = {}
    n_unstuck = 0
    total_strong = 0

    for (name, A_init) in test_substrates():
        res = descent_strong(A_init)
        strong_results[name] = res
        greedy = GREEDY_DESCENT[name]
        beat = res["L_descent_total"] > greedy
        if beat:
            n_unstuck += 1
        total_strong += res["L_descent_total"]

        print(f"{name}  (n={A_init.shape[0]})")
        print(f"  STRONG:  L {res['L_initial']} -> min {res['L_min']} "
              f"(final {res['L_final']}, descent={res['L_descent_total']})")
        print(f"  greedy:  descent={greedy} (cycle 19)")
        print(f"  beat greedy: {beat}")
        print(f"  move classes: {res['classes']}")
        print()

    total_greedy = sum(GREEDY_DESCENT.values())
    R = total_strong / max(1, total_greedy)

    print("=" * 72)
    print(f"n_unstuck (strong > greedy):  {n_unstuck} / 6")
    print(f"total_descent_strong:         {total_strong}")
    print(f"total_descent_greedy (c19):   {total_greedy}")
    print(f"R_strong_vs_greedy:           {R:.4f}")
    print()
    regime, meaning = classify_regime(n_unstuck, R)
    print(f"Regime: {regime}")
    print(f"  {meaning}")


if __name__ == "__main__":
    main()
