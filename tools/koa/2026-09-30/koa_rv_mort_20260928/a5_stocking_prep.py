#!/usr/bin/env python3
"""a5_stocking_prep.py  koa R2 c9. Exports stems/ha and QMD (and largest-tree DBH) by age for the Table 5
point trajectories (out_m1/traj_M1.csv, uneven_aged_traj_M1.csv) and the Fig. 6 density and thinning
trajectories (koa_density_20260925/out/SC_trajectories.csv), ready for overlay on the Baker and Scowcroft
(2005) stocking lines once those line equations are available. crossing(traj, line_fn) returns the first
age at which TPH crosses a line TPH_line(QMD). No stocking line is defined here."""
import os, numpy as np, pandas as pd
JOB = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(JOB, "out_a5")
E = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102/out_m1")
SITE = {100: "Low", 264: "Medium", 450: "High"}
t = pd.read_csv(os.path.join(E, "traj_M1.csv")); t = t[t.year <= 100]
t = pd.DataFrame(dict(source="Table 5", scenario=np.where(t.planted == 1, "Even-aged planted", "Even-aged natural"),
                      site=t.byi.map(SITE), age=t.year, TPH=t.TPH, QMD=t.QMD, DBHMAX=t.DBHMAX))
u = pd.read_csv(os.path.join(E, "uneven_aged_traj_M1.csv")); u = u[u.age <= 100]
u = pd.DataFrame(dict(source="Table 5", scenario="Uneven-aged natural", site=u.BYI.map(SITE), age=u.age, TPH=u.TPH, QMD=u.QMD, DBHMAX=u.DBHMAX))
s = pd.read_csv(os.path.expanduser("~/jobs/koa_density_20260925/out/SC_trajectories.csv"))
s = pd.DataFrame(dict(source="Fig. 6", scenario=s.origin + " " + s.label, site="Medium", age=s.year, TPH=s.TPH, QMD=s.QMD, DBHMAX=s.DBHMAX))
A = pd.concat([t, u, s], ignore_index=True); A.to_csv(os.path.join(OUT, "a5_tph_qmd_trajectories.csv"), index=False)
W = A[A.age.isin([5, 10, 20, 30, 40, 60, 80, 100])].copy(); W["TPH"] = W.TPH.round(0); W["QMD"] = W.QMD.round(1)
W.pivot_table(index=["source", "scenario", "site"], columns="age", values=["TPH", "QMD"]).to_csv(os.path.join(OUT, "a5_tph_qmd_wide.csv"))
print(A.groupby(["source", "scenario", "site"]).size().to_string())
def crossing(g, line_fn):
    g = g.sort_values("age"); d = g.TPH.to_numpy() - line_fn(g.QMD.to_numpy()); sg = np.sign(d)
    k = np.where(np.diff(sg) != 0)[0]
    return None if len(k) == 0 else int(g.age.to_numpy()[k[0] + 1])
