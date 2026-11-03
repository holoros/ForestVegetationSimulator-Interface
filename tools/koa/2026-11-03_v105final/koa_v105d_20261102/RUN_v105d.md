# RUN v105d: koa growth and yield engine v105d (firebreather, ~/jobs/koa_v105d_20261102)

Built 2026-11-02/03. v105d = v105c (K3c1 dDBH, unchanged) + RD x competition forms in every other component with a competition term. RD = SDI/923 (SDI = TPH (QMD/25.4)^1.605 from the live list each annual step; population lqmm SDImax 923); share = tree BAL / plot BAPH (0 where BAPH = 0), as K3c1. Template: the v105c pipeline (koa_v105c_20261102/v105c), copied whole into this job after the v105c MASTER DONE (2026-11-02 23:08 AST); koa_v105c_20261102, koa_v105_20261102, koa_rdcomp_20261102, koa_compscreen_20261102 and koa_v104_20261030 were only read. No FIA coordinate column was read or written by any v105d script.

## What changed (v105c form -> v105d form)

| component | v105c (sensitivity) | v105d (deployed) | coefficients from |
|---|---|---|---|
| dHT increment (Eq. 4) | b3 BAL^2/ln(HT+5) + b4 ln(BAL+1) + b6 sqrt(BAPH HT) | K3c1h: b4 ln(x+1) + b6 sqrt(RD HT), x = share x RD, b3 fixed 0 | refit in this job (inc_v103.R, dHT_L_NO), = independent reference fit (prep/fit_dht_k3c1.R) |
| total height Eq. 2 | g1 ln(BAPH+1); a0, a1 refitted | H1a: g1 ln(RD); a0, a1, g1 refitted; b, c, g2 at v104 | koa_compscreen_20261102 H1a (refit reproduced, prep/refit_compscreen.R) |
| HCB Eq. 3 | HCB_P: b3 sqrt(BAL BAPH + 1) + b4 ln(BAPH+1), v102 vector | C2h: b3 sqrt(share RD + 1) + b4 ln(RD), C2 BYI, all six refitted | koa_compscreen_20261102 C2h (refit reproduced) |
| mortality Stage 3 | c3 ln(BAPH+1) + c4 ln(BAL+1) | M3a: c3 ln(RD) + c4 ln(share RD + 1) | koa_compscreen_20261102 M3a (refit reproduced, intercept added) |
| Stages 1, 2, ingrowth | ln(SDI), SDI | unchanged (one SDImax: RD is a rescaled SDI) | - |
| natural mortality level MORT_CAL | 2.55705 | 2.39002 (re-solved on the v105d engine, a4/run_mort_v104.sh + v105d/set_mortcal_v105d.py) | a2/mort/v104/H_mort_level_natural.csv |

Engine code: koa_params.HT_FORM, HCB_FORM, DHT_FORM, STAGE3_FORM switch each component; "v105b" restores the v105c form exactly (engine parity gate below), so the v105c forms remain available as the sensitivity in this engine, and the v105c job itself is the read-only v105c reference. ln RD is floored at the minimum RD of each fitting frame (RD_FLOOR_HT = RD_FLOOR_STAGE3 = 0.000908499, RD_FLOOR_HCB = 0.0268843; prep/out/rd_min_fitframes.csv).

## Declared deviation

These forms are deployed by Aaron's explicit modeling choice ("I prefer RD times competition... let's do it all"), NOT by the preregistered adoption rules, which they fail:
- dHT: koa_rdcomp_20261102 PREREG rule kept K0 (every RD candidate worse in AIC and better on 1 of 4 held-out sources; K3p dAIC +40.57). The deployed K3c1h has logLik -6952.801, AIC 13933.60 vs K0 13894.83 (dAIC +38.77; out/inc/fit_stats_v103.csv of this job and of koa_v105c_20261102).
- Eq. 2 H1a: koa_compscreen_20261102 rule failed it (LOIO RMSE 2.3998 vs 2.3969; dAIC +132.97).
- Eq. 3 C2h: failed monotonicity (HCB falls as RD rises at fixed share; the deployed HCB_P fails the same check) and its BYI coefficient bootstrap interval includes zero (-1.294 to 0.042).
- Stage 3 M3a: failed (LOIO within-interval AUC 0.7761 vs 0.7764, Brier 0.1197 vs 0.1140; dAIC +46.25).
Source: koa_compscreen_20261102/RESULTS.md, out/verdicts.csv; koa_rdcomp_20261102/RESULTS.md. The v105c forms are kept as the sensitivity (above).

## dHT form: K3p failed the monotonicity check, so the constrained analogue K3c1h is deployed

