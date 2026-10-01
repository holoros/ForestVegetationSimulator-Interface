# Red team 2, koa v103 after the weighted BAL fix

Reviewer: adversarial red team, read only. Job: ~/jobs/koa_v103_20260930 (RUN.md, STAGE1_REPORT.md section 8, a2/redteam first review, a2/run_balfix_chain.sh and a2/logs/balfix_chain.log, a2/out/tables_v103.md, a2/closeout/validation, a2/closeout/jointmc, engine_v103/out_m1, a2/fin/out). Date 30 September 2026. Scratch engine copy in ~/jobs/rt2_koa_v103_scratch/eng; scripts and outputs copied to a2/redteam2/. No coordinate column was read. Numbers are recomputed from the job's files or engine copy unless labelled "as reported". Settled decisions (BYI in index units, option A, v102 dDBH vector with c re-solved under l, dHT_L_NO, Garcia beta 0.1480, HCB_P, Eq. 5 v102 and Eq. 5a v103, weighted engine BAL) are taken as given.

## Overall verdict

READY WITH DISCLOSURES for v105, on the condition that the five must-change items below are done first. None of them changes a Python engine number. The weighted BAL fix is correct: it matches a hand computation to rounding error, reduces exactly to the unweighted rule of record when expf is equal, holds the survivors' BAL fraction at 0.48 to 0.50 over 100 years (pre-fix rule on the same lists: 0.24 to 0.25), and it reaches every Python path that builds a tree list BAL. The post-fix change is the one the first red team predicted (year 100 QMD -6.1 to -11.8 percent, VOL -7.7 to +0.1 percent against the pre-fix run). What is still wrong is around the engine rather than in it. The HiGy.R R mirror still computes conventional BAL. The parity harness never touches BAL. STAGE1_REPORT section 8 and RUN.md still describe the pre-fix engine. The validation has no out of sample natural unit and flags in-sample status only against MORT_CAL. Table 8 is still built on the source-set MC. The Aviva grid still has none of its caveats in the file the client sees.

## Severity table

