# koa_rv_mort_20260928: mortality, Monte Carlo coverage, MAI culmination, FIA attribution and stocking overlay

Date September 28, 2026. Host ifm-kershaw (firebreather). Engine of record `~/jobs/koa_v102_20260918/track2/engine_v102` (MORT_CAL 2.64629), read only. Reviewer items R1 c12, c14, c25 and R2 c7, c9. Every interval below is named. No plot identifier or coordinate appears in this report or in the downloaded outputs (FIA plots are indexed FIA-8 to FIA-13, installations I1 to I17).

Two facts surfaced that change how items 2 and 4 should be read, so they come first.

* The six FIA validation plots are six subplots of three FIA plots. The four that lost 54 to 85% of their stems (observed cohort survival 0.18, 0.34, 0.15 and 0.46, 2010 to 2019) are subplots 1 to 4 of ONE FIA plot. The mortality episode behind the largest natural validation error is therefore one event at one location, and the effective sample for "the six independent plots" is three plots.
* No FIA interval enters Stage 1 or Stage 2. The 23 natural intervals are 21 DOFAW intervals (six plots, four installations) and two PSP intervals (one plot). The "natural Stage 1/2 intervals from FIA" asked for in item 4 do not exist.

A data hygiene note. `frames/plot_intervals_origin_v102_keydedup.csv` (294 rows) carries four PSP 119 to 122 intervals, 2019 to 2023, that span the 2021 removal but have `removal = False`. The deployed `stage1_fit.json` was fitted on the 290-row `koa_origin_20260916/out_span/plot_intervals_origin.csv`, which excludes them, and that file reproduces the json to 4.4e-15 (S1) and 4.4e-16 (S2). All item 1 refits use the 290-row file. The v102 frame copy should not be used for any refit without re-flagging those four rows.

---

## 1. Stage 1 occurrence and Stage 2 magnitude with a stems-at-risk adjustment (R1 c12)

Question. Does the density response of occurrence survive adjustment for the number of stems at risk (and plot area), and separately within natural and planted intervals? Does Stage 2 change?

Method. `a1_stage12.R`. Reproduction gate against `stage1_fit.json` passed. Stage 1 cloglog on `any_mort` with ln(YIP) offset, variants (a) published form, (b) + ln(stems at risk) as a covariate, (c) ln(stems at risk) added to the offset, which is the exact form under a constant per-tree hazard since P(any death) = 1 − exp(−n h t), (d) + ln(plot area), and (e) a binomial count model of deaths among stems at risk (cloglog, ln YIP offset), which estimates the per-tree annual hazard directly. Stage 2 lm of ln(annual rate) on mortality-bearing intervals, published form and + ln(stems at risk) or + ln(plot area). Pooled (with the planted term) and by origin (without it). Plot-cluster percentile bootstrap, 2,000 resamples, seed 20260928. Plot area is n_alive/expf_alive.

Counts (290 intervals, 54 plots, 118 with mortality).

| Origin | Source | Intervals | Plots | Installations | With mortality | Median YIP (yr) | Median stems at risk | Median SDI |
|---|---|---|---|---|---|---|---|---|
| Natural | DOFAW | 21 | 6 | 4 | 19 | 5.0 | 59 | 436 |
| Natural | PSP | 2 | 1 | 1 | 0 | 0.85 | 5 | 185 |
| Natural | all | 23 | 7 | 5 | 19 | 5.0 | 50 | 424 |
| Planted | DOFAW | 6 | 1 | 1 | 6 | 7.5 | 19 | 319 |
| Planted | KMR PSP | 38 | 15 | 1 | 13 | 1.04 | 8 | 87 |
| Planted | PSP | 223 | 31 | 31 | 80 | 1.0 | 14 | 402 |
| Planted | all | 267 | 47 | 33 | 99 | 1.0 | 13 | 283 |

Results, ln(SDI) coefficient with plot-cluster bootstrap 95% percentile interval (share of resamples > 0; resamples converged).

