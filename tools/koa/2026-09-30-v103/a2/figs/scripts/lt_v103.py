#!/usr/bin/env python3
"""lt_v103.py (a2/figs, 2026-09-30): copy of koa_v102 track3/lt/longterm_valid.py, run on engine_v103 (read only, PYTHONDONTWRITEBYTECODE). Added obs_surv_w (expf weighted observed survival, red team finding 4).
Original docstring: longterm_valid.py ENGINE_DIR LABEL OUTDIR (2026-09-16, v98): trajectory validation on every remeasured koa plot with at
least three usable measurements spanning at least LT_MINSPAN (default 4) years. Each plot is initialized from its first measurement and projected
by the deployed engine (M1 gate, Stage 3 by Eq. 5a, calibrated increments, engine's own mortality level, no ingrowth), and the
surviving cohort is compared at EVERY later measurement, not only the last. PSP plots are truncated before their first
thinning-removal interval, as in koa_longterm_validation.validate. Writes LT_<LABEL>_points.csv and LT_<LABEL>_traj.csv."""
import os, sys
import numpy as np, pandas as pd
E, LAB, OUTD = os.path.abspath(sys.argv[1]), sys.argv[2], os.path.abspath(sys.argv[3])
sys.path.insert(0, E); os.chdir(E); os.makedirs(OUTD, exist_ok=True)
import regen_m1 as RM
import koa_projector as PR, koa_longterm_validation as V
RM.set_params(None)
TPH_FAC = V.TPH_FAC
t, geo, surv = V.load()
BYI = V.byi_map(geo, surv); PL = V.planted_map(geo, surv)
pts, trs = [], []
for pid, g in t.groupby("pid"):
    meas = sorted(g["Measure"].dropna().unique())
    rm = V._REMOVAL.get(pid.split("|")[1]) if pid.startswith("PSP|") else None
    if rm:
        meas = [m for m in meas if m < min(rm)]
    if len(meas) < 3 or meas[-1] - meas[0] < float(os.environ.get("LT_MINSPAN", "4")) or pid not in BYI:
        continue
    t0 = meas[0]; g0 = g[g.Measure == t0]
    live0 = g0[(g0.Status.astype(str).str.lower() == "live") & (pd.to_numeric(g0.DBH, errors="coerce") > 0)].copy()
    if len(live0) < 5:
        continue
    B = float(BYI[pid]); planted = int(PL.get(pid, 0))
    ids0 = set(live0.Tree.astype(str))
    dbh = pd.to_numeric(live0.DBH, errors="coerce").values.astype(float)
    ht = pd.to_numeric(live0.HT, errors="coerce").values.astype(float)
    expf = pd.to_numeric(live0.EXPF, errors="coerce").fillna(0).values.astype(float)
    baph0 = (dbh ** 2 * TPH_FAC * expf).sum(); tph0 = expf.sum()
    qmd0 = np.sqrt(baph0 / (TPH_FAC * tph0))
    miss = ~np.isfinite(ht) | (ht <= 0)
    if miss.any():
        ht[miss] = [float(PR.predict_HT(dd, baph0, max(qmd0, 1.0), B, dbhmax=float(np.nanmax(dbh)))) for dd in dbh[miss]]
    trees = pd.DataFrame(dict(dbh=dbh, ht=ht, cr=0.7, expf=expf))
    hmax = int(round(meas[-1] - t0))
    try:
        out = PR.project_psp(trees, B, planted, "A", hmax, ingrowth=False, return_traj=True)
    except Exception as e:
        print("fail", pid, e); continue
    tj = out["traj"].reset_index(drop=True)
    fin = dict(TPH=out["TPH"], BAPH=out["BAPH"], QMD=out["QMD"])
    for h in range(len(tj) + 1):
        r = tj.iloc[h] if h < len(tj) else fin
        trs.append(dict(pid=pid, planted=planted, h=h, TPH=float(r["TPH"]), BAPH=float(r["BAPH"]), QMD=float(r["QMD"])))
    for tk in meas[1:]:
        h = int(round(tk - t0))
        r = tj.iloc[h] if h < len(tj) else fin
        gk = g[(g.Measure == tk) & (g.Status.astype(str).str.lower() == "live") & (g.Tree.astype(str).isin(ids0))]
        gk = gk.assign(_t=gk.Tree.astype(str)).drop_duplicates("_t")   # duplicated tree records (KeyDupFlag), e.g. Kulani 23 in 1994
        e1 = pd.to_numeric(gk.EXPF, errors="coerce").fillna(0).values
        d1 = pd.to_numeric(gk.DBH, errors="coerce").values
        oB = float((d1 ** 2 * TPH_FAC * e1).sum()); oT = float(e1.sum())
        pts.append(dict(pid=pid, source=pid.split("|")[0], planted=planted, byi=B, t0=t0, tk=tk, h=h, tph0=tph0, sdi0=PR.sdi_of(tph0, qmd0),
                        n_meas=len(meas), obs_surv=len(set(gk.Tree.astype(str))) / len(ids0), obs_surv_w=float(live0[live0.Tree.astype(str).isin(set(gk.Tree.astype(str)))].EXPF.pipe(pd.to_numeric, errors='coerce').fillna(0).sum()) / tph0, pr_surv=float(r["TPH"]) / tph0,
                        obsQMD=np.sqrt(oB / (TPH_FAC * oT)) if oT > 0 else np.nan, prQMD=float(r["QMD"]), obsBAPH=oB, prBAPH=float(r["BAPH"])))
P_ = pd.DataFrame(pts); T_ = pd.DataFrame(trs)
P_.to_csv(os.path.join(OUTD, f"LT_{LAB}_points.csv"), index=False); T_.to_csv(os.path.join(OUTD, f"LT_{LAB}_traj.csv"), index=False)
P_["hc"] = pd.cut(P_.h, [0, 5, 10, 20, 35, 60], labels=["1-5", "6-10", "11-20", "21-35", "36-52"])
S = []
for (o, hc), d in P_.groupby(["planted", "hc"], observed=True):
    S.append(dict(label=LAB, origin="planted" if o else "natural", horizon=hc, n_points=len(d), n_plots=d.pid.nunique(),
                  surv_bias=float((d.obs_surv - d.pr_surv).mean()), surv_rmse=float(np.sqrt(((d.obs_surv - d.pr_surv) ** 2).mean())),
                  qmd_bias=float((d.obsQMD - d.prQMD).mean()), qmd_rmse=float(np.sqrt(((d.obsQMD - d.prQMD) ** 2).mean())),
                  ba_bias=float((d.obsBAPH - d.prBAPH).mean()), ba_rmse=float(np.sqrt(((d.obsBAPH - d.prBAPH) ** 2).mean()))))
S = pd.DataFrame(S); S.to_csv(os.path.join(OUTD, f"LT_{LAB}_summary.csv"), index=False)
print(LAB, "plots", P_.pid.nunique(), "points", len(P_), "natural plots", P_[P_.planted == 0].pid.nunique()); print(S.round(3).to_string())
