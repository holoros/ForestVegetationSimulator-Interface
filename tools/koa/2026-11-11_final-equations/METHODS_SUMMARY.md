# Methods summary: koa (*Acacia koa* A. Gray) relative-density system, November 11, 2026

Logs named with a subfolder belong to the November 10 job and are not in this folder.

## Data frames

The growth frame holds 310 plots, of which 305 have a plot-level maximum stand density index (SDImax) from an earlier Bayesian job (log 20, line 1). The height-diameter frame is 3,331 trees on 310 plots (`pass2/09_final_pass.log`, line 1). The diameter increment frame is 5,114 remeasurement intervals (log 22t, line 3) on 97 plots in 60 installations (`repair_round/04v2_cv.log`, line 1).

The mortality frame starts from the confirmed-death frame of 7,478 tree-intervals and 1,169 deaths, in which a death on a permanent sample plot (PSP) counts only when a second dead record confirms it, and the final visit of each plot is censored. The PSP database records thinned stems as dead, so intervals that end in or span a thinning removal year of a PSP installation are censored. That removes 756 tree-intervals and 324 deaths and leaves 6,722 and 845 (log 22t, line 11). No increment interval has a removal year strictly inside it (log 22t, line 3). Benchmark horizons stop before an installation's first removal year, leaving 53 plots and 182 plot-horizons (log 23t, line 6).

## Estimators

S1 is a weighted linear regression of ln(plot SDImax) on ln(BYI) and origin. Weights are inverse squared posterior standard deviations on the log scale, with a floor (script 22t, lines 17 to 19; log 22t, line 1).

E2 is a three-parameter Chapman-Richards curve fitted by nonlinear least squares, unchanged from the November 10 job.

E4r is fitted by weighted nonlinear least squares on end-of-interval diameter. The annual equation is stepped through each interval with competition interpolated between its ends, and weights are re-estimated over three passes (script 22t, lines 23 to 28; log 22t, lines 4 to 6). E5 has no parameters.

E6r is a binomial model with a complementary log-log link and an offset for interval length, fitted by direct maximum likelihood with an analytic gradient (script 22t, lines 32 to 39). Mortality is lowest at 66.4 cm (log 22t, line 15).

Standard errors and 95% intervals for S1, E4r and E6r come from one joint bootstrap. Each of 2,000 resamples draws plots with replacement, refits S1, and refits E4r and E6r with that resample's SDImax. Resamples with a mortality gradient of 0.01 or more were dropped, leaving 1,987 (script 22t, lines 46 to 52; log 22t, line 20).

## Evaluation design

Folds are ten groups of installations, stratified by origin (`utils.R`). Equivalence tests regress observed on predicted, resample plots 2,000 times, and pass when the 90% interval of relative bias, or of slope about 1, lies within 25% (`utils.R`).

With S1 and E4r both refitted in each fold, annual diameter increment has bias 0.030 and RMSE 1.144 cm yr⁻¹ (log 22t, line 7) and slope 0.905, 0.831 to 0.983 (log 22t, line 10).

In the benchmark each plot is projected from its first visit with at least five live koa, with S1 out of fold; the other equations are fitted on all plots. RMSE is 0.124 for survival, 2.78 cm for QMD and 6.76 m² ha⁻¹ for basal area (log 23t, line 6). Equivalence results are in log 23t, lines 17 to 25.

Six gates are checked on 200-year runs from two real starting lists at three BYI levels each (script 23t, lines 39 to 49). Five pass and the Sukachev gate fails (log 23t, line 90). Basal area is never out of site order (log 23t, line 76).

The preregistered test of SDImax against BYI is script 20; the direct quantile model gives a BYI coefficient of 0.508, with a bootstrap median of 0.537 and interval 0.302 to 0.831 (log 20, lines 29 and 39). Script 25 compares SDImax treatments under the censoring rule: benchmark basal area RMSE is 6.74 m² ha⁻¹ for S1 and 6.60 for one value of 742 (log 25, lines 15 and 17), with a paired difference of 0.141, −0.083 to 0.289 (log 25, line 19). The Sukachev gate fails for every treatment (log 25, lines 33 to 35).

The reference file was checked against a separately coded loop to 2.27 × 10⁻¹³ (script 22t, lines 58 to 62; log 22t, line 44).

## Monte Carlo intervals

Each band is the 5th to 95th percentile of 500 draws (script 23t, lines 14 to 20 and 51 to 55). A draw takes one joint bootstrap row, a lognormal plot multiplier on increment (tau), lognormal tree-year variation (sigma, delta) and a gamma plot multiplier on mortality hazard (phi). The components are sigma 1.059, tau 0.409, delta 0.438 and phi 0.029 (log 22t, line 17). A second variant also lets ln(SDImax) deviate from S1 by a normal draw with the residual standard deviation of S1, 0.537 (log 22t, line 2). In the first variant 82 year-by-variable cells, all in one planted scenario, had one non-finite draw, which was left out (log 23t, line 92). The bands are in log 23t, lines 97 to 136.

Coverage is checked at each benchmark plot's longest horizon with 300 draws and binomial sampling of survivors (script 23t, lines 57 to 60). The nominal 90% band contains 89% of basal areas (47 of 53 plots), 85% of QMDs (45) and 72% of survival values (38) with SDImax at its out-of-fold prediction, and 92% (49), 87% (46) and 75% (40) when SDImax may deviate (log 23t, lines 150 to 155).

Seeds are 20261115, 20261116, 20261117, 20261118 and 20261119 for scripts 20, 21, 22t, 23t and 25.


Checks added on November 13, 2026 (scripts 28a, 28b, 29, 29b; supplement v125, Tables S27 to S31): the benchmark with every equation refitted without the plot's installation fold (RMSE 0.128, 3.08 cm, 7.13 m² ha⁻¹), held-out mortality (845 deaths against 832.3 expected, AUC 0.896), a joint bootstrap of installations (987 of 1,000 kept), E6r under three death rules, the benchmark after thinning, and S1 without the Kap plots. The 6.74 against 6.76 m² ha⁻¹ difference between scripts 25 and 23t is the fold partition (random number generator in force when folds are drawn), not the fitting start.
