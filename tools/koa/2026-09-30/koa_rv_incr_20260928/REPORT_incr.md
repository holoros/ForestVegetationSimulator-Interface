10-LINE SUMMARY
1. Gate passed: the Eq. 4 refit reproduces the Table 4 vector exactly (max |Δfixef| = 0; logLik −9,450.628 and −6,661.498). The dDBH multipliers match the engine (0.40548, 1.43606). The dHT multipliers are off in the 4th significant figure (0.51911 vs 0.51917, 2.64761 vs 2.64739).
2. BAL means on the dDBH frame (m² ha⁻¹): deposited 6.09, simulator live list 8.90, conventional 11.18. The simulator's BAL lowers predicted dDBH to 0.903 (95% installation-cluster 0.885 to 0.922) and 0.694 in the top quintile. For dHT it is 0.958 overall and 0.861 in the top quintile.
3. With conventional BAL the prediction falls to 0.825 overall and 0.600 in the top quintile, versus the 10.6% and 27% now printed in [P154]. A conventional-BAL refit has ΔAIC −221.9 and −59.1, but dDBH b9 becomes −0.342 (P = 0.136) and the multipliers 0.313 and 2.270.
4. The builder drops 713 of 5,540 dDBH intervals (348 negative, 365 zero) and 929 dHT intervals (694 negative, 235 zero). Short intervals are hit twice as often (14.4% vs 7.3%). Keeping them gives k 0.376 and 1.174 (dDBH) and 0.349 and 1.667 (dHT).
5. Kulani plot 12 (planted) vs plot 23 (natural), adjusted for covariates: 1.36 (tree-cluster 0.98 to 1.76) for dDBH and 0.77 (0.60 to 0.99) for dHT. The deployed system implies 3.82 and 3.78. The other within-source contrasts: DOFAW 1.44 and 0.76, PSP 1.69 and 2.12 (PSP rests on 5 natural trees).
6. With source as a fixed effect: dDBH b9 is 0.260 (P = 0.306) and the dDBH multipliers are 0.737 and 0.824. dHT b9 holds at 1.008. A DOFAW-only full refit cannot be identified.
7. The bootstrap stopped at 980 of the 2,000 planned draws per response; all 980 converged. The source variance collapsed (τ < 0.01) in 734 of 980 dDBH draws and 335 of 980 dHT draws. Bootstrap SEs are 1.8 to 5.7 times the Wald SEs.
8. Bootstrap 95% percentile intervals. b9: dDBH −0.103 to 2.248 (p_boot 0.073), dHT 0.450 to 3.889. ln(BYI): 0.007 to 0.842 and −0.046 to 0.848. The height bootstrap and the height tree random effect produced no output.
9. The calibrated system is unbiased on 1-year planted intervals (dDBH 1.006, 0.914 to 1.116). It overpredicts 3 to 5 year planted intervals (0.363, 0.262 to 0.477; 9 installations). The 3-year PSP periods (0.485, 0.287) sit below every 1-year period covering the same years.
10. Other sensitivities, ΔAIC for dDBH / dHT: no-CR +26.9 / +1.5 (dDBH b9 goes to 1.019); tree RE −274.6 / −57.5; 1/YIP variance weighting +3,291 / +1,951. Supplement errors found: the CF formula in [P35] and [T57] needs squared SDs, and [P35] says "109 planted DOFAW records" where the frame has 94.

---

# koa_rv_incr_20260928: increment equations (Eq. 4), BAL definition, excluded increments, within-source origin contrast, cluster bootstrap and sensitivities

The job ran on September 28, 2026 (logs 15:04 to 19:43 server time) in `~/jobs/koa_rv_incr_20260928`, unpacked at `/tmp/koa/work/incr/`. This report was written on September 29, 2026 from the unpacked outputs, logs and scripts only. It covers reviewer items R1 c1a, c1b, c3, c4, c5 and c6, as labeled in the script headers. Every number comes from a CSV in `out/` or a line in `logs/`. Where a quantity is not in the files, the report says so. Every interval is named by type.

Three points come first.

* **The installation-cluster bootstrap stopped at 980 of the planned 2,000 draws.** `boot_meta.csv` summarizes draws 1 to 980 for both responses, and all 980 converged. The raw files hold 992 dDBH and 1,352 dHT draws; the summary was cut at the common 980. Neither log has the `BOOT DONE` line, so both runs were cut off before finishing. **The data-source random intercept collapsed (τ source < 0.01) in 734 of 980 dDBH draws (74.9%) and in 335 of 980 dHT draws (34.2%).** Draw index sets were generated up front from seed 20260928, and the script skips draws already done. The run can therefore be resumed to 2,000 without changing draws 1 to 980.
* **The height (Eq. 2) bootstrap and the height tree random effect produced no results.** `boot_height.csv` and `height_treeRE.csv` do not exist. `logs/boot_height.log` stops after the three-level tree fit failed ("Singularity in backsolve at level 0, block 1"), and `s2_height_treere.R` has no log. `height_ref_and_treeRE.csv` holds only the reproduced reference vector.
* **Two text errors in the current supplement.** Section 3 Step 2 [P35] and the Table S8 notes [T57] give the marginal factor as exp(0.5 × (0.5862 + 0.5332)), which evaluates to 1.750. The deployed 1.369 is exp(0.5 × (0.5862² + 0.5332²)), so the two standard deviations must be squared. [P35] also cites "the 109 planted DOFAW records (0.32)", but the v102 dDBH frame and Table S20 have 94 planted DOFAW records.

---

## 0. Reproduction gate (s0_reference.R)

**Method.** `s0_reference.R` refits Eq. 4 with the track2 fit path (`fit_ref` in `common.R`):
* nlme with fixed b0 to b9 and random b0 ~ 1 | Data/Install;
* varPower(0.2, ~DBH.0);
* PSP Planted recoded from `psp_origin_thinning_2026-09-16_DATA.csv`;
* complete cases only.

It starts from the deployed-start vector hard coded in the script and compares the result with `inc_fits.rda` ("V102 deployed_solution"). It then recomputes the origin multipliers, k = Σ observed annual ÷ Σ (level-0 annual prediction × CFX) within origin, with CFX = 1.36869 (dDBH) and 1.030 (dHT). The multiplier intervals come from a 2,000-draw installation-cluster percentile bootstrap (seed 20260928).

| Response | n | logLik | max abs. diff. fixef vs inc_fits.rda | k natural (95% inst.-cluster percentile) | k planted | Conditional R² (period) | Calibrated PA R² (annual) |
|---|---|---|---|---|---|---|---|
| ΔDBH | 4,790 | −9,450.628 | 0 | 0.40548 (0.367 to 0.489) | 1.43607 (1.299 to 1.597) | 0.4627 | 0.3171 |
| ΔHT | 3,857 | −6,661.498 | 0 | 0.51911 (0.312 to 0.612) | 2.64761 (2.398 to 2.879) | 0.1516 | 0.2412 |

**Interpretation.** The gate passes. The refit returns the Table 4 vector exactly, and the dDBH multipliers reproduce the engine constants.

The dHT multipliers differ from the engine constants in the fourth significant figure (0.51911 against 0.51917, 2.64761 against 2.64739). The files do not show why.

The multiplier intervals differ slightly from those in [P45] (0.368 to 0.496, 1.286 to 1.594, 0.331 to 0.616, 2.395 to 2.891). The resamples differ: this job used seed 20260928, and the manuscript names 20260916. No text change is proposed for this.

Every analysis below uses this reference fit and, where they apply, the deployed multipliers 0.40548, 1.43606, 0.51917 and 2.64739.

---

## 1. BAL: deposited, simulator live list, conventional (R1 c5)

