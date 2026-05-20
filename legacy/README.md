# Legacy — chibi-Scheme reference implementation (frozen)

The contents of this directory are the **original prototype** of the
Sixth substrate.  They are preserved unmodified as a historical
reference and as a parity oracle for the refactored Racket-hosted
language (in the parent `sixth/` collection).

**Do not modify files in this directory.**  The new implementation
lives in `../sixth/`, `../stdlib/`, and `../examples/`.

## Contents

- `sixth.scm` — original 15-primitive base interpreter.
- `sixth-substrate.scm` — extended engine with 23 substrate primitives.
- `sixth-debug.scm` — debug-instrumented variant (unused in main flow).
- `core.6th`, `data.6th`, `objects.6th`, `rules.6th`, `meta.6th`,
  `substrate.6th` — original user-side Sixth libraries.
- `demo-*.6th` — 20 emergence proof demonstrations.
- `demo-all.6th` — aggregator.
- `substrate_torch.py`, `substrate_torch_diff.py`, `substrate_nn_cl.py`
  — Python PyTorch bridges (foundational substrate ↔ neural network).
- `README-original.md`, `TECHNICAL.md`, `QUICKSTART.md`, `EXAMPLES.md`,
  `CHANGELOG.md`, `Makefile` — original documentation (renamed to avoid
  conflict with this `README.md`).
- `examples-old/` — earlier examples folder (Conway's Life experiments,
  level2-core, etc.).

## Running the legacy implementation

The chibi-Scheme implementation still runs:

```bash
cd /Users/mikefluff/Documents/Programming/sixt/legacy
echo 'loadfile demo-all.6th
quit' | chibi-scheme sixth-substrate.scm
```

Expected cumulative: 320+ assertions pass across the 20 demos
(latest run: 353 with `demo-glider-2d.6th` included).

## Refactor parity

The Racket-hosted refactor in `../sixth/` must reproduce all assertions
from the demos.  See `../tests/examples-test.rkt` for the regression gate
once Phase F lands.
