# koa_survival_calibrated.R   (tuned 2026-06-05; ramp re-tuned 2026-08-05;
#                              SDImax 1350 withdrawn 2026-08-06; SDImax 933
#                              withdrawn 2026-08-06 by red team seed 20260806;
#                              NO SCALAR SDImax IS DEPLOYED IN THIS VERSION)
# Recommended operational survival for FVS-HI koa, to REPLACE the published
# cloglog (surv.parm / surv_prob) in HiGy.R.
#
# Units in this file are metric throughout and are written in plain ASCII:
# m2 ha-1 for basal area, trees ha-1 yr-1 for recruitment, cm for diameter.
# Stand density index is reported metric first with the imperial equivalent in
# parentheses, using the divisor 2.535 implied by the code's own index diameter
# of 25 cm. A reviewer will sanity check against the imperial number.
#
# ============================================================================
# ==  NO DEFENSIBLE SCALAR SDImax EXISTS FOR THIS DATA. NONE IS DEPLOYED.   ==
# ==  BOTH 1350 METRIC (533 IMPERIAL) AND 933 METRIC (368 IMPERIAL) ARE     ==
# ==  WITHDRAWN. SDImax IS NOW A REPORTING-ONLY ARGUMENT DEFAULTING TO NA.  ==
# ==  THE MORTALITY RAMP IS PARAMETERISED IN ABSOLUTE SDI AND IS UNCHANGED. ==
# ============================================================================
#
# WHY NO SCALAR IS DEPLOYED. The 933 value carried in the previous version of
# this file was withdrawn by an independent red team pass on 2026-08-06, seed
# 20260806, artifacts at /users/PUOM0008/crsfaaron/koa_redteam/. Four findings,
# any one of which would be disqualifying, and which together close the question.
#
# First, the estimator is not an estimator of a boundary in any useful sense. It
# is quantile(sdi_reineke, 0.99, type = 7) evaluated on n = 59 screened
# plot-years. The type 7 index is 58.42, so the returned value is a fixed linear
# blend of order statistics 58 and 59 and nothing else. The other 57 observations
# enter only through their rank, and perturbing any one of them moves the result
# by 0.023 percent. Leave one out over the 59 screened plot-years spans 882 to
# 933 metric (348 to 368 imperial), which is the sensitivity of a two point
# statistic dressed as a sample quantile.
#
# Second, the reported upper end of the interval is degenerate. The published 95
# percent upper limit of 946 metric (373 imperial) is the sample maximum bit for
# bit, and 26.5 percent of the cluster bootstrap draws land exactly on it. An
# interval whose upper limit is a single observation repeated in a quarter of the
# replicates is describing the resampling scheme, not the population.
#
# Third, and decisively, every value on this scale is an extrapolation. NONE of
# the 59 screened plot-years reaches the Reineke index diameter of 25 cm. Their
# quadratic mean diameters run from 1.3 to 22.4 cm with a median of 11.3 cm, so
# every reported SDI is obtained by projecting each plot-year up to 25 cm along a
# slope of -1.605 that has never been estimated for Acacia koa A. Gray. The free
# upper envelope slope estimated on these same data is -0.714 to -0.768,
# depending on the envelope estimator. Forcing -1.605 on a cloud that sits
# entirely below the index diameter inflates every plot-year, and it inflates the
# large diameter plot-years most, which are exactly the ones that then set the
# 0.99 quantile. The direction of the bias is upward and it is not small.
#
# Fourth, the screen that produced the number is a tuning knob rather than a
# filter. The binding element of the screen is the koa crown packing limit, and
# that limit is set by a growing space index. At growing space index 15 the
# screen returns 933 metric (368 imperial). At 20 it returns 622 metric (245
# imperial). At 25 it returns 373 metric (147 imperial). Growing space index 15
# is the most compact crown allometry ever measured for the species and is the
# only setting in that series whose output lies above the koa literature. The
# number was therefore selected, not estimated.
#
# THE EARLIER EPISODE, PRESERVED FOR THE RECORD. The published constant was 500
# metric (197 imperial). That number was never a pooled-sample quantity: it was
# fitted on FIA plot-years alone and then carried into an equation estimated on
# all four sources, so it was wrong in provenance before it was wrong in value. A
# first correction, dated 2026-08-05, replaced it with 1350 metric (533
# imperial) on the strength of a 0.99 quantile regression of the Reineke
# intercept with the slope fixed at -1.605. That correction was withdrawn on
# 2026-08-06. The estimator used, rq(a_i ~ 1, tau = 0.99) on an intercept-only
# model, does not fit a boundary at all; on 269 observations it returns an order
# statistic, so the reported value 1351.50016168609 was one plot-year copied out
# verbatim, PSP plot 102 subplot 2 measured in 2021, and that plot-year rests on
# FIVE stems spread over an implied area of about 56 m2. The four plot-years that
# defined the frontier carried 5, 12, 14 and 30 stems, and their implied basal
# areas ran to 129 m2 ha-1, three times the highest basal area ever published for
# koa. Checked against Baker and Scowcroft's koa growing space index of 15, those
# four plot-years exceeded the non-overlapping-crown packing limit by factors of
# 3.20, 1.89, 1.82 and 1.50, and the rank correlation between crown-packing
# overshoot and Reineke SDI across the whole cloud is +0.990. In other words the
# SDI ranking of this dataset is the overpacking ranking. Plot-years carrying
# forty stems or more never exceed 924 metric (365 imperial). The screened
# replacement, 933 metric, was an attempt to repair that by filtering rather than
# by re-estimating, and it inherited both the fixed slope and a screen whose
# tightest setting was chosen after the fact. Full audit of the 1350 episode at
# /users/PUOM0008/crsfaaron/koa_sdimax_audit/; audit of the 933 episode at
# /users/PUOM0008/crsfaaron/koa_redteam/.
#
# WHAT REPLACES THE SCALAR: A DIAMETER-CONDITIONAL BOUND. A single number is the
# wrong object here, because the Reineke index diameter is far outside the data.
# What the koa literature does support is a maximum stand basal area. Harrington,
# Fownes, Meinzer and Scowcroft (1995, Oecologia 102:277-284,
# doi 10.1007/BF00329794) report 42 m2 ha-1 as the highest basal area observed in
# koa, and that is an external anchor: it is a directly measured quantity at
# diameters the inventories actually carry, and it does not depend on the slope,
# the screen, or the expansion factors. No dispersion is published with it, so it
# is carried here as a single reported maximum and is flagged as such rather than
# given a fabricated interval. [UNKNOWN: the sampling variability of the 42
# m2 ha-1 anchor; Harrington et al. report it as an observed maximum, not as an
# estimate with an interval.]
#
# Converting that anchor through the Reineke identity,
#     BA = SDI * (pi/4) * 25^1.605 / 1e4 * Dq^0.395,
# gives the bound as a function of quadratic mean diameter rather than as a
# scalar: 934 metric (369 imperial) at Dq 20 cm, 796 metric (314 imperial) at
# Dq 30 cm, and 651 metric (257 imperial) at Dq 50 cm. The bound falls with
# diameter, which is the whole point: quoting one number for a species whose
# inventory sits at a median Dq of 11.3 cm hides the fact that the number is
# diameter conditional. Use the bound at the diameter you are actually at.
#
# WHAT THE KOA LITERATURE INDEPENDENTLY SUPPORTS, RETAINED. Two independent koa
# anchors survive the withdrawal of the screened estimate and should continue to
# be quoted, because neither depends on this dataset's expansion factors or on
# the fixed slope. Baker and Scowcroft's 2005 crown-based A-line converts to
# roughly 440 to 530 metric (175 to 210 imperial), an interval that comes from
# the range of their crown-width allometry rather than from a resampling scheme.
# Scowcroft et al.'s 2008 stand, which self-thinned from about 20000 seedlings
# ha-1 to 1000 trees ha-1 over 23 years and is the best empirical anchor on a
# genuine koa self-thinning trajectory, sits at 595 metric (235 imperial) as a
# single-stand point with no interval reported. Taken together the koa-specific
# literature supports roughly 500 to 650 metric (197 to 256 imperial), which is
# well below both withdrawn values and is consistent with the 42 m2 ha-1 anchor
# at the diameters those stands were measured at. The persistent gap between that
# range and anything this dataset produces is itself a finding: it says the
# problem is in the plot-year records, not in the choice of constant.
#
# WHAT WAS WRONG WITH THE EXPANSION-FACTOR STORY, CORRECTED. Earlier versions of
# this file stated that plot area and expansion factor are ABSENT from the source
# files and that back-computing them exposes 112 distinct implied expansion
# factors across 269 plot-years. THAT CLAIM IS FALSE AND IS RETRACTED HERE.
# AK_SURV.csv carries a fully populated EXPF.0 column with exactly FOUR distinct
# values, 14.92, 24.80, 49.56 and 185.91 trees ha-1 per stem, corresponding to
# plot areas of 670.0, 403.2, 201.8 and 53.8 m2. The column is non-missing on all
# 5,969 rows and is constant within 95 of the 100 plots. The five exceptions are
# FIA installations carrying both 14.92 and 185.91, which is macroplot and
# microplot nesting rather than an inconsistency: the 185.91 rows hold stems from
# 2.5 to 11.7 cm and the 14.92 rows hold stems of 12.7 cm and above. The "112
# distinct implied expansion factors" figure was an artifact of reconstructing
# expansion from row counts in an already filtered file, which manufactures a
# distinct implied area for every distinct surviving row count. It measured the
# filter, not the inventory.
#
# THE REAL LIMITATION, STATED PROPERLY. The relative-density exceedance that
# originally motivated abandoning 500 is a data quality problem in the plot-year
# density and diameter records, not a problem in the constant. At any SDImax
# below 2285 metric (901 imperial) some plot-years still exceed relative density
# 1.0, and 2285 is set by a single plot-year implying 129.1 m2 ha-1 of basal
# area, roughly three times the published koa maximum of 42 m2 ha-1. No choice of
# constant can fix a plot-year that is physically impossible, and raising the
# constant until the exceedances disappear is the error that produced 1350. The
# exceedances are the signal that specific plot-year density and diameter records
# need adjudication against the source inventories, and that is the work item.
#
# THE EXCEEDANCE EVIDENCE ITSELF, RETAINED AND REINTERPRETED. Under SDImax 500,
# 41.4 percent of deduplicated tree records and 27.9 percent of plot-years sit
# above relative density 1.0, with a maximum RD of 4.39, which is impossible by
# construction. Under 933 those fall to 5.29 percent and 6.32 percent with a
# maximum RD of 2.35. Under the withdrawn 1350 they were 0.95 percent and 0.74
# percent with a maximum of 1.63. That monotone improvement was read at the time
# as evidence that the larger constants were better. It is not. It is arithmetic:
# any denominator large enough will absorb any numerator, and 1350 looked best
# only because it was large enough to swallow physically impossible plot-years.
# The exceedance count is therefore a diagnostic of the numerator and must never
# again be used to select the denominator. Recomputed on Cardinal 2026-08-06 from
# koa_surv_respec/data/surv_recovered_ii.csv (4518 records after the standard
# deduplication) and koa_surv_respec/out/plot_year_reineke.csv (269 plot-years),
# the same files that produced the published figures.
#
# [UNKNOWN: EXPF.0 settles plot area and expansion factor, but three questions
# about the PSP network remain open and cannot be settled from these files:
# whether any part of the network is variable-radius rather than fixed-area,
# whether subplots were subsampled between visits, and whether the tree lists
# were truncated by a minimum measured diameter that moved between visits. The
# last of these bears directly on the impossible plot-years and should be asked
# of the PSP custodians first.]
#
# WHAT THIS MEANS OPERATIONALLY. Relative density is a REPORTING CONVENIENCE in
# this file and has NO DYNAMICAL ROLE. The mortality ramp is parameterised in
# absolute SDI, onset at 200 and full lift at 850, so it does not need SDImax and
# does not use it. With SDImax left at its default of NA the function computes no
# relative density, returns no relative density, and behaves exactly as it did at
# SDImax 933. If a caller supplies a value, it is honoured and relative density
# is computed from it and attached as an attribute for reporting, but no default
# number is shipped and none should be invented downstream. Any figure, table or
# manuscript sentence expressed as a percent of SDImax must either name the
# constant it used and label it as withdrawn, or be restated in absolute SDI.
# ============================================================================
#
# THE RAMP IS NOT AFFECTED, AND THAT IS THE POINT. The self-thinning ramp is
# parameterised in ABSOLUTE SDI, onset at 200 and full lift at 850. Under the
# previous parameterisation SDImax cancelled identically out of
# frac = (RD - onset)/(full - onset) once RD was written as SDI/SDImax; under the
# present one it never enters. This was verified numerically on Cardinal rather
# than asserted. The survival function evaluated on a grid of 25001 points over
# SDI 0 to 2500 for both origins agreed between SDImax 500, 933 and 1350 to
# 1.1e-16, and the present absolute-SDI form agrees with the withdrawn 933 form
# to the same order. Six 300-year project_cohort runs, two origins by three BYI
# levels, agreed across the three SDImax values to 2.3e-13 in trees ha-1, 7.1e-15
# in QMD, 1.4e-14 in basal area and 2.3e-13 in SDI at every one of the 301 annual
# steps. With ingrowth active, project_psp reaches the same 300-year steady
# state, natural 16.3 m2 ha-1 at SDI 367 and plantation 15.9 m2 ha-1 at SDI 301,
# agreeing to 1.1e-13. Realised annual mortality on the observed record is
# identical to fifteen decimal places at SDImax 500, 933, 1087, 1350 and 1882 and
# at SDImax absent. THIS IS A CONSTANTS AND DOCUMENTATION CORRECTION, NOT A
# RE-FIT. The ramp was not re-tuned and must not be.
#
# CORRECTION OF A FALSE CLAIM MADE ELSEWHERE. It was previously reported that
# correcting SDImax improved the realised Reineke self-thinning slope from a
# range of -1.06 to -1.37 toward -1.11 to -1.61, and that this was independent
# corroboration of the new constant. THAT CLAIM IS FALSE AND MUST NOT BE
# REPEATED. Because SDImax cancels out of the ramp, the realised slope is
# invariant to it: holding the ramp fixed in absolute SDI and moving SDImax from
# 500 to 1350 leaves the slope range bit-identical at all six BYI levels, while
# holding SDImax at 500 and applying only the re-tuned ramp reproduces the
# "corrected" range exactly, including the -1.61 that was highlighted against the
# theoretical -1.605. The entire improvement came from the ramp re-tune and none
# of it from SDImax. Citing it as evidence for a particular SDImax is circular,
# since the ramp was re-tuned because SDImax had been changed. The one channel
# through which SDImax can move a trajectory, holding the thresholds at RD 0.65
# and 0.85 so that the absolute onset silently relocates, makes the slope
# dramatically WORSE, -0.03 to -0.65. No self-thinning slope result computed from
# this model can corroborate a choice of SDImax, and no claim of this kind
# appears anywhere in this file or in koa_ingrowth.R, and none may be added.
#
# WHY THE RAMP WAS RE-TUNED RATHER THAN RESCALED (unchanged from 2026-08-05).
# The thresholds 0.65 and 0.85 were themselves fitted quantities, tuned against
# observed mortality UNDER SDImax = 500, which placed the self-thinning onset
# near SDI 325 and full lift near SDI 425. Two options were evaluated and the
# second was adopted:
#   (a) preserve the absolute thresholds 325 and 425 and re-express them on
#       whatever RD scale was in force. Dynamically identical to the published
#       equation; only the reporting denominator changes.
#   (b) re-tune the ramp from the data at the corrected scale. ADOPTED.
# Both were tested by profile likelihood on the recovered variant (ii) survival
# data restricted to DBH >= 2.5 cm, the tree list FVS actually carries (n =
# 4141 records, 927 events, 15432 tree-years, 48 installation clusters), with
# base_nat, base_plt and maxlift maximised out at every threshold pair so that
# threshold location is not confounded with mortality level. Option (a) is
# rejected, likelihood ratio 67.3 on 2 df, P = 2.4e-15. That test is itself
# SDImax-free, because both options are stated in absolute SDI, so the result
# stands unchanged with no SDImax at all exactly as it stood at 933 and at 1350.
# Simply keeping 0.65 and 0.85 and swapping the denominator is rejected far
# harder; at SDImax 1350 the profiled likelihood ratio was 137.2, P = 1.6e-30,
# and maxlift collapsed to 1.7e-11, that is, the self-thinning term switched off
# entirely and the model degenerated to a constant hazard. The same failure mode
# recurred at 933, where the naive RD rule would silently relocate onset from SDI
# 200 to SDI 606 and full lift from 850 to 793; evaluated at the published levels
# it is rejected against the deployed ramp by a likelihood ratio of 1916.3 on
# 2 df. That is the failure mode a naive rescale would have shipped at any
# constant, and it is the reason the RD scale has now been removed from the
# dynamics entirely.
#
# THE RE-TUNED THRESHOLDS, in absolute SDI so that they do not depend on any
# constant: onset at SDI 200 metric, 79 imperial (95 percent profile region 75 to
# 225 metric, 30 to 89 imperial) and full lift at SDI 850 metric, 335 imperial
# (95 percent profile region 800 to 925 metric, 316 to 365 imperial). The
# full-lift threshold is the well identified one and is stable across samples;
# the onset is not, and moves to SDI 750 metric (296 imperial) if sub-2.5 cm
# seedling records are left in. [UNKNOWN: the onset location is sample dependent
# and should be revisited when the sub-2.5 cm records are adjudicated.]
#
# INDEPENDENTLY REPRODUCED 11 August 2026, thresholds UNCHANGED. Profiling the
# three mortality levels out at every point of a 25-unit threshold grid under seed
# 20260811, on the standardised sample described above, puts the POINT MAXIMUM of
# the profiled surface at exactly onset 200 and full lift 850, and returns a joint
# 95 percent region of onset 75 to 225 and full lift 800 to 925. That reproduces
# both regions quoted above to the grid step, on an independent implementation.
#
# THE PROFILE REGION IS NOT A CLUSTER-ROBUST INTERVAL AND MUST NOT BE QUOTED AS
# ONE. An installation-cluster bootstrap over the 48 installations, 200 draws,
# puts the onset anywhere from 100 to 700 and makes it BIMODAL at 200 and 700 with
# almost nothing between, and puts full lift anywhere from 300 to 1000 with the
# point estimate landing at 800 or 900 in 139 of the 200 draws. The two intervals
# answer different questions, the profile describing curvature of the likelihood
# at the optimum on one sample and the bootstrap describing resampling of the
# installations, and they disagree. QUOTE BOTH AND LABEL WHICH IS WHICH. The
# bimodality is the same sample dependence flagged in the UNKNOWN above, arriving
# from resampling alone without touching the seedling screen, so it corroborates
# that flag rather than adding a second problem.
#
# WHERE FULL LIFT SITS ON A RELATIVE SCALE, AND WHY IT IS NOT QUOTED. Full lift
# at SDI 850 metric is 1.70 of the published 500, 0.911 of the withdrawn 933, and
# 0.630 of the withdrawn 1350. Under the diameter-conditional bound it is 0.91 at
# Dq 20 cm, 1.07 at Dq 30 cm and 1.31 at Dq 50 cm. That spread, a factor of 2.7
# across constants that were all defended in writing within 24 hours, is the
# argument for not quoting a relative figure at all. On the substance the shape
# is right: a self-thinning term that reaches its maximum only as the stand
# approaches its own density limit is what the theory asks for, and it is a clear
# improvement on the withdrawn 1350, where full lift implied that koa attains
# maximum density-dependent mortality at under two thirds of carrying capacity,
# and on the published 500, where full lift computed to RD 1.70 and was therefore
# unreachable by construction. Because the ramp is parameterised in absolute SDI
# this is a reporting question and not a dynamical one, and no projected
# trajectory changes under any of these readings.
#
# WHAT WAS DELIBERATELY NOT CHANGED. base_nat, base_plt and maxlift are LEVELS,
# and the level of koa mortality is currently controlled by an unresolved
# death-recording convention (the sentinel rows) rather than by any density
# constant. Fitting them on the recovered data gives base_nat 0.0384 (0.0142 to
# 0.0510), base_plt 0.0142 (0.0000 to 0.0218) and maxlift 0.0870 (0.0393 to
# 0.1436), all 95% cluster bootstrap over installation. Those values also REVERSE
# the published origin ordering: observed annual mortality is 6.41% natural
# against 2.32% planted on this sample, and the independent cloglog
# respecification finds a Planted coefficient of -1.151 (wild cluster bootstrap
# P < 0.001), so planted stock is protective, not the reverse. They are recorded
# here as base_nat_recovered, base_plt_recovered and maxlift_recovered but are
# NOT the defaults, because HiGy.R as it stands carries no ingrowth, and with no
# recruitment a 3.8% per year background draws an operational stand down to 2 to
# 3 m2 ha-1 of basal area by year 200. With koa_ingrowth active they are safe
# (steady state 13.5 to 16.3 m2 ha-1 at 300 years). Enable them only once the
# sentinel convention is settled AND ingrowth is wired into HiGy.R. None of these
# levels moves with SDImax; all were verified invariant on 2026-08-06 and again
# with SDImax absent.
#
# THOSE THREE LEVELS ARE THE MAXIMUM LIKELIHOOD ESTIMATE AT THE DEPLOYED
# THRESHOLDS, NOT A REFIT OF CONVENIENCE, and they reproduce. Two independent
# implementations on 11 August 2026, both at onset 200 and full lift 850, return
# base_nat 0.038371, base_plt 0.014153 and maxlift 0.087030, and base_nat
# 0.038387, base_plt 0.014166 and maxlift 0.087007, against the 0.0384, 0.0142 and
# 0.0870 recorded above. Agreement to five decimal places across two estimators
# written independently removes any reading in which the recovered levels are an
# artifact of one implementation.
#
# THE CONCRETE REASON NOT TO ENABLE THEM. The ingrowth argument above is a
# consequence, not the test. The test is the Bakuzis matrix, and the recovered
# levels fail it: enabling them moves SIX OF SIX Reineke self-thinning
# trajectories outside the (-2.2, -1.2) tolerance, and raises the natural-stand
# Eichhorn coefficient of variation from 11.4 to 20.3 percent. The published
# levels pass both. Biological consistency of the long-term projection, not the
# ingrowth wiring, is what holds base_nat at 0.003 and maxlift at 0.15, and that
# is the sentence that was missing here.
#
# THE ORIGIN REVERSAL IS NOT A SENTINEL ARTIFACT, AND THAT QUESTION IS NOW
# SETTLED. Removing every sentinel row from the death records leaves the reversal
# intact: annual mortality on non-sentinel deaths alone runs 0.65 percent natural
# against 0.40 percent planted, the same direction as the 6.41 against 2.32
# percent on the full record. It also holds at the cluster level, with base_nat
# exceeding base_plt in 95.5 percent of 200 installation-cluster bootstrap draws.
# So the deployed ordering, base_plt 0.006 above base_nat 0.003, has the SIGN
# WRONG UNDER BOTH READINGS of the death records, and it is retained for exactly
# one reason, that the published levels are retained. This conclusion does not
# move with the custodian adjudication of the sentinel convention, because it has
# now been established separately under each of the two answers that adjudication
# can return.
#
# ALTERNATIVE FORMS TESTED AND REJECTED. Recorded here so that the two-threshold
# ramp is documented as SELECTED rather than assumed, which it was not before. On
# the standardised sample, in units of Akaike information against the deployed
# form and all of them worse: a single-threshold step at 9.9, a single-threshold
# ramp at 21.0, a smooth monotone log-linear hazard at 37.7, and a flexible
# logistic at 3.9. The flexible logistic is the closest competitor and it does not
# argue for smoothness: its own optimum is a step at SDI 790 rather than a smooth
# curve, so the flexible form asked for a threshold when it was free to ask for
# anything.
#
# WHAT THE NON-SENTINEL READING DOES TO EVERY ONE OF THOSE FORMS, established
# twice independently on 11 August 2026. Under that reading the fitted lift is
# exactly ZERO at all five of the deployed and historic threshold pairs, and every
# form free to take either sign chooses a DECREASING density response: the ramp
# lift lands at -0.0238 at a likelihood ratio of 76.3 on 1 degree of freedom, and
# the log-linear slope at -2.87 against +2.07 under the sentinel-inclusive
# reading. So under the non-sentinel reading the answer is not a different ramp.
# It is THE SAME RAMP IMPOSED RATHER THAN FITTED, and if the custodians settle the
# convention that way, that is how the density term must be described.
#
# WHY NOT A FITTED GLM. The published per-tree cloglog discriminates well
# (AUC 0.95) but is numerically unstable applied per tree (annual survival 0.80
# at CR 0.5, ~0 at CR 0.7) and collapses real stands, especially plantations.
# Data diagnostics (tune_survival.R) show the survival signal cannot support a
# free per-tree GLM: only 280 deaths; mortality is lowest in small trees
# (0-5 cm: 0.04%/yr) not highest; and the apparent BYI effect is an artifact of
# ONE cluster of high-BYI NATURAL plots (BYI > 408: 3.3%/yr against about
# 0.15%/yr otherwise), a cluster that contains no plantations. See the origin and
# BYI paragraph below for why it cannot contain any. Forcing BYI into a GLM
# yields absurd, unstable rate ratios (about 890x per log unit).
#
# DESIGN. Annual mortality = a low density-independent background that differs
# by origin PLUS a density-dependent self-thinning term that starts at SDI 200
# metric (79 imperial), increases LINEARLY to a maximum lift at SDI 850 metric
# (335 imperial), and plateaus above. BYI is deliberately NOT a direct mortality
# driver; it influences long-term density correctly through GROWTH (higher BYI
# reaches the self-thinning boundary sooner). Re-verified 2026-08-05 on 300-year
# projections, 5 extreme starting states x 2 origins x 3 BYI levels = 30
# scenarios, plus the original harness starting states: no NaN, no collapse,
# basal area bounded, monotone diameter in every scenario except a plantation
# started at 80 cm against the 60 cm plantation size cap (an input-validation
# artifact, not an equation failure). Those runs are unaffected by the removal of
# the constant and were re-executed to confirm it. With koa_ingrowth active the
# projection reaches a genuine steady state, natural 16.3 m2 ha-1 at SDI 367
# metric (145 imperial) and plantation 15.9 m2 ha-1 at SDI 301 metric (119
# imperial), against 15.5 and 18.3 m2 ha-1 under the published equation. Without
# ingrowth no configuration, published or re-tuned, reaches steady state within
# 300 years; the published equation is still drifting at 6 to 13% per 20 years at
# year 300, so the earlier claim that all stands reach steady state was a
# 200-year artifact and does not hold at 300 years. Peak density on the original
# harness starting states is SDI 345 to 593 metric (136 to 234 imperial) in
# absolute terms. The absolute peak is the invariant quantity and is the only one
# quoted here; expressing it as a percentage is only a statement about which
# denominator is in use, and all the available denominators are withdrawn.
#
# Inputs (metric): sdi (stand SDI), baph m2 ha-1 (fallback if sdi missing),
# qmd cm (quadratic mean diameter, used to make the basal area fallback exact),
# planted 0/1.

