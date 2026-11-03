#!/usr/bin/env python3
"""deploy_run.py RUN (koa_v105attr_20261103): writes one attribution run's engine from its fits.
RD = SDI / SDImax_pop (prep/out/sdimax_pop.csv median of the brms RI_LONG per-draw population SDImax at QMD 25.4 cm).
dDBH K3c1 and dHT (K3c1h or v105c form) from RUN/out/inc (inc_v103.R refit under SDImax_pop); H1a, C2h, M3a from prep/out742 (refit under SDImax_pop);
reverted components take the v105c engine literals and v105c consumer files (koa_v105c_20261102, read only). RD floors from prep/out742 (min RD of each
fitting frame under the new divisor). MORT_CAL reset to (1, 1) for the level re-solve. Updates RUN/out/v105_constants.json and the height consumers."""
import os, re, sys, csv, json, shutil
J = os.path.expanduser("~/jobs/koa_v105attr_20261103"); RUN = sys.argv[1]; W = f"{J}/{RUN}"; E = f"{W}/engine_v103"; P = f"{J}/prep/out742"
C = os.path.expanduser("~/jobs/koa_v105c_20261102")
REV = {"D742": set(), "R_dHT": {"dHT"}, "R_HT": {"HT"}, "R_HCB": {"HCB"}, "R_S3": {"S3"}, "C742": {"dHT", "HT", "HCB", "S3"}}.get(RUN)
if REV is None:   # pairwise revert runs, named P_<comp>_<comp> (comp in dHT, HT, HCB, S3)
    assert RUN.startswith("P_"); REV = set(RUN[2:].split("_")); assert REV <= {"dHT", "HT", "HCB", "S3"} and len(REV) == 2, RUN
SDIMAX = float(list(csv.DictReader(open(f"{J}/prep/out/sdimax_pop.csv")))[0]["median"])
def setline(t, name, val, comment):
    t2, n = re.subn(r"^%s = .*$" % re.escape(name), lambda m: "%s = %s   # %s" % (name, val, comment), t, count=1, flags=re.M); assert n == 1, name; return t2
def grab(path, pat):
    m = re.findall(pat, open(path).read(), flags=re.M); assert len(m) == 1, (path, pat, len(m)); return m[0]
rows = list(csv.DictReader(open(f"{W}/out/inc/coefficients_v103.csv"))); st = {r["fit"]: r for r in csv.DictReader(open(f"{W}/out/inc/fit_stats_v103.csv"))}
def fit(tag):
    co = {r["term"]: float(r["estimate"]) for r in rows if r["fit"] == tag}; se = {r["term"]: float(r["se"]) for r in rows if r["fit"] == tag}; s = st[tag]
    return dict(coef=co, se_model=se, CF=float(s["cf_source_inst"]), tau_source=float(s["tau_source"]), tau_inst=float(s["tau_inst"]), tau_tree=float(s["tau_tree"]),
                c_natural=float(s["c_natural"]), c_planted=float(s["c_planted"]), CAL=[float(s["cal_natural"]), float(s["cal_planted"])], n=int(s["n"]), logLik=float(s["logLik"]))
D, H = fit("dDBH_L_NO"), fit("dHT_L_NO")
if "dHT" in REV:   # gate: v105c-form dHT refit reproduces the v105c dHT_L_NO (no RD in that form)
    JC = json.load(open(f"{C}/out/v105_constants.json")); g = max(abs(H["coef"][k] - JC["DHT"]["coef"][k]) for k in H["coef"]); print("GATE dHT v105c-form refit vs v105c, max abs diff", g); assert g < 1e-6
    assert H["coef"]["b3"] != 0.0
else:
    assert H["coef"]["b3"] == 0.0
HT = {r["parameter"]: float(r["estimate"]) for r in csv.DictReader(open(f"{P}/height_coefficients_H1a.csv"))}
HTSE = {r["parameter"]: float(r["se"]) for r in csv.DictReader(open(f"{P}/height_coefficients_H1a.csv"))}
HC = {r["term"]: float(r["estimate"]) for r in csv.DictReader(open(f"{P}/hcb_coefficients_C2h.csv"))}
S3 = {r["term"]: float(r["estimate"]) for r in csv.DictReader(open(f"{P}/stage3_coefficients_M3a.csv"))}
RF = {r["frame"]: float(r["rd_min"]) for r in csv.DictReader(open(f"{P}/rd_min_fitframes.csv"))}
# ---- koa_equations.py
p = f"{E}/koa_equations.py"; t = open(p).read(); cD, cH = D["coef"], H["coef"]
newD = ("    DDBH = dict(b0=%.7f, b1=%.7f, b2=%.7f, b3=%.7f,   # dDBH_L_NO K3c1 refit (x = BAL share x RD, RD = SDI/%.6f), koa_v105attr %s\n"
        "           b4=%.7f, b5=%.7f, b6=%.7f, b7=%.7f, b8=%.7f, b9=%.7f)") % (tuple(cD[f"b{i}"] for i in range(4)) + (SDIMAX, RUN) + tuple(cD[f"b{i}"] for i in range(4, 10)))
