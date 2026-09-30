# Koa engine refit deployment, 29 September 2026: conventional BAL increment equations in the v102 engine

Job ~/jobs/koa_refit_20260929, engines engine_refit (deployed candidate) and engine_refit_live (sensitivity). Reference is engine_v102 of ~/jobs/koa_v102_20260918/track2 and its outputs traj_v102.csv, val_v102.csv, uneven_v102.csv. Nothing under koa_v102_20260918 was modified.

## 1. What changed

1. A BAL_DEFINITION switch was added to koa_params.py ("percentile" is the 8 September 2026 concept of record that engine_v102 runs, "conventional" is the new definition) and to koa_equations.stand_bal. Under "conventional" the exact tree list path computes BAL_i as the sum over live trees j with DBH_j strictly greater than DBH_i of (pi / 40000) DBH_j^2 EXPF_j in m2 per hectare, equal diameters contributing nothing to each other (new function koa_equations.bal_conventional, checked against a brute force sum). The cohort path (project_cohort) uses fraction = a0 + a1 ln(QMD) with the conventional coefficients BAL_COHORT_LIN_B_CONVENTIONAL = (0.773485, -0.057097) from out/cohort_bal_fraction.csv row bal == c (mean fraction 0.622). Every exact path call site now passes expf so the switch can be taken: koa_projector.project_psp, run_candidates.project, regen_figS4S5. koa_longterm_validation, regenerate_uneven_aged, regen_m1 and calib_mort all project through project_psp or run_candidates.project and are therefore routed through the switch. The percentile arm is unchanged, and the retained PSP_BAL_MODE "cumsum" arm is untouched. run_candidates._finish, which builds the initial Weibull tree list and only uses BAL to set the initial crown ratio, already carried the conventional cumsum construction and was left alone (the Weibull classes have distinct diameters, so ties do not arise there).
2. The increment constants were replaced by the 29 September 2026 refit on all valid remeasurement intervals (frame AP, 15,728 dDBH rows and 13,761 dHT rows, 60 installations): LineageA.DDBH and DHT (b0 to b9, same functional form), CF_DDBH_MARGINAL, CF_DHT (which had stayed at 1.030 through v102 and now takes the fitted exp(0.5 (tau_source^2 + tau_inst^2)) of the dHT fit), CAL_DDBH and CAL_DHT as c_origin / CF so that CF x CAL equals the total per step multiplier c_origin, BAL_DEFINITION = "conventional".
3. HCB_P was NOT refit and is unchanged under both definitions (decision of the lead; the crown BAL term is small). The HCB equation therefore now receives conventional BAL where it was fitted on percentile BAL. This is stated as a known inconsistency.
4. The natural mortality level factor MORT_CAL was re-solved on the patched engine exactly as track 2 did (calib_mort.py and solve_mort.py, form mult, 23 natural non removal intervals, planted unscaled at 1.0).
5. The HiGy.R mirror was brought into step: ddbh.parm and dht.parm site rows carry the refit vectors with a new b9 column (planted level shift), the ddbh() and dht() functions read cf = KOA_CF_x times the origin multiplier KOA_CAL_x, the planted diameter term uses the 45 cm guard of koa_params.DDBH_PLANTED_GUARD_CM instead of pmin(dbh, 40), and the planted height term takes the fitted linear form planted * pmin(ht, 20) that koa_equations carries instead of sqrt(planted * pmin(ht, 20)). New constants KOA_CF_DDBH, KOA_CF_DHT, KOA_CAL_DDBH, KOA_CAL_DHT, KOA_DDBH_PLANTED_GUARD_CM, KOA_BAL_DEFINITION and KOA_BAL_COHORT_LIN_B sit beside KOA_S3_SURV. HiGy.R calc_bal was already the conventional cumsum(ba) - ba over descending dbh with expansion weighted ba, so its BAL needed no change (it differs from bal_conventional only on exact diameter ties). Note that engine_v102 had left the HiGy.R increment tribbles at the constants of record (not even v102), so this is the first time the mirror carries the deployed increment vectors. The stale Stage 1 constants flagged in TRACK_V102_REPORT.md DEVIATION V102-D2 were not touched. HiGy.R parses in R; the parity harness was not rerun.

## 2. Regression gate

engine_v102 was copied to engine_refit and run unmodified through a copy of track2/run_engine.py with tag gate. traj_gate.csv against track2/out/traj_v102.csv: 1,800 rows, every numeric column max absolute difference 0.000e+00, PASS. val_gate.csv against val_v102.csv: max absolute difference 0.000e+00, PASS. After the BAL_DEFINITION switch was installed the gate was rerun with the switch at percentile (tag gate2): again 0.000e+00 on both files, PASS (logs/gate2_compare.txt). The switch therefore reproduces engine_v102 exactly when set to percentile.

## 3. Constants, old (engine_v102) against new (engine_refit)

| name | old | new | note |
|---|---|---|---|
| DDBH_b0 | -1.1509411 | -1.66026913723574 |  |
| DHT_b0 | -3.6114059 | -4.39311540671526 |  |
| DDBH_b1 | 0.3371168 | 0.171193285219291 |  |
| DHT_b1 | 1.1203441 | 0.116858711334184 |  |
| DDBH_b2 | -0.0143456 | -0.0733460999488903 |  |
| DHT_b2 | -0.1154809 | -0.0821115689096912 |  |
| DDBH_b3 | -0.0017722 | -0.0027982424059264 |  |
| DHT_b3 | -0.0009067 | -0.0002022042590091 |  |
| DDBH_b4 | -0.4306515 | -0.0968604070685938 |  |
| DHT_b4 | -0.1332027 | -0.0691151289736847 |  |
| DDBH_b5 | 1.2809352 | -0.813222222767529 |  |
| DHT_b5 | -0.5250905 | -0.122429679597587 |  |
| DDBH_b6 | -0.0176013 | 0.0373041449893961 |  |
| DHT_b6 | 0.0379597 | 0.04484565967782 |  |
| DDBH_b7 | -0.0176238 | -0.0216691240341329 |  |
| DHT_b7 | -0.124088 | -0.0796892221566542 |  |
| DDBH_b8 | 0.3045245 | 0.33316012862787 |  |
| DHT_b8 | 0.2232825 | 0.582040391873932 |  |
| DDBH_b9 | 0.4103534 | 0.577909855537238 |  |
| DHT_b9 | 1.0681935 | 1.796946923487 |  |
| CAL_DDBH_natural | (0.40548, 1.43606) | 0.4138317841312378 |  |
| CAL_DDBH_planted | (0.40548, 1.43606) | 0.8951313831555473 |  |
| CAL_DHT_natural | (0.51917, 2.64739) | 1.0411301140845823 |  |
| CAL_DHT_planted | (0.51917, 2.64739) | 1.0129758165693177 |  |
| CAL_DDBH_SE_LOG_natural | (0.07956, 0.05225) | 0.07956 | PLACEHOLDER: v102 value kept until out/c_bootstrap.csv exists; run patch_selog_refit.py |
| CAL_DDBH_SE_LOG_planted | (0.07956, 0.05225) | 0.05225 | PLACEHOLDER: v102 value kept until out/c_bootstrap.csv exists; run patch_selog_refit.py |
| CAL_DHT_SE_LOG_natural | (0.14862, 0.04807) | 0.14862 | PLACEHOLDER: v102 value kept until out/c_bootstrap.csv exists; run patch_selog_refit.py |
| CAL_DHT_SE_LOG_planted | (0.14862, 0.04807) | 0.04807 | PLACEHOLDER: v102 value kept until out/c_bootstrap.csv exists; run patch_selog_refit.py |
| CF_DDBH_MARGINAL | 1.36869 | 1.35680332657097 |  |
| CF_DHT | 1.030 | 1.0829008924229 |  |
| BAL_DEFINITION | percentile | conventional |  |
| BAL_COHORT_LIN_B_CONVENTIONAL_a0 | (0.773485460160129, -0.0570969153432526) | 0.773485460160129 |  |
| BAL_COHORT_LIN_B_CONVENTIONAL_a1 | (0.773485460160129, -0.0570969153432526) | -0.0570969153432526 |  |
| HiGy_cf_ddbh | 1.026 | 1.35680332657097 |  |
| HiGy_cf_dht | 1.03 | 1.0829008924229 |  |
| HiGy_ddbh_planted_trunc_cm | 40 | 45 |  |
| HiGy_dht_planted_term | sqrt(planted*pmin(ht,20)) | planted*pmin(ht,20) |  |
| HiGy_CAL_DDBH | none (1,1) | (0.41383, 0.89513) |  |
| HiGy_CAL_DHT | none (1,1) | (1.04113, 1.01298) |  |
| HiGy_ddbh.parm_site | record vector (-2.4704737 ...) | refit b0..b9 |  |
| HiGy_dht.parm_site | record vector (-3.382162 ...) | refit b0..b9 |  |
| MORT_CAL_natural | 2.6462860696589208 | 1.85561446551515 |  |
| MORT_CAL_SE_LOG_natural | 0.1817204503423178 | 0.1968043546859353 |  |


CF_DDBH_MARGINAL 1.36869 to 1.35680, CF_DHT 1.030 to 1.08290. Total per step multipliers CF x CAL: dDBH natural 0.56149 (v102 0.55498), dDBH planted 1.21452 (v102 1.96553), dHT natural 1.12744 (v102 0.53475), dHT planted 1.09695 (v102 2.72681). The planted origin multipliers therefore collapse toward one, because the refit carries the origin difference in b9 and b7 on the full interval frame rather than in the calibration.

CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG are PLACEHOLDERS carrying the v102 values (0.07956, 0.05225) and (0.14862, 0.04807): refit_addendum.R was still running its 2,000 draw installation bootstrap of c when this report was written (out/c_bootstrap.csv absent). Run python3 patch_selog_refit.py once that file exists; it rewrites both engines and both patch_values files. No trajectory or validation number depends on these two constants.

## 4. Natural mortality level factor

Solved exactly as track 2 (calib_mort.py, solve_mort.py, form mult, 23 of 23 natural non removal intervals, plot_intervals_origin.csv byte identical to track2/mort/v102, md5 d00f6159). MORT_CAL natural moves from 2.64629 (v102) to 1.85561, plot cluster bootstrap 95 percent 1.4650 to 3.2251, SD of log k 0.19680 (v102 0.18172), installation cluster 95 percent 1.4579 to 2.7068. Leave one installation out levels 1.6992 to 2.1450. Uncalibrated the patched engine predicts 9574 deaths per hectare summed over the intervals against 15326 observed, so the engine now needs a smaller level factor than v102 did: the refit increments grow the natural stands faster early, which raises the gated stand rate. The floor form (0.05944) is not deployed. Planted stays 1.0. The live list sensitivity engine solved to 1.76865.

## 5. Table 5 comparison, v102 (reference) against refit, percent change refit minus v102 over v102

Even aged M0 point path under the gated M1 set up, 300 year runs, six scenarios, plus the uneven aged natural ingrowth point path (uneven_point.py). MAI is standing VOL / age.

### VOL

| Scenario | Site (BYI) | Age | VOL v102 | VOL refit | pct refit | VOL refit_live | pct refit_live |
|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 35.1 | 55.9 | +59.1 | 52.0 | +48.1 |
| even-aged natural | Low (100) | 40 | 73.5 | 108.3 | +47.3 | 101.4 | +38.0 |
| even-aged natural | Low (100) | 60 | 112.8 | 149.5 | +32.5 | 142.1 | +25.9 |
| even-aged natural | Low (100) | 100 | 173.0 | 198.4 | +14.7 | 193.9 | +12.1 |
| even-aged natural | Medium (264) | 20 | 57.4 | 75.1 | +30.8 | 70.0 | +21.9 |
| even-aged natural | Medium (264) | 40 | 120.7 | 140.8 | +16.6 | 132.9 | +10.1 |
| even-aged natural | Medium (264) | 60 | 174.4 | 187.8 | +7.6 | 180.2 | +3.3 |
| even-aged natural | Medium (264) | 100 | 249.0 | 240.5 | -3.4 | 238.0 | -4.4 |
| even-aged natural | High (450) | 20 | 77.5 | 91.2 | +17.6 | 85.1 | +9.7 |
| even-aged natural | High (450) | 40 | 157.8 | 166.4 | +5.5 | 157.9 | +0.1 |
| even-aged natural | High (450) | 60 | 219.5 | 217.7 | -0.8 | 210.1 | -4.3 |
| even-aged natural | High (450) | 100 | 300.5 | 273.3 | -9.1 | 271.7 | -9.6 |
| even-aged planted | Low (100) | 20 | 232.3 | 234.9 | +1.1 | 244.3 | +5.2 |
| even-aged planted | Low (100) | 40 | 378.1 | 335.5 | -11.3 | 358.2 | -5.3 |
| even-aged planted | Low (100) | 60 | 473.8 | 394.4 | -16.7 | 425.8 | -10.1 |
| even-aged planted | Low (100) | 100 | 525.9 | 447.6 | -14.9 | 501.9 | -4.5 |
| even-aged planted | Medium (264) | 20 | 329.1 | 290.3 | -11.8 | 304.4 | -7.5 |
| even-aged planted | Medium (264) | 40 | 498.7 | 396.9 | -20.4 | 426.0 | -14.6 |
| even-aged planted | Medium (264) | 60 | 549.8 | 459.8 | -16.4 | 497.8 | -9.5 |
| even-aged planted | Medium (264) | 100 | 569.2 | 513.6 | -9.8 | 573.6 | +0.8 |
| even-aged planted | High (450) | 20 | 402.5 | 334.0 | -17.0 | 351.4 | -12.7 |
| even-aged planted | High (450) | 40 | 559.7 | 447.3 | -20.1 | 480.9 | -14.1 |
| even-aged planted | High (450) | 60 | 612.5 | 514.3 | -16.0 | 557.1 | -9.1 |
| even-aged planted | High (450) | 100 | 594.9 | 554.3 | -6.8 | 613.4 | +3.1 |
| uneven-aged natural | Low (100) | 20 | 42.2 | 67.2 | +59.2 |  |  |
| uneven-aged natural | Low (100) | 40 | 123.1 | 156.7 | +27.2 |  |  |
| uneven-aged natural | Low (100) | 60 | 187.4 | 222.1 | +18.5 |  |  |
| uneven-aged natural | Low (100) | 100 | 292.1 | 314.5 | +7.7 |  |  |
| uneven-aged natural | Medium (264) | 20 | 83.5 | 96.8 | +15.8 |  |  |
| uneven-aged natural | Medium (264) | 40 | 188.8 | 203.3 | +7.7 |  |  |
| uneven-aged natural | Medium (264) | 60 | 268.2 | 273.9 | +2.1 |  |  |
| uneven-aged natural | Medium (264) | 100 | 399.7 | 376.1 | -5.9 |  |  |
| uneven-aged natural | High (450) | 20 | 117.7 | 120.6 | +2.5 |  |  |
| uneven-aged natural | High (450) | 40 | 236.8 | 237.5 | +0.3 |  |  |
| uneven-aged natural | High (450) | 60 | 329.2 | 314.0 | -4.6 |  |  |
| uneven-aged natural | High (450) | 100 | 481.4 | 425.5 | -11.6 |  |  |

