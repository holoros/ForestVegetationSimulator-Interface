# PREREG: koa_brms_sdimax_20261102 (Hawaii plot-specific SDImax, brms, CONUS method)

Written 2026-11-02T07:31:36-04:00 on firebreather, before any frame build or model fit.

## Method source (read, not modified)
- ~/Max SDI/brms.SDImax.R: brm(bf(ltph ~ lqmd + (1 + lqmd | ID), quantile = 0.95), family = asym_laplace(), chains 4, seed 54321, backend cmdstanr, priors Intercept normal(12.634, 0.119), b lqmd normal(-1.797, 0.106), sd(ID) Intercept normal(0, 0.81), sd(ID) lqmd normal(0, 0.25); brms defaults otherwise (iter 2000, warmup 1000, default centering of the intercept). Data FIA.sum.4-1-23.csv: subplot visit rows, ID = STATECD-UNITCD-COUNTYCD-PLOT, TPH = TPA x 2.48, QMD.cm = qmd x 2.54, filters TPH > 0, finite logs, INVYR 1999-2023, TPH < 50000; STATECD 2 and 15 excluded.
- Subplot frame (FIA.SDIv1.R / "FIA SDI Analysis.R"): live trees, TPA_UNADJ x 4 (subplot expansion), TPA = sum, qmd = sqrt(sum(w DIA^2)/sum(w)) in inches. Those scripts also filtered CONDID == 1; per the task instruction the condition split is NOT applied here (the fixed-area subplot is the sample).
- ~/Max SDI/"Analysis of brms SDImax.R": plot SDImax = exp(b0 + b1 x log(25.4)) with b0, b1 the plot-level coefficients from coef(fit, robust = TRUE) (fixed + random). Production file brms.SDImax.1-27-24.csv carries SDImax.mean and SDImax.median (its generating script was not found on firebreather); here SDImax is computed per posterior draw and summarized (mean = primary, median, 2.5%, 97.5%), and the coef(robust = TRUE) point form is also reported.
- RD as in "RD brms value.R": plot-level SDI (metric) / plot SDImax.
- gbm of SDImax on environment (brms.SDImax.gbm.RDS: gbm gaussian, interaction depth 5) as the template for item 4.

## Data
- FIA Hawaii (STATECD 15), all islands, all species, ~/jobs/koa_rv_byi_20260928/in/HI_TREE.csv: STATUSCD 1, DIA >= 1 in, TPA_UNADJ > 0; one row per subplot visit (STATECD, UNITCD, COUNTYCD, PLOT, SUBP, INVYR); CONUS filters applied; rows with TPH = 0 dropped. Burned plot 15|1|1|2628 excluded (as in koa_maxsdi_20261102). HI_COND.csv used only for STDORGCD (origin summary); HI_PLOT.csv not read. No coordinate column read except in item 4 (see below).
- Koa network: ~/jobs/koa_maxsdi_20261102/out/frame_plot_all_n1.csv, source Network, flag_excl empty (post-thinning plot-years excluded), TPH > 0; each plot-year a row, ID = Data|Install|Plot. Live trees DBH >= 2.54 cm, all species where recorded (PSP, KMR PSP, Mauka koa only).

## Fits (each 4 chains, 4 cores, no threading, seed 54321, cmdstanr)
1. PRIMARY: CONUS specification exactly (priors above, default brms centering).
2. SENS_WEAK: Intercept normal(12, 2), b normal(-1.6, 0.5), sd Intercept and sd lqmd half-normal(0, 1).
3. SENS_UNCENTERED (added because brms applies a class Intercept prior to the CENTERED intercept, i.e. ltph at mean lqmd, while the CONUS values 12.634 / -1.797 are on the ln QMD = 0 scale): CONUS priors with bf(..., center = FALSE) so the intercept prior acts on the uncentered intercept.

## Convergence criteria
All population-level parameters, sd, cor and sigma: Rhat < 1.01, bulk ESS > 400, tail ESS > 400; zero divergent transitions after warmup. Also reported: share of plot SDImax derived quantities meeting Rhat < 1.01 and ESS > 400. If a fit fails, refit with adapt_delta 0.99 and iter 4000 (warmup 2000) and report the refit, pass or fail.

## Outputs
out/fit_summary.csv; out/plot_sdimax.csv (+ summaries by source, origin, island COUNTYCD, koa-dominated); out/plot_rd_brms.csv (RD per plot visit = plot SDI / plot SDImax mean, SDI = TPH (QMD/25.4)^1.605 metric, all species; FIA also summation form sum TPH_i (DBH_i/25.4)^1.605); out/growth_plot_sdimax.csv for growth-model plots (frames/final/dDBH_NO_v103_model.csv); population SDImax = exp(b_Intercept + b_lqmd log 25.4) per draw.
Item 4: gbm of plot SDImax (posterior mean) on Hawaii climate/water, substrate (USGS geology age group), SoilGrids soils, and 30 m topography from ~/jobs/koa_byipred_20261102/LAYERS.csv (no canopy height, LAI or vegetation cover layers). True FIA locations read only inside R from ~/jobs/koa_rv_byi_20260928/in/PLT.GEO_FIA.csv (restricted); no coordinate or block id written or printed. CV: 10-fold random by plot and 20 km x 20 km spatial blocks (UTM 4N), pooled out-of-fold R^2 = 1 - SSE/SST.
Comparison targets: koa_maxsdi_20261102 RESULTS.md (fixed-slope tau 0.99 SDImax 1,983 (1,691 to 2,572); koa-dominated 1,147).
At most 6 cores throughout.

## AMENDMENT 1 (written 2026-11-02T09:34:50-04:00 on firebreather, before RI_UNCENTERED or any further fit was started; PRIMARY finished, SENS_UNCENTERED and SENS_WEAK still sampling)

Observed: PRIMARY (fits/PRIMARY_ad0.8_it2000.rds) did not converge: Rhat 1.71 (Intercept) and 1.74 (lqmd), bulk ESS 6, sd(Intercept) Rhat 1.64, all 4,000 post-warmup transitions at max treedepth 10, E-BFMI < 0.3 in 3 of 4 chains, sigma 0.04, cor(Intercept, lqmd) -0.92 (logs_02_PRIMARY_ad0.8.log).

Why a random-intercept fit is added: the fit frame has 2,460 rows on 672 plots (median 3 rows per plot; 01_frame.log). With this little replication per plot, a plot-specific 0.95-quantile slope is not identifiable from the data, so the (1 + lqmd | ID) specification leaves plot intercept and slope trading off along a ridge (cor -0.92) that the sampler cannot traverse. In addition, brms applied the CONUS intercept prior normal(12.634, 0.119), which is on the ln QMD = 0 scale, to the centered intercept (ltph at mean lqmd 2.623), which is a misplaced prior (SENS_UNCENTERED already addresses that for the random-slope form).

Added fit RI_UNCENTERED:
- bf(ltph ~ 0 + Intercept + lqmd + (1 | ID), quantile = 0.95), family asym_laplace(), backend cmdstanr, 4 chains, seed 54321, adapt_delta 0.95, iter 2000 (warmup 1000).
- Priors: b Intercept (uncentered) normal(12.634, 0.119); b lqmd normal(-1.797, 0.106); sd(ID) Intercept normal(0, 0.81); others brms defaults.
- Plot SDImax per draw = exp(b0_i + b1 x log 25.4), b0_i = b_Intercept + r_ID[i, Intercept], b1 = common slope b_lqmd.

Selection rule: "The fit of record is the first of PRIMARY, SENS_UNCENTERED, RI_UNCENTERED that meets the convergence criteria (Rhat < 1.01, bulk and tail ESS > 400, no divergent transitions after warmup); if none does, the plot SDImax is reported as not estimable with this specification and the pooled frontier results stand."

SENS_WEAK remains a sensitivity fit only and cannot become the fit of record. This rule replaces the earlier clause "If a fit fails, refit with adapt_delta 0.99 and iter 4000": that refit is not run for PRIMARY or SENS_UNCENTERED (reported as a deviation), because the failure is one of identifiability, not of step size.
Item 4 (environmental gbm) is restricted to Hawaii Island FIA plots (COUNTYCD 1); 03_post.R is adapted to read the fit of record and, for RI_UNCENTERED, the common slope.

## AMENDMENT 2 (written 2026-11-02T14:52:45-04:00 on firebreather, before LQMM, RI_LONG or any other new fit was started; no fit running in this job)

Observed (RESULTS.md, out/fit_eval.csv): none of PRIMARY, SENS_UNCENTERED, RI_UNCENTERED met the criteria. RI_UNCENTERED came closest (sd(ID Intercept) Rhat 1.0255, bulk ESS 188; b_Intercept Rhat 1.0114; b_lqmd -1.663, -1.713 to -1.613); every fit hit max treedepth 10 on all 4,000 draws. Two additions follow. At most 4 cores for this job from here on (another job uses the rest).

### (a) RI_LONG
RI_UNCENTERED rerun: same formula bf(ltph ~ 0 + Intercept + lqmd + (1 | ID), quantile = 0.95), asym_laplace, same priors (b Intercept normal(12.634, 0.119), b lqmd normal(-1.797, 0.106), sd(ID) Intercept normal(0, 0.81), brms defaults otherwise), same seed base 54321, cmdstanr; requested 6 chains, 6,000 iterations (3,000 warmup), adapt_delta 0.99, max_treedepth 12.
Run-time estimate (from logs_02_RI_UNCENTERED_ad0.95.log): 4 parallel chains of 2,000 iterations took 2,553 to 2,769 s per chain with every draw at treedepth 10 (about 1.3 s per iteration). At 6,000 iterations that is x3; if treedepth 12 is reached on every iteration as 10 was, each iteration costs up to x4 more, so about 2.3 h per chain if treedepth stays at 10 and up to about 9.2 h per chain if 12 saturates. Six chains on 4 cores need two waves: about 4.6 to 18 h. This exceeds about 6 h, so RI_LONG is REDUCED to 4 chains x 6,000 iterations (3,000 warmup; 12,000 post-warmup draws), all 4 chains in parallel on 4 cores: about 2.3 h (treedepth 10) to about 9.2 h (treedepth 12 saturated). The upper bound still exceeds 6 h; no further reduction is made (iterations are kept so the ESS target stays reachable). If RI_LONG has not finished when this session ends, a chained script evaluates it and runs 03_post.R automatically on completion (see RUN.md).
Evaluation, original criteria (all b_, sd_, sigma): Rhat < 1.01, bulk ESS > 400, tail ESS > 400, zero divergent transitions after warmup.
Relaxed tier (defined now, before RI_LONG runs): Rhat < 1.05, bulk ESS > 100, zero divergent transitions after warmup. A fit passing only the relaxed tier is reported as PROVISIONAL. Treedepth hits are reported, not a criterion.

### (b) LQMM
lqmm::lqmm(ltph ~ lqmd, random = ~1, group = ID, tau = c(0.95, 0.99)) on out/fit_frame.csv (2,460 rows, 672 plots; same frame as the brms fits). lqmm 1.5.8 (installed today from CRAN into the user library).
CONUS specification mirrored: the script that wrote ~/jobs/sdimax_check_20261006/SDImax.lqmm_6-6-24.csv and SDImax.lqmm_p99.plt.csv was not found on firebreather (grep of ~/Max SDI R scripts for "SDImax.lqmm"/"lqmm_p99" found none). The lqmm specification in ~/Max SDI/FIA.SDI.R (m1.6, tau 0.99), ~/Max SDI/FIA SDI Analysis.R (m1.2, tau 0.95) and ~/Max SDI/SDImax.R (m95, tau 0.95) is: fixed ltph ~ lqmd, random ~1, group = plot ID, control = lqmmControl(LP_max_iter = 100000), na.action = na.omit, all other lqmm defaults (method "gs", type "normal", covariance "pdDiag", nK 7, UP_max_iter 20); plot SDImax = exp(b0 + u_i + b1 log 25.4), b0, b1 = coef(fit), u_i = ranef(fit) (SDImax.R line 146; FIA.SDI.R column name SDImax.qreg, as in the 6-6-24 files). Differences from the call above: LP_max_iter = 100000 instead of the default 500, and na.action = na.omit (no NAs in the frame, so no effect). Both are adopted (CONUS mirror).
Plot SDImax = exp(b0 + u_i + b1 x log 25.4) with the common slope b1, per tau; population SDImax = exp(b0 + b1 log 25.4).
Plot-cluster bootstrap: B = 500, seed 20261102 (L'Ecuyer-CMRG for parallel streams, 4 cores); each replicate resamples the 672 plots with replacement (a plot drawn k times enters as k distinct groups) and refits both taus with the same control; reported: percentile 95% intervals of population SDImax at QMD 25.4 cm and of the slope b1. Replicates that fail the convergence check are counted and excluded. Per-plot SDImax intervals are not estimated.
Convergence: lqmm's upper loop converged (opt upp_loop > 0, i.e. not -1/-2) and lower loop did not hit LP_max_iter (low_loop not -1), and all of b0, b1, scale, the random-effect variance and every u_i finite.
LQMM tau = 0.95 is the candidate of record; tau = 0.99 is reported as a sensitivity.

### (c) Rule of record (verbatim)
"Plot SDImax of record is RI_LONG if it meets the original criteria; else LQMM tau = 0.95 if it converges; RI_LONG passing only the relaxed tier is reported beside LQMM as provisional. If neither converges, plot SDImax is not estimable and the pooled frontier stands."

Order: LQMM first, then RI_LONG in background. 03_post.R runs for the fit of record and any provisional fit (outputs suffixed _lqmm for LQMM, _rilong for RI_LONG); 04_env.R (Hawaii Island FIA only) if time allows, on the fit of record.
