# Sixth — substrate-research language

> 15 base primitives + 23 substrate primitives.
> From `MARK` and `EDGE+` rise numbers, time, space, conservation laws,
> particles, observers, autopoietic patterns, and a substrate-internally
> driven cosmogenesis.

Sixth is a small Forth-like stack language hosted on Racket with an
attached hypergraph-rewriting substrate. It is the operational
realisation of the Pointer Architecture substrate
`𝒮 = (G, R, C, A, π)` of the v9.0 preprint, and serves as the released
artifact behind that paper's load-bearing claim L0 (operational
substrate).

The 38 primitives factor into three ontological moves:

- **Difference** — `MARK` creates a fresh distinguishable token.
- **Pointer** — `EDGE+` relates one token to another.
- **Rewrite** — `EACH` / `STEP-CA` family applies a rule across the substrate.

Everything else — Peano arithmetic, causal time, fixed-point stability,
1D/2D distance, Rule 110, Conway's Game of Life, Maturana–Varela
autopoiesis, conscious evolution, a substrate-resident observer that
bootstraps its own 13-node 49-edge cosmos, the substrate's own
self-measurement via three candidate substrate-readable observability
measures, toy substrates instantiating the transformer / brain /
split-brain / ant-colony encoding maps of the v9.0 preprint, and a
visual-trace pilot that renders Pilot D evolution as a multi-panel
figure — is derived in 40 demos totaling 646 assertions.

**What the substrate is and is not.** Sixth is a minimal executable
substrate on which hypotheses about difference, pointers, self-
reference, autopoiesis, and observation can be checked. It is NOT a
claim to have solved consciousness. Two parallel documents lay out
the separation:

- [CLAIMS.md](./CLAIMS.md) — three-tier taxonomy: what the tests
  prove (Tier 1), what the demos demonstrate on synthetic data
  (Tier 2), what remains a philosophical conjecture under the v9.0
  preprint's F5 falsifier (Tier 3).
- [LANGUAGE.md](./LANGUAGE.md) — Sixth as a stand-alone Forth-like
  programming language, evaluable independently of any consciousness
  or cosmology claim. "Read it if you want to know what Sixth IS
  as a programming language, independent of any v9.0 preprint
  claim."

## Pilots A–F

The substrate-native pilots are six levels of ascent above the
foundational demos (`01-numbers` … `20-conway-glider`, 352 ✓):

| Pilot | Demos | Asserts | What |
|-------|-------|---------|------|
| **A** Substrate-native autopoiesis | 21–25 | 81 | Self-producing rings; observer collapse; reflexive vs non-reflexive persistence. Operationalises Maturana–Varela on the discrete substrate. |
| **B** Conscious evolution | 26–29 | 88 | Symbiosis, reproduction with mutation, observer-driven selection (Lamarck-style, not blind Darwin), goal-directed observer behaviour. |
| **C** Cosmogenesis bootstrap | 30 | 21 | 13-node, 48-edge substrate constructed by a substrate-resident observer from one `MARK` at `t=0`; persists under harsh autopoietic decay (d=8, τ=5). |
| **D** Substrate-internally-driven cosmogenesis | 31 | 17 | Observer establishes its own self-loop at `t=0+` (the substrate-monist bootstrap distinction), then drives further construction via a substrate-readable halting predicate `NSUM(O) ≥ target-min` — no host counter, no programmer-chosen shell count. Closes the substrate-monism gap of Pilot C. |
| **E** Substrate-internal `Φ_PA` measurement | 32 | 12 | `stdlib/phi.6th` defines `phi-pa = OUT(O) · [O EDGE? O] · L_max` from three primitives alone. Demo 32 verifies the worked values 0 / 50000 / 130000 across non-reflexive / reflexive / demo-31-shape observers. The substrate measures itself; consciousness's structural form is substrate-readable by the same 38 primitives that build it. |
| **F** Encoding-map demonstrations | 33–36 | 46 | Toy substrates instantiating the preprint's substrate-encoding maps. F.1 (demo 33, transformer): single-pass Φ=0 (PSH1), KV-cache reuse Φ=40000 (PSH2). F.2 (demo 34, brain): waking Φ=80000 (PSH3 high), propofol Φ=0 (PSH3 low). F.3 (demo 35, split-brain): basic Φ_PA indifferent, Φ_integ halves at callosotomy (PSH4 motivates alt-measures). F.4 (demo 36, ant colony): living queen Φ=60000, dead 0 (PSH5). Real-data application is future work. |
| **(trace)** Visual-trace pilots | 37–39 | 18 | Three render pilots using Sixth's `stdlib/dot.6th` + `code/render_trace.py`. Demo 37: Pilot D evolution (5 panels, 1 node → 13 nodes / 49 edges). Demo 38: Pilot C cosmogenesis bootstrap (6 panels including post-autopoiesis state). Demo 39: split-brain intact vs callosotomy (2 panels with phi-pa indifferent / phi-integ halved). Generate all three with `make traces`. Honours the reviewer's request for visual instrumentation of substrate evolution. |

