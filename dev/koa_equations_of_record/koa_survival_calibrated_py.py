"""koa_survival_calibrated_py.py

Calibrated koa annual survival, transcribed from the equation of record
final/koa_survival_calibrated.R (koa.SURV.calibrated, lines 374-446).

    annual mortality = base(origin) + MAXLIFT * frac,  capped at MORT_MAX
    frac             = clip((SDI - ONSET_SDI) / (FULL_SDI - ONSET_SDI), 0, 1)
    annual survival  = 1 - annual mortality

The ramp is parameterised in ABSOLUTE stand density index: onset at SDI 200
metric (79 imperial), full lift at SDI 850 metric (335 imperial). Design follows
the data diagnostics (tune_survival.R): mortality is a low density-independent
background that differs by origin, plus a linear density-dependent
self-thinning term. BYI is intentionally NOT a direct mortality driver; its
apparent effect in the data is confined to one cluster of high-BYI natural
plots that by construction contains no plantations, so an origin by BYI
interaction is not identifiable. BYI influences long-term density correctly
through GROWTH driving stands into self-thinning sooner.

RESPECIFIED 2026-08-07. This module previously carried a RETIRED
parameterisation, a scalar SDI_MAX = 500.0 with a relative-density ramp at
onset RD 0.65 and full lift RD 0.85, which places the absolute onset at SDI 325
and full lift at SDI 425. That is not the equation of record and it diverges
from it materially between SDI 200 and SDI 850. NO SCALAR SDImax IS DEPLOYED.
Relative density is a reporting convenience with no dynamical role. Every
constant now comes from koa_params.py, which is the single source of truth.

Public interface is unchanged: surv_calibrated(...) and make(**kw). The module
level name SDI_MAX is retained but bound to a poisoned sentinel that raises
with an explanation if anything tries to use it.
"""
import warnings

import numpy as np

import koa_params as P

# --- Withdrawn scalar, name retained so importers fail loudly, not silently ---
SDI_MAX = P.SDIMAX_WITHDRAWN

# --- Module level ramp parameters. Read INSIDE the function body, not bound as
# --- default arguments, so a diagnostics caller can override them by
# --- assignment (see koa_longterm_validation.ramp_sensitivity).
ONSET_SDI = P.ONSET_SDI     # 200.0, final/koa_survival_calibrated.R line 490
FULL_SDI = P.FULL_SDI       # 850.0, final/koa_survival_calibrated.R line 493
KR = P.KR                   # Reineke constant, R line 517


def sdi_from_baph(baph, qmd=None):
    """Basal area fallback, inverted through the Reineke identity at the stand's
    own quadratic mean diameter when one is supplied and at QMD_REF_CM = 20 cm
    otherwise. final/koa_survival_calibrated.R lines 524-534. This path no
    longer passes through any SDImax, which is what broke the old circularity."""
    dq = P.QMD_REF_CM if qmd is None else np.maximum(np.asarray(qmd, float), 0.1)
    return np.asarray(baph, float) / (KR * dq ** P.DQ_EXPONENT)


def surv_calibrated(dbh, ht, cr, rht, byi, bal=0.0, baph=0.0, planted=0, sdi=None,
                    qmd=None,
                    base_nat=P.BASE_NAT, base_plt=P.BASE_PLT,
                    onset=None, full=None,
                    onset_sdi=None, full_sdi=None,
                    maxlift=P.MAXLIFT, mort_max=P.MORT_MAX):
    """Annual survival probability.

    Mortality = base(origin) + a linear self-thinning lift that starts at
    ONSET_SDI (200), rises linearly to maxlift at FULL_SDI (850), and plateaus
    above, capped at mort_max. Density is ABSOLUTE SDI. If sdi is not supplied,
    it is derived from baph through the Reineke identity (see sdi_from_baph);
    supply qmd to make that fallback exact at the stand's own diameter.

    onset / full are the diagnostics overrides of the R source (lines 389-390,
    429-430) and are now in ABSOLUTE SDI, NOT relative density. onset_sdi /
    full_sdi are accepted as explicit synonyms. BYI, bal, ht, cr and rht are
    accepted for signature compatibility with the other survival functions in
    this deposit and are deliberately unused.
    """
    if sdi is None:
        sdi_use = sdi_from_baph(baph, qmd)
    else:
        sdi_use = np.asarray(sdi, float)

    on_sdi = ONSET_SDI if (onset is None and onset_sdi is None) else \
        (onset_sdi if onset is None else onset)
    fl_sdi = FULL_SDI if (full is None and full_sdi is None) else \
        (full_sdi if full is None else full)

    base = base_plt if planted == 1 else base_nat
    frac = np.clip((sdi_use - on_sdi) / (fl_sdi - on_sdi), 0.0, 1.0)
    mort = np.clip(base + maxlift * frac, 0.0, mort_max)
    return 1.0 - mort


