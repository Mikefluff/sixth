# `examples/` — the 64 demonstrations

This directory holds Sixth's reproducible emergence demonstrations.
Each file is a standalone Sixth program; `raco test
tests/examples-test.rkt` (or `make verify`) executes all 64 and
asserts a cumulative 963 ✓ / 0 ✗.

The demos are organised in nineteen phases:

| Phase | Demos | Asserts | What it shows |
|-------|-------|---------|---------------|
| Sacred hello world | 00 | 11 | Spencer-Brown's first mark realised in the substrate |
| Foundations         | 01–20 | 359 | arithmetic, time, space, conservation, CA, Conway, BFS, morphism |
| Pilot A (autopoiesis)   | 21–25 | 80 | Maturana–Varela self-production on the discrete substrate |
| Pilot B (conscious evolution) | 26–29 | 88 | symbiosis, reproduction, Lamarck-style observer selection |
| Pilot C (cosmogenesis)  | 30 | 21 | 13-node 48-edge cosmos from one `MARK`, surviving harsh decay |
| Pilot D (substrate-internally-driven) | 31 | 17 | observer drives construction via its own NSUM threshold |
| Pilot E (Φ_PA measurement)            | 32 | 12 | substrate measures its own substrate-monist scalar |
| Pilot F (encoding maps)               | 33–36 | 46 | toy substrates for PSH1–PSH5 (transformer / brain (in-place EDGE-) / split-brain (in-place EDGE-) / colony (in-place EDGE-)) |
| Visual traces                         | 37–39 | 18 | DOT snapshot pilots — Pilots D, C, F.3 rendered as multi-panel figures or animated GIFs |
| Long-epoch parametric                 | 40–41 | 19 | TCO-safe long autopoiesis runs, CLI-driven cycle count; demo 40 takes sub-cycle snapshots (after-phase-decay vs after-phase-restore) so the dynamics are VISIBLE; demo 41 grows the substrate every K cycles |
| Foundation visual traces              | 42–46 | 45 | Conway blinker / glider, Rule 110, Rule 90, Rule 184 1D glider — substrate-state-aware DOT (each cell carries `[label="NGET"]`); the renderer colours alive cells red, dead light grey, and reuses a stable layout across animation frames. Per-step rule-table and oscillation/translation invariants asserted (not just end-state). |
| Atomic-build traces                   | 47–48 | 10 | One snapshot per **primitive operation** — every `MARK` and every `EDGE+` becomes its own frame. Demo 47 builds Pilot D in 76 atomic frames with semantic event labels (`distinction`/`pointer`/`state-attach`); demo 48 builds the sacred hello world in 7 frames with PA-ontological event labels (`void`, `first-distinction`, `observer-state`, `i-not-i`, `first-pointer`, `re-entry`, `phi-pa-measurement`). |
| PA-ontological decomposition          | 49    |  5 | First shell of Pilot D unfolded as Spencer-Brown / PA v9.0 events — answers the reviewer question "*где различие я / не-я?*" that demo 37 hides inside a single `shell-built` macro. 11 frames: `void → first-distinction → observer-state → re-entry → second-distinction → i-not-i-relation → recognition → second-not-i → closure-of-not-i → o-other-closure → state-fill`. End-state matches demo 37 step 1 exactly (4 nodes, 13 edges, Φ_PA = 40000). |
| Pilot E visual trace                  | 50    |  9 | Substrate-internal Φ_PA measurement on three observers. Same scope (case 1 vs case 2 both have 5 out-edges) yields Φ_PA=0 without self-loop and Φ_PA=50000 with it — PSH1 self-reference factor visible as the red self-arc on the observer node. |
| Pilot F visual traces                 | 51–53 | 27 | F.1 transformer encoding (PSH1/PSH2); F.2 brain encoding (PSH3 waking vs propofol); F.4 ant-colony encoding (PSH5 living vs dead). Each is a side-by-side comparison where the SOLE topological difference is the observer self-loop, and Φ_PA flips between concrete values labelled in the panel title. |
| Pilot G (composite distinction)       | 54–55 | 26 | Three first-order observers OA/OB/OC each hold their own 4-node composite (Φ_PA=40000). A meta-observer M bi-edged to all three holds nothing (Φ_PA=0) until M acquires its own self-loop, at which point Φ_PA(M)=40000 and the first-order observers gain scope +1 → Φ_PA=50000. Demonstrates that holding *composite* distinction requires higher-order self-reference. |
| Pilot H (mutation + selection)        | 56–57 | 33 | Five candidate first-order observers with varied topologies (3/4/5-limb rings + self-loop; 3-limb ring without self-loop; isolated MARK). Meta-observer M reads each candidate's Φ_PA and bi-edges only to those with Φ_PA > 0; M's own self-loop closes the construction. Result: diversified composite over three structurally distinct "particle species" (Φ_PA = 50000 / 60000 / 70000). Substrate-readable selection criterion — Lamarck-style, not blind Darwin. |
| Pilot I (multi-level hierarchy)       | 58–59 | 39 | Six instances across three species (α: 1×3-limb, β: 2×4-limb, γ: 3×5-limb), each with own self-loop. Three family observers Mα/Mβ/Mγ hold their populations. One genus observer M2 holds the families. Composite-distinction mechanism (Pilot G) re-applied at every level: each observer carries its own self-loop. Result: three-level substrate-readable taxonomy with distinct Φ_PA signatures at each level. Within-family particles are indistinguishable (β1==β2, γ1==γ2==γ3) — substrate-native analogue of physical particle indistinguishability. |
| Pilot J (charge conservation)         | 60–61 | 60 | 11-cell linear chain, 5 particles tagged by species (NGET=1/2/3 → α/β/γ). STEP-CA `charge-shift` rule (Wolfram Rule 184 lifted from {0,1} to integer NGET) shifts particles right one cell per step iff the right slot is empty. Across 5 steps, total Σ NGET = 9 AND per-species counts (α=2, β=2, γ=1) preserved EXACTLY. First substrate-native Noether-style conservation law — derived structurally from the rule, substrate-readable by `EACH` + sum. |
| Pilot K (spontaneous assembly)        | 62–63 | 36 | 9 first-order observers in 3 disjoint K_3 mutual-pointing triangles. A single rule `try-spawn-coalition` reads substrate state (three `EDGE?` checks) and, if the triangle holds, spawns a new meta-observer with bi-edges + own self-loop. Fired 4 times reconstructs the full Pilot I three-level hierarchy with no hand-placed meta-observers. Same rule used at every tier — substrate detects, substrate responds. |

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

