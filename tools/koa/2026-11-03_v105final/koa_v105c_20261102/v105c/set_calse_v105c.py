#!/usr/bin/env python3
"""set_calse_v105.py: after the v105 bootstraps. dDBH: full-refit installation bootstrap (out/inc/boot_v103_dDBH*.csv, 400 resamples) -> se_boot, ci95_boot,
CAL_DDBH_SE_LOG (SD of log c), copied to the v104 names boot_v103_dDBH_L_NO*.csv. dHT: full-refit bootstrap (boot_v103_dHT*.csv) -> se_boot, ci95_boot,
CAL_SE_LOG_full_refit; CAL_DHT_SE_LOG from the vector-fixed re-solve (boot_v103_dHT_resolveonly.csv), as in v103/v104. Updates out/v105_constants.json and koa_params.py
(registry engine copies synced). Backups exist from patch_engine_v105.py."""
import json, os, re, shutil, numpy as np, pandas as pd
W = os.path.expanduser("~/jobs/koa_v105c_20261102"); I = f"{W}/out/inc"
J = json.load(open(f"{W}/out/v105_constants.json"))
def summ(resp):
    s = pd.read_csv(f"{I}/boot_v103_{resp}_summary.csv").set_index("term"); b = pd.read_csv(f"{I}/boot_v103_{resp}.csv")
    return s, b
sD, bD = summ("dDBH"); sH, bH = summ("dHT")
for k, s in (("DDBH", sD), ("DHT", sH)):
    J[k]["se_boot"] = {t: float(s.loc[t, "boot_se"]) for t in [f"b{i}" for i in range(10)] + ["c_natural", "c_planted"]}
    J[k]["ci95_boot"] = {t: [float(s.loc[t, "lo95"]), float(s.loc[t, "hi95"])] for t in [f"b{i}" for i in range(10)] + ["c_natural", "c_planted"]}
    J[k]["boot_n_ok"] = int(s["n_ok"].iloc[0])
J["DDBH"]["CAL_SE_LOG"] = [float(sD.loc["c_natural", "se_log"]), float(sD.loc["c_planted", "se_log"])]; J["DDBH"]["CAL_SE_LOG_status"] = "v105c full-refit installation bootstrap of the K3c1 fit, 400 resamples"
r = pd.read_csv(f"{I}/boot_v103_dHT_resolveonly.csv")
J["DHT"]["CAL_SE_LOG"] = [float(np.std(np.log(r.c_natural.dropna()), ddof=1)), float(np.std(np.log(r.c_planted.dropna()), ddof=1))]
J["DHT"]["CAL_SE_LOG_full_refit"] = [float(sH.loc["c_natural", "se_log"]), float(sH.loc["c_planted", "se_log"])]; J["DHT"]["CAL_SE_LOG_status"] = "v105b files reused (dHT unchanged in v105c): vector fixed, c re-solved, 400 resamples"
J["DDBH_CANDIDATE_L_NO"] = J["DDBH"]
json.dump(J, open(f"{W}/out/v105_constants.json", "w"), indent=1)
for a, b in (("boot_v103_dDBH.csv", "boot_v103_dDBH_L_NO.csv"), ("boot_v103_dDBH_summary.csv", "boot_v103_dDBH_L_NO_summary.csv")): shutil.copy2(f"{I}/{a}", f"{I}/{b}")
for E in ("engine_v103", "a2/registry/engine", "a2/registry/engine_nocal"):
    p = f"{W}/{E}/koa_params.py"; t = open(p).read()
    t, n = re.subn(r"^CAL_DDBH_SE_LOG = .*$", "CAL_DDBH_SE_LOG = (%.5f, %.5f)   # SD of log c, 400 installation-cluster resamples within source, full refit of dDBH_L_NO K3c1, v105c" % tuple(J["DDBH"]["CAL_SE_LOG"]), t, count=1, flags=re.M); assert n == 1
    t, n = re.subn(r"^CAL_DHT_SE_LOG = .*$", "CAL_DHT_SE_LOG = (%.5f, %.5f)   # SD of log c, vector fixed (full refit bootstrap: %.3f, %.3f), v105b fit reused unchanged in v105c" % (tuple(J["DHT"]["CAL_SE_LOG"]) + tuple(J["DHT"]["CAL_SE_LOG_full_refit"])), t, count=1, flags=re.M); assert n == 1
    open(p, "w").write(t)
print("CAL_DDBH_SE_LOG", J["DDBH"]["CAL_SE_LOG"], "CAL_DHT_SE_LOG", J["DHT"]["CAL_SE_LOG"], "full", J["DHT"]["CAL_SE_LOG_full_refit"], "n_ok", J["DDBH"]["boot_n_ok"], J["DHT"]["boot_n_ok"])
