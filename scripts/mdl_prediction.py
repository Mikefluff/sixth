#!/usr/bin/env python3
"""
MDL groups vs predictive quality on Sixth substrate (cycle 21).

Pre-registered: PREDICTIONS-140.md (commit 1f4a3cc).

Tests whether MDL-discovered equivalence classes predict substrate
dynamics better than random/degree-matched groupings AT THE SAME
GROUP COUNT.

Pipeline:
  1. Run STEP-CA-MIN-STRONG on each of 6 substrates (= cycle 20).
  2. Extract G_substrate = equivalence classes of A_final rows.
  3. Build G_random and G_degree at same K = |G_substrate|.
  4. Simulate trajectory on A_init from normalized-degree start.
  5. For each grouping, compute PredError = mean over T_pred=20 steps
     of ||predicted - true||^2 / ||true||^2 where prediction =
     normalize(A * group-mean-projection(a)).
  6. Classify regime.

Pre-reg regimes:
  AAA: substrate strictly beats BOTH random AND degree on >=5/6
       (excluding ties) AND mean(delta_random) > 0.05 AND
       mean(delta_degree) > 0.05  (MDL alone predictive)
  BBB: substrate beats both on 3-4/6 OR mean(delta) in [0.01, 0.05]
  CCC: substrate beats baselines on <=2/6 OR mean(delta) < 0.01
       (user hypothesis confirmed; need combined L)
"""

import math
import numpy as np
import networkx as nx


SEED_RNG = 42
RANDOM_PARTITION_SEED = 137
T_STEPS_OPT = 200
T0 = 2.0
ALPHA_SA = 0.95
TWO_EDGE_SAMPLE = 200
T_PRED = 20


# -----------------------------------------------------------------
# STEP-CA-MIN-STRONG (copied from cycle 20 verbatim — frozen ref).
# -----------------------------------------------------------------

def L_mdl(A: np.ndarray) -> int:
    return len(np.unique(A, axis=0))


def candidate_single_best(A: np.ndarray) -> tuple:
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


def candidate_two_edge_best(A: np.ndarray, rng) -> tuple:
    n = A.shape[0]
    base_L = L_mdl(A)
    best_delta = math.inf
    best_move = None
    seen = set()
    tries = 0
    while len(seen) < TWO_EDGE_SAMPLE and tries < TWO_EDGE_SAMPLE * 10:
        tries += 1
        i, j, k, l = rng.integers(0, n, size=4)
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


def apply_move(A: np.ndarray, move) -> None:
    for (i, j) in move:
        A[i, j] ^= 1


def step_strong(A: np.ndarray, t: int, rng) -> int:
    d1, m1 = candidate_single_best(A)
    d2, m2 = candidate_two_edge_best(A, rng)
    if d1 <= d2:
        delta, move = d1, m1
    else:
        delta, move = d2, m2
    if delta <= 0 or move is None:
        if move is not None:
            apply_move(A, move)
        return L_mdl(A)
    T_now = T0 * (ALPHA_SA ** t)
    if T_now > 1e-9:
        p = math.exp(-delta / T_now)
        if rng.random() < p:
            apply_move(A, move)
            return L_mdl(A)
    return L_mdl(A)


def strong_descent(A_init: np.ndarray) -> np.ndarray:
    A = A_init.copy()
    rng = np.random.default_rng(SEED_RNG)
    for t in range(T_STEPS_OPT):
        step_strong(A, t, rng)
    return A


# -----------------------------------------------------------------
# Grouping construction.
# -----------------------------------------------------------------

def groups_from_rows(A: np.ndarray) -> np.ndarray:
    """Equivalence classes of identical row vectors. Returns array of
    group ids, one per node."""
    n = A.shape[0]
    labels = np.zeros(n, dtype=int)
    seen = {}
    next_id = 0
    for i in range(n):
        key = tuple(A[i].tolist())
        if key not in seen:
            seen[key] = next_id
            next_id += 1
        labels[i] = seen[key]
    return labels


def groups_random(n: int, k: int, seed: int) -> np.ndarray:
    """Random partition of n nodes into exactly k non-empty groups."""
    rng = np.random.default_rng(seed)
    if k >= n:
        return np.arange(n, dtype=int)
    if k == 1:
        return np.zeros(n, dtype=int)
    # Ensure each group has at least one member.
    base = np.array([i % k for i in range(n)])
    rng.shuffle(base)
    return base


