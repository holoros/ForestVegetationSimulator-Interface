# koa v104 A5 LOIO track (a5/loio), 31 October 2026

Full-chain leave-one-installation-out evaluation of the 17 plot-level benchmark plots (red team: all benchmark plots also informed calibration).
Everything lives in ~/jobs/koa_v104_20261030/a5/loio; nothing outside this folder was modified (originals were read or executed with outputs redirected here).
No coordinate column is read or written (fit frame asserted by nocoord; validation reads geo with usecols, as the original).

## Order of work (ADT)
1. 14:21:48 PREREG.md written (folds, refit chain, metrics, equivalence regions, verbatim decision rule). Timestamp in PREREG_written_at.txt.
2. 14:21:53 to 14:22:42 sanity-gate refit, `Rscript fit_folds.R NONE` (run_fit_gate.sh, log logs/fit_gate.log, 49 s) -> fits/fit_NONE.csv.
3. 14:24:42 to 14:25:14 sanity gate chains, run_gates.sh (logs/gates.log): V104EXACT (v104 constants of record, fits/fit_V104EXACT.csv built from out/v104_constants.json) 16 s; NONE (refit constants) 16 s.
   gate_check.py -> gate_check.csv: V104EXACT reproduces val_v104_plotlevel.csv exactly (max abs diff 0 on all 6 columns, level re-solved 2.51588); NONE within 6.139e-4 (prQMD), 4.874e-4 (prBAPH), 9.9e-6 (pr_surv), level 2.51585. GATE PASSED.
4. 14:27:28 to 14:39:43 folds, run_folds.sh (logs/folds.log, total 735 s): phase 1, 14 refits in three single-core R processes (logs/fit_g1..g3.log, 387 s; 56 to 85 s per fit);
   phase 2, run_chain_fold.sh per fold, sequential (21 to 28 s each; calib uses Pool(3)).
5. analyze_loio.py -> loio_plots.csv, loio_folds.csv, loio_metrics.csv (a few seconds); make_results.py -> RESULTS.md.

## Scripts
- fit_folds.R: sources track2/inc/inc_v103.R lines 1-112 (as a4/inc/inc_byi_x_v104.R); NO frame frames/final/dDBH_NO_v103_model.csv, model_cols "l", GUARD 45; drops every row of the held-out Data|Install;
  fit_one("dDBH", d, "NO") from START$dDBH; CF = exp(0.5 (tau_source^2 + tau_inst^2)); solve_c on the training frame; CAL = c / CF. Failures are written as status FAILED_fit / FAILED_c.
- run_chain_fold.sh <fold>: cp -rL engine_v103 -> engines/engine_<fold>; patch_fold.py (koa_equations.py DDBH %.7f, koa_params.py CF_DDBH_MARGINAL and CAL_DDBH %.5f, MORT_CAL reset (1.0, 1.0), constants printed after re-import);
  interval table a2/mort/v104/plot_intervals_origin.csv minus the held-out installation -> mort/<fold>/; calib_mort_loio.py (copy of a2/mort/calib_mort.py, only Pool(8) -> Pool(3)) and a2/mort/solve_mort.py with KOA_OUTDIR=. -> mort/<fold>/H_mort_*;
  set_mortcal_fold.py (as a4/set_mortcal_v104.py) -> MORT_CAL (k, 1.0); plotlevel_validation_loio.py (copy of a2/closeout/validation/plotlevel_validation.py, input tables and the v103 in-sample list read from the original locations, outputs to val/) -> val/val_<fold>_plotlevel.csv, val/run_<fold>.log.
- gate_check.py, analyze_loio.py, make_results.py.

## Outputs
fits/fit_<fold>.csv (16 files incl. NONE, V104EXACT); mort/<fold>/H_mort_level_natural.csv, H_mort_loio_natural.csv, calib.log; val/val_<fold>_plotlevel.csv and run logs;
gate_check.csv; loio_folds.csv (constants, level, status per fold); loio_plots.csv (17 plots, observed, in-sample and held-out predictions); loio_metrics.csv (bias, RMSE, TOST, decisions); RESULTS.md.
engines/ holds 16 engine copies (4.0 GB); safe to delete after review.

## Outcome
0 of 14 folds failed. Pooled held-out bias passes TOST in the paper's region for survival, QMD and BA: SUPPORTS for all three (RESULTS.md, loio_metrics.csv).
By origin: natural survival and BA, planted BA INCONCLUSIVE (they also fail in sample).

## Deviations and limitations
- PREREG gate asked for the refit vector to reproduce the 7 decimals of koa_equations.py; the full-frame refit (fits/fit_NONE.csv) differs by up to 1.73e-4 (b0, SE 0.69) and 2.5e-5 (b8), same logLik -9587.67; the plot-level gate the task requires (< 1e-3) passes, and the V104EXACT run shows the pipeline itself is exact. Treated as optimizer tolerance, not a failure.
- The natural level was re-solved on every fold engine (not only the four DOFAW folds that supply intervals), because the level depends on the fold's diameter increment; existing LOIO levels (a2/mort/v104/H_mort_loio_natural.csv) were not reused since they come from full-data v104 response curves.
- dHT, crown, Stage 3 ordering, planted mortality, ingrowth settings and the CAL_DDBH_SE_LOG used only in Monte Carlo stay at v104 (calibrated with the held-out data).
- The validation compares the first and last pre-removal measurement of each plot only; no per-measurement comparisons exist to mirror.
- Bootstrap clusters: 14 installations overall, 4 natural, 11 planted (DOFAW|Kulani contributes one plot to each origin).
- Optional temporal split NOT run: PSP 101 to 121 were thinned in 2018 (inputs/psp_origin_thinning_2026-09-16_DATA.csv Thin_Yr), so the "2018 state" of the PSP 103 to 108 benchmark plots straddles a removal the current window rule truncates at, PSP 202 to 204 also carry removals, and an all-source "intervals ending by 2018" frame drops every FIA and KMR PSP row (t.1 2019 to 2025). It needs new preregistered windowing and removal rules, not just compute.
