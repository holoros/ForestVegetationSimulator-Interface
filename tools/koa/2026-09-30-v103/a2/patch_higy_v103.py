"""patch_higy_v103.py (2026-09-30, Stage A2). Mirror the engine_v103 constants into engine_v103/HiGy.R (backup HiGy_PREV_20260930.R in the
engine folder, not a repository): Stage 1 cloglog and p_bar from out_stage1/stage1_fit.json (the four constants that were stale since v99 and
caused V102-D2), Garcia anchored beta and H_QMD allometry, the increment tables (v102 dDBH vector, dHT_L_NO) with CF x origin multiplier and
the 45 cm planted guard (as patch_engine_refit2.py did), and the static height row. calc_bal in HiGy.R is conventional; the engine and the
fits are live list percentile, so KOA_BAL_DEFINITION is written as "percentile" and the calc_bal mismatch is recorded, not changed
(HiGy.R is a mirror, Midgard's production file is the reference). Writes a2/out/patch_values_higy_v103.csv."""
import os, re, json, shutil, pandas as pd
A2 = os.path.dirname(os.path.abspath(__file__)); E = f"{A2}/../engine_v103"; p = f"{E}/HiGy.R"
if not os.path.exists(f"{E}/HiGy_PREV_20260930.R"): shutil.copy(p, f"{E}/HiGy_PREV_20260930.R")
t = open(f"{E}/HiGy_PREV_20260930.R").read(); J = json.load(open(f"{A2}/../out/v103_constants.json")); S = json.load(open(f"{E}/out_stage1/stage1_fit.json"))
rows = []
def sub1(o, n):
    global t; assert t.count(o) == 1, (o[:70], t.count(o)); t = t.replace(o, n); rows.append(dict(old=o.strip()[:90], new=n.strip()[:120]))
def line(prefix, new):
    L = [l for l in t.splitlines() if l.startswith(prefix)]; assert len(L) == 1, (prefix, L); sub1(L[0], new)
b = S["stage1_beta"]
line("KOA_S1_INTERCEPT =", f"KOA_S1_INTERCEPT = {b['intercept']!r}  # cloglog intercept, v103 stage1_fit.json 2026-09-30")
line("KOA_S1_LNSDI     =", f"KOA_S1_LNSDI     = {b['lnSDI']!r}  # coefficient on ln(max(SDI, 1)), v103")
line("KOA_S1_PLANTED   =", f"KOA_S1_PLANTED   = {b['planted']!r}  # planted-origin offset, v103")
line("KOA_S1_PBAR      =", f"KOA_S1_PBAR      = {S['stage1_mean_annual_p']!r}  # mean fitted ANNUAL occurrence, v103")
G = J["GARCIA"]
line("KOA_GARCIA_BETA_ANCHORED =", f"KOA_GARCIA_BETA_ANCHORED = {G['GARCIA_BETA_ANCHORED']!r}  # m-1, v103 live koa anchor")
line("KOA_GARCIA_ALLOM_A       =", f"KOA_GARCIA_ALLOM_A       = {G['GARCIA_ALLOM_A']!r} # H_QMD allometry intercept, v103")
line("KOA_GARCIA_ALLOM_K_HD    =", f"KOA_GARCIA_ALLOM_K_HD    = {G['GARCIA_ALLOM_K_HD']!r}   # H_QMD allometry slope, v103")
DD, DH, HT = J["DDBH"]["coef"], J["DHT"]["coef"], J["HT_P"]
def trib(name, d):
    return (f"  {name} = dplyr::tribble(\n    ~type,    ~species,  ~b0,        ~b1,         ~b2,         ~b3,         ~b4,        ~b5,         ~b6,        ~b7,        ~b8,        ~b9,\n"
            f"    'base',    'AK',   {d['b0']:.7f}, {d['b1']:.7f}, {d['b2']:.7f}, {d['b3']:.7f}, {d['b4']:.7f}, {d['b5']:.7f}, {d['b6']:.7f}, {d['b7']:.7f},        0, {d['b9']:.7f},\n"
            f"    'site',    'AK',   {d['b0']:.7f}, {d['b1']:.7f}, {d['b2']:.7f}, {d['b3']:.7f}, {d['b4']:.7f}, {d['b5']:.7f}, {d['b6']:.7f}, {d['b7']:.7f}, {d['b8']:.7f}, {d['b9']:.7f})\n")
