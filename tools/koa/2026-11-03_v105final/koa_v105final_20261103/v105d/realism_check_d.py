#!/usr/bin/env python3
"""realism_check_d.py [ENGINE_DIR TAG]: does diameter or height growth of suppressed trees ever rise with competition in the projected stands?
Extends v105c/realism_check.py (dDBH) to dHT. For every year of each engine's own deployed projections (engine_dir/out_m1/traj_M1.csv, six even-aged
scenarios; uneven_aged_traj_M1.csv), LineageA.dDBH and LineageA.dHT are evaluated for suppressed trees (BAL share 0.75, 0.9, 1.0 of BAPH; DBH = 0.5 and
0.75 x QMD; HT = 0.5 and 0.75 x stand HT; CR 0.3 and 0.5) at the stand's BAPH and SDI of that year, with central-difference derivatives (1e-4 relative) with
respect to (a) stand density (SDI and BAPH scaled together, share fixed) and (b) the tree's BAL share (stand fixed). Positive = growth rising with competition.
Also dHT for dominant trees (share 0, 0.1) in the density direction (reported; all three engines carry a positive RD/BAPH size term in dHT).
Without arguments: runs v105b (koa_v105_20261102), v105c (koa_v105c_20261102), v105d (this job) in subprocesses and writes v105d/out/realism_summary.csv."""
import os, sys, subprocess, numpy as np, pandas as pd
OUT = os.path.expanduser("~/jobs/koa_v105final_20261103/v105d/out")
if len(sys.argv) == 1:
    rows = []
    for eng, tag in ((os.path.expanduser("~/jobs/koa_v105_20261102/engine_v103"), "v105b"), (os.path.expanduser("~/jobs/koa_v105c_20261102/engine_v103"), "v105c"),
                     (os.path.expanduser("~/jobs/koa_v105final_20261103/engine_v103"), "v105d")):
        r = subprocess.run([sys.executable, os.path.abspath(__file__), eng, tag], capture_output=True, text=True); print(r.stdout, r.stderr[-2000:], flush=True)
        D = pd.read_csv(f"{OUT}/realism_{tag}.csv")
        for comp in ("ddbh", "dht"):
            for k in ("d_density", "d_share"):
                sub = D[(D.kind == "suppressed")]; col = f"{comp}_{k}"
                rows.append(dict(engine=tag, component=comp, trees="suppressed (share 0.75-1)", derivative=k, evaluations=len(sub), positive=int((sub[col] > 1e-12).sum()), max=float(sub[col].max()),
                                 stands_with_positive=";".join(sorted(set(f"{a}/{b}/{c}" for a, b, c in sub[sub[col] > 1e-12][["traj", "planted", "site"]].itertuples(index=False))))))
        sub = D[D.kind == "dominant"]
        rows.append(dict(engine=tag, component="dht", trees="dominant (share 0, 0.1)", derivative="d_density", evaluations=len(sub), positive=int((sub.dht_d_density > 1e-12).sum()), max=float(sub.dht_d_density.max()), stands_with_positive="(reported)"))
        rows.append(dict(engine=tag, component="RD range in projections", trees="", derivative="", evaluations=len(D), positive=None, max=float(D.RD.max()), stands_with_positive="min %.3f" % D.RD.min()))
    S = pd.DataFrame(rows); S.to_csv(f"{OUT}/realism_summary.csv", index=False); print(S.to_string())
    sys.exit(0)
ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]
sys.path.insert(0, ENG); os.chdir(ENG); os.environ.setdefault("MPLCONFIGDIR", "/tmp/mpl")
import koa_params as KP, koa_equations as KE
L = KE.LineageA; print(TAG, "engine", ENG, "DDBH_FORM", getattr(KP, "DDBH_FORM", "v105b (no switch)"), "DHT_FORM", getattr(KP, "DHT_FORM", "v105b (no switch)"), flush=True)
def gD(dbh, baph, share, cr, byi, pl, sdi): return float(L.dDBH(np.array([dbh]), baph, np.array([share * baph]), np.array([cr]), byi, pl, sdi=sdi)[0])
def gH(ht, baph, share, cr, byi, pl, sdi): return float(L.dHT(np.array([ht]), baph, np.array([share * baph]), np.array([cr]), byi, pl, sdi=sdi)[0])
rows = []; h = 1e-4
for fn in ("traj_M1.csv", "uneven_aged_traj_M1.csv"):
    T = pd.read_csv(os.path.join(ENG, "out_m1", fn)); kind_t = "even-aged" if fn == "traj_M1.csv" else "uneven-aged"
    if "age" in T.columns and "year" not in T.columns: T = T.rename(columns={"age": "year", "BYI": "byi", "Site": "site"}).assign(planted=0)
    for _, r in T.iterrows():
        if not (r.BAPH > 0 and r.SDI > 0 and r.HT > 0): continue
        pl = int(r.planted)
        for kind, shares in (("suppressed", (0.75, 0.9, 1.0)), ("dominant", (0.0, 0.1))):
            for share in shares:
                for fq in (0.5, 0.75):
                    for cr in (0.3, 0.5):
                        dbh = max(fq * r.QMD, 1.0); ht = max(fq * r.HT, 1.4)
                        s1, s0 = min(share + h, 1.0), max(share - h, 0.0)
                        rec = dict(traj=kind_t, kind=kind, planted=pl, byi=r.byi, site=r.site, year=int(r.year), QMD=r.QMD, HT=r.HT, BAPH=r.BAPH, SDI=r.SDI,
                                   RD=r.SDI * (KP.INDEX_DIAMETER_CM / 25.4) ** KP.SDI_OF_EXPONENT / KP.DDBH_RD_SDIMAX, share=share, dbh=dbh, ht=ht, cr=cr)
                        for comp, g, size in (("ddbh", gD, dbh), ("dht", gH, ht)):
                            rec[comp] = g(size, r.BAPH, share, cr, r.byi, pl, r.SDI)
                            rec[f"{comp}_d_density"] = (g(size, r.BAPH * (1 + h), share, cr, r.byi, pl, r.SDI * (1 + h)) - g(size, r.BAPH * (1 - h), share, cr, r.byi, pl, r.SDI * (1 - h))) / (2 * h)
                            rec[f"{comp}_d_share"] = (g(size, r.BAPH, s1, cr, r.byi, pl, r.SDI) - g(size, r.BAPH, s0, cr, r.byi, pl, r.SDI)) / (s1 - s0)
                        rows.append(rec)
D = pd.DataFrame(rows); D.to_csv(os.path.join(OUT, f"realism_{TAG}.csv"), index=False)
for comp in ("ddbh", "dht"):
    for k in ("d_density", "d_share"):
        sub = D[D.kind == "suppressed"]; pos = sub[sub[f"{comp}_{k}"] > 1e-12]
        print(TAG, comp, k, "suppressed evaluations", len(sub), "positive", len(pos), "max", sub[f"{comp}_{k}"].max(), flush=True)
print(TAG, "RD range in projections", round(D.RD.min(), 3), "to", round(D.RD.max(), 3))
