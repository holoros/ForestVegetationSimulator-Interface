# RUN.md - koa_s20fix_20260927

Purpose: recompute the start-sensitive refit cells of Supplemental Table S20 (dDBH, KMR PSP held out)
from the best-logLik fold refit, after reproducing the printed values from the producer.

Host: ifm-kershaw (firebreather). R 4.5.1 (2025-06-13), nlme 3.1.170, parallel (mclapply).
Date: 2026-09-27.

Seeds: S1 keeps the producer's set.seed(20260916), which drives only its 2,000-draw source bootstrap.
S2 sets 20260926 for the record; it draws no random numbers (deterministic nlme fits).

Inputs, read-only (md5):
  6d871307853376b7660b10d95137c873  ~/jobs/koa_v102_20260918/track2/inc/frames/V102/dDBH.csv
  8f2a91e2a9acb81e77d6031d490dc6a9  ~/jobs/koa_v102_20260918/track2/inc/frames/V102/dHT.csv
  d97aeb740b6182b79ad64b5c248c3852  ~/jobs/koa_v102_20260918/track2/inc/inc_fits.rda
  92704a1cb939fef8bcb6c7df6a63e988  ~/jobs/koa_v102_20260918/track2/inc/psp_origin_thinning_2026-09-16_DATA.csv
  d7dcc5638c0a2402185f5406efb9e1c3  ~/jobs/koa_v102_20260918/track2/inc/dDBH_BYI.rda
  1a5ca66c430f9d841a20574a9947f3c7  ~/jobs/koa_v102_20260918/track2/inc/dHT_BYI.rda
  c961d7c305823f8a31e8298cd7da462d  ~/jobs/koa_v102_20260918/track3/ref/origin_refit_REFERENCE_COPY.R
  6fa1ab10146a1d85ee8a8e85c70060b3  ~/jobs/koa_v102_20260918/track3/inc/loso_v102.R   (S20 producer)
  7bb4b6850ebd6f3413f876d881b4d5d2  ~/jobs/koa_loso_origin_20260926/D_multistart.R   (source of the four starts)
  Printed S20 values checked against ~/jobs/koa_v102_20260918/track3/inc/out_V102/I_loso.csv
  (ccc2e3471d5be28b2bbb4aee88f3e09a) and the Table S20 text of koa_supplemental_v100.docx (read only).

Scripts:
  S1_producer_repro.R  = loso_v102.R with two lines changed: T3/E2 set to absolute paths, OUT set to
                         ~/jobs/koa_s20fix_20260927/out_repro. Nothing else touched.
  S2_multistart_S20.R  = every S20 fold refitted from the four starts of D_multistart.R, producer
                         definitions of k_train_b, bias_b, ratio_b; best logLik kept per fold.

Commands:
  setsid nohup ./chain.sh > /dev/null 2>&1 < /dev/null &
  chain.sh runs: Rscript S1_producer_repro.R V102 > S1.log 2>&1
                 CORES=7 Rscript S2_multistart_S20.R > S2.log 2>&1
  Wall time: S1 62 s, S2 103 s.

Restricted data: frames asserted free of lat/lon columns in both scripts; only origin-level aggregate
multipliers, biases and ratios are written. No per-plot or per-installation values leave the server.

GitHub and Zenodo: not pushed or deposited; pending Aaron's go-ahead, as for koa_loso_origin_20260926.
The outputs belong with the manuscript's own deposit version if the S20 change is adopted.

Result: RESULT.md