# ORIGIN AND BYI (data-checked). Origin: yes, but the SIGN is now disputed. The
# original diagnostic chain showed plantations HIGHER (0.66%/yr) than natural
# (0.22%/yr), read as young-stand establishment mortality, which is why
# base_plt > base_nat below. The recovered mortality data reverse it (natural
# 6.41%/yr against planted 2.32%/yr). The defaults retain the published ordering
# because they retain the published levels; see the change note above. The
# difference is 0.3 percentage points and is swamped by the ramp in any stand
# above SDI 200 metric (79 imperial).
#
# BYI: no direct term, and the two BYI statements that used to sit forty lines
# apart in this file are reconciled here so that they cannot be read as
# contradictory. There is ONE BYI range fact and it has two sides. Among
# PLANTATION records the maximum by-year index is 191, so the plantation range is
# BYI <= 191 and there are no plantation records anywhere above it. The earlier
# clause "zero records above 399" referred to plantation records and is strictly
# weaker than the 191 maximum, so it is redundant and has been removed rather
# than carried alongside it. The high-mortality cluster that produces the
# apparent BYI effect in the diagnostics sits at BYI > 408 and is composed
# entirely of NATURAL plots. Those two statements are the same fact seen from
# opposite ends: the cluster lies above 408 and the plantations stop at 191, so
# the cluster contains no plantations BY CONSTRUCTION, and an origin x BYI
# interaction is not identifiable because the two factors are confounded by the
# design of the sample. That is the reason no BYI coefficient appears, not a
# judgement that BYI does not matter. The real dynamics you would expect,
# plantations and higher-BYI sites self-thinning faster and survival being lower
# at higher BYI, EMERGE from growth driving stands into the self-thinning ramp
# sooner (verified: natural self-thinning onset age 14 -> 7 as BYI rises
# 100 -> 550; plantations onset 5 to 8 yr, earlier at every BYI).
#
# NOTE ON PARAMETERISATION, STRENGTHENED AGAIN. The ramp thresholds are stated in
# ABSOLUTE SDI and are not derived from, scaled by, or expressed against any
# maximum. The ramp is a property of stand density, not of a constant chosen to
# normalise it. The events of 5 and 6 August 2026 are the argument for this
# parameterisation and not against it. SDImax was carried at 500, then 1350, then
# 933, and is now absent, all inside a 48 hour period, and because the thresholds
# live in absolute SDI not one projected trajectory changed across any of those
# revisions. Had the thresholds been left on the RD scale, the same revisions
# would have silently relocated the self-thinning onset from SDI 325 to 878 to
# 606 to undefined and would have produced four mutually contradictory sets of
# results with no visible edit to any threshold. Do not hard-code onset or full
# on an RD scale, and do not reintroduce a default SDImax in order to do so.
#
# NOTE ON mort_max = 0.20, THE HARD CAP AMONG THE DEFAULT ARGUMENTS BELOW. The
# value is UNCHANGED. It is INERT for the deployed configuration: base_plt 0.006
# plus maxlift 0.15 reaches 0.156, so the maximum realised annual mortality of this
# equation is 0.156 and the cap can never act on it. It is live for exactly one
# candidate ever compared under it, the smooth monotone log-linear hazard, where it
# binds above SDI 1,150 and silently converts a smooth form into a plateau. It was
# also observed BINDING on an alternative during the sentinel dual, where the
# sign-free lift lands on this boundary at exactly -0.2 against a grid check of
# -0.184. A cap that never acts on the equation of record and quietly reshapes
# anything compared against it is a hazard, not a guardrail. ANY respecification
# compared against this equation MUST check whether the cap binds on the
# alternative before the comparison is read, or part of the comparison is against
# the cap rather than against the candidate. This note is recorded in the header
# rather than beside the argument because the function itself is retained
# byte-for-byte; nothing below this line changed on 12 August 2026.
#
# THE RAMP IS SELECTED JOINTLY WITH THE DIAMETER INCREMENT CALIBRATION, NOT
# INDEPENDENTLY OF IT, and the dependency is concrete. At the withdrawn diameter
# increment correction factor of 1.026 the onset 200 full lift 500 variant fits the
# long-term validation better than this equation on six of seven statistics. At the
# deployed 1.369 this equation of record wins on the two stand-development
# quantities. This equation is therefore retained ON THE ASSUMPTION THAT 1.369 IS
# ADOPTED, which it was on 12 August 2026. An editor who moves either constant must
# know that the other was chosen against it, and must redo the joint comparison
# rather than either half of it.
#
# THE 1.6 AGAINST 1.605 DIVERGENCE IS NOW CLOSED RATHER THAN FLAGGED. The drop-in
# instructions at the foot of this file state that stand SDI is computed as
# tph.plot * (qmd/25)^1.605 and not on 1.6, and give the reason; that text stands
# UNCHANGED and remains the instruction. As of 12 August 2026 the deposited Python
# agrees with it: figshare_v62/koa_params.py SDI_OF_EXPONENT was changed from the
# deposited literal 1.6 to the REINEKE_EXPONENT alias, 1.605, so the density
# variable a caller feeds this ramp is now the same quantity as the one every
# constant in this header was derived against, by construction rather than by
# coincidence, and a future re-estimation moves the two together. The paragraph at
# the foot of this file is therefore a closed reconciliation, not an open flag.
koa.SURV.calibrated <- function(sdi = NA, baph = NA, planted = 0, qmd = NA,
                                base_nat = 0.003, base_plt = 0.006,
                                SDImax = NA,            # REPORTING ONLY. No
                                                        # default value exists.
                                                        # 500, 1350 and 933 are
                                                        # all withdrawn. Supply
                                                        # one only if you intend
                                                        # to report a relative
                                                        # density, and name it.
                                onset_sdi = 200,        # metric (79 imperial);
                                                        # was 325 (= 0.65*500);
                                                        # profile 75-225
                                full_sdi  = 850,        # metric (335 imperial);
                                                        # was 425 (= 0.85*500);
                                                        # profile 800-925
                                onset = NULL,           # diagnostics override,
                                full  = NULL,           # absolute SDI, not RD
                                maxlift = 0.15, mort_max = 0.20,
                                baph_ref = 42,          # m2 ha-1; was 60, then
                                                        # 72, then 49. EXTERNAL
                                                        # anchor: highest koa
                                                        # basal area published,
                                                        # Harrington, Fownes,
                                                        # Meinzer & Scowcroft
                                                        # 1995, Oecologia
                                                        # 102:277-284,
                                                        # doi 10.1007/BF00329794
                                qmd_ref = 20) {         # cm; diameter at which
                                                        # the basal area fallback
                                                        # is EXACT (42 m2 ha-1
                                                        # maps to SDI 934 metric,
                                                        # 369 imperial, at Dq 20)
  # Reineke conversion constant, (pi/4) * 25^1.605 / 1e4, so that
  #   BA = kR * SDI * Dq^0.395   and   SDI = BA / (kR * Dq^0.395).
  # The exponent is 1.605 here, in the drop-in instructions below, and in every
  # derivation in this header. Do not substitute 1.6.
  kR <- (pi/4) * 25^1.605 / 1e4

  # Density position on the ramp, in ABSOLUTE SDI. Relative density plays no
  # part in this calculation and is not required to evaluate it.
  if (!is.na(sdi)) {
    sdi_use <- sdi
  } else {
    # Basal area fallback. Inverted through the Reineke identity at the stand's
    # own quadratic mean diameter when one is supplied, which makes the fallback
    # exact at every diameter, and at qmd_ref = 20 cm otherwise, which is the
    # diameter at which the external 42 m2 ha-1 anchor is exact. This path no
    # longer passes through SDImax, which is what broke the old circularity:
    # baph_ref = 49 was not an independent fallback at all, it was the withdrawn
    # 933 evaluated at Dq 30 cm (49.23 m2 ha-1) and was 17 percent above the
    # highest basal area ever published for koa.
    dq_use  <- if (!is.na(qmd)) pmax(qmd, 0.1) else qmd_ref
    sdi_use <- baph / (kR * dq_use^0.395)
  }

  on_sdi  <- if (is.null(onset)) onset_sdi else onset
  fl_sdi  <- if (is.null(full))  full_sdi  else full

  base <- ifelse(planted == 1, base_plt, base_nat)
  frac <- pmin(pmax((sdi_use - on_sdi) / (fl_sdi - on_sdi), 0), 1)  # 0 at SDI
                                                                   # 200, 1 at
                                                                   # 850+
  mort <- pmin(pmax(base + maxlift * frac, 0), mort_max)   # annual mortality
  surv <- 1 - mort                                         # annual survival

  # Relative density is a REPORTING CONVENIENCE ONLY and has NO DYNAMICAL ROLE.
  # It is not computed unless the caller names a maximum, and it never enters
  # the mortality calculation above. With SDImax = NA nothing is divided by it
  # and the returned value is a plain numeric, identical to what this function
  # returned when it shipped a default constant.
  if (!is.na(SDImax)) attr(surv, "RD") <- sdi_use / SDImax
  surv
}

