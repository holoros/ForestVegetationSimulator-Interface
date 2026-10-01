"""compare_yield_grid.py (2026-09-30, v103 Stage A2). Financial yield grid, v102 (~/jobs/koa_fin_20260924/out) against v103 (fin/out): BA ft2/ac, QMD in,
stems/ac, VOL m3/ha at ages 20, 40, 45, 52, 60, 100, 200 with percent change, plus peak BA and its age. Writes fin/out/yield_grid_compare.csv."""
import os, numpy as np, pandas as pd
H = os.path.dirname(os.path.abspath(__file__))
A = pd.read_csv(os.path.expanduser("~/jobs/koa_fin_20260924/out/koa_yield_grid_200yr.csv")); B = pd.read_csv(f"{H}/out/koa_yield_grid_200yr.csv")
rows = []
for (site, byi, tpa), a in A.groupby(["site", "byi", "tpa0"], sort=False):
    b = B[(B.site == site) & (B.byi == byi) & (B.tpa0 == tpa)]; a = a.set_index("age"); b = b.set_index("age")
    for age in (20, 40, 45, 52, 60, 100, 200):
        r = dict(site=site, byi=byi, tpa0=tpa, age=age)
        for v, lab in (("BA_ft2ac", "BA_ft2ac"), ("QMD_in", "QMD_in"), ("TPA", "stems_ac"), ("VOL", "VOL_m3ha")):
            r[f"{lab}_v102"] = float(a.loc[age, v]); r[f"{lab}_v103"] = float(b.loc[age, v]); r[f"{lab}_pct"] = 100.0 * (r[f"{lab}_v103"] - r[f"{lab}_v102"]) / r[f"{lab}_v102"]
        r["peakBA_v102"] = float(a.BA_ft2ac.max()); r["peakBA_age_v102"] = int(a.BA_ft2ac.idxmax()); r["peakBA_v103"] = float(b.BA_ft2ac.max()); r["peakBA_age_v103"] = int(b.BA_ft2ac.idxmax())
        r["peakBA_pct"] = 100.0 * (r["peakBA_v103"] - r["peakBA_v102"]) / r["peakBA_v102"]
        rows.append(r)
D = pd.DataFrame(rows); D.to_csv(f"{H}/out/yield_grid_compare.csv", index=False)
pd.set_option("display.width", 250); pd.set_option("display.max_columns", 30)
print(D[D.age.isin([40, 45, 52])][["site", "tpa0", "age", "BA_ft2ac_v102", "BA_ft2ac_v103", "BA_ft2ac_pct", "QMD_in_pct", "stems_ac_pct", "VOL_m3ha_pct", "peakBA_v102", "peakBA_v103", "peakBA_age_v102", "peakBA_age_v103"]].round(1).to_string())
for age in (40, 45, 52):
    x = D[D.age == age].BA_ft2ac_pct; print(f"age {age}: BA pct change min {x.min():+.1f} median {x.median():+.1f} max {x.max():+.1f}")
