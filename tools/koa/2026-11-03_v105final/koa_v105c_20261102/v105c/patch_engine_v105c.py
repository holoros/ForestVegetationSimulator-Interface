#!/usr/bin/env python3
"""patch_engine_v105c.py (koa v105c, K3c1 dDBH form adopted under koa_rdcomp_20261102/constrained/PREREG_K3c.md).
Mode "form" (run once, before any refit): adds the K3c1 code path to engine_v103/koa_equations.py LineageA.dDBH and HiGy.R ddbh(), switched by
koa_params.DDBH_FORM ("v105b" | "K3c1") and HiGy.R KOA_DDBH_FORM, and sets the switch to "v105b" (parity gate: the new code with the v105b vector and terms
must reproduce v105b exactly). RD = SDI(25.4 cm index, exponent 1.605)/923 from the live list each annual step: the engine sdi argument is
tph (qmd/25)^1.605, so RD = sdi (25/25.4)^1.605 / 923 = tph (qmd/25.4)^1.605 / 923; share = BAL/BAPH (0 where BAPH = 0); x = share RD.
Mode "deploy": writes the refitted dDBH_L_NO K3c1 vector (b3 = 0), CF, CAL = c/CF (out/inc/coefficients_v103.csv, fit_stats_v103.csv), checks dHT unchanged,
resets MORT_CAL to (1, 1) for the level re-solve, sets DDBH_FORM = "K3c1", mirrors HiGy.R, writes out/v105_constants.json. Backups *_PREV_20261102c."""
import json, re, os, sys, csv, subprocess
W = os.path.expanduser("~/jobs/koa_v105c_20261102"); E = f"{W}/engine_v103"; MODE = sys.argv[1]
def backup(*ps): subprocess.run(["bash", f"{W}/v105c/backup_c.sh", *ps], check=True)
def setline(t, name, val, comment):
    t2, n = re.subn(r"^%s = .*$" % re.escape(name), "%s = %s   # %s" % (name, val, comment), t, count=1, flags=re.M); assert n == 1, name; return t2
