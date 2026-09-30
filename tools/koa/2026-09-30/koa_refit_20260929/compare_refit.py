"""compare_refit.py (2026-09-29). Table 5 comparison v102 (reference) against refit (and refit_live sensitivity), uneven-aged rows,
culmination ages (two definitions), and the 23 plot validation comparison with the compare_v102.py aggregates and 25 percent equivalence.
Writes out/table5_compare.csv, out/culmination_compare.csv, out/validation_compare.csv, out/validation_equiv_compare.csv, out/uneven_compare.csv."""
import os, numpy as np, pandas as pd
HERE = os.path.dirname(os.path.abspath(__file__)); OUT = f"{HERE}/out"; REF = os.path.expanduser("~/jobs/koa_v102_20260918/track2/out")
TR = {"v102": pd.read_csv(f"{REF}/traj_v102.csv"), "refit": pd.read_csv(f"{OUT}/traj_refit.csv"), "refit_live": pd.read_csv(f"{OUT}/traj_refit_live.csv"), "refit2": pd.read_csv(f"{OUT}/traj_refit2.csv"), "refit2_live": pd.read_csv(f"{OUT}/traj_refit2_live.csv")}
VA = {"v102": pd.read_csv(f"{REF}/val_v102.csv"), "refit": pd.read_csv(f"{OUT}/val_refit.csv"), "refit_live": pd.read_csv(f"{OUT}/val_refit_live.csv"), "refit2": pd.read_csv(f"{OUT}/val_refit2.csv"), "refit2_live": pd.read_csv(f"{OUT}/val_refit2_live.csv")}
UN = {"v102": pd.read_csv(f"{REF}/uneven_v102.csv"), "refit": pd.read_csv(f"{OUT}/uneven_refit.csv"), "refit2": pd.read_csv(f"{OUT}/uneven_refit2.csv")}
SC = [(0, 100, "Low"), (0, 264, "Medium"), (0, 450, "High"), (1, 100, "Low"), (1, 264, "Medium"), (1, 450, "High")]
VARS = ["QMD", "HT", "BAPH", "TPH", "VOL", "MAI"]
def sel(t, p, b):
    d = TR[t][(TR[t].planted == p) & (TR[t].byi == b)].set_index("year").copy(); d["MAI"] = d.VOL / d.index.to_numpy(); return d
# ---- Table 5
rows = []
for p, b, s in SC:
    for a in (20, 40, 60, 100):
        r = dict(scenario="even-aged " + ("planted" if p else "natural"), site=f"{s} ({b})", age=a)
        for t in TR:
            d = sel(t, p, b).loc[a]
            for v in VARS: r[f"{v}_{t}"] = float(d[v])
        for t in ("refit", "refit_live", "refit2", "refit2_live"):
            for v in VARS: r[f"{v}_pct_{t}"] = 100.0 * (r[f"{v}_{t}"] - r[f"{v}_v102"]) / r[f"{v}_v102"]
        rows.append(r)
for b, s in ((100, "Low"), (264, "Medium"), (450, "High")):
    for a in (20, 40, 60, 100):
        r = dict(scenario="uneven-aged natural", site=f"{s} ({b})", age=a)
        for t in UN:
            u = UN[t][(UN[t].byi == b) & (UN[t].age == a)].iloc[0]
            for v in VARS: r[f"{v}_{t}"] = float(u.VOL / a) if v == "MAI" else float(u[v])
        for t in ("refit", "refit2"):
            for v in VARS: r[f"{v}_pct_{t}"] = 100.0 * (r[f"{v}_{t}"] - r[f"{v}_v102"]) / r[f"{v}_v102"]
        rows.append(r)
T5 = pd.DataFrame(rows); T5.to_csv(f"{OUT}/table5_compare.csv", index=False)
# ---- culmination. Definition A (track 2 / compare_v102.py): argmax of VOL/age over years 10..300 natural, 2..300 planted, asterisk if at the window start.
# Definition B (task): max of net MAI after its first local minimum (MAI falls then rises), searched over the whole 300 y path; "none" if MAI never falls first.
def culm_A(d, p):
    a0 = 10 if p == 0 else 2; mai = d.MAI.loc[a0:]; k = int(mai.idxmax()); return f"{k}{'*' if k == a0 else ''}", float(mai.max())
def culm_B(d):
    m = d.MAI.to_numpy(); yrs = d.index.to_numpy()
    i = next((i for i in range(1, len(m) - 1) if m[i] <= m[i - 1] and m[i] < m[i + 1]), None)
    if i is None: return "none", np.nan
    j = i + int(np.argmax(m[i:])); return str(int(yrs[j])), float(m[j])