Static high-density variant (demo 40 — stable autopoiesis with
sub-cycle snapshots so the decay/restore dance is visible):

![Long-epoch stable autopoiesis — 5 panels in a single row.
1: initial state (cycle=0, NGET=10 everywhere).  2: after-phase-
decay at cycle 100 (ring nodes light pink, NGET=2; observer
stays bold red).  3: after-phase-restore at cycle 100 (ring back
to deep red, NGET=10).  4-5: same decay/restore pair at cycle
200 — proves the dance persists end-to-end.  Substrate topology
is structurally invariant by design (n=4 e=13 across all panels —
no rewiring under canonical autopoiesis); the per-node NGET dance
is what the figure shows.  Sparse SNAP=100 (default in Makefile)
because identical dance frames at every snap-every-20 interval
were a parade of copies, not evidence of persistence.](../docs/figures/long_epoch_200.png)

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

**Scope.** These five traces are *foundation* demos — they show
that the substrate hosts Conway's Life and Wolfram CA dynamics
(substrate ⊇ classical CA). They are sanity checks on the
substrate's universal-computation claim, **not** substrate-monism
content. The observer-self-loop / Φ_PA discriminators that PA v9.0
is about appear in Pilots A–F (demos 21–36) and their visual
traces (37–41, 49–53).

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