### QMD

| Scenario | Site (BYI) | Age | QMD v102 | QMD refit | pct refit | QMD refit_live | pct refit_live |
|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 16.3 | 19.5 | +19.5 | 18.9 | +15.4 |
| even-aged natural | Low (100) | 40 | 23.0 | 27.0 | +17.5 | 25.9 | +12.6 |
| even-aged natural | Low (100) | 60 | 29.0 | 32.6 | +12.1 | 31.2 | +7.3 |
| even-aged natural | Low (100) | 100 | 39.9 | 40.6 | +1.7 | 39.1 | -2.2 |
| even-aged natural | Medium (264) | 20 | 19.4 | 21.7 | +12.2 | 21.0 | +8.1 |
| even-aged natural | Medium (264) | 40 | 28.6 | 30.3 | +5.7 | 29.0 | +1.1 |
| even-aged natural | Medium (264) | 60 | 36.8 | 36.3 | -1.3 | 34.8 | -5.4 |
| even-aged natural | Medium (264) | 100 | 50.5 | 44.8 | -11.2 | 43.2 | -14.3 |
| even-aged natural | High (450) | 20 | 21.6 | 23.2 | +7.0 | 22.3 | +2.9 |
| even-aged natural | High (450) | 40 | 32.6 | 32.2 | -1.2 | 30.8 | -5.5 |
| even-aged natural | High (450) | 60 | 42.1 | 38.6 | -8.3 | 37.0 | -12.1 |
| even-aged natural | High (450) | 100 | 57.5 | 47.3 | -17.6 | 45.7 | -20.5 |
| even-aged planted | Low (100) | 20 | 26.8 | 28.0 | +4.6 | 28.7 | +7.1 |
| even-aged planted | Low (100) | 40 | 38.2 | 36.2 | -5.2 | 38.4 | +0.5 |
| even-aged planted | Low (100) | 60 | 46.9 | 41.3 | -11.9 | 44.8 | -4.5 |
| even-aged planted | Low (100) | 100 | 56.1 | 48.5 | -13.5 | 54.0 | -3.7 |
| even-aged planted | Medium (264) | 20 | 32.5 | 31.0 | -4.4 | 32.1 | -1.2 |
| even-aged planted | Medium (264) | 40 | 46.3 | 39.5 | -14.7 | 42.4 | -8.5 |
| even-aged planted | Medium (264) | 60 | 53.3 | 44.9 | -15.9 | 49.2 | -7.7 |
| even-aged planted | Medium (264) | 100 | 62.1 | 52.5 | -15.6 | 58.9 | -5.2 |
| even-aged planted | High (450) | 20 | 36.0 | 32.8 | -8.9 | 34.1 | -5.3 |
| even-aged planted | High (450) | 40 | 49.9 | 41.5 | -16.9 | 44.8 | -10.3 |
| even-aged planted | High (450) | 60 | 57.3 | 47.0 | -18.0 | 51.9 | -9.4 |
| even-aged planted | High (450) | 100 | 64.6 | 54.4 | -15.9 | 61.3 | -5.1 |
| uneven-aged natural | Low (100) | 20 | 15.6 | 19.2 | +22.7 |  |  |
| uneven-aged natural | Low (100) | 40 | 27.4 | 29.8 | +8.7 |  |  |
| uneven-aged natural | Low (100) | 60 | 37.0 | 37.8 | +2.1 |  |  |
| uneven-aged natural | Low (100) | 100 | 51.4 | 48.6 | -5.5 |  |  |
| uneven-aged natural | Medium (264) | 20 | 21.7 | 22.6 | +4.1 |  |  |
| uneven-aged natural | Medium (264) | 40 | 36.9 | 34.8 | -5.6 |  |  |
| uneven-aged natural | Medium (264) | 60 | 48.2 | 43.1 | -10.6 |  |  |
| uneven-aged natural | Medium (264) | 100 | 64.6 | 54.1 | -16.3 |  |  |
| uneven-aged natural | High (450) | 20 | 25.9 | 24.7 | -4.7 |  |  |
| uneven-aged natural | High (450) | 40 | 42.5 | 37.6 | -11.7 |  |  |
| uneven-aged natural | High (450) | 60 | 54.8 | 46.0 | -16.1 |  |  |
| uneven-aged natural | High (450) | 100 | 72.4 | 57.2 | -21.0 |  |  |

### HT

| Scenario | Site (BYI) | Age | HT v102 | HT refit | pct refit | HT refit_live | pct refit_live |
|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 9.9 | 10.9 | +9.8 | 10.6 | +7.5 |
| even-aged natural | Low (100) | 40 | 12.6 | 13.4 | +5.9 | 13.1 | +3.5 |
| even-aged natural | Low (100) | 60 | 14.8 | 15.0 | +1.7 | 14.7 | -0.5 |
| even-aged natural | Low (100) | 100 | 17.8 | 17.0 | -4.3 | 16.7 | -5.9 |
| even-aged natural | Medium (264) | 20 | 11.9 | 12.4 | +3.5 | 12.1 | +1.3 |
| even-aged natural | Medium (264) | 40 | 15.6 | 15.2 | -2.2 | 14.9 | -4.4 |
| even-aged natural | Medium (264) | 60 | 18.1 | 17.0 | -6.3 | 16.6 | -8.2 |
| even-aged natural | Medium (264) | 100 | 21.4 | 19.1 | -10.9 | 18.8 | -12.3 |
| even-aged natural | High (450) | 20 | 13.7 | 13.7 | -0.4 | 13.4 | -2.5 |
| even-aged natural | High (450) | 40 | 18.0 | 16.8 | -6.4 | 16.5 | -8.4 |
| even-aged natural | High (450) | 60 | 20.8 | 18.7 | -10.0 | 18.3 | -11.7 |
| even-aged natural | High (450) | 100 | 24.2 | 20.9 | -13.7 | 20.6 | -15.0 |
| even-aged planted | Low (100) | 20 | 14.7 | 14.3 | -2.6 | 14.5 | -1.1 |
| even-aged planted | Low (100) | 40 | 18.2 | 16.8 | -7.5 | 17.3 | -5.2 |
| even-aged planted | Low (100) | 60 | 20.4 | 18.3 | -10.3 | 18.8 | -7.6 |
| even-aged planted | Low (100) | 100 | 21.3 | 20.0 | -6.2 | 20.7 | -3.0 |
| even-aged planted | Medium (264) | 20 | 17.5 | 16.2 | -7.8 | 16.5 | -6.2 |
| even-aged planted | Medium (264) | 40 | 21.5 | 18.8 | -12.3 | 19.4 | -9.9 |
| even-aged planted | Medium (264) | 60 | 22.3 | 20.4 | -8.8 | 21.0 | -6.1 |
| even-aged planted | Medium (264) | 100 | 23.0 | 22.1 | -3.8 | 22.8 | -0.7 |
| even-aged planted | High (450) | 20 | 19.9 | 17.8 | -10.4 | 18.2 | -8.7 |
| even-aged planted | High (450) | 40 | 23.4 | 20.6 | -11.8 | 21.2 | -9.3 |
| even-aged planted | High (450) | 60 | 24.2 | 22.2 | -8.0 | 22.9 | -5.2 |
| even-aged planted | High (450) | 100 | 24.5 | 23.8 | -2.9 | 24.4 | -0.4 |
| uneven-aged natural | Low (100) | 20 | 8.6 | 10.0 | +15.5 |  |  |
| uneven-aged natural | Low (100) | 40 | 12.7 | 13.5 | +6.1 |  |  |
| uneven-aged natural | Low (100) | 60 | 15.3 | 15.6 | +1.8 |  |  |
| uneven-aged natural | Low (100) | 100 | 18.6 | 18.1 | -2.6 |  |  |
| uneven-aged natural | Medium (264) | 20 | 11.4 | 11.8 | +3.2 |  |  |
| uneven-aged natural | Medium (264) | 40 | 16.1 | 15.7 | -2.7 |  |  |
| uneven-aged natural | Medium (264) | 60 | 18.9 | 17.9 | -5.5 |  |  |
| uneven-aged natural | Medium (264) | 100 | 22.2 | 20.4 | -8.1 |  |  |
| uneven-aged natural | High (450) | 20 | 13.6 | 13.3 | -2.2 |  |  |
| uneven-aged natural | High (450) | 40 | 18.7 | 17.5 | -6.4 |  |  |
| uneven-aged natural | High (450) | 60 | 21.6 | 19.7 | -8.5 |  |  |
| uneven-aged natural | High (450) | 100 | 24.8 | 22.3 | -10.3 |  |  |

### BAPH

| Scenario | Site (BYI) | Age | BAPH v102 | BAPH refit | pct refit | BAPH refit_live | pct refit_live |
|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 8.9 | 12.8 | +44.9 | 12.2 | +37.8 |
| even-aged natural | Low (100) | 40 | 14.5 | 20.2 | +39.1 | 19.4 | +33.3 |
| even-aged natural | Low (100) | 60 | 19.1 | 24.9 | +30.4 | 24.2 | +26.5 |
| even-aged natural | Low (100) | 100 | 24.3 | 29.1 | +19.8 | 28.9 | +19.1 |
| even-aged natural | Medium (264) | 20 | 12.0 | 15.2 | +26.3 | 14.5 | +20.3 |
| even-aged natural | Medium (264) | 40 | 19.4 | 23.1 | +19.3 | 22.3 | +15.2 |
| even-aged natural | Medium (264) | 60 | 24.1 | 27.6 | +14.9 | 27.1 | +12.5 |
| even-aged natural | Medium (264) | 100 | 29.0 | 31.5 | +8.4 | 31.6 | +9.0 |
| even-aged natural | High (450) | 20 | 14.1 | 16.6 | +18.0 | 15.9 | +12.6 |
| even-aged natural | High (450) | 40 | 22.0 | 24.7 | +12.7 | 24.0 | +9.3 |
| even-aged natural | High (450) | 60 | 26.4 | 29.1 | +10.2 | 28.6 | +8.4 |
| even-aged natural | High (450) | 100 | 31.0 | 32.7 | +5.4 | 33.0 | +6.4 |
| even-aged planted | Low (100) | 20 | 39.6 | 41.1 | +3.8 | 42.1 | +6.4 |
| even-aged planted | Low (100) | 40 | 51.9 | 49.8 | -4.0 | 51.9 | -0.1 |
| even-aged planted | Low (100) | 60 | 58.1 | 54.0 | -7.2 | 56.5 | -2.7 |
| even-aged planted | Low (100) | 100 | 61.6 | 55.9 | -9.2 | 60.7 | -1.6 |
| even-aged planted | Medium (264) | 20 | 46.9 | 44.9 | -4.3 | 46.2 | -1.4 |
| even-aged planted | Medium (264) | 40 | 58.0 | 52.7 | -9.2 | 55.0 | -5.2 |
| even-aged planted | Medium (264) | 60 | 61.6 | 56.5 | -8.3 | 59.3 | -3.6 |
| even-aged planted | Medium (264) | 100 | 61.9 | 58.0 | -6.3 | 62.8 | +1.5 |
| even-aged planted | High (450) | 20 | 50.6 | 46.9 | -7.4 | 48.4 | -4.4 |
| even-aged planted | High (450) | 40 | 59.8 | 54.2 | -9.4 | 56.7 | -5.3 |
| even-aged planted | High (450) | 60 | 63.4 | 57.8 | -8.7 | 60.8 | -4.0 |
| even-aged planted | High (450) | 100 | 60.6 | 58.2 | -4.0 | 62.8 | +3.5 |
| uneven-aged natural | Low (100) | 20 | 12.2 | 16.8 | +37.8 |  |  |
| uneven-aged natural | Low (100) | 40 | 24.2 | 29.1 | +19.9 |  |  |
| uneven-aged natural | Low (100) | 60 | 30.5 | 35.5 | +16.4 |  |  |
| uneven-aged natural | Low (100) | 100 | 39.2 | 43.4 | +10.5 |  |  |
| uneven-aged natural | Medium (264) | 20 | 18.2 | 20.5 | +12.2 |  |  |
| uneven-aged natural | Medium (264) | 40 | 29.3 | 32.4 | +10.7 |  |  |
| uneven-aged natural | Medium (264) | 60 | 35.5 | 38.4 | +8.1 |  |  |
| uneven-aged natural | Medium (264) | 100 | 45.1 | 46.2 | +2.4 |  |  |
| uneven-aged natural | High (450) | 20 | 21.6 | 22.6 | +4.9 |  |  |
| uneven-aged natural | High (450) | 40 | 31.7 | 34.0 | +7.2 |  |  |
| uneven-aged natural | High (450) | 60 | 38.2 | 39.8 | +4.3 |  |  |
| uneven-aged natural | High (450) | 100 | 48.4 | 47.7 | -1.5 |  |  |

### TPH

