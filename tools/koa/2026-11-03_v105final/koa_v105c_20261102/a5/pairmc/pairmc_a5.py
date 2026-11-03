#!/usr/bin/env python3
"""a5/pairmc A5 rerun (pairmc_a5.py): copy of pairmc.py on engine_a5 (Stage 3 fix), output out_a5, plus BOOT variants (PREREG addendum A5).
Usage: python3 pairmc.py prep | gate <wid> <nw> | main <wid> <nw>
Runs inside a5/pairmc/engine (a copy of engine_v103); imports regen_m1 for the engine of record (M1 gated mortality, tree_eq Stage 3)
and its parameter setter. Writes only under a5/pairmc.
"""
import os, sys, inspect, json, time
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); ENG = os.path.join(HERE, "engine_a5"); OUT = os.path.join(HERE, "out_a5"); PREP = os.path.join(HERE, "out", "prep_draws.npz")
os.environ.setdefault("MPLCONFIGDIR", os.path.join(ENG, ".mpl")); sys.path.insert(0, ENG)
import regen_m1 as R           # chdir(ENG), patches stand_mortality, P.ALLOC_MODE = tree_eq
P, KE, RC = R.P, R.KE, R.RC
os.chdir(ENG)
JOINT_PUB = os.path.join(ENG, "out_joint", "K_joint_draws.csv")        # copy of engine_v103/out_joint (500 rows, published)
JOINT_1K = os.path.join(HERE, "jointmc", "out", "K_joint_draws.csv")   # a5 extension, 1000 rows
PUB = os.path.expanduser("~/jobs/koa_v105c_20261102/engine_v103/out_m1")  # read only
LEVELS = [142, 303, 418]; ORIG = [0, 1]; AGES = [20, 30, 40]; NY = 40; NREC = RC.N_CLASS
TAU = dict(I_D=0.8282380, I_H=0.2173551, T_D=0.2960633, T_H=0.2932490)  # VarCorr of v105c dDBH_L_NO (K3c1) and v105b dHT_L_NO (out/inc/fit_stats_v103.csv)
BYI_LO, BYI_HI = 28.9849035779126, 543.404779528712                     # v105 site index range of frames/final/d{DBH,HT}_NO_v103_model.csv
K_INFL = 1.0                                                            # v105: residuals are already 20 km blocked CV residuals (byi_v105), no inflation
SEED_PREP = 20261031

# ---- projection copy with process-error hooks (exact copy of run_candidates.project when fD = fH = 1, tD = tH = None)
src = inspect.getsource(RC.project)
reps = [("def project(trees, byi, planted, n_years, cand,", "def pm_project(trees, byi, planted, n_years, cand, fD=1.0, fH=1.0, tD=None, tH=None,"),
        ("    cr = trees.cr.to_numpy(float); expf = trees.expf.to_numpy(float)\n",
         "    cr = trees.cr.to_numpy(float); expf = trees.expf.to_numpy(float)\n    rid = np.arange(len(dbh)); tD = np.ones(len(dbh)) if tD is None else np.asarray(tD, float); tH = np.ones(len(dbh)) if tH is None else np.asarray(tH, float)\n"),
        ("        dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]\n",
         "        dbh, ht, cr, expf = dbh[order], ht[order], cr[order], expf[order]\n        rid = rid[order]\n"),
        ("L.dDBH(dbh, baph, bal, cr, byi, planted, sdi=sdi, rht=rht))", "L.dDBH(dbh, baph, bal, cr, byi, planted, sdi=sdi, rht=rht) * fD * tD[rid])"),
        ("        dH = L.dHT(ht, baph, bal, cr, byi, planted, sdi=sdi, rht=rht)\n", "        dH = L.dHT(ht, baph, bal, cr, byi, planted, sdi=sdi, rht=rht) * fH * tH[rid]\n"),
        ("        if len(dbh) > 300:\n", "        assert len(dbh) <= 300\n        if len(dbh) > 300:\n")]
for a, b in reps:
    assert src.count(a) == 1, a
    src = src.replace(a, b)
exec(src, RC.__dict__)
pm_project = RC.pm_project

def streams(n):
    """regen_m1 seed 42 stream: per replicate 6 overwritten normals then Garcia alpha; CF stream of the dedicated generator."""
    rng = np.random.default_rng(R.SEED); al = []
    for _ in range(n):
        rng.normal(R.HT0["a0"], R.SE["ht_a0"]); rng.normal(R.HT0["a1"], R.SE["ht_a1"]); max(1e-4, rng.normal(R.HT0["b"], R.SE["ht_b"]))
        rng.normal(R.HT0["c"], R.SE["ht_c"]); rng.normal(R.D0, R.SE["ddbh_lnBYI"]); rng.normal(R.H0, R.SE["dht_lnBYI"])
        al.append(float(np.clip(rng.normal(R.GA0, P.GARCIA_SE_ALPHA), *P.GARCIA_MC_CLIP_ALPHA)))
    R.set_params(None); cf = []
    for _ in range(n):
        R._cf_draw(); cf.append(KE.LineageA.CF_DDBH)
    R.set_params(None)
    return np.array(al), np.array(cf)