**Question.** In the fitting frame, BAL is (1 − BA.perc) × BAPH, where BA.perc is a stem-count percentile over every record in the plot-year, dead and zero-diameter records included. The simulator ranks only the live list, and a reuser would compute conventional BAL. How far apart are the three? What does each do to predicted increment? What happens if Eq. 4 is refitted on conventional BAL?

**Method.** `s4_bal_build.R` works through every plot-year of `AK_TREE_v102.csv` (17,074 tree rows, 870 plot-years) and computes three versions:
* BALd, the deposited rule, as a check.
* BALl, the simulator rule (the `koa_equations.stand_bal` path): the same count percentile, but over live records with DBH > 0, times recorded BAPH.
* BALc, conventional BAL: the expansion-weighted basal-area share of live trees strictly larger than the subject, times recorded BAPH. It equals the direct sum wherever the live list rebuilds recorded BAPH. Weights are set to 1 in plot-years where all live expansion factors are zero. The direct sum is kept separately as BALc_sum.

All frame rows matched at both t0 and t1.

`s_sens.R balconv` refits Eq. 4 with BAL.0 and BAL.1 replaced by BALc.

`s_eval.R` part A evaluates predictions with coefficients held fixed, in population-average form × CFX × origin multiplier. The reference uses the deployed multipliers and the refit uses its own. Results are given overall, by quintile of live-list BAL at interval start, and by origin. Intervals come from 2,000 installation-cluster bootstrap resamples of the evaluation records, percentile, conditional on the fitted coefficients (seed 20260928).

**Reproduction check.** The deposited rule reproduces BA.perc to 1 × 10⁻⁶ on 82.8% of tree rows (bal_build.log). It reproduces the frame's BAL.0 on 75.8% of dDBH rows and 74.3% of dHT rows (bal_summary.csv). Both rates are below the 94.9% and 88.8% in [P34], which use different denominators. The frame BAL, not BALd, was used throughout, so this check only affects how exactly the deposited rule can be described.

**BAL means** (m² ha⁻¹, bal_summary.csv).

| Frame | n | Deposited (frame) | Live list (simulator) | Conventional | Conventional, direct sum | Share whose live list rebuilds BAPH | cor(dep, conv) | cor(dep, live) | Mean BAPH |
|---|---|---|---|---|---|---|---|---|---|
| ΔDBH | 4,790 | 6.09 | 8.90 | 11.18 | 9.86 | 0.847 | 0.908 | 0.923 | 19.77 |
| ΔHT | 3,857 | 5.53 | 8.26 | 10.46 | 9.03 | 0.841 | 0.904 | 0.918 | 18.84 |

By origin on the ΔDBH frame, natural records average 3.98 deposited against 10.44 conventional, and planted records 6.65 against 11.38.

**Prediction ratios, ΔDBH** (eval_bal.csv). Each value is a ratio of summed annual values with a 95% installation-cluster percentile interval, conditional on coefficients.
* "Live / dep." is the prediction under the simulator's BAL divided by the prediction under the fitting BAL.
* "Conv / dep." is derived as the quotient of the two observed ÷ predicted point ratios, which share the same observed sum, so it has no interval.
* "Obs / conv refit" is the recalibrated conventional-BAL refit scored on conventional BAL.

| Group | n | Mean BAL dep / live / conv | Obs / deployed, deposited BAL | Live / dep. prediction | Obs / deployed, live-list BAL | Conv / dep. (derived) | Obs / conv refit |
|---|---|---|---|---|---|---|---|
| All | 4,790 | 6.09 / 8.90 / 11.18 | 1.000 (0.911 to 1.104) | 0.903 (0.885 to 0.922) | 1.107 (1.017 to 1.207) | 0.825 | 1.000 (0.914 to 1.096) |
| Q1 | 958 | 0.22 / 0.25 / 0.44 | 0.934 (0.833 to 1.048) | 0.984 (0.978 to 0.988) | 0.950 (0.849 to 1.072) | 0.945 | 0.970 (0.885 to 1.053) |
| Q2 | 958 | 1.51 / 1.95 / 3.16 | 0.983 (0.844 to 1.135) | 0.928 (0.905 to 0.946) | 1.060 (0.926 to 1.197) | 0.825 | 0.967 (0.856 to 1.079) |
| Q3 | 960 | 3.66 / 4.84 / 7.03 | 1.047 (0.931 to 1.159) | 0.883 (0.856 to 0.906) | 1.186 (1.067 to 1.308) | 0.786 | 0.972 (0.860 to 1.092) |
| Q4 | 956 | 7.08 / 10.05 / 13.47 | 1.062 (0.917 to 1.211) | 0.837 (0.795 to 0.872) | 1.269 (1.131 to 1.421) | 0.736 | 0.993 (0.861 to 1.126) |
| Q5 | 958 | 17.99 / 27.40 / 31.84 | 1.096 (0.873 to 1.334) | 0.694 (0.632 to 0.747) | 1.579 (1.296 to 1.894) | 0.600 | 1.300 (1.056 to 1.572) |
| Natural | 1,000 | 3.98 / 7.40 / 10.44 | 1.000 (0.905 to 1.225) | 0.767 (0.723 to 0.812) | 1.303 (1.181 to 1.602) | 0.644 | 1.000 (0.805 to 1.177) |
| Planted | 3,790 | 6.65 / 9.29 / 11.38 | 1.000 (0.902 to 1.101) | 0.913 (0.898 to 0.929) | 1.095 (0.993 to 1.199) | 0.838 | 1.000 (0.910 to 1.103) |

**Prediction ratios, ΔHT** (selected groups; the full set is in eval_bal.csv).

| Group | n | Obs / deployed, deposited | Live / dep. | Obs / deployed, live-list | Conv / dep. (derived) | Obs / conv refit |
|---|---|---|---|---|---|---|
| All | 3,857 | 1.000 (0.911 to 1.084) | 0.958 (0.949 to 0.967) | 1.044 (0.955 to 1.131) | 0.922 | 1.000 (0.910 to 1.086) |
| Q1 | 772 | 0.953 (0.854 to 1.050) | 0.995 (0.993 to 0.997) | 0.958 (0.859 to 1.051) | 0.984 | 0.968 (0.869 to 1.068) |
| Q3 | 774 | 1.057 (0.905 to 1.216) | 0.966 (0.956 to 0.974) | 1.094 (0.939 to 1.254) | 0.928 | 1.040 (0.897 to 1.190) |
| Q5 | 772 | 1.031 (0.871 to 1.175) | 0.861 (0.832 to 0.888) | 1.197 (1.023 to 1.340) | 0.794 | 1.052 (0.897 to 1.178) |
| Natural | 762 | 1.000 (0.666 to 1.185) | 0.885 (0.873 to 0.903) | 1.129 (0.719 to 1.360) | 0.814 | 1.000 (0.643 to 1.189) |
| Planted | 3,095 | 1.000 (0.906 to 1.095) | 0.962 (0.954 to 0.970) | 1.039 (0.941 to 1.134) | 0.928 | 1.000 (0.911 to 1.091) |

**Conventional-BAL refit** (sens_balconv_*). Same records and the same number of parameters as the reference; reference values in parentheses.

| Response | logLik (ref) | ΔAIC | b4 ln(BAL+1) (ref) | b3 (ref) | b9 Planted (ref) | k natural (95% inst.-cluster) | k planted | Calibrated PA R² (ref) |
|---|---|---|---|---|---|---|---|---|
| ΔDBH | −9,339.66 (−9,450.63) | −221.9 | −0.252, SE 0.019 (−0.431) | −0.00260 (−0.00177) | −0.342, SE 0.229, P = 0.136 (0.410) | 0.313 (0.248 to 0.368) | 2.270 (2.061 to 2.495) | 0.336 (0.317) |
| ΔHT | −6,631.94 (−6,661.50) | −59.1 | −0.090, SE 0.022 (−0.133) | −0.00081 (−0.00091) | 1.040, SE 0.204 (1.068) | 0.513 (0.295 to 0.609) | 2.859 (2.581 to 3.101) | 0.244 (0.241) |

