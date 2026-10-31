#!/usr/bin/env python3
"""lt_core.py (v100 track B, 2026-09-17): shared helpers. Loads the COPIED engine in ./engine with the
deployed M1 gate (import regen_m1; RM.set_params(None)), reproduces lt/longterm_valid.py point by point
(run_points), and provides a tree-identity-tracked copy of koa_projector.project_psp built from its own
source (only an id array is carried through the annual sort; the stand path is untouched and gated)."""
import os, sys, inspect
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__))
E = os.path.join(HERE, "engine")
sys.path.insert(0, E); os.chdir(E)
import regen_m1 as RM
import koa_projector as PR, koa_longterm_validation as V, koa_params as KP, koa_equations as KE
RM.set_params(None)
TPH_FAC = V.TPH_FAC
MORT0 = float(KP.MORT_CAL[0]); CALD0 = tuple(KP.CAL_DDBH); CALH0 = tuple(KP.CAL_DHT)
HC_BINS = [0, 5, 10, 20, 35, 60]; HC_LAB = ["1-5", "6-10", "11-20", "21-35", "36-52"]

# ---- tracked copy of project_psp
_src = inspect.getsource(PR.project_psp).replace("def project_psp(", "def project_psp_tracked(", 1)
_reps = [("    cr = trees.cr.to_numpy(float); expf = trees.expf.to_numpy(float)\n",
          "    cr = trees.cr.to_numpy(float); expf = trees.expf.to_numpy(float)\n    _tid = np.arange(len(dbh)); _binned = False\n"),
         ("        dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]\n",
          "        dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]\n        _tid = _tid[order]\n"),
         ("        if len(dbh) > 300:\n", "        if len(dbh) > 300:\n            _binned = True\n"),
         ("    if return_traj:\n        tj = pd.DataFrame",
          "    out['tid'] = _tid; out['dbh_list'] = dbh; out['ht_list'] = ht; out['expf_list'] = expf; out['binned'] = _binned\n    if return_traj:\n        tj = pd.DataFrame")]
for a, b in _reps:
    assert _src.count(a) == 1, a
    _src = _src.replace(a, b)
exec(compile(_src, "project_psp_tracked", "exec"), PR.__dict__)
project_psp_tracked = PR.project_psp_tracked

T, GEO, SURV = V.load()
BYI = V.byi_map(GEO, SURV); PL = V.planted_map(GEO, SURV)


def setup(pid):
    """Exactly the initialization of lt/longterm_valid.py; returns None if the plot does not qualify."""
    g = T[T.pid == pid]
    meas = sorted(g["Measure"].dropna().unique())
    rm = V._REMOVAL.get(pid.split("|")[1]) if pid.startswith("PSP|") else None
    if rm:
        meas = [m for m in meas if m < min(rm)]
    if len(meas) < 3 or meas[-1] - meas[0] < float(os.environ.get("LT_MINSPAN", "4")) or pid not in BYI:
        return None
    t0 = meas[0]; g0 = g[g.Measure == t0]
    live0 = g0[(g0.Status.astype(str).str.lower() == "live") & (pd.to_numeric(g0.DBH, errors="coerce") > 0)].copy()
    if len(live0) < 5:
        return None
    B = float(BYI[pid]); planted = int(PL.get(pid, 0))
    ids0 = set(live0.Tree.astype(str))
    dbh = pd.to_numeric(live0.DBH, errors="coerce").values.astype(float)
    ht = pd.to_numeric(live0.HT, errors="coerce").values.astype(float)
    expf = pd.to_numeric(live0.EXPF, errors="coerce").fillna(0).values.astype(float)
    baph0 = (dbh ** 2 * TPH_FAC * expf).sum(); tph0 = expf.sum()
    qmd0 = np.sqrt(baph0 / (TPH_FAC * tph0))
    miss = ~np.isfinite(ht) | (ht <= 0)
    ht_meas = ~miss
    if miss.any():
        ht[miss] = [float(PR.predict_HT(dd, baph0, max(qmd0, 1.0), B, dbhmax=float(np.nanmax(dbh)))) for dd in dbh[miss]]
    trees = pd.DataFrame(dict(dbh=dbh, ht=ht, cr=0.7, expf=expf))
    return dict(pid=pid, g=g, meas=meas, t0=t0, live0=live0, ids0=ids0, tree_ids=live0.Tree.astype(str).values,
                B=B, planted=planted, dbh0=dbh.copy(), ht0=ht.copy(), ht_meas=ht_meas, expf0=expf,
                baph0=baph0, tph0=tph0, qmd0=qmd0, trees=trees)


