# koa_ingrowth.R   (2026-06-05; SDImax 1350 withdrawn 2026-08-06; SDImax 933
#                   withdrawn 2026-08-06 by red team seed 20260806; NO SCALAR
#                   SDImax IS DEPLOYED IN THIS VERSION. The equation is now
#                   stated directly in absolute SDI, which is what it was
#                   estimated on, and predictions are unchanged.)
# Koa-only annualized ingrowth for FVS-HI, to add the missing recruitment
# component (HiGy.R currently has no ingrowth). Follows the two-stage / density
# logic of Li, Weiskittel & Kershaw (2011, Can. J. For. Res. 41:2077-2089) but
# reduced to a single annualized expectation keyed on stand density, per Aaron's
# preference.
#
# Units in this file are metric throughout and are written in plain ASCII:
# m2 ha-1 for basal area, trees ha-1 yr-1 for recruitment, cm for diameter.
# Stand density index is metric first with imperial in parentheses, divisor
# 2.535 from the code's own index diameter of 25 cm.
#
# ============================================================================
# ==  NO DEFENSIBLE SCALAR SDImax EXISTS FOR THIS DATA. NONE IS DEPLOYED.   ==
# ==  BOTH 1350 METRIC (533 IMPERIAL) AND 933 METRIC (368 IMPERIAL) ARE     ==
# ==  WITHDRAWN. SDImax IS NOW A REPORTING-ONLY ARGUMENT DEFAULTING TO NA.  ==
# ==  THE FITTED DENSITY RESPONSE IS A SLOPE PER UNIT OF ABSOLUTE SDI AND   ==
# ==  NEVER NEEDED A MAXIMUM AT ALL.                                        ==
# ============================================================================
#
# WHY NO SCALAR IS DEPLOYED. The 933 value carried in the previous version of
# this file was withdrawn by an independent red team pass on 2026-08-06, seed
# 20260806, artifacts at /users/PUOM0008/crsfaaron/koa_redteam/. The reasoning is
# set out at length in koa_survival_calibrated.R and is summarised here so that
# this file can be read on its own. The estimator was
# quantile(sdi_reineke, 0.99, type = 7) on n = 59 screened plot-years; the type 7
# index is 58.42, so the value is a fixed blend of order statistics 58 and 59
# alone, the other 57 observations each move it by 0.023 percent, and leave one
# out spans 882 to 933 metric (348 to 368 imperial). The published 95 percent
# upper limit of 946 metric (373 imperial) is the sample maximum bit for bit,
# with 26.5 percent of bootstrap draws sitting exactly on it. Decisively, none of
# the 59 screened plot-years reaches the Reineke index diameter of 25 cm: their
# quadratic mean diameters run 1.3 to 22.4 cm with a median of 11.3 cm, so every
# value on this scale is an extrapolation along a slope of -1.605 that has never
# been estimated for Acacia koa A. Gray, whose free upper-envelope slope on these
# same data is -0.714 to -0.768. And the screen that produced the number is a
# tuning knob: crown packing at growing space index 15 returns 933 metric (368
# imperial), growing space index 20 returns 622 metric (245 imperial), and
# growing space index 25 returns 373 metric (147 imperial), with 15 the only
# setting in the series whose output lies above the koa literature.
#
# THE EARLIER EPISODE, PRESERVED FOR THE RECORD. The published constant was 500
# metric (197 imperial), an FIA-only quantity that was carried into an equation
# estimated on all four sources, so it was wrong in provenance before it was
# wrong in value. A first correction on 2026-08-05 replaced it with 1350 metric
# (533 imperial) from a 0.99 quantile regression of the Reineke intercept with
# the slope fixed at -1.605. That correction was withdrawn. The estimator,
# rq(a_i ~ 1, tau = 0.99) on an intercept-only model, does not fit a boundary; on
# 269 observations it returns an ORDER STATISTIC, so 1351.50016168609 was one
# plot-year copied out verbatim, PSP plot 102 subplot 2 measured in 2021,
# standing on FIVE stems over an implied area of about 56 m2. The four
# frontier-defining plot-years carried 5, 12, 14 and 30 stems and exceeded the
# koa closed-crown packing limit by factors of 3.20, 1.89, 1.82 and 1.50; the
# rank correlation between crown-packing overshoot and Reineke SDI across the
# cloud is +0.990, so the SDI ranking of this dataset is the overpacking ranking.
# Plot-years with 40 or more stems never exceed 924 metric (365 imperial). Full
# audit of the 1350 episode at /users/PUOM0008/crsfaaron/koa_sdimax_audit/; audit
# of the 933 episode at /users/PUOM0008/crsfaaron/koa_redteam/.
#
# WHAT REPLACES THE SCALAR: A DIAMETER-CONDITIONAL BOUND. The koa literature
# supports a maximum stand basal area rather than a maximum stand density index.
# Harrington, Fownes, Meinzer and Scowcroft (1995, Oecologia 102:277-284,
# doi 10.1007/BF00329794) report 42 m2 ha-1 as the highest basal area observed in
# koa. That anchor is external to this dataset, is measured at diameters the
# inventories actually carry, and does not depend on the slope, the screen or the
# expansion factors. No dispersion is published with it, so it is carried as a
# single reported maximum and flagged as such rather than given a fabricated
# interval. [UNKNOWN: the sampling variability of the 42 m2 ha-1 anchor.]
# Converting it through the Reineke identity,
#     BA = SDI * (pi/4) * 25^1.605 / 1e4 * Dq^0.395,
# gives 934 metric (369 imperial) at Dq 20 cm, 796 metric (314 imperial) at
# Dq 30 cm, and 651 metric (257 imperial) at Dq 50 cm. Quote the bound at the
# diameter you are at, not a scalar.
#
# WHAT THE KOA LITERATURE INDEPENDENTLY SUPPORTS, RETAINED. Baker and
# Scowcroft's 2005 crown-based A-line converts to roughly 440 to 530 metric (175
# to 210 imperial), an interval set by the range of their crown-width allometry.
# Scowcroft et al.'s 2008 stand, which self-thinned from about 20000 seedlings
# ha-1 to 1000 trees ha-1 over 23 years, sits at 595 metric (235 imperial) as a
# single-stand point with no interval reported. The koa-specific literature
# therefore supports roughly 500 to 650 metric (197 to 256 imperial), well below
# both withdrawn values. Neither anchor depends on this dataset's expansion
# factors or on the fixed slope, which is why both survive the withdrawal.
#
# WHAT WAS WRONG WITH THE EXPANSION-FACTOR STORY, CORRECTED. Earlier versions of
# this file stated that plot area and expansion factor are ABSENT from the source
# files and that 112 distinct implied expansion factors appear across 269
# plot-years. THAT CLAIM IS FALSE AND IS RETRACTED HERE. AK_SURV.csv carries a
# fully populated EXPF.0 column with exactly FOUR distinct values, 14.92, 24.80,
# 49.56 and 185.91 trees ha-1 per stem, corresponding to plot areas of 670.0,
# 403.2, 201.8 and 53.8 m2. It is non-missing on all 5,969 rows and constant
# within 95 of the 100 plots. The five exceptions are FIA installations carrying
# both 14.92 and 185.91, which is macroplot and microplot nesting rather than an
# inconsistency, since the 185.91 rows hold stems from 2.5 to 11.7 cm and the
# 14.92 rows hold stems of 12.7 cm and above. The 112 figure was an artifact of
# reconstructing expansion from row counts in an already filtered file, which
# manufactures a distinct implied area for every distinct surviving row count. It
# measured the filter, not the inventory. Use EXPF.0 directly.
#
# THE REAL LIMITATION, STATED PROPERLY. The relative-density exceedance that
# originally motivated abandoning 500 is a data quality problem in the plot-year
# density and diameter records, not a problem in the constant. At any SDImax
# below 2285 metric (901 imperial) some plot-years still exceed relative density
# 1.0, and 2285 is set by a single plot-year implying 129.1 m2 ha-1 of basal
# area, roughly three times the published koa maximum of 42 m2 ha-1. No choice of
# constant can fix a physically impossible plot-year, and raising the constant
# until the exceedances disappear is exactly the error that produced 1350.
#
# WHY NOTHING PREDICTED BY THIS FILE CHANGES. The fitted quantity in this model
# was always a slope per unit of absolute SDI,
#     b_sdi = -3.0933 / 500 = -0.0061866 per SDI unit,
# and the RD-scale coefficient was b_rd = b_sdi * SDImax, which is -3.0933 at
# SDImax 500, -8.3519 at the withdrawn 1350 and -5.7720978 at the withdrawn 933.
# In every one of those parameterisations the product b_rd * RD collapses to
# b_sdi * SDI identically, because RD is a linear rescaling of SDI. Removing
# SDImax therefore removes an algebraic detour and nothing else. The equation
# below is written in the invariant form directly. Verified numerically on
# Cardinal over SDI 0 to 2000 on a 200001-point grid for both origins: the
# maximum absolute difference between the withdrawn 933 parameterisation and the
# present absolute-SDI form is at floating-point level. The same check against
# the published 500 and the withdrawn 1350 parameterisations gives the same
# answer. Only the reporting denominator ever changed, and now there is none.
#
# WHAT A NAIVE SWAP WOULD HAVE DONE, AND WHY THE RISK IS NOW GONE. Changing
# SDImax while leaving b_rd at -3.0933 preserved nothing: at 933 it flattened the
# density response by a factor of 1.87 and inflated recruitment, so at SDI 500 a
# natural stand would have recruited 41.5 instead of 9.9 trees ha-1 yr-1, four
# times too many, and the equivalent error at 1350 was seven times too many. That
# failure mode is structurally impossible in the present form, because there is
# no SDImax in the prediction path to change.
#
# CONSISTENCY REQUIREMENT, NOW TRIVIAL. koa_survival_calibrated.R and this file
# both run without a density maximum, so the two files can no longer disagree
# about a density scale. Both are keyed on absolute SDI. If a relative density is
# reported from either, name the constant used and label it a reporting choice.
#
# CORRECTION OF A FALSE CLAIM MADE ELSEWHERE. It was previously reported that
# correcting SDImax improved the realised Reineke self-thinning slope from
# -1.06 to -1.37 toward -1.11 to -1.61, and that this corroborated the new
# constant. THAT CLAIM IS FALSE. SDImax cancels identically out of the mortality
# ramp, and this ingrowth equation is invariant by exact reparameterisation, so
# the realised slope cannot respond to SDImax at all. Holding the ramp fixed in
# absolute SDI and moving SDImax leaves the slope bit-identical at every BYI
# level, and holding SDImax fixed while applying only the re-tuned ramp
# reproduces the entire claimed improvement. The claim is also circular, since
# the ramp was re-tuned because SDImax had been changed. No self-thinning slope
# result computed from this model can corroborate a choice of SDImax. No claim of
# this kind appears in this file or in koa_survival_calibrated.R, and none may be
# added.
# ============================================================================
#
# DATA. Reconstructed from AK.HT.csv remeasurements (363 plot-periods, 22%
# with ingrowth). Quasi-Poisson log model, stated in the invariant form:
#
#   E[ingrowth, trees ha-1 yr-1] = exp( 5.3836 - 0.0061866*SDI - 1.6359*planted )
#
#   SDI = stand density index, metric, index diameter 25 cm, exponent 1.605;
#   planted = 0 natural, 1 plantation.
#   The equivalent RD form, exp( b0 + b_sdi*SDImax*RD + b_planted*planted ), is
#   algebraically identical for any SDImax and is available through the b_rd
#   override below, but it is not the form to quote, because it drags in a
#   constant that has been revised three times in two days and then withdrawn.
#
# FINDINGS. Absolute stand density is the dominant driver (p < 1e-4): ingrowth
# falls from the cap of 160 trees ha-1 yr-1 in the open, against an uncapped
# intercept prediction of 217.9, to 26.6 natural and 5.2 planted trees ha-1 yr-1
# at SDI 340 metric (134 imperial), which is where the earlier "near canopy
# closure" statement was located. THE FIGURE OF 13 TREES ha-1 yr-1 PREVIOUSLY
# ATTACHED TO SDI 340 IS WRONG AND IS CORRECTED HERE. It does not reproduce:
# exp(5.3836 - 0.0061866*340) is 26.6 natural and 5.2 planted. Thirteen trees
# ha-1 yr-1 natural corresponds to SDI 456 metric (180 imperial), not 340. The 13
# is a stale figure predating the rescaling; the relative densities that used to
# accompany it were correct arithmetic for SDI 340 and are retained below only as
# an illustration of why relative density is no longer quoted. SDI 340 metric is
# RD 0.68 against the published 500, RD 0.36 against the withdrawn 933 and RD
# 0.25 against the withdrawn 1350, a spread of a factor of 2.7 across three
# constants that were each defended in writing inside 24 hours. The absolute SDI
# is the invariant statement and is the only one to quote. Plantations have about
# 5x less ingrowth (rate ratio 0.195, p = 0.029), managed and weeded. BYI is NOT
# included: neither a BYI main effect (p = 0.28) nor a BYI x RD interaction
# (p = 0.56) is significant, and percent koa basal area has no variation (koa
# stands are close to pure koa). BYI acts on ingrowth indirectly through growth
# (it raises density faster). byi_c > 0 enables an OPTIONAL, untested BYI
# multiplier (Aaron's hypothesis: BYI raises ingrowth). [UNKNOWN: the source fit
# reported significance for b0 and b_sdi but no standard errors or dispersion
# scale were retained, so the two recomputed rates above, 26.6 and 5.2 trees ha-1
# yr-1, are exact evaluations of the fitted equation and cannot presently be
# given a prediction interval. Recover the quasi-Poisson vcov and dispersion from
# the original fit before either number is published.]
#
# Recruits enter at a threshold DBH (default 2.5 cm); set HT from koa.HT and an
# initial crown ratio, then add to the tree list before the next cycle.
#
# NOTE ON PARAMETERISATION, STRENGTHENED AGAIN. The density coefficient is stated
# as b_sdi, a slope per unit of absolute SDI, and is NOT derived from or scaled
# by any maximum. The last 48 hours are the argument for this: SDImax was carried
# at 500, then 1350, then 933, and is now absent, and because the coefficient is
# on the absolute scale not one predicted recruitment value moved across any of
# those revisions. Had b_rd been hard-coded on the RD scale, each revision would
# have rescaled the density response by a factor of 2.7 and then 0.69 with no
# visible edit to any coefficient. Passing b_rd directly still works and
# overrides the absolute-scale form, but it then requires SDImax, it exists for
# diagnostics and reproduction of the withdrawn parameterisations, and it must
# not be used in production.
#
# THE BASAL AREA FALLBACK, RE-ANCHORED AND DE-CIRCULARISED. The old fallback
# reference of 49 m2 ha-1 was not an independent quantity: it was the withdrawn
# 933 evaluated at Dq 30 cm (49.23 m2 ha-1), and it stood 17 percent above the
# highest basal area ever published for koa. Using it to convert basal area into
# a density position, and then using that position against thresholds derived
# from the same 933, was circular. The reference is therefore re-anchored
# EXTERNALLY to 42 m2 ha-1 from Harrington, Fownes, Meinzer and Scowcroft (1995,
# Oecologia 102:277-284, doi 10.1007/BF00329794), and the conversion is done
# through the Reineke identity at a stated diameter rather than through a
# maximum. The fallback is EXACT at Dq 20 cm, where 42 m2 ha-1 maps to SDI 934
# metric (369 imperial); supply qmd and it is exact at whatever diameter the
# stand is actually at. It is 796 metric (314 imperial) at Dq 30 cm and 651
# metric (257 imperial) at Dq 50 cm, which is the diameter-conditional bound
# above and is the same statement seen from the other side.

