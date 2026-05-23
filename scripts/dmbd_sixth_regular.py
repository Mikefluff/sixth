#!/usr/bin/env python3
"""
DMBD on Sixth substrate with DEGREE-MATCHED RANDOM REGULAR baseline.

Cycle 17 (PREDICTIONS-136.md attested at commit 33cef9a).

CS-doctor follow-up to cycle 16: replace sparse random baseline with
random k-regular graphs matching each substrate's mean degree.
Tests if R_ELBO = 1.489 signal survives stricter baseline (cycle 14
methodology pattern).
"""

import math
import sys
import os
import statistics

import numpy as np
import torch
import networkx as nx

PYDMBD_PATH = "/tmp/pyDMBD"
sys.path.insert(0, PYDMBD_PATH)
sys.path.insert(0, os.path.join(PYDMBD_PATH, "models"))
sys.path.insert(0, os.path.dirname(__file__))

from models.DynamicMarkovBlanketDiscovery import DMBD

# Re-use functions from cycle 16.
from dmbd_sixth import (
    cycle_substrate, er_substrate, path_substrate, star_substrate,
    complete_substrate, bipartite_substrate, canonical_substrates,
    generate_trajectory, run_dmbd,
)


def random_regular_baseline(n: int, mean_degree: float, seed: int) -> np.ndarray:
    """Random k-regular graph matched to substrate's mean degree.

    Per cycle 14 methodology: k = round(mean_degree), with n*k even
    (auto-adjust if needed).  Observer self-loop added (matches Sixth).
    """
    k = max(1, int(round(mean_degree)))
    # Ensure n*k even.
    if (n * k) % 2 != 0:
        if (n * (k - 1)) % 2 == 0 and k - 1 >= 1:
            k -= 1
        elif (n * (k + 1)) % 2 == 0:
            k += 1
        else:
            # Fallback to ER.
            p = mean_degree / max(n - 1, 1)
            rng = np.random.default_rng(seed)
            A = (rng.random((n, n)) < p).astype(float)
            A[0, 0] = 1
            return A
    if k >= n:
        k = n - 1
        if (n * k) % 2 != 0:
            k -= 1
    if k < 1:
        A = np.zeros((n, n))
        A[0, 0] = 1
        return A
    try:
        g = nx.random_regular_graph(k, n, seed=seed)
    except nx.NetworkXError:
        p = mean_degree / max(n - 1, 1)
        rng = np.random.default_rng(seed)
        A = (rng.random((n, n)) < p).astype(float)
        A[0, 0] = 1
        return A
    g = g.to_directed()
    g.add_edge(0, 0)
    return nx.to_numpy_array(g)


def classify_regime(r_elbo: float) -> tuple:
    if r_elbo > 1.3:
        return ("HH", "signal SURVIVES degree-matched baseline — genuine substrate-distinguishing finding")
    if 0.9 <= r_elbo <= 1.3:
        return ("II", "partial signal; modest substrate distinction")
    return ("JJ", "signal VANISHES — cycle 16 was sparse-baseline artifact; retract")


def main():
    print("DMBD with DEGREE-MATCHED RANDOM REGULAR baseline (cycle 17)")
    print("Pre-reg: PREDICTIONS-136.md (commit 33cef9a)")
    print("=" * 70)
    print()

    T = 50
    M_baseline = 20
    n_restarts = 3

    substrates = canonical_substrates()

    substrate_results = {}
    baseline_objects_all = []
    baseline_elbo_all = []

    for (name, A) in substrates:
        n = A.shape[0]
        n_edges = int(A.sum() - np.trace(A))
        mean_deg = n_edges / max(n, 1)
        k_regular = max(1, int(round(mean_deg)))

        print(f"Substrate: {name}  (n={n}, mean_deg={mean_deg:.2f}, k_regular={k_regular})")
        traj = generate_trajectory(A, T=T)
        sub_res = run_dmbd(traj, n_restarts=n_restarts)
        substrate_results[name] = sub_res
        print(f"  substrate: object_count={sub_res['object_count']}  ELBO={sub_res['elbo']:.2f}")

        # Degree-matched random regular baselines.
        per_baseline_obj = []
        per_baseline_elbo = []
        for seed in range(1, M_baseline + 1):
            A_r = random_regular_baseline(n, mean_deg, seed=seed)
            traj_r = generate_trajectory(A_r, T=T)
            res_r = run_dmbd(traj_r, n_restarts=1)
            per_baseline_obj.append(res_r["object_count"])
            per_baseline_elbo.append(res_r["elbo"])
            baseline_objects_all.append(res_r["object_count"])
            baseline_elbo_all.append(res_r["elbo"])
        print(f"  baseline mean: object_count={statistics.mean(per_baseline_obj):.3f}  "
              f"ELBO={statistics.mean(per_baseline_elbo):.2f}")
        print()

    # Aggregate.
    mean_sub_obj = statistics.mean(r["object_count"] for r in substrate_results.values())
    mean_sub_elbo = statistics.mean(r["elbo"] for r in substrate_results.values())
    mean_base_obj = statistics.mean(baseline_objects_all) if baseline_objects_all else 0
    mean_base_elbo = statistics.mean(baseline_elbo_all) if baseline_elbo_all else 0

    print("=" * 70)
    print(f"Substrate mean object_count: {mean_sub_obj:.3f}")
    print(f"Baseline mean object_count:  {mean_base_obj:.3f}")
    print(f"Substrate mean ELBO:         {mean_sub_elbo:.2f}")
    print(f"Baseline mean ELBO:          {mean_base_elbo:.2f}")
    print()

    R_objects = mean_sub_obj / mean_base_obj if mean_base_obj > 1e-9 else 1.0
    R_elbo = mean_sub_elbo / mean_base_elbo if mean_base_elbo != 0 else 1.0
    print(f"R_objects (cycle 17): {R_objects:.4f}  (cycle 16 was 0.7358)")
    print(f"R_ELBO    (cycle 17): {R_elbo:.4f}  (cycle 16 was 1.4890)")
    print()

    regime, meaning = classify_regime(R_elbo)
    print(f"Regime classification (primary R_ELBO): {regime}")
    print(f"  {meaning}")


if __name__ == "__main__":
    main()
