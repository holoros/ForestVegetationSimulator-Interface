"""Run the Table 8 point path (six even-aged scenarios, 300 y, M0 point projection under the M1 gated
mortality set-up of regen_m1) and the 23 plot validation in one engine copy, exactly as
koa_origin_20260916/v100/trackC3/C3d_hcb_run.py. Usage: python3 run_engine.py <engine_dir> <tag>.
Writes out/traj_<tag>.csv and out/val_<tag>.csv. For tag deployed it gates against
output/engine_joint/out_m1 (table8 at 2 dp, traj_M1 and validation_M1 to 1e-9)."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]
REF = os.path.expanduser("~/jobs/koa_origin_20260916/output/engine_joint/out_m1")
OUT = os.path.join(HERE, "out"); os.makedirs(OUT, exist_ok=True)
sys.path.insert(0, ENG)
os.environ.setdefault("MPLCONFIGDIR", os.path.join(ENG, ".mplcache"))
_cwd = os.getcwd()
import regen_m1 as RM
import run_candidates as RC
import koa_equations as KE
import koa_params as KP
import numpy as np, pandas as pd
os.chdir(ENG)
import koa_longterm_validation as V
os.chdir(_cwd)
print(TAG, "engine", ENG, flush=True)
print(TAG, "DDBH", KE.LineageA.DDBH, flush=True)
print(TAG, "DHT", KE.LineageA.DHT, flush=True)
print(TAG, "CF_DDBH", KE.LineageA.CF_DDBH, "CF_DHT", KE.LineageA.CF_DHT, "CAL_DDBH", KE.LineageA.CAL_DDBH, "CAL_DHT", KE.LineageA.CAL_DHT, flush=True)
print(TAG, "KP CF_DDBH_MARGINAL", KP.CF_DDBH_MARGINAL, "CF_DHT", KP.CF_DHT, "CAL_DDBH", KP.CAL_DDBH, "CAL_DHT", KP.CAL_DHT, flush=True)
rows = []
for tag, planted, byi, site in RC.SCEN:
    RM.set_params(None)
    os.chdir(ENG)
    try:
        d = RC.project(RC.wlist(planted, byi), byi, bool(planted), 300, "M0")
    finally:
        os.chdir(_cwd)
    d = d.copy(); d.insert(0, "site", site); d.insert(0, "byi", byi); d.insert(0, "planted", planted)
    rows.append(d)
    print(TAG, tag, byi, "done", flush=True)
TR = pd.concat(rows, ignore_index=True)
TR.to_csv(os.path.join(OUT, f"traj_{TAG}.csv"), index=False)
V.stand_mortality = RM._gated
RM.set_params(None)
os.chdir(ENG)
try:
    r = V.validate()
finally:
    os.chdir(_cwd)
r.to_csv(os.path.join(OUT, f"val_{TAG}.csv"), index=False)
if TAG == "deployed":
    T = pd.read_csv(os.path.join(REF, "table8_evenaged_M1.csv"))
    TRr = pd.read_csv(os.path.join(REF, "traj_M1.csv"))
    w8 = 0.0; wtr = 0.0
    for tag, planted, byi, site in RC.SCEN:
        d = TR[(TR.planted == planted) & (TR.byi == byi)].set_index("year")
        ref = TRr[(TRr.planted == planted) & (TRr.byi == byi)].set_index("year")
        cols = [c for c in ref.columns if c in d.columns and c not in ("origin", "planted", "byi", "site")]
        wtr = max(wtr, float(np.nanmax(np.abs(d.loc[ref.index, cols].to_numpy(float) - ref[cols].to_numpy(float)))))
        lab = "Even-aged natural" if planted == 0 else "Even-aged planted"
        for a in (20, 40, 60, 100):
            rr = T[(T.Scenario == lab) & (T.Site == f"{site} ({byi})") & (T.Age == a)].iloc[0]; q = d.loc[a]
            for v, val in (("QMD", q.QMD), ("HT", q.HT), ("BAPH", q.BAPH), ("TPH", q.TPH), ("VOL", q.VOL), ("MAI", q.VOL / a)):
                w8 = max(w8, abs(round(float(val), 2) - rr[v]))
    vref = pd.read_csv(os.path.join(REF, "validation_M1.csv"))
    num = [c for c in vref.columns if c != "pid"]
    wv = float(np.nanmax(np.abs(r[num].to_numpy(float) - vref[num].to_numpy(float))))
    ok = w8 == 0 and wtr < 1e-9 and wv < 1e-9 and len(r) == len(vref)
    print(f"GATE table8 max|diff| (2 dp) {w8}; traj_M1 max|diff| {wtr:.3e}; validation_M1 max|diff| {wv:.3e} (n {len(r)} vs {len(vref)}); {'PASS' if ok else 'FAIL'}", flush=True)
print(TAG, "done", flush=True)
