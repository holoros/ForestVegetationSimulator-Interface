# Koa: height increment, crown base, and stand-level mortality tests (rules written before fitting, November 14, 2026)

Written before any of the three scripts ran. The system of record is unchanged until a rule below says otherwise: S1 (maximum SDI from BYI and origin), E2 (height from DBH), E4r (diameter increment), E5 (height increment read off E2), E6r (tree-level mortality), with PSP thinning removals censored. All work is on firebreather in `~/jobs/koa_final_eq_20261110` (scripts 32 to 35). Aaron's instructions of November 14: show the best height increment equation tested, with the current rule as fallback, and adopt a fitted equation if it passes; add a height to crown base equation; test whether a stand-level mortality approach improves the 100-year projections on the Bakuzis criteria.

## 1. Height increment (script 33)

Frame. Every pair of visits of a tree at which it was alive with a measured height of at least 1.37 m (all pairs, not only consecutive ones), with an annualized height change between -2 and 4 m yr^-1. Diameter, basal area in larger trees, basal area and SDI are interpolated year by year along the tree's own visit record between the two visits. Each pair is weighted by 2 over the number of height visits of its tree, so a tree carries the weight of its consecutive intervals, and by the inverse of the interval length, with the variance power re-estimated over three passes as for E4r (weights frozen within a pass).

Forms. Annual height increment, iterated through each interval (iterative annualization).

- R0, the current rule E5: E2(DBH at year end) minus E2(DBH at year start). No fitted parameter.
- R1, the rule calibrated: R0 times exp(c0 + c1 ln BYI + c2 planted + c3 x), where x = (BAL/BA) RD.
- L1, a peaking size form: exp(h0 + h1 ln HT + h2 HT + h3 x + h4 ln BYI + h5 planted).
- L2, L1 tied to diameter growth: L1 times (annual diameter increment + 0.05) to a power h6.
- B1, a bounded differential Chapman-Richards form: c k HT ((A/HT)^(1/c) - 1) exp(h3 x), with A = exp(a0 + a1 ln BYI + a2 planted) and increments below zero set to zero.

Tests. (i) Installations held out in the ten folds of record, scored on the annual height increment with the observed diameter and competition paths: bias, RMSE, and the bootstrap equivalence test of observed on predicted with plots resampled (25% region). (ii) The 53-plot benchmark with the whole system and S1 out of fold: tree height at each plot's longest horizon for trees with a measured height at both ends. (iii) 200-year runs of the six scenarios.

Rule. A fitted form replaces E5 only if all four hold: (a) its held-out RMSE is at least 5% below that of R0; (b) it passes the intercept test and its smallest passing slope region is smaller than that of R0; (c) in all six scenarios the basal-area-weighted height at 200 years is no more than 1.2 times the tallest tree observed for that origin (34.1 m natural, 28.4 m planted), and height at 100 years is not lower on a better site; (d) its benchmark tree-height RMSE is not above that of R0. Among forms that pass, the choice is the one with the fewest parameters within 2% of the lowest held-out RMSE. If none passes, E5 stays and the form with the lowest held-out RMSE is reported as the best tested. If a form is adopted, E5 remains the documented fallback for a tree list without site or competition inputs, and height and assumed volume outputs are rebuilt; basal area, stems, QMD, SDI, the benchmark of Table 3 for those variables and the six gates cannot change, because neither E4r nor E6r uses height.

## 2. Height to crown base (script 34)

Data. The 360 FIA koa trees with a measured crown base (natural stands only, 36 installations), which is the only crown record in the database. The equation is therefore for natural stands and is a static component: nothing else in the system uses it.

Forms. HCB = HT / (1 + exp(eta)), with eta built up in steps: ln HT alone; plus DBH/HT; plus x = (BAL/BA) RD; plus ln BYI.

Rule. Fewest terms within 2% of the lowest held-out RMSE (installations held out). Reported with plot-cluster bootstrap intervals (2,000 resamples) and the equivalence test. If no form predicts crown base better held out than the mean crown ratio applied to height, that is what is reported.

