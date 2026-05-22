#!/usr/bin/env python3
"""
Independent classical Erdős-Rényi Monte Carlo reference.

Cycle 9 (PREDICTIONS-125.md committed 99f33f0).

Purpose: compute E[|connected_component(node_0)|] for G(n=20, p=0.10)
via networkx + Mersenne Twister, independently of substrate's
LCG-RNG + bi-edge + observer self-loop pipeline.  Cycle 8 found
substrate phi-perc = 130,900 at this regime; classical asymptotic
formula gave 108,400.  This reference settles which side is wrong.

Methodology committed in PREDICTIONS-125.md:
  - networkx fast_gnp_random_graph (undirected simple G(n,p))
  - Mersenne Twister via networkx seed=1..1000
  - n=20, p=0.10, M=1000 independent graphs
  - For each graph: S_i = |connected_component(G, 0)|
  - Report mean(S_i) * 10000 (to compare with substrate phi-perc
    where L_max=10000)
  - Report stddev(S_i) * 10000 / sqrt(M) as standard error of mean
"""

import statistics

import networkx as nx


def measure(n: int, p: float, m: int, seed_start: int = 1) -> dict:
    """Run M independent G(n,p) graphs, compute |component(0)| each."""
    sizes = []
    for s in range(seed_start, seed_start + m):
        g = nx.fast_gnp_random_graph(n, p, seed=s)
        # node 0 always exists in fast_gnp_random_graph
        component = nx.node_connected_component(g, 0)
        sizes.append(len(component))
    return {
        "n": n,
        "p": p,
        "m": m,
        "mean": statistics.mean(sizes),
        "stddev": statistics.stdev(sizes) if m > 1 else 0.0,
        "min": min(sizes),
        "max": max(sizes),
        "median": statistics.median(sizes),
    }


def report(name: str, stats: dict, l_max: int = 10000) -> None:
    print(f"=== {name} ===")
    print(f"  n={stats['n']}  p={stats['p']}  M={stats['m']}")
    print(f"  mean(|C(0)|)        = {stats['mean']:.4f}")
    print(f"  stddev(|C(0)|)      = {stats['stddev']:.4f}")
    print(f"  median              = {stats['median']:.2f}")
    print(f"  min, max            = {stats['min']}, {stats['max']}")
    print(f"  mean × L_max        = {stats['mean'] * l_max:.1f}")
    print(f"  stddev × L_max      = {stats['stddev'] * l_max:.1f}")
    sem = stats["stddev"] * l_max / (stats["m"] ** 0.5)
    print(f"  standard error of mean × L_max = {sem:.1f}")
    print()


def classify_regime(mean_x_lmax: float) -> str:
    """Apply PREDICTIONS-125.md regime classifier."""
    if 100_000 <= mean_x_lmax <= 115_000:
        return ("A", "substrate finding STANDS — substrate phi-perc "
                     "deviates from true classical at near-critical")
    if 120_000 <= mean_x_lmax <= 140_000:
        return ("B", "cycle-8 finding RETRACTED as theory-side error — "
                     "asymptotic formula was wrong, substrate fine")
    return ("C", "unanticipated outcome — cycle 10 needed")


if __name__ == "__main__":
    # Primary measurement: matches substrate test exactly.
    print("Reference networkx Monte Carlo (cycle 9 / PREDICTIONS-125.md)")
    print("=" * 60)
    print()

    s = measure(n=20, p=0.10, m=1000, seed_start=1)
    report("PRIMARY: n=20, p=0.10, M=1000", s)

    # Tight: pre-registration committed M≥10000 fallback if SEM>2000.
    s_tight = measure(n=20, p=0.10, m=10000, seed_start=1)
    report("TIGHT: n=20, p=0.10, M=10000", s_tight)

    # Use tight measurement for regime classification (per pre-reg fallback).
    mean_x_lmax = s_tight["mean"] * 10000
    regime, meaning = classify_regime(mean_x_lmax)
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")
    print()

    # Comparison anchors (pre-registered values from PREDICTIONS-125.md):
    print("Comparison:")
    print(f"  Substrate phi-perc (cycle 8, M=100):       130,900")
    print(f"  Classical asymptotic formula:              108,400")
    print(f"  Reference M=1000:                          {s['mean']*10000:.1f}")
    print(f"  Reference M=10000 (tight):                 {mean_x_lmax:.1f}")
    print()

    # Sub-prediction: 1σ bound check on tight measurement.
    sem = s_tight["stddev"] * 10000 / (s_tight["m"] ** 0.5)
    print(f"Sub-prediction check: SEM × L_max = {sem:.1f}")
    if sem <= 2000:
        print("  ✓ SEM ≤ 2000 — reference is tight enough to discriminate A/B.")
    else:
        print("  ✗ SEM > 2000 — reference too noisy; increase M.")
    print()

    # Sanity ladder: also measure at p=15%, p=20%, p=30% for completeness.
    # These are not part of the cycle 9 hypothesis test but useful to know
    # whether the formula tracks reference at non-critical regimes.
    print("Sanity ladder (other p values from cycle 8):")
    print("-" * 60)
    for p_pct in (15, 20, 30):
        s2 = measure(n=20, p=p_pct / 100.0, m=1000, seed_start=1)
        m_x = s2["mean"] * 10000
        print(f"  p={p_pct}%: reference mean×L = {m_x:.1f}  "
              f"(cycle 8 substrate, formula)")
