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
        forensic-pilot-e forensic-pilot-f1 forensic-pilot-f2 forensic-pilot-f4 \
        trace-pa-ontological-shell gif-pa-ontological-shell \
        trace-pilot-e trace-pilot-f1 trace-pilot-f2 trace-pilot-f4 \
        trace-composite-distinction forensic-composite-distinction \
        trace-mutation-selection forensic-mutation-selection \
        trace-particle-families forensic-particle-families \
        trace-charge-conservation forensic-charge-conservation \
        trace-spontaneous-assembly forensic-spontaneous-assembly \
        trace-particle-interaction forensic-particle-interaction \
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
	racket -l sixth/cli -- run examples/55-trace-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_d_trace.png \
	      --title "Pilot D — substrate-internally-driven cosmogenesis"
	@echo "→ open build/figures/pilot_d_trace.png"

trace-pilot-c:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/56-trace-pilot-c.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_c_trace.png \
	      --title "Pilot C — cosmogenesis bootstrap"
	@echo "→ open build/figures/pilot_c_trace.png"

trace-split-brain:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/57-trace-split-brain.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/split_brain_trace.png \
	      --title "Pilot F.3 — split-brain: intact vs callosotomy"
	@echo "→ open build/figures/split_brain_trace.png"

traces: trace-pilot-c trace-pilot-d trace-split-brain
	@echo "→ all visual traces rendered to build/figures/"

# Long-epoch parametric run with snapshot every K cycles, static PNG.
# Override CYCLES / SNAP on the command line, e.g.:
#   make trace-long-epoch CYCLES=2000 SNAP=200
#
# Default SNAP is chosen sparse on purpose: demo 40 emits TWO sub-cycle
# snapshots per snap moment (after-phase-decay + after-phase-restore),
# so SNAP=K with CYCLES=N produces 1 + 2·(N/K) frames.  CYCLES=200
# SNAP=100 → 5 frames (initial, decay@100, restore@100, decay@200,
# restore@200) — enough to show the dance + persistence without
# repeating an identical pair 10 times.
CYCLES ?= 200
SNAP   ?= 100

trace-long-epoch:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES) -D snap-every=$(SNAP) \
	  run examples/53-long-epoch-autopoiesis.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_$(CYCLES).png \
	      --title "Long-epoch autopoiesis — $(CYCLES) cycles, snap every $(SNAP)"
	@echo "→ open build/figures/long_epoch_$(CYCLES).png"

# Same long-epoch run rendered as animated GIF.  Useful for many-snapshot
# runs where a static grid would be unreadable.
trace-long-epoch-gif:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES) -D snap-every=$(SNAP) \
	  run examples/53-long-epoch-autopoiesis.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_$(CYCLES).gif --fps 4 \
	      --title "Long-epoch autopoiesis — $(CYCLES) cycles"
	@echo "→ open build/figures/long_epoch_$(CYCLES).gif"

# Pilot D substrate growth as animated GIF (alternative to the static figure).
gif-pilot-d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/55-trace-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_d_trace.gif --fps 2 \
	      --title "Pilot D — substrate-internally-driven cosmogenesis"
	@echo "→ open build/figures/pilot_d_trace.gif"

gif-pilot-c:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/56-trace-pilot-c.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_c_trace.gif --fps 2 \
	      --title "Pilot C — cosmogenesis bootstrap"
	@echo "→ open build/figures/pilot_c_trace.gif"

gif-split-brain:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/57-trace-split-brain.6th \
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
	racket -l sixth/cli -- run examples/58-trace-conway-blinker.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_blinker.png \
	      --title "Conway's Game of Life — blinker on 5×5 substrate grid"
	@echo "→ open build/figures/conway_blinker.png"

gif-conway-blinker:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/58-trace-conway-blinker.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_blinker.gif --fps 2 \
	      --title "Conway's Game of Life — blinker on 5×5 substrate grid"
	@echo "→ open build/figures/conway_blinker.gif"

# Conway 5-cell glider (translates +1, +1 over 4 steps).
trace-conway-glider:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/59-trace-conway-glider.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_glider.png \
	      --title "Conway's Game of Life — 5-cell glider, 4 STEP-CA cycles"
	@echo "→ open build/figures/conway_glider.png"

