#!/usr/bin/env python3
"""a5/loio/analyze_loio.py (koa v104 A5 LOIO). Pools the held-out plot errors (projected minus observed, final measurement) from
val/val_<fold>_plotlevel.csv (only the held-out installation's benchmark plots), sets them beside the in-sample v104 values
(a2/closeout/validation/val_v104_plotlevel.csv and the published Table C2), and applies the preregistered TOST and decision rule.
Bootstrap: installations resampled with replacement, 2,000 draws, numpy default_rng(20261031); the same cluster draws are used for the
in-sample and held-out columns of a group. 90 percent intervals; bias region 25 percent of |mean observed|; slope region 0.75 to 1.25.
Outputs: loio_plots.csv, loio_metrics.csv, loio_folds.csv. No coordinates are read."""
import os, numpy as np, pandas as pd
W = os.path.expanduser("~/jobs/koa_v104_20261030"); L = f"{W}/a5/loio"; VD = f"{W}/a2/closeout/validation"
DIST = "FIA|15-1-1-2628"
IN = pd.read_csv(f"{VD}/val_v104_plotlevel.csv"); IN = IN[IN.pid != DIST].copy()
IN["inst"] = IN.pid.str.rsplit("|", n=1).str[0]
FOLDS = sorted(IN.inst.unique())
VARS = [("survival", "obs_surv_w", "pr_surv"), ("QMD_cm", "obsQMD", "prQMD"), ("BA_m2ha", "obsBAPH", "prBAPH")]
# ---- held-out plots
rows, frows = [], []
for f in FOLDS:
    tag = f.replace("|", "_"); fr = dict(fold=f)
    fit = pd.read_csv(f"{L}/fits/fit_{tag}.csv").iloc[0].to_dict() if os.path.exists(f"{L}/fits/fit_{tag}.csv") else {"status": "missing"}
    fr.update({k: fit.get(k) for k in ("status", "n_rows", "n_dropped", "n_inst", "b8", "CF", "c_natural", "c_planted", "CAL_natural", "CAL_planted", "logLik", "secs")})
    lv = f"{L}/mort/{tag}/H_mort_level_natural.csv"
    if os.path.exists(lv):
        r = pd.read_csv(lv); r = r[r.form == "mult"].iloc[0]; fr.update(mort_level=r.level, mort_n_intervals=int(r.n_intervals))
    vf = f"{L}/val/val_{tag}_plotlevel.csv"
    if fit.get("status") != "ok" or not os.path.exists(vf):
        fr["chain_status"] = "FAILED"; frows.append(fr); continue
    V = pd.read_csv(vf); V["inst"] = V.pid.str.rsplit("|", n=1).str[0]; H = V[(V.inst == f) & (V.pid != DIST)]
    exp_p = set(IN.pid[IN.inst == f]); got = set(H.pid)
    fr["chain_status"] = "ok" if got == exp_p else f"plots mismatch {sorted(exp_p ^ got)}"; fr["n_plots"] = len(H); frows.append(fr)
    for _, h in H.iterrows():
        i = IN[IN.pid == h.pid].iloc[0]; d = dict(pid=h.pid, fold=f, origin=i.origin)
        for v, o, p in VARS:
            d[f"obs_{v}"] = i[o]; d[f"pr_in_{v}"] = i[p]; d[f"pr_ho_{v}"] = h[p]
            assert abs(h[o] - i[o]) < 1e-9, (h.pid, o)          # same observed values
        rows.append(d)
P = pd.DataFrame(rows); F = pd.DataFrame(frows)
P.to_csv(f"{L}/loio_plots.csv", index=False); F.to_csv(f"{L}/loio_folds.csv", index=False)
# ---- metrics
def stat(o, p):
    pc = p - p.mean(); X = np.column_stack([np.ones_like(pc), pc]); b = np.linalg.lstsq(X, o, rcond=None)[0]
    return p.mean() - b[0], b[1]
C2 = pd.read_csv(f"{VD}/tableC2_v104_plotlevel.csv"); C2 = C2[C2.frame == "v104 plot level"]
c2map = {"all": "all (excl. 2628)", "natural": "natural (excl. 2628)", "planted": "planted"}; qmap = {"survival": "surv (weighted)", "QMD_cm": "qmd", "BA_m2ha": "ba"}
out = []
for g in ("all", "natural", "planted"):
    S = P if g == "all" else P[P.origin == g]
    ids = sorted(S.fold.unique()); idx = {k: np.where(S.fold.to_numpy() == k)[0] for k in ids}
    rng = np.random.default_rng(20261031); draws = [np.concatenate([idx[ids[j]] for j in rng.integers(0, len(ids), len(ids))]) for _ in range(2000)]
    for v, _, _ in VARS:
        o = S[f"obs_{v}"].to_numpy(float); r0 = 0.25 * abs(o.mean())
        pub = C2[(C2.group == c2map[g]) & (C2.quantity == qmap[v])].iloc[0]
        for frame, col in (("in-sample v104", f"pr_in_{v}"), ("held-out LOIO", f"pr_ho_{v}")):
            p = S[col].to_numpy(float); e = p - o; b, s = stat(o, p)
            bs = np.array([stat(o[k], p[k]) for k in draws]); lo, hi = np.quantile(bs[:, 0], [0.05, 0.95]); slo, shi = np.quantile(bs[:, 1], [0.05, 0.95])
            pass_b = bool(lo > -r0 and hi < r0); outside = bool(hi < -r0 or lo > r0)
            out.append(dict(group=g, variable=v, frame=frame, n_plots=len(S), n_inst=len(ids), mean_obs=o.mean(), bias=e.mean(), rmse=np.sqrt((e**2).mean()),
                bias_lo90=lo, bias_hi90=hi, region=r0, tost_bias_pass=pass_b, slope=s, slope_lo90=slo, slope_hi90=shi, tost_slope_pass=bool(slo > 0.75 and shi < 1.25),
                decision=("SUPPORTS" if pass_b else "CONTRADICTS" if outside else "INCONCLUSIVE") if frame == "held-out LOIO" else "",
                published_plotboot_bias_lo=pub.bias_lo, published_plotboot_bias_hi=pub.bias_hi, published_pass_bias=pub.pass_bias,
                published_slope_lo=pub.slope_lo, published_slope_hi=pub.slope_hi, published_pass_slope=pub.pass_slope))
M = pd.DataFrame(out); M.to_csv(f"{L}/loio_metrics.csv", index=False)
pd.set_option("display.width", 250); print(F.to_string()); print(M.drop(columns=[c for c in M.columns if c.startswith("published")]).round(4).to_string())
ok = F[F.chain_status == "ok"]
print("RANGES", {k: (ok[k].min(), ok[k].max()) for k in ("b8", "c_natural", "c_planted", "mort_level", "CF")})