C = []
for p, b, s in SC:
    r = dict(scenario="even-aged " + ("planted" if p else "natural"), site=f"{s} ({b})")
    for t in TR:
        d = sel(t, p, b); r[f"culm_track2_{t}"], r[f"MAI_at_culm_track2_{t}"] = culm_A(d, p); r[f"culm_afterMin_{t}"], r[f"MAI_at_culm_afterMin_{t}"] = culm_B(d)
        r[f"peakVOL_age_{t}"] = int(d.VOL.idxmax()); r[f"peakVOL_{t}"] = float(d.VOL.max())
    C.append(r)
C = pd.DataFrame(C); C.to_csv(f"{OUT}/culmination_compare.csv", index=False)
# ---- validation aggregates and equivalence, as compare_v102.py
Q = [("surv", "obs_surv", "pr_surv"), ("qmd", "obsQMD", "prQMD"), ("ba", "obsBAPH", "prBAPH")]
def summ(r):
    s = {"n": len(r)}
    for lab, o, p in Q:
        d = r[p] - r[o]; s[lab + "_r"] = float(np.corrcoef(r[o], r[p])[0, 1]); s[lab + "_bias"] = float(d.mean()); s[lab + "_RMSE"] = float(np.sqrt((d ** 2).mean()))
    return s
def equiv(obs, pred, nboot=5000, seed=20260917):
    obs, pred = np.asarray(obs, float), np.asarray(pred, float)
    def stat(idx):
        o, p = obs[idx], pred[idx]; pc = p - p.mean(); X = np.column_stack([np.ones_like(pc), pc]); f = np.linalg.lstsq(X, o, rcond=None)[0]; return f[0] - p.mean(), f[1]
    n = len(obs); est = stat(np.arange(n)); rng = np.random.default_rng(seed); bs = np.array([stat(rng.integers(0, n, n)) for _ in range(nboot)])
    ci0 = np.quantile(bs[:, 0], [0.05, 0.95]); ci1 = np.quantile(bs[:, 1], [0.05, 0.95]); ybar = obs.mean(); r0 = 0.25 * abs(ybar)
    return dict(mean_obs=ybar, bias_obs_minus_pred=est[0], bias_lo=ci0[0], bias_hi=ci0[1], region_bias=r0, pass_bias=bool(ci0[0] > -r0 and ci0[1] < r0),
                slope=est[1], slope_lo=ci1[0], slope_hi=ci1[1], pass_slope=bool(ci1[0] > 0.75 and ci1[1] < 1.25))
V, E = [], []
for t in VA:
    r = VA[t]
    for grp, m in (("all", r.planted >= 0), ("natural", r.planted == 0), ("planted", r.planted == 1)):
        s = summ(r[m]); s.update(frame=t, group=grp); V.append(s)
        for lab, o, p in Q:
            e = equiv(r.loc[m, o], r.loc[m, p]); e.update(frame=t, group=grp, quantity=lab, n=int(m.sum())); E.append(e)
V = pd.DataFrame(V)[["frame", "group", "n", "surv_r", "surv_bias", "surv_RMSE", "qmd_r", "qmd_bias", "qmd_RMSE", "ba_r", "ba_bias", "ba_RMSE"]]
V.to_csv(f"{OUT}/validation_compare.csv", index=False)
E = pd.DataFrame(E)[["frame", "group", "quantity", "n", "mean_obs", "bias_obs_minus_pred", "bias_lo", "bias_hi", "region_bias", "pass_bias", "slope", "slope_lo", "slope_hi", "pass_slope"]]
E.to_csv(f"{OUT}/validation_equiv_compare.csv", index=False)
ob = [c for c in VA["v102"].columns if c.startswith("obs")]
print("observed columns identical v102 vs refit vs refit2:", bool((VA["v102"][ob] - VA["refit"][ob]).abs().max().max() < 1e-12), bool((VA["v102"][ob] - VA["refit2"][ob]).abs().max().max() < 1e-12), "pids identical:", bool((VA["v102"].pid == VA["refit2"].pid).all()))
pd.set_option("display.width", 250); pd.set_option("display.max_columns", 40)
print(T5[["scenario", "site", "age", "VOL_v102", "VOL_refit", "VOL_refit2", "VOL_pct_refit", "VOL_pct_refit2", "VOL_pct_refit2_live", "QMD_pct_refit2", "TPH_pct_refit2", "HT_pct_refit2"]].round(1).to_string())
print(C.to_string()); print(V.round(4).to_string()); print(E.round(3).to_string())
