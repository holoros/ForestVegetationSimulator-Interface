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

The equation gains one term, a planted level shift b9, and the planted terms now use the fitted form.

```
ddbh = exp(b0 + b1 log(dbh+1) + b2 dbh + b3 bal^2/log(dbh+5) + b4 log(bal+1) + b5 log(cr)
           + b6 sqrt(ba*dbh) + b7 planted*min(dbh, 45) + b8 log(byi) + b9 planted) * 1.48254,  clipped to [0, 4]
dht  = exp(b0 + b1 log(ht+1)  + b2 ht  + b3 bal^2/log(ht+5)  + b4 log(bal+1) + b5 log(cr)
           + b6 sqrt(ba*ht)  + b7 planted*min(ht, 20)  + b8 log(byi) + b9 planted) * 1.030,    clipped to [0, 2]
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

## What you should know before merging

The level shift and the data-source random intercept compete for the same contrast. The PSP and KMR PSP sources are entirely planted, and the FIA and most DOFAW records are natural. So the population-average form, which is what FVS-HI evaluates, is biased by origin on the fitting data.

**Diameter increment, with the deployed correction factor:**
- Natural records: predicted 1.45 cm yr⁻¹ against 0.56 observed.
- Planted records: predicted 1.32 against 2.10 observed.

**Height increment:**
- Natural records: overpredicted by 0.33 m yr⁻¹.
- Planted records: underpredicted by 1.04 m yr⁻¹.

**Validation.** On the 23-plot validation, projected basal area runs 20.7 m² ha⁻¹ high on natural plots and 13.5 m² ha⁻¹ low on planted plots.

**Next step.** The manuscript's first priority is a calibration of the population-average increment that is specific to each origin. Until that calibration exists, treat FVS-HI koa growth as biased high in natural stands and low in plantations.

**The 2 m height clip.** It binds more often under the refit, because the planted level shift raises planted height increment by a factor of 2.8 at small heights.

## Deposit patches

`patches/` holds unified diffs that take the two deposit R carriers from their 1.8.0 height-refit state to the origin refit.

- `HiGy_deposit_1.8.0-height_to_origin.diff`: the same changes as the repo HiGy.R above.
- `koa_prediction_functions_1.8.0-height_to_origin.diff`: `koa.dDBH.annual()` and `koa.dHT.annual()` get the refit vectors and b9, the linear height planted term and `CF_dDBH` 1.48254.

The Python engine patch (`patch_origin.py`) and the regenerated projections are in the firebreather job `koa_origin_20260916`. That patch also covers the origin recode, the Stage 1 and 2 refit, ingrowth, and validation truncation before thinning.

## Parity test

```
KOA_HIGY=fvsOL/inst/extdata/HiGy.R KOA_KPF=/path/to/koa_prediction_functions.R \
  Rscript dev/validation/koa_origin_refit_20260916/parity/parity_increment.R
```

On a 540-point grid, the test compares `ddbh()`, `dht()`, `koa.dDBH.annual()` and `koa.dHT.annual()` against the patched Python engine. The grid covers both origins, DBH 2 to 70 cm, BAL 0 to 30 m² ha⁻¹, basal area 5 to 60 m² ha⁻¹, CR 0.3 and 0.7, and BYI 50 to 813 Mg ha⁻¹.

All four functions agree to 5 × 10⁻¹⁶. The results are in `parity/parity_increment_results.csv`.

## Open items

1. **Origin-specific calibration.** The population-average increment still needs its origin-specific calibration, as described above.
2. **Deposit release.** Deposit 1.8.0 needs both the height and origin patches merged and a release cut.
3. **Survival.** FVS-HI still carries the published survival equation as a rate. The manuscript deploys a three-stage mortality structure instead (Section 2.6).
