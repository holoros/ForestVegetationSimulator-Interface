"""koa_params.py -- SINGLE SOURCE OF TRUTH for every koa survival and ingrowth
constant used by the deposited Python engine.

CORRECTION, 6 September 2026, HEIGHT INCREMENT PROVENANCE. This file states in
more than one place that no fitting script and no fitted object for the height
increment equation has ever been recovered. THAT STATEMENT IS FALSE and every
instance of it in this file is superseded by SOURCE_OF_TRUTH.md entry OI-6.
dHT_BYI.rda holds dHT.m3, and the fitting script sits at "Koa  Increment
Models.r" lines 316 to 329 and reproduces DHT_COEFFS to 4.625e-7; its variance
components 0.843765 and 0.418954 give a marginal height factor of 1.5585. The
claim is load bearing rather than decorative, because it is the stated
justification for leaving CF_DHT at 1.030. The DEPLOYED VALUE DID NOT MOVE on
6 September 2026 and CF_DHT remains 1.030. Only the provenance claim is
corrected, and the recursion-consistent re-derivation of the factor was still
running in a parallel track when this note was written.

Created 2026-08-07 as the F9 fix: no constant may be typed twice in this
codebase. Every module in figshare_v62/ that needs a survival or ingrowth
number imports it from here. Nothing here is fitted; every value is transcribed
verbatim from the R equations of record, with the file and line it came from
recorded in the comment beside it.

THE EQUATION OF RECORD IS THE R SOURCE, NOT THIS FILE. If the R changes, this
file is edited to match it and the transcription line references are updated.

WHAT CHANGED ON 2026-08-07. The deposited Python previously carried a RETIRED
parameterisation: a scalar SDImax of 500 with a relative-density mortality ramp
at onset RD 0.65 and full lift RD 0.85, which places the absolute onset at
SDI 325 and full lift at SDI 425. The equation of record ramps on ABSOLUTE
stand density index, onset at SDI 200 and full lift at SDI 850, and carries no
SDImax at all. The two parameterisations agree only below SDI 200 and at or
above SDI 850. In between they diverge substantially: annual mortality for
natural origin at SDI 325 is 0.30% under the retired form against 3.18% of
record, at SDI 425 it is 15.30% against 5.49%, and at SDI 500 it is 15.30%
against 7.22%. See test_engine_equivalence.py.

NO SCALAR SDImax IS DEPLOYED. 500, 933 and 1350 metric are all withdrawn.
Relative density is a reporting convenience with no dynamical role, and any
figure, table or sentence expressed as a percent of SDImax is withdrawn along
with the constants. Report absolute SDI.
"""

import math
# ADDED 6 September 2026. The first import this module has ever carried, and it exists
# for one reason: CF_DDBH_MC_SIGMA_LOG is DERIVED from CF_DDBH_MC_SE_REL rather than
# typed beside it, so a future editor who moves the correction's relative standard
# error cannot leave a stale lognormal scale behind. Typing the derived value would be
# the F9 failure mode in its subtler form, namely two numbers that must agree and no
# mechanism that makes them.

# =============================================================================
# Provenance
# =============================================================================

SOURCE_OF_TRUTH = (
    "final/koa_survival_calibrated.R (modified 2026-08-06 09:17; header dated "
    "'tuned 2026-06-05; ramp re-tuned 2026-08-05; SDImax 1350 withdrawn "
    "2026-08-06; SDImax 933 withdrawn 2026-08-06 by red team seed 20260806; NO "
    "SCALAR SDImax IS DEPLOYED IN THIS VERSION') and final/koa_ingrowth.R "
    "(same withdrawal note). Transcribed into Python 2026-08-07."
)

SURVIVAL_SOURCE_FILE = "final/koa_survival_calibrated.R"
INGROWTH_SOURCE_FILE = "final/koa_ingrowth.R"
TRANSCRIBED_ON = "2026-08-07"


# =============================================================================
# The withdrawn scalar. Kept as a named, poisoned sentinel so that any code
# still reaching for SDImax fails loudly with an explanation instead of
# silently reintroducing a retired constant.
# =============================================================================

class WithdrawnConstant:
    """A named constant that has been withdrawn. Any attempt to use it in
    arithmetic, formatting or a float conversion raises with the reason."""

    __slots__ = ("name", "reason")

    def __init__(self, name, reason):
        self.name = name
        self.reason = reason

    def _die(self, *a, **k):
        raise RuntimeError(
            "%s is WITHDRAWN and cannot be used. %s" % (self.name, self.reason)
        )

    __float__ = __int__ = _die
    __truediv__ = __rtruediv__ = _die
    __mul__ = __rmul__ = _die
    __add__ = __radd__ = _die
    __sub__ = __rsub__ = _die
    __lt__ = __le__ = __gt__ = __ge__ = _die
    __format__ = _die

    def __bool__(self):
        return False

    def __repr__(self):
        return "<WithdrawnConstant %s>" % self.name

    __str__ = __repr__


SDIMAX_WITHDRAWN = WithdrawnConstant(
    "SDImax (scalar maximum stand density index for Acacia koa)",
    # final/koa_survival_calibrated.R lines 14-19, 21-123; final/koa_ingrowth.R
    # lines 17-23, 25-62. 500 metric was an FIA-only quantity carried into an
    # equation fitted on all four sources; 1350 metric was a single plot-year
    # copied out of an intercept-only quantile regression; 933 metric was a
    # two-point order-statistic blend on 59 screened plot-years, extrapolated
    # along a slope of -1.605 never estimated for the species, behind a screen
    # whose tightest setting was chosen after the fact.
    "500, 933 and 1350 metric are all withdrawn and no replacement scalar "
    "exists. The mortality ramp and the ingrowth density response are both "
    "parameterised in ABSOLUTE SDI and do not need one. If a relative density "
    "must be reported, name the constant used, label it a reporting choice, and "
    "prefer the diameter-conditional bound in BOUND_SDI_BY_QMD.",
)


# =============================================================================
# Reineke identity. Shared by survival, ingrowth and the diameter-conditional
# bound. BA = KR * SDI * Dq**DQ_EXPONENT and SDI = BA / (KR * Dq**DQ_EXPONENT).
# =============================================================================

REINEKE_EXPONENT = 1.605
# final/koa_survival_calibrated.R line 517 (kR definition) and lines 605-619
# ("THE EXPONENT IN THAT DROP-IN IS 1.605, NOT 1.6, AND THAT MATTERS");
# final/koa_ingrowth.R lines 259-261. Do not substitute 1.6.

DQ_EXPONENT = 0.395
# final/koa_survival_calibrated.R line 533 (dq_use**0.395); line 101 and
# final/koa_ingrowth.R line 74 give the same exponent in the BA identity.
# Equals REINEKE_EXPONENT - 2 + 1.0 only coincidentally; it is 2 - 1.605.

INDEX_DIAMETER_CM = 25.0
# final/koa_survival_calibrated.R lines 11-12 and 517; the Reineke index
# diameter the metric SDI is defined on. Implies the metric-to-imperial
# divisor 2.535 quoted at line 11.

IMPERIAL_DIVISOR = 2.535
# final/koa_survival_calibrated.R line 11; final/koa_ingrowth.R line 15.
# Reporting only: metric SDI divided by this gives the imperial equivalent.


def kR():
    """Reineke conversion constant, (pi/4) * 25**1.605 / 1e4.
    final/koa_survival_calibrated.R line 517; final/koa_ingrowth.R line 261."""
    import math
    return (math.pi / 4.0) * INDEX_DIAMETER_CM ** REINEKE_EXPONENT / 1e4


KR = kR()


# =============================================================================
# MORTALITY ENGINE OF RECORD, 4 September 2026 (deposit 1.6.0, manuscript v82):
# the Garcia (2009) three-stage component, koa_mortality_garcia.py.
# Specification: _v82_build/GARCIA_SPEC_2026-09-04.md. Parameters fitted by
# koa_mortality_3stage_FINAL_2026-09-04.R on the 360 regular plot intervals of
# the survivor-cohort pair table (103 plots, 469 deaths, 15,562 tree-years),
# weighted nonlinear least squares on ln S at the second measurement, seed
# 20260904, B = 2,000 plot-cluster percentile bootstrap.
#
#   S^alpha - (beta * H40)^gamma = constant,  S = 100 / sqrt(N), N trees ha-1,
#   H40 in m, gamma/alpha fixed at 1 (the free ratio is unidentified on this
#   record, bootstrap interval 0.33 to 11.6).
#   Stepping: c = S0^a - (b H40_0)^g; S1 = (c + (b H40_1)^g)^(1/a); N1 = 1e4/S1^2.
#   Deployed annual rate: m_stand = max(1 - N1/N0, base(origin))  [A1 floor],
#   with base(origin) the BASE_NAT / BASE_PLT already of record below.
# =============================================================================

MORT_ENGINE = "garcia_qmd_anchored"
# DEPLOYED 5 September 2026: candidate C5 of the hybrid evaluation, the only arm that
# passed every hard gate of the selection rule (unknowns ledger D1, results in
# _v82_build/hybrid_candidates_2026-09-04.md): no BAPH above 76.06 m2 ha-1 and no SDI
# above 1,453.47 within 52 yr in the even-aged rows, Reineke slope inside -1.2 to -2.2
# at 4 of 6 site by origin combinations in the uncapped Bakuzis run, no volume
# site-ordering inversion attributable to mortality. Was "garcia" (C2) from 4 to 5
# September 2026, which is now labelled EVALUATED.
# ENGINE SELECTOR, 5 September 2026 (hybrid candidate evaluation, unknowns ledger D1).
# Five arms are callable by explicit mort_engine=... on both projectors; the default
# above is the one the selection rule of the ledger picked. Every arm shares the
# retired height vector, every harness bound, the A1 floor (BASE_NAT / BASE_PLT)
# and Stage 3 size allocation; the arms differ ONLY in the density state variable
# that drives the Garcia step and in the anchoring of beta.
#   "garcia"              C2  Garcia on H40 = K_TOP * HT (spec of record as fitted).
#                             EVALUATED, not deployed: runs at floor mortality under
#                             the harness (F-1), fails the envelope and Reineke gates.
#                             Kept callable; its numbers are the stress-test record
#                             (_v82_build/numbers_C2_garcia_h40_STRESSTEST.json).
#   "garcia_qmd"          C3  Garcia on the allometric height equivalent
#                             H_QMD = exp((ln QMD - GARCIA_ALLOM_A) / GARCIA_ALLOM_K_HD),
#                             same alpha, beta, floor. Limiting line in Reineke space
#                             has slope -2 / k_HD by construction.
#   "garcia_qmd_anchored" C5  DEPLOYED. C3 with beta re-anchored (GARCIA_BETA_ANCHORED)
#                             so the limiting line passes through the observed density
#                             envelope (99th percentile of N * H_QMD^2, AK_TREE.csv).
#   "garcia_max_ramp"     C4  max(m_garcia on H40, m_ramp).
#   "ramp"                C1  RETIRED. The density ramp of v81, explicit only; also
#                             fails the Reineke gate (uncapped slopes -2.1 to -2.5).
#   "garcia_qmd_anchored_dd_rd"    C6  C5 with the FLAT A1 floor replaced by the fitted
#                                      density-dependent background term on ln RD (form
#                                      "lnRD" of REG_MORT_COEF below).
#   "garcia_qmd_anchored_dd_sdi"   C7  same, on ln SDI (form "lnSDI").
#   "garcia_qmd_anchored_dd_sdi2"  C8  same, on ln SDI with curvature (form "lnSDI2").
#   "garcia_qmd_anchored_dd_rd_reg"    C9   as C6 but fitted on the REGULAR intervals only.
#   "garcia_qmd_anchored_dd_sdi_reg"   C10  as C7 but fitted on the regular intervals only.
#   "garcia_qmd_anchored_dd_sdi2_reg"  C11  as C8 but fitted on the regular intervals only.
#   "garcia_qmd_anchored_dd_const"     DIAGNOSTIC. The A1 floor REFITTED as a flat rate on
#   "garcia_qmd_anchored_dd_const_reg" DIAGNOSTIC. the same frames, no density term at all.
#                                      These two exist to separate the effect of density
#                                      dependence from the effect of the mortality LEVEL on
#                                      the Bakuzis Reineke slope. They are not candidates.
_DD_ARMS = ("garcia_qmd_anchored_dd_rd", "garcia_qmd_anchored_dd_sdi",
            "garcia_qmd_anchored_dd_sdi2", "garcia_qmd_anchored_dd_rd_reg",
            "garcia_qmd_anchored_dd_sdi_reg", "garcia_qmd_anchored_dd_sdi2_reg",
            "garcia_qmd_anchored_dd_const", "garcia_qmd_anchored_dd_const_reg")
MORT_ENGINES = ("garcia", "garcia_qmd", "garcia_qmd_anchored", "garcia_max_ramp", "ramp") + _DD_ARMS
GARCIA_FAMILY = ("garcia", "garcia_qmd", "garcia_qmd_anchored", "garcia_max_ramp") + _DD_ARMS
GARCIA_QMD_ENGINES = ("garcia_qmd", "garcia_qmd_anchored") + _DD_ARMS
# Arms whose background term is the fitted density-dependent A1' term rather than the flat
# A1 floor. Every one of them uses GARCIA_BETA_ANCHORED for the Garcia step, so
# koa_mortality_garcia.beta_attr() must map them to GARCIA_BETA_ANCHORED.
GARCIA_DD_ENGINES = _DD_ARMS
REG_MORT_ENGINE_FORM = {"garcia_qmd_anchored_dd_rd": "lnRD",
                        "garcia_qmd_anchored_dd_sdi": "lnSDI",
                        "garcia_qmd_anchored_dd_sdi2": "lnSDI2",
                        "garcia_qmd_anchored_dd_rd_reg": "lnRD_reg",
                        "garcia_qmd_anchored_dd_sdi_reg": "lnSDI_reg",
                        "garcia_qmd_anchored_dd_sdi2_reg": "lnSDI2_reg",
                        "garcia_qmd_anchored_dd_const": "const",
                        "garcia_qmd_anchored_dd_const_reg": "const_reg"}