t, n = re.subn(r"    DDBH = dict\(b0=-0\.5585878.*?\n.*?b9=0\.0757393\)", lambda m: newD, t, flags=re.S); assert n == 1
newH = ("    DHT = dict(b0=%.7f, b1=%.7f, b2=%.7f, b3=%.7f,   # dHT_L_NO %s refit, koa_v105attr %s\n"
        "          b4=%.7f, b5=%.7f, b6=%.7f, b7=%.7f, b8=%.7f, b9=%.7f)") % (tuple(cH[f"b{i}"] for i in range(4)) + ("v105c form (no RD)" if "dHT" in REV else "K3c1h (RD = SDI/%.6f, b3 fixed 0)" % SDIMAX, RUN) + tuple(cH[f"b{i}"] for i in range(4, 10)))
t, n = re.subn(r"    DHT = dict\(b0=-2\.2559249.*?\n.*?b9=0\.6476638\)", lambda m: newH, t, flags=re.S); assert n == 1
oldHT = grab(p, r"^HT_P = dict\(a0=36\.878367.*$")
if "HT" in REV: newHT = grab(f"{C}/engine_v103/koa_equations.py", r"^HT_P = dict\(.*$") + "   [v105c HT_P, koa_v105attr %s]" % RUN
else: newHT = "HT_P = dict(a0=%.6f, a1=%.6f, b=%.6f, c=%.6f, g1=%.6f, g2=%.6f)   # H1a refit under RD = SDI/%.6f (a0 a1 g1), koa_v105attr %s, rDBH = DBH/DBH.max" % (tuple(HT[k] for k in ("a0", "a1", "b", "c", "g1", "g2")) + (SDIMAX, RUN))
t = t.replace(oldHT, newHT)
hcbline = "dict(b0=%.10f, b1=%.10f, b2=%.10f, b3=%.10f, b4=%.10f, b5=%.10f)" % tuple(HC[f"b{i}"] for i in range(6))
if "HCB" in REV: hcbline = "dict(b0=0.1684, b1=1.0146, b2=-0.376, b3=-0.0078, b4=-0.3734, b5=-0.221)"   # v105c HCB_P (koa_v105c_20261102 koa_equations.py)
old = "dict(b0=-0.9912204678, b1=0.0762310422, b2=-1.2614647770, b3=0.1485828466, b4=-0.1504298095, b5=-0.6319110712)"; assert t.count(old) == 2
t = t.replace(old, hcbline)
open(p, "w").write(t)
# ---- koa_params.py
p = f"{E}/koa_params.py"; t = open(p).read()
t = setline(t, "DDBH_RD_SDIMAX", "%.9f" % SDIMAX, "brms RI_LONG population SDImax at QMD 25.4 cm, posterior median of per-draw exp(b0 + b1 log 25.4) (koa_v105attr_20261103 prep/out/sdimax_pop.csv)")
t = setline(t, "CF_DDBH_MARGINAL", "%.5f" % D["CF"], "dDBH_L_NO K3c1 under SDImax_pop (%.7f, %.7f), koa_v105attr" % (D["tau_source"], D["tau_inst"]))
t = setline(t, "CAL_DDBH", "(%.5f, %.5f)" % tuple(D["CAL"]), "c / CF of dDBH_L_NO K3c1 under SDImax_pop (c = %.5f, %.5f), koa_v105attr" % (D["c_natural"], D["c_planted"]))
t = setline(t, "CF_DHT", "%.5f" % H["CF"], "dHT_L_NO (%s) (%.7f, %.7f), koa_v105attr" % ("v105c form" if "dHT" in REV else "K3c1h", H["tau_source"], H["tau_inst"]))
t = setline(t, "CAL_DHT", "(%.5f, %.5f)" % tuple(H["CAL"]), "c / CF of dHT_L_NO (c = %.5f, %.5f), koa_v105attr" % (H["c_natural"], H["c_planted"]))
t = setline(t, "MORT_CAL", "(1.0, 1.0)", "RESET for the level re-solve, koa_v105attr %s" % RUN)
if "S3" in REV: s3 = grab(f"{C}/engine_v103/koa_params.py", r"^STAGE3_COEF = (\{[^}]*\})")
else: s3 = repr(dict(c0=S3["c0"], c1=S3["c1"], c2=S3["c2"], c3_lnRD=S3["c3"], c4_lnshareRD=S3["c4"]))
t = setline(t, "STAGE3_COEF", s3, ("v105c Stage 3 (ln(BAPH+1), ln(BAL+1))" if "S3" in REV else "M3a refit under SDImax_pop") + ", koa_v105attr %s" % RUN)
for nm, comp, new in (("HT_FORM", "HT", "H1a"), ("HCB_FORM", "HCB", "C2h"), ("DHT_FORM", "dHT", "K3c1h"), ("STAGE3_FORM", "S3", "M3a")):
    t = setline(t, nm, '"%s"' % ("v105b" if comp in REV else new), "koa_v105attr %s (%s)" % (RUN, "reverted to v105c form" if comp in REV else "v105d form"))