gif-conway-glider:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/59-trace-conway-glider.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/conway_glider.gif --fps 2 \
	      --title "Conway's Game of Life — 5-cell glider translating across 5×5"
	@echo "→ open build/figures/conway_glider.gif"

# Wolfram Rule 110 — universal CA, single-seed propagation.
trace-rule110:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/60-trace-rule110.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule110.png \
	      --title "Wolfram Rule 110 — 11-cell chain, 8 STEP-CA cycles"
	@echo "→ open build/figures/rule110.png"

gif-rule110:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/60-trace-rule110.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule110.gif --fps 2 \
	      --title "Wolfram Rule 110 — single-seed propagation (universal CA)"
	@echo "→ open build/figures/rule110.gif"

# Wolfram Rule 90 — Sierpinski-like fractal from single seed.
trace-rule90:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/61-trace-rule90.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule90.png \
	      --title "Wolfram Rule 90 — Sierpinski-like fractal, 8 STEP-CA cycles"
	@echo "→ open build/figures/rule90.png"

gif-rule90:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/61-trace-rule90.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/rule90.gif --fps 2 \
	      --title "Wolfram Rule 90 — Sierpinski fractal from a single seed"
	@echo "→ open build/figures/rule90.gif"

# Rule 184 1D glider ("car").
trace-glider-1d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/62-trace-glider-1d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/glider_1d.png \
	      --title "Rule 184 1D glider — 5 STEP-CA cycles, car advances c3 → c7"
	@echo "→ open build/figures/glider_1d.png"

gif-glider-1d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/62-trace-glider-1d.6th \
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
	racket -l sixth/cli -- run examples/63-trace-atomic-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_pilot_d.png \
	      --title "Pilot D atomic build — one primitive per panel"
	@echo "→ open build/figures/atomic_pilot_d.png"

gif-atomic-pilot-d:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/63-trace-atomic-pilot-d.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_pilot_d.gif --fps 6 \
	      --title "Pilot D — atomic build, one primitive per frame"
	@echo "→ open build/figures/atomic_pilot_d.gif"

# Sacred hello world, atomic — the substrate's ontological core in
# seven frames.  Render slowly (1 fps) so each substrate-state delta
# is unmissable.
trace-atomic-hello:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/64-trace-atomic-hello.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/atomic_hello.png \
	      --title "Sacred hello world — atomic, one primitive per panel"
	@echo "→ open build/figures/atomic_hello.png"

gif-atomic-hello:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/64-trace-atomic-hello.6th \
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
	racket -l sixth/cli -- run examples/65-trace-pa-ontological-shell.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pa_ontological_shell.png \
	      --title "PA-ontological shell — first shell of Pilot D unfolded"
	@echo "→ open build/figures/pa_ontological_shell.png"

gif-pa-ontological-shell:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/65-trace-pa-ontological-shell.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pa_ontological_shell.gif --fps 1 \
	      --title "PA-ontological shell — Spencer-Brown bootstrap, frame by frame"
	@echo "→ open build/figures/pa_ontological_shell.gif"

# Pilot E — substrate-internal Phi_PA measurement (3 observers).
trace-pilot-e:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/66-trace-pilot-e-phi-pa.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_e_trace.png \
	      --title "Pilot E — substrate-internal Φ_PA measurement (3 observers)"
	@echo "→ open build/figures/pilot_e_trace.png"

# Pilot F.1 transformer encoding (PSH1 vs PSH2).
trace-pilot-f1:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/67-trace-pilot-f1-transformer.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_f1_trace.png \
	      --title "Pilot F.1 — transformer encoding (PSH1 single-pass vs PSH2 KV-cache)"
	@echo "→ open build/figures/pilot_f1_trace.png"

# Pilot F.2 brain encoding (PSH3 waking vs propofol).
trace-pilot-f2:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/68-trace-pilot-f2-brain.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_f2_trace.png \
	      --title "Pilot F.2 — brain encoding (PSH3 waking thalamocortical vs propofol)"
	@echo "→ open build/figures/pilot_f2_trace.png"

# Pilot F.4 ant-colony encoding (PSH5 living vs dead).
trace-pilot-f4:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/69-trace-pilot-f4-colony.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/pilot_f4_trace.png \
	      --title "Pilot F.4 — ant colony encoding (PSH5 living queen vs dead colony)"
	@echo "→ open build/figures/pilot_f4_trace.png"

