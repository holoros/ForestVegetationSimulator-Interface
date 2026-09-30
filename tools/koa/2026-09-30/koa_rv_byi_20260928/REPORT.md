# Validity of the Biomass Yield Index: reviewer analyses (R1 c7, c8, c10; R2 c14)

Job ~/jobs/koa_rv_byi_20260928 on firebreather, September 28, 2026. Scripts, inputs and seeds in RUN.md. Coordinates were used on firebreather only, and everything below is aggregate.

## 0. What the pipeline actually is (read first)

The BYI pipeline is Schmoldt_Index_extraction.r (laptop ~/Documents/MAINE/DATA/Koa). It (1) computes top height H40 (the 40 largest trees per acre, about 100 per ha) and live AGB per subplot visit from FIA HI_TREE, merges with HI_COND and writes AGB.FIA.csv, (2) fits Eq. 1 in nlme with random A by COUNTYCD/PLOT and varPower on H40, and takes the conditional plot asymptote as the Schmoldt index (Schmoldt_Index_by_plot.csv), (3) merges the index onto PLT.GEO_FIA.csv (FIA plot locations with extracted predictors) with all = TRUE and sets every location without an index to 0, (4) runs VSURF and spatialRF::rf_spatial twice (BYI_srf_fit.RDS, the "Kona" model with PTYPE and GEO_YR, and BYI_srf_fit_HI.RDS, the "statewide" model with climate and soil water only), and (5) predicts BYI for the growth plots.

Six facts change how the manuscript describes BYI.

