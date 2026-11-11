# Koa: maximum SDI as a function of BYI, the test, the red team, and the system adopted (November 11, 2026)

**Superseded in part (November 11, 2026, later the same day).** The mortality frame and benchmark behind this note counted PSP thinning removals as deaths. Its account of the test of SDImax against BYI (Sections 2 and 3) stands, with the benchmark comparisons replaced by log 25; every mortality coefficient, benchmark error, projection, band and coverage figure here is replaced by `2026-11-11_koa-final-system_REVIEW.md`.

Rules written first: `2026-11-11_koa-sdimax-byi_PREREG.md`. Evidence: `tools/2026-11-10_final-equations/rdbyi_server` (logs and scripts 20 to 23, `koa_rdbyi_equations.csv`, `koa_step_rdbyi.R`, `out/`, `workbook/`, Figs. 3 to 5). This note supersedes the system described in `2026-11-10_koa-rd-framework_REVIEW.md` and `2026-11-10_koa-rd-framework-final_REVIEW.md`; what those notes say about the data, the record length and the carbon assumptions still stands.

## 1. Outcome in one paragraph

By the rule written before the run, SDImax as a function of BYI is not adopted: it does not predict the remeasured plots better than one value. Aaron chose it anyway (question tool, November 11), with the equations refitted to it, and that choice is defensible on a different ground than the one tested: it makes the system consistent between fitting and use, lets the ceiling vary with site, and passes every 200-year gate including site ordering to 100 years, which the previous system failed. Most of that gain comes from refitting the equations with the SDImax they are applied with: one value with the equations refitted to it passes the same gates with a slightly lower benchmark error (10.54). The deviation from the rule is logged here. The cost is that the site effect on SDImax is weakly identified and the origin effect may be stocking and age more than capacity, which has not been tested.

## 2. What the test showed (logs 20 and 21)

Of 310 growth plots, 305 have a brms SDImax (162 natural, 143 planted); 195 of them have one visit in the brms frame.

**Table 1.** The three criteria of the rule.

| Criterion | Result | Evidence |
|:---:|:---:|:---:|
| BYI coefficient in the direct quantile model excludes zero | Pass | 0.54 (0.30 to 0.83), 300 plot-cluster resamples |
| Benchmark basal area RMSE at least 5% below 742 | Fail | 10.74 refitted (11.22 unrefitted) against 10.76 for 742, and 10.54 for 742 with the equations refitted at 742 |
| Every gate that passes with 742 still passes | Pass | All six pass |

The second-stage regression of ln(plot SDImax) on ln(BYI) and origin, held out by installation, explains 0.136 of the variance; origin alone explains 0.113 and BYI alone −0.031. The BYI coefficient is 0.268 (SE 0.054) weighted by posterior precision, −0.016 (0.048) unweighted, 0.075 (0.056) without the FIA plots and 0.692 (0.124) among the 110 plots with more than one visit. In the direct model fitted by origin it is −0.03 for natural plots and 0.50 for planted plots, where the fitted size-density slope is −0.52, which is not a self-thinning line.

Three follow-up checks (log 21) explain why plot-level values cannot be reached. Plot SDImax restates the plot's own largest density in the brms frame (r = 0.975 for plots with more than one row), so the benchmark gain from "each plot's own SDImax" (6.70) is partly circular. For the FIA and Kap plots, plot SDImax is weakly related to the largest koa SDI of the growth frame (r = 0.23 and 0.18, against 0.68 to 0.86 for the other sources), which suggests that the density behind SDImax and the koa SDI used as the numerator of RD are on different bases for those plots; the cause was not traced. And the residuals of the one-value system do not ask for a site-varying SDImax: ln(observed over projected basal area) on ln(BYI) gives −0.30 (SE 0.23), R² 0.03. Paired plot bootstrap intervals on the differences in basal area RMSE among the applicable systems all include zero (f(BYI, origin) minus 742 refitted: +0.20, −0.02 to +0.40); only each plot's own SDImax is distinguishable (−3.84, −5.97 to −1.61).

## 3. What the red team added

A fresh agent reviewed the rule, script and log without being told the conclusion. Its points that change how the result should be read: in the mortality equation an SDImax of the form exp(a + b ln BYI + c planted) is collinear with the intercept, ln(BYI) and origin terms apart from a numerical guard on small RD, so after refitting the mortality predictions are nearly identical (AIC 4,594.8 to 4,597.3 across candidates) and the choice acts almost only through the competition term of the increment equation; the benchmark (55 plots, 259 of 290 plot-horizons planted, most horizons short) cannot arbitrate between candidates; the weights of the second stage carry no between-plot variance, which is why weighted and unweighted coefficients differ; the bootstrap resamples plots, not installations, so the interval on a site variable is too narrow; and the clearest result in the log is that refitting the equations with the SDImax they are applied with restores site ordering to 100 years, whichever SDImax model is used. Its recommendation was one value with the equations refitted to it.

