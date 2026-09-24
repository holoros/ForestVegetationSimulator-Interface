# HiGy.R changelog

## 0.4.0 (2026-09-23)

Branch ClaudeDevelopment. Files changed: fvsOL/inst/extdata/HiGy.R, fvsOL/inst/extdata/customRun_fvsRunHi.R, this file; new folder fvsOL/inst/extdata/HiGy_tests. Mortality only. No growth constant, no growth equation and no growth code path changed from 0.3.1: diff -w of the growth sections is empty, and the 40 case grid of the 0.3.1 commit through calc_ht(), calc_ddbh() and calc_dht() returns zero difference on this file.

### What changed

The three stage Acacia koa A.Gray mortality component replaces the tree level survivor equation as the production mortality path. It follows the structure of Chen et al. (2023).

- Stage 2 is the whole stand model of Garcia (2009), alpha = gamma = 2.96, run on H_QMD with beta anchored at 0.16019053617304435 m⁻¹ and the A1 background floor (0.003 yr⁻¹ natural, 0.006 yr⁻¹ planted).
- Stage 1 is a complementary log-log occurrence probability in ln(SDI) and origin, applied as a gate on the Stage 2 rate with the expectation over the fitting record preserved (rate divided by p_bar, multiplied by p).
- The origin mortality level factor is applied to the gated rate: 2.64629 natural, 1 planted.
- Stage 3 allocates the stand deaths to trees by the respecified tree level mortality equation of 16 September 2026 (Supplemental Table S12: ln DBH, relative height, ln plot BA, ln BAL), the weight the engine of record deploys, and renormalizes to the stand rate. The Eq. 5 survivor weight ('surv_eq5') and the as published relative size weight ('rel_size') stay reachable through alloc.mode.
- Stand quantities for Stage 2 and the gate are formed on koa records only. OT records take no modelled mortality and keep their expansion factor.
- calc_mortality() and make_ops() gain mort.engine. The default 'garcia' is the new component; 'cloglog' runs the 0.3.1 body unchanged, so every earlier projection is recoverable. make_ops() also gains irregular, mort.seed and planted.background, all off by default.
- customRun_fvsRunHi.R exposes the engine choice and the irregular switch in the run interface, logs which engine ran, and seeds the optional irregular stage once per stand cycle.

### Stage 1 constants synced

The production engine carrier (engine_v102 HiGy.R) still held the 12 September 2026 Stage 1 fit. 0.4.0 carries the 16 September 2026 refit, with stand origin recoded from establishment records and thinning removal intervals censored (290 plot intervals over 54 plots).

| Constant | 12 September fit | 0.4.0 |
|---|---|---|
| intercept | -1.8660048476490962 | -1.67856483466631 |
| ln(SDI) | 0.18970168229495396 | 0.161863756638461 |
| planted | 0.1833723331227772 | -0.19099361188623 |
| p_bar (mean annual occurrence) | 0.3600578102962374 | 0.313065206550519 |

The planted offset changes sign. Its 95% plot clustered interval is -2.114 to 0.222 and includes zero.

### Checked

The production rate path koa_step_deaths() and the Stage 3 allocation koa_alloc_frac() agree with the Python engine of record on the 18 case fixture set in HiGy_tests/ to a worst relative difference of 1.7e-14. The harness drives those functions directly on a shared H_QMD pair; calc_mortality() was checked separately by hand against the same algebra for a natural and a planted stand. The fixture set fails on 16 cases with the 12 September Stage 1 constants, on 9 natural cases with the level factor removed, and on 10 tree weight cases with the Eq. 5 weight in place of the respecified one, so it detects all three. HiGy_tests/smoke_higyonestand.R runs five years of HiGYOneStand() on a natural and a planted synthetic stand with one OT record, which keeps its expansion factor.

### Open, not decided here

The growth functions calc_ht(), calc_ddbh() and calc_dht() take byi and planted from a global `stand` by default, as in 0.3.1; customRun_fvsRunHi.R sets it. calc_mortality() now receives both from HiGYOneStand()'s own argument.

surv_prob() on the retired cloglog path returns exp(-exp(eta)), while the Python engine reads the same fit as a complementary log-log on the alive response. The production path is unaffected because Stage 3 uses the equation only as a renormalized ordering weight whose level cancels.

## 0.3.1 (2026-09-18)

Branch ClaudeDevelopment. Files changed: fvsOL/inst/extdata/HiGy.R, this file. Constants only. No equation form, no function signature and no code path changed from 0.3.0.

### Why the constants moved

On 18 September the data owner reversed two of the three deduplication assumptions that the 0.3.0 constants (fitting set v101) were built on.

- At a doubled tree visit the record with the LARGER age, that is the LATER field visit, is now the record kept. 0.3.0 kept the earlier one.
- Where the two record sets of a plot visit disagree on live status, the LATER record set is now kept. 0.3.0 kept the earlier one.
- The collapse of byte identical rows is unchanged.
- The 2012 PSP 202 to 204 measurement, whose diameters were taken below breast height, is KEPT and flagged as a limitation rather than dropped.

Every fitting frame was rebuilt on that basis and every constant in this file was refit on the rebuilt frames (fitting set v102). The frames are smaller than v101 wherever the conflict visits bite. Each frame passes its uniqueness gate. Height is fitted on 9,059 records over 143 installations; diameter increment on 4,790 rows; height increment on 3,857 rows; survival on the rebuilt deposit table of 4,869 rows with 79 deaths over 62 installations.

The diameter increment likelihood again has two optima. The vector below is the DEPLOYED START optimum, log likelihood minus 9,450.63, which is the higher of the two. The record start optimum (minus 9,453.74) is NOT shipped.

