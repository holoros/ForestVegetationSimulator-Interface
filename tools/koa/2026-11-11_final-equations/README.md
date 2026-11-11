# Koa (*Acacia koa* A. Gray) annual individual-tree growth and mortality system, relative density with SDImax from site and origin (November 11, 2026)

## What this is

This folder holds an annual individual-tree growth and mortality system for *Acacia koa* A. Gray in Hawaii: one equation for the maximum stand density index (SDImax) of a stand from its Biomass Yield Index (BYI) and origin, a height-diameter equation, a diameter increment equation, a height increment rule and a mortality equation. `koa_step_rdbyi.R` is a standalone reference implementation in base R that reads its coefficients from `koa_rdbyi_equations.csv` and projects a tree list one year at a time. The folder also holds the scripts that document the analysis, their console logs, scenario bands, coverage table, yield workbook grid and draft figures from which every reported number was read.

## Status and what it supersedes

This is the folder `tools/koa/2026-11-11_final-equations` of `holoros/ForestVegetationSimulator-Interface` (branch `koa/20261111-final-equations`, pull request into `ClaudeDevelopment`) and the addition to Zenodo version 1.13.0, both released on November 11, 2026 (see How to cite). The manuscript that describes this system was in coauthor review at release. The supplement PDF that goes into version 1.13.0 is supplement v124, which describes this system.

It supersedes four earlier things. The first is the v105final engine deposited in Zenodo versions 1.12.0 to 1.12.2 (`engine_v105final.zip`), which an audit on November 10, 2026 found to differ from its documentation (see `CHANGELOG.md`). The second is the first refit of November 10, 2026 (`koa_step.R`, `koa_final_equations.csv`, folder `tools/koa/2026-11-10_final-equations`, and the Zenodo 1.13.0 draft texts written for it), whose long-run projections had no upper bound. The third is the relative-density release of November 10, 2026 with a single SDImax (`koa_step_rd.R`, `koa_rd_equations.csv`). The fourth is the first build of this same system on the morning of November 11, 2026, whose mortality equation and benchmark counted thinning removals as deaths (see The thinning correction below). None of the second, third or fourth was published, and none should be.

The system applies the fitted equations as estimated. There is no multiplier, cap, floor, frontier, crown model, ingrowth or volume equation. Competition is from live koa only.

## The thinning correction

Twenty-seven of the 32 installations of the plantation permanent sample plot (PSP) network were thinned, and the PSP database records each thinned stem as dead. Earlier versions of this work censored the intervals that end in or span a removal year, using a table of removal years by installation. The frames built on November 10, 2026 did not apply that table, so every fit and benchmark from November 10 and the morning of November 11 counted thinning removals as deaths. In the mortality frame 756 of 7,478 tree-intervals and 324 of 1,169 deaths fall in removal intervals. On planted PSP plots the annual death rate is 27% in removal intervals and 2.1% in the others, and 307 of 417 planted PSP deaths are in removal intervals.

The correction is a censoring rule. Mortality intervals that end in or span a thinning removal year of a PSP installation are censored, which leaves 6,722 tree-intervals and 845 deaths, and benchmark horizons of a thinned installation stop before its first removal year. No diameter increment interval has a removal year strictly inside it, so S1, E2 and E4r are unchanged; E6r, the benchmark, the gates, the projections, the bands and the coverage all changed. Whether thinned stems are coded dead in the PSP database is still to be confirmed with the data provider.

## Quick start

The example needs only base R and the two files `koa_step_rdbyi.R` and `koa_rdbyi_equations.csv` in the working directory. It was written by reading the function signatures in `koa_step_rdbyi.R`; it was not executed in R when this README was prepared, so run it once before relying on it. The tree list and the BYI are illustrative inputs, not data.

```r
source("koa_step_rdbyi.R")
cf <- koa_read_coef("koa_rdbyi_equations.csv")

# A small planted tree list: eight records, each standing for 50 trees per hectare
dbh     <- c(6.2, 7.5, 8.1, 9.4, 10.3, 11.8, 12.6, 14.0)   # diameter at breast height, cm
expf    <- rep(50, length(dbh))                             # trees per hectare represented by each record
ht      <- koa_height(dbh, cf)                              # total height, m (E2; use measured heights where available)
byi     <- 156                                              # Biomass Yield Index, Mg per hectare
planted <- 1                                                # 1 planted, 0 natural

sdimax <- koa_sdimax(byi, planted, cf)                      # S1
print(sdimax)

out <- koa_project(dbh, ht, expf, byi, planted, 40, cf)     # 40 annual steps, SDImax from S1
print(out)                                                  # one row per year, 0 to 40
```