# ---- Re-estimated levels, NOT the defaults ----------------------------------
# Maximum likelihood on the recovered variant (ii) survival data, DBH >= 2.5 cm,
# with 95% cluster bootstrap intervals over installation (435 of 500 replicates
# retained). Realised annual mortality on the observed record under these values
# is 8.07% natural and 2.37% planted, against observed 6.41% and 2.32%; under
# the retained defaults it is 7.59% and 2.25%. All four of those realised figures
# are identical at SDImax 500, 933, 1087, 1350, 1882 and absent, which is the
# direct numerical demonstration that the constant does not touch mortality. Do
# not enable until the sentinel death-recording convention is resolved and
# koa_ingrowth is active in HiGy.R.
koa.SURV.levels_recovered <- list(
  base_nat_recovered = 0.0384,   # 95% CI 0.0142 to 0.0510  (published 0.003)
  base_plt_recovered = 0.0142,   # 95% CI 0.0000 to 0.0218  (published 0.006)
  maxlift_recovered  = 0.0870    # 95% CI 0.0393 to 0.1436  (published 0.15)
)

# ---- Allocate the stand mortality rate to individual trees -------------------
# Distributes the calibrated STAND annual mortality across trees by relative
# size (suppressed trees die first), CONSTRAINED so the expansion-factor-weighted
# mean per-tree mortality equals the stand rate. This keeps the validated
# stand-level density trajectory while making self-thinning size-realistic
# (verified: realized stand mortality matches target exactly; over 100 yr it
# preserves SDI/TPH but raises natural QMD ~6 cm by removing small trees).
# Unaffected by the removal of SDImax: it takes the stand rate as given and never
# refers to a density maximum.
#
# CORRECTED 18 August 2026 (defect R1). THE CONSTRAINT ASSERTED IN THE PARAGRAPH
# ABOVE WAS NOT ENFORCED, AND THE PARENTHETICAL "verified: realized stand
# mortality matches target exactly" WAS TRUE ONLY OF STANDS WHERE THE PER-TREE
# CAP NEVER BOUND. Read both as superseded; they are kept visible rather than
# deleted because the history is part of the record. The allocator formed
# m_i = clip(m_stand * w_i / wbar, 0, cap) with cap = 0.95 and stopped there.
# Before the clip that construction is exact by algebra: the expansion-factor-
# weighted mean of m_i is m_stand identically, whatever the weights are. After
# the clip it is not. Every tree pushed down onto the cap loses the mortality
# above it and nothing picks that mortality up, so the stand delivers LESS
# mortality than the stand-level equation prescribed, silently and with no
# diagnostic. Measured on the uneven-aged scenario: under the deployed "tree_eq"
# weight the Medium site loses 12 to 15 percent of prescribed mortality
# cumulatively, with a worst year delivering about 0.30 of what was prescribed;
# the as-published "size" weight under delivers by 0.5 to 0.9 percent
# cumulatively and by up to 6 percent in a single year.
#
# THE FIX, R1. Solve for the scalar lambda >= 0 satisfying
#
#   sum_i expf_i * min(lambda * m_stand * w_i / wbar, cap) / sum_i expf_i
#       == m_stand
#
# and allocate at lambda rather than at 1. The left side is continuous, non
# decreasing in lambda, equals 0 at lambda = 0 and tends to cap as lambda grows
# without bound, so a root EXISTS IF AND ONLY IF m_stand < cap. That is the whole
# feasibility condition and it is not an artifact of the solver: the cap is a
# ceiling on every individual tree, so no allocation of any shape can deliver a
# stand rate at or above it. Feasibility holds everywhere it was checked on 18
# August 2026, in all 300 point-estimate uneven-aged site-years, where the largest
# stand rate reached is 0.153 against a cap of 0.95, at a cost of 40 to 48
# bracketing plus bisection iterations. When feasibility does fail the allocator
# puts every tree at the cap and warns, naming the stand rate, rather than
# returning a shortfall that looks like a result.
#
# WHERE THE CAP DOES NOT BIND, NOTHING MOVES. lambda = 1 is then already the exact
# root, koa.SURV.renormalize.to.stand.rate detects that case and returns the
# unrescaled clip, and those stands are BITWISE IDENTICAL to the pre-18 August
# code. Only stands where the cap actually binds move at all.
#
# renormalize = FALSE restores the pre-18 August behaviour exactly, lost mortality
# and all, and reproduces every artifact published before 18 August 2026. It is
# the R spelling of koa_params.ALLOC_RENORMALIZE_AS_PUBLISHED and joins the same
# as-published set as ALLOC_MODE_AS_PUBLISHED, CF_DDBH_AS_PUBLISHED and
# SDI_OF_EXPONENT_AS_PUBLISHED. NOTHING IN THE PRODUCTION PATH MAY SET IT. The
# Python carrier of the identical algebra is
# koa_survival_calibrated_py.renormalize_to_stand_rate, and the two are gated
# against each other on a fixed cap-binding synthetic stand, to 1e-9 per tree, by
# GATE 1j of figshare_v62/verify_reproducibility.R.
#
#   dbh    tree DBH (cm); qmd stand QMD (cm); rDBH = dbh/qmd
#   expf   tree expansion factor (trees ha-1). AK_SURV.csv supplies this
#          directly in EXPF.0, with four values, 14.92, 24.80, 49.56 and 185.91
#          trees ha-1 per stem; do not reconstruct it from row counts.
#   m_stand = 1 - koa.SURV.calibrated(sdi = sdi, planted = planted)
#   beta   concentration of mortality on small trees (default 3)

