#!/usr/bin/env python3
"""a5/pairmc A5 summary (summarize_a5.py, copy of summarize.py reading out_a5): gate 1 and gate J checks, ordering probabilities, intervals. Writes out/*.csv and out/summary.json."""
import os, glob, json
import numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "out_a5")
W = os.path.expanduser("~/jobs/koa_v104_20261030/")
S = {}
# ---- gate J: rows 0..499 of the 1000-row joint table equal the published table
A = pd.read_csv(W + "a4/jointmc/out/K_joint_draws.csv"); B = pd.read_csv(os.path.join(HERE, "jointmc/out/K_joint_draws.csv"))
num = [c for c in A.columns if c != "sources"]
gj = float(np.abs(A[num].to_numpy(float) - B.iloc[:500][num].to_numpy(float)).max()); src_eq = bool((A.sources == B.iloc[:500].sources).all())
S["gateJ"] = dict(rows_new=len(B), max_abs_diff_rows_0_499=gj, sources_equal=src_eq, PASS=bool(gj < 1e-9 and src_eq and len(B) == 1000))
# ---- gate 1: per-replicate reproduction of reps_evenaged_M1.csv and the Table 4 ranges
G = pd.concat([pd.read_csv(f) for f in sorted(glob.glob(os.path.join(OUT, "gate1_w*.csv")))], ignore_index=True)
pt = max(json.load(open(f))["point_maxdiff"] for f in glob.glob(os.path.join(OUT, "gate1_point_w*.json")))
Rp = pd.read_csv(W + "engine_v103/out_m1/reps_evenaged_M1.csv"); Rp = Rp[Rp.year.isin([20, 30, 40])]
M = G.merge(Rp, left_on=["rep_pub", "age"], right_on=["rep", "year"], suffixes=("", "_pub"))
assert len(M) == len(G) == 9000, (len(M), len(G))
assert (M.byi == M.byi_pub).all() and (M.scen == M.scen_pub).all()
d = {v: float(np.abs(M[v] - M[v + "_pub"]).max()) for v in ("VOL", "BAPH", "QMD")}
T8 = pd.read_csv(W + "engine_v103/out_m1/table8_evenaged_M1.csv")
rows = []
for (si, scen, byi), g in G.groupby(["si", "scen", "byi"]):
    for a in (20, 40):
        x = g[g.age == a].VOL.to_numpy(float)
        sc = "Even-aged natural" if scen == "nat" else "Even-aged planted"
        t = T8[(T8.Scenario == sc) & (T8.Site.str.contains("(%d)" % byi, regex=False)) & (T8.Age == a)].iloc[0]
        lo, hi = round(float(np.nanpercentile(x, 2.5)), 2), round(float(np.nanpercentile(x, 97.5)), 2)
        rows.append(dict(origin=scen, byi=byi, age=a, n=len(x), VOL_lo_repro=lo, VOL_hi_repro=hi, VOL_lo_pub=t.VOL_lo, VOL_hi_pub=t.VOL_hi,
                         match=bool(abs(lo - t.VOL_lo) < 0.005 and abs(hi - t.VOL_hi) < 0.005)))
G1 = pd.DataFrame(rows); G1.to_csv(os.path.join(OUT, "gate1_table4_ranges.csv"), index=False)
S["gate1"] = dict(point_pm_vs_RC_maxdiff=pt, per_rep_maxdiff=d, ranges_match=int(G1.match.sum()), ranges_total=len(G1),
                  PASS=bool(pt == 0.0 and max(d.values()) < 1e-6 and G1.match.all()))
print(json.dumps(S, indent=1))
if not (S["gate1"]["PASS"] and S["gateJ"]["PASS"]):
    json.dump(S, open(os.path.join(OUT, "summary.json"), "w"), indent=1); raise SystemExit("GATE FAILED: stop")
# ---- main results
X = pd.concat([pd.read_csv(f) for f in sorted(glob.glob(os.path.join(OUT, "raw_w*.csv")))], ignore_index=True)
XB = sorted(glob.glob(os.path.join(OUT, "raw_boot_w*.csv")))   # amendment A5-B: BOOT variants from the rerun only
if XB:
    X = pd.concat([X[~X.variant.isin(["BOOT", "BOOT_PPB"])]] + [pd.read_csv(f) for f in XB], ignore_index=True)
