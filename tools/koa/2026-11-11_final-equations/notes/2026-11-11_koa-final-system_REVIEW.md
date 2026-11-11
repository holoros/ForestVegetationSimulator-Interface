# Koa final system with PSP thinning removals censored (November 11, 2026)

This note is the source of truth for the manuscript, supplement, workbook and deposit. It supersedes the numbers in `2026-11-11_koa-sdimax-byi_REVIEW.md` wherever they involve mortality, the benchmark, projections, intervals or coverage. The equations and the choice of system are unchanged: S1 (SDImax from BYI and origin), E2, E4r, E5, E6r. Evidence: `tools/2026-11-10_final-equations/rdbyi2_server` (logs 22t, 23t, 24b, 25 and their scripts; `koa_rdbyi_equations.csv`; `out/`; `workbook/`; Figs. 3 to 5).

## 1. The defect

Twenty-seven of the 32 PSP installations were thinned, and the PSP database records each thinned stem as dead. The earlier versions of this work censored the intervals that end in or span a removal year, using `psp_origin_thinning_2026-09-16_DATA.csv`. The frames built on November 10 did not apply that table, so every fit and benchmark from November 10 and the morning of November 11 counted thinning removals as deaths. In the mortality frame, 756 of 7,478 tree-intervals and 324 of 1,169 deaths fall in removal intervals (log 22t); on planted PSP plots the annual death rate is 27% in removal intervals and 2.1% in the others, and 307 of 417 planted PSP deaths are in removal intervals (log 24b). The supplement builder flagged the problem when comparing the new frame description with v123.

## 2. The correction

Mortality intervals that end in or span a removal year are censored (6,722 tree-intervals and 845 deaths remain). No diameter increment interval has a removal year strictly inside it, so E4r and S1 are unchanged. Benchmark horizons of a thinned installation stop before its first removal year, which leaves 53 plots (41 planted, 12 natural) and 182 plot-horizons; seven plots have a horizon of 10 years or more, the longest planted record is 52 years in one plot and the longest natural record 33 years.

## 3. Coefficients (joint plot-cluster bootstrap, 2,000 resamples, 1,987 kept)

| Equation | Term | Estimate | SE | 95% interval |
|:---:|:---:|:---:|:---:|:---:|
| S1 | Intercept | 5.645 | 0.372 | 4.919 to 6.349 |
| S1 | ln(BYI) | 0.268 | 0.0691 | 0.135 to 0.399 |
| S1 | Planted | −0.565 | 0.0755 | −0.716 to −0.418 |
| E4r | Intercept | −3.344 | 0.768 | −4.315 to −1.472 |
| E4r | ln(DBH + 1) | 0.259 | 0.0967 | 0.0879 to 0.475 |
| E4r | DBH | −0.0288 | 0.00753 | −0.0449 to −0.0154 |
| E4r | (BAL/BA) × RD | −2.193 | 0.226 | −2.649 to −1.772 |
| E4r | ln(BYI) | 0.517 | 0.131 | 0.194 to 0.671 |
| E4r | Planted | 1.305 | 0.0692 | 1.167 to 1.438 |
| E6r | Intercept | 0.340 | 2.426 | −2.181 to 7.490 |
| E6r | ln(DBH + 1) | −0.870 | 0.285 | −1.480 to −0.362 |
| E6r | DBH | −0.0237 | 0.0383 | −0.0853 to 0.0668 |
| E6r | DBH² | 0.00028 | 0.00063 | −0.00164 to 0.00107 |
| E6r | BAL | 0.0341 | 0.0100 | 0.0176 to 0.0565 |
| E6r | ln(RD) | 0.745 | 0.201 | 0.354 to 1.124 |
| E6r | ln(BYI) | −0.117 | 0.403 | −1.345 to 0.315 |
| E6r | Planted | −1.050 | 0.252 | −1.605 to −0.610 |

Mortality now falls with ln(DBH + 1), rises with BAL and with RD (positive in every resample), and is lower in planted than in natural stands at the same size, competition, RD and BYI (hazard ratio 0.35, 0.20 to 0.54; it was above 1 before the correction). The DBH² term is positive in 77.6% of resamples and its interval includes zero, as do those of the intercept, DBH and ln(BYI); lowest mortality is at 66 cm. Interval components: sigma 1.059, delta 0.438, tau 0.409, phi 0.029. Planted over natural diameter growth is 3.69 times (3.21 to 4.21); diameter growth at the 90th against the 10th percentile of BYI at fixed RD is 2.52 times for natural plots (1.41 to 3.33) and 1.62 for planted (1.20 to 1.87); planted SDImax is 0.57 of natural (0.49 to 0.66). SDImax from S1: natural 862 (706 to 1,029), 1,238 (1,109 to 1,370) and 1,394 (1,216 to 1,584) at BYI 64, 248 and 386; planted 579 (498 to 668), 621 (546 to 701) and 746 (661 to 828) at BYI 120, 156 and 309. Held-out diameter increment is unchanged (bias 0.030, RMSE 1.144 cm yr⁻¹, slope 0.905). The reference file matches a separately coded loop to 2 × 10⁻¹³.

