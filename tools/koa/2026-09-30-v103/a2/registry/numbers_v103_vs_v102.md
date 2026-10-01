# numbers_v103 vs numbers_v102

Keys: v102 93, v103 106, new 13, dropped 0. Nulls in v103: 4. For a composite key the percent column gives the median and the maximum absolute percent change over the numeric leaves present in both versions (leaf detail in build/leaves_v103_vs_v102.csv). FLAG marks any shared numeric leaf (p values excluded) moving more than 5 percent. Keys whose meaning is the before engine (suffix _record, _v97, _v98, clip_shares_v98) now hold engine_v102, so their v102 to v103 change is v99 to v102.

| key | v102 | v103 | shared leaves | percent change | flag | status |
|---|---|---|---|---|---|---|
| ht_a0 | 5 leaves | 5 leaves | 5 | median 9.93, max 10.7 | FLAG |  |
| ht_a1 | 5 leaves | 5 leaves | 5 | median 18.73, max 24.2 | FLAG |  |
| ht_b | 5 leaves | 5 leaves | 5 | median 2.72, max 3.0 |  |  |
| ht_c | 5 leaves | 5 leaves | 5 | median 1.66, max 4.9 |  |  |
| ht_g1 | 5 leaves | 5 leaves | 5 | median 23.47, max 24.7 | FLAG |  |
| ht_g2 | 5 leaves | 5 leaves | 5 | median 7.56, max 9.1 | FLAG |  |
| ht_base | 11 leaves | 11 leaves | 11 | median 3.96, max 26.3 | FLAG |  |
| ht_stats | 28 leaves | 28 leaves | 28 | median 1.60, max 409.6 | FLAG |  |
| ht_loio | 6 leaves | 6 leaves | 6 | median 0.75, max 4.7 |  |  |
| ht_equiv | 36 leaves | 36 leaves | 36 | median 1.63, max 228.6 | FLAG |  |
| ht_site_pct_high_vs_low | 12.6615 | 11.3186 | 1 | -10.61 | FLAG |  |
| ht_site_m_high_vs_low_asymptote | 4.22978 | 3.38376 | 1 | -20.00 | FLAG |  |
| ht_site_pct_per100_at_medium | 3.41496 | 3.07101 | 1 | -10.07 | FLAG |  |
| uneven_sdi_age100 | 3 leaves | 3 leaves | 3 | median 3.70, max 4.4 |  |  |
| cross_cul | 63 leaves | 63 leaves | 63 | median 36.26, max 42.1 | FLAG |  |
| cross_cul_record | 63 leaves | 63 leaves | 63 | median 10.06, max 26.7 | FLAG |  |
| reineke_100 | 45 leaves | 45 leaves | 45 | median 11.01, max 27.3 | FLAG |  |
| reineke_100_record | 45 leaves | 45 leaves | 45 | median 5.18, max 19.9 | FLAG |  |
| reineke_200 | 24 leaves | 24 leaves | 20 | median 7.47, max 41.3 | FLAG |  |
| reineke_200_record | 24 leaves | 24 leaves | 20 | median 5.52, max 70.5 | FLAG |  |
| eichhorn_cv | 6 leaves | 6 leaves | 6 | median 36.90, max 58.5 | FLAG |  |
| site_order_fail | null | null | 0 |  |  |  |
| qmd_monotone | 9 leaves | 9 leaves | 9 |  |  |  |
| envelope_traj_max | 15 leaves | 15 leaves | 15 | median 6.26, max 21.5 | FLAG |  |
| mort_level_refit | 24 leaves | 24 leaves | 24 | median 6.13, max 31.6 | FLAG |  |
| mort_level_record | 24 leaves | 24 leaves | 24 | median 9.33, max 23.3 | FLAG |  |
| valid_refit | 9 leaves | 9 leaves | 9 | median 30.01, max 505.5 | FLAG |  |
| valid_record | 9 leaves | 9 leaves | 9 | median 10.66, max 1493.0 | FLAG |  |
| valid_equiv | 162 leaves | 162 leaves | 162 | median 7.84, max 7489.7 | FLAG |  |
| valid_tertile_mort | 6 leaves | 6 leaves | 6 | median 8.25, max 140.7 | FLAG |  |
| surv_stats | 190 leaves | 190 leaves | 190 | median 1.44, max 181.0 | FLAG |  |
| surv_calib | 18 leaves | 18 leaves | 18 |  |  |  |
| surv_coef | 322 leaves | 322 leaves | 322 | median 30.80, max 7524.6 | FLAG |  |
| eq5_baseline | 32 leaves | 32 leaves | 32 | median 113.64, max 191.1 | FLAG |  |
| eq5_recovered | 32 leaves | 32 leaves | 32 | median 61.08, max 117.1 | FLAG |  |
| accounting | 56 leaves | 42 leaves | 42 | median 0.00, max 1.7 |  |  |
| by_source | 63 leaves | 63 leaves | 63 | median 0.00, max 2.9 |  |  |
| byi_medians | 2 leaves | 2 leaves | 2 | median 0.00, max 0.0 |  |  |
| inc_variants | 200 leaves | 345 leaves | 0 |  |  |  |
| inc_coef | 120 leaves | 120 leaves | 0 |  |  |  |
| stage12 | 28 leaves | 28 leaves | 28 | median 3.21, max 207.3 | FLAG |  |
| stage12_summary | 22 leaves | 22 leaves | 22 | median 0.75, max 2.8 |  |  |
| background_by_origin | 20 leaves | 20 leaves | 20 | median 0.61, max 71.6 | FLAG |  |
| ingrowth | 27 leaves | 24 leaves | 24 | median 0.90, max 9.7 | FLAG |  |
| garcia | 14 leaves | 14 leaves | 14 | median 10.89, max 52.9 | FLAG |  |
| valid_plots | 4 leaves | 4 leaves | 4 | median 0.00, max 0.0 |  |  |
| valid_bias_by_origin | 6 leaves | 6 leaves | 6 | median 85.31, max 408.8 | FLAG |  |
| calibration | 56 leaves | 32 leaves | 24 | median 52.68, max 176.9 | FLAG |  |
| calibration_loio | null | null | 0 |  |  | null in v103 |
| calibration_diag | 308 leaves | 96 leaves | 0 |  |  |  |
| valid_equiv_natural | 162 leaves | 162 leaves | 162 | median 17.14, max 3270.3 | FLAG |  |
| valid_equiv_natural_v97 | 162 leaves | 162 leaves | 162 | median 4.13, max 606.8 | FLAG |  |
| valid_equiv_planted | 162 leaves | 162 leaves | 162 | median 3.25, max 377.6 | FLAG |  |
| valid_equiv_planted_v97 | 162 leaves | 162 leaves | 162 | median 11.50, max 1401.4 | FLAG |  |
| valid_equiv_v97 | 162 leaves | 162 leaves | 162 | median 6.13, max 9223.2 | FLAG |  |
| mortcal_natural | 56 leaves | 56 leaves | 56 | median 4.85, max 100.0 | FLAG |  |
| mortcal_loio_natural | 100 leaves | 100 leaves | 100 | median 2.85, max 1690.7 | FLAG |  |
| mortcal_planted | 56 leaves | 56 leaves | 56 | median 17.28, max 316.4 | FLAG |  |
| mortcal_loio_planted | 660 leaves | 660 leaves | 660 | median 0.98, max 2800.0 | FLAG |  |
| proto_metrics | 408 leaves | 408 leaves | 408 | median 9.93, max 52.3 | FLAG |  |
| proto_order | 24 leaves | 24 leaves | 24 |  |  |  |
| proto_valid | 180 leaves | 180 leaves | 180 | median 31.61, max 2613.5 | FLAG |  |
| loso | null | null | 0 |  |  | null in v103 |
| k_source_boot | 24 leaves | 28 leaves | 20 | median 37.48, max 280.4 | FLAG |  |
| k_by_source | 96 leaves | 96 leaves | 0 |  |  |  |
| mortcal_intervals_natural | 6 leaves | 6 leaves | 6 | median 0.66, max 4.3 |  |  |
| mortcal_intervals_planted | 6 leaves | 6 leaves | 6 | median 1.83, max 5.3 | FLAG |  |
| valid_k12 | 6 leaves | 6 leaves | 6 | median 0.37, max 1.8 |  |  |
| valid_planted_psp | 4 leaves | 4 leaves | 4 | median 36.50, max 69.2 | FLAG |  |
| valid_nat_fia | 4 leaves | 4 leaves | 4 | median 156.71, max 1199.2 | FLAG |  |
| valid_nat_dofaw | 4 leaves | 4 leaves | 4 | median 59.63, max 151.8 | FLAG |  |
| valid_bias_by_origin_v97 | 6 leaves | 6 leaves | 6 | median 25.55, max 753.1 | FLAG |  |
| lt_summary_v98 | 99 leaves | 99 leaves | 0 |  |  |  |
| lt_summary_v97 | 99 leaves | 99 leaves | 0 |  |  |  |
| lt_summary_u98 | 99 leaves | 99 leaves | 0 |  |  |  |
| lt_plots | 9 leaves | 9 leaves | 9 | median 0.00, max 6.6 | FLAG |  |
| sc_summary | 507 leaves | 507 leaves | 507 | median 8.48, max 57.4 | FLAG |  |
| sc_dbhmax | 26 leaves | 26 leaves | 26 | median 1.42, max 22.9 | FLAG |  |
| sc_tph | 52 leaves | 52 leaves | 52 | median 4.18, max 45.3 | FLAG |  |
| sc_diag_cr | 112 leaves | 112 leaves | 112 | median 3.82, max 40.2 | FLAG |  |
| sc_dbhmax20 | 13 leaves | 13 leaves | 13 | median 5.60, max 18.4 | FLAG |  |
| sc_init | 26 leaves | 26 leaves | 26 | median 0.97, max 4.4 |  |  |
| a0_change | 30 leaves | 30 leaves | 30 | median 9.46, max 55.6 | FLAG |  |
| clip_shares | 45 leaves | 45 leaves | 45 | median 0.00, max 300.0 | FLAG |  |
| joint_summary | 259 leaves | 259 leaves | 259 | median 6.74, max 37259.3 | FLAG |  |
| joint_cor | 144 leaves | 144 leaves | 144 | median 92.83, max 6752.3 | FLAG |  |
| joint_source_sets | 66 leaves | 4 leaves | 4 | median 986.96, max 987.0 | FLAG |  |
| joint_n | 500 | 500 | 1 | +0.00 |  |  |
| joint_distinct_sources | 2.748 | 4 | 1 | +45.56 | FLAG |  |
| width_ratio | null | null | 1 |  |  | null in v103 |
| clip_shares_v98 | 45 leaves | 45 leaves | 45 | median 0.00, max 100.0 | FLAG |  |
| ref_spread | 60 leaves | 60 leaves | 60 | median 12.63, max 215.4 | FLAG |  |
| width_ratio_all_ages | null | null | 1 |  |  | null in v103 |
| MORT_CAL | null | 2.54275 | 0 |  |  | new |
| MORT_CAL_SE_LOG | null | 0.24335 | 0 |  |  | new |
| BAL_PERCENTILE_WEIGHTED | null | True | 0 |  |  | new |
| D1_repair | null | 9 leaves | 0 |  |  | new |
| D2_copied_visits | null | 10 leaves | 0 |  |  | new |
| FIA_x4_EXPF | null | 6 leaves | 0 |  |  | new |
| garcia_beta_deployed | null | 0.148033 | 0 |  |  | new |
| deviation_A1_D1 | null | no preregistered increment candidate eligible; fallback (smallest maximum equivalence region) deployed; after A1-D6 applies to dHT only (dHT_L_NO, max region 0.245) | 0 |  |  | new |
| deviation_A1_D6 | null | deployed dDBH is the v102 vector of record with origin constants re-solved on the v103 NO frame under live list percentile BAL (c 0.82034, 2.19349), not a preregistered candidate (Aaron, 30 September 2026) | 0 |  |  | new |
| valid_plotlevel_C1 | null | 272 leaves | 0 |  |  | new |
| valid_plotlevel_C2 | null | 480 leaves | 0 |  |  | new |
| joint_mult_sdlog | null | 18 leaves | 0 |  |  | new |
| planted_domain | null | 9 leaves | 0 |  |  | new |

