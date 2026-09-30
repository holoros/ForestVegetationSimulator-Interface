"""patch_mortcal_refit.py (2026-09-30). As track2/patch_mortcal.py: write the recalibrated natural mortality level (form mult) from
mort/<arm>/H_mort_level_natural.csv into MORT_CAL and MORT_CAL_SE_LOG of engine_<arm>. Planted stays 1.0 as in v102."""
import os, csv, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); rows = []
V102 = {"MORT_CAL_natural": 2.6462860696589208, "MORT_CAL_SE_LOG_natural": 0.1817204503423178}
for arm in ("refit2", "refit2_live"):
    lv = {r["form"]: r for r in csv.DictReader(open(os.path.join(HERE, "mort", arm, "H_mort_level_natural.csv")))}
    k = float(lv["mult"]["level"]); se = float(lv["mult"]["plot_se_log"])
    p = os.path.join(HERE, f"engine_{arm}", "koa_params.py"); t = open(p).read()
    a = "MORT_CAL = (1.0, 1.0)   # natural mortality level calibration (natural, planted) on the M1 stand rate, 2026-09-16"
    assert t.count(a) == 1; t = t.replace(a, f"MORT_CAL = ({k:.5f}, 1.0)   # natural mortality level recalibrated on the 2026-09-30 refit constants ({arm}), 23 natural intervals")
    b = "MORT_CAL_SE_LOG = (0.19069, 0.0)"; assert t.count(b) == 1; t = t.replace(b, f"MORT_CAL_SE_LOG = ({se:.5f}, 0.0)   # plot-cluster bootstrap SD of log k, 2026-09-30")
    open(p, "w").write(t)
    rows += [dict(engine=f"engine_{arm}", name="MORT_CAL_natural", old=V102["MORT_CAL_natural"], new=k, plot_lo95=float(lv["mult"]["plot_lo95"]), plot_hi95=float(lv["mult"]["plot_hi95"])),
             dict(engine=f"engine_{arm}", name="MORT_CAL_SE_LOG_natural", old=V102["MORT_CAL_SE_LOG_natural"], new=se, plot_lo95=None, plot_hi95=None)]
    print(arm, "MORT_CAL", round(k, 5), "SE_LOG", round(se, 5))
pd.DataFrame(rows).to_csv(os.path.join(HERE, "out/patch_values_mortcal_refit2.csv"), index=False)
