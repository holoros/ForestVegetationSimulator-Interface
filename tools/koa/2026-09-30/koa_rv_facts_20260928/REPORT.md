# koa_rv_facts_20260928: read-and-reconcile of open review items (manuscript v102, supplement s100)

Host ifm-kershaw (firebreather), 28 September 2026. Every number below was read or recomputed from files on the server. No deployed engine, deposit staging or existing job directory was modified. No coordinate was read, printed or written. "Main" is manuscript v102, "Supp" is supplement s100, [n] is the paragraph tag of the .txt exports. Scripts in this job: a1/a1_inspect.R, a1/a1_match.R, a1/a1_boot.py, a2_qmd.py, a2b.py, a3/a3_byi.R, a7_frames.py, a7b.py, a7c.py, filt.py, with logs beside them.

## A1. BYI plot counts

Evidence: koa_fig2unc_20260927/in/BYI_srf_fit.RDS (Kona) and BYI_srf_fit_HI.RDS (statewide), response Schmoldt_Index (a1_inspect.R, a1_match.R). OOB pairs from koa_fig2unc_20260927/out_oob_pairs_DATA.csv, plot bootstrap 2,000 resamples, percentile 95% intervals, seed 20260928 (a1_boot.py).

| Quantity | Kona | Statewide |
|---|---|---|
| Training rows | 582 | 581 |
| BYI = 0 / > 0 | 347 / 235 | 347 / 234 |
| Nonzero median (range) | 405 (116.5 to 2,642.5) | 405 (116.5 to 1,321.7) |
| OOB R2 all | 0.299 (0.209 to 0.396) | 0.326 (0.235 to 0.409) |
| OOB RMSE all | 219.3 (184.7 to 264.0) | 198.2 (182.5 to 214.7) |
| OOB R2 nonzero only | -0.478 (-1.033 to -0.262) | -0.849 (-1.335 to -0.512) |
| OOB RMSE nonzero only | 281.0 (216.3 to 361.4) | 246.6 (219.8 to 273.5) |
| OOB bias pred-obs nonzero | -152.7 (-183.6 to -123.3) | -151.0 (-176.0 to -125.6) |
| OOB mean pred on zero rows | 108.6 (96.2 to 122.3) | 101.3 (88.2 to 114.1) |

1. Statewide frame = Kona frame minus one row, the plot with BYI 2,642.5 (all 581 rows match on the 7 shared columns, same order). Both forests use the same Hawaii Island FIA plots (Kona predictors PTYPE, GEO_YR, Kona30mDEM, KonaSKF exist only there). "Statewide" is a predictor set, not a training sample.
2. Plots entering Eq. 1 and number converged: NOT determinable on firebreather (no Chapman-Richards script, FIA frame or log on the server). 235 plots carry a positive asymptote, 347 carry exactly zero, which cannot be a converged conditional asymptote, so "582 plots ... that supported a plot-level asymptote" (Main [31]) is wrong as worded.
3. Meaning of zero: not recorded on the server. Zero plots are drier with less soil water (median rain 693 vs 1,876 mm, WHC25 0.052 vs 0.124), same median substrate age, consistent with FIA plots without measurable tree biomass. Author must confirm.
4. Main [69] "converged for 320 plots ... median 204, SD 144, max 813" is the BYI distribution of the 320 koa network plots in AK_PLT_GEO.csv (median 203.6, SD 144.2, min 0, max 812.8), not Chapman-Richards output.
5. OOB R2 0.300 is carried by the zero/nonzero separation; on positive-asymptote plots OOB R2 is negative.
6. "Training R2 0.885" is not 1 - in-sample MSE/var (that gives 0.842 Kona, 0.793 statewide); producer not on server.

Drop-in (main [31]) replace "using the 582 plots in the deposited modeling subset that supported a plot-level asymptote." with: "using 582 FIA plots on Hawaii Island, of which 235 returned a positive plot-level asymptote and 347 were assigned a BYI of zero because they carried no measurable tree biomass." [AUTHOR TO CONFIRM meaning of zero]
Drop-in (main [69]) first sentence: "The Chapman–Richards mixed-effects model returned positive plot-level asymptotes on 235 FIA plots, from 117 to 2,643 Mg ha^−1^ (median 405 Mg ha^−1^), and at the 320 koa plots of the modeling data the resulting BYI runs from near zero on young lava substrates to 813 Mg ha^−1^ (median 204 Mg ha^−1^, SD 144)." Add after the RMSE parenthesis: "Most of that out-of-sample skill separates plots with and without tree biomass, since on the 235 plots with a positive asymptote the out-of-bag R^2^ is −0.48 (plot bootstrap 95% interval −1.03 to −0.26) and the forest underpredicts them by 153 Mg ha^−1^ on average."
Drop-in (Supp Table S6 caption parenthesis): "(both forests are trained on the same Hawaii Island FIA plots, 582 for the Kona model and 581 for the statewide model, which omits the single plot with a BYI of 2,643 Mg ha^−1^, and each includes 347 plots with a BYI of zero, so statewide names the predictor set and not the training sample)"

