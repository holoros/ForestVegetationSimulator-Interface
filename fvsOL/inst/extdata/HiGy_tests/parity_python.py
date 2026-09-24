#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Python side of the HiGy.R 0.4.0 fixture harness (18 cases). Adapted 23 September 2026
from the 11 September parity harness to add the origin mortality level factor
exactly as the engine of record applies it (regen_m1.py _gated, lines 42 to 46).
Run with KOA_ENGINE set to the Python engine of record directory (engine_v102).

Imports the DEPLOYED source unmodified (koa_mortality_garcia.py, koa_equations.py,
koa_params.py, koa_survival_calibrated_py.py, threestage.py) and reproduces, case by
case, exactly what run_candidates.project() does per year:

    h0, h1   = h_from_qmd(QMD0), h_from_qmd(QMD1)
    m_garcia = stand_mortality("garcia_qmd_anchored", N0, h0, h1, planted, sdi)
    m_stand  = clip(rate_M1(m_garcia, sdi, planted) * mort_cal(planted), 0, 0.95)
               (clip(m_garcia * mort_cal(planted), 0, 0.95) when SDI is not finite)
    w        = clip(1 - exp(-exp(respecified Stage 3 eta)), 1e-9, 1)          # tree_eq
             | exp(-ALLOC_BETA * (dbh/qmd - 1))                                # rel_size
    m_i      = m_stand * w / max(wbar, 1e-9)
    m_tree   = renormalize_to_stand_rate(m_i, expf, m_stand, cap=ALLOC_MORT_CAP)
    deaths_i = expf * m_tree

