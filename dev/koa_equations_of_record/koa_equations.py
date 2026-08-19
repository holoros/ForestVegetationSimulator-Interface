"""
koa_equations.py
================
Component equations for the FVS-HI (Hawaii variant) koa growth & yield model,
implemented for two parameter/equation lineages so they can be stress-tested
against each other through an identical stepping engine.

LINEAGE A  ("PR / manuscript")
    Exactly the equations shipped in Ben Rice's PR #30 HiGy.R (v0.2.0) and
    mirrored in koa_projection.py. dDBH/dHT use the BAL^2/ln(size) + sqrt(BAPH*size)
    form; survival is the ALIVE-response cloglog on the manuscript Table 6 anchor
    (14.102, corrected 15 August 2026 from the stale 18.133 "model development
    snapshot"; see SURV below), i.e. P(alive) = 1 - exp(-exp(eta + ln(YIP)));
    correction factors 1.369 / 1.030, read from koa_params as CF_DDBH_MARGINAL and
    CF_DHT.
    NOTE (12 August 2026): the diameter correction factor was 1.026 here as deposited
    and was labelled a conditional Duan factor. It is neither conditional nor a Duan
    factor; see koa_params.CF_DDBH_MARGINAL for the derivation of the deployed 1.369
    from the nested random intercept, and koa_params.CF_DDBH_AS_PUBLISHED for the
    withdrawal of 1.026. The planted term of dDBH also lost its 40 cm diameter
    truncation on the same date (U31).
    NOTE (1.2.0 correction): releases before 1.2.0 returned exp(-exp(eta)) here,
    which is the complement of the fitted quantity and inverted the crown-ratio
    response. See DEPOSIT_CHANGELOG.md, Defect 1.

LINEAGE B  ("FVS_FINAL / M1-S1")
    The May-2026 stress-test recommendation in koa_FVS_FINAL_parameters.csv:
    increment M1 form (sqrt(SDI) + rHT + log(CR*size) + two BYI terms), survival
    S1 cloglog with ln(YIP) offset, and MARGINAL CFs 1.391 / 1.334.
    NOTE (12 August 2026): lineage B's diameter CF of 1.391 is NOT a stale duplicate
    of lineage A's 1.369 and must not be reconciled with it. The two are marginal
    factors of two different fitted increment specifications (A is the BAL^2/ln(size)
    form, B is the M1 sqrt(SDI) + rHT form), each derived from its own variance
    components. That they land within 1.6 percent of one another is independent
    corroboration of the 12 August marginalisation of lineage A, and destroying it by
    pointing both at one constant would destroy the evidence. Leave 1.391 alone.
    NOTE (15 August 2026): lineage B's dDBH planted term is now guarded the same way
    lineage A's was on 12 August. b7 = +0.057437 on Planted*DBH sits inside the same
    untruncated exponential and is about 3.0x steeper than lineage A's 0.0188938. The
    ARGUMENT is bounded at koa_params.DDBH_PLANTED_GUARD_CM_LINEAGEB = 45.0 cm, lineage
    B's own fitting-support edge, confirmed on the same dDBH.csv lineage A's edge was
    read from (378 planted records, max DBH.0 45.10 cm) rather than assumed to match.
    The FORM stays untruncated. Lineage B is still not the deployed lineage and no
    production caller in this deposit invokes LINEAGES["B"], so the guard is inert
    under every currently-deployed configuration; it exists so the term cannot
    silently diverge if lineage B is ever promoted without the guard being revisited.

All equations are metric: DBH cm, HT m, BAPH/BAL m2/ha, BYI Mg/ha, TPH /ha.
Coefficients are transcribed verbatim from the cited sources; see comments.
"""
import warnings

import numpy as np

