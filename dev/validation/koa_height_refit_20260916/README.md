# Koa static height refit for FVS-HI (September 16, 2026)

Ben, this folder documents the one production change on this branch, the refit of the koa static height equation in `fvsOL/inst/extdata/HiGy.R`. It also carries the matching patches for the Zenodo deposit files, the coefficient tables and a stress test. The same vector is printed as Table 3 of the koa growth and yield manuscript, and every projection in manuscript v94 was generated with it. Nothing here touches the increment, crown or survival code.

## What changed in HiGy.R

The equation form is unchanged.

HT = (a0 + a1 × BYI/100) × (1 − exp(−b × DBH))^c × exp(g1 × ln(BA + 1) + g2 × rDBH), floored at 1.37 m.

The refit does change three things.

1. **The relative diameter is now rDBH = DBH / DBH.max, bounded at 1.** DBH.max is the largest live DBH on the plot at that measurement. The retired vector used DBH / QMD, which the deposited data do not carry. On the deposited data that vector returns a population-average R² of 0.318, against 0.790 for the refit.
2. **Both parameter rows were replaced.**
   - The `site` row is the Table 3 vector.
   - The `base` row is a separately fitted form without BYI, used when `byi` is NA or 0.
3. **`pred_ht()` now requires `dbh.max`.** The old signature would otherwise silently fall back to the retired DBH/QMD definition.
   - `calc_ht()` now computes `dbh.max` per plot from the tree list and passes it on.
   - `pred_ht()` also floors negative `dbh` and `ba` at zero, so it can no longer return NaN.

The diff to `HiGy.R` is 18 lines. Each change carries a dated comment.

## Coefficients

| Row | a0 | a1 | b | c | g1 | g2 |
|---|---|---|---|---|---|---|
| site (Table 3) | 30.1882 | 1.42629 | 0.0184009 | 0.817994 | 0.0511083 | −0.35086 |
| SE | 1.3587 | 0.1440 | 0.000936 | 0.01101 | 0.004951 | 0.01554 |
| base (no BYI) | 31.8661 | 0 | 0.0185562 | 0.801602 | 0.0652061 | −0.329508 |
| retired (DBH/QMD) | 19.832 | 0.106 | 0.044 | 0.863 | −0.198 | 0.479 |

The refit was fitted in nlme with a random intercept on a0 by data source and installation. It used 9,829 live-tree records that carry a height and a BYI, on 143 installations. Its fit statistics are below.

| Level | R² | RMSE (m) | Bias (m) |
|---|---|---|---|
| Conditional | 0.863 | 1.91 | +0.045 |
| Population average | 0.790 | 2.37 | +0.224 |
| Leave one installation out | 0.795 | 2.34 | +0.040 |

Population-average predictions pass regression-based equivalence tests (Robinson et al., 2005) at regions of ±25%. The tests used an installation-cluster bootstrap with 5,000 resamples.
- **Mean bias:** +0.22 m, 90% interval −0.08 to +0.52.
- **Slope:** 0.92, 90% interval 0.87 to 0.97.

The files in this folder are:
- `koa_height_refit_coefficients.csv`: estimates, SEs, t, P and Wald intervals, beside the retired values.
- `koa_height_refit_vcov.csv`: the fixed-effect covariance matrix, for Monte Carlo draws.
- `koa_height_base_coefficients.csv`: the base row.

## Deposit patches

`patches/` holds unified diffs from Zenodo deposit 1.7.1 to the planned 1.8.0 for the two R carriers.

- **`HiGy_deposit_1.7.1_to_1.8.0.diff`:** the same height change, applied to the annotated deposit copy of HiGy.R.
- **`koa_prediction_functions_1.7.1_to_1.8.0.diff`:** changes to `koa.HT()`.
  - It uses the refit vector, with an updated header documenting the fit.
  - It takes `DBH.max`. A single-tree call without it is refused, because the default `max(DBH)` would silently give rDBH = 1. A vector call without it treats DBH as one plot's live list.
  - It floors negative DBH and BAPH at zero.
  - `QMD` stays in the signature but is no longer used.
- **Other changes in `koa_prediction_functions.R`:** `koa.project()` passes `DBH.max = DBH` for its single cohort, and its planted diameter ceiling moves from 60 to 69.7 cm to match the projection engine.

