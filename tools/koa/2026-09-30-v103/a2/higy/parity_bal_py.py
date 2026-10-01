#!/usr/bin/env python3
"""Python side of the BAL parity harness, v103, 30 September 2026.

Imports the engine source in a2/higy/engine unmodified. Mode 'lists' (default):
  1. every hand, edge and random list through koa_equations.bal_percentile_fraction_weighted
     and stand_bal(baph = sum(ba), dbh, expf)                   -> out/parity_bal_py_lists.csv
  2. a 10 year koa_projector.project_psp run on each projection list, recording the
     BAL project_psp computes per tree per year. Recording is by wrapping stand_bal,
     predict_HCB and numpy.argsort in the koa_projector namespace (identity tracking
     only, nothing in the step is changed)                         -> out/parity_bal_py_proj.csv
Mode 'on_r_state': stand_bal evaluated on the per year states of the HiGy.R projection
(out/parity_bal_r_proj.csv)                                        -> out/parity_bal_py_on_rstate.csv
"""
import json, os, sys
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); ENG = os.path.join(HERE, "engine")
OUT = os.path.join(HERE, "out"); os.makedirs(OUT, exist_ok=True)
sys.path.insert(0, ENG); os.chdir(ENG)
import koa_params as P
import koa_equations as KE
import koa_projector as KPJ
TPH_FAC = 0.00007854
CFG = json.load(open(os.path.join(HERE, "koa_parity_bal_v103.json")))
mode = sys.argv[1] if len(sys.argv) > 1 else "lists"
assert P.BAL_PERCENTILE_WEIGHTED is True and P.PSP_BAL_MODE == "percentile"

def bal_py(dbh, expf):
    dbh = np.asarray(dbh, float); expf = np.asarray(expf, float)
    ba = dbh**2 * TPH_FAC * expf
    return KE.bal_percentile_fraction_weighted(dbh, expf), KE.stand_bal(baph=ba.sum(), dbh=dbh, expf=expf)

if mode == "lists":
    rows = []
    for grp in ("hand", "edge", "random"):
        for c in CFG[grp]:
            fr, bal = bal_py(c["dbh"], c["expf"])
            hv = c.get("hand")
            for i in range(len(c["dbh"])):
                rows.append(dict(group=grp, case=c["id"], i=i + 1, dbh=c["dbh"][i], expf=c["expf"][i],
                                 frac=fr[i], bal=bal[i], hand=(hv[i] if hv else np.nan)))
    pd.DataFrame(rows).to_csv(os.path.join(OUT, "parity_bal_py_lists.csv"), index=False, float_format="%.17g")

    # projection
    import numpy as _np
    class _NP:
        def __getattr__(self, k): return getattr(_np, k)
        def argsort(self, a, *args, **kw):
            o = _np.argsort(a, *args, **kw); _st["perm"].append(o); return o
    _st = {"perm": [], "calls": [], "ht": []}
    _sb, _hcb = KPJ.stand_bal, KPJ.predict_HCB
    def sb(baph, dbh=None, qmd=None, tph=None, expf=None):
        out = _sb(baph=baph, dbh=dbh, qmd=qmd, tph=tph, expf=expf)
        _st["calls"].append((float(baph), np.array(dbh), np.array(expf), np.array(out))); return out
    def hcb(dbh, ht, bal, baph, byi):
        _st["ht"].append(np.array(ht)); return _hcb(dbh, ht, bal, baph, byi)
    KPJ.np, KPJ.stand_bal, KPJ.predict_HCB = _NP(), sb, hcb
    rows = []; summ = []
    for pid, L in CFG["projection"].items():
        _st["perm"].clear(); _st["calls"].clear(); _st["ht"].clear()
        trees = pd.DataFrame(dict(dbh=L["dbh"], ht=L["ht"], cr=L["cr"], expf=L["expf"]))
        o = KPJ.project_psp(trees, L["byi"], L["planted"], "A", L["n_years"], mort_engine=P.MORT_ENGINE,
                            ingrowth=False, return_traj=True)
        ids = np.arange(1, len(L["dbh"]) + 1)
        assert len(_st["perm"]) == len(_st["calls"]) == L["n_years"]
        for yr in range(L["n_years"]):
            ids = ids[_st["perm"][yr]]
            baph, d, e, b = _st["calls"][yr]; h = _st["ht"][yr]
            for j in range(len(d)):
                rows.append(dict(list=pid, year=yr + 1, tree=int(ids[j]), dbh=d[j], ht=h[j], expf=e[j],
                                 baph=baph, bal=b[j]))
        tj = o["traj"]; tj.insert(0, "list", pid); tj.insert(1, "year", range(1, len(tj) + 1)); summ.append(tj)
    pd.DataFrame(rows).to_csv(os.path.join(OUT, "parity_bal_py_proj.csv"), index=False, float_format="%.17g")
    pd.concat(summ).to_csv(os.path.join(OUT, "parity_bal_py_proj_stand.csv"), index=False, float_format="%.17g")
    print("python lists and projection written")

elif mode == "on_r_state":
    r = pd.read_csv(os.path.join(OUT, "parity_bal_r_proj.csv"))
    r = r[r.phase == 1]
    rows = []
    for (pid, yr), g in r.groupby(["list", "year"], sort=True):
        fr, bal = bal_py(g.dbh.values, g.expf.values)
        # BA of the list as HiGy.R holds it (ba column) so only the rule is compared
        bal_rba = g.ba.sum() * fr
        for j, (_, rr) in enumerate(g.iterrows()):
            rows.append(dict(list=pid, year=yr, tree=int(rr.tree), frac=fr[j], bal=bal_rba[j]))
    pd.DataFrame(rows).to_csv(os.path.join(OUT, "parity_bal_py_on_rstate.csv"), index=False, float_format="%.17g")
    print("python on R state written")
