#!/usr/bin/env python3
"""stress_mortality.py -- behavioral-envelope stress test of the deployed koa
mortality/survival chain in figshare_v64. Imports the deposit's own modules and
never reimplements the equations. Run from /tmp/mort_st with the deposit at
/tmp/mort_st/deposit. Written August 26, 2026 for the FVS-HI implementation
spec for Ben Rice (Midgard).

Sections a-h mirror the test matrix in
2026-08-26_mortality-stress-test-report_DRAFT.md. Every case prints expected,
observed, and PASS or FLAG. FLAG means correct-but-surprising or divergent from
a tasking assumption, not necessarily a defect.

To rerun against the deposit in place, change the sys.path.insert line to the
deposit directory (for example figshare_v64/ itself). The harness is
deterministic; reruns are bitwise identical.
"""
import sys
import warnings

import numpy as np
import pandas as pd

sys.path.insert(0, "/tmp/mort_st/deposit")

import koa_params as P
import koa_survival_calibrated_py as S
from koa_equations import LINEAGES, predict_HCB
from koa_projector import project_psp, sdi_of

RESULTS = []


def rec(section, case, expected, observed, ok, flag_note=""):
    verdict = "PASS" if ok else ("FLAG " + flag_note if flag_note else "FLAG")
    RESULTS.append((section, case, expected, observed, verdict))
    print("  [%s] %s\n        expected: %s\n        observed: %s"
          % (verdict.split()[0], case, expected, observed))
    if not ok and flag_note:
        print("        note: %s" % flag_note)


def mort_at(sdi, planted=0, **kw):
    s = S.surv_calibrated(15.0, 10.0, 0.5, 0.5, 264.0, sdi=sdi,
                          planted=planted, **kw)
    return 1.0 - float(np.atleast_1d(s)[0])


def eq5b_expected(sdi, planted):
    base = P.BASE_PLT if planted else P.BASE_NAT
    frac = min(max((sdi - P.ONSET_SDI) / (P.FULL_SDI - P.ONSET_SDI), 0.0), 1.0)
    return min(max(base + P.MAXLIFT * frac, 0.0), P.MORT_MAX)


def make_stand():
    dbh = np.array([2.5, 4.0, 8.0, 15.0, 22.0, 30.0, 42.0, 55.0, 70.0, 90.0])
    ht = np.array([3.0, 4.5, 8.0, 12.0, 15.0, 18.0, 21.0, 24.0, 26.0, 28.0])
    cr = np.array([0.10, 0.15, 0.25, 0.35, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70])
    expf = np.array([400.0, 300.0, 185.91, 120.0, 49.56, 49.56, 24.8, 24.8,
                     14.92, 14.92])
    rht = ht / ht.max()
    byi = 264.0
    ba = dbh**2 * 0.00007854 * expf
    baph = ba.sum(); tph = expf.sum()
    qmd = np.sqrt(baph / (0.00007854 * tph))
    sdi = sdi_of(tph, qmd)
    return dict(dbh=dbh, ht=ht, cr=cr, rht=rht, expf=expf, byi=byi,
                qmd=qmd, sdi=float(sdi), baph=baph, tph=tph)


def wmean(x, e):
    return float(np.sum(np.asarray(x) * np.asarray(e)) / np.sum(e))


# ===========================================================================
print("=" * 78)
print("SECTION a. RAMP SHAPE  (Eq. 5b, stand annual mortality vs absolute SDI)")
print("=" * 78)
grid = [0, 50, 100, 199, 200, 201, 400, 600, 849, 850, 851, 1200, 1873, 3000]
print("constants: BASE_NAT %.4g  BASE_PLT %.4g  ONSET_SDI %.4g  FULL_SDI %.4g"
      "  MAXLIFT %.4g  MORT_MAX %.4g" % (P.BASE_NAT, P.BASE_PLT, P.ONSET_SDI,
                                         P.FULL_SDI, P.MAXLIFT, P.MORT_MAX))
print("%8s  %18s  %18s  %18s  %18s" % ("SDI", "mort_nat_obs", "mort_nat_exp",
                                       "mort_plt_obs", "mort_plt_exp"))