A stand with a local density record should be given its own SDImax in place of S1. The value below is an illustrative input.

```r
out_local <- koa_project(dbh, ht, expf, byi, planted, 40, cf, sdimax = 700)
print(out_local)
```

`koa_project()` returns a data frame with one row per year from 0 to `years` and the columns `year`, `BA`, `TPH`, `QMD`, `SDI`, `RD` and `HT`. `koa_step()` takes the same arguments without `years` and returns the tree list one year later as a list with `dbh`, `ht` and `expf`. The function signatures, in the order of their arguments, are `koa_read_coef(path)`, `koa_sdimax(byi, planted, cf)`, `koa_height(dbh, cf)`, `koa_stand(dbh, ht, expf)`, `koa_bal(dbh, ba)`, `koa_step(dbh, ht, expf, byi, planted, cf, sdimax)` and `koa_project(dbh, ht, expf, byi, planted, years, cf, sdimax)`; `sdimax` defaults to `koa_sdimax(byi, planted, cf)`.

## Inputs, outputs and units

**Table 1.** Arguments of `koa_step()` and `koa_project()` and columns of the data frame returned by `koa_project()`. Tree-level arguments are vectors of equal length with one element per tree record. Stand-level arguments are single values. Units are those of the comment block at the top of `koa_step_rdbyi.R`.

| Name | Role | Level | Unit | Meaning |
|:---:|:---:|:---:|:---:|:---:|
| `dbh` | Input | Tree | cm | Diameter at breast height (1.37 m) of each live koa record |
| `ht` | Input | Tree | m | Total height; the function does not fill missing heights, so fill them with `koa_height(dbh, cf)` first |
| `expf` | Input | Tree | trees ha⁻¹ | Trees per hectare represented by each record |
| `byi` | Input | Stand | Mg ha⁻¹ | Biomass Yield Index of the site |
| `planted` | Input | Stand | none | 1 for a planted stand, 0 for a natural stand |
| `years` | Input | Stand | yr | Number of annual steps (`koa_project()` only) |
| `cf` | Input | None | none | Coefficient list returned by `koa_read_coef()` |
| `sdimax` | Input, optional | Stand | trees ha⁻¹ at 25.4 cm | Maximum stand density index; default is S1 |
| `year` | Output | Stand | yr | Years from the starting list |
| `BA` | Output | Stand | m² ha⁻¹ | Basal area of live koa |
| `TPH` | Output | Stand | trees ha⁻¹ | Live koa stems |
| `QMD` | Output | Stand | cm | Quadratic mean diameter |
| `SDI` | Output | Stand | trees ha⁻¹ at 25.4 cm | Stand density index of live koa |
| `RD` | Output | Stand | none | Relative density, *SDI* / *SDI*max |
| `HT` | Output | Stand | m | Basal-area-weighted mean height |

## Equations

All three annual rates are computed from the start-of-year state and applied together. Diameters are in cm, heights in m, basal areas in m² ha⁻¹ and stem counts in trees ha⁻¹.

S1, maximum stand density index:

*SDI*max = exp(*s*₀ + *s*₁ ln(*BYI*) + *s*₂ *planted*)

E2, total height:

*HT* = 1.37 + *a*₀ (1 − exp(−*b* *DBH*))^*c*

E4r, annual diameter increment (cm yr⁻¹):

Δ*DBH* = exp(*b*₀ + *b*₁ ln(*DBH* + 1) + *b*₂ *DBH* + *b*₃ (*BAL* / *BA*) *RD* + *b*₄ ln(*BYI*) + *b*₅ *planted*)

E5, annual height increment (m yr⁻¹):

Δ*HT* = E2(*DBH* + Δ*DBH*) − E2(*DBH*)

E6r, annual probability of death:

*P* = 1 − exp(−exp(*c*₀ + *c*₁ ln(*DBH* + 1) + *c*₂ *DBH* + *c*₃ *DBH*² + *c*₄ *BAL* + *c*₅ ln(*RD*) + *c*₆ ln(*BYI*) + *c*₇ *planted*))