## 3. Stand-level mortality (script 35)

Question. Whether a stand-level mortality model of the kind used before the refit (stand occurrence and amount, then allocation to trees) gives better 100-year behaviour on the Bakuzis criteria than the tree-level E6r, on the frame with thinning removals censored. The earlier comparison was scored before the censoring and was withdrawn.

Forms, all fitted to the censored frame (6,722 tree-intervals, 845 deaths) aggregated to plot-intervals where needed.

- T0, E6r of record (tree level).
- S1m, stand rate: annual stand hazard exp(g0 + g1 ln RD + g2 ln QMD + g3 ln BYI + g4 planted), binomial likelihood on plot-interval deaths with the interval length as exposure; deaths are allocated to trees in proportion to the tree-specific part of E6r (the DBH and BAL terms, refitted as a conditional allocation).
- S2m, occurrence and amount: probability that a plot-interval has any death (complementary log-log with exposure, on ln RD, ln QMD, ln BYI, planted and ln of the number of trees) times the hazard among plot-intervals with deaths; same allocation.

Tests. (i) Installations held out: RMSE of the plot-interval survival proportion. (ii) The 53-plot benchmark with S1 out of fold (survival, QMD, basal area). (iii) The six 200-year gates of record (site ordering of basal area and QMD to 100 years, SDI limit, basal area bound at 200 years, no late rise in SDI, Sukachev, yield against density), with E4r of record.

Rule. A stand-level form is preferred to E6r only if it passes every gate that E6r passes and the Sukachev gate as well, its benchmark basal area RMSE is no more than 2% above 6.76 m^2 ha^-1, and its benchmark survival RMSE is no more than 2% above 0.124. If one is preferred, the change of system goes to Aaron as a question before anything is rebuilt, because it changes every projection. If none is, E6r stays and the comparison is reported in the supplement.

## 4. What is not changed by these tests

No constant is set by hand to pass a gate. A gate that fails is reported as failing. The published Zenodo version 1.13.1 is not edited; an adopted change goes into a new version.

## 5. Addendum, written November 14 before scripts 35 and 36 ran

Three additions at Aaron's instruction during the run. The first crown base run (forms C0 to C6) had finished and its held-out table had been read when this was written; scripts 35 and 36 had not run, and the height increment script had not finished.

Crown base. The crown base form of the earlier builds (HCB = HT / (1 + exp(-eta)), with eta on the square root of HT/100, ln(HT/DBH), a competition term, ln of basal area, and ln(BYI/100)) is added as candidate P7, refitted with the covariates of the present system (live koa basal area and basal area in larger trees). The same rule applies to all eight forms.

Stand-level mortality. A third stand-level form is added: S3m, the tree-level E6r with relative density held at or below 1 by a stand step, where any excess over the SDImax of S1 is removed in proportion to each tree's E6r hazard. It has no fitted or hand-set constant of its own. It is judged by the same rule as S1m and S2m.

Long-term assessment metrics. Following the evaluation of individual-tree simulators by emergent properties (Vospernik 2017; Vospernik et al. 2010), the 200-year runs also report the crown ratio derived from the crown base equation and the height to diameter ratio (HT in m over DBH in m), each as a basal-area-weighted stand mean and for the largest and smallest fifth of trees by diameter. They are reported against the range seen in the data (5th to 95th percentile of the tree records of that origin, where the origin has records) and against two ordering expectations: a height to diameter ratio that is higher in the smaller trees than in the larger trees of a stand and that falls as a stand ages, and a crown ratio that stays inside the observed range. These are assessment metrics and not pass or fail gates for adoption, because no threshold for them was set in advance; a metric outside the data range is reported as such. Crown records exist for natural stands only, so crown ratio in planted stands is an extrapolation of a natural-stand equation.

