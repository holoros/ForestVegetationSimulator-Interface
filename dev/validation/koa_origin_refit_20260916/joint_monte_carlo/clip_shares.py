"""clip_shares.py OUT_M1 OUTCSV: share of replicates whose stand QMD comes within 0.5 cm of the harness ceiling (90.0 cm natural, 69.7 cm planted)
within 100 years, and share in which stems fall by half or more in a single year."""
import sys, pandas as pd, numpy as np
D, O = sys.argv[1], sys.argv[2]
CAPS = {"Even-aged natural": 90.0, "Even-aged planted": 69.7, "Uneven-aged natural": 90.0}; SITE = {100: "Low", 264: "Medium", 450: "High"}
rows = []
for f, lab in (("reps_evenaged_M1.csv", None), ("uneven_aged_reps_M1.csv", "Uneven-aged natural")):
    R = pd.read_csv(f"{D}/{f}"); R = R[R.year <= 100].sort_values(["rep", "year"])
    if lab is None:
        R["scenario"] = np.where(R.scen == "nat", "Even-aged natural", "Even-aged planted")
    else:
        R["scenario"] = lab
    R["cap_hit"] = R.QMD >= R.scenario.map(CAPS) - 0.5
    R["ratio"] = R.groupby(["scenario", "byi", "rep"]).TPH.transform(lambda x: x / x.shift(1))
    g = R.groupby(["scenario", "byi", "rep"]).agg(cap=("cap_hit", "any"),
                                                  half=("ratio", lambda x: bool((x <= 0.5).any()))).reset_index()
    for (sc, b), h in g.groupby(["scenario", "byi"]):
        rows.append(dict(scenario=sc, site=SITE[int(b)], reps=len(h), share_rate_ge_0p5=h.half.mean(), share_cap_bound=h.cap.mean()))
pd.DataFrame(rows).sort_values(["scenario", "site"]).to_csv(O, index=False)
print(pd.DataFrame(rows))
