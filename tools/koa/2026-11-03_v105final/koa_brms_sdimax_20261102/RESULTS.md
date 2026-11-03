# RESULTS: koa_brms_sdimax_20261102 (Hawaii plot-specific SDImax)

## AMENDMENT 2 update (2026-11-02, 15:10 AST) [PREREG.md AMENDMENT 2, RUN.md]

### Bottom line
LQMM tau 0.95 converged and is the plot SDImax of record **unless RI_LONG meets the original criteria** (rule of record, PREREG.md AMENDMENT 2c). RI_LONG is still sampling (started 15:07; estimated 2.3 to 9.2 h); its evaluation (out/fit_eval_rilong.csv, out/record_amend2.csv), 03_post.R outputs (*_rilong) and the 04_env.R gbm on whichever fit is of record run automatically when it ends. Until out/record_amend2.csv exists, the LQMM values below are of record by the rule's second clause, pending RI_LONG.

### LQMM (lqmm 1.5.8; ltph ~ lqmd, random ~1, group = plot, LP_max_iter 100000 as in the CONUS scripts) [out/lqmm_estimates.csv, out/lqmm_boot.csv, logs_05_lqmm.log]
Frame: 2,460 rows, 672 plots (same as the brms fits).
| tau | b0 | b1 (bootstrap 95%) | population SDImax at QMD 25.4 cm (bootstrap 95%) | random-intercept variance | converged (low_loop, upp_loop) | bootstrap replicates converged |
|---|---|---|---|---|---|---|
| 0.95 (of record candidate) | 12.400 | -1.722 (-1.825 to -1.548) | 923 (780 to 1,159) | 0.253 | yes (312, 3) | 500 / 500 |
| 0.99 (sensitivity) | 12.883 | -1.870 (-1.907 to -1.307) | 929 (822 to 2,997) | 0.207 | yes (54, 4) | 500 / 500 |
The tau 0.99 bootstrap is strongly right-skewed (bootstrap median 1,199 vs point 929), so the tau 0.99 population value is poorly determined. The tau 0.95 slope interval includes -1.605 and the RI_UNCENTERED brms slope -1.663.

### Plot SDImax, LQMM tau 0.95 [out/plot_sdimax_lqmm.csv, out/plot_sdimax_summary_lqmm.csv]
All 672 plots: median 911, mean 980, 2.5 to 97.5 percentile 447 to 2,082, range 230 to 3,625 (tau 0.99 plot median 930).
| group | plots | median | 2.5 to 97.5 pct |
|---|---|---|---|
| FIA | 338 | 1,007 | 406 to 2,223 |
| Network | 334 | 859 | 483 to 1,243 |
| FIA natural | 317 | 990 | 402 to 2,203 |
| FIA planted | 19 | 1,298 | 578 to 2,226 |
| Network planted | 143 | 791 | 453 to 1,437 |
| Network natural | 98 | 951 | 624 to 1,224 |
| Network origin unknown | 93 | 933 | 492 to 1,197 |
| koa-dominated (mean koa BA share >= 0.5) | 204 | 779 | 458 to 1,395 |
| not koa-dominated | 468 | 1,002 | 444 to 2,142 |
FIA by island (COUNTYCD): 1 = 999 (234 plots), 3 = 1,030 (32), 7 = 1,083 (25), 9 = 938 (47). FIA unknown origin: 2 plots (589). FIA koa-dominated: 9 plots (649).
Caution: 44.6% of plots contribute one row, so their random intercepts are strongly shrunk toward the population value; log plot SDImax correlates 0.38 with rows per plot [logs_07_post_lqmm.log]. Per-plot intervals were not estimated (AMENDMENT 2b).

### RD against plot SDImax (LQMM tau 0.95) [out/plot_rd_lqmm.csv, out/rd_summary_lqmm.csv]
Plot visits in the fit (1,193): median 0.406, 95th 0.836, max 1.82, share > 1 2.3%. FIA 0.457; network 0.344; network planted 0.341; koa-dominated visits 0.327.
Growth-model plots [out/growth_plot_sdimax_lqmm.csv]: FIA 46 of 50, DOFAW 7 of 7, KMR PSP 14 of 14, PSP 32 of 32 have a plot SDImax.

### Comparisons [out/compare_lqmm.csv]
- Pooled frontier (~/jobs/koa_maxsdi_20261102/RESULTS.md): fixed-slope tau 0.99, all plots 1,983 = 2.15 x the LQMM tau 0.95 population value; koa-dominated 1,147 vs LQMM koa-dominated plot median 779 (0.68). The pooled values are frontiers over all plots, the LQMM values a typical plot's own 0.95 line, so lower values are expected; the all-plot pooled value sits near the LQMM plot 97.5 percentile (2,082).
- v104 projected SDI maxima (natural even-aged 430, planted 881, uneven-aged 607; koa_maxsdi RESULTS.md) and v105 (high site, ~/jobs/koa_v105_20261102/RESULTS_v105.md lines 287 to 295: 430, 882, 611): natural even-aged 430 = 0.47 and uneven-aged 611 = 0.66 of the LQMM population value 923, and below the FIA natural plot median 990; v105 planted 882 exceeds the network planted plot median 791 (1.11 x) and the koa-dominated median 779, but is within their 2.5 to 97.5 range (453 to 1,437).
- brms (not of record): RI_UNCENTERED population value 738 (672 to 803), slope -1.663.

