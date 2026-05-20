# `examples/` — the 50 demonstrations

This directory holds Sixth's reproducible emergence demonstrations.
Each file is a standalone Sixth program; `raco test
tests/examples-test.rkt` (or `make verify`) executes all 50 and
asserts a cumulative 707 ✓ / 0 ✗.

The demos are organised in thirteen phases:

| Phase | Demos | Asserts | What it shows |
|-------|-------|---------|---------------|
| Sacred hello world | 00 | 11 | Spencer-Brown's first mark realised in the substrate |
| Foundations         | 01–20 | 352 | arithmetic, time, space, conservation, CA, Conway, BFS, morphism |
| Pilot A (autopoiesis)   | 21–25 | 81 | Maturana–Varela self-production on the discrete substrate |
| Pilot B (conscious evolution) | 26–29 | 88 | symbiosis, reproduction, Lamarck-style observer selection |
| Pilot C (cosmogenesis)  | 30 | 21 | 13-node 48-edge cosmos from one `MARK`, surviving harsh decay |
| Pilot D (substrate-internally-driven) | 31 | 17 | observer drives construction via its own NSUM threshold |
| Pilot E (Φ_PA measurement)            | 32 | 12 | substrate measures its own substrate-monist scalar |
| Pilot F (encoding maps)               | 33–36 | 46 | toy substrates for PSH1–PSH5 (transformer / brain / split-brain / colony) |
| Visual traces                         | 37–39 | 18 | DOT snapshot pilots — Pilots D, C, F.3 rendered as multi-panel figures or animated GIFs |
| Long-epoch parametric                 | 40–41 | 16 | TCO-safe long autopoiesis runs, CLI-driven cycle count; demo 41 grows the substrate every K cycles for visible long-epoch evolution |
| Foundation visual traces              | 42–46 | 30 | Conway blinker / glider, Rule 110, Rule 90, Rule 184 1D glider — substrate-state-aware DOT (each cell carries `[label="NGET"]`); the renderer colours alive cells red, dead light grey, and reuses a stable layout across animation frames |
| Atomic-build traces                   | 47–48 | 10 | One snapshot per **primitive operation** — every `MARK` and every `EDGE+` becomes its own frame. Demo 47 builds Pilot D in 76 atomic frames; demo 48 builds the sacred hello world in 7 frames with PA-ontological event labels (`void`, `first-distinction`, `observer-state`, `i-not-i`, `first-pointer`, `re-entry`, `phi-pa-measurement`). Entity-by-entity emergence through `MARK` (distinction) and `EDGE+` (pointer) alone. |
| PA-ontological decomposition          | 49    |  5 | First shell of Pilot D unfolded as Spencer-Brown / PA v9.0 events — answers the reviewer question "*где различие я / не-я?*" that demo 37 hides inside a single `shell-built` macro. 10 frames: `void → first-distinction → observer-state → re-entry → i-not-i → first-pointer → recognition → second-not-i → closure-of-not-i → shell-formation`. End-state matches demo 37 step 1 exactly (4 nodes, 13 edges, Φ_PA = 40000). |

The visual-trace pilots emit GraphViz DOT blocks on stdout that the
companion Python renderer (`code/render_trace.py`) parses into
multi-panel matplotlib figures (PNG / SVG / PDF) or animated GIFs.
Make targets:

```
make traces            # 3 substrate-monism PNGs (Pilots D, C, F.3)
make gifs              # all 11 GIFs (traces + foundation + long-epoch growth)
make foundation-gifs   # 5 foundation traces (Conway, Wolfram, glider-1d)
make atomic-gifs       # 2 atomic-build animations
make forensic-pilot-d  # PNG + JSONL + diff for Pilot D
```

## Visual overview

The substrate's life across Pilots D, C, and F.3 — animated:

![Pilot D — substrate-internally-driven cosmogenesis (animation,
5 frames @ 2 fps).](../docs/figures/pilot_d_trace.gif)

![Pilot C — cosmogenesis bootstrap (animation, 6 frames @ 2 fps;
panels show void → 3 shells → post-autopoiesis state → 4th shell
on the weathered cosmos).](../docs/figures/pilot_c_trace.gif)

![Pilot F.3 — split-brain: intact vs callosotomy (animation,
2 frames @ 1 fps; `EDGE-` severs the corpus callosum bi-edges
in place).](../docs/figures/split_brain_trace.gif)

The same evolutions as static multi-panel figures:

