# a5/rerun RESULTS: preliminary-assembly supplement results rerun on the final frames and the v104 system (31 Oct 2026)

Every final value below is read from the named file under ~/jobs/koa_v104_20261030/a5/rerun/. "Preliminary" is the value printed in supplement s114 (/tmp/rt/supp.txt). Bias is projected minus observed unless stated.

## Summary

| Item | Preliminary | Final (v104, final frames) | Material change? |
|---|---|---|---|
| 1. Eq. 2 installation bootstrap, a1 (B = 500, prefix of the 2,000 design) | -1.31 to 2.39; 1,205 of 2,000 converged (60%); SE ratios 3.6 to 6.0 | -1.33 to 2.05; 263 of 500 converged (53%); SE ratios 3.6 to 6.5 | no (a1 still spans zero) |
| 2. S26 coverage, plot-level 17 units (surv / BA / QMD) | 0.65 / 0.65 / 0.91 (23 subplot units) | 0.765 / 0.706 / 0.824 | yes |
| 2. S26 coverage, 23 subplot units (surv / BA / QMD) | 0.65 / 0.65 / 0.91 | 0.696 / 0.696 / 0.696 | yes (QMD) |
| 3. S21 binomial ln(SDI), pooled / natural / planted | +0.299 / +1.105 / +0.105 (-0.022 to 0.224) | +0.366 / +1.045 / +0.185 (0.054 to 0.324) | yes (planted interval now excludes 0) |
| 4. S28 pooled natural survival error, held out vs in sample | +0.057 (RMSE 0.182) vs +0.058 (0.168) | +0.028 (0.125) vs +0.029 (0.112) | no for the conclusion; values about halved |
| 5. S29 natural QMD bias change, local minus population | +4.59 cm (+2.50 to +6.39) | -1.34 cm (-2.61 to -0.43) | yes (sign reverses) |
| 6. S11 observed / implied, dDBH DOFAW | 0.376 | 0.373 | no |
| 7. Limiting line slope, tau 0.99 | -1.43 (-1.68 to -1.20), 471 pm | -1.258 (-1.598 to -0.927), 483 pm | yes (shallower; CI wider) |
| 7. Fitted beta 0.117 (0.057 to 0.159) | | not rerun, fitting script not found | n/a |
| 8. S22 candidate rates | | not rerun, no matching script | n/a |

## 1. Height equation (Eq. 2) installation-cluster bootstrap (h/h_boot_summary_final.csv, h/h_boot_final.csv)
Script h/h_boot.R. It copies the logic of koa_rv_incr_20260928/s2_height_boot.R (the run that gave 1,205 of 2,000), with prep() and fit_ht() taken verbatim from track2/height_refit_v103.R. Frame: frames/final/tree_join_v103.csv, 8,914 records and 143 installations. Seed 20261031.
Plan: changed to B = 500 on coordinator instruction (31 Oct, 15:54 ADT). Draws 1 to 500 are a prefix of the 2,000-draw design; run on 2 and then 5 cores; finished 17:59 ADT.
Gate: the reference fit reproduces HT_P of out/v104_constants.json to 6 decimals (h/h_ref_final.csv).

Converged fits: 263 of 500 (53%); the preliminary run converged 1,205 of 2,000 (60%). Bootstrap statistics are taken over the converged draws only.

| Parameter | Estimate | Wald SE | Bootstrap SE | Ratio | 95% percentile interval | Preliminary interval |
|---|---|---|---|---|---|---|
| a0 | 28.929 | 1.447 | 6.557 | 4.53 | 20.18 to 44.89 | 21.6 to 45.7 |
| a1 (BYI) | 0.967 | 0.1405 | 0.920 | 6.55 | -1.33 to 2.05 | -1.31 to 2.39 |
| b | 0.01703 | 0.000985 | 0.00354 | 3.59 | 0.01371 to 0.02775 | 0.0128 to 0.0270 |
| c | 0.7922 | 0.01197 | 0.0491 | 4.10 | 0.699 to 0.896 | 0.717 to 0.883 |
| g1 | 0.07684 | 0.00646 | 0.0288 | 4.45 | 0.0221 to 0.1230 | 0.019 to 0.102 |
| g2 | -0.3433 | 0.01689 | 0.0674 | 3.99 | -0.461 to -0.204 | -0.492 to -0.220 |

The conclusion is unchanged: a1 spans zero, while the other five parameters stay away from zero. The SE ratios run from 3.6 to 6.5 (preliminary 3.6 to 6.0). As before, the interval is conditional on convergence, since failed resamples are excluded.

## 2. Table S26 coverage (cov/tableS26_coverage_v104.csv)
Scripts: cov/cov_mc.py and cov/cov_summ.py. They are built from a2/closeout/validation/plotlevel_validation.py (unit definitions copied verbatim), the Monte Carlo loop of koa_rv_mort_20260928/a2_mc_validation.py and the coverage code of a2b_coverage.py. Each run uses 500 replicates on the v104 engine (regen_m1 convention: default_rng(42), CF generator, joint draws). Gates: the mirror reproduces validate() exactly (0.0), and the point plot-level units match val_v104_plotlevel.csv (7.1e-15). The table gives coverage with its Clopper-Pearson 95% interval. Plot-level survival is expf-weighted; the count-based figure is identical except on 2628.