ok_all = True
mn_prev = -1.0
mono_ok = True
for sdi in grid:
    mn, mp = mort_at(sdi, 0), mort_at(sdi, 1)
    en, ep = eq5b_expected(sdi, 0), eq5b_expected(sdi, 1)
    ok = abs(mn - en) < 1e-15 and abs(mp - ep) < 1e-15
    ok_all &= ok
    if mn < mn_prev - 1e-15:
        mono_ok = False
    mn_prev = mn
    print("%8g  %18.12f  %18.12f  %18.12f  %18.12f  %s"
          % (sdi, mn, en, mp, ep, "ok" if ok else "MISMATCH"))
rec("a", "grid values match base+MAXLIFT*clip((SDI-200)/650,0,1)",
    "exact to 1e-15 at all 14 SDI points, both origins",
    "all points agree" if ok_all else "MISMATCH", ok_all)
rec("a", "monotone non-decreasing in SDI (natural)", "non-decreasing",
    "non-decreasing" if mono_ok else "decrease found", mono_ok)
rec("a", "onset breakpoint", "mort(199)=mort(200)=base, mort(201)>base",
    "mort(199)=%.12f mort(200)=%.12f mort(201)=%.12f"
    % (mort_at(199), mort_at(200), mort_at(201)),
    abs(mort_at(199) - P.BASE_NAT) < 1e-15
    and abs(mort_at(200) - P.BASE_NAT) < 1e-15
    and mort_at(201) > P.BASE_NAT + 1e-6)
rec("a", "full-lift breakpoint", "mort(849)<mort(850)=mort(851)=plateau",
    "mort(849)=%.12f mort(850)=%.12f mort(851)=%.12f"
    % (mort_at(849), mort_at(850), mort_at(851)),
    mort_at(849) < mort_at(850)
    and abs(mort_at(850) - (P.BASE_NAT + P.MAXLIFT)) < 1e-15
    and abs(mort_at(851) - (P.BASE_NAT + P.MAXLIFT)) < 1e-15)
print("  note: surv_calibrated returns SURVIVAL; mortality recovered as 1-s")
print("        carries one-ulp roundoff (~3e-18 at 0.003), so equality checks")
print("        against literal constants must be tolerance-based, not exact.")
plat_n = P.BASE_NAT + P.MAXLIFT
plat_p = P.BASE_PLT + P.MAXLIFT
rec("a", "plateau (nominal, annual, in-code)",
    "natural 0.153, planted 0.156 (= base + MAXLIFT); MORT_MAX 0.20 never binds",
    "natural %.12f planted %.12f, both < MORT_MAX %.2f"
    % (mort_at(3000, 0), mort_at(3000, 1), P.MORT_MAX),
    abs(mort_at(3000, 0) - plat_n) < 1e-15
    and abs(mort_at(3000, 1) - plat_p) < 1e-15)
m = plat_n
for L in (1, 2, 5, 5.5, 10):
    print("  interval-annualized plateau, L=%4.1f yr: (1-(1-%.3f)^L)/L = %.4f"
          % (L, m, (1 - (1 - m) ** L) / L))
lo, hi = 0.1, 40.0
for _ in range(200):
    mid = 0.5 * (lo + hi)
    if (1 - (1 - m) ** mid) / mid > 0.1085:
        lo = mid
    else:
        hi = mid
L_implied = 0.5 * (lo + hi)
rec("a", "code-terms meaning of manuscript 15.3% vs supplement 10.85%",
    "15.3% = annual plateau BASE_NAT+MAXLIFT; 10.85% = expected deaths per "
    "tree-year after compounding the plateau over the >SDI-1200 bin's "
    "remeasurement intervals",
    "(1-(1-0.153)^L)/L = 0.1085 at L = %.2f yr implied mean interval "
    "(mechanism inferred from the compounding identity; the bin-exact value "
    "was not recomputed here)" % L_implied, True)

# ===========================================================================
print()
print("=" * 78)
print("SECTION b. ALLOCATION  (tree_eq weights, R1 ratio normalization)")
print("=" * 78)
st = make_stand()
m_stand = 1.0 - float(np.atleast_1d(S.surv_calibrated(
    st["qmd"], st["ht"].max(), 0.5, 0.5, st["byi"], baph=st["baph"],
    planted=0, sdi=st["sdi"]))[0])
print("synthetic stand: TPH %.2f  BAPH %.3f  QMD %.3f  SDI %.2f  m_stand %.12f"
      % (st["tph"], st["baph"], st["qmd"], st["sdi"], m_stand))
