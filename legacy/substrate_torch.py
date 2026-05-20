"""
substrate_torch.py — PyTorch NN-shadow of the Sixth substrate engine.

Implements the same primitive operations
(MARK, EDGE+, IN, OUT, NEXT, PREV, NSET, NGET, NSUM, STEP-CA)
as the chibi-Scheme Sixth substrate (sixth-substrate.scm), but with all
state held as PyTorch tensors.  Adjacency lives in a sparse tensor;
node features in a dense tensor; iteration over substrate uses standard
tensor operations.

This is the bridge between the foundational Sixth substrate and the
applied NN architecture of Pointer Architecture v8.0:  every primitive
that Sixth provides as a Scheme function appears here as a tensor op,
allowing identical emergence demonstrations to be run on a GPU and,
crucially, allowing substrate state and rules to be made differentiable.

Three demos verify equivalence with Sixth:

  1.  Peano arithmetic:  numbers from MARK + EDGE+ + IN + PREV
  2.  BFS distance:      graph metric via parallel edge relaxation
  3.  Conway blinker:    2D CA on 5×5 Moore grid via NSUM + STEP-CA
"""
from __future__ import annotations

import torch


class TorchSubstrate:
    """Mutable substrate of nodes + directed edges with node features."""

    def __init__(self, device: str = "cpu"):
        self.device = device
        self.next_id = 0
        self.step_counter = 0
        # adjacency as sparse list-of-edges in {0,1}
        self.edges: set[tuple[int, int]] = set()
        # node features: id → float
        self.features: dict[int, float] = {}
        # born tracking
        self.born_at: dict[int, int] = {}

    # ---------- primitives ----------

    def MARK(self) -> int:
        self.next_id += 1
        self.features[self.next_id] = 0.0
        self.born_at[self.next_id] = self.step_counter
        return self.next_id

    def EDGE_PLUS(self, src: int, dst: int) -> None:
        self.edges.add((src, dst))

    def EDGE_MINUS(self, src: int, dst: int) -> None:
        self.edges.discard((src, dst))

    def EDGE_Q(self, src: int, dst: int) -> bool:
        return (src, dst) in self.edges

    def OUT(self, n: int) -> int:
        return sum(1 for s, _ in self.edges if s == n)

    def IN(self, n: int) -> int:
        return sum(1 for _, d in self.edges if d == n)

    def NEXT(self, n: int) -> int:
        for s, d in sorted(self.edges):
            if s == n:
                return d
        return 0

    def PREV(self, n: int) -> int:
        for s, d in sorted(self.edges):
            if d == n:
                return s
        return 0

    def STEP(self) -> None:
        self.step_counter += 1

    def NOW(self) -> int:
        return self.step_counter

    def BORN(self, n: int) -> int:
        return self.born_at.get(n, -1)

    def NSET(self, n: int, v: float) -> None:
        self.features[n] = float(v)

    def NGET(self, n: int) -> float:
        return self.features.get(n, 0.0)

    def NSUM(self, n: int) -> float:
        """Sum NGET of all out-neighbours of n (used for CA rules)."""
        s = 0.0
        for src, dst in self.edges:
            if src == n:
                s += self.features.get(dst, 0.0)
        return s

    # ---------- tensor views ----------

    def adjacency_tensor(self) -> torch.Tensor:
        """Dense adjacency matrix A[N+1, N+1] (index 0 unused)."""
        N = self.next_id
        A = torch.zeros((N + 1, N + 1), dtype=torch.float32, device=self.device)
        for s, d in self.edges:
            A[s, d] = 1.0
        return A

    def features_tensor(self) -> torch.Tensor:
        """Dense feature vector x[N+1] (index 0 unused, holds 0)."""
        N = self.next_id
        x = torch.zeros(N + 1, dtype=torch.float32, device=self.device)
        for k, v in self.features.items():
            x[k] = v
        return x

    def set_features_tensor(self, x: torch.Tensor) -> None:
        """Write features from a tensor x[N+1] back into the dictionary."""
        for i in range(1, self.next_id + 1):
            self.features[i] = float(x[i].item())

    # ---------- vectorised CA step ----------

    def STEP_CA(self, rule_tensor) -> None:
        """Apply a CA rule expressed as a tensor function.

        rule_tensor: function (state, neighbour_sum) → new_state,
                     both arguments are [N+1] tensors.
        """
        A = self.adjacency_tensor()       # [N+1, N+1]
        x = self.features_tensor()        # [N+1]
        nbr_sum = A @ x                   # standard message passing
        new_x = rule_tensor(x, nbr_sum)
        self.set_features_tensor(new_x)
        self.STEP()

    # ---------- BFS distance via parallel relaxation ----------

    def bfs_distance_tensor(self, source: int, max_iters: int = 50) -> torch.Tensor:
        """Compute single-source shortest paths as relaxation on
        the adjacency tensor.  Returns dist[N+1] (∞ for unreached)."""
        N = self.next_id
        INF = 10 ** 6
        dist = torch.full((N + 1,), INF, dtype=torch.float32, device=self.device)
        dist[source] = 0.0
        A = self.adjacency_tensor()       # [N+1, N+1]
        for _ in range(max_iters):
            # candidate[d] = min_s (dist[s] + 1) over edges s→d
            # Use: extend dist along edges, take min
            # masked broadcast: for each edge (s,d): dist[s] + 1 vs dist[d]
            extended = dist.unsqueeze(1) + 1.0       # [N+1, 1]
            # only consider where edge exists
            big = torch.full_like(A, INF)
            cand = torch.where(A > 0, extended.expand_as(A), big)
            new_dist = torch.min(dist, cand.min(dim=0).values)
            if torch.equal(new_dist, dist):
                break
            dist = new_dist
        return dist


