# koa v104 (A4), 30 October 2026. Job ~/jobs/koa_v104_20261030, a full copy of koa_v103_20260930 with paths rewritten.
Engine directory keeps the name engine_v103 (symlink engine_v104 -> engine_v103); every v104 edit has a *_PREV_20261030 backup beside it.
Trigger: red team of manuscript v121 and supplement s114 (reviews/2026-10-30_koa-v121-s114_REDTEAM8_REVIEW.md, findings S1, S3, S4, S5).
Aaron chose "Option 2" (run the increment refit and mortality rule fix before submitting) and answered the three decisions below.

## A4-D1 Diameter increment vector (red team S1, S5)
Deploy dDBH_L_NO, the preregistered fallback of the v103 rule (no candidate eligible; smallest maximum equivalence region 0.1587),
replacing the v103 deviation A1-D6 (v102 vector with re-solved constants). Fitted on the live-list percentile BAL of Eq. 7, so the
competition index of fitting and of projection now agree. Vector: b0 0.2879773 b1 0.3607553 b2 -0.0223731 b3 -0.0014547 b4 -0.3377001
b5 0.8411799 b6 -0.0167759 b7 -0.0176977 b8 0.1402549 b9 -0.0158981; CF 1.50128; c natural 0.3837, planted 1.4575; CAL 0.25558, 0.97085;
SE log of CAL 0.19339, 0.10799 (installation bootstrap out/inc/boot_v103_dDBH_L_NO.csv). Site effect at BYI 450 vs 100: exp(0.1403 ln 4.5) = 1.235.
Patch: a4/patch_engine_v104.py -> engine koa_equations.py line 342, koa_params.py, out/v104_constants.json; HiGy.R ddbh.parm mirrored.

## A4-D2 Natural mortality level (red team S3)
One removal rule for all three stages: PSP 122 2019 to 2023 excluded everywhere (a2/mort/v104/plot_intervals_origin.csv, removal = True).
a4/run_mort_v104.sh -> a2/mort/v104/H_mort_level_natural.csv: level 2.51588 on 23 intervals (v103 2.54275 on 24), plot bootstrap
SE log 0.15758 (95 percent 1.965 to 3.675), installation 1.986 to 3.335, LOIO 2.342 to 2.908, observed deaths 15,326.
a4/set_mortcal_v104.py -> MORT_CAL (2.51588, 1.0), MORT_CAL_SE_LOG (0.15758, 0.0).

## A4-D3 Stage 3 ordering vector (red team S4)
Deploy the 4,223 record deduplicated Eq. 5 refit as the Stage 3 ordering weight: STAGE3_COEF c0 -2.45353544308563 c1 -1.24379127899638
c2 -0.245835518593837 c3 0.801873721680337 c4 0.164263748192269 (koa_params.py), read by koa_projector.py lines 342 and 353 (previously the
hard coded 4,911 record vector -2.1347, -0.8189, -0.8131, 0.3830, 0.3463). HiGy.R Stage 3 is a different, disclosed port (KOA_S3_SURV) and is not changed.

## Chains
chain 1 (a4/run_chain1_v104.sh): run_engine -> a2/out/traj_v104.csv, val_v104.csv; uneven_point; yield grid; joint draws (a4/joint_draws_v104.R,
seed 20261030, dDBH drawn from fits L_NO, 273 s); MC regen_m1 531 s -> engine_v103/out_m1 (v103 copies in out_m1_v103, a2/mc/out_v103, a2/fin/out_v103).
chain 2 and 2b (a4/run_chain2_v104.sh, run_chain2b_v104.sh): registry engines updated; make_traj; s05 to s07; lt (a4/lt, LT_v104 and u104); ceiling;
mort planted and natural; proto; plot level validation (a2/closeout/validation/val_v104_plotlevel.csv, make_tables_v104.py -> tableC_v104_plotlevel.md);
a4/compute_pending_v104.py -> table2, tableS2, gross_mai, culmination_mc _v104.json; registry koa_numbers_v104.py, compare_v104_vs_v103.py, gate_v104.py
(bash a2/registry/make_md.sh) -> numbers_v104.json, numbers_v104_vs_v103.md, gate 21 of 21 (the residual sd_log check now reads a4/redteam/mc_v104.py on the v104 draws).
a4/diag_c_by_source_v104.R -> a2/out/diag_c_by_source_v104.csv. Figures: a4/run_figs_v104.sh (fig_main_v104.R, figS_v104.R, figS12_v104.R) -> a4/figs.
Parity: engine_v103/parity_r_050.R, parity_python_050.py, parity_compare_050.py rerun on the v104 engine, 18 cases PASSED (mortality path, unchanged by A4).

