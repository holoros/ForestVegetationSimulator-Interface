#!/usr/bin/env python3
"""test_engine_equivalence.py -- two-implementation check that the deposited
Python survival and ingrowth engine reproduces the R equations of record.

WHY THIS FILE EXISTS. On 2026-08-07 the deposited Python was found to be running
a RETIRED parameterisation: a scalar SDImax of 500 with a relative-density
mortality ramp at onset RD 0.65 and full lift RD 0.85, which places the absolute
onset at SDI 325 and full lift at SDI 425. The equation of record ramps on
ABSOLUTE stand density index, onset SDI 200 and full lift SDI 850, and deploys
no SDImax at all. The two agree only below SDI 200 and at or above SDI 850. This
test pins the fix in both directions: the respecified engine must AGREE with the
R equation of record, and it must DISAGREE with the retired engine at the SDI
values where the two parameterisations are known to part company.

HOW THE COMPARISON IS MADE HONEST. R is not available in this environment and
cannot be installed, so the R side is a SECOND, INDEPENDENT transcription
written directly from the text of final/koa_survival_calibrated.R and
final/koa_ingrowth.R, with every numeric literal typed out from the R source
rather than imported. It deliberately does NOT import koa_params, koa_ingrowth
or koa_survival_calibrated_py, so this is a genuine two-implementation
comparison and not a tautology in which a module is checked against itself. The
R line numbers each literal came from are recorded beside it.

TOLERANCE. Agreement is asserted to 1e-12 absolute in annual survival and
annual mortality (both dimensionless, on [0, 1]), and to 1e-9 relative in
expected ingrowth (trees ha-1 yr-1). Both implementations evaluate the same
closed-form arithmetic, so the only expected difference is floating point
association order, which is order 1e-16.

Run: python3 test_engine_equivalence.py     (exit 0 pass, exit 1 fail)
"""
import math
import sys

import numpy as np

# The engine under test.
import koa_ingrowth as ENG_ING
import koa_survival_calibrated_py as ENG_SURV

TOL_SURV = 1e-12          # absolute, annual survival and annual mortality
TOL_ING_REL = 1e-9        # relative, trees ha-1 yr-1
MIN_DIVERGENCE = 0.01     # absolute annual mortality; the retired engine must
                          # differ from the record by at least this much at the
                          # SDI values listed in MUST_DISAGREE_AT


# =============================================================================
# INDEPENDENT TRANSCRIPTION 1: final/koa_survival_calibrated.R lines 481-553,
# function koa.SURV.calibrated. Every literal typed from the R source text.
# =============================================================================

def r_surv_calibrated(sdi=None, baph=None, planted=0, qmd=None,
                      base_nat=0.003,          # R line 375
                      base_plt=0.006,          # R line 375
                      SDImax=None,             # R line 376: REPORTING ONLY, default NA
                      onset_sdi=200,           # R line 383
                      full_sdi=850,            # R line 386
                      onset=None,              # R line 389, absolute SDI override
                      full=None,               # R line 390, absolute SDI override
                      maxlift=0.15,            # R line 391
                      mort_max=0.20,           # R line 391
                      baph_ref=42,             # R line 393
                      qmd_ref=20):             # R line 401
    """Second transcription of koa.SURV.calibrated. Returns annual survival, and
    the relative density attribute as a second element when SDImax is named."""
    # R line 410: kR <- (pi/4) * 25^1.605 / 1e4
    kR = (math.pi / 4.0) * 25 ** 1.605 / 1e4

    # R lines 414-427: density position on the ramp, in ABSOLUTE SDI.
    if sdi is not None:
        sdi_use = sdi
    else:
        # R line 425: dq_use <- if (!is.na(qmd)) pmax(qmd, 0.1) else qmd_ref
        dq_use = max(qmd, 0.1) if qmd is not None else qmd_ref
        # R line 426: sdi_use <- baph / (kR * dq_use^0.395)
        sdi_use = baph / (kR * dq_use ** 0.395)

    on_sdi = onset_sdi if onset is None else onset      # R line 429
    fl_sdi = full_sdi if full is None else full         # R line 430

    # R line 432: base <- ifelse(planted == 1, base_plt, base_nat)
    base = base_plt if planted == 1 else base_nat
    # R line 433: frac <- pmin(pmax((sdi_use - on_sdi)/(fl_sdi - on_sdi), 0), 1)
    frac = min(max((sdi_use - on_sdi) / (fl_sdi - on_sdi), 0.0), 1.0)
    # R line 436: mort <- pmin(pmax(base + maxlift * frac, 0), mort_max)
    mort = min(max(base + maxlift * frac, 0.0), mort_max)
    # R line 437: surv <- 1 - mort
    surv = 1.0 - mort
    # R line 444: if (!is.na(SDImax)) attr(surv, "RD") <- sdi_use / SDImax
    rd = None if SDImax is None else sdi_use / SDImax
    return surv, rd


