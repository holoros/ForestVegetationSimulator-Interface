# PREREG-KOA-01 variant B result: fitted beta 0.117 against deployed anchored beta 0.16019

Run 26 September 2026 on firebreather, job `~/jobs/koa_prereg_B_beta_20260926/`.
Criteria were fixed in `2026-09-26_koa-refinement_PREREG.md` before this run and are not changed here.

## What was run

Two mortality arms of the deployed engine, selected through the engine's own configuration switch
(`run_candidates.project(..., engine=ARM)` -> `koa_mortality_garcia.stand_mortality` -> `engine_beta(engine)`).
No constant was edited and nothing in `~/jobs/koa_v102_20260918/` was modified.

| arm | engine | beta attribute | beta | status |
|---|---|---|---|---|
| C5 | `garcia_qmd_anchored` | `GARCIA_BETA_ANCHORED` | 0.16019053617304435 | DEPLOYED |
| C3 | `garcia_qmd` | `GARCIA_BETA` | 0.117 | fitted, evaluated |

The two arms share the state variable H_QMD, alpha, the A1 floor, Stage 3 allocation, the harness bounds
and the initial tree list. They differ only in beta.

Two grids were run under each arm.

1. Projection grid: the six origin by site-class rows of `run_candidates.SCEN`
   (natural and planted, BYI 100 Low, 264 Medium, 450 High), candidate M0, 200 years.
2. Density and thinning scenarios: the 13 rows of `track3/lt/scenarios.py` at BYI 264, 100 years.

## Fidelity checks

- `run_candidates.validate_copy()` against the deposited `koa_projector.project_psp`: max|diff| = 0.000e+00.
- Scenario hook parity with no thinning: passes at atol 1e-10.
- C5 arm of this run against the deployed record `track3/lt/out/SC_summary.csv`, all 13 scenarios and all
  compared fields: max|diff| = 0.000e+00. The C5 column below is the deployed configuration reproduced exactly.

## Uncertainty

Every projected quantity in the tables below is an exact deterministic engine output. It carries no sampling
interval, because these are point projections from fixed parameters, not estimates from a resampled quantity.
The parameter that separates the two arms does carry one: beta = 0.117 with a plot-cluster percentile bootstrap
95 percent interval 0.057 to 0.159 (B = 2,000, seed 20260904). The anchored value 0.16019 carries no interval;
it is the 99th percentile of the observed N x H_QMD^2 envelope, a calibration constant, and it sits above the
upper bootstrap limit 0.159. A Monte Carlo comparison of the two arms would not be symmetric, because
`regen_m1.set_params` perturbs alpha and holds both betas fixed (koa_params IMPL-13), so no Monte Carlo
interval is reported here rather than one that would misrepresent what was perturbed.

## Projection grid, ages 20, 40, 60 and 100

QMD cm, BAPH m2 ha-1, TPH stems ha-1, VOL m3 ha-1, SDI dimensionless. Exact engine outputs.

