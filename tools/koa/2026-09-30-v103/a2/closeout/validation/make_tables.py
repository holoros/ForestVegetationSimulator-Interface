#!/usr/bin/env python3
"""make_tables.py (2026-09-30). Table C1 and C2 for the plot-level validation. Bias is PREDICTED MINUS OBSERVED throughout.
Reads val_v103_plotlevel.csv, val_v102_plotlevel.csv, fia_plotunits_v10x.csv and, for the before figures, ../../out/val_v103.csv
and ../../out/val_gate.csv. TOST exactly as compare_v103.equiv (5000 plot bootstrap draws, seed 20260917, 90 percent interval,
region 25 percent of |mean obs|, slope of obs on pred within 0.75 to 1.25) with the bias sign flipped to pred minus obs."""
import os, numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "..", "..", "out")
DIST = "FIA|15-1-1-2628"
def load(tag):
    return pd.read_csv(os.path.join(HERE, f"val_{tag}_plotlevel.csv"))
def before(f):
    r = pd.read_csv(os.path.join(OUT, f)); r["origin"] = np.where(r.planted == 1, "planted", "natural")
    r["obs_surv_count"] = r.obs_surv; r["obs_surv_w"] = np.nan; r["role"] = r.origin; r["in_sample"] = False; return r
def groups(r, sens=False):
    nd = r.role != "disturbance"
    g = [("all (excl. 2628)", nd), ("natural (excl. 2628)", nd & (r.origin == "natural")),
         ("natural excl. in-sample", nd & (r.origin == "natural") & ~r.in_sample.astype(bool)),
         ("planted", r.origin == "planted"), ("2628 disturbance case", r.role == "disturbance")]
    return g
def st(o, p):
    ok = np.isfinite(o) & np.isfinite(p); o, p = o[ok], p[ok]
    if len(o) == 0: return np.nan, np.nan, np.nan
    d = p - o; return float(d.mean()), float(np.sqrt((d**2).mean())), (float(np.corrcoef(o, p)[0, 1]) if len(o) > 2 else np.nan)
def c1(r, frame, glist):
    rows = []
    for lab, m in glist:
        x = r[m]; s = dict(frame=frame, group=lab, n=int(m.sum()))
        for k, o, p in (("survW", "obs_surv_w", "pr_surv"), ("survCount", "obs_surv_count", "pr_surv"), ("QMD", "obsQMD", "prQMD"), ("BA", "obsBAPH", "prBAPH")):
            b, e, c = st(x[o].to_numpy(float), x[p].to_numpy(float)); s[k + "_bias"] = b; s[k + "_RMSE"] = e; s[k + "_r"] = c
        s["mean_obsQMD"] = float(x.obsQMD.mean()) if len(x) else np.nan; s["mean_obsBA"] = float(x.obsBAPH.mean()) if len(x) else np.nan
        rows.append(s)
    return rows
def equiv(obs, pred, nboot=5000, seed=20260917):
    obs, pred = np.asarray(obs, float), np.asarray(pred, float)
    def stat(idx):
        o, p = obs[idx], pred[idx]; pc = p - p.mean()
        X = np.column_stack([np.ones_like(pc), pc]); f = np.linalg.lstsq(X, o, rcond=None)[0]
        return p.mean() - f[0], f[1]            # pred minus obs (f[0] = mean obs), slope of obs on pred
    n = len(obs); est = stat(np.arange(n)); rng = np.random.default_rng(seed)
    bs = np.array([stat(rng.integers(0, n, n)) for _ in range(nboot)])
    ci0 = np.quantile(bs[:, 0], [0.05, 0.95]); ci1 = np.quantile(bs[:, 1], [0.05, 0.95])
    ybar = obs.mean(); r0 = 0.25 * abs(ybar)
    return dict(mean_obs=ybar, bias_pred_minus_obs=est[0], bias_lo=ci0[0], bias_hi=ci0[1], region_bias=r0,
                pass_bias=bool(ci0[0] > -r0 and ci0[1] < r0), min_region_bias=max(abs(ci0)) / abs(ybar),
                slope=est[1], slope_lo=ci1[0], slope_hi=ci1[1], pass_slope=bool(ci1[0] > 0.75 and ci1[1] < 1.25))