## 4. Benchmark (S1 out of fold; equations fitted on all plots)

Survival RMSE 0.124 (bias −0.023), QMD 2.78 cm (bias +0.54), basal area 6.76 m² ha⁻¹ (bias +0.81). Planted plots: 0.113, 2.59 cm, 5.79 m² ha⁻¹. Natural plots: 0.176, 3.71 cm, 10.78 m² ha⁻¹ (bias −2.27). Horizons of 10 years or more (22 plot-horizons, 7 plots): 0.122, 3.57 cm, 7.93 m² ha⁻¹. At each plot's longest horizon, with a 25% region: pooled, QMD passes on intercept and slope, survival and basal area pass on the intercept and fail on the slope (0.87, 0.67 to 1.01; 0.82, 0.57 to 1.09); planted, QMD passes both, survival and basal area pass on the intercept only (basal area slope 1.19, 0.93 to 1.44); natural plots fail except the QMD intercept.

Against the alternatives under the same censoring (log 25): one SDImax of 742 with the equations refitted gives 0.123, 2.80 cm and 6.60 m² ha⁻¹; the origin mean 0.123, 2.90 and 6.77; S1 0.123, 2.79 and 6.74 (script 25; 6.76 in script 23, which differs only in the fitting start); each plot's own SDImax 0.117, 2.55 and 5.27. The paired bootstrap difference in basal area RMSE between S1 and one value is +0.14 (−0.08 to +0.29), so the rule written before the test still does not prefer S1 on prediction; S1 has a lower QMD error than the origin mean (−0.10, −0.18 to −0.04).

## 5. Long-run behaviour (200 years, measured starting lists)

Five of the six gates pass: site ordering of basal area and QMD to 100 years (basal area is never out of site order in 200 years for either origin), the SDI limit, the basal area bound at 200 years, no rise in SDI between years 150 and 200, and yield against density. The Sukachev gate fails: stems at 40 and 100 years are not lower on better sites in natural stands (306, 350 and 348 ha⁻¹ at 40 years at low, median and high BYI; planted stands are ordered, 271, 267 and 247), because mortality no longer rises with BYI once removals are censored. The same gate fails for one SDImax and for the origin mean (log 25). Natural stands lose basal area from the start at low BYI (28.8 at year 0, 14.1 at 100 years) and peak at 46 to 50 years at median and high BYI; planted stands peak at 51 to 71 years (39 to 55 m² ha⁻¹) and decline, with RD reaching 1.02 to 1.09.

**Table 3.** Basal area (m² ha⁻¹): point projection with 90% Monte Carlo band, without and with a plot-level deviation of SDImax about S1.

| Origin | BYI | SDImax | 40 yr | 100 yr | 100 yr, SDImax allowed to deviate |
|:---:|:---:|:---:|:---:|:---:|:---:|
| Natural | 64 | 863 | 15.2 (4.5 to 24.9) | 14.1 (3.7 to 25.6) | 14.1 (4.3 to 36.1) |
| Natural | 248 | 1,238 | 29.9 (19.0 to 41.2) | 28.6 (14.2 to 43.8) | 28.6 (11.2 to 53.1) |
| Natural | 386 | 1,394 | 36.9 (24.7 to 49.3) | 34.3 (19.0 to 54.5) | 34.3 (13.7 to 61.1) |
| Planted | 121 | 581 | 36.5 (21.0 to 49.4) | 38.1 (19.0 to 60.5) | 38.1 (13.1 to 69.3) |
| Planted | 156 | 621 | 41.1 (24.8 to 54.0) | 41.4 (20.1 to 64.2) | 41.4 (14.9 to 72.9) |
| Planted | 309 | 746 | 54.8 (35.4 to 71.3) | 49.7 (21.5 to 86.8) | 49.7 (18.2 to 105.7) |

