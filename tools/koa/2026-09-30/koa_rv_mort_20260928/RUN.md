# RUN.md koa_rv_mort_20260928

Date: 2026-09-28. Host: ifm-kershaw (firebreather), Debian 11. R 4.5.1 (base, jsonlite). Python 3.9.2, numpy 2.0.2, pandas 2.3.3 (no scipy).
Seeds: a1 set.seed(20260928); a2 regen_m1 convention (default_rng(42), CF generator 42+7919, joint-draw rows 0..499 of the seed 20260918 table); a2b and a3 bootstrap default_rng(20260928).
Wall time: a1 about 11 min (2,000 plot-cluster resamples x 24 fits); a2 955 s (500 replicates x 23 plots); a2b about 3 min; a3/a3b under 1 min; a5 under 1 min.

What was run
1. a1_stage12.R on inputs/plot_intervals_origin_span.csv (copy of koa_origin_20260916/out_span/plot_intervals_origin.csv) with reproduction gate against inputs/stage1_fit.json (copy of engine_v102/out_stage1/stage1_fit.json): S1 4.4e-15, S2 4.4e-16.
2. PYTHONDONTWRITEBYTECODE=1 python3 a2_mc_validation.py 500, engine imported read only from ~/jobs/koa_v102_20260918/track2/engine_v102 via regen_m1; gate vs out_m1/validation_M1.csv 3.6e-15. Then a2b_coverage.py.
3. a3_culmination.py, a3b_interior_strict.py on engine_v102/out_m1 replicate and point trajectories and koa_calint_20260926/out/traj_calint_planted.csv.
4. Item 4 not run, HI_TREE.csv / HI_COND.csv not on firebreather.
5. a5_stocking_prep.py (trajectory export only), Baker and Scowcroft (2005) PDF not available.
Nothing in any other job directory was modified.

Input md5
d00f61597f139c6629f5349b8296bd59  inputs/plot_intervals_origin_span.csv
ad177efbfd5172959a3b5b03574a8e72  inputs/stage1_fit.json
d3cc60b37092eb4d59a2390ce921307d  engine_v102/out_joint/K_joint_draws.csv
9691ae0f33d8c8575ebc945c0b714332  engine_v102/koa_params.py
35b2a4222c86d108d61147c1a4024709  engine_v102/koa_equations.py
06c9e598f3930833985c656ca398940d  engine_v102/threestage.py
2f09ebb3a770809fb0169b0346385cb0  engine_v102/regen_m1.py
28372ee32b112d220ab7ce8208670d3d  engine_v102/koa_longterm_validation.py
b10a86dbc9f4ff96b5b9abe0cd6d0c36  engine_v102/koa_projector.py
24e39fb29e0dde5e2a674344aaad3397  engine_v102/out_m1/reps_evenaged_M1.csv
7b0fc142a5c38caaa51679e1242c214a  engine_v102/out_m1/uneven_aged_reps_M1.csv
796dee662fa1d4ae014ca7f3d7b1b14f  engine_v102/out_m1/traj_M1.csv
a8a62e27dde89553052bfa54237d6923  engine_v102/out_m1/uneven_aged_traj_M1.csv
82e7793e002f03fe92ebf7a823d52333  engine_v102/out_m1/validation_M1.csv
14d012a36cb81f962835a6919e7c7d30  koa_calint_20260926/out/traj_calint_planted.csv
df665f7a1c81c6629818f9d6c3e8a49f  koa_density_20260925/out/SC_trajectories.csv

Restricted data: AK_PLT_GEO.csv is read inside the engine for BYI and origin maps only; no coordinate was printed or written. out_a2/reps_validation.csv and point_*.csv carry plot keys and are not downloaded.

Zenodo: staged via main session
GitHub: pending Aaron's PAT approval