def set_rep(r, alpha, cf):
    R.set_params(None)
    KE._JOINT[1] = r; KE.cal_draw()
    KE.LineageA.CF_DDBH = float(cf); P.GARCIA_ALPHA = float(alpha); P.GARCIA_BETA_ANCHORED = R.GB0A

def run(planted, byi, **kw):
    d = pm_project(RC.wlist(planted, byi), byi, bool(planted), NY, "M0", **kw).set_index("year")
    return {a: (float(d.loc[a, "VOL"]), float(d.loc[a, "BAPH"]), float(d.loc[a, "QMD"])) for a in AGES}

def prep():
    E = pd.read_csv(os.path.join(HERE, "byi_v105", "byi_blocked_resid_C2P0F.csv"))   # v105: C2-P0 map, 20 km blocked CV, 10 reps
    l = E.lnratio.to_numpy(float); lstar = l.mean() + K_INFL * (l - l.mean())        # multiplicative scale chosen by the PREREG rule
    rng = np.random.default_rng(SEED_PREP); N = 1000
    Z = dict(I_D=rng.standard_normal((N, 2, 3)), I_H=rng.standard_normal((N, 2, 3)),
             T_D=rng.standard_normal((N, 2, 3, NREC)), T_H=rng.standard_normal((N, 2, 3, NREC)))
    byi = np.zeros((N, 2, 3)); first_out = np.zeros((N, 2, 3), bool); ndraw = np.zeros((N, 2, 3), int)
    for i in range(N):
        for o in range(2):
            for j, lev in enumerate(LEVELS):
                k = 0
                while True:
                    v = lev * np.exp(rng.choice(lstar)); k += 1
                    if k == 1: first_out[i, o, j] = not (BYI_LO <= v <= BYI_HI)
                    if BYI_LO <= v <= BYI_HI or k > 1000: break
                byi[i, o, j] = v; ndraw[i, o, j] = k
    np.savez(os.path.join(OUT, "prep_draws.npz"), byi=byi, first_out=first_out, ndraw=ndraw, **Z)
    rows = [dict(rep=i, planted=o, level=LEVELS[j], byi_true=byi[i, o, j], first_draw_out_of_range=int(first_out[i, o, j]), n_draws=ndraw[i, o, j])
            for i in range(N) for o in range(2) for j in range(3)]
    pd.DataFrame(rows).to_csv(os.path.join(OUT, "byi_true_draws.csv"), index=False)
    print("prep done; lnratio mean %.4f sd %.4f inflated sd %.4f" % (l.mean(), l.std(ddof=1), lstar.std(ddof=1)))

INC = os.path.expanduser("~/jobs/koa_v105c_20261102/out/inc/")
def load_boot():
    BD = pd.read_csv(INC + "boot_v103_dDBH_L_NO.csv"); BH = pd.read_csv(INC + "boot_v103_dHT.csv")
    assert len(BD) == 400 and len(BH) == 400   # v105: non-converged draws (ok False) are dropped below with the missing-constant draws
    BD = BD.sort_values("draw").reset_index(drop=True); BH = BH.sort_values("draw").reset_index(drop=True)
    assert (BD.draw.to_numpy() == BH.draw.to_numpy()).all()
    keep = (BD.ok.astype(bool) & BH.ok.astype(bool) & BD[["c_natural", "c_planted"]].notna().all(axis=1) & BH[["c_natural", "c_planted"]].notna().all(axis=1)).to_numpy()   # amendment A5-B; v105 also drops non-converged draws
    BD = BD[keep].reset_index(drop=True); BH = BH[keep].reset_index(drop=True); print("BOOT complete draw pairs", len(BD), flush=True); assert len(BD) >= 300
    H = pd.read_csv(os.path.join(HERE, "boot_inputs", "h_draws_snapshot.csv")); H = H[H.ok == 1].sort_values("draw").reset_index(drop=True)
    return BD, BH, H