# CORRECTED 15 August 2026 (resolves DEPOSIT_CHANGELOG.md open item 9). This
# function carried the stale pre-deduplication "model development snapshot"
# vector (18.133, 0.199, -5.718, 7.640, 15.678, -3.396, 3.039, -25.102) since
# it was written earlier the same day. That vector is not Table 6;
# regenerate_table6.R reproduces the true vector below exactly against the
# deduplicated AK_SURV.csv (n=5,969, 79 deaths). See koa_prediction_functions.R's
# correction notice on koa.surv() for the full account.
koa.SURV.tree.mort <- function(dbh, ht, cr, rht, byi) {
  # Fitted Lineage A survivor equation (manuscript Table 6): cloglog fitted on
  # the ALIVE response with +ln(YIP) offset, so annual P(alive) =
  # 1 - exp(-exp(eta)) and annual mortality = exp(-exp(eta)). Coefficients
  # identical to koa_equations.LineageA.SURV; keep the two in step by hand.
  ht  <- pmax(ht, 0.1); dbh <- pmax(dbh, 0.1)
  eta <- 14.102 + 0.130 * ht - 4.516 * log(ht) + 6.684 * rht +
         14.218 * log(pmin(pmax(cr, 0.01), 0.99)) - 2.806 * log(ht / dbh) +
         2.649 * log(pmax(byi, 1) / 100) - 21.188 * (byi / 1000)
  pmin(pmax(exp(-exp(eta)), 1e-9), 1)             # annual mortality probability
}