Other ΔDBH terms also move under conventional BAL:
* b5 ln(CR): 0.443, P = 0.099 (reference 1.281).
* b6: 0.0023, P = 0.48 (reference −0.0176).
* b7: −0.0311 (reference −0.0176).
* b8 ln(BYI): 0.081, P = 0.315 (reference 0.305).

**Interpretation.** The simulator's live-list BAL is higher than the fitting BAL (8.90 against 6.09 m² ha⁻¹). Under the published coefficients it lowers predicted diameter increment by 9.7% overall (0.903, 0.885 to 0.922), by 30.6% in the most competitive quintile and by 23.3% in natural records. For height the reduction is 4.2% overall and 13.9% in the top quintile. When fed the BAL the simulator actually computes, the deployed system underpredicts its own diameter fitting data: observed exceeds predicted by 10.7% (1.107, 1.017 to 1.207). [P154] said this effect had not been separated; it now has been.

A reuser who feeds conventional BAL would lower predicted diameter increment by 17.5% overall and by 40% in the top quintile. That is more than the 10.6% and 27% now in [P154], which evidently came from an earlier frame. The [P153] means of 6.35 and 12.05 m² ha⁻¹ and correlation of 0.862 also do not match this frame (6.09, 11.18 and 0.908).

Refitting on conventional BAL improves the likelihood a lot at equal parameter count (ΔAIC −222 and −59). But it:
* removes the positive diameter level shift (b9 −0.342, P = 0.136);
* makes the diameter ln(BYI) term non-significant;
* widens the gap between the diameter multipliers (0.313 and 2.270);
* still underpredicts the top quintile by 30% (1.300, 1.056 to 1.572).

The consistent fix would be to refit on the live-list BAL the simulator uses; that fit was not run in this job. The alternative is to keep the current fit and document the roughly 10% simulator shift.

**Proposed main text: new sentence at the end of [P58].**

> Because the simulator ranks the live tree list, which carries no dead or zero-diameter records, its BAL averages 8.90 m² ha⁻¹ on the diameter increment records against 6.09 m² ha⁻¹ for the deposited definition on which Eq. 4 was fitted, and under the published coefficients this lowers predicted diameter increment by 9.7% (95% installation-cluster interval 7.8 to 11.5%) and height increment by 4.2% (3.3 to 5.1%), with the largest reductions, 31% and 14%, on the most competitive fifth of stems (Supplemental Section 8.3).

**Proposed supplement text: replaces the last sentence of [P33]** ("In projection the percentile is computed directly over the live tree list ... (Section 8.3).").

> In projection the percentile is computed over the live tree list, which contains no dead or zero-diameter records, so the simulator's BAL for a given stem is higher than the deposited value and lies between the deposited definition and a conventional one, at means of 6.09 (deposited), 8.90 (live list) and 11.18 m² ha⁻¹ (conventional) on the diameter increment records (Section 8.3).

**Proposed supplement text: replaces [P153] and [P154].**

> Basal area in larger trees is not a direct sum over larger stems in this system. It is stand basal area allocated by a stem-count percentile taken over a population that includes dead and zero-diameter records, so the deposited quantity is systematically smaller than the textbook quantity. On the 4,790 diameter increment records it averages 6.09 m² ha⁻¹, against 8.90 m² ha⁻¹ when the same percentile is taken over the live list, as the simulator does, and 11.18 m² ha⁻¹ for the expansion-weighted basal-area share of live competitors strictly larger than the subject tree times recorded stand basal area (9.86 m² ha⁻¹ as a direct sum, which differs where the live list does not rebuild recorded stand basal area, on 15.3% of records). The deposited quantity correlates at 0.908 with the conventional one and at 0.923 with the live-list one. The understatement is larger in natural records, at 3.98 against 10.44 m² ha⁻¹, than in planted records, at 6.65 against 11.38 m² ha⁻¹.
>
> Under the published increment coefficients, and with every other covariate at its recorded value, the live-list BAL of the simulator lowers predicted annual diameter increment to 0.903 (95% installation-cluster interval 0.885 to 0.922) of the prediction under the fitting definition, and height increment to 0.958 (0.949 to 0.967). The shift is monotone in competition, from 0.984 in the least competitive quintile of live-list BAL to 0.694 (0.632 to 0.747) in the most competitive for diameter and from 0.995 to 0.861 (0.832 to 0.888) for height, and it is larger for natural stems (0.767 for diameter) than for planted stems (0.913). Driven by the BAL it computes in projection, the calibrated system therefore underpredicts its own diameter fitting data by about a tenth, and in the most competitive quintile observed increment exceeds the prediction by more than half (1.579, 1.296 to 1.894), in the same direction as the diameter underprediction on the 23-plot validation. A reuser who computes BAL conventionally and feeds these coefficients would lower predicted diameter increment to 0.825 of the fitted value overall and to 0.600 in the most competitive quintile, and height increment to 0.922 and 0.794. Refitting Eq. 4 on conventional BAL improves the fit at equal parameter count, lowering AIC by 221.9 for diameter and 59.1 for height increment, and the refitted, recalibrated diameter form is unbiased overall but still underpredicts the most competitive quintile (1.300, 1.056 to 1.572). The refit is not deployed because it changes the diameter origin contrast (planted level shift −0.342, P = 0.136, with multipliers of 0.313 natural and 2.270 planted) and the diameter ln(BYI) term (0.081, P = 0.315), so every projection would change. The fit statistics of the deployed equations are unaffected, since they were fitted and evaluated on the deposited quantity, and the definition in Section 3 is what makes the system reimplementable.

---

## 2. Excluded zero and non-positive increments (R1 c4)

**Question.** How many zero and negative increments does the frame builder drop, and where are they? Do the coefficients and multipliers depend on dropping them?

**Method.**
* `s3_zero_counts.R` applies the builder rule of `builders/build_frames_incr.R`: live at both ends, DBH > 0 at both, YIP > 0, and 0 < ΔDBH ÷ YIP < 10, with height additionally 0 < ΔHT ÷ YIP < 10. It applies this to `AK.TREE.incr_v102.csv` joined to the plot keys (key columns only) of `PLT.GEO.V2_v102.csv`, and counts each exclusion.
* `s3_nonpos_build.R` rebuilds the frames with the lower bound removed. Every v102 row is kept exactly and the restored rows are appended (`*_nonpos.csv`).
* `s_sens.R nonpos` refits Eq. 4 on those frames from the reference and record starts, keeping the best likelihood.
* `s_eval.R` part C computes the multipliers the reference equation would carry if the restored rows were counted, with 2,000 installation-cluster bootstrap resamples (percentile, conditional on coefficients).

Note that the Eq. 4 fit takes the periodic increment on the original scale as its response (`dDBH ~ gr.hat3(...)` in `common.R`), which is why non-positive values can enter the refit. The body of `gr.hat2` is in `origin_refit_REFERENCE_COPY.R`, which is not among the unpacked files. How interval length and the start and end covariates enter the fit therefore cannot be read here.

**Counts** (zero_negative_counts.csv).

