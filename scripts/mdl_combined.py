#!/usr/bin/env python3
"""
STEP-CA-MIN-COMBINED on Sixth substrate (cycle 22).

Pre-registered: PREDICTIONS-141.md (commit e81f046).

L22(A | A_init) = MDL_norm(A) + lambda * Pred_norm + mu * DegeneracyPenalty

Where:
  MDL_norm = |unique rows| / n
  Pred_norm = PredError(groups(A), A_init) / PredError(K=1, A_init)
  DegeneracyPenalty = (max_group_size/n)^2 + (singletons/K)
  mu = 0.1 fixed
  lambda in {0.1, 1, 10} fixed grid

Dynamics: STEP-CA picks move with lowest L22 (greedy) + SA tail.

Compares to:
  - degree baseline at same K
  - random baseline (cycle 21 frozen reference)
  - pure MDL (cycle 21 frozen reference)

Pre-reg regimes:
  AAAA (strong pass): >=4/6 both_wins, no K=1, robust, mean_delta_pred>0
  BBBB (pass):        >=3/6 both_wins, no K=1, mean_delta_pred>0
  CCCC (fail):        <=2/6 OR K=1 OR mean_delta_pred<=0
"""

import math
import numpy as np
import networkx as nx


SEED_RNG = 42
RANDOM_PARTITION_SEED = 137
T_STEPS = 200
T0 = 2.0
ALPHA_SA = 0.95
TWO_EDGE_SAMPLE = 200
T_PRED = 20
MU = 0.1
LAMBDAS = [0.1, 1.0, 10.0]


# -----------------------------------------------------------------
# Utilities (cycle 21 reused).
# -----------------------------------------------------------------

def L_mdl(A):
    return len(np.unique(A, axis=0))


def groups_from_rows(A):
    n = A.shape[0]
    labels = np.zeros(n, dtype=int)
    seen = {}
    nxt = 0
    for i in range(n):
        key = tuple(A[i].tolist())
        if key not in seen:
            seen[key] = nxt
            nxt += 1
        labels[i] = seen[key]
    return labels


def groups_random(n, k, seed):
    rng = np.random.default_rng(seed)
    if k >= n:
        return np.arange(n, dtype=int)
    if k == 1:
        return np.zeros(n, dtype=int)
    base = np.array([i % k for i in range(n)])
    rng.shuffle(base)
    return base