GARCIA_ALLOM_A = 0.167997928455782   # v103 M1 pair table, 2026-09-30
GARCIA_ALLOM_K_HD = 1.04106514616602   # v103 M1 pair table, 2026-09-30
# ln QMD0 = a + k_HD ln H40_0, ordinary least squares on the 360 regular intervals
# (irreg FALSE, H40 and SDI0 present) of mortality-3stage/plot_interval_pairs_DATA.csv,
# 103 plots, no site term [A8]. R2 0.701, RMSE 0.460 on ln QMD, SE(a) 0.0989,
# SE(k_HD) 0.0405. Fitted 5 September 2026 by hybrid/fit_allometry.py
# (_v82_build/hybrid/). H_QMD at QMD 8, 15, 25, 40, 60 cm is 6.8, 11.6, 18.0, 26.9
# and 38.0 m. These two constants are NOT perturbed in the Monte Carlo (Table S4).
GARCIA_BETA_ANCHORED = 0.14803309491927027   # v103 live koa stems (>= 5), 100 / sqrt(z99), 2026-09-30
# C5 anchoring. 100 / sqrt(z99) with z99 the 99th percentile of N * H_QMD^2 over the
# 471 live plot-measures (>= 5 stems, KeyDupFlag 0) of AK_TREE.csv, so the limiting
# line N = 10000 / (beta H_QMD)^2 passes through the observed density envelope.
# Moves beta from 0.117 to 0.1602 (+36.9 percent), just outside the bootstrap 95
# percent interval 0.057 to 0.159; N_limit at QMD 25 cm falls from 2,254 to 1,202
# trees ha-1 (SDI 1,202 against the observed maximum 1,453.47). hybrid/beta_anchored.json.
# The default mortality path of koa_projector.project_cohort and project_psp.
# The RETIRED density ramp ("ramp") must be asked for EXPLICITLY
# (project_cohort(..., mort_engine="ramp") or project_psp(..., mort_engine="ramp")).
# Nothing reads the retired ramp by default. It is kept for the comparison of record (LOIO annual bias +0.024 yr-1,
# 101 percent overprediction of regular deaths, against -0.011 yr-1 for Garcia;
# memo of 4 September 2026) and for the v81 regression gate.

GARCIA_ALPHA = 2.96
# alpha = gamma; bootstrap 95 percent interval 1.64 to 4.99.
GARCIA_BETA = 0.117
# bootstrap 95 percent interval 0.057 to 0.159.
GARCIA_GAMMA_OVER_ALPHA = 1.0
# Fixed, not fitted. Limiting line log N + 2 (gamma/alpha) log H40 = constant.
GARCIA_SE_ALPHA = (4.99 - 1.64) / 3.92          # 0.8546
GARCIA_SE_BETA = (0.159 - 0.057) / 3.92         # 0.02602
# [ASSUMPTION A3] Normal approximation to the percentile bootstrap interval,
# SE = (upper - lower) / 3.92. Used ONLY by the Table 8 / Figure 8 Monte Carlo
# (regen_t8_chunked.py, regenerate_fig8.py, regenerate_uneven_aged.py), which
# draw alpha and beta from Normal(estimate, SE) and replace the retired lift
# draw at MAXLIFT_MC_SE. Draws are clipped to the physical range below.
GARCIA_SE_BETA_ANCHORED = None
# CORRECTED 5 September 2026 (IMPL-13): the anchored beta (GARCIA_BETA_ANCHORED, C5) is a
# calibration constant (99th percentile of the observed N*H_QMD^2 envelope), not a fitted
# parameter with a sampling distribution, so it carries no SE and is held FIXED at
# 0.16019053617304435 in the Table 8 / Figure 8 / uneven-aged Monte Carlo -- every producer
# checks beta_attr()=="GARCIA_BETA_ANCHORED" and skips the draw. Table S4 states this
# explicitly as "fixed", not an SE. A prior build (5 September, before this correction)
# perturbed it at the fitted beta's SE by mistake; every dependent Monte Carlo artifact was
# rerun under the fix.
GARCIA_MC_CLIP_ALPHA = (1.0, 6.0)
GARCIA_MC_CLIP_BETA = (0.02, 0.25)
# Clip range for the Monte Carlo draws, about two bootstrap intervals wide,
# keeping alpha above 1 (the form needs alpha > 0 and a Reineke-like slope) and
# beta positive. Harness convention, disclosed with Table S4.
GARCIA_IMPLIED_REINEKE_SLOPE = -1.71
GARCIA_K_HD = GARCIA_ALLOM_K_HD
# Was typed 1.17 (reporting only) on 4 September; now an alias of the fitted value.
# -2 (gamma/alpha) / k_HD with k_HD the slope of ln QMD on ln H40 across the
# regular intervals. Reporting only.

K_TOP = 1.146
# [ASSUMPTION A2] Ratio H40 / (EXPF-weighted mean live height) used to obtain
# H40 from a single average cohort: H40 = K_TOP * HT_cohort. MEASURED 4
# September 2026 in the Cowork sandbox from AK_TREE.csv at the start and end
# plot-measures of the 361 regular intervals in
# mortality-3stage/plot_interval_pairs_DATA.csv (irreg == FALSE), the same
# h40() definition as koa_mortality_3stage_FINAL_2026-09-04.R (sort by DBH
# descending, accumulate EXPF to 40 ha-1, EXPF-weighted mean height of that
# top set) over the EXPF-weighted mean height of all live stems with DBH > 0,
# HT > 0 and EXPF > 0. n = 495 unique plot-measures: median 1.1460 (the value
# adopted), mean 1.1760, IQR 1.0000 to 1.2879, range 0.130 to 2.019; natural
# median 1.138 (n 436), planted 1.179 (n 59); start measures only (n 361)
# median 1.164. The 25th percentile is exactly 1.0 because a plot whose
# largest-DBH record carries EXPF >= 40 has H40 equal to a single stem height
# and a plot with equal heights has ratio 1. Multi-cohort lists compute H40
# exactly and do not use this constant (koa_mortality_garcia.h40_from_list).

# =============================================================================
# A1' DENSITY-DEPENDENT BACKGROUND MORTALITY, 5 September 2026 (v83).
# Replaces the FLAT A1 floor max(m_garcia, base(origin)) with
#     m_stand = max(m_garcia_step, m_regular(density, origin))
# because the anchored Garcia line sits near SDI 1,100 while the 23 validation
# plots sit at initial SDI 13 to 454, so the Garcia term never binds there and
# the whole projected rate was supplied by a constant, which cannot reproduce a
# density gradient. The observed gradient is real: on the 421 rebuilt plot
# intervals the tree-year-weighted annual rate runs 0.0223, 0.0509 and 0.0887
# yr-1 across initial-SDI tertiles at mean SDI 59.0, 310.9 and 837.3.
#
# FRAME (pre-registered, _v83_build/SELECTION_RULE_2026-09-05.md): plot intervals
# rebuilt from AK_TREE.csv alone by _v83_build/build_pairs.py, mirroring the pair
# construction of koa_mortality_3stage_FINAL_2026-09-04.R, with stand density from
# the SUMMED LIVE EXPANSION FACTORS of the starting plot-measure and never from the
# TPH / QMD / BAPH / SDI columns of AK_TREE.csv, which are plot-level attributes
# merged from a tally the deposited stem records do not reproduce. AK_SURV.csv is
# not used at any point because its increment condition selects on the outcome.
# Sentinel reading A (a dead record carrying no measured diameter is a death),
# dead-to-live guard "base" (the convention of the fit of record), ALL intervals
# rather than the regular subset, since Stage 1 is disabled in every reported
# projection so the deterministic rate must be the expectation over regular and
# irregular intervals alike. n = 421 intervals, 112 plots, 1,389 deaths,
# 20,870 tree-years.
#
# ESTIMATOR: binomial GLM, complementary log-log link, offset log(YIP), so the
# linear predictor is on the annual hazard and the annual rate is
#     m = 1 - exp(-exp(eta)).
# Cluster-robust inference by plot-clustered bootstrap, B = 2,000, seed 20260905,
# clustering on plot key (the clustering the Garcia bootstrap used).
#
# CRITICAL SENTINEL DEPENDENCY. Every coefficient below is fitted under sentinel
# reading A. Under reading B, in which a sentinel row is not mortality and the tree
# is censored out of the interval's exposure, the record falls to 98 deaths in
# 14,934 tree-years (22 deaths in the regular subset) and the density term cannot be
# fitted, reproducing the finding already of record for the retired ramp. If the
# custodians rule that sentinels are not mortality, this term is WITHDRAWN, not
# re-estimated, and the engine reverts to the flat A1 floor of arm C5. See
# _v83_build/SENTINEL_DEPENDENCY.md.
#
# OUTCOME: EVERY A1' ARM IS EVALUATED AND NONE IS DEPLOYED. MORT_ENGINE stays
# "garcia_qmd_anchored" (C5). All eight arms clear hard gates 1 and 3 and do so more
# comfortably than C5 (0 even-aged BAPH or SDI points above the observed maxima at any
# age, and the 4 uneven-aged BAPH exceedances C5 carries fall to 0), and they close most
# of the tertile gap the refit exists to fix, but every one of them FAILS hard gate 2:
# the uncapped Bakuzis Reineke slope lands at -2.8 to -4.5 with 0 of 6 site-by-origin
# cells inside -1.2 to -2.2, against 4 of 6 for C5. The two flat diagnostic arms
# ("_dd_const", "_dd_const_reg") were run precisely to attribute that failure and they
# fail it just as badly (-2.81 to -4.50) although they carry NO density term at all,
# while the retired ramp, whose realised rate is HIGHER still, passes at -2.11 to -2.49.
# The Reineke slope in this harness is therefore governed by WHEN in the trajectory
# mortality acts, not by how much of it there is: a term that delivers observed-level
# mortality at low density steepens ln N against ln QMD past the gate, and a threshold
# form that withholds mortality until high density does not. The record demands the
# former, since the low-SDI tertile of the validation plots observes 0.0581 yr-1 at mean
# SDI 13. The conflict is with the growth side of the harness, not with the mortality
# term, so under the pre-registered contamination guard the best-fitting candidate is
# reported and NOT deployed. Full account: _v83_build/.
# =============================================================================
REG_MORT_FORMS = ("const", "lnRD", "lnSDI", "lnSDI2",
                  "const_reg", "lnRD_reg", "lnSDI_reg", "lnSDI2_reg")
REG_MORT_COEF = {
    # FITTED. Perturbed in the Monte Carlo from REG_MORT_SE below.
    # ALL-INTERVAL frame, n = 421 intervals, 112 plots, 1,389 deaths, 20,870 tree-years.
    "const":  {"intercept": -2.4457410, "planted": -1.3217550},
    "lnRD":   {"intercept": -2.0158910, "planted": -1.0688830, "b1": 0.4166610},
    "lnSDI":  {"intercept": -5.3250390, "planted": -1.0271060, "b1": 0.4686260},
    "lnSDI2": {"intercept": -11.5220350, "planted": -1.0739050, "b1": 2.5918240,
               "b2": -0.1787690},
    # REGULAR-INTERVAL frame (irregular = annual cohort mortality above
    # STAGE1_IRREG_THRESHOLD 0.10, the definition of the fit of record), n = 362
    # intervals, 475 deaths, 15,647 tree-years. This is the Stage 2 regular rate in the
    # literal three-stage sense; the all-interval forms above fold the irregular
    # episodes into the deterministic background because Stage 1 is disabled.
    "const_reg":  {"intercept": -3.3250380, "planted": -0.5480130},
    "lnRD_reg":   {"intercept": -2.9903530, "planted": -0.4143300, "b1": 0.2830300},
    "lnSDI_reg":  {"intercept": -5.2414700, "planted": -0.3909820, "b1": 0.3199100},
    "lnSDI2_reg": {"intercept": -13.0983160, "planted": -0.4997290, "b1": 3.1170540,
                   "b2": -0.2435200},
}
REG_MORT_SE = {
    # Plot-cluster bootstrap standard deviations, B = 2,000, seed 20260905. FITTED
    # quantities, so these ARE perturbed in the Monte Carlo, unlike GARCIA_BETA_ANCHORED
    # (IMPL-13). The "lnSDI2" entries are (upper - lower)/3.92 from the percentile
    # interval rather than the bootstrap standard deviation, because a small number of
    # bootstrap resamples separate under the quadratic and inflate the raw standard
    # deviation to order 1e13; the same normal-approximation-to-a-percentile-interval
    # device as ASSUMPTION A3 for the Garcia parameters, and disclosed the same way.
    "const":  {"intercept": 0.13107, "planted": 1.33202},
    "lnRD":   {"intercept": 0.21272, "planted": 1.02834, "b1": 0.11370},
    "lnSDI":  {"intercept": 0.72278, "planted": 1.17959, "b1": 0.12672},
    "lnSDI2": {"intercept": 4.31490, "planted": 0.42176, "b1": 1.46319, "b2": 0.12464},
    # Regular-interval frame. The `planted` standard deviation is order 7 in every form
    # here because only 41 of the 362 regular intervals are planted and a bootstrap
    # resample that draws no planted death separates; the point estimate and the
    # percentile interval in REG_MORT_CI95 are the usable summaries, and no origin
    # contrast fitted on this frame should be treated as identified.
    "const_reg":  {"intercept": 0.19898, "planted": 7.58127},
    "lnRD_reg":   {"intercept": 0.20150, "planted": 7.50651, "b1": 0.07476},
    "lnSDI_reg":  {"intercept": 0.50442, "planted": 7.41523, "b1": 0.07775},
    "lnSDI2_reg": {"intercept": 7.47724, "planted": 7.34941, "b1": 2.45239, "b2": 0.19899},
}
REG_MORT_CI95 = {
    # Plot-cluster bootstrap percentile intervals, reported with the coefficients.
    "const":  {"intercept": (-2.7104, -2.1893), "planted": (-2.9014, -1.0523)},
    "lnRD":   {"intercept": (-2.3888, -1.5594), "planted": (-2.2941, -0.6048),
               "b1": (0.2362, 0.6790)},
    "lnSDI":  {"intercept": (-7.0281, -4.2063), "planted": (-2.1494, -0.4812),
               "b1": (0.2689, 0.7626)},
    "lnSDI2": {"intercept": (-23.0767, -6.1623), "planted": (-1.8010, -0.1477),
               "b1": (0.6346, 6.3703), "b2": (-0.4851, 0.0035)},
    "const_reg":  {"intercept": (-3.8822, -3.1034), "planted": (-16.7061, -0.0155)},
    "lnRD_reg":   {"intercept": (-3.5698, -2.7594), "planted": (-16.3570, 0.1424),
                   "b1": (0.1447, 0.4468)},
    "lnSDI_reg":  {"intercept": (-6.3813, -4.3975), "planted": (-16.3362, 0.0789),
                   "b1": (0.1686, 0.4813)},
    "lnSDI2_reg": {"intercept": (-33.7205, -6.0874), "planted": (-16.2736, -0.0244),
                   "b1": (0.7254, 9.7880), "b2": (-0.7794, -0.0424)},
}
REG_MORT_FIT = {
    # Provenance of each fitted set. AIC is the binomial cloglog AIC on the frame named.
    "frame_all":     dict(source="_v83_build/build_pairs.py pairs_A_base.csv, all intervals",
                          n=421, n_plots=112, deaths=1389, tree_years=20870,
                          obs_tertile_meanSDI=(59.0, 310.9, 837.3),
                          obs_tertile_rate=(0.0223, 0.0509, 0.0887),
                          obs_rate_natural=0.07029, obs_rate_planted=0.02134,
                          AIC=dict(const=2590.62, lnRD=2410.95, lnSDI=2387.39, lnSDI2=2354.20)),
    "frame_regular": dict(source="_v83_build/build_pairs.py pairs_A_base.csv, irregular excluded",
                          n=362, n_plots=104, deaths=475, tree_years=15647,
                          obs_tertile_meanSDI=(52.1, 292.3, 832.2),
                          obs_tertile_rate=(0.0086, 0.0322, 0.0348),
                          obs_rate_natural=0.03159, obs_rate_planted=0.01921,
                          AIC=dict(const_reg=757.99, lnRD_reg=723.29, lnSDI_reg=718.18,
                                   lnSDI2_reg=691.45)),
}
REG_MORT_CLIP = (0.0, 0.25)
# CALIBRATION constant, NOT perturbed in the Monte Carlo (IMPL-13 category). Upper clip
# on the density-dependent background rate, chosen as a harness bound roughly twice the
# highest tertile rate in the fitting frame; the deployed lnSDI form reaches 0.135 at
# SDI 1,450 and 0.187 at SDI 3,000, so the clip does not bind anywhere inside the
# observed envelope and exists only to keep an extrapolated rate physical.
REG_MORT_SDI_MIN = 1.0
REG_MORT_RD_MIN = 1e-4
# CALIBRATION. Lower guards on the density argument, so ln of a vanishing density stays
# finite in the first projected year and in a collapsing stand. Both sit at or below the
# minimum observed in the fitting frame (SDI 0.25, RD 0.0001).