| Stage | n |
|---|---|
| Live-live pairs with DBH > 0 | 5,540 |
| ΔDBH annual < 0 | 348 |
| ΔDBH annual = 0 | 365 |
| ΔDBH annual ≥ 10 cm yr⁻¹ | 37 |
| Retained ΔDBH frame | 4,790 |
| Of retained, ΔHT annual < 0 | 694 |
| Of retained, ΔHT annual = 0 | 235 |
| Of retained, ΔHT annual ≥ 10 m yr⁻¹ | 4 |
| Retained ΔHT frame | 3,857 |

By interval length (zero_negative_by_interval.csv), non-positive ΔDBH occurs in 626 of 4,342 pairs with YIP < 3 yr (14.4%) and in 87 of 1,198 pairs with YIP ≥ 3 yr (7.3%).

**Restored rows and multipliers** (eval_nonpos_k.csv; 95% installation-cluster percentile interval, conditional on coefficients).

| Response | Origin | Frame records | Restored | Restored with annual ≤ 0 | k, frame | k with restored (95%) | Ratio |
|---|---|---|---|---|---|---|---|
| ΔDBH | natural | 1,000 | 92 | 92 | 0.405 | 0.376 (0.341 to 0.453) | 0.928 |
| ΔDBH | planted | 3,790 | 621 | 621 | 1.436 | 1.174 (1.050 to 1.314) | 0.817 |
| ΔHT | natural | 762 | 330 | 302 | 0.519 | 0.349 (0.158 to 0.452) | 0.672 |
| ΔHT | planted | 3,095 | 1,312 | 1,039 | 2.648 | 1.667 (1.395 to 1.955) | 0.630 |

The restored dHT rows include 301 rows with positive height increment. They had been dropped because their diameter increment was non-positive.

**Refit on the restored frames** (sens_nonpos_*; 5,503 and 5,499 records, 60 installations). The likelihood cannot be compared with the reference because the records differ.

| Response | b9 Planted (ref) | b5 ln(CR) (ref) | b4 (ref) | Other large shifts (reference SEs) | τ source, τ inst. | k natural (95%) | k planted (95%) | Calibrated PA R² |
|---|---|---|---|---|---|---|---|---|
| ΔDBH | 0.929, SE 0.179 (0.410) | 2.458 (1.281) | −0.529 (−0.431) | b3 −5.2 | 0.0002, 0.654 | 0.425 (0.382 to 0.571) | 0.923 (0.802 to 1.066) | 0.159 |
| ΔHT | 1.490, SE 0.286 (1.068) | −0.684 (−0.525) | −0.260 (−0.133) | b1 +7.1, b2 −11.7, b6 +12.3, b7 −8.8, b3 −8.6 | 1.161, 0.289 | 0.467 (0.204 to 0.621) | 2.521 (2.140 to 2.916) | 0.160 |

**Interpretation.** The builder drops 713 non-positive diameter increments, 12.9% of live-live pairs, and 929 non-positive height increments among the retained diameter records, 19.4%. Drops are twice as common on intervals shorter than three years.

Counting these records would lower the planted diameter multiplier by 18% and both height multipliers by about a third. A refit moves the height coefficients well beyond their standard errors.

The screen can be defended as a measurement-error rule, since short-interval changes sit within the ±2.48 cm two-measurement envelope of Section 8.1. It is still selection on the outcome, and it raises the level of the calibrated increments, most for height. The paper should state the rule and its size.

**Proposed main text: new sentence after the first sentence of [P44].**

> The fitting frames keep intervals with live trees at both measurements and an annual increment above zero and below 10 cm yr⁻¹ or 10 m yr⁻¹, which removes 713 of 5,540 diameter intervals (348 negative, 365 zero) and 929 of the remaining height intervals (694 negative, 235 zero), most of them on intervals shorter than three years, where a single-year change sits inside measurement error (Supplemental Section 4).

**Proposed supplement text: new paragraph after the Table S8 notes [T57].**

> Note on excluded increments. The increment frames retain intervals with live trees and positive diameter at both measurements whose annual increment lies between zero and 10 cm yr⁻¹ for diameter and, in addition, between zero and 10 m yr⁻¹ for height. Of 5,540 live-to-live intervals, 348 negative and 365 zero diameter increments and 37 above the upper bound were removed, leaving 4,790, and of those, 694 negative and 235 zero height increments and four above the bound were removed, leaving 3,857. Non-positive diameter increments are twice as frequent on intervals shorter than three years (626 of 4,342, 14.4%) as on longer ones (87 of 1,198, 7.3%), consistent with the measurement-error envelope of Section 8.1. Restoring them changes the calibration more than the fit. With the published coefficients, the multipliers computed with the 713 restored diameter records would be 0.376 (95% installation-cluster interval 0.341 to 0.453) natural and 1.174 (1.050 to 1.314) planted, against 0.405 and 1.436, and with the 1,642 restored height records 0.349 (0.158 to 0.452) and 1.667 (1.395 to 1.955), against 0.519 and 2.648. Refitting Eq. 4 with the restored records raises the diameter planted level shift to 0.929 (SE 0.179) and moves several height increment coefficients by more than seven standard errors, with recalibrated multipliers of 0.425 and 0.923 for diameter and 0.467 and 2.521 for height increment. The screen is retained as a measurement-error rule, and its consequence is that the calibrated increments describe trees that registered positive growth over the interval.

---

## 3. Within-source origin contrast (R1 c1a, c1b)

**Question.** Origin is confounded with data source. What is the planted against natural contrast within DOFAW, within PSP, and within Kulani, the only installation with both origins? What happens when data source is a fixed effect, or when Eq. 4 is fitted on DOFAW alone?

**Method.** `s1b_within.R` does three things:
1. Counts records by source, origin, installation and plot.
2. Predicts every record with the reference Eq. 4 in population-average natural form (Planted = 0) × CFX, which accounts for size, competition, crown and BYI. It then forms R_o = Σ observed annual ÷ Σ natural-form prediction within origin and source. The contrast is R_planted ÷ R_natural.
   * The contrast implied by the deployed system is Σ (planted-form prediction × 1.43606 or 2.64739) ÷ Σ (natural-form prediction × 0.40548 or 0.51917) over the same planted records.
   * Intervals come from 2,000 tree-cluster bootstrap resamples within source, stratified by origin, percentile (seed 20260928). DOFAW has one planted installation and PSP one natural installation, so an installation-cluster interval cannot be formed. These intervals are conditional on the installations present.
3. Runs offset refits on DOFAW only. First b1 to b6 and b8 are held at the reference with b0 and b9 free; then b0, b7 and b9 are free. The random effect is b0 ~ 1 | Install.

`s1c_kulani.R` repeats step 2 for Kulani plot 12 (planted) against Kulani plot 23 (natural). `s_sens.R fixsrc` fits data source as a fixed effect on b0, with installation as the only random intercept. `s_sens.R dofaw` refits all ten terms on DOFAW records only.

**Design** (within_source_counts.csv).
* All 94 DOFAW planted diameter records (32 trees) are Kulani plot 12.
* DOFAW natural records number 879 on four installations: Kulani plot 23 (303), Laupahoehoe (263), Waiakea (172) and Waikamoi (141).
* PSP planted records number 3,427 on 31 installations. PSP natural records are 19, from PSP 122 plot 22 (five trees).
* Kulani planted intervals have a median length of 8 yr (dDBH) and 9 yr (dHT), against 5 yr for Kulani natural. They span 1949 to 2001 and 1968 to 2001 respectively.

**Covariate-adjusted contrasts** (within_source_contrast.csv, within_kulani_contrast.csv; 95% tree-cluster percentile intervals conditional on installations).

