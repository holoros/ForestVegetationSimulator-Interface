import re, csv, json, os
W = os.path.expanduser("~/jobs/koa_v104_20261030")
rows = list(csv.DictReader(open(f"{W}/a2/mort/v104/H_mort_level_natural.csv"))); r = [x for x in rows if x["form"] == "mult"][0]
k = float(r["level"]); se = float(r["plot_se_log"])
p = f"{W}/engine_v103/koa_params.py"; t = open(p).read()
t, n = re.subn(r"^MORT_CAL = .*$", "MORT_CAL = (%.5f, 1.0)   # natural level re-solved on engine v104 (dDBH_L_NO, Stage 3 refit), 23 natural intervals, PSP 122 2019-2023 excluded, 2026-10-30 (A4-D2)" % k, t, count=1, flags=re.M); assert n == 1
t, n = re.subn(r"^MORT_CAL_SE_LOG = .*$", "MORT_CAL_SE_LOG = (%.5f, 0.0)   # plot-cluster bootstrap SD of log k, v104" % se, t, count=1, flags=re.M); assert n == 1
open(p, "w").write(t)
J = json.load(open(f"{W}/out/v104_constants.json"))
J["MORT_CAL"] = {"value": [round(k, 5), 1.0], "se_log": [round(se, 5), 0.0], "n_intervals": int(r["n_intervals"]), "plot_ci95": [float(r["plot_lo95"]), float(r["plot_hi95"])], "inst_ci95": [float(r["inst_lo95"]), float(r["inst_hi95"])], "loio_range": [float(r["loio_level_min"]), float(r["loio_level_max"])], "note": "a2/mort/v104; PSP 122 2019-2023 interval excluded (one removal rule for all stages)"}
json.dump(J, open(f"{W}/out/v104_constants.json", "w"), indent=1)
print("MORT_CAL", k, se, r["loio_level_min"], r["loio_level_max"])