| Units | Group | n | Survival | BA | QMD |
|---|---|---|---|---|---|
| Plot level (17, excl. FIA 2628) | Pooled | 17 (14 inst) | 0.765 (0.501-0.932) | 0.706 (0.440-0.897) | 0.824 (0.566-0.962) |
| | Natural | 6 | 1.000 (0.541-1.000) | 0.833 (0.359-0.996) | 1.000 (0.541-1.000) |
| | Planted | 11 | 0.636 (0.308-0.891) | 0.636 (0.308-0.891) | 0.727 (0.390-0.940) |
| | PSP | 10 | 0.700 (0.348-0.933) | 0.700 (0.348-0.933) | 0.800 (0.444-0.975) |
| | 2628 alone | 1 | covered (w) / not (count) | covered | not covered (below) |
| Subplot (23, validate() units) | Pooled | 23 (17 inst) | 0.696 (0.471-0.868) | 0.696 (0.471-0.868) | 0.696 (0.471-0.868) |
| | Natural | 12 | 0.750 (0.428-0.945) | 0.750 (0.428-0.945) | 0.667 (0.349-0.901) |
| | Planted | 11 | 0.636 | 0.636 | 0.727 |
| | Natural DOFAW | 6 | 1.000 | 0.833 | 1.000 |
| | FIA subplots | 6 (3) | 0.500 (0.118-0.882) | 0.667 (0.223-0.957) | 0.333 (0.043-0.777) |

Preliminary (23 units): QMD 0.91, survival and BA 0.65. By origin, preliminary survival was 0.67 natural and 0.64 planted, and BA 0.50 and 0.82. Median pooled interval widths on the plot-level units are 0.384 for survival, 19.8 m2 ha-1 for BA and 8.99 cm for QMD; the preliminary widths were 0.44, 22.0 and 12.8. On the final system the QMD intervals are narrower and QMD coverage falls. On the subplot units, 4 of the 6 FIA subplots lie below their QMD intervals.

## 3. Table S21 ln(SDI) coefficients (s21/out_a1/a1_stage12_coefficients.csv)
Script: s21/a1_stage12_v104.R, a copy of koa_rv_mort_20260928/a1_stage12.R. The only change is the input: a2/mort/v104/plot_intervals_origin.csv after removal. That leaves 285 intervals on 54 plots, 23 natural (7 plots, 19 with a death) and 262 planted (47 plots). Seed 20260928, 2,000 plot-cluster resamples.
The original's gate is not met, by design: the S1 coefficient differs from the STAGE1 constants by 0.030 and S2 by 0.083, because those constants were fitted on 282 v103 intervals.

| Model | Pooled | Natural | Planted |
|---|---|---|---|
| Stage 1 as fitted | +0.171 (+0.029 to +0.319) | not estimable (interval -0.46 to 59.7) | +0.159 (+0.017 to +0.318) |
| Stage 1, ln(n at risk) covariate | +0.170 (+0.035 to +0.315) | not estimable | +0.171 (+0.038 to +0.307) |
| Stage 1, ln(n at risk) offset | +0.190 (+0.049 to +0.340) | not estimable | +0.184 (+0.046 to +0.326) |
| Binomial per-tree hazard | +0.366 (+0.138 to +0.653) | +1.045 (+0.491 to +2.267) | +0.185 (+0.054 to +0.324) |
| Stage 2 as fitted | -0.055 (-0.269 to +0.103) | -0.535 (-0.728 to +1.114) | -0.034 (-0.226 to +0.125) |
| Stage 2, ln(n at risk) covariate | -0.027 (-0.198 to +0.107) | -0.687 (-0.828 to +0.673) | -0.019 (-0.182 to +0.099) |

## 4. Table S28 held-out natural level factor (s28/tableS28_v104_pred_minus_obs.csv; raw obs-minus-proj in s28/B1_lt_natural_summary.csv)
Script: s28/b1_mort_holdout.py with lt_core.py, from koa_origin_20260916/v100/trackB. Inputs are the v104 engine copy (s28/engine) and a2/mort/v104 (held-out factors 2.342 to 2.908). Gates: run_points reproduces a4/lt/LT_v104_points.csv exactly (0.0) and arm a reproduces it to 7.1e-15.
Pooled over 19 points on 4 natural plots: applied (2.51588) +0.029 (RMSE 0.112), held out +0.028 (0.125), none +0.229 (0.267). QMD bias was -1.09, -1.06 and -2.79 cm and BA bias -0.02, -0.14 and +11.49 m2 ha-1. Held-out survival bias by horizon: -0.045, -0.077, +0.060 and +0.077.
The source scripts store errors as observed minus projected. The sign is flipped here to match the table; the applied arm then equals Table S27 (for example natural 1 to 5 yr, -0.046 and RMSE 0.081).