A fourth stand-level form was added after Aaron noted that the earlier stand-level equations had behaved well, and before any stand-level result had been read from a correct fit (a first run of script 35 failed to move from its starting values because of missing stand covariates, and its printed values are void). S4m is the whole-stand mortality model of García (2009), which the earlier builds used with a fixed anchor, floors and a level factor: S^a - (b D)^a = constant, with S = 100 / sqrt(N) the mean spacing and D the quadratic mean diameter as the driving size, a common exponent a and a coefficient b for each origin, all three estimated by binomial likelihood on plot-interval deaths, and deaths allocated to trees as in S1m. No floor, level factor, cap or fixed anchor is used in any stand-level form. The same rule applies.

## 6. Second round of height increment forms, specified after the first round was read (post hoc, disclosed)

First round result (log 33): no fitted form passed. L1, L2 and B1 all beat the E5 rule held out (RMSE 0.755, 0.703 and 0.758 against 0.811 m yr^-1; slope of observed on predicted 0.89, 0.88 and 0.90 against 0.57; both equivalence tests passed) and all failed condition (c), because basal-area-weighted height of planted stands reached 46 to 60 m at 200 years against a bound of 34.1 m. The cause is structural and visible in the coefficients: origin enters as a constant multiplier of height growth at every size (L1, L2) or as a higher asymptote (B1: about 49 m for a planted stand at median BYI), and the planted record is young, so the multiplier estimated on young planted trees is carried to old ones.

These forms were written after seeing that result, which makes them post hoc. The rule and its thresholds are unchanged, and the supplement states the order in which the forms were specified.

- B2: B1 with one asymptote for both origins, A = exp(a0 + a1 ln BYI), and origin acting on the rate, k = exp(lk + k_pl planted). Site sets how tall koa gets; origin sets how fast.
- B3: B2 times (annual diameter increment + 0.05) to a power h6.
- L3: L1 with an origin by height term, h7 planted x HT, so the origin effect can fade with size.
- L4: L2 with the same origin by height term.

R0 and L2 are rerun beside them for reference. If a second-round form passes, it is adopted under the same rule and reported as selected in a second round.

## 7. Third round of height increment forms: BYI interactions within an asymptotic form (written November 14, 2026, before script 42 ran)

Why. The plot-cluster bootstrap of B2 (300 resamples, script 38c), read before this section was written, showed that its asymptote is weakly constrained from above (26.9 m at the median BYI of natural stands, 95% interval 22.9 to 57.6 m) and that the interval of the site coefficient on the asymptote includes zero (-0.293 to 0.297). Version 1.14.0 of the deposit and manuscript v135 report B2 with that weakness stated. Aaron's instruction: the relationship with BYI is complex, so test potential interactions, and an asymptotic form is key. These forms are therefore post hoc with respect to rounds 1 and 2 and to the B2 bootstrap; the rule and its thresholds are unchanged.

Forms, all the bounded differential Chapman-Richards form m k HT [(A/HT)^(1/m) - 1] exp(c x) with x = (BAL/BA) RD, and ln(BYI) centred at 5 where it enters the rate or an interaction:

- B2 (reference, round 2): A = exp(a0 + a1 ln BYI), k = exp(k0 + k1 planted).
- B4: B2 with BYI also on the rate, k = exp(k0 + k1 planted + k2 ln BYI).
- B5: B2 with a site slope of the asymptote that differs by origin, A = exp(a0 + a1 ln BYI + a2 planted ln BYI).
- B6: B2 with BYI by competition, exp((c0 + c1 ln BYI) x).
- B7: one asymptote for all sites, A = exp(a0), and BYI on the rate, k = exp(k0 + k1 planted + k2 ln BYI). Six coefficients, as B2.
- B8: B7 with a rate response to BYI that differs by origin, k = exp(k0 + k1 planted + k2 ln BYI + k3 planted ln BYI).

No asymptote is fixed by hand. R0 (the rule) is rerun for reference.

