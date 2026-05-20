.PHONY: install test test-unit test-examples test-bridges test-render repl docs clean legacy-parity \
        verify verify-figures verify-repro \
        trace-pilot-c trace-pilot-d trace-split-brain traces \
        trace-long-epoch trace-long-epoch-gif \
        trace-long-epoch-growth trace-long-epoch-growth-gif \
        trace-conway-blinker gif-conway-blinker \
        trace-conway-glider gif-conway-glider \
        trace-rule110 gif-rule110 \
        trace-rule90 gif-rule90 \
        trace-glider-1d gif-glider-1d \
        trace-atomic-pilot-d gif-atomic-pilot-d \
        trace-atomic-hello gif-atomic-hello \
        atomic-gifs \
        forensic-pilot-d forensic-pilot-c forensic-split-brain \
        forensic-conway-blinker forensic-conway-glider \
        forensic-rule110 forensic-rule90 forensic-glider-1d \
        forensic-atomic-pilot-d forensic-atomic-hello \
        forensic-long-epoch-growth forensic-pa-ontological-shell forensic-all \
        trace-pa-ontological-shell gif-pa-ontological-shell \
        foundation-gifs all-figures \
        gif-pilot-c gif-pilot-d gif-split-brain gifs

install:
	raco pkg install --link --auto .

test: test-unit test-examples

test-unit:
	raco test sixth tests

test-examples:
	raco test tests/examples-test.rkt

test-bridges:
	raco test tests/bridges/torch-test.rkt

repl:
	racket -l sixth/cli -- repl

docs:
	raco docs sixth

docs-html:
	raco scribble --html --dest build/docs docs/manual.scrbl
	@echo "→ open build/docs/manual.html"

docs-pdf:
	raco scribble --pdf --dest build/docs docs/manual.scrbl

trace-pilot-d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/37-trace-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_d_trace.png \
	      --title "Pilot D — substrate-internally-driven cosmogenesis"
	@echo "→ open build/figures/pilot_d_trace.png"

trace-pilot-c:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/38-trace-pilot-c.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_c_trace.png \
	      --title "Pilot C — cosmogenesis bootstrap"
	@echo "→ open build/figures/pilot_c_trace.png"

trace-split-brain:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/39-trace-split-brain.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/split_brain_trace.png \
	      --title "Pilot F.3 — split-brain: intact vs callosotomy"
	@echo "→ open build/figures/split_brain_trace.png"

traces: trace-pilot-c trace-pilot-d trace-split-brain
	@echo "→ all visual traces rendered to build/figures/"

# Long-epoch parametric run with snapshot every K cycles, static PNG.
# Override CYCLES / SNAP / OUT on the command line, e.g.:
#   make trace-long-epoch CYCLES=2000 SNAP=200
CYCLES ?= 500
SNAP   ?= 50

trace-long-epoch:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES) -D snap-every=$(SNAP) \
	  run examples/40-long-epoch-autopoiesis.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_$(CYCLES).png \
	      --title "Long-epoch autopoiesis — $(CYCLES) cycles, snap every $(SNAP)"
	@echo "→ open build/figures/long_epoch_$(CYCLES).png"

# Same long-epoch run rendered as animated GIF.  Useful for many-snapshot
# runs where a static grid would be unreadable.
trace-long-epoch-gif:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES) -D snap-every=$(SNAP) \
	  run examples/40-long-epoch-autopoiesis.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_$(CYCLES).gif --fps 4 \
	      --title "Long-epoch autopoiesis — $(CYCLES) cycles"
	@echo "→ open build/figures/long_epoch_$(CYCLES).gif"

# Pilot D substrate growth as animated GIF (alternative to the static figure).
gif-pilot-d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/37-trace-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_d_trace.gif --fps 2 \
	      --title "Pilot D — substrate-internally-driven cosmogenesis"
	@echo "→ open build/figures/pilot_d_trace.gif"

gif-pilot-c:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/38-trace-pilot-c.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_c_trace.gif --fps 2 \
	      --title "Pilot C — cosmogenesis bootstrap"
	@echo "→ open build/figures/pilot_c_trace.gif"

gif-split-brain:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/39-trace-split-brain.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/split_brain_trace.gif --fps 1 \
	      --title "Pilot F.3 — split-brain: intact vs callosotomy"
	@echo "→ open build/figures/split_brain_trace.gif"

gifs: gif-pilot-c gif-pilot-d gif-split-brain \
      gif-conway-blinker gif-conway-glider \
      gif-rule110 gif-rule90 gif-glider-1d \
      trace-long-epoch-growth-gif
	@echo "→ all visual-trace GIFs rendered to build/figures/"

# Conway's Game of Life blinker on 5×5 grid — substrate state changes
# cycle-by-cycle (alive/dead colouring honours dot-snapshot-state).
trace-conway-blinker:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/42-trace-conway-blinker.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_blinker.png \
	      --title "Conway's Game of Life — blinker on 5×5 substrate grid"
	@echo "→ open build/figures/conway_blinker.png"