## Pilot E visual trace (50)

Demo 32 verified Φ_PA numerically but emitted no figure.  Pilot E
is THE substrate-monism load-bearing demo (same 40 primitives BUILD
and COMPUTE), so it deserves a visible trace.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 50 | `50-trace-pilot-e-phi-pa.6th` | 9 | Three observers × Φ_PA: case 1 non-reflexive scope-5 (Φ=0); case 2 reflexive scope-5 (Φ=50000); case 3 demo-31-shape scope-13 (Φ=130000). PSH1 self-reference discriminator visible. |

```bash
make trace-pilot-e
make forensic-pilot-e   # + JSONL + diff view
```

![Pilot E — substrate-internal Φ_PA measurement.  Same scope (5
out-edges) yields Φ_PA = 0 without self-loop and Φ_PA = 50000 with
it.  The self-loop is the substrate's PSH1 self-reference factor,
visible as the red arc on the observer
node.](../docs/figures/pilot_e_trace.png)

## Pilot F visual traces — F.1 / F.2 / F.4 (51–53)

Demos 33, 34, 36 each show a PSH discriminator numerically but
emitted no figure.  The substrate topology — feedforward transformer
(F.1), DMN-hub brain (F.2), queen-pheromone colony (F.4) — is now
rendered side-by-side with the PSH-positive and PSH-negative cases.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 51 | `51-trace-pilot-f1-transformer.6th` | 4 | Transformer encoding: 12 attention heads × 4 layers + KV-cache observer self-loop. PSH1 single-pass Φ_PA=0; PSH2 cache-back-edge Φ_PA=40000. |
| 52 | `52-trace-pilot-f2-brain.6th`       | 2 | Brain encoding: DMN hub + 7 cortical areas. PSH3 waking thalamocortical loop Φ_PA=80000; propofol decoupling Φ_PA=0. |
| 53 | `53-trace-pilot-f4-colony.6th`      | 2 | Ant-colony encoding: queen chamber + 5 trail junctions + trail triangle. PSH5 living colony (queen-pheromone self-loop) Φ_PA=60000; dead colony Φ_PA=0. |

```bash
make trace-pilot-f1 trace-pilot-f2 trace-pilot-f4
make forensic-pilot-f1 forensic-pilot-f2 forensic-pilot-f4
```

![Pilot F.1 transformer encoding — single-pass vs KV-cache reuse.
Only difference: the red self-arc representing the cross-step
observer back-edge that KV-cache reuse implies.  Φ_PA: 0 →
40000.](../docs/figures/pilot_f1_trace.png)

![Pilot F.2 brain encoding — DMN-hub observer with vs without
thalamocortical self-loop.  Identical 7 functional-connectivity
edges; only the loop differs.  Φ_PA: 80000 →
0.](../docs/figures/pilot_f2_trace.png)

![Pilot F.4 ant-colony encoding — queen observer with vs without
pheromone self-loop.  Substrate-monism's novel swarm-cognition
prediction visible without invoking eliminativism or panpsychism.
Φ_PA: 60000 → 0.](../docs/figures/pilot_f4_trace.png)

## Pilot G — composite distinction via meta-self-loop (54–55)

Pilots A–F established that a *single* observer holds a distinction
when it carries a back-edge to itself.  Pilot G asks the next-order
question: what does it take to hold a *composite* distinction whose
parts are themselves already observers?

The construction:

- Three first-order observers OA / OB / OC, each with its own
  self-loop and 3-ring of limbs (4-node cluster, Φ_PA = 40000).
- A meta-observer M added with bi-edges to OA, OB, OC.  Topology
  alone is not enough: without M → M, Φ_PA(M) = 0 even though
  M sits at the geometric centre of the composite.
