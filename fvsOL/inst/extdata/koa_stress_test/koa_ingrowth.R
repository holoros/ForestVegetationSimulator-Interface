# koa_ingrowth.R   (2026-06-05; SDImax corrected to 933 metric on 2026-08-06,
#                   superseding the withdrawn 1350 of 2026-08-05)
# Koa-only annualized ingrowth for FVS-HI, to add the missing recruitment
# component (HiGy.R currently has no ingrowth). Follows the two-stage / density
# logic of Li, Weiskittel & Kershaw (2011, Can. J. For. Res. 41:2077-2089) but
# reduced to a single annualized expectation keyed on relative density (RD), per
# Aaron's preference.
#
# Units in this file are metric throughout and are written in plain ASCII:
# m2 ha-1 for basal area, trees ha-1 yr-1 for recruitment, cm for diameter.
# Stand density index is metric first with imperial in parentheses, divisor
# 2.535 from the code's own index diameter of 25 cm.
#
# ============================================================================
# 2026-08-06 CHANGE NOTE: SDImax IS 933 METRIC (368 IMPERIAL), AN UPPER BOUND.
# THE 1350 VALUE PREVIOUSLY CARRIED IN THIS FILE IS WITHDRAWN. b_rd IS
# RESCALED SO THAT PREDICTIONS ARE UNCHANGED, AGAIN.
#
# THE WHOLE EPISODE, PLAINLY. The published constant was 500 metric (197
# imperial), an FIA-only quantity that was carried into an equation estimated on
# all four sources, so it was wrong in provenance before it was wrong in value.
# A first correction on 2026-08-05 replaced it with 1350 metric (533 imperial)
# from a 0.99 quantile regression of the Reineke intercept with the slope fixed
# at -1.605. That correction is WITHDRAWN. The estimator, rq(a_i ~ 1, tau =
# 0.99) on an intercept-only model, does not fit a boundary; on 269 observations
# it returns an ORDER STATISTIC, so 1351.50016168609 is one plot-year copied out
# verbatim, PSP plot 102 subplot 2 measured in 2021, standing on FIVE stems over
# an implied area of about 56 m2. The four frontier-defining plot-years carry 5,
# 12, 14 and 30 stems and exceed the koa closed-crown packing limit by factors
# of 3.20, 1.89, 1.82 and 1.50; the rank correlation between crown-packing
# overshoot and Reineke SDI across the cloud is +0.990, so the SDI ranking of
# this dataset is the overpacking ranking. Plot-years with 40 or more stems
# never exceed 924 metric (365 imperial). Freeing the slope on the same data
# gives an upper envelope between -0.47 and -1.17, and -1.605 sits outside every
# interval; because the extreme plot-years are all large-diameter, forcing the
# steeper slope biases the intercept UPWARD. Full audit at
# /users/PUOM0008/crsfaaron/koa_sdimax_audit/.
#
# WHAT IS DEPLOYED. 933 metric (368 imperial), 95 percent cluster bootstrap
# percentile interval 844 to 946 metric (333 to 373 imperial), B = 2000,
# installations resampled, seed 20260805. It is the 0.99 quantile of the
# screened cloud: 59 plot-years across 13 installations that reproduce their
# reported quadratic mean diameter within 10 percent, carry at least 20 stems,
# and sit at or below the koa crown packing limit. It must be read as an UPPER
# BOUND rather than a best estimate, because the interval covers sampling within
# the screened set and not the screening decision. The koa literature
# independently supports 500 to 650 metric (197 to 256 imperial), and the
# residual gap between that and 933 indicates expansion-factor noise that
# screening has reduced but not removed. Anything above roughly 950 metric (375
# imperial) is unsupported by any screened plot-year in this dataset. Plot area
# and expansion factor are ABSENT from the source files: 112 distinct implied
# expansion factors appear across 269 plot-years, and only 4 of the 29 plots
# remeasured three or more times hold implied area constant within 5 percent
# across remeasurements. This constant should therefore be revisited against the
# source inventories once the PSP custodians supply plot area, expansion factor
# and minimum measured diameter.
#
# WHY b_rd MOVED AND THE PREDICTIONS DID NOT. Unlike the survival ramp, this is
# a smooth log-linear function of density with no thresholds, so re-expressing
# it under a new SDImax is an EXACT reparameterisation rather than a re-tuning.
# The fitted quantity is a slope per unit of SDI,
#     b_sdi = -3.0933 / 500 = -0.0061866 per SDI unit,
# and the RD-scale coefficient is b_rd = b_sdi * SDImax, which is -3.0933 at
# SDImax 500, -8.3519 at the withdrawn 1350, and -5.7720978 at the deployed 933.
# Refitting the quasi-Poisson model with RD recomputed at SDImax = 933 returns
# exactly this value, because the covariate is a linear rescaling of the old
# one. Verified numerically on Cardinal 2026-08-06 over SDI 0 to 2000 on a
# 200001-point grid for both origins: the maximum absolute difference between
# the published predictions and the rescaled ones is 1.4e-13 trees ha-1 yr-1,
# which is floating-point noise. The same check against the withdrawn 1350
# parameterisation gives the same 1.4e-13. Both reparameterisations are exact;
# only the reporting denominator ever changed.
#
# WHAT A NAIVE SWAP WOULD DO. Changing SDImax to 933 while leaving b_rd at
# -3.0933 preserves nothing. It flattens the density response by a factor of
# 1.87 and inflates recruitment: at SDI 500 a natural stand would recruit 41.5
# instead of 9.9 trees ha-1 yr-1, four times too many. The equivalent error at
# 1350 was seven times too many. Do not do it at any SDImax.
#
# CONSISTENCY REQUIREMENT. koa_survival_calibrated.R and this file must carry
# the SAME SDImax. If one is changed the other must be changed in the same
# commit. Changing SDImax consistently changes no prediction anywhere, in this
# file or in the survival ramp; changing it in only one file would, because the
# mortality ramp and the recruitment response would then be reading two
# different density scales.
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
# the ramp was re-tuned because SDImax had been changed. No claim of this kind
# appears in this file or in koa_survival_calibrated.R, and none may be added.
# ============================================================================
#
# DATA. Reconstructed from AK.HT.csv remeasurements (363 plot-periods, 22%
# with ingrowth). Quasi-Poisson log model:
#
#   E[ingrowth, trees ha-1 yr-1] = exp( 5.3836 - 5.7720978*RD - 1.6359*planted )
#
#   RD = SDI / SDImax (SDImax = 933 metric, 368 imperial);
#   planted = 0 natural, 1 plantation.
#   Equivalently and invariantly: exp( 5.3836 - 0.0061866*SDI - 1.6359*planted ).
#   The second form is the one to quote, because it does not depend on a
#   constant that has been revised twice in two days.
#
# FINDINGS. RD is the dominant driver (p < 1e-4): ingrowth falls from ~160
# (open) to ~13 trees ha-1 yr-1 near canopy closure, which in absolute terms is
# SDI ~ 340 metric (134 imperial), or RD 0.36 at SDImax 933, against RD 0.68 of
# the published 500 ceiling and RD 0.25 of the withdrawn 1350. The absolute SDI
# is the invariant statement. Plantations have ~5x less ingrowth (rate ratio
# 0.195, p = 0.029), managed and weeded. BYI is NOT included: neither a BYI main
# effect (p = 0.28) nor a BYI x RD interaction (p = 0.56) is significant, and %
# koa BA has no variation (koa stands are ~pure koa). BYI acts on ingrowth
# indirectly through growth (it raises RD faster). byi_c > 0 enables an
# OPTIONAL, untested BYI multiplier (Aaron's hypothesis: BYI raises ingrowth).
#
# Recruits enter at a threshold DBH (default 2.5 cm); set HT from koa.HT and an
# initial crown ratio, then add to the tree list before the next cycle.
#
# NOTE ON PARAMETERISATION, STRENGTHENED. b_rd is DERIVED from b_sdi and SDImax
# rather than hard-coded, so that any future change to SDImax cannot silently
# change the fitted density response. The last 24 hours are the argument for
# this: SDImax has been carried at 500, then 1350, then 933, and because b_rd is
# derived, not one predicted recruitment value moved across any of those
# revisions. Had b_rd been hard-coded, each revision would have rescaled the
# density response by a factor of 2.7 and then 0.69 with no visible edit to any
# coefficient. Passing b_rd directly still works and overrides the derivation,
# but that override is for diagnostics and should not be used in production.
# The BA fallback reference moves from 60, and from the 72 carried in the
# withdrawn version, to 49 m2 ha-1, for the same reason it does in
# koa_survival_calibrated.R. Setting the two density paths equal,
# baph_ref = SDImax * (25/QMD)^1.605 * (pi/4) * (QMD/100)^2, the
# Reineke-consistent basal area at SDI 933 and QMD 30 cm is 49.2 m2 ha-1, which
# is rounded to 49 here, a difference of 0.4 percent. Run backwards, a baph_ref
# of 49 implies an SDImax of 1090 at QMD 20 cm falling to 759 at QMD 50 cm,
# bracketing 933 as it must; the published 60 m2 ha-1 implied 1335 down to 930
# over the same range and was therefore never compatible with a SDImax of 500.

