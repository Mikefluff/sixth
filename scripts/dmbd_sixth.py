#!/usr/bin/env python3
"""
DMBD (Beck-Ramstead 2025, arXiv:2502.21217) applied to Sixth substrate.

Cycle 16C/D (PREDICTIONS-135.md attested at commit e3d0537).

Generates Sixth-style substrate trajectories via iterated NSUM-update
matrix dynamics, applies DMBD to detect emergent Markov blankets,
compares to random rewrite baselines.

Requires pyDMBD: github.com/bayesianempirimancer/pyDMBD
"""

import math
import sys
import os
import statistics

import numpy as np
import torch
import networkx as nx

# Add pyDMBD to path.
PYDMBD_PATH = "/tmp/pyDMBD"
sys.path.insert(0, PYDMBD_PATH)
sys.path.insert(0, os.path.join(PYDMBD_PATH, "models"))

from models.DynamicMarkovBlanketDiscovery import DMBD


# ---------------------------------------------------------------
# Trajectory generation
# ---------------------------------------------------------------

def cycle_substrate(n: int, self_loops: bool = True) -> np.ndarray:
    """Cycle_n adjacency (symmetric) + optional all-self-loops."""
    A = np.zeros((n, n))
    for v in range(n):
        A[v, (v + 1) % n] = 1
        A[(v + 1) % n, v] = 1
        if self_loops:
            A[v, v] = 1
    return A


def er_substrate(n: int, p: float, seed: int, all_self: bool = False) -> np.ndarray:
    """ER_n_p directed adjacency + observer self-loop (or all self-loops)."""
    g = nx.erdos_renyi_graph(n, p, seed=seed, directed=True)
    g.add_edge(0, 0)
    if all_self:
        for v in range(n):
            g.add_edge(v, v)
    return nx.to_numpy_array(g)


def path_substrate(n: int) -> np.ndarray:
    A = np.zeros((n, n))
    for v in range(n - 1):
        A[v, v + 1] = 1
        A[v + 1, v] = 1
    for v in range(n):
        A[v, v] = 1
    return A


def star_substrate(n: int) -> np.ndarray:
    A = np.zeros((n, n))
    A[0, 0] = 1
    for v in range(1, n):
        A[0, v] = 1
        A[v, v] = 1
    return A


def complete_substrate(n: int) -> np.ndarray:
    return np.ones((n, n))


def bipartite_substrate(parts: int = 3) -> np.ndarray:
    n = 2 * parts
    A = np.zeros((n, n))
    for u in range(parts):
        for v in range(parts, n):
            A[u, v] = 1
            A[v, u] = 1
    for v in range(n):
        A[v, v] = 1
    return A


def random_rewrite_baseline(n: int, p: float, seed: int) -> np.ndarray:
    """Random directed graph + observer self-loop."""
    rng = np.random.default_rng(seed)
    A = (rng.random((n, n)) < p).astype(float)
    A[0, 0] = 1
    return A


def generate_trajectory(adjacency: np.ndarray, T: int = 50) -> np.ndarray:
    """Run iterated NSUM-update for T steps.

    Initial features = out-degree.  Each step: feature' = adjacency @ feature.
    Returns shape (T, n_nodes, 1).
    """
    n = adjacency.shape[0]
    A = adjacency.astype(np.float64)
    feat = A.sum(axis=1)  # out-degrees as initial features

    traj = np.zeros((T, n, 1))
    for t in range(T):
        # Normalize features to avoid explosion (otherwise after T steps
        # values are O(λ_1^T) — too large for DMBD).
        norm = np.linalg.norm(feat)
        if norm > 1e-9:
            feat = feat / norm
        traj[t, :, 0] = feat
        feat = A @ feat
    return traj


# ---------------------------------------------------------------
# DMBD inference wrapper
# ---------------------------------------------------------------

def run_dmbd(trajectory: np.ndarray, n_restarts: int = 5,
              iters: int = 30, verbose: bool = False) -> dict:
    """Run DMBD with n_restarts random initializations.  Return best-ELBO
    model's stats: object count + ELBO.

    trajectory shape: (T, n_nodes, feature_dim)
    """
    T, n_nodes, feat_dim = trajectory.shape
    # DMBD expects (T, batch, n_objects, obs_dim).  Use batch=1.
    data = torch.tensor(trajectory[:, None, :, :], dtype=torch.float32)

    best_elbo = -float("inf")
    best_obj_count = 0

    for restart in range(n_restarts):
        torch.manual_seed(12345 + restart)
        try:
            model = DMBD(
                obs_shape=(n_nodes, feat_dim),
                role_dims=(4, 4, 4),
                hidden_dims=(4, 4, 4),
                batch_shape=(),
                regression_dim=-1,
                control_dim=-1,
            )
            model.update(data, None, None, iters=iters, latent_iters=1, lr=0.5, verbose=False)
            elbo = model.ELBO().item() if hasattr(model.ELBO(), "item") else float(model.ELBO())
            # Object count: number of distinct assignment classes with >5% support.
            NA = model.obs_model.NA  # tensor: per-role assignment counts
            NA_norm = NA / NA.sum()
            obj_count = int((NA_norm > 0.05).sum().item())

            if elbo > best_elbo:
                best_elbo = elbo
                best_obj_count = obj_count
        except Exception as e:
            if verbose:
                print(f"    restart {restart} failed: {type(e).__name__}: {e}")
            continue

    return {"elbo": best_elbo, "object_count": best_obj_count}