Tests and rule. As sections 1 and 6: installations held out in the ten folds of record, the benchmark tree heights, the 200-year scenarios, and conditions (a) to (d) against R0. Among the forms that pass, B2 included, the choice is the one with the fewest coefficients within 2% of the lowest held-out RMSE; with equal coefficients, the lower RMSE. B2 therefore stays unless a round-3 form passes and is chosen over it by that rule.

Identifiability. The chosen form is bootstrapped with 500 plot-cluster resamples (script 43, the full three-pass estimator). The 95% interval of its asymptote at the median BYI of each origin is reported. It is not a pass or fail condition, because no threshold was set before the B2 bootstrap was read, but it is reported beside the same interval for B2, and if a round-3 form is chosen its interval is the reason given in the text only if it is narrower.

If a round-3 form is chosen, height and assumed volume are rebuilt (as script 39), and a new manuscript, supplement, workbook and deposit version follow; basal area, stems, QMD, SDI, the benchmark and the gates cannot change.

## 8. Fourth round of height increment forms: BYI kept, asymptote informed by the static height data (written November 15, 2026, before script 44 ran)

Why. Round 3 (script 42) left B2 in place: B4 and B6 had lower held-out RMSE and failed condition (c), B7 and B8 (one asymptote, BYI on the rate) failed condition (d), and B5 passed with one more coefficient and no gain. The 500-resample bootstrap of B2 (script 43) gave an asymptote of 27.0 m at the median BYI of natural stands with a 95% interval of 22.3 to 54.4 m, and a site coefficient whose interval includes zero (positive in 71% of resamples). Aaron's instruction on November 15: including BYI is logical, so explore alternatives. He chose three of four offered: anchor the asymptote, penalize the asymptote, and fit jointly with the height curve. This is a fourth look at the same held-out installations, so these forms are post hoc with respect to rounds 1 to 3; the rule and thresholds of section 1 are unchanged and the supplement states the order.

What was seen before writing this section: the round 3 log and bootstrap table; the coefficients of the height curve of record (E2: asymptote 1.37 + 19.73 m, b 0.0498, c 1.150); and counts only of trees in the height frame above two diameter thresholds (261 trees on 162 plots at or above the diameter at which E2 reaches 80% of its asymptote, 34.8 cm; 149 trees on 114 plots at 90%). No relation of height to BYI among large trees was looked at.

Forms. All use the increment form of B2, m k HT [(A/HT)^(1/m) - 1] exp(c x), with k = exp(k0 + k1 planted), and all keep BYI on the asymptote.

- B2 (reference) and R0 (the rule), rerun.
- A1, anchored asymptote, upper envelope. Stage 1: for each tree of the height frame (3,331 trees) with DBH of at least 34.8 cm, the asymptote implied by its height under the shape of E2 is A_i = 1.37 + (HT - 1.37) / (1 - exp(-b DBH))^c with b and c of record; ln(A_i) is regressed on ln(BYI) by quantile regression at tau = 0.95. Stage 2: A = exp(q0 + q1 ln BYI) is fixed and k0, k1, m and c are fitted to the increment pairs exactly as B2. Counted as six coefficients.
- A2, anchored asymptote, central. As A1 with tau = 0.50.
- J1, joint fit. The height curve HT = 1.37 + (A - 1.37)(1 - exp(-b DBH))^c and the increment equation share A = exp(a0 + a1 ln BYI). The objective is the weighted increment sum of squares divided by its mean square (per consecutive-interval weight, at the start of each pass) plus the height-curve sum of squares divided by the mean square of E2 of record on the same rows; three passes of the variance power as B2. Six increment coefficients plus b and c of the curve. Whether the J1 curve would replace Eq. 3 is not decided here; the tests below use E2 of record wherever a missing height is filled, so only the increment equation differs between forms. The held-out RMSE of the J1 curve is reported beside a three-parameter curve refitted on the same rows.
- P1, bounded B2. The B2 estimator with a penalty that holds A at every BYI of the fitting frame at or below 1.2 times the tallest measured tree (40.9 m, the bound of condition (c)). If the bound is not active at the estimates, P1 equals B2 and differs only in its bootstrap. P1 is a sensitivity analysis and is not eligible for selection, because the upper limit of its interval is set by the bound.

