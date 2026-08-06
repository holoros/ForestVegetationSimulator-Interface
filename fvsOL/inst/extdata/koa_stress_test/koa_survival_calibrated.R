# koa_survival_calibrated.R   (tuned 2026-06-05; ramp re-tuned 2026-08-05;
#                              SDImax corrected to 933 metric on 2026-08-06
#                              after the 1350 value was withdrawn)
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
# 2026-08-06 CHANGE NOTE: SDImax IS 933 METRIC (368 IMPERIAL), AN UPPER BOUND.
# THE 1350 VALUE PREVIOUSLY CARRIED IN THIS FILE IS WITHDRAWN.
#
# THE WHOLE EPISODE, PLAINLY. The published constant was 500 metric (197
# imperial). That number was never a pooled-sample quantity: it was fitted on
# FIA plot-years alone and then carried into an equation estimated on all four
# sources, so it was wrong in provenance before it was wrong in value. A first
# correction, dated 2026-08-05, replaced it with 1350 metric (533 imperial) on
# the strength of a 0.99 quantile regression of the Reineke intercept with the
# slope fixed at -1.605. That correction has been WITHDRAWN. The estimator used,
# rq(a_i ~ 1, tau = 0.99) on an intercept-only model, does not fit a boundary at
# all; on 269 observations it returns an order statistic, so the reported value
# 1351.50016168609 is one plot-year copied out verbatim, PSP plot 102 subplot 2
# measured in 2021, and that plot-year rests on FIVE stems spread over an
# implied area of about 56 m2. The four plot-years that define the frontier
# carry 5, 12, 14 and 30 stems. Their implied basal areas run to 129 m2 ha-1,
# three times the highest basal area ever published for koa. Checked against
# Baker and Scowcroft's own koa growing space index of 15, the most compact
# crown allometry measured for the species, those four plot-years exceed the
# non-overlapping-crown packing limit by factors of 3.20, 1.89, 1.82 and 1.50,
# and the rank correlation between crown-packing overshoot and Reineke SDI
# across the whole cloud is +0.990. In other words the SDI ranking of this
# dataset is the overpacking ranking. Plot-years carrying forty stems or more
# never exceed 924 metric (365 imperial). Compounding this, freeing the Reineke
# slope on the same data gives an upper-envelope slope between -0.47 and -1.17
# depending on the estimator, and -1.605 lies outside every interval; because
# the extreme plot-years all sit at quadratic mean diameters of 22 to 38 cm
# against a cloud median of 14.8 cm, forcing the steeper theoretical slope
# inflates exactly those plot-years that then go on to set the quantile, so the
# bias runs UPWARD and adds to the small-plot artifact rather than offsetting
# it. Full audit at /users/PUOM0008/crsfaaron/koa_sdimax_audit/.
#
# WHAT IS DEPLOYED AND WHY. The value in this file is 933 metric (368
# imperial), with a 95 percent cluster bootstrap percentile interval of 844 to
# 946 metric (333 to 373 imperial), B = 2000, installations resampled, seed
# 20260805. It is the 0.99 quantile of the SCREENED cloud: plot-years whose
# tree list reproduces the reported quadratic mean diameter within 10 percent,
# which carry at least 20 stems, and which sit at or below the koa closed-crown
# packing limit. That screen leaves 59 plot-years across 13 installations, and
# their maximum implied basal area is 39.2 m2 ha-1, just inside the published
# koa maximum of 42 m2 ha-1, which is the check that the screen is doing what it
# was meant to do. This constant must be read as an UPPER BOUND and not as a
# best estimate, because the interval reflects sampling within the screened set
# and not the screening decision itself. The koa-specific literature
# independently supports 500 to 650 metric (197 to 256 imperial): Baker and
# Scowcroft's 2005 crown-based A-line converts to roughly 440 to 530 metric
# (175 to 210 imperial), and Scowcroft et al.'s 2008 stand, which self-thinned
# from about 20000 seedlings ha-1 to 1000 trees ha-1 over 23 years and is the
# best empirical anchor on a genuine koa self-thinning trajectory, sits at 595
# metric (235 imperial). The screened data and the literature do not agree, and
# the residual gap is itself the finding: it says the expansion-factor noise has
# been reduced by screening but not removed. Anything above roughly 950 metric
# (375 imperial) is not supported by any screened plot-year in this dataset.
# A defensible sensitivity range to carry through downstream work is 600 to 850
# metric (237 to 335 imperial).
#
# WHY THE CONSTANT IS STILL PROVISIONAL. Plot area and expansion factor are
# ABSENT from the source files. Implied area has to be back-computed as stems
# divided by trees per hectare, and doing so exposes 112 distinct implied
# expansion factors across 269 plot-years, with a median implied area of 193 m2
# and a tenth percentile of 29 m2. Among the 29 plots remeasured three or more
# times, only FOUR hold their implied area constant to within 5 percent across
# remeasurements, with a median within-plot coefficient of variation of 0.198.
# That is not the signature of a clean fixed-area tally, so the per-hectare
# expansion cannot be trusted at the individual plot-year level and no estimator
# run on this cloud can be trusted either. This constant should be revisited
# against the source inventories once plot area, expansion factor and the
# minimum measured diameter are obtained from the PSP custodians. [UNKNOWN:
# whether the PSP network is variable-radius, whether subplots were subsampled,
# and whether the tree lists were truncated by a minimum diameter that moved
# between visits. None of the three can be settled from these files.]
#
# HOW THE CONSTANT SHOWS UP IN THE DATA. Under SDImax = 500, 41.4 percent of
# deduplicated tree records and 27.9 percent of plot-years sit above relative
# density 1.0, with a maximum RD of 4.39, which is impossible by construction.
# Under 933 those fall to 5.29 percent and 6.32 percent with a maximum RD of
# 2.35. Under the withdrawn 1350 they were 0.95 percent and 0.74 percent with a
# maximum of 1.63, which looks better only because 1350 is large enough to
# swallow physically impossible plot-years. The screened cloud is the honest
# test and it passes cleanly: among the 59 screened plot-years NONE exceeds RD
# 1.0 at SDImax 933 and the maximum is 0.970, against 35.6 percent exceeding 1.0
# at SDImax 500. Recomputed on Cardinal 2026-08-06 from
# koa_surv_respec/data/surv_recovered_ii.csv (4518 records after the standard
# deduplication) and koa_surv_respec/out/plot_year_reineke.csv (269 plot-years),
# the same files that produced the published figures.
#
# THE INTERNAL CONSISTENCY CHECK, REDONE. The BA fallback in this function
# treats RD as BA divided by baph_ref. Setting that path equal to the Reineke
# path, baph_ref = SDImax * (25/QMD)^1.605 * (pi/4) * (QMD/100)^2, the
# Reineke-consistent basal area at SDI 933 and QMD 30 cm is 49.2 m2 ha-1, so
# baph_ref moves from 60 to 49. Running the identity backwards, a baph_ref of 49
# implies an SDImax of 1090 at QMD 20 cm falling to 759 at QMD 50 cm, bracketing
# the deployed 933 as it must. The published pairing of 500 with 60 m2 ha-1
# implied 1335 down to 930 over the same diameter range, which is where the
# factor of roughly 2.3 disagreement between the two density scales in the
# published equation came from. At SDImax 933 with baph_ref 49 the two paths
# agree to within 0.5 percent at QMD 30 cm. Note for the record that the
# withdrawn file rounded the Reineke basal area at SDI 1350 up to 72 when the
# exact value is 71.2; here 49.2 is rounded to 49, a difference of 0.4 percent.
#
# THE RAMP IS NOT AFFECTED, AND THAT IS THE POINT. The self-thinning ramp is
# parameterised in ABSOLUTE SDI, onset at 200 and full lift at 850, and SDImax
# cancels identically out of frac = (RD - onset)/(full - onset) once RD is
# written as SDI/SDImax. This was verified numerically on Cardinal on
# 2026-08-06 rather than asserted. The survival function evaluated on a grid of
# 25001 points over SDI 0 to 2500 for both origins agrees between SDImax 500,
# 933 and 1350 to 1.1e-16. Six 300-year project_cohort runs, two origins by
# three BYI levels, agree across the three SDImax values to 2.3e-13 in trees
# ha-1, 7.1e-15 in QMD, 1.4e-14 in basal area and 2.3e-13 in SDI at every one of
# the 301 annual steps. With ingrowth active, project_psp reaches the same
# 300-year steady state at 933 as at 1350, natural 16.3 m2 ha-1 at SDI 367 and
# plantation 15.9 m2 ha-1 at SDI 301, agreeing to 1.1e-13. Realised annual
# mortality on the observed record is identical to fifteen decimal places at
# SDImax 500, 933, 1087, 1350 and 1882. THIS IS A CONSTANTS AND DOCUMENTATION
# CORRECTION, NOT A RE-FIT. The ramp was not re-tuned and must not be.
#
# CORRECTION OF A FALSE CLAIM MADE ELSEWHERE. It was previously reported that
# correcting SDImax improved the realised Reineke self-thinning slope from a
# range of -1.06 to -1.37 toward -1.11 to -1.61, and that this was independent
# corroboration of the new constant. THAT CLAIM IS FALSE AND MUST NOT BE
# REPEATED. Because SDImax cancels out of the ramp, the realised slope is
# invariant to it: holding the ramp fixed in absolute SDI and moving SDImax from
# 500 to 1350 leaves the slope range bit-identical at all six BYI levels, while
# holding SDImax at 500 and applying only the re-tuned ramp reproduces the
# "corrected" range exactly, including the -1.61 that was highlighted against
# the theoretical -1.605. The entire improvement came from the ramp re-tune and
# none of it from SDImax. Citing it as evidence for a particular SDImax is
# circular, since the ramp was re-tuned because SDImax had been changed. The
# one channel through which SDImax can move a trajectory, holding the
# thresholds at RD 0.65 and 0.85 so that the absolute onset silently relocates,
# makes the slope dramatically WORSE, -0.03 to -0.65. No claim of this kind
# appears anywhere in this file or in koa_ingrowth.R, and none may be added.
# ============================================================================
#
# WHY THE RAMP WAS RE-TUNED RATHER THAN RESCALED (unchanged from 2026-08-05).
# The thresholds 0.65 and 0.85 were themselves fitted quantities, tuned against
# observed mortality UNDER SDImax = 500, which placed the self-thinning onset
# near SDI 325 and full lift near SDI 425. Two options were evaluated and the
# second was adopted:
#   (a) preserve the absolute thresholds 325 and 425 and re-express them as
#       RD 0.3483 and 0.4555 at SDImax = 933. Dynamically identical to the
#       published equation; only the reporting denominator changes.
#   (b) re-tune the ramp from the data at the corrected scale. ADOPTED.
# Both were tested by profile likelihood on the recovered variant (ii) survival
# data restricted to DBH >= 2.5 cm, the tree list FVS actually carries (n =
# 4141 records, 927 events, 15432 tree-years, 48 installation clusters), with
# base_nat, base_plt and maxlift maximised out at every threshold pair so that
# threshold location is not confounded with mortality level. Option (a) is
# rejected, likelihood ratio 67.3 on 2 df, P = 2.4e-15. That test is itself
# SDImax-free, because both options are stated in absolute SDI, so the result
# stands unchanged at 933 exactly as it stood at 1350. Simply keeping 0.65 and
# 0.85 and swapping the denominator is rejected far harder; at SDImax 1350 the
# profiled likelihood ratio was 137.2, P = 1.6e-30, and maxlift collapsed to
# 1.7e-11, that is, the self-thinning term switched off entirely and the model
# degenerated to a constant hazard. The same failure mode recurs at 933, where
# the naive RD rule would silently relocate onset from SDI 200 to SDI 606 and
# full lift from 850 to 793; evaluated at the published levels it is rejected
# against the deployed ramp by a likelihood ratio of 1916.3 on 2 df. That is the
# failure mode a naive rescale would have shipped at either constant.
#
# THE RE-TUNED THRESHOLDS, in absolute SDI so that they do not depend on the
# disputed constant: onset at SDI 200 metric, 79 imperial (95 percent profile
# region 75 to 225) and full lift at SDI 850 metric, 335 imperial (95 percent
# profile region 800 to 925). At SDImax = 933 that is onset RD 0.2144 (0.0804 to
# 0.2412) and full RD 0.9110 (0.8574 to 0.9914). The full-lift threshold is the
# well identified one and is stable across samples; the onset is not, and moves
# to SDI 750 if sub-2.5 cm seedling records are left in. [UNKNOWN: the onset
# location is sample dependent and should be revisited when the sub-2.5 cm
# records are adjudicated.]
#
# IS FULL LIFT AT RD 0.911 COHERENT. Marginally, and it should be watched. On
# the substance it is the right shape: a self-thinning term that reaches its
# maximum only as the stand approaches its own density limit is what the theory
# asks for, and it is a clear improvement on the withdrawn 1350, where full lift
# sat at RD 0.630 and implied that koa attains maximum density-dependent
# mortality at under two thirds of carrying capacity, and on the published 500,
# where full lift computed to RD 1.70 and was therefore unreachable by
# construction. The caution is that 0.911 leaves very little headroom. At the
# lower end of the SDImax interval, 844 metric, full RD would be 1.007, that is,
# above one, and the ramp would saturate only at densities the constant declares
# impossible. Because the ramp is parameterised in absolute SDI this is a
# reporting problem and not a dynamical one, and no projected trajectory changes,
# but it does mean the RD scale should not be used for interpretation near the
# top of its range without quoting the interval alongside it.
#
# WHAT WAS DELIBERATELY NOT CHANGED. base_nat, base_plt and maxlift are LEVELS,
# and the level of koa mortality is currently controlled by an unresolved
# death-recording convention (the sentinel rows) rather than by SDImax. Fitting
# them on the recovered data gives base_nat 0.0384 (0.0142 to 0.0510), base_plt
# 0.0142 (0.0000 to 0.0218) and maxlift 0.0870 (0.0393 to 0.1436), all 95%
# cluster bootstrap over installation. Those values also REVERSE the published
# origin ordering: observed annual mortality is 6.41% natural against 2.32%
# planted on this sample, and the independent cloglog respecification finds a
# Planted coefficient of -1.151 (wild cluster bootstrap P < 0.001), so planted
# stock is protective, not the reverse. They are recorded here as
# base_nat_recovered, base_plt_recovered and maxlift_recovered but are NOT the
# defaults, because HiGy.R as it stands carries no ingrowth, and with no
# recruitment a 3.8% per year background draws an operational stand down to 2 to
# 3 m2 ha-1 of basal area by year 200. With koa_ingrowth active they are safe
# (steady state 13.5 to 16.3 m2 ha-1 at 300 years). Enable them only once the
# sentinel convention is settled AND ingrowth is wired into HiGy.R. None of
# these levels moves with SDImax; all were verified invariant on 2026-08-06.
#
# WHY NOT A FITTED GLM. The published per-tree cloglog discriminates well
# (AUC 0.95) but is numerically unstable applied per tree (annual survival 0.80
# at CR 0.5, ~0 at CR 0.7) and collapses real stands, especially plantations.
# Data diagnostics (tune_survival.R) show the survival signal cannot support a
# free per-tree GLM: only 280 deaths; mortality is lowest in small trees
# (0-5 cm: 0.04%/yr) not highest; and the apparent BYI effect is an artifact of
# ONE cluster of high-BYI natural plots (BYI>408: 3.3%/yr vs ~0.15% otherwise),
# a cluster that contains no plantations, so a BYI mortality effect cannot even
# be estimated for plantations. Forcing BYI into a GLM yields absurd, unstable
# rate ratios (~890x per log unit).
#
# DESIGN. Annual mortality = a low density-independent background that differs
# by origin PLUS a density-dependent self-thinning term that starts at SDI 200
# (RD 0.214 at SDImax 933), increases LINEARLY to a maximum lift at SDI 850
# (RD 0.911), and plateaus above. BYI is deliberately NOT a direct mortality
# driver; it influences long-term density correctly through GROWTH (higher BYI
# reaches the self-thinning boundary sooner). Re-verified 2026-08-05 on
# 300-year projections, 5 extreme starting states x 2 origins x 3 BYI levels =
# 30 scenarios, plus the original harness starting states: no NaN, no collapse,
# basal area bounded, monotone diameter in every scenario except a plantation
# started at 80 cm against the 60 cm plantation size cap (an input-validation
# artifact, not an equation failure). Those runs are unaffected by the 2026-08-06
# change of constant and were re-executed to confirm it. With koa_ingrowth
# active the projection reaches a genuine steady state, natural 16.3 m2 ha-1 at
# SDI 367 (39.3% of SDImax 933) and plantation 15.9 m2 ha-1 at SDI 301 (32.3%),
# against 15.5 and 18.3 m2 ha-1 under the published equation. Without ingrowth
# no configuration, published or re-tuned, reaches steady state within 300
# years; the published equation is still drifting at 6 to 13% per 20 years at
# year 300, so the earlier claim that all stands reach steady state was a
# 200-year artifact and does not hold at 300 years. Peak density on the original
# harness starting states is SDI 345 to 593 in absolute terms, which is 37 to
# 64% of SDImax 933, was reported as 26 to 44% of the withdrawn 1350, and would
# be 69 to 119% of the published 500. The absolute peak is the invariant
# quantity; the percentage is only a statement about which denominator is in use,
# and should be quoted that way.
#
# Inputs (metric): sdi (stand SDI), baph m2 ha-1 (fallback if sdi missing),
# planted 0/1.

