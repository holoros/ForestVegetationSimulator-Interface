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
