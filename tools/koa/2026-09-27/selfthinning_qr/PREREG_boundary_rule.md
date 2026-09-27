# Pre-stated rules for the koa self-thinning quantile regression test

Written 27 September 2026 on firebreather after step 1 (data and envelope reproduction, no fitting) and
before any quantile regression was run. Step 1 output seen at that point: the analysis frame of 471 live
plot-measures, 147 plots and 101 installations, its composition by source and origin, and nothing else.

## Model and orientation
ln N = b0 + b1 ln QMD, N in stems ha-1 (live expansion factor sum), QMD in cm, linear quantile regression
(quantreg::rq, method br) at tau 0.95 and 0.99. Reineke orientation (density on size), because the
engine's own limiting line N = 10000 / (beta H_QMD)^2 is written in that orientation and both comparison
slopes (Reineke -1.605 and the engine's -2 / k_HD) are slopes of ln N on ln QMD.

## Data sets
- ALL: the 471 plot-measures of the C5 anchor set, QMD from the recorded plot-year column (like for like
  with the anchoring and with the Section 6 envelope). PRIMARY for the containment test.
- B1 boundary subset (primary boundary rule): ln QMD cut into 10 equal-count bins (type 7 quantile breaks,
  lowest included); within each bin keep plot-measures whose SDI = N (QMD / 25)^1.605 is at or above the
  bin's 90th percentile. Re-applied inside every bootstrap resample.
- B2 boundary subset (secondary): per installation (Data | Install), the one plot-measure of maximum SDI.
- ALL_live (sensitivity): ALL with QMD recomputed from live trees only.
- By origin: ALL split into Natural and Planted, and a pooled model with origin shift and slope interaction.

## Intervals
Installation-cluster percentile bootstrap, B = 2000, seed 20260927, installations resampled with replacement
(sample indices generated once, sequentially, in the master process). rq rank-inversion intervals
(summary.rq se = "rank") reported alongside for comparison.

## Containment criterion (fixed now)
Trajectories: deployed engine_v102 long-term trajectories (track3/derived/engine_v102_out_m1/trajectories.csv),
rep 0 (point projection) of every scenario and site class, ages 1 to 100; Monte Carlo reps summarised
separately. Contrast: variant B GRID_trajectories.csv, arm C3_fitted (beta 0.117), and C5_anchored as a
parity check, years 1 to 100 (1 to 200 reported as well).
- PASS: no rep-0 projected point lies above the ALL tau 0.99 point line.
- FAIL: any rep-0 projected point lies above the upper 97.5 percent bootstrap band of the ALL tau 0.99 line.
- In between (above the point line, inside the band): INDETERMINATE, reported as such.
- The tau 0.95 line is descriptive: by construction about 5 percent of observations lie above it, so
  projections touching it are not a failure. Exceedance is reported in stems ha-1 and in SDI at the
  projected QMD, with the age and site class where it is largest; projected points beyond the observed
  QMD range are flagged as extrapolation.
