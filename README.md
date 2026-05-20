# Sixth

> A minimal executable substrate language —
> 38 primitives, 49 reproducible demos, 702 ✓ across them all,
> reference implementation for the Pointer Architecture v9.0 preprint.

```
language tests:    ok
substrate tests:   ok
examples:          702 / 702 ✓ across 49 demos
docs build:        ok
artifact status:   reproducible
```

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

# Spencer-Brown's first mark — the sacred hello world
racket -l sixth/cli -- run examples/00-first-distinction.6th

# the whole regression — all 49 demos, all 702 assertions
make verify
```

The substrate stands or falls on `make verify`. The expected output
ends with `artifact status:  reproducible`; any failure exits
non-zero and prints `BROKEN`.

## Pilots A–F and visual traces

The substrate-native pilots are six levels of ascent above the
foundational demos (`01-numbers` … `20-conway-glider`, 352 ✓):

| Pilot | Demos | Asserts | What |
|-------|-------|---------|------|
| **A** Substrate-native autopoiesis           | 21–25 | 81  | Self-producing rings; observer collapse; reflexive vs non-reflexive persistence. Operationalises Maturana–Varela on the discrete substrate. |
| **B** Conscious evolution                    | 26–29 | 88  | Symbiosis, reproduction with mutation, observer-driven selection (Lamarck-style, not blind Darwin), goal-directed observer behaviour. |
| **C** Cosmogenesis bootstrap                 | 30    | 21  | 13-node 48-edge substrate constructed by a substrate-resident observer from one `MARK` at `t=0`; persists under harsh autopoietic decay. |
| **D** Substrate-internally-driven cosmogenesis | 31  | 17  | Observer establishes its own self-loop at `t=0+` (substrate-monist bootstrap), then drives further construction via `NSUM(O) ≥ target-min` — no host counter. |
| **E** Substrate-internal Φ_PA measurement     | 32   | 12  | `stdlib/phi.6th` ships three candidate measures: `phi-pa`, `phi-integ`, `phi-bidir`. Same 38 primitives that build the substrate also compute its consciousness scalar. |
| **F** Encoding-map demonstrations             | 33–36 | 46 | Toy substrates for PSH1–PSH5. F.1 transformer; F.2 brain; F.3 split-brain (motivates Φ_integ); F.4 ant colony. |
| (trace) | 37–39 | 18 | DOT-rendered snapshots of Pilots D, C, F.3 via `stdlib/dot.6th` + `code/render_trace.py`. Single command `make traces`. |
| (long)  | 40–41 | 16 | Parametric long-epoch pilots. Demo 40 = stable autopoiesis (structurally invariant), demo 41 = growing substrate. CLI `-D max-cycles=N -D snap-every=K` drives arbitrary run lengths (TCO-safe). |
| (foundation visual) | 42–46 | 30 | State-aware DOT traces — Conway blinker / glider, Wolfram Rule 110 / 90, Rule 184 1D glider. Per-cell NGET colours alive=red / dead=grey. `make foundation-gifs`. |
| (atomic) | 47–48 | 10 | One snapshot per primitive operation. Demo 47 = Pilot D in 76 frames; demo 48 = sacred hello world in 7 frames. Entity-by-entity emergence through `MARK` and `EDGE+` alone. `make atomic-gifs`. |

Cumulative: **702 ✓ / 0 ✗ across 49 demos** (Pilots A–F core + 3 substrate-monism trace pilots + 2 long-epoch parametric + 5 foundation visual traces (Conway blinker/glider, Rule 110/90, 1D glider) + 2 atomic-build traces showing entity-by-entity emergence).

## Running and rendering

```bash
# one-shot artifact-status report (Tier-1 verification, see CLAIMS.md)
make verify

# any of the 49 demos
racket -l sixth/cli -- run examples/35-phi-pa-split-brain-toy.6th

# all 49 demos against the rackunit regression gate
raco test tests/examples-test.rkt

# render the three static trace figures (Pilots C, D, F.3)
make traces

# render Pilot D as animated GIF
make gif-pilot-d

# long-epoch autopoiesis at arbitrary scale (CLI parametric)
make trace-long-epoch CYCLES=2000 SNAP=200

# or directly via the CLI
racket -l sixth/cli -- -D max-cycles=10000 -D snap-every=1000 \
                      run examples/40-long-epoch-autopoiesis.6th

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
sixth/        engine — lexer, parser, compiler, VM, 38 primitives
              (15 base + 23 substrate), module loader, REPL, CLI
              (`-D KEY=VAL` for parametric runs), `#lang sixth`
              reader, PyTorch FFI bridges
stdlib/       Sixth-language standard library (prelude, peano,
              graph, grid, ca, bfs, debug, phi, dot) — helpers
              above the 38 primitives. phi.6th ships three
              candidate substrate-readable observability measures;
              dot.6th emits GraphViz DOT snapshots for the
              visual-trace pilots.
examples/     49 emergence demonstrations
              (00 hello + 01–20 foundations + 21–36 Pilots A–F +
              37–39 substrate-monism traces + 40–41 long-epoch
              parametric + 42–46 foundation visual traces +
              47–48 atomic-build traces).
              See `examples/README.md` for the full demo catalogue
              with embedded figures and animations.
code/         Python tooling. render_trace.py reads dot.6th
              snapshots from stdin; emits static multi-panel PNG /
              SVG / PDF or animated GIF.
scripts/      verify.sh (artifact-status report; backs `make verify`)
tests/        rackunit suites — lexer, parser, VM, substrate,
              loader, examples-test.rkt (regression gate at 702 ✓)
docs/         Scribble manual + embedded README figure
build/        regeneratable artefacts (raco scribble HTML, render
              outputs) — gitignored
legacy/       original chibi-Scheme prototype + first-pass PyTorch
              bridges, preserved unmodified as parity oracle
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

Bridge tests run via `raco test tests/bridges/torch-test.rkt`; they
skip cleanly if libtorch is absent.

## Reference

Sixth is the operational substrate behind:

**Pointer Architecture v9.0** (preprint, pending arXiv submission).
The paper defines `𝒮 = (G, R, C, A, π)` formally, maps it to Sixth's
38 primitives, derives the candidate substrate-readable `Φ_PA`
family of consciousness measures from Pilots A–F, and posits the
substrate-monist identity thesis as a working hypothesis under the
falsifier F5.

See [`SUBSTRATE.md`](./SUBSTRATE.md) for the substrate-philosophical
mapping and literature references inherited by the v9.0 preprint
(Spencer-Brown, Maturana–Varela, Hofstadter, Rovelli, Wolfram,
Friston, Whitehead, Spinoza).

## License

MIT. See `info.rkt`.