| Response | Comparison | n planted / natural | R planted | R natural | Observed contrast | Implied by deployed system | Observed ÷ implied |
|---|---|---|---|---|---|---|---|
| ΔDBH | DOFAW | 94 / 879 | 0.559 (0.410 to 0.703) | 0.389 (0.370 to 0.409) | 1.437 (1.049 to 1.834) | 3.822 (3.667 to 4.010) | 0.376 (0.265 to 0.487) |
| ΔDBH | Kulani 12 vs 23 | 94 / 303 | 0.559 (0.407 to 0.719) | 0.412 (0.378 to 0.445) | 1.358 (0.984 to 1.758) | 3.822 (3.665 to 4.014) | 0.355 (0.250 to 0.466) |
| ΔDBH | PSP | 3,427 / 19 | 1.678 (1.627 to 1.729) | 0.993 (0.850 to 1.077) | 1.689 (1.548 to 1.978) | 4.250 (4.201 to 4.305) | 0.397 (0.363 to 0.466) |
| ΔHT | DOFAW | 67 / 683 | 0.401 (0.308 to 0.512) | 0.526 (0.488 to 0.566) | 0.762 (0.587 to 0.985) | 3.781 (3.428 to 4.259) | 0.202 (0.153 to 0.254) |
| ΔHT | Kulani 12 vs 23 | 67 / 266 | 0.401 (0.313 to 0.500) | 0.519 (0.471 to 0.564) | 0.771 (0.596 to 0.993) | 3.781 (3.405 to 4.218) | 0.204 (0.157 to 0.266) |
| ΔHT | PSP | 2,768 / 15 | 2.533 (2.430 to 2.643) | 1.193 (0.920 to 1.636) | 2.122 (1.525 to 2.765) | 4.998 (4.824 to 5.186) | 0.425 (0.307 to 0.552) |

**DOFAW offset refits** (within_dofaw_offset_fits.csv; Wald SE).

| Response | Free terms | b9 (SE, P) | b7 (SE) | logLik | Reference b9 |
|---|---|---|---|---|---|
| ΔDBH (n 973) | b0, b9 | 0.284 (0.092, P = 0.002) | held at −0.0176 | −2,110.16 | 0.410 |
| ΔDBH | b0, b7, b9 | −0.351 (0.174, P = 0.045) | +0.0276 (0.0085) | −2,101.24 | 0.410 |
| ΔHT (n 750) | b0, b9 | 1.017 (0.105, P < 0.001) | held at −0.124 | −1,387.30 | 1.068 |
| ΔHT | b0, b7, b9 | 0.560 (0.304, P = 0.066) | −0.068 (0.034) | −1,386.15 | 1.068 |

**Source as a fixed effect** (sens_fixsrc_*; same records as the reference).

| Response | ΔAIC | b9 (SE, P) | Source offsets on b0 vs DOFAW (SE) | τ inst. | k natural (95% inst.-cluster) | k planted | Calibrated PA R² |
|---|---|---|---|---|---|---|---|
| ΔDBH | −10.0 | 0.260 (0.254, P = 0.306) | FIA 0.163 (0.295), KMR PSP 1.828 (0.608), PSP 1.359 (0.371) | 0.512 | 0.737 (0.608 to 0.800) | 0.824 (0.762 to 0.905) | 0.337 |
| ΔHT | −18.4 | 1.008 (0.199, P < 0.001) | FIA −0.539 (0.188), KMR PSP 2.080 (0.287), PSP 1.688 (0.220) | 0.213 | 1.065 (0.589 to 1.306) | 1.099 (1.023 to 1.180) | 0.262 |

All other coefficients stay within 0.9 reference SEs.

**DOFAW-only full refit** (sens_dofaw_*; 973 and 750 records, four installations, one of them planted).
* ΔDBH: the random-intercept variance collapses (τ 2.0 × 10⁻⁵), and several coefficients move by tens of reference SEs (b5 −16.0, b1 −1.05, b9 −2.02 with SE 0.34). The within-DOFAW planted multiplier is 0.989, with a degenerate interval because there is a single planted installation. On the full frame this equation gives a calibrated R² of −23.98.
* ΔHT: b9 is 2.39 (SE 0.79), with a full-frame R² of −0.91.

Fitted on DOFAW alone, the ten-term equation cannot be identified.

**Interpretation.** Within Kulani, adjusted for size, competition, crown and site, planted koa grew 1.36 times (0.98 to 1.76) the diameter increment of natural koa and 0.77 times (0.60 to 0.99) the height increment. The deployed calibrated system implies 3.8 times for both. On these records it overstates the planted advantage by about 2.8 times for diameter and 4.9 times for height.

The PSP contrast shows the same pattern (observed 1.69 against implied 4.25) but rests on five natural trees.

With source as a fixed effect, the diameter level shift falls to 0.260 (P = 0.306) and the two diameter multipliers converge (0.737 and 0.824). The source terms, not origin, carry most of the diameter contrast. The height level shift survives at 1.008.

Even the Kulani contrast is not clean. It confounds origin with interval length (8 or 9 yr against 5 yr) and calendar span, and item 5 shows the system overpredicts planted increment on long intervals. All intervals in this item are conditional on the installations present.

These results support the manuscript's reading of the multipliers as network corrections, and the text can now cite these numbers.

**Proposed main text: replaces the last sentence of [P72]** ("Held out by data source, the multipliers behave as network corrections, ... (Supplemental Section 11.1 and Table S20).").

> Held out by data source, the multipliers behave as network corrections, since the DOFAW older plantations grow at 0.36 and the KMR installation at 1.48 times the prediction of the planted multiplier of the other sources, and resampling the four sources widens the diameter multiplier intervals to 0.38 to 0.99 (natural) and 0.52 to 2.05 (planted) (Supplemental Section 11.1 and Table S20). The only within-installation comparison, the Kulani plantation against the adjacent natural plot, gives a covariate-adjusted planted to natural ratio of 1.36 (95% tree-cluster interval 0.98 to 1.76) for diameter and 0.77 (0.60 to 0.99) for height increment, against 3.8 implied by the calibrated system, and with data source entered as a fixed effect the diameter level shift falls to 0.26 (P = 0.31), so the origin contrast of the deployed diameter equation cannot be separated from data source (Supplemental Section 8.2).

**Proposed main text: in [P90], replace** "Because the origin multipliers shifted substantially when a whole data source was withheld (Section 3.3), they are best read as network corrections that happen to align with origin." **with:**

> Because the origin multipliers shifted substantially when a whole data source was withheld, and the one within-installation comparison returns a planted diameter advantage of 1.36 against the 3.8 that the calibrated forms imply (Section 3.3), they are best read as network corrections that happen to align with origin.

**Proposed supplement text: new paragraph after [P149]**, with a new Table S20b built from within_source_contrast.csv, within_kulani_contrast.csv, within_dofaw_offset_fits.csv and sens_fixsrc_*.