The Monte Carlo median is below the point at 100 years in every row (planted, BYI 156: 37.0 against 41.4). Coverage of the bands at each plot's longest horizon (300 draws, binomial sampling of survivors added, S1 out of fold in the first variant only): basal area 89% (47 of 53), QMD 85%, survival 72%; with SDImax allowed to deviate 92%, 87% and 75%. By origin in the first variant: planted 93%, 90% and 76%; natural 75%, 67% and 58%.

## 6. Table 4 values for the manuscript (SDImax at its S1 prediction; 5th to 95th percentile of 500 draws)

| Origin | BYI (Mg ha⁻¹) | SDImax | Year | BA (m² ha⁻¹) | QMD (cm) | Stems (ha⁻¹) | Height (m) | Volume (m³ ha⁻¹), assumed ratio | RD |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Natural | 64 | 863 | 20 | 16.7 (5.7 to 25.1) | 19.5 (17.3 to 25.4) | 556 (128 to 766) | 10.8 (10.0 to 12.7) | 72 (30 to 123) | 0.42 (0.13 to 0.60) |
| Natural | 64 | 863 | 40 | 15.2 (4.5 to 24.9) | 25.1 (21.0 to 35.8) | 306 (66 to 449) | 12.5 (11.4 to 14.8) | 76 (27 to 141) | 0.35 (0.09 to 0.51) |
| Natural | 64 | 863 | 100 | 14.1 (3.7 to 25.6) | 39.2 (30.8 to 56.8) | 117 (19 to 192) | 15.2 (13.9 to 17.0) | 86 (24 to 171) | 0.27 (0.06 to 0.47) |
| Natural | 248 | 1238 | 20 | 29.2 (20.3 to 40.2) | 23.8 (19.6 to 30.7) | 657 (446 to 832) | 12.3 (11.0 to 14.2) | 144 (93 to 223) | 0.48 (0.34 to 0.61) |
| Natural | 248 | 1238 | 40 | 29.9 (19.0 to 41.2) | 33.0 (25.7 to 44.4) | 350 (212 to 473) | 14.4 (12.8 to 16.2) | 172 (100 to 259) | 0.43 (0.28 to 0.56) |
| Natural | 248 | 1238 | 100 | 28.6 (14.2 to 43.8) | 53.7 (39.4 to 71.1) | 126 (58 to 202) | 16.7 (15.5 to 17.7) | 191 (94 to 295) | 0.34 (0.17 to 0.51) |
| Natural | 386 | 1394 | 20 | 35.5 (25.3 to 46.8) | 25.9 (20.3 to 32.7) | 671 (497 to 854) | 12.9 (11.3 to 14.5) | 184 (116 to 270) | 0.50 (0.37 to 0.62) |
| Natural | 386 | 1394 | 40 | 36.9 (24.7 to 49.3) | 36.7 (27.2 to 47.2) | 348 (224 to 482) | 15.0 (13.3 to 16.4) | 222 (135 to 315) | 0.45 (0.31 to 0.57) |
| Natural | 386 | 1394 | 100 | 34.3 (19.0 to 54.5) | 59.9 (42.8 to 76.0) | 122 (58 to 217) | 17.0 (15.9 to 18.0) | 234 (127 to 378) | 0.35 (0.19 to 0.55) |
| Planted | 121 | 581 | 20 | 27.4 (14.5 to 40.8) | 29.4 (21.4 to 39.1) | 403 (290 to 445) | 15.2 (13.1 to 17.0) | 166 (77 to 276) | 0.88 (0.53 to 1.20) |
| Planted | 121 | 581 | 40 | 36.5 (21.0 to 49.4) | 41.4 (30.4 to 56.1) | 271 (158 to 340) | 17.1 (15.5 to 18.5) | 249 (134 to 362) | 1.02 (0.65 to 1.29) |
| Planted | 121 | 581 | 100 | 38.1 (19.0 to 60.5) | 67.9 (49.2 to 89.7) | 105 (45 to 171) | 18.6 (17.9 to 19.9) | 284 (142 to 453) | 0.88 (0.43 to 1.31) |
| Planted | 156 | 621 | 20 | 31.5 (16.5 to 47.2) | 31.5 (22.6 to 42.1) | 404 (302 to 449) | 15.6 (13.4 to 17.5) | 197 (91 to 330) | 0.92 (0.55 to 1.22) |
| Planted | 156 | 621 | 40 | 41.1 (24.8 to 54.0) | 44.3 (32.0 to 60.2) | 267 (159 to 345) | 17.4 (15.8 to 18.7) | 285 (160 to 409) | 1.05 (0.69 to 1.31) |
| Planted | 156 | 621 | 100 | 41.4 (20.1 to 64.2) | 72.2 (52.1 to 94.2) | 101 (44 to 173) | 18.7 (18.0 to 20.0) | 310 (152 to 481) | 0.87 (0.43 to 1.32) |
| Planted | 309 | 746 | 20 | 45.3 (25.3 to 62.1) | 37.9 (27.5 to 49.0) | 400 (317 to 450) | 16.7 (14.8 to 18.2) | 303 (153 to 453) | 1.02 (0.66 to 1.30) |
| Planted | 309 | 746 | 40 | 54.8 (35.4 to 71.3) | 53.1 (38.4 to 71.2) | 247 (151 to 344) | 18.1 (16.9 to 19.2) | 396 (245 to 534) | 1.08 (0.80 to 1.35) |
| Planted | 309 | 746 | 100 | 49.7 (21.5 to 86.8) | 85.1 (60.2 to 109.9) | 87 (39 to 173) | 19.0 (18.4 to 20.1) | 377 (169 to 658) | 0.82 (0.38 to 1.38) |

