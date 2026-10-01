#!/usr/bin/env python3
"""plotlevel_validation.py (2026-09-30, koa v103 A2 close-out, red team must-change item 2).
Usage: python3 plotlevel_validation.py <engine_dir> <tag>
Rebuilds the validation units: FIA at PLOT level (four subplots pooled, tree key Plot|Tree, expansion EXPF/4 so the
plot carries TPA_UNADJ x 2.4711 per ha, i.e. x1 rather than the x4 per-subplot expansion), minimum MIN_FIA live koa
records at the first measurement; all other sources exactly as koa_longterm_validation.validate() (pid units, min 5
live records, 4 to 55 yr, PSP thinning truncation). Observed survival is expf weighted (start expf of survivors over
start expf of the cohort), the count figure is kept. Projection code mirrors validate() line for line and is checked
against validate() on the subplot units before use. Input tree, geo and survival tables are ALWAYS the v103 copy in
./engine so both engines see identical lists. Coordinates are never read (geo read with usecols, no LAT/LON)."""
import os, sys
sys.dont_write_bytecode = True; os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__))
ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]
DATA = os.path.join(HERE, "engine")               # v103 input tables
MIN_FIA = 20; MIN_OTHER = 5; MIN_Y, MAX_Y = 4, 55
DIST = "FIA|15-1-1-2628"
sys.path.insert(0, ENG); os.environ.setdefault("MPLCONFIGDIR", os.path.join(ENG, ".mplcache"))
_cwd = os.getcwd()
import regen_m1 as RM                              # chdirs to ENG, installs the gated M1 stand rate
import koa_longterm_validation as V
import koa_params as KP
V.stand_mortality = RM._gated; RM.set_params(None)
print(TAG, "engine", ENG, "MORT_CAL", KP.MORT_CAL, "BAL_PERCENTILE_WEIGHTED", getattr(KP, "BAL_PERCENTILE_WEIGHTED", "absent"), flush=True)

def load():
    t = pd.read_csv(os.path.join(DATA, "AK_TREE.csv"), low_memory=False)
    geo = pd.read_csv(os.path.join(DATA, "AK_PLT_GEO.csv"), usecols=["Data", "Install", "Plot", "Origin", "BYI"])
    surv = pd.read_csv(os.path.join(DATA, "AK_SURV.csv"), usecols=["Data", "Install", "Plot", "BYI", "Planted"], low_memory=False)
    for df in (t, geo, surv):
        for k in ("Data", "Install", "Plot"): df[k] = df[k].astype(str)
        df["pid"] = df["Data"] + "|" + df["Install"] + "|" + df["Plot"]
    return t, geo, surv

def islive(df): return df["Status"].astype(str).str.lower() == "live"

def run_unit(g0, g1, B, planted, ny, scale):
    """g0, g1: start and end records of the unit with column key. Mirrors validate()."""
    live0 = g0[islive(g0) & (pd.to_numeric(g0["DBH"], errors="coerce") > 0)].copy()
    ids0 = set(live0["key"]); live1ids = set(g1[islive(g1)]["key"])
    n0 = len(live0)
    obs_c = len(ids0 & live1ids) / len(ids0)
    dbh = pd.to_numeric(live0["DBH"], errors="coerce").values.astype(float)
    ht = pd.to_numeric(live0["HT"], errors="coerce").values.astype(float)
    expf = pd.to_numeric(live0["EXPF"], errors="coerce").fillna(0).values.astype(float) * scale
    baph0 = (dbh**2 * V.TPH_FAC * expf).sum(); tph0 = expf.sum()
    qmd0 = np.sqrt(baph0 / (V.TPH_FAC * tph0)) if tph0 > 0 else 1.0
    miss = ~np.isfinite(ht) | (ht <= 0)
    if miss.any():
        ht[miss] = [float(V.predict_HT(dd, baph0, max(qmd0, 1.0), B, dbhmax=float(np.nanmax(dbh)))) for dd in dbh[miss]]
    trees = pd.DataFrame(dict(dbh=dbh, ht=ht, cr=0.7, expf=expf))
    os.chdir(ENG)
    try:
        out = V.project_psp(trees, B, planted, "A", ny, mort_engine=KP.MORT_ENGINE, ingrowth=False)
    except Exception as e:
        print("projection failed", e, flush=True); return None
    finally:
        os.chdir(_cwd)
    alive = live0["key"].isin(live1ids).values
    obs_w = expf[alive].sum() / tph0
    sv = g1[islive(g1) & g1["key"].isin(ids0)]
    e1 = pd.to_numeric(sv["EXPF"], errors="coerce").fillna(0).values * scale
    d1 = pd.to_numeric(sv["DBH"], errors="coerce").values
    oB = (d1**2 * V.TPH_FAC * e1).sum(); oT = e1.sum()
    oQ = np.sqrt(oB / (V.TPH_FAC * oT)) if oT > 0 else np.nan
    return dict(n_records0=n0, ny=ny, obs_surv_w=obs_w, obs_surv_count=obs_c, pr_surv=out["TPH"] / tph0 if tph0 > 0 else np.nan,
                obsQMD=oQ, prQMD=out["QMD"], obsBAPH=oB, prBAPH=out["BAPH"], tph0=tph0, sdi0=V.sdi_of(tph0, qmd0), byi=B)