# Pilot G — composite distinction via meta-self-loop (demo 55).
# Three first-order observers + meta-observer M; M's self-loop flips
# phi-pa(M) from 0 to 40000, constituting the composite distinction.
trace-composite-distinction:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/70-trace-composite-distinction.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/composite_distinction.png \
	      --title "Pilot G — composite distinction held by meta-self-loop" \
	      --layout tiered
	@echo "→ open build/figures/composite_distinction.png"

forensic-composite-distinction:
	@bash scripts/forensic.sh examples/70-trace-composite-distinction.6th composite_distinction "Pilot G composite distinction" tiered

# Pilot H — mutation + substrate-readable selection (demo 57).
# Five variants mutated; meta-observer M selects on phi-pa>0;
# diversified composite of three structurally distinct survivors.
trace-mutation-selection:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/71-trace-mutation-selection.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/mutation_selection.png \
	      --title "Pilot H — mutation + substrate-readable selection (particle zoo)" \
	      --layout tiered
	@echo "→ open build/figures/mutation_selection.png"

forensic-mutation-selection:
	@bash scripts/forensic.sh examples/71-trace-mutation-selection.6th mutation_selection "Pilot H mutation+selection" tiered

# Pilot I — multi-level particle hierarchy (demo 59).
# Six instances → three family observers → one genus observer,
# each level held by composite-distinction (Pilot G mechanism
# iterated three times).
trace-particle-families:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/72-trace-particle-families.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/particle_families.png \
	      --title "Pilot I — multi-level particle hierarchy (instances / families / genus)" \
	      --layout tiered
	@echo "→ open build/figures/particle_families.png"

forensic-particle-families:
	@bash scripts/forensic.sh examples/72-trace-particle-families.6th particle_families "Pilot I particle hierarchy" tiered

# Pilot J — substrate-native charge conservation (demo 61).
# 11-cell chain, 5 particles, STEP-CA charge-shift rule preserves
# total Σ NGET and per-species count exactly across all steps.
trace-charge-conservation:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/73-trace-charge-conservation.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/charge_conservation.png \
	      --title "Pilot J — substrate-native charge conservation (Σ NGET invariant under STEP-CA)" \
	      --layout chain
	@echo "→ open build/figures/charge_conservation.png"

forensic-charge-conservation:
	@bash scripts/forensic.sh examples/73-trace-charge-conservation.6th charge_conservation "Pilot J charge conservation" chain

# Pilot K — spontaneous coalition assembly (demo 63).
# Three-level hierarchy emerges entirely by repeated application of
# the substrate-readable try-spawn-coalition rule (no hand-placed
# meta-observers).
trace-spontaneous-assembly:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/74-trace-spontaneous-assembly.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/spontaneous_assembly.png \
	      --title "Pilot K — spontaneous coalition assembly (3-level hierarchy emerges from a single substrate-readable rule)" \
	      --layout tiered
	@echo "→ open build/figures/spontaneous_assembly.png"

forensic-spontaneous-assembly:
	@bash scripts/forensic.sh examples/74-trace-spontaneous-assembly.6th spontaneous_assembly "Pilot K spontaneous assembly" tiered

# Pilot L — particle interaction (bound-state formation, demo 76).
# Two structurally different particles bind via mutual bi-edge +
# composite meta-observer.  Σ NGET over particles preserved.
trace-particle-interaction:
	@mkdir -p build/figures
	racket -l sixth/cli -- run examples/76-trace-particle-interaction.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/particle_interaction.png \
	      --title "Pilot L — particle interaction (bound-state formation: α + β → α↔β + composite M)" \
	      --layout tiered
	@echo "→ open build/figures/particle_interaction.png"

forensic-particle-interaction:
	@bash scripts/forensic.sh examples/76-trace-particle-interaction.6th particle_interaction "Pilot L particle interaction" tiered

forensic-pilot-e:
	@bash scripts/forensic.sh examples/66-trace-pilot-e-phi-pa.6th pilot_e "Pilot E"

forensic-pilot-f1:
	@bash scripts/forensic.sh examples/67-trace-pilot-f1-transformer.6th pilot_f1 "Pilot F.1 transformer"

