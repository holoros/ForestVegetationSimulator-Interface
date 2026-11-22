# Data dictionary: koa (*Acacia koa* A. Gray) growth and mortality system, version 1.15.1 (November 22, 2026)

Each table below describes one distributed data file. Column names and row counts were read from the files with code, and meanings were taken from the script that writes each file. The files of version 1.15.1 are `koa_rdbyi_equations.csv` (script 67) and the files in `out/v142/` (scripts 51, 72 and 83a). The section at the end keeps the dictionary of the 1.13.0 files of November 11, 2026, which earlier deposits refer to; do not use those files for 1.15.1. All files are comma-separated text with a header row. Logical columns hold the strings TRUE and FALSE. No file holds a plot identifier, an installation identifier or a coordinate.

Abbreviations used throughout: BA, basal area of live koa; TPH, live koa stems per hectare; QMD, quadratic mean diameter; SDI, stand density index, *N* (*QMD* / 25.4)^1.605; SDImax, maximum stand density index; RD, relative density, SDI over SDImax; BAL, basal area of larger koa; BYI, Biomass Yield Index; S1, the equation SDImax = exp(*s*₀ + *s*₁ ln(BYI) + *s*₂ planted).

## koa_rdbyi_equations.csv

**Table 1.** Coefficients of the seven equations, 32 rows, one per coefficient, written by script 67 from the fitted objects. Estimates are on the scale on which they enter the equations in `README.md`.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `equation` | Text | none | `S1_sdimax`, `E2_height`, `E5_height_increment`, `E3e_crown_base`, `E4r_diameter_increment`, `E6r_mortality` or `IG_ingrowth` |
| `term` | Text | none | Coefficient name as read by `koa_read_coef()`; see Table 2 |
| `estimate` | Numeric | See Table 2 | Estimate from the full data |
| `se_model` | Numeric | As `estimate` | Empty in every row |
| `se_plot_bootstrap` | Numeric | As `estimate` | Standard deviation of the estimate over the kept plot-cluster bootstrap resamples |
| `lo95` | Numeric | As `estimate` | 2.5th percentile of the kept resamples |
| `hi95` | Numeric | As `estimate` | 97.5th percentile of the kept resamples |
| `n_boot` | Integer | count | Resamples behind the row: 1,986 for S1, E4r and E6r (one joint bootstrap); 500 for E2 and E5 (height and increment frames resampled together); 2,000 for E3e; 1,723 for IG |

**Table 2.** Values of `term` by equation, with the symbol used in `README.md` and the predictor each coefficient multiplies. Predictor units are cm for DBH, m for HT, m² ha⁻¹ for BA and BAL, and Mg ha⁻¹ for BYI. The responses are ln(SDImax) for S1, height in m for E2, height increment in m yr⁻¹ for E5, crown base in m for E3e, ln(annual diameter increment in cm yr⁻¹) for E4r, the complementary log-log of the annual probability of death for E6r, and ingrowth in trees ha⁻¹ yr⁻¹ for IG.