K3p (koa_rdcomp_20261102 vector; b3 = 0.1165 on x^2/ln(HT+5), b4 = -1.1902): d ln g/dx = 2 b3 x/ln(HT+5) + b4/(x+1) evaluated for x from 0 to the observed maximum 3.7029 of the dHT frame at HT = 0.45, 1.40, 4.90, 7.90, 11.60, 22.17 m: positive on 440 of 2406 grid points (from x = 2.490 at HT 0.45 m), so dHT would rise with competition at large x. On x in [0, 2] (the constrained/ grid for dDBH) and [0, p99 = 0.873] it is negative everywhere, and no frame row lies beyond the turning point (prep/mono_dht.R, prep/out/mono_dht_K3p.csv). Under the brief's 'observed range' reading K3p fails, so the constrained analogue (the x^2 term dropped, b3 = 0, exactly as koa_rdcomp_20261102/constrained did for dDBH) is deployed: K3c1h, d ln g/dx = b4/(x+1) < 0 for every x (b4 = -1.1383).
Not checked by the constrained/ precedent and reported here: at fixed share, dHT rises with RD for dominant trees (b6 > 0 on sqrt(RD HT)); the v105b/v105c dHT has the same property on sqrt(BAPH HT) (realism section of RESULTS_v105d.md).

## Gates

### 1. Refit parity: new fits reproduce the compscreen / rdcomp coefficients

| check | value | pass |
|---|---|---|
| Height H1a refit vs compscreen a0 a1 g1, max abs diff | 7.105427357601e-15 | True |
| Height H1a logLik minus compscreen | -1.45519152283669e-11 | True |
| HCB C2h refit vs compscreen b0..b5, max abs diff | 2.88657986402541e-15 | True |
| Stage 3 deployed refit vs STAGE3_COEF, max abs diff | 4.21884749357559e-15 | True |
| Stage 3 M3a refit vs compscreen slopes, max abs diff | 8.881784197001249e-16 | True |
| Stage 3 M3a logLik minus compscreen | 3.86535248253495e-12 | True |

dHT code path (v105d/gate_dht_code.R): frame columns and deterministic predictions vs koa_rdcomp_20261102; K3p refit through the patched path is INFO only (start-dependent optimizer stop: from the stored K3p vector it stops at logLik 0.006 below the koa_rdcomp best-of-two-starts value, 1.5e-3 SE).

| check | value | pass |
|---|---|---|
| dHT XK.0 vs koa_rdcomp K3p frame, max abs diff | 7.105427357601e-15 | True |
| dHT XK.1 vs koa_rdcomp K3p frame, max abs diff | 8.88178419700125e-15 | True |
| dHT RD.0 vs koa_rdcomp K3p frame, max abs diff | 1.19904086659517e-14 | True |
| dHT RD.1 vs koa_rdcomp K3p frame, max abs diff | 8.88178419700125e-15 | True |
| dHT DHT_FORM v105b: pa_pred patched vs v105c code, max abs diff | 0.0 | True |
| dHT K3p prediction: patched pa_pred vs koa_rdcomp lib, max abs diff | 7.105427357600999e-14 | True |
| dHT K3c1h prediction: patched pa_pred vs koa_rdcomp lib (b3 = 0), max abs diff | 7.105427357600999e-14 | True |
| INFO dHT K3p refit via patched fit_one (start = stored K3p) vs koa_rdcomp K3p, max diff in SE units | 0.0014912348575892 | True |
| INFO dHT K3p refit logLik minus koa_rdcomp -6952.703 (log, 3 dp) | -0.0062696050617887 | True |

Fit gate after the full inc_v103.R refit (v105d/gate_v105d_fit.R):

| check | value | pass |
|---|---|---|
| dDBH_L_NO estimates vs v105c (max abs diff) | 0.0 | True |
| dDBH_L_NO CF, c, CAL vs v105c (max abs diff) | 0.0 | True |
| dHT_L_NO fixef vs reference K3c1h (max abs diff) | 6.04701246453843e-06 | True |
| dHT_L_NO fixef vs reference, max diff in SE units | 1.84351803448086e-05 | True |
| dHT_L_NO logLik minus reference | 2.51275632763281e-05 | True |
| dHT_L_NO b3 row (estimate) | 0.0 | True |
| dHT signs b1 > 0, b4 < 0 | 1.0 | True |
| dHT monotone in x = share RD (b4 <= 0, analytic) | -1.13833380563416 | True |
| model frames md5 identical to v105c (4 frames) | 4.0 | True |

### 2. Engine parity

Patched engine with every v105d switch at "v105b" vs the v105c outputs (run_engine six scenarios x 300 yr incl. Stage 3 tree_eq ordering, HCB, dHT, Eq. 2; 23-plot validation; years grid):