- Add M's own self-loop. Now Φ_PA(M) = 40000 — the composite is
  *held*.  And the first-order observers gain scope +1 from their
  newly-back-pointing M neighbour, so each Φ_PA(OA/OB/OC) rises
  from 40000 to 50000.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 54 | `54-composite-distinction-meta-observer.6th` | 21 | Numerical demonstration of the composite-distinction threshold. Without meta-self-loop Φ_PA(M)=0; with it Φ_PA(M)=40000 and first-order observers gain scope. |
| 55 | `55-trace-composite-distinction.6th`         | 5  | Three-snapshot visual companion: three first-order clusters → meta-observer wired but no self-loop (Φ_PA(M) still 0) → meta-self-loop closes the construction. First-order observers tagged NGET=7, meta-observer NGET=9 for renderer differentiation. |

```bash
make trace-composite-distinction
make forensic-composite-distinction
```

![Pilot G composite distinction — three first-order observers each
hold their own composite (Φ_PA=40000); the meta-observer holds the
joint composite only after its own self-loop
closes.](../docs/figures/composite_distinction.png)

The corollary for the v9.0 cosmology: higher-order self-reference is
the necessary structural ingredient for any larger cluster to be
*held* (rather than merely connected) by an observer of observers.
Pilot G is the smallest construction that exhibits the
recursion explicitly.

## Pilot H — mutation + substrate-readable selection (56–57)

Pilot G's composite was held over three *identical* first-order
observers.  Pilot H is the next epoch: substrate-native mutation
generates structural diversity, the meta-observer's substrate-
readable Φ_PA measurement provides the selection pressure, and
the surviving multiset is intrinsically distinguishable — three
"particle species" rather than three copies of one.

Mechanism:

- **Mutation.**  Five candidate first-order observers with varied
  topologies are hand-built; they span the structural space that an
  actual mutation operator would sample (different ring sizes,
  missing self-loop, isolated MARK).
- **Selection.**  Meta-observer M reads each candidate's Φ_PA and
  bi-edges only to candidates with Φ_PA > 0.  Pure substrate-
  readable criterion — no host annotation, no global oracle, no
  blind-Darwin fitness function outside the substrate.
- **Diversified composite.**  M acquires its own self-loop after
  selection.  Φ_PA(M) = 40000.  The three survivors gain scope +1
  from the back-edge to M and end at distinct Φ_PA signatures
  (50000 / 60000 / 70000) — substrate-native speciation in one
  epoch.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 56 | `56-mutation-selection-particle-zoo.6th` | 29 | Numerical: V1/V2/V3 (3/4/5-limb ring + self-loop) survive selection; V4 (no self-loop) and V5 (isolated) are pruned. Distinct-Φ_PA assertions confirm structural diversity. |
| 57 | `57-trace-mutation-selection.6th`         | 4  | Visual: three snapshots (mutation-pool / selection-coupled / diversified-composite). NGET tags: 7=survivor-class, 5=broken-self-ref, 3=isolated, 9=meta-observer. |

```bash
make trace-mutation-selection
make forensic-mutation-selection
```

![Pilot H — mutation + substrate-readable natural selection.
Three panels: five candidate variants → meta-observer couples
only to those with Φ_PA > 0 → meta-self-loop closes the
diversified composite.](../docs/figures/mutation_selection.png)

The corollary for the v9.0 cosmology: distinguishable persistent
self-referential units ("particles") arise from variation +
substrate-internal observation without needing an external
selection authority.  Further epochs would iterate the same
mechanism — mutate the survivors, re-select via meta-observation,
build M2 over multiple M's.

## Pilot I — multi-level particle hierarchy (58–59)

Pilot G held a composite over three identical observers; Pilot H
introduced structural diversity via mutation and substrate-readable
selection.  Pilot I iterates the same mechanism one level further:
each species now has MULTIPLE INSTANCES, a family observer holds
its instances, and a genus-level observer holds the families.

Three levels of self-reference, each constructed by the same
Pilot G pattern (bi-edges to substructures + own self-loop):