def groups_degree(A: np.ndarray, k: int) -> np.ndarray:
    """Partition nodes into k bins by out-degree (ties broken by id)."""
    n = A.shape[0]
    degrees = A.sum(axis=1)
    # Sort nodes by (degree, id).
    order = sorted(range(n), key=lambda i: (degrees[i], i))
    labels = np.zeros(n, dtype=int)
    # Slice into k contiguous bins.
    if k >= n:
        for rank, node_id in enumerate(order):
            labels[node_id] = rank
        return labels
    bin_size = n / k
    for rank, node_id in enumerate(order):
        bin_id = min(k - 1, int(rank // bin_size))
        labels[node_id] = bin_id
    return labels


# -----------------------------------------------------------------
# Predictive evaluation.
# -----------------------------------------------------------------

def normalize(v: np.ndarray) -> np.ndarray:
    nrm = np.linalg.norm(v)
    if nrm < 1e-12:
        return v
    return v / nrm


def project_groupmean(a: np.ndarray, labels: np.ndarray) -> np.ndarray:
    n = a.shape[0]
    out = np.zeros_like(a)
    for g in np.unique(labels):
        idx = np.where(labels == g)[0]
        out[idx] = a[idx].mean()
    return out


def trajectory(A: np.ndarray, a0: np.ndarray, T: int) -> np.ndarray:
    """Returns array of shape (T+1, n) with normalized states."""
    n = A.shape[0]
    traj = np.zeros((T + 1, n))
    traj[0] = a0
    a = a0.copy()
    for t in range(T):
        a = normalize(A @ a)
        traj[t + 1] = a
    return traj


def pred_error(A: np.ndarray, labels: np.ndarray, a0: np.ndarray,
               T: int) -> float:
    """PredError = mean over t=1..T of ||pred - true||^2 / ||true||^2.

    Predicted trajectory uses group-mean projection at every step.
    """
    true_traj = trajectory(A, a0, T)
    pred_traj = np.zeros_like(true_traj)
    pred_traj[0] = a0
    a = a0.copy()
    for t in range(T):
        a_proj = project_groupmean(a, labels)
        a = normalize(A @ a_proj)
        pred_traj[t + 1] = a
    errs = []
    for t in range(1, T + 1):
        denom = max(1e-9, np.linalg.norm(true_traj[t]) ** 2)
        e = np.linalg.norm(pred_traj[t] - true_traj[t]) ** 2 / denom
        errs.append(e)
    return float(np.mean(errs))


# -----------------------------------------------------------------
# Substrate set (same 6 as cycles 19/20).
# -----------------------------------------------------------------

def test_substrates() -> list:
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


# -----------------------------------------------------------------
# Classification.
# -----------------------------------------------------------------

def classify(non_tie_substrate_wins: int, mean_delta_r: float,
             mean_delta_d: float) -> tuple:
    if (non_tie_substrate_wins >= 5
            and mean_delta_r > 0.05
            and mean_delta_d > 0.05):
        return ("AAA", "MDL groups ARE predictive — pure compression already "
                       "discovers dynamics-respecting structure")
    if (3 <= non_tie_substrate_wins <= 4
            or 0.01 <= max(mean_delta_r, mean_delta_d) <= 0.05):
        return ("BBB", "mixed: MDL groups partially predict; need explicit "
                       "prediction term in L")
    return ("CCC", "MDL groups DO NOT reliably predict — user hypothesis "
                   "confirmed; cycle 22 must use combined L")


# -----------------------------------------------------------------
# Main.
# -----------------------------------------------------------------

def main():
    print("MDL groups vs predictive quality (cycle 21)")
    print("Pre-reg: PREDICTIONS-140.md (commit 1f4a3cc)")
    print("=" * 76)
    print()

    substrates = test_substrates()
    delta_r_list = []
    delta_d_list = []
    non_tie_wins = 0
    tie_count = 0
    rows = []

    for (name, A_init) in substrates:
        A_final = strong_descent(A_init)
        labels_sub = groups_from_rows(A_final)
        K = len(np.unique(labels_sub))
        labels_rand = groups_random(A_init.shape[0], K,
                                     seed=RANDOM_PARTITION_SEED)
        labels_deg = groups_degree(A_init, K)
        # Build start activation = normalized degree of A_init.
        a0 = normalize(A_init.sum(axis=1).astype(float))
        if np.linalg.norm(a0) < 1e-12:
            # Degenerate empty graph; uniform a0.
            a0 = normalize(np.ones(A_init.shape[0]))

        e_sub = pred_error(A_init.astype(float), labels_sub, a0, T_PRED)
        e_rand = pred_error(A_init.astype(float), labels_rand, a0, T_PRED)
        e_deg = pred_error(A_init.astype(float), labels_deg, a0, T_PRED)

        d_r = e_rand - e_sub
        d_d = e_deg - e_sub
        is_tie = (K == 1) or (K == A_init.shape[0])

        if is_tie:
            tie_count += 1
            tie_str = "TIE"
        else:
            delta_r_list.append(d_r)
            delta_d_list.append(d_d)
            beat_random = d_r > 0
            beat_degree = d_d > 0
            if beat_random and beat_degree:
                non_tie_wins += 1
            tie_str = (f"{'beat-r' if beat_random else 'lose-r'}/"
                       f"{'beat-d' if beat_degree else 'lose-d'}")

        rows.append((name, K, e_sub, e_rand, e_deg, d_r, d_d, tie_str))
        print(f"{name}  (n={A_init.shape[0]}, K={K})")
        print(f"  PredError substrate: {e_sub:.4f}")
        print(f"  PredError random   : {e_rand:.4f}  (delta {d_r:+.4f})")
        print(f"  PredError degree   : {e_deg:.4f}  (delta {d_d:+.4f})")
        print(f"  status: {tie_str}")
        print()

    mean_dr = float(np.mean(delta_r_list)) if delta_r_list else 0.0
    mean_dd = float(np.mean(delta_d_list)) if delta_d_list else 0.0
    non_tie = 6 - tie_count

    print("=" * 76)
    print(f"non-tie substrates                : {non_tie}")
    print(f"non-tie wins (beats BOTH baselines): {non_tie_wins}")
    print(f"tie cases (K=1 or K=n)             : {tie_count}")
    print(f"mean delta vs random (non-tie)    : {mean_dr:+.4f}")
    print(f"mean delta vs degree (non-tie)    : {mean_dd:+.4f}")
    print()
    regime, meaning = classify(non_tie_wins, mean_dr, mean_dd)
    print(f"Regime: {regime}")
    print(f"  {meaning}")


if __name__ == "__main__":
    main()
