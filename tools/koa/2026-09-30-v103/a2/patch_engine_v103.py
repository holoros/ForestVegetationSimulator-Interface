"""patch_engine_v103.py (2026-09-30, Stage A2). Patch engine_v103 (a copy of koa_v102_20260918/track2/engine_v102 that passed the 0.0
regression gate) with every constant of out/v103_constants.json that the engine carries. BAL: the engine's percentile path on the live
simulated list IS the live list percentile definition (l) the deployed dDBH constants and dHT_L_NO were solved and fitted on, so no
BAL_DEFINITION switch is added; BAL_COHORT_LIN_B takes the v103/l cohort row so the cohort path uses the same definition.
MORT_CAL is set to (1.0, 1.0) and re-solved afterwards (patch_mortcal_v103.py). Writes a2/out/patch_values_engine_v103.csv."""
import os, re, json, shutil, pandas as pd
A2 = os.path.dirname(os.path.abspath(__file__)); W = os.path.dirname(A2); E = f"{W}/engine_v103"
J = json.load(open(f"{W}/out/v103_constants.json")); rows = []
def rec(n, o, v): rows.append(dict(name=n, old=o, new=v))
def sub1(t, o, n):
    assert t.count(o) == 1, (o[:80], t.count(o)); return t.replace(o, n)
def dictline(name, d, c):
    return (f"    {name} = dict(b0={d['b0']:.7f}, b1={d['b1']:.7f}, b2={d['b2']:.7f}, b3={d['b3']:.7f},   # {c}\n"
            f"    {' ' * len(name)}   b4={d['b4']:.7f}, b5={d['b5']:.7f}, b6={d['b6']:.7f}, b7={d['b7']:.7f}, b8={d['b8']:.7f}, b9={d['b9']:.7f})\n")
DD, DH, HT = J["DDBH"], J["DHT"], J["HT_P"]
assert DD["deploy"] and DH["deploy"] and DD["bal_definition"] == DH["bal_definition"] == "live_list_percentile"
# ---------------- koa_equations.py
p = f"{E}/koa_equations.py"; t = open(p).read()
m = re.findall(r"    DDBH = dict\(b0=(-?[0-9.]+), b1=(-?[0-9.]+), b2=(-?[0-9.]+), b3=(-?[0-9.]+),.*?\n.*?b4=(-?[0-9.]+), b5=(-?[0-9.]+), b6=(-?[0-9.]+), b7=(-?[0-9.]+), b8=(-?[0-9.]+), b9=(-?[0-9.]+)\)", t, re.S)
assert len(m) >= 1; v102 = [float(x) for x in m[0]]
assert max(abs(v102[j] - DD["coef"][f"b{j}"]) for j in range(10)) < 5e-7, "engine DDBH is not the v102 vector"
rec("DDBH_vector", "v102 V3", "v102 V3 unchanged (Aaron 2026-09-30)")
pat_dh = re.compile(r"    DHT = dict\(b0=-3\.6114059.*?\n.*?b9=1\.0681935\)\n", re.S); assert len(pat_dh.findall(t)) == 1
dh = {k: float(v) for k, v in DH["coef"].items()}
t = pat_dh.sub(dictline("DHT", dh, "v103 dHT_L_NO (live list percentile BAL, NO frame, repaired covariates), deviation A1-D1, 2026-09-30"), t)
for j in range(10): rec(f"DHT_b{j}", None, dh[f"b{j}"])
old = "HT_P = dict(a0=32.198224, a1=1.208508, b=0.016579, c=0.804891, g1=0.062077, g2=-0.373262)   # v102 refit 2026-09-18, rDBH = DBH/DBH.max"
t = sub1(t, old, f"HT_P = dict(a0={HT['a0']:.6f}, a1={HT['a1']:.6f}, b={HT['b']:.6f}, c={HT['c']:.6f}, g1={HT['g1']:.6f}, g2={HT['g2']:.6f})   # v103 refit 2026-09-30 (repaired BAPH), rDBH = DBH/DBH.max")
for k in HT: rec(f"HT_{k}", None, HT[k])
open(p, "w").write(t)
# ---------------- koa_params.py
p = f"{E}/koa_params.py"; t = open(p).read()
def kp(name, new):
    global t
    L = re.findall(rf"^{name} = .*$", t, re.M); assert len(L) == 1, (name, L); t = sub1(t, L[0], f"{name} = {new}"); rec(name, L[0].split("=", 1)[1].strip()[:60], new)
