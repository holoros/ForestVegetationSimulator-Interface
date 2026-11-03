#!/usr/bin/env python3
"""parity_engine.py: engine with the K3c1 code path but DDBH_FORM = "v105b" and the v105b vector must reproduce the v105b projections exactly:
a2 run_engine point path (six scenarios x 300 yr) and the 23 plot validation, years-to-QMD grid. Compares v105c a2/out/*_parity_v105b.csv with the v105 job."""
import os, pandas as pd, numpy as np, json
V5 = os.path.expanduser("~/jobs/koa_v105_20261102"); VC = os.path.expanduser("~/jobs/koa_v105c_20261102"); rows = []
for a, b in (("a2/out/traj_parity_v105b.csv", "a2/out/traj_v104.csv"), ("a2/out/val_parity_v105b.csv", "a2/out/val_v104.csv"),
             ("v105c/out/years_grid_parity_v105b.csv", "a4/sens/years_grid_v104.csv")):
    A = pd.read_csv(f"{VC}/{a}"); B = pd.read_csv(f"{V5}/{b}"); A = A[[c for c in B.columns]]
    num = [c for c in B.columns if np.issubdtype(B[c].dtype, np.number)]
    same_shape = A.shape == B.shape; d = float(np.nanmax(np.abs(A[num].values - B[num].values))) if same_shape else float("nan")
    nonnum_equal = bool((A.drop(columns=num).astype(str).values == B.drop(columns=num).astype(str).values).all()) if same_shape else False
    rows.append(dict(file=a, reference=f"koa_v105_20261102/{b}", rows=len(A), max_abs_diff=d, nonnumeric_identical=nonnum_equal, pass_=bool(same_shape and d == 0.0 and nonnum_equal)))
R = pd.DataFrame(rows); print(R.to_string()); R.to_csv(f"{VC}/v105c/out/parity_engine.csv", index=False); print("PARITY_ENGINE", "PASS" if R.pass_.all() else "FAIL")