| arm | origin | site | age | QMD | BAPH | TPH | VOL | SDI |
|---|---|---|---|---|---|---|---|---|
| C5 anchored | natural | Low | 20 | 16.33 | 8.86 | 423.2 | 35.1 | 213.6 |
| C5 anchored | natural | Low | 40 | 22.98 | 14.54 | 350.8 | 73.5 | 306.4 |
| C5 anchored | natural | Low | 60 | 29.05 | 19.10 | 288.2 | 112.8 | 366.7 |
| C5 anchored | natural | Low | 100 | 39.93 | 24.29 | 194.0 | 173.0 | 411.3 |
| C5 anchored | natural | Medium | 20 | 19.38 | 12.02 | 407.4 | 57.4 | 270.8 |
| C5 anchored | natural | Medium | 40 | 28.64 | 19.39 | 301.0 | 120.7 | 374.3 |
| C5 anchored | natural | Medium | 60 | 36.81 | 24.06 | 226.1 | 174.4 | 420.7 |
| C5 anchored | natural | Medium | 100 | 50.49 | 29.04 | 145.0 | 249.0 | 448.2 |
| C5 anchored | natural | High | 20 | 21.65 | 14.10 | 383.0 | 77.5 | 304.0 |
| C5 anchored | natural | High | 40 | 32.63 | 21.95 | 262.5 | 157.8 | 402.5 |
| C5 anchored | natural | High | 60 | 42.09 | 26.41 | 189.8 | 219.5 | 437.9 |
| C5 anchored | natural | High | 100 | 57.45 | 31.00 | 119.6 | 300.5 | 454.6 |
| C5 anchored | planted | Low | 20 | 26.82 | 39.62 | 701.4 | 232.3 | 785.0 |
| C5 anchored | planted | Low | 40 | 38.17 | 51.92 | 453.7 | 378.1 | 894.8 |
| C5 anchored | planted | Low | 60 | 46.86 | 58.11 | 336.9 | 473.8 | 923.6 |
| C5 anchored | planted | Low | 100 | 56.06 | 61.62 | 249.7 | 525.9 | 912.5 |
| C5 anchored | planted | Medium | 20 | 32.46 | 46.89 | 566.7 | 329.1 | 861.7 |
| C5 anchored | planted | Medium | 40 | 46.33 | 58.03 | 344.3 | 498.7 | 926.6 |
| C5 anchored | planted | Medium | 60 | 53.32 | 61.56 | 275.7 | 549.8 | 929.9 |
| C5 anchored | planted | Medium | 100 | 62.14 | 61.89 | 204.1 | 569.2 | 880.0 |
| C5 anchored | planted | High | 20 | 36.01 | 50.62 | 497.0 | 402.5 | 892.8 |
| C5 anchored | planted | High | 40 | 49.90 | 59.82 | 305.9 | 559.7 | 927.6 |
| C5 anchored | planted | High | 60 | 57.26 | 63.36 | 246.1 | 612.5 | 930.4 |
| C5 anchored | planted | High | 100 | 64.61 | 60.63 | 184.9 | 594.9 | 848.9 |
| C3 fitted | natural | Low | 20 | 16.33 | 8.86 | 423.2 | 35.1 | 213.6 |
| C3 fitted | natural | Low | 40 | 22.98 | 14.55 | 350.9 | 73.5 | 306.4 |
| C3 fitted | natural | Low | 60 | 29.03 | 19.13 | 289.0 | 113.0 | 367.4 |
| C3 fitted | natural | Low | 100 | 39.91 | 24.33 | 194.5 | 173.2 | 412.1 |
| C3 fitted | natural | Medium | 20 | 19.23 | 12.24 | 421.7 | 58.3 | 276.7 |
| C3 fitted | natural | Medium | 40 | 27.75 | 21.00 | 347.2 | 129.7 | 410.6 |
| C3 fitted | natural | Medium | 60 | 35.03 | 27.37 | 284.0 | 196.4 | 488.0 |
| C3 fitted | natural | Medium | 100 | 47.62 | 33.58 | 188.6 | 285.3 | 530.4 |
| C3 fitted | natural | High | 20 | 21.17 | 14.81 | 420.8 | 80.8 | 322.1 |
| C3 fitted | natural | High | 40 | 30.67 | 25.50 | 345.1 | 180.5 | 479.2 |
| C3 fitted | natural | High | 60 | 38.53 | 32.77 | 281.2 | 267.5 | 562.8 |
| C3 fitted | natural | High | 100 | 51.92 | 39.26 | 185.5 | 375.2 | 599.3 |
| C3 fitted | planted | Low | 20 | 24.95 | 46.56 | 952.0 | 267.2 | 949.2 |
| C3 fitted | planted | Low | 40 | 33.42 | 67.53 | 769.6 | 474.7 | 1226.5 |
| C3 fitted | planted | Low | 60 | 39.52 | 79.99 | 652.2 | 626.0 | 1359.9 |
| C3 fitted | planted | Low | 100 | 47.56 | 85.74 | 482.6 | 718.5 | 1354.8 |
| C3 fitted | planted | Medium | 20 | 29.25 | 57.90 | 861.7 | 394.4 | 1108.6 |
| C3 fitted | planted | Medium | 40 | 39.02 | 79.26 | 662.8 | 652.8 | 1354.3 |
| C3 fitted | planted | Medium | 60 | 44.57 | 87.72 | 562.2 | 764.5 | 1422.1 |
| C3 fitted | planted | Medium | 100 | 53.16 | 92.13 | 415.0 | 845.2 | 1393.1 |
| C3 fitted | planted | High | 20 | 31.81 | 64.22 | 808.3 | 493.1 | 1189.5 |
| C3 fitted | planted | High | 40 | 41.80 | 84.08 | 612.8 | 761.8 | 1398.2 |
| C3 fitted | planted | High | 60 | 47.37 | 92.47 | 524.8 | 875.4 | 1463.6 |
| C3 fitted | planted | High | 100 | 55.83 | 94.86 | 387.5 | 936.0 | 1407.0 |

