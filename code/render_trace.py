#!/usr/bin/env python3
"""render_trace.py — render Sixth substrate-trace snapshots.

Reads a stream of Sixth DOT snapshots from stdin (or a file), each
preceded by a sentinel:
    === SNAPSHOT [meta-key=val ...] ===
followed by a `digraph substrate { ... }` block, and renders them as
side-by-side panels in a single matplotlib figure.

This is the visual-trace pilot answering the external reviewer's
request to make the substrate's life visible.

Usage:
    racket -l sixth/cli -- run examples/37-trace-pilot-d.6th \\
        | python3 code/render_trace.py --out figures/pilot_d_trace.png
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterator

import matplotlib.pyplot as plt
import networkx as nx

SNAPSHOT_HEADER = re.compile(r"^===\s*SNAPSHOT\s*(.*?)\s*===\s*$")
DIGRAPH_OPEN = re.compile(r"^\s*digraph\s+\w+\s*\{")
DIGRAPH_CLOSE = re.compile(r"^\s*\}\s*$")
NODE_LINE = re.compile(r'^\s*"([^"]+)"\s*;\s*$')
EDGE_LINE = re.compile(r'^\s*"([^"]+)"\s*->\s*"([^"]+)"\s*;\s*$')


def _strip(node_id: str) -> str:
    """Sixth's `.` prints with trailing space; strip it."""
    return node_id.strip()


def parse_snapshots(stream: Iterator[str]):
    """Yield (metadata: dict[str,str], graph: nx.DiGraph) per snapshot."""
    current_meta: dict[str, str] | None = None
    in_digraph = False
    nodes: set[str] = set()
    edges: list[tuple[str, str]] = []

    def emit():
        nonlocal current_meta, nodes, edges
        if current_meta is None:
            return None
        graph = nx.DiGraph()
        graph.add_nodes_from(nodes)
        graph.add_edges_from(edges)
        m = current_meta
        current_meta = None
        nodes = set()
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
            nodes.add(_strip(node.group(1)))
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
        if graph.number_of_nodes() == 0:
            ax.set_axis_off()
            ax.set_title(_panel_title(meta, idx), fontsize=9)
            continue

        observer_id = next(iter(graph.nodes), None)
        node_colors = [
            "#d04040" if n == observer_id else "#909090"
            for n in graph.nodes
        ]
        edge_colors = [
            "#a04040" if u == v else "#606060"
            for (u, v) in graph.edges
        ]
        try:
            pos = nx.kamada_kawai_layout(graph)
        except Exception:
            pos = nx.spring_layout(graph, seed=42)

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

    # Hide unused axes.
    for i in range(n, rows * cols):
        axes[i // cols][i % cols].set_axis_off()

    if title:
        fig.suptitle(title, fontsize=11)
        fig.tight_layout(rect=(0, 0, 1, 0.96))
    else:
        fig.tight_layout()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150, bbox_inches="tight")
    print(f"wrote {out_path} ({n} panels)", file=sys.stderr)


def _panel_title(meta: dict[str, str], idx: int) -> str:
    if not meta:
        return f"snapshot {idx}"
    parts = []
    for k in ("shell-count", "nodes", "edges"):
        if k in meta:
            parts.append(f"{k}={meta[k]}")
    extra = " ".join(f"{k}={v}" for k, v in meta.items()
                     if k not in ("shell-count", "nodes", "edges"))
    head = " ".join(parts) if parts else f"snapshot {idx}"
    return f"{head}  {extra}".rstrip()


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Render Sixth substrate-trace snapshots.")
    parser.add_argument(
        "input", nargs="?", type=Path,
        help="trace input file (default: stdin)")
    parser.add_argument(
        "--out", "-o", type=Path, required=True,
        help="output image path (PNG, SVG, PDF)")
    parser.add_argument(
        "--title", "-t", default=None,
        help="figure suptitle")
    args = parser.parse_args(argv)

    if args.input:
        stream = args.input.read_text().splitlines(keepends=True)
    else:
        stream = sys.stdin

    render(parse_snapshots(stream), args.out, args.title)


if __name__ == "__main__":
    main()
