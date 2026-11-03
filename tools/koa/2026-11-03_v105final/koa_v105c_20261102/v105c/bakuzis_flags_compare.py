#!/usr/bin/env python3
"""bakuzis_flags_compare.py: Bakuzis check rows labelled v105 in a4/bakuzis/bakuzis_checks_v104_v105.csv of the v105 job (= v105b) and of this job (= v105c);
writes v105c/out/bakuzis_flags_v105b_v105c.csv (every check, both results) and prints counts and the checks whose result changed."""
import os, pandas as pd
A = pd.read_csv(os.path.expanduser("~/jobs/koa_v105_20261102/a4/bakuzis/bakuzis_checks_v104_v105.csv")); B = pd.read_csv(os.path.expanduser("~/jobs/koa_v105c_20261102/a4/bakuzis/bakuzis_checks_v104_v105.csv"))
k = ["group", "relation", "item"]; A = A[A.version == "v105"][k + ["value", "result"]]; B = B[B.version == "v105"][k + ["value", "result"]]
M = A.merge(B, on=k, how="outer", suffixes=("_v105b", "_v105c")); M.to_csv(os.path.expanduser("~/jobs/koa_v105c_20261102/v105c/out/bakuzis_flags_v105b_v105c.csv"), index=False)
print("v105b:", A.result.value_counts().to_dict()); print("v105c:", B.result.value_counts().to_dict())
ch = M[M.result_v105b != M.result_v105c]; print("changed", len(ch)); print(ch.to_string())
print("v105c FLAG rows:"); print(M[M.result_v105c == "FLAG"][k + ["value_v105c"]].to_string())
