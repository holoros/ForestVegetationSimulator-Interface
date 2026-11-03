# RUN_K3c.md: constrained K3p screen (koa_rdcomp_20261102/constrained), firebreather, 2 November 2026

PREREG_K3c.md frozen 2026-11-02 18:31:26 AST (md5 588c1184a6f0c2d0ddd1b4c1aa39aaf9, PREREG_K3c_md5.txt), before any K3c fit (first fit started 18:32:19 AST,
logs/02c_fit_*.log). Only this folder was written; the parent screen (../), the v105 job and the brms job were only read. Frames: ../out/frame_mem_dDBH_NO.rds
(in-memory rebuild of the v105b NO frame, parent Amendment 1) through ../lib.R frameK; RD = SDI/923. No coordinate column in any input or output.
At most 3 cores (a brms job held 4 and another R job 1).

| step | command | result |
|---|---|---|
| main fits | bash run_main_c.sh (02c_fit.R K0c, K3c1, K3c2 three at a time, then K3pc) | out/fit_<cand>.rds; LOSO and strata inside |
| K3p code-path check | Rscript g0b_k3p_startb.R | K3p through gr.hat3c from the parent's kept start: max abs diff 0, logLik -9532.906 (logs/g0b_k3p_startb.log) |
| bootstrap | bash run_boot_c.sh (03c_boot.R K3c1 3) | out/boot_dDBH_K3c1.csv: 200 of 200 converged, median 47.4 s, 18:40 to 19:36 AST; draws ../out/boot_draws_dDBH.rds (seed 20261101) |
| monotonicity | Rscript 04c_mono.R | out/monotonicity_grid.csv (6,030 grid points per candidate), monotonicity_summary.csv, monotonicity_by_dbh.csv |
| results | Rscript 05c_results.R | out/results_K3c.csv, coefficients_K3c.csv, strata_K3c.csv, gate_G0.csv |

Notes. (1) The first 04c_mono.R run evaluated the grid with a scalar n inside the recursion, so ifelse() returned only the x = 0 value (finite-difference and analytic
derivatives disagreed); fixed to n = rep(1, length(x)) and rerun before any result was used (fd and analytic now agree to 1.7e-7). (2) K3c2 fails the sign check
(b3 = 1.98 > 0); its bootstrap was started by run_boot_c.sh after K3c1 and stopped at once (stop_k3c2_boot.sh, 19:36:39 AST) because it cannot change the verdict
(PREREG compute order) and the cores were needed. (3) K3pc (K3p refit from its own stored vector) differs from the parent fit by up to 1.75e-4 (b5) at the same
logLik; from the parent's kept start the gr.hat3c path reproduces K3p exactly (note 1 of RESULTS_K3c.md).