def r_surv_allocate(dbh, expf, qmd, m_stand, beta=3):
    """Second transcription of koa.SURV.allocate, R lines 481-486."""
    dbh = np.asarray(dbh, float); expf = np.asarray(expf, float)
    rdbh = dbh / max(qmd, 0.1)                      # R line 482
    w = np.exp(-beta * (rdbh - 1.0))                # R line 483
    wbar = np.sum(w * expf) / np.sum(expf)          # R line 484
    return np.minimum(np.maximum(m_stand * w / wbar, 0.0), 0.95)   # R line 485


# =============================================================================
# INDEPENDENT TRANSCRIPTION 1b, ADDED 2026-08-15 with the A1 allocation
# upgrade: final/koa_survival_calibrated.R lines 644-763 (re-pinned 2026-08-19),
# koa.SURV.tree.mort and koa.SURV.allocate(mode = "tree_eq"). Every literal
# typed from the R source text, deliberately NOT imported from
# koa_equations.LineageA.SURV (that agreement is verify_reproducibility.R
# GATE 1h's job) or from koa_survival_calibrated_py.allocate (which is the
# engine under test here). Before 2026-08-15 this file only exercised the
# AS_PUBLISHED "size" allocation path; ALLOC_MODE moved to "tree_eq" as the
# equation of record and this was owed the same session.
# =============================================================================

def r_surv_tree_mort(dbh, ht, cr, rht, byi):
    """Second transcription of koa.SURV.tree.mort, R lines 588-598. Fitted
    Lineage A survivor equation (manuscript Table 6), evaluated as annual
    mortality directly: exp(-exp(eta)), the cloglog complement."""
    dbh = np.asarray(dbh, float); ht = np.asarray(ht, float)
    cr = np.asarray(cr, float); rht = np.asarray(rht, float)
    ht = np.maximum(ht, 0.1); dbh = np.maximum(dbh, 0.1)                # R line 593
    cr_clip = np.minimum(np.maximum(cr, 0.01), 0.99)                    # R line 595
    # CORRECTED 2026-08-15: this transcription copied the stale pre-dedup
    # "model development snapshot" vector (18.133, 0.199, -5.718, 7.640,
    # 15.678, -3.396, 3.039, -25.102), matching what R carried before the same
    # dated fix. Now the true manuscript Table 6 vector (regenerate_table6.R),
    # matching the corrected R source.
    eta = (14.102 + 0.130 * ht - 4.516 * np.log(ht) + 6.684 * rht        # R line 594
           + 14.218 * np.log(cr_clip) - 2.806 * np.log(ht / dbh)         # R line 595
           + 2.649 * np.log(np.maximum(byi, 1) / 100.0)                 # R line 596
           - 21.188 * (byi / 1000.0))                                   # R line 596
    return np.clip(np.exp(-np.exp(eta)), 1e-9, 1.0)                     # R line 597


def r_surv_allocate_tree_eq(dbh, expf, m_stand, ht, cr, rht, byi):
    """Second transcription of koa.SURV.allocate(mode = 'tree_eq'), R lines
    608-619: weight by the fitted tree survivor equation instead of the size
    weight, ratio-normalize so the expansion-factor-weighted mean per-tree
    mortality equals the stand rate exactly, cap at 0.95."""
    dbh = np.asarray(dbh, float); expf = np.asarray(expf, float)
    w = r_surv_tree_mort(dbh, ht, cr, rht, byi)                # R line 613
    wbar = np.sum(w * expf) / np.sum(expf)                     # R line 618
    return np.minimum(np.maximum(m_stand * w / wbar, 0.0), 0.95)   # R line 619


# =============================================================================
# INDEPENDENT TRANSCRIPTION 2: final/koa_ingrowth.R lines 225-292,
# function koa.ingrowth. Every literal typed from the R source text.
# =============================================================================

