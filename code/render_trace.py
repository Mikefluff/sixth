#!/usr/bin/env python3
"""render_trace.py — render Sixth substrate-trace snapshots.

Reads a stream of Sixth DOT snapshots from stdin (or a file), each
preceded by a sentinel:
    === SNAPSHOT [meta-key=val ...] ===
followed by a `digraph substrate { ... }` block.

Outputs:
  - static multi-panel PNG / SVG / PDF (default)
  - animated GIF (--gif or .gif extension)
  - diff mode showing before/after/diff per step (--diff)
  - parallel JSONL trace for forensic reproducibility (--jsonl PATH)

Each rendered panel carries metadata extracted from the sentinel:
  rule=, seed=, step=, event=, observer=, nodes=, edges=
plus computed deltas Δn / Δe / Δlive vs the previous frame.

The JSONL trace is the machine-readable proof that the visualisation
is not a hand-drawn artefact: every snapshot includes the full edge
list, per-node labels (NGET state), and the metadata above, so an
external reviewer can replay or audit the trace without trusting
the rendered image.

Usage:
    racket -l sixth/cli -- run examples/37-trace-pilot-d.6th \\
        | python3 code/render_trace.py \\
            --out figures/pilot_d_trace.png \\
            --jsonl figures/pilot_d_trace.jsonl
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterator

import matplotlib.pyplot as plt
import matplotlib.animation as anim
import networkx as nx

SNAPSHOT_HEADER = re.compile(r"^===\s*SNAPSHOT\s*(.*?)\s*===\s*$")
DIGRAPH_OPEN = re.compile(r"^\s*digraph\s+\w+\s*\{")
DIGRAPH_CLOSE = re.compile(r"^\s*\}\s*$")
NODE_LINE = re.compile(r'^\s*"([^"]+)"\s*(\[[^\]]*\])?\s*;\s*$')
EDGE_LINE = re.compile(r'^\s*"([^"]+)"\s*->\s*"([^"]+)"\s*;\s*$')
LABEL_ATTR = re.compile(r'label\s*=\s*"([^"]*)"')


def _strip(node_id: str) -> str:
    """Sixth's `.` prints with trailing space; strip it."""
    return node_id.strip()


def parse_snapshots(stream: Iterator[str]):
    """Yield (metadata: dict[str,str], graph: nx.DiGraph) per snapshot.
    Graph nodes may carry a 'label' attribute extracted from DOT
    [label="N"] which the renderer uses for state-aware colouring
    (e.g. Conway alive/dead)."""
    current_meta: dict[str, str] | None = None
    in_digraph = False
    nodes: set[str] = set()
    node_labels: dict[str, str] = {}
    edges: list[tuple[str, str]] = []

    def emit():
        nonlocal current_meta, nodes, node_labels, edges
        if current_meta is None:
            return None
        graph = nx.DiGraph()
        graph.add_nodes_from(nodes)
        for nid, lbl in node_labels.items():
            graph.nodes[nid]["label"] = lbl
        graph.add_edges_from(edges)
        m = current_meta
        current_meta = None
        nodes = set()
        node_labels = {}
        edges = []
        return m, graph

    for line in stream:
        header = SNAPSHOT_HEADER.match(line)
        if header:
            yielded = emit()
            if yielded is not None:
                yield yielded
            # Sixth's `.` appends a trailing space, so "key=" and the
            # value end up as two whitespace-separated tokens. Walk
            # tokens, splitting on `=` and pairing key with the next
            # non-empty value token if needed.
            tokens = header.group(1).split()
            meta = {}
            i = 0
            while i < len(tokens):
                tok = tokens[i]
                if "=" in tok:
                    k, v = tok.split("=", 1)
                    k = k.strip()
                    v = v.strip()
                    if not v and i + 1 < len(tokens) and "=" not in tokens[i + 1]:
                        v = tokens[i + 1].strip()
                        i += 1
                    if k:
                        meta[k] = v
                i += 1
            current_meta = meta
            in_digraph = False
            continue

        if DIGRAPH_OPEN.match(line):
            in_digraph = True
            continue
        if in_digraph and DIGRAPH_CLOSE.match(line):
            in_digraph = False
            continue
        if not in_digraph:
            continue

        edge = EDGE_LINE.match(line)
        if edge:
            src = _strip(edge.group(1))
            dst = _strip(edge.group(2))
            nodes.add(src)
            nodes.add(dst)
            edges.append((src, dst))
            continue
        node = NODE_LINE.match(line)
        if node:
            nid = _strip(node.group(1))
            nodes.add(nid)
            attrs = node.group(2) or ""
            m = LABEL_ATTR.search(attrs)
            if m:
                node_labels[nid] = m.group(1).strip()
            continue

    yielded = emit()
    if yielded is not None:
        yield yielded