# --- Stage 1, irregular events. OPTIONAL stochastic hook, DEFAULT OFF ---------
STAGE1_ENABLED = False
STAGE1_RATE_PER_INTERVAL = 0.143             # 60 of 421 plot intervals
STAGE1_IRREG_THRESHOLD = 0.10                # annual cohort mortality that defines an irregular interval
STAGE1_OCCURRENCE_COEF = {"intercept": -3.970, "lnSDI": 0.377, "planted": -0.134, "lnYIP": 0.098}
# Logistic on ln SDI, origin and ln interval length, in-sample AUC 0.614
# (koa_mortality_3stage_FINAL_2026-09-04.R, Stage 1; run.log of job koa_mort3).
STAGE1_MAGNITUDE_MEDIAN = 0.32
STAGE1_MAGNITUDE_IQR = (0.16, 0.69)          # cohort fraction killed, n = 60 events
# No reported projection uses Stage 1. It is documented in the code and in the
# manuscript as not part of the deterministic projections.


# =============================================================================
# RETIRED 4 September 2026: the calibrated density ramp (Eq. 9 of v81).
#   annual mortality = base(origin) + MAXLIFT * frac, capped at MORT_MAX
#   frac = clip((SDI - ONSET_SDI) / (FULL_SDI - ONSET_SDI), 0, 1)
#   annual survival = 1 - annual mortality
# final/koa_survival_calibrated.R lines 481-553.
# The constants below stay DEFINED so that koa_survival_calibrated_py.py still
# evaluates the retired ramp for the comparison of record and the regression
# gate, and so that old scripts fail loudly (the projectors refuse a surv_fn
# unless mort_engine="ramp" is passed) rather than silently reviving it. The
# two origin backgrounds BASE_NAT and BASE_PLT are NOT retired: they are the
# A1 floor of the Garcia component.
# =============================================================================

BASE_NAT = 0.003
# final/koa_survival_calibrated.R line 482 (base_nat = 0.003). Density
# independent background annual mortality, natural origin.

BASE_PLT = 0.006
# final/koa_survival_calibrated.R line 482 (base_plt = 0.006). Density
# independent background annual mortality, planted origin. Lines 403-410 note
# the SIGN of the origin effect is disputed by the recovered data but the
# published ordering is retained because the published levels are retained, and
# lines 331-342 establish that the reversal is not a sentinel artifact and holds
# under both readings of the death records.

ONSET_SDI = 200.0
# RETIRED 4 September 2026 as a deployed constant (ramp withdrawn; see
# MORT_ENGINE). Kept defined for the retired arm only.
# final/koa_survival_calibrated.R line 490 (onset_sdi = 200). Absolute metric
# SDI, 79 imperial. Was 325 (= 0.65 * the withdrawn 500). 95 percent profile
# region 75 to 225 metric (lines 251-253). Lines 256-258 flag the onset as
# sample dependent: it moves to SDI 750 if sub-2.5 cm seedling records are
# left in. [UNKNOWN: onset location, to be revisited when the sub-2.5 cm
# records are adjudicated.]
# CONFIRMED 11 August 2026 and UNCHANGED. Profiling the three mortality levels
# out at every point of a 40 by 55 threshold grid on the standardised sample
# (4,141 records, 927 events, 15,432 tree-years, 48 installations) puts the
# maximum at exactly 200 and 850, reproducing the published profile region to
# the 25-unit grid step. The two-threshold shape also beats every alternative
# form: 3.9 units of Akaike information against a flexible logistic whose own
# optimum is a step, 9.9 against an explicit single-threshold step, 21.0 against
# a single-threshold ramp and 37.7 against a smooth monotone log-linear hazard.
# BUT the profile region is NOT a cluster-robust interval and must not be quoted
# as one. An installation-cluster bootstrap, 200 draws, puts onset anywhere from
# 100 to 700 and makes it BIMODAL at 200 and 700 with almost nothing between,
# which reproduces the sample dependence flagged above from resampling alone
# without touching the seedling screen. Describe the onset as bimodal, not as an
# interval.
# SELECTED JOINTLY with CF_DDBH_MARGINAL. See the note on that constant.

FULL_SDI = 850.0
# RETIRED 4 September 2026 as a deployed constant (ramp withdrawn). Kept
# defined for the retired arm only.
# final/koa_survival_calibrated.R line 493 (full_sdi = 850). Absolute metric
# SDI, 335 imperial. Was 425 (= 0.85 * the withdrawn 500). 95 percent profile
# region 800 to 925 metric (lines 253-254). This is the well identified
# threshold and is stable across samples (lines 254-256).
# QUALIFIED 11 August 2026, value UNCHANGED. "Well identified" is true of the
# profile and false of the cluster bootstrap, which puts full lift anywhere from
# 300 to 1000 and therefore straddles the onset 200 full lift 500 candidate.
# The point estimate lands at 800 or 900 in 139 of 200 draws, a real majority,
# and 73.0 percent of draws sit at or above 800 against 27.0 percent at or below
# 500, which is why the recommendation is not overturned. Quote BOTH intervals
# and label them. The choice between 850 and 500 does not rest on threshold
# uncertainty; it rests on calibration by density bin, where the 500 variant
# predicts 11.40 percent annual mortality in the 350 to 500 bin against an
# observed 5.39 percent on 1,909 tree-years, and on the joint verdict with
# CF_DDBH_MARGINAL. The 500 variant is rejected against these thresholds at a
# likelihood ratio of 33.8 on 2 degrees of freedom.

MAXLIFT = 0.15
# RETIRED 4 September 2026 as a deployed constant (ramp withdrawn). Kept
# defined for the retired arm only.
# final/koa_survival_calibrated.R line 498 (maxlift = 0.15). Maximum
# density dependent lift in annual mortality, reached at FULL_SDI.

MORT_MAX = 0.20
# RETIRED 4 September 2026 with the ramp; the Garcia rate carries no cap other
# than the physical bound 1 - N1/N0 <= 1.
# final/koa_survival_calibrated.R line 498 (mort_max = 0.20). Hard cap on
# annual mortality.
# [INERT AND HAZARDOUS. Flagged 11 August 2026, retained 12 August only because
# no deployed constant moves in the mortality component. BASE_PLT 0.006 plus
# MAXLIFT 0.15 reaches 0.156, so this cap can never act on the deployed ramp;
# maximum realised annual mortality is 0.156. It is live for exactly one
# candidate ever compared under it, the smooth log-linear hazard, where it binds
# above SDI 1,150 and silently converts a smooth form into a plateau. It was
# also observed BINDING on an alternative during the sentinel dual: under the
# non-sentinel reading B2 at the retired 878/1148 thresholds the sign-free lift
# lands at exactly -0.2, this boundary, against a grid check of -0.184.
# A cap that never acts on the deployed equation and quietly reshapes any
# alternative compared under it is a hazard, not a guardrail. Either delete it,
# or re-examine whether it binds before comparing ANY respecification under it.]

BAPH_REF = 42.0
# final/koa_survival_calibrated.R line 499 (baph_ref = 42); identical value at
# final/koa_ingrowth.R line 244. Units m2 ha-1. EXTERNAL anchor: the highest
# koa stand basal area published, Harrington, Fownes, Meinzer and Scowcroft
# 1995, Oecologia 102:277-284, doi 10.1007/BF00329794. Was 60, then 72, then
# 49; the 49 was the withdrawn 933 evaluated at Dq 30 cm and was circular.
# [UNKNOWN: the sampling variability of the 42 m2 ha-1 anchor; Harrington
# et al. report it as an observed maximum, not as an estimate with an
# interval. final/koa_survival_calibrated.R lines 96-98.]

QMD_REF_CM = 20.0
# final/koa_survival_calibrated.R line 508 (qmd_ref = 20); identical value at
# final/koa_ingrowth.R line 252. Diameter at which the basal area fallback is
# exact: 42 m2 ha-1 maps to SDI 934 metric (369 imperial) at Dq 20 cm.

MAXLIFT_MC_SE = 0.03
# RETIRED 4 September 2026. The Table 8 and Figure 8 Monte Carlo now perturbs
# GARCIA_ALPHA and GARCIA_BETA at GARCIA_SE_ALPHA and GARCIA_SE_BETA in place of
# the assumed lift SE. Kept for the retired arm only.
# Monte Carlo standard error used for maxlift in the Table 8 and Figure 8
# uncertainty propagation (figshare_v62/regenerate_table8_CI.py line 40,
# regenerate_fig8.py). Centralised here so MAXLIFT is not typed twice.
# [UNPROVENANCED: no standard error for maxlift appears in
# final/koa_survival_calibrated.R. The R source instead reports a 95 percent
# cluster bootstrap interval for the RE-ESTIMATED maxlift of 0.0393 to 0.1436
# around 0.0870 (line 568), which is not the interval this 0.03 encodes and
# does not bracket the deployed 0.15. Treat the Monte Carlo band on maxlift as
# an assumed sensitivity range, not a fitted standard error.]

MAXLIFT_MC_CLIP = (0.05, 0.25)
# figshare_v62/regenerate_fig8.py and regenerate_table8_CI.py clip the maxlift
# draw to this range. Unprovenanced, unchanged.

STAGE3_COEF = {'c0': -0.901059329975794, 'c1': -0.668917016326945, 'c2': -1.20293687663928, 'c3_lnRD': 0.101091640663181, 'c4_lnshareRD': 1.854166504258}   # M3a refit under SDImax_pop, koa_v105attr P_HT_HCB

ALLOC_BETA = 3.0
# final/koa_survival_calibrated.R line 727 (beta = 3; re-pinned 2026-08-19).
# Concentration of stand mortality onto small trees in koa.SURV.allocate.

ALLOC_MORT_CAP = 0.95
# final/koa_survival_calibrated.R lines 672 (renormalizer default) and 762
# (allocate pass-through; re-pinned 2026-08-19). Per-tree annual mortality cap.