import koa_params as KP
# ADDED 12 August 2026. The increment correction factors and the annual increment
# bounds are no longer typed in this file; they are read from koa_params.py, which
# is the single source of truth for every non-fitted constant in the deposit. This
# import creates no cycle: koa_params imports nothing from this package (only math,
# inside kR), so the chain koa_projector -> koa_equations -> koa_params is acyclic
# and koa_projector.py, which imports names from this module, is unaffected.

DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM = KP.DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM
# The 40 cm diameter truncation that LineageA.dDBH applied to its planted term as
# deposited, retired 12 August 2026 (U31, see LineageA.ddbh_planted_trunc_cm).
# Retained ONLY so that the as-published control variant of Table 8 can be pinned
# to it and remain a live regeneration of the published engine rather than a frozen
# fixture, exactly as koa_params.CF_DDBH_AS_PUBLISHED is retained for the
# correction factor. NOTHING IN THE PRODUCTION PATH MAY READ THIS.
# REPOINTED 12 August 2026, later the same day. This was the literal 40.0, typed
# here while koa_params.py line 579 defined the same value under the same name,
# which is the F9 duplication rule broken by the very edit that was closing it.
# koa_params promoted the constant so the as-published triple would live in one
# file; this alias is what makes that true. The name is kept bound here rather
# than deleted because LineageA's inert else branch references it unqualified and
# because a carrier-scoped withdrawn-name check is documented to expect it here.

ln = np.log
def _sqrt(x): return np.sqrt(np.maximum(x, 0.0))

# ----------------------------------------------------------------------------
# SHARED STATIC EQUATIONS  (identical across lineages: both use the FINAL HT;
# HCB differs between lineages so it is defined per-lineage below)
# ----------------------------------------------------------------------------
# Total height: BYI-modified Chapman-Richards  (HiGy.R ht.pred.parm 'site';
# identical to koa_FVS_FINAL_parameters.csv and koa_projection.predict_HT)
HT_P = dict(a0=19.832, a1=0.106, b=0.044, c=0.863, g1=-0.198, g2=0.479)

def predict_HT(dbh, baph, qmd, byi, use_byi=True):
    a0, a1, b, c, g1, g2 = (HT_P[k] for k in ("a0", "a1", "b", "c", "g1", "g2"))
    rdbh = dbh / np.maximum(qmd, 1e-6)
    inter = a0 + a1 * byi / 100.0 if use_byi else a0
    ht = inter * (1 - np.exp(-b * dbh)) ** c * np.exp(g1 * ln(baph + 1) + g2 * rdbh)
    return np.maximum(ht, 1.37)

# BAL allocation (logistic on rDBH) -- used to derive per-tree BAL from BAPH in
# the stand-level cohort projector. (HiGy.R has no analogue; from FINAL CSV.)
def bal_fraction(rdbh):
    return 1.0 / (1.0 + np.exp(-1.842 + 3.956 * rdbh))

# Height to crown base (identical 'site' parms in HiGy.R and FINAL CSV)
HCB_P = dict(b0=0.1684, b1=1.0146, b2=-0.376, b3=-0.0078, b4=-0.3734, b5=-0.221)
def predict_HCB(dbh, ht, bal, baph, byi):
    p = HCB_P
    eta = (p["b0"] + p["b1"] * _sqrt(ht / 100.0)
           + p["b2"] * ln(np.maximum(ht / np.maximum(dbh, 0.1), 0.5))
           + p["b3"] * _sqrt(bal * baph + 1)
           + p["b4"] * ln(baph + 1)
           + p["b5"] * ln(np.maximum(byi, 1) / 100.0))
    hcb = ht / (1.0 + np.exp(-eta))
    return np.minimum(np.maximum(hcb, 0.0), 0.95 * ht)