```
Level 2 (genus):    M2 ──self
                    │
            ┌───────┼───────┐
Level 1     Mα    Mβ      Mγ    (each with own self-loop)
(families)  │     │ │      │ │ │
            α1   β1 β2    γ1 γ2 γ3   (each with own self-loop)
Level 0
(instances) └─ ring-3 ─┘ └─ ring-4 ─┘ └─ ring-5 ─┘
            (limbs not shown — see figure)
```

Substrate-readable taxonomy emerges naturally:

| Level | Members | Φ_PA signature |
|-------|---------|----------------|
| 0 (instances) | α (1) / β (2) / γ (3) | 50000 / 60000 / 70000 |
| 1 (families)  | Mα / Mβ / Mγ          | 30000 / 40000 / 50000 |
| 2 (genus)     | M2                     | 40000                 |

Distinct Φ_PA signatures at each level make the hierarchy
substrate-readable.  Within-family instances (β1 vs β2, γ1 vs γ2
vs γ3) have identical Φ_PA — the substrate-native analogue of
physical particle indistinguishability.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 58 | `58-particle-families-hierarchy.6th` | 35 | Numerical: builds 6 instances + 3 family observers + 1 genus observer; asserts distinct Φ_PA at each level, within-family indistinguishability, and final inventory (NODES=36, EDGES=132). |
| 59 | `59-trace-particle-families.6th`     | 4  | Visual: three snapshots (instances-built / families-held / genus-held) with NGET tags 1/2/3 for species, 5/6/7 for family observers, 9 for genus. |

```bash
make trace-particle-families
make forensic-particle-families
```

![Pilot I — multi-level particle hierarchy.  Three panels showing
six independent instances → three family observers wired in with
own self-loops → one genus observer holding the families with its
own self-loop.](../docs/figures/particle_families.png)

The corollary for the v9.0 cosmology: the same composite-distinction
mechanism scales to arbitrary depth.  Each new level requires only
that the higher-order observer (a) bi-edges its substructures and
(b) carries its own self-loop — the same two-ingredient recipe that
constituted distinction at level 0.  No fundamentally new substrate
machinery is needed to climb the ladder.

## Pilot J — substrate-native charge conservation (60–61)

Pilot I gave us a substrate-readable taxonomy.  Pilot J asks the
next physics-like question: under substrate rewriting, what is
conserved?

The answer mirrors Noether/baryon-number conservation in physics:
if the rewrite rule never creates or destroys NGET tags but only
moves them between cells, then both the TOTAL CHARGE (Σ NGET
across all cells) AND THE PER-SPECIES COUNT (number of cells with
each specific NGET value) are conserved exactly under arbitrary
many STEP-CA iterations.

Construction:
- 11-cell linear chain (Peano `succ` for PREV/NEXT linking).
- 5 particles packed at the left end with NGET 1,2,3,1,2
  (species α, β, γ, α, β — total Σ = 9; α-count = 2, β-count = 2,
  γ-count = 1).
- STEP-CA rule `charge-shift`: each cell becomes its left neighbour's
  NGET if empty and the left is occupied; becomes empty if non-empty
  and the right is empty; otherwise unchanged.  Equivalent to
  Wolfram Rule 184 lifted from {0,1} to integer NGET values.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 60 | `60-charge-conservation.6th`        | 56 | Numerical: 5 STEP-CA steps, asserts exact position pattern at each step AND Σ NGET = 9 + per-species counts (2,2,1) preserved across all steps. |
| 61 | `61-trace-charge-conservation.6th`  | 4  | Visual: 6 stacked snapshots showing particles spreading from packed (1,2,3,1,2,_,_,_,_,_,_) to fully spread (_,1,_,2,_,3,_,1,_,2,_) while species colors persist. Renderer uses `--layout chain` for horizontal time-series. |

```bash
make trace-charge-conservation
make forensic-charge-conservation
```