mi = np.asarray(S.allocate(st["dbh"], st["expf"], st["qmd"], m_stand,
                           ht=st["ht"], cr=st["cr"], rht=st["rht"],
                           byi=st["byi"]), float)
wm = wmean(mi, st["expf"])
rec("b", "expf-weighted mean per-tree mortality equals stand rate",
    "%.15f" % m_stand, "%.15f (dev %.3e)" % (wm, abs(wm - m_stand)),
    abs(wm - m_stand) < 1e-15)
w = np.clip(1.0 - LINEAGES["A"].surv_annual(st["dbh"], st["ht"], st["cr"],
                                            st["rht"], st["byi"]), 1e-9, 1.0)
rank_ok = bool(np.array_equal(np.argsort(w), np.argsort(mi)))
rec("b", "ordering follows Eq. 5 risk (rank of allocated rate = rank of weight)",
    "identical rank order", "identical" if rank_ok else "differs", rank_ok)
ratios = mi / w
ratio_spread = float(ratios.max() - ratios.min())
rec("b", "R1 is ordering-only when cap does not bind (m_i proportional to w)",
    "m_i / w constant across trees",
    "spread of m_i/w = %.3e (common factor m_stand/wbar = %.6f)"
    % (ratio_spread, float(ratios[0])), ratio_spread < 1e-12)
ms_plt = 1.0 - float(np.atleast_1d(S.surv_calibrated(
    st["qmd"], st["ht"].max(), 0.5, 0.5, st["byi"], planted=1,
    sdi=st["sdi"]))[0])
mi_plt = np.asarray(S.allocate(st["dbh"], st["expf"], st["qmd"], ms_plt,
                               ht=st["ht"], cr=st["cr"], rht=st["rht"],
                               byi=st["byi"]), float)
rec("b", "planted origin changes only the stand rate, not the ordering",
    "same rank order, uniformly scaled rates (base_plt > base_nat)",
    "rank identical: %s; weighted mean %.6f vs natural %.6f"
    % (np.array_equal(np.argsort(mi_plt), np.argsort(mi)),
       wmean(mi_plt, st["expf"]), wm),
    bool(np.array_equal(np.argsort(mi_plt), np.argsort(mi))))

# ===========================================================================
print()
print("=" * 78)
print("SECTION c. CAP BEHAVIOR  (ALLOC_MORT_CAP %.2f per tree; MORT_MAX %.2f "
      "on the stand rate)" % (P.ALLOC_MORT_CAP, P.MORT_MAX))
print("=" * 78)
cap = float(P.ALLOC_MORT_CAP)
wbar = wmean(w, st["expf"])
pin_threshold = cap * wbar / float(w.max())
print("weights: min %.3e max %.3e wbar %.6e" % (w.min(), w.max(), wbar))
print("predicted first-pinning stand rate = cap*wbar/wmax = %.6f"
      % pin_threshold)
sweep = [0.05, 0.5 * pin_threshold, 0.99 * pin_threshold,
         1.01 * pin_threshold, 0.5 * (pin_threshold + cap), 0.90, 0.949,
         0.95, 0.99]
print("%12s %10s %14s %14s %10s" % ("m_stand", "n_at_cap", "wmean_dev",
                                    "max_mi", "warned"))
first_pin = None
bounds_ok = True
for msx in sweep:
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        mix = np.asarray(S.allocate(st["dbh"], st["expf"], st["qmd"], msx,
                                    ht=st["ht"], cr=st["cr"], rht=st["rht"],
                                    byi=st["byi"]), float)
    n_cap = int(np.sum(mix >= cap - 1e-12))
    dev = abs(wmean(mix, st["expf"]) - msx)
    warned = any("renormalize" in str(c.message) for c in caught)
    if n_cap and first_pin is None:
        first_pin = msx
    bounds_ok &= bool(mix.max() <= cap + 1e-12 and mix.min() >= 0.0)
    print("%12.6f %10d %14.3e %14.6f %10s" % (msx, n_cap, dev, mix.max(),
                                              warned))
rec("c", "trees start pinning at m_stand = cap*wbar/wmax",
    "first pinning between 0.99x and 1.01x of %.6f" % pin_threshold,
    "observed first pin in sweep at m_stand %.6f" % first_pin,
    first_pin is not None and first_pin > 0.99 * pin_threshold)