| Equation | `term` | Symbol | Multiplies |
|:---:|:---:|:---:|:---:|
| `S1_sdimax` | `(Intercept)` | *s*₀ | 1 |
| `S1_sdimax` | `lbyi` | *s*₁ | ln(BYI) |
| `S1_sdimax` | `planted` | *s*₂ | planted (1 or 0) |
| `E2_height` | `b` | *b* | Rate, in cm⁻¹ |
| `E2_height` | `c` | *c* | Shape, no unit |
| `E5_height_increment` | `a0` | *a*₀ | 1, in the asymptote *A* = exp(*a*₀ + *a*₁ ln(BYI)) shared with E2 |
| `E5_height_increment` | `a_lbyi` | *a*₁ | ln(BYI), in the asymptote |
| `E5_height_increment` | `lk` | *k*₀ | 1, in ln(rate) |
| `E5_height_increment` | `k_pl` | *k*₁ | planted (1 or 0), in ln(rate) |
| `E5_height_increment` | `lc` | ln *m* | 1, in ln(shape) |
| `E5_height_increment` | `x` | *h*₅ | (BAL / BA) × RD |
| `E3e_crown_base` | `b0` | *d*₀ | 1 |
| `E3e_crown_base` | `lsl` | *d*₁ | ln(HT / DBH) |
| `E3e_crown_base` | `sbalba_k` | *d*₂ | √(BAL × BA + 1); constrained to zero or below |
| `E3e_crown_base` | `lba_k` | *d*₃ | ln(BA + 1); constrained to zero or below |
| `E4r_diameter_increment` | `b0` | *b*₀ | 1 |
| `E4r_diameter_increment` | `ls` | *b*₁ | ln(DBH + 1) |
| `E4r_diameter_increment` | `s` | *b*₂ | DBH |
| `E4r_diameter_increment` | `xrd` | *b*₃ | (BAL / BA) × RD |
| `E4r_diameter_increment` | `lbyi` | *b*₄ | ln(BYI) |
| `E4r_diameter_increment` | `pl` | *b*₅ | planted (1 or 0) |
| `E6r_mortality` | `(Intercept)` | *c*₀ | 1 |
| `E6r_mortality` | `ld` | *c*₁ | ln(DBH + 1) |
| `E6r_mortality` | `dbh_m` | *c*₂ | DBH |
| `E6r_mortality` | `dbh_m2` | *c*₃ | DBH² |
| `E6r_mortality` | `BAL` | *c*₄ | BAL |
| `E6r_mortality` | `lrd` | *c*₅ | ln(RD) |
| `E6r_mortality` | `lbyi` | *c*₆ | ln(BYI) |
| `E6r_mortality` | `planted` | *c*₇ | planted (1 or 0) |
| `IG_ingrowth` | `t0` | *t*₀ | 1, in the complementary log-log of nine-year occurrence |
| `IG_ingrowth` | `t_qmd` | *t*₁ | QMD, in the same |
| `IG_ingrowth` | `mu2` | *μ* | Mean recruits per subplot with any recruit |

## out/v142/scenarios_long_j1.csv

**Table 3.** Point projections and Monte Carlo bands for six scenarios (Table 4 of manuscript v142), 7,272 rows: two origins by three BYI levels by two treatments of SDImax by 101 years by six variables, written by script 51. Each scenario starts from one real tree list per origin; the planted list is the planted visit with at least 30 trees closest to the median QMD and stems of such visits. BYI levels are 170, 317 and 400 Mg ha⁻¹ (natural) and 116, 159 and 308 Mg ha⁻¹ (planted). Bands are percentiles of 500 draws of a joint bootstrap row, a plot increment multiplier, tree-year variation and a plot mortality multiplier, with the height coefficients held at their estimates. Columns are those of Table H3 below. In this file `n_bad` is 0 or 1 in every cell, and 58 cells in all, from one draw of the planted high-BYI scenario with SDImax deviation from year 91 onward, left out a non-finite draw.

## out/v142/ingrowth_bracket_j1.csv

**Table 4.** Deterministic natural-stand scenarios under three ingrowth assumptions, 1,809 rows, written by script 51.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `ingrowth` | Text | none | `none`, `QMD` (the IG equation) or `constant` (a constant rate) |
| `level` | Text | none | BYI level: `lo`, `md` or `hi` |
| `byi` | Numeric | Mg ha⁻¹ | BYI of the scenario |
| `year` | Integer | yr | Years from the starting list |
| `BA` | Numeric | m² ha⁻¹ | Basal area |
| `TPH` | Numeric | trees ha⁻¹ | Stems |
| `QMD` | Numeric | cm | Quadratic mean diameter |
| `HT` | Numeric | m | Basal-area-weighted mean height |
| `VOL` | Numeric | m³ ha⁻¹ | Assumed volume, 0.40 × BA × HT; not a fitted volume |
| `RD` | Numeric | none | Relative density |
| `SDI` | Numeric | trees ha⁻¹ at 25.4 cm | Stand density index |

## out/v142/benchmark_j1.csv

**Table 5.** Observed and projected stand values for every benchmark plot-horizon, 182 rows on 53 plots, written by script 51. Columns and their meanings are those of Table H5 below; SDImax is from S1 fitted without the plot's fold.

## out/v142/coverage_j1.csv and out/v142/coverage_heldout_83a.csv

