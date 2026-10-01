"""compare_v102.py (2026-09-18, track 2), adapted from ~/jobs/koa_dedup_projection_20260917/compare.py. Compare engine_v102 (all components refit),
engine_v102_inc (increment vectors, CF and CAL only) and engine_v102_alt (dDBH optimum from the start of record) against the unpatched copy.
Original docstring: Compare engine_first and engine_last against engine_dep. Writes out/tableA_pctdiff.csv, out/tableB_culmination.csv,
out/tableC_validation.csv, out/tableC_equiv.csv, out/tableD_uneven.csv and prints pipe tables (tables.md).
Equivalence follows koa_dataflags_20260917/compare.py (koa_redteam_20260916/common.R equiv_boot): b0 = mean(obs) - mean(pred),
b1 = slope of obs on pred, 5000 plot bootstrap draws, 90 percent interval, region 25 percent of |mean obs| for b0 and 1 +/- 0.25 for b1."""
import numpy as np, pandas as pd, os
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = os.path.join(HERE, "out")
TAGS = ["deployed", "v103"]; LAB = {"deployed": "V102", "v103": "V103"}; NEW = TAGS[1:]
TR = {t: pd.read_csv(f"{OUT}/traj_{t}.csv") for t in TAGS}
VA = {t: pd.read_csv(f"{OUT}/val_{t}.csv") for t in TAGS}
UN = {t: pd.read_csv(f"{OUT}/uneven_{t}.csv") for t in TAGS}
SC = [(0, 100, "Low"), (0, 264, "Medium"), (0, 450, "High"), (1, 100, "Low"), (1, 264, "Medium"), (1, 450, "High")]
VARS = ["QMD", "HT", "BAPH", "TPH", "VOL"]; AGES = [20, 40, 60, 100]
md = []
def pipe(df, fmt=None):
    cols = list(df.columns); md.append("| " + " | ".join(cols) + " |"); md.append("|" + "---|" * len(cols))
    for _, r in df.iterrows():
        md.append("| " + " | ".join((fmt(c, r[c]) if fmt else str(r[c])) for c in cols) + " |")
    md.append("")
def sel(t, p, b): return TR[t][(TR[t].planted == p) & (TR[t].byi == b)].set_index("year")
# (a)
A = []
for p, b, s in SC:
    d0 = sel("deployed", p, b)
    for t in NEW:
        d1 = sel(t, p, b)
        for a in AGES:
            row = dict(origin="planted" if p else "natural", site=f"{s} ({b})", frame=LAB[t], age=a)
            for v in VARS:
                row[v + "_dep"] = float(d0.loc[a, v]); row[v + "_new"] = float(d1.loc[a, v])
                row[v + "_pct"] = 100.0 * (d1.loc[a, v] - d0.loc[a, v]) / d0.loc[a, v]
            A.append(row)
A = pd.DataFrame(A); A.to_csv(f"{OUT}/tableA_pctdiff.csv", index=False)
md.append("### Table A. Percent difference (v103 - v102)/v102, even-aged point scenarios (M0 point path, gated M1 set-up), age 300 runs\n")
for t in NEW:
    md.append(f"#### {LAB[t]}\n")
    X = A[A.frame == LAB[t]][["origin", "site", "age"] + [v + "_pct" for v in VARS]].copy()
    X.columns = ["Origin", "Site (BYI)", "Age"] + [f"{v} %" for v in VARS]
    pipe(X, lambda c, x: f"{x:+.1f}" if isinstance(x, float) else str(x))
