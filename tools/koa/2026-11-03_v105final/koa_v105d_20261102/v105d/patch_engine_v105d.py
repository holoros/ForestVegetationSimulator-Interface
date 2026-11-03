#!/usr/bin/env python3
"""patch_engine_v105d.py (koa v105d = v105c + RD x competition forms in dHT, height Eq. 2, HCB Eq. 3 and mortality Stage 3; Aaron's modeling choice,
declared deviation from the preregistered adoption rules of koa_rdcomp_20261102 (dHT) and koa_compscreen_20261102 (Eq. 2, Eq. 3, Stage 3)).
Mode "form" (before any refit): adds the code paths, switched by koa_params HT_FORM, HCB_FORM, DHT_FORM, STAGE3_FORM, all set to "v105b" (= v105c behaviour;
parity gate: the new code must reproduce v105c exactly). RD = SDI(25.4 cm, exponent 1.605)/923 from the live list each annual step, as DDBH K3c1.
  Eq. 2 H1a:  ht = (a0 + a1 BYI/100) (1 - exp(-b DBH))^c exp(g1 ln(max(RD, RD_FLOOR_HT)) + g2 rDBH)         [ln(BAPH+1) -> ln RD]
  Eq. 3 C2h:  eta = b0 + b1 sqrt(HT/100) + b2 ln(HT/DBH) + b3 sqrt(share RD + 1) + b4 ln(max(RD, RD_FLOOR_HCB)) + b5 ln(BYI/100)
  dHT K3c1h:  b4 ln(x+1) + b6 sqrt(RD HT), x = share RD, b3 = 0 (K3p: + b3 x^2/ln(HT+5))
  Stage 3 M3a: c0 + c1 ln DBH + c2 rHT + c3 ln(max(RD, RD_FLOOR_STAGE3)) + c4 ln(share RD + 1)
RD floors = minimum RD of each fitting frame (prep/out/rd_min_fitframes.csv); share = BAL/BAPH (0 where BAPH = 0).
Every predict_HCB call must pass rd= under C2h and every dHT call sdi= under K3c1h/K3p (ValueError otherwise: fail loudly). Under M3a STAGE3_COEF
carries keys c3_lnRD, c4_lnshareRD, so any surviving literal Stage 3 expression (P.STAGE3_COEF['c3']) raises KeyError.
Mode "deploy": writes the v105d vectors and switches (see deploy())."""
import json, re, os, sys, csv, subprocess
W = os.path.expanduser("~/jobs/koa_v105d_20261102"); E = f"{W}/engine_v103"; MODE = sys.argv[1]
def backup(*ps): subprocess.run(["bash", f"{W}/v105d/backup_d.sh", *ps], check=True)
def sub1(t, old, new, n=1):
    assert t.count(old) == n, (t.count(old), old[:100]); return t.replace(old, new)
def setline(t, name, val, comment):
    t2, n = re.subn(r"^%s = .*$" % re.escape(name), "%s = %s   # %s" % (name, val, comment), t, count=1, flags=re.M); assert n == 1, name; return t2
S3_OLD = re.compile(r"np\.clip\(1\.0 - np\.exp\(-np\.exp\(P\.STAGE3_COEF\['c0'\] \+ P\.STAGE3_COEF\['c1'\] \* np\.log\(np\.maximum\(dbh, 0\.1\)\) \+ P\.STAGE3_COEF\['c2'\] \* rht \+ "
                    r"P\.STAGE3_COEF\['c3'\] \* np\.log\(baph \+ 1\.0\) \+ P\.STAGE3_COEF\['c4'\] \* np\.log\(np\.maximum\(bal, 0\.0\) \+ 1\.0\)\)\), 1e-9, 1\.0\)")
