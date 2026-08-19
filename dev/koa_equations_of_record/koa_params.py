"""koa_params.py -- SINGLE SOURCE OF TRUTH for every koa survival and ingrowth
constant used by the deposited Python engine.

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
# Survival: the equation of record.
#   annual mortality = base(origin) + MAXLIFT * frac, capped at MORT_MAX
#   frac = clip((SDI - ONSET_SDI) / (FULL_SDI - ONSET_SDI), 0, 1)
#   annual survival = 1 - annual mortality
# final/koa_survival_calibrated.R lines 481-553.
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
# final/koa_survival_calibrated.R line 498 (maxlift = 0.15). Maximum
# density dependent lift in annual mortality, reached at FULL_SDI.

MORT_MAX = 0.20
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

ALLOC_BETA = 3.0
# final/koa_survival_calibrated.R line 727 (beta = 3; re-pinned 2026-08-19).
# Concentration of stand mortality onto small trees in koa.SURV.allocate.

ALLOC_MORT_CAP = 0.95
# final/koa_survival_calibrated.R lines 672 (renormalizer default) and 762
# (allocate pass-through; re-pinned 2026-08-19). Per-tree annual mortality cap.

ALLOC_MODE = "tree_eq"
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

ING_B0 = 5.3836
# final/koa_ingrowth.R line 232 (b0 = 5.3836); equation at line 159.

ING_B_SDI = -0.0061866
# final/koa_ingrowth.R line 233 (b_sdi = -0.0061866). Fitted slope per unit of
# ABSOLUTE SDI. Line 115 gives its derivation, -3.0933 / 500, and lines 113-126
# establish that this is the invariant quantity the model was fitted on: the
# RD-scale coefficient b_rd = b_sdi * SDImax, so the product b_rd * RD collapses
# to b_sdi * SDI identically for any SDImax.

ING_B_PLANTED = -1.6359
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
HARNESS_DBH_MAX_PLANTED_CM = 60.0
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

CF_DDBH_MARGINAL = 1.369
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

CF_DHT = 1.030
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
