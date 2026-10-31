#!/usr/bin/env python3
"""a5/loio/gate_check.py: compare val/val_<tag>_plotlevel.csv to a2/closeout/validation/val_v104_plotlevel.csv (read only). Writes gate_check.csv."""
import os, pandas as pd, numpy as np
W = os.path.expanduser("~/jobs/koa_v104_20261030"); L = f"{W}/a5/loio"
R = pd.read_csv(f"{W}/a2/closeout/validation/val_v104_plotlevel.csv").set_index("pid")
rows = []
for tag in ("V104EXACT", "NONE"):
    X = pd.read_csv(f"{L}/val/val_{tag}_plotlevel.csv").set_index("pid").reindex(R.index)
    for c in ("obs_surv_w", "pr_surv", "obsQMD", "prQMD", "obsBAPH", "prBAPH"):
        d = np.abs(X[c].to_numpy(float) - R[c].to_numpy(float))
        rows.append(dict(tag=tag, col=c, n=int(np.isfinite(d).sum()), max_abs_diff=float(np.nanmax(d)), pass_1e3=bool(np.nanmax(d) < 1e-3)))
G = pd.DataFrame(rows); G.to_csv(f"{L}/gate_check.csv", index=False); print(G.to_string())