## 4. The adopted system (script 22)

S1: SDImax = exp(s0 + s1 ln(BYI) + s2 planted). E4r and E6r as before, with RD = SDI of live koa over the S1 value. Height unchanged. Coefficients are in `koa_rdbyi_equations.csv`; `koa_step_rdbyi.R` reads them, computes SDImax from BYI and origin, accepts a local SDImax in its place, and matches a separately coded loop (sharing the stand, BAL and height functions) to 3 × 10⁻¹².

**Table 2.** Estimates with standard errors and 95% intervals from a joint plot-cluster bootstrap in which each of 2,000 resamples refits S1 and then both equations with that resample's SDImax (1,936 kept; 64 dropped on the mortality gradient).

| Equation | Term | Estimate | SE | 95% interval |
|:---:|:---:|:---:|:---:|:---:|
| S1 | Intercept | 5.645 | 0.375 | 4.918 to 6.358 |
| S1 | ln(BYI) | 0.268 | 0.070 | 0.133 to 0.399 |
| S1 | Planted | −0.565 | 0.076 | −0.716 to −0.419 |
| E4r | Intercept | −3.344 | 0.772 | −4.316 to −1.461 |
| E4r | ln(DBH + 1) | 0.259 | 0.097 | 0.088 to 0.476 |
| E4r | DBH | −0.0288 | 0.0076 | −0.0449 to −0.0154 |
| E4r | (BAL/BA) × RD | −2.193 | 0.226 | −2.647 to −1.772 |
| E4r | ln(BYI) | 0.517 | 0.132 | 0.190 to 0.671 |
| E4r | Planted | 1.305 | 0.069 | 1.168 to 1.439 |
| E6r | Intercept | −3.511 | 2.597 | −5.549 to 4.030 |
| E6r | ln(DBH + 1) | 0.299 | 0.315 | −0.484 to 0.766 |
| E6r | DBH | −0.1647 | 0.0493 | −0.2360 to −0.0351 |
| E6r | DBH² | 0.00115 | 0.00093 | −0.00156 to 0.00229 |
| E6r | BAL | 0.0127 | 0.0114 | −0.0115 to 0.0334 |
| E6r | ln(RD) | 0.986 | 0.271 | 0.520 to 1.591 |
| E6r | ln(BYI) | 0.424 | 0.440 | −0.817 to 0.830 |
| E6r | Planted | 0.226 | 0.272 | −0.428 to 0.639 |

The response of mortality to RD and the competition term in increment have the expected sign in every resample. The DBH² term is positive in 90.6% of resamples, so the late decline of planted stands remains likely and not established; lowest mortality is at 70 cm. In mortality, the intervals for ln(BYI), origin, ln(DBH + 1) and BAL include zero. SDImax from S1 (evaluated at round BYI values; the scenarios in Table 3 use the exact percentiles, hence 863 and 581 there) is 862 (706 to 1,029), 1,238 (1,110 to 1,370) and 1,394 (1,216 to 1,584) for natural stands at BYI 64, 248 and 386, and 579 (498 to 668), 621 (546 to 700) and 746 (661 to 828) for planted stands at BYI 120, 156 and 309. The plot values scatter about S1 with a standard deviation of 0.54 on the log scale.

Held out by installation with S1 and E4r both refitted in each fold, annual diameter increment has bias 0.030 and RMSE 1.144 cm yr⁻¹ (1.132 with plot values, 1.146 with 742) and passes both equivalence tests (slope 0.905, 0.831 to 0.983). Interval components: sigma 1.059, delta 0.438, tau 0.409, phi 0.053.

## 5. Tests of the adopted system (script 23)

Benchmark with S1 out of fold (the growth and mortality equations are fitted on all plots, including the 55 benchmark plots): survival RMSE 0.216, QMD 4.06 cm, basal area 10.74 m² ha⁻¹ (bias +0.28); planted 10.64, natural 11.52; horizons of 10 years or more 13.32. At each plot's longest horizon the pooled set passes both equivalence tests for survival and the intercept test for QMD; basal area fails on intercept and slope (slope 0.66, 0.46 to 0.88), and natural plots fail on everything but the QMD intercept.

