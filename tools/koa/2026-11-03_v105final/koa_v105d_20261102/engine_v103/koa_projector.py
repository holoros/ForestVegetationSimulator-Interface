"""
koa_projector.py
================
Two stepping engines for the koa component equations:

1. project_cohort(...)      -- stand-level even-aged cohort. With bounded=True it
   reproduces koa_projection.py's operational guardrails (self-thinning from
   absolute SDI 300 down to SDI 275, 0.65/0.35 dynamic-static HT blend, ceiling
   min(HT, 25+BYI/55), hard DBH max). With bounded=False it strips those
   guardrails to expose the *raw* increment behavior that FVS-HI/HiGy.R would
   show, since HiGYOneStand applies none of them (only per-step increment caps,
   FVS density mortality, and TreeSzCp size caps).

2. project_psp(...)         -- individual-tree list engine mirroring
   HiGYOneStand(): per-tree BA, BAL = cumsum(BA) over descending DBH, plot QMD /
   SDI / htmax, HCB->CR, annual dDBH/dHT, annual survival -> expf decay, 2.5%/yr
   crown-recession limit, size caps. Used to project real PSP tree lists and
   validate against observed remeasurements.

SDI (metric Reineke, used as a lineage-B covariate and for the envelope):
   SDI = TPH * (QMD/25)^1.605, computed by sdi_of() below as
   tph * (qmd / koa_params.INDEX_DIAMETER_CM) ** koa_params.SDI_OF_EXPONENT.
   [DIVERGENCE CLOSED 12 August 2026. As deposited this docstring and this
   module ran on the exponent 1.6, matching the HiGy.R comment
   expf*(qmd/25)^1.6. koa_params.SDI_OF_EXPONENT was repointed on 12 August
   2026 from the literal 1.6 to the REINEKE_EXPONENT alias, 1.605, which is the
   exponent the equation of record specifies and the one the ramp thresholds,
   the Reineke identity behind the basal area fallback and the
   diameter-conditional bound are all stated on; final/koa_survival_calibrated.R
   lines 605-619 set out why 1.6 is the wrong scale. sdi_of() reads
   SDI_OF_EXPONENT at call time, so it already returns the 1.605 quantity and no
   line of code in this module changed on 12 August 2026. This was a deliberate
   decision and not the repair of a typo, it moves every projected trajectory,
   and the record of the decision sits at koa_params.py under SDI_OF_EXPONENT.
   The as-published 1.6 survives only as
   koa_params.SDI_OF_EXPONENT_AS_PUBLISHED, for pinning the as-published control
   variant of Table 8, and nothing in the production path may read it. Note that
   the HiGy.R comment at its line 1153 still reads expf*(qmd/25)^1.6 and is now
   the last carrier of 1.6 in the tree.]

RESPECIFIED 2026-08-07. The scalar SDI_MAX = 500.0 that this module carried is
WITHDRAWN, along with the percent-of-SDImax reporting built on it. The bounded
self-thinning guardrail is now stated in ABSOLUTE SDI (trigger 300, target 275),
which is numerically identical to the deposited 0.60/0.55-of-500 form and needs
no density maximum. Every constant comes from koa_params.py. The module level
name SDI_MAX is retained but bound to a poisoned sentinel, and the sdi_max
keyword of project_cohort is retained but raises if a value is supplied.
"""
import numpy as np, pandas as pd
from koa_equations import predict_HT, predict_HCB, bal_fraction, stand_bal, LINEAGES, rd_from_sdi, stage3_w   # v105d
import koa_params as P
from koa_mortality_garcia import (mort_garcia, h40_from_list, h40_single_cohort, h_from_qmd,
                                  engine_beta, engine_state, stand_mortality,
                                  relative_density, regular_mortality, background_mortality)