### Realized maxima over the projection

| arm | origin | site | max BAPH 0-100 | age | max SDI 0-100 | age | max BAPH 0-200 | max SDI 0-200 |
|---|---|---|---|---|---|---|---|---|
| C5 anchored | natural | Low | 24.29 | 100 | 411.3 | 100 | 25.43 | 411.6 |
| C5 anchored | natural | Medium | 29.04 | 100 | 448.2 | 98 | 29.92 | 448.2 |
| C5 anchored | natural | High | 31.00 | 100 | 455.0 | 96 | 31.69 | 455.0 |
| C5 anchored | planted | Low | 61.62 | 100 | 925.8 | 78 | 61.67 | 925.8 |
| C5 anchored | planted | Medium | 63.31 | 72 | 932.4 | 72 | 63.31 | 932.4 |
| C5 anchored | planted | High | 64.06 | 77 | 932.6 | 58 | 64.06 | 932.6 |
| C3 fitted | natural | Low | 24.33 | 100 | 412.1 | 100 | 25.47 | 412.4 |
| C3 fitted | natural | Medium | 33.58 | 100 | 530.7 | 96 | 34.48 | 530.7 |
| C3 fitted | natural | High | 39.26 | 100 | 601.0 | 92 | 39.97 | 601.0 |
| C3 fitted | planted | Low | 85.74 | 100 | 1380.7 | 72 | 85.85 | 1380.7 |
| C3 fitted | planted | Medium | 92.93 | 88 | 1435.9 | 74 | 92.93 | 1435.9 |
| C3 fitted | planted | High | 95.75 | 79 | 1475.2 | 73 | 95.75 | 1475.2 |

## Density and thinning scenarios, BYI 264, realized maxima over 100 years

| arm | group | origin | scenario | Reineke slope | max BAPH | age | max SDI | age |
|---|---|---|---|---|---|---|---|---|
| C5 anchored | density | natural | 250 stems | -0.71 | 20.58 | 100 | 316.5 | 100 |
| C5 anchored | density | natural | 500 stems | -1.01 | 29.04 | 100 | 448.2 | 98 |
| C5 anchored | density | natural | 1000 stems | -1.44 | 31.98 | 100 | 480.3 | 65 |
| C5 anchored | density | natural | 2000 stems | -1.68 | 33.39 | 100 | 521.2 | 13 |
| C5 anchored | density | planted | 300 stems | -0.83 | 43.43 | 80 | 638.0 | 68 |
| C5 anchored | density | planted | 600 stems | -1.12 | 56.07 | 82 | 831.3 | 67 |
| C5 anchored | density | planted | 1200 stems | -1.47 | 63.31 | 72 | 932.4 | 72 |
| C5 anchored | density | planted | 2400 stems | -1.69 | 67.11 | 79 | 996.7 | 19 |
| C5 anchored | thinning | planted | Unthinned | -1.47 | 63.31 | 72 | 932.4 | 72 |
| C5 anchored | thinning | planted | Thinned to 500 at age 8 | -1.18 | 54.86 | 82 | 804.3 | 66 |
| C5 anchored | thinning | planted | Thinned to 500 at 8 and 250 at 20 | -1.47 | 43.39 | 75 | 647.4 | 19 |
| C5 anchored | thinning | natural | Unthinned | -1.01 | 29.04 | 100 | 448.2 | 98 |
| C5 anchored | thinning | natural | Thinned to 250 at age 15 | -1.00 | 23.25 | 100 | 352.5 | 97 |
| C3 fitted | density | natural | 250 stems | -0.71 | 20.58 | 100 | 316.5 | 100 |
| C3 fitted | density | natural | 500 stems | -0.80 | 33.58 | 100 | 530.7 | 96 |
| C3 fitted | density | natural | 1000 stems | -1.02 | 49.35 | 100 | 793.7 | 92 |
| C3 fitted | density | natural | 2000 stems | -1.45 | 55.55 | 100 | 864.6 | 65 |
| C3 fitted | density | planted | 300 stems | -0.78 | 45.82 | 83 | 677.7 | 70 |
| C3 fitted | density | planted | 600 stems | -0.88 | 68.71 | 91 | 1059.0 | 69 |
| C3 fitted | density | planted | 1200 stems | -1.09 | 92.93 | 88 | 1435.9 | 74 |
| C3 fitted | density | planted | 2400 stems | -1.43 | 108.39 | 90 | 1663.4 | 48 |
| C3 fitted | thinning | planted | Unthinned | -1.09 | 92.93 | 88 | 1435.9 | 74 |
| C3 fitted | thinning | planted | Thinned to 500 at age 8 | -0.98 | 64.37 | 88 | 982.4 | 58 |
| C3 fitted | thinning | planted | Thinned to 500 at 8 and 250 at 20 | -1.52 | 45.14 | 66 | 730.4 | 19 |
| C3 fitted | thinning | natural | Unthinned | -0.80 | 33.58 | 100 | 530.7 | 96 |
| C3 fitted | thinning | natural | Thinned to 250 at age 15 | -0.99 | 23.70 | 100 | 360.3 | 96 |

