#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Score M0, M1 and M2 against MORTALITY_RULE_2026-09-12.md.

The stepping body is an exact copy of koa_projector.project_psp with one hook: the stand
rate returned by Stage 2 is passed through the candidate transform before Stage 3 allocates
it. Under M0 the transform is the identity, and the copy is validated against the deposited
project_psp before any gate is read.
"""
import os, sys, json
import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.chdir(HERE)

import koa_params as P
import koa_equations as KE
from koa_equations import predict_HT, predict_HCB, stand_bal, LINEAGES
from koa_projector import sdi_of, project_psp, project_cohort
from koa_mortality_garcia import (h40_from_list, h40_single_cohort, h_from_qmd,
                                  stand_mortality, relative_density)
from koa_survival_calibrated_py import renormalize_to_stand_rate
import threestage as TS

TPH_FAC = 0.00007854
N_CLASS = 20
OUT = "out_cand"
os.makedirs(OUT, exist_ok=True)

SCEN = [("nat", 0, 100, "Low"), ("nat", 0, 264, "Medium"), ("nat", 0, 450, "High"),
        ("plt", 1, 100, "Low"), ("plt", 1, 264, "Medium"), ("plt", 1, 450, "High")]
W = {0: dict(k=1.481127375383228, lam=9.138290706876996),
     1: dict(k=1.4476135514616866, lam=6.909836526414346)}
OBS = dict(QMD=69.6786879496591, BAPH=76.0621351844664, SDI=1453.46727427237,
           M_UNCOND=0.09621, M_LO=0.04810, M_HI=0.19242)


def _finish(dbh, expf, byi):
    dbh = np.asarray(dbh, float); expf = np.asarray(expf, float)
    o = np.argsort(-dbh); dbh, expf = dbh[o], expf[o]
    ba = dbh ** 2 * TPH_FAC * expf
    baph = float(ba.sum()); tph = float(expf.sum())
    qmd = float(np.sqrt(baph / (TPH_FAC * tph)))
    bal = np.cumsum(ba) - ba
    ht = np.array([float(predict_HT(x, max(baph, 0.1), max(qmd, 1.0), byi, dbhmax=float(dbh.max()))) for x in dbh])
    hcb = predict_HCB(dbh, ht, bal, baph, byi)
    cr = np.clip(1 - hcb / np.maximum(ht, 0.1), 0.05, 0.95)
    return pd.DataFrame(dict(dbh=dbh, ht=ht, cr=cr, expf=expf))


def wlist(planted, byi):
    w = W[planted]
    n0 = P.harness_init_tph(planted); d0 = P.harness_init_dbh(planted)
    q = (np.arange(N_CLASS) + 0.5) / N_CLASS
    d = w["lam"] * (-np.log(1 - q)) ** (1.0 / w["k"])
    d = d * (d0 / d.mean())
    return _finish(d, np.full(N_CLASS, n0 / N_CLASS), byi)


def transform(cand, m_garcia, sdi, planted):
    if cand == "M0":
        return float(m_garcia)
    if cand == "M1":
        return TS.rate_M1(m_garcia, sdi, planted)
    if cand == "M2":
        return TS.rate_M2(m_garcia, sdi, planted)
    if cand == "M4":
        return TS.rate_M4(m_garcia, sdi, planted)
    if cand == "M5":
        return TS.rate_M5(m_garcia, sdi, planted)
    raise ValueError(cand)


def project(trees, byi, planted, n_years, cand, alloc_mode="tree_eq", dbh_max=None,
            ht_max=P.HARNESS_HT_MAX_PSP_M, engine=None):
    """Exact copy of project_psp's stepping body with the candidate rate hook."""
    if engine is None:
        engine = P.MORT_ENGINE
    if dbh_max is None:
        dbh_max = P.harness_dbh_max(planted)
    L = LINEAGES["A"]
    dbh = trees.dbh.to_numpy(float); ht = trees.ht.to_numpy(float)
    cr = trees.cr.to_numpy(float); expf = trees.expf.to_numpy(float)
    rows = []; h40_prev = None
    for yr in range(int(n_years)):
        order = np.argsort(-dbh)
        dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]
        ba = (dbh ** 2 * TPH_FAC) * expf
        bal = (np.cumsum(ba) - ba) if P.PSP_BAL_MODE == "cumsum" else stand_bal(baph=ba.sum(), dbh=dbh, expf=expf)   # weighted percentile, v103
        bal_conv = np.cumsum(ba) - ba
        baph = ba.sum(); tph = expf.sum()
        qmd = np.sqrt(baph / (TPH_FAC * tph)) if tph > 0 else 0.0
        sdi = sdi_of(tph, qmd); htmax = ht.max() if len(ht) else 0.1
        hcb = predict_HCB(dbh, ht, bal, baph, byi)
        cr = np.clip(1 - hcb / np.maximum(ht, 0.1), 0.05, 0.95)
        rht = ht / max(htmax, 0.1)
        below_bh = ht < 1.3716
        dD = np.where(below_bh, 0.0, L.dDBH(dbh, baph, bal, cr, byi, planted, sdi=sdi, rht=rht))
        dH = L.dHT(ht, baph, bal, cr, byi, planted, sdi=sdi, rht=rht)
        if engine in P.GARCIA_QMD_ENGINES:
            h40_now = float(h_from_qmd(qmd)) if qmd > 0 else float("nan")
        else:
            h40_now = h40_from_list(dbh, ht, expf) if len(dbh) > 1 else h40_single_cohort(ht[0])
        rd_now = (relative_density(tph, h40_now)
                  if (engine in P.GARCIA_DD_ENGINES and np.isfinite(h40_now)) else None)
        m_garcia = stand_mortality(engine, tph, h40_prev, h40_now,
                                   planted=1 if planted else 0, sdi=sdi, rd=rd_now)
        m_stand = transform(cand, m_garcia, sdi, 1 if planted else 0)
        if np.isfinite(h40_now):
            h40_prev = h40_now
        if alloc_mode == "tree_eq":
            w = np.clip(1.0 - np.exp(-np.exp(P.STAGE3_COEF['c0'] + P.STAGE3_COEF['c1'] * np.log(np.maximum(dbh, 0.1)) + P.STAGE3_COEF['c2'] * rht + P.STAGE3_COEF['c3'] * np.log(baph + 1.0) + P.STAGE3_COEF['c4'] * np.log(np.maximum(bal, 0.0) + 1.0))), 1e-9, 1.0)   # respecified Stage 3, 2026-09-16
        else:
            w = np.exp(-P.ALLOC_BETA * (dbh / max(qmd, 0.1) - 1.0))
        wbar = np.sum(w * expf) / max(np.sum(expf), 1e-9)
        m_i = m_stand * w / max(wbar, 1e-9)
        ps = 1.0 - renormalize_to_stand_rate(m_i, expf, m_stand, cap=P.ALLOC_MORT_CAP)
        expf_new = np.maximum(expf * ps, 1e-5)
        _mort_ba = float(np.sum((dbh ** 2 * TPH_FAC) * (expf - expf_new)))  # output only
        realised = 1.0 - float(np.sum(expf_new) / max(np.sum(expf), 1e-9))
        dD_eff = np.where(dbh + dD > dbh_max, 0.0, dD)
        g_surv = float(np.sum(dD_eff * expf_new) / max(np.sum(expf_new), 1e-9))
        rows.append(dict(year=yr + 1, QMD=float(qmd), BAPH=float(baph), TPH=float(tph),
                         SDI=float(sdi), m_garcia=float(m_garcia), m_stand=float(m_stand),
                         m_realised=realised, g_surv=g_surv,
                         bal_conv=float(np.sum(bal_conv * expf) / max(np.sum(expf), 1e-9)),
                         MORT_BA=_mort_ba, DBHMAX=float(dbh.max()),
                         HT=float(predict_HT(qmd, max(baph, 0.1), max(qmd, 1.0), byi, dbhmax=float(dbh.max())))))
        expf = expf_new
        nd = dbh + dD; nh = ht + dH
        nd = np.where(nd > dbh_max, dbh, nd); nh = np.where(nh > ht_max, ht, nh)
        dbh, ht = nd, nh
        if len(dbh) > 300:
            keyb = np.round(dbh * 2) / 2.0
            uk = np.unique(keyb); ndbh = []; nht = []; ncr = []; nexpf = []
            for k in uk:
                m = keyb == k; e = expf[m].sum()
                ndbh.append(np.average(dbh[m], weights=expf[m])); nexpf.append(e)
                nht.append(np.average(ht[m], weights=expf[m])); ncr.append(np.average(cr[m], weights=expf[m]))
            dbh = np.array(ndbh); ht = np.array(nht); cr = np.array(ncr); expf = np.array(nexpf)
    d = pd.DataFrame(rows)
    d["dQMD"] = d.QMD.diff().shift(-1)
    d["selection"] = d.dQMD - d.g_surv
    d["VOL"] = d.BAPH * d.HT * 0.40
    d["MORT_VOL"] = d.MORT_BA * d.HT * 0.40   # output only, same stand height convention
    return d


