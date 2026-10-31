#!/usr/bin/env python3
"""Gate: lt_core.run_points and the tracked projector reproduce out_lt/LT_v98_points.csv and project_psp exactly."""
# a5/rerun copy (2026-10-31): inputs switched to the v104 engine copy (./engine = cp of engine_v103 without out_m1*),
# v104 mortality files a2/mort/v104 and gate a4/lt/LT_v104_points.csv. Logic otherwise verbatim from koa_origin_20260916/v100/trackB.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lt_core as C
import numpy as np, pandas as pd
pids = C.lt_pids(); print("LT plots", len(pids))
P_ = pd.concat([C.run_points(p) for p in pids], ignore_index=True)
ref = pd.read_csv(os.path.join("/home/aaron/jobs/koa_v104_20261030", "a4", "lt", "LT_v104_points.csv"))
import io
P_ = pd.read_csv(io.StringIO(P_.to_csv(index=False)))   # same CSV round trip as the reference file
P2 = P_.sort_values(["pid", "tk"]).reset_index(drop=True); R2 = ref.sort_values(["pid", "tk"]).reset_index(drop=True)
num = [c for c in R2.select_dtypes("number").columns if c in P2.columns]  # a5: LT_v104 adds obs_surv_w
d = float((P2[num].astype(float) - R2[num].astype(float)).abs().max().max())
print("run_points vs LT_v98 max abs diff", d, "shape", P2.shape, R2.shape)
assert d == 0.0 and (P2.pid == R2.pid).all()
mx = 0.0
for p in pids:
    S = C.setup(p); C.apply()
    h = int(round(S["meas"][-1] - S["t0"]))
    a = C.PR.project_psp(S["trees"], S["B"], S["planted"], "A", h, ingrowth=False)
    b = C.project_psp_tracked(S["trees"], S["B"], S["planted"], "A", h, ingrowth=False)
    assert not b["binned"]
    for k in ("TPH", "BAPH", "QMD"):
        mx = max(mx, abs(a[k] - b[k]))
    assert sorted(b["tid"]) == list(range(len(S["trees"])))
    print(p, "n0", len(S["trees"]), "n_ht_measured", int(S["ht_meas"].sum()), "meas", [float(m) for m in S["meas"]], "unique ids", len(S["ids0"]))
print("tracked vs project_psp max abs diff", mx)
assert mx == 0.0
C.KE.joint_assert_clean("gate end")
print("GATE PASS")