## 7. Workbook

Rebuilt from this system (`2026-11-11_koa-yield-curves-for-financial-model_DRAFT.xlsx`, replaced in place with the morning version kept as `_PREV_20261111`). Site ordering of basal area now holds through ages 151 to 175 depending on density.

## 8. What this changes in the account

Prediction of remeasured plots is much better than reported this morning, because the earlier benchmark compared projected mortality with thinning. Planted survival is higher and planted basal area at 20 and 40 years higher; 100-year values are lower for both origins because the planted peak is earlier and natural stands decline. The statement that planted trees die faster than natural trees is reversed. The evidence past 10 years is now seven plots. One gate (Sukachev) fails and is reported. The record that thinned stems are coded dead should be confirmed with Forest Solutions; the question is in the draft email.

## 9. Open

BYI and origin inside the brms frontier model; stand age or stocking in S1; installation-level bootstrap; the weak relation between plot SDImax and growth-frame koa SDI for FIA and Kap plots; koa volume and biomass equations; whether the 53 Kap plots carry an imputed BYI of 64.5 (flagged by the supplement builder, not traced).


## Final pass corrections (November 11, 2026)

An independent check of manuscript v133, supplement v124 and the release documents against the logs and CSV files found no wrong table cell. Wording was corrected in these places. Five plots, not seven, were followed past 10 years (seven reach 10 years or more; `out/coverage_rdbyi.csv`). The Sukachev gate fails in natural stands only. The Monte Carlo median lies below the point projection at 100 years for basal area and volume in every scenario, and not for height, stems or QMD. The site-ordering gate covers basal area and QMD. The scenario starting lists are the 1973 and 2012 measurements of their plots, which are not the first measurements (1968 and 2011, checked on firebreather), so years count from the starting measurement. The mortality intercept interval also includes zero. Fig. 5 and Figs. S2 and S3 now shade planted stands from year 10, where the thinning-free benchmark record of all but one planted plot ends (`scripts/26_fig5_shade.R`). The basal area RMSE of 6.74 in the comparison run against 6.76 in the benchmark run reflects the fitting start (increment coefficients differ by at most 0.0006, log 22t).

Resolved later on November 11, 2026. The three S1.3 items were traced to the stage 1 report of the v103 build (`~/jobs/koa_v103_20260930/STAGE1_REPORT.md`): 282 of 862 plot-years changed in basal area or stem density, 48 exceeded the computed value by more than 10% (22 of them at 1.9 to 2.1 times), and 164 fell more than 10% below it, so the supplement's "32 more" was unsupported and now reads 48 with 22 among them; 68.9 and 47.0 m² ha⁻¹ are the computed maxima of PSP and DOFAW, not source maxima; and the count of checks was dropped because only three are listed. The 317 plots with BYI from 0 in main text 3.2 are the BYI extraction set of supplement Table S5 (317 plots, median 161.4, range 0 to 543.4), a different set from the 310 plots with tree records (29 to 543), so the text stands. Equation S1 is now reported at the exact scenario percentiles everywhere (natural 863, 708 to 1,030; 1,238, 1,109 to 1,369; 1,394, 1,216 to 1,584; planted 581, 500 to 669; 621, 546 to 701; 746, 661 to 828; `logs/27_sdimax_at_percentiles.log`), replacing the values at rounded BYI in Section S3.2, Table S11 and main text 3.3. The workbook now says the SDImax spread exceeds the site range from age 65 in every site class and density and from age 34 or earlier on good and excellent sites (recomputed from `workbook_grid_rdbyi.csv`).
