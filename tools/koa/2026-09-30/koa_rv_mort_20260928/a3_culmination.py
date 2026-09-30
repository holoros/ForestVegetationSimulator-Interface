#!/usr/bin/env python3
"""a3_culmination.py  koa R1 c25. Net MAI (VOL/age) culmination age, point and 95% Monte Carlo
interval, per scenario x site, from the replicate trajectories that produced Table 5
(engine_v102/out_m1/reps_evenaged_M1.csv, 500 reps; uneven_aged_reps_M1.csv, 300 reps) and the
point trajectories (traj_M1.csv, uneven_aged_traj_M1.csv), under several stated search windows.
Also the planted multiplier-interval culmination from koa_calint_20260926/out/traj_calint_planted.csv."""
import os, numpy as np, pandas as pd
JOB = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(JOB, "out_a3"); os.makedirs(OUT, exist_ok=True)
E = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102/out_m1")
SITE = {100: "Low", 264: "Medium", 450: "High"}
ev = pd.read_csv(os.path.join(E, "reps_evenaged_M1.csv"))
ua = pd.read_csv(os.path.join(E, "uneven_aged_reps_M1.csv")); ua["scen"] = "uneven"
tr = pd.read_csv(os.path.join(E, "traj_M1.csv")); tr = tr.rename(columns={"origin": "scen"})
ut = pd.read_csv(os.path.join(E, "uneven_aged_traj_M1.csv"))
if "year" not in ut.columns and "age" in ut.columns: ut["year"] = ut["age"]
if "byi" not in ut.columns and "BYI" in ut.columns: ut["byi"] = ut["BYI"]
ut["scen"] = "uneven"; ut["rep"] = -1
if "VOL" not in ut.columns: ut["VOL"] = ut["Vol"]
tr["rep"] = -1
reps = pd.concat([ev[["scen", "byi", "rep", "year", "VOL"]], ua[["scen", "byi", "rep", "year", "VOL"]]])
pts = pd.concat([tr[["scen", "byi", "rep", "year", "VOL"]], ut[["scen", "byi", "rep", "year", "VOL"]]])
pts = pts[pts.year <= 100]; reps = reps[reps.year <= 100]

def culm(y, v, rule):
    mai = v / y
    if rule == "w10_100":   s = (y >= 10)
    elif rule == "w5_100":  s = (y >= 5)
    elif rule == "w2_100":  s = (y >= 2)
    elif rule == "w1_100":  s = (y >= 1)
    elif rule == "interior":   # argmax after the first local minimum of net MAI (post initial-stock transient)
        dm = np.diff(mai); k = np.argmax(dm > 0) if np.any(dm > 0) else 0
        s = np.arange(len(y)) >= k
    yy, mm = y[s], mai[s]
    j = int(np.argmax(mm)); return int(yy[j]), float(mm[j]), bool(j == 0), bool(j == len(yy) - 1)

RULES = ["w10_100", "w5_100", "w2_100", "w1_100", "interior"]
rows = []
for (sc, b), g in reps.groupby(["scen", "byi"]):
    p = pts[(pts.scen == sc) & (pts.byi == b)].sort_values("year")
    for rule in RULES:
        pa, pm, pe0, pe1 = culm(p.year.to_numpy(), p.VOL.to_numpy(), rule)
        a = []; lo_edge = 0; hi_edge = 0
        for r, gr in g.groupby("rep"):
            gr = gr.sort_values("year"); x = culm(gr.year.to_numpy(), gr.VOL.to_numpy(), rule)
            a.append(x[0]); lo_edge += x[2]; hi_edge += x[3]
        a = np.array(a)
        rows.append(dict(scenario=sc, site=SITE[int(b)], byi=int(b), window=rule, n_reps=len(a),
                         point_age=pa, point_netMAI=round(pm, 2), point_at_lower_edge=pe0,
                         rep_median=float(np.median(a)), lo95=float(np.percentile(a, 2.5)), hi95=float(np.percentile(a, 97.5)),
                         share_reps_at_lower_edge=round(lo_edge / len(a), 3), share_reps_at_upper_edge=round(hi_edge / len(a), 3)))
T = pd.DataFrame(rows); T.to_csv(os.path.join(OUT, "a3_culmination_all_windows.csv"), index=False)
pd.set_option("display.width", 250); print(T.to_string(index=False))
# initial list volume / age-0 facts
for sc in ("nat", "plt"):
    for b in (100, 264, 450):
        p = pts[(pts.scen == sc) & (pts.byi == b)].sort_values("year")
        print("start", sc, b, "VOL yr1 %.2f yr5 %.2f yr10 %.2f" % tuple(p.set_index("year").VOL.loc[[1, 5, 10]]))
# planted multiplier interval (koa_calint), deterministic
C = pd.read_csv(os.path.expanduser("~/jobs/koa_calint_20260926/out/traj_calint_planted.csv"))
print(C.columns.tolist()); rows = []
yc = "year" if "year" in C.columns else "age"
for (st, b), g in C.groupby(["setting", "byi"]):
    g = g[g[yc] <= 100].sort_values(yc)
    for rule in RULES:
        a, m, e0, e1 = culm(g[yc].to_numpy(), g.VOL.to_numpy(), rule)
        rows.append(dict(setting=st, site=SITE[int(b)], window=rule, culm_age=a, netMAI=round(m, 2), at_lower_edge=e0))
C2 = pd.DataFrame(rows); C2.to_csv(os.path.join(OUT, "a3_calint_planted_culmination.csv"), index=False)
print(C2.pivot_table(index=["setting", "site"], columns="window", values="culm_age").to_string())
