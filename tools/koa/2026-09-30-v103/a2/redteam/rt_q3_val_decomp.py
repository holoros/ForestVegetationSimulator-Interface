#!/usr/bin/env python3
"""rt_q3_val_decomp.py (red team 2026-09-30). Runs on a COPY of engine_v103 (scratch/eng). Decomposes the 23-plot validation QMD bias into
growth and mortality parts and tests the engine BAL and BAPH definitions. Variants (all ingrowth off, as validate()):
 V0 deployed (reproduction of a2/out/val_v103.csv)
 V1 BAL as the expf-weighted live-list percentile (records with expf decayed to the 1e-5 floor no longer count in the rank)
 V2 increments and HCB see ALL-species BAPH (non-koa BA of the start plot-year held constant), BAL = koa percentile x all-species BAPH (frame def l)
 V3 observed fates: engine mortality replaced by the observed fate of each tree (dead trees removed at mid interval), growth deployed
 V4 = V1 + V2
QMD bias V0 - V3 is the mortality (selection) contribution, V3 - obs the growth contribution. No coordinates read."""
import os, sys, inspect, textwrap, numpy as np, pandas as pd
os.environ["PYTHONDONTWRITEBYTECODE"] = "1"; sys.dont_write_bytecode = True
E = os.path.expanduser("~/jobs/rt_koa_v103_scratch/eng"); sys.path.insert(0, E); os.chdir(E)
import regen_m1 as RM
import koa_projector as KPJ, koa_longterm_validation as V, koa_params as P
RM.set_params(None)
assert KPJ.stand_mortality is RM._gated
from koa_equations import bal_percentile_fraction
src = textwrap.dedent(inspect.getsource(KPJ.project_psp))
rep = [("def project_psp(", "def project_rt("),
       ("for _ in range(int(n_years)):", "_id = np.arange(len(dbh))\n    for _yr in range(int(n_years)):"),
       ("dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]", "dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]; _id = _id[order]"),
       ("bal = stand_bal(baph=(ba.sum()), dbh=dbh)", "bal = _RT['balfn'](ba, dbh, expf)"),
       ("sdi = sdi_of(tph, qmd); htmax", "baph_g = baph + _RT['other']; sdi = sdi_of(tph, qmd); htmax"),
       ("hcb = predict_HCB(dbh, ht, bal, baph, byi)", "hcb = predict_HCB(dbh, ht, bal, baph_g, byi)"),
       ("L.dDBH(dbh, baph, bal, cr,", "L.dDBH(dbh, baph_g, bal, cr,"),
       ("dH = L.dHT(ht, baph, bal, cr,", "dH = L.dHT(ht, baph_g, bal, cr,"),
       ("_eo = expf", "ps = _RT['pshook'](ps, _yr, _id)\n        _eo = expf")]
for a, b in rep:
    assert src.count(a) >= 1, a
    src = src.replace(a, b, 1) if a != "dH = L.dHT(ht, baph, bal, cr," else src.replace(a, b, 1)
assert "len(dbh) > 300" in src
g = KPJ.__dict__.copy(); _RT = {}; g["_RT"] = _RT; exec(src, g); project_rt = g["project_rt"]
def bal_engine(ba, dbh, expf): return ba.sum() * bal_percentile_fraction(dbh) + 0.0 * _RT['other']
def bal_engine_all(ba, dbh, expf): return (ba.sum() + _RT['other']) * bal_percentile_fraction(dbh)
def wfrac(dbh, expf):
    live = expf > 1e-4; w = np.where(live, expf, 0.0); W = w.sum(); f = np.zeros(len(dbh))
    if W <= 0: return f
    o = np.argsort(dbh); sd = dbh[o]; sw = w[o]; cw = np.cumsum(sw)
    # weight of records with dbh >= d_i excluding self, over total minus self (minimum tie rule analogue)
    ge = W - np.concatenate([[0.0], cw[:-1]])
    for k, idx in enumerate(o): pass
    first = np.searchsorted(sd, sd, side="left"); ge_i = W - np.concatenate([[0.0], cw])[first]
    fr = np.clip((ge_i - sw) / np.maximum(W - sw, 1e-12), 0, 1); f[o] = fr; return f
def bal_w(ba, dbh, expf): return ba.sum() * wfrac(dbh, expf)
def bal_w_all(ba, dbh, expf): return (ba.sum() + _RT['other']) * wfrac(dbh, expf)
# instrument: record engine frac vs weighted frac for live trees (mean over live expf) each year
LOG = []
def bal_log(ba, dbh, expf):
    fe = bal_percentile_fraction(dbh); fw = wfrac(dbh, expf); live = expf > 1e-4
    w = expf[live]; LOG.append(( _RT['pid'], len(dbh), live.sum(), np.average(fe[live], weights=w), np.average(fw[live], weights=w)))
    return ba.sum() * fe