Held-out discipline. For each of the ten folds of record, the stage 1 regression (A1, A2) and the height-curve part (J1) use only trees of installations that are not in the test fold of the increment pairs.

Tests and rule. Conditions (a) to (d) of section 1 against R0, as in every round. Because the purpose of this round is identifiability and all eligible forms have six increment coefficients, the choice among the forms that pass (B2 included) and lie within 2% of the lowest held-out RMSE among them is the one with the narrowest 95% plot-cluster bootstrap interval of the asymptote at the median BYI of natural stands, measured as upper limit over lower limit (script 45, 500 resamples; for A1, A2 and J1 the plots of the height frame and of the increment frame are resampled together and stage 1 is repeated in every resample; B2 uses script 43). B2 therefore stays unless an eligible round-4 form passes, is within 2% of the lowest RMSE, and has a narrower interval.

Reported whichever form is chosen: the stage 1 slopes q1 with intervals and whether each interval excludes zero; the asymptotes of A1 and A2 at the median BYI of each origin, whose difference is a structural uncertainty that neither interval contains; the P1 interval; the J1 curve against E2.

If a round-4 form is chosen, height and assumed volume are rebuilt (as script 39) and a new manuscript, supplement, workbook and deposit version follow; basal area, stems, QMD, SDI, the benchmark for those variables and the gates cannot change.

## 9. Addendum to round 4: maximum times modifier (written November 15, 2026, after the full-frame fits of script 44 were read and before any held-out, benchmark, scenario or bootstrap result of round 4 was read)

Why. Aaron's suggestion on November 15, while script 44 was running: a maximum times modifier approach, with the maximum set by height and BYI. B2 is already a potential times a modifier, since its competition term multiplies a bounded function of height, BYI and origin, but its potential is fitted as a mean with the modifier, by least squares. The forms here differ in one respect: the potential is estimated first as an upper envelope of height increment given height and BYI alone, and the modifier is then fitted with the potential held fixed.

What was seen before writing: the full-frame estimates of B2, A1, A2, P1 and J1 (stage 1 slopes 0.067 and -0.025; asymptotes 20.9 to 30.3 m at the median BYI of natural stands). Nothing held out.

Forms.

- M1. Stage 1, maximum: ΔHTmax = m k HT [(A/HT)^(1/m) - 1], A = exp(a0 + a1 ln BYI), with one k and one m for all trees, fitted to all height pairs by quantile regression at tau = 0.95 (check loss on the annualized difference between observed and projected height at the end of each pair, pairs weighted by 2 over the height visits of the tree; Nelder-Mead from the B2 estimates with the planted rate, restarted once). Stage 2, modifier: ΔHT = ΔHTmax exp(g0 + g1 x + g2 planted), x = (BAL/BA) RD, fitted by the weighted least squares of B2 (three passes of the variance power) with stage 1 fixed. Seven coefficients. The modifier is not forced below one; its largest value in the fitting frame is reported.
- M2. As M1 with tau = 0.90.

Tests and rule. Folds, benchmark, scenarios and conditions (a) to (d) as section 8, with both stages refitted in every training fold. M1 and M2 join the candidates of section 8. Among passing forms within 2% of the lowest held-out RMSE, the form with the fewest coefficients is chosen (section 1), and among those with equally few, the narrowest asymptote interval (section 8). A seven-coefficient M form is therefore chosen only if no passing six-coefficient form is within 2% of it. An M form that passes is bootstrapped with 500 plot-cluster resamples, both stages repeated in each (script 46).

## 10. Ingrowth for the natural (uneven-aged) scenarios (written November 15, 2026, before script 47 ran)

Why. Aaron, November 15: be conservative on long-term projections, and include ingrowth for the uneven-aged scenarios. Offered four ways for ingrowth to enter, he chose a density-dependent rate.

