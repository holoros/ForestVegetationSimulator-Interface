# RUN.md: koa_compscreen_20261102 (C2 and RD screen of the non-increment components, engine v105b), firebreather, 2 November 2026

PREREG.md frozen 2026-11-02 22:03:14 AST (md5 2f1e744d109c5281e0b19c3399f5d1ff); a wording erratum (C2h definition, a slip in one line) appended
22:03:22 AST, before any fit (md5 after cff314f16cacf9c176761a811c5dd993; both in PREREG_written_at.txt). Only ~/jobs/koa_compscreen_20261102/ was written.
koa_v105_20261102, koa_rdcomp_20261102, koa_origin_20260916 (regenerate_table6.R cloglog fitter) and koa_v102_20260918 (Stage 1 sample code path) were only read;
koa_v105c_20261102 and koa_v104_20261030 were not needed beyond the reading done before PREREG. No engine was modified. No coordinate column exists in any
input read or any output (nocoord asserted). Cores: 1 R process at a time (7 of 8 cores held by the rebuild and a Stan job; ps checked before each launch).

| step | command | result |
|---|---|---|
| Stage 1, 2 | Rscript 01_stage12.R (run_a.sh) | out/stage12_results.csv, stage12_gate.csv, stage12_boot.csv (B 1,000, seed 20261102, plot clusters) |
| Stage 3 | Rscript 02_stage3.R | out/stage3_results.csv, stage3_boot.csv (B 1,000, installation clusters) |
| Ingrowth | Rscript 03_ingrowth.R | out/ingrowth_results.csv, ingrowth_boot.csv (B 1,000, plot clusters) |
| HCB | Rscript 04_hcb.R | out/hcb_results.csv, hcb_boot.csv (B 1,000, plot clusters) |
| Height | Rscript 05_height.R (run_b.sh) | out/height_results.csv, height_heldout_folds.csv, height_fits_summary.rds |
| verdicts | Rscript 06_verdicts.R | out/verdicts.csv, verdicts.md |
Logs: logs/<script>.log, logs/run_a.log, logs/run_b.log.

## Gates
- Stage 1/2: the specified frame (a2/mort/v104/plot_intervals_origin.csv minus removal, 285 intervals) does NOT reproduce the deployed STAGE1 vector
  (max abs diff 0.030 Stage 1, 0.083 Stage 2). By the PREREG fallback the stage1_garcia_v103.R sample (282 intervals, removal + refit2 screen on
  frames/final/plot_intervals_v103.csv) was tried and reproduces it (2e-15, 8.9e-16); it is the screen sample (out/stage12_gate.csv).
- Stage 3 refit = STAGE3_COEF (4.2e-15). Ingrowth refit = v103 vector (3.3e-15). HCB_P on the pre-substitution frame reproduces the v103 RMSE (l) 2.38190
  (2.7e-15). Height partial refit = engine HT_P a0, a1 (6.7e-08).

## Deviations
1. Stage 1/2 sample: 282 intervals of the stage1_garcia_v103 path, not the 285 of plot_intervals_origin.csv (PREREG fallback; above).
2. 05_height.R first run stopped at the first held-out prediction (predict.nlme could not re-evaluate the fixed formula built inside fit1); the level-0
   prediction was replaced by direct evaluation of the same model formula with the fold's fixed effects, and the script rerun from the start (logs/05_height.log
   is the final run). The second run completed all 143 LOIO folds but stopped while tabulating (an empty failed-fold counter;
   logs/05_height_run2_failed_at_table.log); the counter was initialised, the held-out predictions are now also saved (out/height_heldout_predictions.rds),
   and the script was rerun a third time from the start. Point fits identical in all runs (same data, same starts).
3. Stage 2 has a continuous response (ln m_ann): LOIO RMSE replaces AUC/Brier (stated in PREREG).