def set_boot(r, alpha, cf, BD, BH, H):
    set_rep(r, alpha, cf)            # joint row r (Stage 1, pbar, kmort), CF draw r, alpha r
    k = r % len(BD); h = r % len(H)
    for j in range(10):
        KE.LineageA.DDBH["b%d" % j] = float(BD["b%d" % j][k]); KE.LineageA.DHT["b%d" % j] = float(BH["b%d" % j][k])
    KE.LineageA.CAL_DDBH = (float(BD.c_natural[k]) / P.CF_DDBH_MARGINAL, float(BD.c_planted[k]) / P.CF_DDBH_MARGINAL)
    KE.LineageA.CAL_DHT = (float(BH.c_natural[k]) / P.CF_DHT, float(BH.c_planted[k]) / P.CF_DHT)
    for key in ("a0", "a1", "b", "c", "g1", "g2"):
        KE.HT_P[key] = float(H[key][h])
    KE.HT_P["b"] = max(KE.HT_P["b"], 1e-4)

def mult(z, tau): return np.exp(tau * z - tau ** 2 / 2)

def gate(wid, nw):
    P.JOINT_DRAWS_FILE = JOINT_PUB; KE._JOINT[0] = None
    al, cf = streams(3000)
    # point check: pm_project with unit multipliers equals run_candidates.project
    R.set_params(None); worst = 0.0
    for o in ORIG:
        for lev in LEVELS:
            a = RC.project(RC.wlist(o, lev), lev, bool(o), NY, "M0")[["QMD", "BAPH", "VOL"]].to_numpy(float)
            b = pm_project(RC.wlist(o, lev), lev, bool(o), NY, "M0")[["QMD", "BAPH", "VOL"]].to_numpy(float)
            worst = max(worst, float(np.abs(a - b).max()))
    print("pm_project vs RC.project max|diff|", worst, flush=True)
    rows = []
    for si, (tag, planted, lev, site) in enumerate(RC.SCEN):
        for r in range(500):
            if r % nw != wid: continue
            set_rep(r, al[si * 500 + r], cf[r]); res = run(planted, lev)
            for a in AGES: rows.append(dict(si=si, scen=tag, byi=lev, rep_pub=si * 500 + r, r=r, age=a, VOL=res[a][0], BAPH=res[a][1], QMD=res[a][2]))
    R.set_params(None)
    pd.DataFrame(rows).to_csv(os.path.join(OUT, "gate1_w%d.csv" % wid), index=False)
    json.dump(dict(point_maxdiff=worst), open(os.path.join(OUT, "gate1_point_w%d.json" % wid), "w"))
    print("gate worker", wid, "done", flush=True)

VARS = tuple(os.environ.get("PAIRMC_VARS", "P,PP,PPB,B,BOOT,BOOT_PPB").split(","))
def main(wid, nw):
    P.JOINT_DRAWS_FILE = JOINT_1K; KE._JOINT[0] = None
    N = 1000; al, cf = streams(N); D = np.load(PREP)
    BD, BH, H = load_boot(); print("boot rows dDBH", len(BD), "dHT", len(BH), "height converged", len(H), flush=True)
    rows = []; t0 = time.time()
    for r in range(N):
        if r % nw != wid: continue
        for var in VARS:
            for o in ORIG:
                for j, lev in enumerate(LEVELS):
                    if var == "B": R.set_params(None)
                    elif var.startswith("BOOT"): set_boot(r, al[r], cf[r], BD, BH, H)
                    else: set_rep(r, al[r], cf[r])
                    kw = {}
                    if var in ("PP", "PPB", "BOOT_PPB"):
                        kw = dict(fD=mult(D["I_D"][r, o, j], TAU["I_D"]), fH=mult(D["I_H"][r, o, j], TAU["I_H"]),
                                  tD=mult(D["T_D"][r, o, j], TAU["T_D"]), tH=mult(D["T_H"][r, o, j], TAU["T_H"]))
                    b = float(D["byi"][r, o, j]) if var in ("PPB", "B", "BOOT_PPB") else float(lev)
                    res = run(o, b, **kw)
                    for a in AGES: rows.append(dict(variant=var, rep=r, planted=o, level=lev, byi_true=b, age=a, VOL=res[a][0], BAPH=res[a][1], QMD=res[a][2]))
        if r % (nw * 50) == wid: print("worker", wid, "rep", r, "%.0fs" % (time.time() - t0), flush=True)
    R.set_params(None)
    pd.DataFrame(rows).to_csv(os.path.join(OUT, os.environ.get("PAIRMC_PREFIX", "raw_w") + "%d.csv" % wid), index=False)
    print("main worker", wid, "done %.0fs" % (time.time() - t0), flush=True)

if __name__ == "__main__":
    m = sys.argv[1]
    if m == "prep": prep()
    elif m == "gate": gate(int(sys.argv[2]), int(sys.argv[3]))
    elif m == "main": main(int(sys.argv[2]), int(sys.argv[3]))
