# RUN_K3c.md (rev2), firebreather, 2 November 2026
PREREG_K3c.md frozen 21:37:53 AST (md5 35f5fa3b2ba1d3137a898cd2869261c6, PREREG_K3c_md5.txt). Only constrained/rev2/ written (no existing file edited, so no
_PREV backups were needed). 1 core (7 of 8 busy: brms 4, the koa_v105c boot 3). No coordinate column in any input or output (frames pass nocoord()).
| step | command | result |
|---|---|---|
| fits | bash run_r2.sh (02r_fit.R K3c3, P05, P5; 21:38 to 21:45) | out/fit_K3c3.rds (both starts logLik -9538.164; LOSO inside), fit_P05.rds, fit_P5.rds |
| monotonicity | Rscript 04r_mono.R | out/monotonicity_summary_rev2.csv, monotonicity_grid_rev2.csv.gz |
| results | Rscript 05r_results.R | out/results_K3c_rev2.csv, k3c2_profile.csv, strata_rev2.csv |
Reused: ../out/fit_K0c.rds, fit_K3c1.rds, fit_K3pc.rds, boot_dDBH_K3c1.csv; ../../out/fit_K0.rds, fit_K3p.rds. Not run: K3c3 bootstrap (fails (i)); Stage 2.