if MODE == "form":
    p = f"{E}/koa_params.py"; backup(p); t = open(p).read(); assert "DDBH_FORM" not in t
    t = t.replace("\nCF_DDBH_MARGINAL = ", "\n# v105c (2026-11-02): dDBH competition form switch. \"v105b\" = b3 BAL^2/ln(DBH+5) + b4 ln(BAL+1) + b6 sqrt(BAPH DBH);\n"
                  "# \"K3c1\" = b4 ln(x+1) + b6 sqrt(RD DBH), x = (BAL/BAPH) RD, RD = SDI/923 (SDI = TPH (QMD/25.4)^1.605, live list, each annual step),\n"
                  "# b3 = 0 (koa_rdcomp_20261102/constrained/PREREG_K3c.md, adopted).\nDDBH_FORM = \"v105b\"\nDDBH_RD_SDIMAX = 923.0   # lqmm population SDImax (koa_brms_sdimax_20261102)\n"
                  "DDBH_RD_INDEX_DIAMETER_CM = 25.4   # Reineke index diameter of the fitted SDI (fit frames), not INDEX_DIAMETER_CM\nCF_DDBH_MARGINAL = ", 1)
    open(p, "w").write(t)
    p = f"{E}/koa_equations.py"; backup(p); t = open(p).read()
    old = """        lp = (p["b0"] + p["b1"] * ln(dbh + 1) + p["b2"] * dbh
              + p["b3"] * bal**2 / ln(dbh + 5) + p["b4"] * ln(bal + 1)
              + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(baph * dbh)
              + p["b7"] * planted * dbh_planted + p["b8"] * ln(np.maximum(byi, 1))
              + p.get("b9", 0.0) * planted)   # planted level shift, origin refit 2026-09-16
"""
    assert t.count(old) == 1
    new = """        if getattr(KP, "DDBH_FORM", "v105b") == "K3c1":   # v105c, 2026-11-02: RD-weighted relative competition, b3 = 0 (PREREG_K3c)
            if sdi is None:
                raise ValueError("DDBH_FORM K3c1 needs sdi (live-list SDI of the step)")
            rd = np.asarray(sdi, float) * (KP.INDEX_DIAMETER_CM / KP.DDBH_RD_INDEX_DIAMETER_CM) ** KP.SDI_OF_EXPONENT / KP.DDBH_RD_SDIMAX
            baph_a = np.asarray(baph, float)
            x = np.where(baph_a > 0, np.asarray(bal, float) / np.where(baph_a > 0, baph_a, 1.0), 0.0) * rd
            lp = (p["b0"] + p["b1"] * ln(dbh + 1) + p["b2"] * dbh
                  + p["b3"] * x**2 / ln(dbh + 5) + p["b4"] * ln(x + 1)
                  + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(rd * dbh)
                  + p["b7"] * planted * dbh_planted + p["b8"] * ln(np.maximum(byi, 1))
                  + p.get("b9", 0.0) * planted)
        else:
            lp = (p["b0"] + p["b1"] * ln(dbh + 1) + p["b2"] * dbh
              + p["b3"] * bal**2 / ln(dbh + 5) + p["b4"] * ln(bal + 1)
              + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(baph * dbh)
              + p["b7"] * planted * dbh_planted + p["b8"] * ln(np.maximum(byi, 1))
              + p.get("b9", 0.0) * planted)   # planted level shift, origin refit 2026-09-16
"""
    t = t.replace(old, new); open(p, "w").write(t)
    p = f"{E}/HiGy.R"; backup(p); t = open(p).read()
    old = "ddbh = function(dbh, bal, ba, cr, byi, planted,\n                b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0) {\n"
    assert t.count(old) == 1
    t = t.replace(old, "ddbh = function(dbh, bal, ba, cr, byi, planted,\n                b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 = 0, rd = NULL) {\n"
                  "  if (KOA_DDBH_FORM == 'K3c1') {   # v105c: x = (BAL/BAPH) RD, RD = TPH (QMD/25.4)^1.605 / 923, b3 = 0; mirrors koa_equations\n"
                  "    if (is.null(rd)) stop('KOA_DDBH_FORM K3c1 needs rd')\n    bal = ifelse(ba > 0, bal / ifelse(ba > 0, ba, 1), 0) * rd; ba = rd }\n")
    old = "                                          TRUE ~ddbh(dbh, bal, ba=ba.plot, cr,\n                                                     byi, planted,\n                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)),"
    assert t.count(old) == 1
    t = t.replace(old, "                                          TRUE ~ddbh(dbh, bal, ba=ba.plot, cr,\n                                                     byi, planted,\n                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,\n"
                  "                                                     rd = tph.plot * (pmax(qmd, 0.1) / KOA_DDBH_RD_D)^KOA_REINEKE_EXP / KOA_DDBH_RD_SDIMAX)),")
    old = "  tree = tree.data %>%\n    dplyr::left_join(plot.data %>%\n                       dplyr::select(plot, ba.plot),\n                     by = 'plot') %>%\n    # Match parameter estimates on species, Koa is currently the default\n    dplyr::mutate(idx = match(sp, ddbh.parm$species"
    assert t.count(old) == 1, t.count(old)
    t = t.replace(old, old.replace("dplyr::select(plot, ba.plot),", "dplyr::select(plot, ba.plot, tph.plot, qmd),   # tph.plot, qmd for the K3c1 RD (v105c)"))
    old = "KOA_DDBH_PLANTED_GUARD_CM = 45.0"
    assert t.count(old) == 1
    t = t.replace(old, old + "\nKOA_DDBH_FORM = 'v105b'   # v105c switch, mirrors koa_params.DDBH_FORM\nKOA_DDBH_RD_SDIMAX = 923\nKOA_DDBH_RD_D = 25.4")
    open(p, "w").write(t); print("form code added; DDBH_FORM = v105b")