# THE SINGLE R CARRIER OF THE R1 ALGEBRA. koa.SURV.allocate calls it and does not
# inline a second copy; a second copy of this solve is a defect, not a
# convenience. Transcribed line for line from
# koa_survival_calibrated_py.renormalize_to_stand_rate so the two return the same
# doubles: the same two early returns, the same geometric bracketing from
# lambda = 1, the same bisection test taken BEFORE the midpoint is formed, and the
# same return of the UPPER bracket hi rather than the midpoint. Changing any of
# those four in one carrier and not the other is exactly the drift GATE 1j exists
# to catch.
#
#   m_i    uncapped allocation m_stand * w_i / wbar, weighted mean m_stand by
#          construction and non-negative for any non-negative stand rate
#   expf   tree expansion factor (trees ha-1), as in koa.SURV.allocate
#   cap    per-tree annual mortality ceiling; koa_params.ALLOC_MORT_CAP carries
#          the same 0.95 on the Python side
#   rtol   relative tolerance on the lambda bracket, 1e-12
koa.SURV.renormalize.to.stand.rate <- function(m_i, expf, m_stand, cap = 0.95,
                                               renormalize = TRUE,
                                               rtol = 1e-12, max_iter = 200L) {
  m      <- as.numeric(m_i)
  capped <- pmin(pmax(m, 0), cap)
  if (!isTRUE(renormalize)) return(capped)   # as-published path, clip and all
  e    <- as.numeric(expf)
  esum <- sum(e)
  ms   <- as.numeric(m_stand)[1]
  if (esum <= 0 || length(m) == 0L || ms <= 0) return(capped)
  # ORDER CORRECTED 18 August 2026 (fifth pass). These two guards were
  # transcribed in the opposite order from the Python carrier, which tests
  # infeasibility FIRST. The Python author hit the same bug, caught it, and
  # reordered; the R transcription preserved the pre-fix ordering, so the two
  # carriers disagreed on one branch while GATE 1j reported them in agreement.
  # The discriminating case is ms >= cap with every m_i at or below cap: the
  # old order fell through the no-bind return and delivered the uncapped
  # allocation SILENTLY (0.883 against a prescribed 0.99 on the test vector),
  # which is the original under-delivery defect wearing a different mask, while
  # Python warned and returned every tree at the cap. Latent rather than active:
  # m_i = m_stand * w_i / wbar forces max(m_i) >= m_stand, verified at a minimum
  # margin of 1.67e-07 over 200,000 random stands, so the projector's own
  # allocation cannot reach it. A direct caller passing an arbitrary m_i can.
  # GATE 1j does NOT catch this, because its infeasible test stand carries an
  # m_i above the cap, which is the case where both orderings agree.
  if (ms >= cap) {
    warning(sprintf(paste0("koa.SURV.renormalize.to.stand.rate: stand mortality ",
                           "rate %.6g is at or above the per-tree cap %.6g, so no ",
                           "allocation can deliver it. Every tree is set to the ",
                           "cap and the stand under delivers by %.6g."),
                    ms, cap, ms - cap))
    return(rep(cap, length(m)))
  }
  if (max(m) <= cap) return(capped)          # lambda = 1 exactly, nothing to do
  wmean <- function(lam) sum(e * pmin(lam * m, cap)) / esum
  lo <- 1; hi <- 1                  # wmean(1) <= m_stand here, the cap binds
  bracketed <- FALSE
  for (i in seq_len(max_iter)) {
    if (wmean(hi) >= ms) { bracketed <- TRUE; break }
    lo <- hi; hi <- hi * 2
  }
  if (!bracketed) {
    warning(sprintf(paste0("koa.SURV.renormalize.to.stand.rate: failed to bracket ",
                           "lambda for stand rate %.6g under cap %.6g; returning ",
                           "the capped allocation unrescaled."), ms, cap))
    return(capped)
  }
  for (i in seq_len(max_iter)) {
    if (hi - lo <= rtol * hi) break
    mid <- 0.5 * (lo + hi)
    if (wmean(mid) < ms) lo <- mid else hi <- mid
  }
  pmin(pmax(hi * m, 0), cap)
}

