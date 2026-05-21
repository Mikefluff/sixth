# Sixth

> A minimal executable substrate language —
> 40 primitives, 98 reproducible demos, 1440 ✓ across them all,
> reference implementation for the Pointer Architecture v9.0 preprint.

```
language tests:    ok
substrate tests:   ok
examples:          1440 / 1440 ✓ across 98 demos
docs build:        ok
ffi optional:      n/a
renderer tests:    ok
figures fresh:     ok (23 forensic JSONL traces match)
artifact status:   reproducible
```

Stronger reproducibility evidence via `make verify-repro` — runs
each forensic-trace demo twice, hashes the JSONL, asserts byte-
identical outputs across all 23 demos × 2 runs.

![Pilot D evolution — substrate-internally-driven cosmogenesis,
shell-count 0 → 4, observer node in red.](./docs/figures/pilot_d_trace.png)

## What this is

Sixth is a small Forth-like concatenative stack language hosted on
Racket, with a hypergraph rewriting substrate attached as a second
tier of primitives. From `MARK` (the only constructor of a fresh
distinguishable token) and `EDGE+` (the only constructor of a
pointer between tokens), the released harness derives Peano
arithmetic, cellular automata, Conway's Game of Life,
Maturana–Varela autopoiesis, observer-relative cosmogenesis,
self-measurement via the substrate-monist Φ_PA family, and toy
substrates for the transformer / brain / split-brain / ant-colony
encoding maps of the v9.0 preprint.

It is a **minimal executable substrate** on which hypotheses about
difference, pointers, self-reference, autopoiesis, and observation
can be checked — not a claim to have solved consciousness. The
[CLAIMS.md](./CLAIMS.md) document carries the explicit three-tier
taxonomy that separates what the tests prove (Tier 1), what the
demos demonstrate on synthetic data (Tier 2), and what remains a
philosophical / research hypothesis (Tier 3). The
[LANGUAGE.md](./LANGUAGE.md) document pitches Sixth as a stand-alone
programming language for readers who reject the v9.0 cosmology.

## 30-second quickstart

```bash
# install the package
raco pkg install --link .

# Spencer-Brown's first mark — the second rung of the canonical ladder
racket -l sixth/cli -- run examples/02-first-distinction.6th

# the whole regression — all 98 demos, all 1440 assertions
make verify
```

The substrate stands or falls on `make verify`. The expected output
ends with `artifact status:  reproducible`; any failure exits
non-zero and prints `BROKEN`.

## Pilots A–F and visual traces

The substrate-native pilots are six levels of ascent above the
foundational demos (`01-numbers` … `20-conway-glider`, 359 ✓):