# ----------------------------------------------------------------------------
# LINEAGE A  -- PR HiGy.R v0.2.0 (== koa_projection.py)
# ----------------------------------------------------------------------------
class LineageA:
    name = "A_PR_manuscript"
    # CHANGED 12 August 2026: both correction factors and both annual caps are now
    # read from koa_params rather than typed here. CF_DDBH moves from the withdrawn
    # 1.026 to CF_DDBH_MARGINAL = 1.369; CF_DHT, DDBH_ANNUAL_CAP and DHT_ANNUAL_CAP
    # are numerically unchanged (1.030, 4.0 cm yr-1, 2.0 m yr-1) and are repointed
    # only so they stop being typed in five files, which is the divergence history
    # recorded in koa_params. The caps still match HiGy.R pmin(pmax(.,0),4) and
    # pmin(pmax(.,0),2); koa_prediction_functions.R clipped at 6 and 4 and was
    # reconciled against HiGy.R on 12 August, see koa_params.DDBH_ANNUAL_CAP.
    CF_DDBH, CF_DHT = KP.CF_DDBH_MARGINAL, KP.CF_DHT
    ddbh_cap, dht_cap = KP.DDBH_ANNUAL_CAP, KP.DHT_ANNUAL_CAP

    # Diameter at which the argument of the PLANTED term of dDBH is bounded, cm.
    # None means no bound at all, which is the bare fitted form (U31, 12 August
    # 2026). Exposed as a class attribute rather than hardcoded in dDBH so that the
    # as-published control variant of Table 8 can pin it back to 40 cm for one cell
    # and remain a live regeneration; see DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM above
    # and regen_t8_chunked.py. Any code that sets it MUST restore it.
    # CHANGED 12 August 2026, later the same day. The deployed value is no longer
    # None but KP.DDBH_PLANTED_GUARD_CM = 45.0 cm, which is a DECLARED
    # EXTRAPOLATION GUARD and not a reinstatement of the withdrawn 40 cm
    # truncation. U31 stands and the fitted FORM is still untruncated; what 45.0
    # bounds is the ARGUMENT of the planted term, at the edge of the diameter
    # range the term was estimated on. b7 is positive at 0.0188938 and sits inside
    # the exponential, so with the harness diameter cap released the multiplier
    # reaches 43.76 at DBH 200 cm while no planted fitting record exceeds
    # 45.10 cm. With the cap active, which is the deployed default, the guard
    # moves one Table 8 cell by 0.4 cm and nothing else. See
    # koa_params.DDBH_PLANTED_GUARD_CM for the full provenance and the measured
    # effect. dDBH still honours None, so a caller that deliberately wants the
    # unbounded argument can still ask for it and has to say so.
    ddbh_planted_trunc_cm = (KP.DDBH_PLANTED_GUARD_CM if KP.DDBH_PLANTED_UNTRUNCATED
                             else DDBH_PLANTED_TRUNC_AS_PUBLISHED_CM)

    # HCB 'site' parms -- HiGy.R hcb.pred.parm (NOTE: differs from koa_projection)
    HCB = dict(b0=0.1684, b1=1.0146, b2=-0.376, b3=-0.0078, b4=-0.3734, b5=-0.221)
    # CARRIERS OF RECORD. The two coefficient dicts below are NOT repointed at
    # koa_params and must stay byte-identical. The reason is the reproducibility gate:
    # a gate that reads the same object it is checking checks nothing, so the deployed
    # vector has to be an independent literal from whatever the gate compares it to.
    # They are DUPLICATED into koa_params.DDBH_COEFFS and koa_params.DHT_COEFFS for
    # centralisation, and the two copies MUST be kept in step by hand.
    # [OWED, verified 12 August 2026: no gate currently checks that they agree. Gate 1
    # of verify_reproducibility.R compares the manuscript parameter tables against a
    # transcription of the deployed HiGy.R values hardcoded in that script, and reads
    # neither this file nor koa_params, so these dicts are a third independent copy
    # that nothing reads. A three-way check of HiGy.R ddbh.parm, LineageA.DDBH and
    # koa_params.DDBH_COEFFS is the gate this centralisation needs and does not yet
    # have. Until it exists, an edit to one copy and not the others splits the
    # deployed vector from the documented one silently.]
    # Fitted values, do not touch: the 12 August calibration moves exactly one
    # constant, CF_DDBH.
    # dDBH 'site' parms -- HiGy.R ddbh.parm
    DDBH = dict(b0=-2.4704737, b1=0.2072221, b2=-0.0159616, b3=-0.0016893,
                b4=-0.2972574, b5=-0.4470330, b6=-0.0158403, b7=0.0188938, b8=0.4530166)
    # dHT 'site' parms -- HiGy.R dht.parm
    DHT = dict(b0=-3.382162, b1=0.272454, b2=-0.105319, b3=-0.000829,
               b4=-0.071718, b5=-1.483889, b6=0.033035, b7=0.017887, b8=0.433224)
    # survival 'site' parms; P(alive)=1-exp(-exp(eta+ln(YIP)))
    # CORRECTED 15 August 2026 (resolves DEPOSIT_CHANGELOG.md open item 9). These
    # are manuscript Table 6 exactly (regenerate_table6.R reproduces them to the
    # coefficient and the clustered SE against the deduplicated AK_SURV.csv,
    # n=5,969, 79 deaths). The vector below (18.133, 0.199, -5.718, 7.640, 15.678,
    # -3.396, 3.039, -25.102) that occupied this dict through 15 August was the
    # "model development snapshot" (n=5,686, 144 deaths), fit before the 1.2.0
    # deduplication of AK_SURV.csv and before the FIA 2010-2019 remeasurement
    # panel was complete. It is not Table 6 and appears only as a Supplemental
    # Table S3c comparison; regenerate_survival.R and regenerate_table6.R both
    # say so explicitly. Applying that stale vector here (with this same ht/dbh,
    # BYI/100-log, BYI/1000-linear convention, which is the convention Table 6
    # itself was fit under) was not a units bug on top of a correct vector; the
    # vector itself was wrong. See koa_prediction_functions.R's correction notice
    # on koa.surv(), items 2 and 3, which is superseded by this fix.
    SURV = dict(b0=14.102, b1=0.130, b2=-4.516, b3=6.684, b4=14.218, b5=-2.806,
                b6=2.649, b7=-21.188)

    @classmethod
    def predict_HCB(cls, dbh, ht, bal, baph, byi):
        p = cls.HCB
        eta = (p["b0"] + p["b1"] * _sqrt(ht / 100.0)
               + p["b2"] * ln(np.maximum(ht / np.maximum(dbh, 0.1), 0.5))
               + p["b3"] * _sqrt(bal * baph + 1)
               + p["b4"] * ln(baph + 1)
               + p["b5"] * ln(np.maximum(byi, 1) / 100.0))
        hcb = ht / (1.0 + np.exp(-eta))
        return np.minimum(np.maximum(hcb, 0.0), 0.95 * ht)

    @classmethod
    def dDBH(cls, dbh, baph, bal, cr, byi, planted, sdi=None, rht=None):
        p = cls.DDBH
        # CHANGED 12 August 2026, U31. The planted term was
        # p["b7"] * planted * np.minimum(dbh, 40) as deposited, matching HiGy.R at
        # what was then line 232, now line 279 and untruncated, where the fit and
        # koa_prediction_functions.R line 265 use
        # UNTRUNCATED diameter. Only 4 of the 6,209 fitting records are planted stems
        # above 40 cm, so the truncation was nearly invisible in fitting, but b7 is
        # POSITIVE at 0.0188938 and every projected planted trajectory in Table 8 runs
        # to the 60 cm plantation diameter cap and therefore passes 40 cm, so the
        # truncation acted on every planted row of the published table. Removing it
        # restores the fitted form. The bounding diameter is now a class attribute
        # so the as-published control can pin it back at 40 cm.
        # AMENDED 12 August 2026, later the same day. The deployed value of that
        # attribute is now KP.DDBH_PLANTED_GUARD_CM = 45.0 cm, a DECLARED
        # EXTRAPOLATION GUARD rather than a truncation: the fitted form is still
        # untruncated and U31 stands, and what is clamped is the ARGUMENT, to the
        # 45.10 cm upper edge of the planted fitting support. Under the deployed
        # harness diameter cap the guard moves one Table 8 cell by 0.4 cm; with the
        # cap released it takes planted age 100 on the high site from 214.6 to
        # 126.7 cm quadratic mean diameter. Provenance in koa_params.
        trunc = cls.ddbh_planted_trunc_cm
        dbh_planted = dbh if trunc is None else np.minimum(dbh, trunc)
        lp = (p["b0"] + p["b1"] * ln(dbh + 1) + p["b2"] * dbh
              + p["b3"] * bal**2 / ln(dbh + 5) + p["b4"] * ln(bal + 1)
              + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(baph * dbh)
              + p["b7"] * planted * dbh_planted + p["b8"] * ln(np.maximum(byi, 1)))
        return np.clip(np.exp(lp) * cls.CF_DDBH, 0, cls.ddbh_cap)

    @classmethod
    def dHT(cls, ht, baph, bal, cr, byi, planted, sdi=None, rht=None):
        p = cls.DHT
        # The planted term truncates HEIGHT at 20 m and the annual increment clips at
        # 2.0 m yr-1. Both are unchanged on 12 August 2026 and both agree with
        # HiGy.R, which is what this lineage transcribes: the truncation is HiGy.R
        # line 431 sqrt(planted * pmin(ht, 20)) and the clip is line 439. The 20 is
        # now read from koa_params.DDBH_HT_TRUNCATION_M and the 2.0 from
        # koa_params.DHT_ANNUAL_CAP, same value, one place. The parallel to U31 IS
        # RESOLVED, and in the opposite direction to U31 itself:
        # koa_prediction_functions.R was changed on 12 August 2026 to match this
        # file and HiGy.R, and now truncates the planted term at pmin(HT, 20.0) at
        # its line 363 and clips at 2.0 at its line 378, where as deposited it used
        # an untruncated height and clipped at 4 m yr-1. All three implementations
        # therefore agree on the height side as of 12 August 2026 and the divergence
        # is CLOSED rather than open.
        # ADJUDICATED BY DEPLOYMENT, NOT BY THE FIT, and that caveat survives the
        # reconciliation. The height increment fitting script has never been
        # recovered, so there is no fitted form to adjudicate either implementation
        # against; 20 m with a clip of 2.0 is chosen only because it is what HiGy.R
        # carries into FVS-HI and what every projected artifact in this deposit was
        # computed under. See the bracketed note on koa_params.DHT_ANNUAL_CAP; it
        # must be disclosed as a consistency decision and not a correctness one.
        lp = (p["b0"] + p["b1"] * ln(ht + 1) + p["b2"] * ht
              + p["b3"] * bal**2 / ln(ht + 5) + p["b4"] * ln(bal + 1)
              + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(baph * ht)
              + p["b7"] * _sqrt(planted * np.minimum(ht, KP.DDBH_HT_TRUNCATION_M))
              + p["b8"] * ln(np.maximum(byi, 1)))
        return np.clip(np.exp(lp) * cls.CF_DHT, 0, cls.dht_cap)

    @classmethod
    def surv_annual(cls, dbh, ht, cr, rht, byi, sdi=None, planted=None, yip=1.0):
        p = cls.SURV
        ht = np.maximum(ht, 0.1); dbh = np.maximum(dbh, 0.1)
        eta = (p["b0"] + p["b1"] * ht + p["b2"] * ln(ht) + p["b3"] * rht
               + p["b4"] * ln(np.clip(cr, 0.01, 0.99)) + p["b5"] * ln(ht / dbh)
               + p["b6"] * ln(np.maximum(byi, 1) / 100.0) + p["b7"] * (byi / 1000.0))
        # cloglog fitted on the ALIVE response with +ln(YIP) offset (regenerate_survival.R)
        return np.clip(1.0 - np.exp(-np.exp(eta + np.log(yip))), 0, 1)

    @classmethod
    def surv_annual_stable(cls, dbh, ht, cr, rht, byi, sdi=None, planted=None,
                           yip=1.0, cr_lim=(0.20, 0.55), rht_lim=(0.30, 0.70),
                           floor=0.90):
        """LEGACY GUARD. DO NOT USE. Retained only so that code written against
        releases at or before 1.1.0 still imports and returns the same numbers.

        History: this wrapper was added to suppress the inverted survival curve
        produced by the pre-1.2.0 `surv_annual`, which returned exp(-exp(eta)),
        the complement of the fitted ALIVE response. Clamping crown ratio to
        (0.20, 0.55) and relative height to (0.30, 0.70), and flooring annual
        survival at 0.90, hid that sign error rather than fixing it.

        `surv_annual` is correct as of 1.2.0, so the guard is no longer a
        stabiliser. It is now actively harmful: the clamps truncate crown ratio
        and relative height into exactly the interval where the corrected
        equation is least reliable and least well supported by the fitting data,
        and the 0.90 floor caps annual mortality at 10 percent regardless of
        stand state.

        For any deployed projection use `koa_survival_calibrated_py.surv_calibrated`
        (Eq. 5b), which is what every reported result in the manuscript uses. For
        the raw statistical fit use `surv_annual` directly. See
        DEPOSIT_CHANGELOG.md, Defect 1.
        """
        warnings.warn(
            "LineageA.surv_annual_stable is a deprecated legacy guard retained "
            "for backward compatibility only; it clamps CR/rHT into the least "
            "reliable region of the corrected equation. Use surv_calibrated "
            "(Eq. 5b) for projections or surv_annual for the raw fit.",
            DeprecationWarning, stacklevel=2)
        cr_c = np.clip(cr, *cr_lim); rht_c = np.clip(rht, *rht_lim)
        s = cls.surv_annual(dbh, ht, cr_c, rht_c, byi)
        return np.clip(np.maximum(s, floor), 0, 1)