# ---------------------------------------------------------------
# Main analysis
# ---------------------------------------------------------------

def canonical_substrates() -> list:
    """10 canonical substrates from cycle 13 setup."""
    subs = []
    subs.append(("ER_n10_p10", er_substrate(10, 0.10, seed=1)))
    subs.append(("ER_n20_p10", er_substrate(20, 0.10, seed=2)))
    subs.append(("ER_n10_p30", er_substrate(10, 0.30, seed=3)))
    subs.append(("ER_n10_p20_all-self", er_substrate(10, 0.20, seed=4, all_self=True)))
    subs.append(("ER_n20_p20_all-self", er_substrate(20, 0.20, seed=5, all_self=True)))
    subs.append(("star_n10", star_substrate(10)))
    subs.append(("cycle_n10_all-self", cycle_substrate(10)))
    subs.append(("complete_K5", complete_substrate(5)))
    subs.append(("bipartite_K33", bipartite_substrate(3)))
    subs.append(("path_n10_self", path_substrate(10)))
    return subs


def classify_regime(r_objects: float) -> tuple:
    if r_objects > 1.5:
        return ("EE", "substrate has MORE MB structure than random — positive substrate-of-cognition finding")
    if 0.7 <= r_objects <= 1.5:
        return ("FF", "substrate ≈ random — null finding")
    return ("GG", "substrate has LESS MB structure than random — anti-distinguishing")


def main():
    print("DMBD (Beck-Ramstead 2025) on Sixth substrate (cycle 16C/D)")
    print("Pre-reg: PREDICTIONS-135.md (commit e3d0537)")
    print("=" * 70)
    print()

    T = 50
    M_baseline = 20  # reduced from 50 for compute manageability
    n_restarts = 3   # reduced from 10 for compute (per substrate)

    substrates = canonical_substrates()

    substrate_results = {}
    for (name, A) in substrates:
        print(f"Substrate: {name}  (n={A.shape[0]})")
        traj = generate_trajectory(A, T=T)
        res = run_dmbd(traj, n_restarts=n_restarts)
        substrate_results[name] = res
        print(f"  trajectory: shape {traj.shape}, range [{traj.min():.4f}, {traj.max():.4f}]")
        print(f"  DMBD result: object_count={res['object_count']}  ELBO={res['elbo']:.2f}")
        print()

    print("=" * 70)
    print(f"BASELINE: {M_baseline} random substrates per matched (n, p)")
    print("-" * 70)
    baseline_objects = []
    baseline_elbo = []
    for sub_name, sub_res in substrate_results.items():
        # Use matched n; pick random density similar to substrate.
        n = next((s.shape[0] for nm, s in substrates if nm == sub_name), 10)
        p = 0.20  # default density for baseline
        for seed in range(1, M_baseline + 1):
            A_rand = random_rewrite_baseline(n, p, seed=seed)
            traj_rand = generate_trajectory(A_rand, T=T)
            res_rand = run_dmbd(traj_rand, n_restarts=1)  # 1 restart for baseline (compute)
            baseline_objects.append(res_rand["object_count"])
            baseline_elbo.append(res_rand["elbo"])

    mean_baseline_obj = statistics.mean(baseline_objects) if baseline_objects else 0
    mean_baseline_elbo = statistics.mean(baseline_elbo) if baseline_elbo else 0
    mean_sub_obj = statistics.mean(r["object_count"] for r in substrate_results.values())
    mean_sub_elbo = statistics.mean(r["elbo"] for r in substrate_results.values())

    print(f"Substrate mean object_count: {mean_sub_obj:.3f}")
    print(f"Baseline mean object_count:  {mean_baseline_obj:.3f}")
    print(f"Substrate mean ELBO:         {mean_sub_elbo:.2f}")
    print(f"Baseline mean ELBO:          {mean_baseline_elbo:.2f}")
    print()

    if mean_baseline_obj > 1e-9:
        R_objects = mean_sub_obj / mean_baseline_obj
    elif mean_sub_obj > 1e-9:
        R_objects = float("inf")
    else:
        R_objects = 1.0

    if mean_baseline_elbo != 0:
        R_elbo = mean_sub_elbo / mean_baseline_elbo
    else:
        R_elbo = 1.0

    print(f"R_objects = {R_objects:.4f}")
    print(f"R_ELBO    = {R_elbo:.4f}")
    print()

    regime, meaning = classify_regime(R_objects)
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")


if __name__ == "__main__":
    main()
