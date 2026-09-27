#!/usr/bin/env python3
"""grid.py ENGINE_DIR OUTDIR  --  PREREG-KOA-01 variant B, projection grid.

Runs the six site-class by origin rows of run_candidates.SCEN under the two
Garcia-QMD arms that differ ONLY in beta:

    C5  garcia_qmd  anchored   beta = koa_params.GARCIA_BETA_ANCHORED = 0.16019053617304435  (DEPLOYED)
    C3  garcia_qmd             beta = koa_params.GARCIA_BETA          = 0.117                (FITTED)

The arm is selected through the engine's own configuration switch
(run_candidates.project(..., engine=ARM) -> koa_mortality_garcia.stand_mortality
-> engine_beta(engine)). No constant is edited. Deterministic point projections.
"""
import os, sys
import numpy as np, pandas as pd

E, OUTD = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
sys.path.insert(0, E)
os.makedirs(OUTD, exist_ok=True)
os.chdir(E)

import regen_m1 as RM
import run_candidates as RC, koa_params as P
import koa_mortality_garcia as MG

ARMS = [("C5_anchored", "garcia_qmd_anchored"), ("C3_fitted", "garcia_qmd")]
OBS = RC.OBS
NY = 200
CAND = "M0"

print("engine dir:", E)
print("P.MORT_ENGINE (deployed default):", P.MORT_ENGINE)
for lab, arm in ARMS:
    assert arm in P.MORT_ENGINES, arm
    print("  arm %-12s engine=%-22s beta_attr=%-22s beta=%.17g"
          % (lab, arm, MG.beta_attr(arm), MG.engine_beta(arm)))
print("observed maxima: BAPH %.4f  SDI %.4f  QMD %.4f" % (OBS["BAPH"], OBS["SDI"], OBS["QMD"]))
print()

rows, summ = [], []
for lab, arm in ARMS:
    beta = MG.engine_beta(arm)
    for tag, planted, byi, site in RC.SCEN:
        RM.set_params(None)          # reset to deposited parameter state
        d = RC.project(RC.wlist(planted, byi), byi, bool(planted), NY, CAND, engine=arm)
        d = d.copy()
        d["arm"] = lab; d["engine"] = arm; d["beta"] = beta
        d["origin"] = tag; d["planted"] = planted; d["byi"] = byi; d["site"] = site
        rows.append(d)
        x = d.set_index("year")
        d100 = d[d.year <= 100]
        rec = dict(arm=lab, engine=arm, beta=beta, origin=tag, site=site, byi=byi,
                   max_ba_100=float(d100.BAPH.max()),
                   age_max_ba_100=int(d100.loc[d100.BAPH.idxmax(), "year"]),
                   max_sdi_100=float(d100.SDI.max()),
                   age_max_sdi_100=int(d100.loc[d100.SDI.idxmax(), "year"]),
                   max_ba_200=float(d.BAPH.max()), max_sdi_200=float(d.SDI.max()),
                   m_realised_mean_100=float(d100.m_realised.mean()))
        for a in (20, 40, 60, 100):
            for c in ("QMD", "TPH", "BAPH", "VOL", "SDI"):
                rec["%s_%d" % (c, a)] = float(x.loc[a, c])
        summ.append(rec)

T = pd.concat(rows, ignore_index=True)
S = pd.DataFrame(summ)
T.to_csv(os.path.join(OUTD, "GRID_trajectories.csv"), index=False)
S.to_csv(os.path.join(OUTD, "GRID_summary.csv"), index=False)

# ---- harness fidelity check: C5 grid against the deposited record -----------
ref = os.path.join(E, "out_cand", "traj_M0.csv")
if os.path.exists(ref):
    R = pd.read_csv(ref)
    A = T[(T.arm == "C5_anchored")]
    j = R.merge(A, on=["year", "origin", "byi"], suffixes=("_ref", "_new"))
    if len(j):
        w = max(float(np.abs(j.QMD_ref - j.QMD_new).max()),
                float(np.abs(j.BAPH_ref - j.BAPH_new).max()),
                float(np.abs(j.TPH_ref - j.TPH_new).max()))
        print("C5 reproduction of out_cand/traj_M0.csv: rows matched %d, max|diff| = %.3e -> %s"
              % (len(j), w, "PASS" if w < 1e-9 else "CHECK"))
    else:
        print("C5 reproduction: no rows matched in traj_M0.csv")
else:
    print("C5 reproduction: out_cand/traj_M0.csv not present")
print()

pd.set_option("display.width", 260); pd.set_option("display.max_columns", 99)
cols = ["arm", "origin", "site"] + ["%s_%d" % (c, a) for a in (20, 40, 60, 100)
                                    for c in ("QMD", "BAPH", "TPH", "VOL", "SDI")]
print(S[cols].round(2).to_string(index=False))
print()
print(S[["arm", "origin", "site", "max_ba_100", "age_max_ba_100", "max_sdi_100",
         "age_max_sdi_100", "max_ba_200", "max_sdi_200"]].round(2).to_string(index=False))
print()
print("=" * 90)
print("ENVELOPE, prereg gate F5: BAPH <= %.4f and SDI <= %.4f" % (OBS["BAPH"], OBS["SDI"]))
print("=" * 90)
for lab, arm in ARMS:
    g = S[S.arm == lab]
    mb, ms = float(g.max_ba_100.max()), float(g.max_sdi_100.max())
    print("  %-12s 0-100 yr: max BAPH %8.3f (%+7.2f%% vs observed)   max SDI %9.2f (%+7.2f%% vs observed)  -> %s"
          % (lab, mb, 100 * (mb / OBS["BAPH"] - 1), ms, 100 * (ms / OBS["SDI"] - 1),
             "INSIDE" if (mb <= OBS["BAPH"] and ms <= OBS["SDI"]) else "EXCEEDS"))
    mb2, ms2 = float(g.max_ba_200.max()), float(g.max_sdi_200.max())
    print("  %-12s 0-200 yr: max BAPH %8.3f (%+7.2f%%)                max SDI %9.2f (%+7.2f%%)             -> %s"
          % (lab, mb2, 100 * (mb2 / OBS["BAPH"] - 1), ms2, 100 * (ms2 / OBS["SDI"] - 1),
             "INSIDE" if (mb2 <= OBS["BAPH"] and ms2 <= OBS["SDI"]) else "EXCEEDS"))
    n = S[S.arm == lab]
    rep = T[(T.arm == lab) & (T.year.isin([20, 40, 60, 100]))]
    print("     reported ages only: rows past BAPH %d/24, past SDI %d/24, past QMD %d/24"
          % (int((rep.BAPH > OBS["BAPH"]).sum()), int((rep.SDI > OBS["SDI"]).sum()),
             int((rep.QMD > OBS["QMD"]).sum())))
print("DONE grid")
