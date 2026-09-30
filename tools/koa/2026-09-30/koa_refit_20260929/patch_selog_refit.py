"""patch_selog_refit.py (2026-09-29). Run AFTER refit_addendum.R has written out/c_bootstrap.csv: replaces the v102 PLACEHOLDER values of
CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG in engine_refit (fits dDBH_c_AP, dHT_c_AP) and engine_refit_live (dDBH_l_AP, dHT_l_AP) with the
installation-cluster bootstrap SD of log c (column selog), and updates out/patch_values_engine_<arm>.csv. Trajectories do not depend on these."""
import os, re, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); B = pd.read_csv(f"{HERE}/out/c_bootstrap.csv")
for eng, arm in (("engine_refit", "c"), ("engine_refit_live", "l")):
    p = f"{HERE}/{eng}/koa_params.py"; t = open(p).read(); pv = pd.read_csv(f"{HERE}/out/patch_values_{eng}.csv")
    for resp, const in (("dDBH", "CAL_DDBH_SE_LOG"), ("dHT", "CAL_DHT_SE_LOG")):
        fit = f"{resp}_{arm}_AP"; s = B[B.fit == fit].set_index("origin").selog
        if not {"natural", "planted"} <= set(s.index): print("missing", fit); continue
        line = re.findall(rf"^{const} = .*$", t, re.M); assert len(line) == 1
        t = t.replace(line[0], f"{const} = ({s['natural']:.5f}, {s['planted']:.5f})   # installation-cluster bootstrap SD of log c, out/c_bootstrap.csv {fit}, 2026-09-29")
        for o in ("natural", "planted"): pv.loc[pv.name == f"{const}_{o}", "new"] = float(s[o])
        print(eng, const, round(float(s["natural"]), 5), round(float(s["planted"]), 5))
    open(p, "w").write(t); pv.to_csv(f"{HERE}/out/patch_values_{eng}.csv", index=False)
print("done; CAL_*_SE_LOG placeholders replaced")