| Pilot | Demos | Asserts | What |
|-------|-------|---------|------|
| **A** Substrate-native autopoiesis           | 32–36 | 80  | Self-producing rings; observer collapse; reflexive vs non-reflexive persistence. Operationalises Maturana–Varela on the discrete substrate. |
| **B** Conscious evolution                    | 37–40 | 88  | Symbiosis, reproduction with mutation, observer-driven selection (Lamarck-style, not blind Darwin), goal-directed observer behaviour. |
| **C** Cosmogenesis bootstrap                 | 41    | 21  | 13-node 48-edge substrate constructed by a substrate-resident observer from one `MARK` at `t=0`; persists under harsh autopoietic decay. |
| **D** Substrate-internally-driven cosmogenesis | 42  | 17  | Observer establishes its own self-loop at `t=0+` (substrate-monist bootstrap), then drives further construction via `NSUM(O) ≥ target-min` — no host counter. |
| **E** Substrate-internal Φ_PA measurement     | 43   | 12  | `stdlib/phi.6th` ships three candidate measures: `phi-pa`, `phi-integ`, `phi-bidir`. Same 40 primitives that build the substrate also compute its consciousness scalar. |
| **F** Encoding-map demonstrations             | 44–47 | 46 | Toy substrates for PSH1–PSH5. F.1 transformer; F.2 brain; F.3 split-brain (motivates Φ_integ); F.4 ant colony. |
| (trace) | 55–57 | 18 | DOT-rendered snapshots of Pilots D, C, F.3 via `stdlib/dot.6th` + `code/render_trace.py`. Single command `make traces`. |
| (long)  | 53–54 | 19 | Parametric long-epoch pilots. Demo 40 = stable autopoiesis (after-decay/after-restore sub-cycle snapshots make the dynamics visible), demo 41 = growing substrate. CLI `-D max-cycles=N -D snap-every=K` drives arbitrary run lengths (TCO-safe). |
| (foundation visual) | 58–62 | 45 | State-aware DOT traces — Conway blinker / glider, Wolfram Rule 110 / 90, Rule 184 1D glider. Per-cell NGET colours alive=red / dead=grey. Per-step rule-table assertions verify the dynamics (not just end state). `make foundation-gifs`. |
| (atomic) | 63–64 | 10 | One snapshot per primitive operation. Demo 47 = Pilot D in 76 frames; demo 48 = sacred hello world in 7 frames (events: `void`, `first-distinction`, `observer-state`, `i-not-i`, `first-pointer`, `re-entry`, `phi-pa-measurement`). Entity-by-entity emergence. `make atomic-gifs`. |
| (PA-ontological) | 65 | 5 | First shell of Pilot D unfolded as Spencer-Brown / PA v9.0 events: `void → first-distinction → observer-state → re-entry → second-distinction → i-not-i-relation → recognition → second-not-i → closure-of-not-i → o-other-closure → state-fill`. 11 frames. Opens the macro that demo 37 collapses into one frame. `make trace-pa-ontological-shell`. |
| (Pilot E trace) | 66 | 9 | Three observers × Φ_PA computed substrate-internally. case 1 (non-reflexive, scope 5) → Φ_PA=0; case 2 (reflexive, scope 5) → Φ_PA=50000; case 3 (demo-31 shape, scope 13) → Φ_PA=130000. PSH1 self-reference discriminator visible. `make trace-pilot-e`. |
| (Pilot F.1 trace) | 67 | 9 | Transformer encoding (12 heads × 4 layers). PSH1 single-pass Φ_PA=0; PSH2 KV-cache back-edge Φ_PA=40000. `make trace-pilot-f1`. |
| (Pilot F.2 trace) | 68 | 10 | Brain encoding (DMN hub + 7 cortical areas). PSH3 waking thalamocortical loop Φ_PA=80000; in-place EDGE- decouples → Φ_PA=0. `make trace-pilot-f2`. |
| (Pilot F.4 trace) | 69 | 8 | Ant-colony encoding (queen + 5 trail junctions). PSH5 living colony with queen-pheromone self-loop Φ_PA=60000; in-place EDGE- severs loop → Φ_PA=0. `make trace-pilot-f4`. |
| **G** Composite distinction via meta-self-loop | 48/70 | 26 | Three first-order observers OA/OB/OC each hold their own composite (4-node cluster, Φ_PA=40000). A meta-observer M bi-edged to all three holds nothing (Φ_PA=0) until M acquires its own self-loop, at which point Φ_PA(M)=40000 and the first-order observers gain scope +1 (Φ_PA → 50000). Demonstrates that higher-order self-reference is what holds composite distinction. `make trace-composite-distinction`. |
| **H** Mutation + substrate-readable selection | 49/71 | 33 | Five candidate first-order observers with varied topologies (3/4/5-limb rings + self-loop; 3-limb ring without self-loop; isolated MARK). Meta-observer M reads each candidate's Φ_PA and bi-edges only to those with Φ_PA > 0; M's own self-loop closes the construction. Result: diversified composite over three structurally distinct "particle species" (Φ_PA = 50000 / 60000 / 70000). Lamarck-style, observer-driven — not blind Darwin. `make trace-mutation-selection`. |
| **I** Multi-level particle hierarchy           | 50/72 | 39 | Six instances across three species (α: 1×3-limb, β: 2×4-limb, γ: 3×5-limb), each with own self-loop. Three family observers Mα/Mβ/Mγ hold their populations (each with own self-loop, Pilot G pattern). One genus observer M2 holds the families (own self-loop). Result: three-level taxonomy with distinct Φ_PA signatures at each level — instances 50000/60000/70000, families 30000/40000/50000, genus 40000. Within-family instances are indistinguishable (substrate-native analogue of physical particle indistinguishability); cross-family + cross-level differences are substrate-readable. `make trace-particle-families`. |
| **J** Substrate-native charge conservation     | 51/73 | 60 | 11-cell linear chain, 5 particles tagged by species (NGET=1/2/3 → α/β/γ). STEP-CA `charge-shift` rule (generalised Wolfram Rule 184 lifted from {0,1} to integer NGET) moves particles right one cell per step iff the slot is empty. Across 5 steps, total Σ NGET = 9 AND per-species count (α=2, β=2, γ=1) are conserved EXACTLY. Smallest construction exhibiting a Noether-style conservation law derived structurally from the rule, substrate-readable via `EACH` + sum. `make trace-charge-conservation`. |
| **K** Spontaneous coalition assembly           | 52/74 | 36 | 9 first-order observers in 3 disjoint K_3 mutual-pointing triangles. A single substrate-readable rule `try-spawn-coalition` — three `EDGE?` checks → MARK new node + bi-edges + own self-loop — fires four times (3× at family tier + 1× at genus tier after sibling socialisation) and reconstructs the full Pilot I hierarchy with no hand-placed meta-observers. The rule reads substrate state, the substrate spawns the response. `make trace-spontaneous-assembly`. |
| **L** Particle interaction (bound state)       | 75/76 | 33 | Two structurally distinct particles α (NGET=1, 3-limb cluster) and β (NGET=2, 4-limb cluster) interact via a substrate-readable BIND rule: mutual bi-edge α↔β + composite observer M (NGET=8) with own self-loop. The bound state carries its own Φ_PA = 30000; α and β gain scope +2 each → Φ_PA 60000/70000. Σ NGET over particles preserved (M is binding marker, not a particle). Same physics-grammar as meson = quark + antiquark + gluon binding. `make trace-particle-interaction`. |
| **M** Bound-state decay (inverse of L)         | 77/78 | 32 | Reverse direction of Pilot L. The DECAY EVENT is severing M's self-loop alone — Φ_PA(M) collapses 30000 → 0 the instant phi-self-ref(M) = 0, even though M is still topologically connected to α and β (Pilot G principle in reverse). Phase B housekeeping removes M↔α/β + α↔β bi-edges; M survives as an isolated ash node (no edges, NGET=0). Σ NGET over particles preserved across the full bind+decay cycle. Binding is REVERSIBLE under EDGE-. `make trace-particle-decay`. |
| (stress) | 79–84 | 59 | Parametric long-run stress tests for EVERY dynamic pilot: closed-ring charge conservation (79), bind+decay idempotence (80), autopoiesis stability (81), Conway blinker periodicity (82), sprout linear growth (83), Rule 184 ring conservation (84). Each tracks its invariant at EVERY cycle (not just end-state) and asserts max-drift = 0 at the end. Default CYCLES=1000 keeps the regression gate CI-fast; CLI override `-D max-cycles=N` scales to 10⁶ on the same source. Showcase: `make stress-test STRESS_CYCLES=1000000` confirms all six invariants hold exactly across one million iterations each. |
| (honest-emergence) | 85–89, 91–92 | 160 | Corrective to Pilots G/H/I/L/M/K which hand-place composites. Demo 85: EACH-2PATH triangle scanner without pre-knowledge spawns composites for hand-wired triangles. Demo 86: full emergence — 5-cell chain → close-2path adds 1↔3, 2↔4, 3↔5 → triangle-scanner spawns 3 composites. Demo 87: honest Pilot H — EACH-walked selection rule reads phi-pa per node and attaches survivors to M. Demo 88: honest Pilot I — two-tier hierarchy from a 7-cell chain via 4 rule applications. Demo 89: honest Pilot L — nested-EACH pair scanner discovers all 9 cross-flavour bindings without a `bind(α, β)` enumeration. Demo 91: honest Pilot M — 3-phase substrate-walked decay scanner (decay-event severs self-loops on NGET=8, unwind removes incident edges, ash resets NGET) processes 9 bound states without per-composite source lines. Demo 92: recursive N-tier hierarchy iterated to FIXED POINT — same rules at every tier with memory-stored NGET filter, 5+3+1+0 spawn pattern, termination data-driven. |
| (Peircean trit) | 90 | 21 | Substrate-readable classifier tags every node into balanced trit {−1, 0, +1} corresponding to Peirce's firstness / secondness / thirdness. Trit 0 (secondness) = self-loop only = Φ_PA = L_max — the "Tao of the substrate." Philosophical anchor: Peirce's reduction thesis (Burch 1991; Hereth Correia & Pöschel 2006), not the apparent "three multiplicands in Φ_PA" rhyme (which is a notational accident, not structural). |
| (HEDGE3) | 93–98 | 119 | Typed trivalent hyperedge primitive family (HEDGE3+/-/?, HEDGES3, HEDGES3-KIND, EACH-HEDGE3, EACH-HEDGE3-KIND; +7 primitives) + `stdlib/hedge.6th` kind constants. Four canonical kinds with strict typing: WITNESS (src, dst, witness — substrate-native provenance; demo 93), CONTEXT (in, ctx, out — rewrite-rule firings as substrate-readable history; demo 95), MEDIATOR (src, mid, dst — channels as substrate nodes with load tracking + rerouting + fault injection; demo 97), SIMPLEX (a, b, c — undirected 2-cells of a simplicial complex with Euler characteristic χ = V−E+F computed from substrate state; demo 98). Demo 94 shows all four coexisting under strict typing. Demo 96 demonstrates wobble-at-position-3 via DNA codon analogy (8 hyperedges encode 32 codons, 4× compression matches Crick's wobble degeneracy). Substantive substrate-level realisation of Peirce's reduction thesis. Coexists with binary edges; bootstrap claim for the original 40-demo ascent preserved. |

Cumulative: **1440 ✓ / 0 ✗ across 98 demos** (canonical Spencer-Brown ladder + substrate applications + Pilots A–F core + 3 substrate-monism trace pilots + 2 long-epoch parametric + 5 foundation visual traces + 2 atomic-build traces + Pilots G–M composite/particle pilots + stress-test track + honest-emergence track + Peircean trit observer + HEDGE3 typed trivalent hyperedges).

## Running and rendering

```bash
# one-shot artifact-status report (Tier-1 verification, see CLAIMS.md)
make verify

# any of the 98 demos
racket -l sixth/cli -- run examples/46-phi-pa-split-brain-toy.6th

# all 98 demos against the rackunit regression gate
raco test tests/examples-test.rkt

# render the three static trace figures (Pilots C, D, F.3)
make traces

# render Pilot D as animated GIF
make gif-pilot-d

# long-epoch autopoiesis at arbitrary scale (CLI parametric)
make trace-long-epoch CYCLES=2000 SNAP=200

# or directly via the CLI
racket -l sixth/cli -- -D max-cycles=10000 -D snap-every=1000 \
                      run examples/53-long-epoch-autopoiesis.6th

# REPL
racket -l sixth/cli -- repl
```

`#lang sixth` is first-class — any Racket-aware editor (DrRacket,
racket-mode) runs `.rkt` files starting with `#lang sixth`:

```racket
#lang sixth
: factorial dup 1 > if dup 1 - factorial * else drop 1 then ;
5 factorial .   \ prints 120
```

## Repository layout

```
sixth/        engine — lexer, parser, compiler, VM, 40 primitives
              (17 base + 23 substrate), module loader, REPL, CLI
              (`-D KEY=VAL` for parametric runs), `#lang sixth`
              reader, PyTorch FFI bridges
stdlib/       Sixth-language standard library (prelude, peano,
              graph, bfs, debug, phi, dot) — helpers above the 40
              primitives. phi.6th ships three
              candidate substrate-readable observability measures;
              dot.6th emits GraphViz DOT snapshots for the
              visual-trace pilots.
examples/     98 emergence demonstrations
              (00 hello + 01–20 foundations + 21–36 Pilots A–F +
              37–39 substrate-monism traces + 40–41 long-epoch
              parametric + 42–46 foundation visual traces +
              47–48 atomic-build traces + 49 PA-ontological
              shell decomposition + 50 Pilot E visual trace +
              51–53 Pilot F.1/F.2/F.4 visual traces +
              54–55 Pilot G composite distinction via meta-self-loop +
              56–57 Pilot H mutation + substrate-readable selection +
              58–59 Pilot I multi-level particle hierarchy +
              60–61 Pilot J charge conservation +
              62–63 Pilot K spontaneous coalition assembly).
              See `examples/README.md` for the full demo catalogue
              with embedded figures and animations.
code/         Python tooling. render_trace.py reads dot.6th
              snapshots from stdin; emits static multi-panel PNG /
              SVG / PDF or animated GIF.
scripts/      verify.sh (artifact-status report; backs `make verify`)
tests/        rackunit suites — lexer, parser, VM, substrate,
              loader, examples-test.rkt (regression gate at 1440 ✓)
docs/         Scribble manual + embedded README figure
build/        regeneratable artefacts (raco scribble HTML, render
              outputs) — gitignored
legacy/       original chibi-Scheme prototype + first-pass PyTorch
              bridges. Frozen historical reference; production
              implementation is the Racket-hosted sixth/ collection
              (see legacy/README.md). Not maintained, not in CI.
CLAIMS.md     three-tier epistemic taxonomy:
              Tier 1 proven by tests / Tier 2 demonstrated by
              examples / Tier 3 philosophical-or-research-hypothesis
LANGUAGE.md   Sixth as a stand-alone programming language,
              evaluable without engaging the v9.0 cosmology
```

## Documentation

```bash
make docs-html
# → open build/docs/manual.html
```

The Scribble manual covers:

- `language.scrbl` — syntax, semantics, every base primitive
- `substrate.scrbl` — substrate's foundational mapping and the
  ontological role of each substrate primitive
- `stdlib.scrbl` — every stdlib word with stack effect
- `architecture.scrbl` — lexer / parser / compiler / VM / substrate
  / bridges module boundaries
- `migration.scrbl` — chibi-Scheme → Racket migration notes

## PyTorch FFI bridges

`sixth/bridges/torch/` lifts the substrate into autograd via the
native Racket FFI to libtorch (no Python in the path). Three shapes:

- `shadow.rkt` — Substrate ⇄ Tensor mirror; lossless round-trip
- `diff.rkt`   — autograd-aware operations over substrate features
- `nn.rkt`     — Substrate-NN continual-learning architecture

Bridge tests are advertised at `tests/bridges/torch-test.rkt` but the
file has not yet been ported from the chibi-Scheme legacy tree;
`tests/bridges/README.md` documents the gap. `verify.sh` reports
`ffi optional: n/a` cleanly when the test file is absent.

## Reference

Sixth is the operational substrate behind:

**Pointer Architecture v9.0** (preprint, pending arXiv submission).
The paper defines `𝒮 = (G, R, C, A, π)` formally, maps it to Sixth's
40 primitives, derives the candidate substrate-readable `Φ_PA`
family of consciousness measures from Pilots A–F, and posits the
substrate-monist identity thesis as a working hypothesis under the
falsifier F5.

See [`SUBSTRATE.md`](./SUBSTRATE.md) for the substrate-philosophical
mapping and literature references inherited by the v9.0 preprint
(Spencer-Brown, Maturana–Varela, Hofstadter, Rovelli, Wolfram,
Friston, Whitehead, Spinoza).

## License

MIT. See `info.rkt`.
