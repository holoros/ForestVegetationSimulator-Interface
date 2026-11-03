#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regenerate Supplemental Figures S4 (natural) and S5 (planted) under the M1 engine of
record, nine panels each, with 95% Monte Carlo parameter-perturbation percentile bands from
500 replicates. Same layout, colours and reference lines as the published versions.

The only change to the projection code is a record-only addition: expansion-weighted mean
crown ratio and the relative density against the anchored Garcia limit are written into the
row dictionary. No rate, no coefficient and no bound is touched, and validate_copy() below
still asserts bit-identity of the stepping body against the deposited project_psp.
"""
import os, sys, time, json
import numpy as np, pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); os.chdir(HERE)
os.environ.setdefault("MPLCONFIGDIR", os.path.join(HERE, ".mplcache"))

import koa_params as P
import koa_equations as KE
import koa_mortality_garcia as MG
import koa_projector as PR
import threestage as TS
import run_candidates as RC
from koa_equations import predict_HT, predict_HCB, rd_from_sdi, stage3_w   # v105d
from koa_mortality_garcia import h_from_qmd, relative_density

OUT = "out_m1"; os.makedirs(OUT, exist_ok=True)
P.ALLOC_MODE = "tree_eq"
_ORIG_SM = MG.stand_mortality

def _gated(engine, N0, h_prev, h_now, planted=0, sdi=None, rd=None):
    m = _ORIG_SM(engine, N0, h_prev, h_now, planted=planted, sdi=sdi, rd=rd)
    if sdi is None or not np.isfinite(sdi):
        return float(np.clip(m * TS.mort_cal(planted), 0.0, 0.95))   # mortality calibration 2026-09-16
    return float(np.clip(TS.rate_M1(m, sdi, planted) * TS.mort_cal(planted), 0.0, 0.95))   # mortality calibration 2026-09-16

MG.stand_mortality = _gated; PR.stand_mortality = _gated; RC.stand_mortality = _gated

N_REPS, SEED, MAXA = 500, 42, 100
SE = dict(ht_a0=0.614, ht_a1=0.018, ht_b=0.002, ht_c=0.019,
          ddbh_lnBYI=0.0820, dht_lnBYI=0.0799)
HT0 = dict(KE.HT_P); D0 = KE.LineageA.DDBH["b8"]; H0 = KE.LineageA.DHT["b8"]
GA0, GB0, GB0A = P.GARCIA_ALPHA, P.GARCIA_BETA, P.GARCIA_BETA_ANCHORED
CF0 = KE.LineageA.CF_DDBH
_CFRNG = [None]

def _cf_reset():
    KE.LineageA.CF_DDBH = CF0
    _CFRNG[0] = np.random.default_rng(SEED + P.CF_DDBH_MC_SEED_OFFSET)

def _cf_draw():
    z = _CFRNG[0].standard_normal()
    cf = CF0 * float(np.exp(P.CF_DDBH_MC_SIGMA_LOG * z))
    lo, hi = P.CF_DDBH_MC_CLIP_REL[0]*CF0, P.CF_DDBH_MC_CLIP_REL[1]*CF0
    KE.LineageA.CF_DDBH = float(np.clip(cf, lo, hi))

def set_params(rng=None):
    if rng is None:
        KE.HT_P.update(HT0); KE.LineageA.DDBH["b8"] = D0; KE.LineageA.DHT["b8"] = H0
        P.GARCIA_ALPHA, P.GARCIA_BETA, P.GARCIA_BETA_ANCHORED = GA0, GB0, GB0A
        _cf_reset(); KE.cal_reset(); return
    KE.HT_P["a0"] = rng.normal(HT0["a0"], SE["ht_a0"])
    KE.HT_P["a1"] = rng.normal(HT0["a1"], SE["ht_a1"])
    KE.HT_P["b"]  = max(1e-4, rng.normal(HT0["b"], SE["ht_b"]))
    KE.HT_P["c"]  = rng.normal(HT0["c"], SE["ht_c"])
    KE.LineageA.DDBH["b8"] = rng.normal(D0, SE["ddbh_lnBYI"])
    KE.LineageA.DHT["b8"]  = rng.normal(H0,  SE["dht_lnBYI"])
    _cf_draw()
    KE.cal_draw()
    P.GARCIA_ALPHA = float(np.clip(rng.normal(GA0, P.GARCIA_SE_ALPHA), *P.GARCIA_MC_CLIP_ALPHA))
    P.GARCIA_BETA_ANCHORED = GB0A

TPH_FAC = RC.TPH_FAC
stand_bal = RC.stand_bal
sdi_of = RC.sdi_of
renormalize_to_stand_rate = RC.renormalize_to_stand_rate
LINEAGES = RC.LINEAGES
transform = RC.transform
h40_from_list = RC.h40_from_list
h40_single_cohort = RC.h40_single_cohort


def project_rec(trees, byi, planted, n_years, cand, alloc_mode="tree_eq",
                dbh_max=None, ht_max=P.HARNESS_HT_MAX_PSP_M, engine=None):
    """RC.project with two extra RECORDED columns, CR and RD. Stepping body unchanged."""
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
        hcb = predict_HCB(dbh, ht, bal, baph, byi, rd=rd_from_sdi(sdi))   # v105d rd
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
        m_garcia = RC.stand_mortality(engine, tph, h40_prev, h40_now,
                                      planted=1 if planted else 0, sdi=sdi, rd=rd_now)
        m_stand = transform(cand, m_garcia, sdi, 1 if planted else 0)
        if np.isfinite(h40_now):
            h40_prev = h40_now
        if alloc_mode == "tree_eq":
            w = stage3_w(dbh, rht, baph, bal, sdi)   # respecified Stage 3 (copied from run_candidates.py), 2026-09-16
        else:
            w = np.exp(-P.ALLOC_BETA * (dbh / max(qmd, 0.1) - 1.0))
        wbar = np.sum(w * expf) / max(np.sum(expf), 1e-9)
        m_i = m_stand * w / max(wbar, 1e-9)
        ps = 1.0 - renormalize_to_stand_rate(m_i, expf, m_stand, cap=P.ALLOC_MORT_CAP)
        expf_new = np.maximum(expf * ps, 1e-5)
        realised = 1.0 - float(np.sum(expf_new) / max(np.sum(expf), 1e-9))
        dD_eff = np.where(dbh + dD > dbh_max, 0.0, dD)
        g_surv = float(np.sum(dD_eff * expf_new) / max(np.sum(expf_new), 1e-9))
        rows.append(dict(year=yr + 1, QMD=float(qmd), BAPH=float(baph), TPH=float(tph),
                         SDI=float(sdi), m_garcia=float(m_garcia), m_stand=float(m_stand),
                         m_realised=realised, g_surv=g_surv,
                         bal_conv=float(np.sum(bal_conv * expf) / max(np.sum(expf), 1e-9)),
                         HT=float(predict_HT(qmd, max(baph, 0.1), max(qmd, 1.0), byi, dbhmax=float(dbh.max()))),   # rDBH = QMD/DBH.max, as run_candidates.py
                         CR=float(np.sum(cr * expf) / max(np.sum(expf), 1e-9)),
                         RD=(float(relative_density(tph, h40_now))
                             if np.isfinite(h40_now) else np.nan)))
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
    d["MAI"] = d.VOL / d.year
    d["PAI"] = d.VOL.diff()
    d.loc[d.index[0], "PAI"] = d.VOL.iloc[0]
    return d


def validate_copy():
    """The recording wrapper must not move a single number."""
    set_params(None)
    for planted in (0, 1):
        a = RC.project(RC.wlist(planted, 303), 303, bool(planted), 100, "M1")
        set_params(None)
        b = project_rec(RC.wlist(planted, 303), 303, bool(planted), 100, "M1")
        for c in ("QMD", "BAPH", "TPH", "SDI", "HT", "VOL", "m_realised"):
            dmax = float(np.max(np.abs(a[c].to_numpy() - b[c].to_numpy())))
            assert dmax == 0.0, f"copy drift {planted} {c} {dmax:.3e}"
    print("validate_copy: max|diff| = 0.000e+00 on every carried column", flush=True)


BYIS = [(142, "Low (142)"), (303, "Medium (303)"), (418, "High (418)")]
COL = {142: "#E8A33D", 303: "#2E8B76", 418: "#1F5F8B"}
QTY = [("QMD", "QMD (cm)"), ("HT", "Height (m)"), ("BAPH", "Basal area (m$^2$ ha$^{-1}$)"),
       ("TPH", "Density (trees ha$^{-1}$)"), ("VOL", "Volume (m$^3$ ha$^{-1}$)"),
       ("CR", "Crown ratio"), ("RD", "Relative density $N/N_{limit}$"),
       ("MAI", "MAI (m$^3$ ha$^{-1}$ yr$^{-1}$)"), ("PAI", "PAI (m$^3$ ha$^{-1}$ yr$^{-1}$)")]
REFS = {"BAPH": [(12.3, "FIA Q25"), (28.7, "FIA Q75")],
        "VOL": [(45.0, "FIA Q25"), (125.0, "FIA Q75")]}


def collect(planted):
    """Point trajectory plus N_REPS perturbed trajectories for each of three site classes."""
    out = {}
    for si, (byi, lab) in enumerate(BYIS):
        t0 = time.time()
        set_params(None)
        rng = np.random.default_rng(SEED)
        for _j in range(si * N_REPS):      # keep the stream position scenario-specific
            if _j % N_REPS == 0:
                KE._JOINT[1] = 0   # joint rows restart with each skipped block, 2026-09-16 (v99)
            set_params(rng)
        set_params(None)
        pt = project_rec(RC.wlist(planted, byi), byi, bool(planted), MAXA, "M1")
        band = {k: np.full((N_REPS, MAXA), np.nan) for k, _ in QTY}
        for r in range(N_REPS):
            set_params(rng)
            d = project_rec(RC.wlist(planted, byi), byi, bool(planted), MAXA, "M1")
            for k, _ in QTY:
                band[k][r, :len(d)] = d[k].to_numpy()[:MAXA]
        set_params(None)
        out[byi] = dict(point=pt, band=band)
        print(f"  {'planted' if planted else 'natural'} {lab}: {time.time()-t0:.0f}s", flush=True)
    return out


def draw(res, planted, path, title):
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 7,
                         "axes.linewidth": 0.6, "savefig.facecolor": "white",
                         "axes.grid": False})
    fig, axes = plt.subplots(3, 3, figsize=(9.0, 7.2))
    yrs = np.arange(1, MAXA + 1)
    for i, (k, ylab) in enumerate(QTY):
        ax = axes[i // 3][i % 3]
        for byi, lab in BYIS:
            b = res[byi]["band"][k]
            lo = np.nanpercentile(b, 2.5, axis=0); hi = np.nanpercentile(b, 97.5, axis=0)
            ax.fill_between(yrs, lo, hi, color=COL[byi], alpha=0.18, lw=0)
            ax.plot(yrs, res[byi]["point"][k].to_numpy()[:MAXA], color=COL[byi], lw=1.3)
        for v, lb in REFS.get(k, []):
            ax.axhline(v, color="0.45", ls="--", lw=0.6)
            ax.annotate(lb, (MAXA * 0.99, v), ha="right", va="bottom",
                        fontsize=5.5, color="0.4")
        if k == "RD":
            ax.axhline(1.0, color="0.45", ls=":", lw=0.8)
            ax.annotate("Anchored García limit", (MAXA * 0.99, 1.0), ha="right",
                        va="bottom", fontsize=5.5, color="0.4")
        ax.set_xlabel("Stand age (yr)"); ax.set_ylabel(ylab)
        ax.annotate(f"({chr(97+i)})", (0.03, 0.93), xycoords="axes fraction",
                    fontsize=7, fontweight="bold")
        ax.margins(x=0.02)
    h = [plt.Line2D([], [], color=COL[b], lw=1.4, label=l) for b, l in BYIS]
    fig.legend(handles=h, loc="lower center", ncol=3, frameon=False,
               title="Site (BYI, Mg ha$^{-1}$)", fontsize=6.5, title_fontsize=6.5)
    fig.suptitle(title, x=0.012, ha="left", fontsize=8)
    fig.tight_layout(rect=(0, 0.045, 1, 0.975))
    fig.savefig(path, dpi=400)
    plt.close(fig)
    print("wrote", path, flush=True)


if __name__ == "__main__":
    validate_copy()
    for planted, fn, ttl in ((0, "FigS4_natural_M1.png", "Natural stand projections"),
                             (1, "FigS5_planted_M1.png", "Planted stand projections")):
        res = collect(planted)
        draw(res, planted, os.path.join(OUT, fn), ttl)
        rows = []
        for byi, lab in BYIS:
            p = res[byi]["point"].copy(); p["byi"] = byi; p["site"] = lab
            p["origin"] = "plt" if planted else "nat"
            rows.append(p)
        pd.concat(rows).to_csv(os.path.join(
            OUT, f"figS{4+planted}_point_{'plt' if planted else 'nat'}_M1.csv"), index=False)
    print("done", flush=True)