# deployed absolute for reference
md.append("#### v102 absolute values for reference (VOL m3/ha, BAPH m2/ha, QMD cm, HT m, TPH)\n")
X = A[A.frame == "V103"][["origin", "site", "age"] + [v + "_dep" for v in VARS]].copy(); X.columns = ["Origin", "Site (BYI)", "Age"] + VARS
pipe(X, lambda c, x: f"{x:.1f}" if isinstance(x, float) else str(x))
md.append("#### v103 absolute volume, m3/ha\n")
X = A.pivot_table(index=["origin", "site", "age"], columns="frame", values="VOL_new").reset_index()
X["DEPLOYED"] = A[A.frame == "V103"].set_index(["origin", "site", "age"]).loc[list(zip(X.origin, X.site, X.age)), "VOL_dep"].to_numpy()
X = X[["origin", "site", "age", "DEPLOYED", "V103"]]; X.columns = ["Origin", "Site (BYI)", "Age", "VOL v102", "VOL v103"]
pipe(X, lambda c, x: f"{x:.1f}" if isinstance(x, float) else str(x))
# (b)
B = []
for p, b, s in SC:
    row = dict(origin="planted" if p else "natural", site=f"{s} ({b})")
    for t in TAGS:
        d = sel(t, p, b); a0 = 10 if p == 0 else 2; mai = (d.VOL / d.index.to_numpy()).loc[a0:]
        row[f"MAI culm {LAB[t]}"] = (str(int(mai.idxmax())) + ("*" if mai.idxmax() == a0 else "")); row[f"MAI max {LAB[t]}"] = float(mai.max())
        row[f"peak VOL age {LAB[t]}"] = int(d.VOL.idxmax()); row[f"peak VOL {LAB[t]}"] = float(d.VOL.max())
    B.append(row)
B = pd.DataFrame(B); B.to_csv(f"{OUT}/tableB_culmination.csv", index=False)
md.append("### Table B. Age of net MAI culmination (standing VOL over age, searched over years 10 to 300 for natural stands because the initial stock makes VOL/age fall from year 1 for about eight years, and over years 2 to 300 for planted stands, an asterisk marks a curve that declines over the whole window with no interior culmination) and of peak standing volume, with the MAI (m3/ha/y) and VOL (m3/ha) at those ages\n")
pipe(B, lambda c, x: (f"{x:.2f}" if isinstance(x, float) else str(x)))
# (c)
Q = [("surv", "obs_surv", "pr_surv"), ("qmd", "obsQMD", "prQMD"), ("ba", "obsBAPH", "prBAPH")]
def summ(r):
    s = {"n": len(r)}
    for lab, o, p in Q:
        d = r[p] - r[o]
        s[lab + "_r"] = float(np.corrcoef(r[o], r[p])[0, 1]) if len(r) > 2 else np.nan
        s[lab + "_bias"] = float(d.mean()); s[lab + "_RMSE"] = float(np.sqrt((d ** 2).mean()))
    return s
C = []
for t in TAGS:
    r = VA[t]
    for grp, m in (("all", r.planted >= 0), ("natural", r.planted == 0), ("planted", r.planted == 1)):
        s = summ(r[m]); s.update(frame=LAB[t], group=grp); C.append(s)
C = pd.DataFrame(C)[["frame", "group", "n", "surv_r", "surv_bias", "surv_RMSE", "qmd_r", "qmd_bias", "qmd_RMSE", "ba_r", "ba_bias", "ba_RMSE"]]
C.to_csv(f"{OUT}/tableC_validation.csv", index=False)
md.append("### Table C1. 23 plot validation aggregates, bias is predicted minus observed (survival count fraction as built in A2; see a2/closeout/validation for the expf weighted, plot level rebuild) (survival fraction, QMD cm, basal area m2/ha)\n")
pipe(C, lambda c, x: (f"{x:.4f}" if isinstance(x, float) else str(x)))
def equiv(obs, pred, nboot=5000, seed=20260917):
    obs, pred = np.asarray(obs, float), np.asarray(pred, float)
    def stat(idx):
        o, p = obs[idx], pred[idx]; pc = p - p.mean()
        X = np.column_stack([np.ones_like(pc), pc]); f = np.linalg.lstsq(X, o, rcond=None)[0]
        return f[0] - p.mean(), f[1]
    n = len(obs); est = stat(np.arange(n)); rng = np.random.default_rng(seed)
    bs = np.array([stat(rng.integers(0, n, n)) for _ in range(nboot)])
    ci0 = np.quantile(bs[:, 0], [0.05, 0.95]); ci1 = np.quantile(bs[:, 1], [0.05, 0.95])
    ybar = obs.mean(); r0 = 0.25 * abs(ybar)
    return dict(mean_obs=ybar, bias_pred_minus_obs=-est[0], bias_lo=-ci0[1], bias_hi=-ci0[0], region_bias=r0,
                pass_bias=bool(ci0[0] > -r0 and ci0[1] < r0), min_region_bias=max(abs(ci0)) / abs(ybar),
                slope=est[1], slope_lo=ci1[0], slope_hi=ci1[1], pass_slope=bool(ci1[0] > 0.75 and ci1[1] < 1.25))
