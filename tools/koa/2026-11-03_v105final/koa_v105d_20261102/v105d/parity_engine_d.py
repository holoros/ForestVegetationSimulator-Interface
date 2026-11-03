#!/usr/bin/env python3
"""parity_engine_d.py: engine with the v105d code paths but every v105d switch at "v105b" must reproduce the v105c projections exactly:
a2 run_engine point path (six scenarios x 300 yr, run_candidates.project with Stage 3 tree_eq ordering, HCB, dHT, Eq. 2) and the 23 plot validation,
and the years-to-QMD grid. Compares koa_v105d a2/out/*_parity_v105c.csv with koa_v105c_20261102 (read only)."""
import os, pandas as pd, numpy as np
VC = os.path.expanduser("~/jobs/koa_v105c_20261102"); VD = os.path.expanduser("~/jobs/koa_v105d_20261102"); rows = []
for a, b in (("a2/out/traj_parity_v105c.csv", "a2/out/traj_v104.csv"), ("a2/out/val_parity_v105c.csv", "a2/out/val_v104.csv"),
             ("v105d/out/years_grid_parity_v105c.csv", "a4/sens/years_grid_v104.csv")):
    A = pd.read_csv(f"{VD}/{a}"); B = pd.read_csv(f"{VC}/{b}"); A = A[[c for c in B.columns]]
    num = [c for c in B.columns if np.issubdtype(B[c].dtype, np.number)]
    same_shape = A.shape == B.shape; d = float(np.nanmax(np.abs(A[num].values - B[num].values))) if same_shape else float("nan")
    nonnum_equal = bool((A.drop(columns=num).astype(str).values == B.drop(columns=num).astype(str).values).all()) if same_shape else False
    rows.append(dict(file=a, reference=f"koa_v105c_20261102/{b}", rows=len(A), max_abs_diff=d, nonnumeric_identical=nonnum_equal, pass_=bool(same_shape and d == 0.0 and nonnum_equal)))
R = pd.DataFrame(rows); print(R.to_string()); R.to_csv(f"{VD}/v105d/out/parity_engine.csv", index=False); print("PARITY_ENGINE", "PASS" if R.pass_.all() else "FAIL")
