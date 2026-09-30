"""patch_engine_refit.py (2026-09-29, koa_refit_20260929). Modeled on track2/patch_engine_v102.py. Patch an engine copy that already
carries the BAL_DEFINITION switch (patch_bal_switch.py) with the 29 September 2026 refit of Eq. 4 on all valid remeasurement intervals.
  engine_refit       arm "c": conventional BAL, fits dDBH_c_AP and dHT_c_AP, cohort fraction row bal == c, BAL_DEFINITION = "conventional".
  engine_refit_live  arm "l": live-list percentile BAL (what the engine already computes), fits dDBH_l_AP and dHT_l_AP, cohort row bal == l
                     written into BAL_COHORT_LIN_B, BAL_DEFINITION stays "percentile". Sensitivity arm only.
Constants: DDBH and DHT dicts (b0..b9, same functional form), CF_DDBH_MARGINAL = cf_source_inst of the dDBH fit, CF_DHT = cf_source_inst of
the dHT fit (v102 kept 1.030), CAL_DDBH = (c_natural, c_planted) / CF, CAL_DHT likewise (fit_stats k_natural, k_planted are exactly that),
CAL_*_SE_LOG from out/c_bootstrap.csv when it exists (else the v102 values are kept as PLACEHOLDERS and flagged), MORT_CAL reset to
(1.0, 1.0) for the level recalibration (patch_mortcal_refit.py), and the HiGy.R mirror (ddbh.parm / dht.parm site rows, b9 column, cf,
origin multipliers, conventional BAL already in calc_bal). Writes out/patch_values_<engine>.csv. Usage: python3 patch_engine_refit.py <engine> <arm>."""
import os, re, sys, json, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "out")
eng, arm = sys.argv[1], sys.argv[2]; E = os.path.join(HERE, eng)
CO = pd.read_csv(f"{OUT}/coefficients.csv"); ST = pd.read_csv(f"{OUT}/fit_stats.csv"); CB = pd.read_csv(f"{OUT}/cohort_bal_fraction.csv")
BOOT = pd.read_csv(f"{OUT}/c_bootstrap.csv") if os.path.exists(f"{OUT}/c_bootstrap.csv") else None
def vec(fit):
    c = CO[CO.fit == fit].set_index("term"); return {f"b{j}": float(c.estimate[f"b{j}"]) for j in range(10)}
def stat(fit): return ST[ST.fit == fit].iloc[0]
def sub1(txt, old, new):
    assert txt.count(old) == 1, (old[:70], txt.count(old)); return txt.replace(old, new)
def dictline(name, d, comment):
    return (f"    {name} = dict(b0={d['b0']:.7f}, b1={d['b1']:.7f}, b2={d['b2']:.7f}, b3={d['b3']:.7f},   # {comment}\n"
            f"    {' ' * len(name)}   b4={d['b4']:.7f}, b5={d['b5']:.7f}, b6={d['b6']:.7f}, b7={d['b7']:.7f}, b8={d['b8']:.7f}, b9={d['b9']:.7f})\n")
fd, fh = f"dDBH_{arm}_AP", f"dHT_{arm}_AP"
dd, dh = vec(fd), vec(fh); sd, sh = stat(fd), stat(fh)
cf_dd, cf_dh = float(sd.cf_source_inst), float(sh.cf_source_inst)
cal_dd = (float(sd.c_natural) / cf_dd, float(sd.c_planted) / cf_dd); cal_dh = (float(sh.c_natural) / cf_dh, float(sh.c_planted) / cf_dh)
assert abs(cal_dd[0] - sd.k_natural) < 1e-9 and abs(cal_dh[1] - sh.k_planted) < 1e-9
def selog(fit, origin, fallback):
    if BOOT is None or not ((BOOT.fit == fit) & (BOOT.origin == origin)).any(): return fallback, "PLACEHOLDER_v102"
    return float(BOOT[(BOOT.fit == fit) & (BOOT.origin == origin)].selog.iloc[0]), "c_bootstrap.csv"
