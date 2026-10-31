#!/usr/bin/env python3
"""Stage A4 (v104, 30 October 2026). Patch the engine for the three decisions of record:
 D1 deploy dDBH_L_NO (the preregistered fallback) with its CF, origin constants and SE of log c;
 D2 one removal rule for all mortality stages: the PSP 122 2019-2023 interval is excluded from the level calibration;
 D3 Stage 3 ordering uses the 4,223-record deduplicated refit of the size and competition form.
Writes out/v104_constants.json (MORT_CAL null until re-solved). Backs up every edited file with _PREV_20261030."""
import json, re, shutil, os
W = os.path.expanduser("~/jobs/koa_v104_20261030"); E = f"{W}/engine_v103"
J = json.load(open(f"{W}/out/v103_constants.json"))
L = J["DDBH_CANDIDATE_L_NO"]; coef = L["coef"]
# --- constants json
J4 = dict(J)
J4["meta"] = dict(J["meta"], job="koa_v104_20261030", stage="A4 v104 engine", date="2026-10-30",
    decisions="Aaron 2026-10-30: deploy dDBH_L_NO (preregistered fallback); exclude PSP 122 2019-2023 interval from the level calibration (one removal rule for all stages); Stage 3 ordering from the 4,223-record refit")
J4["DDBH_V103_DEPLOYED_PREV"] = dict(J["DDBH"], deploy=False, note="v103 deployment (v102 vector re-solved), superseded 2026-10-30")
D = dict(L); D["deploy"] = True; D["fit"] = "dDBH_L_NO"; D["note"] = "deployed 2026-10-30 (Aaron): the preregistered fallback, smallest maximum equivalence region among candidates"
J4["DDBH"] = D
reg = json.load(open(f"{W}/a2/registry/numbers_v103.json"))
s3 = {r["term"]: r for r in reg["surv_coef"]["value"] if r.get("sample") == "recovered" and r.get("spec") == "size_competition_only"}
order = ["(Intercept)", "log(dbh)", "rht", "log(baph + 1)", "log(bal + 1)"]
J4["STAGE3"] = {"form": "death response cloglog, eta = c0 + c1 ln(DBH) + c2 rHT + c3 ln(BAPH+1) + c4 ln(BAL+1); only the ordering is used",
    "sample": "recovered (ii), 4,223 records, 877 deaths, deduplicated, v103 covariates",
    "coef": {f"c{i}": s3[t]["estimate"] for i, t in enumerate(order)},
    "ci95_boot": {f"c{i}": [s3[t]["boot_lo"], s3[t]["boot_hi"]] for i, t in enumerate(order)},
    "prev_4911": {"c0": -2.13468022306448, "c1": -0.818899541466801, "c2": -0.813105157217597, "c3": 0.382953931412773, "c4": 0.346317281270796}}
J4["MORT_CAL"] = {"value": None, "note": "re-solve on the v104 engine with the PSP 122 2019-2023 interval excluded (23 natural intervals)"}
json.dump(J4, open(f"{W}/out/v104_constants.json", "w"), indent=1)
def backup(p):
    b = p.replace(".py", "_PREV_20261030.py").replace(".R", "_PREV_20261030.R") if not p.endswith("_PREV_20261030.py") else p
    if not os.path.exists(b): shutil.copy(p, b)
# --- koa_equations.py vector
p = f"{E}/koa_equations.py"; backup(p); t = open(p).read()
new = ("    DDBH = dict(b0=%.7f, b1=%.7f, b2=%.7f, b3=%.7f,   # dDBH_L_NO, live-list BAL, NO frame, deployed 2026-10-30 (A4-D1)\n"
       "           b4=%.7f, b5=%.7f, b6=%.7f, b7=%.7f, b8=%.7f, b9=%.7f)") % tuple(coef[f"b{i}"] for i in range(10))
t2, n = re.subn(r"    DDBH = dict\(b0=-1\.1509411.*?\n.*?b9=0\.4103534\)", new, t, flags=re.S); assert n == 1
open(p, "w").write(t2)
# --- koa_params.py constants
p = f"{E}/koa_params.py"; backup(p); t = open(p).read()
def setline(t, name, val, comment):
    t2, n = re.subn(r"^%s = .*$" % re.escape(name), "%s = %s   # %s" % (name, val, comment), t, count=1, flags=re.M); assert n == 1, name; return t2
t = setline(t, "CF_DDBH_MARGINAL", "%.5f" % L["CF"], "exp(0.5 (tau_source^2 + tau_inst^2)) of dDBH_L_NO (0.4579692, 0.7764691), 2026-10-30 (A4-D1)")
t = setline(t, "CAL_DDBH", "(%.5f, %.5f)" % tuple(L["CAL"]), "c / CF of dDBH_L_NO (c = %.5f, %.5f), 2026-10-30" % (L["c_natural"], L["c_planted"]))
t = setline(t, "CAL_DDBH_SE_LOG", "(%.5f, %.5f)" % tuple(L["CAL_SE_LOG"]), "SD of log c, 400 installation-cluster resamples within source, full refit of dDBH_L_NO, v103 frames")
t = setline(t, "MORT_CAL", "(1.0, 1.0)", "RESET 2026-10-30 for the A4 level re-solve with the PSP 122 2019-2023 interval excluded; set by a4/set_mortcal_v104.py")
s3c = J4["STAGE3"]["coef"]
block = ("\nSTAGE3_COEF = {%s}   # Stage 3 ordering, death-response cloglog on the 4,223-record deduplicated sample (A4-D3, 2026-10-30); replaces the 4,911-record vector hard-coded in koa_projector.py\n" % ", ".join('"%s": %r' % kv for kv in s3c.items()))
t = t.replace("\nALLOC_BETA = 3.0", block + "\nALLOC_BETA = 3.0", 1); assert "STAGE3_COEF" in t
open(p, "w").write(t)
# --- koa_projector.py Stage 3 lines
p = f"{E}/koa_projector.py"; backup(p); t = open(p).read()
old = "np.exp(-np.exp(-2.13468022306448 + -0.818899541466801 * np.log(np.maximum(dbh, 0.1)) + -0.813105157217597 * rht + 0.382953931412773 * np.log(baph + 1.0) + 0.346317281270796 * np.log(np.maximum(bal, 0.0) + 1.0)))"
newp = "np.exp(-np.exp(P.STAGE3_COEF['c0'] + P.STAGE3_COEF['c1'] * np.log(np.maximum(dbh, 0.1)) + P.STAGE3_COEF['c2'] * rht + P.STAGE3_COEF['c3'] * np.log(baph + 1.0) + P.STAGE3_COEF['c4'] * np.log(np.maximum(bal, 0.0) + 1.0)))"
assert t.count(old) == 2, t.count(old); t = t.replace(old, newp).replace("# respecified Stage 3, 2026-09-16", "# Stage 3 ordering from koa_params.STAGE3_COEF (A4-D3, 2026-10-30)")
open(p, "w").write(t)
print("patched; STAGE3", s3c)