msx = 0.5 * (pin_threshold + cap)
mix = np.asarray(S.allocate(st["dbh"], st["expf"], st["qmd"], msx,
                            ht=st["ht"], cr=st["cr"], rht=st["rht"],
                            byi=st["byi"]), float)
uncapped = mix < cap - 1e-12
ratio_unc = mix[uncapped] / w[uncapped]
rec("c", "between first pinning and infeasibility: common lambda>1 rescale of "
    "uncapped trees, weighted mean restored",
    "wmean = m_stand; uncapped m_i still proportional to w",
    "wmean dev %.3e; uncapped m_i/w spread %.3e; %d of %d trees at cap"
    % (abs(wmean(mix, st["expf"]) - msx),
       float(ratio_unc.max() - ratio_unc.min()) if ratio_unc.size else 0.0,
       int(np.sum(mix >= cap - 1e-12)), mix.size),
    abs(wmean(mix, st["expf"]) - msx) < 1e-12)
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    inf = np.asarray(S.allocate(st["dbh"], st["expf"], st["qmd"], 0.99,
                                ht=st["ht"], cr=st["cr"], rht=st["rht"],
                                byi=st["byi"]), float)
warned = any("at or above the per-tree cap" in str(c.message) for c in caught)
rec("c", "infeasible stand rate 0.99 >= cap 0.95",
    "RuntimeWarning emitted, every tree returned at cap 0.95, stand under "
    "delivers by 0.04",
    "warned=%s, all at cap=%s" % (warned, bool(np.all(inf == cap))),
    warned and bool(np.all(inf == cap)))
rec("c", "bounds: no tree above cap, none below zero (whole sweep)",
    "0 <= m_i <= 0.95 everywhere", "held at every sweep point", bounds_ok)
m_ramp_max = mort_at(3000, 1)
m_forced = mort_at(3000, 1, maxlift=0.25)
rec("c", "MORT_MAX 0.20 caps the STAND rate inside Eq. 5b, not the per-tree "
    "allocation, and never binds on the deployed constants",
    "deployed max stand rate 0.156 < 0.20; cap binds only under a "
    "diagnostics override (maxlift=0.25 gives 0.256 -> clipped to 0.20)",
    "deployed max %.6f; override observed %.6f" % (m_ramp_max, m_forced),
    False if not (abs(m_forced - P.MORT_MAX) < 1e-15
                  and m_ramp_max < P.MORT_MAX) else False,
    flag_note="tasking described mort_max 0.20 as the per-tree cap; in code "
              "0.20 caps the stand rate (inert on deployed constants) and "
              "0.95 (ALLOC_MORT_CAP) is the per-tree cap. Max feasible stand "
              "rate under allocation is 0.95, unreachable from Eq. 5b.")

# ===========================================================================
print()
print("=" * 78)
print("SECTION d. DEGENERATE STANDS")
print("=" * 78)
mi1 = np.asarray(S.allocate(np.array([20.0]), np.array([100.0]), 20.0, 0.05,
                            ht=np.array([15.0]), cr=np.array([0.5]),
                            rht=np.array([1.0]), byi=264.0), float)
rec("d", "single tree", "m_i = m_stand exactly (w/wbar = 1)",
    "m_i = %.15f vs 0.05 (dev %.3e)" % (mi1[0], abs(mi1[0] - 0.05)),
    abs(mi1[0] - 0.05) < 1e-16)
d2 = np.array([10.0, 40.0]); e2 = np.array([1.0, 1000.0])
h2 = np.array([8.0, 22.0]); c2 = np.array([0.2, 0.6]); r2 = h2 / h2.max()
mi2 = np.asarray(S.allocate(d2, e2, 30.0, 0.05, ht=h2, cr=c2, rht=r2,
                            byi=264.0), float)
wm2 = wmean(mi2, e2)
rec("d", "two trees, expf 1 vs 1000",
    "weighted mean 0.05 held; rare tree may carry a much higher rate",
    "m_i = [%.6f, %.6f], weighted mean %.15f" % (mi2[0], mi2[1], wm2),
    abs(wm2 - 0.05) < 1e-15)