## A2. Largest observed QMD and basal area

Evidence: a2_qmd.py, a2b.py on deposited AK_PLT.csv (776 plot-years) and AK_TREE.csv (md5 81383c5e, identical to v102 tree table), live koa stems per plot-year.

| Filter | Natural max QMD | Planted max QMD | Natural max BAPH | Planted max BAPH |
|---|---|---|---|---|
| any | 167.5 (Mauka 2023, 1 stem) | 59.38 (KMR CAR 2025, 5 stems) | 91.40 (Kap 2020, 3 stems) | 256.65 (PSP 106 2021, 15 stems) |
| >= 5 live stems | 69.68 (Mauka 2023, exactly 5) | 59.38 | 76.06 (DOFAW 1994, 30 stems) | 256.65 |
| >= 10 live stems | 31.95 | 46.88 | 76.06 | 256.65 |

- 69.68, 76.06 and SDI 1,453.47 are OBS in track2/engine_v102/run_candidates.py line 36 (and numbers_v102.json envelope_traj_max): maxima over NATURAL plot-years with at least five live koa stems. koa_params.py line 1513 mislabels 69.68 as the largest on any plot-year.
- 59.4 = planted maximum under every filter.
- 88.7 reproduces under no filter (nearest natural plot-years 88.5 and 89.0 cm on 1 and 2 stems). It is wrong.
- The planted ceiling 69.7 equals the natural five-stem maximum. The natural 90 cm ceiling exceeds every natural plot-year of five or more stems.
- Planted BAPH above 76.06 exists: PSP 106 2021 256.6 m2/ha (0.020 ha plot, EXPF 49.56, DBH 17.4 to 47.1 but plot DBH.max 201) and PSP 104 2021 129.1. Both are in the dDBH, dHT, AK_SURV and static height frames (28 height records) but not in main Table 2 (BAPH max 91.4). Probable data error, check against the PSP master file.

Drop-in (main [62]) replace "The natural value approximates ... not itself an observed quantity." with: "The planted value equals the largest QMD observed on a natural plot-year carrying at least five live stems, 69.7 cm, and sits above the largest planted QMD of 59.4 cm, whereas the natural value is a harness constant above every natural plot-year of five or more stems."
Drop-in (Fig. 4 caption) "dashed lines mark the largest QMD (69.7 cm) and basal area (76.06 m^2^ ha^−1^) observed on a natural plot-year carrying at least five live koa stems."
Drop-in (Table 5 notes) "No point estimate exceeds the largest basal area observed on a natural plot-year of at least five live stems, 76.06 m^2^ ha^−1^ (largest 64.1 m^2^ ha^−1^), and the uneven-aged natural high-site row at age 100 exceeds the largest QMD on such a plot-year, 69.7 cm."
Drop-in (main [81]) "Uneven-aged QMD exceeds 69.7 cm, the largest QMD on a natural plot-year of at least five live stems, on the high site at age 93"
Drop-in (Supp [254]) "The planted value equals the largest quadratic mean diameter observed on a natural plot-year carrying at least five live stems (69.7 cm, against 59.4 cm for the largest planted plot-year), raised from 60 cm". Same wording at Supp [1412], [1414] and the Table S18 note.

## A3. BYI of non-FIA plots, Kulani