def render(snapshots, out_path: Path, title: str | None,
           layout: str = "auto") -> None:
    snaps = list(snapshots)
    if not snaps:
        sys.exit("no snapshots found in input")

    n = len(snaps)
    # Chain layouts read top-to-bottom as a time series — one row per
    # snapshot, all in a single column.  Otherwise default 5-wide grid.
    if layout == "chain":
        cols, rows = 1, n
        panel_w, panel_h = 9.0, 1.6
    elif layout == "tiered":
        cols = min(n, 5)
        rows = (n + cols - 1) // cols
        panel_w, panel_h = 5.6, 4.6
    else:
        cols = min(n, 5)
        rows = (n + cols - 1) // cols
        panel_w = panel_h = 3.2
    fig, axes = plt.subplots(
        rows, cols,
        figsize=(panel_w * cols, panel_h * rows),
        squeeze=False,
    )

    label_max = _global_label_max(snaps)
    for idx, (meta, graph) in enumerate(snaps):
        ax = axes[idx // cols][idx % cols]
        _draw_snapshot(ax, meta, graph, idx,
                       label_max=label_max, layout=layout)

    # Hide unused axes.
    for i in range(n, rows * cols):
        axes[i // cols][i % cols].set_axis_off()

    suptitle = _figure_suptitle(snaps, title)
    if suptitle:
        fig.suptitle(suptitle, fontsize=10)
        fig.tight_layout(rect=(0, 0, 1, 0.93))
    else:
        fig.tight_layout()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    print(f"wrote {out_path} ({n} panels)", file=sys.stderr)


_PRIMARY_KEYS = ("step", "shell-count", "cycle", "case", "frame")
_DELTA_KEYS = ("Δn", "Δe", "Δlive")
_HEADER_KEYS = ("rule", "seed")
_PA_KEYS = ("phi-pa", "phi-integ", "phi-bidir", "nsum-O", "target-min", "self-ref")
_HIDDEN_KEYS = (set(_PRIMARY_KEYS) | set(_DELTA_KEYS) | set(_HEADER_KEYS)
                | set(_PA_KEYS)
                | {"event", "observer", "nodes", "edges"})


def _panel_title(meta: dict[str, str], idx: int) -> str:
    """Two-line per-panel title.
    Line 1: step + event       (frame identity)
    Line 2: n/e + Δn/Δe/Δlive  (size + per-step deltas)
    Heavy metadata (rule, seed) lives in the figure suptitle.
    Anything left over (nsum, nget, …) lands on a third line."""
    if not meta:
        return f"snapshot {idx}"
    lead = next(
        (f"{k}={meta[k]}" for k in _PRIMARY_KEYS if k in meta),
        f"#{idx}",
    )
    line1 = [lead]
    if "event" in meta:
        line1.append(meta["event"])

    line2 = []
    if "nodes" in meta and "edges" in meta:
        line2.append(f"n={meta['nodes']} e={meta['edges']}")
    deltas = [f"{k}={meta[k]}" for k in _DELTA_KEYS if k in meta]
    if deltas:
        line2.append(" ".join(deltas))

    # Pull PA-specific signals (Φ_PA family, NSUM target, self-ref) onto
    # their own line — these are what makes the panel substrate-monism
    # readable rather than "yet another graph snapshot".  Any key whose
    # name STARTS with "phi-" is treated as a per-observer Φ value
    # (e.g. phi-pa-OA, phi-pa-M2) and joins the same line so
    # multi-observer demos don't bury them in the unstructured extras.
    pa_keys_in_meta = [k for k in _PA_KEYS if k in meta]
    extra_phi_keys = sorted(
        k for k in meta
        if k.startswith("phi-") and k not in pa_keys_in_meta
    )
    pa_items = [f"{k}={meta[k]}" for k in pa_keys_in_meta + extra_phi_keys]

    # "level" is redundant with the tier the node sits at in tiered
    # layouts, and is already implied by frame index elsewhere — drop it
    # to keep the title compact.
    extras = [
        f"{k}={v}" for k, v in meta.items()
        if k not in _HIDDEN_KEYS
        and not k.startswith("phi-")
        and k != "level"
    ]

    lines = ["  ·  ".join(line1)]
    if line2:
        lines.append("  ·  ".join(line2))
    # Wrap PA-line at 4 items per row so a multi-observer snapshot
    # doesn't bleed off the panel edge.
    for i in range(0, len(pa_items), 4):
        lines.append("  ".join(pa_items[i:i + 4]))
    if extras:
        lines.append(" ".join(extras))
    return "\n".join(lines)


def _figure_suptitle(snaps, fallback: str | None) -> str:
    """Lift rule/seed to figure-level suptitle when present and stable
    across the trace."""
    if not snaps:
        return fallback or ""
    bits = []
    for k in _HEADER_KEYS:
        vals = {meta.get(k) for meta, _g in snaps if meta and meta.get(k)}
        if len(vals) == 1:
            bits.append(f"{k}: {next(iter(vals))}")
        elif len(vals) > 1:
            bits.append(f"{k}: <varies>")
    rule_seed = "  ·  ".join(bits)
    if fallback and rule_seed:
        return f"{fallback}\n{rule_seed}"
    return rule_seed or (fallback or "")


def _annotate_deltas(snaps):
    """Mutate snapshot metadata in place with Δn, Δe, Δlive vs prev."""
    prev_nodes = None
    prev_edges = None
    prev_live = None
    for meta, graph in snaps:
        n = graph.number_of_nodes()
        e = graph.number_of_edges()
        live = sum(
            1 for nd in graph.nodes
            if int(graph.nodes[nd].get("label", "0") or "0") > 0
        )
        if prev_nodes is not None:
            meta["Δn"] = f"{n - prev_nodes:+d}"
            meta["Δe"] = f"{e - prev_edges:+d}"
            meta["Δlive"] = f"{live - prev_live:+d}"
        else:
            meta["Δn"] = "—"
            meta["Δe"] = "—"
            meta["Δlive"] = "—"
        prev_nodes, prev_edges, prev_live = n, e, live
    return snaps


def write_jsonl(snaps, out_path: Path) -> None:
    """Write the snapshot stream as a JSONL trace — one object per
    frame, with metadata + edge list + per-node labels. This is the
    forensic-trace artefact: a machine-readable proof that the
    visualisation reflects an actual substrate execution."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w") as f:
        for idx, (meta, graph) in enumerate(snaps):
            obj = {
                "snapshot_index": idx,
                "metadata": dict(meta) if meta else {},
                "nodes": sorted(graph.nodes),
                "edges": sorted([list(e) for e in graph.edges]),
                "node_labels": {
                    n: graph.nodes[n].get("label")
                    for n in graph.nodes
                    if "label" in graph.nodes[n]
                },
            }
            f.write(json.dumps(obj, sort_keys=True, default=str) + "\n")
    print(f"wrote {out_path} ({len(snaps)} JSONL frames)", file=sys.stderr)


def _diff_panel(ax, meta, prev_graph, graph, idx) -> None:
    """Three-state diff: green = added, red = removed, grey = unchanged."""
    if graph.number_of_nodes() == 0:
        ax.set_axis_off()
        ax.set_title(_panel_title(meta, idx), fontsize=8)
        return

    prev_nodes = set(prev_graph.nodes) if prev_graph else set()
    prev_edges = set(prev_graph.edges) if prev_graph else set()
    curr_nodes = set(graph.nodes)
    curr_edges = set(graph.edges)

    union = nx.DiGraph()
    union.add_nodes_from(prev_nodes | curr_nodes)
    union.add_edges_from(prev_edges | curr_edges)
    try:
        pos = nx.kamada_kawai_layout(union)
    except Exception:
        pos = nx.spring_layout(union, seed=42)

    node_color = []
    for n in union.nodes:
        if n in curr_nodes and n not in prev_nodes:
            node_color.append("#2eb02e")   # added — green
        elif n in prev_nodes and n not in curr_nodes:
            node_color.append("#d04040")   # removed — red
        else:
            node_color.append("#a8a8a8")   # unchanged — grey

    edge_color = []
    for u, v in union.edges:
        if (u, v) in curr_edges and (u, v) not in prev_edges:
            edge_color.append("#1f8b1f")
        elif (u, v) in prev_edges and (u, v) not in curr_edges:
            edge_color.append("#b03030")
        else:
            edge_color.append("#888888")

    ax.clear()
    nx.draw_networkx_edges(
        union, pos, ax=ax,
        edge_color=edge_color, arrows=True, arrowsize=8,
        width=1.0, connectionstyle="arc3,rad=0.08",
    )
    nx.draw_networkx_nodes(
        union, pos, ax=ax,
        node_color=node_color, node_size=180,
        linewidths=0.5, edgecolors="black",
    )
    nx.draw_networkx_labels(
        union, pos, ax=ax, font_size=7, font_color="white",
    )
    ax.set_axis_off()
    ax.set_title(_panel_title(meta, idx) + "  [DIFF added/removed/—]",
                 fontsize=8)


def render_diff(snapshots, out_path: Path, title: str | None) -> None:
    """Render per-step diffs: panel N shows what changed from N-1 to N.
    Frame 0 omitted (no prior frame to diff against)."""
    snaps = list(snapshots)
    if len(snaps) < 2:
        sys.exit("diff mode needs at least 2 snapshots")

    n = len(snaps) - 1
    cols = min(n, 5)
    rows = (n + cols - 1) // cols
    fig, axes = plt.subplots(
        rows, cols, figsize=(3.6 * cols, 3.6 * rows), squeeze=False,
    )
    for idx in range(1, len(snaps)):
        ax = axes[(idx - 1) // cols][(idx - 1) % cols]
        prev_meta, prev_graph = snaps[idx - 1]
        meta, graph = snaps[idx]
        _diff_panel(ax, meta, prev_graph, graph, idx)
    for i in range(n, rows * cols):
        axes[i // cols][i % cols].set_axis_off()
    suptitle = _figure_suptitle(snaps, title)
    if suptitle:
        fig.suptitle(suptitle + "  —  per-step DIFF view", fontsize=10)
        fig.tight_layout(rect=(0, 0, 1, 0.93))
    else:
        fig.tight_layout()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    print(f"wrote {out_path} ({n} diff panels)", file=sys.stderr)


def _observer_node(meta: dict[str, str], graph) -> str | None:
    """Sixth's snapshot metadata may carry `observer=N` — honour it
    so the highlighted node is the substrate's actual observer.

    Fallback when metadata is missing: pick the node with the highest
    out-degree (observers in every Pilot demo are the substrate's
    highest-OUT node by construction).  Tie-break on lowest node id
    for determinism."""
    obs = meta.get("observer") if meta else None
    if obs and obs in graph.nodes:
        return obs
    if graph.number_of_nodes() == 0:
        return None
    return max(
        graph.nodes,
        key=lambda n: (graph.out_degree(n), -int(n) if str(n).lstrip("-").isdigit() else 0),
    )


def _global_label_max(snaps) -> int:
    """Compute the max integer node-label seen across the whole trace.
    Per-snapshot max would collapse (e.g. autopoiesis after-decay where
    every node = 2 and after-restore where every node = 10) into
    identical visuals; a trace-wide max preserves the gradient."""
    g_max = 0
    for _meta, g in snaps:
        for n in g.nodes:
            lbl = g.nodes[n].get("label", "")
            try:
                v = int(lbl)
            except (TypeError, ValueError):
                v = 0
            g_max = max(g_max, v)
    return g_max


def _tier_from_label(label_val: int) -> int:
    """Map a NGET tag to a hierarchy tier.

    Convention used by Pilots G/H/I and any future hierarchical demo:
      NGET = 0              → tier 0  (substrate, limbs)
      NGET ∈ {1, 2, 3}      → tier 1  (level-1 observers / instances /
                                       per-species particles)
      NGET ∈ {5, 6, 7}      → tier 2  (level-2 observers / families /
                                       meta-observers)
      NGET ≥ 8              → tier 3  (level-3+ meta-meta-observers)
    Other values fall back to tier 0.  Demos opt in by tagging.
    """
    if label_val <= 0:
        return 0
    if 1 <= label_val <= 3:
        return 1
    if 5 <= label_val <= 7:
        return 2
    if label_val >= 8:
        return 3
    return 0


# Species/observer hues — categorical, not gradient.  Tier 1 gets the
# primary hue per species; tier 2 gets a darker shade of the same hue
# so a family observer reads as "of the same kin" as its instances;
# tier 3 gets a distinct gold.
_TIER_PALETTE = {
    0: "#d0d0d0",          # limbs / background
    1: "#2b8a8a",          # species α
    2: "#d49a1a",          # species β
    3: "#884a8a",          # species γ
    5: "#175555",          # family-α observer (dark teal)
    6: "#9a7012",          # family-β observer (dark amber)
    7: "#5c2f5c",          # family-γ observer (dark plum)
    8: "#2a5f8f",          # bound-state composite marker (Pilot L)
    9: "#c43030",          # genus / meta-meta observer (bold red)
}
_TIER_FALLBACK = "#909090"


def _tier_colour(label_val: int) -> str:
    return _TIER_PALETTE.get(label_val, _TIER_FALLBACK)


# Node sizes grow with tier so the hierarchy is unmissable.
_TIER_SIZE = {0: 90, 1: 320, 2: 620, 3: 980}


def _chain_layout(graph):
    """Horizontal-line layout — nodes placed left-to-right by integer id.

    Designed for 1D-chain CA demos (Pilot J charge conservation, Rule 110/
    90 traces, Conway 1D glider) where the substrate topology IS a linear
    sequence and the natural reading direction is left-to-right.
    """
    if graph.number_of_nodes() == 0:
        return {}
    nodes = list(graph.nodes)
    nodes.sort(key=lambda n: int(n) if n.isdigit() else 0)
    n = len(nodes)
    return {node: ((i / max(n - 1, 1)) * 2.0 - 1.0, 0.0)
            for i, node in enumerate(nodes)}


def _tiered_layout(graph, label_values):
    """Multipartite layout keyed by tier — tier 0 at bottom, tier 3 at top.

    Within a tier, networkx spaces nodes evenly across the band.  Members
    of the same tier are sorted by integer node id (Sixth substrate MARKs
    are sequential integers) so the layout is deterministic and limbs of
    the same instance tend to cluster.
    """
    if graph.number_of_nodes() == 0:
        return {}
    tier_attr = {n: _tier_from_label(label_values.get(n, 0))
                 for n in graph.nodes}
    # Inject as node attribute so networkx multipartite_layout can read.
    for n, t in tier_attr.items():
        graph.nodes[n]["_tier"] = t
    try:
        pos = nx.multipartite_layout(
            graph, subset_key="_tier", align="horizontal")
    except Exception:
        # Fall back gracefully if some tier is empty in a weird way.
        pos = nx.kamada_kawai_layout(graph)
    return pos


def _is_hierarchical_layout(layout: str) -> bool:
    return layout in ("tiered",)


def _draw_snapshot(ax, meta, graph, idx, fixed_pos=None, label_max=None,
                   layout="auto") -> None:
    if graph.number_of_nodes() == 0:
        ax.set_axis_off()
        ax.set_title(_panel_title(meta, idx), fontsize=9)
        return

    observer_id = _observer_node(meta, graph)
    has_labels = any("label" in graph.nodes[n] for n in graph.nodes)

    # Build a label→intensity scale so NGET=2 vs NGET=10 render as
    # visually distinct shades, not collapsed into binary "alive/dead".
    # Conway demos keep binary semantics (max=1); autopoiesis demos
    # (max=10) get full gradient.  Use trace-wide max (passed in)
    # rather than per-snapshot max, otherwise after-decay and
    # after-restore frames each normalise to their own max and look
    # identical even though NGET genuinely changed.
    label_values: dict[str, int] = {}
    if has_labels:
        for n in graph.nodes:
            try:
                label_values[n] = int(graph.nodes[n].get("label", "0") or "0")
            except ValueError:
                label_values[n] = 0
    max_lbl = label_max if label_max is not None else (
        max(label_values.values(), default=0) if has_labels else 0
    )

    def _label_colour(v: int) -> str:
        # Light grey at 0 → deep red at max.  Linear ramp through a fixed
        # palette so output is deterministic without matplotlib colormap
        # state.  Five stops are enough to read "decayed vs restored".
        if max_lbl == 0:
            return "#e0e0e0"
        ratio = max(0.0, min(1.0, v / max_lbl))
        stops = ["#e8e8e8", "#f5c4c4", "#e98080", "#d04040", "#a01818"]
        idx = int(round(ratio * (len(stops) - 1)))
        return stops[idx]

    def _node_colour(n: str) -> str:
        # State-aware: label intensity for non-observers; observer keeps
        # its distinctive red regardless of label so it never disappears
        # into the background during an autopoiesis decay frame.
        if n == observer_id:
            return "#c43030"
        if has_labels:
            return _label_colour(label_values.get(n, 0))
        return "#909090"

    if layout in ("tiered", "chain") and has_labels:
        # Categorical palette by NGET — same hues whether stacked by
        # tier (tiered) or laid out linearly (chain).
        node_colors = [_tier_colour(label_values.get(n, 0))
                       for n in graph.nodes]
        if layout == "tiered":
            node_sizes = [_TIER_SIZE.get(
                              _tier_from_label(label_values.get(n, 0)), 220)
                          for n in graph.nodes]
            node_borders = [
                (2.2 if _tier_from_label(label_values.get(n, 0)) >= 2 else 0.8)
                for n in graph.nodes
            ]
        else:  # chain
            # Uniform "cell" size on a chain; non-empty cells get heavier
            # border so the occupied vs vacuum split is obvious.
            node_sizes = [
                (520 if label_values.get(n, 0) > 0 else 220)
                for n in graph.nodes
            ]
            node_borders = [
                (1.8 if label_values.get(n, 0) > 0 else 0.6)
                for n in graph.nodes
            ]
    else:
        node_colors = [_node_colour(n) for n in graph.nodes]
        # Observer is structurally load-bearing in PA — give it ~3× area
        # and a thick black border so the figure encodes its role rather
        # than treating it as one node among many.  Self-loops get extra
        # width because the Spencer-Brown bootstrap distinction is THE
        # visual marker of substrate-monism.
        node_sizes = [550 if n == observer_id else 220 for n in graph.nodes]
        node_borders = [2.2 if n == observer_id else 0.8 for n in graph.nodes]
    edge_colors = [
        "#c43030" if u == v else "#606060"
        for (u, v) in graph.edges
    ]
    edge_widths = [
        2.6 if u == v else 0.8
        for (u, v) in graph.edges
    ]
    if fixed_pos is not None:
        pos = {n: fixed_pos[n] for n in graph.nodes if n in fixed_pos}
        if len(pos) != graph.number_of_nodes():
            # Fall back if any node is missing from fixed positions.
            if layout == "tiered":
                pos = _tiered_layout(graph, label_values)
            elif layout == "chain":
                pos = _chain_layout(graph)
            else:
                pos = nx.kamada_kawai_layout(graph)
    elif layout == "tiered":
        pos = _tiered_layout(graph, label_values)
    elif layout == "chain":
        pos = _chain_layout(graph)
    else:
        try:
            pos = nx.kamada_kawai_layout(graph)
        except Exception:
            pos = nx.spring_layout(graph, seed=42)

    ax.clear()
    nx.draw_networkx_edges(
        graph, pos, ax=ax,
        edge_color=edge_colors,
        arrows=True,
        arrowsize=8,
        width=edge_widths,
        connectionstyle="arc3,rad=0.08",
    )
    nx.draw_networkx_nodes(
        graph, pos, ax=ax,
        node_color=node_colors,
        node_size=node_sizes,
        linewidths=node_borders,
        edgecolors="black",
    )
    nx.draw_networkx_labels(
        graph, pos, ax=ax,
        font_size=7,
        font_color="white",
    )

    ax.set_axis_off()
    ax.set_title(_panel_title(meta, idx), fontsize=9)


def _union_layout(snaps, layout: str = "auto"):
    """Pre-compute positions for the union of all snapshot graphs so
    a node that appears across multiple frames stays in the same
    place — eliminates the "jiggle" the user reported on early GIFs."""
    union = nx.DiGraph()
    union_labels: dict[str, int] = {}
    for _meta, graph in snaps:
        union.add_nodes_from(graph.nodes)
        union.add_edges_from(graph.edges)
        for n in graph.nodes:
            try:
                v = int(graph.nodes[n].get("label", "0") or "0")
            except ValueError:
                v = 0
            # Take the max NGET seen across snapshots so an observer
            # tagged late still anchors to its tier in earlier frames
            # where it didn't yet exist.
            if v > union_labels.get(n, 0):
                union_labels[n] = v
    if union.number_of_nodes() == 0:
        return {}
    if layout == "tiered":
        return _tiered_layout(union, union_labels)
    if layout == "chain":
        return _chain_layout(union)
    try:
        return nx.kamada_kawai_layout(union)
    except Exception:
        return nx.spring_layout(union, seed=42)


def render_gif(snapshots, out_path: Path, title: str | None,
               fps: int, layout: str = "auto") -> None:
    snaps = list(snapshots)
    if not snaps:
        sys.exit("no snapshots found in input")

    # Compute layout ONCE on the union of every snapshot's graph so
    # nodes that persist across frames stay in the same place — kills
    # the layout-jiggle problem reported on early GIFs.
    union_pos = _union_layout(snaps, layout=layout)
    label_max = _global_label_max(snaps)

    fig_w = 8.5 if layout == "tiered" else 6.5
    fig, ax = plt.subplots(figsize=(fig_w, 6.5))
    suptitle = _figure_suptitle(snaps, title)
    if suptitle:
        fig.suptitle(suptitle, fontsize=10)

    def frame(idx):
        meta, graph = snaps[idx]
        _draw_snapshot(ax, meta, graph, idx,
                       fixed_pos=union_pos, label_max=label_max,
                       layout=layout)
        return []

    animation = anim.FuncAnimation(
        fig, frame,
        frames=len(snaps),
        interval=1000 // max(fps, 1),
        blit=False,
        repeat=True,
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    animation.save(out_path, writer=anim.PillowWriter(fps=fps))
    print(f"wrote {out_path} ({len(snaps)} frames @ {fps} fps)",
          file=sys.stderr)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Render Sixth substrate-trace snapshots.")
    parser.add_argument(
        "input", nargs="?", type=Path,
        help="trace input file (default: stdin)")
    parser.add_argument(
        "--out", "-o", type=Path, required=True,
        help="output image path (PNG/SVG/PDF static; .gif animation)")
    parser.add_argument(
        "--title", "-t", default=None,
        help="figure suptitle")
    parser.add_argument(
        "--gif", action="store_true",
        help="render as animated GIF (one frame per snapshot)")
    parser.add_argument(
        "--fps", type=int, default=4,
        help="GIF frame rate (default 4)")
    parser.add_argument(
        "--diff", action="store_true",
        help="render per-step DIFF view (panel N shows what changed "
             "between snapshot N-1 and N: green added, red removed, "
             "grey unchanged)")
    parser.add_argument(
        "--jsonl", type=Path, default=None,
        help="also write a forensic JSONL trace to this path "
             "(one object per snapshot: metadata + edge list + "
             "per-node labels)")
    parser.add_argument(
        "--layout", choices=("auto", "tiered", "chain"), default="auto",
        help="node layout strategy. 'auto' = kamada-kawai (default, "
             "good for flat / force-directed); 'tiered' = multipartite "
             "by NGET tier (Pilots G/H/I composite-distinction hierarchy); "
             "'chain' = horizontal line by node id (Pilot J charge "
             "conservation, 1D CA traces). Both 'tiered' and 'chain' "
             "use the categorical NGET palette: NGET=1/2/3 are species "
             "α/β/γ in teal/amber/plum, 5/6/7 are darker family hues, "
             "9 is genus red, 0 is grey background.")
    args = parser.parse_args(argv)

    if args.input:
        stream = args.input.read_text().splitlines(keepends=True)
    else:
        stream = sys.stdin

    if args.out.suffix.lower() == ".gif":
        args.gif = True

    snaps = list(parse_snapshots(stream))
    _annotate_deltas(snaps)

    if args.jsonl:
        write_jsonl(snaps, args.jsonl)

    if args.diff:
        render_diff(snaps, args.out, args.title)
    elif args.gif:
        render_gif(iter(snaps), args.out, args.title, args.fps,
                   layout=args.layout)
    else:
        render(iter(snaps), args.out, args.title, layout=args.layout)


if __name__ == "__main__":
    main()