1. Both random forests were trained on Hawaii Island only. PLT.GEO_FIA.csv holds 717 FIA locations, all in COUNTYCD 1, and 582 (Kona set) or 581 (statewide set) have complete predictors. The "statewide" forest is a Hawaii Island forest without geological predictors, and the surface on Oahu, Maui County and Kauai is an extrapolation from Hawaii Island. The 104 Eq. 1 plots on those islands entered no forest.
2. The 347 zeros are not fitted values. They are FIA locations with no Eq. 1 estimate that the merge filled with 0. At their latest visit 299 were nonforest, 41 nonsampled (reason codes 2 and 3) and 7 forest, and none has a live tree record in HI_TREE. The other 235 training values are the Eq. 1 asymptotes of every Hawaii Island Eq. 1 plot.
3. The counts in [31] and [69] refer to different tables. Eq. 1 returned an asymptote for all 339 FIA plots it was fitted to. 320 is the number of rows in AK_PLT_GEO.csv (the growth-model plots), and "median 204, SD 144, near zero to 813" is the distribution of BYI in that table (reproduced exactly, median 203.6, SD 144.2, 0 to 812.8), not of the Eq. 1 plots (median 408.3, SD 217.7, 99.9 to 2,642.6).
4. Units. The data.table step sums DRYBIO_AG x TPA_UNADJ within a subplot without the x4 subplot expansion that the H40 step applies, so every AGB value in the Eq. 1 frame, and therefore BYI, is one quarter of a per-hectare quantity. Verified on 332 visits with four subplots, median plot AGB 122.5 Mg/ha against a median subplot frame value of 30.6, ratio 4.000. BYI enters the increment equations as ln(BYI), so predictions are unaffected apart from the intercept, but the unit label Mg/ha, the site classes 100/264/450 and any comparison with published biomass are off by a factor of 4. AUTHOR DECISION (relabel as index units, or multiply by 4 and refit).
5. The asymptote is an extrapolation. Recovering the archived shape from the archived plot asymptotes gives k = 0.0284 and p = 2.171, so at the median H40 of 11.3 m the curve stands at 6.0% of A and 99.0% of subplot rows lie below half the asymptote. The unbounded ML fit runs to k -> 0 and A -> infinity, and within the archived bounds (k >= 0.01) k sits on its bound in every refit. BYI is therefore identified by the plot random effect (plot biomass relative to the population curve at the plot's top height) and not by an observed approach to an asymptote.
6. The 38 FIA growth installations in AK_PLT_GEO carry a BYI that equals neither their Eq. 1 estimate (0 of 38 within 0.5, Spearman 0.86), nor the in-sample prediction of the stored Kona forest (0 of 38), nor the deposited surface at their FIA public coordinates (8 of 38 within 5 units, Spearman 0.53). The source of those values could not be determined from the files on hand, so the Fig. 2 caption sentence that fitted plots carry "the value estimated for that plot" is not supported for FIA plots and cannot be checked for non-FIA plots here.

Also, the archived nlme call does not run on nlme 3.1.170 ("Singularity in backsolve at level 0", every variant in 02a to 02c). Eq. 1 was therefore refitted in its exactly equivalent conditionally linear form (lme on f(H40; k, p) with random slopes by county and plot, varPower, ML), with (k, p) either profiled (route 2) or held at the archived shape (route 1). Route 1 reproduces the archived plot asymptotes with r = 0.980 (median ratio 0.90).

## 1. Plot counts through the pipeline (R1 c7, R2 c14)

Table S-BYI-1. Counts through the BYI pipeline.

| Stage | Count |
|---|---|
| FIA plots entering Eq. 1 | 339 (Hawaii 235, Maui County 47, Oahu 32, Kauai 25) |
| Plot visits / subplot visits | 564 (2010 and 2019 cycles) / 1,838 |
| Rows of the Eq. 1 frame | 2,312, of which 474 (20.5%) repeat a subplot visit because the HI_COND merge adds one row per condition (155 rows nonforest, 137 nonsampled conditions) |
| Plots measured twice / once | 225 / 114 |
| Plots returning a conditional asymptote | 339 (all), range 99.9 to 2,642.6, median 408.3, SD 217.7 in index units, none zero |
| FIA locations in the predictor extraction | 717, Hawaii Island only |
| Kona forest training n | 582 = 235 with an Eq. 1 asymptote + 347 zero-filled locations without one |
| Statewide forest training n | 581 = 234 + 347 (the plot at 2,642.6 removed by the < 1,500 filter) |
| Eq. 1 plots in no forest | 104 (Oahu, Maui County, Kauai) |
| Growth-model plots carrying BYI (AK_PLT_GEO) | 320, median 203.6, SD 144.2, 0 to 812.8 |

The deduplicated frame (1,838 rows) gives plot asymptotes correlated at r = 0.994 with the archived frame's (bounded route-2 refit), so the duplication changes the level of the index (median ratio 0.74 under route 2) more than its ranking.

## 2. BYI versus stocking (R1 c8a)

Method 03_stocking.R. Plot-visit stocking from HI_TREE live trees (all species, DIA >= 1 in), SDI = TPH (QMD/25.4)^1.605, relative density against the tau 0.99 koa limiting line of koa_selfthin_qr_20260927 (ln N = 11.631 - 1.4265 ln QMD), and SDI/1,453 (largest SDI on any koa plot-year, which has the same ranks as SDI). Stocking averaged over the visits that entered Eq. 1. Spearman correlations, 2,000 plot bootstrap resamples, 95% percentile intervals.

Table S-BYI-2. Spearman correlation of plot BYI with stocking.

| Plot set | n | SDI (= SDI/1,453) | Relative density (limiting line) | Stems per ha | Basal area |
|---|---|---|---|---|---|
| Eq. 1 plots, all islands (all BYI > 0) | 339 | 0.53 (0.45 to 0.60) | 0.54 (0.46 to 0.61) | 0.42 (0.33 to 0.50) | 0.51 (0.43 to 0.59) |
| Same, stocking at first measurement | 339 | 0.54 (0.46 to 0.61) | 0.55 (0.47 to 0.62) | 0.44 (0.36 to 0.52) | |
| Eq. 1 plots, Hawaii Island | 235 | 0.54 (0.45 to 0.62) | 0.53 (0.43 to 0.62) | 0.37 (0.26 to 0.47) | |
| RF training locations incl. 347 zeros (latest visit) | 582 | 0.96 (0.95 to 0.97) | 0.96 (0.95 to 0.97) | 0.95 (0.93 to 0.96) | |

Plot BYI also correlates with observed plot AGB (0.39, 0.31 to 0.48) and negatively with top height (-0.15, -0.24 to -0.05). log BYI regressed on log observed AGB and log H40 gives R2 = 0.60 (slopes +0.354 and -0.919, both P < 0.001), which is the reviewer's point in numbers, since BYI is largely plot biomass scaled up by how short the plot is. Median BYI by relative-density class is 366 (RD <= 0.15, n 77), 328 (0.15 to 0.30, 50), 391 (0.30 to 0.50, 58) and 494 (> 0.50, 154). The limiting line is fitted to koa plots and applied here to mixed-species FIA plots, which is a caveat on the relative-density column only.

Interpretation. The correlation is moderate and positive in every subset and is not an artifact of the zeros, although among the RF training locations the zeros push it to 0.96 because a zero means no trees. Per R1 c8(c), BYI should be described as a productivity index conditional on current stocking. The reviewer's further request, refitting the increment equations with BYI residualized on stocking, was not run here.

## 3. BYI temporal stability (R1 c8b)

Method 05_temporal.R. The 225 plots measured in both the 2010 and 2019 cycles. Route 1 (primary) holds the Eq. 1 shape at the archived values (k 0.0284, p 2.171) and re-estimates A (fixed + county + plot random, varPower) separately from first-measurement and second-measurement subplot rows. Route 2 profiles (k, p) freely within the archived bounds in each subset. Agreement by 2,000 plot bootstrap resamples, TOST region +/-25% of mean BYI for the mean difference and 0.75 to 1.25 for the slope of second on first (90% intervals).

Table S-BYI-3. Agreement of plot BYI estimated from the first and from the second FIA measurement (n = 225).

| Statistic | Route 1, shape fixed | Route 2, shape re-estimated |
|---|---|---|
| Mean BYI | 437.8 | 1,355.3 |
| Pearson r | 0.92 (0.83 to 0.96) | 0.92 (0.82 to 0.96) |
| Spearman r | 0.83 (0.75 to 0.89) | 0.82 (0.74 to 0.88) |
| Lin's concordance | 0.91 (0.82 to 0.96) | 0.73 (0.57 to 0.83) |
| Mean difference, second - first | +21.1 (90% 12.7 to 29.5), +4.8% | -424.3 (90% -458.8 to -392.0), -31.3% |
| TOST on mean, +/-25% | equivalent (region +/-109.4) | not shown equivalent (region +/-338.8) |
| Slope of second on first | 0.96 (90% 0.86 to 1.02), equivalent | 0.73 (90% 0.64 to 0.78), not equivalent |
| Plots within +/-25% of their own mean | 88.0% (83.6 to 92.0) | 30.7% (24.9 to 36.5) |

Against the archived index (both measurements), route 1 BYI from the first measurement alone is equivalent in mean (-33.4, 90% -41.9 to -25.2) but not in slope (0.75, 0.72 to 0.80), and from the second measurement alone equivalent in both (-12.4, and 0.79, 0.75 to 0.84).

Interpretation. With the population shape held fixed, plot BYI is repeatable across a nine-year remeasurement, but the median plot gained only 0.6 m of top height between visits, the change in BYI tracks the change in plot AGB (Spearman 0.52) and 25.3% of plots lost biomass. The test therefore shows repeatability over a short interval, not invariance across stand development, and the level of BYI depends on the shape parameters, which the data do not identify (route 2). The Growth and Yield checklist criterion is met only in the weak form.

## 4. Spatially blocked cross-validation of the random forests (R1 c10, R2 c14)

Method 04_rf_cv.R. ranger with each spatialRF object's stored arguments and predictor set (the fits carry no spatial eigenvector predictors, so plain ranger is the same model; OOB RMSE reproduced exactly). Schemes are random 10-fold, square blocks of 5, 10 and 20 km assigned to 10 folds with random grid offsets, and leave-one-region-out with 4 and 8 k-means regions of Hawaii Island, each repeated 10 times. R2 = 1 - SSE/SST within the evaluated set. Intervals are the range over the 10 repetitions and a 2,000-resample block bootstrap (95%) on the pooled predictions of the first repetition. Leave-one-island-out is impossible because both forests were trained on Hawaii Island alone, and its closest substitute is the transfer test in Section 5.

Residual autocorrelation. The FIA grid has a median nearest-neighbor distance of 3.1 km (5th percentile 1.3 km), with 2 pairs closer than 500 m and 5 closer than 1 km, so Moran's I at lags below 500 m cannot be computed. The OOB residual semivariogram is flat from the first populated band (1 to 2 km) outward, near the total variance, so no range is detectable beyond the grid spacing. Distance-band Moran's I (Kona forest) was -0.21 (P = 0.12) at 1 to 2 km, +0.076 (P = 0.042) at 4 to 5 km, -0.063 (P = 0.022) at 5 to 7.5 km and not significant in any band from 7.5 to 200 km (Table S-BYI-5). The spatialRF "distance thresholds" of 5, 10 and 100 m reported with the fit are lower cut-offs of inverse-distance weights over all pairs, not lags, and at those thresholds the Kona residual Moran's I was -0.008 (P = 0.030), so the sentence "non-significant at every lag of 500 m or more" misreads that output. Blocks of 10 and 20 km exceed any structure detectable here.

Table S-BYI-4. Cross-validated performance of the two BYI forests (mean over 10 repetitions, repetition range, block bootstrap 95% interval for the first repetition).

| Forest | Scheme | All plots R2 | All plots RMSE | BYI > 0 R2 | BYI > 0 RMSE | BYI > 0 bias |
|---|---|---|---|---|---|---|
| Kona (n 582, 235 > 0) | Out of bag | 0.300 | 219 | -0.48 | 281 | -153 |
| | Random 10-fold | 0.299 (0.28 to 0.32; 0.21 to 0.40) | 219 (188 to 260) | -0.48 | 282 | -153 |
| | Blocks 5 km | 0.297 (0.28 to 0.33; 0.23 to 0.36) | 220 (190 to 258) | -0.49 | 282 | -155 |
| | Blocks 10 km | 0.270 (0.23 to 0.32; 0.14 to 0.37) | 224 (185 to 275) | -0.56 (-1.24 to -0.41) | 289 | -160 |
| | Blocks 20 km | 0.246 (0.22 to 0.30; 0.10 to 0.37) | 227 (185 to 275) | -0.58 (-1.16 to -0.37) | 290 | -159 |
| | Leave one of 4 regions out | 0.141 (0.14 to 0.15; 0.08 to 0.22) | 243 (189 to 293) | -0.53 | 286 | -141 |
| | Leave one of 8 regions out | 0.209 (0.19 to 0.22; 0.11 to 0.28) | 233 (191 to 280) | -0.56 | 289 | -161 |
| Kona, trained on BYI > 0 only | Out of bag | | | 0.114 | 218 | +4 |
| | Blocks 10 km | | | 0.083 (0.04 to 0.14) | 221 | +5 |
| | Blocks 20 km | | | 0.027 (-0.10 to 0.09) | 228 | +9 |
| Statewide (n 581, 234 > 0) | Out of bag | 0.326 | 198 | -0.85 | 247 | -151 |
| | Blocks 10 km | 0.299 (0.27 to 0.32; 0.13 to 0.35) | 202 (180 to 234) | -0.89 | 250 | -157 |
| | Blocks 20 km | 0.259 (0.22 to 0.30; 0.21 to 0.37) | 208 (171 to 232) | -0.99 | 256 | -156 |
| | Leave one of 4 regions out | 0.065 (0.05 to 0.08; -0.06 to 0.21) | 233 (193 to 262) | -1.07 | 261 | -122 |
| Statewide, trained on BYI > 0 only | Out of bag | | | 0.174 | 165 | +1 |
| | Blocks 20 km | | | 0.103 (-0.04 to 0.21) | 172 | +4 |

(Negative R2 on the BYI > 0 subset means the predictions are worse than that subset's own mean, because the forests, trained with 60% zeros, predict forested plots about 150 units too low.)

Interpretation. Blocking lowers the pooled R2 only modestly (0.300 to 0.27 at 10 km and 0.25 at 20 km, and to 0.14 when a quarter of the island is withheld), so the out-of-bag figure is not badly inflated by autocorrelation. The pooled R2, however, measures the separation of forest from nonforest locations. Among the plots that carry an asymptote the forests have no skill as trained, and a forest trained on those plots alone explains 3% to 18% of the variation under blocking.

## 5. Transfer of the deposited surface to other islands (substitute for leave-one-island-out)

Method 06_assign_transfer.R. BYI_all.tif (md5 6c926adc) read with gdallocationinfo at the FIA public (perturbed) coordinates of the Eq. 1 plots, compared with their plot asymptotes, 2,000 bootstrap resamples.

Table S-BYI-5a. Deposited surface against plot BYI.

| Island | n | Median plot BYI | Median surface | R2 | RMSE | Bias | Spearman |
|---|---|---|---|---|---|---|---|
| Hawaii (training island) | 235 | 405 | 271 | -0.33 (-0.92 to -0.09) | 267 (204 to 348) | -150 (-179 to -123) | 0.48 (0.37 to 0.59) |
| Oahu | 30 (2 off the surface) | 384 | 116 | -3.60 | 326 | -280 | 0.14 (-0.20 to 0.47) |
| Maui County | 47 | 443 | 118 | -2.67 | 386 | -309 | 0.09 (-0.21 to 0.37) |
| Kauai | 25 | 417 | 117 | -3.58 | 370 | -317 | 0.10 (-0.30 to 0.49) |
| Other islands pooled | 102 | 409 | 117 | -2.96 (-4.50 to -2.09) | 365 (322 to 411) | -302 (-344 to -264) | 0.13 (-0.07 to 0.31) |

Table S-BYI-5b. Moran's I of OOB residuals by distance band (Kona forest; statewide in 04 log). Pairs 2 (0 to 0.5 km), 3 (0.5 to 1), 54 (1 to 2), 96 (2 to 3), 210 (3 to 4), 560 (4 to 5), 1,483 (5 to 7.5), 2,079 (7.5 to 10), then more than 5,000 per band. I = n/a, n/a, -0.211 (P 0.12), -0.153 (0.10), +0.068 (0.33), +0.076 (0.04), -0.063 (0.02), +0.013 (0.49), and |I| <= 0.021 with P >= 0.13 in every band from 10 to 200 km. The statewide forest gives -0.406 (P 0.014) at 1 to 2 km on 53 pairs and +0.130 (P 0.002) at 4 to 5 km.

Interpretation. On the other islands the surface is a near-constant low value (median 117 against 409) with no rank agreement, so it carries no information about the relative productivity of Oahu, Maui or Kauai FIA plots. Even on Hawaii Island the surface ranks forested plots only moderately and sits 150 units low. The perturbation of public FIA coordinates (up to about 1.6 km) adds noise to this test and would weaken, not create, rank agreement at the 30 m scale.

## 6. Proposed drop-in text

Numbers below are in the index units of the archived pipeline. If Aaron decides to rescale by 4 (item 0.4), every BYI value, interval and RMSE scales by 4 and R2 and correlations do not change.

### Supplement text (new Supplemental Section, "Validity of the Biomass Yield Index", about 430 words)

We tested three properties of BYI that a site index should have, namely a documented sample, independence from current stocking, and invariance to the measurement used to estimate it, and we evaluated the mapped surface by spatial cross-validation. Eq. 1 was fitted to 2,312 subplot measurements on 339 FIA plots, 235 on Hawaii Island and 104 on Oahu, Maui County and Kauai, and every plot received a conditional asymptote (median 408, range 100 to 2,643 in index units, Table S-BYI-1). Predictor layers were assembled for Hawaii Island only, so both random forests were trained on the 582 Hawaii Island FIA locations with complete predictors, 235 carrying an asymptote and 347 nonforest or unsampled locations with no live trees, which were assigned zero. The statewide forest differs from the Kona forest only by omitting the geological predictors, and its values on the other islands are an extrapolation.

Plot BYI rose with stocking (Spearman correlation with stand density index 0.53, 95% bootstrap interval 0.45 to 0.60, and with relative density on the koa limiting line 0.54, 0.46 to 0.61, Table S-BYI-2), and plot biomass and top height together explained 60% of the variation in log BYI. The shape of Eq. 1 places the median plot at 6% of its asymptote, so the asymptote is an extrapolation of current biomass rather than an observed capacity. Estimated separately from the 2010 and the 2019 measurements of the 225 plots measured twice, with the shape held at the pooled estimate, plot BYI was equivalent between measurements in mean (difference +21, 90% interval 13 to 29, against a region of ±109) and in slope (0.96, 0.86 to 1.02), but top height changed by only 0.6 m in the median plot, and with the shape re-estimated in each subset the two measurements differed by 31% (Table S-BYI-3).

Blocked cross-validation lowered the pooled R2 of the Kona forest from 0.300 out of bag to 0.270 and 0.246 at 10 and 20 km blocks and to 0.141 when a quarter of the island was withheld (Table S-BYI-4). Residual semivariance was flat beyond the 1 to 2 km band and Moran's I was not significant beyond 7.5 km, but the FIA grid holds only two plot pairs closer than 500 m, so autocorrelation below that distance cannot be assessed. On the 235 plots with a nonzero asymptote the forest predicted about 155 index units too low and explained none of the variation among plots, and a forest trained on those plots alone reached R2 of 0.03 to 0.08 under blocking. At the FIA plots of the other islands the deposited surface bore no rank relation to plot BYI (Spearman 0.13, −0.07 to 0.31, Table S-BYI-5).

BYI is therefore a productivity index conditional on current stocking, and the surface separates forest from nonforest and assigns coarse productivity classes on Hawaii Island rather than predicting plot productivity.


### Main text, Section 2.3 [31]

Replaces "using the 582 plots in the deposited modeling subset that supported a plot-level asymptote."
> using 2,312 subplot measurements on 339 plots, 235 of them on Hawaii Island, of which 225 were measured in both the 2010 and 2019 inventories.

Add to [33], after "two spatial random forest models were developed (Breiman, 2001)."
> Both forests were trained on the 582 Hawaii Island FIA locations with complete predictors, 235 carrying a plot asymptote and 347 nonforest or unsampled locations without live trees that were assigned a BYI of zero, so the surface on the other islands is an extrapolation from Hawaii Island.

### Main text, Section 3.2 [69]

Replaces "The Chapman–Richards mixed-effects model converged for 320 plots and gave plot-level BYI from near zero on young lava substrates to 813 Mg ha−1 on the most productive sites (median 204 Mg ha−1, SD 144)." and "with residual Moran’s I non-significant at every lag of 500 m or more."
> Eq. 1 returned a conditional asymptote for all 339 plots (median 408, SD 218), and the values carried by the 320 growth-model plots range from 0 to 813 (median 204). [...] Under spatial blocks of 10 and 20 km the out-of-bag R^2^ of 0.300 fell to 0.270 and 0.246, but on the 235 plots with a nonzero asymptote the forest predicted about 155 units too low and explained none of their variation, so its skill lies in separating forest from nonforest locations (Supplemental Table S-BYI-4).

### Main text, Section 4.2 [88]

Replaces "Consequently, the mapped surface is best interpreted as a site class assignment, as the gap between out-of-bag and training fit (R^2^ of 0.300 against 0.885) indicates,"
> Plot BYI rises with stand density index (Spearman correlation 0.53, 0.45 to 0.60) and was repeatable between two inventories nine years apart only when the curve shape was held fixed, so BYI is best read as a productivity index conditional on current stocking rather than as a site index. The mapped surface separates forest from nonforest and assigns coarse site classes on Hawaii Island, with little skill among forested plots and none on the other islands (Supplemental Section S-BYI), and a covariate measured with that much error

(the sentence then continues "attenuates its own coefficient, so the site response ...").

### Other text that the results contradict
- Supplement Table S6 caption, replace "(Kona model n = 582, statewide model n = 581, each including 347 observations with a BYI of zero)" with "(both models trained on Hawaii Island FIA locations, Kona model n = 582 and statewide model n = 581, each including 347 nonforest or unsampled locations without live trees assigned a BYI of zero)".
- Section 2.3 [33] "Because geological predictors were available only for Hawaii Island" is true but incomplete, since no predictor was extracted off Hawaii Island for training.
- Fig. 2 caption, "Plot-level BYI entering the fitted equations is the value estimated for that plot rather than a value read from this surface." Not supported for the 38 FIA growth installations (item 0.6). Aaron needs to trace where AK_PLT_GEO BYI came from before this sentence stays.
- Section 1 [21] "long-term asymptotic biomass capacity" and Section 4.5 [96] both need to follow R1 c9 in light of item 0.5.
- Units "Mg ha^-1^" for BYI throughout, pending item 0.4.

## 7. Items not done or not determinable
- Leave-one-island-out CV is impossible because the training set is one island. Section 5 is the substitute.
- Moran's I below 500 m is not computable (2 pairs).
- The archived nlme fit cannot be rerun on this host's nlme. Route 1 reproduces its plot values at r = 0.98 and was used instead.
- The increment refits with BYI residualized on stocking (R1 c8a, second request) were not run.
- The origin of the AK_PLT_GEO BYI values for FIA and non-FIA growth plots was not determined.