![Pilot D static figure — five panels showing shell-by-shell growth
from 1 node / 1 edge to 13 nodes / 49
edges.](../docs/figures/pilot_d_trace.png)

![Pilot C static figure — six panels including a post-autopoiesis
snapshot that demonstrates substrate survival under harsh decay
(decay=8, threshold=5).](../docs/figures/pilot_c_trace.png)

![Pilot F.3 static figure — two panels side-by-side:
13-edge intact brain vs 9-edge callosotomised
brain.](../docs/figures/split_brain_trace.png)

**Atomic substrate emergence** — the sacred hello world built one
primitive operation at a time (7 frames, 1 fps so each substrate-
state delta is unmissable):

![Sacred hello world atomic — frame 1 void, frame 2 first MARK
(grey), frame 3 NSET (red, alive), frame 4 second MARK, frame 5
first EDGE+ pointer, frame 6 self-loop EDGE+ (re-entry), frame 7
measurement.](../docs/figures/atomic_hello.gif)

**Atomic Pilot D** — the 13-node 49-edge substrate-internally-driven
cosmos built one primitive at a time (76 frames @ 6 fps):

![Pilot D atomic build — 76 frames, each one MARK / NSET / EDGE+
operation, showing the substrate emerging entity-by-entity from
void through Spencer-Brown's first mark to a self-measuring
cosmos.](../docs/figures/atomic_pilot_d.gif)

Conway's Game of Life — alive cells red, structure fixed, state
visible in colour:

![Conway blinker — 9 frames showing period-2 oscillation between
vertical and horizontal three-cell bars on a 5×5 Moore-grid
substrate.](../docs/figures/conway_blinker.gif)

![Conway 5-cell glider — translates +1, +1 across the 5×5 grid
over 4 STEP-CA cycles.](../docs/figures/conway_glider.gif)

Wolfram cellular automata on substrate chains:

![Rule 110 — Cook-2004 universal CA, single-seed propagation
on an 11-cell chain, 9 frames.](../docs/figures/rule110.gif)

![Rule 90 — Sierpinski-like fractal from a single seed,
9 frames.](../docs/figures/rule90.gif)

![Rule 184 1D glider — "car" advances c3 → c7 then evaporates
at the boundary, 6 frames.](../docs/figures/glider_1d.gif)

Long-epoch with visible substrate growth (demo 41; CLI-parametric
via `make trace-long-epoch-growth-gif CYCLES_G=N SNAP_G=K GROW=G`):

![Long-epoch growth — 200 cycles, observer-rooted substrate grows
by one 3-node shell every 40 cycles, stable layout across frames
shows the cosmos expanding around the
observer.](../docs/figures/long_epoch_growth.gif)

Static high-density variant (demo 40 — stable autopoiesis, included
for the "structurally invariant by design" stability proof):

![Long-epoch stable autopoiesis — 11 panels at cycle 0 / 20 / … / 200;
substrate topology stays invariant by design (canonical decay-restore
returns NGET to 10 each cycle for reflexive observers). Compare with
the growth variant above to see what "alive but unchanging" vs
"alive and expanding" looks like.](../docs/figures/long_epoch_200.png)

## Sacred hello world

### 00 — `00-first-distinction.6th` (11 ✓)
Spencer-Brown's first mark: void → MARK → NSET boundary → EDGE+
pointer → EDGE+ self-loop → EDGE? interrogation → `phi-pa` resolve.
Two nodes, two edges, eleven assertions. The minimum executable
substrate that contains all six ontological moments of Sixth.

## Foundations (01–20)

