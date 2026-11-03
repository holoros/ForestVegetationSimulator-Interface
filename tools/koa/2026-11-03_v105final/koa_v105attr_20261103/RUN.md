# RUN: koa v105d component attribution under the brms SDImax of record (koa_v105attr_20261103, firebreather, 2026-11-03)

PREREG.md written 06:28:45 AST before any run (md5 at write time cbb78c30c3173cc26693820d27f1c7cb). Read only: koa_v105d_20261102, koa_v105c_20261102,
koa_v105_20261102, koa_compscreen_20261102, koa_rdcomp_20261102, koa_brms_sdimax_20261102 (and koa_v104_20261030 trajectories read by the Bakuzis script).
No FIA coordinate column was read or written.

## Steps

1. SDImax (scripts/00_sdimax.R): 12,000 posterior draws of RI_LONG; SDImax_j = exp(b0_j + b1_j log 25.4); median 741.996871565, 95% 679.96 to 807.39,
   mean 742.42 (prep/out/sdimax_pop.csv). The record's fit_summary_rilong.csv SDImax_pop (mean 742.419, 679.96 to 807.39) is reproduced.
2. Refits of H1a, C2h, M3a (scripts/refit_compscreen_pop.R = copy of v105d prep/refit_compscreen.R with the divisor and output dir from the environment):
   at 923 the gate reproduces v105d/compscreen (max abs diff 7.1e-15, logLik 1.5e-11; REFIT_PARITY_COMPSCREEN PASS, logs/refit_923.log, prep/out923);
   at 741.997 (prep/out742): H1a a0 36.54291 a1 1.73411 g1 0.045727; C2h b0 -0.92956 ... b3 0.11920 b4 -0.14928; M3a c0 -0.90106 c3 0.10109 c4 1.85417.
   The "FAIL" line in logs/refit_742.log is the compscreen comparison, expected to fail at a different divisor (ln forms: intercept shift only; the
   share x RD terms change). RD floors under the new divisor: height and Stage 3 0.001130119, HCB 0.03344242 (minimum RD of each fitting frame).
3. Per-run copies of koa_v105d_20261102 (scripts/make_copies.sh, tar; a5/loio and *.tgz excluded; absolute paths rewritten, 225 files per run; two absolute
   symlinks repointed). track2/inc/inc_v103.R SDIMAX_POP 923 -> 741.996871565 in each copy.
4. Increment refits (scripts/run_inc.sh): D742 (K3c1 dDBH + K3c1h dHT) and R_dHT (K3c1 dDBH + v105c-form dHT). dDBH identical between them (0.0); the v105c
   form dHT refit reproduces the v105c dHT_L_NO exactly (gate 0.0). Frames unchanged (md5). out/inc copied D742 -> R_HT, R_HCB, R_S3; R_dHT -> C742.
   D742 dDBH: b4 -2.6284 (v105d -3.0978), logLik -9560.26 (v105d -9564.02); dHT K3c1h: b4 -0.97245 (-1.13833), logLik -6952.30 (-6952.80).
5. Per run (scripts/run_pipeline*.sh): deploy_run.py (engine vectors, CF/CAL, forms, floors, constants json, height consumers), MORT_CAL re-solve
   (a4/run_mort_v104.sh + set_mortcal), registry engine sync, literal grep (scripts/check_literals_attr.py: LITERALS PASS, 0 code hits, every run),
   chain 1 (point paths, 500 joint draws with their gates, 500-replicate MC), chain 2 (validation, LT, culmination), step-aware Bakuzis, coverage
   (500 joint draws of the run itself, cov_mc.py + cov_summ.py), realism (dDBH and dHT derivatives). Joint-draw gates passed in every run (vectors vs
   constants json <= 4e-15; engine CAL gate <= 6.1e-6; Stage 1 reproduction).
6. Collection: scripts/eichhorn_exact.R (unrounded Eichhorn CVs, same computation as the Bakuzis script), scripts/collect.py (out/metrics_long.csv,
   out/metrics_wide.csv; files older than the run's deploy are refused as stale - none were), scripts/attribute.py (out/attribution.csv),
   scripts/make_results.py (RESULTS_tables.md).

## Deviations

1. Attempt 1 (logs/attempt1): deploy_run.py's grab() used re.S, so the HT_P pattern spanned the file and HT_P was not replaced; the literal grep stopped
   every run before any projection. Engines were restored from v105d and redeployed after the fix.
2. C742 attempt 2: joint draws stopped at the CAL gate because KOA_DHT_FORM was not exported (solve_c sourced inc_v103.R in the K3c1h form); killed,
   fixed (run_pipeline2.sh exports the run's form), rerun. No output of the failed attempt was used.
3. run_cov.sh runs only the coverage replicates; cov_summ.py (Table S26 summary) was run by hand for D742, C742, R_dHT, R_HT and in-pipeline for R_HCB, R_S3.
4. Cores: two runs at a time, 2 workers each (<= 4); during two short windows (about 6 min) the cov_summ hand runs overlapped the next pair (up to 6).
5. Not rerun (no metric consumes them): full-refit increment bootstraps, height bootstrap, dHT re-solve (CAL_*_SE_LOG in these engines are stale v105d values),
   LOIO, paired MC, figures, registry. These are run on the final engine in koa_v105final_20261103.
6. Plot-level and trajectory validation and coverage of R_HT are identical to D742 to 3 decimals: the validation projections start from measured heights,
   so Eq. 2 only enters through missing-height imputation (none changes the outcome); the Eq. 2 effect shows in the long point paths (culmination,
   Eichhorn, Bakuzis, 40-yr volume).
7. The firebreather bridge dropped 08:35-09:50 AST; the detached runs completed (R_HCB 08:38:56, R_S3 08:39:50).
8. Pairwise revert P_HT_HCB was run for information only (the preregistered rule needs no pairwise run: every failure present in D742 is removed by a
   single revert).