t, geo, surv = load()
BYI = V.byi_map(geo, surv); PL = V.planted_map(geo, surv)
cal = pd.read_csv(os.path.join(HERE, "..", "..", "mort", "v103", "H_mort_intervals_natural_mult.csv"), usecols=["pid"])
CAL = set(cal.pid)

def window(g, pid):
    meas = sorted(g["Measure"].dropna().unique())
    if len(meas) < 2: return None
    t0, t1 = meas[0], meas[-1]
    _rm = V._REMOVAL.get(pid.split("|")[1]) if pid.startswith("PSP|") else None
    if _rm:
        _pre = [m for m in meas if m < min(_rm)]
        if len(_pre) < 2: return None
        t1 = _pre[-1]
    return t0, t1

sub, units, fia_all = [], [], []
for pid, g in t.groupby("pid"):                          # pid units (as validate), FIA here = subplot units x4 (check only)
    w = window(g, pid)
    if w is None: continue
    t0, t1 = w; ny = int(t1 - t0)
    if ny < MIN_Y or ny > MAX_Y or pid not in BYI: continue
    g = g.assign(key=g["Tree"].astype(str)); g0, g1 = g[g.Measure == t0], g[g.Measure == t1]
    if (islive(g0) & (pd.to_numeric(g0["DBH"], errors="coerce") > 0)).sum() < MIN_OTHER: continue
    r = run_unit(g0, g1, float(BYI[pid]), int(PL.get(pid, 0)), ny, 1.0)
    if r is None: continue
    r.update(pid=pid, source=pid.split("|")[0], planted=int(PL.get(pid, 0))); sub.append(r)
    if not pid.startswith("FIA|"): units.append(r)
F = t[t.Data == "FIA"]
for inst, g in F.groupby("Install"):                     # FIA plot units, x1
    pid = "FIA|" + inst; w = window(g, pid)
    if w is None: continue
    t0, t1 = w; ny = int(t1 - t0)
    bs = [BYI[p] for p in g.pid.unique() if p in BYI]
    if ny < MIN_Y or ny > MAX_Y or not bs: continue
    g = g.assign(key=g["Plot"].astype(str) + "|" + g["Tree"].astype(str)); g0, g1 = g[g.Measure == t0], g[g.Measure == t1]
    n0 = int((islive(g0) & (pd.to_numeric(g0["DBH"], errors="coerce") > 0)).sum())
    if n0 < MIN_OTHER: continue
    pl = int(max(PL.get(p, 0) for p in g.pid.unique()))
    r = run_unit(g0, g1, float(np.mean(bs)), pl, ny, 0.25)
    if r is None: continue
    r.update(pid=pid, source="FIA", planted=pl, nsub0=int(g0.Plot.nunique()), pass_min=n0 >= MIN_FIA); fia_all.append(r)
    if n0 >= MIN_FIA: units.append(r)
S = pd.DataFrame(sub); U = pd.DataFrame(units); FA = pd.DataFrame(fia_all)
# check: mirror reproduces validate() on the same engine (own data of that engine)
os.chdir(ENG)
try: ref = V.validate()
finally: os.chdir(_cwd)
m = S.set_index("pid").reindex(ref.pid)
cols = [("obs_surv_count", "obs_surv"), ("pr_surv", "pr_surv"), ("obsQMD", "obsQMD"), ("prQMD", "prQMD"), ("obsBAPH", "obsBAPH"), ("prBAPH", "prBAPH")]
dmax = max(float(np.nanmax(np.abs(m[a].to_numpy(float) - ref[b].to_numpy(float)))) for a, b in cols)
dpr = max(float(np.nanmax(np.abs(m[a].to_numpy(float) - ref[b].to_numpy(float)))) for a, b in cols if a.startswith("pr"))
print(f"{TAG} CHECK mirror vs validate() on the engine's own tables: n {len(ref)} vs {m.notna().all(axis=1).sum()}; max|diff| all cols {dmax:.3e}, predicted cols {dpr:.3e}", flush=True)
for X in (U, FA):
    X["origin"] = np.where(X.planted == 1, "planted", "natural")
    X["in_sample"] = X.pid.isin(CAL)
    X["role"] = np.where(X.pid == DIST, "disturbance", X.origin)
C = ["pid", "source", "origin", "in_sample", "n_records0", "ny", "obs_surv_w", "obs_surv_count", "pr_surv", "obsQMD", "prQMD", "obsBAPH", "prBAPH", "role", "byi", "tph0", "sdi0"]
U[C].to_csv(os.path.join(HERE, f"val_{TAG}_plotlevel.csv"), index=False)
FA[C + ["nsub0", "pass_min"]].to_csv(os.path.join(HERE, f"fia_plotunits_{TAG}.csv"), index=False)
S.to_csv(os.path.join(HERE, f"val_{TAG}_subplot_mirror.csv"), index=False)
print(TAG, "units", len(U), U.role.value_counts().to_dict(), flush=True)
print(FA[["pid", "n_records0", "nsub0", "pass_min", "obs_surv_w", "obs_surv_count", "pr_surv", "obsQMD", "prQMD", "obsBAPH", "prBAPH"]].round(3).to_string(), flush=True)
print(TAG, "done", flush=True)
