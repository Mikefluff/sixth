#!/usr/bin/env python3
"""
STEP-CA-PRED: Predictive Objecthood without MDL (cycle 23, Phase A).

Pre-registered: PREDICTIONS-142.md (commit 8572023).

L23 = PredError + alpha * ModelComplexity + gamma * DegeneracyPenalty
  PredError: raw, T_pred=20 (cycle 21/22 formula)
  ModelComplexity = K / n
  DegeneracyPenalty = (max_size/n)^2 + (singletons/K)
  gamma = 0.1 fixed
  alpha in {0.01, 0.1, 1} fixed grid

PASS evaluated by PredError vs degree baseline (NOT by L23) to avoid
penalty tricks.

Pre-reg regimes:
  AAAAA: pred_wins>=4, mean_delta>0.005, NOT concentrated, no K=1, robust
  BBBBB: pred_wins>=3, no K=1, mean_delta>0
  CCCCC: pred_wins<=2 OR K=1 OR concentrated OR mean_delta<=0
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
GAMMA = 0.1
ALPHAS = [0.01, 0.1, 1.0]


# -----------------------------------------------------------------
# Utilities (reused).
# -----------------------------------------------------------------

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


def degeneracy_penalty(labels):
    K = len(np.unique(labels))
    if K == 0:
        return 0.0
    sizes = [int((labels == g).sum()) for g in np.unique(labels)]
    n = len(labels)
    max_size_ratio = max(sizes) / n
    singletons = sum(1 for s in sizes if s == 1)
    return (max_size_ratio ** 2) + (singletons / K)


def partition_entropy(labels):
    K = len(np.unique(labels))
    if K <= 1:
        return 0.0
    sizes = np.array([(labels == g).sum() for g in np.unique(labels)],
                     dtype=float)
    p = sizes / sizes.sum()
    return float(-(p * np.log(p + 1e-12)).sum())


# -----------------------------------------------------------------
# L23 components.
# -----------------------------------------------------------------

def L23(A_current, A_init, a0, alpha):
    labels = groups_from_rows(A_current)
    n = A_current.shape[0]
    K = len(np.unique(labels))
    pe = pred_error(A_init, labels, a0, T_PRED)
    mc = K / n
    dp = degeneracy_penalty(labels)
    return pe + alpha * mc + GAMMA * dp


# -----------------------------------------------------------------
# STEP-CA-PRED.
# -----------------------------------------------------------------

def best_single_move(A, A_init, a0, alpha):
    n = A.shape[0]
    base = L23(A, A_init, a0, alpha)
    best_delta = math.inf
    second_best = math.inf
    best_move = None
    for i in range(n):
        for j in range(n):
            A[i, j] ^= 1
            new = L23(A, A_init, a0, alpha)
            A[i, j] ^= 1
            d = new - base
            if d < best_delta:
                second_best = best_delta
                best_delta = d
                best_move = [(i, j)]
            elif d < second_best:
                second_best = d
    return best_delta, best_move, second_best


def best_two_move(A, A_init, a0, alpha, rng):
    n = A.shape[0]
    base = L23(A, A_init, a0, alpha)
    best_delta = math.inf
    second_best = math.inf
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
        new = L23(A, A_init, a0, alpha)
        A[i, j] ^= 1
        A[k, l] ^= 1
        d = new - base
        if d < best_delta:
            second_best = best_delta
            best_delta = d
            best_move = [(int(i), int(j)), (int(k), int(l))]
        elif d < second_best:
            second_best = d
    return best_delta, best_move, second_best


def step_pred(A, t, A_init, a0, alpha, rng, log):
    d1, m1, sb1 = best_single_move(A, A_init, a0, alpha)
    d2, m2, sb2 = best_two_move(A, A_init, a0, alpha, rng)
    if d1 <= d2:
        delta, move, sb = d1, m1, sb1
    else:
        delta, move, sb = d2, m2, sb2
    log.append({
        "t": t,
        "best_delta": delta,
        "second_best_delta": sb,
        "max_size_ratio": max(int((groups_from_rows(A) == g).sum())
                              for g in np.unique(groups_from_rows(A)))
                          / A.shape[0],
        "partition_entropy": partition_entropy(groups_from_rows(A)),
    })
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


def pred_descent(A_init, alpha):
    A = A_init.copy()
    a0 = normalize(A_init.sum(axis=1).astype(float))
    if np.linalg.norm(a0) < 1e-12:
        a0 = normalize(np.ones(A_init.shape[0]))
    rng = np.random.default_rng(SEED_RNG)
    log = []
    for t in range(T_STEPS):
        step_pred(A, t, A_init.astype(float), a0, alpha, rng, log)
    return A, a0, log


# -----------------------------------------------------------------
# Substrates (same 6 as cycles 19-22).
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


PATH_DENSE_SET = {"ER_n10_p30_seed1", "path_n10"}  # C22 winners


# -----------------------------------------------------------------
# Main.
# -----------------------------------------------------------------

def main():
    print("STEP-CA-PRED on Sixth substrate (cycle 23, Phase A)")
    print("Pre-reg: PREDICTIONS-142.md (commit 8572023)")
    print(f"alphas={ALPHAS}, gamma={GAMMA}, T={T_STEPS}, T0={T0}, "
          f"alpha_SA={ALPHA_SA}")
    print("=" * 78)

    substrates = test_substrates()
    results = {a: {} for a in ALPHAS}

    for alpha in ALPHAS:
        print(f"\n##### ALPHA = {alpha} #####")
        for (name, A_init) in substrates:
            print(f"\n  Substrate: {name}  (n={A_init.shape[0]})")
            A_final, a0, log = pred_descent(A_init, alpha)
            labels_sub = groups_from_rows(A_final)
            K = len(np.unique(labels_sub))
            labels_deg = groups_degree(A_init, K)

            pe_sub = pred_error(A_init.astype(float), labels_sub, a0,
                                 T_PRED)
            pe_deg = pred_error(A_init.astype(float), labels_deg, a0,
                                 T_PRED)

            delta_pred = pe_deg - pe_sub
            pred_win = pe_sub < pe_deg

            avg_sb = float(np.mean([abs(e["second_best_delta"])
                                    for e in log if not math.isinf(
                                        e["second_best_delta"])]))
            results[alpha][name] = {
                "K": K,
                "PE_sub": pe_sub,
                "PE_deg": pe_deg,
                "delta_pred": delta_pred,
                "pred_win": pred_win,
                "is_K1": K == 1,
                "avg_second_best": avg_sb,
            }
            print(f"    K={K}  PE_sub={pe_sub:.5f}  PE_deg={pe_deg:.5f}  "
                  f"delta={delta_pred:+.5f}  pred_win={pred_win}")

    print("\n" + "=" * 78)
    print("AGGREGATE per alpha:")
    summary = {}
    for alpha in ALPHAS:
        r = results[alpha]
        pw = sum(1 for v in r.values() if v["pred_win"])
        has_k1 = any(v["is_K1"] for v in r.values())
        mean_delta = float(np.mean([v["delta_pred"] for v in r.values()]))
        winners = {n for n, v in r.items() if v["pred_win"]}
        concentrated = (len(winners) > 0
                        and winners.issubset(PATH_DENSE_SET))
        summary[alpha] = {
            "pred_wins": pw, "has_K1": has_k1,
            "mean_delta": mean_delta, "concentrated": concentrated,
            "winners": winners,
        }
        print(f"  alpha={alpha}:  pred_wins={pw}  has_K1={has_k1}  "
              f"mean_delta={mean_delta:+.5f}  concentrated={concentrated}  "
              f"winners={winners}")

    # Best alpha = argmax(pred_wins); tiebreak mean_delta.
    best_alpha = max(ALPHAS, key=lambda a: (summary[a]["pred_wins"],
                                              summary[a]["mean_delta"]))
    s = summary[best_alpha]

    # robust_drop.
    r = results[best_alpha]
    names = list(r.keys())
    drops = []
    for to_remove in names:
        pw_minus = sum(1 for n, v in r.items()
                       if n != to_remove and v["pred_win"])
        drops.append(max(0, s["pred_wins"] - pw_minus))
    robust_drop = max(drops) if drops else 0

    print(f"\nBest alpha: {best_alpha}  (pred_wins={s['pred_wins']}, "
          f"mean_delta={s['mean_delta']:+.5f})")
    print(f"  concentrated: {s['concentrated']}  has_K1: {s['has_K1']}  "
          f"robust_drop: {robust_drop}")

    # Classify.
    if (s["pred_wins"] >= 4 and s["mean_delta"] > 0.005
            and not s["concentrated"] and not s["has_K1"]
            and robust_drop <= 1):
        regime = "AAAAA"
        meaning = ("STRONG PASS — predictive loss generalizes across "
                   "substrate families, beats degree consistently")
    elif (s["pred_wins"] >= 3 and not s["has_K1"]
            and s["mean_delta"] > 0):
        regime = "BBBBB"
        meaning = ("WEAK PASS — predictive loss helps on some substrates; "
                   "cycle 24 tests if effect grows on degree-blind benchmarks")
    else:
        regime = "CCCCC"
        meaning = ("FAIL — predictive-only loss does NOT improve over "
                   "degree on NSUM dynamics; cycle 24 Phase B (degree-blind) "
                   "distinguishes substrate failure vs benchmark artifact")
    print(f"\nRegime: {regime}")
    print(f"  {meaning}")

    # Critical diagnostic.
    deltas = [summary[a]["mean_delta"] for a in ALPHAS]
    delta_spread = max(deltas) - min(deltas)
    print(f"\nDiagnostic: delta_spread across alphas = {delta_spread:+.5f}")
    if delta_spread < 0.001:
        print("  -> Flat landscape across alphas suggests benchmark-artifact "
              "(degree IS the oracle); cycle 24 mandatory.")
    else:
        print("  -> Non-trivial alpha-sensitivity; landscape has structure "
              "but search may be limited.")


if __name__ == "__main__":
    main()