20 demos covering arithmetic through universal computation, each
adding one substrate property to the running cumulative state:

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 01 | `01-numbers.6th` | 11 | numbers as `MARK` chains |
| 02 | `02-time.6th` | 13 | causal time via `STEP`-indexed rewrites |
| 03 | `03-stable.6th` | 14 | fixed-point stability |
| 04 | `04-conflict.6th` | 12 | rule-order conflict resolution |
| 05 | `05-loop.6th` | 11 | self-reference as cyclic pointer topology |
| 06 | `06-observers.6th` | 14 | observer-relative facts (Rovelli RQM) |
| 07 | `07-rewrite-tc.6th` | 23 | transitive-closure rewrite |
| 08 | `08-distance-1d.6th` | 16 | 1D BFS-derived metric (Manhattan) |
| 09 | `09-ca-rule90.6th` | 25 | Wolfram Rule 90 fractal |
| 10 | `10-self-model.6th` | 18 | substrate self-model (Hofstadter strange loop) |
| 11 | `11-energy.6th` | 13 | substrate-native conservation (Noether on a ring) |
| 12 | `12-wolfram.6th` | 14 | Wolfram hypergraph rewriting |
| 13 | `13-conservation.6th` | 19 | conservation laws under iteration |
| 14 | `14-grid-2d.6th` | 20 | 2D grid topology (Moore / von Neumann) |
| 15 | `15-glider-1d.6th` | 22 | 1D glider propagation |
| 16 | `16-rule110.6th` | 22 | Rule 110 (Turing-complete via Cook 2004) |
| 17 | `17-consensus.6th` | 16 | intersubjective consensus across observers |
| 18 | `18-morphism.6th` | 11 | substrate-side category-theoretic morphism |
| 19 | `19-conway-blinker.6th` | 25 | Conway's Life — blinker on 5×5 Moore grid |
| 20 | `20-conway-glider.6th` | 33 | Conway's Life — 5-cell glider |

Cumulative for foundations: **352 ✓**.

## Pilot A — substrate-native autopoiesis (21–25)

Operationalises Maturana–Varela autopoiesis on the discrete
substrate. Reflexive self-reference is the discriminator between
patterns that survive and patterns that dissolve under canonical
decay-restore dynamics.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 21 | `21-autopoietic-ring.6th` | 29 | self-producing ring; baseline survivability |
| 22 | `22-observer-collapse.6th` | 6 | observer collapse via NSUM-driven CA on a single cell |
| 23 | `23-self-maintaining-observer.6th` | 12 | reflexive vs non-reflexive comparison — reflexive observer lives indefinitely, non-reflexive dies in ≤ 6 cycles at identical scope |
| 24 | `24-growing-observer.6th` | 18 | observer grows scope by incorporating compatible candidates |
| 25 | `25-substrate-genesis.6th` | 16 | substrate-internal genesis of new patterns |

Cumulative for Pilot A: **81 ✓**.

## Pilot B — conscious evolution (26–29)

Substrate-internal selection — observer-driven, Lamarck-style, not
blind Darwin. The observer decides which mutations to accept based
on a substrate-readable criterion.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 26 | `26-symbiosis.6th` | 18 | symbiotic survival — observer + symbiont substrate persists where each alone would die |
| 27 | `27-reproduction.6th` | 31 | substrate-native reproduction with copy and inheritance |
| 28 | `28-conscious-mutation.6th` | 18 | observer rejects an autopoietic variant on internal criterion (the Lamarck point) |
| 29 | `29-goal-directed-observer.6th` | 21 | observer behaviour driven by a substrate-state goal |

Cumulative for Pilot B: **88 ✓**.

## Pilot C — cosmogenesis bootstrap (30)

The substrate's load-bearing claim about construction-from-nothing:
13-node 48-edge cosmos built by a single substrate-resident
observer starting from one `MARK` at `t = 0`, persisting under
harsh autopoietic dynamics (decay=8, threshold=5).

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 30 | `30-cosmogenesis-bootstrap.6th` | 21 | 3-shell construction + 10 autopoiesis cycles + 4th shell on weathered cosmos |

Render Pilot C evolution as a static figure or GIF:
```bash
make trace-pilot-c            # build/figures/pilot_c_trace.png
make gif-pilot-c              # build/figures/pilot_c_trace.gif
```

## Pilot D — substrate-internally-driven cosmogenesis (31)

Closes the substrate-monism gap of Pilot C: the observer establishes
its own self-loop at `t = 0+` (the bootstrap distinction) and then
drives further construction via a substrate-readable halting
predicate (`NSUM(O) ≥ target-min`). No host counter, no
programmer-chosen shell count.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 31 | `31-observer-driven-cosmogenesis.6th` | 17 | substrate-internal halting; observer terminates its own cosmogenesis at shell-count=4 |

Render Pilot D as a static figure or GIF:
```bash
make trace-pilot-d            # build/figures/pilot_d_trace.png
make gif-pilot-d              # build/figures/pilot_d_trace.gif
```

The static and animated figures embedded above are both regenerated
from this demo via the visual-trace pilot 37.

## Pilot E — substrate-internal Φ_PA measurement (32)