# ============================================================
# Demo 1 — Peano arithmetic mirrors demo-numbers.6th
# ============================================================

def peano_succ(sub: TorchSubstrate, n: int) -> int:
    m = sub.MARK()
    sub.EDGE_PLUS(n, m)
    return m


def peano_value(sub: TorchSubstrate, n: int) -> int:
    v = 0
    while sub.IN(n) > 0:
        n = sub.PREV(n)
        v += 1
    return v


def peano_add(sub: TorchSubstrate, a: int, b: int) -> int:
    if sub.IN(b) == 0:
        return a
    return peano_succ(sub, peano_add(sub, a, sub.PREV(b)))


def peano_mul(sub: TorchSubstrate, a: int, b: int) -> int:
    if sub.IN(b) == 0:
        return sub.MARK()  # zero
    return peano_add(sub, a, peano_mul(sub, a, sub.PREV(b)))


def demo_peano():
    print("─" * 60)
    print("DEMO 1 — Peano arithmetic on PyTorch substrate")
    print("─" * 60)
    sub = TorchSubstrate()
    zero = sub.MARK()
    chain3 = peano_succ(sub, peano_succ(sub, peano_succ(sub, zero)))
    assert peano_value(sub, zero) == 0
    assert peano_value(sub, chain3) == 3
    a = peano_succ(sub, peano_succ(sub, sub.MARK()))            # 2
    b = peano_succ(sub, peano_succ(sub, peano_succ(sub, sub.MARK())))  # 3
    s = peano_add(sub, a, b)
    p = peano_mul(sub, a, b)
    assert peano_value(sub, s) == 5
    assert peano_value(sub, p) == 6
    print(f"  ✓ peano_value(0) = 0")
    print(f"  ✓ peano_value(chain of 3 succs) = 3")
    print(f"  ✓ peano_value(2 + 3) = 5")
    print(f"  ✓ peano_value(2 × 3) = 6")
    print(f"  substrate state: {sub.next_id} nodes, {len(sub.edges)} edges")


# ============================================================
# Demo 2 — BFS distance mirrors demo-distance.6th + demo-grid.6th
# ============================================================

def demo_distance_1d():
    print("─" * 60)
    print("DEMO 2a — 1D distance: chain a→b→c→d→e via tensor relaxation")
    print("─" * 60)
    sub = TorchSubstrate()
    a = sub.MARK(); b = sub.MARK(); c = sub.MARK()
    d = sub.MARK(); e = sub.MARK()
    sub.EDGE_PLUS(a, b)
    sub.EDGE_PLUS(b, c)
    sub.EDGE_PLUS(c, d)
    sub.EDGE_PLUS(d, e)
    dist = sub.bfs_distance_tensor(a)
    expected = [0, 1, 2, 3, 4]
    for i, ex in enumerate(expected, start=1):
        assert int(dist[i].item()) == ex
    print(f"  ✓ distances from a: {[int(dist[i].item()) for i in [a, b, c, d, e]]}")