def lt_pids():
    return [p for p in sorted(T.pid.unique()) if setup(p) is not None]


def apply(mort=None, cal_dd=None, cal_dh=None):
    RM.set_params(None)          # restores base values (cal_reset); overrides go AFTER it
    if mort is not None:
        KP.MORT_CAL_LIVE[0] = float(mort)
    if cal_dd is not None:
        KE.LineageA.CAL_DDBH = tuple(float(x) for x in cal_dd)
    if cal_dh is not None:
        KE.LineageA.CAL_DHT = tuple(float(x) for x in cal_dh)


def observed_at(S, tk):
    g = S["g"]
    gk = g[(g.Measure == tk) & (g.Status.astype(str).str.lower() == "live") & (g.Tree.astype(str).isin(S["ids0"]))]
    return gk.assign(_t=gk.Tree.astype(str)).drop_duplicates("_t")


def run_points(pid, mort=None, cal_dd=None, cal_dh=None, S=None):
    """One plot, points at every later measurement, exactly as lt/longterm_valid.py."""
    S = S or setup(pid)
    apply(mort, cal_dd, cal_dh)
    try:
        meas, t0, tph0, qmd0 = S["meas"], S["t0"], S["tph0"], S["qmd0"]
        hmax = int(round(meas[-1] - t0))
        out = PR.project_psp(S["trees"], S["B"], S["planted"], "A", hmax, ingrowth=False, return_traj=True)
    finally:
        RM.set_params(None)
    tj = out["traj"].reset_index(drop=True)
    fin = dict(TPH=out["TPH"], BAPH=out["BAPH"], QMD=out["QMD"])
    pts = []
    for tk in meas[1:]:
        h = int(round(tk - t0))
        r = tj.iloc[h] if h < len(tj) else fin
        gk = observed_at(S, tk)
        e1 = pd.to_numeric(gk.EXPF, errors="coerce").fillna(0).values
        d1 = pd.to_numeric(gk.DBH, errors="coerce").values
        oB = float((d1 ** 2 * TPH_FAC * e1).sum()); oT = float(e1.sum())
        pts.append(dict(pid=pid, source=pid.split("|")[0], planted=S["planted"], byi=S["B"], t0=t0, tk=tk, h=h, tph0=tph0,
                        sdi0=PR.sdi_of(tph0, qmd0), n_meas=len(meas), obs_surv=len(set(gk.Tree.astype(str))) / len(S["ids0"]),
                        pr_surv=float(r["TPH"]) / tph0, obsQMD=np.sqrt(oB / (TPH_FAC * oT)) if oT > 0 else np.nan,
                        prQMD=float(r["QMD"]), obsBAPH=oB, prBAPH=float(r["BAPH"])))
    return pd.DataFrame(pts)


def add_err(P_):
    P_ = P_.copy()
    P_["hc"] = pd.cut(P_.h, HC_BINS, labels=HC_LAB)
    P_["e_surv"] = P_.obs_surv - P_.pr_surv
    P_["e_qmd"] = P_.obsQMD - P_.prQMD
    P_["e_ba"] = P_.obsBAPH - P_.prBAPH
    return P_


def summ(d):
    o = dict(n_points=len(d), n_plots=d.pid.nunique())
    for v in ("surv", "qmd", "ba"):
        e = d["e_" + v].to_numpy(float)
        o[v + "_bias"] = float(np.mean(e)) if len(e) else np.nan
        o[v + "_rmse"] = float(np.sqrt(np.mean(e ** 2))) if len(e) else np.nan
    return o