assert not X[["VOL", "BAPH", "QMD"]].isna().any().any(), "NaN in results"
X["origin"] = np.where(X.planted == 1, "planted", "natural")
X.to_csv(os.path.join(OUT, "pairmc_reps.csv"), index=False)
Wd = X.pivot_table(index=["variant", "origin", "age", "rep"], columns="level", values="VOL").reset_index()
pr = []
def verdict(p): return "SUPPORTED" if p >= 0.90 else ("WEAK" if p > 0.50 else "NOT SUPPORTED")
for (var, org, age), g in Wd.groupby(["variant", "origin", "age"]):
    n = len(g)
    for lab, hi, lo in (("high>low", 450, 100), ("med>low", 264, 100), ("high>med", 450, 264)):
        p = float((g[hi] > g[lo]).mean()); dv = (g[hi] - g[lo]).to_numpy(float)
        pr.append(dict(variant=var, origin=org, age=age, comparison=lab, n=n, P=round(p, 4), MCSE=round(float(np.sqrt(p * (1 - p) / n)), 4),
                       diff_median=round(float(np.median(dv)), 2), diff_lo=round(float(np.percentile(dv, 2.5)), 2), diff_hi=round(float(np.percentile(dv, 97.5)), 2),
                       verdict=verdict(p), decision_variant=(var == "PPB")))
PR = pd.DataFrame(pr); PR.to_csv(os.path.join(OUT, "prob_ordering.csv"), index=False)
iv = []
for (var, org, lev, age), g in X.groupby(["variant", "origin", "level", "age"]):
    r = dict(variant=var, origin=org, level=lev, age=age, n=len(g))
    for v in ("VOL", "BAPH", "QMD"):
        x = g[v].to_numpy(float); r[v + "_med"] = round(float(np.median(x)), 2)
        r[v + "_lo"] = round(float(np.percentile(x, 2.5)), 2); r[v + "_hi"] = round(float(np.percentile(x, 97.5)), 2)
    iv.append(r)
IV = pd.DataFrame(iv); IV.to_csv(os.path.join(OUT, "intervals.csv"), index=False)
# paired P vs published Table 4 ranges (not a gate)
cmp = []
for _, t in T8[T8.Age.isin([20, 40])].iterrows():
    org = "natural" if "natural" in t.Scenario else "planted"; lev = int(t.Site.split("(")[1].rstrip(")"))
    q = IV[(IV.variant == "P") & (IV.origin == org) & (IV.level == lev) & (IV.age == t.Age)].iloc[0]
    cmp.append(dict(origin=org, level=lev, age=int(t.Age), pub_VOL=t.VOL, pub_lo=t.VOL_lo, pub_hi=t.VOL_hi, paired1000_med=q.VOL_med, paired1000_lo=q.VOL_lo, paired1000_hi=q.VOL_hi))
pd.DataFrame(cmp).to_csv(os.path.join(OUT, "paired_P_vs_table4.csv"), index=False)
BT = pd.read_csv(os.path.join(HERE, "out", "byi_true_draws.csv"))
tr = BT.groupby(["planted", "level"]).agg(first_draw_out_rate=("first_draw_out_of_range", "mean"), byi_med=("byi_true", "median"),
     byi_lo=("byi_true", lambda x: x.quantile(.025)), byi_hi=("byi_true", lambda x: x.quantile(.975)), max_draws=("n_draws", "max")).reset_index()
tr.to_csv(os.path.join(OUT, "byi_truncation.csv"), index=False)
S["n_reps_per_variant"] = int(X.groupby("variant").rep.nunique().min())
json.dump(S, open(os.path.join(OUT, "summary.json"), "w"), indent=1)
pd.set_option("display.width", 250)
print(PR[PR.variant == "PPB"].to_string(index=False)); print(PR[PR.variant != "PPB"].to_string(index=False))
print(IV[IV.age == 40][["variant", "origin", "level", "VOL_med", "VOL_lo", "VOL_hi"]].to_string(index=False)); print(tr.to_string(index=False))
