#!/usr/bin/env python3
"""rt_q4_traj.py (red team 2026-09-30). On a COPY of engine_v103: the six even-aged point trajectories (run_engine.py set-up, RC.project M0
under the M1 gate) with (E) the engine percentile BAL of record and (W) the expf-weighted live percentile; logs the stand mean BAL fraction.
Also projects FIA plot 15-1-1-2628 aggregated to plot level (4 subplots, expf/4) against its subplots. No coordinates read."""
import os, sys, inspect, textwrap, numpy as np, pandas as pd
sys.dont_write_bytecode = True
E = os.path.expanduser("~/jobs/rt_koa_v103_scratch/eng"); sys.path.insert(0, E); os.chdir(E)
import regen_m1 as RM, run_candidates as RC, koa_params as P
from koa_equations import bal_percentile_fraction
sys.path.insert(0, os.path.expanduser("~/jobs/rt_koa_v103_scratch"))
src = textwrap.dedent(inspect.getsource(RC.project))
a = "stand_bal(baph=ba.sum(), dbh=dbh)"; assert a in src
src = src.replace("def project(", "def project_rt(").replace(a, "_RT['balfn'](ba, dbh, expf)")
g = RC.__dict__.copy(); _RT = {}; g["_RT"] = _RT; exec(src, g); project_rt = g["project_rt"]
def wfrac(dbh, expf):
    w = np.where(expf > 1e-4, expf, 0.0); W = w.sum(); f = np.zeros(len(dbh))
    if W <= 0: return f
    o = np.argsort(dbh); sd = dbh[o]; sw = w[o]; cw = np.concatenate([[0.0], np.cumsum(sw)])
    first = np.searchsorted(sd, sd, side="left"); ge = W - cw[first]
    f[o] = np.clip((ge - sw) / np.maximum(W - sw, 1e-12), 0, 1); return f
LOG = []
def mk(kind):
    def fn(ba, dbh, expf):
        fe = bal_percentile_fraction(dbh); fw = wfrac(dbh, expf); w = np.where(expf > 1e-4, expf, 0.0)
        LOG.append((_RT["tag"], kind, _RT.setdefault("yr", 0), float(np.average(fe, weights=w)) if w.sum() > 0 else np.nan, float(np.average(fw, weights=w)) if w.sum() > 0 else np.nan, len(dbh), int((expf > 1e-4).sum())))
        _RT["yr"] += 1
        return ba.sum() * (fe if kind == "E" else fw)
    return fn
rows = []
for tag, planted, byi, site in RC.SCEN:
    for kind in ("E", "W"):
        RM.set_params(None); _RT.update(balfn=mk(kind), tag=f"{planted}_{byi}", yr=0)
        d = project_rt(RC.wlist(planted, byi), byi, bool(planted), 300, "M0").copy()
        d.insert(0, "bal", kind); d.insert(0, "site", site); d.insert(0, "byi", byi); d.insert(0, "planted", planted); rows.append(d)
    print(tag, "done", flush=True)
TR = pd.concat(rows, ignore_index=True); TR.to_csv("../rt_traj_EW.csv", index=False)
pd.DataFrame(LOG, columns=["tag","bal","yr","frac_engine","frac_weighted","nrec","nlive"]).to_csv("../rt_traj_ballog.csv", index=False)
ref = pd.read_csv(os.path.expanduser("~/jobs/koa_v103_20260930/a2/out/traj_v103.csv"))
e = TR[TR.bal == "E"].drop(columns="bal").reset_index(drop=True)
cols = [c for c in ["QMD","BAPH","TPH","VOL"] if c in ref.columns and c in e.columns]
m = e.merge(ref, on=["planted","byi","year"], suffixes=("", "_ref"))
print("repro max abs diff", {c: float((m[c]-m[c+"_ref"]).abs().max()) for c in cols})
print("DONE")
