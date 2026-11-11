# Koa: maximum SDI as a function of BYI. Rules written before any run (November 11, 2026)

Aaron's question: should SDImax be modeled as a function of BYI so that it varies by site and comes closer to the plot-level estimates, in place of one value (742) for a new stand? Nothing below has been run. What is known going in: with each plot's own brms SDImax the benchmark basal area RMSE is 6.70 m² ha⁻¹ and with 742 it is 10.76; the earlier environmental model for SDImax (42 predictors, Hawaii Island FIA plots) explained 0.25 of the variance in blocked cross-validation; the median plot in the brms fit has one visit.

## Candidate models of SDImax

Data: the 305 growth plots matched to a brms value, with their BYI and origin, and their rows in the brms fit frame (`koa_brms_sdimax_20261102/out/fit_frame.csv`).

1. Direct: the quantile mixed model of record in its frequentist form (lqmm, tau 0.95, random plot intercept), ln(stems) on ln(QMD), with ln(BYI) added to the fixed part, with and without origin. This is the test of whether BYI moves the size-density frontier, because it does not regress on shrunken plot estimates.
2. Second stage: ln(plot brms SDImax) on ln(BYI), with and without origin, weighted by the inverse posterior variance. This is on the scale the equations were fitted with, so it is the form that would be used in application. It is a regression on shrunken estimates and is labelled as such.
3. References: 742 for every plot; the origin mean (origin only, no BYI); each plot's own value.

## Tests, identical for every candidate

a. Held out by installation (the ten folds of `utils.R`): for model 1 the mean check loss of held-out rows with and without BYI; for model 2 the held-out R² of ln(SDImax) and the slope of observed on predicted (attenuation). The BYI coefficient with a plot-cluster bootstrap interval (model 1) and its range when each installation is left out (model 2).
b. Benchmark: the 55 plots and 290 plot-horizons, projected with the current E4r and E6r and the out-of-fold SDImax of each candidate; survival, QMD and basal area RMSE, bias and equivalence at the longest horizon. Then the same with E4r and E6r refitted using the candidate's SDImax, since the equations were fitted with each plot's own value and an applied system should be fitted with the SDImax it will be given.
c. Bakuzis: the six 200-year scenarios with SDImax predicted from each scenario's BYI and origin, same gates as script 15, plus the year at which basal area stops being ordered by site.
d. Ceiling: the correlation of plot SDImax with the plot's own largest observed SDI, for plots with one visit and with more than one, to show how much of the plot-level variation a site variable could ever reach.

## Decision

SDImax as a function of BYI is adopted only if all three hold: (1) the 95% bootstrap interval of the BYI coefficient in the direct model excludes zero; (2) with out-of-fold SDImax the benchmark basal area RMSE is at least 5% below that with 742 and neither survival nor QMD RMSE is more than 2% worse; (3) every gate that passes with 742 still passes. Between the refitted and unrefitted equations the lower benchmark basal area RMSE is taken. If it is not adopted, 742 with the low and high cases stays, and what BYI does buy is reported. A failed test is not closed by adding terms after the fact; any model tried beyond those listed is reported as exploratory.

## Stress alternatives fixed now

Unweighted second stage; tau 0.99 in the direct model; origins fitted separately; FIA plots excluded; plots with a single visit excluded.

## Honest limits stated in advance

BYI already enters diameter increment and mortality, so a BYI effect on SDImax is partly confounded with those. The workbook site classes at BYI 340 and 450 lie above the 90th percentile of planted plots (309), so SDImax there would be extrapolated. A plot SDImax from one visit is close to a restatement of that plot's stocking.