md = []
def pipe(df):
    cols = list(df.columns); md.append("| " + " | ".join(cols) + " |"); md.append("|" + "---|" * len(cols))
    for _, r in df.iterrows():
        md.append("| " + " | ".join((f"{v:.3f}" if isinstance(v, float) else str(v)) for v in r) + " |")
    md.append("")
V3, V2 = load("v103"), load("v102")
B3, B2 = before("val_v103.csv"), before("val_gate.csv")
C = pd.DataFrame(c1(V3, "v103 plot level", groups(V3)) + c1(V2, "v102 plot level", groups(V2))
                 + c1(B3, "v103 before (a2/out/val_v103.csv)", [("all", B3.planted >= 0), ("natural", B3.planted == 0), ("planted", B3.planted == 1)])
                 + c1(B2, "v102 before (a2/out/val_gate.csv)", [("all", B2.planted >= 0), ("natural", B2.planted == 0), ("planted", B2.planted == 1)]))
# sensitivity: FIA minimum 15 live records instead of 20 (adds 15-1-1-2647 and 15-1-1-4895, 19 records each)
SEN = []
for tag, V in (("v103", V3), ("v102", V2)):
    fa = pd.read_csv(os.path.join(HERE, f"fia_plotunits_{tag}.csv")); add = fa[(~fa.pass_min) & (fa.n_records0 >= 15)]
    X = pd.concat([V, add[V.columns]], ignore_index=True)
    SEN += c1(X, f"{tag} plot level, FIA min 15 (+{len(add)} plots)", [g for g in groups(X) if g[0].startswith("natural")])
C.to_csv(os.path.join(HERE, "tableC1_v103_plotlevel.csv"), index=False)
show = ["frame", "group", "n", "survW_bias", "survW_RMSE", "survCount_bias", "QMD_bias", "QMD_RMSE", "QMD_r", "BA_bias", "BA_RMSE", "BA_r", "mean_obsQMD", "mean_obsBA"]
md.append("# Koa v103 plot-level validation (A2 close-out, red team must-change item 2)\n")
md.append("Bias is PREDICTED MINUS OBSERVED in every table and column (survival fraction, QMD cm, basal area m2/ha of the surviving initial cohort). "
          "survW: observed survival expf weighted (same definition as predicted). survCount: old count based observed survival, kept for the record. "
          "FIA units are whole plots (4 subplots pooled, x1 expansion), minimum 20 live koa records at the first measurement; FIA 15-1-1-2628 is the disturbance case and is excluded from every aggregate except its own row. "
          "in-sample: plots in the natural MORT_CAL calibration set (a2/mort/v103/H_mort_intervals_natural_mult.csv). The 'before' frames are the 23 unit files as deployed (FIA subplots, count survival), re-expressed pred minus obs.\n")
md.append("### Table C1. Validation aggregates\n"); pipe(C[show])
md.append("### Table C1 sensitivity. FIA minimum record count 15 instead of 20\n"); pipe(pd.DataFrame(SEN)[show])
E = []
for tag, V in (("v103 plot level", V3), ("v102 plot level", V2)):
    for lab, m in groups(V):
        for q, o, p in (("surv (weighted)", "obs_surv_w", "pr_surv"), ("qmd", "obsQMD", "prQMD"), ("ba", "obsBAPH", "prBAPH")):
            n = int(m.sum())
            if n < 3:
                E.append(dict(frame=tag, group=lab, quantity=q, n=n, note="n < 3, not tested")); continue
            e = equiv(V.loc[m, o], V.loc[m, p]); e.update(frame=tag, group=lab, quantity=q, n=n, note=""); E.append(e)
E = pd.DataFrame(E)[["frame", "group", "quantity", "n", "mean_obs", "bias_pred_minus_obs", "bias_lo", "bias_hi", "region_bias", "pass_bias", "min_region_bias", "slope", "slope_lo", "slope_hi", "pass_slope", "note"]]
E.to_csv(os.path.join(HERE, "tableC2_v103_plotlevel.csv"), index=False)
md.append("### Table C2. 25 percent equivalence (TOST): 90 percent plot bootstrap interval (5000 draws, seed 20260917) of mean predicted minus mean observed inside +/- 25 percent of mean observed, and slope of observed on predicted inside 0.75 to 1.25\n")
pipe(E.fillna(""))
open(os.path.join(HERE, "tableC_v103_plotlevel.md"), "w").write("\n".join(md)); print("\n".join(md))
