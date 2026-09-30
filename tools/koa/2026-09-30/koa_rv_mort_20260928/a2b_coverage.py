#!/usr/bin/env python3
"""a2b_coverage.py  empirical coverage of the nominal 95% Monte Carlo interval (2.5th to 97.5th percentile
of the replicate projections) on the 23 validation plots, pooled, by origin and by source; FIA point errors
with and without the natural level factor. Plot identifiers are replaced by an anonymous index on output."""
import os, numpy as np, pandas as pd
from math import comb
JOB = os.path.dirname(os.path.abspath(__file__)); O = os.path.join(JOB, "out_a2")
rng = np.random.default_rng(20260928); B = 2000
R = pd.read_csv(os.path.join(O, "reps_validation.csv")); P = pd.read_csv(os.path.join(O, "point_with_level.csv"))
NL = pd.read_csv(os.path.join(O, "point_no_level.csv"))
nrep = R.rep.nunique(); print("replicates", nrep, "rows", len(R), "min plots per rep", R.groupby("rep").size().min())
V = {"survival": ("obs_surv", "pr_surv"), "BA": ("obsBAPH", "prBAPH"), "QMD": ("obsQMD", "prQMD")}
q = R.groupby("pid").agg(**{f"{v}_{s}": (c[1], f) for v, c in V.items() for s, f in
                            (("lo", lambda x: np.percentile(x, 2.5)), ("hi", lambda x: np.percentile(x, 97.5)), ("med", "median"))})
D = P.set_index("pid").join(q)
D["source"] = [p.split("|")[0] for p in D.index]; D["inst"] = ["|".join(p.split("|")[:2]) for p in D.index]
D["origin"] = np.where(D.planted == 1, "planted", "natural")
for v, (o, p) in V.items():
    D[f"{v}_cov"] = (D[o] >= D[f"{v}_lo"]) & (D[o] <= D[f"{v}_hi"])
    D[f"{v}_side"] = np.where(D[o] < D[f"{v}_lo"], "below", np.where(D[o] > D[f"{v}_hi"], "above", "inside"))
    D[f"{v}_width"] = D[f"{v}_hi"] - D[f"{v}_lo"]
def cp(k, n, a=0.05):
    from scipy.stats import beta  # may be absent
    return (beta.ppf(a / 2, k, n - k + 1) if k > 0 else 0.0, beta.ppf(1 - a / 2, k + 1, n - k) if k < n else 1.0)
def cp_exact(k, n, a=0.05):   # Clopper-Pearson by bisection on the binomial cdf, no scipy
    cdf = lambda x, p: sum(comb(n, i) * p ** i * (1 - p) ** (n - i) for i in range(x + 1))
    def solve(f):
        lo, hi = 0.0, 1.0
        for _ in range(60):
            m = (lo + hi) / 2
            if f(m): lo = m
            else: hi = m
        return (lo + hi) / 2
    L = 0.0 if k == 0 else solve(lambda p: 1 - cdf(k - 1, p) < a / 2)
    U = 1.0 if k == n else solve(lambda p: cdf(k, p) > a / 2)
    return L, U
def clboot(sub, col):
    g = sub.groupby("inst")[col].agg(["sum", "count"]); ks = g.index.to_numpy()
    if len(ks) < 2: return (np.nan, np.nan, len(ks))
    b = []
    for _ in range(B):
        s = rng.choice(ks, len(ks), replace=True); b.append(g.loc[s, "sum"].sum() / g.loc[s, "count"].sum())
    return (np.percentile(b, 2.5), np.percentile(b, 97.5), len(ks))
groups = {"pooled": D, "natural": D[D.origin == "natural"], "planted": D[D.origin == "planted"],
          "DOFAW": D[D.source == "DOFAW"], "FIA": D[D.source == "FIA"], "PSP": D[D.source == "PSP"],
          "natural DOFAW": D[(D.origin == "natural") & (D.source == "DOFAW")]}
rows = []
for gname, sub in groups.items():
    for v in V:
        k = int(sub[f"{v}_cov"].sum()); n = len(sub); L, U = cp_exact(k, n); bl, bh, nc = clboot(sub, f"{v}_cov")
        rows.append(dict(group=gname, variable=v, n_plots=n, n_installations=sub.inst.nunique(), covered=k, coverage=round(k / n, 3),
                         cp_lo=round(L, 3), cp_hi=round(U, 3), inst_boot_lo=round(bl, 3), inst_boot_hi=round(bh, 3),
                         below=int((sub[f"{v}_side"] == "below").sum()), above=int((sub[f"{v}_side"] == "above").sum()),
                         median_width=round(float(sub[f"{v}_width"].median()), 3)))
C = pd.DataFrame(rows); C.to_csv(os.path.join(O, "a2_coverage.csv"), index=False); print(C.to_string(index=False))
# anonymous per-plot table
D = D.reset_index(); D["plot_index"] = [f"{s}-{i+1}" for i, s in enumerate(D.source)]
anon_inst = {k: f"I{j+1}" for j, k in enumerate(D.inst.unique())}; D["inst_index"] = D.inst.map(anon_inst)
keep = ["plot_index", "inst_index", "origin", "ny"] + [c for c in D.columns if any(c.startswith(v + "_") for v in V)] + ["obs_surv", "pr_surv", "obsBAPH", "prBAPH", "obsQMD", "prQMD"]
D[keep].round(4).to_csv(os.path.join(O, "a2_plot_intervals_anon.csv"), index=False)
# FIA errors with and without level (pred minus obs)
N = NL.set_index("pid")
out = []
for lab, T in (("with level factor", P.set_index("pid")), ("without level factor (MORT_CAL natural = 1)", N)):
    for gname, mask in (("FIA 6", lambda i: i.startswith("FIA")), ("natural 12", None)):
        sel = [i for i in T.index if (mask(i) if mask else T.loc[i, "planted"] == 0)]
        t = T.loc[sel]
        out.append(dict(run=lab, group=gname, n=len(t),
                        surv_pred_minus_obs=round(float((t.pr_surv - t.obs_surv).mean()), 3),
                        BA_pred_minus_obs=round(float((t.prBAPH - t.obsBAPH).mean()), 2),
                        QMD_pred_minus_obs=round(float((t.prQMD - t.obsQMD).mean()), 2),
                        obs_BA_mean=round(float(t.obsBAPH.mean()), 2), obs_surv_mean=round(float(t.obs_surv.mean()), 3)))
F = pd.DataFrame(out); F.to_csv(os.path.join(O, "a2_fia_level_errors.csv"), index=False); print(F.to_string(index=False))
# FIA per-subplot, anonymous
f = D[D.plot_index.str.startswith("FIA")][["plot_index", "inst_index", "obs_surv", "pr_surv", "survival_lo", "survival_hi", "obsBAPH", "prBAPH", "BA_lo", "BA_hi", "obsQMD", "prQMD", "QMD_lo", "QMD_hi"]]
f = f.merge(pd.DataFrame(dict(plot_index=f.plot_index.values, pr_surv_nolevel=N.loc[[i for i in N.index if i.startswith("FIA")], "pr_surv"].values,
                              prBAPH_nolevel=N.loc[[i for i in N.index if i.startswith("FIA")], "prBAPH"].values)), on="plot_index")
f.round(3).to_csv(os.path.join(O, "a2_fia_subplots_anon.csv"), index=False); print(f.round(3).to_string(index=False))