**Table 6.** Observed values and nominal 90% bands at the longest horizon of each benchmark plot, 318 rows each: 53 plots by two treatments of SDImax by three variables. `coverage_j1.csv` (script 51) uses the full-data equations; `coverage_heldout_83a.csv` (script 83a) keeps the same draws and centres them on S1, E4r and E6r refitted without the plot's installation fold. Columns are those of Table H4 below.

## out/v142/coverage_heldout_83a_summary.csv

**Table 7.** Coverage of the nominal 90% band by equation set, SDImax treatment, variable and origin, 36 rows, written by script 83a.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `equations` | Text | none | `in-sample (script 51)` or `held out by installation (28a folds)` |
| `site_dev` | Logical | none | FALSE: SDImax at its S1 prediction. TRUE: with a plot-level lognormal deviation |
| `var` | Text | none | `surv`, `qmd` or `ba` |
| `planted` | Integer or empty | none | 1 planted, 0 natural, empty for all plots |
| `plots` | Integer | count | Benchmark plots in the row |
| `coverage` | Numeric | proportion | Share of plots whose observed value lies in the band |
| `width` | Numeric | As `var` | Mean band width |

## out/v142/workbook_grid_72.csv, workbook_logistic_72.csv, workbook_diag_72.csv, workbook_crossover_72.csv

**Table 8.** The 200-year grid behind the Forest Solutions yield workbook and its summaries, written by script 72 (`72_workbook_1150.R`) with 1.15.1 coefficients. Rows: 9,600, 48, 48 and 4. Columns and meanings are those of Tables H6 to H9 below, with one change: the starting list is the rule-picked planted visit of Table 3 (37 trees) in place of an 11-tree list, still rescaled to a QMD of 7.24 cm. Site classes keep BYI 450, 340, 230 and 120 Mg ha⁻¹.

## Files of version 1.13.0 (historical)

The tables below describe the files of November 11, 2026 in `out/` and `workbook/`. Their numbers carry the prefix H.

### out/scenarios_long_rdbyi.csv

**Table H3.** Point projections and Monte Carlo bands for six scenarios, 7,272 rows: two origins by three BYI levels by two treatments of SDImax by 101 years by six variables. Each scenario starts from one real tree list per origin. Bands are percentiles of 500 draws of a joint bootstrap row, a plot increment multiplier, tree-year variation and a plot mortality multiplier, with the height coefficients held at their estimates.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `planted` | Integer | none | 1 planted, 0 natural |
| `level` | Text | none | BYI level of the scenario: `lo`, `md` or `hi`, the 10th, 50th and 90th percentile of BYI among the origin's plots |
| `byi` | Numeric | Mg ha⁻¹ | BYI of the scenario |
| `sdimax` | Numeric | trees ha⁻¹ at 25.4 cm | SDImax from S1 at the scenario's BYI and origin; the same value is stored in both treatments |
| `site_dev` | Logical | none | FALSE: each draw's SDImax is S1 evaluated with that draw's bootstrap row. TRUE: that value is also multiplied by a lognormal plot-level deviation whose standard deviation is the residual standard deviation of S1 |
| `year` | Integer | yr | Years from the starting measurement of each scenario plot, 0 to 100 |
| `var` | Text | none | `BA` (m² ha⁻¹), `TPH` (trees ha⁻¹), `QMD` (cm), `HT` (basal-area-weighted mean height, m), `VOL` (m³ ha⁻¹, the assumed 0.40 × BA × HT, not a fitted volume) or `RD` (no unit) |
| `point` | Numeric | As `var` | Deterministic projection at the coefficient estimates |
| `p05` | Numeric | As `var` | 5th percentile of the finite draws |
| `p50` | Numeric | As `var` | Median of the finite draws |
| `p95` | Numeric | As `var` | 95th percentile of the finite draws |
| `n_bad` | Integer | count | Draws that were not finite in that cell and were left out of the percentiles; 0 or 1 in this file |

### out/coverage_rdbyi.csv