Writes expected_python_stand.csv and expected_python_tree.csv. Nothing is refitted and no
constant is defined here.
"""
import json, os, sys, warnings
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ENGINE_DIR = os.environ["KOA_ENGINE"]
sys.path.insert(0, ENGINE_DIR)
os.chdir(ENGINE_DIR)          # threestage.py reads out_stage1/ relative to itself

import koa_params as P
import koa_mortality_garcia as MG
from koa_equations import LINEAGES
from koa_survival_calibrated_py import renormalize_to_stand_rate
import threestage as TS

L = LINEAGES["A"]
ENGINE = "garcia_qmd_anchored"
TPH_FAC = 0.00007854           # only for reporting, never enters the step

CFG = json.load(open(os.path.join(HERE, "koa_parity_cases.json")))
BYI = float(CFG["byi"])


def koa_sdi(tph, qmd):
    """Reineke SDI on the exponent of record, 1.605. Mirrors HiGy.R koa_sdi()."""
    return tph * (max(qmd, 0.1) / 25.0) ** 1.605


stand_rows, tree_rows = [], []

for c in CFG["cases"]:
    tl = CFG["treelists"][c["treelist"]]
    dbh = np.array(tl["dbh"], float)
    ht = np.array(tl["ht"], float)
    cr = np.array(tl["cr"], float)
    expf = np.array(tl["expf"], float)
    ddbh = np.array(tl["ddbh"], float)
    planted = int(c["planted"])
    mode = c["alloc_mode"]
    gate_on = bool(c.get("gate", 1))

    N0 = float(expf.sum())
    qmd0 = float(np.sqrt(np.sum(expf * dbh ** 2) / N0))
    qmd1 = float(np.sqrt(np.sum(expf * (dbh + ddbh) ** 2) / N0))
    sdi = float("nan") if c["sdi_mode"] == "none" else koa_sdi(N0, qmd0)

    h0 = float(MG.h_from_qmd(qmd0))
    h1 = float(MG.h_from_qmd(qmd1))

    # Stage 2, the deployed arm of record, floored on A1. Exactly the call
    # run_candidates.project makes.
    m_garcia = float(MG.stand_mortality(ENGINE, N0, h0, h1, planted=planted,
                                        sdi=(None if not np.isfinite(sdi) else sdi)))

    # Stage 1 gate and origin level factor, exactly regen_m1._gated.
    if gate_on and np.isfinite(sdi):
        p1 = float(TS.stage1_p(sdi, planted))
        m_stand = float(np.clip(TS.rate_M1(m_garcia, sdi, planted) * TS.mort_cal(planted), 0.0, 0.95))
    elif gate_on:
        p1 = float("nan")
        m_stand = float(np.clip(m_garcia * TS.mort_cal(planted), 0.0, 0.95))
    else:
        p1 = float("nan")
        m_stand = m_garcia

    # Stage 3.
    rht = ht / max(float(ht.max()), 0.1)
    ba_t = dbh ** 2 * TPH_FAC * expf                     # m2 ha-1 per record
    baph = float(ba_t.sum())
    order = np.argsort(-dbh, kind="stable")              # BAL on descending DBH, as HiGy.R calc_bal()
    bal = np.empty_like(ba_t); bal[order] = np.cumsum(ba_t[order]) - ba_t[order]
    if mode == "tree_eq":
        # respecified Stage 3 weight of the engine of record, verbatim from
        # engine_v102 run_candidates.py line 114 (koa_projector.py 346 and 357)
        w = np.clip(1.0 - np.exp(-np.exp(-2.13468022306448 + -0.818899541466801 * np.log(np.maximum(dbh, 0.1)) + -0.813105157217597 * rht + 0.382953931412773 * np.log(baph + 1.0) + 0.346317281270796 * np.log(np.maximum(bal, 0.0) + 1.0))), 1e-9, 1.0)
    else:
        w = np.exp(-P.ALLOC_BETA * (dbh / max(qmd0, 0.1) - 1.0))
    wbar = float(np.sum(w * expf) / max(float(expf.sum()), 1e-9))
    m_i = m_stand * w / max(wbar, 1e-9)
    with warnings.catch_warnings(record=True) as wlist:
        warnings.simplefilter("always")
        m_tree = np.asarray(renormalize_to_stand_rate(m_i, expf, m_stand,
                                                      cap=P.ALLOC_MORT_CAP), float)
        warned = int(any("cap" in str(x.message) for x in wlist))
    deaths_i = expf * m_tree
    deaths_ha = N0 * m_stand

    stand_rows.append(dict(
        label=c["label"], treelist=c["treelist"], planted=planted, alloc_mode=mode,
        gate=int(gate_on), n_tree=len(dbh), N0=N0, QMD0=qmd0, QMD1=qmd1, SDI=sdi,
        BAPH=float(np.sum(dbh ** 2 * TPH_FAC * expf)),
        H_QMD0=h0, H_QMD1=h1, m_garcia=m_garcia, p_stage1=p1, m_stand=m_stand,
        deaths_ha=deaths_ha, deaths_alloc=float(deaths_i.sum()),
        wbar=wbar, max_mort_frac=float(m_tree.max()), cap_warn=warned))
    for i in range(len(dbh)):
        tree_rows.append(dict(label=c["label"], tree=i + 1, dbh=float(dbh[i]),
                              expf=float(expf[i]), w=float(w[i]),
                              mort_frac=float(m_tree[i]), deaths=float(deaths_i[i])))


def write_csv(path, rows):
    keys = list(rows[0].keys())
    with open(path, "w") as f:
        f.write(",".join(keys) + "\n")
        for r in rows:
            f.write(",".join(("%.17g" % r[k]) if isinstance(r[k], float) else str(r[k])
                             for k in keys) + "\n")


write_csv(os.path.join(HERE, "expected_python_stand.csv"), stand_rows)
write_csv(os.path.join(HERE, "expected_python_tree.csv"), tree_rows)

print("PYTHON side, deployed source, %d cases" % len(stand_rows))
print("engine dir %s" % ENGINE_DIR)
print("mort_cal natural %.17g planted %.17g" % (TS.mort_cal(0), TS.mort_cal(1)))
print("engine %s  beta %.17g  p_bar %.17g  cap %.17g  alloc_beta %.17g"
      % (ENGINE, MG.engine_beta(ENGINE), TS.P_BAR, P.ALLOC_MORT_CAP, P.ALLOC_BETA))
print("%-22s %8s %10s %9s %16s %16s %10s" %
      ("label", "SDI", "m_garcia", "p1", "m_stand", "deaths_ha", "capwarn"))
for r in stand_rows:
    print("%-22s %8.2f %10.6f %9.6f %16.12f %16.6f %10d" %
          (r["label"], r["SDI"], r["m_garcia"], r["p_stage1"], r["m_stand"],
           r["deaths_ha"], r["cap_warn"]))
print("\nwrote expected_python_stand.csv and expected_python_tree.csv")