# ---------------------------------------------------------------------------
# MORTALITY ENGINE, 4 September 2026. The default mortality path of both
# projectors is the Garcia (2009) three-stage component of
# koa_mortality_garcia.py (koa_params.MORT_ENGINE = "garcia"). The calibrated
# density ramp that drove every projection through v81 is RETIRED and is
# reached only by passing mort_engine="ramp" EXPLICITLY, in which case the
# pre-4 September code path runs unchanged (surv_fn, surv_mode, guardrail and
# all). A caller that passes a surv_fn without mort_engine="ramp" is refused,
# so a script written for the ramp fails loudly instead of silently running the
# retired rate under the new default. See _resolve_engine().
# ---------------------------------------------------------------------------
def _resolve_engine(mort_engine, surv_fn=None, surv_mode=None):
    eng = P.MORT_ENGINE if mort_engine is None else str(mort_engine)
    if eng not in P.MORT_ENGINES:
        raise ValueError("mort_engine must be one of %r (koa_params.MORT_ENGINES); got %r" % (P.MORT_ENGINES, eng))
    # EXTENDED 5 September 2026: five arms (koa_params.MORT_ENGINES). Every Garcia-family
    # arm takes the Garcia path below; the arms differ in the state variable and beta
    # (koa_mortality_garcia.engine_state / engine_beta) and C4 adds the ramp term.
    if eng in P.GARCIA_FAMILY and surv_fn is not None:
        raise RuntimeError(
            "A surv_fn was supplied but the deployed mortality engine is the Garcia "
            "three-stage component (koa_params.MORT_ENGINE = 'garcia'), which takes no "
            "survival function. The density ramp is RETIRED (4 September 2026). To run "
            "the retired arm on purpose pass mort_engine='ramp' explicitly.")
    if eng in P.GARCIA_FAMILY and surv_mode == "calib_alloc":
        raise RuntimeError(
            "surv_mode='calib_alloc' names the RETIRED ramp allocation path. Under the "
            "deployed Garcia engine allocation is by relative size automatically; pass "
            "mort_engine='ramp' explicitly to run the retired arm.")
    return eng

SDI_MAX = P.SDIMAX_WITHDRAWN   # WITHDRAWN. Name retained so importers fail loudly.
FORM_FACTOR = P.FORM_FACTOR    # 0.40; V = BAPH * meanHT * FF
def sdi_of(tph, qmd): return tph * (np.maximum(qmd, 0.1) / P.INDEX_DIAMETER_CM) ** P.SDI_OF_EXPONENT


# ---------------------------------------------------------------------------
def ht_monotone_guard(ht, enabled=None):
    """HARNESS-LEVEL monotone height guardrail. Returns (guarded, binds).

    guarded is the running maximum of ht within the trajectory, so the reported series is
    non-decreasing in age; binds is 1 wherever the guard raised a value and 0 where it did
    not, which is what makes every guarded cell a DECLARED BOUND rather than a projection.
    Controlled by koa_params.HARNESS_HT_MONOTONE.

    THIS FUNCTION DOES NOT TOUCH predict_HT. The fitted static height equation still turns
    over beyond roughly QMD 87 cm and BAPH 83 m2 ha-1; the harness only stops reporting the
    fall. Every producer of a height series calls this, so there is one guard and not three
    implementations of one.
    """
    if enabled is None:
        enabled = bool(getattr(P, "HARNESS_HT_MONOTONE", False))
    h = np.asarray(ht, float)
    if not enabled:
        return h.copy(), np.zeros(h.shape, dtype=int)
    g = np.maximum.accumulate(h)
    return g, (g > h).astype(int)


RELEASE = set()
# Harness bounds released for the current run; any subset of P.HARNESS_BOUNDS,
# that is {"dbh_cap", "ht_ceiling", "ht_blend"}. Empty means every bound is
# active, which is the deposited default and reproduces the published
# behaviour exactly. Added 7 August 2026: the Table 8 regeneration needed to
# account for the bound release one bound at a time rather than through the
# single bounded=False switch, which releases all three at once and cannot
# tell the diameter cap apart from the height ceiling. That release mechanism
# lived only in an undeposited patch, so the deposit did not contain the
# engine that produced its own Table 8. It does now.
#
# A released bound must be DECLARED wherever the output is reported. Variant
# of record for Table 8 is RELEASE = {"dbh_cap"}: the diameter cap is a harness
# guardrail and reporting it as a confidence limit was the published defect.
# RELEASE = set(P.HARNESS_BOUNDS) is a disclosed sensitivity only and is
# WITHDRAWN from publication: it yields mean stand heights of 38.58 m against a
# tallest measured koa stem of 34.14 m in AK_TREE.csv.