koa.SURV.allocate <- function(dbh, expf, qmd, m_stand, beta = 3,
                              ht = NULL, cr = NULL, rht = NULL, byi = NULL,
                              mode = c("tree_eq", "size"), renormalize = TRUE) {
  # ADOPTED 2026-08-15: the allocation weight of record is the fitted tree-level
  # survivor equation ("tree_eq"), entering as ordering only; the stand rate is
  # unchanged. "size" is the as-published exp(-beta*(rDBH - 1)) control weight.
  # BASIS, RESTATED 18 August 2026. The two lines that stood here cited the 15
  # August MORNING numbers, |BAPH error| -0.811 m2 ha-1 (p 0.0004) and
  # |QMD error| -0.576 cm (p 0.112, 94.4 percent of resamples). Those were
  # superseded the same day by the survival coefficient vector fix and are kept
  # visible here as SUPERSEDED rather than deleted. The current 23-plot paired
  # bootstrap against the size weight, reproduced twice independently on 18
  # August 2026 at 20,000 resamples, gives absolute QMD error -1.25766 cm
  # (p 0.0000, 100.000 percent of resamples) and absolute BAPH error
  # -0.90026 m2 ha-1 (p 0.0009, 99.955 percent). The direction and the decision
  # are unchanged; the magnitudes are larger, and the QMD result, which read as
  # not significant at p 0.112, is now the stronger of the two rather than the
  # weaker. Cohort survival unchanged.
  #
  # renormalize = TRUE (deployed 2026-08-18) enforces the weighted-mean
  # constraint AFTER the per-tree cap, through the R1 solve documented above.
  # renormalize = FALSE reproduces every artifact published before 18 August
  # 2026 exactly, cap shortfall and all.
  mode <- match.arg(mode)
  if (mode == "tree_eq") {
    if (is.null(ht) || is.null(cr) || is.null(rht) || is.null(byi))
      stop("koa.SURV.allocate(mode = 'tree_eq') needs ht, cr, rht and byi; ",
           "pass mode = 'size' for the as-published size weight")
    w <- koa.SURV.tree.mort(dbh, ht, cr, rht, byi)
  } else {
    rDBH <- dbh / pmax(qmd, 0.1)
    w    <- exp(-beta * (rDBH - 1))               # small trees (rDBH<1) -> w>1
  }
  wbar <- sum(w * expf) / sum(expf)               # expf-weighted mean weight
  koa.SURV.renormalize.to.stand.rate(m_stand * w / wbar, expf, m_stand,
                                     cap = 0.95, renormalize = renormalize)
}

