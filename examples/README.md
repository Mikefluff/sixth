# `examples/` — the 41 demonstrations

This directory holds Sixth's reproducible emergence demonstrations.
Each file is a standalone Sixth program; `raco test
tests/examples-test.rkt` (or `make verify`) executes all 41 and
asserts a cumulative 657 ✓ / 0 ✗.

The demos are organised in seven phases:

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
| Conway visual trace                   | 42 | 7 | Conway's Game of Life blinker on 5×5 grid; state-aware DOT rendering shows alive/dead cells over time |

The visual-trace pilots emit GraphViz DOT blocks on stdout that the
companion Python renderer (`code/render_trace.py`) parses into
multi-panel matplotlib figures (PNG / SVG / PDF) or animated GIFs.
Single command `make traces` regenerates all three static figures,
`make gifs` regenerates all three animations.

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

Conway's Game of Life blinker on a 5×5 substrate grid — alive cells
red, oscillates with period 2 (vertical ⇄ horizontal); structure
fixed, state visible in colour:

![Conway blinker — 9 frames showing period-2 oscillation between
vertical and horizontal three-cell bars on a 5×5 Moore-grid
substrate. State-aware colouring honours per-cell NGET via the
DOT `[label="N"]` attribute.](../docs/figures/conway_blinker.gif)

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

## Conway visual trace (42)

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 42 | `42-trace-conway-blinker.6th` | 7 | Conway's Game of Life blinker (cells 8, 13, 18) on 5×5 Moore-grid substrate; 9 snapshots across 8 Conway steps; state-aware DOT (`dot-snapshot-state`) emits each node's NGET as a `[label="N"]` attribute. The renderer parses the label and colours alive cells (NGET=1) red, dead cells (NGET=0) light grey. Period-2 oscillation is visible cycle-by-cycle. |

```bash
make trace-conway-blinker    # build/figures/conway_blinker.png
make gif-conway-blinker      # build/figures/conway_blinker.gif
```

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
    ("41-my-new-demo.6th"           N)))   ; N = expected ✓
```

Update the cumulative gate (currently 657) and `make verify` passes
cleanly. To add a visual trace, `use dot` and emit `dot-snapshot`
calls between substrate operations.

## References

- Repository root: [`../README.md`](../README.md)
- Three-tier taxonomy: [`../CLAIMS.md`](../CLAIMS.md)
- Sixth as stand-alone language: [`../LANGUAGE.md`](../LANGUAGE.md)
- Substrate-philosophical mapping: [`../SUBSTRATE.md`](../SUBSTRATE.md)
- v9.0 preprint: (pending arXiv submission)