| Model | Pooled | Natural only | Planted only |
|---|---|---|---|
| S1 published form | +0.162 (+0.013, +0.314; 0.98) | +0.649 (−0.457, +143.7; not estimable) | +0.155 (+0.010, +0.324; 0.98) |
| S1 + ln(stems) covariate | +0.162 (+0.024, +0.306; 0.98) [ln stems +0.602 (+0.222, +1.058)] | not estimable | +0.168 (+0.032, +0.306; 0.99) [ln stems +0.748 (+0.329, +1.155)] |
| S1 ln(stems) in offset | +0.181 (+0.034, +0.321; 0.99) | not estimable | +0.182 (+0.042, +0.323; 0.99) |
| S1 + ln(plot area) | +0.159 (−0.011, +0.314; 0.97; 1,735 of 2,000) | not estimable | +0.154 (+0.005, +0.318; 0.98; 1,268) |
| Binomial per-tree hazard | +0.299 (+0.074, +0.615; 1.00) | +1.105 (+0.587, +2.267; 1.00) | +0.105 (−0.022, +0.224; 0.95) |
| S2 published form | −0.045 (−0.260, +0.113) | −0.535 (−0.845, +1.114) | −0.030 (−0.227, +0.129) |
| S2 + ln(stems) covariate | −0.022 (−0.200, +0.112) [ln stems −0.496 (−0.834, −0.168)] | −0.641 (−0.844, +0.673) | −0.021 (−0.190, +0.098) [ln stems −0.697 (−0.976, −0.362)] |
| S2 + ln(plot area) | −0.043 (−0.253, +0.113; 1,299) | not estimable | −0.029 (−0.246, +0.117; 1,272) |

Notes. "Not estimable" in the natural Stage 1 rows means 19 of the 23 natural intervals record a death, so occurrence is nearly separated and the bootstrap distribution is unbounded (upper limits of +107 to +5e15). The published origin term is equally weak, planted −0.191 (−2.03, +0.21) and +0.531 (−2.54, +1.08) once stems enter. Plot area takes only two values in this record (0.0403 ha on DOFAW, 0.0202 ha on PSP and KMR), so it is aliased with data source, which is why the area fits fail in 13 to 37% of resamples and return implausible area coefficients. The area variant is therefore not informative and the stems-at-risk variants carry the answer. Correlation of ln(SDI) with ln(stems) is 0.17 pooled, 0.10 planted and 0.68 natural. The Stage 2 bootstrap here (seed 20260928) gives −0.260 to +0.113 for the published fit against −0.259 to +0.111 of record, a Monte Carlo difference only.

Interpretation. The occurrence response to density is not an artifact of stems at risk. It survives the stems covariate and the constant-hazard offset, pooled and within the planted intervals that supply 267 of the 290 intervals, with the same coefficient (+0.16 to +0.18). Stems at risk has its own strong positive effect, as expected. Occurrence cannot be estimated from the 23 natural intervals at all, so "neither stage differs by origin" should become "origin could not be estimated". The per-tree binomial hazard adds something the reviewer did not ask for, a strong density response of per-tree mortality in the natural intervals (+1.11, +0.59 to +2.27) and a weak one in the planted intervals. Stage 2 keeps no detectable density response under every adjustment, while the conditional rate falls with stems at risk (−0.50), which is the discreteness floor of one death on few stems.

Proposed main text, replaces the sentence in [73] "Occurrence increases with SDI, with an ln(SDI) coefficient of +0.162 (plot-clustered 95% interval +0.013 to +0.315), whereas magnitude given occurrence does not (−0.045, −0.259 to +0.111), and neither stage differs by origin".

> Occurrence increases with SDI, with an ln(SDI) coefficient of +0.162 (plot-clustered 95% interval +0.013 to +0.315), and the response persists with the log of stems at risk as a covariate (+0.162, +0.024 to +0.306) or in the offset (+0.181, +0.034 to +0.321). The planted intervals supply 267 of the 290 intervals, from 47 plots with a median length of one year, and within them the response is the same (+0.155, +0.010 to +0.324), whereas occurrence could not be estimated from the 23 natural intervals from seven plots because 19 of them record a death. Magnitude given occurrence showed no detectable density response under any adjustment (−0.045, −0.259 to +0.111), an interval that does not exclude a response of the size found for occurrence, and the origin terms of both stages could not be estimated (Supplemental Section 7.1).