# Drop-in for HiGy.R calc_mortality(): compute stand SDI from the plot summary
#   (sdi = tph.plot * (qmd/25)^1.605), then either
#   (a) uniform stand rate:
#       surv = koa.SURV.calibrated(sdi = sdi, planted = stand$planted)
#       dexpf = expf * (1 - surv) * mort.mult
#   (b) size-allocated (recommended for individual-tree realism):
#       m_stand = 1 - koa.SURV.calibrated(sdi = sdi, planted = stand$planted)
#       p_tree  = koa.SURV.allocate(dbh, expf, qmd, m_stand,
#                                   ht = ht, cr = cr, rht = ht / max(ht),
#                                   byi = byi,          # tree_eq, the record
#                                   renormalize = TRUE) # R1, 18 August 2026
#       dexpf   = expf * p_tree * mort.mult
#       (mode = 'size' reproduces every artifact published before 2026-08-15;
#        renormalize = FALSE reproduces every artifact published before
#        2026-08-18. Neither belongs in a production paste.)
#
# PASTE koa.SURV.renormalize.to.stand.rate ALONG WITH koa.SURV.allocate, AND DO
# NOT PASTE THE PRE-18 AUGUST ALLOCATOR. renormalize = TRUE is the default here
# precisely so that a paste that forgets the argument still gets the enforced
# constraint, but the allocator now calls a second function and a paste that
# takes koa.SURV.allocate on its own will fail to find it. The constraint the
# comment on koa.SURV.allocate states, that the expansion-factor-weighted mean
# per-tree mortality equals the stand rate, is delivered by that call and by
# nothing else: without it, every tree the 0.95 cap pushes down loses the
# mortality above the cap and the stand quietly under thins. On the uneven-aged
# scenario that shortfall reached 12 to 15 percent of prescribed mortality
# cumulatively under the deployed tree_eq weight. A variant that carries the
# allocator without the renormalizer is not the model of record.
#
# THE EXPONENT IN THAT DROP-IN IS 1.605, NOT 1.6, AND THAT MATTERS. Earlier
# versions of this file used 1.605 in the header and in the baph_ref derivation
# but told the implementer to compute stand SDI as tph.plot * (qmd/25)^1.6. The
# drop-in line is the one somebody actually pastes, so the deployed model would
# have carried a different density variable from the one every constant in the
# file was derived against. The two agree exactly at Dq 25 cm and diverge away
# from it by the factor (Dq/25)^0.005: about 0.46 percent low at Dq 10 cm and
# about 0.44 percent high at Dq 60 cm. That is small in percentage terms and it
# is not the point. The point is that the ramp thresholds, the Reineke identity
# used for the basal area fallback, and the diameter-conditional bound are all
# stated on the 1.605 scale, so a stand SDI computed on the 1.6 scale is not the
# same quantity and the ramp would sit at a slightly wrong place at every
# diameter except 25 cm. At the ramp onset of SDI 200 that is roughly one full
# SDI unit of silent offset, in a direction that depends on stand diameter and
# therefore drifts as the stand grows.
#
# If any calling code hard-codes SDImax = 500, or the withdrawn 1350, or the
# withdrawn 933, REMOVE IT rather than replacing it with another number, and make
# sure koa_ingrowth.R is on the same footing; both files now run without a
# density maximum. Neither file needs one, and a disagreement between them is no
# longer possible because neither carries a default. If a relative density must
# be reported, name the constant used, state that it is a reporting choice, and
# prefer the diameter-conditional bound from the 42 m2 ha-1 anchor: 934 metric
# (369 imperial) at Dq 20 cm, 796 metric (314 imperial) at Dq 30 cm, 651 metric
# (257 imperial) at Dq 50 cm.
# Refine the constants as Kahikinui, KMR, and Kualoa remeasurements accrue, and
# treat the density maximum as an open question to be settled by adjudicating
# the impossible plot-year density and diameter records against the source
# inventories, not by choosing a larger number.
