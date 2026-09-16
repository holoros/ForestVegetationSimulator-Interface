# Koa increment refit after the stand-origin correction (September 16, 2026)

Ben, this folder documents the second production change on this branch. It changes the koa diameter and height increment functions in `fvsOL/inst/extdata/HiGy.R`. The height refit in `../koa_height_refit_20260916/` is unchanged by it.

## Why the refit was needed

The deposit coded all 32 plantation permanent sample plot (PSP) installations as natural. That coding reached the plot, increment and survival tables. Plot establishment records show that 31 of the 32 are plantations:

- Keauhou: stratum Planted or Rx Plant, planting dates from 2006 to 2021.
- Pahala: planted in 2013 at 12 × 5.2 m spacing.

PSP 122, which regenerated after scarification, stays natural. The reduced coding table is `psp_origin_coding.csv`: installation, new origin, and the years whose intervals were censored as thinning removals.

**Effect on the increment data.** The recode moves 4,833 of the 6,209 diameter increment records and 3,995 of the 5,012 height increment records into the planted class. Before the recode, those counts were 378 and 337. Observed mean annual diameter increment is 2.10 cm yr⁻¹ in planted records against 0.56 in natural records.

**Thinning removals.** The master database records thinned stems as dead. Those removals are censored in every mortality fit. They do not enter the increment fits.

## What changed in HiGy.R

The equation gains one term, a planted level shift b9, the planted terms now use the fitted form, and both increments carry an origin calibration factor (below).

```
ddbh = exp(b0 + b1 log(dbh+1) + b2 dbh + b3 bal^2/log(dbh+5) + b4 log(bal+1) + b5 log(cr)
           + b6 sqrt(ba*dbh) + b7 planted*min(dbh, 45) + b8 log(byi) + b9 planted) * 1.48254 * k_ddbh[origin],  clipped to [0, 4]
dht  = exp(b0 + b1 log(ht+1)  + b2 ht  + b3 bal^2/log(ht+5)  + b4 log(bal+1) + b5 log(cr)
           + b6 sqrt(ba*ht)  + b7 planted*min(ht, 20)  + b8 log(byi) + b9 planted) * 1.030 * k_dht[origin],     clipped to [0, 2]
```

1. **Parameters.** Both `ddbh.parm` and `dht.parm` carry the refit vector and a new `b9` column.
   - `ddbh()` and `dht()` take `b9` with a default of 0, so old callers still run.
   - `calc_ddbh()` and `calc_dht()` pass `b9` through.
   - The base rows (no BYI) keep the site-row vector with b8 = 0, as before. No separate no-BYI increment fit exists.
2. **Height planted term.** It is now linear, `b7 * planted * pmin(ht, 20)`, which is the fitted form. The repo previously carried `sqrt(planted * pmin(ht, 20))`, which never matched the fit.
3. **Diameter planted term.** Its argument is now clamped at 45 cm, where the repo copy used 40.
   - After the recode, 45 cm is the 99th percentile of planted diameters in the fitting frame (44.7 cm; maximum 57.0 cm).
   - The Zenodo deposit already used 45.
4. **Diameter correction factor.** It is now the marginal factor 1.48254, which is exp(0.5 × (0.750² + 0.475²)) using the source and installation standard deviations of the refit.
   - The repo copy carried 1.026, a value the deposit withdrew in August because nothing supports it.
   - The deposit carried 1.369, the marginal factor of the published fit.
   - The height factor stays at 1.030.

## Coefficients (V3, deployed)