def renormalize_to_stand_rate(m_i, expf, m_stand, cap=None,
                              rtol=1e-12, max_iter=200):
    """Rescale per-tree mortality rates so the expansion-factor-weighted mean
    equals the stand rate AFTER the per-tree cap is applied. R1, 2026-08-18.

    m_i is the uncapped allocation m_stand * w_i / wbar, whose weighted mean is
    m_stand by construction. Clipping it at cap destroys that: mortality above
    the cap is lost and nothing recovers it, so the stand under delivers. This
    solves for the scalar lambda >= 0 with

        sum_i expf_i * min(lambda * m_i, cap) / sum_i expf_i == m_stand

    and returns clip(lambda * m_i, 0, cap). The left side is continuous and
    non-decreasing in lambda, is 0 at lambda = 0 and tends to cap as lambda
    grows, so the root exists if and only if m_stand < cap. Bracketing is
    geometric on lambda, then bisection to relative tolerance rtol.

    Two early returns, both exact rather than approximate. If the cap does not
    bind, lambda = 1 is already the root and the unrescaled clip is returned, so
    those stands are BITWISE IDENTICAL to the pre-2026-08-18 allocator; only
    capped stands move. If P.ALLOC_RENORMALIZE is False the same unrescaled clip
    is returned unconditionally, which reproduces the as-published behaviour
    exactly (see koa_params.ALLOC_RENORMALIZE_AS_PUBLISHED).

    If m_stand >= cap the constraint is infeasible, since the cap bounds every
    tree. That case warns, naming the stand rate, and returns every tree at the
    cap, which is the closest feasible allocation. It is tested first, ahead of
    the no-bind early return, because an infeasible stand rate can arrive with
    no individual m_i above the cap and must not slip out through that return.
    Infeasibility does not arise in the deposited scenarios: the largest stand
    rate reached is 0.153 against a cap of 0.95, over all 90,300 site-years of
    the 300-replicate uneven-aged regeneration in both allocation modes.

    This function is the SINGLE carrier of the algebra. allocate() below and the
    calib_alloc branch of koa_projector.project_psp both call it. Do not inline
    a second copy in either place.
    """
    cap = float(P.ALLOC_MORT_CAP) if cap is None else float(cap)
    m = np.asarray(m_i, float)
    capped = np.clip(m, 0.0, cap)
    if not getattr(P, "ALLOC_RENORMALIZE", True):
        return capped                      # as-published path, clip and all
    e = np.asarray(expf, float)
    esum = float(np.sum(e))
    ms = float(m_stand)
    if esum <= 0.0 or m.size == 0 or ms <= 0.0:
        return capped
    if ms >= cap:
        # Tested BEFORE the no-bind early return on purpose. A stand rate at or
        # above the cap is infeasible even when no individual m_i happens to
        # exceed the cap, and that case must warn rather than fall through the
        # early return and under deliver silently, which is the original defect.
        warnings.warn(
            "renormalize_to_stand_rate: stand mortality rate %.6g is at or "
            "above the per-tree cap %.6g, so no allocation can deliver it. "
            "Every tree is set to the cap and the stand under delivers by "
            "%.6g." % (ms, cap, ms - cap),
            RuntimeWarning, stacklevel=2)
        return np.full(m.shape, cap)
    if float(np.max(m)) <= cap:
        return capped                      # lambda = 1 exactly, nothing to do

    def wmean(lam):
        return float(np.sum(e * np.minimum(lam * m, cap)) / esum)

    lo, hi = 1.0, 1.0                      # wmean(1) <= m_stand, cap binds here
    for _ in range(max_iter):
        if wmean(hi) >= ms:
            break
        lo, hi = hi, hi * 2.0
    else:
        warnings.warn(
            "renormalize_to_stand_rate: failed to bracket lambda for stand "
            "rate %.6g under cap %.6g; returning the capped allocation "
            "unrescaled." % (ms, cap), RuntimeWarning, stacklevel=2)
        return capped
    for _ in range(max_iter):
        if hi - lo <= rtol * hi:
            break
        mid = 0.5 * (lo + hi)
        if wmean(mid) < ms:
            lo = mid
        else:
            hi = mid
    return np.clip(hi * m, 0.0, cap)


