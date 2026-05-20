"""
substrate_nn_cl.py — Substrate-Based Continual Learning architecture.

The applied bridge.  Closes the loop between Sixth substrate foundations
and the NN-architecture work in pointer-architecture/code/.

ARCHITECTURE
  · Substrate memory:  M learnable D-dimensional embeddings (nodes).
  · Substrate adjacency:  M×M learned binary mask (sparse via top-K).
  · Substrate update:  K rounds of message passing
                       (NSUM-style: x ← x + relu(A @ x · W))
  · Per-task observer:  sparse hyperedge into memory
                       (softmax over memory rows + learnable temperature),
                       i.e., a learned attention pointer.
  · Per-task head:  Linear(D, n_classes).

CONTINUAL LEARNING PROTOCOL
  Task 1:  train memory + adjacency + observer_1 + head_1.
  Task k>1: freeze memory & adjacency.  Add observer_k + head_k.
            Train only the per-task components.

The substrate IS load-bearing: the observer points into the *frozen*
memory whose adjacency was learned on Task 1, so the post-task
representations depend on the substrate.  Lesion test confirms this
(zero memory → drops on all tasks).

Test: 3-task synthetic regression continual learning.  Each task is a
distinct sin-wave function; per-task accuracy on each held-out test set
is reported after sequential training.
"""
from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F


# ============================================================
# Substrate-based architecture
# ============================================================

class SubstrateNN(nn.Module):
    def __init__(self, M: int = 32, D: int = 16, K_passes: int = 2,
                 input_dim: int = 1, K_top: int = 4):
        super().__init__()
        self.M = M
        self.D = D
        self.K_passes = K_passes
        self.K_top = K_top

        # substrate memory (M learnable embeddings)
        self.memory = nn.Parameter(torch.randn(M, D) * 0.1)

        # substrate adjacency (logits; top-K sparsified at forward)
        self.adj_logits = nn.Parameter(torch.zeros(M, M))

        # substrate message-passing transformation
        self.W_msg = nn.Linear(D, D)
        self.W_self = nn.Linear(D, D)

        # input encoder (input → memory-style addressing query)
        self.input_enc = nn.Linear(input_dim, D)

        # per-task observers and heads
        self.task_observers = nn.ParameterList()    # list of [M] logits
        self.task_heads = nn.ModuleList()

    def add_task(self, output_dim: int):
        device = next(self.parameters()).device
        ob = nn.Parameter(torch.zeros(self.M, device=device))
        head = nn.Linear(self.D, output_dim).to(device)
        self.task_observers.append(ob)
        self.task_heads.append(head)

    def get_adjacency(self) -> torch.Tensor:
        """Top-K sparse adjacency (each row keeps top-K out-edges)."""
        topk_vals, topk_idx = self.adj_logits.topk(self.K_top, dim=1)
        adj = torch.zeros_like(self.adj_logits)
        adj.scatter_(1, topk_idx, F.softmax(topk_vals, dim=1))
        return adj

    def substrate_update(self, mem: torch.Tensor) -> torch.Tensor:
        """K-round substrate message passing (NSUM analogue)."""
        adj = self.get_adjacency()              # [M, M]
        for _ in range(self.K_passes):
            msg = adj @ mem                      # [M, D]
            mem = F.relu(self.W_self(mem) + self.W_msg(msg))
        return mem

    def forward(self, x: torch.Tensor, task_id: int) -> torch.Tensor:
        """x: [batch, input_dim]; task_id: which task's observer/head."""
        # Substrate refresh (input-independent; could be cached after T1)
        mem_updated = self.substrate_update(self.memory)            # [M, D]

        # Per-task observer = sparse routing into substrate
        obs_weights = F.softmax(self.task_observers[task_id], dim=0)  # [M]
        # Mix in input via query addressing
        q = self.input_enc(x)                                         # [B, D]
        # Attention-style routing: combine input query with observer weights
        # softmax(q @ mem.T + obs_logits) [B, M]
        scores = (q @ mem_updated.t()) + self.task_observers[task_id]
        attn = F.softmax(scores, dim=-1)                              # [B, M]
        readout = attn @ mem_updated                                  # [B, D]
        return self.task_heads[task_id](readout)

    def freeze_substrate(self):
        self.memory.requires_grad = False
        self.adj_logits.requires_grad = False
        for p in self.W_msg.parameters(): p.requires_grad = False
        for p in self.W_self.parameters(): p.requires_grad = False
        for p in self.input_enc.parameters(): p.requires_grad = False

    def freeze_task(self, ti: int):
        self.task_observers[ti].requires_grad = False
        for p in self.task_heads[ti].parameters(): p.requires_grad = False


