"""tests/render-test.py — unit tests for code/render_trace.py.

Covers the parser surface and metadata pipeline that the forensic
trace pipeline depends on.  Anything that breaks the panel-title,
JSONL, or delta-annotation logic gets caught here before it slips
into a regenerated figure.

Run via `python3 tests/render-test.py` or `make test-render`.
Exits non-zero on any failure.
"""
from __future__ import annotations
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "code"))
import render_trace as R  # noqa: E402


SAMPLE = """\
=== SNAPSHOT step=0 rule=test-rule seed=void event=initial-state nodes=1 edges=0 ===
digraph substrate {
  rankdir=LR;
  "1" [label="0"] ;
}
=== SNAPSHOT step=1 rule=test-rule seed=void event=MARK nodes=2 edges=0 ===
digraph substrate {
  rankdir=LR;
  "1" [label="0"] ;
  "2" [label="0"] ;
}
=== SNAPSHOT step=2 rule=test-rule seed=void event=EDGE+ nodes=2 edges=1 ===
digraph substrate {
  rankdir=LR;
  "1" [label="0"] ;
  "2" [label="1"] ;
  "1" -> "2" ;
}
"""


class ParserTests(unittest.TestCase):
    def test_parse_three_snapshots(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        self.assertEqual(len(snaps), 3)

    def test_metadata_keys_extracted(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        meta0 = snaps[0][0]
        self.assertEqual(meta0["rule"], "test-rule")
        self.assertEqual(meta0["seed"], "void")
        self.assertEqual(meta0["event"], "initial-state")
        self.assertEqual(meta0["step"], "0")

    def test_node_labels_preserved(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        graph_last = snaps[2][1]
        self.assertEqual(graph_last.nodes["2"].get("label"), "1")

    def test_edges_parsed(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        self.assertEqual(list(snaps[2][1].edges), [("1", "2")])


class DeltaTests(unittest.TestCase):
    def test_delta_panel(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        R._annotate_deltas(snaps)
        # frame 0 has no prev — dashes
        self.assertEqual(snaps[0][0]["Δn"], "—")
        # frame 1 added one node (1 → 2)
        self.assertEqual(snaps[1][0]["Δn"], "+1")
        self.assertEqual(snaps[1][0]["Δe"], "+0")
        # frame 2 added one edge + one live cell (label 0→1 on node 2)
        self.assertEqual(snaps[2][0]["Δn"], "+0")
        self.assertEqual(snaps[2][0]["Δe"], "+1")
        self.assertEqual(snaps[2][0]["Δlive"], "+1")


class PanelTitleTests(unittest.TestCase):
    def test_multi_line_title(self):
        meta = {
            "step": "1", "event": "MARK", "nodes": "2", "edges": "0",
            "Δn": "+1", "Δe": "+0", "Δlive": "+0",
        }
        title = R._panel_title(meta, 1)
        lines = title.split("\n")
        self.assertEqual(lines[0], "step=1  ·  MARK")
        self.assertIn("n=2 e=0", lines[1])
        self.assertIn("Δn=+1", lines[1])

    def test_empty_meta_fallback(self):
        self.assertEqual(R._panel_title({}, 7), "snapshot 7")

    def test_rule_seed_in_suptitle_not_panel(self):
        meta = {"step": "1", "rule": "test", "seed": "void"}
        title = R._panel_title(meta, 0)
        self.assertNotIn("rule=test", title)
        self.assertNotIn("seed=void", title)


class JsonlTests(unittest.TestCase):
    def test_jsonl_round_trip(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        R._annotate_deltas(snaps)
        with tempfile.NamedTemporaryFile("w+", suffix=".jsonl", delete=False) as f:
            out = Path(f.name)
        R.write_jsonl(snaps, out)
        lines = out.read_text().splitlines()
        self.assertEqual(len(lines), 3)
        obj0 = json.loads(lines[0])
        self.assertEqual(obj0["snapshot_index"], 0)
        self.assertEqual(obj0["metadata"]["rule"], "test-rule")
        self.assertEqual(obj0["nodes"], ["1"])
        obj2 = json.loads(lines[2])
        self.assertEqual(obj2["edges"], [["1", "2"]])
        out.unlink()


class SuptitleTests(unittest.TestCase):
    def test_lifts_rule_and_seed_when_stable(self):
        snaps = list(R.parse_snapshots(io.StringIO(SAMPLE)))
        suptitle = R._figure_suptitle(snaps, fallback="Test fig")
        self.assertIn("rule: test-rule", suptitle)
        self.assertIn("seed: void", suptitle)
        self.assertIn("Test fig", suptitle)


if __name__ == "__main__":
    unittest.main(verbosity=2)