koa.ingrowth <- function(sdi = NA, baph = NA, planted = 0, qmd = NA,
                         SDImax = NA,               # REPORTING ONLY. No default
                                                    # value exists. 500, 1350 and
                                                    # 933 are all withdrawn.
                                                    # Required only if b_rd is
                                                    # supplied, or if a relative
                                                    # density is to be reported.
                         b0 = 5.3836,
                         b_sdi = -0.0061866,        # fitted slope per SDI unit
                                                    # (= -3.0933 / 500); the
                                                    # invariant quantity, and the
                                                    # one the model was fitted on
                         b_rd = NULL,               # diagnostics override only;
                                                    # requires SDImax. -3.0933 at
                                                    # 500, -5.7720978 at the
                                                    # withdrawn 933, -8.3519 at
                                                    # the withdrawn 1350
                         b_planted = -1.6359,
                         byi = 264, byi_c = 0, byi_ref = 390, cap = 160,
                         baph_ref = 42,             # m2 ha-1; was 60, then 72,
                                                    # then 49. EXTERNAL anchor:
                                                    # highest koa basal area
                                                    # published, Harrington,
                                                    # Fownes, Meinzer &
                                                    # Scowcroft 1995, Oecologia
                                                    # 102:277-284,
                                                    # doi 10.1007/BF00329794
                         qmd_ref = 20) {            # cm; diameter at which the
                                                    # basal area fallback is
                                                    # EXACT (42 m2 ha-1 maps to
                                                    # SDI 934 metric, 369
                                                    # imperial, at Dq 20)
  # Reineke conversion constant, (pi/4) * 25^1.605 / 1e4, so that
  #   BA = kR * SDI * Dq^0.395   and   SDI = BA / (kR * Dq^0.395).
  # Exponent 1.605 here and everywhere in this file and in
  # koa_survival_calibrated.R. Do not substitute 1.6.
  kR <- (pi/4) * 25^1.605 / 1e4

  # Density in ABSOLUTE SDI. Relative density plays no part in the prediction.
  if (!is.na(sdi)) {
    sdi_use <- sdi
  } else {
    dq_use  <- if (!is.na(qmd)) pmax(qmd, 0.1) else qmd_ref
    sdi_use <- baph / (kR * dq_use^0.395)
  }

  # Density term. The absolute-SDI form is the production path. The b_rd
  # override reproduces any RD-scale parameterisation exactly and is retained
  # for diagnostics only; it is the one path that divides by SDImax, and it
  # requires the caller to have named one.
  if (is.null(b_rd)) {
    dens_term <- b_sdi * sdi_use
  } else {
    if (is.na(SDImax))
      stop("b_rd was supplied without SDImax; the RD path needs a named maximum, and no default exists.")
    dens_term <- b_rd * (sdi_use / SDImax)
  }

  e <- exp(b0 + dens_term + b_planted * (planted == 1))
  if (byi_c != 0) e <- e * (pmax(byi, 1) / byi_ref)^byi_c
  out <- pmin(pmax(e, 0), cap)                # expected recruits, trees ha-1 yr-1

  # Relative density is a REPORTING CONVENIENCE ONLY and has NO DYNAMICAL ROLE.
  # Not computed unless the caller names a maximum. With SDImax = NA nothing is
  # divided by it and the returned value is a plain numeric.
  if (!is.na(SDImax)) attr(out, "RD") <- sdi_use / SDImax
  out
}

