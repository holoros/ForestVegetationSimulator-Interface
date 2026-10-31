"""sens_v104.py (A4, 30 Oct 2026): recompute on the v104 engine the supplement sensitivity statements that depended on the
earlier engine: (1) net MAI culmination at the bounds of the planted diameter multiplier interval, (2) unweighted-rank BAL
sensitivity at year 100, (3) years for a tree without competition to grow from 2.5 cm to the initial QMD, (4) projected
planted stemwood biomass against Eq. 1 on the yield grid, (5) ceiling arms are read from a2/registry/ceiling/v104 by the
report, not here. Deterministic point path (M0 under the gated M1 set-up) as run_engine.py. No coordinates read."""
import os, sys, json, math
import numpy as np, pandas as pd
J = os.path.expanduser("~/jobs/koa_v104_20261030"); ENG = os.path.join(J, "engine_v103"); OUT = os.path.join(J, "a4/sens")
sys.path.insert(0, ENG); os.environ.setdefault("MPLCONFIGDIR", "/tmp/mpl"); _cwd = os.getcwd(); os.chdir(ENG)
import regen_m1 as RM, run_candidates as RC, koa_equations as KE, koa_params as KP
R = {}
def mai_culm(d):   # Table S32 rule: maximum of VOL/age after the first local minimum (natural search 10..300, planted 2..300)
    y = d.y.to_numpy() if "y" in d else d.year.to_numpy(); v = d.VOL.to_numpy(); mai = v / y
    i0 = 1
    while i0 + 1 < len(mai) and mai[i0 + 1] < mai[i0]: i0 += 1
    j = i0 + int(np.argmax(mai[i0:])); return int(y[j]), float(mai[j])
def proj(planted, byi, years=300):
    RM.set_params(None); return RC.project(RC.wlist(planted, byi), byi, bool(planted), years, "M0")
base = {}
for tag, planted, byi, site in RC.SCEN:
    base[(planted, byi)] = proj(planted, byi); print("base", site, planted, byi, flush=True)
# (1) culmination at the planted multiplier bounds (installation-cluster bootstrap 95 percent interval of CAL planted)
B = pd.read_csv(os.path.join(J, "out/inc/boot_v103_dDBH_L_NO_summary.csv")); cp = B[B.term == "cal_planted"].iloc[0]
R["cal_planted_interval"] = dict(estimate=float(cp.estimate), lo95=float(cp.lo95), hi95=float(cp.hi95))
R["culmination_at_bounds"] = {}
for byi, site in ((100, "Low"), (264, "Medium"), (450, "High")):
    row = {}
    for lab, val in (("lo", cp.lo95), ("point", KP.CAL_DDBH[1]), ("hi", cp.hi95)):
        KP.CAL_DDBH = (KP.CAL_DDBH[0], float(val)); KE.cal_reset(); d = proj(1, byi); a, m = mai_culm(d); row[lab] = dict(age=a, mai=m)
    KP.CAL_DDBH = (KP.CAL_DDBH[0], float(cp.estimate)); KE.cal_reset()
    R["culmination_at_bounds"][site] = row; print("bounds", site, row, flush=True)
# (2) unweighted percentile rank at year 100, natural even-aged
R["unweighted_rank"] = {}
KP.BAL_PERCENTILE_WEIGHTED = False
for byi, site in ((100, "Low"), (264, "Medium"), (450, "High")):
    d = proj(0, byi, 100); b = base[(0, byi)]; r100 = d[d.y == 100].iloc[0] if "y" in d else d[d.year == 100].iloc[0]
    b100 = b[b.y == 100].iloc[0] if "y" in b else b[b.year == 100].iloc[0]
    R["unweighted_rank"][site] = dict(qmd_pct=100 * (r100.QMD - b100.QMD) / b100.QMD, vol_pct=100 * (r100.VOL - b100.VOL) / b100.VOL)
    print("unweighted", site, R["unweighted_rank"][site], flush=True)
KP.BAL_PERCENTILE_WEIGHTED = True
# (3) years from 2.5 cm to the initial QMD for a single tree without competition (BAL 0, BAPH 0, CR 0.9, calibrated form)
R["years_to_initial_qmd"] = {}
for planted, target in ((0, KP.harness_init_dbh(False)), (1, KP.harness_init_dbh(True))):
    for byi in (100, 264, 450):
        dbh = 2.5; yrs = 0
        while dbh < target and yrs < 200:
            dbh += float(KE.LineageA.dDBH(np.array([dbh]), 0.0, np.array([0.0]), np.array([0.9]), byi, planted)[0]); yrs += 1
        R["years_to_initial_qmd"][f"{'planted' if planted else 'natural'}|{byi}"] = dict(target_cm=float(target), years=yrs)
print("years", R["years_to_initial_qmd"], flush=True)
# (4) planted stemwood biomass against Eq. 1 on the v104 yield grid
G = pd.read_csv(os.path.join(J, "a2/fin/out/koa_yield_grid_200yr.csv"))
k, p = 0.0284, 2.171; dens = 0.51
rows = []
for (site, byi, tpa0), g in G.groupby(["site", "byi", "tpa0"]):
    g = g[(g.age >= 5) & (g.age <= 100)].copy()
    h100 = KE.predict_HT(g.DBHMAX.to_numpy(), g.BAPH.to_numpy(), g.QMD.to_numpy(), byi, dbhmax=g.DBHMAX.to_numpy())
    eq1 = byi * (1 - np.exp(-k * h100)) ** p; bio = g.VOL.to_numpy() * dens
    g["ratio"] = bio / eq1; g["bio"] = bio; g["eq1"] = eq1; g["h100"] = h100; rows.append(g)
Y = pd.concat(rows); Y.to_csv(os.path.join(OUT, "yield_grid_eq1_v104.csv"), index=False)
R["eq1_ratio_median_by_byi"] = Y.groupby("byi").ratio.median().round(3).to_dict()
R["eq1_ratio_median_by_byi_x4"] = (Y.groupby("byi").ratio.median() / 4).round(3).to_dict()
a40 = Y[Y.age == 40].groupby("byi").bio.mean(); a10 = Y[Y.age == 10].groupby("byi").bio.mean()
R["bio40_mean_by_byi"] = a40.round(1).to_dict(); R["bio40_fold_450_over_120"] = float(a40[450] / a40[120]); R["bio10_fold_450_over_120"] = float(a10[450] / a10[120])
per = Y[Y.age == 40].pivot_table(index="tpa0", columns="byi", values="bio"); R["bio40_fold_by_density"] = (per[450] / per[120]).round(2).to_dict()
hh = Y[(Y.age >= 10) & (Y.age <= 40)].groupby(["byi", "age"]).h100.mean().unstack(0)
e = lambda b, h: b * (1 - np.exp(-k * h)) ** p
R["eq1_fold_equal_h"] = 450 / 120.0; R["eq1_fold_projected_h_range"] = [float((e(450, hh[450]) / e(120, hh[120])).min()), float((e(450, hh[450]) / e(120, hh[120])).max())]
R["ddbh_fold_450_over_120"] = float(math.exp(KE.LineageA.DDBH["b8"] * math.log(450 / 120.0)))
R["dbhmax_at_40_by_byi"] = Y[Y.age == 40].groupby("byi").DBHMAX.agg(["min", "max"]).round(1).to_dict()
json.dump(R, open(os.path.join(OUT, "sens_v104.json"), "w"), indent=1, default=float)
print(json.dumps(R, indent=1, default=float)); print("SENS DONE")
