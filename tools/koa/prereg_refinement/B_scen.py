#!/usr/bin/env python3
"""scen.py ENGINE_DIR OUTDIR  --  PREREG-KOA-01 variant B, density and thinning scenarios.

Byte-for-byte the scenario construction of track3/lt/scenarios.py (v98), with one
change: the mortality arm is passed explicitly to project_thin, so the same grid
runs under the deployed anchored beta (C5) and the fitted beta (C3). Nothing in
the engine directory is edited.
"""
import os, sys, inspect
import numpy as np, pandas as pd
E, OUTD = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
sys.path.insert(0, E); os.chdir(E); os.makedirs(OUTD, exist_ok=True)
import regen_m1 as RM
import run_candidates as RC, koa_params as P
import koa_mortality_garcia as MG
from koa_projector import predict_HT
RM.set_params(None)
TPH_FAC = 0.00007854
OBS = RC.OBS
ARMS = [("C5_anchored", "garcia_qmd_anchored"), ("C3_fitted", "garcia_qmd")]


def _thin_below(dbh, ht, cr, expf, target, byi):
    o = np.argsort(dbh); dbh, ht, cr, expf = dbh[o], ht[o], cr[o], expf[o]
    tph = expf.sum(); cut = max(tph - target, 0.0); rem = np.zeros_like(expf)
    for i in range(len(expf)):
        if cut <= 0: break
        take = min(expf[i], cut); rem[i] = take; cut -= take
    keep = expf - rem
    baph = float((dbh ** 2 * TPH_FAC * expf).sum()); qmd = np.sqrt(baph / (TPH_FAC * tph))
    rba = float((dbh ** 2 * TPH_FAC * rem).sum()); rt = float(rem.sum())
    rq = np.sqrt(rba / (TPH_FAC * rt)) if rt > 0 else 0.0
    rh = float(predict_HT(max(rq, 1.0), max(baph, 0.1), max(qmd, 1.0), byi, dbhmax=float(dbh.max()))) if rt > 0 else 0.0
    m = keep > 1e-6
    return dbh[m], ht[m], cr[m], keep[m], dict(rem_tph=rt, rem_ba=rba, rem_qmd=rq, rem_vol=rba * rh * 0.40)

src = inspect.getsource(RC.project)
src = src.replace("def project(trees, byi, planted, n_years, cand, alloc_mode=\"tree_eq\", dbh_max=None,",
                  "def project_thin(trees, byi, planted, n_years, cand, THIN=None, REMOVED=None, alloc_mode=\"tree_eq\", dbh_max=None,", 1)
src = src.replace("        expf = expf_new\n", "        expf = expf_new\n        if DOM is not None:\n            DOM.append(_d100(dbh, expf))\n", 1)
src = src.replace("THIN=None, REMOVED=None,", "THIN=None, REMOVED=None, DOM=None,", 1)
hook = ("        if THIN and (yr + 1) in THIN:\n"
        "            dbh, ht, cr, expf, _rem = _thin_below(dbh, ht, cr, expf, THIN[yr + 1], byi)\n"
        "            REMOVED.append(dict(year=yr + 1, **_rem))\n")
anchor = "    for yr in range(int(n_years)):\n"
assert src.count(anchor) == 1
src = src.replace(anchor, anchor + hook)
def _d100(dbh, expf, n=100.0):
    o = np.argsort(-dbh); d, e = dbh[o], expf[o]
    c = np.cumsum(e); w = np.clip(n - (c - e), 0, e)
    return float(np.sqrt(np.sum(w * d ** 2) / max(w.sum(), 1e-9)))
ns = RC.__dict__; ns["_thin_below"] = _thin_below; ns["_d100"] = _d100
exec(src, ns)
project_thin = ns["project_thin"]
base = RC.project(RC.wlist(1, 264), 264, True, 100, "M0"); hk = project_thin(RC.wlist(1, 264), 264, True, 100, "M0", THIN=None, REMOVED=[])
assert np.allclose(base[["QMD", "TPH", "BAPH", "VOL"]].to_numpy(), hk[["QMD", "TPH", "BAPH", "VOL"]].to_numpy(), rtol=0, atol=1e-10), "hook parity failed"
print("hook parity ok")
for lab, arm in ARMS:
    print("  arm %-12s engine=%-22s beta=%.17g" % (lab, arm, MG.engine_beta(arm)))


def dens_list(planted, byi, n):
    w = RC.wlist(planted, byi); w = w.copy(); w["expf"] = w.expf * n / w.expf.sum()
    return RC._finish(w.dbh.to_numpy(), w.expf.to_numpy(), byi)

BYI = 264
SC = []
for planted, dens in ((0, (250, 500, 1000, 2000)), (1, (300, 600, 1200, 2400))):
    for n in dens:
        SC.append(dict(group="density", origin="planted" if planted else "natural", planted=planted, label=f"{n} stems", n0=n, thin=None))