# ORIGIN AND BYI (data-checked). Origin: yes, but the SIGN is now disputed. The
# original diagnostic chain showed plantations HIGHER (0.66%/yr) than natural
# (0.22%/yr), read as young-stand establishment mortality, which is why
# base_plt > base_nat below. The recovered mortality data reverse it (natural
# 6.41%/yr against planted 2.32%/yr). The defaults retain the published ordering
# because they retain the published levels; see the change note above. The
# difference is 0.3 percentage points and is swamped by the ramp in any stand
# above SDI 200. BYI: no direct term. Plantations occur only at BYI <= 191
# (max 191; zero records above 399), so an origin x BYI interaction is not
# identifiable (confounded). The real dynamics you would expect, plantations
# and higher-BYI sites self-thinning faster and survival being lower at higher
# BYI, EMERGE from growth driving stands into the self-thinning ramp sooner
# (verified: natural self-thinning onset age 14 -> 7 as BYI rises 100 -> 550;
# plantations onset 5-8 yr, earlier at every BYI). No BYI coefficient.
#
# NOTE ON PARAMETERISATION, STRENGTHENED. onset and full are DERIVED from
# absolute SDI thresholds and SDImax rather than hard-coded on the RD scale.
# The ramp is a property of stand density, not of the constant chosen to
# normalise it, so changing SDImax must move the RD thresholds and leave the
# absolute ones alone. The events of 5 and 6 August 2026 are the argument for
# this parameterisation and not against it. SDImax has now been carried at 500,
# then 1350, then 933 inside a single 24 hour period, and because the thresholds
# live in absolute SDI, not one projected trajectory changed across any of those
# revisions. Had the thresholds been left on the RD scale, the same three
# revisions would have silently relocated the self-thinning onset from SDI 325
# to 878 to 606 and would have produced three mutually contradictory sets of
# results with no visible edit to any threshold. Do not hard-code onset or full
# on the RD scale, and do not "simplify" the derivation away. Passing onset or
# full directly still works and overrides the derivation, but that override
# exists for diagnostics and should not be used in production.
koa.SURV.calibrated <- function(sdi = NA, baph = NA, planted = 0,
                                base_nat = 0.003, base_plt = 0.006,
                                SDImax = 933,           # metric (368 imperial);
                                                        # screened-data UPPER BOUND,
                                                        # 95% CI 844-946 metric
                                                        # (333-373 imperial).
                                                        # Was 500, then 1350
                                                        # (WITHDRAWN 2026-08-06).
                                onset_sdi = 200,        # metric (79 imperial);
                                                        # was 325 (= 0.65*500);
                                                        # profile 75-225
                                full_sdi  = 850,        # metric (335 imperial);
                                                        # was 425 (= 0.85*500);
                                                        # profile 800-925
                                onset = onset_sdi/SDImax,   # 0.2144 at SDImax 933
                                full  = full_sdi/SDImax,    # 0.9110 at SDImax 933
                                maxlift = 0.15, mort_max = 0.20,
                                baph_ref = 49) {        # was 60, then 72;
                                                        # Reineke-consistent BA at
                                                        # SDI 933, QMD 30 cm = 49.2
  RD   <- if (!is.na(sdi)) sdi / SDImax else baph / baph_ref    # relative density
  base <- ifelse(planted == 1, base_plt, base_nat)
  frac <- pmin(pmax((RD - onset) / (full - onset), 0), 1)  # 0 at SDI 200, 1 at 850+
  mort <- pmin(pmax(base + maxlift * frac, 0), mort_max)   # annual mortality
  1 - mort                                                 # annual survival
}

