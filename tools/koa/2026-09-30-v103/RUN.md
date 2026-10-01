# RUN.md, koa v103 Stage A1 (job ~/jobs/koa_v103_20260930, firebreather)

Started 30 September 2026. R 4.5.1 (nlme), python3 (pandas, numpy). Only this directory is written; every other job directory is read only and inputs are copies (md5 in logs/md5_inputs.txt).

## Preregistered rules (written before any repair or fit was run)

D1 stand covariates. For every plot-year of the koa tree table, BAPH, TPH, QMD and SDI (summation form of record, sum EXPF x (DBH/25.4)^1.605) are recomputed from LIVE stems (Status live, DBH > 0, EXPF > 0) of ALL species from the deduplicated all species list; BA.AK and pBA.AK from the live koa list. The all species list is in/TREE.ALL.csv deduplicated with the v102 rulings A3 (byte identical rows collapse) and A1' (doubled tree visit keeps the larger Age, ties keep the last record in file order; A2' is the same keep rule). FIA plot-years are rebuilt from in/HI_TREE.csv (STATUSCD 1, all species, DIA > 0, per subplot expansion TPA_UNADJ x 4 x 2.47105 per ha), mapped Install = STATECD-UNITCD-COUNTYCD-PLOT, Plot = SUBP, Tree = TREE, Measure = INVYR. Where a plot-year has no live stem with EXPF > 0: if it has no live stem with DBH > 0 the stand variables are 0 (QMD NA); if it has live stems with DBH > 0 but no expansion factor, the deposited value is kept and flagged.

D2 carried forward records. Every installation and plot of every source is scanned; for each visit the trees live with DBH > 0 at that visit and the previous visit are compared. A visit with at least 90 percent of those trees identical in DBH and HT (HT missing at both counts as identical) is a copied visit and is removed from the tree lists entirely. In a visit with 50 to 90 percent identical trees the identical tree-visits are removed (partial copy) and the rest kept. A tree with unchanged DBH in a visit under 50 percent identical is kept (real zero growth). Stand variables are computed on the full visit (before partial copy tree-visits are removed, since those stems exist).

BAL definitions carried on every frame that uses BAL: d = deposited form recomputed on the repaired list, (1 - rank percentile of DBH over every koa record of the plot-year) x repaired BAPH; l = live list percentile, (1 - rank percentile over live koa stems) x repaired BAPH; c = conventional, expansion weighted basal area per ha of live stems of all species strictly larger than the subject.

Removal screen (refit2.R R9): any PSP interval with a removal year from Thin_Yr or removal_t1_years strictly inside (t0, t1) is dropped from the increment and survival frames.

