#!/usr/bin/env python3
"""calib_mort.py ENGINE_DIR JOB_DIR (2026-09-16, v98 round)
Natural mortality level calibration in engine space. Each mortality-bearing or not plot interval of the
Stage 1/2 table (removal intervals excluded) is initialized from its tree list at the interval start and
projected over the interval by the deployed calibrated engine (engine_calib, M1 gate, Stage 3 by Eq. 5a,
no ingrowth), exactly as koa_longterm_validation does, with a natural mortality adjustment in one of two
pre-registered forms:
  mult  : deployed annual stand rate times k (natural stands only), clip 0.95
  floor : natural background floor BASE_NAT replaced by b (then gated by M1 as deployed)
The level is solved so that sum over intervals of TPH0 x (1 - projected cohort survival) equals the observed
sum. Intervals come from plot-cluster and installation-cluster bootstraps (2,000) on precomputed response
curves. Leave-one-installation-out k is also reported. Planted intervals are scored as a diagnostic only.
Outputs JOB_DIR/out/H_mort_*.csv
"""
import os, sys, time, json
import numpy as np, pandas as pd
E, J = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
WHICH = sys.argv[3] if len(sys.argv) > 3 else "natural"
sys.path.insert(0, E); os.chdir(E)
os.environ.setdefault("MPLCONFIGDIR", os.path.join(E, ".mpl"))
import regen_m1 as RM
import koa_params as P, koa_mortality_garcia as MG, koa_projector as PR, run_candidates as RC
import koa_longterm_validation as V
from multiprocessing import Pool

MULT = {"k": 1.0}
def gated2(engine, N0, h_prev, h_now, planted=0, sdi=None, rd=None):
    m = RM._gated(engine, N0, h_prev, h_now, planted=planted, sdi=sdi, rd=rd)
    if int(planted) == (1 if WHICH == "planted" else 0):
        m = float(np.clip(m * MULT["k"], 0.0, 0.95))
    return m
for mod in (MG, PR, RC, V):
    mod.stand_mortality = gated2

TPH_FAC = V.TPH_FAC
IV = pd.read_csv(os.path.join(J, os.environ.get("KOA_OUTDIR", "out"), "plot_intervals_origin.csv"))
IV = IV[(IV.planted == (1 if WHICH == "planted" else 0)) & (~IV.removal.astype(bool))].reset_index(drop=True)
t, geo, surv = V.load()
BYI = V.byi_map(geo, surv)
CASES = []
for i, r in IV.iterrows():
    pid = f"{r.Data}|{r.Install}|{r.Plot}"
    g = t[t.pid == pid]
    g0, g1 = g[g.Measure == r.m_from], g[g.Measure == r.m_to]
    live0 = g0[(g0.Status.astype(str).str.lower() == "live") & (pd.to_numeric(g0.DBH, errors="coerce") > 0)]
    if len(live0) < 1 or pid not in BYI:
        print("skip", pid, r.m_from, len(live0), pid in BYI); continue
    ids0 = set(live0.Tree.astype(str))
    live1 = set(g1[g1.Status.astype(str).str.lower() == "live"].Tree.astype(str))
    dbh = pd.to_numeric(live0.DBH, errors="coerce").values.astype(float)
    ht = pd.to_numeric(live0.HT, errors="coerce").values.astype(float)
    expf = pd.to_numeric(live0.EXPF, errors="coerce").fillna(0).values.astype(float)
    B = float(BYI[pid]); baph0 = (dbh**2 * TPH_FAC * expf).sum(); tph0 = expf.sum()
    qmd0 = np.sqrt(baph0 / (TPH_FAC * tph0))
    miss = ~np.isfinite(ht) | (ht <= 0)
    if miss.any():
        ht[miss] = [float(PR.predict_HT(dd, baph0, max(qmd0, 1.0), B, dbhmax=float(np.nanmax(dbh)))) for dd in dbh[miss]]
    CASES.append(dict(i=i, pid=pid, Data=r.Data, Install=str(r.Install), plot=pid, m_from=r.m_from, m_to=r.m_to,
                      yip=float(r.yip), ny=max(1, int(round(r.yip))), byi=B, tph0=tph0, sdi0=PR.sdi_of(tph0, qmd0),
                      qmd0=qmd0, n0=len(ids0), obs_surv=len(ids0 & live1) / len(ids0),
                      tab_n_alive=int(r.n_alive), tab_n_died=int(r.n_died),
                      trees=pd.DataFrame(dict(dbh=dbh, ht=ht, cr=0.7, expf=expf))))
print(WHICH, "intervals", len(CASES), "of", len(IV))

def proj(args):
    form, val, c = args
    MULT["k"] = 1.0; P.BASE_NAT = 0.003; P.BASE_PLT = 0.006
    if form == "mult": MULT["k"] = val
    elif form == "floor":
        if WHICH == "planted": P.BASE_PLT = val
        else: P.BASE_NAT = val
    RM.set_params(None)
    pl = 1 if WHICH == "planted" else 0
    try:
        out = PR.project_psp(c["trees"], c["byi"], pl, "A", c["ny"], ingrowth=False)
        return out["TPH"] / c["tph0"]
    except Exception as e:
        return np.nan

GRID = {"mult": np.unique(np.r_[1.0, np.geomspace(0.25, 80, 44)]),
        "floor": np.unique(np.r_[0.003, np.geomspace(0.001, 0.40, 44)])}
if __name__ == "__main__":
    t0 = time.time()
    light = [{k: v for k, v in c.items() if k != "trees"} for c in CASES]
    rows = []
    with Pool(6) as pool:   # v105d: 6 workers (core limit), results unchanged
        for form, gr in GRID.items():
            jobs = [(form, float(v), c) for v in gr for c in CASES]
            res = pool.map(proj, jobs, chunksize=4)
            n = len(CASES)
            for a, v in enumerate(gr):
                for b, c in enumerate(light):
                    rows.append(dict(form=form, val=float(v), **c, pr_surv=res[a * n + b]))
            print(form, "done", round(time.time() - t0), "s", flush=True)
    R = pd.DataFrame(rows)
    R.to_csv(os.path.join(J, os.environ.get("KOA_OUTDIR", "out"), f"H_mort_curves_{WHICH}.csv"), index=False)
    print("CURVES DONE", WHICH, round(time.time() - t0))