| Scenario | Site (BYI) | Age | TPH v102 | TPH refit | pct refit | TPH refit_live | pct refit_live |
|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 423.2 | 429.4 | +1.5 | 437.5 | +3.4 |
| even-aged natural | Low (100) | 40 | 350.8 | 353.3 | +0.7 | 368.7 | +5.1 |
| even-aged natural | Low (100) | 60 | 288.2 | 299.0 | +3.8 | 316.7 | +9.9 |
| even-aged natural | Low (100) | 100 | 194.0 | 224.9 | +15.9 | 241.5 | +24.5 |
| even-aged natural | Medium (264) | 20 | 407.4 | 408.9 | +0.4 | 419.6 | +3.0 |
| even-aged natural | Medium (264) | 40 | 301.0 | 321.5 | +6.8 | 338.9 | +12.6 |
| even-aged natural | Medium (264) | 60 | 226.1 | 266.7 | +18.0 | 284.5 | +25.9 |
| even-aged natural | Medium (264) | 100 | 145.0 | 199.5 | +37.5 | 215.4 | +48.5 |
| even-aged natural | High (450) | 20 | 383.0 | 394.9 | +3.1 | 407.0 | +6.3 |
| even-aged natural | High (450) | 40 | 262.5 | 302.8 | +15.4 | 320.8 | +22.2 |
| even-aged natural | High (450) | 60 | 189.8 | 248.9 | +31.2 | 266.5 | +40.4 |
| even-aged natural | High (450) | 100 | 119.6 | 185.7 | +55.3 | 201.0 | +68.1 |
| even-aged planted | Low (100) | 20 | 701.4 | 665.5 | -5.1 | 649.9 | -7.3 |
| even-aged planted | Low (100) | 40 | 453.7 | 484.3 | +6.8 | 448.6 | -1.1 |
| even-aged planted | Low (100) | 60 | 336.9 | 403.3 | +19.7 | 359.1 | +6.6 |
| even-aged planted | Low (100) | 100 | 249.7 | 302.9 | +21.3 | 265.3 | +6.2 |
| even-aged planted | Medium (264) | 20 | 566.7 | 593.1 | +4.7 | 571.8 | +0.9 |
| even-aged planted | Medium (264) | 40 | 344.3 | 429.8 | +24.8 | 390.1 | +13.3 |
| even-aged planted | Medium (264) | 60 | 275.7 | 357.5 | +29.7 | 311.6 | +13.0 |
| even-aged planted | Medium (264) | 100 | 204.1 | 268.5 | +31.6 | 230.3 | +12.8 |
| even-aged planted | High (450) | 20 | 497.0 | 554.2 | +11.5 | 530.1 | +6.7 |
| even-aged planted | High (450) | 40 | 305.9 | 401.4 | +31.2 | 360.3 | +17.8 |
| even-aged planted | High (450) | 60 | 246.1 | 333.8 | +35.7 | 287.6 | +16.9 |
| even-aged planted | High (450) | 100 | 184.9 | 250.7 | +35.5 | 212.7 | +15.0 |
| uneven-aged natural | Low (100) | 20 | 635.3 | 581.1 | -8.5 |  |  |
| uneven-aged natural | Low (100) | 40 | 412.0 | 417.7 | +1.4 |  |  |
| uneven-aged natural | Low (100) | 60 | 283.5 | 316.3 | +11.5 |  |  |
| uneven-aged natural | Low (100) | 100 | 188.8 | 233.5 | +23.6 |  |  |
| uneven-aged natural | Medium (264) | 20 | 494.2 | 511.3 | +3.5 |  |  |
| uneven-aged natural | Medium (264) | 40 | 273.8 | 340.2 | +24.2 |  |  |
| uneven-aged natural | Medium (264) | 60 | 194.8 | 263.3 | +35.2 |  |  |
| uneven-aged natural | Medium (264) | 100 | 137.5 | 201.0 | +46.2 |  |  |
| uneven-aged natural | High (450) | 20 | 407.9 | 470.5 | +15.4 |  |  |
| uneven-aged natural | High (450) | 40 | 223.3 | 306.7 | +37.4 |  |  |
| uneven-aged natural | High (450) | 60 | 162.0 | 240.0 | +48.1 |  |  |
| uneven-aged natural | High (450) | 100 | 117.7 | 186.0 | +58.1 |  |  |

### MAI

| Scenario | Site (BYI) | Age | MAI v102 | MAI refit | pct refit | MAI refit_live | pct refit_live |
|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 1.8 | 2.8 | +59.1 | 2.6 | +48.1 |
| even-aged natural | Low (100) | 40 | 1.8 | 2.7 | +47.3 | 2.5 | +38.0 |
| even-aged natural | Low (100) | 60 | 1.9 | 2.5 | +32.5 | 2.4 | +25.9 |
| even-aged natural | Low (100) | 100 | 1.7 | 2.0 | +14.7 | 1.9 | +12.1 |
| even-aged natural | Medium (264) | 20 | 2.9 | 3.8 | +30.8 | 3.5 | +21.9 |
| even-aged natural | Medium (264) | 40 | 3.0 | 3.5 | +16.6 | 3.3 | +10.1 |
| even-aged natural | Medium (264) | 60 | 2.9 | 3.1 | +7.6 | 3.0 | +3.3 |
| even-aged natural | Medium (264) | 100 | 2.5 | 2.4 | -3.4 | 2.4 | -4.4 |
| even-aged natural | High (450) | 20 | 3.9 | 4.6 | +17.6 | 4.3 | +9.7 |
| even-aged natural | High (450) | 40 | 3.9 | 4.2 | +5.5 | 3.9 | +0.1 |
| even-aged natural | High (450) | 60 | 3.7 | 3.6 | -0.8 | 3.5 | -4.3 |
| even-aged natural | High (450) | 100 | 3.0 | 2.7 | -9.1 | 2.7 | -9.6 |
| even-aged planted | Low (100) | 20 | 11.6 | 11.7 | +1.1 | 12.2 | +5.2 |
| even-aged planted | Low (100) | 40 | 9.5 | 8.4 | -11.3 | 9.0 | -5.3 |
| even-aged planted | Low (100) | 60 | 7.9 | 6.6 | -16.7 | 7.1 | -10.1 |
| even-aged planted | Low (100) | 100 | 5.3 | 4.5 | -14.9 | 5.0 | -4.5 |
| even-aged planted | Medium (264) | 20 | 16.5 | 14.5 | -11.8 | 15.2 | -7.5 |
| even-aged planted | Medium (264) | 40 | 12.5 | 9.9 | -20.4 | 10.6 | -14.6 |
| even-aged planted | Medium (264) | 60 | 9.2 | 7.7 | -16.4 | 8.3 | -9.5 |
| even-aged planted | Medium (264) | 100 | 5.7 | 5.1 | -9.8 | 5.7 | +0.8 |
| even-aged planted | High (450) | 20 | 20.1 | 16.7 | -17.0 | 17.6 | -12.7 |
| even-aged planted | High (450) | 40 | 14.0 | 11.2 | -20.1 | 12.0 | -14.1 |
| even-aged planted | High (450) | 60 | 10.2 | 8.6 | -16.0 | 9.3 | -9.1 |
| even-aged planted | High (450) | 100 | 5.9 | 5.5 | -6.8 | 6.1 | +3.1 |
| uneven-aged natural | Low (100) | 20 | 2.1 | 3.4 | +59.2 |  |  |
| uneven-aged natural | Low (100) | 40 | 3.1 | 3.9 | +27.2 |  |  |
| uneven-aged natural | Low (100) | 60 | 3.1 | 3.7 | +18.5 |  |  |
| uneven-aged natural | Low (100) | 100 | 2.9 | 3.1 | +7.7 |  |  |
| uneven-aged natural | Medium (264) | 20 | 4.2 | 4.8 | +15.8 |  |  |
| uneven-aged natural | Medium (264) | 40 | 4.7 | 5.1 | +7.7 |  |  |
| uneven-aged natural | Medium (264) | 60 | 4.5 | 4.6 | +2.1 |  |  |
| uneven-aged natural | Medium (264) | 100 | 4.0 | 3.8 | -5.9 |  |  |
| uneven-aged natural | High (450) | 20 | 5.9 | 6.0 | +2.5 |  |  |
| uneven-aged natural | High (450) | 40 | 5.9 | 5.9 | +0.3 |  |  |
| uneven-aged natural | High (450) | 60 | 5.5 | 5.2 | -4.6 |  |  |
| uneven-aged natural | High (450) | 100 | 4.8 | 4.3 | -11.6 |  |  |

## 6. Net MAI culmination

Two definitions. track2 is the compare_v102.py rule (argmax of VOL/age over years 10 to 300 for natural stands, 2 to 300 for planted, asterisk when the maximum sits at the window start so there is no interior culmination). afterMin is the rule requested for this job (maximum of net MAI after its first local minimum on the full 300 year path, none when MAI never falls first).

| scenario | site | culm_track2_v102 | culm_track2_refit | culm_track2_refit_live | culm_afterMin_v102 | culm_afterMin_refit | culm_afterMin_refit_live | MAI_at_culm_track2_v102 | MAI_at_culm_track2_refit | peakVOL_age_v102 | peakVOL_age_refit | peakVOL_v102 | peakVOL_refit |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 10* | 10* | 10* | 59 | 23 | none | 1.97 | 2.84 | 171 | 135 | 207.34 | 209.06 |
| even-aged natural | Medium (264) | 39 | 20 | 10* | 39 | 20 | 20 | 3.02 | 3.76 | 153 | 127 | 282.08 | 248.58 |
| even-aged natural | High (450) | 31 | 19 | 19 | 31 | 19 | 19 | 3.99 | 4.56 | 124 | 123 | 324.06 | 280.15 |
| even-aged planted | Low (100) | 13 | 9 | 9 | 13 | 9 | 9 | 12.08 | 13.92 | 105 | 113 | 528.35 | 450.00 |
| even-aged planted | Medium (264) | 10 | 7 | 7 | none | none | none | 18.67 | 18.83 | 84 | 105 | 577.03 | 514.63 |
| even-aged planted | High (450) | 8 | 7 | 7 | none | none | none | 24.37 | 23.00 | 77 | 90 | 626.60 | 564.71 |


## 7. Validation, 23 plots

Aggregates, bias is projected minus observed (survival fraction, QMD cm, basal area m2 per ha). Observed columns and plot identities are identical between v102 and refit.

| frame | group | n | surv_r | surv_bias | surv_RMSE | qmd_r | qmd_bias | qmd_RMSE | ba_r | ba_bias | ba_RMSE |
|---|---|---|---|---|---|---|---|---|---|---|---|
| v102 | all | 23 | 0.7144 | 0.1163 | 0.2635 | 0.9113 | -1.6684 | 2.9356 | 0.5503 | 0.3053 | 12.4321 |
| v102 | natural | 12 | 0.7249 | 0.1978 | 0.3177 | 0.8166 | -1.5385 | 3.0467 | 0.5779 | 4.1128 | 10.5308 |
| v102 | planted | 11 | 0.4815 | 0.0274 | 0.1871 | 0.9506 | -1.8102 | 2.8094 | 0.4751 | -3.8482 | 14.2192 |
| refit | all | 23 | 0.7100 | 0.1049 | 0.2597 | 0.9107 | -0.5652 | 2.4437 | 0.5101 | 3.3536 | 13.2693 |
| refit | natural | 12 | 0.7385 | 0.2044 | 0.3175 | 0.9353 | -0.6093 | 2.0192 | 0.6176 | 7.5361 | 11.9651 |
| refit | planted | 11 | 0.5472 | -0.0036 | 0.1763 | 0.9116 | -0.5171 | 2.8353 | 0.3859 | -1.2090 | 14.5594 |
| refit_live | all | 23 | 0.6886 | 0.1166 | 0.2725 | 0.8955 | -0.7036 | 2.6752 | 0.4889 | 3.0884 | 13.4521 |
| refit_live | natural | 12 | 0.7108 | 0.2207 | 0.3406 | 0.8994 | -0.5581 | 2.0260 | 0.6662 | 7.6180 | 11.6540 |
| refit_live | planted | 11 | 0.5952 | 0.0030 | 0.1693 | 0.8904 | -0.8623 | 3.2383 | 0.3347 | -1.8530 | 15.1725 |
| refit2 | all | 23 | 0.7522 | 0.0935 | 0.2405 | 0.8817 | -0.6581 | 2.8030 | 0.4846 | 2.0333 | 13.2157 |
| refit2 | natural | 12 | 0.7582 | 0.1716 | 0.2876 | 0.8483 | -0.5046 | 2.6098 | 0.5527 | 5.9014 | 11.5076 |
| refit2 | planted | 11 | 0.5575 | 0.0083 | 0.1752 | 0.9159 | -0.8257 | 2.9996 | 0.3816 | -2.1864 | 14.8568 |
| refit2_live | all | 23 | 0.7324 | 0.0990 | 0.2506 | 0.8832 | -0.0505 | 2.9982 | 0.4618 | 2.7693 | 13.6448 |
| refit2_live | natural | 12 | 0.7357 | 0.1843 | 0.3071 | 0.8811 | 0.4871 | 2.2051 | 0.6271 | 7.1444 | 11.6604 |
| refit2_live | planted | 11 | 0.6020 | 0.0058 | 0.1684 | 0.8849 | -0.6370 | 3.6729 | 0.3331 | -2.0035 | 15.5228 |


25 percent equivalence on the mean (TOST, 90 percent plot bootstrap interval of mean observed minus mean predicted inside plus or minus 25 percent of the observed mean) and on the slope (0.75 to 1.25), as compare_v102.py.