SC += [dict(group="thinning", origin="planted", planted=1, label="Unthinned", n0=1200, thin=None),
       dict(group="thinning", origin="planted", planted=1, label="Thinned to 500 at age 8", n0=1200, thin={8: 500}),
       dict(group="thinning", origin="planted", planted=1, label="Thinned to 500 at 8 and 250 at 20", n0=1200, thin={8: 500, 20: 250}),
       dict(group="thinning", origin="natural", planted=0, label="Unthinned", n0=500, thin=None),
       dict(group="thinning", origin="natural", planted=0, label="Thinned to 250 at age 15", n0=500, thin={15: 250})]
rows, rems, summ = [], [], []
for lab, arm in ARMS:
    beta = MG.engine_beta(arm)
    for s in SC:
        RM.set_params(None)
        REM = []; DOM = []
        d = project_thin(dens_list(s["planted"], BYI, s["n0"]), BYI, bool(s["planted"]), 100, "M0",
                         THIN=s["thin"], REMOVED=REM, DOM=DOM, engine=arm)
        d["D100"] = DOM[:len(d)]
        rv = pd.DataFrame(REM) if REM else pd.DataFrame(columns=["year", "rem_tph", "rem_ba", "rem_qmd", "rem_vol"])
        d["cum_removed_vol"] = [float(rv[rv.year <= y].rem_vol.sum()) for y in d.year]
        d["total_yield"] = d.VOL + d.cum_removed_vol
        d["cum_mort_vol"] = d.MORT_VOL.cumsum()
        d["mai_net"] = d.VOL / d.year; d["mai_total"] = d.total_yield / d.year
        for k in ("group", "origin", "label", "n0"):
            d[k] = s[k]
        d["arm"] = lab; d["engine"] = arm; d["beta"] = beta
        rows.append(d)
        for _, r in rv.iterrows():
            rems.append(dict(arm=lab, group=s["group"], origin=s["origin"], label=s["label"], **r.to_dict()))
        st = d[(d.year > 10) & (np.r_[False, np.diff(d.TPH) < 0])]
        sl = float(np.polyfit(np.log(st.QMD), np.log(st.TPH), 1)[0]) if len(st) >= 5 else np.nan
        x = d.set_index("year")
        def _cul(stock):
            v = stock.to_numpy(); age = d.year.to_numpy(); mai = v / age; pai = np.r_[np.nan, np.diff(v)]
            up = np.where(pai > mai)[0]; up = up[0] if len(up) else 0
            return int(age[up + int(np.argmax(mai[up:]))])
        rec = dict(arm=lab, engine=arm, beta=beta, group=s["group"], origin=s["origin"], label=s["label"], n0=s["n0"],
                   reineke_slope=sl, max_sdi=float(d.SDI.max()), max_ba=float(d.BAPH.max()),
                   age_max_ba=int(d.loc[d.BAPH.idxmax(), "year"]), age_max_sdi=int(d.loc[d.SDI.idxmax(), "year"]),
                   cul_mai_net=_cul(d.VOL), cul_mai_total=_cul(d.total_yield),
                   removed_vol=float(rv.rem_vol.sum()), qmd_monotone=bool((np.diff(d.QMD) >= -1e-9).all()))
        for a in (20, 40, 60, 100):
            for c in ("QMD", "D100", "TPH", "BAPH", "VOL", "SDI", "total_yield", "mai_total"):
                rec[f"{c}_{a}"] = float(x.loc[a, c])
        summ.append(rec)
pd.concat(rows).to_csv(os.path.join(OUTD, "SC_trajectories.csv"), index=False)
pd.DataFrame(rems).to_csv(os.path.join(OUTD, "SC_removals.csv"), index=False)
S = pd.DataFrame(summ); S.to_csv(os.path.join(OUTD, "SC_summary.csv"), index=False)
pd.set_option("display.width", 300); pd.set_option("display.max_columns", 99)
print(S[["arm", "group", "origin", "label", "reineke_slope", "max_ba", "age_max_ba", "max_sdi", "age_max_sdi",
         "QMD_40", "TPH_40", "BAPH_40", "VOL_40", "SDI_40",
         "QMD_100", "TPH_100", "BAPH_100", "VOL_100", "SDI_100"]].round(2).to_string(index=False))
print()
print("=" * 90)
print("ENVELOPE across the 13 scenarios, prereg gate F5: BAPH <= %.4f, SDI <= %.4f" % (OBS["BAPH"], OBS["SDI"]))
for lab, arm in ARMS:
    g = S[S.arm == lab]
    mb, ms = float(g.max_ba.max()), float(g.max_sdi.max())
    nb, nsd = int((g.max_ba > OBS["BAPH"]).sum()), int((g.max_sdi > OBS["SDI"]).sum())
    print("  %-12s max BAPH %8.3f (%+7.2f%%) in %d/%d scenarios past;  max SDI %9.2f (%+7.2f%%) in %d/%d past -> %s"
          % (lab, mb, 100 * (mb / OBS["BAPH"] - 1), nb, len(g), ms, 100 * (ms / OBS["SDI"] - 1), nsd, len(g),
             "INSIDE" if (mb <= OBS["BAPH"] and ms <= OBS["SDI"]) else "EXCEEDS"))
print("DONE scen")