Per-age scenario values (QMD, D100, TPH, BAPH, VOL, SDI, total yield, MAI at 20, 40, 60, 100) are in
`out/SC_summary.csv`, with the full annual series in `out/SC_trajectories.csv`.

## Envelope comparison

Observed maxima: BAPH 76.0621 m2 ha-1, SDI 1453.4673 (the pre-registered F5 gate).

| arm | grid max BAPH | vs observed | grid max SDI | vs observed | scenario max BAPH | vs observed | scenario max SDI | vs observed |
|---|---|---|---|---|---|---|---|---|
| C5 anchored | 64.06 | -15.78% | 932.6 | -35.84% | 67.11 | -11.77% | 996.7 | -31.42% |
| C3 fitted | 95.75 | +25.89% | 1475.2 | +1.49% | 108.39 | +42.50% | 1663.4 | +14.44% |

Cells and scenarios that breach the envelope, C3 fitted beta only (C5 breaches nothing, 0 of 6 grid cells and
0 of 13 scenarios on both quantities):

| grid or scenario | row | max BAPH | vs observed | max SDI | vs observed |
|---|---|---|---|---|---|
| grid | planted Low | 85.74 | +12.72% | 1380.7 | -5.01% |
| grid | planted Medium | 92.93 | +22.17% | 1435.9 | -1.21% |
| grid | planted High | 95.75 | +25.89% | 1475.2 | +1.49% |
| scenario | density planted 1200 stems | 92.93 | +22.17% | 1435.9 | -1.21% |
| scenario | density planted 2400 stems | 108.39 | +42.50% | 1663.4 | +14.44% |
| scenario | thinning planted Unthinned | 92.93 | +22.17% | 1435.9 | -1.21% |

## Verdict against the pre-registered criterion

B is NOT adopted. The fitted beta 0.117 leaves the observed density envelope: basal area reaches
95.75 m2 ha-1 on the planted High grid cell (+25.89 percent above the observed 76.06) and 108.39 m2 ha-1 in the
planted 2,400 stems scenario (+42.50 percent), and stand density index reaches 1,475.2 on the planted High grid
cell (+1.49 percent above the observed 1,453.5) and 1,663.4 in the planted 2,400 stems scenario (+14.44 percent).
The deployed anchored beta stays inside on every row, peaking at 67.11 m2 ha-1 (-11.77 percent) and SDI 996.7
(-31.42 percent). This is the outcome the pre-registration recorded as expected, so it is reported as a
sensitivity and not written up as a discovery. Beta was not tuned and the run stops here.

## What this does and does not settle

It settles that the deployed anchoring is what holds the projections inside the envelope, and that the fitted
value does not hold them there. It does not settle the circularity noted in Section 6 of the supplement.
Containment under C5 is still being checked against the same 99th-percentile envelope that beta was anchored to,
and the result above cannot break that circle because it uses the same envelope as the criterion. What would
settle it is an independent containment target, for example held-out plot-measures not used in the anchoring
percentile, or a Reineke maximum-size-density line fitted to the boundary plots by quantile regression with its
own interval, tested against projections from both arms.

## Files

- `~/jobs/koa_prereg_B_beta_20260926/grid.py`, `scen.py`, `run.sh`, `run.log`
- `~/jobs/koa_prereg_B_beta_20260926/out/GRID_summary.csv`, `GRID_trajectories.csv`
- `~/jobs/koa_prereg_B_beta_20260926/out/SC_summary.csv`, `SC_trajectories.csv`, `SC_removals.csv`
- `~/jobs/koa_prereg_B_beta_20260926/out/exceedance.txt`
