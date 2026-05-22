#!/usr/bin/env python3
"""
Counter-example search for SUBSTRATE-EQUIV-CONJECTURE.md Conjecture 2.

Cycle 12C (PREDICTIONS-131.md attested at commit 8adbdee).

Conjecture 2: For HEDGE3 substrate with n nodes and k typed
hyperedges, storage ratio
  R(S) = StorageCost_HEDGE3(S) / StorageCost_min_binary_equiv(S)
is bounded by a constant.

This script:
1. Enumerates small HEDGE3 substrate configurations
2. For each: computes both storage costs explicitly
3. Reports max R, min R, and configurations achieving extremes
4. Classifies regime per pre-registration:
   N — R_max > 2.0       → counter-example found
   O — R_max ∈ [1.5, 2]   → modest advantage
   P — R_max ∈ [1, 1.5)   → barely better
   Q — R_max < 1.0        → HEDGE3 wasteful, retract demo 105 claim

Storage accounting (per PREDICTIONS-131.md):

HEDGE3 storage cost per hyperedge: 5 fields
  (src, dst, witness, kind, hyperedge-id)
  → for k hyperedges: 5k units

Binary-equivalent encoding (must preserve same triadic relation
  information):
  - 1 auxiliary node H_i per hyperedge to represent identity
  - 3 binary edges (H_i, src), (H_i, dst), (H_i, witness) for
    structural relation
  - 1 edge label for kind ∈ {WITNESS, MEDIATOR, CONTEXT, SIMPLEX}
  → cost per hyperedge: 1 aux node + 3 edges + 1 label = 5 units

Pre-registered prediction: R(S) ≈ 1 (5/5) for all configurations,
likely regime P or O — demo 105's "5x" likely measured against
a sub-optimal binary baseline that didn't use the auxiliary-node
encoding.

The search is illuminating EITHER way:
  - finds R > 2: substrate has real storage advantage
  - finds R < 1: HEDGE3 is wasteful for some configs
  - finds R ≈ 1: HEDGE3 advantage was overstated; ergonomics only.
"""

import itertools
import random
from typing import Iterator


KINDS = ("WITNESS", "MEDIATOR", "CONTEXT", "SIMPLEX")


def hedge3_storage_cost(hyperedges: list) -> int:
    """Storage in 'units' for HEDGE3 representation.
    Each typed hyperedge has 5 fields: src, dst, witness, kind, id.
    """
    return 5 * len(hyperedges)


def binary_storage_cost(n_nodes: int, hyperedges: list) -> int:
    """Minimal binary-equivalent encoding cost.

    Per hyperedge (s, d, w, kind):
    - 1 auxiliary node H_i
    - 3 binary edges: (H_i, s), (H_i, d), (H_i, w)
    - 1 kind label stored as edge attribute or extra cell

    Total per hyperedge: 1 + 3 + 1 = 5 units.

    The base n_nodes are shared with HEDGE3 (both representations
    have the same N actual substrate nodes); we count only the
    INCREMENTAL cost added by hyperedge structure.
    """
    return 5 * len(hyperedges)


def shared_witness_optimization_cost(hyperedges: list) -> int:
    """Optimized binary cost if multiple hyperedges share the same
    witness — can merge aux nodes by witness.

    For each unique witness w, store one aux node + edges to it
    once.  This reduces redundancy when many hyperedges share
    witnesses.
    """
    if not hyperedges:
        return 0
    # Group by witness.
    by_witness = {}
    for (s, d, w, kind) in hyperedges:
        by_witness.setdefault(w, []).append((s, d, kind))

    cost = 0
    for w, sd_kinds in by_witness.items():
        # 1 aux node per witness shared.
        # Then for each (s, d, kind): 2 edges + 1 label.
        # Plus 1 edge to witness w from aux.
        cost += 1  # aux node
        cost += 1  # edge to witness
        for (s, d, kind) in sd_kinds:
            cost += 3  # edge to s, edge to d, kind label
    return cost


def shared_source_optimization_cost(hyperedges: list) -> int:
    """Try another aggregation: group by source.

    For each unique source s, store one aux node, then chains
    of (d, w, kind) attached.
    """
    if not hyperedges:
        return 0
    by_source = {}
    for (s, d, w, kind) in hyperedges:
        by_source.setdefault(s, []).append((d, w, kind))

    cost = 0
    for s, dwk in by_source.items():
        cost += 1  # aux node per source
        cost += 1  # edge to source
        for (d, w, kind) in dwk:
            cost += 3  # edges to d, w, label
    return cost


def minimal_binary_cost(n_nodes: int, hyperedges: list) -> int:
    """Take the minimum over several binary encoding strategies."""
    if not hyperedges:
        return 0
    naive = binary_storage_cost(n_nodes, hyperedges)
    shared_w = shared_witness_optimization_cost(hyperedges)
    shared_s = shared_source_optimization_cost(hyperedges)
    return min(naive, shared_w, shared_s)