**Table H4.** Observed values and nominal 90% bands at the longest horizon of each benchmark plot, 318 rows: 53 plots by two treatments of SDImax by three variables. Bands are from 300 draws with binomial sampling of survivors added. Rows carry no plot identifier, so rows of the same plot can be matched only by `planted` and `h`.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `planted` | Integer | none | 1 planted, 0 natural |
| `h` | Integer | yr | Longest horizon of the plot: years from its first eligible visit to its last usable visit, which for a thinned installation is the last visit before its first removal year |
| `site_dev` | Logical | none | FALSE: SDImax centred on the plot's out-of-fold S1 prediction. TRUE: S1 with a plot-level lognormal deviation, as in Table H3 |
| `var` | Text | none | `surv` (proportion of starting stems surviving), `qmd` (cm) or `ba` (m² ha⁻¹) |
| `obs` | Numeric | As `var` | Observed value at horizon `h` |
| `lo` | Numeric | As `var` | 5th percentile of the draws |
| `hi` | Numeric | As `var` | 95th percentile of the draws |
| `inside` | Logical | none | TRUE when `obs` is at or between `lo` and `hi`, as evaluated at full precision in script 23t. Survival takes discrete values, so many survival observations sit on a band limit; in this file every such row is stored TRUE |

### out/benchmark_rdbyi.csv

**Table H5.** Observed and projected stand values for every benchmark plot-horizon, 182 rows on 53 plots (155 rows planted, 27 natural). Each plot is projected from its first visit with at least five live measured koa, with SDImax from S1 fitted without the plot's fold. Horizons of a thinned PSP installation stop before its first removal year. Rows carry no plot identifier.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `planted` | Integer | none | 1 planted, 0 natural |
| `h` | Integer | yr | Horizon: years from the plot's starting visit to the later visit |
| `o_surv` | Numeric | proportion | Observed survival: expansion-factor sum of starting trees still alive, over the starting sum |
| `p_surv` | Numeric | proportion | Projected survival: projected stems over starting stems |
| `o_qmd` | Numeric | cm | Observed QMD of the surviving starting trees |
| `p_qmd` | Numeric | cm | Projected QMD |
| `o_ba` | Numeric | m² ha⁻¹ | Observed basal area of the surviving starting trees |
| `p_ba` | Numeric | m² ha⁻¹ | Projected basal area |

### workbook/workbook_grid_rdbyi.csv