## 5. Table S29 stand-level calibration (s28/tableS29_v104_pred_minus_obs.csv; raw s28/B2_summary_boot.csv, B2_plot_ratios.csv, B2_byplot.csv)
Script: s28/b2_local_calib.py on the same engine copy. Gate: the population arm reproduces LT_v104 to 7.1e-15.
- Natural, all 15 points on 4 plots: QMD bias -1.38 (population) against -2.72 (local), a change of -1.34 cm (-2.61 to -0.43). QMD RMSE rose from 1.77 to 3.38. Survival bias went from +0.05 to +0.09.
- Planted 1 to 5 yr (26 points, 10 plots): QMD change -1.26 (-3.29 to +0.92).
- Kulani 12: BA RMSE fell from 27.94 to 8.45 and survival RMSE rose from 0.18 to 0.42.

The natural first-interval diameter ratios are 0.75 to 1.00. On v104 the local calibration therefore lowers natural growth and worsens QMD, where the preliminary assembly removed the bias (+4.59 cm).

## 6. Table S11 within-source contrasts (s11/tableS11_within_source_v104.csv)
Script: s11/s11_v104.R, combining the logic of koa_rv_incr_20260928/s1b_within.R and s1c_kulani.R. Inputs: the final NO frames, the v104 L_NO vectors, and the v104 constants applied recursion-consistently. Gate: solve_c reproduces the deployed constants exactly.

| Response | Comparison | Records pl./nat. | Observed | Implied | Obs/implied |
|---|---|---|---|---|---|
| dDBH | Kulani 12 vs 23 | 101 / 326 | 0.928 (0.661-1.202) | 2.451 (2.343-2.576) | 0.379 (0.259-0.505) |
| dDBH | DOFAW | 101 / 950 | 0.913 (0.652-1.160) | 2.451 | 0.373 (0.256-0.486) |
| dDBH | PSP | 3,433 / 19 | 1.310 (1.140-1.551) | 2.992 | 0.438 (0.380-0.520) |
| dHT | Kulani 12 vs 23 | 74 / 289 | 0.659 (0.504-0.845) | 2.669 | 0.247 (0.188-0.319) |
| dHT | DOFAW | 74 / 754 | 0.664 (0.513-0.840) | 2.669 | 0.249 (0.191-0.322) |
| dHT | PSP | 2,772 / 15 | 1.556 (1.090-1.964) | 4.815 | 0.323 (0.226-0.408) |

Both the observed and the implied contrasts are lower than before. The obs/implied ratios are close to the preliminary ones (0.355, 0.376, 0.397, 0.204, 0.202, 0.425): the applied system still overstates the planted advantage by a factor of about 2.3 to 4.

## 7. Independent limiting line (qr/qr_lines_v104.csv, origin_model_v104.csv, containment_v104.csv)
Scripts: qr/01_frame_v104.R and qr/02_fit_v104.R (from koa_selfthin_qr_20260927; seed 20260927, B 2,000) and qr/03_contain_v104.py.
The frame is the anchor frame of the deployed beta 0.14803: live koa stems, at least 5 per plot-measure, from inputs/AK_TREE_v103.csv. The gate reproduces n 483 and z99 exactly. It covers 483 plot-measures, 141 plots and 97 installations.
- tau 0.99: slope -1.258 (-1.598 to -0.927). Reineke's -1.605 lies outside the interval, against inside it in the preliminary run. The engine slope -1.921 also lies outside.
- tau 0.95: slope -1.215 (-1.477 to -0.924).
- Containment under the tau 0.99 line: no point run and no Monte Carlo replicate lies above it. At most, planted points reach 51.6% of the line and planted replicates 65.8% (0.6585 before the Stage 3 fix, 0.6580 after); natural points reach 24.2% and natural replicates 36.9%. The preliminary run gave planted 74% and natural 47%.
- Under the tau 0.95 line, 26 planted replicate-years lie above it, by up to 28.2 stems ha-1.
- Containment was rerun on the trajectories regenerated after the Stage 3 vector fix (qr/containment_v104.csv). The maximum shares are unchanged to three decimals; only the maximum exceedance under the tau 0.95 line changed, from 29.1 to 28.2 stems ha-1. The earlier file is qr/containment_v104_PRE_stage3fix.csv.

The fitted beta 0.117 (0.057 to 0.159) was not rerun. 0.117 is the stored GARCIA_BETA, and no script producing it with a plot bootstrap was found in koa_garcia_mortality, koa_v82_hybrid or koa_prereg_B_beta_20260926. The comparison of beta 0.117 against the line (exceedance of up to 69 stems) needs variant-B trajectories on v104, which do not exist.

## 8. Table S22. Not rerun
engine_v103/run_candidates.py scores M0 to M5 against the record envelope (QMD 69.68, M_UNCOND 0.09621). S22 instead uses 0.0557 yr-1, natural plot-year maxima, recalibrated kappa 0.1155 and 23-plot validation columns. No script implementing those definitions was found, so a rerun would not be comparable.