What was seen before writing: counts only. The frames hold 10 koa recruits past 12.7 cm on 5 of the 48 remeasured US Forest Service FIA subplots of natural stands (one nine-year interval each, 432 subplot-years, each tree standing for 59.5 trees ha^-1, about 1.4 trees ha^-1 yr^-1), and 15 recruits on 7 planted plots. FIA recruits below 12.7 cm (microplot size) were excluded when the frames were built. No relation of ingrowth to density, site or any other variable was looked at. Some of the 10 are large for a nine-year interval (up to 24.6 cm), so trees missed at the first visit cannot be ruled out; the count is used as recorded and this is stated.

Frame. The 48 remeasured FIA subplots of natural stands. Response: the number of koa first recorded alive at the second visit with DBH of at least 12.7 cm. Exposure: interval length times subplot area (1/59.5 ha). Relative density at the first visit is koa SDI over the SDImax of record for the subplot (S1).

Forms, Poisson with a log link and the exposure as offset: N1, a constant rate; N2, rate = exp(n0 + n1 RD). Reported only, not eligible: N3, rate = exp(n0 + n1 basal area of all species).

Tests and rule. Installations (FIA plots) held out in the ten folds of record; score, the held-out Poisson deviance. Intervals from 2,000 resamples of installations. N2 enters the natural scenarios only if all three hold: (a) its held-out deviance is below that of N1; (b) n1 is negative and the upper limit of its 95% interval is below zero; (c) with ingrowth in the three natural scenarios (trees entering at 12.7 cm with the height of Eq. 3, each year, at the rate for the relative density of that year) the six 200-year gates of record still pass. If N2 fails, nothing is adopted: the constant rate and its interval are reported and the choice between a constant-rate scenario assumption and the present limitation statement goes back to Aaron.

Reported either way: the three natural scenarios at 20, 40, 100 and 200 years without ingrowth, with N1 and with N2 (basal area, stems, QMD, RD, height under Eq. 6 of record), and the 95% range of each over 300 bootstrap draws of the ingrowth coefficients with every other equation at its estimates. The benchmark of Table 3 follows the trees of the first visit and cannot change. Planted scenarios stay without ingrowth.

## 11. Ingrowth with relative density, basal area and BYI (written November 15, 2026, before script 48 ran)

Why. After the result of section 10 (N2 failed; Aaron chose the constant rate N1 for the natural scenarios), Aaron suggested using RD with basal area and BYI. These forms are post hoc with respect to script 47, whose log was read first: RD slope positive (0.468), an all-species basal area slope of -0.0315 (z -1.90), recruits by RD third 5, 1 and 4, held-out deviance N1 73.3, N2 83.9, N3 75.0. The frame is unchanged (48 subplots, 10 recruits on 5), so a three-covariate form has about three recruits per coefficient and is expected to be unstable; that is the reason for the held-out test.

Two stages, at Aaron's instruction given while this section was being written and before anything was run. Stage 1, occurrence: whether a subplot gained at least one koa recruit past 12.7 cm over its interval, a binomial model with a complementary log-log link and the log of interval length as offset, so the linear predictor is an annual hazard. Stage 2, amount: the number of recruits on a subplot that gained any, a zero-truncated Poisson with one mean (five subplots carry all ten recruits, so stage 2 takes no covariate). Expected ingrowth per hectare and year is the stage 1 probability over a nine-year interval times the stage 2 mean, divided by nine years and the subplot area.