d3 = np.full(5, 20.0); e3 = np.full(5, 50.0); h3 = np.full(5, 15.0)
c3 = np.full(5, 0.5); r3 = np.full(5, 1.0)
mi3 = np.asarray(S.allocate(d3, e3, 20.0, 0.07, ht=h3, cr=c3, rht=r3,
                            byi=264.0), float)
rec("d", "all-identical trees (tie handling)",
    "every tree gets exactly the stand rate 0.07",
    "max |m_i - 0.07| = %.3e" % float(np.max(np.abs(mi3 - 0.07))),
    bool(np.max(np.abs(mi3 - 0.07)) < 1e-15))
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    mi0 = np.asarray(S.allocate(np.array([]), np.array([]), 20.0, 0.05,
                                ht=np.array([]), cr=np.array([]),
                                rht=np.array([]), byi=264.0), float)
    w_msgs = [str(c.message)[:60] for c in caught]
rec("d", "empty tree list / zero TPH",
    "returns empty array, no exception (numpy 0/0 RuntimeWarning on wbar)",
    "returned shape %s; warnings: %s" % (mi0.shape, w_msgs or "none"),
    False if mi0.size != 0 else False,
    flag_note="correct no-op but silent; FVS should skip mortality on an "
              "empty tree list explicitly")
with warnings.catch_warnings(record=True):
    warnings.simplefilter("always")
    miz = np.asarray(S.renormalize_to_stand_rate(np.array([0.1, 0.2]),
                                                 np.array([0.0, 0.0]), 0.05),
                     float)
rec("d", "renormalizer with total expf = 0",
    "early return of the clipped input (guard esum <= 0)",
    "returned %s" % miz, False if not np.allclose(miz, [0.1, 0.2]) else False,
    flag_note="constraint silently unenforced when total expf = 0")
d5 = np.array([1.0, 2.5, 20.0]); e5 = np.array([100.0, 100.0, 100.0])
h5 = np.array([2.0, 3.0, 15.0]); c5 = np.array([0.3, 0.3, 0.5])
r5 = h5 / h5.max()
mi5 = np.asarray(S.allocate(d5, e5, 12.0, 0.05, ht=h5, cr=c5, rht=r5,
                            byi=264.0), float)
rec("d", "DBH 1.0 and 2.5 cm (at and below the 2.5 cm data threshold)",
    "no special-casing: weight equation evaluates, weighted mean holds",
    "m_i = %s, wmean dev %.3e" % (np.round(mi5, 6),
                                  abs(wmean(mi5, e5) - 0.05)),
    False if abs(wmean(mi5, e5) - 0.05) >= 1e-15 else False,
    flag_note="the 2.5 cm screen is a fitting screen, not a runtime guard; "
              "Eq. 5 weights extrapolate below it (projector zeroes dDBH "
              "below breast height but mortality still applies)")
d6 = np.array([200.0, 20.0]); e6 = np.array([5.0, 200.0])
h6 = np.array([30.0, 15.0]); c6 = np.array([0.7, 0.5])
r6 = np.array([1.0, 0.5])
w6 = np.clip(1.0 - LINEAGES["A"].surv_annual(d6, h6, c6, r6, 264.0),
             1e-9, 1.0)
mi6 = np.asarray(S.allocate(d6, e6, 25.0, 0.05, ht=h6, cr=c6, rht=r6,
                            byi=264.0), float)
rec("d", "200 cm DBH tree (beyond data)",
    "Eq. 5 mortality underflows, weight floors at the 1e-9 clip, tree gets a "
    "near-zero rate; weighted mean holds",
    "w = [%.3e, %.3e], m_i(200cm) = %.3e, wmean dev %.3e"
    % (w6[0], w6[1], mi6[0], abs(wmean(mi6, e6) - 0.05)),
    False if abs(wmean(mi6, e6) - 0.05) >= 1e-15 else False,
    flag_note="extrapolation: very large trees become near-immortal in the "
              "allocation; the 1e-9 weight floor is the only guard")

# ===========================================================================
print()
print("=" * 78)
print("SECTION e. ANNUALIZATION AND INTERVAL BEHAVIOR")
print("=" * 78)
m_fix = 0.05
e0 = 100.0
e10 = e0
for _ in range(10):
    e10 = max(e10 * (1.0 - m_fix), 1e-5)
