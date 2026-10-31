# koa v104 A5: full-chain leave-one-installation-out (LOIO) evaluation. PREREGISTRATION

Written 31 October 2026, before any held-out quantity was computed. Job ~/jobs/koa_v104_20261030, work folder a5/loio.
Trigger: referee red team finding that all 17 plot-level benchmark plots (a2/closeout/validation/val_v104_plotlevel.csv, role != disturbance)
also informed calibration of the projection system.

## Benchmark plots and folds
The 17 benchmark plots are the rows of val_v104_plotlevel.csv excluding the disturbance case FIA|15-1-1-2628 (excluded from every aggregate in
the paper's Table C1/C2, and it has 0 rows in the dDBH NO frame). A fold is each installation (key Data|Install) that contains at least one of them.
14 folds:

| fold (installation) | benchmark plots | origin | rows in dDBH NO frame (before complete cases) | natural mortality intervals (a2/mort/v104) |
|---|---|---|---|---|
| DOFAW\|Kulani | Kulani 12 (planted), Kulani 23 (natural) | both | 427 | 5 |
| DOFAW\|Laupahoehoe | 41 | natural | 291 | 5 |
| DOFAW\|Waiakea | 11, 14, 24 | natural | 182 | 8 |
| DOFAW\|Waikamoi | 25 | natural | 151 | 3 |
| PSP\|103 ... PSP\|108 (six folds) | 3, 4, 5, 6, 7, 8 | planted | 161, 204, 144, 148, 99, 152 | 0 |
| PSP\|123 | 23 | planted | 18 | 0 |
| PSP\|202, PSP\|203, PSP\|204 | 2, 3, 4 | planted | 155, 156, 143 | 0 |

## What is refit per fold (the full chain)
1. Drop every record of the held-out installation from the dDBH NO calibration frame (frames/final/dDBH_NO_v103_model.csv, live-list BAL columns, model_cols "l").
2. Refit dDBH_L_NO with track2/inc/inc_v103.R fit_one (same form gr.hat3 with planted guard 45 cm, random b0 | Data/Install/TreeID, varPower, START$dDBH as in the fit of record).
3. CF = exp(0.5 (tau_source^2 + tau_inst^2)); origin constants c by solve_c on the fold training frame; CAL = c / CF.
4. Patch a copy of the engine (a5/loio/engines/engine_<fold>, cp -rL of engine_v103) with the fold vector b0..b9 (koa_equations.py DDBH), CF_DDBH_MARGINAL and CAL_DDBH
   (koa_params.py), formatted exactly as a4/patch_engine_v104.py does (%.7f, %.5f).
5. Natural mortality level: re-solved on EVERY fold engine (MORT_CAL reset to 1 during calibration, as in A4), with a copy of a2/mort/calib_mort.py and solve_mort.py
   on the v104 interval table a2/mort/v104/plot_intervals_origin.csv (removal rule of record, PSP 122 2019 to 2023 excluded) minus every interval of the held-out
   installation (only the four DOFAW folds remove intervals). Form "mult". Existing LOIO levels in a2/mort/v104/H_mort_loio_natural.csv are NOT reused: they were
   solved on response curves from the full-data v104 engine, so they do not carry the fold's refit diameter increment (the v104 rule is reproduced, the chain is not).
   Then MORT_CAL = (k_fold, 1.0) is written as a4/set_mortcal_v104.py does.
6. Run the plot-level validation (copy of a2/closeout/validation/plotlevel_validation.py, identical projection code and input tables, outputs redirected to a5/loio)
   on the fold engine and keep only the held-out installation's benchmark plots.
Height increment (dHT), crown, Stage 3 ordering vector, planted mortality and all other components stay at v104 values (limitation: they were calibrated with the
held-out data). A fold whose refit errors, whose constants are not solvable, or whose level is non-finite is recorded as FAILED and reported; never dropped silently.

## Sanity gate (before any fold)
The same pipeline with no installation held out must reproduce the v104 vector (b0..b9 to the 7 decimals of koa_equations.py), CF 1.50128, CAL 0.25558 / 0.97085,
MORT_CAL 2.51588, and the v104 in-sample plot-level values in val_v104_plotlevel.csv (pr_surv, prQMD, prBAPH) to rounding (max abs difference < 1e-3 on each).
If it does not, stop and report why.

## Metrics
Error = projected minus observed at the final measurement of each plot (the validation script produces one comparison per plot, t0 to the last pre-removal
measurement; there are no per-measurement comparisons). Variables: cohort survival (expf weighted observed survival, obs_surv_w, vs pr_surv), QMD (cm) and basal area
(m2 ha-1) of the surviving initial cohort. Groups: all 17 plots, natural (6), planted (11), as in Table C1/C2.
Per variable and group: n, mean bias, RMSE, mean observed; TOST on bias: 90 percent bootstrap interval of mean predicted minus mean observed; TOST on slope:
90 percent bootstrap interval of the slope of observed on predicted (centered predictor, as make_tables_v104.py equiv()).
Bootstrap: resampling installations (clusters) with replacement, 2,000 resamples, numpy default_rng seed 20261031. The same installation bootstrap is also applied to the
in-sample v104 values so the two columns are comparable; the published in-sample plot bootstrap (Table C2, 5,000 draws, seed 20260917) is shown beside them.
Note: the natural group has only 4 installations and the overall pool 14, so cluster intervals are wide; this is stated, not corrected.

## Equivalence regions (the paper's own; make_tables_v104.py, tableC_v104_plotlevel.md Table C2)
Bias: the 90 percent interval must lie inside +/- 25 percent of the mean observed value of the group (same plots, so the same region in and out of sample:
all-plot regions survival 0.1553, QMD 6.090 cm, BA 6.771 m2 ha-1). Slope of observed on predicted: 90 percent interval inside 0.75 to 1.25.

## Decision rule (verbatim)
the held-out evaluation SUPPORTS the in-sample claim for a variable if pooled held-out bias passes TOST within the same equivalence region used in sample; it CONTRADICTS it if the held-out bias interval lies wholly outside that region; otherwise INCONCLUSIVE.

Applied per variable on the pooled 17 plots with the installation bootstrap interval (primary); the by-origin results are reported under the same rule as secondary.
Slope TOST is reported but does not enter the decision rule.

## Also reported
Fold-to-fold range of refit b8 (ln BYI coefficient), c natural, c planted and the natural level factor.
Optional temporal split for PSP plantation plots (fit on intervals ending by 2018, project 2018 state to 2019-2025) only if under one hour of compute.