ALLOC_MODE = "size"
# CHANGED 4 September 2026 from "tree_eq" to "size" with the Garcia component
# (Stage 3 of the specification of record): deaths are allocated by relative
# diameter only, w_i = exp(-ALLOC_BETA * (DBH_i/QMD - 1)), renormalised to the
# stand rate by renormalize_to_stand_rate. The memo of 4 September 2026 shows
# relative size orders deaths within plot at concordance 0.73 on the regular
# intervals. The Table 6 cloglog equation is NOT used anywhere in projection.
# The paragraph below is the 15 August 2026 record of the tree_eq decision it
# supersedes, kept visible as history.
# Allocation weight of record, ADOPTED 2026-08-15 (_ooda_20260815_standmort/).
#   "tree_eq"  weight = fitted Lineage A survivor equation annual mortality,
#              1 - koa_equations.LineageA.surv_annual(...), ratio-normalized so
#              the expansion-factor-weighted mean per-tree mortality equals the
#              stand rate exactly. The tree equation enters as ORDERING only;
#              its level, and the sentinel convention behind it, do not act.
#   "size"     the pre-2026-08-15 exp(-ALLOC_BETA*(DBH/QMD - 1)) size weight,
#              retained as the as-published control variant.
# The stand-level rate (BASE_NAT, BASE_PLT, ONSET_SDI, FULL_SDI, MAXLIFT) did
# NOT move. Basis: 23-plot validation, paired bootstrap vs the size weight:
# absolute BAPH error -0.811 m2 ha-1 (p 0.0004, 99.98 percent of resamples),
# absolute survivor QMD error -0.576 cm (p 0.112, 94.4 percent), cohort
# survival unchanged. Cohort-scale artifacts (Table 8, S11, Bakuzis) are
# unaffected because allocation does not act at cohort scale.
#
# CORRECTION 18 August 2026, two errors in the paragraph above. Both are left
# standing because the history is part of the record; read them as superseded.
#
# (1) The bootstrap figures quoted are the 15 August MORNING numbers and were
# superseded the same day by the survival coefficient vector fix, which this
# paragraph was never revised for. Reproduced twice independently on 18 August
# at 20,000 resamples, the 23-plot paired bootstrap against the size weight
# gives absolute QMD error -1.25766 cm (p 0.0000, 100.000 percent of resamples)
# and absolute BAPH error -0.90026 m2 ha-1 (p 0.0009, 99.955 percent). The
# direction and the decision are unchanged; the magnitudes are larger, and the
# QMD result, which read as not significant at p 0.112, is now the stronger of
# the two rather than the weaker.
#
# (2) "Cohort-scale artifacts (Table 8, S11, Bakuzis) are unaffected because
# allocation does not act at cohort scale" is true only of the EVEN-AGED rows.
# Those run through koa_projector.project_cohort, which carries no tree list and
# never reaches the allocator. The UNEVEN-AGED rows of Table 8 and of Table S11
# run through project_psp with surv_mode="calib_alloc" and ingrowth on
# (figshare_v62/regenerate_uneven_aged.py line 59, and the S11 producer in
# _ooda_20260808_figs11/), so every one of those rows is allocator sensitive.
# Measured 18 August: 15 of 45 S11 rows and 105 of 315 cells move with the
# allocation weight. The Bakuzis input is built from the cohort engine and is
# genuinely unaffected, so only the S11 and Table 8 half of the claim is wrong.

ALLOC_MODE_AS_PUBLISHED = "size"
# The allocation weight every artifact published before 2026-08-15 used,
# including the as-published Table 8 control chain and FigS9 as deposited.

ALLOC_RENORMALIZE = True                # deployed, 2026-08-18
ALLOC_RENORMALIZE_AS_PUBLISHED = False  # every artifact published before 2026-08-18
# Whether the per-tree allocation is rescaled so that the expansion-factor-
# weighted mean per-tree mortality equals the stand rate AFTER the
# ALLOC_MORT_CAP clip, rather than only before it.
#
# The defect, found 18 August 2026. The allocator forms
# m_i = clip(m_stand * w_i / wbar, 0, ALLOC_MORT_CAP), with wbar the
# expansion-factor-weighted mean weight. Before the clip that construction is
# exact by algebra: the weighted mean of m_i is m_stand identically, whatever
# the weights are. After the clip it is not. Every tree pushed down onto the cap
# loses the mortality above it and nothing picks that mortality up, so the stand
# delivers LESS mortality than the stand-level equation prescribed, silently and
# without any diagnostic. The constraint was asserted in three places, the
# ALLOC_MODE block above, the allocate() docstring in
# koa_survival_calibrated_py.py and the project_psp commentary in
# koa_projector.py, and enforced in none of them. Measured 18 August on the
# uneven-aged scenario as delivered over prescribed stand mortality, summed over
# 100 years. Under ALLOC_MODE "tree_eq" the Medium site delivers 0.8477 of what
# was prescribed, a 15.2 percent cumulative loss, short in 39 of 100 years, with
# a worst year at 0.2989; Low and High deliver 1.0000 because the cap never
# binds there at all. Under the as-published "size" weight every site loses
# something: 0.9996 at Low, 0.9946 at Medium and 0.9913 at High, so 0.04 to
# 0.87 percent cumulatively, with a worst single year at 0.9400. The size-mode
# loss is small but it is not zero, which is why the as-published switch below
# is needed rather than optional.
#
# The fix, R1. Solve for the scalar lambda >= 0 satisfying
#   sum_i expf_i * min(lambda * m_stand * w_i / wbar, cap) / sum_i expf_i
#       == m_stand
# and allocate at lambda rather than at 1. The left side is continuous,
# non-decreasing in lambda, equals 0 at lambda = 0 and tends to cap as lambda
# grows without bound, so a root EXISTS IF AND ONLY IF m_stand < cap. That is
# the entire feasibility condition, and it is not an artifact of the solver: the
# cap is a ceiling on every individual tree, so no allocation of any shape can
# deliver a stand rate at or above it. On the uneven-aged scenario the condition
# holds everywhere it was checked on 18 August: in all 300 point-estimate
# site-years and in all 90,300 site-years of the full 300-replicate
# regeneration, both allocation modes, where the largest stand rate reached is
# 0.153 against a cap of 0.95. The solve takes 40 to 48 iterations of bracketing
# plus bisection at the deployed tolerance. When feasibility does fail, the
# allocator puts every tree at the cap and warns, naming the stand rate, instead
# of returning a shortfall that looks like a result.
# Where the cap does not bind, lambda = 1 is already the exact root, and
# koa_survival_calibrated_py.renormalize_to_stand_rate detects that case and
# returns the unrescaled clip, so those stands are bitwise identical to the
# pre-18 August code. Only stands where the cap actually binds move at all.
#
# Setting ALLOC_RENORMALIZE = False restores the as-published behaviour exactly,
# lost mortality and all, which is what ALLOC_RENORMALIZE_AS_PUBLISHED names.
# It has to exist because R1 moves the deposited "size" mode numbers slightly,
# and the deposit must keep the ability to reproduce its own published artifacts
# as a live regeneration rather than a frozen fixture. Latest member of the
# as-published set, beside ALLOC_MODE_AS_PUBLISHED, CF_DDBH_AS_PUBLISHED,
# SDI_OF_EXPONENT_AS_PUBLISHED and DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM.
# NOTHING IN THE PRODUCTION PATH MAY READ ALLOC_RENORMALIZE_AS_PUBLISHED.
# The single carrier of the algebra is
# koa_survival_calibrated_py.renormalize_to_stand_rate. allocate() and the
# calib_alloc branch of koa_projector.project_psp both call it, and neither
# reimplements it; a second copy of this solve is a defect, not a convenience.


# --- Re-estimated survival LEVELS. NOT the defaults. --------------------------
# final/koa_survival_calibrated.R lines 555-569. Maximum likelihood on the
# recovered variant (ii) survival data, DBH >= 2.5 cm, 95 percent cluster
# bootstrap over installation (435 of 500 replicates retained). Do NOT enable
# until the sentinel death-recording convention is resolved AND ingrowth is
# active in HiGy.R (lines 294-311, 563-564). Lines 313-320 record that these
# three levels are the maximum likelihood estimate at the deployed thresholds
# and reproduce across two independent implementations, and lines 322-329 record
# the concrete reason not to enable them, which is the Bakuzis matrix and not
# the ingrowth wiring.
LEVELS_RECOVERED = {
    "base_nat_recovered": 0.0384,   # line 566; 95% CI 0.0142 to 0.0510
    "base_plt_recovered": 0.0142,   # line 567; 95% CI 0.0000 to 0.0218
    "maxlift_recovered": 0.0870,    # line 568; 95% CI 0.0393 to 0.1436
}
LEVELS_RECOVERED_CI = {
    "base_nat_recovered": (0.0142, 0.0510),   # line 566
    "base_plt_recovered": (0.0000, 0.0218),   # line 567
    "maxlift_recovered": (0.0393, 0.1436),    # line 568
}


# =============================================================================
# Ingrowth: the equation of record.
#   E[ingrowth, trees ha-1 yr-1] = exp(B0 + B_SDI*SDI + B_PLANTED*planted)
#   optionally multiplied by (max(byi,1)/BYI_REF)**byi_c, then capped at CAP.
# final/koa_ingrowth.R lines 159, 225-292.
# =============================================================================

ING_B0 = 3.383783   # v103 refit 2026-09-30
# final/koa_ingrowth.R line 232 (b0 = 5.3836); equation at line 159.

ING_B_SDI = -0.005379672   # v103 refit 2026-09-30
# final/koa_ingrowth.R line 233 (b_sdi = -0.0061866). Fitted slope per unit of
# ABSOLUTE SDI. Line 115 gives its derivation, -3.0933 / 500, and lines 113-126
# establish that this is the invariant quantity the model was fitted on: the
# RD-scale coefficient b_rd = b_sdi * SDImax, so the product b_rd * RD collapses
# to b_sdi * SDI identically for any SDImax.

ING_B_PLANTED = 1.639832   # v103 refit 2026-09-30
# final/koa_ingrowth.R line 242 (b_planted = -1.6359). Rate ratio 0.195,
# p = 0.029 (line 182): plantations recruit about 5x less, managed and weeded.

ING_BYI_DEFAULT = 264.0
# final/koa_ingrowth.R line 243 (byi = 264).

ING_BYI_C_DEFAULT = 0.0
# final/koa_ingrowth.R line 243 (byi_c = 0). Zero disables the OPTIONAL,
# UNTESTED BYI multiplier (line 188). BYI is not in the fitted model: no BYI
# main effect (p = 0.28) and no BYI by RD interaction (p = 0.56), lines 183-187.

ING_BYI_REF = 390.0
# final/koa_ingrowth.R line 243 (byi_ref = 390). Only used when byi_c != 0.

ING_CAP = 160.0
# final/koa_ingrowth.R line 243 (cap = 160), trees ha-1 yr-1.
# [UNPROVENANCED: the R source carries this cap and line 170 reports ingrowth
# "falls from the cap of 160 trees ha-1 yr-1 in the open, against an uncapped
# intercept prediction of 217.9", but NO derivation, fit, citation or data
# source for the value 160 appears anywhere in final/koa_ingrowth.R or in
# final/koa_survival_calibrated.R. It is carried forward unchanged because it
# is in the equation of record and it binds in the open-grown range, but its
# provenance is unknown and it must not be described as fitted.]

ING_RECRUIT_DBH_CM = 2.5
# final/koa_ingrowth.R line 195 and line 297 (dbh = 2.5). Threshold diameter
# at which recruits enter the tree list.

# --- Reference evaluations of the ingrowth equation of record, for checking ---
# final/koa_ingrowth.R lines 168-181. At SDI 340 metric (134 imperial) the
# equation gives 26.6 trees ha-1 yr-1 natural and 5.2 planted. The figure of 13
# trees ha-1 yr-1 previously attached to SDI 340 is WRONG and was corrected in
# the R source: 13 natural corresponds to SDI 456 metric (180 imperial).
# [UNKNOWN: no quasi-Poisson vcov or dispersion scale was retained from the
# source fit, so 26.6 and 5.2 are exact evaluations of the fitted equation and
# cannot presently be given a prediction interval. Line 188-193.]
ING_REFERENCE_POINTS = {
    ("sdi340", "natural"): 26.6,
    ("sdi340", "planted"): 5.2,
    ("13_trees_natural_at_sdi", None): 456.0,
    ("uncapped_intercept", "natural"): 217.9,
}


# =============================================================================
# The diameter-conditional density bound that REPLACES the withdrawn scalar.
# final/koa_survival_calibrated.R lines 87-107 and 626-629;
# final/koa_ingrowth.R lines 64-77 and 218-223. Obtained by converting the
# external 42 m2 ha-1 anchor through the Reineke identity. Quote the bound at
# the diameter the stand is actually at; do not quote a scalar.
# =============================================================================

BOUND_SDI_BY_QMD = {
    20.0: 934.0,   # metric, 369 imperial; R survival line 103, ingrowth line 75
    30.0: 796.0,   # metric, 314 imperial; R survival line 104, ingrowth line 75
    50.0: 651.0,   # metric, 257 imperial; R survival line 104, ingrowth line 76
}


def bound_sdi(qmd_cm):
    """Diameter-conditional maximum SDI implied by the 42 m2 ha-1 anchor.
    Reproduces BOUND_SDI_BY_QMD to the rounding in the R header."""
    return BAPH_REF / (KR * float(qmd_cm) ** DQ_EXPONENT)


# What the koa literature independently supports, retained for reporting.
# final/koa_survival_calibrated.R lines 109-123; final/koa_ingrowth.R 79-87.
LITERATURE_SDI_RANGE = (500.0, 650.0)          # metric; 197 to 256 imperial
LITERATURE_ALINE_BAKER_SCOWCROFT_2005 = (440.0, 530.0)   # metric; 175 to 210
LITERATURE_SELFTHIN_SCOWCROFT_2008 = 595.0     # metric; 235 imperial


# =============================================================================
# Projector density constants. These live here so the retired 500 has no
# remaining foothold in koa_projector.py.
# =============================================================================