koa.ingrowth <- function(sdi = NA, baph = NA, planted = 0,
                         SDImax = 933,              # metric (368 imperial);
                                                    # screened-data UPPER BOUND,
                                                    # 95% CI 844-946 metric
                                                    # (333-373 imperial).
                                                    # Was 500, then 1350
                                                    # (WITHDRAWN 2026-08-06).
                         b0 = 5.3836,
                         b_sdi = -0.0061866,        # fitted slope per SDI unit
                                                    # (= -3.0933 / 500); the
                                                    # SDImax-free quantity
                         b_rd = b_sdi * SDImax,     # -5.7720978 at SDImax 933
                                                    # (-3.0933 at 500,
                                                    #  -8.3519 at 1350)
                         b_planted = -1.6359,
                         byi = 264, byi_c = 0, byi_ref = 390, cap = 160,
                         baph_ref = 49) {           # was 60, then 72; see note
  RD <- if (!is.na(sdi)) sdi / SDImax else baph / baph_ref
  e  <- exp(b0 + b_rd * RD + b_planted * (planted == 1))
  if (byi_c != 0) e <- e * (pmax(byi, 1) / byi_ref)^byi_c
  pmin(pmax(e, 0), cap)                       # expected recruits, trees ha-1 yr-1
}

# Drop-in for HiGy.R (add an ingrowth step, e.g. at FVS stop point 6):
#   n.rec <- koa.ingrowth(sdi = sdi, planted = stand$planted)   # trees ha-1 yr-1
#   if (n.rec > 0.01) add a recruit record: dbh = 2.5 cm,
#       ht = koa.HT(2.5, baph, qmd, byi), cr ~ 0.6, expf = n.rec
# Verified on 200-yr projections: stands become realistically multi-cohort
# (sustained BA/density rather than self-thinning to a few large trees), with no
# runaway or collapse across origin and BYI. Re-verified 2026-08-05 to 300 years
# against the re-tuned survival ramp, and re-executed at SDImax 933 on
# 2026-08-06: with this ingrowth active the projection reaches a genuine steady
# state, natural 16.3 m2 ha-1 at SDI 367 and plantation 15.9 m2 ha-1 at SDI 301,
# with density drift under 0.04% per 20 years. Those steady states are identical
# at SDImax 933 and 1350 to within 1.1e-13 in basal area, trees ha-1, quadratic
# mean diameter and SDI, which is the direct check that the constant does not
# touch the dynamics; only the percent-of-SDImax reporting changes, from 27.2%
# natural and 22.3% plantation at 1350 to 39.3% and 32.3% at 933. Without
# ingrowth the same runs are still drifting at 6 to 13% per 20 years at year 300
# and settle 35% lower in basal area, so this component is what actually closes
# the long-run stand dynamics; wiring it into HiGy.R is a prerequisite for
# enabling the recovered mortality levels documented in
# koa_survival_calibrated.R.
