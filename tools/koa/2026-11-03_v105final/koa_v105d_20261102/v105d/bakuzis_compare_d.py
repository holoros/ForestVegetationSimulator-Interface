#!/usr/bin/env python3
"""bakuzis_compare_d.py: Bakuzis check rows labelled v105 in a4/bakuzis/bakuzis_checks_v104_v105.csv of the v105 job (= v105b), the v105c job and this job
(= v105d); all three from the same step-aware bundled check (a4/bakuzis/bakuzis_v105_vs_v104.R: Reineke screen keeps years with QMD gain > 0.10 x median
step and stem loss > 0.5% per yr; trajectories that lose stems with < 3 points are NOT EVALUATED). Writes v105d/out/bakuzis_flags_3way.csv and prints counts
(PASS, FLAG, info, NOT EVALUATED, evaluated = PASS + FLAG), the Reineke step values, the checks whose result differs between v105c and v105d."""
import os, re, pandas as pd
P = {"v105b": "~/jobs/koa_v105_20261102", "v105c": "~/jobs/koa_v105c_20261102", "v105d": "~/jobs/koa_v105d_20261102"}
k = ["group", "relation", "item"]; M = None
for tag, p in P.items():
    A = pd.read_csv(os.path.expanduser(p + "/a4/bakuzis/bakuzis_checks_v104_v105.csv")); A = A[A.version == "v105"][k + ["value", "result"]].copy()
    e = A.relation == "Eichhorn"; A.loc[e, "value"] = A.loc[e, "item"] + ": " + A.loc[e, "value"].astype(str); A.loc[e, "item"] = "CV of VOL at equal HT (height range differs by version, in value)"
    A = A[k + ["value", "result"]].rename(columns={"value": f"value_{tag}", "result": f"result_{tag}"})
    M = A if M is None else M.merge(A, on=k, how="outer")
    vc = A[f"result_{tag}"].value_counts().to_dict(); ev = vc.get("PASS", 0) + vc.get("FLAG", 0)
    steps = sorted(set(re.findall(r"step ([0-9.]+)", " ".join(A[f"value_{tag}"].astype(str)))))
    print(tag, vc, "evaluated (PASS+FLAG)", ev, "not evaluated", vc.get("NOT EVALUATED", 0), "Reineke step values", steps)
M.to_csv(os.path.expanduser("~/jobs/koa_v105d_20261102/v105d/out/bakuzis_flags_3way.csv"), index=False)
ch = M[M.result_v105c != M.result_v105d]; print("changed v105c -> v105d:", len(ch)); print(ch[k + ["value_v105c", "result_v105c", "value_v105d", "result_v105d"]].to_string())
print("v105d FLAG rows:"); print(M[M.result_v105d == "FLAG"][k + ["value_v105d"]].to_string())