SDI_OF_EXPONENT = REINEKE_EXPONENT
# CHANGED 12 August 2026 from the deposited 1.6 to REINEKE_EXPONENT, 1.605.
# figshare_v62/koa_projector.py line 28 as deposited computed sdi_of as
# tph * (qmd/25)**1.6, which is not the quantity the ramp thresholds are stated
# on. The 7 August note that stood here retained 1.6 deliberately, so that the
# 6 August pass would change exactly one thing, the mortality ramp, and so that
# the before and after comparison of the ramp fix would not be confounded. It
# also recorded that switching to REINEKE_EXPONENT is a separate, deliberate
# decision that will move every projected trajectory and must be made
# explicitly. This IS that decision, made explicitly on 12 August as part of a
# single propagation pass that also moves the diameter increment correction
# factor, so that the downstream artifact set regenerates once rather than
# twice.
# The grounds are unchanged from the 7 August note. The equation of record
# specifies 1.605 for the stand SDI a caller feeds the ramp, and
# final/koa_survival_calibrated.R lines 796-812 state explicitly that 1.6 is
# wrong and why: the ramp thresholds, the Reineke identity used for the basal
# area fallback and the diameter-conditional bound are all stated on the 1.605
# scale, so an SDI computed on the 1.6 scale is not the same quantity. The two
# agree exactly at Dq 25 cm and diverge by (Dq/25)**0.005, about 0.46 percent
# low at Dq 10 cm and 0.44 percent high at Dq 60 cm, roughly one SDI unit of
# silent offset at the ramp onset.
# This is now an alias rather than a literal, on purpose: the two quantities are
# the same Reineke exponent and a future re-estimation must move them together.
# Table S11 was held on this divergence and on the increment calibration, and
# both are settled in this pass, so it regenerates once.

SDI_OF_EXPONENT_AS_PUBLISHED = 1.6
# WITHDRAWN 12 August 2026 as a deployed value, retained ONLY so that the
# as-published control variant of Table 8 can be pinned to it and remain a live
# regeneration rather than a frozen fixture. Companion to
# CF_DDBH_AS_PUBLISHED, and added for the same reason.
# PROMOTED HERE 12 August after the Table 8 driver track found a third
# inheritance the propagation specification had missed. The specification named
# the correction factor, and verification then added the planted truncation, and
# this is the third: koa_projector.sdi_of reads SDI_OF_EXPONENT at call time, so
# moving it from 1.6 to 1.605 shifts the stand density index fed to the survival
# function of EVERY variant including the as-published control. Variant A runs
# koa_survival_calibrated_py_PREV_20260807, whose ramp is linear in SDI/500
# between 0.65 and 0.85, so a shift of (Dq/25)**0.005, about 0.2 percent near
# Dq 40 cm, lands directly on a live ramp and perturbs mortality, hence stems
# per hectare, hence every value column of the control.
# So the as-published pin is a TRIPLE and not a single constant: the correction
# factor at CF_DDBH_AS_PUBLISHED, the planted truncation active at 40 cm, and
# this exponent at 1.6. Any future control variant must pin all three.
# NOTHING IN THE PRODUCTION PATH MAY READ THIS.

GUARDRAIL_TRIGGER_SDI = 300.0
# figshare_v62/koa_projector.py line 62 as deposited: the operational
# self-thinning guardrail fires when SDI / 500 exceeds 0.60, i.e. at absolute
# SDI 300. Restated in absolute SDI so the withdrawn 500 does not have to be
# reintroduced to evaluate it. Numerically identical to the deposited form.
# [UNPROVENANCED: no derivation for the 0.60 trigger appears in either R
# equation of record. It is an operational guardrail inherited from
# koa_projection.py, not a fitted quantity, and it is DORMANT whenever
# project_cohort is called with surv_fn set, which is how every consumer in
# this deposit calls it.]

GUARDRAIL_TARGET_SDI = 275.0
# figshare_v62/koa_projector.py line 63 as deposited: the guardrail thins to
# 0.55 * 500 = absolute SDI 275. Same provenance note as above.

GUARDRAIL_DBH_EXPONENT = 0.08
# figshare_v62/koa_projector.py line 64 as deposited: the diameter response to
# the guardrail thinning, (TPH/TPH_new)**0.08. Unprovenanced, unchanged.

FORM_FACTOR = 0.40
# figshare_v62/koa_projector.py line 27 as deposited: V = BAPH * meanHT * FF.
# Not a survival or ingrowth constant; centralised here only so the projector
# has one place to read numbers from.


# -----------------------------------------------------------------------------
# BASAL AREA IN LARGER TREES. ONE CONCEPT, TWO EVALUATION PATHS.
# Added 8 September 2026, deposit 1.6.0. The deposit previously carried FOUR
# distinct BAL constructions at eleven sites (RT-F, 7 September 2026, section 1).
# The concept of record is the one the dDBH, dHT and HCB coefficients were fitted
# on, namely stand basal area allocated by the subject stem's diameter percentile
# within the plot-year,
#
#     BAL = (1 - BA.perc) * BAPH,
#     BA.perc = (rank(DBH, ties.method = "min") - 1) / (n - 1)
#
# taken over EVERY record in the plot-year, dead and zero-diameter placeholders
# included, unweighted (RT-D, 7 September 2026, which reproduces the deposited
# column to 1e-6 on 96.0335 percent of the rows in the complete plot-years).
# koa_equations.stand_bal is the single carrier of that concept and it has two
# evaluation paths, selected by what the caller can see rather than by preference.
#
# EXACT PATH, taken whenever a real record set exists (project_psp, AK_SURV.r, the
# fitting pipeline). The percentile is computed directly on the record set. This
# REPLACES the conventional cumsum construction that project_psp carried at its
# line 254, which RT-F measured at 1.4 to 3.5 percent in predicted annual increment.
#
# COHORT PATH, taken when only QMD and TPH exist (project_cohort). The cohort
# carries no diameter distribution and no record set, so the fraction is predicted
# directly from cohort state by the linear mean-stem function below. It is fitted
# on the deposited BAL / BAPH carried by stems sitting within five percent of the
# stand quadratic mean diameter, over the 393 complete plot-years of AK.TREE.csv
# that carry at least five positive-diameter stems and at least one such stem, and
# it is validated by grouped ten-fold cross-validation on plot identity rather than
# on rows.
#
# WHY QUADRATIC MEAN DIAMETER ALONE AND NOT DIAMETER AND STEM DENSITY. Both forms
# were fitted side by side on the same 393 plot-years and cross-validated under
# IDENTICAL grouped folds, repeated over 500 independent fold draws so that the
# comparison could be read against its own Monte Carlo noise rather than against a
# single draw. Held-out root mean squared error is 0.143101 for the diameter-only
# form and 0.143705 for the two-term form, and the PAIRED difference, which is the
# quantity the fold noise cancels from, is +0.000605 with a Monte Carlo standard
# deviation of 0.000324 and a 2.5 to 97.5 percentile interval of +0.000134 to
# +0.001324. The interval excludes zero and the diameter-only form measures better
# on 499 of 500 draws, so the density term costs held-out accuracy rather
# than buying it. It was also not significant, at a plot-clustered t of 0.511 and
# a classical nested F p of 0.4982, yet THE DECISION WAS TAKEN ON THE MEASURED
# HELD-OUT ERROR AND NOT ON THE t. The margin is small in absolute terms, about
# 0.0006 in a fraction whose target has a standard deviation of 0.15011, so the
# parsimonious form would have been taken on a tie in any case.
#
# TWO OTHER ALTERNATIVES WERE COSTED AND REJECTED, and all three are declared below
# rather than dropped. A measured constant at the conditional mean (RT-H option one)
# measures a held-out RMSE of 0.15071 on the canonical draw. A two-parameter Weibull
# whose scale is pinned by QMD and whose shape is predicted from cohort state (RT-I)
# measures 0.14590, and its fitted calibration slope came out at -1.82156, meaning
# the raw distributional quantity moves the wrong way against the target and a
# coefficient reverses it.
#
# THE DEPLOYED CONSTANT THIS REPLACES WAS A BOUNDARY ERROR. project_cohort set
# BAL_avg = BAPH * bal_fraction(1.0) = 0.10774 * BAPH. bal_fraction was fitted on
# rDBH = DBH / DBH.max and not on DBH / QMD as three places in this deposit stated,
# verified at 100.00000000 percent against 36.401 percent, so rDBH = 1.0 denotes the
# LARGEST stem of a real plot-year and the 743 stems sitting there carry an observed
# BAL / BAPH of exactly 0.000000. The average stem carries 0.34762. NO FITTED
# COEFFICIENT OF THE dDBH, HEIGHT, HCB, SURVIVAL OR MORTALITY ARMS MOVES WITH THIS
# CORRECTION, and the harness diameter ceilings are unchanged at 60 and 90 cm.
# -----------------------------------------------------------------------------

COHORT_BAL_MODES = ("linear", "linear_qmd_tph", "constant", "deployed_boundary")
COHORT_BAL_MODE = "linear"
# "linear": the deployed cohort path, BAL_COHORT_LIN_B below, a function of
# quadratic mean diameter alone.
# "linear_qmd_tph": BAL_COHORT_LIN2_B below, the two-term form carrying a stem
# density term. Costed against the deployed form under identical grouped folds and
# NOT adopted, since it measures worse held out. Retained as a declared sensitivity
# arm so the comparison in the release record can be reproduced.
# "constant": BAL_COHORT_CONSTANT below, the measured conditional mean. The simplest
# alternative that was costed alongside and NOT adopted.
# "deployed_boundary": the pre-correction BAPH * bal_fraction(1.0). RETAINED for the
# exact-restoration regression check and for reproducing the as-published Table 8,
# Figure 8, Table S14 and Bakuzis input. It must never be used in production.

BAL_COHORT_LIN_B = (0.447031313529582, 0.0003371884737382)   # live list percentile fraction, cohort_bal_fraction_v103.csv row v103/l, 2026-09-30
# fraction = a0 + a1 * ln(QMD). Ordinary least squares on the 393 complete
# plot-years, in-sample R2 = 0.10897, residual sd = 0.14170. Standard errors
# clustered on the 107 distinct plot identities, since plots are remeasured:
#   a0  0.52636827  se 0.03018068  t 17.44
#   a1  -0.06766300  se 0.01151984  t -5.87
# Classical standard errors are 0.02682162 and 0.00978473.
# Both terms are firm. The diameter term carries the whole of the signal and it
# carries it in the physically sensible direction, since a stand whose average stem
# is large has fewer stems above that average.

BAL_COHORT_LIN2_B = (0.4694419148154744, -0.06409816504209419, 0.007168615537578263)
# fraction = a0 + a1 * ln(QMD) + a2 * ln(TPH), the REJECTED two-term arm, read only
# when COHORT_BAL_MODE is "linear_qmd_tph". In-sample R2 = 0.11002, residual sd =
# 0.14162. Its density term carries a plot-clustered t of 0.511. Held out under
# identical grouped folds it measures 0.143705 against 0.143101 for the deployed
# form. Retained so the comparison is reproducible from the deposit rather than only
# from the release record.

BAL_COHORT_LIN_BOUNDS = (0.0, 1.0)
# The fraction is clipped to the unit interval as a guard. IT NEVER BINDS. No
# held-out prediction in the cross-validation fell outside the interval on any of
# the 500 fold draws, and the release record states the raw range the function
# takes over the deployed trajectories. A linear function on the RAW rather than the
# logged diameter would have gone negative inside the projector's own state range,
# which is why the logged form is deployed.

BAL_COHORT_LIN_CALIB_RANGE = (0.865406593127515, 69.6786879496591, 26.22, 8184.0)
# QMD low, QMD high, TPH low, TPH high over the calibration set, in cm and
# trees ha-1. The stem density limits are declared even though the deployed function
# does not read stem density, both because the two-term arm above does and because
# the calibration set is one set. Declared so that any use outside it is visible as
# extrapolation. The release record states the fraction of projection steps that fall
# outside it and the ages at which they do.

BAL_COHORT_CONSTANT = 0.34761721720798644
# The deposited BAL / BAPH carried by stems within five percent of the stand quadratic
# mean diameter, averaged over the same 393 complete plot-years, standard error
# 0.00757. Corroborated at 0.34595 on 872 rows of dDBH.csv (RT-F), 0.34305 on 1,275
# rows of AK.TREE.csv and 0.346872 from the logistic at the mean QMD / DBH.max (RT-V).
# Read only when COHORT_BAL_MODE is "constant".

PSP_BAL_MODES = ("percentile", "cumsum")
PSP_BAL_MODE = "percentile"
# 30 September 2026 (v103, red team A1A2 finding 1): the exact path percentile is weighted by expf so
# that decayed records do not stay in the rank; with equal expf it equals the unweighted rule of record.
# False reproduces engine_v102 and the pre-fix engine_v103 exactly.
BAL_PERCENTILE_WEIGHTED = True
# "percentile": the exact path, the fitted concept. "cumsum": the pre-correction
# conventional size-weighted np.cumsum(ba) - ba, retained for the same regression
# check and for reproducing the as-published uneven-aged rows and Figure S9.


# -----------------------------------------------------------------------------
# HARNESS BOUNDS. Added 7 August 2026 when the split-engine deliverables were
# rebuilt. These are guardrails of the stand-level cohort harness, not estimated
# parameters of any equation, and none of them appears in
# final/koa_survival_calibrated.R or final/koa_ingrowth.R. They are centralised
# here because they were hardcoded in koa_projector.py and typed a second time in
# _zenodo_restage_20260807/gates_interval_and_input.py, which is the duplication
# the 7 August audit flagged as the unclosed half of F9. Any consumer that
# reports a bound, releases a bound, or gates on a bound reads it from here.
#
# UNPROVENANCED. Every value below is a harness convention with no citation in
# the equations of record. They must never be reported as model behaviour, and a
# deliverable that sits on one is reporting the bound, not the projection. That
# is exactly the defect that put the diameter cap into the published Table 8
# confidence limits.
# -----------------------------------------------------------------------------

HARNESS_DBH_MAX_NATURAL_CM = 90.0
HARNESS_DBH_MAX_PLANTED_CM = 69.7   # raised 2026-09-16 to the observed maximum QMD
# figshare_v62/koa_projector.py as deposited: dbh_max = 60.0 if planted else 90.0,
# applied in project_cohort and as the default dbh_max of project_psp.

HARNESS_HT_BLEND_DYNAMIC = 0.65
HARNESS_HT_BLEND_STATIC = 0.35
# figshare_v62/koa_projector.py as deposited: HT = 0.65*HT_dynamic + 0.35*HT_static,
# where HT_static is predict_HT at the current diameter.

