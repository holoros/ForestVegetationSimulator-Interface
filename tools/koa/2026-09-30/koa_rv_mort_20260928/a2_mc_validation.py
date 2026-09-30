#!/usr/bin/env python3
"""a2_mc_validation.py  koa R1 c14. Monte Carlo replicate projections of the 23-plot validation
through the deployed engine_v102 (engine of record M1 as installed by regen_m1 at import), reusing
the joint-draw table out_joint/K_joint_draws.csv (seed 20260918, 500 rows) and the regen_m1
set_params() convention (independent-draw generator default_rng(42), CF generator 42+7919), exactly
as table8_evenaged() uses them for the first scenario. Also point runs with and without the natural
level factor. Nothing in the engine directory is written (PYTHONDONTWRITEBYTECODE=1 required).
Usage: python3 a2_mc_validation.py N_REPS
"""
import os, sys, time, json
JOB = os.path.dirname(os.path.abspath(__file__))
ENG = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102")
assert os.environ.get("PYTHONDONTWRITEBYTECODE") == "1"
sys.path.insert(0, ENG)
import numpy as np, pandas as pd
import regen_m1 as R                      # installs M1 gate + MORT_CAL (chdir to ENG)
import koa_params as P, koa_equations as KE
import koa_longterm_validation as V
N = int(sys.argv[1]) if len(sys.argv) > 1 else 500
OUT = os.path.join(JOB, "out_a2"); os.makedirs(OUT, exist_ok=True)
_cache = V.load(); V.load = lambda: _cache
V.stand_mortality = R._gated

def run():
    r = V.validate()
    return r[["pid", "ny", "planted", "obs_surv", "pr_surv", "obsQMD", "prQMD", "obsBAPH", "prBAPH"]]

t0 = time.time()
R.set_params(None); R.assert_clean("start")
pt = run(); print("point run plots", len(pt), "%.1fs" % (time.time() - t0), flush=True)
ref = pd.read_csv(os.path.join(ENG, "out_m1", "validation_M1.csv"))
m = pt.merge(ref, on="pid", suffixes=("", "_ref"))
gate = max(float(np.max(np.abs(m[c] - m[c + "_ref"]))) for c in ("pr_surv", "prQMD", "prBAPH"))
print("GATE point vs out_m1/validation_M1.csv max abs diff", gate, flush=True)
assert len(m) == 23 and gate < 1e-9
pt.to_csv(os.path.join(OUT, "point_with_level.csv"), index=False)
KP = P
KP.MORT_CAL_LIVE[0] = 1.0
nf = run(); nf.to_csv(os.path.join(OUT, "point_no_level.csv"), index=False)
KP.MORT_CAL_LIVE[:] = list(KP.MORT_CAL)
R.set_params(None); R.assert_clean("after no-level")
print("no-level point run done %.1fs" % (time.time() - t0), flush=True)

rng = np.random.default_rng(R.SEED)
R._CFCLIP[0] = 0
fh = open(os.path.join(OUT, "reps_validation.csv"), "w"); first = True
for i in range(N):
    R.set_params(rng)
    d = run(); d["rep"] = i
    d.to_csv(fh, header=first, index=False); first = False; fh.flush()
    if i % 10 == 0:
        print("rep", i, "plots", len(d), "%.0fs" % (time.time() - t0), flush=True)
fh.close()
R.set_params(None); R.assert_clean("end")
print("DONE reps", N, "cf clipped", R._CFCLIP[0], "wall %.0fs" % (time.time() - t0), flush=True)