Stand quantities:

*BA* = Σ 0.00007854 *DBH*² *expf*; *N* = Σ *expf*; *QMD* = √(*BA* / (0.00007854 *N*)); *SDI* = *N* (*QMD* / 25.4)^1.605; *RD* = *SDI* / *SDI*max

**Table 2.** Symbols used in the equations. Every quantity is computed from live koa only. The two numerical guards are the only values in the code other than unit constants.

| Symbol | Unit | Definition |
|:---:|:---:|:---:|
| *DBH* | cm | Diameter at breast height (1.37 m) |
| *HT* | m | Total height |
| *expf* | trees ha⁻¹ | Trees per hectare represented by a record |
| *BYI* | Mg ha⁻¹ | Biomass Yield Index of the site |
| *planted* | none | 1 for planted stands, 0 for natural stands |
| *BA* | m² ha⁻¹ | Stand basal area; held at 10⁻⁶ or above where it is a divisor |
| *N* | trees ha⁻¹ | Stand stem count |
| *QMD* | cm | Quadratic mean diameter |
| *BAL* | m² ha⁻¹ | Basal area of trees larger than the subject tree; trees of equal diameter share one value and do not count one another |
| *SDI* | trees ha⁻¹ at 25.4 cm | Stand density index with exponent 1.605 and reference diameter 25.4 cm |
| *SDI*max | trees ha⁻¹ at 25.4 cm | Maximum stand density index, from S1 or supplied by the user |
| *RD* | none | Relative density; held at 0.001 or above inside the logarithm of E6r |
| Δ*DBH* | cm yr⁻¹ | Annual diameter increment |
| Δ*HT* | m yr⁻¹ | Annual height increment |
| *P* | yr⁻¹ | Annual probability of death; each record's *expf* is multiplied by 1 − *P* |
| *s*, *a*, *b*, *c* with subscripts | none | Coefficients in Table 3 |

## Coefficients

**Table 3.** Estimates, plot-cluster bootstrap standard errors and 95% percentile intervals, generated by code from `koa_rdbyi_equations.csv` and rounded to four significant figures; the CSV holds full precision. For S1, E4r and E6r each resample refits S1 and then both equations with that resample's SDImax, so the intervals are joint. The last column is the number of resamples behind each interval, as recorded in the CSV. In the mortality equation the intervals for the intercept, *DBH*, *DBH*² and ln(*BYI*) include zero.

| Equation | Symbol | Term | Name in CSV | Estimate | SE | 95% interval | Resamples |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| S1 | *s*₀ | Intercept | `(Intercept)` | 5.645 | 0.3723 | 4.919 to 6.349 | 1,987 |
| S1 | *s*₁ | ln(*BYI*) | `lbyi` | 0.2677 | 0.06912 | 0.1354 to 0.3990 | 1,987 |
| S1 | *s*₂ | *planted* | `planted` | −0.5655 | 0.07552 | −0.7164 to −0.4185 | 1,987 |
| E2 | *a*₀ | Asymptote above breast height (m) | `a0` | 19.73 | 0.4833 | 18.82 to 20.71 | 2,000 |
| E2 | *b* | Rate (cm⁻¹) | `b` | 0.04983 | 0.004897 | 0.04046 to 0.05936 | 2,000 |
| E2 | *c* | Shape | `c` | 1.150 | 0.07759 | 1.004 to 1.309 | 2,000 |
| E4r | *b*₀ | Intercept | `b0` | −3.344 | 0.7678 | −4.315 to −1.472 | 1,987 |
| E4r | *b*₁ | ln(*DBH* + 1) | `ls` | 0.2589 | 0.09673 | 0.08792 to 0.4753 | 1,987 |
| E4r | *b*₂ | *DBH* | `s` | −0.02875 | 0.007535 | −0.04493 to −0.01538 | 1,987 |
| E4r | *b*₃ | (*BAL* / *BA*) × *RD* | `xrd` | −2.193 | 0.2257 | −2.649 to −1.772 | 1,987 |
| E4r | *b*₄ | ln(*BYI*) | `lbyi` | 0.5170 | 0.1312 | 0.1935 to 0.6715 | 1,987 |
| E4r | *b*₅ | *planted* | `pl` | 1.305 | 0.06916 | 1.167 to 1.438 | 1,987 |
| E6r | *c*₀ | Intercept | `(Intercept)` | 0.3404 | 2.426 | −2.181 to 7.490 | 1,987 |
| E6r | *c*₁ | ln(*DBH* + 1) | `ld` | −0.8697 | 0.2854 | −1.480 to −0.3618 | 1,987 |
| E6r | *c*₂ | *DBH* | `dbh_m` | −0.02367 | 0.03829 | −0.08526 to 0.06678 | 1,987 |
| E6r | *c*₃ | *DBH*² | `dbh_m2` | 0.0002755 | 0.0006334 | −0.001637 to 0.001066 | 1,987 |
| E6r | *c*₄ | *BAL* | `BAL` | 0.03407 | 0.01004 | 0.01756 to 0.05647 | 1,987 |
| E6r | *c*₅ | ln(*RD*) | `lrd` | 0.7449 | 0.2011 | 0.3541 to 1.124 | 1,987 |
| E6r | *c*₆ | ln(*BYI*) | `lbyi` | −0.1165 | 0.4026 | −1.345 to 0.3153 | 1,987 |
| E6r | *c*₇ | *planted* | `planted` | −1.050 | 0.2520 | −1.605 to −0.6101 | 1,987 |

