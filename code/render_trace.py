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


def render(snapshots, out_path: Path, title: str | None) -> None:
    snaps = list(snapshots)
    if not snaps:
        sys.exit("no snapshots found in input")

    n = len(snaps)
    cols = min(n, 5)
    rows = (n + cols - 1) // cols
    fig, axes = plt.subplots(
        rows, cols,
        figsize=(3.2 * cols, 3.2 * rows),
        squeeze=False,
    )

    for idx, (meta, graph) in enumerate(snaps):
        ax = axes[idx // cols][idx % cols]
        _draw_snapshot(ax, meta, graph, idx)

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
_HIDDEN_KEYS = (set(_PRIMARY_KEYS) | set(_DELTA_KEYS) | set(_HEADER_KEYS)
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

    extras = [f"{k}={v}" for k, v in meta.items() if k not in _HIDDEN_KEYS]

    lines = ["  ·  ".join(line1)]
    if line2:
        lines.append("  ·  ".join(line2))
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
    so the highlighted node is the substrate's actual observer rather
    than whichever node happens to come first in graph.nodes."""
    obs = meta.get("observer") if meta else None
    if obs and obs in graph.nodes:
        return obs
    return next(iter(graph.nodes), None)


def _draw_snapshot(ax, meta, graph, idx, fixed_pos=None) -> None:
    if graph.number_of_nodes() == 0:
        ax.set_axis_off()
        ax.set_title(_panel_title(meta, idx), fontsize=9)
        return

    observer_id = _observer_node(meta, graph)
    has_labels = any("label" in graph.nodes[n] for n in graph.nodes)

    def _node_colour(n: str) -> str:
        # State-aware: label "1" / "0" (Conway alive/dead) trumps observer.
        if has_labels:
            lbl = graph.nodes[n].get("label", "")
            try:
                v = int(lbl)
            except ValueError:
                v = 0
            return "#d04040" if v > 0 else "#e0e0e0"
        return "#d04040" if n == observer_id else "#909090"

    node_colors = [_node_colour(n) for n in graph.nodes]
    edge_colors = [
        "#a04040" if u == v else "#606060"
        for (u, v) in graph.edges
    ]
    if fixed_pos is not None:
        pos = {n: fixed_pos[n] for n in graph.nodes if n in fixed_pos}
        if len(pos) != graph.number_of_nodes():
            # Fall back if any node is missing from fixed positions.
            pos = nx.kamada_kawai_layout(graph)
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
        width=0.8,
        connectionstyle="arc3,rad=0.08",
    )
    nx.draw_networkx_nodes(
        graph, pos, ax=ax,
        node_color=node_colors,
        node_size=180,
        linewidths=0.5,
        edgecolors="black",
    )
    nx.draw_networkx_labels(
        graph, pos, ax=ax,
        font_size=7,
        font_color="white",
    )

    ax.set_axis_off()
    ax.set_title(_panel_title(meta, idx), fontsize=9)


def _union_layout(snaps):
    """Pre-compute positions for the union of all snapshot graphs so
    a node that appears across multiple frames stays in the same
    place — eliminates the "jiggle" the user reported on early GIFs."""
    union = nx.DiGraph()
    for _meta, graph in snaps:
        union.add_nodes_from(graph.nodes)
        union.add_edges_from(graph.edges)
    if union.number_of_nodes() == 0:
        return {}
    try:
        return nx.kamada_kawai_layout(union)
    except Exception:
        return nx.spring_layout(union, seed=42)


def render_gif(snapshots, out_path: Path, title: str | None,
               fps: int) -> None:
    snaps = list(snapshots)
    if not snaps:
        sys.exit("no snapshots found in input")

    # Compute layout ONCE on the union of every snapshot's graph so
    # nodes that persist across frames stay in the same place — kills
    # the layout-jiggle problem reported on early GIFs.
    union_pos = _union_layout(snaps)

    fig, ax = plt.subplots(figsize=(6.5, 6.5))
    suptitle = _figure_suptitle(snaps, title)
    if suptitle:
        fig.suptitle(suptitle, fontsize=10)

    def frame(idx):
        meta, graph = snaps[idx]
        _draw_snapshot(ax, meta, graph, idx, fixed_pos=union_pos)
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
        render_gif(iter(snaps), args.out, args.title, args.fps)
    else:
        render(iter(snaps), args.out, args.title)


if __name__ == "__main__":
    main()