HARNESS_HT_CEILING_INTERCEPT_M = 25.0
HARNESS_HT_CEILING_BYI_DIVISOR = 55.0
# figshare_v62/koa_projector.py as deposited: HT = min(HT, 25 + BYI/55). At the
# three deposited site levels this is 26.82, 29.80 and 33.18 m.

HARNESS_HT_MAX_PSP_M = 92.0 * 0.3048
# figshare_v62/koa_projector.py as deposited: ht_max default of project_psp,
# 92 feet expressed in metres, 28.0416 m.

HARNESS_TPH_COLLAPSE = 5.0
# figshare_v62/koa_projector.py as deposited: below 5 trees per hectare the
# cohort record is held flat to the end of the horizon rather than projected.

HARNESS_INIT_DBH_NATURAL_CM = 8.0
HARNESS_INIT_DBH_PLANTED_CM = 6.0
HARNESS_INIT_TPH_NATURAL = 500.0
HARNESS_INIT_TPH_PLANTED = 1200.0
# figshare_v62/koa_projector.py as deposited, project_cohort defaults. These are
# the starting conditions of every published even-aged row in Table 8 and every
# even-aged panel of Figure 8, and until 7 August 2026 they had no single
# definition anywhere in the deposit. That is worse than a duplicated literal:
# gate 1 constraints K4 and K5 cite these numbers as their authority, so the
# authority for two gates was a default argument nothing declared. Unprovenanced
# harness conventions, like the bounds above.

def harness_init_dbh(planted):
    """Starting diameter of the stand-level cohort harness, cm."""
    return HARNESS_INIT_DBH_PLANTED_CM if planted else HARNESS_INIT_DBH_NATURAL_CM


def harness_init_tph(planted):
    """Starting stocking of the stand-level cohort harness, trees ha-1."""
    return HARNESS_INIT_TPH_PLANTED if planted else HARNESS_INIT_TPH_NATURAL


HARNESS_BOUNDS = ("dbh_cap", "ht_ceiling", "ht_blend")
# The three releasable bounds of project_cohort, in the order used by the
# Table 8 variant accounting. Variant of record D releases dbh_cap only.

def harness_dbh_max(planted):
    """Diameter cap of the stand-level cohort harness, cm."""
    return HARNESS_DBH_MAX_PLANTED_CM if planted else HARNESS_DBH_MAX_NATURAL_CM


def harness_ht_ceiling(byi):
    """Height ceiling of the stand-level cohort harness, m."""
    return HARNESS_HT_CEILING_INTERCEPT_M + byi / HARNESS_HT_CEILING_BYI_DIVISOR


HARNESS_HT_MONOTONE = True
# MONOTONE HEIGHT GUARD, ADDED 8 September 2026 (deposit 1.7.0). A HARNESS GUARDRAIL, on
# exactly the footing of the diameter ceiling above it and the height ceiling beside it:
# unprovenanced, never to be reported as model behaviour, and DECLARED PER CELL wherever a
# reported value sits on it.
#
# WHAT IT DOES. Within one trajectory it carries the running maximum mean height forward,
# so the REPORTED height series is non-decreasing in age. Applied by
# koa_projector.ht_monotone_guard, in the harness bounds block beside the height ceiling,
# and by the uneven-aged producers through that same one function.
#
# WHAT IT DOES NOT DO, AND THIS IS THE WHOLE OF WHAT MAKES IT DEFENSIBLE. It does NOT touch
# predict_HT and it moves no fitted coefficient. THE STATIC HEIGHT EQUATION STILL TURNS
# OVER: evaluated beyond roughly a stand quadratic mean diameter of 87 cm with a basal area
# beyond roughly 83 m2 ha-1 it returns a SMALLER mean height than at a smaller stand. That
# is a real property of the fitted surface, it stays in the equation, and it is stated in
# SOURCE_OF_TRUTH.md, in INTEGRITY_REPORT.md and in DEPOSIT_CHANGELOG.md. What changes is
# that the harness no longer PRINTS a falling mean height as though it were a projection.
# A guard that is disclosed is a guardrail; a guard that is silent is a fabrication, so
# every carrier that reports a guarded height also reports where the guard bound.
#
# WHY IT EXISTS, MEASURED ON THIS ENGINE AND NOT INHERITED. Replaying each Table 8 variant's
# own Monte Carlo draw stream over 12,000 replicate trajectories on 8 September 2026:
#   W_qmd_anchored_bounded (DEPLOYED)   275 of 3,000 replicates carry a falling height step,
#                                       all in the natural rows (44, 101 and 130 of 500 at
#                                       BYI 100, 264 and 450; every planted cell 0 of 500),
#                                       worst single-step fall 0.009308 m, and ZERO falling
#                                       steps on all six point estimates.
#   W_qmd_anchored_dbh_released         497 of 3,000.
#   G_garcia_bounded (C2, evaluated)    1,214 of 3,000, and 56 and 72 falling steps on the
#                                       POINT ESTIMATES at natural Medium and natural High,
#                                       worst 0.071957 m.
#   R_ramp_bounded_v81 (as-published)   0 of 3,000. The retired ramp never produces it, so
#                                       the turnover is a property of the state space the
#                                       Garcia-family arms visit and not of the height
#                                       equation alone.
# The consequence reached the deposit: Table8_CI_variants_20260906.csv carried FIVE
# non-monotone height series in the C2 arm, including a falling published UPPER limit,
# HT_hi at Even-aged natural Medium (264) reading 14.97, 15.05, 15.00, 15.04 across ages
# 20, 40, 60 and 100. Gate C5 does not read that file (INTEGRITY_REPORT.md, D5), which is
# why it went undetected.
#
# IT IS NOT ONE OF THE THREE RELEASABLE BOUNDS. HARNESS_BOUNDS stays
# ("dbh_cap", "ht_ceiling", "ht_blend") and the Table 8 release accounting is unchanged,
# because a fourth releasable bound would change the meaning of the `released` column of
# every deposited row including the as-published control. The guard is switched by THIS
# flag, and its binding is declared through the bounds_reported token "ht_monotone", the
# pct_HT_at_guard column of the variants diagnostic, and the ht_guard columns of
# uneven_aged_traj.csv and TableS14_point_estimates.csv.


# =============================================================================
# Diameter and height increment: coefficients, correction factors and bounds.
# ADDED 12 August 2026. These were previously typed independently in five files
# (koa_equations.py, HiGy.R, koa_prediction_functions.R,
# WeiskittelKoaGy_2026_03_27.r and the ddbh.parm tribble) and were in no
# central place at all, despite F9 having been closed on the claim that every
# harness bound and constant was centralised here. A calibration constant that
# has to be edited in five places will diverge, which is exactly the recorded
# history of CF_dDBH = 1.026.
#
# THE COEFFICIENTS DO NOT MOVE AND THE CORRECTION FACTOR DOES. Every fixed
# effect below is the deployed vector transcribed unchanged, so manuscript
# Table 4, Supplemental Table S1 and gate 1 of verify_reproducibility.R all
# continue to pass. The entire 12 August increment calibration is one constant.
# =============================================================================

# --- Correction factors -------------------------------------------------------

CAL_DDBH = (0.23596, 0.76421)   # c / CF of dDBH_L_NO K3c1 under SDImax_pop (c = 0.37248, 1.20637), koa_v105attr
CAL_DHT = (0.17573, 1.21046)   # c / CF of dHT_L_NO (c = 0.42100, 2.89985), koa_v105attr
CAL_DDBH_SE_LOG = (0.20117, 0.09132)   # SD of log c, 400 installation-cluster resamples within source, full refit of dDBH_L_NO K3c1, v105final
CAL_DHT_SE_LOG = (0.12866, 0.07454)   # SD of log c, vector fixed (full refit bootstrap: 0.579, 0.511), dHT_L_NO K3c1h, v105final
CAL_MC_SEED = 20260916
MORT_CAL = (2.43532, 1.0)   # natural level re-solved on engine v105d (v105c + RD x competition in dHT, Eq. 2, Eq. 3, Stage 3), PSP 122 2019-2023 excluded, 2026-11-02
MORT_CAL_SE_LOG = (0.16150, 0.0)   # plot-cluster bootstrap SD of log k, v105d
MORT_CAL_MC_SEED = 20260917
MORT_CAL_LIVE = list(MORT_CAL)   # live value, reset and perturbed by koa_equations.cal_reset / cal_draw
# v105c (2026-11-02): dDBH competition form switch. "v105b" = b3 BAL^2/ln(DBH+5) + b4 ln(BAL+1) + b6 sqrt(BAPH DBH);
# "K3c1" = b4 ln(x+1) + b6 sqrt(RD DBH), x = (BAL/BAPH) RD, RD = SDI/923 (SDI = TPH (QMD/25.4)^1.605, live list, each annual step),
# b3 = 0 (koa_rdcomp_20261102/constrained/PREREG_K3c.md, adopted).
DDBH_FORM = "K3c1"   # v105c deployed form (PREREG_K3c adopted); "v105b" restores the v105b competition terms
DDBH_RD_SDIMAX = 741.996871565   # brms RI_LONG population SDImax at QMD 25.4 cm, posterior median of per-draw exp(b0 + b1 log 25.4) (koa_v105attr_20261103 prep/out/sdimax_pop.csv)
DDBH_RD_INDEX_DIAMETER_CM = 25.4   # Reineke index diameter of the fitted SDI (fit frames), not INDEX_DIAMETER_CM
# v105d (2026-11-02): RD x competition forms in every other component with a competition term (Aaron's modeling choice; declared deviation from
# the preregistered adoption rules of koa_rdcomp_20261102 (dHT) and koa_compscreen_20261102 (Eq. 2 H1a, Eq. 3 C2h, Stage 3 M3a)). "v105b" = v105c forms.
HT_FORM = "v105b"   # koa_v105attr P_HT_HCB (reverted to v105c form)
HCB_FORM = "v105b"   # koa_v105attr P_HT_HCB (reverted to v105c form)
DHT_FORM = "K3c1h"   # koa_v105attr P_HT_HCB (v105d form)
STAGE3_FORM = "M3a"   # koa_v105attr P_HT_HCB (v105d form)
RD_FLOOR_HT = 0.001130119195   # minimum RD of the height fitting frame under SDImax_pop (prep/out742/rd_min_fitframes.csv)
RD_FLOOR_HCB = 0.03344242009   # minimum RD of the hcb fitting frame under SDImax_pop (prep/out742/rd_min_fitframes.csv)
RD_FLOOR_STAGE3 = 0.001130119195   # minimum RD of the stage3 fitting frame under SDImax_pop (prep/out742/rd_min_fitframes.csv)
CF_DDBH_MARGINAL = 1.57859   # dDBH_L_NO K3c1 under SDImax_pop (0.4871505, 0.8220363), koa_v105attr
# CHANGED 12 August 2026. Replaces the withdrawn CF_dDBH = 1.026 as the deployed
# diameter increment correction factor. Derivation: exp(0.5 * (tau_D**2 +
# tau_I**2)) with tau_D = 0.6131806 between data source and tau_I = 0.5021988
# between installation within source, from VarCorr(dDBH.m3) in
# KoaDatasets_12152025/dDBH_BYI.rda, giving exp(0.5 * 0.6281941) = 1.36902.
# This is the marginalisation of the nested random intercept, and it is EXACT
# rather than approximate for the form actually deployed, because the deployed
# form is a single annual step evaluating exp(lp) times a constant and is
# therefore exactly log-linear in the random intercept.
# It is NOT a Duan smearing factor and it is NOT exp(0.5 * s2) on a weighted
# least squares residual variance. That description, which the deposited script
# headers carried, is the origin of U30.
# Corroborated by four routes that do not share an estimator: the empirical mean
# of exp(u) over the 60 installations is 1.39283, the marginal Duan factor on
# the weighted least squares rung is 1.3721, LineageB in koa_equations.py
# already carried 1.391 labelled as marginal, and ddbh_CFs.csv spans 1.3911 to
# 1.4295 across six specifications.
# Effect: population R2 moves from -0.0523 to +0.1110 and installation-balanced
# bias from +0.3169 to -0.0581 cm yr-1. It does not make the deployed form
# unbiased on the fitting table and is not meant to: it closes 47.1 percent of
# the 0.81 cm yr-1 gap and leaves +0.4345 cm yr-1, which is the design imbalance
# term, the fitting table being 72 percent PSP, and is a property of that sample
# rather than of the equation. See _ooda_20260811_u29/.
# Selected JOINTLY with the mortality ramp. At CF 1.026 the onset 200 full lift
# 500 ramp fits the long-term validation better; at 1.369 the recorded ramp at
# 200 and 850 does. A future editor moving either constant must know the other
# was chosen against it. See _ooda_20260811_joint/ 12 August report.

