"""patch_jointmc.py (2026-09-16, v99 round): switch the engine Monte Carlo to joint, source-level parameter rows.
Usage: python3 patch_jointmc.py ENGINE_DIR JOB_DIR
cal_reset restores every base value and rewinds the row counter. cal_draw reads the next row of
out_joint/K_joint_draws.csv and sets the height vector, both increment vectors, the four origin multipliers,
the Stage 1 occurrence coefficients with their mean annual occurrence, and the natural mortality level.
The call sits after the drivers' own normal draws, so the Garcia alpha and the diameter CF streams are unchanged,
and the drivers' independent height and b8 draws are overwritten by the joint row."""
import os, re, sys, shutil
E, J = sys.argv[1], sys.argv[2]
os.makedirs(os.path.join(E, "out_joint"), exist_ok=True)
for f in ("K_joint_draws.csv", "K_joint_summary.csv", "K_joint_cor.csv", "K_joint_source_sets.csv", "K_joint_counts.txt"):
    shutil.copy(os.path.join(J, "out_span", f), os.path.join(E, "out_joint", f))
p = os.path.join(E, "koa_equations.py"); s = open(p).read()
old = s[s.index("_CALRNG = [None]"):s.index("# ----------------------------------------------------------------------------\n# SHARED STATIC EQUATIONS")]
new = '''_CALRNG = [None]
_MORTRNG = [None]
_JOINT = [None, 0]
_JBASE = {}
def _joint_rows():
    if _JOINT[0] is None:
        import csv
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), KP.JOINT_DRAWS_FILE)
        with open(path) as fh:
            _JOINT[0] = [{k: (v if k == "sources" else float(v)) for k, v in r.items()} for r in csv.DictReader(fh)]
    return _JOINT[0]
def _joint_capture():
    import threestage as _TS
    _JBASE.update(HT=dict(HT_P), DD=dict(LineageA.DDBH), DH=dict(LineageA.DHT), S1=dict(_TS.S1), PBAR=float(_TS.P_BAR))
def cal_reset():
    """Joint Monte Carlo, 2026-09-16 (v99): restore every jointly drawn value and rewind the row counter."""
    import threestage as _TS
    LineageA.CAL_DDBH, LineageA.CAL_DHT = KP.CAL_DDBH, KP.CAL_DHT
    KP.MORT_CAL_LIVE[:] = list(KP.MORT_CAL)
    HT_P.update(_JBASE["HT"]); LineageA.DDBH.update(_JBASE["DD"]); LineageA.DHT.update(_JBASE["DH"])
    _TS.S1.update(_JBASE["S1"]); _TS.P_BAR = _JBASE["PBAR"]
    _JOINT[1] = 0
def joint_assert_clean(where):
    """Joint Monte Carlo state check, 2026-09-16 (v99): every jointly drawn value is back at its base."""
    import threestage as _TS
    live = (dict(HT_P), dict(LineageA.DDBH), dict(LineageA.DHT), dict(_TS.S1), float(_TS.P_BAR),
            tuple(LineageA.CAL_DDBH), tuple(LineageA.CAL_DHT), list(KP.MORT_CAL_LIVE), _JOINT[1])
    base = (_JBASE["HT"], _JBASE["DD"], _JBASE["DH"], _JBASE["S1"], _JBASE["PBAR"],
            tuple(KP.CAL_DDBH), tuple(KP.CAL_DHT), list(KP.MORT_CAL), 0)
    if live != base:
        raise SystemExit("H6 FAIL, joint Monte Carlo state leaked at %s" % where)
def cal_draw():
    """Joint Monte Carlo, 2026-09-16 (v99): one row of source-resampled, jointly drawn parameters."""
    import threestage as _TS
    rows = _joint_rows()
    if _JOINT[1] >= len(rows):
        raise RuntimeError("joint Monte Carlo table exhausted at row %d; generate more rows" % _JOINT[1])
    r = rows[_JOINT[1]]; _JOINT[1] += 1
    for k in ("a0", "a1", "b", "c", "g1", "g2"):
        HT_P[k] = r["ht_" + k]
    for j in range(10):
        LineageA.DDBH["b%d" % j] = r["d_b%d" % j]; LineageA.DHT["b%d" % j] = r["h_b%d" % j]
    LineageA.CAL_DDBH = (r["cal_dd_nat"], r["cal_dd_plt"]); LineageA.CAL_DHT = (r["cal_dh_nat"], r["cal_dh_plt"])
    _TS.S1["intercept"] = r["s1_int"]; _TS.S1["lnSDI"] = r["s1_lnsdi"]; _TS.S1["planted"] = r["s1_pl"]; _TS.P_BAR = r["pbar"]
    KP.MORT_CAL_LIVE[0] = r["kmort"]

'''
s = s.replace(old, new)
if not re.search(r"^import os", s, re.M):
    s = s.replace("\nimport warnings\n", "\nimport os\nimport warnings\n", 1)
    assert re.search(r"^import os", s, re.M)
s = s.rstrip("\n") + "\n\n_joint_capture()   # base values for the joint Monte Carlo, 2026-09-16 (v99)\n"
open(p, "w").write(s)
r_ = os.path.join(E, "regen_m1.py"); u = open(r_).read()
a_ = '        raise SystemExit("H6 FAIL, parameter state leaked at %s" % where)\n'
assert u.count(a_) == 1
u = u.replace(a_, a_ + '    KE.joint_assert_clean(where)   # joint Monte Carlo state, 2026-09-16 (v99)\n')
open(r_, "w").write(u)
f_ = os.path.join(E, "regen_figS4S5.py"); v = open(f_).read()
b_ = "        for _ in range(si * N_REPS):      # keep the stream position scenario-specific\n            set_params(rng)\n"
assert v.count(b_) == 1
v = v.replace(b_, "        for _j in range(si * N_REPS):      # keep the stream position scenario-specific\n"
                  "            if _j % N_REPS == 0:\n                KE._JOINT[1] = 0   # joint rows restart with each skipped block, 2026-09-16 (v99)\n"
                  "            set_params(rng)\n")
open(f_, "w").write(v)
q = os.path.join(E, "koa_params.py"); t = open(q).read()
t = t.rstrip("\n") + '\nJOINT_DRAWS_FILE = "out_joint/K_joint_draws.csv"   # joint, source-level Monte Carlo rows, 2026-09-16 (v99)\n'
open(q, "w").write(t)
with open(os.path.join(E, "PATCH_REPORT_JOINT.md"), "w") as fh:
    fh.write("# Joint Monte Carlo patch, 2026-09-16 (v99)\n\n" + __doc__ + "\n")
print("patched", p, q, r_, f_)