> Within-source contrasts. Two sources carry both origins. In DOFAW every planted record comes from Kulani plot 12 (94 diameter and 67 height records from 32 trees), and the natural records come from four installations, one of which is Kulani plot 23. In PSP the natural records are 19 diameter and 15 height records from five trees at PSP 122. Each record was predicted by the published Eq. 4 in its natural, population-average form, so that size, competition, crown ratio and BYI are accounted for, and the planted to natural contrast is the ratio of observed to predicted increment in planted records divided by the same ratio in natural records, with 95% intervals from 2,000 tree-cluster bootstrap resamples stratified by origin. These intervals are conditional on the installations present, because no source holds more than one installation of its minority origin. Within Kulani the contrast is 1.36 (0.98 to 1.76) for diameter and 0.77 (0.60 to 0.99) for height increment, within DOFAW 1.44 (1.05 to 1.83) and 0.76 (0.59 to 0.98), and within PSP 1.69 (1.55 to 1.98) and 2.12 (1.53 to 2.77), whereas the calibrated system implies 3.82 and 3.78 on the DOFAW planted records and 4.25 and 5.00 on the PSP planted records (Table S20b). The Kulani planted intervals are also longer than the natural ones, at a median of 8 against 5 years, so interval length is not separated from origin even there. Holding the other coefficients at their published values and refitting only the intercept and level shift on DOFAW gives a diameter level shift of 0.284 (SE 0.092) and a height level shift of 1.017 (SE 0.105), and freeing the planted size slope as well gives −0.351 (SE 0.174) and 0.560 (SE 0.304). Entering data source as a fixed intercept offset, with installation as the only random intercept, lowers AIC by 10.0 and 18.4, reduces the diameter level shift to 0.260 (SE 0.254, P = 0.306) while the height level shift stays at 1.008 (SE 0.199), and brings the two diameter multipliers to 0.737 and 0.824, so the diameter origin contrast of the deployed equation is carried by data source. A refit of all ten terms on DOFAW alone is not identifiable, since its diameter coefficients move by tens of standard errors and the result does not transfer to the other sources.

---

## 4. Installation-cluster bootstrap of Eq. 4, and the height model (R1 c3)

**Question.** How much do the Wald SEs of Eq. 4 understate uncertainty when installations are resampled? Does the planted level shift survive?

**Method.** `s2_boot.R <resp> 2000 2` resamples the Data × Install clusters with replacement: 60 for ΔDBH, 58 for ΔHT. Duplicated installations are relabeled as separate random-effect levels, and each resample is refitted with the reference path from the reference optimum. Results are appended in chunks of 8. All 2,000 index sets were drawn up front from seed 20260928.

`s2_boot_summary.R 980` summarizes draws 1 to 980, successful fits only. It reports:
* the bootstrap SE;
* the 95% percentile interval;
* the ratio of bootstrap SE to Wald SE;
* p_boot = 2 min(P(b ≤ 0), P(b ≥ 0));
* the bootstrap SE excluding draws where the source variance collapsed.

**Status. The bootstrap stopped at 980 of 2,000 planned draws per response.** 992 dDBH and 1,352 dHT draws are on disk, and the summary uses the common first 980. All 980 converged for both responses.

**The source variance collapsed (τ source < 0.01) in 734 of 980 ΔDBH draws (74.9%) and in 335 of 980 ΔHT draws (34.2%).**
* ΔDBH: median τ source 0.00023, median τ installation 0.533.
* ΔHT: median τ source 0.861, median τ installation 0.215.

Median time per fit was 29 s (ΔDBH) and 24 s (ΔHT). The reference ΔDBH standard deviations are 0.5862 (source) and 0.5332 (installation), from the Table S8 notes. With 980 draws each 2.5% tail rests on about 25 draws, so the interval limits carry noticeable Monte Carlo error. The run should be resumed to 2,000 before these numbers are final.

**ΔDBH** (boot_summary.csv; 95% installation-cluster percentile intervals, 980 draws).

| Term | Estimate | Wald SE | Boot SE | Ratio | 95% percentile interval | p_boot | Boot SE excl. collapsed |
|---|---|---|---|---|---|---|---|
| b0 | −1.151 | 0.676 | 1.428 | 2.11 | −5.205 to 0.315 | 0.102 | 0.870 |
| b1 ln(DBH+1) | 0.337 | 0.0373 | 0.124 | 3.32 | 0.097 to 0.602 | 0.008 | 0.122 |
| b2 DBH | −0.0143 | 0.0039 | 0.0175 | 4.48 | −0.0518 to 0.0120 | 0.353 | 0.0187 |
| b3 BAL²/ln(DBH+5) | −0.00177 | 0.00048 | 0.00156 | 3.23 | −0.00512 to 0.0000093 | 0.063 | 0.00176 |
| b4 ln(BAL+1) | −0.431 | 0.0254 | 0.109 | 4.28 | −0.647 to −0.233 | 0 (no draw crosses zero) | 0.097 |
| b5 ln(CR) | 1.281 | 0.294 | 0.638 | 2.17 | 0.067 to 2.550 | 0.041 | 0.590 |
| b6 √(BAPH×DBH) | −0.0176 | 0.0035 | 0.0104 | 2.98 | −0.0358 to 0.0059 | 0.131 | 0.0098 |
| b7 Planted×DBH | −0.0176 | 0.0025 | 0.0089 | 3.62 | −0.0403 to −0.0041 | 0.008 | 0.0067 |
| b8 ln(BYI) | 0.305 | 0.083 | 0.225 | 2.71 | 0.007 to 0.842 | 0.039 | 0.118 |
| b9 Planted | 0.410 | 0.239 | 0.611 | 2.56 | −0.103 to 2.248 | 0.073 | 0.322 |

**ΔHT.**

| Term | Estimate | Wald SE | Boot SE | Ratio | 95% percentile interval | p_boot | Boot SE excl. collapsed |
|---|---|---|---|---|---|---|---|
| b0 | −3.612 | 0.747 | 1.359 | 1.82 | −8.289 to −2.065 | 0 | 0.819 |
| b1 ln(HT+1) | 1.121 | 0.095 | 0.239 | 2.51 | 0.724 to 1.661 | 0 | 0.222 |
| b2 HT | −0.1155 | 0.0129 | 0.0330 | 2.56 | −0.1892 to −0.0622 | 0 | 0.0294 |
| b3 BAL²/ln(HT+5) | −0.00091 | 0.00030 | 0.00173 | 5.72 | −0.00568 to −0.000041 | 0.018 | 0.00159 |
| b4 ln(BAL+1) | −0.133 | 0.028 | 0.097 | 3.47 | −0.314 to 0.056 | 0.200 | 0.094 |
| b5 ln(CR) | −0.525 | 0.278 | 0.575 | 2.07 | −1.716 to 0.547 | 0.345 | 0.581 |
| b6 √(BAPH×HT) | 0.0380 | 0.0049 | 0.0151 | 3.09 | 0.0182 to 0.0767 | 0 | 0.0131 |
| b7 Planted×HT | −0.124 | 0.0073 | 0.0287 | 3.94 | −0.2027 to −0.0895 | 0 | 0.0227 |
| b8 ln(BYI) | 0.223 | 0.069 | 0.202 | 2.94 | −0.046 to 0.848 | 0.159 | 0.097 |
| b9 Planted | 1.068 | 0.205 | 1.076 | 5.25 | 0.450 to 3.889 | 0.004 | 0.506 |

For the level terms the bootstrap distributions are skewed away from the estimates (bootstrap means: ΔDBH b0 −2.018 and b9 1.122; ΔHT b9 1.827), so the percentile intervals are not centered on the estimates.

**Height model (Eq. 2).** `s2_height_boot.R` reproduced the Table 3 reference: n 9,059, 143 installations, a0 32.198, a1 1.2085, b 0.016579, c 0.8049, g1 0.0621, g2 −0.3733 (height_ref_and_treeRE.csv).

The three-level random intercept (source/installation/tree) failed with "Singularity in backsolve at level 0, block 1".

The height bootstrap left no output: there is no `boot_height.csv`, no completion line in the log, and the B passed on the command line is not recorded. **There is no Eq. 2 bootstrap result.**

`s2_height_treere.R` was written to fit the tree level nested in installation with the source level dropped; its header gives the v102 source SD as 0.0019. It has no log and no `height_treeRE.csv`, so either it did not run or its output was not retrieved. **There is no height tree random effect result.**

**Interpretation.** Resampling installations inflates every Eq. 4 SE by 1.8 to 5.7 times the Wald value.