| Term | ΔDBH est. | SE | ΔHT est. | SE |
|---|---|---|---|---|
| b0 | −2.0972 | 0.7045 | −4.0426 | 0.7834 |
| b1 | 0.3106 | 0.0326 | 0.9239 | 0.0831 |
| b2 | −0.00853 | 0.00257 | −0.1100 | 0.0104 |
| b3 | −0.00197 | 0.000394 | −0.00122 | 0.000236 |
| b4 | −0.2900 | 0.0208 | −0.0359 | 0.0238 |
| b5 | −0.2599 | 0.2345 | −1.5423 | 0.2365 |
| b6 | −0.0105 | 0.00284 | 0.0487 | 0.00382 |
| b7 | −0.0258 | 0.00226 | −0.1196 | 0.00644 |
| b8 | 0.3108 | 0.0820 | 0.2471 | 0.0799 |
| b9 | 0.4018 | 0.2357 | 1.0236 | 0.2347 |

The four fitted variants (V0 to V3) are in `koa_increment_variants_coefficients.csv` and `koa_increment_variants_stats.csv`. `koa_increment_fit_statistics.csv` gives R², RMSE, MAE and bias by origin, both conditional and population-average, with and without the correction factor.

The ingrowth refit (Eq. 6) is in `koa_ingrowth_origin_coefficients.csv`. FVS-HI does not carry it.

## Origin calibration (second commit)

The population-average form is biased by origin on the fitting data, because the level shift and the data-source random intercept compete for the same contrast. The PSP and KMR PSP sources are entirely planted, while the FIA and most DOFAW records are natural.

Uncalibrated, with the deployed correction factor:

- **Diameter increment.** Natural records are predicted at 1.45 cm yr⁻¹ against 0.56 observed. Planted records are predicted at 1.32 against 2.10.
- **Height increment.** Natural records are overpredicted by 0.33 m yr⁻¹, and planted records are underpredicted by 1.04 m yr⁻¹.

`ddbh()` and `dht()` therefore now multiply by an origin calibration factor after the correction factor. The factor is the ratio of observed to predicted total annual increment within origin (`koa_increment_origin_calibration.csv`). The 95% intervals come from 2,000 installation-cluster bootstrap resamples.

| | natural | planted |
|---|---|---|
| ΔDBH | 0.38479 (0.297 to 0.470) | 1.58591 (1.447 to 1.725) |
| ΔHT | 0.52127 (0.319 to 0.645) | 2.65956 (2.430 to 2.857) |

**Effect on fit.** Population-average R² rises from 0.109 to 0.359 for diameter increment and from −0.342 to 0.270 for height increment.

**Leave-one-installation-out check.** The equation and the multipliers were both refit with each installation held out.
- Calibrated R² is 0.347 for diameter and 0.246 for height.
- Held-out mean bias is within 0.03 cm yr⁻¹ and 0.01 m yr⁻¹ in both origins.

## What you should know before merging

1. **The multipliers are network corrections as much as origin corrections.** Held out by data source (`koa_increment_multiplier_leave_one_source_out.csv`):
   - The DOFAW plantation grows at 0.32 times the diameter increment predicted by the planted multiplier of the other sources, and KMR at 1.15 times. The planted multiplier is in effect the PSP multiplier.
   - Held-out FIA natural records grow at 0.59 times their prediction, or 1.12 times when the equation is also refit without FIA.
   - Resampling the four sources gives diameter multiplier intervals of 0.27 to 1.08 (natural) and 0.51 to 1.81 (planted).
2. **The 2 m yr⁻¹ height clip binds more often.** Small planted trees on open sites reach it.
3. **The harness diameter ceiling acts per tree.** The planted 69.7 cm harness ceiling stops the largest planted trees growing by about age 35 in the manuscript projections. FVS-HI does not carry that ceiling.

## Natural mortality level (manuscript v98, engine only)

FVS-HI `HiGy.R` still carries the published survival equation as a rate and has no three-stage mortality, so **this section changes no FVS-HI code**. It documents the deployed Python engine and its R port (`HiGy.R` v0.5.x in the deposit engine folder).