Evidence: a3/a3_byi.R, both forests predicted at PLT.GEO.V2_v102 covariates (no coordinate columns, asserted).
- Deposited BYI = PLT.GEO.V2 BYI exactly.
- 0 of 78 FIA koa plots carry a value equal to any training response or in-sample prediction. 38 distinct values over 38 FIA installations.
- Kap: 53 plots on 4 installations share one value (62.1). Kahikinui 29 values over 64 plots. Values lie near the stored forest predictions at plot covariates (median abs diff 6 to 55 by source), consistent with the composite surface plus substrate age correction evaluated at location. None is Float32-representable, so not read from the deposited Float32 tif itself.
- Kulani 12 BYI 25.15 (Kona forest prediction 23.85), minimum of the v102 increment and survival frames (next 92.67). Kulani 42 BYI 0.00 has no increment records.
- Fig. 2 caption claim is wrong for every source.
Drop-in (Fig. 2 caption) replace "Plot-level BYI entering the fitted equations is the value estimated for that plot rather than a value read from this surface." with "Plot-level BYI entering the fitted equations is the value of the composite surface model at each plot, including the substrate age correction, and not the Chapman–Richards asymptote of an individual FIA plot."

## A7. Expansions and covariate definitions

Evidence: deposit README.md lines 1072 to 1079, Supp [929], engine_v102 koa_mortality_garcia.py lines 60 to 61 and 144 to 146, koa_params.py lines 237 to 240, builders/build_frames_incr.R line 24, a7_frames.py, a7b.py, a7c.py.
- KMR = Keauhou-Mauna Loa Restoration. CAR = "competitive annual remeasurements" per README line 1077 only (Aaron to confirm). Kap = Kapapala Forest Reserve, Hawaii Island.
- H_40 = EXPF-weighted mean height of the 40 largest-DBH trees per ha (h40_from_list). Allometry ln QMD = a + k_HD ln H_40 (a -0.16863, k_HD 1.17195) is OLS on the 360 regular intervals of the record plot_interval_pairs_DATA.csv.
- YIP = t.1 - t.0, the remeasurement interval in whole years.
- BAPH, TPH, QMD, SDI are all-species live-tree values (match koa-only sums on 86 to 90% of pure-koa plot-years, 0 to 3% of the 192 mixed plot-years). BA.AK and pBA.AK are koa-only. SDI = sum EXPF (DBH/25.4)^1.605 (reference 25.4 cm, not the 25 at Supp [257]).
- BAL = BAPH x (1 - BA.perc) in 98.5% of live records, all species (largest koa stem has BAL > 0 on 63 of 192 mixed plot-years).
- In projection all are recomputed from the koa tree list, so koa-only.
Drop-in (Table 1 note) "KMR is the Keauhou–Mauna Loa Restoration program, whose CAR and PSP networks are counted separately, and Kap is the Kapāpala Forest Reserve."
Drop-in (main [60]) "on the allometry of ln QMD on ln H_40_, the expansion-factor-weighted mean height of the 40 largest-diameter trees ha^−1^,"
Drop-in (main [47]) after "ln(YIP) offset" add ", where YIP is the remeasurement interval in years"
Drop-in (Supp [5]) after "quadratic mean diameter (QMD)" add ", all computed from every live tree of every species on the plot, with SDI summed as Σ EXPF (DBH/25.4)^1.605^, whereas the simulator recomputes them from the projected koa tree list"

## Zero and negative increments

Rule, builders/build_frames_incr.R line 41: DBH.0 > 0, both visits live, YIP > 0, 0 < dDBH.ann < 10. dHT frame line 48: 0 < dHT/YIP < 10. Survival line 55: live at t0, YIP > 0, 0 < dDBH.ann < 10.
Counts (filt.py): dDBH 5,540 live pairs, 365 zero, 348 negative, 37 >= 10 excluded, 4,790 kept, minimum kept 0.0043 cm/yr (prints 0.00). dHT 929 <= 0 and 4 >= 10 excluded from 4,790, 3,857 kept, minimum 0.009 m/yr. Survival: 6,896 live at t0, 1,343 dead at t1, the condition removes 1,990 records including 1,264 of the 1,343 deaths (1,244 with zero or missing terminal DBH) and 726 non-growing survivors, plus 37 >= 10, leaving 4,869 with 79 deaths.
Drop-in (Table 2 note) "ΔDBH and ΔHT are strictly positive by construction, since intervals with zero or negative annual increment (713 of 5,540 diameter and 929 of 4,790 height intervals) or with increments of 10 or more units per year (37 and 4) were excluded, and the minima print as 0.00 and 0.01 after rounding."
Drop-in (Supp [703]) "Of 6,896 records alive at the first measurement, that condition removes 1,264 of the 1,343 observed deaths and 726 survivors whose diameter did not increase."

## A9 (a) Survival flow

