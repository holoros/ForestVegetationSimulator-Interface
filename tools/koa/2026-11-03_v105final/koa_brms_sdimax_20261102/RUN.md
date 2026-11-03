# RUN: koa_brms_sdimax_20261102

Host firebreather; job directory ~/jobs/koa_brms_sdimax_20261102; at most 6 cores for this job throughout (another job, scripts/02_cv.R, used about 2).

| step | script / launcher | started | ended | cores | log |
|---|---|---|---|---|---|
| frame | 01_frame.R | 07:32 | 07:32 | 1 | 01_frame.log |
| PRIMARY | 02_fit.R via run02.sh | 07:32 | 08:46 (74.3 min) | 4 | logs_02_PRIMARY_ad0.8.log |
| SENS_UNCENTERED | 02_fit_c.R via run02c.sh | 07:46 | 10:10 (143.2 min) | 2 | logs_02_SENS_UNCENTERED_ad0.8.log |
| SENS_WEAK | 02_fit_c.R via run02c.sh | 08:47 | 10:00 (73.2 min) | 4 | logs_02_SENS_WEAK_ad0.8.log |
| AMENDMENT 1 | appended to PREREG.md | 09:34:50 | | | PREREG.md |
| RI_UNCENTERED (aborted) | 02_fit_c.R via run02d.sh | 10:01 | killed 10:14 | 2 | logs_02_RI_UNCENTERED_ad0.95_aborted2core.log |
| RI_UNCENTERED | 02_fit_c.R via run02e.sh | 10:14 | 11:01 (47.1 min) | 4 | logs_02_RI_UNCENTERED_ad0.95.log |
| evaluation + selection | 03a_eval.R | 11:05 | 11:06 | 1 | logs_03a_eval.log |

All times AST, 2026-11-02. Seeds 54321, cmdstanr, 4 chains, 1,000 warmup + 1,000 sampling each.

Notes
- RI_UNCENTERED was first started with 2 cores (chains run 2 at a time) as soon as SENS_WEAK ended; once SENS_UNCENTERED also ended it was killed at warmup iteration ~500 and restarted with 4 cores (all chains parallel, same seed) so it would finish about 30 min sooner. Only the 4-core run is used.
- 02_fit_c.R was edited (RI_UNCENTERED branch added) while SENS_UNCENTERED and SENS_WEAK were running. R had already read the whole script, so both fits ran every statement (fit saved, summary and NUTS counts printed), but each log ends with a spurious "Error: unexpected ')'" when R read the bytes the edit appended. Harmless; the fits in fits/ are complete.
- 03a_eval.R (new) applies the criteria and the AMENDMENT 1 selection rule; it writes out/fit_eval.csv, out/fit_summary.csv and out/fits_used.csv. logs_03a_eval_test_partial.log is an earlier test run made before SENS_UNCENTERED and RI_UNCENTERED had finished.
- No fit met the criteria, so 03_post.R and 04_env.R were NOT run (they need a fit of record; 03_post.R stops by design when none exists). out/plot_sdimax.csv, out/plot_rd_brms.csv, out/growth_plot_sdimax.csv, fig_sdimax.png and the environmental gbm outputs do not exist. 03_post.R has been adapted for a common-slope (RI) fit of record and 04_env.R restricted to Hawaii Island (COUNTYCD 1) FIA plots, ready if a later amendment produces a converged fit.
- No coordinates were read, printed or written (04_env.R, the only script that reads the restricted location file, was not run).

## AMENDMENT 2 (2026-11-02 afternoon; job limited to 4 cores)

| step | script / launcher | started | ended | cores | log |
|---|---|---|---|---|---|
| AMENDMENT 2 | appended to PREREG.md | 14:52:45 | | | PREREG.md |
| lqmm install | CRAN lqmm 1.5.8 (+ SparseGrid) into user library | about 14:51 (before AMENDMENT 2; no fitting) | | 1 | |
| LQMM test (B = 4, discarded) | 05_lqmm.R 4 4 | 14:53 | 14:54 | 4 | logs_05_lqmm_test_B4.log |
| LQMM main fit + bootstrap B = 500 | 05_lqmm.R via run05.sh | 14:54:34 | 15:06:53 (main fit 3.9 s; bootstrap 733 s) | 4 | logs_05_lqmm.log, run05.log |
| LQMM post | 07_post_lqmm.R (nice 19) | 15:08 | 15:08 | 1 | logs_07_post_lqmm.log |
| RI_LONG | 02_fit_long.R via run06_rilong.sh (waits for run05 "LQMM done") | 15:07:11 | running | 4 | logs_02_RI_LONG_ad0.99_td12.log, run06.log |
| RI_LONG evaluation + rule | 06_eval_long.R (chained in run06_rilong.sh) | after RI_LONG | | 1 | logs_06_eval_long.log |
| RI_LONG post (if either tier passes) | 03_post.R out/fits_used_rilong.csv _rilong (chained) | after eval | | 1 | logs_03_post_rilong.log |
| environment gbm on fit of record | 04_env.R via run08_env.sh (waits for run06.done; reads out/record_amend2.csv) | after run06 | | 1 | logs_04_env_lqmm.log or logs_04_env_rilong.log, run08.log |

Notes
- RI_LONG reduced from 6 to 4 chains before launch (run-time estimate in AMENDMENT 2a: 2.3 to 9.2 h per chain; 6 chains on 4 cores would need two waves, 4.6 to 18 h). Expected finish about 17:30 to 00:30 AST if the estimate holds; run06.done and run08.done mark completion.
- 07_post_lqmm.R (a few seconds, single thread, nice 19) ran while RI_LONG's 4 chains were warming up, so the job briefly used 5 cores. 04_env.R was deliberately chained after RI_LONG instead of run concurrently, to stay within 4 cores.
- 03_post.R and 04_env.R now take optional arguments (fits_used file + output suffix; plot file + SDImax column + suffix); backups of the AMENDMENT 1 versions: 03_post.R.bak_amend1, 04_env.R.bak_amend1. With no arguments both behave as before.
- LQMM bootstrap: RNG L'Ecuyer-CMRG, set.seed(20261102), parallel::mclapply 4 cores (mc.set.seed); all 500 replicates converged at both taus.
- No coordinates read, printed or written so far (04_env.R, the only script that reads the restricted location file, has not yet run; it writes only CV metrics, relative influence and the model object).
