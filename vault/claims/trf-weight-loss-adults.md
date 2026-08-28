---
type: Claim
title: TRF produces modest body-weight loss in adults with obesity
tags: [time-restricted-eating, weight-loss, obesity]
summary: "4h and 6h time-restricted eating produced ~3% body-weight loss vs. control over 8 weeks in adults with obesity."
description: "Time-restricted eating (4h or 6h daily window) produces a modest (~3%) body-weight reduction relative to unrestricted-timing controls over 8 weeks in adults with obesity."
created: 2026-08-27
updated: 2026-08-27
statement: "In adults with obesity, an 8-week time-restricted eating protocol (4-hour or 6-hour daily eating window) reduces body weight by approximately 3% relative to an unrestricted-timing control diet, with no significant difference between the 4h and 6h windows."
grade: B
applies_to: [adults-with-obesity]
sex_note: "The supporting RCT's completer cohort was ~90% female; the weight-loss effect was not analyzed by sex, so a sex-specific effect size cannot be isolated from the pooled estimate — but because women were the large majority of the sample, the ~3% pooled figure is in practice mostly a female-driven estimate."
evidence_gap: women
supports: [studies/cienfuegos-2020-4h-6h-trf]
contradicts: []
---

## Basis

Grade B: a single RCT ([[studies/cienfuegos-2020-4h-6h-trf]], N = 58 randomized /
49 completers, adequate for the endpoint) found both 4h-TRF and 6h-TRF produced ~3.2%
body-weight loss vs. ~0% (control) over 8 weeks (p < 0.001), with no significant
difference between the two window lengths. Per the rubric, one adequately powered RCT
supports grade B; a second concordant RCT (or a meta-analysis) in the same population
would be needed to reach A.

[[studies/moro-2016-trf-males]] is **not** listed under `supports` — it is `tier:
narrative` (a page only, no claims extracted from it), and CLAUDE.md §3 defines `supports`
as the claims-extraction relation a `structured`-tier study carries, so a narrative study
never belongs in another claim's `supports` list. It is corroborating body-composition
evidence worth naming here in prose only: TRF reduced fat mass more than a normal diet
(−16.4% vs. −2.8%, p = 0.0448). It does **not** count toward the grade above — it measured
fat mass, not body weight, in a categorically different population (lean, resistance-trained
young men vs. adults with obesity) — so it corroborates the general direction of effect
without independently confirming *this* claim, and without being cited as a source of it.

`evidence_gap: women` is inherited from Cienfuegos 2020, which was never sex-stratified
(per CLAUDE.md §5). No one-letter grade drop applies here, because `applies_to` names
the general adults-with-obesity population, not a women-specific one — contrast
[[claims/trf-glucose-women-evidence]], which cites the same study for a women-specific
population and *is* subject to the drop.

## Notes

- Both TRF arms also reduced spontaneous energy intake by ~550 kcal/day (~30%) without
  explicit calorie counting in the supporting trial — a plausible mechanism for the
  weight loss, not an independent confirmation of it.
- Neither TRF arm in the supporting trial reached the study authors' own 5%-of-baseline
  threshold for "clinically significant" weight loss at 8 weeks — this is a modest, not
  large, effect.