| frame | group | quantity | n | mean_obs | bias_obs_minus_pred | bias_lo | bias_hi | region_bias | pass_bias | slope | slope_lo | slope_hi | pass_slope |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v102 | all | surv | 23 | 0.595 | -0.116 | -0.201 | -0.038 | 0.149 | False | 0.902 | 0.745 | 1.173 | False |
| v102 | all | qmd | 23 | 23.599 | 1.668 | 0.856 | 2.499 | 5.900 | True | 0.908 | 0.766 | 1.038 | True |
| v102 | all | ba | 23 | 21.845 | -0.305 | -4.634 | 3.946 | 5.461 | True | 0.997 | 0.396 | 2.010 | False |
| v102 | natural | surv | 12 | 0.428 | -0.198 | -0.321 | -0.082 | 0.107 | False | 0.754 | 0.468 | 1.094 | False |
| v102 | natural | qmd | 12 | 24.381 | 1.539 | 0.310 | 2.835 | 6.095 | True | 0.849 | 0.536 | 1.166 | False |
| v102 | natural | ba | 12 | 16.036 | -4.113 | -8.587 | 0.670 | 4.009 | False | 1.174 | 0.489 | 3.444 | False |
| v102 | planted | surv | 11 | 0.778 | -0.027 | -0.121 | 0.063 | 0.195 | True | 0.875 | -0.750 | 1.884 | False |
| v102 | planted | qmd | 11 | 22.747 | 1.810 | 0.736 | 2.883 | 5.687 | True | 0.934 | 0.768 | 1.137 | True |
| v102 | planted | ba | 11 | 28.182 | 3.848 | -3.307 | 10.414 | 7.046 | False | 0.745 | -0.074 | 2.052 | False |
| refit | all | surv | 23 | 0.595 | -0.105 | -0.190 | -0.027 | 0.149 | False | 0.912 | 0.714 | 1.142 | False |
| refit | all | qmd | 23 | 23.599 | 0.565 | -0.249 | 1.383 | 5.900 | True | 1.050 | 0.838 | 1.318 | False |
| refit | all | ba | 23 | 21.845 | -3.354 | -7.760 | 1.066 | 5.461 | False | 0.889 | 0.355 | 1.806 | False |
| refit | natural | surv | 12 | 0.428 | -0.204 | -0.326 | -0.092 | 0.107 | False | 0.765 | 0.476 | 1.096 | False |
| refit | natural | qmd | 12 | 24.381 | 0.609 | -0.343 | 1.509 | 6.095 | True | 1.374 | 1.093 | 1.642 | False |
| refit | natural | ba | 12 | 16.036 | -7.536 | -11.878 | -3.064 | 4.009 | False | 0.978 | 0.363 | 1.972 | False |
| refit | planted | surv | 11 | 0.778 | 0.004 | -0.085 | 0.088 | 0.195 | True | 0.988 | -0.585 | 2.052 | False |
| refit | planted | qmd | 11 | 22.747 | 0.517 | -0.884 | 1.885 | 5.687 | True | 0.971 | 0.709 | 1.355 | False |
| refit | planted | ba | 11 | 28.182 | 1.209 | -6.272 | 8.221 | 7.046 | False | 0.637 | -0.300 | 2.378 | False |
| refit_live | all | surv | 23 | 0.595 | -0.117 | -0.204 | -0.036 | 0.149 | False | 0.863 | 0.663 | 1.088 | False |
| refit_live | all | qmd | 23 | 23.599 | 0.704 | -0.179 | 1.594 | 5.900 | True | 0.925 | 0.729 | 1.190 | False |
| refit_live | all | ba | 23 | 21.845 | -3.088 | -7.591 | 1.394 | 5.461 | False | 0.813 | 0.315 | 1.680 | False |
| refit_live | natural | surv | 12 | 0.428 | -0.221 | -0.349 | -0.100 | 0.107 | False | 0.713 | 0.439 | 1.029 | False |
| refit_live | natural | qmd | 12 | 24.381 | 0.558 | -0.360 | 1.506 | 6.095 | True | 0.939 | 0.710 | 1.244 | False |
| refit_live | natural | ba | 12 | 16.036 | -7.618 | -11.742 | -3.438 | 4.009 | False | 0.954 | 0.380 | 1.726 | False |
| refit_live | planted | surv | 11 | 0.778 | -0.003 | -0.088 | 0.079 | 0.195 | True | 1.050 | -0.615 | 1.978 | False |
| refit_live | planted | qmd | 11 | 22.747 | 0.862 | -0.727 | 2.398 | 5.687 | True | 0.922 | 0.644 | 1.416 | False |
| refit_live | planted | ba | 11 | 28.182 | 1.853 | -5.950 | 9.066 | 7.046 | False | 0.541 | -0.341 | 2.406 | False |
| refit2 | all | surv | 23 | 0.595 | -0.093 | -0.174 | -0.021 | 0.149 | False | 0.957 | 0.794 | 1.187 | True |
| refit2 | all | qmd | 23 | 23.599 | 0.658 | -0.296 | 1.595 | 5.900 | True | 0.932 | 0.739 | 1.196 | False |
| refit2 | all | ba | 23 | 21.845 | -2.033 | -6.592 | 2.503 | 5.461 | False | 0.879 | 0.288 | 2.117 | False |
| refit2 | natural | surv | 12 | 0.428 | -0.172 | -0.287 | -0.064 | 0.107 | False | 0.810 | 0.510 | 1.128 | False |
| refit2 | natural | qmd | 12 | 24.381 | 0.505 | -0.775 | 1.699 | 6.095 | True | 1.385 | 0.905 | 1.800 | False |
| refit2 | natural | ba | 12 | 16.036 | -5.901 | -10.432 | -1.007 | 4.009 | False | 1.143 | 0.461 | 3.277 | False |
| refit2 | planted | surv | 11 | 0.778 | -0.008 | -0.096 | 0.077 | 0.195 | True | 0.935 | -0.703 | 1.778 | False |
| refit2 | planted | qmd | 11 | 22.747 | 0.826 | -0.663 | 2.211 | 5.687 | True | 0.865 | 0.632 | 1.212 | False |
| refit2 | planted | ba | 11 | 28.182 | 2.186 | -5.414 | 9.247 | 7.046 | False | 0.594 | -0.225 | 2.307 | False |
| refit2_live | all | surv | 23 | 0.595 | -0.099 | -0.181 | -0.024 | 0.149 | False | 0.902 | 0.745 | 1.107 | False |
| refit2_live | all | qmd | 23 | 23.599 | 0.051 | -0.999 | 1.054 | 5.900 | True | 0.791 | 0.615 | 1.022 | False |
| refit2_live | all | ba | 23 | 21.845 | -2.769 | -7.441 | 1.806 | 5.461 | False | 0.770 | 0.247 | 1.891 | False |
| refit2_live | natural | surv | 12 | 0.428 | -0.184 | -0.307 | -0.069 | 0.107 | False | 0.752 | 0.468 | 1.057 | False |
| refit2_live | natural | qmd | 12 | 24.381 | -0.487 | -1.503 | 0.562 | 6.095 | True | 0.884 | 0.638 | 1.244 | False |
| refit2_live | natural | ba | 12 | 16.036 | -7.144 | -11.386 | -2.678 | 4.009 | False | 1.070 | 0.439 | 2.225 | False |
| refit2_live | planted | surv | 11 | 0.778 | -0.006 | -0.090 | 0.076 | 0.195 | True | 0.938 | -0.723 | 1.640 | False |
| refit2_live | planted | qmd | 11 | 22.747 | 0.637 | -1.295 | 2.293 | 5.687 | True | 0.771 | 0.525 | 1.228 | False |
| refit2_live | planted | ba | 11 | 28.182 | 2.004 | -6.075 | 9.319 | 7.046 | False | 0.487 | -0.261 | 2.309 | False |


## 8. Live list sensitivity (engine_refit_live)

Coefficients dDBH_l_AP and dHT_l_AP (percentile BAL over the live list, which is what the current engine computes on a projected list), cohort fraction row bal == l written into BAL_COHORT_LIN_B, BAL_DEFINITION percentile, its own mortality level solve. The six even aged trajectories are in the tables of section 5 (refit_live columns) and its validation is included in section 7 for completeness. The refit_live arm moves in the same direction as the deployed conventional arm at every natural cell and is milder on the planted sites (planted volume at age 40 minus 5 to minus 15 percent against minus 11 to minus 20 percent).

## 9. Not completed, caveats

1. CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG are v102 placeholders until out/c_bootstrap.csv exists (patch_selog_refit.py is staged). The trajectories and validation do not read them; the Monte Carlo drivers (regen_m1, joint draws) do.
2. The Monte Carlo (regen_m1 out_m1, joint draws, Table 8 intervals, figures) and the number registry were NOT rerun. Only the M0 point paths, the uneven aged point path and the 23 plot point validation were produced.
3. HCB_P keeps its percentile fitted coefficients while receiving conventional BAL (lead's decision).
4. The HiGy.R mirror edits go beyond what v102 did (v102 left the increment tribbles at the constants of record). They mirror the Python numbers and forms; the parity harness parity_r_050.R / parity_python_050.py was not rerun, and the Stage 1 constants in HiGy.R remain stale as in v102 (DEVIATION V102-D2).
5. The Garcia stand mortality constants, Stage 1 and Stage 2, the survival vector, the static height vector and ingrowth are carried from v102 unchanged.
6. The dHT fit form: the R refit used b7 x Planted x HT untruncated, while the engine (as since 16 September 2026) applies b7 x planted x min(HT, 20 m). The mirror follows the engine. This discrepancy predates this job and is unchanged.
7. bal_conventional uses pi / 40000 for per tree basal area while the projector's BAPH uses 0.00007854; the relative difference is 5e-6 and BAL can exceed BAPH by that amount on a single dominant. Stated for completeness.
8. Under the afterMin culmination rule the natural low site now culminates at year 23 (v102: 59) and the planted medium and high sites have no culmination under either engine because MAI declines monotonically from year 2.


# Second pass (refit2), 30 September 2026

The red team rejected the AP fits (size response and sign flips) and found the deposited plot-year BAPH and TPH doubled on 29 plot-years (out/plotyear_repair_log.csv). refit2.R repaired those covariates, fitted on the NO frame (NO (consecutive pairs plus first-to-last per tree, tree random intercept)), used HCB_P for CR and the 45 cm and 20 m planted guards inside the recursion, and conventional BAL as the direct expansion weighted sum. Deployed choice out/deployed_choice2.json: dDBH_c_NO (n 4969) and dHT_c_NO (n 4033), cohort fraction row c a0 0.74373, a1 -0.05094 (mean fraction 0.6087). Rule as recorded in the json: refit2 preregistered rule: sign checks and two-frame equivalence; dDBH_c_NO passes both; no dHT fit passes the intercept at exactly 25 percent (dHT_l_NO 25.1, dHT_c_NO 28.5 and 26.0 percent), dHT_c_NO deployed by stated deviation because it beats the incumbent v102 vector on both components (slope 0.99 vs 0.83, intercept region 0.29 vs 0.34) and keeps one BAL definition across the system

engine_refit and engine_refit_live from the first pass are left in place. The chain was repeated as engine_refit2 (deployed candidate) and engine_refit2_live (live list alternative dDBH_l_NO, dHT_l_NO, cohort row l).

## S1. Gate

engine_v102 copied fresh to engine_refit2, BAL_DEFINITION switch installed with the same patch_bal_switch.py, run_engine.py tag gate3 with the switch at percentile: traj_gate3.csv against traj_v102.csv 0.000e+00 on every numeric column, val_gate3.csv against val_v102.csv 0.000e+00, PASS (logs/gate3_compare.txt).

## S2. Constants, old (engine_v102) against new (engine_refit2)

| name | old | new | note |
|---|---|---|---|
| DDBH_b0 | -1.1509411 | -0.0289436398354308 |  |
| DHT_b0 | -3.6114059 | -2.71977559666745 |  |
| DDBH_b1 | 0.3371168 | 0.338470268718732 |  |
| DHT_b1 | 1.1203441 | 1.13354486286027 |  |
| DDBH_b2 | -0.0143456 | -0.0172324921350166 |  |
| DHT_b2 | -0.1154809 | -0.10828768002196 |  |
| DDBH_b3 | -0.0017722 | -0.00342414489616872 |  |
| DHT_b3 | -0.0009067 | -0.000252702455801308 |  |
| DDBH_b4 | -0.4306515 | -0.239369734949266 |  |
| DHT_b4 | -0.1332027 | -0.11652679312275 |  |
| DDBH_b5 | 1.2809352 | 0.899430851896873 |  |
| DHT_b5 | -0.5250905 | 0.260360591825496 |  |
| DDBH_b6 | -0.0176013 | -0.0143202805857141 |  |
| DHT_b6 | 0.0379597 | 0.0292536028533531 |  |
| DDBH_b7 | -0.0176238 | -0.0220406131909561 |  |
| DHT_b7 | -0.124088 | -0.116050483635868 |  |
| DDBH_b8 | 0.3045245 | 0.129689727330333 |  |
| DHT_b8 | 0.2232825 | 0.155406126220152 |  |
| DDBH_b9 | 0.4103534 | -0.0650440494165983 |  |
| DHT_b9 | 1.0681935 | 0.798282628703745 |  |
| CAL_DDBH_natural | (0.40548, 1.43606) | 0.3338344262319585 |  |
| CAL_DDBH_planted | (0.40548, 1.43606) | 1.472155293110641 |  |
| CAL_DHT_natural | (0.51917, 2.64739) | 0.2291226135409648 |  |
| CAL_DHT_planted | (0.51917, 2.64739) | 1.3096722117894697 |  |
| CAL_DDBH_SE_LOG_natural | (0.07956, 0.05225) | 0.07956 | PLACEHOLDER: v102 value, no c bootstrap exists for the NO fits |
| CAL_DDBH_SE_LOG_planted | (0.07956, 0.05225) | 0.05225 | PLACEHOLDER: v102 value, no c bootstrap exists for the NO fits |
| CAL_DHT_SE_LOG_natural | (0.14862, 0.04807) | 0.14862 | PLACEHOLDER: v102 value, no c bootstrap exists for the NO fits |
| CAL_DHT_SE_LOG_planted | (0.14862, 0.04807) | 0.04807 | PLACEHOLDER: v102 value, no c bootstrap exists for the NO fits |
| CF_DDBH_MARGINAL | 1.36869 | 1.56025392685074 |  |
| CF_DHT | 1.030 | 2.02681111706053 |  |
| BAL_DEFINITION | percentile | conventional |  |
| BAL_COHORT_LIN_B_CONVENTIONAL_a0 | (0.773485460160129, -0.0570969153432526) | 0.743733501799217 |  |
| BAL_COHORT_LIN_B_CONVENTIONAL_a1 | (0.773485460160129, -0.0570969153432526) | -0.0509419234788266 |  |
| HiGy_cf_ddbh | 1.026 | 1.56025392685074 |  |
| HiGy_cf_dht | 1.03 | 2.02681111706053 |  |
| HiGy_ddbh_planted_trunc_cm | 40 | 45 |  |
| HiGy_dht_planted_term | sqrt(planted*pmin(ht,20)) | planted*pmin(ht,20) |  |
| HiGy_CAL_DDBH | none (1,1) | (0.33383, 1.47216) |  |
| HiGy_CAL_DHT | none (1,1) | (0.22912, 1.30967) |  |
| HiGy_ddbh.parm_site | record vector (-2.4704737 ...) | refit b0..b9 |  |
| HiGy_dht.parm_site | record vector (-3.382162 ...) | refit b0..b9 |  |
| MORT_CAL_natural | 2.6462860696589208 | 2.360331792993119 |  |
| MORT_CAL_SE_LOG_natural | 0.1817204503423178 | 0.1521881284982772 |  |


CF_DDBH_MARGINAL 1.36869 to 1.56025; CF_DHT 1.030 to 2.02681. CAL_DDBH (0.33383, 1.47216), CAL_DHT (0.22912, 1.30967), so the total per step multipliers c are dDBH 0.52087 natural and 2.29694 planted (v102 0.55498 and 1.96553), dHT 0.46439 and 2.65446 (v102 0.53475 and 2.72681). Unlike the AP pass these sit close to the v102 pattern. CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG keep the v102 PLACEHOLDERS (0.07956, 0.05225) and (0.14862, 0.04807); no c bootstrap exists for the NO fits. HiGy.R mirrored as in the first pass (tribbles, b9, cf times origin multiplier, 45 cm guard, linear planted height term, KOA_* constants); parses in R. HCB_P unchanged.

## S3. Observed plot values and the 29 repaired plot-years

Neither consumer reads the deposited plot-year BAPH or TPH. koa_longterm_validation.validate computes tph0 and baph0 at the interval start and obsQMD and obsBAPH at the end from the live tree records with EXPF (lines 121 to 125 and 142 to 145), and calib_mort.py computes tph0, baph0 and obs_surv the same way from the live list (lines 48 to 53); solve_mort.py reads only tph0 and obs_surv. The deposited TPH and BAPH columns of AK_TREE.csv (doubled, deposited over repaired TPH ratio 1.909 to 2.651) are carried in the table but never read. check_observed_repair.py confirms that for all 29 plot-years the engine's live list values equal the repaired values of out/plotyear_repair_log.csv to 1e-6 (out/observed_repair_check.csv). The repaired plot-years touch 4 of 23 validation intervals and 3 of 23 calibration intervals (out/observed_repair_intervals.csv, listed below), and on each of them the observed values used were already the live list values, so the repair changes nothing in either the calibration or the validation: the repaired and unrepaired runs are numerically identical. No separate refit2_unrepairedobs run was produced because there is no code path that would make it differ; the validation observed columns are identical across v102, refit, and refit2 (compare_refit.py check).

| use | pid | m_from | m_to | repaired_plotyear |
|---|---|---|---|---|
| validation | DOFAW|Waiakea|24 | 1968 | 2001 | DOFAW|Waiakea|24|1968 |
| validation | PSP|202|2 | 2012 | 2017 | PSP|202|2|2017 |
| validation | PSP|203|3 | 2012 | 2017 | PSP|203|3|2017 |
| validation | PSP|204|4 | 2012 | 2017 | PSP|204|4|2017 |
| calibration | DOFAW|Kulani|23 | 1985 | 1994 | DOFAW|Kulani|23|1994 |
| calibration | DOFAW|Kulani|23 | 1994 | 2001 | DOFAW|Kulani|23|1994 |
| calibration | DOFAW|Waiakea|24 | 1968 | 1973 | DOFAW|Waiakea|24|1968 |


## S4. Natural mortality level factor

MORT_CAL natural: v102 2.64629, refit (AP) 1.85561, refit2 2.36033, plot cluster bootstrap 95 percent 1.8792 to 3.4091, SD log k 0.15219, installation cluster 1.8845 to 3.1434, LOIO 2.1721 to 2.6908; uncalibrated predicted deaths 7284 against 15326 observed per hectare summed. Planted 1.0. refit2_live solved to 2.09340.

## S5. Table 5, refit2 against v102 (and the first pass refit for reference)

### VOL

| Scenario | Site (BYI) | Age | VOL v102 | VOL refit | VOL refit2 | pct refit | pct refit2 | VOL refit2_live | pct refit2_live |
|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 35.1 | 55.9 | 62.0 | +59.1 | +76.7 | 64.1 | +82.5 |
| even-aged natural | Low (100) | 40 | 73.5 | 108.3 | 128.4 | +47.3 | +74.6 | 137.8 | +87.4 |
| even-aged natural | Low (100) | 60 | 112.8 | 149.5 | 180.1 | +32.5 | +59.6 | 198.1 | +75.6 |
| even-aged natural | Low (100) | 100 | 173.0 | 198.4 | 248.3 | +14.7 | +43.5 | 282.4 | +63.2 |
| even-aged natural | Medium (264) | 20 | 57.4 | 75.1 | 82.5 | +30.8 | +43.6 | 88.1 | +53.4 |
| even-aged natural | Medium (264) | 40 | 120.7 | 140.8 | 162.6 | +16.6 | +34.6 | 179.9 | +49.0 |
| even-aged natural | Medium (264) | 60 | 174.4 | 187.8 | 219.9 | +7.6 | +26.1 | 248.0 | +42.1 |
| even-aged natural | Medium (264) | 100 | 249.0 | 240.5 | 292.6 | -3.4 | +17.5 | 338.2 | +35.8 |
| even-aged natural | High (450) | 20 | 77.5 | 91.2 | 98.6 | +17.6 | +27.2 | 107.1 | +38.1 |
| even-aged natural | High (450) | 40 | 157.8 | 166.4 | 188.5 | +5.5 | +19.5 | 211.3 | +33.9 |
| even-aged natural | High (450) | 60 | 219.5 | 217.7 | 250.4 | -0.8 | +14.1 | 285.1 | +29.9 |
| even-aged natural | High (450) | 100 | 300.5 | 273.3 | 327.6 | -9.1 | +9.0 | 381.1 | +26.8 |
| even-aged planted | Low (100) | 20 | 232.3 | 234.9 | 243.0 | +1.1 | +4.6 | 267.8 | +15.3 |
| even-aged planted | Low (100) | 40 | 378.1 | 335.5 | 356.6 | -11.3 | -5.7 | 398.5 | +5.4 |
| even-aged planted | Low (100) | 60 | 473.8 | 394.4 | 427.3 | -16.7 | -9.8 | 483.1 | +2.0 |
| even-aged planted | Low (100) | 100 | 525.9 | 447.6 | 433.4 | -14.9 | -17.6 | 535.7 | +1.9 |
| even-aged planted | Medium (264) | 20 | 329.1 | 290.3 | 288.7 | -11.8 | -12.3 | 322.6 | -2.0 |
| even-aged planted | Medium (264) | 40 | 498.7 | 396.9 | 413.3 | -20.4 | -17.1 | 466.2 | -6.5 |
| even-aged planted | Medium (264) | 60 | 549.8 | 459.8 | 459.2 | -16.4 | -16.5 | 543.3 | -1.2 |
| even-aged planted | Medium (264) | 100 | 569.2 | 513.6 | 471.4 | -9.8 | -17.2 | 573.2 | +0.7 |
| even-aged planted | High (450) | 20 | 402.5 | 334.0 | 325.3 | -17.0 | -19.2 | 365.6 | -9.2 |
| even-aged planted | High (450) | 40 | 559.7 | 447.3 | 460.4 | -20.1 | -17.8 | 521.1 | -6.9 |
| even-aged planted | High (450) | 60 | 612.5 | 514.3 | 494.8 | -16.0 | -19.2 | 592.2 | -3.3 |
| even-aged planted | High (450) | 100 | 594.9 | 554.3 | 512.0 | -6.8 | -13.9 | 607.3 | +2.1 |
| uneven-aged natural | Low (100) | 20 | 42.2 | 67.2 | 89.9 | +59.2 | +112.8 |  |  |
| uneven-aged natural | Low (100) | 40 | 123.1 | 156.7 | 197.4 | +27.2 | +60.3 |  |  |
| uneven-aged natural | Low (100) | 60 | 187.4 | 222.1 | 275.5 | +18.5 | +47.0 |  |  |
| uneven-aged natural | Low (100) | 100 | 292.1 | 314.5 | 402.3 | +7.7 | +37.7 |  |  |
| uneven-aged natural | Medium (264) | 20 | 83.5 | 96.8 | 124.7 | +15.8 | +49.3 |  |  |
| uneven-aged natural | Medium (264) | 40 | 188.8 | 203.3 | 242.9 | +7.7 | +28.7 |  |  |
| uneven-aged natural | Medium (264) | 60 | 268.2 | 273.9 | 332.0 | +2.1 | +23.8 |  |  |
| uneven-aged natural | Medium (264) | 100 | 399.7 | 376.1 | 476.2 | -5.9 | +19.1 |  |  |
| uneven-aged natural | High (450) | 20 | 117.7 | 120.6 | 148.3 | +2.5 | +26.0 |  |  |
| uneven-aged natural | High (450) | 40 | 236.8 | 237.5 | 278.1 | +0.3 | +17.5 |  |  |
| uneven-aged natural | High (450) | 60 | 329.2 | 314.0 | 376.7 | -4.6 | +14.4 |  |  |
| uneven-aged natural | High (450) | 100 | 481.4 | 425.5 | 535.5 | -11.6 | +11.2 |  |  |

### QMD

| Scenario | Site (BYI) | Age | QMD v102 | QMD refit | QMD refit2 | pct refit | pct refit2 | QMD refit2_live | pct refit2_live |
|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 16.3 | 19.5 | 20.4 | +19.5 | +25.1 | 20.5 | +25.7 |
| even-aged natural | Low (100) | 40 | 23.0 | 27.0 | 30.0 | +17.5 | +30.7 | 30.5 | +32.9 |
| even-aged natural | Low (100) | 60 | 29.0 | 32.6 | 37.8 | +12.1 | +30.1 | 39.0 | +34.4 |
| even-aged natural | Low (100) | 100 | 39.9 | 40.6 | 50.0 | +1.7 | +25.2 | 53.0 | +32.6 |
| even-aged natural | Medium (264) | 20 | 19.4 | 21.7 | 22.7 | +12.2 | +17.3 | 23.2 | +19.5 |
| even-aged natural | Medium (264) | 40 | 28.6 | 30.3 | 33.6 | +5.7 | +17.5 | 34.9 | +21.7 |
| even-aged natural | Medium (264) | 60 | 36.8 | 36.3 | 42.2 | -1.3 | +14.6 | 44.5 | +20.9 |
| even-aged natural | Medium (264) | 100 | 50.5 | 44.8 | 55.3 | -11.2 | +9.6 | 60.0 | +18.9 |
| even-aged natural | High (450) | 20 | 21.6 | 23.2 | 24.1 | +7.0 | +11.4 | 24.7 | +14.3 |
| even-aged natural | High (450) | 40 | 32.6 | 32.2 | 35.7 | -1.2 | +9.5 | 37.4 | +14.5 |
| even-aged natural | High (450) | 60 | 42.1 | 38.6 | 44.7 | -8.3 | +6.1 | 47.6 | +13.2 |
| even-aged natural | High (450) | 100 | 57.5 | 47.3 | 58.3 | -17.6 | +1.6 | 64.0 | +11.4 |
| even-aged planted | Low (100) | 20 | 26.8 | 28.0 | 27.7 | +4.6 | +3.3 | 29.8 | +11.0 |
| even-aged planted | Low (100) | 40 | 38.2 | 36.2 | 36.2 | -5.2 | -5.2 | 40.6 | +6.5 |
| even-aged planted | Low (100) | 60 | 46.9 | 41.3 | 42.0 | -11.9 | -10.4 | 48.7 | +3.8 |
| even-aged planted | Low (100) | 100 | 56.1 | 48.5 | 47.9 | -13.5 | -14.6 | 58.3 | +4.0 |
| even-aged planted | Medium (264) | 20 | 32.5 | 31.0 | 29.8 | -4.4 | -8.3 | 32.5 | +0.3 |
| even-aged planted | Medium (264) | 40 | 46.3 | 39.5 | 38.7 | -14.7 | -16.4 | 44.3 | -4.3 |
| even-aged planted | Medium (264) | 60 | 53.3 | 44.9 | 43.5 | -15.9 | -18.4 | 52.3 | -1.8 |
| even-aged planted | Medium (264) | 100 | 62.1 | 52.5 | 49.9 | -15.6 | -19.7 | 61.3 | -1.3 |
| even-aged planted | High (450) | 20 | 36.0 | 32.8 | 30.9 | -8.9 | -14.2 | 34.1 | -5.4 |
| even-aged planted | High (450) | 40 | 49.9 | 41.5 | 40.2 | -16.9 | -19.5 | 46.4 | -7.0 |
| even-aged planted | High (450) | 60 | 57.3 | 47.0 | 44.3 | -18.0 | -22.6 | 54.1 | -5.4 |
| even-aged planted | High (450) | 100 | 64.6 | 54.4 | 51.0 | -15.9 | -21.1 | 62.8 | -2.9 |
| uneven-aged natural | Low (100) | 20 | 15.6 | 19.2 | 23.0 | +22.7 | +47.0 |  |  |
| uneven-aged natural | Low (100) | 40 | 27.4 | 29.8 | 38.7 | +8.7 | +41.5 |  |  |
| uneven-aged natural | Low (100) | 60 | 37.0 | 37.8 | 50.0 | +2.1 | +35.0 |  |  |
| uneven-aged natural | Low (100) | 100 | 51.4 | 48.6 | 66.5 | -5.5 | +29.3 |  |  |
| uneven-aged natural | Medium (264) | 20 | 21.7 | 22.6 | 27.4 | +4.1 | +26.4 |  |  |
| uneven-aged natural | Medium (264) | 40 | 36.9 | 34.8 | 44.1 | -5.6 | +19.4 |  |  |
| uneven-aged natural | Medium (264) | 60 | 48.2 | 43.1 | 56.2 | -10.6 | +16.8 |  |  |
| uneven-aged natural | Medium (264) | 100 | 64.6 | 54.1 | 73.6 | -16.3 | +14.0 |  |  |
| uneven-aged natural | High (450) | 20 | 25.9 | 24.7 | 29.7 | -4.7 | +14.5 |  |  |
| uneven-aged natural | High (450) | 40 | 42.5 | 37.6 | 47.1 | -11.7 | +10.6 |  |  |
| uneven-aged natural | High (450) | 60 | 54.8 | 46.0 | 59.7 | -16.1 | +9.0 |  |  |
| uneven-aged natural | High (450) | 100 | 72.4 | 57.2 | 77.5 | -21.0 | +7.1 |  |  |

### HT

| Scenario | Site (BYI) | Age | HT v102 | HT refit | HT refit2 | pct refit | pct refit2 | HT refit2_live | pct refit2_live |
|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 9.9 | 10.9 | 11.7 | +9.8 | +18.0 | 11.7 | +18.5 |
| even-aged natural | Low (100) | 40 | 12.6 | 13.4 | 15.1 | +5.9 | +19.9 | 15.3 | +21.2 |
| even-aged natural | Low (100) | 60 | 14.8 | 15.0 | 17.4 | +1.7 | +18.0 | 17.7 | +20.0 |
| even-aged natural | Low (100) | 100 | 17.8 | 17.0 | 20.3 | -4.3 | +14.1 | 20.8 | +16.7 |
| even-aged natural | Medium (264) | 20 | 11.9 | 12.4 | 13.4 | +3.5 | +11.8 | 13.5 | +13.4 |
| even-aged natural | Medium (264) | 40 | 15.6 | 15.2 | 17.2 | -2.2 | +10.7 | 17.6 | +13.0 |
| even-aged natural | Medium (264) | 60 | 18.1 | 17.0 | 19.7 | -6.3 | +8.6 | 20.2 | +11.3 |
| even-aged natural | Medium (264) | 100 | 21.4 | 19.1 | 22.7 | -10.9 | +5.8 | 23.3 | +8.9 |
| even-aged natural | High (450) | 20 | 13.7 | 13.7 | 14.8 | -0.4 | +7.6 | 15.1 | +9.6 |
| even-aged natural | High (450) | 40 | 18.0 | 16.8 | 19.0 | -6.4 | +5.8 | 19.5 | +8.4 |
| even-aged natural | High (450) | 60 | 20.8 | 18.7 | 21.6 | -10.0 | +4.0 | 22.2 | +7.0 |
| even-aged natural | High (450) | 100 | 24.2 | 20.9 | 24.7 | -13.7 | +2.1 | 25.5 | +5.4 |
| even-aged planted | Low (100) | 20 | 14.7 | 14.3 | 15.0 | -2.6 | +2.0 | 15.4 | +4.9 |
| even-aged planted | Low (100) | 40 | 18.2 | 16.8 | 17.9 | -7.5 | -1.8 | 18.5 | +1.7 |
| even-aged planted | Low (100) | 60 | 20.4 | 18.3 | 19.6 | -10.3 | -3.6 | 20.4 | +0.2 |
| even-aged planted | Low (100) | 100 | 21.3 | 20.0 | 20.4 | -6.2 | -4.4 | 21.5 | +0.8 |
| even-aged planted | Medium (264) | 20 | 17.5 | 16.2 | 16.7 | -7.8 | -5.1 | 17.2 | -1.8 |
| even-aged planted | Medium (264) | 40 | 21.5 | 18.8 | 19.8 | -12.3 | -7.7 | 20.6 | -4.1 |
| even-aged planted | Medium (264) | 60 | 22.3 | 20.4 | 21.0 | -8.8 | -5.8 | 22.3 | -0.3 |
| even-aged planted | Medium (264) | 100 | 23.0 | 22.1 | 21.8 | -3.8 | -5.0 | 22.9 | -0.2 |
| even-aged planted | High (450) | 20 | 19.9 | 17.8 | 18.2 | -10.4 | -8.5 | 18.9 | -5.1 |
| even-aged planted | High (450) | 40 | 23.4 | 20.6 | 21.6 | -11.8 | -7.7 | 22.5 | -3.9 |
| even-aged planted | High (450) | 60 | 24.2 | 22.2 | 22.5 | -8.0 | -7.0 | 23.9 | -1.1 |
| even-aged planted | High (450) | 100 | 24.5 | 23.8 | 23.4 | -2.9 | -4.7 | 24.5 | -0.2 |
| uneven-aged natural | Low (100) | 20 | 8.6 | 10.0 | 11.2 | +15.5 | +30.0 |  |  |
| uneven-aged natural | Low (100) | 40 | 12.7 | 13.5 | 15.7 | +6.1 | +23.4 |  |  |
| uneven-aged natural | Low (100) | 60 | 15.3 | 15.6 | 18.2 | +1.8 | +18.7 |  |  |
| uneven-aged natural | Low (100) | 100 | 18.6 | 18.1 | 21.2 | -2.6 | +13.9 |  |  |
| uneven-aged natural | Medium (264) | 20 | 11.4 | 11.8 | 13.3 | +3.2 | +16.1 |  |  |
| uneven-aged natural | Medium (264) | 40 | 16.1 | 15.7 | 17.9 | -2.7 | +11.1 |  |  |
| uneven-aged natural | Medium (264) | 60 | 18.9 | 17.9 | 20.6 | -5.5 | +8.8 |  |  |
| uneven-aged natural | Medium (264) | 100 | 22.2 | 20.4 | 23.6 | -8.1 | +6.4 |  |  |
| uneven-aged natural | High (450) | 20 | 13.6 | 13.3 | 14.9 | -2.2 | +9.0 |  |  |
| uneven-aged natural | High (450) | 40 | 18.7 | 17.5 | 19.8 | -6.4 | +6.1 |  |  |
| uneven-aged natural | High (450) | 60 | 21.6 | 19.7 | 22.6 | -8.5 | +4.6 |  |  |
| uneven-aged natural | High (450) | 100 | 24.8 | 22.3 | 25.6 | -10.3 | +3.2 |  |  |

### BAPH

| Scenario | Site (BYI) | Age | BAPH v102 | BAPH refit | BAPH refit2 | pct refit | pct refit2 | BAPH refit2_live | pct refit2_live |
|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 8.9 | 12.8 | 13.3 | +44.9 | +49.7 | 13.7 | +54.0 |
| even-aged natural | Low (100) | 40 | 14.5 | 20.2 | 21.2 | +39.1 | +45.6 | 22.5 | +54.6 |
| even-aged natural | Low (100) | 60 | 19.1 | 24.9 | 25.8 | +30.4 | +35.2 | 28.0 | +46.4 |
| even-aged natural | Low (100) | 100 | 24.3 | 29.1 | 30.6 | +19.8 | +25.8 | 34.0 | +39.9 |
| even-aged natural | Medium (264) | 20 | 12.0 | 15.2 | 15.4 | +26.3 | +28.4 | 16.3 | +35.3 |
| even-aged natural | Medium (264) | 40 | 19.4 | 23.1 | 23.6 | +19.3 | +21.6 | 25.6 | +31.8 |
| even-aged natural | Medium (264) | 60 | 24.1 | 27.6 | 27.9 | +14.9 | +16.1 | 30.7 | +27.7 |
| even-aged natural | Medium (264) | 100 | 29.0 | 31.5 | 32.3 | +8.4 | +11.1 | 36.2 | +24.7 |
| even-aged natural | High (450) | 20 | 14.1 | 16.6 | 16.7 | +18.0 | +18.3 | 17.8 | +26.1 |
| even-aged natural | High (450) | 40 | 22.0 | 24.7 | 24.8 | +12.7 | +12.9 | 27.1 | +23.5 |
| even-aged natural | High (450) | 60 | 26.4 | 29.1 | 29.0 | +10.2 | +9.7 | 32.1 | +21.4 |
| even-aged natural | High (450) | 100 | 31.0 | 32.7 | 33.1 | +5.4 | +6.8 | 37.3 | +20.4 |
| even-aged planted | Low (100) | 20 | 39.6 | 41.1 | 40.6 | +3.8 | +2.6 | 43.5 | +9.9 |
| even-aged planted | Low (100) | 40 | 51.9 | 49.8 | 49.9 | -4.0 | -3.9 | 53.8 | +3.7 |
| even-aged planted | Low (100) | 60 | 58.1 | 54.0 | 54.4 | -7.2 | -6.4 | 59.1 | +1.7 |
| even-aged planted | Low (100) | 100 | 61.6 | 55.9 | 53.1 | -9.2 | -13.8 | 62.3 | +1.1 |
| even-aged planted | Medium (264) | 20 | 46.9 | 44.9 | 43.3 | -4.3 | -7.6 | 46.8 | -0.2 |
| even-aged planted | Medium (264) | 40 | 58.0 | 52.7 | 52.1 | -9.2 | -10.2 | 56.6 | -2.6 |
| even-aged planted | Medium (264) | 60 | 61.6 | 56.5 | 54.6 | -8.3 | -11.3 | 61.0 | -0.9 |
| even-aged planted | Medium (264) | 100 | 61.9 | 58.0 | 54.0 | -6.3 | -12.8 | 62.5 | +0.9 |
| even-aged planted | High (450) | 20 | 50.6 | 46.9 | 44.7 | -7.4 | -11.6 | 48.5 | -4.3 |
| even-aged planted | High (450) | 40 | 59.8 | 54.2 | 53.3 | -9.4 | -10.9 | 57.9 | -3.1 |
| even-aged planted | High (450) | 60 | 63.4 | 57.8 | 55.0 | -8.7 | -13.2 | 61.9 | -2.2 |
| even-aged planted | High (450) | 100 | 60.6 | 58.2 | 54.8 | -4.0 | -9.7 | 62.0 | +2.3 |
| uneven-aged natural | Low (100) | 20 | 12.2 | 16.8 | 20.0 | +37.8 | +63.6 |  |  |
| uneven-aged natural | Low (100) | 40 | 24.2 | 29.1 | 31.5 | +19.9 | +29.9 |  |  |
| uneven-aged natural | Low (100) | 60 | 30.5 | 35.5 | 37.8 | +16.4 | +23.8 |  |  |
| uneven-aged natural | Low (100) | 100 | 39.2 | 43.4 | 47.4 | +10.5 | +20.9 |  |  |
| uneven-aged natural | Medium (264) | 20 | 18.2 | 20.5 | 23.5 | +12.2 | +28.6 |  |  |
| uneven-aged natural | Medium (264) | 40 | 29.3 | 32.4 | 33.9 | +10.7 | +15.8 |  |  |
| uneven-aged natural | Medium (264) | 60 | 35.5 | 38.4 | 40.4 | +8.1 | +13.8 |  |  |
| uneven-aged natural | Medium (264) | 100 | 45.1 | 46.2 | 50.5 | +2.4 | +12.0 |  |  |
| uneven-aged natural | High (450) | 20 | 21.6 | 22.6 | 24.9 | +4.9 | +15.6 |  |  |
| uneven-aged natural | High (450) | 40 | 31.7 | 34.0 | 35.1 | +7.2 | +10.7 |  |  |
| uneven-aged natural | High (450) | 60 | 38.2 | 39.8 | 41.8 | +4.3 | +9.3 |  |  |
| uneven-aged natural | High (450) | 100 | 48.4 | 47.7 | 52.2 | -1.5 | +7.8 |  |  |

### TPH

| Scenario | Site (BYI) | Age | TPH v102 | TPH refit | TPH refit2 | pct refit | pct refit2 | TPH refit2_live | pct refit2_live |
|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 423.2 | 429.4 | 405.2 | +1.5 | -4.3 | 412.8 | -2.5 |
| even-aged natural | Low (100) | 40 | 350.8 | 353.3 | 299.1 | +0.7 | -14.7 | 307.0 | -12.5 |
| even-aged natural | Low (100) | 60 | 288.2 | 299.0 | 230.2 | +3.8 | -20.1 | 233.6 | -18.9 |
| even-aged natural | Low (100) | 100 | 194.0 | 224.9 | 155.8 | +15.9 | -19.7 | 154.3 | -20.5 |
| even-aged natural | Medium (264) | 20 | 407.4 | 408.9 | 380.4 | +0.4 | -6.6 | 386.0 | -5.3 |
| even-aged natural | Medium (264) | 40 | 301.0 | 321.5 | 265.2 | +6.8 | -11.9 | 267.7 | -11.1 |
| even-aged natural | Medium (264) | 60 | 226.1 | 266.7 | 199.8 | +18.0 | -11.6 | 197.3 | -12.7 |
| even-aged natural | Medium (264) | 100 | 145.0 | 199.5 | 134.2 | +37.5 | -7.5 | 128.0 | -11.8 |
| even-aged natural | High (450) | 20 | 383.0 | 394.9 | 365.1 | +3.1 | -4.7 | 369.4 | -3.6 |
| even-aged natural | High (450) | 40 | 262.5 | 302.8 | 247.5 | +15.4 | -5.7 | 247.3 | -5.8 |
| even-aged natural | High (450) | 60 | 189.8 | 248.9 | 184.8 | +31.2 | -2.6 | 179.8 | -5.2 |
| even-aged natural | High (450) | 100 | 119.6 | 185.7 | 123.8 | +55.3 | +3.5 | 116.0 | -3.0 |
| even-aged planted | Low (100) | 20 | 701.4 | 665.5 | 674.5 | -5.1 | -3.8 | 625.2 | -10.9 |
| even-aged planted | Low (100) | 40 | 453.7 | 484.3 | 485.4 | +6.8 | +7.0 | 415.0 | -8.5 |
| even-aged planted | Low (100) | 60 | 336.9 | 403.3 | 392.6 | +19.7 | +16.5 | 318.0 | -5.6 |
| even-aged planted | Low (100) | 100 | 249.7 | 302.9 | 295.4 | +21.3 | +18.3 | 233.2 | -6.6 |
| even-aged planted | Medium (264) | 20 | 566.7 | 593.1 | 622.8 | +4.7 | +9.9 | 562.7 | -0.7 |
| even-aged planted | Medium (264) | 40 | 344.3 | 429.8 | 442.6 | +24.8 | +28.5 | 366.4 | +6.4 |
| even-aged planted | Medium (264) | 60 | 275.7 | 357.5 | 367.2 | +29.7 | +33.2 | 283.5 | +2.8 |
| even-aged planted | Medium (264) | 100 | 204.1 | 268.5 | 276.3 | +31.6 | +35.4 | 211.6 | +3.7 |
| even-aged planted | High (450) | 20 | 497.0 | 554.2 | 596.0 | +11.5 | +19.9 | 531.3 | +6.9 |
| even-aged planted | High (450) | 40 | 305.9 | 401.4 | 420.7 | +31.2 | +37.5 | 342.5 | +11.9 |
| even-aged planted | High (450) | 60 | 246.1 | 333.8 | 356.3 | +35.7 | +44.8 | 269.1 | +9.3 |
| even-aged planted | High (450) | 100 | 184.9 | 250.7 | 268.2 | +35.5 | +45.0 | 200.4 | +8.4 |
| uneven-aged natural | Low (100) | 20 | 635.3 | 581.1 | 480.9 | -8.5 | -24.3 |  |  |
| uneven-aged natural | Low (100) | 40 | 412.0 | 417.7 | 267.4 | +1.4 | -35.1 |  |  |
| uneven-aged natural | Low (100) | 60 | 283.5 | 316.3 | 192.6 | +11.5 | -32.1 |  |  |
| uneven-aged natural | Low (100) | 100 | 188.8 | 233.5 | 136.5 | +23.6 | -27.7 |  |  |
| uneven-aged natural | Medium (264) | 20 | 494.2 | 511.3 | 397.5 | +3.5 | -19.6 |  |  |
| uneven-aged natural | Medium (264) | 40 | 273.8 | 340.2 | 222.2 | +24.2 | -18.8 |  |  |
| uneven-aged natural | Medium (264) | 60 | 194.8 | 263.3 | 162.6 | +35.2 | -16.5 |  |  |
| uneven-aged natural | Medium (264) | 100 | 137.5 | 201.0 | 118.6 | +46.2 | -13.7 |  |  |
| uneven-aged natural | High (450) | 20 | 407.9 | 470.5 | 359.7 | +15.4 | -11.8 |  |  |
| uneven-aged natural | High (450) | 40 | 223.3 | 306.7 | 201.9 | +37.4 | -9.6 |  |  |
| uneven-aged natural | High (450) | 60 | 162.0 | 240.0 | 149.2 | +48.1 | -7.9 |  |  |
| uneven-aged natural | High (450) | 100 | 117.7 | 186.0 | 110.5 | +58.1 | -6.1 |  |  |

### MAI

| Scenario | Site (BYI) | Age | MAI v102 | MAI refit | MAI refit2 | pct refit | pct refit2 | MAI refit2_live | pct refit2_live |
|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 20 | 1.8 | 2.8 | 3.1 | +59.1 | +76.7 | 3.2 | +82.5 |
| even-aged natural | Low (100) | 40 | 1.8 | 2.7 | 3.2 | +47.3 | +74.6 | 3.4 | +87.4 |
| even-aged natural | Low (100) | 60 | 1.9 | 2.5 | 3.0 | +32.5 | +59.6 | 3.3 | +75.6 |
| even-aged natural | Low (100) | 100 | 1.7 | 2.0 | 2.5 | +14.7 | +43.5 | 2.8 | +63.2 |
| even-aged natural | Medium (264) | 20 | 2.9 | 3.8 | 4.1 | +30.8 | +43.6 | 4.4 | +53.4 |
| even-aged natural | Medium (264) | 40 | 3.0 | 3.5 | 4.1 | +16.6 | +34.6 | 4.5 | +49.0 |
| even-aged natural | Medium (264) | 60 | 2.9 | 3.1 | 3.7 | +7.6 | +26.1 | 4.1 | +42.1 |
| even-aged natural | Medium (264) | 100 | 2.5 | 2.4 | 2.9 | -3.4 | +17.5 | 3.4 | +35.8 |
| even-aged natural | High (450) | 20 | 3.9 | 4.6 | 4.9 | +17.6 | +27.2 | 5.4 | +38.1 |
| even-aged natural | High (450) | 40 | 3.9 | 4.2 | 4.7 | +5.5 | +19.5 | 5.3 | +33.9 |
| even-aged natural | High (450) | 60 | 3.7 | 3.6 | 4.2 | -0.8 | +14.1 | 4.8 | +29.9 |
| even-aged natural | High (450) | 100 | 3.0 | 2.7 | 3.3 | -9.1 | +9.0 | 3.8 | +26.8 |
| even-aged planted | Low (100) | 20 | 11.6 | 11.7 | 12.2 | +1.1 | +4.6 | 13.4 | +15.3 |
| even-aged planted | Low (100) | 40 | 9.5 | 8.4 | 8.9 | -11.3 | -5.7 | 10.0 | +5.4 |
| even-aged planted | Low (100) | 60 | 7.9 | 6.6 | 7.1 | -16.7 | -9.8 | 8.1 | +2.0 |
| even-aged planted | Low (100) | 100 | 5.3 | 4.5 | 4.3 | -14.9 | -17.6 | 5.4 | +1.9 |
| even-aged planted | Medium (264) | 20 | 16.5 | 14.5 | 14.4 | -11.8 | -12.3 | 16.1 | -2.0 |
| even-aged planted | Medium (264) | 40 | 12.5 | 9.9 | 10.3 | -20.4 | -17.1 | 11.7 | -6.5 |
| even-aged planted | Medium (264) | 60 | 9.2 | 7.7 | 7.7 | -16.4 | -16.5 | 9.1 | -1.2 |
| even-aged planted | Medium (264) | 100 | 5.7 | 5.1 | 4.7 | -9.8 | -17.2 | 5.7 | +0.7 |
| even-aged planted | High (450) | 20 | 20.1 | 16.7 | 16.3 | -17.0 | -19.2 | 18.3 | -9.2 |
| even-aged planted | High (450) | 40 | 14.0 | 11.2 | 11.5 | -20.1 | -17.8 | 13.0 | -6.9 |
| even-aged planted | High (450) | 60 | 10.2 | 8.6 | 8.2 | -16.0 | -19.2 | 9.9 | -3.3 |
| even-aged planted | High (450) | 100 | 5.9 | 5.5 | 5.1 | -6.8 | -13.9 | 6.1 | +2.1 |
| uneven-aged natural | Low (100) | 20 | 2.1 | 3.4 | 4.5 | +59.2 | +112.8 |  |  |
| uneven-aged natural | Low (100) | 40 | 3.1 | 3.9 | 4.9 | +27.2 | +60.3 |  |  |
| uneven-aged natural | Low (100) | 60 | 3.1 | 3.7 | 4.6 | +18.5 | +47.0 |  |  |
| uneven-aged natural | Low (100) | 100 | 2.9 | 3.1 | 4.0 | +7.7 | +37.7 |  |  |
| uneven-aged natural | Medium (264) | 20 | 4.2 | 4.8 | 6.2 | +15.8 | +49.3 |  |  |
| uneven-aged natural | Medium (264) | 40 | 4.7 | 5.1 | 6.1 | +7.7 | +28.7 |  |  |
| uneven-aged natural | Medium (264) | 60 | 4.5 | 4.6 | 5.5 | +2.1 | +23.8 |  |  |
| uneven-aged natural | Medium (264) | 100 | 4.0 | 3.8 | 4.8 | -5.9 | +19.1 |  |  |
| uneven-aged natural | High (450) | 20 | 5.9 | 6.0 | 7.4 | +2.5 | +26.0 |  |  |
| uneven-aged natural | High (450) | 40 | 5.9 | 5.9 | 7.0 | +0.3 | +17.5 |  |  |
| uneven-aged natural | High (450) | 60 | 5.5 | 5.2 | 6.3 | -4.6 | +14.4 |  |  |
| uneven-aged natural | High (450) | 100 | 4.8 | 4.3 | 5.4 | -11.6 | +11.2 |  |  |

## S6. Culmination

| scenario | site | culm_track2_v102 | culm_track2_refit | culm_track2_refit2 | culm_track2_refit2_live | culm_afterMin_v102 | culm_afterMin_refit2 | MAI_at_culm_track2_v102 | MAI_at_culm_track2_refit2 | peakVOL_age_v102 | peakVOL_age_refit2 | peakVOL_v102 | peakVOL_refit2 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| even-aged natural | Low (100) | 10* | 10* | 34 | 39 | 59 | 34 | 1.97 | 3.23 | 171 | 151 | 207.34 | 276.40 |
| even-aged natural | Medium (264) | 39 | 20 | 27 | 31 | 39 | 27 | 3.02 | 4.19 | 153 | 123 | 282.08 | 311.94 |
| even-aged natural | High (450) | 31 | 19 | 24 | 27 | 31 | 24 | 3.99 | 4.97 | 124 | 111 | 324.06 | 339.11 |
| even-aged planted | Low (100) | 13 | 9 | 9 | 9 | 13 | 9 | 12.08 | 14.27 | 105 | 90 | 528.35 | 434.09 |
| even-aged planted | Medium (264) | 10 | 7 | 8 | 8 | none | none | 18.67 | 18.21 | 84 | 110 | 577.03 | 471.56 |
| even-aged planted | High (450) | 8 | 7 | 7 | 7 | none | none | 24.37 | 21.42 | 77 | 101 | 626.60 | 512.39 |


## S7. Validation, 23 plots, all frames

| frame | group | n | surv_r | surv_bias | surv_RMSE | qmd_r | qmd_bias | qmd_RMSE | ba_r | ba_bias | ba_RMSE |
|---|---|---|---|---|---|---|---|---|---|---|---|
| v102 | all | 23 | 0.7144 | 0.1163 | 0.2635 | 0.9113 | -1.6684 | 2.9356 | 0.5503 | 0.3053 | 12.4321 |
| v102 | natural | 12 | 0.7249 | 0.1978 | 0.3177 | 0.8166 | -1.5385 | 3.0467 | 0.5779 | 4.1128 | 10.5308 |
| v102 | planted | 11 | 0.4815 | 0.0274 | 0.1871 | 0.9506 | -1.8102 | 2.8094 | 0.4751 | -3.8482 | 14.2192 |
| refit | all | 23 | 0.7100 | 0.1049 | 0.2597 | 0.9107 | -0.5652 | 2.4437 | 0.5101 | 3.3536 | 13.2693 |
| refit | natural | 12 | 0.7385 | 0.2044 | 0.3175 | 0.9353 | -0.6093 | 2.0192 | 0.6176 | 7.5361 | 11.9651 |
| refit | planted | 11 | 0.5472 | -0.0036 | 0.1763 | 0.9116 | -0.5171 | 2.8353 | 0.3859 | -1.2090 | 14.5594 |
| refit_live | all | 23 | 0.6886 | 0.1166 | 0.2725 | 0.8955 | -0.7036 | 2.6752 | 0.4889 | 3.0884 | 13.4521 |
| refit_live | natural | 12 | 0.7108 | 0.2207 | 0.3406 | 0.8994 | -0.5581 | 2.0260 | 0.6662 | 7.6180 | 11.6540 |
| refit_live | planted | 11 | 0.5952 | 0.0030 | 0.1693 | 0.8904 | -0.8623 | 3.2383 | 0.3347 | -1.8530 | 15.1725 |
| refit2 | all | 23 | 0.7522 | 0.0935 | 0.2405 | 0.8817 | -0.6581 | 2.8030 | 0.4846 | 2.0333 | 13.2157 |
| refit2 | natural | 12 | 0.7582 | 0.1716 | 0.2876 | 0.8483 | -0.5046 | 2.6098 | 0.5527 | 5.9014 | 11.5076 |
| refit2 | planted | 11 | 0.5575 | 0.0083 | 0.1752 | 0.9159 | -0.8257 | 2.9996 | 0.3816 | -2.1864 | 14.8568 |
| refit2_live | all | 23 | 0.7324 | 0.0990 | 0.2506 | 0.8832 | -0.0505 | 2.9982 | 0.4618 | 2.7693 | 13.6448 |
| refit2_live | natural | 12 | 0.7357 | 0.1843 | 0.3071 | 0.8811 | 0.4871 | 2.2051 | 0.6271 | 7.1444 | 11.6604 |
| refit2_live | planted | 11 | 0.6020 | 0.0058 | 0.1684 | 0.8849 | -0.6370 | 3.6729 | 0.3331 | -2.0035 | 15.5228 |


25 percent equivalence (TOST), all frames.

| frame | group | quantity | n | mean_obs | bias_obs_minus_pred | bias_lo | bias_hi | region_bias | pass_bias | slope | slope_lo | slope_hi | pass_slope |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v102 | all | surv | 23 | 0.595 | -0.116 | -0.201 | -0.038 | 0.149 | False | 0.902 | 0.745 | 1.173 | False |
| v102 | all | qmd | 23 | 23.599 | 1.668 | 0.856 | 2.499 | 5.900 | True | 0.908 | 0.766 | 1.038 | True |
| v102 | all | ba | 23 | 21.845 | -0.305 | -4.634 | 3.946 | 5.461 | True | 0.997 | 0.396 | 2.010 | False |
| v102 | natural | surv | 12 | 0.428 | -0.198 | -0.321 | -0.082 | 0.107 | False | 0.754 | 0.468 | 1.094 | False |
| v102 | natural | qmd | 12 | 24.381 | 1.539 | 0.310 | 2.835 | 6.095 | True | 0.849 | 0.536 | 1.166 | False |
| v102 | natural | ba | 12 | 16.036 | -4.113 | -8.587 | 0.670 | 4.009 | False | 1.174 | 0.489 | 3.444 | False |
| v102 | planted | surv | 11 | 0.778 | -0.027 | -0.121 | 0.063 | 0.195 | True | 0.875 | -0.750 | 1.884 | False |
| v102 | planted | qmd | 11 | 22.747 | 1.810 | 0.736 | 2.883 | 5.687 | True | 0.934 | 0.768 | 1.137 | True |
| v102 | planted | ba | 11 | 28.182 | 3.848 | -3.307 | 10.414 | 7.046 | False | 0.745 | -0.074 | 2.052 | False |
| refit | all | surv | 23 | 0.595 | -0.105 | -0.190 | -0.027 | 0.149 | False | 0.912 | 0.714 | 1.142 | False |
| refit | all | qmd | 23 | 23.599 | 0.565 | -0.249 | 1.383 | 5.900 | True | 1.050 | 0.838 | 1.318 | False |
| refit | all | ba | 23 | 21.845 | -3.354 | -7.760 | 1.066 | 5.461 | False | 0.889 | 0.355 | 1.806 | False |
| refit | natural | surv | 12 | 0.428 | -0.204 | -0.326 | -0.092 | 0.107 | False | 0.765 | 0.476 | 1.096 | False |
| refit | natural | qmd | 12 | 24.381 | 0.609 | -0.343 | 1.509 | 6.095 | True | 1.374 | 1.093 | 1.642 | False |
| refit | natural | ba | 12 | 16.036 | -7.536 | -11.878 | -3.064 | 4.009 | False | 0.978 | 0.363 | 1.972 | False |
| refit | planted | surv | 11 | 0.778 | 0.004 | -0.085 | 0.088 | 0.195 | True | 0.988 | -0.585 | 2.052 | False |
| refit | planted | qmd | 11 | 22.747 | 0.517 | -0.884 | 1.885 | 5.687 | True | 0.971 | 0.709 | 1.355 | False |
| refit | planted | ba | 11 | 28.182 | 1.209 | -6.272 | 8.221 | 7.046 | False | 0.637 | -0.300 | 2.378 | False |
| refit_live | all | surv | 23 | 0.595 | -0.117 | -0.204 | -0.036 | 0.149 | False | 0.863 | 0.663 | 1.088 | False |
| refit_live | all | qmd | 23 | 23.599 | 0.704 | -0.179 | 1.594 | 5.900 | True | 0.925 | 0.729 | 1.190 | False |
| refit_live | all | ba | 23 | 21.845 | -3.088 | -7.591 | 1.394 | 5.461 | False | 0.813 | 0.315 | 1.680 | False |
| refit_live | natural | surv | 12 | 0.428 | -0.221 | -0.349 | -0.100 | 0.107 | False | 0.713 | 0.439 | 1.029 | False |
| refit_live | natural | qmd | 12 | 24.381 | 0.558 | -0.360 | 1.506 | 6.095 | True | 0.939 | 0.710 | 1.244 | False |
| refit_live | natural | ba | 12 | 16.036 | -7.618 | -11.742 | -3.438 | 4.009 | False | 0.954 | 0.380 | 1.726 | False |
| refit_live | planted | surv | 11 | 0.778 | -0.003 | -0.088 | 0.079 | 0.195 | True | 1.050 | -0.615 | 1.978 | False |
| refit_live | planted | qmd | 11 | 22.747 | 0.862 | -0.727 | 2.398 | 5.687 | True | 0.922 | 0.644 | 1.416 | False |
| refit_live | planted | ba | 11 | 28.182 | 1.853 | -5.950 | 9.066 | 7.046 | False | 0.541 | -0.341 | 2.406 | False |
| refit2 | all | surv | 23 | 0.595 | -0.093 | -0.174 | -0.021 | 0.149 | False | 0.957 | 0.794 | 1.187 | True |
| refit2 | all | qmd | 23 | 23.599 | 0.658 | -0.296 | 1.595 | 5.900 | True | 0.932 | 0.739 | 1.196 | False |
| refit2 | all | ba | 23 | 21.845 | -2.033 | -6.592 | 2.503 | 5.461 | False | 0.879 | 0.288 | 2.117 | False |
| refit2 | natural | surv | 12 | 0.428 | -0.172 | -0.287 | -0.064 | 0.107 | False | 0.810 | 0.510 | 1.128 | False |
| refit2 | natural | qmd | 12 | 24.381 | 0.505 | -0.775 | 1.699 | 6.095 | True | 1.385 | 0.905 | 1.800 | False |
| refit2 | natural | ba | 12 | 16.036 | -5.901 | -10.432 | -1.007 | 4.009 | False | 1.143 | 0.461 | 3.277 | False |
| refit2 | planted | surv | 11 | 0.778 | -0.008 | -0.096 | 0.077 | 0.195 | True | 0.935 | -0.703 | 1.778 | False |
| refit2 | planted | qmd | 11 | 22.747 | 0.826 | -0.663 | 2.211 | 5.687 | True | 0.865 | 0.632 | 1.212 | False |
| refit2 | planted | ba | 11 | 28.182 | 2.186 | -5.414 | 9.247 | 7.046 | False | 0.594 | -0.225 | 2.307 | False |
| refit2_live | all | surv | 23 | 0.595 | -0.099 | -0.181 | -0.024 | 0.149 | False | 0.902 | 0.745 | 1.107 | False |
| refit2_live | all | qmd | 23 | 23.599 | 0.051 | -0.999 | 1.054 | 5.900 | True | 0.791 | 0.615 | 1.022 | False |
| refit2_live | all | ba | 23 | 21.845 | -2.769 | -7.441 | 1.806 | 5.461 | False | 0.770 | 0.247 | 1.891 | False |
| refit2_live | natural | surv | 12 | 0.428 | -0.184 | -0.307 | -0.069 | 0.107 | False | 0.752 | 0.468 | 1.057 | False |
| refit2_live | natural | qmd | 12 | 24.381 | -0.487 | -1.503 | 0.562 | 6.095 | True | 0.884 | 0.638 | 1.244 | False |
| refit2_live | natural | ba | 12 | 16.036 | -7.144 | -11.386 | -2.678 | 4.009 | False | 1.070 | 0.439 | 2.225 | False |
| refit2_live | planted | surv | 11 | 0.778 | -0.006 | -0.090 | 0.076 | 0.195 | True | 0.938 | -0.723 | 1.640 | False |
| refit2_live | planted | qmd | 11 | 22.747 | 0.637 | -1.295 | 2.293 | 5.687 | True | 0.771 | 0.525 | 1.228 | False |
| refit2_live | planted | ba | 11 | 28.182 | 2.004 | -6.075 | 9.319 | 7.046 | False | 0.487 | -0.261 | 2.309 | False |


## S8. Financial yield grid (fin/run_yield_grid_refit2.py against ~/jobs/koa_fin_20260924/out/koa_yield_grid_200yr.csv)

Sixteen planted scenarios, four sites (BYI 450, 340, 230, 120) by four established densities (100 to 400 stems per acre), 200 years, M0 point path. Full table fin/out/yield_grid_compare.csv (ages 20, 40, 45, 52, 60, 100, 200). Ages 40, 45 and 52 below.

| site | tpa0 | age | BA_ft2ac_v102 | BA_ft2ac_refit2 | BA_ft2ac_pct | QMD_in_v102 | QMD_in_refit2 | QMD_in_pct | stems_ac_pct | VOL_m3ha_pct | peakBA_v102 | peakBA_refit2 | peakBA_age_v102 | peakBA_age_refit2 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Excellent | 100 | 40 | 159.5 | 155.2 | -2.7 | 20.1 | 19.7 | -2.0 | +1.4 | -3.2 | 179.7 | 174.9 | 70 | 72 |
| Excellent | 100 | 45 | 165.9 | 161.1 | -2.9 | 20.9 | 20.4 | -2.2 | +1.4 | -3.4 | 179.7 | 174.9 | 70 | 72 |
| Excellent | 100 | 52 | 172.9 | 167.7 | -3.0 | 21.8 | 21.3 | -2.2 | +1.4 | -3.6 | 179.7 | 174.9 | 70 | 72 |
| Excellent | 200 | 40 | 210.4 | 196.9 | -6.4 | 19.1 | 17.8 | -6.7 | +7.6 | -8.8 | 236.5 | 215.7 | 76 | 69 |
| Excellent | 200 | 45 | 217.9 | 202.2 | -7.2 | 19.8 | 18.4 | -7.5 | +8.4 | -9.5 | 236.5 | 215.7 | 76 | 69 |
| Excellent | 200 | 52 | 226.3 | 207.7 | -8.2 | 20.8 | 19.1 | -8.4 | +9.4 | -10.8 | 236.5 | 215.7 | 76 | 69 |
| Excellent | 300 | 40 | 236.2 | 215.4 | -8.8 | 19.0 | 16.7 | -11.7 | +17.0 | -13.0 | 261.0 | 231.7 | 70 | 79 |
| Excellent | 300 | 45 | 242.6 | 219.9 | -9.3 | 19.8 | 17.3 | -12.5 | +18.3 | -13.1 | 261.0 | 231.7 | 70 | 79 |
| Excellent | 300 | 52 | 250.3 | 224.2 | -10.4 | 20.8 | 17.9 | -13.9 | +20.9 | -14.3 | 261.0 | 231.7 | 70 | 79 |
| Excellent | 400 | 40 | 251.6 | 226.0 | -10.2 | 19.3 | 16.1 | -16.2 | +27.9 | -15.9 | 273.6 | 237.8 | 74 | 80 |
| Excellent | 400 | 45 | 257.1 | 230.2 | -10.5 | 20.1 | 16.7 | -16.6 | +28.9 | -15.4 | 273.6 | 237.8 | 74 | 80 |
| Excellent | 400 | 52 | 263.7 | 233.3 | -11.5 | 21.1 | 17.3 | -18.3 | +32.4 | -16.6 | 273.6 | 237.8 | 74 | 80 |
| Good | 100 | 40 | 151.1 | 151.1 | +0.0 | 19.4 | 19.3 | -0.1 | +0.2 | -0.3 | 175.4 | 172.9 | 78 | 76 |
| Good | 100 | 45 | 158.6 | 157.7 | -0.6 | 20.2 | 20.1 | -0.4 | +0.2 | -0.4 | 175.4 | 172.9 | 78 | 76 |
| Good | 100 | 52 | 165.9 | 164.2 | -1.0 | 21.1 | 21.0 | -0.6 | +0.2 | -1.2 | 175.4 | 172.9 | 78 | 76 |
| Good | 200 | 40 | 203.5 | 193.5 | -4.9 | 18.4 | 17.5 | -5.0 | +5.3 | -7.4 | 233.3 | 213.9 | 78 | 71 |
| Good | 200 | 45 | 211.0 | 200.3 | -5.1 | 19.1 | 18.1 | -5.2 | +5.6 | -6.7 | 233.3 | 213.9 | 78 | 71 |
| Good | 200 | 52 | 220.2 | 205.6 | -6.6 | 20.1 | 18.8 | -6.3 | +6.4 | -8.5 | 233.3 | 213.9 | 78 | 71 |
| Good | 300 | 40 | 230.2 | 212.3 | -7.8 | 18.3 | 16.5 | -10.1 | +14.0 | -12.1 | 258.9 | 229.6 | 79 | 82 |
| Good | 300 | 45 | 236.7 | 219.1 | -7.5 | 19.1 | 17.1 | -10.1 | +14.5 | -10.6 | 258.9 | 229.6 | 79 | 82 |
| Good | 300 | 52 | 244.5 | 222.7 | -8.9 | 20.0 | 17.7 | -11.6 | +16.5 | -12.3 | 258.9 | 229.6 | 79 | 82 |
| Good | 400 | 40 | 246.5 | 223.2 | -9.5 | 18.6 | 15.8 | -14.7 | +24.4 | -15.4 | 270.9 | 236.1 | 83 | 79 |
| Good | 400 | 45 | 252.1 | 229.4 | -9.0 | 19.3 | 16.5 | -14.6 | +24.7 | -13.7 | 270.9 | 236.1 | 83 | 79 |
| Good | 400 | 52 | 258.7 | 231.8 | -10.4 | 20.4 | 17.1 | -16.1 | +27.4 | -15.3 | 270.9 | 236.1 | 83 | 79 |
| Marginal | 100 | 40 | 140.6 | 145.2 | +3.3 | 18.4 | 18.8 | +2.5 | -1.6 | +2.8 | 169.2 | 169.9 | 79 | 76 |
| Marginal | 100 | 45 | 147.6 | 152.8 | +3.5 | 19.1 | 19.6 | +2.6 | -1.6 | +4.4 | 169.2 | 169.9 | 79 | 76 |
| Marginal | 100 | 52 | 156.0 | 159.3 | +2.1 | 20.1 | 20.5 | +1.9 | -1.6 | +2.7 | 169.2 | 169.9 | 79 | 76 |
| Marginal | 200 | 40 | 193.9 | 188.6 | -2.7 | 17.5 | 17.0 | -2.5 | +2.2 | -5.3 | 229.1 | 212.0 | 83 | 78 |
| Marginal | 200 | 45 | 201.1 | 196.2 | -2.4 | 18.2 | 17.7 | -2.5 | +2.6 | -3.8 | 229.1 | 212.0 | 83 | 78 |
| Marginal | 200 | 52 | 210.3 | 202.5 | -3.7 | 19.1 | 18.5 | -3.2 | +2.8 | -4.9 | 229.1 | 212.0 | 83 | 78 |
| Marginal | 300 | 40 | 221.8 | 208.0 | -6.2 | 17.3 | 16.0 | -7.3 | +9.1 | -10.3 | 254.8 | 226.9 | 89 | 89 |
| Marginal | 300 | 45 | 228.2 | 214.8 | -5.8 | 18.1 | 16.7 | -7.6 | +10.3 | -9.0 | 254.8 | 226.9 | 89 | 89 |
| Marginal | 300 | 52 | 236.1 | 220.3 | -6.7 | 19.0 | 17.4 | -8.4 | +11.2 | -9.4 | 254.8 | 226.9 | 89 | 89 |
| Marginal | 400 | 40 | 239.1 | 219.2 | -8.3 | 17.5 | 15.4 | -11.7 | +17.5 | -13.7 | 268.2 | 234.0 | 81 | 77 |
| Marginal | 400 | 45 | 244.7 | 225.5 | -7.8 | 18.4 | 16.1 | -12.2 | +19.7 | -12.6 | 268.2 | 234.0 | 81 | 77 |
| Marginal | 400 | 52 | 251.5 | 230.6 | -8.3 | 19.3 | 16.8 | -12.8 | +20.5 | -12.3 | 268.2 | 234.0 | 81 | 77 |
| Low Feasibility | 100 | 40 | 118.2 | 135.0 | +14.2 | 16.6 | 17.9 | +8.4 | -2.8 | +17.6 | 155.3 | 164.3 | 92 | 84 |
| Low Feasibility | 100 | 45 | 126.6 | 142.5 | +12.6 | 17.4 | 18.7 | +7.6 | -2.8 | +15.4 | 155.3 | 164.3 | 92 | 84 |
| Low Feasibility | 100 | 52 | 136.3 | 151.2 | +10.9 | 18.5 | 19.8 | +6.9 | -2.9 | +13.4 | 155.3 | 164.3 | 92 | 84 |
| Low Feasibility | 200 | 40 | 171.9 | 180.1 | +4.8 | 15.6 | 16.3 | +4.4 | -3.9 | +6.3 | 217.6 | 207.9 | 94 | 88 |
| Low Feasibility | 200 | 45 | 181.7 | 187.9 | +3.4 | 16.4 | 17.0 | +3.4 | -3.2 | +4.4 | 217.6 | 207.9 | 94 | 88 |
| Low Feasibility | 200 | 52 | 193.7 | 197.2 | +1.8 | 17.5 | 17.8 | +2.0 | -2.2 | +2.2 | 217.6 | 207.9 | 94 | 88 |
| Low Feasibility | 300 | 40 | 201.1 | 200.4 | -0.4 | 15.4 | 15.4 | -0.1 | -0.3 | -0.6 | 247.7 | 223.0 | 90 | 81 |
| Low Feasibility | 300 | 45 | 210.5 | 207.4 | -1.4 | 16.2 | 16.0 | -1.4 | +1.3 | -2.2 | 247.7 | 223.0 | 90 | 81 |
| Low Feasibility | 300 | 52 | 221.6 | 215.8 | -2.6 | 17.3 | 16.8 | -3.0 | +3.5 | -3.9 | 247.7 | 223.0 | 90 | 81 |
| Low Feasibility | 400 | 40 | 220.0 | 212.2 | -3.5 | 15.4 | 14.8 | -4.2 | +5.2 | -5.3 | 263.6 | 231.5 | 94 | 72 |
| Low Feasibility | 400 | 45 | 228.6 | 218.7 | -4.3 | 16.3 | 15.4 | -5.7 | +7.5 | -6.6 | 263.6 | 231.5 | 94 | 72 |
| Low Feasibility | 400 | 52 | 238.8 | 226.5 | -5.2 | 17.5 | 16.2 | -7.4 | +10.6 | -7.9 | 263.6 | 231.5 | 94 | 72 |

Age 40: BA percent change min -10.2, median -4.2, max +14.2.

Age 45: BA percent change min -10.5, median -4.7, max +12.6.

Age 52: BA percent change min -11.5, median -5.9, max +10.9.


## S9. Not completed, caveats (second pass)

1. CAL_*_SE_LOG are v102 placeholders (no bootstrap for the NO fits).
2. Monte Carlo, joint draws, Table 8 intervals, registry and parity harness not rerun.
3. HCB_P fitted on percentile BAL, fed conventional BAL.
4. dHT_c_NO was deployed by stated deviation from the preregistered intercept rule (see the rule text above).
5. The v102 yield grid of 24 September is taken as the reference as found; it was not regenerated.