## New keys

- MORT_CAL: natural level, 24 natural intervals; solve_mort level 2.542751 in a2/mort/v103/H_mort_level_natural.csv, reproduced exactly by registry mort/v103_natural (plant
- MORT_CAL_SE_LOG: plot cluster bootstrap; plot_se_log 0.243353 in H_mort_level_natural.csv
- BAL_PERCENTILE_WEIGHTED: expf weighted exact path BAL percentile (a2/patch_bal_weighted_v103.py, red team A1A2 finding 1); equal expf reproduces the unweighted rule of record; False rep
- D1_repair: plotyears, changed and fallback from summary.json; no_live_expf, set_to_zero, g2 flags and tree rows quoted from STAGE1_REPORT section 2
- D2_copied_visits: the 8 copied visits are PSP 101 to 108, 2015 copies of 2014; records removed and frame effects quoted from STAGE1_REPORT section 3
- FIA_x4_EXPF: deposited FIA stand values used whole plot TPA on one subplot (one quarter of the subplot value); rebuilt per subplot (x4). Validation at subplot scale is outsi
- garcia_beta_deployed: live koa stems >= 5, 100/sqrt(z99), n 483; all species form 0.1161 not deployed; v102 record 0.1602
- deviation_A1_D1: 
- deviation_A1_D6: 
- valid_plotlevel_C1: FIA whole plots x1, min 20 koa records, 15-1-1-2628 disturbance case excluded; sign convention opposite to valid_bias_by_origin
- valid_plotlevel_C2: 25 percent equivalence, 5,000 plot bootstrap
- joint_mult_sdlog: installation design within source; residual = SD of log multiplier after OLS on the same equation's b0 to b9 draws (kmort has no vector)
- planted_domain: planted PSP increment data span BYI 158 to 561 (KMR PSP 109 to 191 also planted) and stand age under 18; Kulani 12 (BYI 25) is out of domain (pred BA 43.8 vs ob

## Dropped keys

None.

## Ten largest changes (one leaf per key, |v102| >= 0.01, SEs, p values, interval bounds, bias and difference leaves, correlations, fold level rows, coefficient tables and before keys excluded)

| key | leaf | v102 | v103 | percent |
|---|---|---|---|---|
| valid_equiv_natural | qmd long intervals.rmse | 3.324 | 10.23 | +207.7 |
| stage12 | stage2_beta.planted | -0.01785 | -0.05485 | -207.3 |
| surv_stats | [baseline|size_competition_only].brier_skill | 0.1712 | 0.481 | +181.0 |
| valid_equiv | qmd long intervals.rmse | 3.126 | 7.982 | +155.3 |
| joint_summary | h_b5.base | -0.5251 | 0.2179 | +141.5 |
| valid_tertile_mort | proj.high | 0.02607 | 0.06276 | +140.7 |
| valid_refit | QMD.RMSE | 2.936 | 6.925 | +135.9 |
| k_source_boot | [dDBH|natural].k | 0.4055 | 0.8203 | +102.3 |
| calibration | [dDBH|natural].k | 0.4055 | 0.8203 | +102.3 |
| ref_spread | dDBH natural.between_source_share | 0.7786 | 0 | -100.0 |

## Gate: headline numbers derived two independent ways (21 of 21 agree)

| quantity | way A | source A | way B | source B | relative difference | agree |
|---|---|---|---|---|---|---|
| MORT_CAL natural | 2.54275 | engine_v103 koa_params.py | 2.54275 | registry rerun calib_mort+solve_mort on engine_nocal | 3.67e-07 | True |
| MORT_CAL_SE_LOG | 0.24335 | engine_v103 koa_params.py | 0.243353 | registry rerun, plot bootstrap SD log k | 1.08e-05 | True |
| Garcia beta anchored | 0.148033 | engine koa_params GARCIA_BETA_ANCHORED | 0.148033 | 100/sqrt(z99) from beta_anchor_v103.json | 0.00e+00 | True |
| HT_P a0 | 28.9288 | registry s02 rerun (track3 02_height_refit.R) | 28.9288 | v103_constants.json (track2/height_refit_v103.R) | 0.00e+00 | True |
| HT_P a1 | 0.966788 | registry s02 rerun | 0.966788 | v103_constants.json | 0.00e+00 | True |
| dDBH c natural | 0.82034 | v103_constants.json (a1close_v103.R) | 0.82034 | a2/diag_c_by_source.R, all sources | 0.00e+00 | True |
| dDBH CAL natural = c/CF | 0.59936 | engine koa_params CAL_DDBH | 0.599361 | c_natural / CF from constants json | 2.00e-06 | True |
| dHT CAL natural = c/CF | 0.18025 | engine koa_params CAL_DHT | 0.180248 | c_natural / CF from constants json | 9.15e-06 | True |
| Stage 1 pbar | 0.312726 | track2/stage1/stage1_fit_v103.json | 0.312726 | registry stage12_summary_v103.R refit | 0.00e+00 | True |
| Stage 1 intervals | 282 | stage1_fit_v103.json | 282 | registry refit | 0.00e+00 | True |
| D2 copied visits | 8 | out/repair/summary.json | 8 | count share >= 0.90 in d2_scan_all_visits.csv | 0.00e+00 | True |
| D1 plot-years changed | 282 | out/repair/summary.json | 282 | recount BAPH or TPH change > 1e-6 in plotyear_stand_before_after.csv | 0.00e+00 | True |
| FIA BAPH median after x4 | 25.3425 | g3_before_after_by_source.csv | 25.3425 | median over FIA rows of plotyear_stand_before_after.csv | 0.00e+00 | True |
| plot level natural QMD bias (pred - obs) | -0.278646 | tableC1_v103_plotlevel.csv | -0.278646 | recomputed from val_v103_plotlevel.csv | 1.99e-16 | True |
| plot level planted BA bias (pred - obs) | -1.80392 | tableC1 | -1.80392 | recomputed from val_v103_plotlevel.csv | 1.23e-16 | True |
| joint cal_dd_nat sd_log | 0.351127 | K_joint_summary.csv | 0.351127 | SD of log over K_joint_draws.csv (ddof 1) | 3.16e-16 | True |
| joint cal_dd_nat residual sd_log | 0.035 | registry OLS on d_b0..b9 | 0.035 | a2/redteam2/mc.py output (independent script, 3 dp) | 0.00e+00 | True |
| Table 8 natural Medium 100 VOL_hi | 354.27 | table8_evenaged_M1.csv | 354.272 | 97.5 percentile of reps_evenaged_M1.csv | 4.36e-06 | True |
| Table 8 natural Medium 100 VOL | 263.81 | table8_evenaged_M1.csv | 263.807 | traj_M1.csv point projection | 9.67e-06 | True |
| natural Medium 100 QMD (05 points vs table 8) | 59.9698 | registry s05 rerun 05_refit_table6_points | 59.97 | table8_evenaged_M1.csv | 3.01e-06 | True |
| validation natural dq mean (obs - pred) | -4.75082 | registry make_traj validation_23 | -4.75082 | engine validation_M1.csv directly | 0.00e+00 | True |