**Table H6.** Deterministic 200-year trajectories behind the yield workbook, 9,600 rows: three SDImax cases by four site classes by four starting densities by 200 ages. All rows are planted stands started from one real planted tree list rescaled to a QMD of 7.24 cm and to the stated stems per acre. Metric columns are the model outputs; the columns after `SDI` are unit conversions of them made in script 23t.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `sdimax` | Text | none | SDImax case: `central` (S1), `low` or `high` (S1 multiplied by the 10th or 90th percentile of the planted plots' deviations about S1) |
| `site` | Text | none | Site class: `Excellent`, `Good`, `Marginal` or `Low Feasibility` |
| `byi` | Integer | Mg ha⁻¹ | BYI of the site class: 450, 340, 230 or 120 |
| `stems_ac` | Integer | trees ac⁻¹ | Starting density: 100, 200, 300 or 400 |
| `sdimax_value` | Numeric | trees ha⁻¹ at 25.4 cm | SDImax used for the trajectory |
| `age` | Integer | yr | 1 to 200; the starting list is age 1, so age is the projection year plus 1 |
| `BA` | Numeric | m² ha⁻¹ | Basal area |
| `TPH` | Numeric | trees ha⁻¹ | Stems |
| `QMD` | Numeric | cm | Quadratic mean diameter |
| `HT` | Numeric | m | Basal-area-weighted mean height |
| `VOL` | Numeric | m³ ha⁻¹ | Assumed volume, 0.40 × BA × HT; not a fitted volume |
| `RD` | Numeric | none | Relative density, SDI over `sdimax_value` |
| `SDI` | Numeric | trees ha⁻¹ at 25.4 cm | Stand density index |
| `BA_ft2ac` | Numeric | ft² ac⁻¹ | `BA` × 4.356 |
| `QMD_in` | Numeric | in | `QMD` / 2.54 |
| `TPA` | Numeric | trees ac⁻¹ | `TPH` / 2.471054 |
| `HT_ft` | Numeric | ft | `HT` × 3.28084 |
| `VOL_ft3ac` | Numeric | ft³ ac⁻¹ | `VOL` × 14.2913 |
| `VBAR` | Numeric | not determined | 95 × `HT` over the height of the central, Good, 200 stems per acre trajectory at age 45; the unit and the source of the constant 95 are not stated in the script |

### workbook/workbook_logistic_rdbyi.csv

**Table H7.** Three-parameter logistic curves fitted by least squares to the basal area trajectories of Table H6, 48 rows: one per SDImax case, site class and starting density. The curve is `BA_ft2ac` = *A* / (1 + exp(−(age − *B*) / *C*)). It is a summary of the grid for the workbook and is not part of the growth system.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `sdimax` | Text | none | SDImax case, as in Table H6 |
| `site` | Text | none | Site class, as in Table H6 |
| `byi` | Integer | Mg ha⁻¹ | BYI of the site class |
| `stems_ac` | Integer | trees ac⁻¹ | Starting density |
| `A` | Numeric | ft² ac⁻¹ | Asymptote of the curve fitted to ages 1 to 60 |
| `B` | Numeric | yr | Age at half the asymptote, ages 1 to 60 |
| `C` | Numeric | yr | Scale, ages 1 to 60 |
| `rmse` | Numeric | ft² ac⁻¹ | Root mean square error of the curve against the grid, ages 1 to 60 |
| `rmse_pct` | Numeric | % | `rmse` as a percentage of mean grid basal area, ages 1 to 60 |
| `e40` | Numeric | ft² ac⁻¹ | Grid minus curve at age 40 |
| `e52` | Numeric | ft² ac⁻¹ | Grid minus curve at age 52 |
| `A100` | Numeric | ft² ac⁻¹ | Asymptote of the curve fitted to ages 1 to 100 |
| `B100` | Numeric | yr | Age at half the asymptote, ages 1 to 100 |
| `C100` | Numeric | yr | Scale, ages 1 to 100 |
| `rmse_pct100` | Numeric | % | Root mean square error as a percentage of mean grid basal area, ages 1 to 100 |

### workbook/workbook_diag_rdbyi.csv

**Table H8.** Diagnostics of each trajectory of Table H6, 48 rows: one per SDImax case, site class and starting density. Basal areas are in the imperial units of the workbook.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `sdimax` | Text | none | SDImax case, as in Table H6 |
| `site` | Text | none | Site class, as in Table H6 |
| `byi` | Integer | Mg ha⁻¹ | BYI of the site class |
| `stems_ac` | Integer | trees ac⁻¹ | Starting density |
| `sdimax_value` | Numeric | trees ha⁻¹ at 25.4 cm | SDImax used for the trajectory |
| `BA20`, `BA40`, `BA52`, `BA100`, `BA200` | Numeric | ft² ac⁻¹ | Basal area at ages 20, 40, 52, 100 and 200 |
| `peakBA` | Numeric | ft² ac⁻¹ | Largest basal area over the 200 ages |
| `peak_age` | Integer | yr | Age of `peakBA` |
| `decline_pct` | Numeric | % | 100 × (1 − `BA200` / `peakBA`) |
| `stems52` | Numeric | trees ac⁻¹ | Stems at age 52 |
| `qmd52` | Numeric | in | QMD at age 52 |
| `reineke` | Numeric | none | Slope of ln(trees ac⁻¹) on ln(QMD in inches) over the 200 ages of the trajectory |
| `rises_to_peak` | Logical | none | TRUE when basal area never falls before its peak |
| `rd_max` | Numeric | none | Largest relative density over the 200 ages |
| `sdi_max` | Numeric | trees ha⁻¹ at 25.4 cm | Largest SDI over the 200 ages |

### workbook/workbook_crossover_rdbyi.csv

**Table H9.** Ordering of basal area by site class in the central SDImax case, 4 rows: one per starting density. Site order means Low Feasibility at or below Marginal, Marginal at or below Good, and Good at or below Excellent.

| Column | Type | Unit | Meaning |
|:---:|:---:|:---:|:---:|
| `stems_ac` | Integer | trees ac⁻¹ | Starting density |
| `first_inversion` | Integer | yr | First age at which basal area is not in site order |
| `exc_minus_low_100` | Numeric | ft² ac⁻¹ | Basal area of Excellent minus Low Feasibility at age 100 |
| `low_minus_exc_200` | Numeric | ft² ac⁻¹ | Basal area of Low Feasibility minus Excellent at age 200 |