def groups_degree(A, k):
    n = A.shape[0]
    degrees = A.sum(axis=1)
    order = sorted(range(n), key=lambda i: (degrees[i], i))
    labels = np.zeros(n, dtype=int)
    if k >= n:
        for rank, node_id in enumerate(order):
            labels[node_id] = rank
        return labels
    bin_size = n / k
    for rank, node_id in enumerate(order):
        bin_id = min(k - 1, int(rank // bin_size))
        labels[node_id] = bin_id
    return labels


def normalize(v):
    nrm = np.linalg.norm(v)
    if nrm < 1e-12:
        return v
    return v / nrm


def project_groupmean(a, labels):
    out = np.zeros_like(a)
    for g in np.unique(labels):
        idx = np.where(labels == g)[0]
        out[idx] = a[idx].mean()
    return out


def pred_error(A_init, labels, a0, T):
    """Cycle 21 formula: mean per-step relative L2 error."""
    A = A_init.astype(float)
    true_traj = [a0.copy()]
    a = a0.copy()
    for _ in range(T):
        a = normalize(A @ a)
        true_traj.append(a)
    pred_traj = [a0.copy()]
    a = a0.copy()
    for _ in range(T):
        a_proj = project_groupmean(a, labels)
        a = normalize(A @ a_proj)
        pred_traj.append(a)
    errs = []
    for t in range(1, T + 1):
        denom = max(1e-9, np.linalg.norm(true_traj[t]) ** 2)
        e = np.linalg.norm(pred_traj[t] - true_traj[t]) ** 2 / denom
        errs.append(e)
    return float(np.mean(errs))


# -----------------------------------------------------------------
# L22 components.
# -----------------------------------------------------------------

def mdl_norm(labels, n):
    return len(np.unique(labels)) / n


def degeneracy_penalty(labels):
    K = len(np.unique(labels))
    if K == 0:
        return 0.0
    sizes = [int((labels == g).sum()) for g in np.unique(labels)]
    n = len(labels)
    max_size_ratio = max(sizes) / n
    singletons = sum(1 for s in sizes if s == 1)
    return (max_size_ratio ** 2) + (singletons / K)


def pred_norm(labels, A_init, a0, pred_K1):
    pe = pred_error(A_init, labels, a0, T_PRED)
    return pe / max(1e-9, pred_K1)


def L22(A_current, A_init, a0, pred_K1, lam):
    labels = groups_from_rows(A_current)
    n = A_current.shape[0]
    m = mdl_norm(labels, n)
    p = pred_norm(labels, A_init, a0, pred_K1)
    d = degeneracy_penalty(labels)
    return m + lam * p + MU * d, m, p, d, labels


# -----------------------------------------------------------------
# STEP-CA-MIN-COMBINED-STRONG.
# -----------------------------------------------------------------

def best_single_move(A, A_init, a0, pred_K1, lam):
    n = A.shape[0]
    base_L, _, _, _, _ = L22(A, A_init, a0, pred_K1, lam)
    best_delta = math.inf
    best_move = None
    for i in range(n):
        for j in range(n):
            A[i, j] ^= 1
            new_L, _, _, _, _ = L22(A, A_init, a0, pred_K1, lam)
            A[i, j] ^= 1
            d = new_L - base_L
            if d < best_delta:
                best_delta = d
                best_move = [(i, j)]
    return best_delta, best_move


def best_two_move(A, A_init, a0, pred_K1, lam, rng):
    n = A.shape[0]
    base_L, _, _, _, _ = L22(A, A_init, a0, pred_K1, lam)
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
        new_L, _, _, _, _ = L22(A, A_init, a0, pred_K1, lam)
        A[i, j] ^= 1
        A[k, l] ^= 1
        d = new_L - base_L
        if d < best_delta:
            best_delta = d
            best_move = [(int(i), int(j)), (int(k), int(l))]
    return best_delta, best_move


def step_combined(A, t, A_init, a0, pred_K1, lam, rng):
    d1, m1 = best_single_move(A, A_init, a0, pred_K1, lam)
    d2, m2 = best_two_move(A, A_init, a0, pred_K1, lam, rng)
    if d1 <= d2:
        delta, move = d1, m1
    else:
        delta, move = d2, m2
    if move is None:
        return
    if delta <= 0:
        for (i, j) in move:
            A[i, j] ^= 1
        return
    T_now = T0 * (ALPHA_SA ** t)
    if T_now > 1e-9 and rng.random() < math.exp(-delta / T_now):
        for (i, j) in move:
            A[i, j] ^= 1


def combined_descent(A_init, lam):
    A = A_init.copy()
    a0 = normalize(A_init.sum(axis=1).astype(float))
    if np.linalg.norm(a0) < 1e-12:
        a0 = normalize(np.ones(A_init.shape[0]))
    pred_K1 = pred_error(A_init.astype(float),
                          np.zeros(A_init.shape[0], dtype=int),
                          a0, T_PRED)
    rng = np.random.default_rng(SEED_RNG)
    for t in range(T_STEPS):
        step_combined(A, t, A_init.astype(float), a0, pred_K1, lam, rng)
    return A, a0, pred_K1


# -----------------------------------------------------------------
# Substrates.
# -----------------------------------------------------------------

def test_substrates():
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
# Main loop.
# -----------------------------------------------------------------

def evaluate_grouping(labels, A_init, a0, pred_K1, lam, n):
    pe = pred_error(A_init.astype(float), labels, a0, T_PRED)
    m = mdl_norm(labels, n)
    p = pe / max(1e-9, pred_K1)
    d = degeneracy_penalty(labels)
    L = m + lam * p + MU * d
    return {
        "K": len(np.unique(labels)),
        "MDL_norm": m,
        "PredError": pe,
        "Pred_norm": p,
        "Penalty": d,
        "L22": L,
    }


def main():
    print("STEP-CA-MIN-COMBINED on Sixth substrate (cycle 22)")
    print("Pre-reg: PREDICTIONS-141.md (commit e81f046)")
    print(f"lambdas={LAMBDAS}, mu={MU}, T={T_STEPS}, T0={T0}, alpha={ALPHA_SA}")
    print("=" * 78)

    substrates = test_substrates()
    # results[lam][substrate_name] = dict
    results = {lam: {} for lam in LAMBDAS}

    for lam in LAMBDAS:
        print(f"\n##### LAMBDA = {lam} #####")
        for (name, A_init) in substrates:
            print(f"\n  Substrate: {name}  (n={A_init.shape[0]})")
            A_final, a0, pred_K1 = combined_descent(A_init, lam)
            labels_sub = groups_from_rows(A_final)
            K = len(np.unique(labels_sub))
            labels_deg = groups_degree(A_init, K)
            labels_rand = groups_random(A_init.shape[0], K,
                                          seed=RANDOM_PARTITION_SEED)

            r_sub = evaluate_grouping(labels_sub, A_init, a0, pred_K1,
                                       lam, A_init.shape[0])
            r_deg = evaluate_grouping(labels_deg, A_init, a0, pred_K1,
                                       lam, A_init.shape[0])
            r_rand = evaluate_grouping(labels_rand, A_init, a0, pred_K1,
                                        lam, A_init.shape[0])

            combined_win = r_sub["L22"] < r_deg["L22"]
            pred_win = r_sub["PredError"] < r_deg["PredError"]
            results[lam][name] = {
                "K": K,
                "sub": r_sub,
                "deg": r_deg,
                "rand": r_rand,
                "combined_win": combined_win,
                "pred_win": pred_win,
                "both_win": combined_win and pred_win,
                "is_K1": K == 1,
                "delta_pred": r_deg["PredError"] - r_sub["PredError"],
            }
            print(f"    K={K}  L22_sub={r_sub['L22']:.4f}  "
                  f"L22_deg={r_deg['L22']:.4f}  "
                  f"PE_sub={r_sub['PredError']:.4f}  "
                  f"PE_deg={r_deg['PredError']:.4f}")
            print(f"    combined_win={combined_win}  pred_win={pred_win}  "
                  f"both={combined_win and pred_win}  K=1={K==1}")

    # Aggregate per lambda.
    print("\n" + "=" * 78)
    print("AGGREGATE per lambda:")
    summary = {}
    for lam in LAMBDAS:
        r = results[lam]
        cw = sum(1 for v in r.values() if v["combined_win"])
        pw = sum(1 for v in r.values() if v["pred_win"])
        bw = sum(1 for v in r.values() if v["both_win"])
        has_k1 = any(v["is_K1"] for v in r.values())
        mean_delta = float(np.mean([v["delta_pred"] for v in r.values()]))
        summary[lam] = {
            "combined_wins": cw, "pred_wins": pw, "both_wins": bw,
            "has_K1": has_k1, "mean_delta_pred": mean_delta,
        }
        print(f"  lambda={lam}:  combined_wins={cw}  pred_wins={pw}  "
              f"both_wins={bw}  has_K1={has_k1}  mean_delta_pred={mean_delta:+.4f}")

    # Best lambda = argmax(both_wins), tiebreak by mean_delta_pred.
    best_lam = max(LAMBDAS, key=lambda l: (summary[l]["both_wins"],
                                             summary[l]["mean_delta_pred"]))
    s = summary[best_lam]
    print(f"\nBest lambda: {best_lam}  (both_wins={s['both_wins']}, "
          f"mean_delta_pred={s['mean_delta_pred']:+.4f}, has_K1={s['has_K1']})")

    # Robust drop = max drop in both_wins removing any single substrate.
    r = results[best_lam]
    names = list(r.keys())
    drops = []
    for to_remove in names:
        bw_minus = sum(1 for n, v in r.items()
                       if n != to_remove and v["both_win"])
        drop = (s["both_wins"] - bw_minus) - (1 if r[to_remove]["both_win"] else 0)
        drops.append(max(0, s["both_wins"] - bw_minus))
    robust_drop = max(drops) if drops else 0
    print(f"  robust_drop (max single-substrate removal impact): {robust_drop}")

    # Classify.
    if (s["both_wins"] >= 4 and not s["has_K1"]
            and s["mean_delta_pred"] > 0 and robust_drop <= 1):
        regime = "AAAA"
        meaning = ("STRONG PASS — combined L beats degree on prediction AND "
                   "combined score on >=4 substrates; robust; no degeneracy")
    elif (s["both_wins"] >= 3 and not s["has_K1"]
            and s["mean_delta_pred"] > 0):
        regime = "BBBB"
        meaning = ("PASS — combined L beats degree on >=3 substrates; "
                   "combined loss validated as substrate-of-objecthood signal")
    else:
        regime = "CCCC"
        meaning = ("FAIL — MDL+prediction family wrong direction; cycle 23 "
                   "must pivot to Information Bottleneck or Predictive Proc")
    print(f"\nRegime: {regime}")
    print(f"  {meaning}")


if __name__ == "__main__":
    main()