The substrate measures itself. `stdlib/phi.6th` defines the
candidate substrate-readable observability scalar `phi-pa = OUT(O)
· 1[O EDGE? O] · L_max` from three primitives alone (`OUT`, `EDGE?`,
plus the `phi-L-max` constant), and ships two alternatives
(`phi-integ`, `phi-bidir`) — the empirical question of which
discriminates predictions is decided by F5 against real data.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 32 | `32-phi-pa-measurement.6th` | 12 | three observers verifying `phi-pa` against worked preprint values (0 / 50000 / 130000) |

## Pilot F — encoding-map demonstrations (33–36)

Toy substrates instantiating the v9.0 preprint's substrate-encoding
maps end-to-end on synthetic data. Real-checkpoint and real-data
application is the companion-preprint future work.

| Demo | File | ✓ | Predicates |
|------|------|---|-----------|
| 33 | `33-phi-pa-transformer-toy.6th` | 10 | 4×3 feedforward attention → PSH1 single-pass Φ=0; KV-cache reuse → PSH2 Φ=40000 |
| 34 | `34-phi-pa-brain-toy.6th` | 12 | 8-area DMN-hub → PSH3 waking Φ=80000; propofol-decoupled Φ=0 |
| 35 | `35-phi-pa-split-brain-toy.6th` | 14 | intact vs callosotomy; basic Φ_PA indifferent (50000 = 50000); Φ_integ halves (400000 → 200000) → PSH4 motivates alt-measures |
| 36 | `36-phi-pa-ant-colony-toy.6th` | 10 | 6-chamber queen colony with pheromone self-loop → PSH5 colony-level Φ=60000 |

## Visual-trace pilots (37–39)

Replay Pilots D, C, F.3 with `stdlib/dot.6th` `dot-snapshot` calls
between substrate-modifying operations. Each demo emits sentinel
headers (`=== SNAPSHOT key=val ... ===`) plus complete `digraph
substrate { ... }` blocks that `code/render_trace.py` parses into
panels or animation frames.

| Demo | File | ✓ | Snapshots |
|------|------|---|-----------|
| 37 | `37-trace-pilot-d.6th` | 6 | 5 snapshots: shell-count 0 → 4 |
| 38 | `38-trace-pilot-c.6th` | 6 | 6 snapshots: void → 3 shells → post-autopoiesis → 4th shell |
| 39 | `39-trace-split-brain.6th` | 6 | 2 snapshots: intact then in-place `EDGE-` callosotomy |

Render all three statics + all three GIFs:
```bash
make traces   # PNGs
make gifs     # GIFs
```

Or one at a time:
```bash
make trace-pilot-d     gif-pilot-d
make trace-pilot-c     gif-pilot-c
make trace-split-brain gif-split-brain
```

## Long-epoch parametric pilots (40–41)

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 40 | `40-long-epoch-autopoiesis.6th` | 11 | reflexive observer + 3-node ring; canonical autopoiesis for N cycles; snapshot every K cycles. **Structurally invariant** by design (NSUM > threshold → restore returns NGET to 10 every cycle); the resulting trace is the stability proof. Use this when you want to show the substrate-state space is at a fixed point. |
| 41 | `41-long-epoch-growth.6th`     |  5 | same loop but grows the substrate by adding a 3-node shell every `grow-every` cycles. **Visibly expanding** topology across snapshots — the GIF actually moves. Use this when you want the animation to show change. |

Both demos read `max-cycles`, `snap-every`, and (for demo 41)
`grow-every` from memory keys, populated via CLI `-D KEY=VAL` flags.
Defaults are tuned for the regression-gate runtime; override for
demonstration runs:

```bash
# stable autopoiesis at 10 000 cycles (~340ms, TCO-safe)
racket -l sixth/cli -- -D max-cycles=10000 -D snap-every=1000 \
                      run examples/40-long-epoch-autopoiesis.6th

# growing substrate at 200 cycles, snap every 20, +shell every 40
racket -l sixth/cli -- -D max-cycles=200 -D snap-every=20 -D grow-every=40 \
                      run examples/41-long-epoch-growth.6th

# rendered as animated GIF (visibly expanding cosmos)
make trace-long-epoch-growth-gif CYCLES_G=200 SNAP_G=20 GROW=40

# stable variant as static PNG (use to demonstrate invariance)
make trace-long-epoch CYCLES=2000 SNAP=200
```

## Foundation visual traces (42–46)