The interval components used only for Monte Carlo bands are a tree-year standard deviation sigma of 1.059 that scales with increment to the power delta of 0.438, a plot multiplier on increment with standard deviation tau of 0.409, and a plot multiplier on the mortality hazard with variance phi of 0.029. Point projections use none of them.

## What was tested and what failed

Every number in this section is from the results note `2026-11-11_koa-final-system_REVIEW.md`, which was read from logs 22t, 23t, 24b and 25, except the account of the test of SDImax against BYI in logs 20 and 21, which is from `2026-11-11_koa-sdimax-byi_REVIEW.md` and still stands. Both notes are in `notes/` of this folder.

The rule for adopting SDImax as a function of BYI was written before the test and had three criteria. It did not prefer the adopted form, because the second criterion failed, and it still fails with thinning removals censored. The author adopted S1 on November 11, 2026 on a different ground: the system is then consistent between fitting and use and the ceiling varies with site. A single value of 742 with the equations refitted to it has a slightly lower benchmark basal area error and the same gate results.

**Table 4.** The three preregistered criteria and their outcome with thinning removals censored. The benchmark is 53 remeasured plots (41 planted, 12 natural) and 182 plot-horizons, each projected from its first visit. Basal area error is in m² ha⁻¹.

| Criterion | Result | Evidence |
|:---:|:---:|:---:|
| BYI coefficient in the direct quantile model excludes zero | Pass | 0.54 (0.30 to 0.83), 300 plot-cluster resamples |
| Benchmark basal area RMSE at least 5% below that with 742 | Fail | 6.74 for S1 against 6.60 for 742 with the equations refitted; paired difference +0.14 (−0.08 to +0.29) |
| Every gate that passes with 742 still passes | Pass | The same five gates pass and the same one (Sukachev) fails |

**Table 5.** Tests of the adopted system and their outcome. Held-out tests leave out whole installations. Equivalence tests are bootstrap tests of observed on predicted at each plot's longest horizon, with a 25% region.