def r_ingrowth(sdi=None, baph=None, planted=0, qmd=None,
               SDImax=None,          # R line 226: REPORTING ONLY, default NA
               b0=5.3836,            # R line 232
               b_sdi=-0.0061866,     # R line 233
               b_rd=None,            # R line 237, diagnostics override
               b_planted=-1.6359,    # R line 242
               byi=264, byi_c=0, byi_ref=390, cap=160,   # R line 243
               baph_ref=42,          # R line 244
               qmd_ref=20):          # R line 252
    """Second transcription of koa.ingrowth. Returns trees ha-1 yr-1."""
    kR = (math.pi / 4.0) * 25 ** 1.605 / 1e4        # R line 261

    if sdi is not None:                              # R lines 264-269
        sdi_use = sdi
    else:
        dq_use = max(qmd, 0.1) if qmd is not None else qmd_ref
        sdi_use = baph / (kR * dq_use ** 0.395)

    if b_rd is None:                                 # R lines 275-281
        dens_term = b_sdi * sdi_use
    else:
        if SDImax is None:
            raise RuntimeError("b_rd was supplied without SDImax")
        dens_term = b_rd * (sdi_use / SDImax)

    e = math.exp(b0 + dens_term + b_planted * (1 if planted == 1 else 0))   # R line 283
    if byi_c != 0:                                   # R line 284
        e = e * (max(byi, 1) / byi_ref) ** byi_c
    return min(max(e, 0.0), cap)                     # R line 285


# =============================================================================
# THE RETIRED ENGINE, transcribed from the deposited Python as it stood before
# 2026-08-07 (figshare_v62/koa_survival_calibrated_py.py lines 12, 15, 22-26 and
# koa_ingrowth.py lines 15-16, 22-23). Present ONLY so the test can prove the
# fix changed behaviour. Nothing in the production path may call these.
# =============================================================================

def retired_surv(sdi=None, baph=None, planted=0,
                 base_nat=0.003, base_plt=0.006,
                 onset=0.65, full=0.85, maxlift=0.15, mort_max=0.20):
    SDI_MAX = 500.0                                  # retired line 12
    RD = (sdi / SDI_MAX) if sdi is not None else (baph / 60.0)   # retired line 22
    base = base_plt if planted == 1 else base_nat
    frac = min(max((RD - onset) / (full - onset), 0.0), 1.0)
    return 1.0 - min(max(base + maxlift * frac, 0.0), mort_max)


def retired_ingrowth(sdi=None, baph=None, planted=0, cap=160.0):
    SDI_MAX, B0, B_RD, B_PLANTED = 500.0, 5.3836, -3.0933, -1.6359
    rd = (sdi / SDI_MAX) if sdi is not None else (baph / 60.0)
    return float(np.clip(math.exp(B0 + B_RD * rd + B_PLANTED * int(planted)), 0.0, cap))


# =============================================================================
# Test grid
# =============================================================================

SDI_GRID = [0.0, 75.0, 100.0, 200.0, 225.0, 325.0, 340.0, 425.0, 456.0, 500.0,
            525.0, 640.0, 651.0, 796.0, 800.0, 850.0, 925.0, 934.0, 1200.0, 2000.0]
ORIGINS = [(0, "natural"), (1, "planted")]
MUST_DISAGREE_AT = [325.0, 425.0, 500.0]
BAPH_GRID = [1.0, 5.0, 10.0, 20.0, 30.0, 42.0]
QMD_GRID = [None, 5.0, 11.3, 20.0, 30.0, 50.0]


