# deploy_v105d.py (exec'd by patch_engine_v105d.py deploy; W, E, backup, setline, sub1, json, re, os, sys, csv in scope).
# Writes: dHT_L_NO K3c1h refit vector (b3 = 0), CF_DHT, CAL_DHT (= c/CF) from out/inc; HT_P = H1a (prep/out/height_coefficients_H1a.csv, = compscreen H1a);
# HCB_P and LineageA.HCB = C2h (prep/out/hcb_coefficients_C2h.csv); STAGE3_COEF = M3a (prep/out/stage3_coefficients_M3a.csv) with keys c3_lnRD, c4_lnshareRD;
# switches HT_FORM H1a, HCB_FORM C2h, DHT_FORM K3c1h, STAGE3_FORM M3a; MORT_CAL reset to (1, 1) for the level re-solve; out/v105_constants.json updated
# (V105C_PREV keeps every replaced v105c value). Checks: dDBH vector unchanged vs v105c (1e-12).
rows = list(csv.DictReader(open(f"{W}/out/inc/coefficients_v103.csv"))); st = {r["fit"]: r for r in csv.DictReader(open(f"{W}/out/inc/fit_stats_v103.csv"))}
def fit(tag):
    co = {r["term"]: float(r["estimate"]) for r in rows if r["fit"] == tag}; se = {r["term"]: float(r["se"]) for r in rows if r["fit"] == tag}; s = st[tag]
    return dict(coef=co, se_model=se, CF=float(s["cf_source_inst"]), tau_source=float(s["tau_source"]), tau_inst=float(s["tau_inst"]), tau_tree=float(s["tau_tree"]),
                c_natural=float(s["c_natural"]), c_planted=float(s["c_planted"]), CAL=[float(s["cal_natural"]), float(s["cal_planted"])], n=int(s["n"]), logLik=float(s["logLik"]))
D, H = fit("dDBH_L_NO"), fit("dHT_L_NO"); assert H["coef"]["b3"] == 0.0, H["coef"]
J = json.load(open(f"{W}/out/v105_constants.json")); JC = json.load(open(os.path.expanduser("~/jobs/koa_v105c_20261102/out/v105_constants.json")))
dd = max(abs(D["coef"][k] - JC["DDBH"]["coef"][k]) for k in D["coef"]); print("dDBH vector vs v105c max abs diff", dd); assert dd < 1e-12
HT = {r["parameter"]: float(r["estimate"]) for r in csv.DictReader(open(f"{W}/prep/out/height_coefficients_H1a.csv"))}
HTSE = {r["parameter"]: float(r["se"]) for r in csv.DictReader(open(f"{W}/prep/out/height_coefficients_H1a.csv"))}
HC = {r["term"]: float(r["estimate"]) for r in csv.DictReader(open(f"{W}/prep/out/hcb_coefficients_C2h.csv"))}
S3 = {r["term"]: float(r["estimate"]) for r in csv.DictReader(open(f"{W}/prep/out/stage3_coefficients_M3a.csv"))}
S3k = dict(c0=S3["c0"], c1=S3["c1"], c2=S3["c2"], c3_lnRD=S3["c3"], c4_lnshareRD=S3["c4"])
J5 = json.loads(json.dumps(J))
J5["V105C_PREV"] = {"DHT": J["DHT"], "HT_P": J["HT_P"], "HT_P_SE": J.get("HT_P_SE"), "HCB_P": J["HCB_P"], "STAGE3": J["STAGE3"], "MORT_CAL": J.get("MORT_CAL")}
J5["meta"] = dict(J["meta"], job="koa_v105d_20261102", stage="v105d engine (v105c + RD x competition in dHT K3c1h, Eq. 2 H1a, Eq. 3 C2h, Stage 3 M3a)", date="2026-11-02",
    decisions=J["meta"].get("decisions", "") + " | v105d: RD x competition forms in dHT (K3c1h, b3 = 0), Eq. 2 (H1a), Eq. 3 (C2h), Stage 3 (M3a) by modeling choice; declared deviation from the preregistered rules of koa_rdcomp_20261102 and koa_compscreen_20261102")
x = dict(J["DHT"]); x.update({kk: H[kk] for kk in ("coef", "se_model", "CF", "tau_source", "tau_inst", "tau_tree", "c_natural", "c_planted", "CAL")})
x.update(form="K3c1h", note="v105d K3c1h refit on the v105c frames (x = BAL share x RD, RD = SDI/923, b3 fixed 0), 2026-11-02", se_boot=None, ci95_boot=None, CAL_SE_LOG_status="pending v105d bootstrap")
x["selection_rule_outcome"] = "v105d: K3c1h deployed by modeling choice (declared deviation; koa_rdcomp_20261102 rule kept K0)"
J5["DHT"] = x
J5["HT_P"] = HT; J5["HT_P_SE"] = HTSE; J5["HT_P_deploy"] = "v105d H1a (koa_compscreen_20261102): g1 ln(RD) in place of g1 ln(BAPH+1); a0, a1, g1 refitted; b, c, g2 at v104"
J5["HCB_P"] = HC; J5["HCB_P_deploy"] = "v105d C2h (koa_compscreen_20261102): b3 sqrt(share RD + 1), b4 ln(RD), C2 BYI; all six refitted by nls on 360 FIA records"
J5["HCB_P_decision"] = "v105d: C2h deployed by modeling choice (declared deviation); compscreen rule kept HCB_P (monotonicity and BYI bootstrap failed)"
J5["STAGE3"] = {"form": "v105d M3a: eta = c0 + c1 ln(DBH) + c2 rHT + c3 ln(RD) + c4 ln(share RD + 1); only the ordering is used", "coef": S3k,
                "sample": J["STAGE3"].get("sample"), "note": "koa_compscreen_20261102 M3a refit (prep/refit_compscreen.R); declared deviation"}
