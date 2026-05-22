# Encoding Design — Pythia Attention → Sixth Substrate

## Encoding scheme (pre-registered)

For each (layer L, head H, prompt P) tuple:

1. **Nodes**: one node per attention head position.  For Pythia
   1.4B (24 layers × 16 heads × 2048 context), too many for
   single substrate.  Sampling: take one layer at a time;
   nodes = heads in that layer for given context window.

2. **Edges**: directed edge from head h_i to head h_j with
   probability proportional to mean attention weight (averaged
   over context positions).  Threshold above τ = 0.05 (default;
   may tune).

3. **Features (NSET)**: each node's NGET = its mean self-attention
   weight (diagonal element) × 10000 to keep integer arithmetic.

4. **Self-loops**: node gets self-loop iff its diagonal attention
   weight > τ_self (default 0.10).  This determines `phi-self-ref`
   factor.

## Φ-family adaptation

Same stdlib/phi.6th words apply directly:
- `phi-pa(O)` = OUT(O) · self-ref · L_max
- `phi-perc(O)` = component-size(O) · self-ref · L_max
- `phi-integ(O)` = OUT · self-ref · NSUM · L_max
- `phi-bidir(O)` = (OUT + IN) · self-ref · L_max

For "observer", we use ONE specific head per layer (the most
self-attentive head; ties broken by head index) and average over
layers.

## Pre-registered metrics

### Behavioural metrics on Pythia 1.4B (from public eval harness)

1. **LAMBADA accuracy** (proxy: completion probability)
2. **MMLU subset average** (5 subjects)
3. **Layer-wise representational quality** (LM-Eval probe scores)

### Per-prompt substrate-derived Φ values

For each prompt P, get one Φ_PA, Φ_perc, Φ_integ, Φ_bidir value
per layer.  Aggregate: per-layer mean across prompts.

### Correlation tests

Spearman ρ between:
- ⟨Φ_PA⟩(layer) and per-layer linear-probe score
- ⟨Φ_perc⟩(layer) and per-layer linear-probe score
- ⟨Φ_PA⟩(scale) and capability score (across model sizes)
- ⟨Φ_perc⟩(scale) and capability score

ρ > 0.3 across ≥ 3 metrics = positive evidence.
ρ < 0.1 across all = F5.1 fires.

## Predictions (to be pre-registered in PREDICTIONS.md
before measurement)

### Substrate-monism predicts (BEFORE running):

1. **Φ_perc increases monotonically with layer index** (deeper
   layers = more integrated information).
2. **Φ_PA grows sub-linearly with model scale** (larger model →
   slightly more self-attention per head, but with bounded
   diminishing returns).
3. **Φ_integ correlates with capability** more strongly than
   Φ_PA (integration captures information-richness, Φ_PA only
   captures connectivity).

### Null hypotheses (under which F5.1 fires):

1. All Φ-family values uncorrelated with layer/scale.
2. Negative correlation (deeper layers = LESS Φ).
3. Correlations within noise band (|ρ| < 0.1).

## Methodological commitment

This document pre-registers the encoding, metrics, predictions,
and falsifiers.  Any post-hoc revision will be flagged in
commit history with `[POST-HOC]` tag.

## Open design questions (to resolve before execution)

- [ ] Single-head observer vs ensemble of all heads per layer?
- [ ] Threshold τ for attention edges (0.05 vs 0.01 vs adaptive)?
- [ ] Layer-by-layer encoding vs cross-layer single substrate?
- [ ] Token-position averaging vs per-position encoding?
- [ ] Causal mask handling (directed edges only forward in context)?

These are intentionally LEFT OPEN until the pre-execution sprint;
ad hoc decisions during analysis would invalidate the pre-
registration.

## Scope clarification

This companion does NOT claim to test whether Pythia is
"conscious".  It tests whether Φ-family substrate-readable
measures correlate with model-behavioural metrics.  Even if
strong correlation found, that does NOT establish consciousness
in Pythia — it establishes that Φ_PA captures *something* about
attention-pattern structure that also matters for capability.
The substrate-monist identity thesis remains an interpretive
claim (Tier 3 of CLAIMS.md); this companion tests the
operational direction (PSH1-PSH5 of v9.0 preprint).
