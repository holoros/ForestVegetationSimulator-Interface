# RUN v105final: koa growth and yield engine (firebreather, ~/jobs/koa_v105final_20261103), 2026-11-03

Engine choice and rule application: FINAL_ENGINE.md. Attribution study: ~/jobs/koa_v105attr_20261103 (PREREG.md, RUN.md, RESULTS.md; copies of its key
outputs in final/attr). Read only: koa_v105attr_20261103, koa_v105d_20261102, koa_v105c_20261102, koa_v105_20261102 (compare). No FIA coordinate column read or written.

## Build

1. final/make_copy.sh: copy of koa_v105attr_20261103/R_HT (complete v105d-pipeline job tree with the attribution refits under SDImax 741.997) plus the v105d LOIO
   scripts (no engines/val/mort/fits outputs); 225 + 11 files path-rewritten; 2 absolute symlinks repointed.
2. Engine switched to the chosen run P_HT_HCB (identical out/inc fits; only koa_equations.py, koa_params.py, registry engine copies, out/v105_constants.json and
   a2/mort/v104 level files differ; backups of the R_HT versions in final/overlay_backup_R_HT). Forms: DDBH K3c1, DHT K3c1h, STAGE3 M3a, HT v105b, HCB v105b;
   DDBH_RD_SDIMAX 741.996871565; RD floors 0.001130119 (height, Stage 3), 0.03344242 (HCB, unused); MORT_CAL 2.43532 (re-solved in koa_v105attr P_HT_HCB).
3. final/final_master.sh: full-refit installation bootstraps dDBH (400, 4 cores while the attribution info run used 2) and dHT (400, 6 cores), dHT vector-fixed re-solve
   (400); height bootstrap draws = the v105c draws (Eq. 2 is the v105c form; 392 of 500 converged, g1 fixed); registry s02 = v105c files; core limits 6;
   set_calse (CAL SE refreshed); phase 1 (chains 1-2, tables, all main and supplementary figures, Fig. S3/S4, sens, years grid, LT nocal, diag_c, red-team MC,
   registry 21 of 21); phase 2 (LOIO, Table S11, Bakuzis step aware and matrix, containment, paired MC 1,000 joint draws + BOOT variants); realism; literal grep.
4. Separately: pairmc TAU (installation and tree SD of dDBH_L_NO and dHT_L_NO) set from out/inc/fit_stats_v103.csv before the paired MC ran (the v105d values were
   literals); a5/loio/fits/fit_V105EXACT.csv rebuilt from out/v105_constants.json and the LOIO gate chains, gate check, analysis and results rerun
   (a5/loio/rerun_loio_post_v105d.sh -> logs/*_final.log); coverage (a5/rerun/cov run_cov.sh + cov_summ.py, 500 joint draws); final/compare_final.py; RESULTS.md;
   final/make_build_tgz_final.py -> v105final_build_inputs.tgz + report/v105final_build_manifest.csv.

## Deviations

1. The master was started on the R_HT engine; the engine was switched to P_HT_HCB (step 2) while only the dDBH bootstrap was running, before any projection. The
   bootstrap reads only out/inc and the frames, identical for both.
2. Phase-2 LOIO first ran without fits/fit_V105EXACT.csv (the fits directory was not copied), so V105EXACT failed in phase 2; the file was rebuilt and the gate
   chains and analysis rerun before anything read the LOIO outputs.
3. Stage 3 M3a and HCB have no bootstrap in this pipeline (none consumed by the MC, coverage or paired MC), as in v105d.
4. Cores: <= 6 throughout (4 + 2 during the attribution info run).