| file | rows | max_abs_diff | pass_ |
|---|---|---|---|
| a2/out/traj_parity_v105c.csv | 1800 | 0.0 | True |
| a2/out/val_parity_v105c.csv | 23 | 0.0 | True |
| v105d/out/years_grid_parity_v105c.csv | 48 | 0.0 | True |

Python engine vs R for every component (v105d/py_r_parity_d.R, .py), deployed v105d engine:

| check | rows | max_rel_diff | tol | pass_ |
|---|---|---|---|---|
| INFO dDBH engine with its printed (7 dp) vector vs recursion with the full-precision vector | 3101 | 9.356114148983964e-07 | 1e-05 | True |
| dDBH (K3c1) engine code with the full-precision vector vs inc_v103.R recursion, one annual step | 3101 | 2.220446049250313e-14 | 1e-09 | True |
| INFO dHT engine with its printed (7 dp) vector vs recursion with the full-precision vector | 2068 | 1.31341590359213e-06 | 1e-05 | True |
| dHT (K3c1h) engine code with the full-precision vector vs inc_v103.R recursion, one annual step | 2068 | 1.2656542480726783e-14 | 1e-09 | True |
| INFO Eq. 2 engine with its printed (6 dp) HT_P vs R with the full-precision vector | 8723 | 7.0449421550877744e-06 | 0.0001 | True |
| Eq. 2 H1a predict_HT(rd = R RD), full-precision vector, vs R formula | 8723 | 1.1093348462054564e-12 | 1e-09 | True |
| RD rebuilt by the engine from plot-year TPH, QMD vs R RD (SDI_qmd/923) | 8914 | 6.306066779870889e-14 | 1e-09 | True |
| Eq. 3 C2h predict_HCB(rd = R RD) vs R formula | 360 | 3.9046987865276606e-11 | 1e-09 | True |
| Stage 3 M3a stage3_w vs R glm formula (ln YIP = 0) | 4222 | 9.103828801926284e-15 | 1e-09 | True |

### 3. Hard-coded coefficient literals

v105d/check_literals_v105d.py greps every .py/.R/.sh of engine_v103, registry engines, a2, a4, a5, track2, scripts for literals of the replaced v105c vectors (HT_P, HCB_P, dHT_L_NO, STAGE3_COEF) and for the v105b-form Stage 3 expression, and exits 1 on any unlisted hit. Result: LITERALS PASS hits 0 allowed files 12 . The first run failed (46 hits: the stale v104-era pairmc/engine_a5 copy, which run_pairmc_v105.sh deletes and recopies from engine_v103 before use; the v102 before-engine a2/closeout/validation/engine_v102; the V104 shape vector in a5/rerun/h/h_boot_v105d.R). Allowed files and reasons are printed in v105d/logs/check_literals.log. The literal Stage 3 expressions in koa_projector.py (2), run_candidates.py and regen_figS4S5.py (the earlier hard-coding bug) were replaced by one function, koa_equations.stage3_w, and STAGE3_COEF carries renamed keys (c3_lnRD, c4_lnshareRD) so a surviving v105b-form expression raises KeyError. predict_HCB raises without rd= and dHT without sdi=.

Figures with literal forms: a4/figs/fig_main_v104.R (Fig. 3 increment and height curves, panel f) and figS12_v104.R (Fig. S1 height and HCB panels) patched by v105d/patch_figs_v105d.py. Finding: the v105c Fig. 3 dDBH curves (panels a, d) evaluated the v105b BAL/BAPH form with the K3c1 vector (a v105c defect, fixed here). The curves use a fixed stand of BAPH 30 m2/ha at QMD 25 cm (RD 0.646, stated in the script).

### 4. Bootstraps

- dHT K3c1h full-refit installation bootstrap (track2/inc/boot_v103.R dHT 400 4): 00:35:07 BOOT DONE dHT converged 400 of 400
- dHT vector-fixed re-solve (stageB/boot_resolve_dht_v105.R, 400): dHT re-solve-only SE log c: 0.1285549 0.07448916 n ok 400
- dDBH K3c1 bootstrap: reused from v105c (dDBH fit identical to 0, gate above).
- Eq. 2 H1a installation bootstrap (a5/rerun/h/h_boot_v105d.R 500 4): HEIGHT BOOT v105d DONE 2026-11-02 23:22:07  ; summary a5/rerun/h/h_boot_summary_final.csv (500 of 500 converged).

### 5. Phase 1 and phase 2 (as v105c)

