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
self-measurement via the substrate-monist `Φ_PA` scalar, and toy
substrates instantiating the transformer and brain encoding maps of
the v9.0 preprint — is derived in 34 demos totaling 593 assertions.

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
| **F** Encoding-map demonstrations | 33–34 | 22 | Toy substrates instantiating the preprint's substrate-encoding maps. F.1 (demo 33): 4×3 feedforward attention graph; single-pass yields Φ=0 (PSH1), KV-cache reuse adds back-edge → Φ=40000 (PSH2). F.2 (demo 34): 8-area DMN-hub graph; waking with thalamocortical loop → Φ=80000 (PSH3 high), propofol-decoupled → Φ=0 (PSH3 low). Real-checkpoint / real-EEG application is future work. |

Cumulative: 593 ✓ / 0 ✗ across 34 demos.

## Quickstart

```bash
# install the package and stdlib (one-time)
raco pkg install --link .

# run a single demo
racket -l sixth/cli -- run examples/34-phi-pa-brain-toy.6th

# run all 34 demos against the rackunit regression gate
raco test tests/examples-test.rkt
# → examples regression: 593 / 593 ✓ across 34 demos

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
              grid, ca, bfs, debug, phi) — all helpers above the 38
              primitives live here, none of them are themselves
              primitives. phi.6th defines the substrate-monist
              Φ_PA measure used by Pilot E.
examples/     34 emergence demonstrations (01–34)
tests/        rackunit suites — lexer, parser, VM, substrate, loader,
              examples-test.rkt (regression gate at 593 ✓)
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
