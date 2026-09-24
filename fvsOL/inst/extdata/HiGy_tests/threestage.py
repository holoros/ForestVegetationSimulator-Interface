# -*- coding: utf-8 -*-
"""Three-stage mortality candidates M0, M1 and M2, per MORTALITY_RULE_2026-09-12.md.

Stage 1 supplies the annual probability that a stand experiences any mortality. Stage 2
supplies the rate given that it does. Stage 3, unchanged from the engine of record, uses
the fitted tree-level survivor equation of manuscript Table 6 to order deaths within the
stand, renormalized to the stand rate.

Nothing here refits the tree-level survival equation.
"""
import json, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
_F = json.load(open(os.path.join(HERE, "out_stage1", "stage1_fit.json")))

# ---- Stage 1, fitted 12 September 2026 on 326 plot intervals over 54 plots -------------
# cloglog with ln(YIP) offset: P(any mortality | YIP) = 1 - exp(-exp(eta + ln YIP))
S1 = _F["stage1_beta"]                       # intercept, lnSDI, planted
S1_CI = _F["stage1_ci"]
S1_AUC = _F["stage1_auc"]
P_BAR = _F["stage1_mean_annual_p"]           # mean fitted annual occurrence, 0.3601

# ---- Stage 2 conditional magnitude, fitted on the 151 mortality-bearing intervals ------
# ln(annual rate) = c0 + c1 ln(SDI) + c2 planted
S2 = _F["stage2_beta"]
S2_CI = _F["stage2_ci"]
S2_DUAN = _F["stage2_duan"]        # Duan (1983) smearing, log-scale retransformation

SDI_FLOOR = 1.0
import koa_params as _KP


def mort_cal(planted=0):
    """Origin mortality level multiplier on the M1 stand rate (natural calibrated, planted 1), 2026-09-16."""
    return float(_KP.MORT_CAL_LIVE[1 if planted else 0])


def stage1_p(sdi, planted=0, yip=1.0):
    """Annual probability that the stand experiences any mortality."""
    eta = (S1["intercept"] + S1["lnSDI"] * np.log(max(float(sdi), SDI_FLOOR))
           + S1["planted"] * (1 if planted else 0) + np.log(max(float(yip), 1e-9)))
    return float(1.0 - np.exp(-np.exp(np.clip(eta, -30.0, 5.0))))


def stage2_conditional(sdi, planted=0):
    """Annual mortality rate given that mortality occurs."""
    lnm = (S2["intercept"] + S2["lnSDI"] * np.log(max(float(sdi), SDI_FLOOR))
           + S2["planted"] * (1 if planted else 0))
    return float(np.clip(np.exp(lnm) * S2_DUAN, 0.0, 0.95))


def rate_M1(m_garcia, sdi, planted=0):
    """Gate only, expectation preserved. The incumbent rate is made conditional by
    dividing by the mean fitted annual occurrence, then gated by the fitted occurrence."""
    return float(np.clip(m_garcia / P_BAR * stage1_p(sdi, planted), 0.0, 0.95))


# M4, added 12 September 2026 under AMENDMENT 1 after M2 was scored. Chen's structure,
# namely a constant conditional magnitude gated by the fitted density-dependent occurrence,
# rescaled by a single disclosed constant KAPPA so the deployed LEVEL matches the engine of
# record. The structure comes from the koa data; the level does not, and cannot, until the
# growth side is repaired alongside it.
KAPPA = 0.146671       # calibrated 12 September 2026 so the deployed level matches the
                        # engine of record; the record's own level is 1/KAPPA times higher


def rate_M4(m_garcia, sdi, planted=0, kappa=None):
    k = KAPPA if kappa is None else kappa
    m = stage2_conditional(sdi, planted) * stage1_p(sdi, planted) * k
    return float(np.clip(m, 0.0, 0.95))


def rate_M5(m_garcia, sdi, planted=0, kappa=None):
    """M4's Chen structure with the Garcia self-thinning rate retained as a FLOOR, so the
    deployed rate is never below what self-thinning already demands. Added 12 September
    2026 under AMENDMENT 1, after M4 lost the density envelope by thinning too little
    early."""
    return float(np.clip(max(rate_M4(m_garcia, sdi, planted, kappa), float(m_garcia)),
                         0.0, 0.95))


def rate_M2(m_garcia, sdi, planted=0, cap_to_garcia_limit=True):
    """Chen-faithful. Stage 2 conditional magnitude times Stage 1 occurrence. The Garcia
    self-thinning rate is retained as a lower bound only, so the self-thinning boundary is
    never LESS binding than the incumbent engine makes it."""
    m = stage2_conditional(sdi, planted) * stage1_p(sdi, planted)
    if cap_to_garcia_limit:
        m = max(m, float(m_garcia))      # never below what self-thinning already demands
    return float(np.clip(m, 0.0, 0.95))


def describe():
    lo, hi = S1_CI["lnSDI"]
    lo2, hi2 = S2_CI["lnSDI"]
    return (
        "Stage 1 cloglog, ln(SDI) %+.5f [%+.5f, %+.5f], AUC %.4f, mean annual p %.4f\n"
        "Stage 2 conditional, ln(SDI) %+.5f [%+.5f, %+.5f]\n"
        % (S1["lnSDI"], lo, hi, S1_AUC, P_BAR, S2["lnSDI"], lo2, hi2))


if __name__ == "__main__":
    print(describe())
    print(f"{'SDI':>8s} {'p(any)':>9s} {'m|any':>9s} {'M2 rate':>9s}")
    for s in (50, 100, 200, 400, 600, 900, 1200):
        print(f"{s:8d} {stage1_p(s):9.4f} {stage2_conditional(s):9.4f} "
              f"{stage2_conditional(s)*stage1_p(s):9.4f}")