def main():
    fails = []
    max_dev_surv = 0.0
    max_dev_ing = 0.0

    # ---- Table 1: survival on the absolute SDI grid ----------------------
    print("=" * 96)
    print("SURVIVAL: respecified deposited engine vs independent transcription of")
    print("          final/koa_survival_calibrated.R, with the RETIRED engine for contrast.")
    print("          Annual mortality, percent. Tolerance %.0e absolute in survival." % TOL_SURV)
    print("=" * 96)
    hdr = ("{:>7} | {:>10} {:>10} {:>11} | {:>10} {:>10} {:>11} | {:>9}"
           .format("SDI", "nat REC", "nat PY", "nat RETIRED",
                   "plt REC", "plt PY", "plt RETIRED", "diverges"))
    print(hdr)
    print("-" * len(hdr))
    for sdi in SDI_GRID:
        cells = {}
        for pl, _lab in ORIGINS:
            m_r = 1.0 - r_surv_calibrated(sdi=sdi, planted=pl)[0]
            m_p = 1.0 - float(np.atleast_1d(
                ENG_SURV.surv_calibrated(15.0, 10.0, 0.5, 0.5, 264.0,
                                         sdi=sdi, planted=pl))[0])
            m_x = 1.0 - retired_surv(sdi=sdi, planted=pl)
            dev = abs(m_p - m_r)
            max_dev_surv = max(max_dev_surv, dev)
            if dev > TOL_SURV:
                fails.append("survival mismatch vs R at SDI %.0f planted=%d: "
                             "record %.15g python %.15g dev %.3e"
                             % (sdi, pl, m_r, m_p, dev))
            cells[pl] = (m_r, m_p, m_x)
        div = abs(cells[0][0] - cells[0][2]) > 1e-12
        print("{:>7.0f} | {:>10.4f} {:>10.4f} {:>11.4f} | {:>10.4f} {:>10.4f} {:>11.4f} | {:>9}"
              .format(sdi, cells[0][0] * 100, cells[0][1] * 100, cells[0][2] * 100,
                      cells[1][0] * 100, cells[1][1] * 100, cells[1][2] * 100,
                      "yes" if div else "no"))

    # ---- the fix must have changed behaviour ------------------------------
    print()
    print("PROOF THE FIX CHANGED BEHAVIOUR. The respecified engine must DISAGREE with")
    print("the retired engine at these SDI values by at least %.3f in annual mortality:"
          % MIN_DIVERGENCE)
    for sdi in MUST_DISAGREE_AT:
        for pl, lab in ORIGINS:
            m_p = 1.0 - float(np.atleast_1d(
                ENG_SURV.surv_calibrated(15.0, 10.0, 0.5, 0.5, 264.0,
                                         sdi=sdi, planted=pl))[0])
            m_x = 1.0 - retired_surv(sdi=sdi, planted=pl)
            gap = abs(m_p - m_x)
            ok = gap >= MIN_DIVERGENCE
            print("  SDI %6.0f %-8s respecified %7.4f%%  retired %7.4f%%  gap %7.4f  %s"
                  % (sdi, lab, m_p * 100, m_x * 100, gap, "OK" if ok else "FAIL"))
            if not ok:
                fails.append("respecified engine still agrees with the RETIRED engine "
                             "at SDI %.0f planted=%d (gap %.3e); the fix did not take"
                             % (sdi, pl, gap))

    # ---- the two must agree outside the ramp ------------------------------
    print()
    print("The two parameterisations must still AGREE below the onset (SDI 200) and at")
    print("or above full lift (SDI 850), because both plateau there:")
    for sdi in [0.0, 100.0, 200.0, 850.0, 1200.0, 2000.0]:
        m_p = 1.0 - float(np.atleast_1d(
            ENG_SURV.surv_calibrated(15.0, 10.0, 0.5, 0.5, 264.0, sdi=sdi, planted=0))[0])
        m_x = 1.0 - retired_surv(sdi=sdi, planted=0)
        gap = abs(m_p - m_x)
        print("  SDI %6.0f natural: respecified %7.4f%%  retired %7.4f%%  gap %.2e  %s"
              % (sdi, m_p * 100, m_x * 100, gap, "OK" if gap <= 1e-12 else "FAIL"))
        if gap > 1e-12:
            fails.append("respecified and retired engines disagree outside the ramp at "
                         "SDI %.0f (gap %.3e); one of the plateaux is wrong" % (sdi, gap))

    # ---- basal area fallback path -----------------------------------------
    print()
    print("BASAL AREA FALLBACK (sdi not supplied), respecified vs R transcription.")
    print("Annual mortality percent, natural origin. R lines 417-427.")
    print("{:>8} {:>8} {:>12} {:>12} {:>11}".format("baph", "qmd", "SDI implied", "REC mort%", "PY mort%"))
    for baph in BAPH_GRID:
        for qmd in QMD_GRID:
            s_r, _ = r_surv_calibrated(baph=baph, qmd=qmd, planted=0)
            s_p = float(np.atleast_1d(ENG_SURV.surv_calibrated(
                15.0, 10.0, 0.5, 0.5, 264.0, baph=baph, qmd=qmd, planted=0))[0])
            sdi_impl = float(np.atleast_1d(ENG_SURV.sdi_from_baph(baph, qmd))[0])
            dev = abs(s_p - s_r)
            max_dev_surv = max(max_dev_surv, dev)
            if dev > TOL_SURV:
                fails.append("basal area fallback mismatch at baph=%.1f qmd=%s: dev %.3e"
                             % (baph, qmd, dev))
            if qmd in (None, 20.0):
                print("{:>8.1f} {:>8} {:>12.1f} {:>12.4f} {:>11.4f}"
                      .format(baph, "ref 20" if qmd is None else "%.1f" % qmd,
                              sdi_impl, (1 - s_r) * 100, (1 - s_p) * 100))

    # ---- size allocation ---------------------------------------------------
    dbh = np.array([2.5, 5.0, 11.3, 20.0, 35.0, 60.0])
    expf = np.array([185.91, 185.91, 49.56, 24.80, 14.92, 14.92])
    qmd = 22.4
    m_stand = 1.0 - float(np.atleast_1d(ENG_SURV.surv_calibrated(
        qmd, 20.0, 0.5, 0.5, 264.0, sdi=400.0, planted=0))[0])
    a_r = r_surv_allocate(dbh, expf, qmd, m_stand)
    a_p = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, m_stand), float)
    dev = float(np.max(np.abs(a_p - a_r)))
    max_dev_surv = max(max_dev_surv, dev)
    print()
    print("SIZE ALLOCATION (R lines 481-486): max |python - R| = %.3e over %d trees, "
          "expf-weighted mean %.6f vs stand rate %.6f"
          % (dev, len(dbh), float(np.sum(a_p * expf) / np.sum(expf)), m_stand))
    if dev > TOL_SURV:
        fails.append("size allocation mismatch: max dev %.3e" % dev)

    # ---- tree_eq allocation, ADDED 2026-08-15 (A1, record since that date) --
    # ALLOC_MODE moved from "size" to "tree_eq" this session; everything above
    # this block exercises only the retained AS_PUBLISHED "size" path via an
    # explicit mode="size" default (ht=None), which was the gap flagged when
    # the propagation landed. This block exercises the mode="tree_eq" path on
    # the same six-tree list, dbh/expf/qmd/m_stand reused unchanged from the
    # size-allocation block above so the two modes are compared on identical
    # trees and an identical stand rate.
    ht_tree = np.array([6.5, 9.0, 13.5, 17.0, 21.5, 26.0])
    cr_tree = np.array([0.30, 0.35, 0.42, 0.48, 0.55, 0.62])
    rht_tree = ht_tree / ht_tree.max()
    byi_tree = 264.0
    a_r_tree = r_surv_allocate_tree_eq(dbh, expf, m_stand, ht_tree, cr_tree, rht_tree, byi_tree)
    a_p_tree = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, m_stand,
                                            ht=ht_tree, cr=cr_tree, rht=rht_tree,
                                            byi=byi_tree, mode="tree_eq"), float)
    dev_tree = float(np.max(np.abs(a_p_tree - a_r_tree)))
    max_dev_surv = max(max_dev_surv, dev_tree)
    print()
    print("TREE_EQ ALLOCATION (mode='tree_eq', R lines 608-619, A1 record since")
    print("2026-08-15): max |python - R| = %.3e over %d trees" % (dev_tree, len(dbh)))
    if dev_tree > TOL_SURV:
        fails.append("tree_eq allocation mismatch vs R: max dev %.3e" % dev_tree)

    # Ratio-normalization: the expansion-factor-weighted mean per-tree
    # mortality must equal the stand rate exactly (R line 618, wbar
    # normalization), the property the whole disaggregation rests on.
    wmean_tree = float(np.sum(a_p_tree * expf) / np.sum(expf))
    ratio_dev = abs(wmean_tree - m_stand)
    print("  expf-weighted mean per-tree mortality %.6f vs stand rate %.6f (dev %.3e)"
          % (wmean_tree, m_stand, ratio_dev))
    if ratio_dev > 1e-9:
        fails.append("tree_eq ratio-normalization failed: expf-weighted mean %.6f "
                     "vs stand rate %.6f, dev %.3e" % (wmean_tree, m_stand, ratio_dev))

    # Per-tree cap 0.95 (R line 619 / koa_params.ALLOC_MORT_CAP) respected.
    cap_ok = bool(np.all(a_p_tree <= 0.95 + 1e-12))
    print("  per-tree cap 0.95 respected: max per-tree mortality %.6f  %s"
          % (float(a_p_tree.max()), "OK" if cap_ok else "FAIL"))
    if not cap_ok:
        fails.append("tree_eq per-tree cap 0.95 exceeded: max %.6f" % float(a_p_tree.max()))

    # The tree_eq weight must not coincide with the size weight on the same
    # tree list: the ordering now comes from the fitted Table 6 equation
    # (crown ratio, relative height, BYI), not from DBH/QMD alone, so a
    # coincidence here would mean the mode switch is not actually taking
    # effect (e.g. silently falling through to the "size" branch).
    mode_gap = float(np.max(np.abs(a_p_tree - a_p)))
    mode_gap_ok = mode_gap > 1e-6
    print("  differs from the 'size' allocation on the same tree list: max |diff| %.4f  %s"
          % (mode_gap, "OK" if mode_gap_ok else "FAIL (modes coincide)"))
    if not mode_gap_ok:
        fails.append("tree_eq allocation is numerically identical to the size allocation "
                     "on the same tree list (max |diff| %.3e); the mode switch may not be "
                     "taking effect" % mode_gap)

    # ---- R1 cap renormalization, ADDED 2026-08-18 --------------------------
    # The constraint tested at ratio_dev above holds only while the per-tree cap
    # does not bind. It was asserted in three places and enforced in none, so
    # every tree pushed onto ALLOC_MORT_CAP silently dropped the mortality above
    # the cap and the stand under delivered. R1 solves for the scalar lambda
    # with expf-weighted mean of clip(lambda*m_i, 0, cap) equal to m_stand.
    # This block pins both halves of the claim made for it: a no-op where the
    # cap does not bind, and restoration of the constraint where it does.
    import koa_params as P_R1
    cap_r1 = float(P_R1.ALLOC_MORT_CAP)
    renorm_saved = getattr(P_R1, "ALLOC_RENORMALIZE", True)
    print()
    print("R1 CAP RENORMALIZATION (koa_params.ALLOC_RENORMALIZE, 2026-08-18):")
    try:
        # Ratio m_i/m_stand of the size allocation, taken at a stand rate far too
        # small for the cap to bind, so the ratios are the unclipped w_i/wbar.
        eps = 1e-9
        ratio = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, eps), float) / eps
        rmax = float(ratio.max())

        # (i) cap does not bind: R1 must be a bitwise no-op. m_stand from the
        # size-allocation block above is far below cap/rmax.
        P_R1.ALLOC_RENORMALIZE = False
        a_off = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, m_stand), float)
        P_R1.ALLOC_RENORMALIZE = True
        a_on = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, m_stand), float)
        binds_lo = bool(m_stand * rmax > cap_r1)
        nooop = bool(a_on.tobytes() == a_off.tobytes())
        print("  cap does not bind (m_stand %.6f, max m_i %.6f, cap %.2f): "
              "renormalized result bitwise identical to as-published  %s"
              % (m_stand, m_stand * rmax, cap_r1, "OK" if (nooop and not binds_lo) else "FAIL"))
        if binds_lo:
            fails.append("R1 no-op case is mis-specified: the cap already binds at "
                         "m_stand %.6f" % m_stand)
        if not nooop:
            fails.append("R1 is not a no-op where the cap does not bind: max dev %.3e"
                         % float(np.max(np.abs(a_on - a_off))))

        # (ii) cap binds: pick a stand rate strictly between cap/rmax, where the
        # cap starts to bind, and cap itself, where the constraint goes
        # infeasible. Feasible and binding by construction, whatever the weights.
        m_hi = 0.5 * (cap_r1 / rmax + cap_r1)
        P_R1.ALLOC_RENORMALIZE = False
        b_off = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, m_hi), float)
        P_R1.ALLOC_RENORMALIZE = True
        b_on = np.asarray(ENG_SURV.allocate(dbh, expf, qmd, m_hi), float)
        w_off = float(np.sum(b_off * expf) / np.sum(expf))
        w_on = float(np.sum(b_on * expf) / np.sum(expf))
        dev_on = abs(w_on - m_hi)
        print("  cap binds (m_stand %.6f): as-published weighted mean %.6f (short by "
              "%.3e), renormalized weighted mean %.6f (dev %.3e)"
              % (m_hi, w_off, m_hi - w_off, w_on, dev_on))
        if not (m_hi - w_off) > 1e-9:
            fails.append("R1 binding case is mis-specified: the as-published "
                         "allocation is not short at m_stand %.6f" % m_hi)
        if dev_on > 1e-12:
            fails.append("R1 failed to restore the stand-rate constraint: weighted "
                         "mean %.6f vs stand rate %.6f, dev %.3e" % (w_on, m_hi, dev_on))
        cap_ok_r1 = bool(np.all(b_on <= cap_r1 + 1e-12))
        print("  per-tree cap still respected after renormalization: max %.6f  %s"
              % (float(b_on.max()), "OK" if cap_ok_r1 else "FAIL"))
        if not cap_ok_r1:
            fails.append("R1 renormalization exceeded the per-tree cap: max %.6f"
                         % float(b_on.max()))

        # (iii) infeasible: no allocation can deliver a stand rate at or above
        # the cap, so the solver must warn and return every tree at the cap
        # rather than silently returning a shortfall.
        import warnings as _warnings
        with _warnings.catch_warnings(record=True) as caught:
            _warnings.simplefilter("always")
            c_inf = np.asarray(ENG_SURV.renormalize_to_stand_rate(
                np.full(len(dbh), cap_r1), expf, cap_r1 + 0.01, cap=cap_r1), float)
        all_cap = bool(np.allclose(c_inf, cap_r1, rtol=0, atol=0))
        warned = bool(len(caught) > 0)
        print("  infeasible stand rate %.2f >= cap %.2f: every tree at the cap %s, "
              "warning raised %s" % (cap_r1 + 0.01, cap_r1,
                                     "OK" if all_cap else "FAIL",
                                     "OK" if warned else "FAIL"))
        if not all_cap:
            fails.append("R1 infeasible case did not return every tree at the cap")
        if not warned:
            fails.append("R1 infeasible case did not warn")
    finally:
        P_R1.ALLOC_RENORMALIZE = renorm_saved

    # ---- ingrowth ----------------------------------------------------------
    print()
    print("=" * 96)
    print("INGROWTH: respecified deposited engine vs independent transcription of")
    print("          final/koa_ingrowth.R. Trees ha-1 yr-1. Tolerance %.0e relative." % TOL_ING_REL)
    print("=" * 96)
    hdr = ("{:>7} | {:>11} {:>11} {:>13} | {:>11} {:>11} {:>13}"
           .format("SDI", "nat REC", "nat PY", "nat RETIRED", "plt REC", "plt PY", "plt RETIRED"))
    print(hdr)
    print("-" * len(hdr))
    for sdi in SDI_GRID:
        row = {}
        for pl, _lab in ORIGINS:
            g_r = r_ingrowth(sdi=sdi, planted=pl)
            g_p = ENG_ING.ingrowth_annual(sdi=sdi, planted=pl)
            g_x = retired_ingrowth(sdi=sdi, planted=pl)
            rel = abs(g_p - g_r) / max(abs(g_r), 1e-12)
            max_dev_ing = max(max_dev_ing, rel)
            if rel > TOL_ING_REL:
                fails.append("ingrowth mismatch vs R at SDI %.0f planted=%d: "
                             "record %.15g python %.15g rel %.3e" % (sdi, pl, g_r, g_p, rel))
            row[pl] = (g_r, g_p, g_x)
        print("{:>7.0f} | {:>11.4f} {:>11.4f} {:>13.4f} | {:>11.4f} {:>11.4f} {:>13.4f}"
              .format(sdi, row[0][0], row[0][1], row[0][2],
                      row[1][0], row[1][1], row[1][2]))

    print()
    print("Note on ingrowth: the retired module used SDI_MAX = 500 with B_RD = -3.0933,")
    print("and -3.0933/500 = -0.0061866 exactly, so the retired and record ingrowth")
    print("predictions coincide whenever sdi was supplied. The retired form was an")
    print("algebraic detour through a withdrawn constant, not a numerical error. What")
    print("the respecification removes is the detour and the baph/60 fallback.")

    # ---- ingrowth reference points from the R header ------------------------
    print()
    print("Reference evaluations quoted in final/koa_ingrowth.R lines 168-181:")
    for sdi, pl, lab, want in [(340.0, 0, "natural", 26.6), (340.0, 1, "planted", 5.2)]:
        got = ENG_ING.ingrowth_annual(sdi=sdi, planted=pl)
        ok = abs(got - want) < 0.05
        print("  SDI %.0f %-8s: engine %.4f, R header states %.1f  %s"
              % (sdi, lab, got, want, "OK" if ok else "FAIL"))
        if not ok:
            fails.append("ingrowth reference point SDI %.0f %s: engine %.4f vs header %.1f"
                         % (sdi, lab, got, want))
    got456 = ENG_ING.ingrowth_annual(sdi=456.0, planted=0)
    print("  SDI 456 natural : engine %.4f, R header states 13 trees ha-1 yr-1 corresponds "
          "to SDI 456  %s" % (got456, "OK" if abs(got456 - 13.0) < 0.2 else "FAIL"))
    if abs(got456 - 13.0) >= 0.2:
        fails.append("ingrowth at SDI 456 is %.4f, R header states about 13" % got456)

    # ---- withdrawn names must fail loudly ----------------------------------
    print()
    print("WITHDRAWN NAMES must be present but unusable (so importers fail loudly):")
    for mod, name in [(ENG_SURV, "koa_survival_calibrated_py.SDI_MAX"),
                      (ENG_ING, "koa_ingrowth.SDI_MAX")]:
        assert hasattr(mod, "SDI_MAX"), "%s was deleted; four files import it" % name
        try:
            _ = mod.SDI_MAX / 2.0
            print("  %-40s FAIL (usable in arithmetic)" % name)
            fails.append("%s is still usable in arithmetic" % name)
        except RuntimeError:
            print("  %-40s OK (raises RuntimeError on use)" % name)
    import koa_projector as ENG_PROJ
    assert hasattr(ENG_PROJ, "SDI_MAX"), "koa_projector.SDI_MAX was deleted"
    try:
        _ = ENG_PROJ.SDI_MAX * 1.05
        print("  %-40s FAIL (usable in arithmetic)" % "koa_projector.SDI_MAX")
        fails.append("koa_projector.SDI_MAX is still usable in arithmetic")
    except RuntimeError:
        print("  %-40s OK (raises RuntimeError on use)" % "koa_projector.SDI_MAX")
    try:
        ENG_ING.ingrowth_annual(sdi=340.0, planted=0, rd=0.68)
        print("  %-40s FAIL (RD path ran without a named SDImax)" % "ingrowth rd= path")
        fails.append("ingrowth rd= path ran without a named SDImax")
    except RuntimeError:
        print("  %-40s OK (raises without a named SDImax)" % "ingrowth rd= path")

    # ---- single source of truth --------------------------------------------
    print()
    import koa_params as P
    print("SINGLE SOURCE OF TRUTH: koa_params.SOURCE_OF_TRUTH")
    print("  " + P.SOURCE_OF_TRUTH.replace("; ", ";\n  "))
    for name, want, where in [("ONSET_SDI", 200.0, "R line 383"),
                              ("FULL_SDI", 850.0, "R line 386"),
                              ("BASE_NAT", 0.003, "R line 375"),
                              ("BASE_PLT", 0.006, "R line 375"),
                              ("MAXLIFT", 0.15, "R line 391"),
                              ("MORT_MAX", 0.20, "R line 391"),
                              ("ING_B0", 5.3836, "ingrowth R line 232"),
                              ("ING_B_SDI", -0.0061866, "ingrowth R line 233"),
                              ("ING_B_PLANTED", -1.6359, "ingrowth R line 242"),
                              ("ING_CAP", 160.0, "ingrowth R line 243, UNPROVENANCED")]:
        got = getattr(P, name)
        ok = got == want
        print("  %-14s = %-12g (%s) %s" % (name, got, where, "OK" if ok else "FAIL"))
        if not ok:
            fails.append("koa_params.%s is %r, R source says %r" % (name, got, want))

    print()
    print("=" * 96)
    print("Max deviation from the independent R transcription: survival %.3e "
          "(tolerance %.0e), ingrowth %.3e relative (tolerance %.0e)"
          % (max_dev_surv, TOL_SURV, max_dev_ing, TOL_ING_REL))
    if fails:
        print("FAILED: %d assertion(s)" % len(fails))
        for f in fails:
            print("  - " + f)
        return 1
    print("PASSED: the deposited Python engine reproduces the R equations of record on")
    print("        %d SDI values x 2 origins, on the basal area fallback grid, on the size"
          % len(SDI_GRID))
    print("        allocation, on the tree_eq allocation (A1, record since 2026-08-15,")
    print("        ratio-normalized and cap-respecting), and on the ingrowth equation; and")
    print("        it no longer agrees with the retired parameterisation at SDI 325, 425 or")
    print("        500.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
