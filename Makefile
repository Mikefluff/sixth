.PHONY: install test test-unit test-examples test-bridges repl docs clean legacy-parity \
        verify trace-pilot-c trace-pilot-d trace-split-brain traces \
        trace-long-epoch trace-long-epoch-gif \
        trace-long-epoch-growth trace-long-epoch-growth-gif \
        trace-conway-blinker gif-conway-blinker \
        trace-conway-glider gif-conway-glider \
        trace-rule110 gif-rule110 \
        trace-rule90 gif-rule90 \
        trace-glider-1d gif-glider-1d \
        trace-atomic-pilot-d gif-atomic-pilot-d \
        trace-atomic-hello gif-atomic-hello \
        atomic-gifs forensic-pilot-d \
        foundation-gifs \
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

# Forensic trace — image + JSONL evidence + per-step diff view.
# Produces three artefacts per pilot so an external reviewer can
# audit the substrate execution from machine-readable logs, not
# only the rendered figure.  Demo 37 (Pilot D) is the showcase.
forensic-pilot-d:
	@mkdir -p build/figures
	@racket -l sixth/cli -- run examples/37-trace-pilot-d.6th > build/figures/pilot_d_trace.dot
	python3 code/render_trace.py build/figures/pilot_d_trace.dot \
	    --out build/figures/pilot_d_forensic.png \
	    --jsonl build/figures/pilot_d_forensic.jsonl \
	    --title "Pilot D — forensic trace"
	python3 code/render_trace.py build/figures/pilot_d_trace.dot \
	    --out build/figures/pilot_d_diff.png --diff \
	    --title "Pilot D"
	@echo "→ build/figures/pilot_d_forensic.png  (snapshots + deltas)"
	@echo "→ build/figures/pilot_d_forensic.jsonl (machine-readable trace)"
	@echo "→ build/figures/pilot_d_diff.png      (per-step DIFF view)"

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
