# PREREG: koa v105d component attribution under the brms SDImax of record (koa_v105attr_20261103)

Written before any run of this job (timestamp at the end, firebreather clock). Job folder ~/jobs/koa_v105attr_20261103 (new). Read only:
koa_v105d_20261102, koa_v105c_20261102, koa_v105_20261102, koa_compscreen_20261102, koa_rdcomp_20261102, koa_brms_sdimax_20261102 (and the
koa_v104_20261030 trajectories that the Bakuzis script compares against). No FIA coordinate column is read or written.

## Question

v105d (v105c + RD x competition forms in dHT K3c1h, total height H1a, HCB C2h, mortality Stage 3 M3a; MORT_CAL recalibrated) fails realism
checks that v105c passed: natural low-site MAI culmination at the 10-yr floor (v105c 21 yr), Eichhorn flags in even-aged natural (median CV 11.4%)
and uneven-aged natural (12.6%) against the 10% limit, Bakuzis 94/35 vs 96/33, pooled BA coverage 0.647 vs 0.706. Which component causes which
failure, after RD is rescaled to the new SDImax of record?

## SDImax divisor

Population SDImax at QMD 25.4 cm from the converged brms RI_LONG fit (koa_brms_sdimax_20261102/fits/RI_LONG_ad0.99_it6000_td12.rds; record
out/record_amend2.csv): per posterior draw j, SDImax_j = exp(b_Intercept_j + b_lqmd_j log 25.4); reported as the median and the 2.5/97.5% quantiles
of SDImax_j. The point value used everywhere is that median (full precision, written to prep/out/sdimax_pop.csv). Expected near 742.
RD = SDI / SDImax_pop, SDI = TPH (QMD/25.4)^1.605 (unchanged definition) in every run.

## Runs

Template: the v105d pipeline (koa_v105d_20261102), copied per run into <job>/<RUN>/ with paths rewritten; originals never modified.

| run | dDBH | dHT | total height Eq. 2 | HCB Eq. 3 | mortality Stage 3 |
|---|---|---|---|---|---|
| D742 | K3c1 @742 | K3c1h @742 | H1a @742 | C2h @742 | M3a @742 |
| R-dHT | K3c1 @742 | v105c form (refit, no RD) | H1a @742 | C2h @742 | M3a @742 |
| R-HT | K3c1 @742 | K3c1h @742 | v105c HT_P (ln(BAPH+1)) | C2h @742 | M3a @742 |
| R-HCB | K3c1 @742 | K3c1h @742 | H1a @742 | v105c HCB_P | M3a @742 |
| R-S3 | K3c1 @742 | K3c1h @742 | H1a @742 | C2h @742 | v105c Stage 3 (ln(BAPH+1), ln(BAL+1)) |
| C742 | K3c1 @742 | v105c form | v105c HT_P | v105c HCB_P | v105c Stage 3 |

"@742" = refitted with RD = SDI/SDImax_pop: dDBH K3c1 and dHT K3c1h by track2/inc/inc_v103.R (SDIMAX_POP replaced), H1a, C2h and M3a by a copy
of v105d/prep/refit_compscreen.R with POP replaced. Every RD-using coefficient is refitted (log-RD forms included, where only intercepts should move).
The ln RD floors (RD_FLOOR_HT, RD_FLOOR_HCB, RD_FLOOR_STAGE3) are recomputed as the minimum RD of each fitting frame under the new divisor.
The v105c-form components carry no RD, so their coefficients are the v105c values (dHT old form refitted by inc_v103.R with KOA_DHT_FORM=v105b; gate:
reproduces the v105c dHT_L_NO fixed effects to 1e-6). C742 = the v105d engine with every v105d switch at "v105b" (shown by the v105d engine parity
gate to reproduce v105c exactly) and dDBH K3c1 @742, i.e. v105c with RD rescaled.
In every run: origin multipliers (CAL, CF) from that run's increment refit, MORT_CAL re-solved on that run's engine (a4/run_mort_v104.sh as v105d did),
consumers (joint draws height vcov, HT_P, HCB_P, STAGE3_COEF) set to that run's components.

Gates per run: refit parity of the scripts at 923 against v105d prep/out (H1a, C2h, M3a; must reproduce to 1e-6 before the 742 refits are used);
engine constants equal the fit outputs; the joint-draw gates of a4/joint_draws_v104.R (vectors and CAL against out/v105_constants.json); a literal grep
over each run's engine and consumers that no replaced coefficient vector (v105d K3c1 dDBH, K3c1h dHT, H1a, C2h, M3a vectors and the 923 divisor)
survives in any consumer (the Stage 3 literal-vector bug).

## Metrics per run

1. Even-aged natural and planted volume and QMD at 40 yr, BYI 142/303/418 (500-replicate MC median and 95%; engine_v103/out_m1/table8_evenaged_M1.csv).
2. MAI culmination ages (a4/culmination_mc_v104.json; point path windowed 10-100 yr "pt_window" and MC median); the low-site metric is
   Even-aged natural | Low (142) pt_window.
3. Eichhorn median (and max) CV of VOL at equal HT by stratum (Even-aged natural, Even-aged planted, Uneven-aged natural), step-aware Bakuzis script.
4. Bakuzis PASS / FLAG / info / NOT EVALUATED counts, evaluated = PASS + FLAG, and the Reineke step (a4/bakuzis/bakuzis_v105_vs_v104.R).
5. Validation bias and RMSE of QMD and BA by source (plot-level a2/closeout/validation/val_v104_plotlevel.csv; trajectory a4/lt/LT_v104_points.csv).
6. Pooled BA coverage (plot-level, Table S26 scripts a5/rerun/cov, 500 joint draws).
7. dHT density-derivative positive count for suppressed trees, and dDBH positive-derivative count (density and share), realism script.

Bootstrap-dependent metrics: coverage uses each run's own 500 joint draws, regenerated per run by a4/joint_draws_v104.R from that run's fit
vcovs, origin-multiplier re-solves and MORT_CAL bootstrap pool, so no v105d draws are reused. The full-refit installation bootstraps (dDBH, dHT
boot_v103.R; height h_boot) and the vector-fixed dHT re-solve are not rerun: no metric above consumes them (CAL_*_SE_LOG are stored in
koa_params but not read by the MC, joint draws or coverage scripts). Their koa_params values stay at the v105d numbers and are flagged as stale.
Not run (not metrics here): LOIO, paired MC, figures, registry, sensitivity, red-team MC.

## Attribution rule (verbatim)

"A component is identified as a cause of a realism failure if reverting it alone (run R-x) removes that failure (low-site natural culmination above
the 10-yr floor and within 5 yr of C742; Eichhorn CV at or below 10% in that stratum; Bakuzis flags no more than C742; pooled BA coverage within
0.02 of C742). If no single revert removes a failure, run the pairwise reverts among the two components whose single reverts moved it most, and report."

Failure presence is first established in D742 (a failure absent in D742 is reported as not reproduced under the new divisor, and no attribution is
made for it). "Moved most" = largest change from D742 toward C742 in the failing metric.

Cores: at most 4 (another job holds 2); runs are executed so that concurrent workers never exceed 4.

PREREG written 2026-11-03 06:28:45 AST (before any run)