| Stage | Records | Deaths | Survivors | Tree-yr | Per record | Per yr | Inst | Plots | Trees |
|---|---|---|---|---|---|---|---|---|---|
| v1.1.0 table | 6,489 | 280 | 6,209 | n/a | 4.31% | n/a | 62 | | |
| minus 520 exact duplicates (record) | 5,969 | 79 | 5,890 | 14,089 | 1.32% | 0.561% | 62 | 100 | 1,412 |
| record collapsed one per key (diagnostic) | 5,047 | 79 | 4,968 | 12,236 | 1.57% | 0.646% | 62 | 100 | 1,412 |
| v102 rebuild, deposited AK_SURV, Table S9 | 4,869 | 79 | 4,790 | 11,881 | 1.62% | 0.665% | 62 | 98 | 1,406 |
| recovered (i) | 4,114 | 798 | 3,316 | 15,258 | 19.4% | 5.23% | 47 | 87 | 1,361 |
| recovered (ii) | 4,298 | 877 | 3,421 | 15,519 | 20.4% | 5.65% | 51 | 91 | 1,444 |
| (ii) standardized, Fig. S7b | 3,929 | 808 | | 15,049 | | | 48 | | |
Sources: DEPOSIT_CHANGELOG lines 943 to 975, INTEGRITY_REPORT line 163, v102 logs/finalize_frames.log and rebuild_surv_v102.log, recounts of the three AK_SURV files.
Fixes: Supp [7] "which reduce to 79 independent mortality events in 5,969 records once the 520 exact duplicate records are removed, and to the same 79 events in 4,869 records (1.62%, or 0.665% per year across 11,881 tree-years) once duplicate tree visits are resolved as in Section 1.1". Supp [656] 1.32% -> 1.62%. Supp [701] 5,890 survivors -> 4,790 (recheck 7.81 and 2.29 yr). Supp [703] "reproduces the deduplicated deposit table exactly, at 5,969 records, 79 independent mortality events, 14,089 tree-years, 62 installations, 100 plots and 1,412 trees, and after duplicate tree visits are resolved (Section 1.1) the same procedure gives the 4,869 records, 79 events, 11,881 tree-years, 98 plots and 1,406 trees to which Table S9 is fitted". Supp [2699] 0.561% -> 0.665%.

## A9 (b) to (p)