t, geo, surv = V.load(); BYI = V.byi_map(geo, surv); PLm = V.planted_map(geo, surv)
plt = pd.read_csv(os.path.expanduser("~/jobs/koa_v103_20260930/inputs/AK_PLT_v103.csv"), usecols=["Data","Install","Plot","Measure","BAPH","BA.AK"])
plt["pid"] = plt.Data.astype(str) + "|" + plt.Install.astype(str) + "|" + plt.Plot.astype(str)
val = pd.read_csv(os.path.expanduser("~/jobs/koa_v103_20260930/a2/out/val_v103.csv"))
rows = []
for pid in val.pid:
    g0all = t[t.pid == pid]; meas = sorted(g0all.Measure.dropna().unique()); t0 = meas[0]
    ny = int(val.loc[val.pid == pid, "ny"].iloc[0]); t1 = t0 + ny
    if t1 not in meas: t1 = [m for m in meas if m <= t0 + ny][-1]
    g0, g1 = g0all[g0all.Measure == t0], g0all[g0all.Measure == t1]
    live0 = g0[(g0.Status.astype(str).str.lower() == "live") & (pd.to_numeric(g0.DBH, errors="coerce") > 0)].copy()
    ids0 = live0.Tree.astype(str).values; live1 = set(g1[g1.Status.astype(str).str.lower() == "live"].Tree.astype(str))
    dead = np.array([i not in live1 for i in ids0])
    dbh = live0.DBH.astype(float).values; ht = pd.to_numeric(live0.HT, errors="coerce").values.astype(float); expf = live0.EXPF.astype(float).values
    baph0 = (dbh**2*V.TPH_FAC*expf).sum(); tph0 = expf.sum(); qmd0 = np.sqrt(baph0/(V.TPH_FAC*tph0)); B = float(BYI[pid]); pl = int(PLm.get(pid, 0))
    miss = ~np.isfinite(ht) | (ht <= 0)
    if miss.any(): ht[miss] = [float(V.predict_HT(dd, baph0, max(qmd0, 1.0), B, dbhmax=float(np.nanmax(dbh)))) for dd in dbh[miss]]
    trees = pd.DataFrame(dict(dbh=dbh, ht=ht, cr=0.7, expf=expf))
    pr = plt[(plt.pid == pid) & (plt.Measure == t0)]; other = float(max(pr.BAPH.iloc[0] - pr["BA.AK"].iloc[0], 0.0)) if len(pr) else 0.0
    surv_tr = g1[(g1.Status.astype(str).str.lower() == "live") & (g1.Tree.astype(str).isin(ids0))]
    e1 = surv_tr.EXPF.astype(float).values; d1 = surv_tr.DBH.astype(float).values
    oQ = np.sqrt((d1**2*e1).sum()/e1.sum()) if e1.sum() > 0 else np.nan
    # observed QMD of survivors using t0 expansion (removes the FIA micro to subplot reweighting)
    keep = ~dead; m1 = dict(zip(surv_tr.Tree.astype(str), d1)); d1b = np.array([m1.get(i, np.nan) for i in ids0[keep]]); e0k = expf[keep]
    oQ_t0w = np.sqrt(np.nansum(d1b**2*e0k)/e0k[np.isfinite(d1b)].sum()) if keep.any() else np.nan
    obs_surv_w = expf[keep].sum()/expf.sum()
    # static selection: QMD at t0 of observed survivors
    q0_surv = np.sqrt((dbh[keep]**2*expf[keep]).sum()/expf[keep].sum()) if keep.any() else np.nan
    res = dict(pid=pid, ny=ny, planted=pl, n0=len(dbh), tph0=tph0, qmd0=qmd0, other_ba0=other, koa_ba0=baph0, obs_surv_n=1-dead.mean(), obs_surv_w=obs_surv_w,
               obsQMD=oQ, obsQMD_t0w=oQ_t0w, qmd0_obs_survivors=q0_surv, n_expf_levels=len(np.unique(np.round(expf, 3))))
    half = max(1, ny // 2)
    def ps_none(ps, yr, idd): return ps
    def ps_obs(ps, yr, idd): return np.where(dead[idd] & (yr == half - 1), 0.0, 1.0)
    variants = {"V0": (bal_engine, 0.0, ps_none), "V1": (bal_w, 0.0, ps_none), "V2": (bal_engine_all, other, ps_none),
                "V3": (bal_engine, 0.0, ps_obs), "V4": (bal_w_all, other, ps_none), "V5": (bal_w_all, other, ps_obs), "LOG": (bal_log, 0.0, ps_none)}
    for k, (bf, oth, ph) in variants.items():
        _RT.update(balfn=bf, other=oth, pshook=ph, pid=pid)
        o = project_rt(trees, B, pl, "A", ny, ingrowth=False)
        if k == "LOG": continue
        res[f"{k}_QMD"] = o["QMD"]; res[f"{k}_surv"] = o["TPH"]/tph0; res[f"{k}_BAPH"] = o["BAPH"]
    rows.append(res); print(pid, {k: round(v, 3) for k, v in res.items() if isinstance(v, float)}, flush=True)
R = pd.DataFrame(rows); R.to_csv(os.path.expanduser("~/jobs/rt_koa_v103_scratch/rt_val_decomp.csv"), index=False)
L = pd.DataFrame(LOG, columns=["pid","nrec","nlive","frac_engine","frac_weighted"]); L.to_csv(os.path.expanduser("~/jobs/rt_koa_v103_scratch/rt_bal_log.csv"), index=False)
chk = R.merge(val[["pid","prQMD","pr_surv"]], on="pid"); print("repro max |V0-prQMD|", (chk.V0_QMD-chk.prQMD).abs().max(), "surv", (chk.V0_surv-chk.pr_surv).abs().max())
print("DONE")
