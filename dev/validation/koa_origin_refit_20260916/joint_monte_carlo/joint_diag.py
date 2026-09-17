"""joint_diag.py ENGINE_DIR OUTCSV: spread of the deployed increment and mortality rates at a reference tree and stand
under the joint rows (v99) against the independent draws of v98 (b8 of each increment equation plus lognormal multipliers
and mortality factor). Reference tree: DBH 20 cm, height 12 m, BAPH 20 m2 ha-1, BAL 10 m2 ha-1, CR 0.5, BYI 264; reference
stand rate: Garcia rate 0.02 yr-1 at SDI 400. The diameter CF draw is common to both schemes and omitted. vector_only holds the
multipliers at their point values while the coefficient vectors take the joint rows; between_source_share is the share of the
log variance lying between source combinations."""
import sys, os, numpy as np, pandas as pd
E, O = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
sys.path.insert(0, E); os.chdir(E)
import koa_equations as KE, koa_params as P, threestage as TS
L = KE.LineageA
def ref():
    out = []
    for pl in (0, 1):
        out.append(float(L.dDBH(np.array([20.0]), 20.0, np.array([10.0]), np.array([0.5]), 264.0, pl)[0]))
        out.append(float(L.dHT(np.array([12.0]), 20.0, np.array([10.0]), np.array([0.5]), 264.0, pl)[0]))
    out.append(TS.rate_M1(0.02, 400, 0) * TS.mort_cal(0)); out.append(TS.rate_M1(0.02, 400, 1) * TS.mort_cal(1))
    return out
lab = ["dDBH natural", "dHT natural", "dDBH planted", "dHT planted", "mortality natural", "mortality planted"]
KE.cal_reset(); base = ref(); D0, H0 = L.DDBH["b8"], L.DHT["b8"]
nrow = len(KE._joint_rows()); src = [r["sources"] for r in KE._joint_rows()]
J = []; VO = []
for i in range(nrow):
    KE.cal_draw(); J.append(ref())
    cd, ch, mk = L.CAL_DDBH, L.CAL_DHT, P.MORT_CAL_LIVE[0]
    L.CAL_DDBH, L.CAL_DHT = P.CAL_DDBH, P.CAL_DHT   # vector drawn, multipliers held at their point values
    VO.append(ref())
    L.CAL_DDBH, L.CAL_DHT = cd, ch
KE.cal_reset(); J = np.array(J); VO = np.array(VO)
rng = np.random.default_rng(20260918); V = []; B8 = []
for i in range(nrow):
    z = rng.standard_normal(7)
    L.DDBH["b8"] = D0 + 0.0820 * z[5]; L.DHT["b8"] = H0 + 0.0799 * z[6]
    L.CAL_DDBH = (P.CAL_DDBH[0] * np.exp(P.CAL_DDBH_SE_LOG[0] * z[0]), P.CAL_DDBH[1] * np.exp(P.CAL_DDBH_SE_LOG[1] * z[2]))
    L.CAL_DHT = (P.CAL_DHT[0] * np.exp(P.CAL_DHT_SE_LOG[0] * z[1]), P.CAL_DHT[1] * np.exp(P.CAL_DHT_SE_LOG[1] * z[3]))
    P.MORT_CAL_LIVE[0] = P.MORT_CAL[0] * np.exp(P.MORT_CAL_SE_LOG[0] * z[4])
    V.append(ref())
    KE.cal_reset(); L.DDBH["b8"] = D0; L.DHT["b8"] = H0
    L.DDBH["b8"] = D0 + 0.0820 * z[5]; L.DHT["b8"] = H0 + 0.0799 * z[6]; B8.append(ref())
    L.DDBH["b8"] = D0; L.DHT["b8"] = H0
KE.cal_reset(); V = np.array(V); B8 = np.array(B8)
rows = []
for k in range(6):
    q = lambda a: np.percentile(a[:, k], [2.5, 97.5])
    rows.append(dict(quantity=lab[k], base=base[k], joint_lo=q(J)[0], joint_hi=q(J)[1], joint_sdlog=float(np.std(np.log(J[:, k]))),
                     vector_only_sdlog=float(np.std(np.log(VO[:, k]))),
                     between_source_share=float(pd.Series(np.log(J[:, k])).groupby(pd.Series(src)).transform("mean").var() / np.log(J[:, k]).var()),
                     indep_lo=q(V)[0], indep_hi=q(V)[1], indep_sdlog=float(np.std(np.log(V[:, k]))), indep_b8_only_sdlog=float(np.std(np.log(B8[:, k])))))
R = pd.DataFrame(rows); R.to_csv(O, index=False); print(R.round(4).to_string())