(b) numbers_v102.json mort_level_refit (engine_v102 traj_M1) vs mort_level_record (v99 engine_joint). v99 unweighted natural 0.0124, 0.0154, 0.0169 (planted annualised 0.0172, 0.0186, 0.0193); v99 stem-weighted 0.0121, 0.0155, 0.0176. v102 deployed unweighted natural 0.0095, 0.0124, 0.0143, planted 0.0156, 0.0175, 0.0185; stem-weighted natural 0.0094, 0.0125, 0.0149, planted 0.0193, 0.0242, 0.0272. Table S18 = v99 weighted, Supp [1730] = v99 unweighted, Table S19 and 11.3 "0.010 to 0.014" = v102 unweighted. Fix Table S18 "0.0094 to 0.0149", Supp [1730] "0.0095, 0.0124 and 0.0143 ... planted 0.0156, 0.0175 and 0.0185", caption S19 "unweighted means of the annual stand rate over years 1 to 100". Delete or rerun "0.0074, 0.0096 and 0.0107".
(c) No estimator difference. OLS ln TPH on ln QMD over ages 11 to 100 on deployed M1 = Section 6 slopes: natural -0.80, -1.01, -1.12, planted -1.32, -1.47, -1.55 (3 of 6 in band), uneven -1.07, -1.11, -1.16 (3 of 9). "4 of 6" is the 4 Sep 2026 v66 hybrid evaluation (koa_v82_hybrid/stage/build/hybrid_candidates_2026-09-04.md line 57, natural high -1.24). Fix Table S18 "3 of 6", Supp [1729] "places three of six Reineke slopes in the band (the three planted sites)", delete the Supp [1631] clause. Other S18 rows are the same v66 run (engine_v102/out_cand is empty).
(d) Recovered (ii) AUC 0.600 = non-converged glm last iterate (track5_s11base/out_v102), 0.597 = converged BFGS ML (c2c_numbers_v102_rerun_20260924.log). Brier 0.0209 on 4,869 (v102), 0.0171 on 5,969 (record). Fix Table S21 0.597 and 0.021.
(e) s05 v102 trajectories, uneven high: QMD 69.37 at 92, 69.76 at 93. Age 93. Fix Supp [1412], [2701].
(f) b6 sqrt(BAPH x size) -0.0176013 (SE 0.00349), b7 Planted x DBH -0.0176238 (SE 0.00245). Real. Print -0.01760 and -0.01762 in Table 4 and S8 with a note.
(g) Median BYI: v102 dDBH and survival 390.15, dHT 392.59, record dDBH 388.83. Fix Supp [2603] 389 -> 390.
(h) Development sample apparent AUC 0.938 (Table S10 B0), v102 0.889. 0.924 = respecified Eq. 5 term set (s06, AIC 405.3). Fix Supp [700] "falls from 0.938 to 0.889".
(i) 51 installations no death, 2 deaths only, 53 unscoreable, 9 scoreable (numbers_v102 surv_stats loio_folds_scoreable 9). Fix Supp [702] "53 of the 62 folds cannot be scored on their own, 51 for want of a death and 2 for want of a survivor, and of the nine that hold both, the FIA installation carrying 62 of the 79 events dominates the pooled value and returns 0.473 on its own" (0.473 not recomputed).
(j) ht_equiv region_bias 2.29524 m (mean 9.18096). Fix Table S7 caption ±2.30 m.
(k) track3/inc/out_V102/G_calibration_loio.csv: +0.040, -0.016 cm/yr, +0.025, +0.009 m/yr, R2 0.278, 0.214. out_RECORD: +0.030, -0.000, +0.003, +0.010, R2 0.347, 0.246. Step 2 biases are the record frame. Fix Supp [254] "+0.040 and −0.016 cm yr^−1^ (natural, planted) and +0.025 and +0.009 m yr^−1^", Table S21 footnote c same three decimals, Table S17 note 0.347 -> "0.278 (Section 3, Step 2)".
(l) track5_figS/v100/trackC1/C1b_survival_calibration.csv (4,869): expected 139.4, calibration slope 0.353 (Wald 0.286 to 0.420, installation bootstrap 0.094 to 0.630), 1,322 (27.2%) predicted exactly 1, HL not computed. 140.9 = record frame. Fix Supp [435] "expecting 139.4 deaths against 79 observed, with a calibration slope of 0.35 on the complementary log-log scale (95% interval 0.29 to 0.42), a Brier skill score of −0.31 and 27.2% of records at a predicted survival of exactly 1" (rerun HL if kept).
(m) 0.506/0.939 = 16 Sep record run (4,911 records, 899 events, c2c_numbers.log line 12). v102 0.475/0.923. Fix Supp [941].
(n) validation_23.csv Kulani 12: survival 0.194 vs 0.550 (-0.355), BA 13.63 vs 43.49 (-29.9), QMD 31.6 vs 33.6 (-2.0). Supp [2603] -0.256/-8.1/-36.3 is a pre-v102 counterfactual baseline, no v102 rerun exists. Rerun or replace with "Under the deployed engine its first-to-last errors are −0.355 in survival, −2.0 cm in quadratic mean diameter and −29.9 m^2^ ha^−1^ in basal area (observed minus projected, Table S16)."
(o) Table S4 = percentiles over 500 accepted joint rows (K_joint_summary.csv): -2.601 to -0.643, 0.0157 to 0.3028, -0.771 to 0.276. Section 7.1 = engine_v102/out_stage1/stage1_fit.json stage1_ci: -2.686 to 0.335, 0.0133 to 0.3152, -2.114 to 0.222. Both right. Table S4 note: "Stage 1 ranges are percentiles over the 500 accepted joint rows under the acceptance rule of Section 3, which excludes extreme resamples, and are therefore narrower than the plot-cluster bootstrap intervals of Section 7.1."
(p) Deployed planted net MAI culmination 13 (low), 10, 8 (numbers_v102 cross_cul). Engine of record 11 (05_engine_of_record_crossover_culmination.csv). "From 11 to 10" (Supp [2579]) is the HCB least-squares substitution against the old engine, no v102 rerun found. Rerun or delete that clause and treat the rest of the sentence as unverified.

## A8

Not found on the server. 90,200 to 98,300 ha (Main [20]) and 170,000 ha (Main [27]) are both cited to Owen et al. (2022), not present. They differ by about 1.8 times under one citation and must be checked against the source.

## Additional finding

Every Kahikinui Install value in the deposited AK_TREE.csv (1,068 rows), AK_PLT.csv (64) and AK_PLT_GEO.csv (64) is a longitude-latitude string. Not FIA, but contrary to the README's coordinate removal. Values not printed. Recode in the next deposit version.

Zenodo: staged via main session. GitHub: pending Aaron's PAT approval.