forensic-pilot-f2:
	@bash scripts/forensic.sh examples/68-trace-pilot-f2-brain.6th pilot_f2 "Pilot F.2 brain"

forensic-pilot-f4:
	@bash scripts/forensic.sh examples/69-trace-pilot-f4-colony.6th pilot_f4 "Pilot F.4 colony"

# Forensic trace — image + JSONL evidence + per-step diff view.
# Produces three artefacts per pilot so an external reviewer can
# audit the substrate execution from machine-readable logs, not
# only the rendered figure.  Backed by scripts/forensic.sh.
forensic-pilot-d:
	@bash scripts/forensic.sh examples/55-trace-pilot-d.6th pilot_d "Pilot D"

forensic-pilot-c:
	@bash scripts/forensic.sh examples/56-trace-pilot-c.6th pilot_c "Pilot C"

forensic-split-brain:
	@bash scripts/forensic.sh examples/57-trace-split-brain.6th split_brain "Pilot F.3 split-brain"

forensic-conway-blinker:
	@bash scripts/forensic.sh examples/58-trace-conway-blinker.6th conway_blinker_f "Conway blinker"

forensic-conway-glider:
	@bash scripts/forensic.sh examples/59-trace-conway-glider.6th conway_glider_f "Conway glider"

forensic-rule110:
	@bash scripts/forensic.sh examples/60-trace-rule110.6th rule110_f "Wolfram Rule 110"

forensic-rule90:
	@bash scripts/forensic.sh examples/61-trace-rule90.6th rule90_f "Wolfram Rule 90"

forensic-glider-1d:
	@bash scripts/forensic.sh examples/62-trace-glider-1d.6th glider_1d_f "Rule 184 1D glider"

forensic-atomic-pilot-d:
	@bash scripts/forensic.sh examples/63-trace-atomic-pilot-d.6th atomic_pilot_d_f "Pilot D atomic"

forensic-atomic-hello:
	@bash scripts/forensic.sh examples/64-trace-atomic-hello.6th atomic_hello_f "Sacred hello atomic"

forensic-long-epoch-growth:
	@bash scripts/forensic.sh examples/54-long-epoch-growth.6th long_epoch_growth_f "Long-epoch growth"

forensic-pa-ontological-shell:
	@bash scripts/forensic.sh examples/65-trace-pa-ontological-shell.6th pa_ontological_shell_f "PA-ontological shell"

forensic-all: forensic-pilot-d forensic-pilot-c forensic-split-brain \
              forensic-conway-blinker forensic-conway-glider \
              forensic-rule110 forensic-rule90 forensic-glider-1d \
              forensic-atomic-pilot-d forensic-atomic-hello \
              forensic-long-epoch-growth forensic-pa-ontological-shell \
              forensic-pilot-e forensic-pilot-f1 \
              forensic-pilot-f2 forensic-pilot-f4 \
              forensic-composite-distinction \
              forensic-mutation-selection \
              forensic-particle-families \
              forensic-charge-conservation \
              forensic-spontaneous-assembly \
              forensic-particle-interaction
	@echo "→ all 22 forensic traces rendered (PNG + JSONL + diff per demo)"

# Visibly growing substrate over a long epoch (demo 41 — shell added
# every GROW cycles; structure changes across frames).
CYCLES_G ?= 100
SNAP_G   ?= 10
GROW     ?= 20

trace-long-epoch-growth:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES_G) -D snap-every=$(SNAP_G) \
	                     -D grow-every=$(GROW) \
	  run examples/54-long-epoch-growth.6th \
	  | python3 code/render_trace.py \
	      --out build/figures/long_epoch_growth.png \
	      --title "Long-epoch growth — $(CYCLES_G) cycles, +shell every $(GROW)"
	@echo "→ open build/figures/long_epoch_growth.png"

trace-long-epoch-growth-gif:
	@mkdir -p build/figures
	racket -l sixth/cli -- -D max-cycles=$(CYCLES_G) -D snap-every=$(SNAP_G) \
	                     -D grow-every=$(GROW) \
	  run examples/54-long-epoch-growth.6th \
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
# forensic PNG + JSONL + diff for all 16 trace-grade demos.  Idempotent;
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
