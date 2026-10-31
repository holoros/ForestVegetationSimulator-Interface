#!/usr/bin/env python3
"""a5/loio/set_mortcal_fold.py ENGINE_DIR LEVEL_CSV: as a4/set_mortcal_v104.py (MORT_CAL = (k, 1.0), MORT_CAL_SE_LOG = (plot SE log, 0.0)) for a fold engine."""
import sys, re, csv, os, math
E = os.path.abspath(sys.argv[1]); r = [x for x in csv.DictReader(open(sys.argv[2])) if x["form"] == "mult"][0]
k = float(r["level"]); se = float(r["plot_se_log"]); assert math.isfinite(k), "non-finite level"
p = f"{E}/koa_params.py"; t = open(p).read()
t, n = re.subn(r"^MORT_CAL = .*$", "MORT_CAL = (%.5f, 1.0)   # a5/loio fold natural level, %s intervals" % (k, r["n_intervals"]), t, count=1, flags=re.M); assert n == 1
t, n = re.subn(r"^MORT_CAL_SE_LOG = .*$", "MORT_CAL_SE_LOG = (%.5f, 0.0)   # a5/loio fold plot bootstrap SD log k" % se, t, count=1, flags=re.M); assert n == 1
open(p, "w").write(t)
sys.path.insert(0, E); sys.dont_write_bytecode = True
import koa_params as KP
print("MORTCAL", E, KP.MORT_CAL, KP.MORT_CAL_SE_LOG, "n_intervals", r["n_intervals"], flush=True)