rec("e", "10-year survival at frozen state (loop semantics incl. 1e-5 floor)",
    "expf * (1-annual)^10 = %.10f" % (e0 * (1 - m_fix) ** 10),
    "%.10f (dev %.3e)" % (e10, abs(e10 - e0 * (1 - m_fix) ** 10)),
    abs(e10 - e0 * (1 - m_fix) ** 10) < 1e-12)
tr = pd.DataFrame(dict(dbh=st["dbh"], ht=st["ht"], cr=st["cr"],
                       expf=st["expf"]))
out1 = project_psp(tr.copy(), st["byi"], 0, "A", 1, surv_mode="calib_alloc",
                   ingrowth=False, use_size_caps=False)
tph1 = out1["TPH"]
order = np.argsort(-st["dbh"])
db_o = st["dbh"][order]; ht_o = st["ht"][order]; ex_o = st["expf"][order]
ba_o = db_o**2 * 0.00007854 * ex_o
bal_o = np.cumsum(ba_o) - ba_o
hcb_o = predict_HCB(db_o, ht_o, bal_o, st["baph"], st["byi"])
cr_o = np.clip(1 - hcb_o / np.maximum(ht_o, 0.1), 0.05, 0.95)
rht_o = ht_o / ht_o.max()
w_o = np.clip(1.0 - LINEAGES["A"].surv_annual(db_o, ht_o, cr_o, rht_o,
                                              st["byi"]), 1e-9, 1.0)
m_i_o = S.renormalize_to_stand_rate(m_stand * w_o / wmean(w_o, ex_o), ex_o,
                                    m_stand, cap=P.ALLOC_MORT_CAP)
tph_exp = float(np.sum(np.maximum(ex_o * (1 - m_i_o), 1e-5)))
rec("e", "one projector year removes exactly the allocated rates "
    "(weights use the projector's recomputed CR, not the input CR)",
    "TPH after 1 yr = %.10f" % tph_exp,
    "%.10f (dev %.3e)" % (tph1, abs(tph1 - tph_exp)),
    abs(tph1 - tph_exp) < 1e-9)
rec("e", "YIP",
    "Eq. 5b has no YIP; YIP enters only the fitted Eq. 5 cloglog as a ln(YIP) "
    "offset and the allocation weight calls it with yip=1, so YIP is inert in "
    "the deployed chain; a multi-year interval is consumed as that many "
    "annual steps with state recomputed each year (per-year compounding, "
    "never a per-period rate)",
    "verified by code read of project_psp and LineageA.surv_annual; "
    "compounding verified numerically above", True)
rec("e", "expansion-factor floor",
    "expf floored at 1e-5 trees/ha every year; a cohort never reaches zero",
    "np.maximum(expf*ps, 1e-5) in project_psp", False,
    flag_note="trees never fully die in the Python engine; FVS must decide "
              "to reproduce or replace the 1e-5 floor (FVS kills trees "
              "by reducing TPA, so the natural port drops the floor and "
              "documents the divergence)")

# ===========================================================================
print()
print("=" * 78)
print("SECTION f. INTERACTION ORDER (code read of koa_projector.project_psp)")
print("=" * 78)
seq = """within one projection year, in order, all reading START-OF-YEAR state:
 1. sort trees by descending DBH
 2. stand summary: per-tree BA, BAL (cumsum less own BA), BAPH, TPH, QMD,
    SDI = TPH*(QMD/25)^1.605, HTmax
 3. crown update: HCB model -> CR = clip(1 - HCB/HT, 0.05, 0.95) [overwrites CR]
 4. rHT = HT / max(HTmax, 0.1)
 5. dDBH, dHT computed but NOT yet applied; dDBH = 0 where HT < 1.3716 m
 6. mortality: m_stand = 1 - surv_calibrated(sdi=step-2 SDI, planted);
    weights w = clip(1 - Eq5.surv_annual(dbh, ht, step-3 CR, step-4 rht, byi),
    1e-9, 1); m_i = renormalize(m_stand*w/wbar); expf *= (1 - m_i), floor 1e-5
 7. increments applied: DBH += dDBH, HT += dHT; size caps REJECT the step
    (tree keeps its old DBH or HT if the cap would be exceeded)
 8. ingrowth: expected recruits from step-2 SDI, appended at 2.5 cm DBH with
    modeled height (step-2 BAPH, QMD) and CR 0.6
 9. if >300 records, bin to 0.5 cm DBH classes (expf-weighted means)
SDI is recomputed only at the top of the NEXT year: mortality in year t uses
pre-growth, pre-ingrowth density of year t; increments in year t use
pre-mortality competition (BAL, BAPH) of year t."""
print(seq)
rec("f", "order of operations",
    "grow computed, mortality applied, growth applied, ingrowth appended, "
    "all on start-of-year state; SDI recomputed once per year",
    "verified by code read; the mortality-before-growth interleave confirmed "
    "numerically in section e", True)