# --- The correction factor's SAMPLING UNCERTAINTY, ADDED 6 September 2026 ----
# CF_DDBH_MARGINAL ABOVE DOES NOT MOVE. What is added here is the variance it was
# published without. Until this date Supplemental Table S4 classified the marginal
# correction as `Fixed` and the Table 8, Figure 8 and uneven-aged Monte Carlo
# perturbed only the fixed effects, so the published 95 percent limits omitted the
# largest variance component in the increment model. That is now measured rather
# than argued, and it is propagated.
#
# THE MEASUREMENT. Gate 7 of _cfswap/SELECTION_RULE_2026-09-06e.md re-solves the
# recursion-consistent correction with whole installations held out, ten folds
# grouped by `Install` at seed 20260906, on the 22,585 intervals and 1,369 trees of
# 58 installations in _allpairs/frames/frame_allpairs.csv. The unweighted solution
# k* = 1.64127 ranges from 1.50285 to 1.78082 across folds, a spread of 16.94
# percent of its full-sample value.
#
# THE COMPARISON WITH THE PERTURBED COEFFICIENTS, STATED CAREFULLY, BECAUSE THE
# EASY VERSION OF IT IS WRONG. Against the standard errors the supplemental
# DECLARES, the correction's variability is the largest quantity in the increment
# model by some way, since Table S4 gives the diameter b8 an SE of 0.0401 on 0.4530,
# a coefficient of variation of 8.9 percent, and the four height parameters run 1.6
# to 17.9 percent. Against the standard errors the drivers actually APPLY it is not,
# since every Monte Carlo producer in this deposit perturbs the diameter b8 at 0.089
# and the height b8 at 0.081, which are 19.6 and 18.7 percent and are 2.2 and 1.7
# times the declared values. That divergence between the declared and the applied
# standard errors is a SEPARATE defect, found on 6 September 2026 while this block
# was being written, recorded as a known issue in INTEGRITY_REPORT.md and
# deliberately NOT repaired here, since repairing it would move the published limits
# for a second and unrelated reason in the same pass.
#
# In any case the comparison of bare coefficients of variation is not the comparison
# that matters. The b8 slope enters ONE term of the linear predictor and its effect
# on an annual increment depends on ln(BYI), while the correction multiplies EVERY
# annual increment and feeds forward through b2, b3, b4 and b6. What justifies
# propagating the correction is not that its coefficient of variation wins a
# ranking. It is that the quantity was classified `Fixed` and given no variance at
# all while being demonstrably resampling-dependent at a sixth of its own value.
#
# THE ESTIMATOR AND WHY THIS NUMBER RATHER THAN ANOTHER. Part 10 of the selection
# rule pre-registered the standard error as the LARGER of the gate 7 fold spread and
# a tree-clustered bootstrap of the calibration equation at B = 500 and seed
# 20260906. Both were run, by _cfswap/scripts/bootstrap_cf_se.py, and the tree
# bootstrap returns a standard deviation of about a fifth of the fold spread, which
# is the pre-registered expectation rather than a surprise: resampling trees holds
# the installation composition of the sample fixed, and finding 1 of
# _cfswap/RESULTS_DRAFT_2026-09-06e.md locates the variability between installations
# that differ sixfold in observed growth at comparable stand age. An
# installation-clustered bootstrap, added by the uncertainty rule at the same B and
# seed, sits between the two. The pre-registered instruction therefore selects the
# fold spread. Read as a relative standard deviation it is corroborated by the
# delete-one-group jackknife standard error implied by the same ten fits, 12.47
# percent, which is within a factor of 1.36 of it; the uncertainty rule declared in
# advance that a disagreement beyond a factor of two would send the jackknife value
# here instead.
#
# WHAT IS ASSUMED, AND IT IS THE WEAKEST LINK. The spread is measured on k*, a
# smearing solution, while the deployed correction is the theoretic marginal factor
# exp(0.5 (tau_D**2 + tau_I**2)). The uncertainty is transferred as a COEFFICIENT OF
# VARIATION and applied to 1.369, on the argument that the theoretic form is derived
# from variance components estimated on the same 58 installations and inherits the
# same dependence on which of them are in the sample. That is an argument and not a
# measurement. What would settle it is a parametric bootstrap of VarCorr(dDBH.m3),
# which needs the fitting object and has not been run. Disclose it.
CF_DDBH_MC_SE_REL = 0.1694
# Relative standard deviation of the diameter increment correction factor. Applied to
# whatever CF the variant carries, so an as-published control at 1.026 would draw
# around 1.026 and the deployed arm draws around 1.369.

CF_DDBH_MC_SIGMA_LOG = math.sqrt(math.log(1.0 + CF_DDBH_MC_SE_REL ** 2))
# Log scale of the LOGNORMAL draw, 0.16820 at the relative SD above. The draw is
# CF * exp(CF_DDBH_MC_SIGMA_LOG * Z) with Z standard normal, so its MEDIAN is exactly
# the deployed correction and the deployed point value cannot move. Lognormal rather
# than normal because a smearing correction is a positive multiplicative factor and a
# normal draw at a relative SD near a fifth puts a left tail where the recursion
# behaves nothing like it does at the point value. Consequence, stated rather than
# corrected: the MEAN of the draws exceeds the median by exp(sigma**2 / 2), about 1.4
# percent, and correcting that would move the deployed constant.

CF_DDBH_MC_CLIP_REL = (0.5, 2.0)
# Draws are clipped to this multiple of the variant's CF, so [0.685, 2.738] at the
# deployed 1.369. At the log scale above both bounds sit beyond four standard
# deviations, so the clip is a guard against a pathological tail and not a shaper of
# the distribution. Every producer counts and reports the clipped draws; a run in
# which the count is not near zero is a run whose spread has changed and must be
# re-examined rather than reported.

CF_DDBH_MC_SEED_OFFSET = 7919
# The correction is drawn from a SECOND generator, default_rng(SEED + this), rewound
# at every point-estimate call. The existing default_rng(42) stream is untouched and
# bit-identical, so the widening of any published limit is attributable to the
# correction's variance alone rather than to a reshuffle of the height and slope
# draws. Rewinding on the point-estimate call is what lets the chunked drivers keep
# reproducing a monolithic run without being edited, since their burn advances both
# generators the same number of times; it also makes the correction draws COMMON
# across scenarios within a variant, which is declared rather than hidden.

CF_DDBH_MC_ESTIMATOR = (
    "gate 7 fold spread, 10 folds grouped by Install, seed 20260906, on 22585 "
    "intervals / 1369 trees / 58 installations of _allpairs/frames/frame_allpairs.csv; "
    "recursion-consistent unweighted k* = 1.64127, folds 1.50285 to 1.78082, spread "
    "16.94 percent; larger than the pre-registered tree-clustered bootstrap at B=500 "
    "seed 20260906; transferred to CF_DDBH_MARGINAL as a coefficient of variation")
# Carried as a string so that the deposited table's declaration column, the
# supplemental Table S4 row and the integrity report all quote ONE provenance
# sentence rather than three paraphrases of it.

CF_DDBH_AS_PUBLISHED = 1.026
# WITHDRAWN 12 August 2026 as a deployed value, retained ONLY so that the
# as-published control variant of Table 8 can be pinned to it and remain a live
# regeneration rather than a frozen fixture. Its provenance is unknown: U30
# could not reconstruct it under any of twenty candidate definitions, and it
# appears in FVS_FINAL_2026_05_12/ddbh_CFs.csv as a constant across all six
# specifications, which is the signature of a value copied in rather than
# computed. U30 closes as SUPERSEDED, not as answered.
# NOTHING IN THE PRODUCTION PATH MAY READ THIS.

DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM = 40.0
# WITHDRAWN 12 August 2026 as a deployed behaviour, retained ONLY so that the
# as-published control variant of Table 8 can be pinned to it and remain a live
# regeneration rather than a frozen fixture. Third member of the as-published
# triple, beside CF_DDBH_AS_PUBLISHED and SDI_OF_EXPONENT_AS_PUBLISHED.
# PROMOTED HERE 12 August at the request of the gate track, which found the
# triple split across two files: this value lived only at koa_equations.py in
# LineageA's inert else branch, so regen_t8_chunked.py had to reach into
# koa_equations for one third of a pin whose other two thirds are here. That is
# the F9 failure mode in miniature.
# The behaviour it names is the withdrawn one: b7 * planted * min(DBH, 40) where
# the fitted form is untruncated. See DDBH_PLANTED_UNTRUNCATED.
# NOTHING IN THE PRODUCTION PATH MAY READ THIS. Note for the gate: this name is
# legitimately mentioned by LineageA in its inert branch, so a carrier-scoped
# withdrawn-name check must not convict koa_equations.py for naming it there.

CF_DHT = 2.39567   # dHT_L_NO (K3c1h) (1.3041697, 0.2155557), koa_v105attr
# Height increment correction factor, UNCHANGED. koa_equations.py LineageA line
# 69 as deposited and HiGy.R dht(). The height increment equation is out of
# scope for the 12 August calibration because its fitting script has never been
# recovered, so no marginal factor can be derived for it. Centralised here only
# so it stops being typed in three files.
# [UNPROVENANCED, and now the only unprovenanced correction factor in the
# deposit. Disclose it as such.]

# --- Optional source-level calibration, NOT the default -----------------------

DDBH_SOURCE_MULTIPLIERS = {
    "PSP":      2.13640,
    "KMR_PSP":  1.83501,
    "DOFAW":    0.72748,
    "FIA":      0.58066,
}
# ADDED 12 August 2026 as an OPTIONAL, NON-DEFAULT calibration. Each value is
# exp(u_s + 0.5 * tau_I**2), that is the source random intercept exposed with
# the installation effect marginalised out within a known source. The unknown
# source case, which is EVERY hypothetical stand projection including manuscript
# Table 8, Figure 8, uneven_aged_table8.csv and the Bakuzis grid, takes
# CF_DDBH_MARGINAL. Verified 12 August: those artifacts carry no data source to
# key an offset to, so the source-level deployment reduces exactly to the
# default on all of them.
# WHY IT IS OFFERED. On the 23 remeasured validation plots the population-average
# form is grossly biased BY NETWORK under every scalar correction factor and the
# aggregate is cancellation, not accuracy. At CF_DDBH_MARGINAL the diameter bias
# runs DOFAW +7.4821 cm, FIA +5.5852 cm and PSP -6.9055 cm for an aggregate of
# +0.732 cm. Keying per source collapses the three to -1.1056, +0.4897 and
# -0.1170 cm and cuts diameter RMSE by a factor of 2.5, at p < 0.0001 on a
# paired plot bootstrap. It degrades the survival statistics.
# THREE THINGS MUST BE DECLARED WITH IT AND NONE IS OPTIONAL.
# (1) CONFOUNDING. The network contrast correlates with remeasurement interval
#     at r = 0.827 and with stand age, and stand age is missing for all FIA
#     records. This is an empirical network calibration, not a validated stand
#     class effect.
# (2) PLACEMENT. It must be applied on the correction factor INSIDE the
#     increment function, before the annual clip. Carried instead on the FVS
#     BAIMULT keyword, that is on ddbh.mult at HiGy.R line 351 or
#     koa_projector.py line 148, it is applied AFTER the clip and escapes the
#     bound, delivering 5.1149 cm yr-1 against a nominal ceiling of 4, which is
#     27.9 percent above it.
# (3) SUPPORT. Validated against ten PSP, seven DOFAW and six FIA plots of the
#     23. There is NO KMR_PSP plot among them, so 1.83501 is deployed on no
#     validation evidence whatsoever.

DDBH_SOURCE_DEFAULT_KEY = None
# Explicitly no default source. A caller that cannot name the source must use
# CF_DDBH_MARGINAL rather than pick a network for it.

# --- Annual bounds on the increment functions ---------------------------------

DDBH_ANNUAL_CAP = 4.0
# HiGy.R line 295 pmin(pmax(ddbh, 0), 4) and koa_equations.py LineageA
# ddbh_cap. RECONCILED 12 August: koa_prediction_functions.R, at what is now
# line 273, and WeiskittelKoaGy_2026_03_27.r, at what is now line 276, both
# clipped at 6 cm yr-1 as deposited and both cannot be right.
# 4.0 wins because it is the value pull request 31 carries into FVS-HI and the
# value every projected artifact in this deposit was computed under. The bound
# binds on ZERO of the 6,209 fitting records and on zero of the 27,112
# validation tree-years at CF_DDBH_MARGINAL, so the reconciliation moves no
# published number; it binds on 69 tree-years under the optional source-level
# calibration, all of them on PSP.

DHT_ANNUAL_CAP = 2.0
# HiGy.R line 439 and koa_equations.py LineageA dht_cap. RECONCILED 12 August:
# koa_prediction_functions.R clipped at 4 m yr-1 on an untruncated height, at
# what is now line 378, and WeiskittelKoaGy_2026_03_27.r did the same at what is
# now line 381, while HiGy.R line 431 truncates height at 20 m and line 439
# clips at 2. This divergence was found on 11 August and is parallel to U31.
# Both R files now carry the 20 m truncation and the 2.0 clip, so all four
# carriers agree and the divergence is closed.
# [ADJUDICATED BY DEPLOYMENT, NOT BY THE FIT. The height increment fitting
# script has never been recovered, so there is no fitted form to check either
# implementation against. 2.0 with the 20 m truncation is chosen because it is
# what HiGy.R carries into FVS-HI and what every projected artifact used. This
# is a consistency decision and not a correctness one, and it must be disclosed
# as such.]

DDBH_HT_TRUNCATION_M = 20.0
# HiGy.R line 431: the height increment planted term uses sqrt(planted *
# pmin(ht, 20)). Centralised for the same reason as the caps. All three
# implementations agree on the square root; the 11 August claim that HiGy.R
# deploys a square root where the fit uses a linear size term is FALSE for the
# square root itself and TRUE for the truncation.

# --- Diameter increment fixed effects, deployed vector, UNCHANGED -------------

