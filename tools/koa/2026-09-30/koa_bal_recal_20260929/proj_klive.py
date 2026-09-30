"""proj_klive.py. Deterministic sensitivity of the deployed engine (engine_v102, M1 via regen_m1) to origin multipliers
recalibrated under the engine's own live-list BAL (bal_recal.R, coefficients of Eq. 4 fixed). Nothing in the engine
directory is edited; multipliers are set through LineageA.CAL_DDBH / CAL_DHT, the same configuration point cal_draw() uses.
The natural mortality level factor is held at its deployed value (2.646); it was solved under the deployed multipliers."""
import os, sys
import numpy as np, pandas as pd
ENG = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102")
OUT = os.path.expanduser("~/jobs/koa_bal_recal_20260929/out"); os.makedirs(OUT, exist_ok=True)
sys.path.insert(0, ENG); os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplc")
import koa_params as P, koa_equations as KE, run_candidates as RC, regen_m1 as RM
import koa_longterm_validation as V
K = pd.read_csv(os.path.join(OUT, "k_by_bal.csv")).set_index(["resp", "bal"])
SET = {"deployed": (P.CAL_DDBH, P.CAL_DHT),
       "live": ((K.loc[("dDBH","live"),"k_nat"], K.loc[("dDBH","live"),"k_plt"]), (K.loc[("dHT","live"),"k_nat"], K.loc[("dHT","live"),"k_plt"]))}
print("deployed", P.CAL_DDBH, P.CAL_DHT, "live", SET["live"], flush=True)
_cache = V.load(); V.load = lambda: _cache; V.stand_mortality = RM._gated
rows = []; val = []
for name, (dd, dh) in SET.items():
    for planted in (False, True):
        for byi in (100, 264, 450):
            RM.set_params(None); KE.joint_assert_clean("pre")
            KE.LineageA.CAL_DDBH = tuple(dd); KE.LineageA.CAL_DHT = tuple(dh)
            d = RC.project(RC.wlist(int(planted), byi), byi, planted, 100, "M0")
            KE.LineageA.CAL_DDBH = P.CAL_DDBH; KE.LineageA.CAL_DHT = P.CAL_DHT; RM.set_params(None)
            d = d.assign(setting=name, planted=int(planted), byi=byi); rows.append(d)
    RM.set_params(None); KE.LineageA.CAL_DDBH = tuple(dd); KE.LineageA.CAL_DHT = tuple(dh)
    v = V.validate(); v = v.assign(setting=name); val.append(v)
    KE.LineageA.CAL_DDBH = P.CAL_DDBH; KE.LineageA.CAL_DHT = P.CAL_DHT; RM.set_params(None); KE.joint_assert_clean("post")
    print("done", name, flush=True)
A = pd.concat(rows, ignore_index=True); A.to_csv(os.path.join(OUT, "traj_klive.csv"), index=False)
Vv = pd.concat(val, ignore_index=True); Vv.to_csv(os.path.join(OUT, "validation_klive_KEYED_SERVERSIDE.csv"), index=False)
print(A.columns.tolist())
