# Koa (*Acacia koa* A. Gray) annual individual-tree growth and mortality system, version 1.15.1 (November 22, 2026)

## Status

Version 1.15.1 is the system of record. Its equations are published on Zenodo in version 1.15.2, [10.5281/zenodo.24442327](https://doi.org/10.5281/zenodo.24442327), a documentation and provenance release that carries this folder with the 1.15.1 equations unchanged (version 1.15.1 is [10.5281/zenodo.24432587](https://doi.org/10.5281/zenodo.24432587)), and the concept DOI for all versions is [10.5281/zenodo.21081014](https://doi.org/10.5281/zenodo.21081014). It is carried in FVS-HI by `fvsOL/inst/extdata/HiGy.R` version 0.5.2, whose parameters match `koa_rdbyi_equations.csv` to full precision for every equation except the optional ingrowth scenario, which HiGy.R does not implement, and in manuscript v142 and supplement v134.

Two files are the model: `koa_rdbyi_equations.csv`, which holds every coefficient with its plot-cluster bootstrap interval, and `koa_step_rdbyi.R`, a base-R reference implementation that reads the CSV and projects a koa tree list in annual steps. Nothing in the code is hard-coded except unit constants and three numerical guards.

This README describes 1.15.1 only. `CHANGELOG.md` lists every version from 1.12.2 with its reasons, and `HISTORY.md` keeps the full README as it stood at 1.15.1 before this rewrite, including the 1.13.0 to 1.14.1 sections, the 1.13.0 domain of use and the preregistered SDImax criteria. `METHODS_SUMMARY.md` describes 1.13.0 and is retained for provenance.

What changed in 1.15.1: the Biomass Yield Index (BYI) was recomputed with out-of-bag predictions at the 36 US Forest Service FIA plots (69 growth subplots) that had trained the BYI forests, 474 duplicate rows were removed from the frame of the BYI biomass equation, and every BYI-dependent equation was refit with its form unchanged. Natural-stand BYI levels (10th, 50th and 90th percentiles of plots) are now 170, 317 and 400 Mg ha⁻¹ and planted levels 116, 159 and 308 Mg ha⁻¹. BYI stays on the scale of the biomass frame, which omits the fourfold FIA subplot expansion, so values are about one quarter of a per-hectare asymptote.

## Domain of use

The system projects pure koa stands described by a live tree list, a BYI and an origin (planted or natural). Read every projection with these limits.

Planted stands are the supported case. On the 41 planted benchmark plots the projected QMD passes both equivalence tests, and survival and basal area pass the intercept test and fail the slope test. Natural stands are indicative only: on the 12 natural plots basal area and survival fail both tests, and held out by installation the 90% bands covered 8 of 12 natural plots for basal area and QMD and 4 of 12 for survival.

The record is short. Seven plots have a benchmark horizon of 10 years or more, the longest planted record is 52 years and the longest natural record is 33 years. Projections to 40, 100 or 200 years rest on the form of the equations and on SDImax, and the bands widen accordingly.

Maximum SDI varies weakly with site. The BYI coefficient of S1 is 0.217 with a 95% interval of −0.015 to 0.447, a single SDImax of 742 gives the same benchmark error within its interval, and planted SDImax is 0.56 of natural, which the data cannot separate from the youth and wide spacing of the planted plots. A user with a local density record should supply `sdimax` directly.

Not modeled: thinning (the mortality equation describes death without removals), mixed stands, volume and carbon. Where volume appears in outputs it is 0.40 × basal area × basal-area-weighted height, a stated assumption. Crown base is an output only. Ingrowth is an optional scenario assumption for natural stands, fitted to 10 recruits on 5 of 48 subplots, and is not meant for planted stands. The model is not validated for site-by-site screening from mapped BYI.

## Quick start

The example needs only base R and the two files `koa_step_rdbyi.R` and `koa_rdbyi_equations.csv` in the working directory. Rerun in R 4.5.2 with the 1.15.1 files, it returns an SDImax of 637.921 and basal areas of 30.904 and 41.409 m² ha⁻¹ at years 20 and 40. These are illustrative projections from illustrative inputs, not data and not validation.

```r
source("koa_step_rdbyi.R")
cf <- koa_read_coef("koa_rdbyi_equations.csv")

# A small planted tree list: eight records, each standing for 50 trees per hectare
dbh     <- c(6.2, 7.5, 8.1, 9.4, 10.3, 11.8, 12.6, 14.0)   # diameter at breast height, cm
expf    <- rep(50, length(dbh))                             # trees per hectare represented by each record
byi     <- 156                                              # Biomass Yield Index, Mg per hectare
planted <- 1                                                # 1 planted, 0 natural
ht      <- koa_height(dbh, byi, cf)                          # total height, m (E2; use measured heights where available)

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

`koa_project()` returns a data frame with one row per year from 0 to `years` and the columns `year`, `BA`, `TPH`, `QMD`, `SDI`, `RD` and `HT`. `koa_step()` takes the same arguments without `years` and returns the tree list one year later as a list with `dbh`, `ht`, `expf`, `hcb` (crown base of the start-of-year trees) and `qmd`. The functions are `koa_read_coef(path)`, `koa_sdimax(byi, planted, cf)`, `koa_asymptote(byi, cf)`, `koa_height(dbh, byi, cf)`, `koa_dht(ht, x, byi, planted, cf)`, `koa_hcb(dbh, ht, bal, ba, cf)`, `koa_ingrowth(qmd, cf)`, `koa_step(dbh, ht, expf, byi, planted, cf, sdimax, height)` and `koa_project(dbh, ht, expf, byi, planted, years, cf, sdimax, height, ingrowth)`. `sdimax` defaults to S1, `height` defaults to the fitted E5 (`height = "rule"` is the fallback, which failed the held-out equivalence tests), and `ingrowth` defaults to `FALSE`.

## Running koa in FVS-HI

`fvsOL/inst/extdata/HiGy.R` (version tag `HiGyV0.5.2`) carries S1, E2, E3e, E4r, E5 and E6r with the parameters of `koa_rdbyi_equations.csv`; it has no ingrowth; its changelog is `fvsOL/inst/extdata/HiGyChangeLog.md`. `customRun_fvsRunHi.R` in the same folder runs it.

Every stand needs two extra columns in `FVS_StandInit`: `BYI` (Mg ha⁻¹, on the scale above) and `STDORGCD` (1 planted, 0 natural). `fvs/HiByi.kcp` queries both into Event Monitor variables. Its keywords must sit inside each stand of the keyfile, which is how FVS-Online inserts an attached kcp. An `AddFile` record that points to the kcp does not load it, and the stands then run without growth. When the Event Monitor has not yet computed BYI at stop point 1, `customRun_fvsRunHi.R` reads BYI and STDORGCD from `FVS_StandInit` directly.

`fvs/build_fvs_db_142.R` builds the 1.15.1 input database (one stand per plot measurement, live koa with DBH above zero, imperial units, no coordinates). A height recorded below breast height (1.37 m) for a tree with DBH is written as missing, 77 records in 7 stands, so HiGy imputes it from E2. This is the rule the system of record applies to every starting list, and it keeps HiGy's `ht < 1.3716` rule, which gives such a tree no diameter growth, from freezing trees that the reference grows. The recorded heights stay in the inventory SQLite. Under HiGy 0.5.2 all nine Hawaii test stands then match `koa_step_rdbyi.R` to 10⁻⁶ in basal area, stems and diameter; heights of the 14 small trees of PSP_202_2 differ by up to 4.7% at year 5 and by less than 1% from year 30. All 310 first-measurement stands run 50 years.

## Inputs, outputs and units

**Table 1.** Arguments of `koa_step()` and `koa_project()` and columns of the data frame returned by `koa_project()`. Tree-level arguments are vectors of equal length with one element per tree record; stand-level arguments are single values.

| Name | Role | Level | Unit | Meaning |
|:---:|:---:|:---:|:---:|:---:|
| `dbh` | Input | Tree | cm | Diameter at breast height (1.37 m) of each live koa record |
| `ht` | Input | Tree | m | Total height; missing heights are not filled, so fill them with `koa_height(dbh, byi, cf)` first |
| `expf` | Input | Tree | trees ha⁻¹ | Trees per hectare represented by each record |
| `byi` | Input | Stand | Mg ha⁻¹ | Biomass Yield Index of the site |
| `planted` | Input | Stand | none | 1 for a planted stand, 0 for a natural stand |
| `years` | Input | Stand | yr | Number of annual steps (`koa_project()` only) |
| `cf` | Input | None | none | Coefficient list returned by `koa_read_coef()` |
| `sdimax` | Input, optional | Stand | trees ha⁻¹ at 25.4 cm | Maximum stand density index; default is S1 |
| `height` | Input, optional | None | none | `"E5"` (default) or `"rule"` |
| `ingrowth` | Input, optional | None | none | `FALSE` (default) or `TRUE` for the natural-stand scenario (`koa_project()` only) |
| `year` | Output | Stand | yr | Years from the starting list |
| `BA` | Output | Stand | m² ha⁻¹ | Basal area of live koa |
| `TPH` | Output | Stand | trees ha⁻¹ | Live koa stems |
| `QMD` | Output | Stand | cm | Quadratic mean diameter |
| `SDI` | Output | Stand | trees ha⁻¹ at 25.4 cm | Stand density index of live koa |
| `RD` | Output | Stand | none | Relative density, *SDI* / *SDI*max |
| `HT` | Output | Stand | m | Basal-area-weighted mean height |

## Equations

All annual rates are computed from the start-of-year state and applied together. Competition is from live koa only. Diameters are in cm, heights in m, basal areas in m² ha⁻¹ and stem counts in trees ha⁻¹. Symbols are defined in Table 2 and coefficients are in Table 3.

S1, maximum stand density index:

*SDI*max = exp(*s*₀ + *s*₁ ln(*BYI*) + *s*₂ *planted*)

Shared height asymptote of E2 and E5:

*A* = exp(*a*₀ + *a*₁ ln(*BYI*))

E2, total height (fitted jointly with E5, form J1):

*HT* = 1.37 + (*A* − 1.37) (1 − exp(−*b* *DBH*))^*c*

E3e, height to crown base (output only; crown ratio is 1 − *HCB* / *HT*):

*HCB* = *HT* / (1 + exp(*d*₀ + *d*₁ ln(*HT* / *DBH*) + *d*₂ √(*BAL* *BA* + 1) + *d*₃ ln(*BA* + 1)))

E4r, annual diameter increment (cm yr⁻¹):

Δ*DBH* = exp(*b*₀ + *b*₁ ln(*DBH* + 1) + *b*₂ *DBH* + *b*₃ *x* + *b*₄ ln(*BYI*) + *b*₅ *planted*), with *x* = (*BAL* / *BA*) *RD*

E5, annual height increment (m yr⁻¹), zero for a tree taller than *A*:

Δ*HT* = *m* *k* *HT* [(*A* / *HT*)^(1/*m*) − 1] exp(*h*₅ *x*), with *k* = exp(*k*₀ + *k*₁ *planted*) and *m* = exp(ln *m*)

E6r, annual probability of death:

*P* = 1 − exp(−exp(*c*₀ + *c*₁ ln(*DBH* + 1) + *c*₂ *DBH* + *c*₃ *DBH*² + *c*₄ *BAL* + *c*₅ ln(*RD*) + *c*₆ ln(*BYI*) + *c*₇ *planted*))

IG, natural-stand ingrowth (optional scenario, trees ha⁻¹ yr⁻¹ passing 12.7 cm, entering at 12.7 cm with the height of E2):

*I* = [1 − exp(−9 exp(*t*₀ + *t*₁ *QMD*))] *μ* × 59.5 / 9

Stand quantities:

*BA* = Σ 0.00007854 *DBH*² *expf*; *N* = Σ *expf*; *QMD* = √(*BA* / (0.00007854 *N*)); *SDI* = *N* (*QMD* / 25.4)^1.605; *RD* = *SDI* / *SDI*max

Fallback height (`height = "rule"`): Δ*HT* = E2(*DBH* + Δ*DBH*) − E2(*DBH*).

**Table 2.** Symbols. Every quantity is computed from live koa only.

| Symbol | Unit | Definition |
|:---:|:---:|:---:|
| *DBH* | cm | Diameter at breast height (1.37 m) |
| *HT* | m | Total height; held at 0.5 m or above where it enters a logarithm or ratio |
| *HCB* | m | Height to crown base |
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
| *A* | m | Height asymptote shared by E2 and E5 |
| *x* | none | Competition index (*BAL* / *BA*) *RD* |
| *P* | yr⁻¹ | Annual probability of death; each record's *expf* is multiplied by 1 − *P* |
| *I* | trees ha⁻¹ yr⁻¹ | Ingrowth past 12.7 cm |

## Coefficients

**Table 3.** Estimates, plot-cluster bootstrap standard errors and 95% percentile intervals, generated by code from `koa_rdbyi_equations.csv` and rounded to four significant figures; the CSV holds full precision. S1, E4r and E6r share one joint bootstrap (1,986 of 2,000 resamples kept). E2 and E5 share a bootstrap of 500 resamples in which the plots of the height and increment frames are resampled together. The E3e competition terms are constrained to be zero or negative, so their upper bounds sit at zero. The CSV column `se_model` is empty for every row.

| Equation | Symbol | Term | Name in CSV | Estimate | SE | 95% interval | Resamples |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| S1 | *s*₀ | Intercept | `(Intercept)` | 5.937 | 0.672 | 4.569 to 7.295 | 1,986 |
| S1 | *s*₁ | ln(*BYI*) | `lbyi` | 0.2167 | 0.1147 | −0.01514 to 0.4469 | 1,986 |
| S1 | *s*₂ | *planted* | `planted` | −0.5728 | 0.08302 | −0.7379 to −0.4089 | 1,986 |
| E2 | *b* | Rate (cm⁻¹) | `b` | 0.04641 | 0.004985 | 0.03686 to 0.05586 | 500 |
| E2 | *c* | Shape | `c` | 1.083 | 0.07432 | 0.9445 to 1.234 | 500 |
| E2, E5 | *a*₀ | Asymptote intercept, ln(m) | `a0` | 2.451 | 0.2021 | 2.15 to 2.952 | 500 |
| E2, E5 | *a*₁ | ln(*BYI*) on the asymptote | `a_lbyi` | 0.1109 | 0.03488 | 0.02382 to 0.1629 | 500 |
| E5 | *k*₀ | ln(rate), natural | `lk` | −3.48 | 0.2664 | −4.188 to −3.2 | 500 |
| E5 | ln *m* | ln(shape) | `lc` | 0.1533 | 0.1403 | −0.0451 to 0.4922 | 500 |
| E5 | *h*₅ | (*BAL* / *BA*) *RD* | `x` | −0.8013 | 0.1835 | −1.183 to −0.4827 | 500 |
| E5 | *k*₁ | *planted* on ln(rate) | `k_pl` | 1.369 | 0.2331 | 1.172 to 1.995 | 500 |
| E3e | *d*₀ | Intercept | `b0` | −0.8289 | 0.1871 | −1.163 to −0.427 | 2,000 |
| E3e | *d*₁ | ln(*HT* / *DBH*) | `lsl` | −0.4444 | 0.1616 | −0.7602 to −0.1342 | 2,000 |
| E3e | *d*₂ | √(*BAL* *BA* + 1) | `sbalba_k` | −0.03967 | 0.02233 | −0.08155 to 0 | 2,000 |
| E3e | *d*₃ | ln(*BA* + 1) | `lba_k` | −0.0994 | 0.1077 | −0.3643 to 0 | 2,000 |
| E4r | *b*₀ | Intercept | `b0` | −3.336 | 0.6977 | −4.216 to −1.532 | 1,986 |
| E4r | *b*₁ | ln(*DBH* + 1) | `ls` | 0.2569 | 0.09964 | 0.08213 to 0.4782 | 1,986 |
| E4r | *b*₂ | *DBH* | `s` | −0.02841 | 0.007746 | −0.04532 to −0.01424 | 1,986 |
| E4r | *b*₃ | (*BAL* / *BA*) *RD* | `xrd` | −2.19 | 0.2241 | −2.653 to −1.774 | 1,986 |
| E4r | *b*₄ | ln(*BYI*) | `lbyi` | 0.516 | 0.118 | 0.2043 to 0.6601 | 1,986 |
| E4r | *b*₅ | *planted* | `pl` | 1.313 | 0.07037 | 1.178 to 1.446 | 1,986 |
| E6r | *c*₀ | Intercept | `(Intercept)` | 0.3154 | 2.069 | −3.787 to 4.545 | 1,986 |
| E6r | *c*₁ | ln(*DBH* + 1) | `ld` | −0.8533 | 0.2835 | −1.446 to −0.3468 | 1,986 |
| E6r | *c*₂ | *DBH* | `dbh_m` | −0.02488 | 0.03817 | −0.08981 to 0.05594 | 1,986 |
| E6r | *c*₃ | *DBH*² | `dbh_m2` | 0.0002761 | 0.000652 | −0.00138 to 0.001134 | 1,986 |
| E6r | *c*₄ | *BAL* | `BAL` | 0.03407 | 0.009957 | 0.01787 to 0.056 | 1,986 |
| E6r | *c*₅ | ln(*RD*) | `lrd` | 0.7394 | 0.2018 | 0.3542 to 1.131 | 1,986 |
| E6r | *c*₆ | ln(*BYI*) | `lbyi` | −0.117 | 0.3371 | −0.8122 to 0.5877 | 1,986 |
| E6r | *c*₇ | *planted* | `planted` | −1.048 | 0.2582 | −1.571 to −0.5441 | 1,986 |
| IG | *t*₀ | Intercept, occurrence | `t0` | −1.226 | 0.7673 | −2.856 to 0.07683 | 1,723 |
| IG | *t*₁ | *QMD* on occurrence | `t_qmd` | −0.1306 | 0.02672 | −0.1767 to −0.07483 | 1,723 |
| IG | *μ* | Mean recruits per subplot with any | `mu2` | 2 | 0.5789 | 1 to 2.667 | 1,723 |

The Monte Carlo bands also use four interval components that point projections never use: a tree-year standard deviation sigma of 1.057 that scales with increment to the power delta of 0.44, a plot multiplier on diameter increment with standard deviation tau of 0.404, and a plot multiplier on the mortality hazard with variance phi of 0.0295 (`logs/142/51.log`).

## Evaluation of version 1.15.1

The benchmark is 53 remeasured plots (41 planted, 12 natural) and 182 plot-horizons, each projected from its first visit with horizons stopped before any thinning. S1 is out of fold in the benchmark of record; E4r and E6r are fitted on all plots. Equivalence tests regress observed on predicted at each plot's longest horizon with a plot-cluster bootstrap and a 25% region set by convention. Every number in Table 4 is read from the log named in its row.

**Table 4.** Tests of the 1.15.1 system. Survival is a proportion, QMD error is in cm and basal area error in m² ha⁻¹.

| Test | Result | Evidence | Log |
|:---:|:---:|:---:|:---:|
| Benchmark, all plots | QMD passes both tests; survival and basal area pass the intercept test only | RMSE 0.124, 2.72 cm, 6.71 m² ha⁻¹; basal area slope 0.81 (0.56 to 1.09) | `142/51.log` |
| Benchmark, planted plots | QMD passes both; survival and basal area the intercept only | RMSE 0.112, 2.53 cm, 5.63 m² ha⁻¹ | `142/51.log` |
| Benchmark, natural plots | Fails except the QMD intercept | RMSE 0.177, 3.66 cm, 11.02 m² ha⁻¹ (basal area bias −2.30) | `142/51.log` |
| Benchmark, horizons of 10 years or more | Not tested for equivalence | 22 plot-horizons on 7 plots: 0.112, 3.46 cm, 7.82 m² ha⁻¹ | `142/51.log` |
| Benchmark with S1, E4r and E6r refitted without each plot's installation | QMD slope no longer passes | RMSE 0.128, 3.00 cm, 7.13 m² ha⁻¹; QMD slope 0.82 (0.73 to 0.95) | `142/28a.log` |
| Diameter increment E4r, installations held out | Passes both tests | Bias 0.025, RMSE 1.139 cm yr⁻¹, slope 0.918 (0.844 to 0.992) | `142/22t.log` |
| Height E2, installations held out | Passes both tests | Bias 0.04 m, RMSE 2.65 m, slope 0.96 (0.91 to 1.01) | `142/52.log` |
| Height increment E5, installations held out | Passes the intercept test, fails the slope test | Bias 0.040, RMSE 0.748 m yr⁻¹, slope 0.85 (0.74 to 0.99); the rule fallback has bias 0.189 and slope 0.56 | `142/52.log` |
| Crown base E3e, held out (fitted in 1.14.3, unchanged) | Passes both tests | Bias −0.01 m, RMSE 2.20 m, slope 1.07 (0.97 to 1.16) | `CHANGELOG.md`, 1.14.3 |
| Mortality E6r, tree-intervals held out | Calibrated overall | 845 deaths against 833.3 expected; AUC 0.896 (planted 0.726, natural 0.794) | `142/28a.log` |
| Coverage of the nominal 90% band, in sample | Close for basal area, short for survival | Basal area 0.887, QMD 0.849, survival 0.736 | `142/51.log` |
| Coverage of the nominal 90% band, equations held out by installation | Short, and short for natural plots | 0.849, 0.792, 0.679; with SDImax allowed to deviate 0.887, 0.811, 0.755; natural plots 0.667, 0.667, 0.333 | `142/83a.log`, `out/v142/coverage_heldout_83a_summary.csv` |
| Six 200-year gates (site order to 100 years, SDI limit, basal area bound, no SDI rise in years 150 to 200, Sukachev, yield against density) | All six pass | Site order of basal area holds in every scenario | `142/51.log` |
| Single SDImax of 742 against S1 | No benchmark difference | Basal area RMSE difference +0.196 (−0.018 to 0.343), paired bootstrap of 2,000 | `142/25.log` |

The full modified Bakuzis matrix (script 68, two origins, five BYI levels, four starting densities, 200 years) holds site order for height, QMD and assumed volume at every age and density. Basal area holds it except in planted runs after 168 to 198 years, when the highest BYI levels fall below lower ones. The Sukachev ratio is at most 1.003 (gate 1.02). Self-thinning slopes run from −1.54 to −2.30, with natural stands started at 4,000 stems ha⁻¹ at −2.24 to −2.30, steeper than Reineke's −1.605. Eichhorn's rule does not hold: the median coefficient of variation of volume across site at matched height is 0.14 to 0.20. Projected basal area and SDI stay below the observed 99.9th percentiles (`logs/142/68.log`). Across 42 planted starting lists (script 83b), QMD at 100 years from 2,400 stems ha⁻¹ relative to 300 ranges from 0.92 to 1.36, and 13 lists show a late basal-area inversion between the lowest and highest site levels (`out/v142/bakuzis_142_lists/bakuzis_lists_summary.csv`).

With SDI held at the median plot value and *BAL* / *BA* at 0.5, diameter growth on the 90th-percentile BYI site is 1.62 times that on the 10th in natural stands and 1.86 times in planted stands (`out/v142/growth_ratio_fixed_sdi_83c.csv`, `logs/142/83c.log`).

**Table 5.** Alternatives tested under 1.15.1 and not adopted. Each rule was written before its fit unless stated.

| Alternative | Outcome | Evidence | Log |
|:---:|:---:|:---:|:---:|
| S1 with a ln(BYI) × origin interaction | Not adopted | Interaction 0.246 (SE 0.146); held-out R² of ln(*SDI*max) 0.126 against 0.153 for S1 | `142/20.log` |
| S1 with origin only, or BYI only | Not adopted | Held-out R² 0.113 and 0.133 | `142/20.log` |
| Planted contrast in E4r that fades with DBH | Not adopted; held-out RMSE gain under the 1% rule | Pseudo-AIC −51.5, held-out RMSE −0.27% | `142/82.log` |
| Extra stand-density terms in E4r (PREREG section 10) | E4r itself is eligible and has the fewest coefficients, so it stays | Largest QMD rise in the density series 0.9% | `142/69.log` |
| Anchored height form A2 | Picked by the interval-width rule of script 45; J1 kept by the authors' choice and reported | J1 asymptote at median natural BYI 21.98 m (20.95 to 23.16) | `142/45.log`, `142/67.log` |
| Height forms A1 and B2 in the scenarios | Sensitivity only | 2.7 to 7.8 m taller than J1 at 100 years; assumed volume 14 to 36% larger | `142/83c.log` |
| Relative density capped at 1.0 | Sensitivity only, not deployed | Reported in supplement v134 | `142/58.log` |
| Stand-level mortality forms | None preferred to E6r | Reported in supplement v134 | `142/35.log` |

## The thinning correction

Twenty-seven of the 32 installations of the plantation permanent sample plot (PSP) network were thinned, and the PSP database records each thinned stem as dead. Mortality intervals that end in or span a thinning removal year of a PSP installation are censored, which leaves 6,722 tree-intervals and 845 deaths, and benchmark horizons of a thinned installation stop before its first removal year. Before this rule (frames of November 10 and the morning of November 11, 2026), 324 of 1,169 deaths fell in removal intervals. Whether thinned stems are coded dead in the PSP database is still to be confirmed with the data provider.

## How to reproduce 1.15.1

`koa_step_rdbyi.R` with `koa_rdbyi_equations.csv` reproduces every point projection with base R alone. The scripts document how the coefficients, tests and bands were obtained; their logs are in `logs/142` and every reported number was read from them.

Script 80 recomputes BYI out of bag. It needs US Forest Service FIA true plot coordinates, so it runs only on the restricted server, and its plot-level output is not distributed; `out/v142/byi_oob_80_summary.csv` summarizes it. Script 81 writes the new BYI into the model frames. Every BYI-dependent script was then rerun in this order: 20, 21, 22t, 23t, 28a, 28b, 27, 29, 29b, 44, 45, 50, 51, 52, 58, 64, 64b, 57b, 33, 33b, 42, 35, 46, 15, 25, 67, 68, 69, 70, 71, 72, 74 and 73, followed by the new scripts 82, 83a, 83b, 83c and 84. Script 67 writes `koa_rdbyi_equations.csv`.

The scripts read the model frames, which are not on GitHub. They are in the Zenodo record (`koa_frames.sqlite`, and the inputs listed in `HISTORY.md`, Table 7), and `site_byi_142.csv` in the record gives each plot's 1.15.1 BYI without coordinates. The scripts print no plot or installation identifier to the logs.

## File manifest

**Table 6.** Current files. Column definitions are in `DATA_DICTIONARY.md`.

| File | Purpose |
|:---:|:---:|
| `README.md` | This file (1.15.1) |
| `CHANGELOG.md` | Every version from 1.12.2, with reasons |
| `HISTORY.md` | The README as it stood before this rewrite, including the 1.13.0 to 1.14.1 sections |
| `DATA_DICTIONARY.md` | Column type, unit and meaning for every data file |
| `koa_step_rdbyi.R` | Reference implementation in base R |
| `koa_rdbyi_equations.csv` | Coefficients with plot-cluster bootstrap standard errors and 95% intervals |
| `fvs/HiByi.kcp`, `fvs/build_fvs_db_142.R`, `fvs/patch_higy_142.py` | FVS-HI keyword component, input database builder and the HiGy 0.5.2 parameter patch |
| `scripts/`, `logs/142/` | Scripts and their 1.15.1 logs |
| `out/v142/scenarios_long_j1.csv` | Point projections and 90% Monte Carlo bands for six scenarios to 100 years (Table 4 of manuscript v142) |
| `out/v142/ingrowth_bracket_j1.csv` | Natural scenarios with no ingrowth, the QMD form and a constant rate |
| `out/v142/benchmark_j1.csv` | Observed and projected survival, QMD and basal area for each plot-horizon |
| `out/v142/coverage_j1.csv`, `out/v142/coverage_heldout_83a*.csv` | Band coverage in sample and with equations held out |
| `out/v142/workbook_*_72.csv` | 200-year grid and fitted curves behind the Forest Solutions yield workbook |
| `out/v142/`, `out/bakuzis_142/`, `out/figs_v142/` | Other 1.15.1 outputs, the Bakuzis matrix runs and the 1.15.1 figures |
| `Fig3_equations.png`, `Fig4_benchmark.png`, `Fig5_projections.png` | Manuscript v142 figures 3 to 5 |

`out/scenarios_long_rdbyi.csv`, `out/benchmark_rdbyi.csv`, `out/coverage_rdbyi.csv` and `workbook/*_rdbyi.csv` are the 1.13.0 outputs of November 11, 2026, kept because earlier deposits refer to them; do not use them for 1.15.1. `METHODS_SUMMARY.md` and `notes/` are provenance for earlier versions.

## How to cite

Weiskittel, A.R., Sprecher, I., Gottesman, A., Rice, B., 2026. Acacia koa individual-tree growth and yield data and prediction functions (Hawaii, 1949–2025). Version 1.15.2. Zenodo. https://doi.org/10.5281/zenodo.24442327

Version 1.15.2 carries the 1.15.1 equations with updated documentation. The previous versions are 1.15.1 (https://doi.org/10.5281/zenodo.24432587) and 1.15.0 (https://doi.org/10.5281/zenodo.24425094). The concept DOI for all versions is 10.5281/zenodo.21081014.

## Licence and contact

Licence: Creative Commons Attribution 4.0 International (CC BY 4.0), as stated on the Zenodo record.

Contact: Aaron R. Weiskittel, Center for Research on Sustainable Forests, University of Maine, Orono, ME 04469, USA (aaron.weiskittel@maine.edu).