### Total height (ht.pred.parm)

| Parameter | 0.3.0 | 0.3.1 |
|---|---|---|
| a0 | 29.602570 | 32.198224 |
| a1 | 1.113977 | 1.208508 |
| b | 0.018602 | 0.016579 |
| c | 0.809098 | 0.804891 |
| g1 | 0.061037 | 0.062077 |
| g2 | -0.346588 | -0.373262 |

All six terms sit within 2.2 record standard errors. The base row keeps a1 at zero as before.

### Diameter increment (ddbh.parm, ddbh, origin.calib.parm)

| Parameter | 0.3.0 | 0.3.1 |
|---|---|---|
| b0 | -2.3664829 | -1.1509411 |
| b1 | 0.5137942 | 0.3371168 |
| b2 | -0.0308719 | -0.0143456 |
| b3 | -0.0019559 | -0.0017722 |
| b4 | -0.3238710 | -0.4306515 |
| b5 | -0.0118847 | 1.2809352 |
| b6 | -0.0071952 | -0.0176013 |
| b7 | -0.0223510 | -0.0176238 |
| b8 | 0.3481424 | 0.3045245 |
| b9 | 0.4495101 | 0.4103534 |
| cf (Duan) | 1.34728 | 1.36869 |
| origin multiplier, natural | 0.43437 | 0.40548 |
| origin multiplier, planted | 1.53553 | 1.43606 |

The movement is in the competition and crown block, not the level block. b4 and b5 move by about 6.6 to 6.7 record standard errors in opposite directions, so the crown ratio term changes sign, while b0, b8 and b9 stay within 1.3 standard errors of the record.

### Height increment (dht.parm, dht, origin.calib.parm)

| Parameter | 0.3.0 | 0.3.1 |
|---|---|---|
| b0 | -4.2936412 | -3.6114059 |
| b1 | 1.2352052 | 1.1203441 |
| b2 | -0.1476842 | -0.1154809 |
| b3 | -0.0011966 | -0.0009067 |
| b4 | -0.0542262 | -0.1332027 |
| b5 | -1.6042988 | -0.5250905 |
| b6 | 0.0574931 | 0.0379597 |
| b7 | -0.1252505 | -0.1240880 |
| b8 | 0.2216682 | 0.2232825 |
| b9 | 1.0300277 | 1.0681935 |
| cf (Duan) | 1.030 | 1.030 (unchanged) |
| origin multiplier, natural | 0.54877 | 0.51917 |
| origin multiplier, planted | 2.73012 | 2.64739 |

Both fitting starts converge to the same optimum, so this vector is fully identified. The same crown ratio and competition rotation appears here as in the diameter increment.

### Survival (surv.parm, Eq. 5)

Updated in place on the rebuilt table. The vector moves by less than a quarter of a standard error on every term, so Eq. 5 is effectively unchanged by the ruling.

| Parameter | 0.3.0 | 0.3.1 |
|---|---|---|
| b0 | 14.673 | 14.132 |
| b1 | 0.151 | 0.132 |
| b2 | -4.860 | -4.571 |
| b3 | 7.036 | 6.721 |
| b4 | 14.893 | 14.302 |
| b5 | -3.065 | -2.914 |
| b6 | 2.631 | 2.588 |
| b7 | -21.378 | -20.968 |

The base row zeroes b6 and b7 as before.

### Parity

Checked against the Python engine of record (engine_v102, koa_equations.py, LineageA) on a 40 case grid driven through the deployed wrappers calc_ht(), calc_ddbh() and calc_dht(). Maximum absolute difference zero in height, zero in diameter increment and zero in height increment, including the two cases that reach the 2 m per year height increment cap, which cap identically on both sides. A five year HiGYOneStand run on planted and natural synthetic stands completes without error.

NOTE ON THE STAGE 1 SYNCHRONISATION. The cross language parity harness for the three stage mortality component does not pass as shipped in the research engine, under v102 constants or under the constants of record, because that engine's HiGy.R mirror carries a pre origin Stage 1 block while the deployed out_stage1/stage1_fit.json carries the 16 September origin refit, the planted offset differing in sign between the two. With the four constants synchronised the harness passes exactly, 18 cases at 12 decimal places on rates and 6 on per tree deaths. That block does NOT exist in this file, because the three stage mortality is not in this release (see below), so there is nothing here to synchronise. The fix travels with the mortality commit.

### Not in this release

The three stage mortality structure (stand level occurrence and rate with tree level allocation) that the manuscript recommends before FVS-HI is used for projection is not in this commit. It follows as a separate commit on this branch with a reference implementation and a fixture set, so that the R port can be checked to tolerance against the Python engine. Its constants are now the v102 set, which includes the natural mortality level factor 2.646 in place of the v101 2.46552, and the four synchronised Stage 1 constants described above.

The ingrowth equation is not implemented in HiGy.R (the Ingrowth section is a placeholder in 0.2.0 and stays so).

tree.size.cap carries max.height 92, which is in feet while the model runs in metres. Left as is pending review.

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

The three stage mortality structure (stand level occurrence and rate with tree level allocation, natural level factor 2.46552 under the v101 fitting set, now 2.646 under v102) that the manuscript recommends before FVS-HI is used for projection is not in this commit. It follows as a separate commit on this branch with a reference implementation and a fixture set, so that the R port can be checked to tolerance against the Python engine.

The ingrowth equation is not implemented in HiGy.R (the Ingrowth section is a placeholder in 0.2.0 and stays so).

tree.size.cap carries max.height 92, which is in feet while the model runs in metres. Left as is pending review.

## 0.2.0

Integration of biomass yield index (BYI) and planted indicator.

## 0.1.0

Initial version.
