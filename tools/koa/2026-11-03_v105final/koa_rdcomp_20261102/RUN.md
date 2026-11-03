# RUN.md: koa_rdcomp_20261102 (RD-weighted competition screen, Eq. 4 v105b), firebreather, 2 November 2026

PREREG.md frozen 2026-11-02 16:49:36 AST (md5 f1999c64b40ed026006a60280a68b568), Amendment 1 appended before any candidate other than K0 was fitted
(md5 after amendment 898a536af9ede32b1d8acf1e3d110b46; both in PREREG_md5.txt). Only ~/jobs/koa_rdcomp_20261102/ was written. The v105 job
(~/jobs/koa_v105_20261102), koa_brms_sdimax_20261102 and koa_byi2_20261101 were only read (00b_frames_mem.R evaluates inc_v103.R lines 148-197 with write.csv
masked to a no-op). No coordinate column exists in any input or output (nocoord asserted on every frame). At most 3 cores (a brms job held 4).

| step | command | result |
|---|---|---|
| stand table | Rscript 00_stand.R | out/stand_plotyear.csv: 862 plot-years from inputs/AK_TREE_v103.csv; SDI = TPH (QMD/25.4)^1.605 (TPH 0 -> 0, 100 plot-years); cor with summation SDI 0.984 |
| join check | Rscript 01_rd_join.R | joined BAPH = frame BAPH.0 and BAPH.1 to 1.1e-13; SDI at t.0 and t.1 on every row; plot SDImax on 4,962 of 4,992 dDBH rows (30 FIA rows, 4 plots, get 923) |
| frames in memory | Rscript 00b_frames_mem.R | out/frame_mem_{dDBH,dHT}_NO.rds; CSV vs memory max diff 3.4e-13, keys identical (Amendment 1) |
| K0 check | Rscript k0test.R | dDBH max abs diff vs deployed 5.0e-16 (logLik -9584.775); dHT 4.0e-15 (-6932.417) |
| main fits | bash run_main.sh (02_fit.R K0, g1.R, then K1..K3p 3 at a time) | out/fit_<cand>.rds; gate G1 PASS (out/gate_G1.csv: diffs 5.0e-16 / 4.0e-15; K0 40-60 cm ratio 1.701321) |
| bootstraps | bash run_boot.sh (03_boot.R resp cand 3; order in the script) | out/boot_<resp>_<cand>.csv; draws out/boot_draws_<resp>.rds (seed 20261101) |
| results | Rscript 04_results.R | out/results_table.csv, coefficients.csv, strata.csv, loso.csv |
| diagnostic | Rscript 05_diag_turn.R | out/diag_bal_turning.csv (not part of the rule) |

Abandoned: the first K0 run on the CSV frame (logs/02_fit_K0_csvframe_abandoned.log; b0 off by 1.1e-4 at the same logLik), stopped before G1; see Amendment 1.
Common rows: dDBH 4,971 (1,337 trees, 60 installations), dHT 4,033 (1,167 trees, 58 installations) = all model_cols rows (every row has SDI at t.0 and t.1).
Starts: for all 12 candidate fits both starts converged; the kept logLik and the other start differ by at most 0.08 (logs/02_fit_<cand>.log).
Bootstraps run: dDBH K3p only (17:17 to 18:20 AST, 3 cores, 200 of 200 converged, median 55.8 s per draw; logs/03_boot_dDBH_K3p.log). The queue (run_boot.sh) was
stopped at 18:25 AST right after it, once K3p was the only rule-relevant candidate (logs/run_boot.log); the K0 dDBH bootstrap had just started and was killed
(logs/03_boot_dDBH_K0.log has only its start line, no output). Every other candidate fails signs, 3-of-4 or ΔAIC, so its bootstrap cannot change any verdict
(PREREG compute order). Not run: dDBH K0, K1, K2, K3, K1p, K2p and all dHT bootstraps.
