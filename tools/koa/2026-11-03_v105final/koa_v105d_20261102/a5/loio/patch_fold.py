#!/usr/bin/env python3
"""a5/loio/patch_fold.py ENGINE_DIR FIT_CSV  (koa v104 A5 LOIO). Mirrors a4/patch_engine_v104.py for the fold constants:
koa_equations.py DDBH vector (%.7f), koa_params.py CF_DDBH_MARGINAL (%.5f), CAL_DDBH (%.5f), and MORT_CAL reset to (1.0, 1.0) for the level re-solve
(as A4 did before a4/run_mort_v104.sh). Stage 3 vector, CAL_DDBH_SE_LOG and everything else stay at v104. Prints the patched constants read back."""
import sys, re, csv, os
E, F = os.path.abspath(sys.argv[1]), sys.argv[2]
r = list(csv.DictReader(open(F)))[0]
assert r["status"] == "ok", r["status"]
b = [float(r[f"b{i}"]) for i in range(10)]; CF = float(r["CF"]); cal = (float(r["CAL_natural"]), float(r["CAL_planted"]))
p = f"{E}/koa_equations.py"; t = open(p).read()
new = ("    DDBH = dict(b0=%.7f, b1=%.7f, b2=%.7f, b3=%.7f,   # dDBH_L_NO LOIO fold refit (a5/loio)\n"
       "           b4=%.7f, b5=%.7f, b6=%.7f, b7=%.7f, b8=%.7f, b9=%.7f)") % tuple(b)
t2, n = re.subn(r"    DDBH = dict\(b0=[-0-9.]+.*?\n.*?b9=[-0-9.]+\)", new, t, count=1, flags=re.S); assert n == 1 and t2.count("dDBH_L_NO LOIO fold refit (a5/loio)") == 1   # v105d: count=1 = the LineageA vector (the v105c pattern also matched LineageB.DDBH, n = 2, so every v105c fold chain failed)
open(p, "w").write(t2)
p = f"{E}/koa_params.py"; t = open(p).read()
def setline(t, name, val):
    t2, n = re.subn(r"^%s = .*$" % re.escape(name), "%s = %s   # a5/loio fold %s" % (name, val, os.path.basename(F)), t, count=1, flags=re.M); assert n == 1, name; return t2
t = setline(t, "CF_DDBH_MARGINAL", "%.5f" % CF)
t = setline(t, "CAL_DDBH", "(%.5f, %.5f)" % cal)
t = setline(t, "MORT_CAL", "(1.0, 1.0)")
open(p, "w").write(t)
sys.path.insert(0, E); sys.dont_write_bytecode = True
import importlib, koa_params as KP, koa_equations as KE
print("PATCHED", E, "DDBH", KE.LineageA.DDBH if hasattr(KE, "LineageA") and hasattr(KE.LineageA, "DDBH") else "n/a",
      "CF", KP.CF_DDBH_MARGINAL, "CAL", KP.CAL_DDBH, "MORT_CAL", KP.MORT_CAL, flush=True)
