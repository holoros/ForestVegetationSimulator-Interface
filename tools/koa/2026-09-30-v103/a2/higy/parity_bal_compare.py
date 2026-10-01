#!/usr/bin/env python3
"""Compare the R and Python sides of the BAL parity harness, v103, 30 September 2026.
Tolerance 1e-10 absolute on the BAL fraction (R vs Python); hand values (4 dp table) to 1e-4.
Writes out/parity_bal_compare.txt; exit 1 if any tolerance fails."""
import os, sys
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "out")
sys.path.insert(0, os.path.join(HERE, "engine"))
import koa_equations as KE
TOL = 1e-10; HTOL = 1e-4   # red team table is printed to 4 dp (0.553748 shown as 0.5538)
lines = []; fails = []
def say(s=""): lines.append(s); print(s)

# 1. lists
p = pd.read_csv(os.path.join(OUT, "parity_bal_py_lists.csv"))
r = pd.read_csv(os.path.join(OUT, "parity_bal_r_lists.csv"))
m = p.merge(r, on=["group", "case", "i"], suffixes=("_py", "_r"), validate="1:1")
assert len(m) == len(p) == len(r)
m["dfr"] = (m.frac_py - m.frac_r).abs(); m["dbal"] = (m.bal_py - m.bal_r).abs()
say("BAL PARITY, weighted live percentile, v103 (R a2/higy/engine/HiGy.R vs Python koa_equations)")
say("1. Lists")
for grp in ("hand", "edge", "random"):
    g = m[m.group == grp]
    say(f"  {grp:6s} lists {g.case.nunique():4d} records {len(g):5d}  max |frac R - Py| {g.dfr.max():.3e}  max |BAL R - Py| {g.dbal.max():.3e} m2/ha")
    if g.dfr.max() > TOL: fails.append(f"lists {grp} fraction")
h = m[m.hand.notna()]
for case, g in h.groupby("case", sort=False):
    ok_py = (g.frac_py - g.hand).abs().max() <= HTOL; ok_r = (g.frac_r - g.hand).abs().max() <= HTOL
    say(f"    {case:24s} R {np.round(g.frac_r.values, 4).tolist()}  hand {g.hand.tolist()}  py {'ok' if ok_py else 'FAIL'} r {'ok' if ok_r else 'FAIL'}")
    if not (ok_py and ok_r): fails.append(f"hand {case}")
e4 = m[m.case == "E4_equal_expf"]
say(f"    E4 equal expf vs unweighted rule of record: max diff {np.abs(e4.frac_py.values - KE.bal_percentile_fraction(e4.dbh_py.values if 'dbh_py' in e4 else e4.dbh.values)).max():.3e}")
rn = m[m.group == "random"]
nt = int((rn.groupby("case").size() - rn.groupby("case").dbh.nunique()).sum())
say(f"    random: n 2 to 40, {nt} tied records, expf {rn.expf.min():.1e} to {rn.expf.max():.0f}; worst case {rn.loc[rn.dfr.idxmax(), 'case']}")

# 2. same state, Python engine trajectory
say("2. R calc_bal_percentile() on the project_psp states (same dbh, expf, per tree per year)")
pp = pd.read_csv(os.path.join(OUT, "parity_bal_py_proj.csv"))
rs = pd.read_csv(os.path.join(OUT, "parity_bal_r_on_pystate.csv"))
pp2 = pp.copy(); pp2["frac_py"] = np.nan
for (pid, yr), g in pp2.groupby(["list", "year"]):
    pp2.loc[g.index, "frac_py"] = KE.bal_percentile_fraction_weighted(g.dbh.values, g.expf.values)
x = pp2.merge(rs.rename(columns={"frac": "frac_r"}), on=["list", "year", "tree"], suffixes=("_py", "_r"), validate="1:1")
for pid, g in x.groupby("list", sort=False):
    dfr = (g.frac_py - g.frac_r).abs().max(); dbal = (g.bal_py - g.bal_r).abs().max()
    say(f"  {pid:18s} tree-years {len(g):4d}  max |frac| {dfr:.3e}  max |BAL R - engine BAL| {dbal:.3e} m2/ha")
    if dfr > TOL: fails.append(f"same-state {pid}")

# 3. same state, HiGy.R trajectory
say("3. Python rule on the HiGyOneStand() states (phase 1, start of step)")
rp = pd.read_csv(os.path.join(OUT, "parity_bal_r_proj.csv"))
r1 = rp[rp.phase == 1]
po = pd.read_csv(os.path.join(OUT, "parity_bal_py_on_rstate.csv"))
y = r1.merge(po, on=["list", "year", "tree"], suffixes=("_r", "_py"), validate="1:1")
ba = y.groupby(["list", "year"]).ba.transform("sum")
for pid, g in y.assign(dfr=(y.bal_r - y.bal_py).abs() / ba).groupby("list", sort=False):
    say(f"  {pid:18s} tree-years {len(g):4d}  max |frac| {g.dfr.max():.3e}  max |BAL| {(g.bal_r - g.bal_py).abs().max():.3e}")
    if g.dfr.max() > TOL: fails.append(f"r-state {pid}")

# 4. the two projections side by side (not a parity test; other differences exist)
say("4. HiGyOneStand() vs project_psp, 10 years, per tree per year (start of step; descriptive)")
z = pp.merge(r1, on=["list", "year", "tree"], suffixes=("_py", "_r"), validate="1:1")
for pid, g in z.groupby("list", sort=False):
    for yr in (1, 2, 5, 10):
        q = g[g.year == yr]
        say(f"  {pid:18s} yr {yr:2d}  max|dDBH| {(q.dbh_py - q.dbh_r).abs().max():7.4f} cm  max|dHT| {(q.ht_py - q.ht_r).abs().max():7.4f} m"
            f"  max|dEXPF| {(q.expf_py - q.expf_r).abs().max():8.4f}  max|dBAL| {(q.bal_py - q.bal_r).abs().max():7.4f} m2/ha"
            f"  TPH py {q.expf_py.sum():7.1f} r {q.expf_r.sum():7.1f}")
p2 = rp[rp.phase == 2]
say(f"  HiGy.R phase 2 (crown recession) BAL uses the start of step ba column: max |sum(ba) - BA of updated list| "
    f"{(p2.groupby(['list','year']).apply(lambda g: abs(g.ba.sum() - (g.dbh**2*0.00007854*g.expf).sum())).max()):.4f} m2/ha")
say()
say("PARITY PASSED" if not fails else "PARITY FAILED: " + "; ".join(fails))
open(os.path.join(OUT, "parity_bal_compare.txt"), "w").write("\n".join(lines) + "\n")
sys.exit(1 if fails else 0)