def validate_copy():
    worst = 0.0
    for planted in (0, 1):
        for byi in (100, 264, 450):
            t = wlist(planted, byi)
            old = P.ALLOC_MODE; P.ALLOC_MODE = "tree_eq"
            try:
                o = project_psp(t, byi, bool(planted), "A", n_years=100, ingrowth=False,
                                use_size_caps=True, dbh_max=P.harness_dbh_max(bool(planted)),
                                return_traj=True)
            finally:
                P.ALLOC_MODE = old
            d = project(t, byi, bool(planted), 100, "M0")
            a = o["traj"][["QMD", "BAPH", "TPH"]].to_numpy(float)
            b = d[["QMD", "BAPH", "TPH"]].to_numpy(float)
            worst = max(worst, float(np.abs(a - b).max()))
    return worst


def main():
    w = validate_copy()
    print(f"copy validation against deposited project_psp: max|diff| = {w:.3e} "
          f"-> {'PASS' if w < 1e-9 else 'FAIL'}")
    if w >= 1e-9:
        raise SystemExit("stepping copy does not reproduce project_psp; no gate is read")
    print()
    print(TS.describe())

    traj = {}
    for cand in ("M0", "M1", "M2", "M4", "M5"):
        frames = []
        for tag, planted, byi, site in SCEN:
            d = project(wlist(planted, byi), byi, bool(planted), 200, cand)
            d["cand"] = cand; d["origin"] = tag; d["planted"] = planted
            d["byi"] = byi; d["site"] = site
            frames.append(d)
        traj[cand] = pd.concat(frames, ignore_index=True)
        traj[cand].to_csv(os.path.join(OUT, f"traj_{cand}.csv"), index=False)
    A = pd.concat(traj.values(), ignore_index=True)
    A.to_csv(os.path.join(OUT, "traj_all.csv"), index=False)

    print("=" * 78)
    print("H1  MORTALITY LEVEL, natural stands, realised annual rate over the horizon")
    print(f"    observed unconditional {OBS['M_UNCOND']:.5f}; PASS band "
          f"{OBS['M_LO']:.5f} to {OBS['M_HI']:.5f} on >= 2 of 3 natural sites")
    print("=" * 78)
    h1 = {}
    for cand in ("M0", "M1", "M2", "M4", "M5"):
        d = traj[cand]; d = d[(d.planted == 0) & (d.year <= 100)]
        inband = 0; parts = []
        for byi, g in d.groupby("byi"):
            m = float(g.m_realised.mean())
            ok = OBS["M_LO"] <= m <= OBS["M_HI"]
            inband += ok
            parts.append(f"BYI {byi}: {m:.5f}{'*' if ok else ' '}")
        h1[cand] = inband >= 2
        print(f"    {cand}  {'  '.join(parts)}   -> {'PASS' if h1[cand] else 'FAIL'}")

    print()
    print("=" * 78)
    print("H2  DENSITY RESPONSE, projected annual mortality across SDI terciles")
    print("=" * 78)
    h2 = {}
    for cand in ("M0", "M1", "M2", "M4", "M5"):
        d = traj[cand]; d = d[(d.planted == 0) & (d.year <= 200)].copy()
        q = d.SDI.quantile([1 / 3, 2 / 3]).to_list()
        d["t"] = np.where(d.SDI <= q[0], 0, np.where(d.SDI <= q[1], 1, 2))
        vals = [float(d[d.t == i].m_realised.mean()) for i in (0, 1, 2)]
        mono = vals[0] < vals[1] < vals[2]
        h2[cand] = mono
        print(f"    {cand}  low {vals[0]:.5f}  mid {vals[1]:.5f}  high {vals[2]:.5f}   "
              f"-> {'PASS' if mono else 'FAIL'}")

    print()
    print("=" * 78)
    print("H3  DENSITY ENVELOPE, reported ages 20/40/60/100")
    print("=" * 78)
    h3 = {}
    base = None
    for cand in ("M0", "M1", "M2", "M4", "M5"):
        d = traj[cand]; s = d[d.year.isin([20, 40, 60, 100])]
        nq = int((s.QMD > OBS["QMD"]).sum()); nb = int((s.BAPH > OBS["BAPH"]).sum())
        ns = int((s.SDI > OBS["SDI"]).sum())
        tot = nq + nb + ns
        if cand == "M0":
            base = tot
        h3[cand] = tot <= base
        print(f"    {cand}  past QMD {nq}  past BAPH {nb}  past SDI {ns}  total {tot}   "
              f"-> {'PASS' if h3[cand] else 'FAIL'}")

    print()
    print("=" * 78)
    print("H4  BAKUZIS REINEKE SLOPE (scored as an outcome, never as the criterion)")
    print("=" * 78)
    AGES = [25, 50, 100, 150, 200]
    h4 = {}
    for cand in ("M0", "M1", "M2", "M4", "M5"):
        d = traj[cand]; nok = 0; out = []
        for (tag, byi), g in d.groupby(["origin", "byi"]):
            g = g[g.year.isin(AGES)].sort_values("year")
            qq = g.QMD.to_numpy(float); tt = g.TPH.to_numpy(float)
            keep = np.r_[True, np.diff(qq) > 0.5]
            qq, tt = qq[keep], tt[keep]
            if len(qq) < 3 or np.std(np.log(qq)) < 1e-3:
                out.append(f"{tag}{byi}:n/a"); continue
            sl = np.polyfit(np.log(qq), np.log(tt), 1)[0]
            ok = -2.2 < sl < -1.2
            nok += ok
            out.append(f"{tag}{byi}:{sl:+.2f}{'*' if ok else ''}")
        h4[cand] = nok
        print(f"    {cand}  {'  '.join(out)}   -> {nok} of 6 inside band")

    res = dict(H1=h1, H2=h2, H3=h3, H4=h4)
    json.dump(res, open(os.path.join(OUT, "gates.json"), "w"), indent=1, default=str)
    print()
    print("wrote", OUT)


if __name__ == "__main__":
    main()