def project_cohort(byi, planted, lineage, bounded=True, surv_mode="cohort", surv_fn=None,
                   init_dbh=None, init_tph=None, init_age=1, max_age=100,
                   ddbh_mult=1.0, dht_mult=1.0, mort_mult=1.0, sdi_max=None,
                   guardrail_trigger_sdi=P.GUARDRAIL_TRIGGER_SDI,
                   guardrail_target_sdi=P.GUARDRAIL_TARGET_SDI, mort_engine=None):
    # mort_engine: None -> koa_params.MORT_ENGINE ("garcia", deployed 4 September
    #   2026). "garcia": stand mortality from koa_mortality_garcia.mort_garcia on
    #   H40 = K_TOP * HT (A2), realised H40 change over the previous year (one
    #   year lag, floor only in the first year), guardrail off. "ramp": the
    #   RETIRED pre-v82 path below, exactly as deposited, explicit only.
    # surv_mode (ramp arm, surv_fn None): 'cohort'=raw eqn floored at 0.5/yr
    #            (koa_projection.py crutch), 'raw'=raw eqn no floor (FVS
    #            behavior), 'stable'=clamped+floored
    # sdi_max is RETAINED for signature compatibility only and must not be used:
    # the scalar is withdrawn. Set the guardrail in absolute SDI instead.
    engine = _resolve_engine(mort_engine, surv_fn)
    if sdi_max is not None:
        raise RuntimeError(
            "project_cohort(sdi_max=...) is WITHDRAWN. No scalar SDImax is "
            "deployed: 500, 933 and 1350 metric are all withdrawn "
            "(final/koa_survival_calibrated.R lines 14-19). The bounded "
            "self-thinning guardrail is now stated in absolute SDI; pass "
            "guardrail_trigger_sdi and guardrail_target_sdi instead."
        )
    L = LINEAGES[lineage]
    dbh_max = P.harness_dbh_max(planted)
    if init_dbh is None: init_dbh = P.harness_init_dbh(planted)
    if init_tph is None: init_tph = P.harness_init_tph(planted)
    ages = list(range(init_age, max_age + 1)); n = len(ages)
    rec = {k: np.zeros(n) for k in ["QMD","HT","BAPH","TPH","CR","SDI","HCB","VOL",
                                    "ht_guard"]}
    rec["age"] = np.array(ages)

    DBH, TPH = float(init_dbh), float(init_tph)
    QMD = DBH; BAPH = TPH * np.pi/4 * (DBH/100)**2
    HT = float(predict_HT(DBH, max(BAPH,0.1), QMD, byi)); CR = 0.65
    # MONOTONE HEIGHT GUARD state, ADDED 8 September 2026 (deposit 1.7.0). ht_run_max is the
    # running maximum carried forward within this trajectory; ht_guard_flag records whether
    # the guard raised the height the NEXT iteration records, so the flag lands on the same
    # row as the value it declares.
    ht_run_max = HT; ht_guard_flag = 0
    h40_prev = None                                  # Garcia engine: realised H40 of the previous year
    for step, age in enumerate(ages):
        SDI = sdi_of(TPH, QMD)
        # CORRECTED 8 September 2026, deposit 1.6.0. Was BAPH * bal_fraction(1.0)
        # = 0.10774 * BAPH, which is the LARGEST stem's share of stand basal area and
        # not the average stem's, because bal_fraction was fitted on DBH / DBH.max and
        # not on DBH / QMD. The cohort fraction is now a linear function of the
        # cohort's quadratic mean diameter, fitted against the deposited target and
        # cross-validated on plot identity. TPH is passed so that the declared
        # sensitivity arm "linear_qmd_tph" can be run without editing this line; the
        # deployed arm does not read it. koa_params.COHORT_BAL_MODE =
        # "deployed_boundary" restores the pre-correction value exactly.
        BAL_avg = float(stand_bal(BAPH, qmd=QMD, tph=TPH))
        # BAL_dom is WITHDRAWN. It was BAPH * bal_fraction(1.5), it was assigned and
        # never read anywhere in this module, and rDBH = 1.5 lies outside the fitted
        # support of a covariate bounded at 1.0.
        HCB = float(predict_HCB(DBH, HT, BAL_avg, BAPH, byi, rd=rd_from_sdi(SDI)))   # v105d rd
        CR = max(0.20, (HT-HCB)/HT) if HT > 0.1 else 0.65
        rHT = 0.50
        rec["ht_guard"][step] = ht_guard_flag
        rec["QMD"][step], rec["HT"][step], rec["BAPH"][step] = QMD, HT, BAPH
        rec["TPH"][step], rec["CR"][step], rec["SDI"][step] = TPH, CR, SDI
        rec["HCB"][step], rec["VOL"][step] = HCB, BAPH*HT*FORM_FACTOR
        if step == n-1: break

        if engine == "ramp" and bounded and surv_fn is None:   # self-thinning guardrail (off when a survival function or the Garcia engine drives mortality)
            # Absolute-SDI form. Identical to the deposited 0.60/0.55-of-500
            # rule: thin to guardrail_target_sdi whenever SDI exceeds
            # guardrail_trigger_sdi. No density maximum enters.
            if SDI > guardrail_trigger_sdi:
                tr = guardrail_target_sdi/SDI; tphn = TPH*tr
                DBH *= (TPH/max(tphn,1))**P.GUARDRAIL_DBH_EXPONENT; QMD = DBH; TPH = tphn
                BAPH = TPH*np.pi/4*(QMD/100)**2

        if engine in P.GARCIA_FAMILY:
            # Stage 2. State variable of the single average cohort: K_TOP * HT (A2)
            # for the H40 arms, H_QMD for the QMD arms (koa_mortality_garcia.engine_state).
            # The step is driven by the realised change over the previous year; in
            # the first year only the A1 floor acts. C4 adds the retired ramp term.
            # A1' arms (C6 to C8) additionally take the current stand density, so the
            # background term the step floors on is density dependent instead of flat.
            h40_now = engine_state(engine, HT, QMD)
            rd_now = (relative_density(TPH, h40_now)
                      if (engine in P.GARCIA_DD_ENGINES and np.isfinite(h40_now)) else None)
            m = stand_mortality(engine, TPH, h40_prev, h40_now, planted=1 if planted else 0,
                                sdi=SDI, rd=rd_now)
            if engine == "garcia_max_ramp":
                from koa_survival_calibrated_py import surv_calibrated
                m_ramp = 1.0 - float(surv_calibrated(DBH, HT, CR, rHT, byi, bal=BAL_avg, baph=BAPH,
                                                     planted=planted, sdi=SDI))
                m = max(m, m_ramp)
            h40_prev = h40_now
            ps = float(np.clip(1.0 - mort_mult*m, 0.0, 1.0))
        elif surv_fn is not None:
            ps = float(np.atleast_1d(surv_fn(DBH, HT, CR, rHT, byi,
                                             bal=BAL_avg, baph=BAPH, planted=planted, sdi=SDI))[0])
            ps = np.clip(1.0 - mort_mult*(1.0-ps), 0.0, 1.0)
        elif surv_mode == "stable":
            ps = float(L.surv_annual_stable(DBH, HT, CR, rHT, byi))
            ps = np.clip(1.0 - mort_mult*(1.0-ps), 0.0, 1.0)
        elif surv_mode == "raw":
            ps = float(L.surv_annual(DBH, HT, CR, rHT, byi, sdi=SDI, planted=planted))
            ps = np.clip(1.0 - mort_mult*(1.0-ps), 0.0, 1.0)
        else:  # 'cohort' (koa_projection.py): floor at 0.50/yr
            ps = float(L.surv_annual(DBH, HT, CR, rHT, byi, sdi=SDI, planted=planted))
            ps = np.clip(1.0 - mort_mult*(1.0-ps), 0.50, 1.0)
        TPH *= ps
        if TPH < P.HARNESS_TPH_COLLAPSE:
            for s2 in range(step+1, n):
                for k in rec:
                    if k != "age": rec[k][s2] = rec[k][step]
            break
        BAPH = TPH*np.pi/4*(QMD/100)**2

        dD = float(L.dDBH(DBH, BAPH, BAL_avg, CR, byi, planted, sdi=SDI, rht=rHT))*ddbh_mult
        dH = float(L.dHT(HT, BAPH, BAL_avg, CR, byi, planted, sdi=SDI, rht=rHT))*dht_mult
        DBH += dD; QMD = DBH; HT += dH
        if bounded:                                  # HT blend + ceiling + hard cap
            ht_static = float(predict_HT(DBH, BAPH, QMD, byi))
            if "ht_blend" not in RELEASE:
                HT = P.HARNESS_HT_BLEND_DYNAMIC*HT + P.HARNESS_HT_BLEND_STATIC*ht_static
            if "ht_ceiling" not in RELEASE:
                HT = min(HT, P.harness_ht_ceiling(byi))
            # MONOTONE HEIGHT GUARD, in the bounds block beside the ceiling and on the same
            # terms: it is a harness bound, it feeds back into the state exactly as the
            # ceiling and the diameter cap do, and it is NOT one of the three releasable
            # bounds (see koa_params.HARNESS_HT_MONOTONE).
            if P.HARNESS_HT_MONOTONE:
                ht_guard_flag = 1 if HT < ht_run_max else 0
                HT = max(HT, ht_run_max)
                ht_run_max = HT
            if "dbh_cap" not in RELEASE:
                DBH = min(DBH, dbh_max); QMD = DBH
        BAPH = TPH*np.pi/4*(QMD/100)**2
    return pd.DataFrame(rec)


