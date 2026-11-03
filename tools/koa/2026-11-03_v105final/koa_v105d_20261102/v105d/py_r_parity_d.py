#!/usr/bin/env python3
"""py_r_parity_d.py: Python engine (engine_v103, deployed v105d) vs R (py_r_parity_d.R) for each component; writes v105d/out/parity_py_r.csv.
Increments: engine L.dDBH / L.dHT divided by CF x CAL (rows where the annual cap binds excluded) vs the inc_v103.R recursion. Eq. 2: engine predict_HT with rd = R's RD
(rows above the 1.37 m floor) and, separately, RD rebuilt by the engine from (BAPH, QMD) of the plot-year vs the R RD. Eq. 3: predict_HCB(rd=) vs R (the engine
caps at 0.95 HT, rows below the cap). Stage 3: stage3_w with sdi giving the R RD vs R."""
import os, sys, numpy as np, pandas as pd
E = os.path.expanduser("~/jobs/koa_v105d_20261102/engine_v103"); sys.path.insert(0, E); os.chdir(E); O = "../v105d/out"
import koa_params as KP, koa_equations as KE, koa_projector as PR
L = KE.LineageA; rows = []
import json; J = json.load(open("../out/v105_constants.json"))
FULL = {"dDBH": {k: float(v) for k, v in J["DDBH"]["coef"].items()}, "dHT": {k: float(v) for k, v in J["DHT"]["coef"].items()}, "HT": {k: float(v) for k, v in J["HT_P"].items()}}
def rec(chk, n, v, tol): rows.append(dict(check=chk, rows=int(n), max_rel_diff=float(v), tol=tol, pass_=bool(v < tol)))
for resp, fn in (("dDBH", L.dDBH), ("dHT", L.dHT)):
    D = pd.read_csv(f"{O}/pyr_{resp}.csv"); sdi = PR.sdi_of(D["TPH.0"].values, D["QMD.0"].values)
    cal = np.where(D.Planted.values == 1, (L.CAL_DDBH if resp == "dDBH" else L.CAL_DHT)[1], (L.CAL_DDBH if resp == "dDBH" else L.CAL_DHT)[0]); CF = L.CF_DDBH if resp == "dDBH" else L.CF_DHT
    size = D["DBH.0"].values if resp == "dDBH" else D["HT.0"].values
    full = fn(size, D["BAPH.0"].values, D["BALx.0"].values, D["CRx.0"].values, D["BYI"].values, D["Planted"].values, sdi=sdi)
    ok = full < (L.ddbh_cap if resp == "dDBH" else L.dht_cap) - 1e-12; py = full / (CF * cal)
    rec(f"INFO {resp} engine with its printed (7 dp) vector vs recursion with the full-precision vector", ok.sum(), np.max(np.abs(py[ok] / D.r_inc.values[ok] - 1)), 1e-5)
    dct = L.DDBH if resp == "dDBH" else L.DHT; keep = dict(dct); dct.update(FULL[resp])
    full = fn(size, D["BAPH.0"].values, D["BALx.0"].values, D["CRx.0"].values, D["BYI"].values, D["Planted"].values, sdi=sdi); dct.update(keep)
    ok = full < (L.ddbh_cap if resp == "dDBH" else L.dht_cap) - 1e-12; py = full / (CF * cal)
    rec(f"{resp} ({KP.DDBH_FORM if resp == 'dDBH' else KP.DHT_FORM}) engine code with the full-precision vector vs inc_v103.R recursion, one annual step", ok.sum(), np.max(np.abs(py[ok] / D.r_inc.values[ok] - 1)), 1e-9)
H = pd.read_csv(f"{O}/pyr_height.csv")
py = KE.predict_HT(H.dbh.values, H.baph.values, np.full(len(H), 20.0), H.byi.values, dbhmax=H.dbhmax.values, rd=H.RD.values); ok = H.r_ht.values > 1.37
rec("INFO Eq. 2 engine with its printed (6 dp) HT_P vs R with the full-precision vector", ok.sum(), np.max(np.abs(py[ok] / H.r_ht.values[ok] - 1)), 1e-4)
keep = dict(KE.HT_P); KE.HT_P.update(FULL["HT"]); py = KE.predict_HT(H.dbh.values, H.baph.values, np.full(len(H), 20.0), H.byi.values, dbhmax=H.dbhmax.values, rd=H.RD.values); KE.HT_P.update(keep)
rec("Eq. 2 H1a predict_HT(rd = R RD), full-precision vector, vs R formula", ok.sum(), np.max(np.abs(py[ok] / H.r_ht.values[ok] - 1)), 1e-9)
ok2 = np.isfinite(H.QMDs.values) & (H.QMDs.values > 0)
rdpy = KE.rd_from_sdi(PR.sdi_of(H.TPHs.values[ok2], H.QMDs.values[ok2]))
rec("RD rebuilt by the engine from plot-year TPH, QMD vs R RD (SDI_qmd/923)", ok2.sum(), np.max(np.abs(rdpy / H.RD.values[ok2] - 1)), 1e-9)
C = pd.read_csv(f"{O}/pyr_hcb.csv"); py = KE.predict_HCB(C.DBH.values, C.HT.values, C.BALl.values, C.BAPH_hi.values, C.BYI.values, rd=C.RD.values); ok = C.r_hcb.values < 0.95 * C.HT.values
rec("Eq. 3 C2h predict_HCB(rd = R RD) vs R formula", ok.sum(), np.max(np.abs(py[ok] / C.r_hcb.values[ok] - 1)), 1e-9)
S = pd.read_csv(f"{O}/pyr_stage3.csv"); sdi = S.RD.values * KP.DDBH_RD_SDIMAX / (KP.INDEX_DIAMETER_CM / KP.DDBH_RD_INDEX_DIAMETER_CM) ** KP.SDI_OF_EXPONENT
py = KE.stage3_w(S.dbh.values, S.rht.values, S.baph.values, S.bal.values, sdi); ok = (S.r_w.values > 1e-9) & (S.RD.values >= KP.RD_FLOOR_STAGE3)
rec("Stage 3 M3a stage3_w vs R glm formula (ln YIP = 0)", ok.sum(), np.max(np.abs(py[ok] / S.r_w.values[ok] - 1)), 1e-9)
R = pd.DataFrame(rows); print(R.to_string()); R.to_csv(f"{O}/parity_py_r.csv", index=False); print("PARITY_PY_R", "PASS" if R.pass_.all() else "FAIL")
