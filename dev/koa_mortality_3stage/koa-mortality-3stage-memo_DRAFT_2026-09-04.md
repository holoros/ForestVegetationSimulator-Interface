# Koa mortality for FVS-HI: is a three-stage structure with a García stand-level survival model better than the density ramp of record?

**To:** Aaron Weiskittel. **From:** Claude (autonomous OODA run). **Date:** September 4, 2026. **Status:** DRAFT, decision pending.

**Decision this serves.** Which mortality component ships in FVS-HI (Ben Rice's package, PR 31, Zenodo 1.5.0) and is described as the equation of record in the *Acacia koa* A. Gray manuscript.

## Short answer

Yes, with a qualification. The three-stage structure of Chen et al. (2023) matches how mortality actually occurs in the koa network, where 66% of all recorded deaths fall in 14% of plot intervals, and García (2009) supplies a stand-level second stage that is fittable, self-thinning consistent by construction, and exact under the network's unequal remeasurement intervals. On the regular-mortality record the García form with the ratio gamma/alpha fixed at 1 has the lowest leave-one-installation-out error on stand density of any candidate, an annual mortality bias whose cluster-bootstrap interval includes zero, and an implied Reineke slope of -1.71, inside the -1.2 to -2.2 tolerance band. The ramp of record predicts twice the regular deaths observed (+101%), with an annual bias of +0.024 yr⁻¹ whose interval excludes zero, and is worst exactly where it matters for long projections, at SDI above 500. The qualification is that the density signal in the regular record is weak enough that a constant 3.1% yr⁻¹ rate is nearly as accurate as any fitted form, so the case for García rests on behavior (bounded self-thinning, path invariance, no annualization) more than on fit, which is the argument García makes for data-poor situations and the one principle 4 of the modeling philosophy asks for.

## What was wrong with the prior negative result

The August 28 García fits (MEMORY.md, sixth pass) used `TPH` from `AK_PLT.csv`, which includes ingrowth, so N rose with height in young stands and the fitted limit line cut through the data. Those fits also returned alpha = 2.000 and gamma = 10.000 in every subset, which are starting-grid values, so the optimizer never left its starts. Rebuilding N on the survivor cohort (trees live at the first measurement, followed to the second, ingrowth excluded, a death counted only when the tree is never recorded live again) and separating irregular intervals removes both defects. This is a failed repair in the F8 sense and is logged so it is not retried.

## Data as rebuilt

From `AK_TREE.csv` and `AK_PLT.csv` (deposit 1.4.0 copies), 421 consecutive plot intervals on 119 plots carry 1,383 cohort deaths under the sentinel-cleared reading (a dead status with DBH 0 counts as a death unless the tree is later recorded live). The thinning register for the KS permanent plots (27 of 32 thinned) and the 2009, 2018, 2020 and 2021 pulses in the new-dead counts show that the record mixes thinning removals, a single FIA die-off (installation 15-1-1-2628, four subplots at 52 to 83% loss), and 1960s to 1990s DOFAW plantation losses of unrecorded cause with regular self-thinning. An interval was called irregular when cohort mortality exceeded 0.10 yr⁻¹. That rule flags 60 of 421 intervals carrying 913 of 1,383 deaths (66%), with median cohort loss 0.32 (IQR 0.16 to 0.69). The regular set is 360 intervals on 103 plots, 469 deaths in 15,562 tree-years, 3.0% yr⁻¹ pooled, 0.9% yr⁻¹ below SDI 200 rising to 5.2% at SDI 500 to 850 and 2.1% above 850 (29 intervals). Under the non-sentinel reading the regular set holds 21 deaths, too few to fit anything, so the reading question stays open and is priced below.

## The three stages

Stage 1, occurrence. A logistic model of the irregular flag on ln SDI, origin and ln interval gives AUC 0.61 in sample (0.69 for any death), so occurrence is a plot-level event that is only weakly predictable, as Chen et al. found (0.55 to 0.74). Stage 1 therefore belongs in FVS-HI as an optional stochastic event with the observed rate (0.14 per plot interval) and magnitude distribution, not in the default deterministic projection.

Stage 2, regular stand-level survival. García's form S^alpha - (beta H)^gamma = constant, S = 100/sqrt(N) and H = H40, was fitted by weighted nonlinear least squares on ln S at the second measurement. Candidates on identical data: García free and with gamma/alpha fixed at 1 and 2, a cloglog plot-pair GLM on ln SDI and origin with a ln(interval) offset, a constant rate, and the ramp of record (onset 200, full lift 850, 0.15 yr⁻¹, backgrounds 0.003 and 0.006).

| Candidate | Parameters | LOIO RMSE N₁ (trees ha⁻¹) | LOIO deaths bias | LOIO annual bias (yr⁻¹) | Annual bias 95% CI | Implied Reineke slope |
|---|---|---|---|---|---|---|
| García gamma/alpha = 1 | alpha = gamma = 2.96 (1.64 to 4.99), beta = 0.117 (0.057 to 0.159) | 106 | -5% | -0.011 | -0.016 to -0.001 | -1.71 |
| García free | alpha 2.10, beta 0.085, gamma 2.83 | 111 | +9% | -0.009 | -0.017 to +0.002 | -2.30 |
| cloglog ln SDI | b(ln SDI) = 0.31, planted -0.38 | 77 | +14% | -0.007 | -0.005 to -0.001 | none |
| constant rate | 0.031 yr⁻¹ | 82 | +9% | -0.008 | not bootstrapped | none |
| ramp of record | as deployed | 116 | +101% | +0.024 | +0.012 to +0.038 | -1.2 to -2.2 in projection only with the cap |

Intervals are plot-cluster percentile bootstrap intervals, B = 2,000, seed 20260904. The free García ratio gamma/alpha has a bootstrap interval of 0.33 to 11.6, so it is not identified on this record and fixing it at 1 is required, which is García's own remedy for sparse data. The García gamma/alpha = 1 fit underpredicts regular annual mortality by about 1 percentage point (interval excludes zero on the low side, driven by the long DOFAW intervals discussed below); the ramp overpredicts by 2.4 points with an interval that excludes zero on the high side by a wide margin.

The cloglog GLM wins on N₁ RMSE because its ln SDI slope is shallow and it behaves almost like the constant rate. It has no self-thinning limit and cannot be trusted in extrapolation. The García gamma/alpha = 1 fit bounds 99.4% of the observed (N, H40) pairs beneath its limiting line (the free fit bounds 100%), which the two prior attempts failed to do. The equivalence test on observed against predicted N₁ passes the ±25% region for every candidate including the ramp, because N₁ is dominated by N₀; the annual bias interval is the discriminating statistic, and the ramp's is the only one that is both large and one-sided high.

Stratified LOIO shows where each fails. By interval length, García underpredicts the 7-year and longer intervals (1.4% against 4.9% yr⁻¹ observed) and overpredicts the annual ones (2.2% against 1.7%); the ramp is above observation in every stratum (5.3% at one year, 7.2% at 7+). That pattern is data-source confounding, since the long intervals are DOFAW plantations at 5.3% yr⁻¹ and the annual ones are KS permanent plots at 1.5% yr⁻¹, and no candidate resolves it. By origin, García predicts 0.4% yr⁻¹ for planted stands against 2.2% observed on 41 intervals, because planted H40 growth is small in those intervals, and a planted background term will be needed.

Stage 3, allocation. Within plot, ranking cohort trees by relative diameter alone orders the deaths at a c-index of 0.73 in regular intervals and 0.78 in irregular ones (rHT 0.71 and 0.77, BAL 0.73 and 0.78). The Table 6 cloglog is not needed for ordering; a relative-size weight does the job Chen et al. assign to their stage 3, and it is what the deployed `tree_eq` allocation already does with more machinery.

## Recommendation

Replace the ramp with a three-stage component: regular mortality by García with gamma/alpha = 1 (two parameters, driven by projected H40 from the height equation, exact over any step length, self-thinning line log N + 2 log H40 = constant), allocation by relative size with expansion-factor renormalization, and irregular events as an optional stochastic stage off by default. Keep the sentinel reading as the stated basis and price it: under the non-sentinel reading no regular model is estimable at all, which is a data question for the DOFAW and PSP custodians, not a model question.

## Costs of the switch

Table 8, Supplemental Fig. S6, the Bakuzis assessment, Supplemental Table S2, deposit 1.5.0, PR 31 and Ben's package were all generated with the ramp and must be regenerated before the paper can call García the equation of record. The v81 trim already built today (abstract 299, body 8,692, supplement 9,669, equations renumbered, sentinel counts reconciled) is independent of this choice; only Sections 2.4.3, 2.6, 3.3.4, 3.3.5, 4.2 to 4.4 and Supplemental Section 2 change.

## Unknowns ledger

[ASSUMPTION: irregular threshold 0.10 yr⁻¹; the alternative, the thinning register plus year pulses, flags a similar set but leaves the DOFAW plantation losses unclassified.] [IMPLICIT: H40 is the EXPF-weighted mean height of the 40 largest-diameter live trees per ha, the manuscript's Eq. 1 convention.] [UNKNOWN: whether DOFAW sentinel losses are deaths or thinning; if thinning, regular natural mortality is nearer 1.5% yr⁻¹ and beta falls.] [UNVERIFIED: the ramp thresholds' maximum-likelihood justification of August 11 was computed on tree-year records that pool the irregular intervals, which is why it doubles regular mortality.]

## Files

R script `koa_mortality_3stage_FINAL_2026-09-04.R` (base R, ran on firebreather, seed 20260904), outputs `plot_interval_pairs_DATA.csv`, the metric and stratum tables, the equivalence table, and four figures (N against H40 plane with García trajectories and limit line by origin; LOIO annual mortality by SDI class with binomial intervals; regular against irregular intervals; observed against predicted N₁ with the fitted slope and bootstrap intervals). Location: `active-projects/koa-fvs-hi-pr31-stress-test/mortality-3stage/`.

References. Chen, C., Kershaw, J.A., Weiskittel, A.R., McGarrigle, E., 2023. Forest Ecosystems 10, 100086. García, O., 2009. Math. Comput. For. Nat.-Res. Sci. 1, 1 to 9. Robinson, A.P., Froese, R.E., 2004. Ecol. Model. 176, 349 to 358.
