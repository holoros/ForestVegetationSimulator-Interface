#!/usr/bin/env python3
"""Build koa_parity_bal_v103.json: BAL parity cases for the weighted percentile rule.
Hand cases from red team 2 (Q1 table), edge cases (R12, n = 1, W = 0), 200 random lists
with heavy ties and weights 1e-5 to 741, and two initial tree lists for the 10 year
projection (one PSP planted, one DOFAW natural). Seeded, deterministic."""
import json, os, sys
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "engine")); os.chdir(os.path.join(HERE, "engine"))

hand = [
  dict(id="H1_ties_unequal_weight", dbh=[30, 20, 10, 10], expf=[4, 2, 1, 3], hand=[0, 0.5, 1, 1]),
  dict(id="H2_all_tied", dbh=[10, 10, 10], expf=[1, 2, 3], hand=[1, 1, 1]),
  dict(id="H3_microplot_decayed", dbh=[5, 40, 40, 12, 12, 12, 33],
       expf=[741, 59.5, 59.5, 1e-5, 59.5, 741, 59.5],
       hand=[1, 0.0358, 0.0358, 0.5692, 0.5538, 0.2431, 0.0717]),
]
edge = [
  dict(id="E1_R12_single_live", dbh=[10, 20, 30], expf=[50, 1e-5, 1e-5], hand=[1, 0, 0]),
  dict(id="E2_n1", dbh=[25.0], expf=[10.0], hand=[0]),
  dict(id="E3_W0", dbh=[10, 20, 30], expf=[0, 0, 0], hand=[0, 0, 0]),
  dict(id="E4_equal_expf", dbh=[30, 20, 20, 10, 5], expf=[24.8]*5, hand=None),
]
rng = np.random.default_rng(20260930)
fixed = np.array([1e-5, 1.0, 24.8, 59.5, 741.0])
rnd = []
for k in range(200):
    n = int(rng.integers(2, 41))
    npool = int(rng.integers(1, max(2, n // 2) + 1))
    pool = np.round(rng.uniform(2, 60, npool), 1)
    d = rng.choice(pool, n)
    w = np.where(rng.random(n) < 0.5, rng.choice(fixed, n),
                 np.exp(rng.uniform(np.log(1e-5), np.log(741.0), n)))
    rnd.append(dict(id=f"R{k+1:03d}", dbh=[float(x) for x in d], expf=[float(x) for x in w]))

import koa_longterm_validation as V
t, geo, surv = V.load(); B = V.byi_map(geo, surv); PL = V.planted_map(geo, surv)
proj = {}
for pid in ["PSP|202|2", "DOFAW|Waiakea|24"]:
    g = t[t.pid == pid]; m0 = sorted(g.Measure.dropna().unique())[0]
    g0 = g[(g.Measure == m0) & (g.Status.astype(str).str.lower() == "live") &
           (pd.to_numeric(g.DBH, errors="coerce") > 0)]
    proj[pid] = dict(byi=float(B[pid]), planted=int(PL.get(pid, 0)), measure=float(m0),
                     dbh=[float(x) for x in g0.DBH], ht=[float(x) for x in g0.HT],
                     expf=[float(x) for x in g0.EXPF], cr=0.7, n_years=10)
json.dump(dict(_note="BAL parity cases, weighted live percentile, v103, 2026-09-30. "
               "hand values from red team 2 Q1 (4 dp); tolerance 1e-10 on fractions R vs Python.",
               hand=hand, edge=edge, random=rnd, projection=proj),
          open(os.path.join(HERE, "koa_parity_bal_v103.json"), "w"), indent=1)
print("cases", len(hand), len(edge), len(rnd), {k: len(v["dbh"]) for k, v in proj.items()})
