#!/usr/bin/env python3
"""Koa financial model yield curves: 4 site classes x 4 planting densities, 200 yr.

Engine of record: regen_m1 (M1 Chen Stage 1 gate on the Garcia rate, Weibull
tree-list init, Stage 3 allocation by the respecified survivor equation,
origin mortality calibration of 2026-09-16). Importing regen_m1 applies the
stand_mortality patch; nothing here re-derives an equation.

Densities are ESTABLISHED stems, not seedlings planted. The system carries no
establishment mortality (Supplement Section 7.2), so planted density must be
divided by the survival target before it is entered here.
"""
import os, sys, json
sys.path.insert(0, "/home/aaron/jobs/koa_v103_20260930/engine_v103")
os.chdir("/home/aaron/jobs/koa_v103_20260930/engine_v103")
import numpy as np, pandas as pd

import regen_m1 as RM          # module-level patch: MG/PR/RC.stand_mortality -> gated
import run_candidates as RC
import koa_params as P

OUT = "/home/aaron/jobs/koa_v103_20260930/a2/fin/out"
os.makedirs(OUT, exist_ok=True)

AC_PER_HA = 2.4710538
FT2_PER_M2_PER_AC = 10.7639 / AC_PER_HA      # m2/ha -> ft2/acre = 4.3560
SITES = [("Excellent", 450), ("Good", 340), ("Marginal", 230), ("Low Feasibility", 120)]
TPAS = [100, 200, 300, 400]
NYR = 200
PLANTED = True


def wlist_n(planted, byi, n0):
    """RC.wlist with the stocking overridden. Same Weibull, same mean dbh."""
    w = RC.W[1 if planted else 0]
    d0 = P.harness_init_dbh(1 if planted else 0)
    q = (np.arange(RC.N_CLASS) + 0.5) / RC.N_CLASS
    d = w["lam"] * (-np.log(1 - q)) ** (1.0 / w["k"])
    d = d * (d0 / d.mean())
    return RC._finish(d, np.full(RC.N_CLASS, n0 / RC.N_CLASS), byi)


def reineke(d):
    """Realized self-thinning slope, ln(TPH) on ln(QMD), over the horizon."""
    m = (d.QMD > 2.5) & (d.TPH > 1) & np.isfinite(d.QMD) & np.isfinite(d.TPH)
    if m.sum() < 10:
        return float("nan")
    return float(np.polyfit(np.log(d.QMD[m]), np.log(d.TPH[m]), 1)[0])


frames, diag = [], []
for site, byi in SITES:
    for tpa in TPAS:
        tph0 = tpa * AC_PER_HA
        RM.set_params(None)
        d = RC.project(wlist_n(PLANTED, byi, tph0), byi, PLANTED, NYR, "M0")
        RM.set_params(None)
        d = d.assign(site=site, byi=byi, tpa0=tpa, tph0=round(tph0, 1))
        d["age"] = d["year"]
        d["BA_ft2ac"] = d.BAPH * FT2_PER_M2_PER_AC
        d["TPA"] = d.TPH / AC_PER_HA
        d["QMD_in"] = d.QMD / 2.54
        d["HT_ft"] = d.HT * 3.280840
        d["VBAR_cuft_per_ft2"] = np.where(d.BAPH > 1e-9, d.VOL / d.BAPH, np.nan) * 3.280840
        frames.append(d)
        dd = d.set_index("age")
        diag.append(dict(
            site=site, byi=byi, tpa0=tpa,
            BA_max_ft2ac=round(float(d.BA_ft2ac.max()), 2),
            age_at_BA_max=int(d.BA_ft2ac.idxmax() + 1),
            BA20=round(float(dd.loc[20, "BA_ft2ac"]), 2),
            BA40=round(float(dd.loc[40, "BA_ft2ac"]), 2),
            BA52=round(float(dd.loc[52, "BA_ft2ac"]), 2),
            BA100=round(float(dd.loc[100, "BA_ft2ac"]), 2),
            BA200=round(float(dd.loc[200, "BA_ft2ac"]), 2),
            QMD52_in=round(float(dd.loc[52, "QMD_in"]), 2),
            QMD100_in=round(float(dd.loc[100, "QMD_in"]), 2),
            TPA52=round(float(dd.loc[52, "TPA"]), 1),
            TPA100=round(float(dd.loc[100, "TPA"]), 1),
            reineke_slope=round(reineke(d), 3),
            BA_monotone_to_peak=bool(
                (d.BA_ft2ac.iloc[:int(d.BA_ft2ac.idxmax()) + 1].diff().dropna() >= -1e-9).all()),
        ))

A = pd.concat(frames, ignore_index=True)
cols = ["site", "byi", "tpa0", "tph0", "age", "BA_ft2ac", "TPA", "QMD_in", "HT_ft",
        "VBAR_cuft_per_ft2", "BAPH", "TPH", "QMD", "HT", "VOL", "SDI", "DBHMAX",
        "m_stand", "m_realised"]
A[cols].to_csv(os.path.join(OUT, "koa_yield_grid_200yr.csv"), index=False)
D = pd.DataFrame(diag)
D.to_csv(os.path.join(OUT, "koa_yield_grid_diagnostics.csv"), index=False)
print(D.to_string(index=False))
print()
print("rows", len(A), "-> ", os.path.join(OUT, "koa_yield_grid_200yr.csv"))