pd_old = re.compile(r"  ddbh\.parm = dplyr::tribble\(\n.*?0\.4530166\)\n", re.S); ph_old = re.compile(r"dht\.parm = dplyr::tribble\(\n.*?0\.433224\)\n", re.S)
assert len(pd_old.findall(t)) == 1 and len(ph_old.findall(t)) == 1
t = pd_old.sub(trib("ddbh.parm", DD) + "  # v102 vector of record, deployed in v103 (c re-solved under live list BAL), mirrors koa_equations.LineageA.DDBH\n", t)
t = ph_old.sub(trib("dht.parm", DH).lstrip() + "# dHT_L_NO, v103 2026-09-30, mirrors koa_equations.LineageA.DHT\n", t); rows.append(dict(old="ddbh.parm, dht.parm (Midgard 0.4.0 vectors)", new="v103 deployed vectors with b9"))
sub1("ddbh = function(dbh, bal, ba, cr, byi, planted,\n                b0, b1, b2, b3, b4, b5, b6, b7, b8) {\n\n  cf = 1.026   # Duan (1983) smearing correction factor\n",
     "ddbh = function(dbh, bal, ba, cr, byi, planted,\n                b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0) {\n\n  cf = KOA_CF_DDBH * ifelse(planted == 1, KOA_CAL_DDBH[2], KOA_CAL_DDBH[1])   # CF x origin multiplier, mirrors koa_equations, v103\n")
sub1("               b7 * planted * pmin(dbh, 40) +\n               b8 * log(pmax(byi, 1))) *cf\n", "               b7 * planted * pmin(dbh, KOA_DDBH_PLANTED_GUARD_CM) +\n               b8 * log(pmax(byi, 1)) + b9 * planted) *cf\n")
sub1("dht = function(dbh, ht, bal, ba, cr, byi, planted,\n               b0, b1, b2, b3, b4, b5, b6, b7, b8) {\n\n\n  cf = 1.030   # Duan (1983) smearing correction factor\n",
     "dht = function(dbh, ht, bal, ba, cr, byi, planted,\n               b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0) {\n\n\n  cf = KOA_CF_DHT * ifelse(planted == 1, KOA_CAL_DHT[2], KOA_CAL_DHT[1])   # CF x origin multiplier, mirrors koa_equations, v103\n")
sub1("              b7 * sqrt(planted * pmin(ht, 20)) +\n              b8 * log(pmax(byi, 1))) *cf\n", "              b7 * planted * pmin(ht, 20) +   # fitted linear form, as koa_equations.LineageA.dHT\n              b8 * log(pmax(byi, 1)) + b9 * planted) *cf\n")
sub1("                  b8 = ddbh.parm$b8[idx],\n", "                  b8 = ddbh.parm$b8[idx],\n                  b9 = ddbh.parm$b9[idx],\n")
sub1("                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8)),\n", "                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)),\n")
sub1("                  b8 = dht.parm$b8[idx],\n", "                  b8 = dht.parm$b8[idx],\n                  b9 = dht.parm$b9[idx],\n")
sub1("                               planted, b0, b1, b2, b3, b4, b5, b6, b7, b8),\n", "                               planted, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9),\n")
sub1("  'base',  'AK',      19.832,   0,      0.044,   0.863,   -0.198,   0.479,\n  'site',  'AK',      19.832,   0.106,  0.044,   0.863,   -0.198,   0.479)",
     f"  'base',  'AK',      {HT['a0']:.6f},   0,      {HT['b']:.6f},   {HT['c']:.6f},   {HT['g1']:.6f},   {HT['g2']:.6f},\n  'site',  'AK',      {HT['a0']:.6f},   {HT['a1']:.6f},  {HT['b']:.6f},   {HT['c']:.6f},   {HT['g1']:.6f},   {HT['g2']:.6f})   # v103 HT_P values; HiGy pred_ht uses a1 * byi / 100 and rdbh = dbh/qmd, the engine uses a1 * BYI/100 and DBH/DBH.max (form difference recorded, not changed)")
D, H = J["DDBH"], J["DHT"]
sub1("KOA_S3_W_FLOOR = 1e-9      # lower clip on the survivor weight, as deployed\n", "KOA_S3_W_FLOOR = 1e-9      # lower clip on the survivor weight, as deployed\n"
     f"# Increment mirror constants, v103 (2026-09-30); mirror koa_params of engine_v103.\nKOA_CF_DDBH = {D['CF']:.5f}\nKOA_CF_DHT  = {H['CF']:.5f}\nKOA_CAL_DDBH = c({D['CAL'][0]:.5f}, {D['CAL'][1]:.5f})\nKOA_CAL_DHT  = c({H['CAL'][0]:.5f}, {H['CAL'][1]:.5f})\n"
     "KOA_DDBH_PLANTED_GUARD_CM = 45.0\nKOA_BAL_DEFINITION = \"percentile\"   # engine and fits: live list percentile; calc_bal() here is conventional (recorded mismatch)\n"
     f"KOA_BAL_COHORT_LIN_B = c({J['BAL_COHORT']['a0']:.7f}, {J['BAL_COHORT']['a1']:.7f})\n")
open(p, "w").write(t); pd.DataFrame(rows).to_csv(f"{A2}/out/patch_values_higy_v103.csv", index=False); print("HiGy.R mirrored,", len(rows), "edits")