| Test | Result | Evidence |
|:---:|:---:|:---:|
| Annual diameter increment, held-out installations | Pass | Bias 0.030 cm yr⁻¹, RMSE 1.144 cm yr⁻¹, slope 0.905 |
| Benchmark QMD, all plots | Pass | RMSE 2.78 cm (bias +0.54); passes intercept and slope tests |
| Benchmark survival, all plots | Partial | RMSE 0.124 (bias −0.023); passes the intercept test, fails the slope test (0.87, 0.67 to 1.01) |
| Benchmark basal area, all plots | Partial | RMSE 6.76 m² ha⁻¹ (bias +0.81); passes the intercept test, fails the slope test (0.82, 0.57 to 1.09) |
| Benchmark, planted plots | Partial | 0.113, 2.59 cm, 5.79 m² ha⁻¹; QMD passes both tests, survival and basal area the intercept only |
| Benchmark, natural plots | Fail | 0.176, 3.71 cm, 10.78 m² ha⁻¹ (bias −2.27); fails except the QMD intercept |
| Benchmark, horizons of 10 years or more | Not tested for equivalence | 22 plot-horizons on 7 plots: 0.122, 3.57 cm, 7.93 m² ha⁻¹ |
| Site ordering of basal area and QMD to 100 years | Pass | Basal area is never out of site order in 200 years for either origin |
| SDI limit, basal area bound at 200 years, no rise in SDI between years 150 and 200, yield against density | Pass | Four gates, all pass |
| Sukachev gate | Fail | Stems at 40 and 100 years are not lower on better sites in natural stands (they are in planted stands); the gate also fails for one SDImax and for the origin mean |
| Response of mortality to relative density | Supported | Positive in every bootstrap resample |
| Rise of mortality in large trees | Not established | DBH² term positive in 77.6% of resamples and its interval includes zero; lowest mortality at 66 cm |
| Coverage of the nominal 90% Monte Carlo band, SDImax at its out-of-fold prediction | Close for basal area, short for the others | Basal area 89% (47 of 53 plots), QMD 85% (45 of 53), survival 72% (38 of 53) |
| Coverage of the nominal 90% band, SDImax allowed to deviate | Close for basal area, short for survival | Basal area 92% (49 of 53), QMD 87% (46 of 53), survival 75% (40 of 53) |
| Coverage by origin, SDImax at its out-of-fold prediction | Natural plots short | Planted 93%, 90% and 76%; natural 75%, 67% and 58% for basal area, QMD and survival |
| Reference file against a separately coded loop | Pass | Largest absolute difference 2 × 10⁻¹³ |

The Sukachev gate fails because mortality no longer rises with BYI once removals are censored. Planted trees have a lower mortality hazard than natural trees at the same size, competition, relative density and BYI (hazard ratio 0.35, 0.20 to 0.54); the ratio was above 1 before the correction. The Monte Carlo median of basal area is below the point projection at 100 years in every scenario.

Four further findings limit how S1 should be read. The second-stage regression behind S1 explains 0.136 of the variance of ln(plot SDImax) held out by installation, against 0.113 for origin alone. The BYI coefficient is 0.268 (SE 0.054) weighted by posterior precision and −0.016 (0.048) unweighted. Planted SDImax is 0.57 of natural (0.49 to 0.66), which the data cannot separate from the youth and wide spacing of the planted plots. Each plot's own SDImax predicts the benchmark better than S1 (basal area RMSE 5.27 m² ha⁻¹), and that value is not available for a new stand.

## Domain of use and known limits

The system is for stands of koa described by a tree list, a BYI and an origin. The scenario BYI levels, which are the 10th, 50th and 90th percentiles of each origin's plots, are 64, 248 and 386 Mg ha⁻¹ for natural plots and 121, 156 and 309 Mg ha⁻¹ for planted plots. A BYI of 309 Mg ha⁻¹ is the 90th percentile of planted plots, so SDImax for planted stands above it rests on about a tenth of the planted plots.

The record is short. With benchmark horizons stopped before the first thinning, seven plots have a horizon of 10 years or more. The longest planted record is 52 years in one plot and the longest natural record is 33 years. Projections beyond the record rest on the form of the equations and on SDImax.

Long projections have a definite shape that the record cannot confirm. On the measured starting lists, natural stands at low BYI lose basal area from the start (28.8 m² ha⁻¹ at year 0, 14.1 at 100 years) and peak at 46 to 50 years at median and high BYI. Planted stands peak at 51 to 71 years (39 to 55 m² ha⁻¹) and decline, with relative density reaching 1.02 to 1.09.

Natural stands are indicative only, because the 12 natural benchmark plots fail the equivalence tests except the QMD intercept. The growth and mortality equations are fitted on all plots, including the benchmark plots, so the benchmark is out of fold for S1 only.

The two parameters that make SDImax vary are the least secure in the system. A user with a local density record should supply `sdimax` directly.

The system has no ingrowth, no crown variables and no uneven-aged structure beyond what the tree list carries. Height comes from diameter only. Thinning is not modeled: the mortality equation describes death without removals. Volume is not modeled: where volume appears in the outputs it is 0.40 × basal area × basal-area-weighted height, a stated assumption for which no source is cited. Carbon is not computed.

## How to reproduce

