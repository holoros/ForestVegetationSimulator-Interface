# RUN.md a5/rerun (koa v104), 31 Oct 2026, host firebreather

Scope: rerun the supplement s114 results that Section S8 lists as computed on the preliminary covariate assembly, using the final frames and the v104 system described in a4/RUN.md. Everything below is relative to ~/jobs/koa_v104_20261030/a5/rerun/. Nothing outside this directory was modified. Engines were imported read only with PYTHONDONTWRITEBYTECODE=1, and a find for files newer than the run start in engine_v103 returned none. s28/engine is a tar copy of engine_v103 without the out_m1* directories (out_joint, out_stage1 and out_m1/validation_M1.csv were copied in). No coordinate column was read: geo tables were read with usecols, and the QR frame asserts no coordinate-like names. The plot-key CSVs (cov_reps.csv, cov_point_*.csv, analysis_frame_v104_DATA.csv) stay on firebreather. Cores: at most 3 (2 for the height bootstrap, 1 for everything else).

| Item | Source script (preliminary) | Rerun script | Changed inputs | Seed / B | Log | Gate |
|---|---|---|---|---|---|---|
| 1 Eq. 2 bootstrap | koa_rv_incr_20260928/s2_height_boot.R | h/h_boot.R, h/h_summ.R | frames/final/tree_join_v103.csv with prep/fit_ht from track2/height_refit_v103.R | 20261031 / 2000 | logs/h_boot.log | reference = HT_P (6 dp) |
| 2 S26 | koa_rv_mort_20260928/a2_mc_validation.py + a2b_coverage.py | cov/cov_mc.py (built by cov/build.py from a2/closeout/validation/plotlevel_validation.py), cov/cov_summ.py | v104 engine_v103, v104 joint draws, 17 (18) plot-level + 23 subplot units | regen_m1 (42) / 500 reps; CI boot 20260928 | logs/cov.log | mirror 0.0; val_v104_plotlevel 7.1e-15 |
| 3 S21 | koa_rv_mort_20260928/a1_stage12.R | s21/a1_stage12_v104.R | a2/mort/v104/plot_intervals_origin.csv (removal applied, 285 intervals) | 20260928 / 2000 | logs/s21.log | reported only: S1 0.030, S2 0.083 vs STAGE1 (282-interval fit) |
| 4 S28 | koa_origin_20260916/v100/trackB/b1_mort_holdout.py + lt_core.py | s28/b1_mort_holdout.py, s28/gate_core.py, s28/to_pred_minus_obs.py | s28/engine (v104), a2/mort/v104 loio/level/intervals, a4/lt/LT_v104_points.csv | none | logs/s28_B1.log, s28_gate.log | LT_v104 0.0 |
| 5 S29 | koa_origin_20260916/v100/trackB/b2_local_calib.py | s28/b2_local_calib.py | as item 4 | 20260917 / 2000 | logs/s29_B2.log | LT_v104 7.1e-15 |
| 6 S11 | koa_rv_incr_20260928/s1b_within.R (ii), s1c_kulani.R | s11/s11_v104.R | frames/final/*_NO_v103_model.csv (live BAL), v104 L_NO vectors and c constants | 20260928 / 2000 | logs/s11.log | solve_c = deployed c exactly |
| 7 limiting line | koa_selfthin_qr_20260927/01_data_envelope.R, 02_fit_contain.R | qr/01_frame_v104.R, qr/02_fit_v104.R, qr/03_contain_v104.py | inputs/AK_TREE_v103.csv anchor frame (483), v104 allometry, engine_v103/out_m1 traj and reps | 20260927 / 2000 | logs/qr.log | n 483, z99 456333.510467 |
| 8 S22 | not identified | not run | | | | |

Changes beyond inputs:
- h_boot.R saves one checkpoint file per draw, and the tree random-effect comparison was dropped.
- S11 applies the v104 origin constants inside the annual recursion (b0 + ln c, as inc_v103.R solve_c), because that is how the v104 system applies them. The preliminary run used the v102 k x CF multiplier.
- The 02_fit_v104.R containment section was replaced by 03_contain_v104.py, which reads v104 trajectories.
- The Table S28 and S29 signs were flipped to projected minus observed in to_pred_minus_obs.py.

Still running at handback: item 1 (setsid; parent R process plus 2 workers running h_boot.R). To resume after an interruption, run `bash h/run_h.sh` (finished draws are skipped). To summarize, run `Rscript h/h_summ.R`. To stop, kill the h_boot.R R processes; matching the pattern from inside a shell whose own command line contains it kills that shell too.

## Update 31 Oct 2026, 15:54 ADT (coordinator instruction)
- Height bootstrap plan changed to B = 500. The seed (20261031) and the draw index generation are unchanged, so draws 1 to 500 are a prefix of the 2,000 design. a5/stage3fix/run_a5.log showed "A5 DONE" at 15:24, so the 2-core job was stopped at 15:53 after 77 draws (stale .tmp files removed) and restarted with `bash h/run_h500.sh` (`Rscript h_boot.R 500 5`, 5 cores). Log: logs/h_boot500.log. It reuses the 77 checkpoints in h/draws, and h_summ.R now reports draws_planned = 500.
- Stage 3 fix dependency check (a5/stage3fix): S26, S28 and S29 do not use run_candidates.project. They project through koa_longterm_validation and koa_projector.project_psp; regen_m1 is imported only for _gated and set_params. Confirmed with the regenerated outputs, all identical to the inputs used here (max abs diff 0.0): val_v104_plotlevel.csv (18 units), a4/lt/LT_v104_points.csv (85 points) and engine_v103/out_m1/validation_M1.csv (23 units). K_joint_draws.csv has the same md5 (b441636107fe19b7011f92a950ba308d), and the engine modules koa_params, koa_equations, koa_projector, koa_longterm_validation, threestage and regen_m1 are byte-identical to the s28/engine copy. No rerun is needed.
- The limiting-line containment was rerun on the regenerated engine_v103/out_m1 traj_M1.csv (15:07) and reps_evenaged_M1.csv (15:13): qr/containment_v104.csv. The earlier file is kept as qr/containment_v104_PRE_stage3fix.csv. The line itself (qr_lines_v104.csv) is unchanged.
- Height bootstrap B = 500 finished at 17:59 ADT: logs/h_boot500.log reads "HEIGHT BOOT DONE ok 263 of 500". h_summ.R then wrote h/h_boot_summary_final.csv (500 draws, numbered 1 to 500, no duplicates).
