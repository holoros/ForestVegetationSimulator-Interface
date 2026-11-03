import re, csv, json, os
W = os.path.expanduser("~/jobs/koa_v105d_20261102")
rows = list(csv.DictReader(open(f"{W}/a2/mort/v104/H_mort_level_natural.csv"))); r = [x for x in rows if x["form"] == "mult"][0]
k = float(r["level"]); se = float(r["plot_se_log"])
p = f"{W}/engine_v103/koa_params.py"; t = open(p).read()
t, n = re.subn(r"^MORT_CAL = .*$", "MORT_CAL = (%.5f, 1.0)   # natural level re-solved on engine v105d (v105c + RD x competition in dHT, Eq. 2, Eq. 3, Stage 3), PSP 122 2019-2023 excluded, 2026-11-02" % k, t, count=1, flags=re.M); assert n == 1
t, n = re.subn(r"^MORT_CAL_SE_LOG = .*$", "MORT_CAL_SE_LOG = (%.5f, 0.0)   # plot-cluster bootstrap SD of log k, v105d" % se, t, count=1, flags=re.M); assert n == 1
open(p, "w").write(t)
J = json.load(open(f"{W}/out/v105_constants.json"))
J["MORT_CAL"] = {"value": [round(k, 5), 1.0], "se_log": [round(se, 5), 0.0], "n_intervals": int(r["n_intervals"]), "plot_ci95": [float(r["plot_lo95"]), float(r["plot_hi95"])], "inst_ci95": [float(r["inst_lo95"]), float(r["inst_hi95"])], "loio_range": [float(r["loio_level_min"]), float(r["loio_level_max"])], "note": "a2/mort/v104 on the v105d engine; PSP 122 2019-2023 interval excluded"}
json.dump(J, open(f"{W}/out/v105_constants.json", "w"), indent=1)
print("MORT_CAL", k, se, r["loio_level_min"], r["loio_level_max"])
