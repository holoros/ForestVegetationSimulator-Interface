#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Propagate origin-calibration multiplier uncertainty through the koa v102
planted projection.

Nothing in the engine directory is edited. The engine of record is imported as
regen_m1 (module-level it sets P.ALLOC_MODE = "tree_eq" and monkeypatches
stand_mortality to the M1-gated, mortality-calibrated form), and the planted
origin-calibration multipliers are selected through the engine's own runtime
configuration point: the LineageA.CAL_DDBH / LineageA.CAL_DHT class attributes
that koa_equations.cal_draw() itself writes. The natural pair element is left at
its deployed value in every setting.

Settings (planted element only):
  deployed  dDBH 1.43606  dHT 2.64739
  lower     dDBH 0.518    dHT 0.541      (95% interval lower bounds, Table S20)
  upper     dDBH 2.051    dHT 3.597      (95% interval upper bounds, Table S20)

Outputs are deterministic engine evaluations. They carry no sampling interval.
"""
import os, sys, json
import numpy as np
import pandas as pd

ENG = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102")
OUT = os.path.expanduser("~/jobs/koa_calint_20260926/out")
sys.path.insert(0, ENG)
os.environ.setdefault("MPLCONFIGDIR", os.path.join(ENG, ".mplcache"))
os.makedirs(OUT, exist_ok=True)

import koa_params as P
import koa_equations as KE
import run_candidates as RC
import regen_m1 as RM          # module-level: engine of record patches applied on import

NYEARS = 250
AGES = (40, 100)
SITES = ((100, "Low"), (264, "Medium"), (450, "High"))

# Gates, fixed in advance (observed maxima)
GATE = dict(BAPH=76.0621, SDI=1453.4673, QMD=69.68)

DEP_DD_NAT, DEP_DD_PLT = P.CAL_DDBH
DEP_DH_NAT, DEP_DH_PLT = P.CAL_DHT

SETTINGS = [
    ("deployed", DEP_DD_PLT, DEP_DH_PLT),
    ("lower",    0.518,      0.541),
    ("upper",    2.051,      3.597),
]

print("engine dir      :", ENG)
print("MORT_ENGINE     :", P.MORT_ENGINE)
print("ALLOC_MODE      :", P.ALLOC_MODE)
print("deployed CAL_DDBH (nat, plt):", P.CAL_DDBH)
print("deployed CAL_DHT  (nat, plt):", P.CAL_DHT)
print("stand_mortality patched     :", RC.stand_mortality is not RM._ORIG_SM)
print()

frames = []
for name, dd_plt, dh_plt in SETTINGS:
    for byi, site in SITES:
        RM.set_params(None)                 # restore every deployed base value
        KE.joint_assert_clean("pre " + name)
        # engine's own configuration point for the origin calibration multipliers
        KE.LineageA.CAL_DDBH = (DEP_DD_NAT, dd_plt)
        KE.LineageA.CAL_DHT = (DEP_DH_NAT, dh_plt)
        d = RC.project(RC.wlist(1, byi), byi, True, NYEARS, "M0")
        KE.LineageA.CAL_DDBH = P.CAL_DDBH   # hand state back before the next cell
        KE.LineageA.CAL_DHT = P.CAL_DHT
        RM.set_params(None)
        KE.joint_assert_clean("post " + name)
        d = d.assign(setting=name, cal_ddbh_plt=dd_plt, cal_dht_plt=dh_plt,
                     byi=byi, site=site, origin="plt", planted=1)
        d["MAI"] = d.VOL / d.year
        frames.append(d)
        print("  ran %-8s BYI %3d  (%s)" % (name, byi, site), flush=True)

A = pd.concat(frames, ignore_index=True)
A.to_csv(os.path.join(OUT, "traj_calint_planted.csv"), index=False)

# ------------------------------------------------------------------ point table
rows = []
for (name, byi), g in A.groupby(["setting", "byi"], sort=False):
    g = g.set_index("year")
    for a in AGES:
        r = g.loc[a]
        rows.append(dict(setting=name, byi=byi, site=g.site.iloc[0], age=a,
                         cal_ddbh_plt=float(g.cal_ddbh_plt.iloc[0]),
                         cal_dht_plt=float(g.cal_dht_plt.iloc[0]),
                         QMD=round(float(r.QMD), 2), BAPH=round(float(r.BAPH), 2),
                         TPH=round(float(r.TPH), 2), HT=round(float(r.HT), 2),
                         VOL=round(float(r.VOL), 2), MAI=round(float(r.VOL / a), 2)))
T = pd.DataFrame(rows)
T.to_csv(os.path.join(OUT, "table_calint_points.csv"), index=False)

# --------------------------------------------------------- MAI culmination age
culm = []
for (name, byi), g in A.groupby(["setting", "byi"], sort=False):
    for hz in (100, NYEARS):
        s = g[g.year <= hz]
        i = int(s.MAI.to_numpy(float).argmax())
        culm.append(dict(setting=name, byi=byi, site=g.site.iloc[0], horizon=hz,
                         culm_age=int(s.year.to_numpy()[i]),
                         MAI_max=round(float(s.MAI.to_numpy(float)[i]), 2),
                         at_horizon_edge=bool(int(s.year.to_numpy()[i]) == hz)))
C = pd.DataFrame(culm)
C.to_csv(os.path.join(OUT, "table_calint_culmination.csv"), index=False)

# ---------------------------------------------------------------------- gates
grows = []
for (name, byi), g in A.groupby(["setting", "byi"], sort=False):
    for hz in (100, NYEARS):
        s = g[g.year <= hz]
        rec = dict(setting=name, byi=byi, site=g.site.iloc[0], horizon=hz)
        for v, lim in GATE.items():
            mx = float(s[v].max())
            yr = int(s.year.to_numpy()[int(s[v].to_numpy(float).argmax())])
            rec[v + "_max"] = round(mx, 4)
            rec[v + "_max_age"] = yr
            rec[v + "_limit"] = lim
            rec[v + "_exceed"] = round(mx - lim, 4) if mx > lim else 0.0
            rec[v + "_exceed_pct"] = round(100.0 * (mx - lim) / lim, 2) if mx > lim else 0.0
        grows.append(rec)
G = pd.DataFrame(grows)
G.to_csv(os.path.join(OUT, "table_calint_gates.csv"), index=False)

# ------------------------------------------------- reproduction check, deployed
ref = pd.read_csv(os.path.join(ENG, "out_m1", "table8_evenaged_M1.csv"))
ref = ref[ref.Scenario.str.contains("planted")]
chk = []
for _, r in ref.iterrows():
    if int(r.Age) not in AGES:
        continue
    byi = int(r.Site.split("(")[1].rstrip(")"))
    m = T[(T.setting == "deployed") & (T.byi == byi) & (T.age == int(r.Age))]
    if not len(m):
        continue
    m = m.iloc[0]
    for v in ("QMD", "BAPH", "TPH", "VOL", "MAI"):
        chk.append(dict(byi=byi, age=int(r.Age), var=v,
                        deposited=float(r[v]), rerun=float(m[v]),
                        diff=round(float(m[v]) - float(r[v]), 6)))
K = pd.DataFrame(chk)
K.to_csv(os.path.join(OUT, "check_deployed_vs_deposited.csv"), index=False)
worst = float(K["diff"].abs().max())

print()
print("=" * 100)
print("REPRODUCTION CHECK, deployed setting vs deposited out_m1/table8_evenaged_M1.csv")
print("  max |diff| over QMD, BAPH, TPH, VOL, MAI at ages 40 and 100 = %.6f  -> %s"
      % (worst, "PASS" if worst <= 0.005 else "FAIL"))
print("=" * 100)
print()
print("POINT TABLE (deterministic engine outputs, no sampling interval)")
print(T.to_string(index=False))
print()
print("NET MAI CULMINATION AGE")
print(C.to_string(index=False))
print()
print("GATES vs observed maxima BAPH 76.0621, SDI 1453.4673, QMD 69.68")
print(G.to_string(index=False))
print()
print("HT_FALLBACK_CALLS", KE.HT_FALLBACK_CALLS[0])
print("wrote", sorted(os.listdir(OUT)))
print("done")
