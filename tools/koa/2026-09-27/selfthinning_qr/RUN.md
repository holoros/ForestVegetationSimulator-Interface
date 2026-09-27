# RUN: koa self-thinning quantile regression test (Supplement Section 6 circularity)

- Host: firebreather (ifm-kershaw), Linux 5.10.0-35-amd64 x86_64, Debian GNU/Linux 11 (bullseye)
- R 4.5.1 (2025-06-13); quantreg 6.1, data.table 1.18.6.1, ggplot2 4.0.3, parallel 4.5.1 (mclapply, 6 cores). quantreg was already installed; no hand-rolled LP was needed.
- Seed: 20260927 (Mersenne-Twister, Inversion, Rejection). All 2,000 installation resamples are drawn once, sequentially, in the master process before the parallel fits, so results do not depend on the core count. A full rerun of 02_fit_contain.R into scratch/rerun reproduced bootstrap_coefs.csv, qr_lines.csv, qr_bands.csv and origin_model.csv bit for bit (identical md5).
- Run 27 September 2026. Nothing outside this directory was modified. No coordinates: every input's column names were checked against a coordinate pattern (01_data_envelope.R, 02_fit_contain.R, 04_figure.R assert it); none present.

## Inputs (read only)

| md5 | path under ~/jobs |
|---|---|
| 81383c5e08f1415589dcd1e271329370 | koa_v102_20260918/track2/engine_v102/AK_TREE.csv |
| 072334b568781be7cc0a94550ec382fb | koa_v102_20260918/track2/engine_v102/AK_PLT.csv (origin only) |
| ec5d72940c6625e6da8d4ff67aaa3c56 | koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv (deployed, MORT_CAL 2.64629) |
| 57085e3ccd5b0e5abf93bcb7b9bd4fc6 | koa_prereg_B_beta_20260926/out/GRID_trajectories.csv (variant B, arms C5 and C3) |
| 9691ae0f33d8c8575ebc945c0b714332 | koa_v102_20260918/track2/engine_v102/koa_params.py (constants A, k_HD, beta read from here) |
| 1739f497ca9a204bdcae6fb2ba682a02 | koa_v102_20260918/track3/garcia/beta_anchored_v102.json (anchor of record) |
| e27a6a4f6db16d9dbc851ca469cf47cd | koa_zenodo_180/stage_v102/envelope_check_v82.py (envelope producer, derivation reproduced in R) |
| b4cbbff16b9c90fb0a77778c371771dc | koa_v82_hybrid/hybrid/fit_allometry.py (beta anchor producer, derivation reproduced in R) |

## Commands (in ~/jobs/koa_selfthin_qr_20260927)

    setsid nohup Rscript 01_data_envelope.R  > out/01_data_envelope.log 2>&1 &   # envelope + anchor reproduction, analysis frame
    # PREREG_boundary_rule.md written here, before any fit (md5 6ba91aceca6c8742348f7c254f6013d9)
    setsid nohup Rscript 02_fit_contain.R    > out/02_fit_contain.log 2>&1 &     # rq fits, cluster bootstrap, containment (~2.5 min)
    setsid nohup Rscript 03_tables.R         > out/03_tables.log 2>&1 &          # summaries for RESULT.md
    setsid nohup Rscript 03b_origin_lines.R  > out/03b_origin_lines.log 2>&1 &   # origin-specific lines (descriptive)
    setsid nohup Rscript 04_figure.R         > out/04_figure.log 2>&1 &          # figure, PNG 600 dpi + PDF

The figure was rasterized (PNG downscaled 4x with PIL; PDF via pdftoppm at 150 dpi), transferred and inspected visually.
First render had two visible defects that metadata would not show (y labels 4,999/499/49 from integer truncation;
beta printed as 0.16); both fixed in 04_figure.R before the final render.

## Scripts and outputs (md5)

| md5 | file |
|---|---|
| 5d292c503806478bbcf2c0da78155ce9 | 01_data_envelope.R |
| cdd5694f4291ace36453aad98666fcca | 02_fit_contain.R |
| 26222ea6af039a726de0597e04302695 | 03_tables.R |
| a98b0b6bb87ed222c4135bed23b71d43 | 03b_origin_lines.R |
| d9939ecb21e84971e03e0c07e93f2b77 | 04_figure.R |
| 6ba91aceca6c8742348f7c254f6013d9 | PREREG_boundary_rule.md |
| 9612cca49562b24c13c7dd73539d24ee | out/analysis_frame_DATA.csv (471 plot-measures, no coordinates) |
| 0c637377cffbd63a19938fcc1896c91a | out/envelope_reproduction.csv |
| 418c63cd100d0a7e9253c9b211b941b4 | out/boundary_B1_DATA.csv |
| ec4a515762cd42beee628a541f1b3e84 | out/boundary_B2_DATA.csv |
| 96c1378912e4890669e569c94db0d3df | out/bootstrap_coefs.csv |
| 8d0c22af9a652c79e6c66e99552b85b8 | out/qr_lines.csv |
| a1381b6301f8bf48b6197b5cb6042f3e | out/qr_bands.csv |
| 26af5713f6dcd1e14b13df8a1a5c6420 | out/origin_model.csv |
| a416df81e1610a7981bdb47d6626d18f | out/containment_summary.csv |
| 628c3dfde41494fd82eac28942ec20c9 | out/containment_montecarlo.csv |
| 079cada0f7fd433a92c9d6438001ce4c | out/qr_results.rds |
| 562fa5a278825e7c35a2f338b7dbdd97 | out/Fig_selfthinning_QR.png (4110 x 2787 px, 600 dpi, 174 x 118 mm) |
| 52cf5cd71621c39d9dacee9c065dd86b | out/Fig_selfthinning_QR.pdf |
