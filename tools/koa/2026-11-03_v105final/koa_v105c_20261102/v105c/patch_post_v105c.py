#!/usr/bin/env python3
"""patch_post_v105c.py (after patch_engine_v105c.py deploy): downstream constants that carry the deployed dDBH fit as literals.
- a5/loio/patch_fold.py: DDBH regex generalised (it matched the v105b vector literally).
- a5/loio/fits/fit_V105EXACT.csv: rebuilt from out/v105_constants.json (now the v105c constants of record; name kept so the LOIO scripts run unchanged).
- a5/loio/make_results.py: the "of record" line reads the v105c values.
- a5/pairmc/pairmc.py, pairmc_a5.py: TAU I_D, T_D (installation and tree random-intercept SD of dDBH_L_NO) from out/inc/fit_stats_v103.csv.
- core limit 3 (other jobs hold 5 of 8 cores): calib_mort Pool(4) -> 3, joint_draws NC 4 -> 3, figS34 mc.cores 4 -> 3 (deterministic; results unchanged)."""
import os, re, json, csv, subprocess
W = os.path.expanduser("~/jobs/koa_v105c_20261102")
def backup(*ps): subprocess.run(["bash", f"{W}/v105c/backup_c.sh", *ps], check=True)
J = json.load(open(f"{W}/out/v105_constants.json")); D = J["DDBH"]; st = {r["fit"]: r for r in csv.DictReader(open(f"{W}/out/inc/fit_stats_v103.csv"))}["dDBH_L_NO"]
p = f"{W}/a5/loio/patch_fold.py"; backup(p); t = open(p).read()
old = 't2, n = re.subn(r"    DDBH = dict\\(b0=-0\\.5414106.*?\\n.*?b9=0\\.2455269\\)", new, t, flags=re.S); assert n == 1   # v105 engine vector'
assert t.count(old) == 1, "patch_fold pattern"
t = t.replace(old, 't2, n = re.subn(r"    DDBH = dict\\(b0=[-0-9.]+.*?\\n.*?b9=[-0-9.]+\\)", new, t, flags=re.S); assert n == 1   # v105c: any engine vector'); open(p, "w").write(t)
p = f"{W}/a5/loio/fits/fit_V105EXACT.csv"; backup(p)
row = dict(fold="V105EXACT", status="ok", CF=D["CF"], CAL_natural=D["CAL"][0], CAL_planted=D["CAL"][1], c_natural=D["c_natural"], c_planted=D["c_planted"],
           msg="v105c constants of record from out/v105_constants.json (no refit)", **{f"b{i}": D["coef"][f"b{i}"] for i in range(10)})
with open(p, "w", newline="") as fh: w = csv.DictWriter(fh, fieldnames=list(row)); w.writeheader(); w.writerow(row)
p = f"{W}/a5/loio/make_results.py"; backup(p); t = open(p).read()
old = '"Fold-to-fold range (v105 of record: b8 0.2779335, c natural 0.4163, c planted 1.2596, CF 1.42746, level 2.51767; out/v105_constants.json):"'; assert t.count(old) == 1
t = t.replace(old, '"Fold-to-fold range (v105c of record: b8 %.7f, c natural %.4f, c planted %.4f, CF %.5f, level %.5f; out/v105_constants.json):"' % (D["coef"]["b8"], D["c_natural"], D["c_planted"], D["CF"], J["MORT_CAL"]["value"][0]))
t = t.replace("# koa v105 LOIO results (2 Nov 2026; v104 A5 scripts, v105 engine and frames)", "# koa v105c LOIO results (2 Nov 2026; v104 A5 scripts, v105c engine (K3c1 dDBH) and frames)")
open(p, "w").write(t)
for f in ("a5/pairmc/pairmc.py", "a5/pairmc/pairmc_a5.py"):
    p = f"{W}/{f}"; backup(p); t = open(p).read()
    old = "TAU = dict(I_D=0.7766421, I_H=0.2173551, T_D=0.2750139, T_H=0.2932490)  # VarCorr of v105 dDBH_L_NO, dHT_L_NO (out/inc/fit_stats_v103.csv)"; assert t.count(old) == 1, f
    t = t.replace(old, "TAU = dict(I_D=%.7f, I_H=0.2173551, T_D=%.7f, T_H=0.2932490)  # VarCorr of v105c dDBH_L_NO (K3c1) and v105b dHT_L_NO (out/inc/fit_stats_v103.csv)" % (float(st["tau_inst"]), float(st["tau_tree"])))
    open(p, "w").write(t)
for f, a, b in (("a2/mort/calib_mort.py", "with Pool(4) as pool:   # v105b: 4 workers (core limit), results unchanged", "with Pool(3) as pool:   # v105c: 3 workers (core limit), results unchanged"),
                ("a4/joint_draws_v104.R", 'N <- as.integer(Sys.getenv("KOA_NJOINT", "500")); NC <- 4', 'N <- as.integer(Sys.getenv("KOA_NJOINT", "500")); NC <- 3   # v105c core limit'),
                ("a5/pairmc/joint_draws_pairmc.R", 'NC <- 4', 'NC <- 3'),
                ("a4/figs/figS34_v104.R", "}, mc.cores = 4))   # v105b core limit (jackknife, results unchanged)", "}, mc.cores = 3))   # v105c core limit (jackknife, results unchanged)")):
    p = f"{W}/{f}"; t = open(p).read(); n = t.count(a)
    if n >= 1: backup(p); t = t.replace(a, b, 1); open(p, "w").write(t); print("core limit", f)
    else: print("core-limit pattern not found (left)", f)
print("post patches done; TAU I_D %.7f T_D %.7f" % (float(st["tau_inst"]), float(st["tau_tree"])))