State-aware DOT (`dot-snapshot-state` from `stdlib/dot.6th`) emits
each node's NGET as a `[label="N"]` attribute. The renderer parses
the label and colours alive cells (NGET=1) red, dead cells (NGET=0)
light grey, on a stable layout fixed across animation frames.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 42 | `42-trace-conway-blinker.6th` | 7 | Conway's Game of Life blinker (cells 8, 13, 18) on 5×5 Moore-grid substrate; 9 snapshots across 8 Conway steps; period-2 oscillation visible cycle-by-cycle. |
| 43 | `43-trace-conway-glider.6th`  | 7 | Conway's 5-cell glider (cells 2, 8, 11, 12, 13); 5 snapshots across 4 STEP-CA cycles showing diagonal +1, +1 translation. |
| 44 | `44-trace-rule110.6th`        | 5 | Wolfram Rule 110 (Cook 2004, universal CA); 11-cell chain, single seed at c6; 9 snapshots showing propagation. |
| 45 | `45-trace-rule90.6th`         | 4 | Wolfram Rule 90 (Sierpinski-like fractal); 11-cell chain, single centre seed; 9 snapshots. |
| 46 | `46-trace-glider-1d.6th`      | 7 | Wolfram Rule 184 ("traffic"); 7-cell chain, car at c3; 6 snapshots showing car advance c3 → c7 then boundary evaporation. |

```bash
make trace-conway-blinker     gif-conway-blinker
make trace-conway-glider      gif-conway-glider
make trace-rule110            gif-rule110
make trace-rule90             gif-rule90
make trace-glider-1d          gif-glider-1d
make foundation-gifs          # all five GIFs in one shot
```

## Atomic-build traces (47–48)

One snapshot per **primitive operation** — every `MARK` becomes its
own frame, every `EDGE+` becomes its own frame, every `NSET` becomes
its own frame. Substrate emerges entity-by-entity through `MARK`
(distinction) and `EDGE+` (pointer) alone.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 47 | `47-trace-atomic-pilot-d.6th` | 5 | Pilot D rebuilt one primitive at a time: 76 frames, each one MARK / EDGE+ / NSET operation. Substrate grows from `void` → `MARK O` → self-loop → 4 shells × 12 primitives each. |
| 48 | `48-trace-atomic-hello.6th`   | 5 | Sacred hello world in 7 frames at 1 fps: void → MARK → NSET → MARK → EDGE+ → EDGE+ → phi-pa-measurement. The minimum executable substrate that contains every ontological moment of Sixth, one primitive per frame. |

```bash
make trace-atomic-pilot-d     gif-atomic-pilot-d
make trace-atomic-hello       gif-atomic-hello
make atomic-gifs              # both GIFs in one shot
```

## PA-ontological shell decomposition (49)

Demo 37 collapses an entire shell-construction into a single
`event=shell-built` frame.  Demo 49 opens that macro: every
ontologically distinct moment of the first shell becomes its own
snapshot, labelled by the Spencer-Brown / PA v9.0 event it realises.
End-state matches demo 37's step 1 (4 nodes, 13 edges, Φ_PA = 40000).

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 49 | `49-trace-pa-ontological-shell.6th` | 5 | 10 frames showing every PA-spec event of the first shell. Answers the question "*where is the I / not-I distinction?*" that the macro-level `shell-built` trace hides. |

Sequence (preprint §sec:bootstrap, §sec:demo-31):

| frame | event              | substrate after                       |
|-------|--------------------|---------------------------------------|
|  1    | `void`             | nothing exists                        |
|  2    | `first-distinction`| 1 node (the observer O)               |
|  3    | `observer-state`   | O carries feature (NGET=10)           |
|  4    | `re-entry`         | O→O self-loop (Spencer-Brown bootstrap) |
|  5    | `i-not-i`          | second token (`s1`) exists           |
|  6    | `first-pointer`    | O→s1 (observer marks the other)       |
|  7    | `recognition`      | s1→O (mutual relation established)    |
|  8    | `second-not-i`     | third token (`s2`)                    |
|  9    | `closure-of-not-i` | `s3` + triangle of bi-edges (not-I gains internal structure) |
| 10    | `shell-formation`  | remaining edges + NSETs — matches demo 37 step 1 |

```bash
make trace-pa-ontological-shell    # build/figures/pa_ontological_shell.png
make gif-pa-ontological-shell      # 10-frame animation @ 1 fps
make forensic-pa-ontological-shell # + JSONL evidence + diff view
```