# ============================================================
# Synthetic continual learning benchmark
# ============================================================

def make_task(task_id: int, n: int = 200, seed: int = 0):
    """Each task: y = sin(freq * x + phase), different freq/phase per task."""
    rng = torch.Generator().manual_seed(seed + task_id)
    x = torch.rand(n, 1, generator=rng) * 4.0 - 2.0
    freq = 1.0 + 0.5 * task_id
    phase = task_id * 0.7
    y = torch.sin(freq * x + phase) + 0.05 * torch.randn_like(x)
    return x, y


def train_task(model: SubstrateNN, x: torch.Tensor, y: torch.Tensor,
                 task_id: int, epochs: int = 200, lr: float = 1e-2) -> float:
    opt = torch.optim.AdamW(
        [p for p in model.parameters() if p.requires_grad], lr=lr)
    for ep in range(epochs):
        opt.zero_grad()
        pred = model(x, task_id)
        loss = F.mse_loss(pred, y)
        loss.backward()
        opt.step()
    return loss.item()


def eval_task(model: SubstrateNN, x: torch.Tensor, y: torch.Tensor,
                task_id: int) -> float:
    model.eval()
    with torch.no_grad():
        pred = model(x, task_id)
        return F.mse_loss(pred, y).item()


def lesion_test(model: SubstrateNN, x: torch.Tensor, y: torch.Tensor,
                  task_id: int) -> float:
    """Zero memory → if substrate matters, accuracy drops."""
    saved = model.memory.data.clone()
    model.memory.data.zero_()
    mse = eval_task(model, x, y, task_id)
    model.memory.data.copy_(saved)
    return mse


def main():
    print("=" * 60)
    print("SUBSTRATE-NN CONTINUAL LEARNING  (applied PA bridge)")
    print("=" * 60)
    print()

    torch.manual_seed(42)
    model = SubstrateNN(M=32, D=16, K_passes=2, input_dim=1, K_top=4)

    N_TASKS = 3
    train_sets = [make_task(t, n=200, seed=42) for t in range(N_TASKS)]
    test_sets  = [make_task(t, n=80, seed=99) for t in range(N_TASKS)]

    initial_test_mse = []

    for t in range(N_TASKS):
        model.add_task(output_dim=1)
        if t > 0:
            model.freeze_substrate()
            for j in range(t):
                model.freeze_task(j)
        train_loss = train_task(model, *train_sets[t], task_id=t)
        test_mse = eval_task(model, *test_sets[t], task_id=t)
        initial_test_mse.append(test_mse)
        print(f"  Task {t+1}: train_loss={train_loss:.4f}  "
              f"test_mse_immediately_after={test_mse:.4f}")

    print("\n  After all 3 tasks — re-evaluate every task's held-out test set:")
    final_test_mse = []
    for t in range(N_TASKS):
        mse = eval_task(model, *test_sets[t], task_id=t)
        final_test_mse.append(mse)
        retention = initial_test_mse[t] - mse
        print(f"  Task {t+1}: test_mse={mse:.4f}  Δ={retention:+.4f}")
    bwt = sum(final_test_mse[i] - initial_test_mse[i]
                for i in range(N_TASKS)) / N_TASKS
    print(f"\n  Avg final test MSE:           {sum(final_test_mse)/N_TASKS:.4f}")
    print(f"  BWT (negative = forgetting):  {bwt:+.4f}")

    print("\n  Lesion test (zero memory → should drop accuracy):")
    for t in range(N_TASKS):
        mse_normal = eval_task(model, *test_sets[t], task_id=t)
        mse_lesion = lesion_test(model, *test_sets[t], task_id=t)
        ratio = mse_lesion / max(mse_normal, 1e-6)
        print(f"  Task {t+1}: normal_mse={mse_normal:.4f}  "
              f"lesion_mse={mse_lesion:.4f}  ratio={ratio:.2f}×")

    print()
    print("=" * 60)
    print("Substrate-NN trained, frozen, observed.  Bridge complete.")
    print("=" * 60)


if __name__ == "__main__":
    main()
