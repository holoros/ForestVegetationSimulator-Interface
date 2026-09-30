# RUN.md - koa_rv_byi_20260928

Purpose: reviewer analyses on the Biomass Yield Index (R1 comments 7, 8, 10; R2 comment 14), manuscript v102, supplement s100.

- Date: September 28, 2026. Host: ifm-kershaw (firebreather). R 4.5.1 (2025-06-13); nlme 3.1.170, ranger 0.18.0, data.table 1.18.6.1; GDAL 3.2.2 (gdallocationinfo). spatialRF, gstat and terra are not installed; nothing was installed. The spatialRF fits were refitted with ranger from their stored ranger.arguments (500 trees, mtry 3, min.node.size 5, sample.fraction 1 with replacement, seed 42), which reproduces the stored OOB RMSE exactly (219.32 Kona, 198.20 statewide).
- Seeds: 20260928 (all scripts); ranger seeds 42 (OOB refit) and 42 + repetition (CV).
- Bootstrap: 2,000 resamples, percentile intervals, plot clusters (Eq. 1, stocking) or CV blocks (RF).
- Wall time: about 15 min of compute across all scripts (15:00 to 15:37 ADT including debugging).

Inputs (md5). Uploaded from the laptop folder ~/Documents/MAINE/DATA/Koa (and GIS/) straight to firebreather, never through the Cowork sandbox:
- in/AGB.FIA.csv 09610010dd3de0af703eeb29dc3a0541 (Eq. 1 fitting frame written by Schmoldt_Index_extraction.r)
- in/Schmoldt_Index_by_plot.csv 616abb5ef1f3b3f34d4adf8fe0f68fd4 (archived plot asymptotes, 339 plots)
- in/Schmoldt_Index_extraction.r 7d26b0b00d619199cbc0fad562fdefef (the BYI pipeline: H40, AGB, nlme Eq. 1, VSURF, spatialRF, prediction)
- in/PLT.GEO_FIA.csv 091c5613a23c062b36996989130da9e7 (RESTRICTED, FIA locations with extracted predictors; used on firebreather only)
- in/HI_PLOT.csv 873555b8f3a4f5beab219dbcbaa1b2f8 (FIA public, perturbed coordinates; used on firebreather only)
- in/HI_TREE.csv ba376b2cf1e9cc5f76d4ae58422f2976, in/HI_COND.csv 89db45d918bcf41936e60e76c4d146bf
- in/BYI_srf_fit.RDS 21904f34c48be122902bcc0f43260f2b, in/BYI_srf_fit_HI.RDS 9eda9a2b832846effd2796607248d0c5 (copied from koa_fig2unc_20260927/in)
- in/BYI_OOB_island_performance.md 43427ee992d1c1db9e1178a7ead414c0, in/BYI_srf_fit.txt 5abe456ad44fbbb522be80042798347c, in/HI GIS.r, in/Koa FIA Stats.r (context)
- read in place: ../koa_zenodo_180/stage_v190/AK_PLT_GEO.csv 95f3fac7792248139767bff6a81a2fda, BYI_all.tif 6c926adcaf98a677396c1a6749dccdfe

Scripts (run in order; each writes <name>.log):
- 00_inspect.R structure of the two spatialRF objects (no coordinate values)
- 01_counts.R pipeline counts, rebuild of both RF training frames (identical in order to the stored data)
- 02a/02b/02c_try.R the archived nlme call fails on nlme 3.1.170 ("Singularity in backsolve at level 0") in every variant tried
- 02_eq1_refits.R Eq. 1 in its exactly equivalent conditionally linear form (lme with random slopes on f(H40)), (k, p) by profile ML within the archived bounds; 02_eq1_refits_UNBOUNDED.log shows the unbounded optimum at k -> 0, A -> infinity
- 03_stocking.R plot-visit TPH, BA, QMD, SDI, relative density from HI_TREE; Spearman with bootstrap
- 04_rf_cv.R random, spatial block (5, 10, 20 km) and leave-one-region-out CV, OOB residual semivariogram and distance-band Moran's I (499 permutations)
- 05_temporal.R first vs second measurement refits and TOST
- 06_assign_transfer.R AK_PLT_GEO FIA values, zero-location status, transfer of BYI_all.tif to the Eq. 1 plots of other islands
- 07_growthplots_surface.R surface values at the 38 FIA growth installations
- run_*.R are sink wrappers.

Restricted data: coordinates were read only inside R on firebreather to build blocks, distance bands and raster lookups. work_frames_RESTRICTED.rds and stocking_frames.rds hold coordinates or plot keys and stay on firebreather; they are NOT downloaded. All out_*.csv files and REPORT.md are aggregates without coordinates or per-plot rows.

Zenodo: staged via main session. GitHub: pending Aaron's PAT approval.
