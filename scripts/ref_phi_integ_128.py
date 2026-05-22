#!/usr/bin/env python3
"""
Independent phi-integ reference for cycle 10C cross-check.

Cycle 11A (PREDICTIONS-128.md attested at commit 6a1fd73).

phi-integ semantics (substrate-equivalent):
    NGET[v] := degree(v)   for all v
    NSUM[O] := sum(NGET[v] for v in out_neighbours(O))
    return degree(O) * 1 * NSUM[O] * L_max

For undirected G(n, p) with observer self-loop:
    out_neighbours(O) = {O} ∪ {v : edge (O, v)}
    degree(O) = 1 (self-loop) + len(other_neighbours)
    degree(v) for v ≠ O = len(neighbours(v))

CRITICAL: networkx undirected `degree(0)` with self-loop counts
it as 2 (one for each endpoint).  Substrate counts it as 1
(single directed self-loop edge).  We adjust by treating
substrate-style: count self-loop as +1 only.

For non-observer nodes (no self-loops in our setup), networkx
degree matches substrate OUT.
"""

import statistics

import networkx as nx


def substrate_style_degree(g: nx.Graph, node: int) -> int:
    """Return substrate-OUT-equivalent degree.

    networkx undirected degree counts self-loops as 2.
    Substrate counts self-loop as 1 directed edge.
    Adjust: subtract 1 if self-loop present, since networkx
    double-counted vs substrate's single count.
    """
    d = g.degree(node)
    if g.has_edge(node, node):
        d -= 1
    return d


def phi_integ(g: nx.Graph, observer: int = 0, l_max: int = 10000) -> int:
    """Compute substrate-equivalent phi-integ(observer) on graph g."""
    out_nbrs = set(g.neighbors(observer))
    # Add observer to its own out-neighbour set ONLY if self-loop present.
    if g.has_edge(observer, observer):
        out_nbrs.add(observer)
    nsum = sum(substrate_style_degree(g, v) for v in out_nbrs)
    return substrate_style_degree(g, observer) * nsum * l_max


def measure(n: int, p: float, m: int, seed_start: int = 1) -> dict:
    """Run M independent G(n, p) ER graphs with observer self-loop,
    compute phi-integ(0) each."""
    samples = []
    out0_samples = []
    nsum0_samples = []
    for s in range(seed_start, seed_start + m):
        g = nx.fast_gnp_random_graph(n, p, seed=s)
        # Add observer self-loop.
        g.add_edge(0, 0)
        val = phi_integ(g, 0)
        samples.append(val)
        out0_samples.append(substrate_style_degree(g, 0))
        # NSUM(0) = phi_integ / OUT(0) / L_max (recovered)
        nsum0_samples.append(val // 10000 // max(substrate_style_degree(g, 0), 1))
    return {
        "n": n,
        "p": p,
        "m": m,
        "mean": statistics.mean(samples),
        "stddev": statistics.stdev(samples) if m > 1 else 0.0,
        "min": min(samples),
        "max": max(samples),
        "median": statistics.median(samples),
        "out0_mean": statistics.mean(out0_samples),
        "nsum0_mean": statistics.mean(nsum0_samples),
    }


def report(name: str, stats: dict) -> None:
    print(f"=== {name} ===")
    print(f"  n={stats['n']}  p={stats['p']}  M={stats['m']}")
    print(f"  phi-integ mean       = {stats['mean']:.1f}")
    print(f"  phi-integ stddev     = {stats['stddev']:.1f}")
    print(f"  phi-integ median     = {stats['median']:.1f}")
    print(f"  phi-integ min, max   = {stats['min']}, {stats['max']}")
    sem = stats["stddev"] / (stats["m"] ** 0.5)
    print(f"  SEM                  = {sem:.1f}")
    print(f"  OUT(0) mean          = {stats['out0_mean']:.4f}")
    print(f"  NSUM(0) mean         = {stats['nsum0_mean']:.4f}")
    print()


def classify_regime(ref_mean: float, sub_mean: float, ana_mean: float) -> str:
    """Apply PREDICTIONS-128.md regime classifier."""
    d_sub = abs(ref_mean - sub_mean)
    d_ana = abs(ref_mean - ana_mean)
    sub_match = d_sub <= 5000
    ana_match = d_ana <= 9000

    if sub_match and ana_match:
        return ("D'", "cycle 10C STANDS — substrate AND analytic both confirmed")
    if sub_match and not ana_match:
        return ("E'", "substrate matches ref but analytic was off — review derivation")
    if not sub_match and ana_match:
        return ("F'", "substrate DEVIATES from ref — cycle 10C RETRACT; FIRST substrate-derived deviation")
    return ("G'", "neither matches — cycle 12 deep investigation")


SUBSTRATE_MEAN = 297650
ANALYTIC_MEAN = 303400
SUBSTRATE_STDDEV = 308074


if __name__ == "__main__":
    print("phi-integ reference Monte Carlo (cycle 11A / PREDICTIONS-128.md)")
    print("=" * 70)
    print()

    s = measure(n=20, p=0.10, m=10000, seed_start=1)
    report("PRIMARY: n=20, p=0.10, M=10000", s)

    ref_mean = s["mean"]

    print("Comparison:")
    print(f"  substrate (cycle 10C, M=1000):     {SUBSTRATE_MEAN}")
    print(f"  analytic (PREDICTIONS-127.md):     {ANALYTIC_MEAN}")
    print(f"  ref      (this run, M=10000):      {ref_mean:.1f}")
    print()
    print(f"  |ref - substrate| = {abs(ref_mean - SUBSTRATE_MEAN):.1f}")
    print(f"  |ref - analytic|  = {abs(ref_mean - ANALYTIC_MEAN):.1f}")
    print()

    regime, meaning = classify_regime(ref_mean, SUBSTRATE_MEAN, ANALYTIC_MEAN)
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")
    print()

    # Sub-prediction check.
    print("Sub-prediction (ref stddev ∈ [240000, 380000]):")
    sub_ok = 240000 <= s["stddev"] <= 380000
    print(f"  ref stddev      = {s['stddev']:.1f}")
    print(f"  substrate stddev= {SUBSTRATE_STDDEV} (cycle 10C)")
    print(f"  In bound:       = {sub_ok}")
    print()

    # Also report sanity: networkx OUT(0) and NSUM(0) for cross-validation.
    print("Substrate equivalence sanity (cycle 10C measured):")
    print(f"  E[OUT(0)] substrate  ≈ 2.85")
    print(f"  E[OUT(0)] networkx   = {s['out0_mean']:.4f}")
    print(f"  E[NSUM(0)] expected  ≈ 8.22 (PREDICTIONS-127.md formula)")
    print(f"  E[NSUM(0)] networkx  = {s['nsum0_mean']:.4f}")