se_dd = (selog(fd, "natural", 0.07956), selog(fd, "planted", 0.05225)); se_dh = (selog(fh, "natural", 0.14862), selog(fh, "planted", 0.04807))
cb = CB[CB.bal == arm].iloc[0]; a0, a1 = float(cb.a0), float(cb.a1)
old = {}; rows = []
def rec(name, new, o): rows.append(dict(engine=eng, name=name, old=o, new=new))
# ---- koa_equations.py
p = os.path.join(E, "koa_equations.py"); txt = open(p).read()
pat_dd = re.compile(r"    DDBH = dict\(b0=(-?[0-9.]+), b1=(-?[0-9.]+), b2=(-?[0-9.]+), b3=(-?[0-9.]+),.*?\n.*?b4=(-?[0-9.]+), b5=(-?[0-9.]+), b6=(-?[0-9.]+), b7=(-?[0-9.]+), b8=(-?[0-9.]+), b9=(-?[0-9.]+)\)\n", re.S)
pat_dh = re.compile(r"    DHT = dict\(b0=(-?[0-9.]+), b1=(-?[0-9.]+), b2=(-?[0-9.]+), b3=(-?[0-9.]+),.*?\n.*?b4=(-?[0-9.]+), b5=(-?[0-9.]+), b6=(-?[0-9.]+), b7=(-?[0-9.]+), b8=(-?[0-9.]+), b9=(-?[0-9.]+)\)\n", re.S)
m_dd, m_dh = pat_dd.findall(txt), pat_dh.findall(txt); assert len(m_dd) == 1 and len(m_dh) == 1
for j in range(10): rec(f"DDBH_b{j}", dd[f"b{j}"], float(m_dd[0][j])); rec(f"DHT_b{j}", dh[f"b{j}"], float(m_dh[0][j]))
tag = "conventional BAL" if arm == "c" else "live-list percentile BAL (sensitivity)"
txt = pat_dd.sub(dictline("DDBH", dd, f"refit {fd}, all valid intervals, {tag}, 2026-09-29"), txt)
txt = pat_dh.sub(dictline("DHT", dh, f"refit {fh}, all valid intervals, {tag}, 2026-09-29"), txt)
open(p, "w").write(txt)
# ---- koa_params.py
p = os.path.join(E, "koa_params.py"); txt = open(p).read()
def kp(name, newval_str, newval, regex=None):
    global txt
    m = re.findall(rf"^{name} = (.+?)(?:\s+#.*)?$", txt, re.M); assert len(m) == 1, (name, m)
    line = re.findall(rf"^{name} = .*$", txt, re.M)[0]
    txt = sub1(txt, line, f"{name} = {newval_str}"); return m[0]
o = kp("CAL_DDBH", f"({cal_dd[0]:.5f}, {cal_dd[1]:.5f})   # origin calibration (natural, planted) = c / CF, refit {fd}, 2026-09-29", cal_dd)
rec("CAL_DDBH_natural", cal_dd[0], o); rec("CAL_DDBH_planted", cal_dd[1], o)
o = kp("CAL_DHT", f"({cal_dh[0]:.5f}, {cal_dh[1]:.5f})   # refit {fh}, 2026-09-29", cal_dh); rec("CAL_DHT_natural", cal_dh[0], o); rec("CAL_DHT_planted", cal_dh[1], o)
o = kp("CAL_DDBH_SE_LOG", f"({se_dd[0][0]:.5f}, {se_dd[1][0]:.5f})   # installation-cluster bootstrap SD of log c, source {se_dd[0][1]}", None)
rec("CAL_DDBH_SE_LOG_natural", se_dd[0][0], o); rec("CAL_DDBH_SE_LOG_planted", se_dd[1][0], o)
o = kp("CAL_DHT_SE_LOG", f"({se_dh[0][0]:.5f}, {se_dh[1][0]:.5f})   # source {se_dh[0][1]}", None); rec("CAL_DHT_SE_LOG_natural", se_dh[0][0], o); rec("CAL_DHT_SE_LOG_planted", se_dh[1][0], o)
o = kp("CF_DDBH_MARGINAL", f"{cf_dd:.5f}   # exp(0.5 (tau_source^2 + tau_inst^2)) of {fd}, 2026-09-29", cf_dd); rec("CF_DDBH_MARGINAL", cf_dd, o)
o = kp("CF_DHT", f"{cf_dh:.5f}   # exp(0.5 (tau_source^2 + tau_inst^2)) of {fh}, 2026-09-29 (was 1.030 through v102)", cf_dh); rec("CF_DHT", cf_dh, o)
o = kp("MORT_CAL", "(1.0, 1.0)   # natural mortality level calibration (natural, planted) on the M1 stand rate, 2026-09-16", None); rec("MORT_CAL_natural_placeholder", 1.0, o)
o = kp("MORT_CAL_SE_LOG", "(0.19069, 0.0)", None); rec("MORT_CAL_SE_LOG_natural_placeholder", 0.19069, o)
if arm == "c":
    o = kp("BAL_DEFINITION", '"conventional"', None); rec("BAL_DEFINITION", "conventional", o.strip('"'))
    o = kp("BAL_COHORT_LIN_B_CONVENTIONAL", f"({a0!r}, {a1!r})", None); rec("BAL_COHORT_LIN_B_CONVENTIONAL_a0", a0, o); rec("BAL_COHORT_LIN_B_CONVENTIONAL_a1", a1, o)