# ---- Re-estimated levels, NOT the defaults ----------------------------------
# Maximum likelihood on the recovered variant (ii) survival data, DBH >= 2.5 cm,
# with 95% cluster bootstrap intervals over installation (435 of 500 replicates
# retained). Realised annual mortality on the observed record under these values
# is 8.07% natural and 2.37% planted, against observed 6.41% and 2.32%; under
# the retained defaults it is 7.59% and 2.25%. All four of those realised figures
# are identical at SDImax 500, 933, 1087, 1350 and 1882, which is the direct
# numerical demonstration that the constant does not touch mortality. Do not
# enable until the sentinel death-recording convention is resolved and
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
# Unaffected by the SDImax correction: it takes the stand rate as given.
#
#   dbh    tree DBH (cm); qmd stand QMD (cm); rDBH = dbh/qmd
#   expf   tree expansion factor (trees ha-1)
#   m_stand = 1 - koa.SURV.calibrated(sdi = sdi, planted = planted)
#   beta   concentration of mortality on small trees (default 3)

koa.SURV.allocate <- function(dbh, expf, qmd, m_stand, beta = 3) {
  rDBH <- dbh / pmax(qmd, 0.1)
  w    <- exp(-beta * (rDBH - 1))                 # small trees (rDBH<1) -> w>1
  wbar <- sum(w * expf) / sum(expf)               # expf-weighted mean weight
  pmin(pmax(m_stand * w / wbar, 0), 0.95)         # per-tree annual mortality
}

# Drop-in for HiGy.R calc_mortality(): compute stand SDI from the plot summary
#   (sdi = tph.plot * (qmd/25)^1.6), then either
#   (a) uniform stand rate:
#       surv = koa.SURV.calibrated(sdi = sdi, planted = stand$planted)
#       dexpf = expf * (1 - surv) * mort.mult
#   (b) size-allocated (recommended for individual-tree realism):
#       m_stand = 1 - koa.SURV.calibrated(sdi = sdi, planted = stand$planted)
#       p_tree  = koa.SURV.allocate(dbh, expf, qmd, m_stand)
#       dexpf   = expf * p_tree * mort.mult
# If any calling code hard-codes SDImax = 500, or the withdrawn 1350, change it
# to 933 in the SAME commit, and make sure koa_ingrowth.R is on the same
# constant; the two files must not disagree about the density scale. Changing
# SDImax does not change any projection, but a disagreement between the two
# files would, because it would put the mortality ramp and the recruitment
# response on two different density scales.
# Refine the constants as Kahikinui, KMR, and Kualoa remeasurements accrue, and
# treat SDImax as open until plot area and expansion factor arrive from the PSP
# custodians.
