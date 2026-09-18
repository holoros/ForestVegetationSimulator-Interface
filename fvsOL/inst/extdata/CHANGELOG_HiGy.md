# HiGy.R changelog

## 0.3.0 (2026-09-18)

Branch ClaudeDevelopment, based on MidgardNaturalResources main at c4e7336. Files changed: fvsOL/inst/extdata/HiGy.R, fvsOL/inst/extdata/customRun_fvsRunHi.R (one comment), this file.

All constants come from the koa growth and yield refit of 2026-09-17 on the deduplicated fitting frames (manuscript v101, Zenodo deposit 1.8.0 when published). Every equation below was checked against the Python engine of record (koa_equations.py, LineageA) on a 40 case grid through calc_ht(), calc_ddbh() and calc_dht(), with zero difference in height, diameter increment and height increment.

### Total height (ht.pred.parm, pred_ht, calc_ht)

Refit on 9,066 records over 143 installations. Relative diameter is now dbh divided by the plot maximum dbh, bounded at 1, which is the covariate the equation was fitted on. The previous code used dbh divided by quadratic mean diameter. calc_plot_summary() gains dbhmax and calc_ht() passes it in place of qmd. The base row keeps the site row with the BYI slope a1 set to zero, as in 0.2.0.

| Parameter | 0.2.0 | 0.3.0 |
|---|---|---|
| a0 | 19.832 | 29.602570 |
| a1 | 0.106 | 1.113977 |
| b | 0.044 | 0.018602 |
| c | 0.863 | 0.809098 |
| g1 | -0.198 | 0.061037 |
| g2 | 0.479 | -0.346588 |

### Diameter increment (ddbh.parm, ddbh, calc_ddbh)

Refit on 4,842 rows. The planted term is b7 times planted times pmin(dbh, 45), the 45 cm bound being the upper edge of the planted fitting support. A planted level shift b9 is added. The Duan correction factor is 1.34728 (was 1.026, which was a withdrawn value). An origin calibration multiplier (origin.calib.parm, natural 0.43437, planted 1.53553) is applied inside ddbh() before the 0 to 4 cm constraint, matching the engine of record. The base row sets b8 to zero as before.

| Parameter | 0.2.0 | 0.3.0 |
|---|---|---|
| b0 | -2.4704737 | -2.3664829 |
| b1 | 0.2072221 | 0.5137942 |
| b2 | -0.0159616 | -0.0308719 |
| b3 | -0.0016893 | -0.0019559 |
| b4 | -0.2972574 | -0.3238710 |
| b5 | -0.4470330 | -0.0118847 |
| b6 | -0.0158403 | -0.0071952 |
| b7 | 0.0188938 | -0.0223510 |
| b8 | 0.4530166 | 0.3481424 |
| b9 | none | 0.4495101 |
| cf | 1.026 | 1.34728 |

### Height increment (dht.parm, dht, calc_dht)

Refit on 3,956 rows. The planted term is linear, b7 times planted times pmin(ht, 20), where 0.2.0 used the square root of that product. A planted level shift b9 is added. The Duan correction factor stays at 1.030. An origin calibration multiplier (natural 0.54877, planted 2.73012) is applied inside dht() before the 0 to 2 m constraint.

calc_dht() now passes the plot basal area (ba.plot) to dht(). In 0.2.0 the call passed ba, which inside the mutate resolved to the tree record's own basal area rather than the plot total, so the b6 term was evaluated on the wrong quantity. This is a defect fix independent of the refit.

| Parameter | 0.2.0 | 0.3.0 |
|---|---|---|
| b0 | -3.382162 | -4.2936412 |
| b1 | 0.272454 | 1.2352052 |
| b2 | -0.105319 | -0.1476842 |
| b3 | -0.000829 | -0.0011966 |
| b4 | -0.071718 | -0.0542262 |
| b5 | -1.483889 | -1.6042988 |
| b6 | 0.033035 | 0.0574931 |
| b7 | 0.017887 | -0.1252505 |
| b8 | 0.433224 | 0.2216682 |
| b9 | none | 1.0300277 |

### Survival (surv.parm, surv_prob)

Refit of the death response cloglog on 4,919 rows with 77 deaths. Form unchanged. The base row zeroes b6 and b7 as before.

| Parameter | 0.2.0 | 0.3.0 |
|---|---|---|
| b0 | 18.133 | 14.673 |
| b1 | 0.199 | 0.151 |
| b2 | -5.718 | -4.860 |
| b3 | 7.640 | 7.036 |
| b4 | 15.678 | 14.893 |
| b5 | -3.396 | -3.065 |
| b6 | 3.039 | 2.631 |
| b7 | -25.102 | -21.378 |

### customRun_fvsRunHi.R

One comment updated to the new pred_ht() argument list. No functional change. The imputation block already builds plot.smry with calc_plot_summary(), so dbhmax is available to calc_ht() without further edits.

### Not in this release

The three stage mortality structure (stand level occurrence and rate with tree level allocation, natural level factor 2.46552) that the manuscript recommends before FVS-HI is used for projection is not in this commit. It follows as a separate commit on this branch with a reference implementation and a fixture set, so that the R port can be checked to tolerance against the Python engine.

The ingrowth equation is not implemented in HiGy.R (the Ingrowth section is a placeholder in 0.2.0 and stays so).

tree.size.cap carries max.height 92, which is in feet while the model runs in metres. Left as is pending review.

## 0.2.0

Integration of biomass yield index (BYI) and planted indicator.

## 0.1.0

Initial version.