- Stage B: STAGE_B DONE Mon 02 Nov 2026 11:29:19 PM AST (literal check rerun after adding two regenerated/archival directories to SKIP and h_boot_v105d.R to ALLOW; see logs/check_literals.log)
- Phase 1: sens 0 | years_grid 0 | lt nocal 0 | diag_c 0 | redteam mc 0 | registry 0 | GATE 19 of 21 | PHASE1 DONE Tue 03 Nov 2026 12:58:43 AM AST
- Phase 1 registry gate: first pass GATE 19 of 21 (HT_P a0, a1 disagreed: registry s02 still held the v105c height fit). Registry s02 was then regenerated for H1a (v105d/registry_s02_v105d.R) and make_md.sh rerun: GATE 21 of 21 (v105d/logs/registry_gate_rerun.log).
- Fig. 3 (fig_main_v104.R) failed in phase 1 (chol of a height vcov with zero rows for the fixed b, c, g2); the v105d height vcov for the figure bands now carries the v104 block for b, c, g2 (as the v105 track3 script did), and fig3-fig6 were rerun: fig_main rerun 0 Tue 03 Nov 2026 01:00:33 AM AST
- Phase 2: loio 0 Tue 03 Nov 2026 01:08:48 AM AST | LOIO_V105_DONE Tue 03 Nov 2026 01:08:48 AM AST | s11 0 | bakuzis 0 | bakuzis_matrix 0 | contain 0 | pairmc 0 | PAIRMC_V105_DONE Tue 03 Nov 2026 01:27:18 AM AST | pairmc boot 0 | PHASE2 DONE Tue 03 Nov 2026 01:31:59 AM AST
- LOIO: in phase 2 the two gate chains (V105EXACT, NONE) failed with the v105c patch_fold.py (its DDBH regex matched LineageA and LineageB, n = 2; the same failure made every v105c LOIO chain fail, so the v105c LOIO verdicts are stale v105b values). patch_fold.py was fixed (count=1) while run_folds.sh was still fitting, so all 14 fold chains ran with the fix (a5/loio/logs/folds_v105.log, 0 FAILED); gates, gate check, analysis and results were rerun (a5/loio/rerun_loio_post_v105d.sh).
  LOIO sanity gate (a5/loio/gate_check.csv; max abs diff vs a2/closeout/validation/val_v104_plotlevel.csv, 18 units): V105EXACT (constants of record) max 0 (PASS); NONE (full-frame dDBH refit through fit_folds.R) max 0.001197 (prQMD; tolerance 1e-3, so FLAGGED: the refit stops slightly off the deployed K3c1 vector; v105b NONE max 3.3e-4).
- Paired MC gate (a5/pairmc/logs/a5_gatecheck.log):   "PASS": true |   "PASS": true
- Master: boot dHT 0 Tue 03 Nov 2026 12:35:07 AM AST | resolve dHT 0 | phase1 0 | phase2 0 | realism 0 | bakuzis compare 0 | compare 0 | MASTER DONE Tue 03 Nov 2026 01:36:26 AM AST

## Notes and further deviations

1. Increment frames keep the HCB_P crown ratio (track2/inc/inc_v103.R builds CR of the dDBH/dHT fitting frames with HCB_P; frames md5-identical to v105c). The engine projects CR from C2h. This is a declared inconsistency between the fitted and the projected crown ratio input of both increment equations (dDBH b5, dHT b5); refitting both increments on C2h crown ratios would change the v105c dDBH vector, which the brief fixes.
2. HiGy.R (FVS-HI mirror) is not updated for the v105d forms (header note added); the Python engine is of record.
3. Registry s01 (accounting) not rerun (inputs unchanged). Registry s02 (height) regenerated for H1a (v105d/registry_s02_v105d.R; LOIO nls per fold, RMSE in a2/registry/s02/v105/02_height_loio.csv); 02_height_vector_contrast.csv there is the old-form file (not regenerated) and the base-form file stays CARRIED from v104. Fuller Eq. 2 statistics: track3_s02/v105d.
4. Height bootstrap: v105c had 392 of 500 converged draws with g1 fixed; v105d draws g1 as well (a0, a1, g1 free), 500 of 500 converged; the paired-MC BOOT variants use these draws.
5. Coverage (Table S26) was not part of the v105c pipeline; it was run here for v105c (its engine and joint draws) and for v105d with the same scripts; no v105b value exists.
7. a4/figs/s34/out_span/*.csv were symlinks into koa_v105c_20261102/a2/mort/v104 (absolute links survive the copy and the path rewrite), so the phase-1 Fig. S3/S4 run read the v105c natural level (2.55705; v105d/logs/figS34_v105d.out). The links were repointed to this job and figS34_v104.R rerun: figS34 rerun 0 Tue 03 Nov 2026 01:40:27 AM AST ; level read:   level file check: obs_deaths 15326.4, pred_uncal 7150.7, level 2.39002  . No other symlink into koa_v105c_20261102 exists in this job.
6. Cores: 4 to 6 of 8 for the bootstraps and phases (another user job held 4 until about 01:00); for about one minute (01:09-01:10) the LOIO gate rerun (3) overlapped the paired-MC joint draws (6).