The runnable part of this folder is the reference file and the coefficient CSV: `koa_step_rdbyi.R` with `koa_rdbyi_equations.csv` reproduces every point projection from a tree list, a BYI and an origin, with base R alone. The scripts document how the coefficients, tests and bands were obtained. They cannot be rerun from this folder or from the Zenodo record, because they read inputs that are not distributed.

The scripts run in the order 20, 21, 22t, 23t, 24b, 25 from the job folder `~/jobs/koa_final_eq_20261110`, which each script sets as its working directory. `scripts/utils.R` holds the fold assignment and the bootstrap equivalence test and is sourced by every script except 24b. The logs do not state run times.

**Table 6.** Script order, purpose, outputs and seeds. Inputs are listed in Table 7. Scripts 22t and 23t write their outputs under `rdbyi2` names (coefficients to `release_rdbyi2/`, scenarios and figures to `ms_rdbyi2/`, the other files to `out/`); script 26 redraws Fig. 5 from the scenario file with the shading at years 33 (natural) and 10 (planted), and script 27 evaluates equation S1 with its bootstrap intervals at the exact scenario BYI percentiles (log 22t prints them at BYI rounded to whole numbers); the copies in this folder carry the `rdbyi` names of the file manifest. Random numbers use the L'Ecuyer-CMRG generator in parallel sections, so exact Monte Carlo values may differ if the number of cores is changed.

| Script | Purpose | Outputs | Seed and settings |
|:---:|:---:|:---:|:---:|
| `20_sdimax_byi.R` | Preregistered test of SDImax against BYI; candidate refits; 200-year gates. Run before the thinning correction; its benchmark comparisons are replaced by script 25 | `out/sdimax_byi.rds`, `logs/20_sdimax_byi.log` | 20261115; 300 quantile-model resamples (`KOA_NBQ`) |
| `21_sdimax_followup.R` | Follow-up checks raised by the review of script 20. Run before the thinning correction | `logs/21_sdimax_followup.log` | 20261116; 2,000 paired resamples |
| `22t_rdbyi_final.R` | Adopted fits with removal intervals censored, interval components, joint bootstrap, coefficient table, check of the reference file | Fitted objects, bootstrap rows, `koa_rdbyi_equations.csv`, `logs/22t_rdbyi_final.log` | 20261117; 2,000 resamples (`KOA_NBOOT`), 6 cores (`KOA_CORES`) |
| `23t_rdbyi_items.R` | Benchmark with horizons stopped before the first removal year, gates, Monte Carlo bands, coverage, figures, workbook grid | `out/benchmark_rdbyi.csv`, `out/scenarios_long_rdbyi.csv`, `out/coverage_rdbyi.csv`, Figs. 3 to 5, four workbook CSVs, `logs/23t_rdbyi_items.log` | 20261118; 500 band draws (`KOA_NDRAW`), 300 coverage draws (`KOA_NDRAW_COV`), 6 cores |
| `24b_thin_refit.R` | Diagnosis of the thinning defect: deaths in removal intervals, and the mortality equation with and without them | `logs/24b_thin_refit.log` | No random numbers |
| `25_compare_censored.R` | Comparison of SDImax treatments under the censoring rule: benchmark, paired bootstrap and gates | `logs/25_compare_censored.log` | 20261119; 2,000 paired resamples |

**Table 7.** Inputs the scripts read that are not in this folder. None of them is among the files added in version 1.13.0. A reader who wants to rerun the scripts needs all of them.

| Input | Read by | What it is |
|:---:|:---:|:---:|
| `frames/frames.rds`, `frames/mf_confirmed.rds` | `frames.rds` by all six scripts; `mf_confirmed.rds` by 20, 22t, 24b and 25 | The R data frames (trees, increment intervals, confirmed-death mortality intervals), built by the earlier scripts of the November 10 job from `koa_frames.sqlite` (md5 42531bd2922405afa4aec79ad11cecf3), which is in the Zenodo record |
| Plot SDImax table and fit frame of the brms SDImax job (`koa_brms_sdimax_20261102`) | 20, 21, 22t, 23t, 25 | Plot-level SDImax estimates to which S1 is fitted |
| `psp_origin_thinning_2026-09-16_DATA.csv` | 22t, 23t, 24b, 25 | Removal years by PSP installation, which define the censored intervals |
| `release/koa_step.R`, `release/koa_final_equations.csv` | 20, 21, 22t, 23t, 25 | Reference file and coefficients of the November 10 refit; the scripts take the stand, competition and height functions and the height coefficients from them |
| `out/rd_final_fits.rds`, `out/E2_height_cr3.rds`, `out/rdbyi_fits.rds` | 20, 21 and 25; 23t; 24b | Fitted objects of earlier scripts of the same job that are not in this folder |

