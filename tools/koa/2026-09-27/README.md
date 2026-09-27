# koa scripts, 27 September 2026

This folder holds the scripts, run notes and small aggregate outputs from three firebreather jobs run on 27 September 2026 for the Acacia koa growth and yield manuscript.

fig2_uncertainty (job koa_fig2unc_20260927) builds the out-of-bag uncertainty layer for Fig. 2, the BYI site index surface. It fits a local error model to the out-of-bag prediction pairs and maps the resulting uncertainty alongside the original figure script, which is kept here as fig2_ORIGINAL_COPY.R for reference.

s20_multistart (job koa_s20fix_20260927) reproduces the producer run behind Table S20 and refits the held-out source models from several starting values, keeping the best fit and reporting the log likelihood spread across starts.

selfthinning_qr (job koa_selfthin_qr_20260927) fits the self-thinning limiting line by quantile regression with an installation-cluster bootstrap, under the preregistered boundary rule in PREREG_boundary_rule.md, and tests whether the deployed engine's projections stay inside it.

The manuscript and supplement edits these jobs support were applied on 27 September 2026. No plot-level data, fitted model objects or coordinates are included; each job's RUN.md records the full file inventory with checksums, including what stayed on the server.
