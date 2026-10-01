"""patch_mortcal_v103.py: write the re-solved natural mortality level (form mult, 24 natural intervals) into MORT_CAL of engine_v103."""
import csv, os, pandas as pd
H = os.path.dirname(os.path.abspath(__file__)); lv = {r["form"]: r for r in csv.DictReader(open(f"{H}/mort/v103/H_mort_level_natural.csv"))}
k = float(lv["mult"]["level"]); se = float(lv["mult"]["plot_se_log"]); n = int(float(lv["mult"]["n_intervals"]))
p = f"{H}/../engine_v103/koa_params.py"; t = open(p).read()
a = "MORT_CAL = (1.0, 1.0)   # placeholder, re-solved by patch_mortcal_v103.py"; assert t.count(a) == 1
t = t.replace(a, f"MORT_CAL = ({k:.5f}, 1.0)   # natural mortality level re-solved on engine_v103 (v103 constants and tree table), {n} natural intervals, 2026-09-30")
b = [l for l in t.splitlines() if l.startswith("MORT_CAL_SE_LOG = ")]; assert len(b) == 1
t = t.replace(b[0], f"MORT_CAL_SE_LOG = ({se:.5f}, 0.0)   # plot-cluster bootstrap SD of log k, v103")
open(p, "w").write(t)
pd.DataFrame([dict(name="MORT_CAL_natural", old=2.6462860696589208, new=k, plot_lo95=float(lv["mult"]["plot_lo95"]), plot_hi95=float(lv["mult"]["plot_hi95"]), n_intervals=n),
              dict(name="MORT_CAL_SE_LOG_natural", old=0.1817204503423178, new=se)]).to_csv(f"{H}/out/patch_values_mortcal_v103.csv", index=False)
print("MORT_CAL", round(k, 5), "SE_LOG", round(se, 5), "n", n)