| # | Severity | Finding | Key numbers (recomputed unless noted) | Where |
|---|---|---|---|---|
| R1 | Major | HiGy.R, the R mirror, does not implement the weighted percentile. calc_bal is conventional cumsum(ba) - ba, and the header records this as a "recorded mismatch" | KOA_BAL_DEFINITION = "percentile" with calc_bal conventional (HiGy.R L683, L2096 to L2110); no weighted function in R | engine_v103/HiGy.R, a2/patch_higy_v103.py |
| R2 | Major | The parity harness has no BAL coverage, so "parity 0" in the chain log says nothing about the fix | All 18 cases compare stand mortality and allocated deaths with ddbh given as input; synthetic lists have no ties, no unequal weight ties and no decayed records | koa_parity_cases_050.json, parity_compare_050_v103.txt |
| R3 | Major | Documentation lags the code. STAGE1_REPORT section 8 still says the engine's percentile path "computes l" (the claim finding 1 disproved). Neither STAGE1_REPORT nor RUN.md records the fix, the gate, the MORT_CAL re-solve or the rerun | MORT_CAL 2.46620 to 2.54275 (SE_LOG 0.24335, n 24) is only in balfix_chain.log. The stale "KNOWN RESIDUAL" comment remains in project_psp | STAGE1_REPORT.md section 8, RUN.md, koa_projector.py L302 to L310 |
| R4 | Major | The plot-level validation is sound in construction but is in-sample throughout, and the in_sample flag understates this | All 17 non-disturbance units are in the dDBH NO fitting frame (DOFAW natural 13 to 326 rows each, PSP planted 18 to 204, Kulani 12 101). in_sample is True only for the 6 MORT_CAL plots; planted units show False. Natural out of sample n = 0 (n = 2 at minimum 15 records) | a2/closeout/validation/val_v103_plotlevel.csv, frames/final/dDBH_NO_v103_model.csv |
| R5 | Major | The within-source installation MC is a real design fix but a small one, and it is not the MC behind Table 8 | Vector draws explain 96 to 99 percent of log multiplier variance (R2 0.99, 0.98, 0.96, 0.99). The installation residual sd_log is 0.035, 0.055, 0.126, 0.071. Widths vs deployed are 0.47 to 1.06. Deployed out_m1 still comes from a2/mc/out (source sets) | a2/closeout/jointmc/out/K_joint_draws.csv; a2/redteam2/mc.out |
| R6 | Major | Aviva grid: the three caveats are still present and still not stated in the files | Age 1: QMD 7.2 cm, HT 5.5 to 5.9 m, DBHMAX 16.4 cm. DBHMAX reaches 69 cm at ages 27 to 34 on Excellent and Good, and 63.6 to 69.7 cm at age 40. VOL column is m3/ha next to ft2/ac and TPA. No README or header in a2/fin/out | a2/fin/out/*.csv |
| R7 | Moderate | Natural density envelope and planted domain unchanged by the fix | Natural peak SDI 426 to 429 (planted 880 to 889). Kulani 12 predicted BA 43.8 vs observed 13.6 m2/ha, survival 0.54 vs 0.19. The Low Feasibility grid site (BYI 120) and the BYI 100 scenarios sit below all PSP planted data (min BYI 157.7) | traj_v103.csv, val_v103_plotlevel.csv |
| R8 | Minor | Site ordering: BA and VOL invert late, and natural QMD sits above planted QMD at every age for matched BYI | BA ordering holds only to year 92 (natural) and 80 (planted); VOL to 149 and 167 | traj_v103.csv; a2/redteam2/traj.out |
| R9 | Minor | Bakuzis: planted 264 and 450 still FLAG, slopes a little shallower | Post-fix natural -1.55, -1.85, -2.03; planted -2.03, -2.32, -2.56 (pre-fix -2.06, -2.46, -2.78) | engine_v103/out_m1/bakuzis_slopes_M1.csv |
| R10 | Minor | Weighted engine BAL and unweighted frame l differ at year 0 where expf varies within a plot. This is small for the constants | FIA microplot records only (102 of 1,071 natural dDBH rows); DOFAW and PSP carry equal expf, so the two are identical | koa_equations.py |
| R11 | Minor | Origin label in the model frames is not the planted flag | PSP rows: Origin "Natural" on all 3,452 rows while Planted = 1 on 3,433 (recoded by psp_planted in inc_v103.R) | frames/final/dDBH_NO_v103_model.csv |
| R12 | Minor | Weighted rule edge case: a single live record among decayed records scores fraction 1 | [10, 20, 30] cm with expf [50, 1e-5, 1e-5] gives 1.0, 0, 0 | t_bal.out |

## Evidence by question

### Q1. Is the weighted BAL fix correct and complete?

Function. bal_percentile_fraction_weighted(dbh, expf) returns (W_ge,i - w_i) / (W - w_i), where W_ge,i is the expf of all records with DBH at least DBH_i (ties included). This is the weighted analogue of the rule of record, 1 - (r_min - 1)/(n - 1). I checked it against a brute force hand computation (a2/redteam2/t_bal.py):

| case | dbh | expf | engine | hand |
|---|---|---|---|---|
| ties with unequal weight | 30, 20, 10, 10 | 4, 2, 1, 3 | 0, 0.5, 1, 1 | 0, 0.5, 1, 1 |
| all tied | 10, 10, 10 | 1, 2, 3 | 1, 1, 1 | 1, 1, 1 |
| microplot plus decayed records | 5, 40, 40, 12, 12, 12, 33 | 741, 59.5, 59.5, 1e-5, 59.5, 741, 59.5 | 1, 0.0358, 0.0358, 0.5692, 0.5538, 0.2431, 0.0717 | identical |
| 2,000 random lists (n 2 to 40, heavy ties, weights 1e-5 to 741) | | | max abs diff 3.6e-10 (float cumsum) | |
| equal expf vs unweighted rule of record | | | max abs diff 1.1e-16 | |

Tied records count each other as "at least as large". This matches the rule of record's minimum-rank convention. stand_bal switches on KP.BAL_PERCENTILE_WEIGHTED (True) only when expf is passed. With the switch on, stand_bal(10, [30, 20, 10], expf [1, 1, 100]) gives 0, 0.099, 10, where the unweighted rule gives 0, 5, 10. Edge case R12: when one live record is left among decayed ones, its "others" are all dead, so the fraction is taken over 1e-5 weights. This is harmless in practice but should be noted in the docstring.

Behaviour. I instrumented RC.project on the engine copy (balcheck.py). The expf-weighted stand mean fraction is 0.500, 0.492 and 0.482 at years 1, 50 and 100 (natural 264), and 0.500, 0.486 and 0.478 (planted 264). The pre-fix rule on the same lists gives 0.500, 0.337, 0.247 and 0.500, 0.284, 0.236. The fix does what it claims.

Call sites. Every Python tree-list path goes through one of three patched lines:

| path | route | weighted? |
|---|---|---|
| koa_projector.project_psp | line 315, stand_bal(..., expf=expf) | yes |
| run_candidates.project | line 91 | yes |
| regen_m1 (Table 8, MC, Fig 5, S6, S8, S9) | RC.project; uneven via regenerate_uneven_aged; validation via koa_longterm_validation, both project_psp | yes |
| uneven-aged drivers (regenerate_uneven_aged, a2/uneven_point.py) | project_psp | yes |
| yield grid (a2/fin/run_yield_grid_v103.py) | RC.project | yes |
| regen_figS4S5.project_rec | line 102, own copy | yes |
| plotlevel_validation.py | V.project_psp | yes |
| project_cohort (regen_t8_chunked only) | stand_bal(qmd=...) cohort path, fitted fraction | not applicable, and not in the chain |
| HiGy.R | calc_bal conventional | no (R1) |

The engine copies used by the closeout (a2/closeout/validation/engine, a2/closeout/jointmc/engine) carry the switch True and MORT_CAL 2.54275. The gate copy engine_v103_wgate carries False and 2.46620. The chain log reports WORST 0.000e+00 for traj and val against the pre-fix outputs (as reported; I did not rerun the gate), so switch off reproduces the pre-fix engine.

Parity (R2). parity_r_050.R and parity_python_050.py test Stage 2 and 3 mortality only, and every case matches exactly. No case builds BAL, and HiGy.R would fail one if it did, because its calc_bal is conventional. For v105 add at least these: a tie case with unequal expf, a microplot-weight case and a decayed-record case (the three rows of the table above), and a 10 year projection parity on one list.

### Q2. Closure of red team 1 findings 1 to 14

| # | Status | Evidence |
|---|---|---|
| 1 engine BAL | Closed in Python, partly closed overall | Fraction held at 0.48 to 0.50. Post-fix vs pre-fix at 100 yr: QMD natural -6.1, -7.9, -9.0 percent, planted -11.8, -11.3, -10.1; VOL -5.9, -5.4, -7.7 and -7.7, -2.6, +0.1; TPH +8.8 to +26.0. These equal RT1's predicted ranges. R mirror, parity and documentation still open (R1 to R3) |
| 2 natural validation | Partly closed | 2628 separated; FIA at plot level. Natural (excluding 2628) QMD bias pred minus obs is -0.28 cm, RMSE 1.71 (v102 bias -2.19). All 6 natural units are in-sample, n out of sample 0; no LOIO rerun |
| 3 c rise is definitional | Not addressed in text found | Nothing in STAGE1_REPORT section 8 says so. Still true by construction |
| 4 FIA unit and survival metric | Closed | x1 pooling, minimum 20 records, weighted survival (Q3) |
| 5 joint MC | Partly closed | Within-source design run as a closeout side job; deployed Table 8 unchanged; no statement found of which multiplier SE feeds Table 8 |
| 6 Aviva grid | Partly closed | Reissued after the fix (correct order); caveats not written into the files |
| 7 natural envelope | Open, disclose | Peak SDI 426 to 429. Year 24 natural TPH 399 to 306, QMD 20.7 to 29.1 cm, BA 13.4 to 20.3 m2/ha vs Scowcroft et al. 2007 (UNVERIFIED) about 1000, 18, 25.7 |
| 8 planted domain | Open, disclose | Kulani 12 BA 43.8 vs 13.6 m2/ha, survival 0.540 vs 0.194 |
| 9 A1 gate | Disclosure, unchanged | Not retested (fix does not touch the frames) |
| 10 Bakuzis | Open, disclose | FLAG count 2 (planted 264, 450) |
| 11 stale S4/S5 | Closed | out_m1 FigS4/S5 and point CSVs rewritten at 14:22 and 14:30; md5 differs from out_m1_v102copy and out_m1_prebalfix |
| 12 labels, signs | Mostly closed | Table A header now (v103 - v102)/v102; C1 and C2 both pred minus obs; the plot-level table documents the observed BA change through the "before" rows (mean obs BA 16.0 vs 26.5) |
| 13 MC point position | Partly closed | Deployed natural QMD point at 0.17 to 0.32 of the interval, TPH 0.53 to 0.94; installation MC natural QMD 0.31 to 0.42 |
| 14 weak site terms | Settled, disclose | Unchanged |

### Q3. Plot-level validation

Construction. FIA subplots are pooled with EXPF/4, which returns the per plot TPA_UNADJ x 2.471 expansion (x1). This is correct: TPA_UNADJ already carries the microplot factor, so it does not need a separate adjustment. My recomputed 2628 plot values (observed BA 25.75 m2/ha, weighted survival 0.215) match RT1's. The mirror of validate() reproduces the engine's own subplot tables exactly (max diff 0, as reported in run_v103.log). Weighted survival equals count survival on every DOFAW and PSP unit because expf is equal within those plots, so the change only matters for FIA.

The minimum of 20 removes every FIA plot except 2628 (2647 and 4895 have 19 records each). At 15 they return; they are the only out of sample natural units, and v103 does worse than v102 on them (QMD bias +3.85 vs +1.21 cm, survival -0.181 vs -0.119). The threshold is defensible but deletes the only out-of-sample evidence, so report the sensitivity beside the main table.

In-sample status (R4). in_sample only marks MORT_CAL plots. All 11 planted units (PSP 103 to 108, 123, 202 to 204, Kulani 12) are in the dDBH NO fitting frame on which the planted constant is solved, so the planted "False" labels are misleading. The honest statement for v105 is that there is no independent validation of either origin: Table C is a goodness-of-fit check at the stand level over 4 to 52 yr spans.

Results as rebuilt. Natural (6 DOFAW): QMD bias -0.28 cm, BA bias +0.60 m2/ha with RMSE 8.93, survival bias +0.060. TOST passes QMD and fails BA and survival. Planted (11): QMD -0.93, BA -1.80 (RMSE 13.3), survival +0.030. 2628 disturbance case: QMD +9.80 cm, survival 0.103 predicted vs 0.215 observed. BA is right (25.64 vs 25.75). The natural BA misses are large and cancel: Kulani 23 predicted 28.0 vs observed 41.5, Laupahoehoe 41 27.6 vs 36.5, Waiakea 24 24.4 vs 13.6, Waikamoi 25 28.5 vs 19.9.

### Q4. Within-source installation resampling

Installation counts in the dDBH NO frame: DOFAW 4 natural installations (6 plots) plus 1 planted (Kulani 12); FIA 23; KMR PSP 1; PSP 31 planted plus 1 natural (19 rows); 38.9 distinct installations drawn per replicate on average (32 to 46). Resampling within source removes the degenerate tails of the source-set design: no draw can now solve the natural multiplier on 19 PSP trees, or the planted dHT multiplier on DOFAW alone. That is a real correction.

It cannot give a sampling distribution where it matters most: KMR PSP and the PSP natural cell (one installation each) never vary, and the natural dDBH multiplier is 89 percent DOFAW rows from 4 installations (at most 35 distinct multisets).

The multiplier spread is not installation uncertainty at all. Regressing log multiplier on the drawn vector coefficients gives R2 of 0.990 (cal_dd_nat), 0.977 (cal_dd_plt), 0.962 (cal_dh_nat) and 0.988 (cal_dh_plt). The residual installation sd_log is 0.035, 0.055, 0.126 and 0.071, the same size as the vector fixed constants bootstrap SE of log c (0.0296, 0.0538, 0.1293, 0.0695). So about 97 percent of the multiplier width is the re-solve compensating for the vector draw, under either resampling design. Marginal sd_log moves only from 0.401, 0.388, 0.806, 0.808 (source sets) to 0.351, 0.365, 0.648, 0.644 (installations). Table 8 interval widths under the installation draws are 0.55 to 0.93 (natural QMD), 0.63 to 0.77 (planted QMD) and 0.58 to 1.05 (VOL) of the deployed widths, with point values identical (max diff 0). Verdict: a correct improvement, worth deploying for v105 because it is more defensible and centres the natural point better (QMD position 0.31 to 0.42 vs 0.17 to 0.32). It should not be described as a material change in uncertainty.

### Q5. Biological realism after the fix

From a2/out/traj_v103.csv (point path, M1 gate), my summary in traj.out:

| origin, BYI | yr 24 QMD / TPH / BA | yr 100 QMD / TPH / BA / VOL | peak SDI (yr) | MAI culm (max) | Reineke, 100 yr after peak SDI |
|---|---|---|---|---|---|
| natural 100 | 20.7 / 399 / 13.4 | 47.3 / 153 / 26.9 / 208 | 426 (95) | 37 (2.66) | -2.36 |
| natural 264 | 25.6 / 346 / 17.8 | 60.0 / 103 / 29.0 / 264 | 428 (62) | 25 (4.24) | -2.23 |
| natural 450 | 29.1 / 306 / 20.3 | 65.4 / 84 / 28.1 / 276 | 429 (49) | 20 (5.56) | -2.21 |
| planted 100 | 29.7 / 637 / 44.0 | 52.0 / 257 / 54.6 / 450 | 880 (47) | 12 (13.20) | -2.14 |
| planted 264 | 35.5 / 501 / 49.5 | 57.3 / 214 / 55.3 / 492 | 885 (31) | 8 (20.29) | -2.04 |
| planted 450 | 39.1 / 434 / 52.0 | 59.8 / 194 / 54.5 / 515 | 889 (25) | 7 (26.20) | -2.06 |

Site ordering holds at every year for QMD, HT and TPH (decreasing with site). BA ordering breaks from year 92 (natural) and 80 (planted; at 100 yr 54.6, 55.3, 54.5), VOL from 149 and 167. These late inversions predate the fix (BA 99 and 73) and are disclosable for a 40 to 52 yr rotation. Natural QMD exceeds planted QMD at every age for matched BYI because the natural harness starts from an initial stock and self-thins to half the planted density; state this next to Fig S9 so it is not read as a growth crossover.

Reineke slopes after peak (-2.04 to -2.36) are steeper than -1.605 but plausible for post-peak decline. The natural SDI envelope (about 430) is half the planted envelope and half the observed DOFAW natural plot SDI (623 to 924, as reported by RT1), unchanged by the fix. MAI culminates at 20 to 37 yr (natural) and 7 to 12 yr (planted), the latter inside the PSP data span.

Planted extrapolation. 88 percent of planted dDBH rows are PSP with a median interval of 1 yr; Kulani 12 is the only older planting and its BA is over-predicted 3.2 times. Planted rows with BYI below 158 are 413 of 3,900 (Kulani 12 at BYI 25, KMR PSP 109 to 191, 143 PSP rows), so BYI 100 (Table 8 Low) and 120 (grid Low Feasibility) rest on one plot and one installation. Flag planted output beyond about age 18 and below BYI 158 as extrapolation.

Uneven-aged Table D, v103 vs v102: QMD +21.5 to +38.2 percent, TPH -19.6 to -35.9 percent, the largest version change in the deliverables.

### Q6. Aviva RLF grid

yield_grid_compare.csv, 16 cells, ages 40, 45 and 52 (v103 post-fix vs 24 September v102): BA -9.3 to +5.7 percent, QMD -5.2 to +3.6, stems -5.9 to +0.9, VOL -12.6 to +6.6. The pattern is systematic and matters for cash flow. By density, VOL change is -3.5 to +6.6 (100 TPA), -8.4 to +2.1 (200), -10.8 to -0.4 (300) and -12.6 to -2.2 (400). By site it is -12.6 to -1.9 (Excellent) and -6.8 to +6.6 (Low Feasibility). High density on good sites loses 8 to 13 percent of standing volume in the harvest window, and low density on poor sites gains up to 7 percent. The fix alone moved the grid by VOL -6.3 to -1.4, BA -3.6 to -1.1 and QMD -10.3 to -0.7 percent against the pre-fix grid. For an RLF model built on 300 to 400 TPA Excellent or Good cells, a 10 percent lower harvest volume is material even though it lies inside the MC interval. Peak BA age moves earlier on most dense cells (for example Excellent 200 TPA 76 to 67 yr). BA then falls 27.6 to 44.1 percent from peak to 200 yr.

Caveats, all still present (R6):

- Age offset: age 1 carries QMD 7.2 cm, HT 5.5 to 5.9 m and DBHMAX 16.4 cm, so grid age is years since the harness start, not since planting.
- 69.7 cm cap: DBHMAX reaches 69.0 cm at ages 27 to 34 on Excellent and Good and 45 to 49 on Low Feasibility, and it is 63.6 to 69.7 cm at age 40 and 68.9 to 69.7 at 52. The cap binds inside the rotation window on every commercial cell.
- VOL units: VOL is m3/ha in a table whose other columns are ft2/ac, TPA and inches.

The grid Reineke column (-0.79 to -1.49, diagnostics file, as reported) also disagrees with the Table 8 slopes and should be explained or dropped. None of these caveats appears in a2/fin/out, which holds only the three CSVs.

### Q7. What a hostile Forest Ecosystems referee finds first

1. No independent validation: every Table C unit is in the increment fitting frame, the six natural units also set MORT_CAL, and the only two out of sample natural plots are excluded by the 20 record rule (v103 worse than v102 on them).
2. The BAL definition changed after the gate that justified the constants. The gate still holds at year 0 for every equal-expf source (all but 102 FIA rows); say so in one sentence.
3. Intervals are mostly vector compensation (R2 0.96 to 0.99); one-installation cells never vary.
4. Planted projections to 100 yr rest on 1 yr PSP intervals under age 18; the one old planting is over-predicted 3.2 times in BA.
5. The natural stand never exceeds SDI about 430, half the observed natural plots.
6. HiGy.R and the Python engine disagree on BAL (R1), so a referee running HiGy.R will not reproduce Table 8.

## Must change before v105

1. Implement the weighted percentile in HiGy.R for the tree-list path (or remove the claim that HiGy.R mirrors the projector) and add BAL parity cases: unequal-weight ties, a microplot weight, decayed records and a 10 yr projection.
2. Update STAGE1_REPORT section 8 and RUN.md: the fix, the switch gate (WORST 0), MORT_CAL 2.46620 to 2.54275 (SE_LOG 0.24335), the rerun chain with md5s, and the post-fix changes. Remove the stale "KNOWN RESIDUAL" comment in project_psp. Add one sentence that the weighted form equals frame l wherever expf is equal within a plot (all sources except the FIA microplot records).
3. Relabel the validation. Add an in_fit_frame column alongside in_sample (true for all 17 units). State that there is no out-of-sample natural or planted unit. Move the FIA minimum-15 sensitivity (2 out-of-sample natural plots, v103 QMD bias +3.85 cm) into the main text.
4. Decide the MC of record. Either regenerate Table 8 and the out_m1 intervals from the within-source installation draws, or state that Table 8 uses source-set draws. In both cases say that the multiplier width is almost entirely vector compensation (residual sd_log 0.035 to 0.126).
5. Put the age offset, the 69.7 cm cap binding at ages 27 to 34 and the VOL unit into a header row or README shipped with the Aviva grid. Also flag the planted Low Feasibility cell (BYI 120) as below the PSP data range.

## Can be disclosed

- R7 to R12 as stated in the severity table: natural SDI envelope and the UNVERIFIED Scowcroft miss; Kulani 12 and planted extrapolation beyond about age 18 and below BYI 158; late BA and VOL ordering inversions; Bakuzis FLAGs; the Origin label; the single-live-record edge case.
- Uneven-aged Table D change vs v102, and natural DOFAW BA RMSE 8.9 m2/ha despite unbiased QMD.
- Settled decisions: dHT site term not identified, dHT size gate, Eq. 5 v102 retained.

## Reproducibility

Scripts and outputs in a2/redteam2/:

- t_bal.py and t_bal.out: hand check and random test of the weighted function.
- balcheck.py and balcheck.out: 100 yr BAL fraction trace on the engine copy.
- traj.py and traj.out: trajectory summaries, site ordering and pre vs post fix changes.
- mc.py and mc.out: vector R2 decomposition, interval widths and point positions for the installation MC.

Engine runs used ~/jobs/rt2_koa_v103_scratch/eng, a copy of engine_v103 with __pycache__ removed. The grid, validation and frame summaries were one-line pandas reads of the files named in each table. The switch-off gate (WORST 0) and MORT_CAL 2.54275 are as reported in balfix_chain.log and were not rerun. Nothing under ~/jobs/koa_v103_20260930 was modified outside a2/redteam2/.