![Pilot J — six stacked chain snapshots show 5 particles spreading
rightward across an 11-cell substrate over 5 STEP-CA steps; each
particle keeps its species color (teal/amber/plum) and Σ NGET = 9
persists across every frame.](../docs/figures/charge_conservation.png)

The corollary for the v9.0 cosmology: conservation laws are
substrate-readable — checked by `EACH`ing and summing, without any
external bookkeeping.  Any rule that only MOVES NGET (does not
create or destroy it) carries an automatic Noether-style invariant.

## Pilot K — spontaneous coalition assembly (62–63)

Pilot I built the three-level hierarchy by hand: every meta-observer
was MARKed explicitly in the demo script.  Pilot K removes the hand.

A single procedural word `try-spawn-coalition` reads the substrate
(do these three observers form a mutually-pointing K_3 triangle?)
and conditionally spawns a new meta-observer over them — bi-edges
to all three + own self-loop (Pilot G recipe).  Same word fires at
every tier.

Construction:
- Seed substrate with 9 first-order observers in 3 disjoint
  mutually-pointing triangles (α-clique OA1↔OA2↔OA3↔OA1, β-clique
  OB1..OB3, γ-clique OC1..OC3).  Each observer is a Pilot G cluster.
- coalition-cycle 1: `try-spawn-coalition` fires 3 times, once per
  known trio.  Each detection spawns a tier-2 family observer
  (Mα, Mβ, Mγ).
- Negative test: `try-spawn-coalition` on a CROSS-family trio
  (OA1, OB1, OC1) correctly refuses to spawn — `EDGE?` fails.
- socialize-metas: family observers Mα/Mβ/Mγ wire into a mutual
  triangle.
- coalition-cycle 2: same `try-spawn-coalition` fires once on the
  family-tier triangle, spawns the genus observer M2.

End-state hierarchy is shape-identical to Pilot I (9 instances → 3
families → 1 genus), but every meta-observer was MARKed by the rule
responding to substrate-readable `EDGE?` conditions.

| Demo | File | ✓ | Property |
|------|------|---|----------|
| 62 | `62-spontaneous-coalition-assembly.6th` | 32 | Numerical: seeds 3 triangles, applies `try-spawn-coalition` 4 times, asserts each spawn occurred + cross-family negative test + final Φ_PA at every tier. |
| 63 | `63-trace-spontaneous-assembly.6th`     | 4  | Visual: 4-snapshot trace (seeded / cycle-1 / socialized / cycle-2) shows the hierarchy emerging level by level under repeated application of the same rule. |

```bash
make trace-spontaneous-assembly
make forensic-spontaneous-assembly
```

![Pilot K — four panels show a three-level observer hierarchy
emerging from 9 first-order observers + a single substrate-readable
coalition-detection rule.  No hand-placed meta-observers; every
spawn is a substrate-readable
response.](../docs/figures/spontaneous_assembly.png)

The corollary for the v9.0 cosmology: hierarchy formation is not
imposed top-down.  A flat substrate populated with mutually-pointing
clusters self-organises into a multi-level taxonomy under a single
local detection-and-spawn rule.  Pilot I's compositional structure
is what the substrate produces, not what we impose.

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
`EACH-EDGE`, `emit`, and `.` alone. The 40-primitive count is
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
    ("54-my-new-demo.6th"           N)))   ; N = expected ✓
```

Update the cumulative gate (currently 963) and `make verify` passes
cleanly. To add a visual trace, `use dot` and emit `dot-snapshot`
calls between substrate operations.

## References

- Repository root: [`../README.md`](../README.md)
- Three-tier taxonomy: [`../CLAIMS.md`](../CLAIMS.md)
- Sixth as stand-alone language: [`../LANGUAGE.md`](../LANGUAGE.md)
- Substrate-philosophical mapping: [`../SUBSTRATE.md`](../SUBSTRATE.md)
- v9.0 preprint: (pending arXiv submission)