1. **Stage 1/2 refit.** Four PSP intervals (119 to 122, 2019 to 2023) span the 2021 thinning without ending in it, so their removals were counted as deaths. With those censored too, the fit uses 290 of 326 intervals, 118 carrying mortality (`mortality_level/koa_stage12_coefficients_removal_span_censored.csv`). ln(SDI) on occurrence is +0.162, and the interval still excludes zero.
2. **Level factor.** Each natural interval is projected from its own tree list by the engine. The gated stand rate returns 42% of the observed deaths, so the natural rate is multiplied by **2.59367** (plot-cluster 95% interval 1.93 to 4.16; held-out installations 2.42 to 3.13). Planted stands keep 1.
3. **Rejected alternatives** (`mortality_level/koa_mortality_level_candidates_*.csv`):
   - A natural floor of 0.062 yr⁻¹ empties natural stands within 100 years (Reineke -3.41 to -3.50).
   - The planted factor of 3.60 moves planted validation survival from equivalent to 0.28 below observed and breaks site ordering.
4. **Effect.**
   - Natural 100-year Reineke slopes move from -0.52 to -0.75 to -0.97 to -1.21.
   - Natural validation survival error moves from -0.316 to -0.187, observed minus projected.
5. **R port.** `patches/HiGy_engine_0.5.0_to_0.5.1_mortality.diff` updates the Stage 1 constants and adds the factor to `koa_gate_rate()`. `parity/parity_mortality_gate.R` matches the engine at 0 difference on 128 points.

## Long-term trajectories and scenarios

`longterm/koa_trajectory_validation_by_horizon.csv` compares 15 plots with three or more measurements at every remeasurement, with and without the natural factor. On the four long natural DOFAW plots (also used for the factor):
- Survival error is -0.11 at 21 to 35 years, against -0.32 without the factor.
- The 52-year Kulani plantation is projected to hold more and larger stems than it carried.

`longterm/koa_behavior_scenarios.csv` covers initial density and thinning from below:
- The largest tree grows more slowly at higher density.
- Mean QMD does not fall with density, because density-dependent mortality removes the smallest stems.
- Thinning lowers total yield.

## Deposit patches

`patches/` holds unified diffs that take the two deposit R carriers from their 1.8.0 height-refit state to the origin refit.

- `HiGy_deposit_1.8.0-height_to_origin.diff`: the same changes as the repo HiGy.R above.
- `koa_prediction_functions_1.8.0-height_to_origin.diff`: `koa.dDBH.annual()` and `koa.dHT.annual()` get the refit vectors and b9, the linear height planted term, `CF_dDBH` 1.48254 and the origin calibration.

The Python engine patch (`patch_origin.py`) and the regenerated projections are in the firebreather job `koa_origin_20260916`. That patch also covers the origin recode, the Stage 1 and 2 refit, ingrowth, and validation truncation before thinning.

## Parity test

```
KOA_HIGY=fvsOL/inst/extdata/HiGy.R KOA_KPF=/path/to/koa_prediction_functions.R \
  Rscript dev/validation/koa_origin_refit_20260916/parity/parity_increment.R
```

On a 540-point grid, the test compares `ddbh()`, `dht()`, `koa.dDBH.annual()` and `koa.dHT.annual()` against the patched Python engine. The grid covers both origins, DBH 2 to 70 cm, BAL 0 to 30 m² ha⁻¹, basal area 5 to 60 m² ha⁻¹, CR 0.3 and 0.7, and BYI 50 to 813 Mg ha⁻¹.

All four functions agree to 9 × 10⁻¹⁶. The results are in `parity/parity_increment_results.csv`.

## Open items

1. **Planted mortality level.** Short planted intervals imply a rate about 3.6 times the deployed one, while the ten-year planted validation plots match it. Longer planted remeasurement, with removals and fill-in planting recorded separately, is needed.
2. **Stand-level calibration.** It should replace the source-level growth multipliers.
3. **Deposit release.** Deposit 1.8.0 needs the height, origin, calibration and mortality patches merged and a release cut. The deposit engine `HiGy.R` still carries the pre-origin increment block.
4. **FVS-HI survival.** FVS-HI still carries the published survival equation as a rate. Porting the three-stage structure (`koa_gate_rate()` and its helpers) is the route to matching the manuscript.