def demo_distance_2d():
    print("─" * 60)
    print("DEMO 2b — 2D Manhattan: 3×3 grid bidirectional, BFS via tensor")
    print("─" * 60)
    sub = TorchSubstrate()
    # build 3×3 grid via numeric ids
    for _ in range(9):
        sub.MARK()                       # 9 cells, ids 1..9
    # (i,j) → id = (i-1)*3 + j
    def cid(i, j): return (i - 1) * 3 + j
    def bi(a, b):
        sub.EDGE_PLUS(a, b); sub.EDGE_PLUS(b, a)
    # rows
    for i in range(1, 4):
        for j in range(1, 3):
            bi(cid(i, j), cid(i, j + 1))
    # cols
    for j in range(1, 4):
        for i in range(1, 3):
            bi(cid(i, j), cid(i + 1, j))
    assert len(sub.edges) == 24
    dist = sub.bfs_distance_tensor(cid(1, 1))   # source: corner
    expected = {(1,1):0,(1,2):1,(1,3):2,(2,1):1,(2,2):2,
                (2,3):3,(3,1):2,(3,2):3,(3,3):4}
    for (i, j), ex in expected.items():
        actual = int(dist[cid(i, j)].item())
        assert actual == ex, f"d{(i,j)}: got {actual} want {ex}"
    print(f"  ✓ corner→far-corner Manhattan distance = "
          f"{int(dist[cid(3,3)].item())}")
    print(f"  ✓ all 9 cells have correct Manhattan distance")


# ============================================================
# Demo 3 — Conway blinker mirrors demo-conway.6th
# ============================================================

def demo_conway():
    print("─" * 60)
    print("DEMO 3 — Conway GoL blinker on 5×5 grid via tensor STEP-CA")
    print("─" * 60)
    sub = TorchSubstrate()
    for _ in range(25):
        sub.MARK()
    def cid(i, j): return (i - 1) * 5 + j
    def bi(a, b): sub.EDGE_PLUS(a, b); sub.EDGE_PLUS(b, a)
    # rows, cols, both diagonals (Moore neighbourhood)
    for i in range(1, 6):
        for j in range(1, 5):
            bi(cid(i, j), cid(i, j + 1))
    for j in range(1, 6):
        for i in range(1, 5):
            bi(cid(i, j), cid(i + 1, j))
    for i in range(1, 5):
        for j in range(1, 5):
            bi(cid(i, j), cid(i + 1, j + 1))   # NW-SE
    for i in range(1, 5):
        for j in range(2, 6):
            bi(cid(i, j), cid(i + 1, j - 1))   # NE-SW
    assert len(sub.edges) == 144

    # blinker: vertical column 3 at rows 2,3,4
    for n in range(1, 26):
        sub.NSET(n, 0.0)
    sub.NSET(cid(2, 3), 1.0)
    sub.NSET(cid(3, 3), 1.0)
    sub.NSET(cid(4, 3), 1.0)

    def conway_rule(state, nbr_sum):
        eq3 = (nbr_sum == 3).float()
        eq2 = (nbr_sum == 2).float()
        # next = 1 if eq3 else (state if eq2 else 0)
        return eq3 + (1.0 - eq3) * eq2 * state

    # step 1: should become horizontal
    sub.STEP_CA(conway_rule)
    assert sub.NGET(cid(2, 3)) == 0
    assert sub.NGET(cid(4, 3)) == 0
    assert sub.NGET(cid(3, 2)) == 1
    assert sub.NGET(cid(3, 3)) == 1
    assert sub.NGET(cid(3, 4)) == 1
    print(f"  ✓ step 1: blinker rotated vertical → horizontal")

    # step 2: back to vertical
    sub.STEP_CA(conway_rule)
    assert sub.NGET(cid(3, 2)) == 0
    assert sub.NGET(cid(3, 4)) == 0
    assert sub.NGET(cid(2, 3)) == 1
    assert sub.NGET(cid(3, 3)) == 1
    assert sub.NGET(cid(4, 3)) == 1
    print(f"  ✓ step 2: blinker oscillated back to vertical (period 2)")


# ============================================================
# main
# ============================================================

if __name__ == "__main__":
    print("=" * 60)
    print("NN-SHADOW OF SIXTH SUBSTRATE  (PyTorch tensors)")
    print("=" * 60)
    print()
    demo_peano()
    print()
    demo_distance_1d()
    demo_distance_2d()
    print()
    demo_conway()
    print()
    print("=" * 60)
    print("ALL TESTS PASS — NN-shadow reproduces Sixth substrate emergence.")
    print("=" * 60)
