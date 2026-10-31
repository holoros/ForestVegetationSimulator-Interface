# RUN.md: a5/pairmc (paired Monte Carlo of BYI ordering), 31 October 2026

Host firebreather; python3 (numpy, pandas), R (nlme, MASS, ranger). At most 3 cores. Nothing outside a5/pairmc was modified.
PREREG.md written 14:24 ADT (md5 50165b29e0ebd056969b174a5f65a2f6) before any computation.

## Steps (in order)
1. engine/: copy (cp -rL) of engine_v103 = engine_v104, without out_m1* directories, AK_PLT_GEO.csv (coordinates) and koa_regen.tgz. Not edited;
   the process-error hooks live in pairmc.py as a programmatic copy of run_candidates.project (pm_project) with five asserted string edits.
2. joint_draws_pairmc.R (copy of a4/joint_draws_v104.R; only MCOUT -> a5/pairmc/jointmc/out and NC 4 -> 3), run_joint.sh with KOA_NJOINT=1000,
   seed 20261030: 929 s, rejected sources 0, Stage 1 redrawn 53 (logs/joint_draws_pairmc.log). Gate J: rows 0 to 499 identical to
   a4/jointmc/out/K_joint_draws.csv (max |diff| 0.0, sources equal).
3. byi/byi_resid.R: Kona BYI forest (koa_rv_byi_20260928/in/BYI_srf_fit.RDS stored training frame: response and 10 environmental predictors,
   no coordinate columns, asserted) refitted on the 235 BYI > 0 plots, seed 42. Gate B: OOB RMSE 217.611, R2 0.114, bias 4.473 equal
   out_T3_rf_cv_summary.csv. Output byi/byi_oob_resid_kona_nz.csv (obs, pred, residual, log ratio; shuffled, no keys), byi_resid_summary.csv, byi_resid.log.
   Scale rule: Spearman |e| vs pred 0.256 (P 0.0001), |ln(obs/pred)| vs pred 0.047 (P 0.47) -> multiplicative.
4. pairmc.py prep: seed 20261031; installation and TreeID normals, true BYI = nominal x exp(l*), l* resampled from the log ratios inflated about
   their mean by 227.938/217.611, truncated (redraw) to [25.147, 691.244] -> out/prep_draws.npz, out/byi_true_draws.csv.
5. run_all.sh: pairmc.py gate (3 workers, 71 s) -> out/gate1_w*.csv; summarize.py gate check; pairmc.py main (3 workers, 564 s, 1,000 replicates,
   variants P, PP, PPB, B) -> out/raw_w*.csv; summarize.py -> out/pairmc_reps.csv, prob_ordering.csv, intervals.csv, paired_P_vs_table4.csv,
   gate1_table4_ranges.csv, byi_truncation.csv, summary.json; logs/summary.log.

## Gates
- pm_project with unit multipliers vs run_candidates.project: max |diff| 0.0 (6 stands, 40 yr).
- Gate 1: published-scheme reproduction equals engine_v103/out_m1/reps_evenaged_M1.csv for all 3,000 replicate-scenarios at years 20, 30, 40
  (max |diff| 0.0 for VOL, BAPH, QMD); 12 of 12 Table 4 VOL ranges (ages 20 and 40, table8_evenaged_M1.csv) reproduced to 2 decimals. PASS.
- Gate J and Gate B: PASS (above).

## Deviations from the task brief
- BYI error uses OOB residuals of the BYI > 0 forest inflated to the 20 km blocked RMSE, not blocked residuals: the blocks need FIA true
  coordinates, which this track must not read (declared in PREREG).
- Truncation range is the increment calibration range of BYI (25.147 to 691.244), not the map plot range (116.5 to 2,642.5), because the engine
  would extrapolate beyond it (declared in PREREG).
- Process error is the installation and TreeID random intercepts of the increment fits; the within-tree annual residual, the Data-source effect
  and mortality stochasticity are omitted (reasons in PREREG).

## Observation outside scope (not changed)
run_candidates.project (the Table 4 path through regen_m1) still hard-codes the 4,911-record Stage 3 ordering vector (-2.13468, -0.81890, -0.81311,
0.38295, 0.34632; run_candidates.py line 114); A4-D3's STAGE3_COEF (4,223-record vector) is read only by koa_projector.py lines 342 and 353.
So the published Table 4 (and this track, which reproduces it) does not use the A4-D3 vector.

## A5 rerun (31 October 2026, 15:25 to 15:48 ADT)
- Waited for a5/stage3fix/run_a5.log "A5 DONE" (15:24:07; chain1 0, chain2 0, figs 0, figS34 0, sens 0).
- PREREG addendum A5 (15:04 ADT) and amendment A5-B (15:43 ADT) written before the respective runs.
- run_all_a5.sh: fresh engine copy engine_a5 (same exclusions), height draw snapshot boot_inputs/h_draws_snapshot.csv (45 files, 25 converged),
  pairmc_a5.py gate (66 s) -> gates PASS, pairmc_a5.py main (801 s, P, PP, PPB, B, BOOT, BOOT_PPB) -> out_a5/raw_w*.csv.
- BOOT NaN defect (14 incomplete dDBH bootstrap rows) -> amendment A5-B -> run_boot_a5.sh (PAIRMC_VARS=BOOT,BOOT_PPB, 260 s) -> out_a5/raw_boot_w*.csv;
  summarize_a5.py takes BOOT variants from the rerun only and asserts no NaN -> out_a5/pairmc_reps.csv, prob_ordering.csv, intervals.csv,
  paired_P_vs_table4.csv, gate1_table4_ranges.csv, byi_truncation.csv, summary.json.
- diag_warn.py: warning attribution check (logs/diag_warn.log).