### Figure
fig_sdimax_lqmm.png: data with LQMM tau 0.95 population line and 40 plot lines; histogram of plot SDImax with population value and bootstrap band, pooled 1,983 / 1,147 and v105 maxima marked.

### Deviations (AMENDMENT 2)
1. RI_LONG reduced to 4 chains x 6,000 before launch (written into AMENDMENT 2a); upper run-time estimate still exceeds 6 h.
2. LQMM uses the CONUS control LP_max_iter = 100000 and na.action = na.omit (stated in AMENDMENT 2b); the script that wrote the CONUS SDImax.lqmm_6-6-24.csv / _p99.plt.csv was not found, so the specification mirrors ~/Max SDI/FIA.SDI.R, FIA SDI Analysis.R and SDImax.R.
3. 07_post_lqmm.R ran (seconds, 1 thread) beside RI_LONG's 4 chains, briefly 5 cores; 04_env.R chained after RI_LONG to keep 4 cores.
4. 03_post.R and 04_env.R gained optional arguments (output suffixes); behaviour without arguments unchanged.

---
## AMENDMENT 1 results (unchanged below)


## Bottom line
None of PRIMARY, SENS_UNCENTERED or RI_UNCENTERED met the preregistered convergence criteria (Rhat < 1.01, bulk and tail ESS > 400 on every population-level, sd, cor and sigma parameter; no divergent transitions after warmup). Under the AMENDMENT 1 selection rule, plot SDImax is reported as **not estimable with this specification**, and the pooled frontier results of koa_maxsdi_20261102 stand (all plots tau 0.99 fixed-slope 1,983, 95% cluster bootstrap 1,691 to 2,572; koa-dominated 1,147, 924 to 1,266; ~/jobs/koa_maxsdi_20261102/RESULTS.md). No plot SDImax, plot RD, growth-plot lookup or environmental model is reported. [out/fit_eval.csv, out/fits_used.csv]

Frame: 2,460 rows (1,829 FIA subplot visits on 338 plots; 631 network plot-years on 334 plots), 672 plots, median 3 rows per plot. [01_frame.log]

## Convergence [out/fit_eval.csv, out/fit_summary.csv]
| fit | max Rhat | min bulk ESS | min tail ESS | divergent | treedepth-10 hits | passes |
|---|---|---|---|---|---|---|
| PRIMARY (CONUS priors, centered intercept) | 1.741 (b_lqmd) | 6 | 14 | 0 | 4,000 / 4,000 | no |
| SENS_UNCENTERED (CONUS priors on uncentered intercept) | 1.194 (sd lqmd) | 14 | 17 | 0 | 4,000 / 4,000 | no |
| RI_UNCENTERED (random intercept, common slope) | 1.025 (sd Intercept) | 188 | 506 | 0 | 4,000 / 4,000 | no |
| SENS_WEAK (sensitivity only) | 1.042 | 95 | 225 | 0 | 4,000 / 4,000 | no |

RI_UNCENTERED came closest: b_Intercept 11.982 (Rhat 1.0114, bulk ESS 497), b_lqmd -1.663 (-1.713 to -1.613; Rhat 1.0064, ESS 547), sigma 0.048 (Rhat 1.0046, ESS 1,089), but sd(ID Intercept) 0.829 had Rhat 1.0255 and bulk ESS 188, and b_Intercept Rhat 1.0114 also exceeds 1.01. Every fit hit the maximum tree depth on every draw. The random-slope fits estimate cor(Intercept, lqmd) about -0.93 and sigma about 0.04, consistent with the plot intercept/slope ridge described in AMENDMENT 1. [logs_03a_eval.log]

## Item 4 comparison with the pooled frontier
Not possible as specified: there is no fit of record, so there are no plot SDImax medians or 95% ranges by source, origin or koa dominance. For orientation only (non-converged, not of record, not a frontier): the population-level value exp(b_Intercept + b_lqmd log 25.4), i.e. a typical plot's 0.95-quantile line at QMD 25.4 cm, is 738 (672 to 803) in RI_UNCENTERED, 565 in SENS_UNCENTERED, 588 in SENS_WEAK and 1,220 in PRIMARY, all below the pooled tau 0.99 values 1,983 (all plots) and 1,147 (koa-dominated). [out/fit_summary.csv]

## Deviations from PREREG.md
1. AMENDMENT 1 (09:34:50 AST, before RI_UNCENTERED started) added RI_UNCENTERED and the selection rule, and dropped the original clause to refit failing fits at adapt_delta 0.99 / 4,000 iterations; that refit was not run for any fit.
2. RI_UNCENTERED ran with 4 cores after an aborted 2-core start (RUN.md).
3. 03_post.R and 04_env.R were not run because no fit of record exists; out/fit_summary.csv was written by 03a_eval.R instead of 03_post.R.
4. The item 4 environmental model (Hawaii Island FIA only, 10-fold and 20 km block CV) was not fitted, for the same reason.

## Possible next step (not run; would need a new amendment and Aaron's decision)
RI_UNCENTERED was near the thresholds; a longer run (for example 4,000 sampling iterations per chain) or a higher max_treedepth might lift the sd ESS above 400 (untested), but under the current rule it is not the fit of record.