Manuscript v132 lists a plot-level origin and thinning table among the contents of the Zenodo record. Whether that file is the thinning table the scripts read was not determined. True FIA plot coordinates are not distributed, so no step that depends on plot location can be repeated from the deposit; the frames carry each plot's BYI as stored.

Scripts 21, 22t and 23t contain one hard-coded plot identifier, the same in each, which selects the planted starting list used for the workbook grid and for the check of the reference file. It is not reproduced here. The scripts print no plot or installation identifier to the logs.

## File manifest

**Table 8.** Files in this folder and their purpose. Column definitions for every data file are in `DATA_DICTIONARY.md`.

| File | Purpose |
|:---:|:---:|
| `README.md` | This file |
| `DATA_DICTIONARY.md` | Column type, unit and meaning for every data file |
| `CHANGELOG.md` | What changed from 1.12.2 and why |
| `METHODS_SUMMARY.md` | Data frames, estimators, evaluation design and Monte Carlo intervals, with script and log pointers |
| `koa_step_rdbyi.R` | Standalone reference implementation in base R |
| `koa_rdbyi_equations.csv` | Coefficients with standard errors and 95% intervals |
| `scripts/` | `20_sdimax_byi.R`, `21_sdimax_followup.R`, `22t_rdbyi_final.R`, `23t_rdbyi_items.R`, `24b_thin_refit.R`, `25_compare_censored.R`, `26_fig5_shade.R`, `27_sdimax_at_percentiles.R`, `utils.R` |
| `logs/` | Console log of each script; every reported number was read from these |
| `out/scenarios_long_rdbyi.csv` | Point projections and 90% Monte Carlo bands for six scenarios to 100 years, with and without a deviation of SDImax |
| `out/coverage_rdbyi.csv` | Observed values and 90% bands at each benchmark plot's longest horizon |
| `out/benchmark_rdbyi.csv` | Observed and projected survival, QMD and basal area for each plot-horizon |
| `workbook/workbook_grid_rdbyi.csv` | 200-year trajectories behind the yield workbook, by site class, starting density and SDImax case |
| `workbook/workbook_logistic_rdbyi.csv` | Logistic curves fitted to the workbook basal area trajectories |
| `workbook/workbook_diag_rdbyi.csv` | Diagnostics of each workbook trajectory |
| `workbook/workbook_crossover_rdbyi.csv` | Age at which basal area stops being ordered by site class |
| `Fig3_equations.png` | Draft figure, 300 dpi: the fitted equations with bootstrap bands |
| `Fig4_benchmark.png` | Draft figure, 300 dpi: observed against projected at each plot's longest horizon |
| `Fig5_projections.png` | Draft figure, 300 dpi: scenario projections to 100 years, years past the benchmark record shaded (script 26) |

## How to cite

Weiskittel, A.R., Sprecher, I., Gottesman, A., Rice, B., 2026. Acacia koa individual-tree growth and yield data and prediction functions (Hawaii, 1949–2025). Version 1.13.0. Zenodo. https://doi.org/10.5281/zenodo.24116922

Version 1.13.0 was published on November 11, 2026 with the DOI 10.5281/zenodo.24116922. The concept DOI for all versions is 10.5281/zenodo.21081014, and the version before it is 1.12.2 (https://doi.org/10.5281/zenodo.24039072).

The authors and title are those of the dataset reference in manuscript v132. The superseded 1.13.0 texts file does not list creators: it carries the record's creators unchanged from version 1.12.2, and this version does the same.

## Licence and contact

Licence: the licence of the Zenodo record, carried unchanged from version 1.12.2. No licence is stated in the earlier README, commit message, pull request body or Zenodo texts for this folder, so none is stated here; confirm it against the record before publishing.

Contact: Aaron R. Weiskittel, Center for Research on Sustainable Forests, University of Maine, Orono, ME 04469, USA (aaron.weiskittel@maine.edu), the corresponding author of the manuscript.