# ----------------------------------------------------------------------------
# LINEAGE B  -- FVS_FINAL M1/S1 recommendation (koa_FVS_FINAL_parameters.csv)
# ----------------------------------------------------------------------------
class LineageB:
    name = "B_FVS_FINAL_M1S1"
    CF_DDBH, CF_DHT = 1.391, 1.334          # MARGINAL CFs (stress_test_summary)
    ddbh_cap, dht_cap = 4.0, 2.0

    # Diameter at which the argument of the PLANTED term of dDBH is bounded, cm.
    # ADDED 15 August 2026, at Aaron's request, following the same pattern as
    # LineageA.ddbh_planted_trunc_cm: LineageB.DDBH b7 = +0.057437 on
    # Planted * DBH sits inside the same untruncated exponential form as
    # LineageA and is about 3.0x steeper, so it is left unguarded for even
    # less reason than LineageA was before 12 August. koa_params confirmed
    # LineageB's OWN fitting support directly, on the same dDBH.csv LineageA
    # was checked against (378 planted records, max DBH.0 45.10 cm), rather
    # than assuming LineageA's edge would transfer. The FORM stays
    # untruncated; only the ARGUMENT fed into it is bounded. See
    # koa_params.DDBH_PLANTED_GUARD_CM_LINEAGEB for the full provenance,
    # including the confirmation that LineageB is not the deployed lineage
    # and this guard is therefore inert under every currently-deployed
    # configuration.
    ddbh_planted_guard_cm = KP.DDBH_PLANTED_GUARD_CM_LINEAGEB

    HCB = LineageA.HCB                       # FINAL CSV HCB == HiGy.R HCB
    # dDBH M1_BYI -- FINAL CSV
    DDBH = dict(b0=0.675575, b1=-0.722509, b2=-0.010397, b3=-0.268313, b4=0.512349,
                b5=-0.023877, b6=1.154764, b7=0.057437, b8=1.726263, b9=-4.529999)
    # dHT M1_BYI -- FINAL CSV
    DHT = dict(b0=-1.018003, b1=1.916395, b2=-0.115641, b3=-0.017570, b4=-1.314187,
               b5=0.014844, b6=0.341214, b7=0.037215, b8=2.129420, b9=-8.171071)
    # survival S1_BYI -- FINAL CSV; cloglog P(alive)=1-exp(-exp(eta+ln(YIP)))
    SURV = dict(b0=36.767230, b1=0.335877, b2=-7.566182, b3=7.372809, b4=16.294807,
                b5=-3.594212, b6=3.194631, b7=-26.781613)

    predict_HCB = LineageA.predict_HCB.__func__   # same HCB

    @classmethod
    def dDBH(cls, dbh, baph, bal, cr, byi, planted, sdi=0.0, rht=0.5):
        p = cls.DDBH
        # GUARDED 15 August 2026, same pattern as LineageA.dDBH's planted term.
        # b7 = +0.057437 sits inside the exponential with no saturation; the
        # ARGUMENT of the planted term is bounded at ddbh_planted_guard_cm
        # (koa_params.DDBH_PLANTED_GUARD_CM_LINEAGEB, 45.0 cm, LineageB's own
        # fitting-support edge on the same dDBH.csv). The functional FORM is
        # unchanged and still untruncated.
        dbh_planted = np.minimum(dbh, cls.ddbh_planted_guard_cm)
        lp = (p["b0"] + p["b1"] * ln(dbh + 1) + p["b2"] * dbh + p["b3"] * ln(bal + 1)
              + p["b4"] * ln(np.maximum(cr * dbh, 0.001)) + p["b5"] * _sqrt(sdi)
              + p["b6"] * rht + p["b7"] * planted * dbh_planted
              + p["b8"] * ln(np.maximum(byi, 1) / 100.0) + p["b9"] * byi / 1000.0)
        return np.clip(np.exp(lp) * cls.CF_DDBH, 0, cls.ddbh_cap)

    @classmethod
    def dHT(cls, ht, baph, bal, cr, byi, planted, sdi=0.0, rht=0.5):
        p = cls.DHT
        lp = (p["b0"] + p["b1"] * ln(ht + 1) + p["b2"] * ht + p["b3"] * ln(bal + 1)
              + p["b4"] * ln(np.maximum(cr * ht, 0.001)) + p["b5"] * _sqrt(sdi)
              + p["b6"] * rht + p["b7"] * planted * ht
              + p["b8"] * ln(np.maximum(byi, 1) / 100.0) + p["b9"] * byi / 1000.0)
        return np.clip(np.exp(lp) * cls.CF_DHT, 0, cls.dht_cap)

    @classmethod
    def surv_annual(cls, dbh, ht, cr, rht, byi, sdi=None, planted=None, yip=1.0):
        p = cls.SURV
        ht = np.maximum(ht, 0.1); dbh = np.maximum(dbh, 0.1)
        slender = ht / (dbh / 100.0)                  # HT_m / DBH_m
        eta = (p["b0"] + p["b1"] * ht + p["b2"] * ln(ht) + p["b3"] * rht
               + p["b4"] * ln(np.clip(cr, 0.01, 0.99)) + p["b5"] * ln(np.maximum(slender, 1))
               + p["b6"] * ln(np.maximum(byi, 1) / 100.0) + p["b7"] * (byi / 1000.0))
        # P(alive) = 1 - exp(-exp(eta + ln(YIP)))
        return np.clip(1.0 - np.exp(-np.exp(eta + ln(yip))), 0, 1)


LINEAGES = {"A": LineageA, "B": LineageB}
