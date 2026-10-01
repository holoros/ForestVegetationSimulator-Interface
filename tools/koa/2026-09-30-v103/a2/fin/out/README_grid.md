# Koa yield grid v103, read me before use (30 September 2026, INTERNAL, not yet sent)

Files: koa_yield_grid_200yr.csv (16 site by planting density cells, ages 1 to 200), koa_yield_grid_diagnostics.csv, yield_grid_compare.csv ((v103 - v102)/v102 against the 24 September grid). Engine engine_v103 (weighted BAL, MORT_CAL 2.54275), deterministic point path, planted origin.

Four caveats hold for every cell.

1. Age is years since the start of the projection harness, not years since planting. Age 1 already carries QMD 2.85 in (7.2 cm), height 18 to 19 ft (5.5 to 5.9 m) and a largest stem of 16.4 cm. Shift the age axis before matching to rotation ages from planting.
2. The engine caps DBH at 69.7 cm. On the Excellent and Good cells the largest stems reach the cap at ages 27 to 34 (Low Feasibility 45 to 49), and DBHMAX is 63.6 to 69.7 cm by age 40, so the cap binds inside the 40 to 52 yr decision window. Capped stems stop growing while mortality continues, which contributes to the BA decline after the peak (27.6 to 44.1 percent from peak to age 200).
3. VOL is m³ ha⁻¹ (metric) while BA_ft2ac, TPA, QMD_in and HT_ft are imperial. VBAR_cuft_per_ft2 is the imperial volume to basal area ratio. Convert VOL with 1 m³ ha⁻¹ = 14.29 ft³ ac⁻¹.
4. Low Feasibility (BYI 120) sits below the planted data of the main PSP installations (minimum BYI 158); only the KMR PSP installation (BYI 109 to 191) and Kulani 12 lie below that. Planted projections beyond about age 18 are extrapolations for every cell, since the planted records are almost all younger than 18 yr.

The Reineke column in the diagnostics file is the slope fitted over the grid trajectory and is not comparable with the Bakuzis slopes of Table 8.
