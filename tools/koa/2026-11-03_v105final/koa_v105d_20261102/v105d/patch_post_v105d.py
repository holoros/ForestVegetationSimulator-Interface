#!/usr/bin/env python3
"""patch_post_v105d.py (after deploy and the MORT_CAL re-solve): downstream constants carried as literals.
- a5/pairmc/pairmc.py, pairmc_a5.py: TAU I_H, T_H (installation and tree random-intercept SD of dHT_L_NO, now K3c1h) from out/inc/fit_stats_v103.csv.
- a5/loio/make_results.py: the "of record" line reads the v105d values (dDBH unchanged; level = v105d MORT_CAL).
- core limit 6 for deterministic parallel steps (calib_mort Pool, joint draws NC, figS34 mc.cores); results unchanged by worker count."""
import os, re, json, csv, subprocess
W = os.path.expanduser("~/jobs/koa_v105d_20261102")
def backup(*ps): subprocess.run(["bash", f"{W}/v105d/backup_d.sh", *ps], check=True)
J = json.load(open(f"{W}/out/v105_constants.json")); D = J["DDBH"]; st = {r["fit"]: r for r in csv.DictReader(open(f"{W}/out/inc/fit_stats_v103.csv"))}
sD, sH = st["dDBH_L_NO"], st["dHT_L_NO"]
for f in ("a5/pairmc/pairmc.py", "a5/pairmc/pairmc_a5.py"):
    p = f"{W}/{f}"; backup(p); t = open(p).read()
    t, n = re.subn(r"^TAU = dict\(.*$", "TAU = dict(I_D=%.7f, I_H=%.7f, T_D=%.7f, T_H=%.7f)  # VarCorr of v105c dDBH_L_NO (K3c1) and v105d dHT_L_NO (K3c1h) (out/inc/fit_stats_v103.csv)"
                  % (float(sD["tau_inst"]), float(sH["tau_inst"]), float(sD["tau_tree"]), float(sH["tau_tree"])), t, count=1, flags=re.M); assert n == 1, f
    open(p, "w").write(t)
p = f"{W}/a5/loio/make_results.py"; backup(p); t = open(p).read()
t, n = re.subn(r'"Fold-to-fold range \(v105c of record: [^"]*"', '"Fold-to-fold range (v105d of record: b8 %.7f, c natural %.4f, c planted %.4f, CF %.5f, level %.5f; out/v105_constants.json):"'
               % (D["coef"]["b8"], D["c_natural"], D["c_planted"], D["CF"], J["MORT_CAL"]["value"][0]), t); assert n == 1
t = t.replace("# koa v105c LOIO results (2 Nov 2026; v104 A5 scripts, v105c engine (K3c1 dDBH) and frames)", "# koa v105d LOIO results (2 Nov 2026; v104 A5 scripts, v105d engine (K3c1 dDBH, K3c1h dHT, H1a, C2h, M3a) and frames)")
open(p, "w").write(t)
for f, a, b in (("a2/mort/calib_mort.py", "with Pool(3) as pool:   # v105c: 3 workers (core limit), results unchanged", "with Pool(6) as pool:   # v105d: 6 workers (core limit), results unchanged"),
                ("a4/joint_draws_v104.R", 'NC <- 3   # v105c core limit', 'NC <- 6   # v105d core limit'),
                ("a5/pairmc/joint_draws_pairmc.R", 'NC <- 3', 'NC <- 6'),
                ("a4/figs/figS34_v104.R", "}, mc.cores = 3))   # v105c core limit (jackknife, results unchanged)", "}, mc.cores = 6))   # v105d core limit (jackknife, results unchanged)")):
    p = f"{W}/{f}"; t = open(p).read(); n = t.count(a)
    if n >= 1: backup(p); t = t.replace(a, b, 1); open(p, "w").write(t); print("core limit", f)
    else: print("core-limit pattern not found (left)", f)
print("post patches done; TAU I_H %s T_H %s" % (sH["tau_inst"], sH["tau_tree"]))