elif MODE == "deploy":
    rows = list(csv.DictReader(open(f"{W}/out/inc/coefficients_v103.csv"))); st = {r["fit"]: r for r in csv.DictReader(open(f"{W}/out/inc/fit_stats_v103.csv"))}
    def fit(tag):
        co = {r["term"]: float(r["estimate"]) for r in rows if r["fit"] == tag}; se = {r["term"]: float(r["se"]) for r in rows if r["fit"] == tag}; s = st[tag]
        return dict(coef=co, se_model=se, CF=float(s["cf_source_inst"]), tau_source=float(s["tau_source"]), tau_inst=float(s["tau_inst"]), tau_tree=float(s["tau_tree"]),
                    c_natural=float(s["c_natural"]), c_planted=float(s["c_planted"]), CAL=[float(s["cal_natural"]), float(s["cal_planted"])], n=int(s["n"]), logLik=float(s["logLik"]))
    D, H = fit("dDBH_L_NO"), fit("dHT_L_NO"); assert D["coef"]["b3"] == 0.0, D["coef"]
    J = json.load(open(f"{W}/out/v105_constants.json")); J5 = json.loads(json.dumps(J))
    hd = max(abs(H["coef"][k] - J["DHT"]["coef"][k]) for k in H["coef"]); print("dHT vector vs v105b max abs diff", hd); assert hd < 1e-9
    J5["meta"] = dict(J["meta"], job="koa_v105c_20261102", stage="v105c engine (v105b + K3c1 dDBH competition form)", date="2026-11-02",
        decisions=J["meta"].get("decisions", "") + " | v105c: dDBH competition terms K3c1 (x = BAL share x RD, RD = SDI/923; b3 = 0), koa_rdcomp_20261102/constrained/PREREG_K3c.md")
    x = dict(J["DDBH"]); x.update({kk: D[kk] for kk in ("coef", "se_model", "CF", "tau_source", "tau_inst", "tau_tree", "c_natural", "c_planted", "CAL")})
    x["form"] = "K3c1"; x["note"] = "v105c K3c1 refit on the v105b frames, 2026-11-02 (b3 fixed at 0)"; x["se_boot"] = None; x["ci95_boot"] = None; x["CAL_SE_LOG_status"] = "carried from v105b until set_calse_v105c.py"
    J5["DDBH"] = x; J5["DDBH_CANDIDATE_L_NO"] = x; J5["MORT_CAL"] = {"value": None, "note": "re-solve on the v105c engine, PSP 122 2019-2023 excluded"}
    J5["V105B_PREV"] = {"DDBH": J["DDBH"]["coef"], "CF_DDBH": J["DDBH"]["CF"], "CAL_DDBH": J["DDBH"]["CAL"], "MORT_CAL": J.get("MORT_CAL")}
    json.dump(J5, open(f"{W}/out/v105_constants.json", "w"), indent=1)
    cD = D["coef"]
    p = f"{E}/koa_equations.py"; backup(p); t = open(p).read()
    newD = ("    DDBH = dict(b0=%.7f, b1=%.7f, b2=%.7f, b3=%.7f,   # dDBH_L_NO K3c1 refit (x = BAL share x RD, RD = SDI/923, b3 fixed 0), v105c 2026-11-02\n"
            "           b4=%.7f, b5=%.7f, b6=%.7f, b7=%.7f, b8=%.7f, b9=%.7f)") % tuple(cD[f"b{i}"] for i in range(10))
    t, n = re.subn(r"    DDBH = dict\(b0=-0\.5414106.*?\n.*?b9=0\.2455269\)", newD, t, flags=re.S); assert n == 1
    open(p, "w").write(t)
    p = f"{E}/koa_params.py"; backup(p); t = open(p).read()
    t = setline(t, "CF_DDBH_MARGINAL", "%.5f" % D["CF"], "exp(0.5 (tau_source^2 + tau_inst^2)) of dDBH_L_NO K3c1 (%.7f, %.7f), v105c 2026-11-02" % (D["tau_source"], D["tau_inst"]))
    t = setline(t, "CAL_DDBH", "(%.5f, %.5f)" % tuple(D["CAL"]), "c / CF of dDBH_L_NO K3c1 (c = %.5f, %.5f), v105c 2026-11-02" % (D["c_natural"], D["c_planted"]))
    t = setline(t, "MORT_CAL", "(1.0, 1.0)", "RESET 2026-11-02 for the v105c level re-solve (PSP 122 2019-2023 excluded); set by v105c/set_mortcal_v105c.py")
    t = setline(t, "DDBH_FORM", '"K3c1"', "v105c deployed form (PREREG_K3c adopted); \"v105b\" restores the v105b competition terms")
    open(p, "w").write(t)
    p = f"{E}/HiGy.R"; backup(p); t = open(p).read(); f7 = lambda v: "%.7f" % v
    oldD = "-0.5414106, 0.3621754, -0.0220549, -0.0014447, -0.3391600, 0.8396624, -0.0172214, -0.0178162,"
    assert t.count(oldD) == 2; t = t.replace(oldD, ", ".join(f7(cD[f"b{i}"]) for i in range(8)) + ",")
    old = "        0, 0.2455269,"; assert t.count(old) == 1; t = t.replace(old, "        0, %s," % f7(cD["b9"]))
    old = "0.2779335, 0.2455269)   # dDBH_L_NO refit on C2-P0 (imputed where missing), v105b 2026-11-02"; assert t.count(old) == 1
    t = t.replace(old, "%s, %s)   # dDBH_L_NO K3c1 refit, v105c 2026-11-02 (KOA_DDBH_FORM K3c1)" % (f7(cD["b8"]), f7(cD["b9"])))
    for nm, val in (("KOA_CF_DDBH = 1.42746", "KOA_CF_DDBH = %.5f" % D["CF"]), ("KOA_CAL_DDBH = c(0.29167, 0.88237)", "KOA_CAL_DDBH = c(%.5f, %.5f)" % tuple(D["CAL"])),
                    ("KOA_DDBH_FORM = 'v105b'", "KOA_DDBH_FORM = 'K3c1'")):
        assert t.count(nm) == 1, nm; t = t.replace(nm, val)
    open(p, "w").write(t)
    import importlib; sys.path.insert(0, E); os.chdir(E)
    import koa_params as KP, koa_equations as KE
    print("DDBH", KE.LineageA.DDBH); print("DDBH_FORM", KP.DDBH_FORM, "CF_DDBH_MARGINAL", KP.CF_DDBH_MARGINAL, "CAL_DDBH", KP.CAL_DDBH, "CF_DHT", KP.CF_DHT, "CAL_DHT", KP.CAL_DHT, "MORT_CAL", KP.MORT_CAL)