gif-conway-blinker:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/42-trace-conway-blinker.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_blinker.gif --fps 2 \
	      --title "Conway's Game of Life — blinker on 5×5 substrate grid"
	@echo "→ open build/figures/conway_blinker.gif"

# Conway 5-cell glider (translates +1, +1 over 4 steps).
trace-conway-glider:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/43-trace-conway-glider.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_glider.png \
	      --title "Conway's Game of Life — 5-cell glider, 4 STEP-CA cycles"
	@echo "→ open build/figures/conway_glider.png"

gif-conway-glider:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/43-trace-conway-glider.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_glider.gif --fps 2 \
	      --title "Conway's Game of Life — 5-cell glider translating across 5×5"
	@echo "→ open build/figures/conway_glider.gif"

# Wolfram Rule 110 — universal CA, single-seed propagation.
trace-rule110:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/44-trace-rule110.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule110.png \
	      --title "Wolfram Rule 110 — 11-cell chain, 8 STEP-CA cycles"
	@echo "→ open build/figures/rule110.png"

gif-rule110:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/44-trace-rule110.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule110.gif --fps 2 \
	      --title "Wolfram Rule 110 — single-seed propagation (universal CA)"
	@echo "→ open build/figures/rule110.gif"

# Wolfram Rule 90 — Sierpinski-like fractal from single seed.
trace-rule90:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/45-trace-rule90.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule90.png \
	      --title "Wolfram Rule 90 — Sierpinski-like fractal, 8 STEP-CA cycles"
	@echo "→ open build/figures/rule90.png"

gif-rule90:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/45-trace-rule90.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule90.gif --fps 2 \
	      --title "Wolfram Rule 90 — Sierpinski fractal from a single seed"
	@echo "→ open build/figures/rule90.gif"

# Rule 184 1D glider ("car").
trace-glider-1d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/46-trace-glider-1d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/glider_1d.png \
	      --title "Rule 184 1D glider — 5 STEP-CA cycles, car advances c3 → c7"
	@echo "→ open build/figures/glider_1d.png"

gif-glider-1d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/46-trace-glider-1d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/glider_1d.gif --fps 2 \
	      --title "Rule 184 1D glider — substrate-level momentum"
	@echo "→ open build/figures/glider_1d.gif"

foundation-gifs: gif-conway-blinker gif-conway-glider gif-rule110 \
                 gif-rule90 gif-glider-1d
	@echo "→ all foundation visual-trace GIFs rendered to build/figures/"

# Atomic-build trace — one snapshot per primitive operation.  Same
# Pilot D substrate as demo 37 but shown entity-by-entity instead of
# shell-by-shell.  ~76 frames.
trace-atomic-pilot-d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/47-trace-atomic-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_pilot_d.png \
	      --title "Pilot D atomic build — one primitive per panel"
	@echo "→ open build/figures/atomic_pilot_d.png"

gif-atomic-pilot-d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/47-trace-atomic-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_pilot_d.gif --fps 6 \
	      --title "Pilot D — atomic build, one primitive per frame"
	@echo "→ open build/figures/atomic_pilot_d.gif"

# Sacred hello world, atomic — the substrate's ontological core in
# seven frames.  Render slowly (1 fps) so each substrate-state delta
# is unmissable.
trace-atomic-hello:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/48-trace-atomic-hello.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_hello.png \
	      --title "Sacred hello world — atomic, one primitive per panel"
	@echo "→ open build/figures/atomic_hello.png"

gif-atomic-hello:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/48-trace-atomic-hello.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_hello.gif --fps 1 \
	      --title "Sacred hello world — six moments + the measurement"
	@echo "→ open build/figures/atomic_hello.gif"

atomic-gifs: gif-atomic-hello gif-atomic-pilot-d
	@echo "→ atomic-build GIFs rendered to build/figures/"

# PA-ontological shell trace — first shell of Pilot D unfolded as
# Spencer-Brown / PA v9.0 events (first-distinction, re-entry,
# i-not-i, first-pointer, recognition, closure-of-not-i,
# shell-formation).  Demo 49.
trace-pa-ontological-shell:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/49-trace-pa-ontological-shell.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pa_ontological_shell.png \
	      --title "PA-ontological shell — first shell of Pilot D unfolded"
	@echo "→ open build/figures/pa_ontological_shell.png"

gif-pa-ontological-shell:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/49-trace-pa-ontological-shell.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pa_ontological_shell.gif --fps 1 \
	      --title "PA-ontological shell — Spencer-Brown bootstrap, frame by frame"
	@echo "→ open build/figures/pa_ontological_shell.gif"

# Forensic trace — image + JSONL evidence + per-step diff view.
# Produces three artefacts per pilot so an external reviewer can
# audit the substrate execution from machine-readable logs, not
# only the rendered figure.  Backed by scripts/forensic.sh.
forensic-pilot-d:
	@bash scripts/forensic.sh examples/37-trace-pilot-d.6th pilot_d "Pilot D"