Eq. 4 increment selection (preregistered, written before any increment fit). For each response (dDBH, dHT) the candidates are P_CS (deposited form percentile BAL d, consecutive frame, the incumbent form), C_CS and C_NO (conventional BAL c), L_CS and L_NO (live list percentile BAL l). All use the engine form recursion (HCB_P crown ratio computed with the candidate's BAL, planted size guard min(size, 45 cm) for dDBH and min(size, 20 m) for dHT inside the recursion), random intercept b0 on Data/Install (CS) or Data/Install/TreeID (NO), varPower(0.2, ~DBH.0), start from the v102 vector of record. Every candidate is scored on both the CS and the NO v103 frames. Eligible if (i) sign checks pass (dDBH b1 > 0, b4 < 0, b5 > 0, b6 < 0; dHT b1 > 0, b4 < 0), (ii) the installation cluster bootstrap equivalence test of observed on predicted annual increment (1,000 resamples, intercept region 25 percent of the mean observed, slope region 1 +- 0.25) passes on both frames, and (iii) the largest |obs/pred - 1| over DBH classes to 60 cm (HT classes to 30 m) on the NO frame is at most 0.25. Among eligible candidates prefer conventional BAL (C_CS or C_NO, the lower NO frame RMSE of the two) unless another eligible candidate has an NO frame RMSE more than 2 percent lower. P_CS is always reported as the benchmark; if it beats the chosen candidate by more than 1 percent RMSE on both frames, P_CS is deployed and that is stated. If no candidate is eligible for a response, the candidate with the smallest maximum equivalence region (max over the four intercept and slope regions on the two frames) is deployed and the deviation recorded. Origin constants are solved recursion consistently by origin (refit2.R solve_c); CF = exp(0.5 (tau_source^2 + tau_inst^2)); engine CAL_o = c_o / CF. The two deployed fits then get a 400 resample installation cluster coefficient bootstrap resampling within source (boot_coef2.R pattern) for bootstrap SE and percentile intervals of every coefficient and of c_natural and c_planted, and SE of log c for CAL_*_SE_LOG.

Eq. 3 HCB rule: refit HCB_P form on the FIA crown frame with covariates rebuilt from HI_TREE under the selected BAL definition; deploy only if population average RMSE improves and every coefficient keeps its sign; otherwise keep HCB_P.

## Commands and timings

All commands run from ~/jobs/koa_v103_20260930 with `setsid nohup ... &` and polled (fire_run 60 s cap). Timings from logs/timings.txt and log timestamps.

| Step | Command | Inputs (md5 in logs/md5_inputs.txt) | Outputs | Time |
|---|---|---|---|---|
| D1, D2 repair | python3 scripts/repair_v103.py | in/TREE.ALL.csv 4c4a654c, in/HI_TREE.csv ba376b2c, inputs/AK_TREE_v102.csv 81383c5e, inputs/AK_PLT.csv 072334b5 | inputs/AK_TREE_v103.csv, inputs/AK_PLT_v103.csv, out/repair/*, logs/repair_v103.log | about 45 s |
| builder chain on v102 (gate) and v103 | bash scripts/build_frames_v103.sh (build_incr.py, builders/build_frames_incr.R, builders/rebuild_surv_origin_2026-09-16_REFERENCE_COPY.py, builders/build_pairs_m1.R) | inputs/AK_TREE_v10x.csv, inputs/PLT.GEO.V2_v102.csv 2884cb19, psp_origin_thinning 92704a1c | frames/v102, frames/v103 | 39 s, 53 s |
| post frames | python3 scripts/post_frames_v103.py | frames/v10x, v102 frames, AK_HCB, ingrowth, plot_intervals of v102 | frames/final/*, out/frames/* | about 50 s |
| Eq. 2 height | Rscript track2/height_refit_v103.R; track3_rt/02_height_refit.R (LOIO) on v102 and v103 | track2/height tree_join_v102, frames/final/tree_join_v103.csv | track2/out/height_*, track3_s02/v10x | 31 s; 50 s and 1,190 s |
| Eq. 6 ingrowth | Rscript track2/ingrowth_refit_v103.R | ingrowth v102 and v103 frames | track2/out/ingrowth_coefficients_v103.csv | 67 s |
| Eq. 5, 5a | Rscript track2/surv_refit_v103.R | surv baseline and recovered ii v102 and v103 | track2/out/surv_* | 1,116 s |
| Stage 1, Garcia | Rscript track2/stage1/stage1_garcia_v103.R; python3 track2/stage1/beta_anchor_v103.py | plot_intervals v102 and v103, M1 pair tables record, v102, v103, AK_TREE record and v103 | track2/stage1/* | about 12 min; 40 s |
| Eq. 3 HCB | Rscript track2/hcb/hcb_v103.R | frames/final/AK_HCB_v103.csv | track2/hcb/* | about 3 min |
| Eq. 4 increments | Rscript track2/inc/inc_v103.R all | frames/final/*_CS_v103.csv, inputs/AK_TREE_v103.csv, refit2 frames2 (gate), v102 frames (gate) | out/inc/*, frames/final/*_v103_model.csv | 19.6 min |
| cohort fraction | Rscript track2/inc/cohort_v103.R | refit2 bal_treevisit2 (gate), inputs/AK_TREE_v103.csv | out/inc/cohort_bal_fraction_v103.csv | about 40 s |
| coefficient bootstrap | Rscript track2/inc/boot_v103.R dDBH 400 4; Rscript track2/inc/boot_v103.R dHT 400 4 (in parallel) | out/inc/fits_v103.rda, frames/final/*_NO_v103_model.csv | out/inc/boot_v103_* | see logs/boot_v103_*.log |
| report | python3 scripts/make_report.py | everything above | STAGE1_REPORT.md, out/v103_constants.json | seconds |

Deviations recorded while running: the Stage 1 reproduction gate first failed (0.027) because it was pointed at plot_intervals_origin (294 rows, the non span table) rather than plot_intervals (326) with the span removal rule of origin_refit_span.R; with the correct input it reproduces the deployed json to 4e-15. The refit2 reproduction gate R1 is met at 5.7e-5 SE (CSV round trip) rather than 1e-6 absolute. The beta anchor definition of record counts dead stems (reproduced only in that form).

## Stage A1 close-out (30 September 2026, afternoon)

| Step | Command | Outputs | Time |
|---|---|---|---|
| v102 dDBH vector under d, l, c; gate; constants bootstrap | Rscript --vanilla track2/inc/a1close_v103.R | out/inc/a1close_v102vector_by_bal.csv, a1close_v102vector_strata.csv, a1close_bal_choice.txt, boot_v103_dDBH_v102recal.csv, boot_v103_dDBH_v102recal_summary.csv (renamed from the script's output name so the dDBH_L_NO summary keeps boot_v103_dDBH_summary.csv), boot_v103_dHT_resolveonly.csv | about 9 min |
| stage 1 AUC | Rscript --vanilla track2/stage1/stage1_auc_v103.R | track2/stage1/stage1_auc_v103.txt (v103 0.6407; v102 on its frame 0.6289; record 0.6668 was on the pre-dedup frame) | seconds |
| report and json | python3 scripts/make_report.py; python3 scripts/finalize_constants_v103.py; python3 scripts/report_a1close.py | STAGE1_REPORT.md (backup STAGE1_REPORT_PREV_20260930.md), out/v103_constants.json (A1 version kept as out/v103_constants_A1_PREV_20260930.json) | seconds |

The first a1close launch failed on a missing library(nlme) and was rerun unchanged otherwise.
1bf329dab9d755f4acfe895155fb1d10  track2/inc/a1close_v103.R
d69d6f4d7ee0484caf1a0ffe7a87eb2d  scripts/finalize_constants_v103.py
6d4eb2527ae3830caf8d0d930c7a0c95  scripts/report_a1close.py


## Stage A2 (30 September 2026, afternoon)

Engine patch, weighted BAL fix, close-out of red team items, parallel tracks. Report: a2/A2_REPORT.md. Red team passes: a2/redteam/2026-09-30_koa-v103-A1A2_REDTEAM_REVIEW.md, a2/redteam2/2026-09-30_koa-v103-postfix_REDTEAM2_REVIEW.md.

| Step | Command | Outputs | Result |
|---|---|---|---|
| weighted BAL fix and rerun chain | bash a2/run_balfix_chain.sh | engine_v103_wgate (switch off), a2/out/*_v103.csv, a2/fin/out, a2/mc/out, a2/mort/v103, engine_v103/out_m1; pre-fix copies *_prebalfix | 13:24 to 13:55, all exits 0; switch-off gate WORST 0.000e+00 on traj and val; MORT_CAL 2.46620 to 2.54275 (SE_LOG 0.24335, n 24); mortality parity 18 cases passed |
| FigS4, FigS5 regen | python3 engine_v103/regen_figS4S5.py | engine_v103/out_m1/FigS4_natural_M1.png, FigS5_planted_M1.png | run after the fix (14:13 to 14:30) and after the MC promotion (log a2/logs/figS45_jmc.log, exit 0); stale 11:57 copies in a2/closeout/ |
| table headers and bias sign | python3 a2/compare_v103.py (backup compare_v103_PREV_20260930.py, tables_v103_PREV_20260930.md) | a2/out/tables_v103.md | Table A and D read (v103 - v102)/v102; C1 and C2 predicted minus observed |
| plot level validation | python3 a2/closeout/validation/plotlevel_validation.py; make_tables.py | val_v103_plotlevel.csv (in_sample, in_fit_frame added), tableC_v103_plotlevel.md | FIA pooled at x1, minimum 20 records, weighted survival, 2628 separate; 23 to 17 units plus 2628 (deviation A2-D1) |
| joint MC within source | Rscript a2/closeout/jointmc/joint_draws_v103_inst.R; regen_m1.py in a2/closeout/jointmc/engine; compare_table8.py | promoted 15:43 to a2/mc/out, engine_v103/out_joint, engine_v103/out_m1 and a2/joint_draws_v103.R; previous kept as *_srcset_PREV_20260930 | point gate max difference 0.0 PASS; draws 9 min, MC 1,289 s (deviation A2-D2) |
| HiGy.R weighted BAL | a2/higy/patch_higy_weightedbal.py; parity_bal_r.R, parity_bal_py.py, parity_bal_compare.py | engine_v103/HiGy.R (backup HiGy_PREV_20260930b.R), koa_projector.py comment only (backup _PREV_20260930), BAL parity files copied into engine_v103 | BAL parity max difference 1.4e-15; 18 mortality cases byte identical (deviation A2-D3) |
| Aviva grid caveats | written | a2/fin/out/README_grid.md | age offset, DBH cap, VOL unit, Low Feasibility domain |
| figures | a2/figs/scripts/*.R, *.py | a2/figs/deliver (TIFF 600 dpi, PNG, md5) | Figs 3 to 6, S1 to S8 |
| number registry | a2/registry/koa_numbers_v103.py and stage scripts | a2/registry/numbers_v103.json, numbers_v103_vs_v102.md | 106 keys, 4 null, gate 21 of 21 |

md5 after A2: engine_v103/koa_params.py 720a0f0ad8c3c53c5d9f3bbd72203b44; koa_equations.py fd9b13e4c1b493135eb56cbc86f5097a; koa_projector.py 462c0dd31e729cffc67fe20022907549; HiGy.R 81639e2fc2ebbeb159dffdae6790e9e2; a2/joint_draws_v103.R 56b65053c97c0432d6a6974f5a3daf19; a2/compare_v103.py 190e22726b2c597f9928d46a11e07804; a2/closeout/validation/plotlevel_validation.py b6934963c4ac5ff89ef64dad15478e1a; make_tables.py 480f591bbeb4ff91a2f02ec79d7f4340; a2/fin/out/koa_yield_grid_200yr.csv 2b76f8272a0e0836373ced4e2b2f0f91.

Note: a2/joint_draws_v103.R is now the within-source script; rerunning it writes to a2/closeout/jointmc/out, from which run_mc_v103.sh does not read. Copy to a2/mc/out before any rerun of run_mc_v103.sh.

Zenodo: citable, staged in Stage A3 (stage_v195). GitHub: pushed in Stage A3 housekeeping.
