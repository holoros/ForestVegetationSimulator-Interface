#!/usr/bin/env python3
"""realism_check.py ENGINE_DIR TAG: does diameter growth of suppressed trees ever rise with competition in the projected stands?
For every year of the deployed projections (engine_dir/out_m1/traj_M1.csv, even-aged 6 scenarios; uneven_aged_traj_M1.csv) the engine's own
LineageA.dDBH is evaluated for suppressed trees (BAL share 0.75, 0.9, 1.0 of BAPH; DBH = 0.5 and 0.75 x QMD; CR 0.3 and 0.5) at the stand's BAPH and SDI of that
year, and its partial derivatives by central differences (1e-4 relative) with respect to (a) stand density (SDI and BAPH scaled together, share fixed) and
(b) the tree's BAL share (stand fixed). A positive derivative = growth rising with competition. Writes v105c/out/realism_<TAG>.csv and prints counts."""
import os, sys, numpy as np, pandas as pd
ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]; OUT = os.path.expanduser("~/jobs/koa_v105c_20261102/v105c/out")
sys.path.insert(0, ENG); os.chdir(ENG); os.environ.setdefault("MPLCONFIGDIR", "/tmp/mpl")
import koa_params as KP, koa_equations as KE
L = KE.LineageA; form = getattr(KP, "DDBH_FORM", "v105b (no switch)"); print(TAG, "engine", ENG, "form", form, "DDBH", L.DDBH, flush=True)
def g(dbh, baph, share, cr, byi, pl, sdi):
    v = L.dDBH(np.array([dbh]), baph, np.array([share * baph]), np.array([cr]), byi, pl, sdi=sdi)[0]; return float(v)
rows = []
for fn, kind in (("traj_M1.csv", "even-aged"), ("uneven_aged_traj_M1.csv", "uneven-aged")):
    T = pd.read_csv(os.path.join(ENG, "out_m1", fn))
    if "age" in T.columns and "year" not in T.columns: T = T.rename(columns={"age": "year", "BYI": "byi", "Site": "site"}).assign(planted=0)   # uneven-aged table: natural
    for _, r in T.iterrows():
        if not (r.BAPH > 0 and r.SDI > 0): continue
        for share in (0.75, 0.9, 1.0):
            for fq in (0.5, 0.75):
                for cr in (0.3, 0.5):
                    dbh = max(fq * r.QMD, 1.0); h = 1e-4
                    gd = (g(dbh, r.BAPH * (1 + h), share, cr, r.byi, int(r.planted), r.SDI * (1 + h)) - g(dbh, r.BAPH * (1 - h), share, cr, r.byi, int(r.planted), r.SDI * (1 - h))) / (2 * h)
                    s1, s0 = min(share + h, 1.0), share - h
                    gs = (g(dbh, r.BAPH, s1, cr, r.byi, int(r.planted), r.SDI) - g(dbh, r.BAPH, s0, cr, r.byi, int(r.planted), r.SDI)) / (s1 - s0)
                    rows.append(dict(traj=kind, planted=int(r.planted), byi=r.byi, site=r.site, year=int(r.year), QMD=r.QMD, BAPH=r.BAPH, SDI=r.SDI,
                                     RD=r.SDI * (KP.INDEX_DIAMETER_CM / 25.4) ** KP.SDI_OF_EXPONENT / 923.0, share=share, dbh=dbh, cr=cr, ddbh=g(dbh, r.BAPH, share, cr, r.byi, int(r.planted), r.SDI),
                                     d_ddbh_d_density=gd, d_ddbh_d_share=gs))
D = pd.DataFrame(rows); D.to_csv(os.path.join(OUT, f"realism_{TAG}.csv"), index=False)
for k in ("d_ddbh_d_density", "d_ddbh_d_share"):
    pos = D[D[k] > 1e-12]
    print(TAG, k, "evaluations", len(D), "positive", len(pos), "max", D[k].max(), "stands with any positive", pos.groupby(["traj", "planted", "site"]).size().to_dict() if len(pos) else {}, flush=True)
print(TAG, "RD range in projections", round(D.RD.min(), 3), "to", round(D.RD.max(), 3))