def allocate(dbh, expf, qmd, m_stand, beta=P.ALLOC_BETA,
             ht=None, cr=None, rht=None, byi=None, mode=None):
    """Distribute the STAND annual mortality rate across trees, constrained so
    the expansion-factor-weighted mean per-tree mortality equals the stand rate.

    That constraint is ENFORCED as of 2026-08-18, by
    renormalize_to_stand_rate(). Between the deposit and 17 August it was
    asserted here and nowhere implemented: the P.ALLOC_MORT_CAP clip below
    discarded whatever mortality sat above the cap, so the weighted mean came
    out under the stand rate. See koa_params.ALLOC_RENORMALIZE for the defect,
    the fix and the feasibility condition m_stand < cap. Setting
    P.ALLOC_RENORMALIZE False returns the pre-18 August behaviour, and where the
    cap does not bind the two are bitwise identical.

    mode "tree_eq" (record since 2026-08-15, P.ALLOC_MODE): weight is the fitted
    Lineage A survivor equation annual mortality; requires ht, cr, rht, byi.
    mode "size": the as-published exp(-beta*(DBH/QMD - 1)) size weight.
    When mode is None: follows P.ALLOC_MODE if the tree state is supplied,
    else the size weight, which keeps pre-2026-08-15 call sites (and
    test_engine_equivalence.py, which tests the as-published path) unchanged.
    final/koa_survival_calibrated.R koa.SURV.allocate is the R carrier."""
    if mode is None:
        mode = getattr(P, "ALLOC_MODE", "size") if ht is not None else "size"
    if mode == "tree_eq":
        if ht is None or cr is None or rht is None or byi is None:
            raise ValueError("allocate(mode='tree_eq') needs ht, cr, rht, byi")
        from koa_equations import LINEAGES
        dbh_a, ht_a = np.asarray(dbh, float), np.asarray(ht, float)
        cr_a, rht_a = np.asarray(cr, float), np.asarray(rht, float)
        w = np.clip(1.0 - LINEAGES["A"].surv_annual(dbh_a, ht_a, cr_a, rht_a, byi),
                    1e-9, 1.0)
    else:
        rdbh = np.asarray(dbh, float) / max(float(qmd), 0.1)
        w = np.exp(-beta * (rdbh - 1.0))
    expf_a = np.asarray(expf, float)
    wbar = np.sum(w * expf_a) / np.sum(expf_a)
    return renormalize_to_stand_rate(m_stand * w / wbar, expf_a, m_stand,
                                     cap=P.ALLOC_MORT_CAP)


def make(**kw):
    """Return a surv_fn(dbh, ht, cr, rht, byi, ...) closure with kw frozen in.
    Signature unchanged from the deposited version; make(maxlift=...) still works."""
    def f(dbh, ht, cr, rht, byi, bal=0.0, baph=0.0, planted=0, sdi=None, **k):
        return surv_calibrated(dbh, ht, cr, rht, byi, bal=bal, baph=baph,
                               planted=planted, sdi=sdi, **kw)
    return f


# --- Re-estimated LEVELS, NOT the defaults. See koa_params.LEVELS_RECOVERED and
# --- final/koa_survival_calibrated.R lines 555-569. Do not enable until the
# --- sentinel death-recording convention is resolved and ingrowth is active.
LEVELS_RECOVERED = P.LEVELS_RECOVERED