# Drop-in for HiGy.R (add an ingrowth step, e.g. at FVS stop point 6):
#   sdi   <- tph.plot * (qmd/25)^1.605          # exponent 1.605, not 1.6
#   n.rec <- koa.ingrowth(sdi = sdi, planted = stand$planted)   # trees ha-1 yr-1
#   if (n.rec > 0.01) add a recruit record: dbh = 2.5 cm,
#       ht = koa.HT(2.5, baph, qmd, byi), cr ~ 0.6, expf = n.rec
# Verified on 200-yr projections: stands become realistically multi-cohort
# (sustained BA/density rather than self-thinning to a few large trees), with no
# runaway or collapse across origin and BYI. Re-verified 2026-08-05 to 300 years
# against the re-tuned survival ramp, re-executed at SDImax 933 on 2026-08-06,
# and re-executed with SDImax absent on the same day: with this ingrowth active
# the projection reaches a genuine steady state, natural 16.3 m2 ha-1 at SDI 367
# metric (145 imperial) and plantation 15.9 m2 ha-1 at SDI 301 metric (119
# imperial), with density drift under 0.04% per 20 years. Those steady states are
# identical at SDImax 933, at 1350 and with no SDImax at all to within 1.1e-13 in
# basal area, trees ha-1, quadratic mean diameter and SDI, which is the direct
# check that the constant never touched the dynamics; only the percent-of-SDImax
# reporting ever changed, and that reporting has now been withdrawn along with
# the constants. Without ingrowth the same runs are still drifting at 6 to 13%
# per 20 years at year 300 and settle 35% lower in basal area, so this component
# is what actually closes the long-run stand dynamics; wiring it into HiGy.R is a
# prerequisite for enabling the recovered mortality levels documented in
# koa_survival_calibrated.R.
