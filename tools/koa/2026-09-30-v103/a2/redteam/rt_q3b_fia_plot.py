#!/usr/bin/env python3
"""rt_q3b_fia_plot.py (red team; FIA plots aggregated to plot level, 4 subplots, expf/4, same engine copy; 2026-09-30). Runs on a COPY of engine_v103 (scratch/eng). Decomposes the 23-plot validation QMD bias into
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

t, geo, surv = V.load(); BYI = V.byi_map(geo, surv)
rows=[]
for inst in ["15-1-1-2628","15-1-1-4895","15-1-1-2647"]:
    g=t[(t.Data=="FIA")&(t.Install==inst)]; m0,m1=sorted(g.Measure.unique())[:2]
    g0=g[g.Measure==m0]; g1=g[g.Measure==m1]
    l0=g0[(g0.Status.str.lower()=="live")&(g0.DBH>0)].copy(); l0["key"]=l0.Plot.astype(str)+"_"+l0.Tree.astype(str)
    l1=g1[(g1.Status.str.lower()=="live")&(g1.DBH>0)].copy(); l1["key"]=l1.Plot.astype(str)+"_"+l1.Tree.astype(str)
    dbh=l0.DBH.values.astype(float); ht=pd.to_numeric(l0.HT,errors="coerce").values.astype(float); expf=l0.EXPF.values.astype(float)/4.0
    pids=[f"FIA|{inst}|{p}" for p in l0.Plot.unique()]; B=float(np.mean([BYI[p] for p in pids if p in BYI]))
    baph0=(dbh**2*V.TPH_FAC*expf).sum(); tph0=expf.sum(); qmd0=np.sqrt(baph0/(V.TPH_FAC*tph0))
    miss=~np.isfinite(ht)|(ht<=0)
    if miss.any(): ht[miss]=[float(V.predict_HT(dd,baph0,max(qmd0,1.0),B,dbhmax=float(np.nanmax(dbh)))) for dd in dbh[miss]]
    trees=pd.DataFrame(dict(dbh=dbh,ht=ht,cr=0.7,expf=expf))
    sv=l1[l1.key.isin(set(l0.key))]; e1=sv.EXPF.values/4.0; d1=sv.DBH.values
    oQ=np.sqrt((d1**2*e1).sum()/e1.sum()); keep=l0.key.isin(set(l1.key)).values
    res=dict(inst=inst,n0=len(dbh),nsub=l0.Plot.nunique(),tph0=tph0,ba0=baph0,qmd0=qmd0,sdi0=V.sdi_of(tph0,qmd0),obs_surv_w=expf[keep].sum()/tph0,obs_ba1=(d1**2*V.TPH_FAC*e1).sum(),obsQMD=oQ,ny=int(m1-m0))
    for k,bf in (("E",bal_engine),("W",bal_w)):
        _RT.update(balfn=bf,other=0.0,pshook=lambda ps,yr,idd: ps,pid=inst)
        o=project_rt(trees,B,0,"A",int(m1-m0),ingrowth=False)
        res[k+"_QMD"]=o["QMD"]; res[k+"_surv"]=o["TPH"]/tph0; res[k+"_BA"]=o["BAPH"]
    rows.append(res); print({k:(round(v,3) if isinstance(v,float) else v) for k,v in res.items()},flush=True)
pd.DataFrame(rows).to_csv(os.path.expanduser("~/jobs/rt_koa_v103_scratch/rt_fia_plotlevel.csv"),index=False)