Stage 1 forms; basal area is koa basal area at the first visit, which the system projects: T1, constant; T2, RD; T3, BA; T4, RD, BA and ln BYI (Aaron's suggestion); T5, RD and ln BYI; T6, BA and ln BYI; T7, RD and BA; T8, ln BYI. Reported only: T4 with all-species basal area, which the system does not project. The single-stage constant rate N1 is rerun as the reference.

Rule. Among T2 to T8, the form with the lowest held-out stage 1 deviance (installations held out, ten folds of record, both stages refitted in each training fold) replaces the constant rate only if all hold: (a) its held-out stage 1 deviance is below that of T1 and the held-out Poisson deviance of its expected counts is below that of N1; (b) the ratio of its expected rate at the 90th to the 10th percentile of each density term (RD, BA) in the frame, with the other terms at their medians, is below one with the upper limit of its 95% installation-bootstrap interval below one, so that ingrowth falls with density; (c) every fold fit and at least 90% of 2,000 bootstrap fits are clean (converged, finite coefficients, no fitted probability of zero or one); (d) the 200-year gates are unchanged from the run without ingrowth and the rate stays between zero and the largest subplot rate observed in every year of the three natural scenarios. Otherwise the constant rate stays, as Aaron decided, and the two-stage forms are reported in the supplement as tested. If only T1 is supported, the two-stage constant and N1 give the same expected rate by construction and N1 is kept.

## 12. Exploratory screen of other ingrowth covariates and interactions (written November 15, 2026, before script 49 ran)

Why. Aaron asked whether interactions or other covariates such as SDI or QMD help. Read before writing: the fits and held-out scores of script 48 (T5, RD with ln BYI, was the only form below the constants held out, with a positive RD coefficient). With five subplots carrying any recruit, the frame supports about one stage 1 coefficient, so a screen of many forms will pick some by chance. This screen is therefore exploratory: it is reported in full, nothing in it is adopted by rule, and any use of a screened form is Aaron's decision and is stated as post hoc.

Stage 1 forms (cloglog, interval offset; stage 2 one mean), koa quantities at the first visit: single terms RD, SDI, BA, QMD, ln(stems + 1), all-species BA, BA of other species, koa share of BA, ln BYI; each density term with ln BYI; interactions RD by ln BYI, SDI by ln BYI, QMD by ln BYI, SDI by QMD; RD, QMD and ln BYI together. Reported for each: coefficients with z, AIC, held-out stage 1 deviance and held-out count deviance in the ten folds of record, and the number of clean fold fits.

## 13. Two-stage ingrowth with QMD in the natural scenarios (written November 15, 2026, before script 50 ran)

Decision. After the screen of section 12 (QMD alone: coefficient -0.131, z -2.43; held-out stage 1 deviance 25.3 against 37.2 for the constant; count deviance 39.6 against 73.3; ten clean folds), Aaron chose the QMD form for the natural scenarios, to be run through the bootstrap and the 200-year checks first. The form was selected from a screen of 22 on five subplots with any recruit, so it is post hoc and is stated as such wherever it is used. He was told that the starting list of the natural scenarios already carries stems below 12.7 cm (1,091 of 2,108 stems ha^-1), so a rate that is high at low QMD adds stems alongside those the list is already growing, and he chose the form without a delayed start.

Form. Stage 1: probability that a subplot gains any koa recruit past 12.7 cm in nine years = 1 - exp(-9 exp(t0 + t1 QMD)), QMD of koa in cm. Stage 2: two recruits per subplot that gains any (zero-truncated Poisson mean, one value). Expected ingrowth (trees ha^-1 yr^-1) = probability times stage 2 mean times 59.5 / 9, entering at 12.7 cm with the height of Eq. 3, natural scenarios only.

Checks before it goes into any table: (i) 2,000 installation resamples of both stages, with the share of clean fits, intervals of t0, t1 and of the rate at QMD 15, 25, 40 and 60 cm; (ii) the six gates against the run without ingrowth; (iii) the rate in every scenario year against the largest subplot rate observed, and scenario QMD against the QMD range of the frame; (iv) the three natural scenarios at 20, 40, 100 and 200 years without ingrowth, with the constant rate, and with the QMD form, and the 95% range over 300 bootstrap draws. If fewer than 90% of bootstrap fits are clean, a gate that passes without ingrowth fails with it, or the rate leaves the observed range, the result goes back to Aaron before anything is built.