assert re.findall(r"^CF_DDBH_MARGINAL = 1\.36869", t, re.M) and abs(DD["CF"] - 1.36869) < 1e-9
kp("CAL_DDBH", f"({DD['CAL'][0]:.5f}, {DD['CAL'][1]:.5f})   # c / CF, v102 vector with c re-solved on the v103 NO frame under live list BAL (c = {DD['c_natural']:.5f}, {DD['c_planted']:.5f}), 2026-09-30")
kp("CAL_DHT", f"({DH['CAL'][0]:.5f}, {DH['CAL'][1]:.5f})   # c / CF of dHT_L_NO (c = {DH['c_natural']:.5f}, {DH['c_planted']:.5f}), 2026-09-30")
kp("CAL_DDBH_SE_LOG", f"({DD['CAL_SE_LOG'][0]:.5f}, {DD['CAL_SE_LOG'][1]:.5f})   # SD of log c, 400 installation-cluster resamples within source, vector fixed, v103")
kp("CAL_DHT_SE_LOG", f"({DH['CAL_SE_LOG'][0]:.5f}, {DH['CAL_SE_LOG'][1]:.5f})   # SD of log c, vector fixed (full refit bootstrap: {DH['CAL_SE_LOG_full_refit'][0]:.3f}, {DH['CAL_SE_LOG_full_refit'][1]:.3f}), v103")
kp("CF_DHT", f"{DH['CF']:.5f}   # exp(0.5 (tau_source^2 + tau_inst^2)) of dHT_L_NO, 2026-09-30 (was 1.030 through v102)")
kp("MORT_CAL", "(1.0, 1.0)   # placeholder, re-solved by patch_mortcal_v103.py")
C = J["BAL_COHORT"]; assert C["definition"] == "l"
kp("BAL_COHORT_LIN_B", f"({C['a0']!r}, {C['a1']!r})   # live list percentile fraction, cohort_bal_fraction_v103.csv row v103/l, 2026-09-30")
G = J["GARCIA"]
kp("GARCIA_ALLOM_A", f"{G['GARCIA_ALLOM_A']!r}   # v103 M1 pair table, 2026-09-30")
kp("GARCIA_ALLOM_K_HD", f"{G['GARCIA_ALLOM_K_HD']!r}   # v103 M1 pair table, 2026-09-30")
kp("GARCIA_BETA_ANCHORED", f"{G['GARCIA_BETA_ANCHORED']!r}   # v103 live koa stems (>= 5), 100 / sqrt(z99), 2026-09-30")
I = J["ING"]
kp("ING_B0", f"{I['ING_B0']:.6f}   # v103 refit 2026-09-30"); kp("ING_B_SDI", f"{I['ING_B_SDI']:.9f}   # v103 refit 2026-09-30"); kp("ING_B_PLANTED", f"{I['ING_B_PLANTED']:.6f}   # v103 refit 2026-09-30")
open(p, "w").write(t)
# ---------------- Stage 1 / 2 json
s1 = dict(J["STAGE1"]); s1["stage1_auc"] = float(open(f"{W}/track2/stage1/stage1_auc_v103.txt").read())
json.dump(s1, open(f"{E}/out_stage1/stage1_fit.json", "w"), indent=2); rec("stage1_fit.json", "v102", "v103 (+ apparent AUC)")
# ---------------- height SEs in the MC drivers
SE = J["HT_P_SE"]
p2 = f"{E}/regen_m1.py"; t2 = open(p2).read()
t2 = sub1(t2, "SE = dict(ht_a0=1.519063, ht_a1=0.151297, ht_b=0.000956, ht_c=0.011408,", f"SE = dict(ht_a0={SE['a0']:.6f}, ht_a1={SE['a1']:.6f}, ht_b={SE['b']:.6f}, ht_c={SE['c']:.6f},"); open(p2, "w").write(t2)
p3 = f"{E}/regenerate_uneven_aged.py"; t3 = open(p3).read()
t3 = sub1(t3, "SE = dict(a0=1.519063, a1=0.151297, b=0.000956, c=0.011408,", f"SE = dict(a0={SE['a0']:.6f}, a1={SE['a1']:.6f}, b={SE['b']:.6f}, c={SE['c']:.6f},"); open(p3, "w").write(t3)
rec("HT_SE_regen_m1_and_uneven", "v102", "v103")
# ---------------- data tables (v103 repaired, engine column set)
tr = pd.read_csv(f"{E}/AK_TREE.csv", nrows=1).columns.tolist(); T = pd.read_csv(f"{W}/inputs/AK_TREE_v103.csv")
assert not ({"lat", "lon", "x", "y"} & set(c.lower() for c in T.columns)); T[tr].to_csv(f"{E}/AK_TREE.csv", index=False)
pl = pd.read_csv(f"{E}/AK_PLT.csv", nrows=1).columns.tolist(); P = pd.read_csv(f"{W}/inputs/AK_PLT_v103.csv"); P[pl].to_csv(f"{E}/AK_PLT.csv", index=False)
sv = pd.read_csv(f"{E}/AK_SURV.csv", nrows=1).columns.tolist(); S = pd.read_csv(f"{W}/frames/final/AK_SURV_v103.csv"); S[sv].to_csv(f"{E}/AK_SURV.csv", index=False)
rec("AK_TREE.csv", 17074, len(T)); rec("AK_PLT.csv", None, len(P)); rec("AK_SURV.csv", None, len(S))
pd.DataFrame(rows).to_csv(f"{A2}/out/patch_values_engine_v103.csv", index=False); print("engine_v103 patched,", len(rows), "entries")