E = []
for t in TAGS:
    r = VA[t]
    for grp, m in (("all", r.planted >= 0), ("natural", r.planted == 0), ("planted", r.planted == 1)):
        for lab, o, p in Q:
            e = equiv(r.loc[m, o], r.loc[m, p]); e.update(frame=LAB[t], group=grp, quantity=lab, n=int(m.sum())); E.append(e)
E = pd.DataFrame(E)[["frame", "group", "quantity", "n", "mean_obs", "bias_pred_minus_obs", "bias_lo", "bias_hi", "region_bias", "pass_bias", "min_region_bias", "slope", "slope_lo", "slope_hi", "pass_slope"]]
E.to_csv(f"{OUT}/tableC_equiv.csv", index=False)
md.append("### Table C2. 25 percent equivalence on the mean (TOST, 90 percent plot bootstrap interval of mean predicted minus mean observed inside +/- 25 percent of mean obs) and on the slope (0.75 to 1.25). The overall rows are the verdicts of record, the origin rows are added here\n")
pipe(E, lambda c, x: (f"{x:.3f}" if isinstance(x, float) else str(x)))
# plot-level max change
base = VA["deployed"].set_index("pid")
for t in NEW:
    r = VA[t].set_index("pid").loc[base.index]; num = [c for c in base.columns if c.startswith("pr")]
    d = (r[num] - base[num]).abs().max(axis=1)
    md.append(f"{LAB[t]}, plots whose projected values changed (max abs diff above 1e-9), {int((d > 1e-9).sum())} of {len(d)}. Observed columns unchanged, {bool((r[[c for c in base.columns if c.startswith('obs')]] - base[[c for c in base.columns if c.startswith('obs')]]).abs().max().max() < 1e-12)}\n")
# (d)
D = []
for t in NEW:
    u0 = UN["deployed"].set_index(["byi", "age"]); u1 = UN[t].set_index(["byi", "age"])
    for (b, a), r in u0.iterrows():
        row = dict(frame=LAB[t], site=f"{r.site} ({b})", age=a)
        for v in VARS:
            row[v + "_dep"] = float(r[v]); row[v + "_pct"] = 100.0 * (u1.loc[(b, a), v] - r[v]) / r[v]
        D.append(row)
D = pd.DataFrame(D); D.to_csv(f"{OUT}/tableD_uneven.csv", index=False)
md.append("### Table D. Uneven-aged natural ingrowth scenario, point path with gated M1 mortality (regen_m1.uneven_aged set-up), percent difference (v103 - v102)/v102, with the v102 value in parentheses\n")
X = D[["frame", "site", "age"]].copy()
for v in VARS: X[v] = [f"{p:+.1f} ({d:.1f})" for p, d in zip(D[v + "_pct"], D[v + "_dep"])]
pipe(X)
open(f"{HERE}/out/tables_v103.md", "w").write("\n".join(md)); print("\n".join(md))