For diameter:
* ln(BAL+1), ln(DBH+1) and the planted size slope keep intervals that exclude zero.
* ln(CR) and ln(BYI) only just do (lower limits 0.067 and 0.007).
* The planted level shift does not (−0.10 to 2.25, p_boot 0.073), consistent with its Wald P of 0.086.

For height:
* The size, density and planted terms keep intervals that exclude zero, including the level shift (0.45 to 3.89).
* ln(BAL+1), ln(CR) and ln(BYI) do not.

Part of the inflation comes from the diameter draws where the source variance collapsed: excluding them roughly halves the bootstrap SE of b0, b8 and b9. Even so, the ratios stay well above 1.

The projection Monte Carlo in [P63] draws the coefficient vectors from the fitted Wald covariance, so its parameter spread is understated by the same factor.

The height increment ln(BYI) term cannot be told apart from zero under installation resampling (−0.046 to 0.848). This bears on how strongly the paper can claim that BYI enters the increment equations.

**Proposed main text: in [P71], replace** "with ln(BYI) coefficients of 0.305 and 0.223 (P < 0.001 and P = 0.001)." **with:**

> with ln(BYI) coefficients of 0.305 and 0.223 (Wald P < 0.001 and P = 0.001), whose 95% installation-cluster bootstrap intervals are 0.007 to 0.842 and −0.046 to 0.848 (Supplemental Table S8b).

**Proposed main text: in [P72], replace** "(+0.410, P = 0.086, and +1.068, P < 0.001)" **with:**

> (+0.410, P = 0.086, and +1.068, P < 0.001; 95% installation-cluster bootstrap intervals −0.10 to 2.25 and 0.45 to 3.89)

**Proposed main text: new last sentence in the Table 4 notes [P208].**

> Resampling installations with replacement (980 completed of 2,000 planned resamples) gives standard errors 1.8 to 5.7 times the fitted ones shown here, and the bootstrap intervals are in Supplemental Table S8b.

**Proposed main text: in [P63], insert after** "both increment coefficient vectors and the six height parameters are drawn from their fitted covariances,":

> which the installation-cluster bootstrap of the increment equations shows to understate coefficient spread by a factor of 1.8 to 5.7 (Supplemental Table S8b),

**Proposed supplement text: new Table S8b and caption after the Table S8 notes [T57]**, placed before the excluded-increment note of item 2. The table body is the two tables above.

> Table S8b. Installation-cluster bootstrap of the increment equations. Installations (60 for diameter and 58 for height increment, each a combination of data source and installation) were resampled with replacement, duplicated installations were treated as separate random-effect levels, and Eq. 4 was refitted from the published vector with the published random effects and variance function. Of 2,000 planned resamples, drawn in advance from seed 20260928, the first 980 completed for each equation and all 980 converged; the run stopped before the remainder. The data-source variance collapsed to below 0.01 in 734 of the 980 diameter and 335 of the 980 height resamples. The table gives the fitted estimate and standard error, the bootstrap standard error, the 95% percentile interval and a bootstrap sign proportion, twice the smaller share of resamples on either side of zero. Bootstrap standard errors are 2.1 to 4.5 times the fitted ones for diameter and 1.8 to 5.7 times for height increment. The diameter planted level shift has an interval of −0.103 to 2.248 and the height one 0.450 to 3.889, and the ln(BYI) terms have intervals of 0.007 to 0.842 and −0.046 to 0.848. With 980 resamples the interval limits carry Monte Carlo error at about the third significant figure.

**Height model text:** none is proposed, because no Eq. 2 bootstrap or tree random effect result exists. If the reviewer's height request must be answered, note that the three-level tree fit is not estimable in nlme on this frame, and rerun `s2_height_treere.R` and the height bootstrap.

---

## 5. Other sensitivities (R1 c3, c4, c6)

**Method.** Each variant is run by `s_sens.R <spec>`, started from the reference vector and, for dDBH, also from the record-start vector, keeping the higher likelihood. The start kept is shown in the table.
* **nocr**: ln(CR) removed (b5 = 0, with CR set to 1).
* **treere**: a tree-level random intercept nested in installation within source (random b0 ~ 1 | Data/Install/Tree).
* **wlen**: residual variance additionally multiplied by 1 ÷ YIP (`varComb(varPower(0.2, ~DBH.0), varFixed(~invYIP))`), so longer intervals get more weight. This is the only length weighting tested.
* **lt3**: intervals of 3 years or more only.

Multipliers are the refit's own, with 2,000-draw installation-cluster percentile intervals. For lt3 they are also evaluated on the full frame.

`s_eval.R` part B scores the deployed calibrated system by interval length class and origin. `s_eval2.R` scores it by measurement period on the planted PSP and KMR PSP networks, for periods with n ≥ 20; that file has no intervals.

**Fit and multipliers** (sens_*_stats.csv).

| Spec | Response | Start kept | n | ΔAIC vs ref | τ (as fitted) | k natural (95%) | k planted (95%) | Calibrated PA R² |
|---|---|---|---|---|---|---|---|---|
| nocr | ΔDBH | record | 4,790 | +26.9 | 0.0002, 0.532 | 0.568 (0.505 to 0.714) | 0.984 (0.896 to 1.092) | 0.311 |
| nocr | ΔHT | reference | 3,857 | +1.5 | 1.059, 0.225 | 0.495 (0.303 to 0.582) | 2.581 (2.325 to 2.827) | 0.234 |
| treere | ΔDBH | record | 4,790 | −274.6 | 0.0002, 0.511, tree 0.267 | 0.532 (0.478 to 0.692) | 0.899 (0.806 to 1.018) | 0.305 |
| treere | ΔHT | reference | 3,857 | −57.5 | 1.035, 0.235, tree 0.240 | 0.509 (0.305 to 0.604) | 2.540 (2.299 to 2.748) | 0.249 |
| wlen | ΔDBH | record | 4,790 | +3,291.4 | 0.0003, 0.659 | 0.521 (0.466 to 0.669) | 1.033 (0.930 to 1.163) | 0.114 |
| wlen | ΔHT | reference | 3,857 | +1,950.7 | 0.847, 0.340 | 0.615 (0.368 to 0.726) | 2.171 (1.922 to 2.447) | 0.128 |
| lt3 | ΔDBH | reference | 1,111 (164 planted, 35 inst.) | not comparable | 0.645, 1.218 | 0.817 (0.675 to 1.106) | 0.491 (0.275 to 0.734) | 0.155 (full frame −4.37) |
| lt3 | ΔHT | reference | 842 (128 planted, 33 inst.) | not comparable | 0.00005, 0.484 | 1.040 (0.593 to 1.393) | 1.113 (0.825 to 1.383) | 0.167 (full frame −0.88) |

**Key coefficient changes** (sens_*_coef.csv; reference values in parentheses).

| Spec | ΔDBH | ΔHT |
|---|---|---|
| nocr | b9 1.019, SE 0.138 (0.410); b0 −3.47 (−1.15); b8 0.575 (0.305); b4 −0.372 (−0.431) | all terms within 1.4 reference SEs; b9 1.094 (1.068) |
| treere | b9 1.151, SE 0.140 (0.410); b8 0.525 (0.305); b5 1.631 (1.281); b0 −2.52 (−1.15) | all terms within 1.9 reference SEs; b9 0.946, SE 0.212 |
| wlen | b5 −0.783 (1.281); b3 −0.0147 (−0.00177); b2 −0.055 (−0.014); b7 +0.0088 (−0.0176); b9 0.409 (0.410) | b4 −0.411 (−0.133); b5 0.864 (−0.525); b3 −0.00003, P = 0.79 |
| lt3 | b1 −1.18 (0.337); b5 −8.29 (1.281); b6 0.106 (−0.018); b9 0.471, P = 0.45 | b1 0.371, P = 0.18 (1.121); b3 −0.0316 (−0.00091); b5 2.52 (−0.525); b9 2.50 (1.068) |

