#!/usr/bin/env python3
"""Diagnostic only: attribute the year 1 HiGyOneStand() vs project_psp divergence.
Evaluates the Python LineageA increments on the HiGy.R year 1 inputs, one input at a time."""
import os, sys, json
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "out")
sys.path.insert(0, os.path.join(HERE, "engine")); os.chdir(os.path.join(HERE, "engine"))
import koa_params as P
from koa_equations import LINEAGES, predict_HCB
from koa_projector import sdi_of
L = LINEAGES["A"]; CFG = json.load(open(os.path.join(HERE, "koa_parity_bal_v103.json")))
rp = pd.read_csv(os.path.join(OUT, "parity_bal_r_proj.csv")); pp = pd.read_csv(os.path.join(OUT, "parity_bal_py_proj.csv"))
out = []
for pid, C in CFG["projection"].items():
    byi, pl = C["byi"], C["planted"]
    r1 = rp[(rp.list == pid) & (rp.year == 1) & (rp.phase == 1)].set_index("tree").sort_index()
    r2 = rp[(rp.list == pid) & (rp.year == 2) & (rp.phase == 1)].set_index("tree").sort_index()
    p2 = pp[(pp.list == pid) & (pp.year == 2)].set_index("tree").sort_index()
    d, h, e, bal = r1.dbh.values, r1.ht.values, r1.expf.values, r1.bal.values
    ba = d**2*0.00007854*e; baph = ba.sum(); tph = e.sum(); qmd = np.sqrt(baph/(0.00007854*tph))
    sdi = sdi_of(tph, qmd); rht = h/h.max()
    cr_py = np.clip(1 - predict_HCB(d, h, bal, baph, byi)/np.maximum(h, 0.1), 0.05, 0.95)
    dD_r = r2.dbh.values - d; dH_r = r2.ht.values - h
    dD_pycr = L.dDBH(d, baph, bal, cr_py, byi, pl, sdi=sdi, rht=rht)
    dD_rcr  = L.dDBH(d, baph, bal, r1.cr.values, byi, pl, sdi=sdi, rht=rht)
    dH_pycr = L.dHT(h, baph, bal, cr_py, byi, pl, sdi=sdi, rht=rht)
    dH_rcr  = L.dHT(h, baph, bal, r1.cr.values, byi, pl, sdi=sdi, rht=rht)
    dH_rcr_treeba = L.dHT(h, ba, bal, r1.cr.values, byi, pl, sdi=sdi, rht=rht)
    below = h < 1.3716; dD_rcr = np.where(below, 0, dD_rcr); dD_pycr = np.where(below, 0, dD_pycr)
    out.append(f"{pid}: mean CR py(HCB) {cr_py.mean():.3f} vs R(input) {r1.cr.mean():.3f}")
    out.append(f"  dDBH  max|R - Py(py CR)| {np.abs(dD_r - dD_pycr).max():.4f}  max|R - Py(R CR)| {np.abs(dD_r - dD_rcr).max():.2e}")
    out.append(f"  dHT   max|R - Py(py CR)| {np.abs(dH_r - dH_pycr).max():.4f}  max|R - Py(R CR, plot BA)| {np.abs(dH_r - dH_rcr).max():.4f}"
               f"  max|R - Py(R CR, tree ba in b6)| {np.abs(dH_r - dH_rcr_treeba).max():.2e}")
    out.append(f"  year 1 deaths/ha  R {(e - r2.expf.values).sum():.3f}  Py {(e - p2.expf.values).sum():.3f}")
print("\n".join(out)); open(os.path.join(OUT, "diag_projection_diffs.txt"), "w").write("\n".join(out) + "\n")
