src = open('plv_copy.py').read()
src = src.replace('HERE = os.path.dirname(os.path.abspath(__file__))',
  'HERE = os.path.expanduser("~/jobs/koa_v104_20261030/a2/closeout/validation")  # a5: inputs read from the validation dir, read only\nA5 = os.path.dirname(os.path.abspath(__file__))')
src = src.replace('ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]', 'ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]; NREP = int(sys.argv[3])')
# record unit definitions alongside results
src = src.replace('    r = run_unit(g0, g1, float(BYI[pid]), int(PL.get(pid, 0)), ny, 1.0)\n',
  '    r = run_unit(g0, g1, float(BYI[pid]), int(PL.get(pid, 0)), ny, 1.0)\n    if r is not None: DEFS_S.append((pid, (g0, g1, float(BYI[pid]), int(PL.get(pid, 0)), ny, 1.0)))\n')
src = src.replace('    r = run_unit(g0, g1, float(np.mean(bs)), pl, ny, 0.25)\n',
  '    r = run_unit(g0, g1, float(np.mean(bs)), pl, ny, 0.25)\n    if r is not None and n0 >= MIN_FIA: DEFS_U.append((pid, (g0, g1, float(np.mean(bs)), pl, ny, 0.25)))\n')
src = src.replace('sub, units, fia_all = [], [], []', 'sub, units, fia_all = [], [], []; DEFS_S, DEFS_U = [], []')
cut = src.index('# check: mirror reproduces validate()')
body = src[:cut]
tail = src[cut:src.index('for X in (U, FA):')]
loop = r'''
print(TAG, "mirror check", dmax, dpr, flush=True)
assert dpr < 1e-9
# a5 gate: point plot-level units equal the archived val_v104_plotlevel.csv
ref_pl = pd.read_csv(os.path.join(HERE, "val_v104_plotlevel.csv")).set_index("pid")
mm = U.set_index("pid").reindex(ref_pl.index)
gpl = max(float(np.nanmax(np.abs(mm[c].to_numpy(float) - ref_pl[c].to_numpy(float)))) for c in ("pr_surv", "prQMD", "prBAPH", "obs_surv_w", "obsQMD", "obsBAPH"))
print("GATE plot-level point vs val_v104_plotlevel.csv max|diff|", gpl, "units", len(U), flush=True); assert gpl < 1e-9
# subplot units (validate() definition, 23 units)
U_ids = set(u for u, _ in DEFS_U)
for u, _ in DEFS_S: U_ids.add(u)
S.to_csv(os.path.join(A5, "cov_point_subplot.csv"), index=False); U.to_csv(os.path.join(A5, "cov_point_plotlevel.csv"), index=False)
# Monte Carlo replicates: regen_m1 convention exactly as koa_rv_mort_20260928/a2_mc_validation.py (rng default_rng(RM.SEED), _CFCLIP reset)
import time
t0 = time.time(); rng = np.random.default_rng(RM.SEED); RM._CFCLIP[0] = 0
RM.set_params(None); RM.assert_clean("start")
fh = open(os.path.join(A5, "cov_reps.csv"), "w"); first = True
for i in range(NREP):
    RM.set_params(rng)
    rows = []
    for unitset, defs in (("plotlevel", DEFS_U), ("subplot", DEFS_S)):
        for pid, a in defs:
            r = run_unit(*a)
            if r is None: continue
            rows.append(dict(rep=i, unitset=unitset, pid=pid, pr_surv=r["pr_surv"], prQMD=r["prQMD"], prBAPH=r["prBAPH"]))
    pd.DataFrame(rows).to_csv(fh, header=first, index=False); first = False; fh.flush()
    if i % 10 == 0: print("rep", i, len(rows), "%.0fs" % (time.time() - t0), flush=True)
fh.close(); RM.set_params(None); RM.assert_clean("end")
print("DONE reps", NREP, "cf clipped", RM._CFCLIP[0], "wall %.0fs" % (time.time() - t0), flush=True)
'''
pre = r'''
'''
# U, S need origin/role columns before loop; replicate the role step for U
roles = '''for X in (U,):
    X["origin"] = np.where(X.planted == 1, "planted", "natural")
    X["in_sample"] = X.pid.isin(CAL)
    X["role"] = np.where(X.pid == DIST, "disturbance", X.origin)
'''
open('cov_mc.py', 'w').write('# a5/rerun/cov/cov_mc.py: built by build.py from a2/closeout/validation/plotlevel_validation.py (copied verbatim up to the\n# mirror check) plus the Monte Carlo loop of koa_rv_mort_20260928/a2_mc_validation.py. Usage: python3 cov_mc.py <engine> v104 <NREP>\n' + body + tail + roles + loop)