Apply them with `patch -p1` from the deposit root, or read them as a checklist. The Python engine patch (`patch_engine.py`) and the regenerated projections are in the firebreather job `koa_redteam_20260916`, not in this repository.

## Stress test

`stress/stress_R_height.R` sources `HiGy.R` and `koa_prediction_functions.R` from `KOA_RDIR`. It compares them with the patched Python engine on a grid of 1,890 points (`ht_grid_python.csv.gz`, read from `KOA_STRESS_DIR`) and runs 18 checks. The results are in `stress_R_height_results.csv`.

```
KOA_RDIR=/path/to/deposit-1.8.0 Rscript stress/stress_R_height.R
KOA_RDIR=fvsOL/inst/extdata KOA_HIGY=HiGy.R ...   # this repo's HiGy.R, with koa_prediction_functions.R copied beside it
```

Sixteen checks pass against both the deposit copy and this repository's copy. `koa.HT()` and `pred_ht()` agree with the Python engine to 1 × 10⁻⁴ m on all 1,620 grid points with BYI above zero. Other passing checks cover:
- finite heights at or above 1.37 m everywhere
- ordering by BYI and by relative size
- bounding when DBH.max is below DBH
- refusal of the two silent-fallback calls
- NA and negative inputs
- per-plot DBH.max in `calc_ht()` on a two-plot list
- the site row matching Table 3

Two checks are flagged by design, and both belong in your review.

1. **The base row does not match the Python engine run without BYI.** They differ by up to 4.5 m (0 to 23%). The engine drops a1 from the site vector, while FVS-HI uses the separately fitted base form. No manuscript projection runs without BYI, so this affects only FVS-HI users who supply no BYI. The base form is the better-supported choice, since it was fitted for that case (population-average R² 0.796).
2. **Within a plot, height rises with DBH only up to about 86 cm when DBH.max is 90 cm.** The peak falls at 109 cm for DBH.max = 150 cm and at 134 cm for DBH.max = 250 cm.
   - **Cause:** the negative g2. Above those diameters the largest trees on a plot are predicted slightly shorter than the peak.
   - **Scope:** it does not arise under the harness ceilings (69.7 cm planted, 90 cm natural). It can arise on big-tree plots such as Kap and Mauka, where mean DBH is 79 to 108 cm.
   - **Options:** leave it as is, or cap rDBH's effect above about 90 cm. I would not change the fitted form without a refit.

A few behaviors are worth knowing.
- With `byi = NA` and site-row parameters passed by hand, `pred_ht()` uses the site a0 with no BYI term. `calc_ht()` avoids this by switching to the base row whenever BYI is NA or 0, so use `calc_ht()`.
- `calc_ht()` takes BYI from `stand$byi` by default, as before.
- `dbh.max` is computed from every row of `tree.data` for that plot. FVS-HI passes only live trees; if a caller passes dead records with a diameter, the maximum will be wrong.

## Projection robustness (engine side, for context)

A companion test reran 100-year point projections from the patched Python engine. It covered 50 runs:
- both origins
- five BYI levels (50, 100, 264, 450 and 813 Mg ha⁻¹)
- initial density and diameter halved and doubled

Every run stayed finite. Quadratic mean diameter was monotone and stems per hectare declined in every run.

- **Natural stands:** volume ordered correctly by site at every age under every perturbation. Their QMD exceeded the 69.7 cm observed maximum only at BYI 813, or at BYI 450 with initial density halved or doubled.
- **Planted stands:** they reach the 69.7 cm ceiling, and their site ordering of volume fails late in every perturbation (first failure between ages 72 and 99). That is the ceiling artifact described in the manuscript.
- **Envelope:** no even-aged run exceeded the observed basal area (76.06 m² ha⁻¹) or stand density index (1,453) maxima.

The full tables are in the manuscript folder, not in this repository.

## Open items

1. **Origin coding.** The PSP network is coded Natural throughout the deposit and the fitting frames, but the manuscript's Table 1 labels it plantations. A plot-level origin list is being requested. If any PSP plots are planted, the increment, ingrowth, Stage 1 and origin-floor terms need a refit. The height equation carries no origin term and is unaffected.
2. **Release.** Deposit 1.8.0 needs these patches merged and a release cut before the manuscript's Table 3 note is true.
3. **Increment level (unchanged by this refit).** The increment equations still underpredict the population-average level (Supplemental Section 8 of the manuscript).
