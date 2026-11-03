#!/usr/bin/env python3
"""a5/rerun/cov/cov_summ.py: Table S26 coverage on the v104 replicates (cov_reps.csv, 500 joint draws). Logic copied from
koa_rv_mort_20260928/a2b_coverage.py (percentile 2.5/97.5, exact Clopper-Pearson by bisection, installation-cluster bootstrap
seed 20260928, B 2000). Unit sets: 'plotlevel' = val_v104_plotlevel.csv units (17 after excluding FIA 15-1-1-2628, the
disturbance case, as make_tables_v104.py does; the 18-unit set is also reported) and 'subplot' = the 23 validate() units of the
v104 engine (FIA at subplot expansion, as the preliminary Table S26). Observed survival: plot level expf weighted (obs_surv_w, the
v104 validation of record) and count; subplot units count (validate() definition, as preliminary)."""
import os, numpy as np, pandas as pd
from math import comb
O = os.path.dirname(os.path.abspath(__file__))
R = pd.read_csv(os.path.join(O, "cov_reps.csv"))
DIST = "FIA|15-1-1-2628"
def cp_exact(k, n, a=0.05):
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
rows, per = [], []
for unitset, pf, survs in (("plotlevel", "cov_point_plotlevel.csv", (("survival_w", "obs_surv_w"), ("survival_count", "obs_surv_count"))),
                           ("subplot", "cov_point_subplot.csv", (("survival_count", "obs_surv_count"),))):
    rng = np.random.default_rng(20260928); B = 2000
    P = pd.read_csv(os.path.join(O, pf)).set_index("pid"); Rr = R[R.unitset == unitset]
    print(unitset, "replicates", Rr.rep.nunique(), "min units per rep", Rr.groupby("rep").size().min(), "units", len(P))
    V = dict(survs); V.update({"BA": "obsBAPH", "QMD": "obsQMD"}); PRC = {"BA": "prBAPH", "QMD": "prQMD"}
    q = Rr.groupby("pid").agg(surv_lo=("pr_surv", lambda x: np.percentile(x, 2.5)), surv_hi=("pr_surv", lambda x: np.percentile(x, 97.5)),
                              BA_lo=("prBAPH", lambda x: np.percentile(x, 2.5)), BA_hi=("prBAPH", lambda x: np.percentile(x, 97.5)),
                              QMD_lo=("prQMD", lambda x: np.percentile(x, 2.5)), QMD_hi=("prQMD", lambda x: np.percentile(x, 97.5)), nrep=("rep", "nunique"))
    D = P.join(q); D["inst"] = ["|".join(p.split("|")[:2]) for p in D.index]; D["origin"] = np.where(D.planted == 1, "planted", "natural")
    for v, o in V.items():
        k = "surv" if v.startswith("survival") else v
        D[f"{v}_cov"] = (D[o] >= D[f"{k}_lo"]) & (D[o] <= D[f"{k}_hi"])
        D[f"{v}_side"] = np.where(D[o] < D[f"{k}_lo"], "below", np.where(D[o] > D[f"{k}_hi"], "above", "inside"))
        D[f"{v}_width"] = D[f"{k}_hi"] - D[f"{k}_lo"]
    def clboot(sub, col):
        g = sub.groupby("inst")[col].agg(["sum", "count"]); ks = g.index.to_numpy()
        if len(ks) < 2: return (np.nan, np.nan)
        b = [g.loc[s, "sum"].sum() / g.loc[s, "count"].sum() for s in (rng.choice(ks, len(ks), replace=True) for _ in range(B))]
        return (np.percentile(b, 2.5), np.percentile(b, 97.5))
    nd = D.index != DIST
    groups = [("pooled", nd), ("natural", nd & (D.origin == "natural")), ("planted", nd & (D.origin == "planted")),
              ("DOFAW", nd & (D.source == "DOFAW")), ("natural DOFAW", nd & (D.source == "DOFAW") & (D.origin == "natural")),
              ("PSP", nd & (D.source == "PSP")), ("FIA", nd & (D.source == "FIA"))]
    if unitset == "plotlevel":
        groups += [("all 18 incl. 2628", D.index == D.index), ("2628 disturbance case", D.index == DIST)]
    for gname, m in groups:
        sub = D[m]
        if len(sub) == 0: continue
        for v in V:
            k = int(sub[f"{v}_cov"].sum()); n = len(sub); L, U = cp_exact(k, n); bl, bh = clboot(sub, f"{v}_cov")
            rows.append(dict(unitset=unitset, group=gname, variable=v, n_units=n, n_installations=sub.inst.nunique(), covered=k,
                             coverage=round(k / n, 3), cp_lo=round(L, 3), cp_hi=round(U, 3), inst_boot_lo=round(bl, 3), inst_boot_hi=round(bh, 3),
                             below=int((sub[f"{v}_side"] == "below").sum()), above=int((sub[f"{v}_side"] == "above").sum()),
                             median_width=round(float(sub[f"{v}_width"].median()), 3)))
    D2 = D.reset_index(); D2["unit_index"] = [f"{s}-{i+1}" for i, s in enumerate(D2.source)]; D2["unitset"] = unitset
    keep = ["unitset", "unit_index", "origin", "ny", "nrep"] + [c for c in D2.columns if c.endswith(("_cov", "_side", "_width", "_lo", "_hi"))]
    per.append(D2[keep].round(4))
C = pd.DataFrame(rows); C.to_csv(os.path.join(O, "tableS26_coverage_v104.csv"), index=False)
pd.concat(per).to_csv(os.path.join(O, "tableS26_unit_intervals_anon_v104.csv"), index=False)
pd.set_option("display.width", 220); print(C.to_string(index=False))