## Headline v104 results (registry numbers_v104.json)
Table 4 natural even-aged 40 yr volume 124.4 / 153.6 / 175.0 m3 ha-1 (low, medium, high BYI; v103 106.3 / 160.2 / 197.4); 100 yr 212 / 242 / 266;
planted 40 yr 369 / 421 / 463; natural QMD 40 yr 30.4 / 34.0 / 36.1 cm. Plot level validation, 17 plots: survival bias +0.043 (TOST pass, slope pass),
QMD -1.21 cm (bias pass, slope 0.85 fail), BA -1.29 m2 ha-1 (bias pass, slope fail); natural survival not equivalent (+0.062); planted QMD slope fails.

## A4-D4 (30 Oct 2026, 21:55 ADT): BYI x competition interaction candidate, preregistered before running
Aaron asked whether BYI should enter Eq. 4 in another form or with interactions. The linear mixed screen (a4/byi, not the recursion
fit of record) ranked ln(BYI) x ln(BAL+1) first by AIC among forms that keep a single BYI main effect, and ranked the plain ln(BYI)
main effect first on three of the four held out sources by leave one source out RMSE (the quadratic was lower on FIA; a4/byi/byi_loso_v104.csv). Decision: fit the interaction form as a proper recursion
candidate (<resp>_LX_NO: live-list BAL, NO frame, extra term b10 ln(BYI) ln(BAL_t+1)) with inc_v103.R machinery, and deploy it over
<resp>_L_NO only if all four preregistered conditions in a4/inc/inc_byi_x_v104.R hold: sign checks, non-negative BYI elasticity at
BAL q05 and q95, the v103 eligibility or fallback rule, and leave one source out RMSE not worse than L_NO on more than one source.
Otherwise it is reported in S3.2 as a sensitivity. Script: a4/inc/inc_byi_x_v104.R; outputs a4/inc/out; log a4/logs/inc_byi_x_v104.log.
Outcome (22:08 ADT): NOT DEPLOYED for either response. dDBH_LX_NO: logLik -9561.9 vs -9587.7 (L_NO), b8 -0.0826, b10 0.1640; BYI elasticity
-0.083 at BAL q05 (condition ii fails: a richer site lowers growth of trees with little competition), 0.190 at the median, 0.470 at q95;
max equivalence region 0.1654 vs 0.1587 for L_NO (iii fails); leave one source out RMSE worse on FIA (2.507 vs 2.416) and PSP (1.059 vs 1.028),
better on DOFAW (1.029 vs 1.107) and KMR PSP (0.580 vs 0.602) (iv fails, 2 of 4). dHT_LX_NO: logLik -6928.7 vs -6931.9, b8 -0.0261, b10 0.0750,
elasticity -0.026 at q05 (ii fails); max region 0.2349 vs 0.2453 (passes iii as fallback); LOSO worse on DOFAW and PSP (iv fails).
The v104 system keeps ln(BYI) as a main effect; the candidate is reported in S3.2 as a sensitivity. Outputs a4/inc/out/*_byi_x_v104.csv.

## A4-S (30 Oct 2026, 23:07 ADT): sensitivity statements recomputed on the v104 engine for the supplement retrace
a4/sens/sens_v104.py -> a4/sens/sens_v104.json and yield_grid_eq1_v104.csv (culmination at the planted multiplier bounds 0.609 to 1.131,
unweighted rank sensitivity, years from 2.5 cm to the initial QMD (grid: a4/sens/years_grid_v104.py -> years_grid_v104.csv), planted stemwood biomass against Eq. 1 on the v104 yield grid);
a2/registry/run_ceiling.sh rerun (the chain 2 run had failed on a missing output directory) -> a2/registry/ceiling/v104;
a4/inc/respec_v104.R -> a4/inc/out/respec_v104.csv (no ln(CR), no tree intercept, residual variance proportional to YIP, both responses);
a2/figs/scripts/lt_v103.py on a2/registry/engine_nocal -> a4/lt/nocal (trajectory validation without the natural level factor).
Figure scripts a4/figs/fig_main_v104.R and figS_v104.R: BYI legend and axis labels restored to Mg ha-1 (were "index units"); rerun 22:58 to 23:00.
Also: a4/inc/s32_sens_v104.R and s32_sens_bd_v104.R -> a4/inc/out/s32_sens_v104.csv, s32_sens_bd_v104.csv (restored non-positive increments, data source as a fixed intercept,
protocol switch not computable on the calibration frame: every KMR PSP interval ends in 2023); a4/inc/lntph_v104.R -> a4/inc/out/lntph_splits_v104.csv (ln TPH on twenty random
80:20 installation splits, seed 20261030). The dHT refit on the restored frame did not converge within 20 minutes and was stopped; only the re-solved constants are reported for height.
Figs S3 and S4 regenerated 23:45 with a4/figs/figS34_v104.R (out_span -> a2/mort/v104, S18 trajectories from the v104 traj_M1); S3 unchanged in content (survival frames unchanged), S4 panel (c) and (b) carry the 2.51588 level.