# ---------------------------------------------------------------------------
def project_psp(trees, byi, planted, lineage, n_years, surv_mode="raw", surv_fn=None,
                alloc_beta=P.ALLOC_BETA, ingrowth=False, ingrowth_byi_c=0.0,
                recruit_dbh=P.ING_RECRUIT_DBH_CM,
                use_size_caps=True, dbh_max=None, ht_max=P.HARNESS_HT_MAX_PSP_M, return_traj=False,
                mort_engine=None):
    """trees: DataFrame with dbh(cm), ht(m), cr(0-1), expf(/ha). One plot.
    mort_engine: None -> koa_params.MORT_ENGINE ("garcia", deployed 4 September
    2026): stand mortality from koa_mortality_garcia.mort_garcia on H40 computed
    EXACTLY from the tree list (koa_mortality_garcia.h40_from_list; K_TOP * HT
    only when the list holds a single record, A2), realised H40 change over the
    previous year (one-year lag, floor only in the first year), allocated to
    trees by relative diameter (Stage 3, koa_params.ALLOC_MODE "size") through
    renormalize_to_stand_rate. "ramp": the RETIRED pre-v82 path, explicit only;
    then surv_mode is 'raw'|'stable'|'calib_alloc' as deposited. Numpy engine;
    return_traj gives the annual stand-summary trajectory."""
    from koa_survival_calibrated_py import surv_calibrated, renormalize_to_stand_rate
    from koa_ingrowth import ingrowth_annual
    engine = _resolve_engine(mort_engine, surv_fn, surv_mode)
    L = LINEAGES[lineage]
    surv = L.surv_annual_stable if surv_mode == "stable" else L.surv_annual
    if dbh_max is None: dbh_max = P.harness_dbh_max(planted)
    dbh = trees.dbh.to_numpy(float); ht = trees.ht.to_numpy(float)
    cr = trees.cr.to_numpy(float); expf = trees.expf.to_numpy(float)
    traj = []; recs = []; _mortba = []; _dbhmax = []
    h40_prev = None                                  # Garcia engine: realised H40 of the previous year
    for _ in range(int(n_years)):
        order = np.argsort(-dbh)
        dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]
        ba = (dbh**2*0.00007854)*expf
        # CORRECTED 8 September 2026, deposit 1.6.0. Was np.cumsum(ba) - ba, the
        # conventional expansion-weighted basal area in strictly larger competitors,
        # which is a different quantity from the one the dDBH, dHT and HCB coefficients
        # were fitted on and cost this path 1.4 to 3.5 percent in predicted annual
        # increment (RT-F, section 3). The percentile rule of record now runs here,
        # expf weighted since v103 (stand_bal with expf, KP.BAL_PERCENTILE_WEIGHTED).
        if P.PSP_BAL_MODE == "cumsum":
            bal = np.cumsum(ba) - ba
        else:
            bal = stand_bal(baph=(ba.sum()), dbh=dbh, expf=expf)   # weighted percentile, v103
        baph = ba.sum(); tph = expf.sum()
        qmd = np.sqrt(baph/(0.00007854*tph)) if tph > 0 else 0.0
        sdi = sdi_of(tph, qmd); htmax = ht.max() if len(ht) else 0.1
        if return_traj:
            traj.append((baph, tph, qmd, sdi)); _dbhmax.append(float(dbh.max()) if len(dbh) else 0.0)
        hcb = predict_HCB(dbh, ht, bal, baph, byi, rd=rd_from_sdi(sdi))   # v105d rd
        cr = np.clip(1 - hcb/np.maximum(ht, 0.1), 0.05, 0.95)
        rht = ht/max(htmax, 0.1)
        below_bh = ht < 1.3716
        dD = np.where(below_bh, 0.0, L.dDBH(dbh, baph, bal, cr, byi, planted, sdi=sdi, rht=rht))
        dH = L.dHT(ht, baph, bal, cr, byi, planted, sdi=sdi, rht=rht)
        if engine in P.GARCIA_FAMILY:
            # Stage 2 on the tree list. H40 arms: H40 exact from the list (A2), a
            # single-record list is one average cohort and takes K_TOP * HT. QMD
            # arms: H_QMD of the stand quadratic mean diameter. C4 adds the ramp term.
            if engine in P.GARCIA_QMD_ENGINES:
                h40_now = float(h_from_qmd(qmd)) if qmd > 0 else float("nan")
            else:
                h40_now = h40_from_list(dbh, ht, expf) if len(dbh) > 1 else h40_single_cohort(ht[0])
            rd_now = (relative_density(tph, h40_now)
                      if (engine in P.GARCIA_DD_ENGINES and np.isfinite(h40_now)) else None)
            m_stand = stand_mortality(engine, tph, h40_prev, h40_now, planted=1 if planted else 0,
                                      sdi=sdi, rd=rd_now)
            if engine == "garcia_max_ramp":
                m_stand = max(m_stand, 1.0 - float(surv_calibrated(qmd, htmax, 0.5, 0.5, byi, baph=baph,
                                                                    planted=planted, sdi=sdi)))
            if np.isfinite(h40_now): h40_prev = h40_now
            # Stage 3: allocation by relative diameter (ALLOC_MODE "size" of
            # record), renormalised to the stand rate by the single carrier.
            if getattr(P, "ALLOC_MODE", "size") == "tree_eq":
                w = stage3_w(dbh, rht, baph, bal, sdi)   # Stage 3 ordering from koa_params.STAGE3_COEF (A4-D3, 2026-10-30)
            else:
                w = np.exp(-alloc_beta*(dbh/max(qmd,0.1) - 1.0))
            wbar = np.sum(w*expf)/max(np.sum(expf), 1e-9)
            m_i = m_stand*w/max(wbar, 1e-9)
            ps = 1.0 - renormalize_to_stand_rate(m_i, expf, m_stand, cap=P.ALLOC_MORT_CAP)
        elif surv_mode == "calib_alloc":
            m_stand = 1.0 - float(surv_calibrated(qmd, htmax, 0.5, 0.5, byi, baph=baph, planted=planted, sdi=sdi))
            if getattr(P, "ALLOC_MODE", "size") == "tree_eq":
                # Allocation weight of record since 2026-08-15: the fitted
                # Lineage A survivor equation, entering as ordering only.
                w = stage3_w(dbh, rht, baph, bal, sdi)   # Stage 3 ordering from koa_params.STAGE3_COEF (A4-D3, 2026-10-30)
            else:
                w = np.exp(-alloc_beta*(dbh/max(qmd,0.1) - 1.0))
            wbar = np.sum(w*expf)/max(np.sum(expf), 1e-9)
            # R1, 18 August 2026. The weighted mean of m_stand*w/wbar is
            # m_stand by algebra, but the per-tree cap discards whatever sits
            # above it, so as written this line delivered LESS mortality than
            # the stand equation prescribed and said nothing about it. The
            # rescale that restores the constraint lives in ONE place,
            # koa_survival_calibrated_py.renormalize_to_stand_rate, which
            # allocate() also calls; it is not reimplemented here on purpose.
            # It also carries the P.ALLOC_RENORMALIZE gate and reads the cap
            # from P.ALLOC_MORT_CAP, which this line used to hardcode as 0.95.
            m_i = m_stand*w/max(wbar, 1e-9)
            ps = 1.0 - renormalize_to_stand_rate(m_i, expf, m_stand,
                                                 cap=P.ALLOC_MORT_CAP)
        elif surv_fn is not None:
            ps = surv_fn(dbh, ht, cr, rht, byi, bal=bal, baph=baph, planted=planted, sdi=sdi)
        else:
            ps = surv(dbh, ht, cr, rht, byi, sdi=sdi, planted=planted)
        _eo = expf
        expf = np.maximum(expf*ps, 1e-5)
        _mortba.append(float(((dbh**2*0.00007854)*(_eo-expf)).sum()))   # output only
        nd = dbh + dD; nh = ht + dH
        if use_size_caps:
            nd = np.where(nd > dbh_max, dbh, nd); nh = np.where(nh > ht_max, ht, nh)
        dbh, ht = nd, nh
        if ingrowth:
            n_rec = ingrowth_annual(sdi=sdi, planted=planted, byi=byi, byi_c=ingrowth_byi_c)
            recs.append(n_rec)
            if n_rec > 1e-3:
                rh = float(predict_HT(recruit_dbh, baph, max(qmd,1.0), byi, dbhmax=max(float(dbh.max()), recruit_dbh)))
                dbh = np.append(dbh, recruit_dbh); ht = np.append(ht, rh)
                cr = np.append(cr, 0.6); expf = np.append(expf, n_rec)
        else:
            recs.append(0.0)
        # cap list size: bin to 0.5 cm DBH classes when large (keeps it fast)
        if len(dbh) > 300:
            keyb = np.round(dbh*2)/2.0
            uk = np.unique(keyb); ndbh=[]; nht=[]; ncr=[]; nexpf=[]
            for k in uk:
                m = keyb==k; e=expf[m].sum()
                ndbh.append(np.average(dbh[m],weights=expf[m])); nexpf.append(e)
                nht.append(np.average(ht[m],weights=expf[m])); ncr.append(np.average(cr[m],weights=expf[m]))
            dbh=np.array(ndbh); ht=np.array(nht); cr=np.array(ncr); expf=np.array(nexpf)
    baph = (dbh**2*0.00007854*expf).sum(); tph = expf.sum()
    qmd = np.sqrt(baph/(0.00007854*tph)) if tph > 0 else 0.0
    out = dict(QMD=qmd, BAPH=baph, TPH=tph, SDI=sdi_of(tph, qmd),
               HTmax=ht.max() if len(ht) else 0.0, VOL=baph*ht.mean()*FORM_FACTOR)
    if return_traj:
        tj = pd.DataFrame(traj, columns=["BAPH","TPH","QMD","SDI"])
        tj["ingrowth"] = recs[:len(tj)]
        tj["MORT_BA"] = _mortba[:len(tj)]; tj["DBHMAX"] = _dbhmax[:len(tj)]
        out["traj"] = tj
    return out