forensic-pilot-c:
	@bash scripts/forensic.sh examples/38-trace-pilot-c.6th pilot_c "Pilot C"

forensic-split-brain:
	@bash scripts/forensic.sh examples/39-trace-split-brain.6th split_brain "Pilot F.3 split-brain"

forensic-conway-blinker:
	@bash scripts/forensic.sh examples/42-trace-conway-blinker.6th conway_blinker_f "Conway blinker"

forensic-conway-glider:
	@bash scripts/forensic.sh examples/43-trace-conway-glider.6th conway_glider_f "Conway glider"

forensic-rule110:
	@bash scripts/forensic.sh examples/44-trace-rule110.6th rule110_f "Wolfram Rule 110"

forensic-rule90:
	@bash scripts/forensic.sh examples/45-trace-rule90.6th rule90_f "Wolfram Rule 90"

forensic-glider-1d:
	@bash scripts/forensic.sh examples/46-trace-glider-1d.6th glider_1d_f "Rule 184 1D glider"

forensic-atomic-pilot-d:
	@bash scripts/forensic.sh examples/47-trace-atomic-pilot-d.6th atomic_pilot_d_f "Pilot D atomic"

forensic-atomic-hello:
	@bash scripts/forensic.sh examples/48-trace-atomic-hello.6th atomic_hello_f "Sacred hello atomic"

forensic-long-epoch-growth:
	@bash scripts/forensic.sh examples/41-long-epoch-growth.6th long_epoch_growth_f "Long-epoch growth"

forensic-pa-ontological-shell:
	@bash scripts/forensic.sh examples/49-trace-pa-ontological-shell.6th pa_ontological_shell_f "PA-ontological shell"

forensic-all: forensic-pilot-d forensic-pilot-c forensic-split-brain \
              forensic-conway-blinker forensic-conway-glider \
              forensic-rule110 forensic-rule90 forensic-glider-1d \
              forensic-atomic-pilot-d forensic-atomic-hello \
              forensic-long-epoch-growth forensic-pa-ontological-shell
	@echo "→ all 12 forensic traces rendered (PNG + JSONL + diff per demo)"

# Visibly growing substrate over a long epoch (demo 41 — shell added
# every GROW cycles; structure changes across frames).
CYCLES_G ?= 100
SNAP_G   ?= 10
GROW     ?= 20

trace-long-epoch-growth:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES_G) -D snap-every=$(SNAP_G) \
	                     -D grow-every=$(GROW) \
	  run examples/41-long-epoch-growth.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_growth.png \
	      --title "Long-epoch growth — $(CYCLES_G) cycles, +shell every $(GROW)"
	@echo "→ open build/figures/long_epoch_growth.png"

trace-long-epoch-growth-gif:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES_G) -D snap-every=$(SNAP_G) \
	                     -D grow-every=$(GROW) \
	  run examples/41-long-epoch-growth.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_growth.gif --fps 3 \
	      --title "Long-epoch growth — $(CYCLES_G) cycles, +shell every $(GROW)"
	@echo "→ open build/figures/long_epoch_growth.gif"

verify:
	@bash scripts/verify.sh

# Python renderer unit tests — guard the panel-title / JSONL /
# delta-annotation logic that the forensic trace pipeline depends on.
test-render:
	@python3 tests/render-test.py

# Stronger reproducibility check — run each forensic demo twice,
# hash the JSONL outputs, assert byte-identical.  Substrate is fully
# deterministic, so any drift here is a host-side bug.  Not part of
# default `verify` (adds ~30s); separate target for paper-level claims.
verify-repro:
	@bash scripts/verify_repro.sh

# Verify that committed figures match what the .6th demos produce now.
# Re-runs every forensic-grade demo, regenerates its JSONL, and diffs
# against the committed copy under docs/figures/.  JSONL is deterministic
# (text, sorted keys); PNG/GIF carry matplotlib timestamps and are
# intentionally excluded.  Single non-zero exit on drift.
verify-figures:
	@bash scripts/verify_figures.sh

# Render every figure the repository ships — static PNGs, animated GIFs,
# forensic PNG + JSONL + diff for all 11 trace-grade demos.  Idempotent;
# safe to re-run.  Output under build/figures/.
all-figures: traces gifs foundation-gifs atomic-gifs forensic-all \
             trace-conway-blinker trace-conway-glider \
             trace-rule110 trace-rule90 trace-glider-1d \
             trace-atomic-pilot-d trace-atomic-hello \
             trace-long-epoch-growth \
             trace-long-epoch trace-long-epoch-gif
	@echo "→ all figures rendered to build/figures/"

examples-all:
	@for f in examples/*.6th; do \
	  echo "=== $$f ==="; \
	  racket -l sixth/cli -- run "$$f" | tail -1; \
	done

clean:
	find . -name compiled -type d -prune -exec rm -rf {} +

legacy-parity:
	@echo "Running legacy chibi-Scheme demos as parity baseline..."
	cd legacy && echo 'loadfile demo-all.6th\nquit' | chibi-scheme sixth-substrate.scm | grep "REPORT" | tail -1