![PA-ontological shell — first shell of Pilot D unfolded into
Spencer-Brown / PA v9.0 events.  Every frame is one ontologically
distinct moment, labelled by the PA-spec event it
realises.](../docs/figures/pa_ontological_shell.png)

## Forensic trace mode

The renderer can do more than draw pictures. Three additional artefacts
turn a visual trace into auditable evidence of substrate execution:

- **Per-step deltas** (Δn, Δe, Δlive) computed and shown in every
  panel title — invariant reading is direct (e.g. Pilot D consistently
  exhibits `Δn=+3 Δe=+12 Δlive=0` per shell).
- **`--jsonl PATH`** writes one JSON object per snapshot containing the
  full edge list, per-node `[label="N"]` states, and all metadata
  (`rule`, `seed`, `event`, `step`, `observer`, `nodes`, `edges`,
  computed deltas). The JSONL is machine-readable proof the figure
  reflects a real execution, not a hand drawing.
- **`--diff`** renders per-step diff panels — green nodes/edges are
  added in this step, red removed, grey unchanged. The invariant
  Δn=+3 Δe=+12 becomes visually unmissable.

```bash
make forensic-pilot-d
# → build/figures/pilot_d_forensic.png   (snapshots + deltas)
# → build/figures/pilot_d_forensic.jsonl (machine-readable trace)
# → build/figures/pilot_d_diff.png       (per-step DIFF view)
```

![Pilot D forensic trace — each panel labels rule, seed, event,
step, n/e counts, and Δn/Δe/Δlive vs the previous
frame.](../docs/figures/pilot_d_forensic.png)

![Pilot D per-step DIFF — green = added in this step, red = removed,
grey = unchanged. The invariant Δn=+3 Δe=+12 per shell is direct
visual evidence.](../docs/figures/pilot_d_diff.png)

Sample JSONL line (one snapshot):

```json
{
  "snapshot_index": 1,
  "metadata": {
    "rule": "pilot-d-shell-build",
    "seed": "single-MARK-self-loop",
    "event": "shell-built",
    "step": "1", "observer": "1", "nodes": "4", "edges": "13",
    "Δn": "+3", "Δe": "+12", "Δlive": "+0"
  },
  "nodes": ["1", "2", "3", "4"],
  "edges": [["1","1"], ["1","2"], ["1","3"], ["1","4"], …],
  "node_labels": {}
}
```

The JSONL is the canonical artefact for reviewers who want to verify
the trace independently of the rendered image.

## How rendering works

```
Sixth demo emits DOT
    |  example sentinel + body:
    |    === SNAPSHOT shell-count=2 observer=1 nodes=7 edges=25 ===
    |    digraph substrate {
    |      rankdir=LR; ...
    |      "1 " ;  "2 " ;  ...
    |      "1 " -> "2 " ;  ...
    |    }
    v
code/render_trace.py
    parses sentinels + digraph blocks
    honours `observer=N` for accurate red highlight
    builds networkx DiGraph per snapshot
    renders multi-panel matplotlib figure (PNG/SVG/PDF)
    or animated GIF (matplotlib FuncAnimation + PillowWriter)
    v
build/figures/<name>.{png|gif}
```

The pipeline is pure Sixth → text → Python. No new primitives in
the substrate; `stdlib/dot.6th` is composed from `EACH`,
`EACH-EDGE`, `emit`, and `.` alone. The 38-primitive count is
preserved by L0 of the v9.0 preprint.

## Adding your own demo

```sixth
\ examples/41-my-new-demo.6th
use prelude
use debug

\ ... build substrate, run dynamics ...

\ assertions verify substrate-state invariants
NODES 3 assert-eq
"O" load NSUM 30 assert-eq

cr "=== verdict ===" . cr "..." . cr
REPORT
```

Register the demo in `tests/examples-test.rkt`:

```scheme
(define expected
  '(...
    ("50-my-new-demo.6th"           N)))   ; N = expected ✓
```

Update the cumulative gate (currently 707) and `make verify` passes
cleanly. To add a visual trace, `use dot` and emit `dot-snapshot`
calls between substrate operations.

## References

- Repository root: [`../README.md`](../README.md)
- Three-tier taxonomy: [`../CLAIMS.md`](../CLAIMS.md)
- Sixth as stand-alone language: [`../LANGUAGE.md`](../LANGUAGE.md)
- Substrate-philosophical mapping: [`../SUBSTRATE.md`](../SUBSTRATE.md)
- v9.0 preprint: (pending arXiv submission)