Two-hundred-year runs on the two real starting lists pass all six gates. Natural basal area is ordered by site throughout; planted basal area is first out of order at year 120. Natural stands settle at an RD of 0.56 to 0.64 and planted stands reach 1.06 to 1.07 before declining, so the fitted SDImax is not a common frontier for the two origins.

**Table 3.** Basal area (m² ha⁻¹): point projection with 90% Monte Carlo band (500 draws of a joint bootstrap row, plot increment multiplier, tree-year variation and plot mortality multiplier), without and with a plot-level deviation of SDImax about S1.

| Origin | BYI | SDImax | 40 yr | 100 yr | 100 yr, SDImax allowed to deviate |
|:---:|:---:|:---:|:---:|:---:|:---:|
| Natural | 64 | 863 | 23.9 (11.3 to 36.8) | 28.9 (12.3 to 46.9) | 28.9 (8.4 to 64.8) |
| Natural | 248 | 1,238 | 38.3 (20.8 to 57.3) | 50.9 (24.0 to 75.6) | 50.9 (17.8 to 110.1) |
| Natural | 386 | 1,394 | 45.9 (25.7 to 64.8) | 60.8 (30.3 to 89.0) | 60.8 (21.5 to 131.6) |
| Planted | 121 | 581 | 34.8 (18.0 to 52.1) | 46.0 (18.3 to 64.8) | 46.0 (12.6 to 88.7) |
| Planted | 156 | 621 | 39.2 (20.0 to 56.2) | 49.2 (18.8 to 69.1) | 49.2 (12.7 to 99.4) |
| Planted | 309 | 746 | 53.0 (29.0 to 73.2) | 54.0 (12.8 to 92.8) | 54.0 (8.9 to 117.5) |

The Monte Carlo median is below the point projection at 100 years in every row (planted, BYI 156: 42.5 against 49.2). In the deviation variant one draw per cell became non-finite late in two planted scenarios and was dropped from the percentiles (218 year-by-variable cells). Coverage at each plot's longest horizon, by 300 draws with binomial sampling of survivors added (so the bands of Table 3 would cover no more than this; S1 is out of fold in the first variant only): basal area 76%, QMD 82%, survival 64% with SDImax at its out-of-fold prediction (basal area 68% at horizons of 10 years or more); 86%, 82% and 78% when SDImax is allowed to deviate. Natural-plot survival is covered 54% and 69% of the time. Three survival observations sit exactly on a band limit and are counted outside; counted inside, survival coverage is 67% and 80%. The wider band is the honest one for a new stand, and it is still short of nominal for all three variables.

Other quantities for the text: diameter growth at the 90th against the 10th percentile of BYI at fixed RD is 2.52 times for natural plots (1.40 to 3.32) and 1.62 for planted (1.19 to 1.87); planted over natural at the same size, competition, RD and BYI is 3.69 times for diameter growth (3.21 to 4.22) and 1.25 for mortality hazard (0.65 to 1.90); planted SDImax is 0.57 of natural (0.49 to 0.66).

## 6. Workbook

`submission/2026-11-11_koa-yield-curves-for-financial-model_DRAFT.xlsx` is rebuilt from this system and replaces the November 10 draft. SDImax for the four site classes is 825, 765, 689 and 579. Basal area at age 40 runs from 125 to 282 ft² ac⁻¹; site ordering holds through ages 79 to 98 depending on density, against 53 to 68 in the November 10 draft; peak basal area falls between ages 55 and 125. The ninth sheet shows the 10th and 90th percentile of planted plots about S1 (0.50 and 1.50 times). The classes at BYI 340 and 450 are above the 90th percentile of planted plots (309), so their SDImax is extrapolated.

## 7. What this does and does not settle

The system is now internally consistent, bounded and ordered by site to 100 years on the measured starting lists (to ages 79 to 98 in the workbook grid, depending on density), and its inputs are only BYI, origin and a tree list. It does not predict remeasured plots better than a single SDImax, and the two parameters that make SDImax vary are the least secure in the system: the BYI slope depends on the weighting, and the origin term means a planted stand is given 57% of the ceiling of a natural stand on the same site, which the data cannot separate from the youth and wide spacing of the planted plots. A user with a local density record should supply SDImax directly.

## 8. Open

BYI and origin inside the brms frontier model, which is the principled version of S1 (hours of sampling; the frequentist analogue was unstable); stand age or initial stocking in S1 to test the origin term; resampling installations in the bootstrap; the koa volume and biomass equations; the v133 text.