**Deployed calibrated system by interval length** (eval_interval.csv). Values are observed ÷ predicted summed annual increment with 95% installation-cluster percentile intervals, conditional on coefficients. Classes from a single installation have degenerate intervals and are marked "1 inst.".

| Response | Origin | 1 yr | 2 yr | 3 to 5 yr | 6 to 10 yr | > 10 yr |
|---|---|---|---|---|---|---|
| ΔDBH | natural | 1.061 (0.630 to 1.729), n 43 | 3.069, n 10, 1 inst. | 1.050 (0.964 to 1.132), n 493 | 0.872 (0.758 to 1.036), n 444 | 0.793, n 10, 1 inst. |
| ΔDBH | planted | 1.006 (0.914 to 1.116), n 3,178 | 1.127 (0.923 to 1.351), n 448 | 0.363 (0.262 to 0.477), n 84 | 0.435, n 48, 1 inst. | 0.243, n 32, 1 inst. |
| ΔHT | natural | 1.293 (0.358 to 1.480), n 38 | 3.346, n 10, 1 inst. | 1.006 (0.638 to 1.306), n 347 | 0.904 (0.499 to 1.032), n 358 | 0.547, n 9, 1 inst. |
| ΔHT | planted | 1.060 (0.962 to 1.155), n 2,536 | 0.746 (0.656 to 0.828), n 431 | 0.364 (0.256 to 0.488), n 69 | 0.201, n 29, 1 inst. | 0.200, n 30, 1 inst. |

**By measurement period on the planted PSP networks** (eval_planted_by_period.csv; point ratios only, no intervals).

| Period (years) | Diameter ratio | Height ratio | n | Installations |
|---|---|---|---|---|
| 2017 to 2020 (3-year) | 0.485 | 0.287 | 33 | 7 |
| 2021 to 2024 (3-year) | 0.287 | 0.488 | 37 | 8 |
| 2017 to 2018 (1-year) | 1.423 | | | |
| 2018 to 2019 (1-year) | 0.687 | | | |
| 2019 to 2020 (1-year) | 0.927 | | | |
| 2023 to 2024 (1-year) | 1.029 | | | |
| 2021 to 2023 (2-year) | 0.937 | | | |

The 1- and 2-year rows are shown for diameter only.

**Interpretation.**

*Crown ratio.* Removing ln(CR) costs 26.9 AIC units for diameter and 1.5 for height. In the diameter equation it moves the planted level shift from 0.410 to 1.019. Crown ratio, itself predicted from competition variables, therefore trades against the origin and site terms in the diameter equation, as [P91] says. The height equation is largely indifferent to it.

*Tree random intercept.* It improves the likelihood strongly (ΔAIC −275 and −58). For diameter it moves the solution to the second optimum, where the source variance is near zero and the planted level shift is 1.151 (SE 0.140). The height equation is stable.

*Interval-length weighting.* As specified, it fits far worse (ΔAIC +3,291 and +1,951) and is not supported. The opposite weighting was not tested.

*Interval length.* This is the sharpest result of the item.
* The calibrated system is unbiased on the 1- and 2-year planted intervals, which make up about 96% of planted records.
* It overpredicts planted increment on 3 to 5 year intervals by about 2.8 times (0.363, 0.262 to 0.477, nine installations).
* The 3-year PSP periods sit below every 1-year period covering the same calendar years, so the effect follows interval length rather than calendar year.
* Natural intervals, mostly 3 to 10 years long, show no comparable shortfall.
* An equation fitted only on intervals of 3 years or more is a different equation (b1 and b5 change sign for diameter) and fails badly on the full frame.

The planted multiplier and level shift are therefore estimated almost entirely from 1-year plantation intervals. They should not be assumed to hold over longer spans, which matters for long planted projections and for the Kulani contrast in item 3.

**Proposed main text: in [P91], insert after** "... so the two trade against each other.":

> Removing ln(CR) raises AIC by 26.9 for diameter and 1.5 for height increment, and in the diameter equation it moves the planted level shift from 0.41 to 1.02, so the crown term also trades against the origin terms (Supplemental Section 11.1).

**Proposed main text: new sentence at the end of [P72]**, after the item 3 replacement.

> The calibrated system is unbiased on the one- and two-year intervals that supply 96% of the planted records, at an observed to predicted diameter increment ratio of 1.01 (95% installation-cluster interval 0.91 to 1.12) on one-year intervals, but overpredicts planted increment on the 84 three- to five-year intervals from nine installations, at 0.36 (0.26 to 0.48), whereas natural intervals of three to ten years show no comparable shortfall (Supplemental Section 11.1).

**Proposed main text: in [P99], insert after** "with thinning removals and fill-in planting recorded separately,":

> since the planted increment calibration rests almost entirely on one-year intervals and overpredicts the few longer planted intervals by a factor of about 2.8,

**Proposed supplement text: new paragraph in Section 11.1 after [P180].**

> Sensitivity of the increment equations to specification. Four respecifications of Eq. 4 were fitted on the published frames. Removing ln(CR) raised AIC by 26.9 for diameter and 1.5 for height increment, left the height coefficients within 1.4 standard errors of their published values, and in the diameter equation moved the planted level shift to 1.019 (SE 0.138) and the multipliers to 0.568 and 0.984. A tree-level random intercept nested in installation lowered AIC by 274.6 and 57.5, with tree standard deviations of 0.267 and 0.240; the height coefficients stayed within 1.9 standard errors of their published values, whereas the diameter solution moved to one with a near-zero source variance and a planted level shift of 1.151 (SE 0.140). Making the residual variance inversely proportional to interval length raised AIC by 3,291 and 1,951 and was not pursued. Refitting on intervals of three years or more (1,111 diameter and 842 height records) produced coefficients of opposite sign for ln(size + 1) and ln(CR) in the diameter equation and a calibrated R² of −4.37 on the full frame. Scored by interval length, the deployed calibrated diameter increment has an observed to predicted ratio of 1.006 (95% installation-cluster interval 0.914 to 1.116) on 3,178 one-year and 1.127 (0.923 to 1.351) on 448 two-year planted intervals, against 0.363 (0.262 to 0.477) on 84 three- to five-year planted intervals from nine installations, and 0.435 and 0.243 on the six- to ten-year and longer planted intervals, each from a single installation. The corresponding height ratios are 1.060, 0.746, 0.364, 0.201 and 0.200. On the planted PSP network the two three-year periods, 2017 to 2020 and 2021 to 2024, return diameter ratios of 0.485 and 0.287, below every one-year period covering the same years (0.687 to 1.423), so the shortfall follows interval length and not calendar period. Natural records show no comparable pattern, at 1.050 (0.964 to 1.132) on three- to five-year and 0.872 (0.758 to 1.036) on six- to ten-year intervals. The planted calibration is therefore a calibration of one-year plantation growth.

---

## Files and open actions

Scripts are in `/tmp/koa/work/incr/*.R`, outputs in `/tmp/koa/work/incr/out/`, logs in `/tmp/koa/work/incr/logs/`.

Not present, so not reported:
* `boot_height.csv`
* `height_treeRE.csv`
* `sens_*_fits.rda`
* `origin_refit_REFERENCE_COPY.R` (the `gr.hat2` body)

To finish item 4:
1. Rerun `s2_boot.R dDBH 2000 <cores>` and `s2_boot.R dHT 2000 <cores>`. They resume from draws 993 and 1,353.
2. Then run `s2_boot_summary.R 2000`.