else:
    o = kp("BAL_COHORT_LIN_B", f"({a0!r}, {a1!r})   # live-list percentile fraction, row bal == l of cohort_bal_fraction.csv, 2026-09-29", None)
    rec("BAL_COHORT_LIN_B_a0", a0, o); rec("BAL_COHORT_LIN_B_a1", a1, o)
open(p, "w").write(txt)
# ---- HiGy.R mirror
p = os.path.join(E, "HiGy.R"); t = open(p).read()
def trib(name, d, b8base):
    return (f"  {name} = dplyr::tribble(\n"
            f"    ~type,    ~species,  ~b0,        ~b1,         ~b2,         ~b3,         ~b4,        ~b5,         ~b6,        ~b7,        ~b8,        ~b9,\n"
            f"    'base',    'AK',   {d['b0']:.7f}, {d['b1']:.7f}, {d['b2']:.7f}, {d['b3']:.7f}, {d['b4']:.7f}, {d['b5']:.7f}, {d['b6']:.7f}, {d['b7']:.7f},        0, {d['b9']:.7f},\n"
            f"    'site',    'AK',   {d['b0']:.7f}, {d['b1']:.7f}, {d['b2']:.7f}, {d['b3']:.7f}, {d['b4']:.7f}, {d['b5']:.7f}, {d['b6']:.7f}, {d['b7']:.7f}, {d['b8']:.7f}, {d['b9']:.7f})\n")
pd_old = re.compile(r"  ddbh\.parm = dplyr::tribble\(\n.*?0\.4530166\)\n", re.S); ph_old = re.compile(r"dht\.parm = dplyr::tribble\(\n.*?0\.433224\)\n", re.S)
assert len(pd_old.findall(t)) == 1 and len(ph_old.findall(t)) == 1
t = pd_old.sub(trib("ddbh.parm", dd, 0) + f"  # refit {fd}, all valid intervals, {tag}, 2026-09-29; b9 = planted level shift; mirrors koa_equations.LineageA.DDBH\n", t)
t = ph_old.sub(trib("dht.parm", dh, 0).lstrip() + f"# refit {fh}, all valid intervals, {tag}, 2026-09-29; b9 = planted level shift; mirrors koa_equations.LineageA.DHT\n", t)
t = sub1(t, "ddbh = function(dbh, bal, ba, cr, byi, planted,\n                b0, b1, b2, b3, b4, b5, b6, b7, b8) {\n\n  cf = 1.026   # Duan (1983) smearing correction factor\n",
         "ddbh = function(dbh, bal, ba, cr, byi, planted,\n                b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0) {\n\n  cf = KOA_CF_DDBH * ifelse(planted == 1, KOA_CAL_DDBH[2], KOA_CAL_DDBH[1])   # CF x origin calibration, mirrors koa_equations, 2026-09-29\n")
t = sub1(t, "               b7 * planted * pmin(dbh, 40) +\n               b8 * log(pmax(byi, 1))) *cf\n",
         "               b7 * planted * pmin(dbh, KOA_DDBH_PLANTED_GUARD_CM) +\n               b8 * log(pmax(byi, 1)) + b9 * planted) *cf\n")