def storage_ratio(n_nodes: int, hyperedges: list) -> float:
    """R(S) = HEDGE3 / minimal_binary_equiv."""
    binary = minimal_binary_cost(n_nodes, hyperedges)
    if binary == 0:
        return float("inf") if hyperedges else 1.0
    return hedge3_storage_cost(hyperedges) / binary


def enumerate_hyperedges(n_nodes: int, k: int, sample_budget: int) -> Iterator[list]:
    """Yield k-hyperedge configurations on n_nodes.

    Hyperedge: (s, d, w, kind) with s, d, w in [0, n) (not necessarily
    distinct — substrate allows degenerate hyperedges), kind ∈ KINDS.
    """
    all_triples = [
        (s, d, w, kind)
        for s in range(n_nodes)
        for d in range(n_nodes)
        for w in range(n_nodes)
        for kind in KINDS
    ]
    n_triples = len(all_triples)
    total_configs = 1
    try:
        # Binomial coefficient n_triples choose k
        from math import comb
        total_configs = comb(n_triples, k)
    except Exception:
        pass

    if total_configs <= sample_budget:
        # Exhaustive.
        for combo in itertools.combinations(all_triples, k):
            yield list(combo)
    else:
        # Random sample.
        rng = random.Random(12345)
        seen = set()
        for _ in range(sample_budget):
            sample = tuple(sorted(rng.sample(all_triples, k)))
            if sample not in seen:
                seen.add(sample)
                yield list(sample)


def search() -> dict:
    results = {
        "all_ratios": [],
        "max_R": 0.0,
        "max_R_config": None,
        "min_R": float("inf"),
        "min_R_config": None,
        "configs_examined": 0,
    }

    for n in [3, 4, 5, 6]:
        # Cap k at small number so we don't blow up enumeration.
        max_k = min(n * n, 6)  # at most 6 hyperedges
        for k in range(1, max_k + 1):
            sample_budget = 5000  # per (n, k)
            for hyperedges in enumerate_hyperedges(n, k, sample_budget):
                R = storage_ratio(n, hyperedges)
                results["all_ratios"].append((n, k, R))
                results["configs_examined"] += 1
                if R > results["max_R"]:
                    results["max_R"] = R
                    results["max_R_config"] = (n, list(hyperedges))
                if R < results["min_R"]:
                    results["min_R"] = R
                    results["min_R_config"] = (n, list(hyperedges))

    return results


def classify_regime(R_max: float) -> tuple:
    if R_max > 2.0:
        return ("N", "counter-example to constant-factor; HEDGE3 has > 2x advantage")
    if 1.5 <= R_max <= 2.0:
        return ("O", "modest advantage; HEDGE3 useful but bounded")
    if 1.0 <= R_max < 1.5:
        return ("P", "barely advantageous; demo 105's '5x' likely sub-optimal binary")
    return ("Q", "HEDGE3 WASTEFUL; binary encoding more compact; retract demo 105")


def main():
    print("Substrate counter-example search (cycle 12C / PREDICTIONS-131.md)")
    print("=" * 70)
    print()

    print("Running enumeration (n=3..6, k=1..6, sample budget 5000 per (n,k))...")
    results = search()
    print(f"Total configs examined: {results['configs_examined']}")
    print()

    print(f"Max R(S): {results['max_R']:.4f}")
    if results["max_R_config"]:
        n, he = results["max_R_config"]
        print(f"  achieved by n={n}, hyperedges={he}")
    print()

    print(f"Min R(S): {results['min_R']:.4f}")
    if results["min_R_config"]:
        n, he = results["min_R_config"]
        print(f"  achieved by n={n}, hyperedges={he}")
    print()

    # Distribution summary by n.
    print("Ratio distribution by n:")
    by_n = {}
    for (n, k, R) in results["all_ratios"]:
        by_n.setdefault(n, []).append(R)
    for n in sorted(by_n.keys()):
        ratios = by_n[n]
        print(f"  n={n}: N={len(ratios):5d}  min={min(ratios):.3f}  "
              f"max={max(ratios):.3f}  mean={sum(ratios)/len(ratios):.3f}")
    print()

    regime, meaning = classify_regime(results["max_R"])
    print(f"Regime classification: {regime}")
    print(f"  {meaning}")
    print()

    # If max R == 1.0 across the board, the conjecture-2 search is
    # confirmed (constant factor = 1, no asymptotic advantage).
    if abs(results["max_R"] - 1.0) < 1e-9 and abs(results["min_R"] - 1.0) < 1e-9:
        print("CONCLUSION: R(S) = 1.0 EXACTLY across all enumerated configs.")
        print("  HEDGE3 and minimal-binary encoding have IDENTICAL storage cost.")
        print("  Demo 105's '5x' advantage was against a sub-optimal binary")
        print("  baseline (likely used 5 cells per hyperedge in binary, but a")
        print("  more compact 'shared aux node' encoding matches HEDGE3 cost).")
        print()
        print("  This is a substrate-derived finding in the NEGATIVE direction:")
        print("  Conjecture 2 is CONFIRMED with constant F = 1 (no advantage).")
        print("  HEDGE3's value is purely ERGONOMIC, not storage-related.")


if __name__ == "__main__":
    main()