The sacred hello world is `examples/00-first-distinction.6th`: one
MARK, one boundary, one EDGE, one self-loop, one conflict, one
resolve — Spencer-Brown's first mark realised in the substrate.

Cumulative: 646 ✓ / 0 ✗ across 40 demos.

## Quickstart

```bash
# install the package and stdlib (one-time)
raco pkg install --link .

# the sacred hello world — Spencer-Brown's first mark
racket -l sixth/cli -- run examples/00-first-distinction.6th

# any of the 40 demos
racket -l sixth/cli -- run examples/35-phi-pa-split-brain-toy.6th

# run all 40 demos against the rackunit regression gate
raco test tests/examples-test.rkt
# → examples regression: 646 / 646 ✓ across 40 demos

# one-shot artifact-status (Tier-1 verification, see CLAIMS.md)
make verify
# → artifact status:  reproducible

# render all visual trace figures (Pilots C, D, F.3)
make traces
# → build/figures/{pilot_c,pilot_d,split_brain}_trace.png

# REPL
racket -l sixth/cli -- repl
```

`#lang sixth` is first-class — any Racket-aware editor (DrRacket,
racket-mode) can run `.rkt` files starting with `#lang sixth`:

```racket
#lang sixth
: factorial dup 1 > if dup 1 - factorial * else drop 1 then ;
5 factorial .   \ prints 120
```

## Repository layout

```
sixth/        engine — lexer, parser, compiler, VM,
              38 primitives (15 base + 23 substrate), module loader,
              REPL, CLI, #lang sixth reader, PyTorch FFI bridges
stdlib/       Sixth-language standard library (prelude, peano, graph,
              grid, ca, bfs, debug, phi, dot) — all helpers above the
              38 primitives live here, none of them are themselves
              primitives. phi.6th defines three candidate substrate-
              readable observability measures; dot.6th emits substrate
              snapshots as GraphViz DOT for the visual-trace pilot.
examples/     40 emergence demonstrations
              (00 hello + 01–36 + 37–39 visual traces)
code/         Python tooling. render_trace.py reads dot.6th snapshots
              from stdin and renders multi-panel matplotlib figures.
tests/        rackunit suites — lexer, parser, VM, substrate, loader,
              examples-test.rkt (regression gate at 646 ✓)
CLAIMS.md     three-tier taxonomy: Tier 1 proven by tests / Tier 2
              demonstrated by examples / Tier 3 philosophical hypothesis
              under F5. Single-command verification: `make verify`.
LANGUAGE.md   Sixth as a stand-alone Forth-like programming language,
              evaluable without engaging any cosmology / consciousness
              claim of the v9.0 preprint
docs/         Scribble manual — language reference, substrate
              foundations, stdlib word index, architecture notes,
              migration guide
legacy/       original chibi-Scheme prototype + first-pass PyTorch
              bridges, preserved unmodified as parity oracle
build/        regeneratable artefacts (raco scribble HTML, etc.) —
              gitignored
```

## Documentation

Render the Scribble manual to HTML:

```bash
make docs-html
# → open build/docs/manual.html
```

The manual covers:

- `language.scrbl` — syntax, semantics, every base primitive
- `substrate.scrbl` — the substrate's foundational mapping and the
  ontological role of each substrate primitive
- `stdlib.scrbl` — every stdlib word with stack effect
- `architecture.scrbl` — lexer / parser / compiler / VM / substrate /
  bridges module boundaries
- `migration.scrbl` — chibi-Scheme → Racket migration notes for the
  legacy prototype

## PyTorch FFI bridges

`sixth/bridges/torch/` lifts the substrate into autograd via the
native Racket FFI to libtorch (no Python in the path). Three shapes:

- `shadow.rkt`  — Substrate ⇄ Tensor mirror; lossless round-trip
- `diff.rkt`    — autograd-aware operations over substrate features
- `nn.rkt`      — Substrate-NN continual-learning architecture
                  (port of `legacy/substrate_nn_cl.py`)

Bridge tests run via `raco test tests/bridges/torch-test.rkt`; they
skip cleanly if libtorch is absent.

## Reference

Sixth is the operational substrate behind:

**Pointer Architecture v9.0** (preprint pending arXiv submission).
The paper defines `𝒮 = (G, R, C, A, π)` formally, maps it to Sixth's
38 primitives, derives the substrate-monist `Φ_PA` measure of
consciousness from Pilots A–D, and posits the substrate-monist
identity thesis as a working hypothesis under the falsifier F5.

See [`SUBSTRATE.md`](./SUBSTRATE.md) for the substrate-philosophical
mapping and literature references inherited by the v9.0 preprint
(Spencer-Brown, Maturana–Varela, Hofstadter, Rovelli, Wolfram, Friston,
Whitehead, Spinoza).

## License

MIT. See `info.rkt`.
