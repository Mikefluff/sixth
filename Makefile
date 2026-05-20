.PHONY: install test test-unit test-examples test-bridges repl docs clean legacy-parity \
        verify trace-pilot-c trace-pilot-d trace-split-brain traces \
        trace-long-epoch trace-long-epoch-gif gif-pilot-d

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