DDBH_COEFFS = {
    "b0": -2.4704737,   # intercept
    "b1":  0.2072221,   # ln(DBH + 1)
    "b2": -0.0159616,   # DBH
    "b3": -0.0016893,   # BAL**2 / ln(DBH + 5), the social position term
    "b4": -0.2972574,   # ln(BAL + 1)
    "b5": -0.4470330,   # ln(CR)
    "b6": -0.0158403,   # sqrt(BAPH * DBH)
    "b7":  0.0188938,   # Planted * DBH, UNTRUNCATED, see DDBH_PLANTED_UNTRUNCATED
    "b8":  0.4530166,   # ln(BYI)
}
# Transcribed unchanged from koa_equations.py LineageA.DDBH and the HiGy.R
# ddbh.parm tribble, which remain the carriers of record and are byte-identical
# to their 11 August state. Folding CF_DDBH_MARGINAL into b0 would give
# b0 = -2.1820444 and identical predictions, and it is the WRONG choice: it
# would break the match between the deployed vector and the fitted vector that
# gate 1 exists to check, break the match with manuscript Table 4, and hide a
# calibration decision inside a fitted parameter. The constant stays a constant.
# ESTIMATOR, for the record, because every deposited script header described it
# wrongly as weighted least squares with weights 1/sqrt(YIP): this is a
# NONLINEAR MIXED MODEL on raw period diameter change, fitted through an annual
# stepping projector, with a nested random intercept by data source and
# installation and a power-of-the-mean variance function on initial diameter.
# nlme lme object dDBH.m3 in dDBH_BYI.rda, 6,209 rows, 4 source groups, 60
# source-by-installation groups, log likelihood -12892.82.
# FULL-PRECISION FITTED VALUES for the two terms the withdrawn over-steepness
# claim turned on: b3 = -0.001689304 with a standard error of 0.000402 on 6,141
# degrees of freedom, likelihood ratio 19.12 against zero at p = 1.2e-5; and
# b6 = -0.01584032 with a standard error of 0.00280863. The deployed digits
# above are these rounded, and the rounding is what gate 1 checks.
# FIT STATISTICS, by level, because three different pairs have circulated:
#   conditional (random intercepts retained): RMSE 1.2722 cm yr-1, R2 0.4157,
#     MAE 0.8561, bias +0.0700
#   population average as deployed at CF_DDBH_MARGINAL: RMSE 1.5693 cm yr-1,
#     R2 0.1110
#   population average as deployed at CF_DDBH_AS_PUBLISHED: RMSE 1.7073,
#     R2 -0.0523
# The pair R2 0.298 and RMSE 1.424 cm yr-1 carried in the deposited script
# headers belongs to an earlier 5,542-record pre-BYI frame and is WITHDRAWN.
# The pair R2 0.270 and RMSE 1.42 in manuscript Table 7 has no located producer.

DDBH_PLANTED_UNTRUNCATED = True
# CHANGED 12 August 2026, this is U31. HiGy.R, at what is now line 279, and
# koa_equations.py LineageA.dDBH, at what are now lines 172 to 177, deployed the
# planted term as b7 * Planted * pmin(DBH, 40) where the fit and
# koa_prediction_functions.R line 265 use untruncated diameter. Only 4
# of 6,209 fitting records are planted stems above 40 cm, so the truncation was
# nearly invisible in fitting, but the projected planted trajectories in
# Table 8 run to the 60 cm plantation diameter cap and every one of them passes
# 40 cm, so the truncation acts on every planted row of the published table.
# Removing it is the fitted form.

DDBH_PLANTED_GUARD_CM = 45.0
# DECLARED EXTRAPOLATION GUARD on the diameter argument of the planted term,
# ADDED 12 August 2026. This is NOT a reinstatement of the withdrawn 40 cm
# truncation and it is NOT a claim about the fitted form. The FORM stays
# untruncated and DDBH_PLANTED_UNTRUNCATED stays True; what is bounded is the
# ARGUMENT, so that a coefficient estimated on planted stems of 45.10 cm and
# below is never evaluated at 200 cm. Both are true at once because they are
# statements about different things, the equation and the domain it is evaluated
# on.
# WHY A BOUND IS NEEDED AT ALL. b7 = +0.0188938 sits on Planted * DBH INSIDE the
# exponential, so it is a positive feedback with no saturation anywhere in the
# functional form. The multiplier it puts on annual diameter increment runs 2.13
# at DBH 40 cm, 3.11 at 60 cm, 6.62 at 100 cm and 43.76 at 200 cm. U31 removed
# the pmin(DBH, 40) truncation because the fitted form is untruncated, which was
# correct as a statement about the fit, and in doing so removed the only thing
# damping the term at large diameter.
# FITTING SUPPORT, which is much narrower than the truncation that was removed.
# Of the 378 planted records in dDBH.csv the maximum initial diameter is
# 45.10 cm, only 4 exceed 40 cm, only 1 exceeds 45 cm and NONE exceeds 50 cm.
# The term carries no information whatsoever above 45.10 cm, while the deployed
# projection with the harness diameter cap released evaluates it out to 214.6 cm
# quadratic mean diameter at age 100, against a largest koa plot-year quadratic
# mean diameter ever measured of 69.68 cm. The guard is set at the edge of that
# support.
# MEASURED EFFECT. With the harness diameter cap RELEASED, planted age 100 on
# the high site falls from 214.6 to 126.7 cm. With the cap ACTIVE, which is the
# deployed default, the guard changes exactly one Table 8 cell, planted Low site
# age 40, from 52.7 to 52.3 cm, and changes nothing else. That inertness under
# the default is the property a guard is supposed to have: it does not move the
# published projection, and it bounds the projection an FVS user reaches by
# releasing the cap through a keyword.
# THIS IS NOT A FITTED QUANTITY and it is not the withdrawn truncation. It is an
# operational bound on the domain of evaluation, declared as such, and it must be
# disclosed that way. The withdrawn 40 cm value was undeclared, unprovenanced and
# read as though it were part of the equation; this one is declared, is set at
# the edge of the fitting support, and names itself an extrapolation guard.
# The as-published control variant keeps its own pin at
# DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM = 40.0 and is unaffected by this constant.

DDBH_PLANTED_GUARD_CM_LINEAGEB = 45.0
# DECLARED EXTRAPOLATION GUARD on the diameter argument of LineageB's planted
# term, ADDED 15 August 2026, following the same pattern as
# DDBH_PLANTED_GUARD_CM above and at Aaron's request: LineageB was left outside
# the 12 August guard because it is not the deployed lineage, but it should not
# be left unguarded indefinitely just because it is dormant.
# FITTING SUPPORT, INDEPENDENTLY CONFIRMED RATHER THAN ASSUMED. LineageB's
# dDBH (koa_FVS_FINAL_parameters.csv, spec M1_BYI, the May-2026 stress-test
# recommendation, refit in koa_unified_models.R) is fit on the SAME underlying
# file as LineageA's dDBH: DATA_DIR/dDBH.csv in koa_unified_models.R resolves to
# ~/Documents/MAINE/DATA/Koa/KoaDatasets_12152025/dDBH.csv, 6,209 rows, the
# identical file and row count cited above for LineageA's fitting table. This
# was checked directly rather than presumed identical: of the 378 Planted == 1
# records in that file the maximum DBH.0 is 45.10 cm, only 4 exceed 40 cm, only
# 1 exceeds 45 cm and none exceeds 50 cm -- the same four numbers as LineageA's
# support, because it is the same 378 rows. The guard value is therefore
# LineageB's own fitting-support edge, confirmed by direct computation on
# dDBH.csv, and not a borrowed fallback from LineageA.
# WHY A BOUND IS NEEDED, AND WHY MORE URGENTLY THAN LINEAGE A. LineageB.DDBH b7
# = +0.057437 on Planted * DBH sits inside the same untruncated exponential
# form as LineageA, but is about 3.0x steeper (0.057437 / 0.0188938 = 3.04),
# matching the "three times steeper" comparison in the 12 August handoff note.
# The resulting multiplier on annual diameter increment is exp(b7 * dbh): 9.95
# at DBH 40 cm, 13.34 at the 45.10 cm fitting edge, 31.38 at 60 cm, 312.2 at
# 100 cm and 97,480 at 200 cm -- all four values computed directly from the
# coefficient, not asserted. No LineageB Table 8 projection exists to quote a
# "cap released" endpoint diameter the way LineageA's 214.6 cm figure was
# measured, because LineageB is never run through the deployed projection
# pipeline (see INERT, below); the multiplier alone is enough to show the term
# has no saturation and would diverge harder than LineageA's if it were ever
# evaluated past its support.
# INERT UNDER EVERY CURRENTLY-DEPLOYED CONFIGURATION. LineageB is not the
# deployed lineage. Checked directly on 15 August 2026: no production caller in
# this deposit passes lineage="B" or indexes LINEAGES["B"] anywhere in
# koa_projector.py, koa_survival_calibrated_py.py, regen_t8_chunked.py,
# make_table8_from_variants.py, make_bakuzis_input.py or any other script that
# feeds a manuscript table or figure. LineageB is reachable only by naming it
# explicitly (LINEAGES["B"] or koa_equations.LineageB) from a script written to
# do so, which as of this date is none of them. This guard therefore changes
# nothing about any published number; it bounds a term that is not currently
# being evaluated at all, so that it cannot silently diverge if LineageB is
# ever promoted to deployed status without this guard being revisited first.
# THIS IS NOT A FITTED QUANTITY, exactly as DDBH_PLANTED_GUARD_CM above is not:
# it is an operational bound on the domain of evaluation for a lineage that is
# not deployed, declared as such and set at the edge of its own fitting
# support.

DDBH_CV_R2_DEPLOYED = 0.139
# Ten-fold randomly partitioned cross-validated population-average R2 of the
# DEPLOYED specification, M3, from FVS_FINAL_2026_05_12/koa_unified_models.R.
# The 0.163 the manuscript reports is the same statistic for M1, the RETIRED
# specification, which was evaluated and not adopted because it overshoots age
# 20 quadratic mean diameter against Table 8 by a factor of 2.8. This matters
# because 0.163 sits inside the paper's stated 0.15 to 0.40 benchmark band and
# 0.139 falls below it, so the benchmark comparison reverses. Not a defect in
# the equation; a defect in which number was quoted.

# --- Height increment fixed effects, deployed vector, UNCHANGED ---------------

DHT_COEFFS = {
    "b0": -3.382162,    # intercept
    "b1":  0.272454,    # ln(HT + 1)
    "b2": -0.105319,    # HT
    "b3": -0.000829,    # BAL**2 / ln(HT + 5)
    "b4": -0.071718,    # ln(BAL + 1)
    "b5": -1.483889,    # ln(CR)
    "b6":  0.033035,    # sqrt(BAPH * HT)
    "b7":  0.017887,    # sqrt(Planted * pmin(HT, DDBH_HT_TRUNCATION_M))
    "b8":  0.433224,    # ln(BYI)
}
# Transcribed unchanged from koa_equations.py LineageA.DHT and the HiGy.R
# dht.parm tribble. NO FITTED OBJECT AND NO FITTING SCRIPT FOR THIS EQUATION
# HAS EVER BEEN RECOVERED anywhere in either tree, so there is no conditional
# statistic, no variance component and therefore no marginal correction factor
# available for it. That is why CF_DHT stays at its unprovenanced 1.030 while
# CF_DDBH moves, and the asymmetry must be disclosed rather than smoothed over.
# Deposited header pair R2 0.218 and RMSE 1.082 m yr-1 reproduces under nothing.
# Population-average refit gives R2 -0.2831 and RMSE 1.3840 m yr-1, and the
# deployed single-step form gives R2 -0.274 and RMSE 1.379 m yr-1.
# DHT_CV_R2_DEPLOYED is 0.033 for M3 against the 0.094 the manuscript reports
# for the retired M1, the same substitution as for diameter.

DHT_CV_R2_DEPLOYED = 0.033


# =============================================================================
# The RETIRED parameterisation. Recorded here ONLY so that
# test_engine_equivalence.py can prove the respecified engine no longer agrees
# with it, and so that a reader of the deposit can reproduce what the previous
# version computed. NOTHING IN THE PRODUCTION PATH MAY READ THESE.
# =============================================================================

RETIRED_SDI_MAX = 500.0          # was figshare_v62/koa_survival_calibrated_py.py line 12,
                                 # koa_projector.py line 26, koa_ingrowth.py line 15
RETIRED_ONSET_RD = 0.65          # was koa_survival_calibrated_py.py line 15; absolute SDI 325
RETIRED_FULL_RD = 0.85           # was koa_survival_calibrated_py.py line 15; absolute SDI 425
# REJECTED ON THE LIKELIHOOD as well as withdrawn on the scalar, established
# 11 August 2026 on the standardised sample. The three retired configurations
# lose to the recorded thresholds by 892, 2,114 and 4,228 units of Akaike
# information at scalars 500, 933 and 1,350 respectively, and the margin grows
# monotonically with the scalar. At 325 and 425 the form predicts 15.31 percent
# annual mortality in the 350 to 500 bin against an observed 5.39 percent.
# At 878 and 1,148 it fails the sign test even under the reading most favourable
# to a density response, returning a sign-free lift of -0.0381 and exactly zero
# when constrained to increase.
# The FORM is worth separating from the SCALAR and the separation is favourable
# to it: on the Bakuzis matrix the retired form at 325 and 425 is the mildest
# candidate on Reineke and the lowest on Eichhorn anywhere in the grid, which is
# the strongest surviving argument for anything other than the recorded ramp and
# is why the 5 August assessment found mortality biologically defensible while
# still running this form. On the 12 August paired plot bootstrap that advantage
# does not separate it from the recorded ramp: the absolute bias difference is
# -0.9947 cm at p = 0.7680 and -4.6997 m2 ha-1 at p = 0.3022, and the milder
# self-thinning slope is categorical only under one of four Reineke definitions.
# The relative-density parameterisation also carries the failure mode documented
# at final/koa_survival_calibrated.R lines 240-249, where holding 0.65 and 0.85
# fixed while the scalar moves relocates the absolute onset from 325 to 878 to
# 606 with no visible edit. KEEP THE ABSOLUTE PARAMETERISATION.
RETIRED_B_RD = -3.0933           # was koa_ingrowth.py line 16; = ING_B_SDI * 500
RETIRED_BAPH_DIVISOR = 60.0      # was koa_survival_calibrated_py.py line 22 and
                                 # koa_ingrowth.py line 22: baph/60 used as a relative
                                 # density. Replaced by the Reineke identity at BAPH_REF
                                 # and QMD_REF_CM, which is what the R record does.
RETIRED_B_RD_AT_933 = -5.7720978    # final/koa_ingrowth.R line 239
RETIRED_B_RD_AT_1350 = -8.3519      # final/koa_ingrowth.R line 240
WITHDRAWN_SDIMAX_VALUES = (500.0, 933.0, 1350.0)
# final/koa_survival_calibrated.R lines 15-19, 61-85; final/koa_ingrowth.R 17-23.


__all__ = [n for n in dir() if not n.startswith("_")]
JOINT_DRAWS_FILE = "out_joint/K_joint_draws.csv"   # joint, source-level Monte Carlo rows, 2026-09-16 (v99)
