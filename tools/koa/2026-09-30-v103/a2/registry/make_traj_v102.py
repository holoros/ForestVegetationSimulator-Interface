#!/usr/bin/env python3
"""make_traj.py <engine_dir>: turn the M1 driver outputs into the trajectory and validation files
# track 3 copy (2026-09-18): optional second argument OUTDIR so the derived files are written beside track 3 rather than into the engine copy.
the red team R stages read (TCOL and VCOL maps of config.R). Output only; no projection is run.

Writes, inside <engine_dir>/out_m1/:
  trajectories.csv   scenario, site, age, rep, QMD, HT, BAPH, TPH, VOL, MORT_VOL, SDI
                     rep 0 = point projection (ages 1 to 100); rep 1..n = Monte Carlo replicates
  validation_23.csv  PLOT, obs_surv, pred_surv, obs_ba, pred_ba, obs_qmd, pred_qmd, origin, interval
"""
import os, sys
import pandas as pd

d = os.path.join(sys.argv[1], "out_m1"); OUTD = sys.argv[2] if len(sys.argv) > 2 else d; os.makedirs(OUTD, exist_ok=True)
SITE = {100: "Low", 264: "Medium", 450: "High"}
SCN = {"nat": "Even-aged natural", "plt": "Even-aged planted"}
fr = []

t = pd.read_csv(os.path.join(d, "traj_M1.csv"))
t = t[t.year <= 100]
fr.append(pd.DataFrame(dict(scenario=t.origin.map(SCN), site=t.byi.map(SITE), age=t.year, rep=0,
                            QMD=t.QMD, HT=t.HT, BAPH=t.BAPH, TPH=t.TPH, VOL=t.VOL,
                            MORT_VOL=t.MORT_VOL, SDI=t.SDI)))
r = os.path.join(d, "reps_evenaged_M1.csv")
if os.path.exists(r):
    r = pd.read_csv(r)
    fr.append(pd.DataFrame(dict(scenario=r.scen.map(SCN), site=r.byi.map(SITE), age=r.year, rep=r.rep + 1,
                                QMD=r.QMD, HT=r.HT, BAPH=r.BAPH, TPH=r.TPH, VOL=r.VOL,
                                MORT_VOL=r.MORT_VOL, SDI=float("nan"))))
u = pd.read_csv(os.path.join(d, "uneven_aged_traj_M1.csv"))
u = u[u.age <= 100]
fr.append(pd.DataFrame(dict(scenario="Uneven-aged natural", site=u.BYI.map(SITE), age=u.age, rep=0,
                            QMD=u.QMD, HT=u.HT, BAPH=u.BAPH, TPH=u.TPH, VOL=u.Vol,
                            MORT_VOL=u.MORT_VOL, SDI=u.SDI)))
ur = os.path.join(d, "uneven_aged_reps_M1.csv")
if os.path.exists(ur):
    ur = pd.read_csv(ur)
    ur = ur[ur.year <= 100]
    fr.append(pd.DataFrame(dict(scenario="Uneven-aged natural", site=ur.byi.map(SITE), age=ur.year,
                                rep=ur.rep + 1, QMD=ur.QMD, HT=float("nan"), BAPH=ur.BAPH, TPH=ur.TPH,
                                VOL=ur.VOL, MORT_VOL=float("nan"), SDI=float("nan"))))
T = pd.concat(fr, ignore_index=True)
assert T.site.notna().all() and T.scenario.notna().all()
T.to_csv(os.path.join(OUTD, "trajectories.csv"), index=False)
print("trajectories.csv", T.shape, T.groupby(["scenario", "rep"]).size().groupby(level=0).size().to_dict())

v = os.path.join(d, "validation_M1.csv")
if os.path.exists(v):
    v = pd.read_csv(v)
    V = pd.DataFrame(dict(PLOT=v.pid, obs_surv=v.obs_surv, pred_surv=v.pr_surv, obs_ba=v.obsBAPH,
                          pred_ba=v.prBAPH, obs_qmd=v.obsQMD, pred_qmd=v.prQMD,
                          origin=v.planted.map({0: "natural", 1: "planted"}), interval=v.ny))
    V.to_csv(os.path.join(OUTD, "validation_23.csv"), index=False)
    print("validation_23.csv", V.shape)