if MODE == "form":
    RF = {r["frame"]: float(r["rd_min"]) for r in csv.DictReader(open(f"{W}/prep/out/rd_min_fitframes.csv"))}
    p = f"{E}/koa_params.py"; backup(p); t = open(p).read(); assert "HT_FORM" not in t
    anchor = "DDBH_RD_INDEX_DIAMETER_CM = 25.4   # Reineke index diameter of the fitted SDI (fit frames), not INDEX_DIAMETER_CM\n"
    t = sub1(t, anchor, anchor +
      "# v105d (2026-11-02): RD x competition forms in every other component with a competition term (Aaron's modeling choice; declared deviation from\n"
      "# the preregistered adoption rules of koa_rdcomp_20261102 (dHT) and koa_compscreen_20261102 (Eq. 2 H1a, Eq. 3 C2h, Stage 3 M3a)). \"v105b\" = v105c forms.\n"
      "HT_FORM = \"v105b\"       # \"H1a\": g1 ln(max(RD, RD_FLOOR_HT)) in place of g1 ln(BAPH+1)\n"
      "HCB_FORM = \"v105b\"      # \"C2h\": b3 sqrt(share RD + 1) + b4 ln(max(RD, RD_FLOOR_HCB)) in place of b3 sqrt(BAL BAPH + 1) + b4 ln(BAPH+1)\n"
      "DHT_FORM = \"v105b\"      # \"K3c1h\": b4 ln(x+1) + b6 sqrt(RD HT), x = share RD, b3 = 0; \"K3p\": the same plus b3 x^2/ln(HT+5)\n"
      "STAGE3_FORM = \"v105b\"   # \"M3a\": c3 ln(max(RD, RD_FLOOR_STAGE3)) + c4 ln(share RD + 1) in place of c3 ln(BAPH+1) + c4 ln(BAL+1)\n"
      "RD_FLOOR_HT = %.10g   # minimum RD of the Eq. 2 fitting frame (8,914 records), floor of ln RD in projection\n"
      "RD_FLOOR_HCB = %.10g   # minimum RD of the Eq. 3 fitting frame (360 records)\n"
      "RD_FLOOR_STAGE3 = %.10g   # minimum RD of the Stage 3 fitting frame (4,223 records)\n" % (RF["height"], RF["hcb"], RF["stage3"]))
    open(p, "w").write(t)
    p = f"{E}/koa_equations.py"; backup(p); t = open(p).read(); assert "rd_from_sdi" not in t
    t = sub1(t, "_CALRNG = [None]\n", "def rd_from_sdi(sdi):\n    \"\"\"v105d: RD = SDI(25.4 cm index, exponent SDI_OF_EXPONENT)/923 from the engine SDI (25 cm index), as DDBH K3c1.\"\"\"\n"
             "    return np.asarray(sdi, float) * (KP.INDEX_DIAMETER_CM / KP.DDBH_RD_INDEX_DIAMETER_CM) ** KP.SDI_OF_EXPONENT / KP.DDBH_RD_SDIMAX\n"
             "def rd_from_baph_qmd(baph, qmd):\n    \"\"\"v105d: RD of a stand with basal area baph (m2/ha) and quadratic mean diameter qmd (cm): TPH = BAPH/(0.00007854 QMD^2).\"\"\"\n"
             "    q = np.maximum(np.asarray(qmd, float), 0.1); tph = np.asarray(baph, float) / (0.00007854 * q ** 2)\n"
             "    return tph * (q / KP.DDBH_RD_INDEX_DIAMETER_CM) ** KP.SDI_OF_EXPONENT / KP.DDBH_RD_SDIMAX\n"
             "def _share(bal, baph):\n    baph_a = np.asarray(baph, float)\n    return np.where(baph_a > 0, np.asarray(bal, float) / np.where(baph_a > 0, baph_a, 1.0), 0.0)\n"
             "def stage3_w(dbh, rht, baph, bal, sdi=None):\n    \"\"\"Stage 3 ordering weight (tree death probability, cloglog), v105d single implementation; form by koa_params.STAGE3_FORM.\"\"\"\n"
             "    C = KP.STAGE3_COEF\n    if getattr(KP, \"STAGE3_FORM\", \"v105b\") == \"M3a\":\n        if sdi is None:\n            raise ValueError(\"STAGE3_FORM M3a needs sdi\")\n"
             "        rd = rd_from_sdi(sdi); x = _share(bal, baph) * rd\n"
             "        return np.clip(1.0 - np.exp(-np.exp(C['c0'] + C['c1'] * np.log(np.maximum(dbh, 0.1)) + C['c2'] * rht + C['c3_lnRD'] * np.log(np.maximum(rd, KP.RD_FLOOR_STAGE3)) + C['c4_lnshareRD'] * np.log(x + 1.0))), 1e-9, 1.0)\n"
             "    return np.clip(1.0 - np.exp(-np.exp(C['c0'] + C['c1'] * np.log(np.maximum(dbh, 0.1)) + C['c2'] * rht + C['c3'] * np.log(baph + 1.0) + C['c4'] * np.log(np.maximum(bal, 0.0) + 1.0))), 1e-9, 1.0)\n"
             "_CALRNG = [None]\n")
    old = """def predict_HT(dbh, baph, qmd, byi, use_byi=True, dbhmax=None):
    a0, a1, b, c, g1, g2 = (HT_P[k] for k in ("a0", "a1", "b", "c", "g1", "g2"))"""
    t = sub1(t, old, old.replace("dbhmax=None):", "dbhmax=None, rd=None):"))
    old = "    ht = inter * (1 - np.exp(-b * dbh)) ** c * np.exp(g1 * ln(baph + 1) + g2 * rdbh)\n"
    t = sub1(t, old, "    if getattr(KP, \"HT_FORM\", \"v105b\") == \"H1a\":   # v105d: ln RD in place of ln(BAPH+1); RD from (baph, qmd) unless given\n"
             "        r = rd_from_baph_qmd(baph, qmd) if rd is None else np.asarray(rd, float)\n"
             "        ht = inter * (1 - np.exp(-b * dbh)) ** c * np.exp(g1 * ln(np.maximum(r, KP.RD_FLOOR_HT)) + g2 * rdbh)\n"
             "    else:\n    " + old)
    old = """def predict_HCB(dbh, ht, bal, baph, byi):
    p = HCB_P
    eta = (p["b0"] + p["b1"] * _sqrt(ht / 100.0)
           + p["b2"] * ln(np.maximum(ht / np.maximum(dbh, 0.1), 0.5))
           + p["b3"] * _sqrt(bal * baph + 1)
           + p["b4"] * ln(baph + 1)
           + p["b5"] * ln(np.maximum(byi, 1) / 100.0))
"""
    t = sub1(t, old, """def predict_HCB(dbh, ht, bal, baph, byi, rd=None):
    p = HCB_P
    if getattr(KP, "HCB_FORM", "v105b") == "C2h":   # v105d: sqrt(share RD + 1), ln RD
        if rd is None:
            raise ValueError("HCB_FORM C2h needs rd (live-list RD of the step)")
        rd = np.asarray(rd, float)
        eta = (p["b0"] + p["b1"] * _sqrt(ht / 100.0)
               + p["b2"] * ln(np.maximum(ht / np.maximum(dbh, 0.1), 0.5))
               + p["b3"] * _sqrt(_share(bal, baph) * rd + 1)
               + p["b4"] * ln(np.maximum(rd, KP.RD_FLOOR_HCB))
               + p["b5"] * ln(np.maximum(byi, 1) / 100.0))
    else:
        eta = (p["b0"] + p["b1"] * _sqrt(ht / 100.0)
           + p["b2"] * ln(np.maximum(ht / np.maximum(dbh, 0.1), 0.5))
           + p["b3"] * _sqrt(bal * baph + 1)
           + p["b4"] * ln(baph + 1)
           + p["b5"] * ln(np.maximum(byi, 1) / 100.0))
""")
    old = "    def predict_HCB(cls, dbh, ht, bal, baph, byi):\n        p = cls.HCB\n"
    t = sub1(t, old, old + "        if getattr(KP, \"HCB_FORM\", \"v105b\") != \"v105b\":\n            raise RuntimeError(\"LineageA.predict_HCB is the v105b form; use koa_equations.predict_HCB(..., rd=) (v105d)\")\n")
    old = """        lp = (p["b0"] + p["b1"] * ln(ht + 1) + p["b2"] * ht
              + p["b3"] * bal**2 / ln(ht + 5) + p["b4"] * ln(bal + 1)
              + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(baph * ht)
              + p["b7"] * planted * np.minimum(ht, KP.DDBH_HT_TRUNCATION_M)   # fitted linear form, 2026-09-16
              + p["b8"] * ln(np.maximum(byi, 1)) + p.get("b9", 0.0) * planted)
"""
    t = sub1(t, old, """        if getattr(KP, "DHT_FORM", "v105b") in ("K3c1h", "K3p"):   # v105d: RD-weighted relative competition (K3c1h: b3 = 0)
            if sdi is None:
                raise ValueError("DHT_FORM %s needs sdi (live-list SDI of the step)" % KP.DHT_FORM)
            rd = rd_from_sdi(sdi); x = _share(bal, baph) * rd
            b3 = p["b3"] if KP.DHT_FORM == "K3p" else 0.0
            lp = (p["b0"] + p["b1"] * ln(ht + 1) + p["b2"] * ht
                  + b3 * x**2 / ln(ht + 5) + p["b4"] * ln(x + 1)
                  + p["b5"] * ln(np.maximum(cr, 0.01)) + p["b6"] * _sqrt(rd * ht)
                  + p["b7"] * planted * np.minimum(ht, KP.DDBH_HT_TRUNCATION_M)
                  + p["b8"] * ln(np.maximum(byi, 1)) + p.get("b9", 0.0) * planted)
        else:
""" + old.replace("        lp = (", "            lp = (", 1))
    open(p, "w").write(t)
    # projector and the two standalone projection consumers
    for f, reps in (("koa_projector.py", [("from koa_equations import predict_HT, predict_HCB, bal_fraction, stand_bal, LINEAGES",
                                           "from koa_equations import predict_HT, predict_HCB, bal_fraction, stand_bal, LINEAGES, rd_from_sdi, stage3_w   # v105d"),
                                          ("        HCB = float(predict_HCB(DBH, HT, BAL_avg, BAPH, byi))", "        HCB = float(predict_HCB(DBH, HT, BAL_avg, BAPH, byi, rd=rd_from_sdi(SDI)))   # v105d rd"),
                                          ("        hcb = predict_HCB(dbh, ht, bal, baph, byi)\n", "        hcb = predict_HCB(dbh, ht, bal, baph, byi, rd=rd_from_sdi(sdi))   # v105d rd\n")]),
                    ("run_candidates.py", [("from koa_equations import predict_HT, predict_HCB, stand_bal, LINEAGES", "from koa_equations import predict_HT, predict_HCB, stand_bal, LINEAGES, rd_from_sdi, stage3_w   # v105d"),
                                           ("        hcb = predict_HCB(dbh, ht, bal, baph, byi)\n", "        hcb = predict_HCB(dbh, ht, bal, baph, byi, rd=rd_from_sdi(sdi))   # v105d rd\n"),
                                           ("\n    hcb = predict_HCB(dbh, ht, bal, baph, byi)\n", "\n    hcb = predict_HCB(dbh, ht, bal, baph, byi, rd=rd_from_sdi(tph * (max(qmd, 0.1) / P.INDEX_DIAMETER_CM) ** P.SDI_OF_EXPONENT))   # v105d rd (sdi_of of koa_projector)\n")]),
                    ("regen_figS4S5.py", [("from koa_equations import predict_HT, predict_HCB", "from koa_equations import predict_HT, predict_HCB, rd_from_sdi, stage3_w   # v105d"),
                                          ("        hcb = predict_HCB(dbh, ht, bal, baph, byi)\n", "        hcb = predict_HCB(dbh, ht, bal, baph, byi, rd=rd_from_sdi(sdi))   # v105d rd\n")])):
        p = f"{E}/{f}"; backup(p); t = open(p).read()
        for a, b in reps: t = sub1(t, a, b)
        t, n = S3_OLD.subn("stage3_w(dbh, rht, baph, bal, sdi)", t); print(f, "Stage 3 literal expressions replaced:", n); assert n >= 1
        open(p, "w").write(t)
    p = f"{E}/HiGy.R"; backup(p); t = open(p).read()
    if not t.startswith("## v105d NOTE"):
        t = ("## v105d NOTE (2026-11-02): this FVS-HI mirror carries the v105c dDBH K3c1 code path only. The v105d forms of Eq. 2 (H1a), Eq. 3 (C2h), dHT (K3c1h)\n"
             "## and Stage 3 (M3a) are implemented in the Python engine of record (koa_equations.py, koa_projector.py) and are NOT mirrored here.\n") + t
        open(p, "w").write(t)
    print("form code added; HT_FORM HCB_FORM DHT_FORM STAGE3_FORM = v105b")
elif MODE == "deploy":
    exec(open(f"{W}/v105d/deploy_v105d.py").read())