for nm, fr in (("RD_FLOOR_HT", "height"), ("RD_FLOOR_HCB", "hcb"), ("RD_FLOOR_STAGE3", "stage3")):
    t = setline(t, nm, "%.10g" % RF[fr], "minimum RD of the %s fitting frame under SDImax_pop (prep/out742/rd_min_fitframes.csv)" % fr)
open(p, "w").write(t)
# ---- constants json (joint draws gate DDBH, DHT coef and HT_P against it)
Jp = f"{W}/out/v105_constants.json"; JJ = json.load(open(Jp))
for k, F in (("DDBH", D), ("DHT", H)):
    x = dict(JJ[k]); x.update({kk: F[kk] for kk in ("coef", "se_model", "CF", "tau_source", "tau_inst", "tau_tree", "c_natural", "c_planted", "CAL")})
    x.update(se_boot=None, ci95_boot=None, note="koa_v105attr %s refit under SDImax_pop %.6f" % (RUN, SDIMAX)); JJ[k] = x
JJ["DDBH_CANDIDATE_L_NO"] = JJ["DDBH"]
if "HT" in REV:
    JC = json.load(open(f"{C}/out/v105_constants.json")); JJ["HT_P"] = JC["HT_P"]; JJ["HT_P_SE"] = JC.get("HT_P_SE")
else:
    JJ["HT_P"] = HT; JJ["HT_P_SE"] = HTSE
JJ["HCB_P"] = {f"b{i}": float(v) for i, v in enumerate(re.findall(r"=(-?[0-9.]+)", hcbline))}
JJ["STAGE3"] = dict(JJ["STAGE3"], coef=eval(s3)); JJ["MORT_CAL"] = {"value": None}; JJ["RD_FLOORS"] = RF; JJ["SDIMAX_POP"] = SDIMAX
JJ["meta"] = dict(JJ["meta"], job="koa_v105attr_20261103/%s" % RUN, reverted=sorted(REV))
json.dump(JJ, open(Jp, "w"), indent=1)
# ---- height consumers read by the joint draws
src = (f"{C}/track2/out/height_coefficients.csv", f"{C}/track2/height/height_vcov_v103.csv") if "HT" in REV else None
if src:
    shutil.copy2(src[0], f"{W}/track2/out/height_coefficients.csv"); shutil.copy2(src[1], f"{W}/track2/height/height_vcov_v103.csv")
else:
    p = f"{W}/track2/out/height_coefficients.csv"; R = list(csv.DictReader(open(p))); fn = list(R[0].keys()); est = {r["parameter"]: r for r in csv.DictReader(open(f"{P}/height_coefficients_H1a.csv"))}
    out = [dict(r, estimate=est[r["parameter"]]["estimate"], se=est[r["parameter"]]["se"], fixed_at_v104=est[r["parameter"]]["fixed"].upper()) if r["frame"] == "v103" else r for r in R]
    with open(p, "w", newline="") as fh: w = csv.DictWriter(fh, fieldnames=fn, quoting=csv.QUOTE_NONNUMERIC); w.writeheader(); w.writerows(out)
    shutil.copy2(f"{P}/height_vcov_H1a.csv", f"{W}/track2/height/height_vcov_v103.csv")
# ---- check
sys.path.insert(0, E); os.chdir(E)
import koa_params as KP, koa_equations as KE
assert abs(KP.DDBH_RD_SDIMAX - SDIMAX) < 1e-6
print(RUN, "reverted", sorted(REV)); print("DDBH", KE.LineageA.DDBH); print("DHT", KE.LineageA.DHT); print("HT_P", KE.HT_P); print("HCB_P", KE.HCB_P, KE.LineageA.HCB); print("STAGE3_COEF", KP.STAGE3_COEF)
print("forms", KP.DDBH_FORM, KP.HT_FORM, KP.HCB_FORM, KP.DHT_FORM, KP.STAGE3_FORM, "SDIMAX", KP.DDBH_RD_SDIMAX, "floors", KP.RD_FLOOR_HT, KP.RD_FLOOR_HCB, KP.RD_FLOOR_STAGE3,
      "CF_DDBH", KP.CF_DDBH_MARGINAL, "CAL_DDBH", KP.CAL_DDBH, "CF_DHT", KP.CF_DHT, "CAL_DHT", KP.CAL_DHT, "MORT_CAL", KP.MORT_CAL)
print("DEPLOY_RUN DONE", RUN)
