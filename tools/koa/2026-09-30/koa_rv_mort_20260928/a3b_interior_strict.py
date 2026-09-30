#!/usr/bin/env python3
"""a3b_interior_strict.py  interior culmination restricted to replicates that have one (a local minimum of
net MAI followed by a rise within ages 1 to 100); replicates whose net MAI declines throughout are counted,
not coded as age 1. Same inputs as a3_culmination.py."""
import os, numpy as np, pandas as pd
JOB = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(JOB, "out_a3")
E = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102/out_m1")
SITE = {100: "Low", 264: "Medium", 450: "High"}
ev = pd.read_csv(os.path.join(E, "reps_evenaged_M1.csv"))
ua = pd.read_csv(os.path.join(E, "uneven_aged_reps_M1.csv")); ua["scen"] = "uneven"
reps = pd.concat([ev[["scen", "byi", "rep", "year", "VOL"]], ua[["scen", "byi", "rep", "year", "VOL"]]]); reps = reps[reps.year <= 100]
rows = []
for (sc, b), g in reps.groupby(["scen", "byi"]):
    a = []; none = 0; n = 0
    for r, gr in g.groupby("rep"):
        gr = gr.sort_values("year"); y = gr.year.to_numpy(); m = gr.VOL.to_numpy() / y; n += 1
        dm = np.diff(m)
        if not np.any(dm > 0): none += 1; continue
        k = int(np.argmax(dm > 0)); j = k + int(np.argmax(m[k:])); a.append(int(y[j]))
    a = np.array(a)
    rows.append(dict(scenario=sc, site=SITE[int(b)], n_reps=n, n_no_interior=none, share_no_interior=round(none / n, 3),
                     median=float(np.median(a)), lo95=float(np.percentile(a, 2.5)), hi95=float(np.percentile(a, 97.5))))
T = pd.DataFrame(rows); T.to_csv(os.path.join(OUT, "a3_culmination_interior_strict.csv"), index=False); print(T.to_string(index=False))