# ===========================================================================
print()
print("=" * 78)
print("SECTION g. DETERMINISM")
print("=" * 78)
runs = []
for _ in range(2):
    mi_r = np.asarray(S.allocate(st["dbh"], st["expf"], st["qmd"], m_stand,
                                 ht=st["ht"], cr=st["cr"], rht=st["rht"],
                                 byi=st["byi"]), float)
    out_r = project_psp(tr.copy(), st["byi"], 0, "A", 10,
                        surv_mode="calib_alloc", ingrowth=True,
                        return_traj=True)
    runs.append((mi_r.tobytes(), out_r["traj"].to_numpy().tobytes()))
det = runs[0] == runs[1]
rec("g", "identical inputs give identical outputs (allocation + 10-yr "
    "projection with ingrowth)", "bitwise identical",
    "bitwise identical" if det else "DIFFER", det)
rec("g", "no RNG in the mortality path",
    "no random draws in surv_calibrated, allocate, renormalize_to_stand_rate, "
    "project_psp, or ingrowth_annual (expected-value recruitment)",
    "verified by code read", True)

# ===========================================================================
print()
print("=" * 78)
print("SECTION h. NaN / NEGATIVE / MISSING INPUTS")
print("=" * 78)


def try_alloc(dbh, expf, ht, cr, rht):
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        try:
            out = np.asarray(S.allocate(np.asarray(dbh, float),
                                        np.asarray(expf, float), 20.0, 0.05,
                                        ht=np.asarray(ht, float),
                                        cr=np.asarray(cr, float),
                                        rht=np.asarray(rht, float),
                                        byi=264.0), float)
            wmv = (wmean(out, expf) if np.sum(expf) != 0 else float("nan"))
            return out, ("returned %s; wmean %.6g; %d warnings"
                         % (np.round(out, 6), wmv, len(caught)))
        except Exception as exc:
            return None, "raised %s: %s" % (type(exc).__name__, exc)


d = [10.0, 20.0, 30.0]; e = [100.0, 100.0, 100.0]
h = [8.0, 15.0, 20.0]; c = [0.3, 0.5, 0.6]; r = [0.4, 0.75, 1.0]
out, obs = try_alloc([np.nan, 20.0, 30.0], e, h, c, r)
nan_all = out is not None and bool(np.all(np.isnan(out)))
rec("h", "NaN DBH", "NaN propagates through the weight and wbar and poisons "
    "EVERY tree's rate (no raise, no drop)", obs, False if nan_all else False,
    flag_note="one bad tree silently NaNs the whole stand's mortality; the "
              "FVS port needs an input guard the Python engine does not have")
out, obs = try_alloc(d, [100.0, -50.0, 100.0], h, c, r)
neg_ok = out is not None and not bool(np.any(np.isnan(out)))
rec("h", "negative expansion factor",
    "no guard: negative expf enters wbar and the constraint is enforced "
    "against a corrupted mean; per-tree rates stay in [0, cap]", obs,
    False if neg_ok else False,
    flag_note="silently accepted; the weighted-mean identity is algebraic, "
              "not physical, under negative weights")
out, obs = try_alloc(d, e, h, [0.3, np.nan, 0.6], r)
nan_cr = out is not None and bool(np.all(np.isnan(out)))
rec("h", "missing (NaN) crown ratio", "np.clip keeps NaN; propagates through "
    "ln(CR) to every tree, same contamination as NaN DBH", obs,
    False if nan_cr else False,
    flag_note="same stand-wide contamination mode")
mn = mort_at(float("nan"))
rec("h", "NaN SDI into Eq. 5b", "NaN mortality returned (clip keeps NaN); "
    "no raise", "mort = %s" % mn, False if np.isnan(mn) else False,
    flag_note="propagates")
mneg = mort_at(-50.0)
rec("h", "negative SDI into Eq. 5b", "frac clips to 0, mortality = base",
    "mort = %.6f" % mneg, abs(mneg - P.BASE_NAT) < 1e-15)