Proposed main text, [85] second sentence (adapts the reviewer's version).

> Mortality occurrence increased with stand density on a record dominated by short plantation intervals, and the response did not depend on the number of stems at risk, whereas the conditional rate showed no detectable density response within a wide interval, and the three-stage structure was adopted to carry that difference into projection.

Proposed supplement text (Section 7.1, new paragraph and Table S16b from `out_a1/a1_stage12_coefficients.csv` and `a1_counts_by_origin.csv`).

> Because the probability that a plot records at least one death rises with the number of stems at risk even at a constant per-tree rate, Stage 1 was refitted with the log of stems at risk as a covariate and, separately, added to the ln(YIP) offset, which is the exact form under a constant per-tree hazard. Plot area takes only two values in this record, 0.040 ha on the DOFAW plots and 0.020 ha on the PSP and KMR plots, so an area term is aliased with data source and was not used for inference. Across 2,000 plot-cluster bootstrap resamples the ln(SDI) coefficient was +0.162 (95% percentile interval +0.024 to +0.306) with the covariate and +0.181 (+0.034 to +0.321) with the offset, against +0.162 (+0.013 to +0.315) of record, and within the 267 planted intervals it was +0.155 (+0.010 to +0.324), +0.168 and +0.182. The 23 natural intervals, 21 from six DOFAW plots on four installations and two from one PSP plot, with a median length of five years, cannot support a Stage 1 fit, since 19 of the 23 record a death and the bootstrap distribution of every natural coefficient is unbounded. A binomial model of deaths among stems at risk, which estimates the per-tree annual hazard, gave ln(SDI) coefficients of +0.299 (+0.074 to +0.615) pooled, +1.105 (+0.587 to +2.267) natural and +0.105 (−0.022 to +0.224) planted. Stage 2 showed no detectable density response under any adjustment (Table S16b), and its conditional rate declined with stems at risk (−0.496, −0.834 to −0.168), the floor that one death on a small plot places on an annual rate. No FIA interval enters either stage.

---

## 2. Monte Carlo interval coverage on the 23 validation plots (R1 c14)

Question. Empirical coverage of the nominal 95% Monte Carlo interval for cohort survival, basal area and QMD, pooled, by origin and on the six FIA plots, and the FIA errors with and without the natural level factor.

Method. `a2_mc_validation.py` then `a2b_coverage.py`. No per-plot replicate runs existed (`koa_longterm_validation.validate()` and `regen_m1.validation()` are point only), so they were run. The deployed engine is imported through `regen_m1` (M1 gate and MORT_CAL installed exactly as for Table 5), and each replicate calls `regen_m1.set_params(rng)` with the Table 5 convention (independent draws from default_rng(42), diameter correction factor from 42 + 7919, one row of `out_joint/K_joint_draws.csv` per replicate, rows 0 to 499, the seed 20260918 table). Each of the 23 plots is projected from its initial tree list over its own interval without ingrowth, 500 replicates, all 23 plots returned in every replicate, no correction-factor clips. Gate, the point run reproduces `out_m1/validation_M1.csv` to 3.6e-15. Coverage is the share of plots whose observed value lies inside the 2.5th to 97.5th percentile of its replicate projections. Intervals on coverage are exact Clopper-Pearson on plot counts and an installation-cluster percentile bootstrap (2,000). Wall time 955 s for 500 replicates.

| Group | n plots (installations) | Survival | Basal area | QMD |
|---|---|---|---|---|
| Pooled | 23 (17) | 0.65 (CP 0.43 to 0.84; boot 0.47 to 0.83), 4 below, 4 above | 0.65 (0.43 to 0.84; 0.39 to 0.95), 5 below, 3 above | 0.91 (0.72 to 0.99; 0.76 to 1.00) |
| Natural | 12 (7) | 0.67 (0.35 to 0.90) | 0.50 (0.21 to 0.79), 4 below, 2 above | 0.92 (0.62 to 1.00) |
| Planted | 11 (11) | 0.64 (0.31 to 0.89) | 0.82 (0.48 to 0.98) | 0.91 (0.59 to 1.00) |
| Natural DOFAW | 6 (4) | 1.00 (0.54 to 1.00) | 0.67 (0.22 to 0.96), 2 above | 1.00 (0.54 to 1.00) |
| FIA | 6 (3) | 0.33 (0.04 to 0.78), 2 below, 2 above | 0.33 (0.04 to 0.78), 4 below | 0.83 (0.36 to 1.00) |
| PSP | 10 (10) | 0.70 (0.35 to 0.93) | 0.90 (0.56 to 1.00) | 0.90 (0.56 to 1.00) |

Median interval widths, pooled, 0.44 in survival, 22.0 m2 ha−1 in basal area and 12.8 cm in QMD.

FIA errors, projected minus observed, point runs.

| Run | Group | Survival | Basal area (m2 ha−1) | QMD (cm) |
|---|---|---|---|---|
| With level factor (2.646) | FIA, 6 | +0.307 | +9.38 | −0.89 |
| Without (factor 1) | FIA, 6 | +0.413 | +10.76 | −1.43 |
| With level factor | Natural, 12 | +0.198 | +4.11 | −1.54 |
| Without | Natural, 12 | +0.320 | +10.09 | −3.26 |

Observed FIA means are 0.522 survival and 7.00 m2 ha−1. Both natural rows and the FIA with-factor row reproduce the manuscript ([77], 0.31 and 9.4, −0.32 and −10.1 as observed minus projected). The installation bootstrap interval of a mean over three FIA installations is degenerate, so no interval is given for these means. By subplot, the four heavy-loss subplots of the one FIA plot are projected at survival 0.72 to 0.84 against 0.15 to 0.46 observed and all four lie below the basal area interval (observed 2.6 to 11.9 against intervals starting at 12.3 to 14.3), while the other two FIA plots lie inside for survival and basal area.

Interpretation. The Monte Carlo intervals cover QMD at about the nominal rate but cover survival and basal area on only about two thirds of plots, and the Clopper-Pearson upper limits (0.84) exclude 0.95, so the intervals are too narrow for survival and basal area. That is expected from what the intervals omit (process, BYI and initialization error) and should be said. Undercoverage concentrates on the FIA subplots of the one plot with a mortality episode and, for survival, on the PSP plots. The level factor removes about a quarter of the FIA survival error and an eighth of the basal area error, so the FIA gap is mostly not a level problem.

Proposed main text, replaces the first sentence of [77] ("The remaining natural error sits mostly on the six FIA plots, which contribute nothing to the calibration and where projected survival exceeds observed by 0.31 ... within nine years.").

> The remaining natural error sits mostly on the six FIA plots, which contribute no interval to the mortality calibration although FIA records enter the natural increment multiplier, and where projected survival exceeds observed by 0.31 and projected basal area exceeds observed by 9.4 m^2^ ha^−1^ against an observed mean of 7.0 m^2^ ha^−1^ (0.41 and 10.8 m^2^ ha^−1^ without the level factor). The six are subplots of three FIA plots, and the four that lost 54 to 85% of their stems within nine years are subplots of a single plot.

New main-text sentence for Section 3.4, after [77].

> The 95% Monte Carlo intervals contained the observed value on 21 of the 23 plots for QMD (0.91, exact 95% interval 0.72 to 0.99) but on 15 of 23 for both cohort survival and basal area (0.65, 0.43 to 0.84), and on two of the six FIA subplots for each, so they understate predictive uncertainty for stand density and basal area, as expected from the error sources they omit (Supplemental Table S26).

Proposed supplement text (Section 11.3, with Table S26 from `out_a2/a2_coverage.csv`, per-plot anonymous detail in `a2_plot_intervals_anon.csv`).

> Coverage of the projection intervals was checked on the 23 validation plots by projecting each plot from its initial tree list through the deployed engine under the same 500 joint Monte Carlo draws used for Table 5, without ingrowth, and counting the plots whose observed value lay inside the 2.5th to 97.5th percentile of its replicates. Coverage was 0.91 for QMD (exact 95% interval 0.72 to 0.99, installation-cluster bootstrap 0.76 to 1.00), 0.65 for cohort survival (0.43 to 0.84) and 0.65 for basal area (0.43 to 0.84). By origin, survival coverage was 0.67 natural and 0.64 planted and basal area coverage 0.50 and 0.82. On the six FIA subplots, which come from three FIA plots, coverage was 0.33 for survival and basal area and 0.83 for QMD, and the four subplots of the one plot that lost 54 to 85% of its stems all fell below their basal area intervals. Without the natural level factor the FIA errors, projected minus observed, were +0.41 in survival and +10.8 m^2^ ha^−1^ in basal area, against +0.31 and +9.4 with it. The intervals carry parameter and data-source uncertainty only, and the coverage shortfall for survival and basal area measures what the omitted process, BYI and initialization errors contribute.

Abstract. The reviewer's replacement sentence stands with one change, "errors were largest on the six plots that did not inform the mortality calibration" could read "errors were largest on six FIA subplots, four of them from a single plot with a mortality episode, that did not inform the mortality calibration".

---

## 3. Net MAI culmination intervals (R1 c25)

Question. Recompute culmination-age intervals per scenario and site under a stated search window, find the source of "1 to 60 and 1 to 51" and of "7 to 32", and give a supplement table.

Method. `a3_culmination.py` and `a3b_interior_strict.py` on the replicate trajectories that produced Table 5 (`out_m1/reps_evenaged_M1.csv`, 500 replicates, and `uneven_aged_reps_M1.csv`, 300) and the point trajectories (`traj_M1.csv`, `uneven_aged_traj_M1.csv`), ages 1 to 100. Net MAI is VOL/age with age = years since the initial list. Windows computed are ages 10 to 100 (as requested), 5, 2 and 1 to 100, and an interior rule, argmax of net MAI after its first local minimum. Intervals are 2.5th and 97.5th percentiles of the replicate culmination ages.

What the scripts define. `track2/compare_v102.py` (Table B) searches ages 10 to 300 for natural and 2 to 300 for planted stands. The Table 5 note says natural from age 10. The published intervals are reproduced by none of these. They are reproduced exactly by the interior rule when replicates whose net MAI declines throughout are coded as age 1 (natural medium 1 to 59.5, high 1 to 51, planted high 6 to 19.5, medium 6 to 22, low 8 to 34.5, published as 1 to 60, 1 to 51, 6 to 20, 6 to 22, 8 to 35). The lower limit of 1 is therefore the share of natural replicates with no interior culmination (21% medium, 22% high), not a culmination at age 1. The "7 to 32" planted range comes from `~/jobs/koa_calint_20260926/out/table_calint_culmination_interior.csv`, deterministic runs at the Table S20 interval bounds of the planted multipliers under the same interior rule (upper bounds give 7 on the medium and high sites, lower bounds give 32 on the low site). It is a range across sites and bounds, not a Monte Carlo interval.

Starting list. The initial list is at age 0 with 500 natural stems ha−1 (QMD 9.6 cm at age 1) or 1,200 planted stems ha−1 (7.2 cm), and carries 9.6 to 10.9 (natural) and 10.9 to 12.2 m3 ha−1 (planted) at age 1, so net MAI at age 1 is 9.6 to 12.2 m3 ha−1 yr−1 and falls for several years before rising.

Proposed Table S27, net MAI culmination age (yr), point projection with replicate median and 95% Monte Carlo interval for parameter and data-source uncertainty.

| Scenario | Site | Window 10 to 100, point | Median (2.5th, 97.5th) | Share at age 10 | Interior rule, point | Median (2.5th, 97.5th) among replicates with an interior culmination | Share without one |
|---|---|---|---|---|---|---|---|
| Even-aged natural | Low | 10 | 10 (10, 66) | 0.72 | 59 | 54 (19, 71) | 0.28 |
| Even-aged natural | Medium | 39 | 30 (10, 58) | 0.35 | 39 | 38 (16, 60) | 0.21 |
| Even-aged natural | High | 31 | 26 (10, 51) | 0.28 | 31 | 31 (13, 53) | 0.22 |
| Even-aged planted | Low | 13 | 12 (10, 35) | 0.22 | 13 | 12 (8, 35) | 0.002 |
| Even-aged planted | Medium | 10 | 10 (10, 22) | 0.75 | 10 | 9 (6, 22) | 0 |
| Even-aged planted | High | 10 | 10 (10, 20) | 0.92 | 8 | 8 (6, 20) | 0.002 |
| Uneven-aged natural | Low | 51 | 56 (24, 100) | 0 | 51 | 56 (24, 100) | 0 |
| Uneven-aged natural | Medium | 34 | 36 (14, 93) | 0 | 34 | 36 (14, 93) | 0 |
| Uneven-aged natural | High | 28 | 28 (12, 91) | 0 | 28 | 28 (12, 91) | 0 |

Planted multiplier interval (deterministic, Table S20 bounds), interior rule 7 to 32 years (lower bounds 32, 22, 18 low to high, upper bounds 10, 7, 7), and 10 to 32 years under the 10 to 100 window.

Interpretation. A uniform 10 to 100 window is unsuitable for planted stands, since the high-site point culmination (8 yr) precedes it and 75 to 92% of medium and high planted replicates stop at the window edge, and it also leaves most low natural replicates at the edge. The interior rule, with replicates lacking an interior culmination reported as a share, is the definition that matches the text and the Table 5 point values (8, 10, 13, 39, 31) and gives honest lower limits. I recommend it for all scenarios, stated once in Section 2.6 and in the Table 5 note. The uneven-aged upper limits sit at or near 100, so those intervals are truncated by the horizon.

Proposed main text, replaces the last sentence of [80] ("Net MAI culminates at 8 to 13 years in planted stands, with 95% Monte Carlo intervals of 6 to 20, 6 to 22 and 8 to 35 years ... with intervals of 1 to 60 and 1 to 51 years.").

> Net MAI, taken as the maximum after the early decline set by the volume of the initial list, culminates at 8 to 13 years in planted stands, with 95% Monte Carlo intervals for parameter and data-source uncertainty of 6 to 20, 6 to 22 and 8 to 35 years from the high to the low site and a range of 7 to 32 years at the bounds of the planted multiplier interval of Supplemental Table S20 (Section 4.3). On the medium and high natural sites it culminates at 39 and 31 years, with intervals of 16 to 60 and 13 to 53 years among the 79% and 78% of replicates whose net MAI has an interior maximum within 100 years (Supplemental Table S27).

Proposed Section 2.6 sentence (new).

> The initial tree list is placed at stand age 0 and already carries 10 to 12 m^3^ ha^−1^ at age 1, so net MAI falls for the first years, and culmination is taken as the maximum of net MAI after its first local minimum, with replicates whose net MAI declines throughout 100 years reported as a share rather than assigned an age.

Proposed Table 5 note, replaces "Net MAI culmination in natural stands is the maximum from age 10, since standing volume divided by age is largest in the first year, when the starting list already carries 10 to 11 m^3^ ha^−1^, and on the low natural site net MAI is largest at age 10, the first age searched, although an interior local maximum occurs at age 59."

> Net MAI culmination is the maximum of net MAI after its first local minimum, since the starting list at age 0 already carries 10 to 12 m^3^ ha^−1^ at age 1 and net MAI falls for the first years (Supplemental Table S27), and on the low natural site that maximum is at age 59, while 28% of its replicates show no interior maximum within 100 years.

Note for [102] and Supplement [2711]. "on the low natural site net MAI is largest at age 10, the first age searched, despite an interior local maximum at age 59" should follow whichever definition is adopted. Under the interior rule it becomes "on the low natural site the interior maximum is at age 59 (19 to 71 years), and 28% of replicates show none within 100 years".

---

## 4. FIA mortality attribution, AGENTCD, DSTRBCD, TRTCD (R2 c7)

Status. NOT COMPLETED. HI_TREE.csv and HI_COND.csv are not on firebreather (searched `~` to depth 5, `~/jobs/koa_zenodo_180`, `~/restricted`, `~/incoming`, `~/output`; the only HI FIA material is a plot locator file). The deposited AK_TREE.csv records Status (live or dead) only, with no agent code. The main session needs to place `~/Documents/MAINE/DATA/Koa/HI_TREE.csv` and `HI_COND.csv` on firebreather (for example in this job's `inputs/`) for the tabulation to run.

What can be stated from the data held.

* Scope is smaller than the reviewer assumes. The natural Stage 1/2 intervals contain no FIA record, so the tabulation covers only the six FIA validation subplots, which are three FIA plots, and the four heavy-loss subplots are one plot. Across the six, 141 koa stems were live in 2010, 79 were recorded dead in 2019 and 3 were absent, 79 of the 82 losses being on the one plot.
* The tabulation to run once the tables arrive is AGENTCD for the 79 dead koa (and all species on the same subplots), DSTRBCD1 to 3 with DSTRBYR and TRTCD1 to 3 for the conditions of the three plots at both visits, aggregated to counts by code, reporting plots as anonymous indices only. A short script is straightforward and I did not write placeholder output.

Interim main text for [94], second sentence, until the codes are read.

> The FIA plot that lost 54 to 85% of its stems on four subplots within nine years records the kind of episode no deterministic stand rate reproduces, and its damage and disturbance codes are reported in Supplemental Section 7.

---

## 5. Stocking guide overlay, Baker and Scowcroft (2005) (R2 c9)

Status. NOT COMPLETED, equations not recovered. `/tmp/koa/fb/baker2005.pdf` was not present at any check during this job. The Treesearch copy (treesearch/38026) is blocked by the egress proxy and by robots.txt, and its abstract states only that the guidelines are built from stem and crown diameter measurements, with less crown space needed on moist windward than on dry leeward sites. I did not reconstruct the lines from memory, because the site-specific crown width equations and line definitions cannot be recovered with certainty.

Prepared. `a5_stocking_prep.py` writes `out_a5/a5_tph_qmd_trajectories.csv` (stems ha−1, QMD and largest-tree DBH by age 1 to 100 for the nine Table 5 point trajectories and the 13 Fig. 6 density and thinning trajectories) and a wide table at ages 5 to 100, plus a `crossing()` helper that returns the first age at which a trajectory crosses a line TPH_line(QMD). Once the PDF is in `/tmp/koa/fb/` the overlay is a short run. One caution for that run is that the guidelines may be written on mean stem diameter or crown-based stocking rather than QMD, and the simulator reports QMD, so the diameter definition must be matched.

Interim main text for [97], first sentence, which removes the unsupported "complements".

> For management, net MAI culminates early in planted stands and later on the medium and high natural sites (Section 3.5), well short of the 40 to 60 years that sawlog quality requires (Baker et al., 2009), and koa value depends on heartwood, figure and stem form that the model does not carry, so volume culmination alone should not set koa rotations.

---

## Files

Job `~/jobs/koa_rv_mort_20260928/`: `a1_stage12.R`, `a2_mc_validation.py`, `a2b_coverage.py`, `a3_culmination.py`, `a3b_interior_strict.py`, `a5_stocking_prep.py`, `RUN.md`, logs `a1.log`, `a2.log`, `a2b.log`, `a3.log`. Outputs `out_a1/` (coefficients, counts, collinearity), `out_a2/` (coverage, FIA errors, anonymous per-plot intervals; the raw `reps_validation.csv`, `point_*.csv` carry plot keys and stay on firebreather), `out_a3/` (all windows, interior strict, calint), `out_a5/` (trajectory tables). Downloaded to `/tmp/koa/fb/koa_rv_mort_20260928/` are the report, RUN.md, scripts and the anonymous output tables only.