t = sub1(t, "dht = function(dbh, ht, bal, ba, cr, byi, planted,\n               b0, b1, b2, b3, b4, b5, b6, b7, b8) {\n\n\n  cf = 1.030   # Duan (1983) smearing correction factor\n",
         "dht = function(dbh, ht, bal, ba, cr, byi, planted,\n               b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0) {\n\n\n  cf = KOA_CF_DHT * ifelse(planted == 1, KOA_CAL_DHT[2], KOA_CAL_DHT[1])   # CF x origin calibration, mirrors koa_equations, 2026-09-29\n")
t = sub1(t, "              b7 * sqrt(planted * pmin(ht, 20)) +\n              b8 * log(pmax(byi, 1))) *cf\n",
         "              b7 * planted * pmin(ht, 20) +   # fitted linear form, as koa_equations.LineageA.dHT, 2026-09-29\n              b8 * log(pmax(byi, 1)) + b9 * planted) *cf\n")
t = sub1(t, "                  b8 = ddbh.parm$b8[idx],\n", "                  b8 = ddbh.parm$b8[idx],\n                  b9 = ddbh.parm$b9[idx],\n")
t = sub1(t, "                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8)),\n", "                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)),\n")
t = sub1(t, "                  b8 = dht.parm$b8[idx],\n", "                  b8 = dht.parm$b8[idx],\n                  b9 = dht.parm$b9[idx],\n")
t = sub1(t, "                               planted, b0, b1, b2, b3, b4, b5, b6, b7, b8),\n", "                               planted, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9),\n")
t = sub1(t, "KOA_S3_W_FLOOR = 1e-9      # lower clip on the survivor weight, as deployed\n",
         "KOA_S3_W_FLOOR = 1e-9      # lower clip on the survivor weight, as deployed\n"
         f"# Increment mirror constants, 29 September 2026 refit ({tag}); mirror koa_params.\n"
         f"KOA_CF_DDBH = {cf_dd:.5f}              # CF_DDBH_MARGINAL\n"
         f"KOA_CF_DHT  = {cf_dh:.5f}              # CF_DHT (was 1.030 through v102)\n"
         f"KOA_CAL_DDBH = c({cal_dd[0]:.5f}, {cal_dd[1]:.5f})  # origin multipliers (natural, planted) = c / CF\n"
         f"KOA_CAL_DHT  = c({cal_dh[0]:.5f}, {cal_dh[1]:.5f})\n"
         f"KOA_DDBH_PLANTED_GUARD_CM = 45.0       # koa_params.DDBH_PLANTED_GUARD_CM, replaces the pmin(dbh, 40) truncation\n"
         f"KOA_BAL_DEFINITION = \"{'conventional' if arm == 'c' else 'percentile'}\"   # calc_bal() is conventional cumsum(ba) - ba over descending dbh\n"
         f"KOA_BAL_COHORT_LIN_B = c({a0:.7f}, {a1:.7f})   # cohort fraction a0 + a1 ln(QMD), row bal == {arm}\n")
open(p, "w").write(t)
for nm, o, n in (("HiGy_cf_ddbh", 1.026, cf_dd), ("HiGy_cf_dht", 1.030, cf_dh), ("HiGy_ddbh_planted_trunc_cm", 40, 45), ("HiGy_dht_planted_term", "sqrt(planted*pmin(ht,20))", "planted*pmin(ht,20)"),
                 ("HiGy_CAL_DDBH", "none (1,1)", f"({cal_dd[0]:.5f}, {cal_dd[1]:.5f})"), ("HiGy_CAL_DHT", "none (1,1)", f"({cal_dh[0]:.5f}, {cal_dh[1]:.5f})"),
                 ("HiGy_ddbh.parm_site", "record vector (-2.4704737 ...)", "refit b0..b9"), ("HiGy_dht.parm_site", "record vector (-3.382162 ...)", "refit b0..b9")): rec(nm, n, o)
df = pd.DataFrame(rows); df.to_csv(f"{OUT}/patch_values_{eng}.csv", index=False); print(eng, arm, "patched", len(df), "values; SE_LOG source", se_dd[0][1], se_dh[0][1])
print("CF", cf_dd, cf_dh, "CAL_DDBH", cal_dd, "CAL_DHT", cal_dh, "cohort", a0, a1)