# ===========================================================================
print()
print("=" * 78)
print("ACCEPTANCE TEST VECTORS (full precision, for the Ben Rice spec)")
print("=" * 78)
np.set_printoptions(precision=17, suppress=False, linewidth=110)
print("\nAT-1 ramp: (SDI, planted) -> annual mortality")
for sdi in [0, 200, 400, 525, 850, 1200]:
    for pl in (0, 1):
        print("  SDI %6g planted %d -> %.17g" % (sdi, pl, mort_at(sdi, pl)))
print("\nAT-2 five-tree allocation, cap not binding")
d = np.array([5.0, 12.0, 20.0, 35.0, 60.0])
e = np.array([300.0, 150.0, 80.0, 40.0, 15.0])
h = np.array([5.0, 11.0, 16.0, 22.0, 27.0])
c = np.array([0.15, 0.30, 0.45, 0.55, 0.65])
r = h / h.max()
byi = 264.0
ba = float((d**2 * 0.00007854 * e).sum()); tph = float(e.sum())
qmd = float(np.sqrt(ba / (0.00007854 * tph))); sdi = float(sdi_of(tph, qmd))
ms = 1.0 - float(np.atleast_1d(S.surv_calibrated(qmd, h.max(), 0.5, 0.5, byi,
                                                 baph=ba, planted=0,
                                                 sdi=sdi))[0])
mi_at2 = np.asarray(S.allocate(d, e, qmd, ms, ht=h, cr=c, rht=r, byi=byi),
                    float)
wgt = np.clip(1.0 - LINEAGES["A"].surv_annual(d, h, c, r, byi), 1e-9, 1.0)
print("  inputs: dbh ", [float(x) for x in d])
print("          expf", [float(x) for x in e])
print("          ht  ", [float(x) for x in h])
print("          cr  ", [float(x) for x in c])
print("          rht ", ["%.17g" % x for x in r])
print("          byi ", byi, " planted 0")
print("  derived: BAPH %.17g  TPH %.17g  QMD %.17g  SDI %.17g"
      % (ba, tph, qmd, sdi))
print("  m_stand %.17g" % ms)
print("  Eq.5 weights w_i:", wgt)
print("  allocated m_i:", mi_at2)
print("  expf-weighted mean of m_i: %.17g" % wmean(mi_at2, e))
print("\nAT-3 cap-binding renormalization (same 5 trees, forced m_stand 0.93)")
with warnings.catch_warnings(record=True):
    warnings.simplefilter("always")
    mi_at3 = np.asarray(S.allocate(d, e, qmd, 0.93, ht=h, cr=c, rht=r,
                                   byi=byi), float)
print("  allocated m_i:", mi_at3)
print("  n at cap 0.95: %d; expf-weighted mean %.17g (target 0.93)"
      % (int(np.sum(mi_at3 >= 0.95 - 1e-12)), wmean(mi_at3, e)))
print("\nAT-4 infeasible stand rate 0.99 (cap 0.95)")
with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    mi_at4 = np.asarray(S.allocate(d, e, qmd, 0.99, ht=h, cr=c, rht=r,
                                   byi=byi), float)
print("  all at cap: %s; warning: %s"
      % (bool(np.all(mi_at4 == 0.95)),
         [str(cw.message)[:100] for cw in caught]))
print("\nAT-5 ten annual applications of a frozen 0.05 rate")
print("  expf 100 -> %.17g  (= 100*0.95^10 = %.17g)" % (e10, 100 * 0.95**10))
print("\nAT-6 single tree")
print("  allocate(dbh=[20], expf=[100], qmd=20, m_stand=0.05, ht=[15], "
      "cr=[0.5], rht=[1.0], byi=264) -> %.17g" % mi1[0])

# ===========================================================================
print()
print("=" * 78)
print("SUMMARY TABLE")
print("=" * 78)
n_pass = sum(1 for r_ in RESULTS if r_[4] == "PASS")
n_flag = len(RESULTS) - n_pass
for sec, case, expc, obsv, verd in RESULTS:
    print("%-3s %-5s %s" % (sec, verd.split()[0], case))
print("\n%d cases: %d PASS, %d FLAG (annotated)" % (len(RESULTS), n_pass,
                                                    n_flag))