J5["MORT_CAL"] = {"value": None, "note": "re-solve on the v105d engine, PSP 122 2019-2023 excluded"}
J5["RD_FLOORS"] = {r["frame"]: float(r["rd_min"]) for r in csv.DictReader(open(f"{W}/prep/out/rd_min_fitframes.csv"))}
json.dump(J5, open(f"{W}/out/v105_constants.json", "w"), indent=1)
p = f"{E}/koa_equations.py"; backup(p); t = open(p).read(); cH = H["coef"]
newH = ("    DHT = dict(b0=%.7f, b1=%.7f, b2=%.7f, b3=%.7f,   # dHT_L_NO K3c1h refit (x = BAL share x RD, RD = SDI/923, b3 fixed 0), v105d 2026-11-02\n"
        "          b4=%.7f, b5=%.7f, b6=%.7f, b7=%.7f, b8=%.7f, b9=%.7f)") % tuple(cH[f"b{i}"] for i in range(10))
t, n = re.subn(r"    DHT = dict\(b0=-2\.2488611.*?\n.*?b9=0\.6930402\)", newH, t, flags=re.S); assert n == 1
oldHT = "HT_P = dict(a0=28.990422, a1=1.142886, b=0.017026, c=0.792247, g1=0.076841, g2=-0.343310)   # v105b refit on the C2-P0 site index (imputed where missing) 2026-11-02, rDBH = DBH/DBH.max"
t = sub1(t, oldHT, "HT_P = dict(a0=%.6f, a1=%.6f, b=%.6f, c=%.6f, g1=%.6f, g2=%.6f)   # v105d H1a (g1 on ln RD; a0 a1 g1 refit, koa_compscreen_20261102), rDBH = DBH/DBH.max" % tuple(HT[k] for k in ("a0", "a1", "b", "c", "g1", "g2")))
hcbline = "dict(b0=%.10f, b1=%.10f, b2=%.10f, b3=%.10f, b4=%.10f, b5=%.10f)" % tuple(HC[f"b{i}"] for i in range(6))
t = sub1(t, "HCB_P = dict(b0=0.1684, b1=1.0146, b2=-0.376, b3=-0.0078, b4=-0.3734, b5=-0.221)\n", "HCB_P = %s   # v105d C2h (koa_compscreen_20261102): b3 on sqrt(share RD + 1), b4 on ln RD\n" % hcbline)
t = sub1(t, "    HCB = dict(b0=0.1684, b1=1.0146, b2=-0.376, b3=-0.0078, b4=-0.3734, b5=-0.221)\n", "    HCB = %s   # v105d C2h carrier (LineageA.predict_HCB raises under HCB_FORM C2h)\n" % hcbline)
open(p, "w").write(t)
p = f"{E}/koa_params.py"; backup(p); t = open(p).read()
t = setline(t, "CF_DHT", "%.5f" % H["CF"], "exp(0.5 (tau_source^2 + tau_inst^2)) of dHT_L_NO K3c1h (%.7f, %.7f), v105d 2026-11-02" % (H["tau_source"], H["tau_inst"]))
t = setline(t, "CAL_DHT", "(%.5f, %.5f)" % tuple(H["CAL"]), "c / CF of dHT_L_NO K3c1h (c = %.5f, %.5f), v105d 2026-11-02" % (H["c_natural"], H["c_planted"]))
t = setline(t, "MORT_CAL", "(1.0, 1.0)", "RESET 2026-11-02 for the v105d level re-solve (PSP 122 2019-2023 excluded); set by v105d/set_mortcal_v105d.py")
t = setline(t, "STAGE3_COEF", repr(S3k), "v105d M3a (koa_compscreen_20261102): c3 on ln RD, c4 on ln(share RD + 1); keys renamed so v105b-form literals fail")
for nm, v in (("HT_FORM", "H1a"), ("HCB_FORM", "C2h"), ("DHT_FORM", "K3c1h"), ("STAGE3_FORM", "M3a")):
    t = setline(t, nm, '"%s"' % v, "v105d deployed form (modeling choice, declared deviation); \"v105b\" restores the v105c form")
open(p, "w").write(t)
import importlib; sys.path.insert(0, E); os.chdir(E)
import koa_params as KP, koa_equations as KE
print("DHT", KE.LineageA.DHT); print("HT_P", KE.HT_P); print("HCB_P", KE.HCB_P); print("STAGE3_COEF", KP.STAGE3_COEF)
print("forms", KP.DDBH_FORM, KP.HT_FORM, KP.HCB_FORM, KP.DHT_FORM, KP.STAGE3_FORM, "CF_DHT", KP.CF_DHT, "CAL_DHT", KP.CAL_DHT, "MORT_CAL", KP.MORT_CAL)
