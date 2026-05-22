# Companion #1 — Pythia Φ_PA Validation

Companion to the Sixth substrate research-track program.  Tests
whether substrate-readable Φ-family measures (`phi-pa`, `phi-perc`,
`phi-integ`, `phi-bidir`, `phi-pa-witness`) correlate with known
behavioural metrics on real transformer-attention substrates.

**Status: SCAFFOLD ONLY — not yet executed.**  Deadline (per
RESULTS.md / CLAIMS.md F5.1 datestamp): **2027-06-30**.  If by that
date no positive correlation `r > 0.3` is found across ≥3 metrics
on Pythia attention substrate, F5.1 fires (substrate-monism
encoding-map programme falsified for Pythia case).

## What this companion does

For Pythia models (1.4B, 6.9B, possibly larger via API):
1. **Extract** attention patterns on a standardized prompt set
   (LAMBADA, MMLU subset, simple completion tasks)
2. **Encode** each (layer, head, prompt) attention matrix as a
   Sixth substrate (attention head ⇒ node, attention weight ⇒
   edge with NSET feature)
3. **Compute** Φ-family measures per encoded substrate
4. **Correlate** Φ-family values with known model metrics:
   - capability score (task accuracy)
   - calibration (probability ranking)
   - activation-patching sensitivity
   - layer-wise representational quality (LM-Eval)
5. **Predict** Φ-family on Pythia 6.9B BEFORE measurement; test
   prediction on actual measurement

## Why this is the «killer move» for substrate-monism

Toy-substrate demos (105–123) all use author-built substrates;
encoding-map circularity dominates evidence.  Real-data validation
on Pythia BREAKS the circularity: Pythia was not designed for Φ_PA
to fire.  If Φ-family captures something real about transformer
behaviour, this is non-trivial evidence; if not, F5.1 fires
honestly.

## Pre-flight checklist (BEFORE running)

- [ ] Sixth substrate engine + stats stdlib stable (DONE: cycle 6)
- [ ] phi-perc read-only verified (DONE: cycle 3, fixed cycle 7)
- [ ] Ensemble framework verified (DONE: demos 121, 122)
- [ ] Theory-driven prediction discipline established (DONE:
      demo 123 first valid predict-then-measure cycle)
- [ ] Pythia 1.4B accessible (Hugging Face hub + GPU access)
- [ ] Encoding scheme designed and unit-tested (DESIGN.md)
- [ ] Correlation methodology pre-registered (CORRELATION-PLAN.md)
- [ ] Predictions for 6.9B written BEFORE measuring (PREDICTIONS.md)

## Files (planned)

| File | Purpose | Status |
|------|---------|--------|
| `README.md` | This file | DONE |
| `DESIGN.md` | Encoding scheme + Φ-family adaptation to attention | TODO |
| `CORRELATION-PLAN.md` | Pre-registered metric correlations | TODO |
| `PREDICTIONS.md` | Pre-registered predictions for Pythia 6.9B | TODO |
| `requirements.txt` | Python deps (transformers, torch, datasets, scipy) | TODO |
| `extract.py` | Extract attention patterns from Pythia | STUB |
| `encode.py` | Convert attention → Sixth substrate `.6th` files | TODO |
| `measure.py` | Run Sixth on each encoded substrate, harvest Φ values | TODO |
| `correlate.py` | Statistical correlation of Φ vs behavioural metrics | TODO |
| `run.sh` | Orchestrate the full pipeline | TODO |

## Methodological commitments

1. **Pre-register** predictions and metrics BEFORE measurement
   (PREDICTIONS.md + CORRELATION-PLAN.md committed to git first).
2. **Multi-seed ensembles** where applicable (Pythia inference
   may not have stochastic variation if temperature=0; but prompt
   sampling does).
3. **Multi-model scale**: 1.4B + 6.9B + ideally a third scale,
   to test theory-extensivity prediction across scales.
4. **Honest reporting**: include negative results.  If no
   correlation found, F5.1 fires.  Document the firing.
5. **Methodological transparency**: all encoding choices, threshold
   parameters, correlation metrics decided BEFORE seeing data.
   Post-hoc revision flagged explicitly.

## Compute budget (rough)

- Pythia 1.4B inference on 1000 prompts × forward-pass with
  attention extraction: ~30 minutes on V100/A100
- Sixth substrate Φ-family computation on per-prompt substrates
  (n ≈ 100-200 per substrate): ~1 hour total
- Statistical analysis: minutes
- Total per model: ~2 hours

For 1.4B + 6.9B: ~5 hours compute + analysis time.
Feasible for ~1-2 week sprint when resources allocated.

## Risk register

| Risk | Mitigation |
|------|------------|
| Attention matrix encoding non-canonical | Pre-register encoding in DESIGN.md; multiple alternative encodings tested |
| Correlation found with one metric but not others | Pre-register all metrics; report all results |
| Φ-family value range explodes on large n | Apply per-Φ normalization documented in DESIGN.md |
| Sixth too slow for substrate sizes ~200 nodes | Profile; potentially port phi-perc to native Racket for hot path |
| Compute access blocked | Use smaller models (Pythia 70M, 160M) first; scale up later |

## Connection to v9.0 preprint

CLAIMS.md Tier 2 / Tier 3 cite this companion as the empirical-
validation gateway.  Until this companion runs, substrate-monism
Tier-2 «encoding-map composes structurally» claim is unsupported by
real data — only by toy substrates.  This companion's outcome
determines whether substrate-monism graduates to Tier 1-supported
or fires F5.1.
