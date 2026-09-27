# RUN.md - koa_fig2unc_20260927

Purpose: add an out-of-bag uncertainty layer to manuscript Figure 2 (koa v102 BYI surface), at Aaron's
request of 27 September 2026, and check the RMSE the manuscript reports for the BYI random forest.

- Host: ifm-kershaw (firebreather). R 4.5.1; ranger, data.table, ggplot2, patchwork, scales. No terra.
- Seed: 20260927 set; the refits use the stored ranger seed 42 from each fit object.
- Inputs (uploaded from laptop ~/Documents/MAINE/DATA/Koa/, md5):
  in/BYI_srf_fit.RDS 21904f34c48be122902bcc0f43260f2b (Kona forest, 582 rows)
  in/BYI_srf_fit_HI.RDS 9eda9a2b832846effd2796607248d0c5 (statewide forest, 581 rows)
  in/BYI_OOB_per_plot.rds 6169b3bb25a5297edff4f5a058f2f73d (archived OOB file; NOT used, see below)
  byi_arch.xyz ed165f5812a9009a482f087b6de567b3, byi_isl.xyz 5b9a6705697e65de9b3cff827eb253a9 (symlinks to
  ../koa_fig2_20260926, warped from the deposited BYI_all.tif 6c926adcaf98a677396c1a6749dccdfe by warp2.sh)
- 01_errmodel.R: refits each forest from its stored ranger.arguments to recover per-row OOB predictions.
  Both refits reproduce the archived OOB MSE exactly (48101.33 and 39284.86, difference 0). OOB RMSE 219.32
  Kona, 198.20 statewide; in-sample RMSE 104.33 and 109.88. The archived BYI_OOB_per_plot.rds gives 217.66
  and differs from the refit by up to 269 per row, so it is from another run and was not used.
  Output out_oob_pairs_DATA.csv (obs, oob, model; no coordinates).
- 02_errfit.R: loess (span 0.6, degree 1, surface direct) of squared OOB residual on OOB prediction per
  forest; held at end value outside the OOB prediction range. Degree 2 was tried first and rejected: it bent
  to 561 Mg ha-1 past 600 on 41 points against a binned 326. Outputs out/errmodels.rds, out/local_rmse_table.csv.
- 03_fig2u.R: Figure 2 panels (a, b) as fig2_ORIGINAL_COPY.R; (c, d) local OOB RMSE mapped through each cell's
  BYI, Kona forest where lon > -156.10 and lat < 20.35, statewide elsewhere. 174 x 186 mm, 600 dpi LZW TIFF,
  PDF, 150 dpi check PNG. Rendered and inspected three times (title clipping and scale-bar label fixed).
  Launch: setsid nohup Rscript 03_fig2u.R > fig2u.log 2>&1
- Output: Fig2_byi_surface_v102.tiff md5 00b1cfdfac9ac28341bb0beab3e47180 (4110 x 4393, 600 dpi). The copy in
  the laptop submission folder is 0cf7748779a9874bb3a7f19afc20048d, 5,979 bytes larger from the commit path,
  decoded pixels identical.
- Restricted data: none. The fit objects carry predictor columns only; coordinates were never read.

## GitHub and Zenodo
GitHub: scripts to be pushed with the koa 27 September jobs (see session handoff). Zenodo: the figure is a
manuscript figure, not a deposit file; the error model tables ride with the next deposit version if Aaron wants
the layer archived.
