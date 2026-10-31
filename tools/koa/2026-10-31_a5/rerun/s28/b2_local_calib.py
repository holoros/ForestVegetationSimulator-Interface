#!/usr/bin/env python3
"""B2 (v100 track B, 2026-09-17): stand-level (local) calibration from the first remeasurement interval only.
ratio_d = sum(obs dDBH)/sum(proj dDBH) over trees alive at measurements 1 and 2 (matched by tree id), ratio_h likewise
if >= 5 trees carry measured heights at both; ratios capped to [0.2, 5]. The plot's origin entry of CAL_DDBH (CAL_DHT) is
multiplied by the ratio and the plot is reprojected from measurement 1. Scored only at measurements after the second."""
# a5/rerun copy (2026-10-31): inputs switched to the v104 engine copy (./engine = cp of engine_v103 without out_m1*),
# v104 mortality files a2/mort/v104 and gate a4/lt/LT_v104_points.csv. Logic otherwise verbatim from koa_origin_20260916/v100/trackB.
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, pandas as pd
import lt_core as C
OUT = C.HERE
CAP = (0.2, 5.0); MINH = 5; NB = 2000; SEED = 20260917


def num(x):
    return pd.to_numeric(x, errors="coerce").to_numpy(float)


ratios, pts = [], []
for p in C.lt_pids():
    S = C.setup(p)
    o = S["planted"]; t0, t1 = S["meas"][0], S["meas"][1]
    h1 = int(round(t1 - t0))
    C.apply()
    try:
        pr = C.project_psp_tracked(S["trees"], S["B"], o, "A", h1, ingrowth=False)
    finally:
        C.RM.set_params(None)
    assert not pr["binned"]
    pdbh = np.empty(len(S["trees"])); pht = np.empty(len(S["trees"]))
    pdbh[pr["tid"]] = pr["dbh_list"]; pht[pr["tid"]] = pr["ht_list"]
    # first record of each tree id at measurement 1 (duplicates exist for PSP|123|23)
    ids = pd.Series(S["tree_ids"])
    first = ids[~ids.duplicated()]
    row_of = dict(zip(first.values, first.index.values))
    ndup0 = int(ids.duplicated().sum())
    g1 = C.observed_at(S, t1)
    d1 = num(g1.DBH); h1o = num(g1.HT); tid1 = g1.Tree.astype(str).values
    od, pdd, oh, phh = [], [], [], []
    for k, tr in enumerate(tid1):
        r = row_of[tr]
        if np.isfinite(d1[k]) and d1[k] > 0:
            od.append(d1[k] - S["dbh0"][r]); pdd.append(pdbh[r] - S["dbh0"][r])
            if S["ht_meas"][r] and np.isfinite(h1o[k]) and h1o[k] > 0:
                oh.append(h1o[k] - S["ht0"][r]); phh.append(pht[r] - S["ht0"][r])
    od, pdd, oh, phh = map(np.array, (od, pdd, oh, phh))
    rd_raw = od.sum() / pdd.sum() if len(od) and pdd.sum() > 0 else np.nan
    rh_raw = oh.sum() / phh.sum() if len(oh) >= MINH and phh.sum() > 0 else np.nan
    rd = float(np.clip(rd_raw, *CAP)) if np.isfinite(rd_raw) else 1.0
    rh = float(np.clip(rh_raw, *CAP)) if np.isfinite(rh_raw) else 1.0
    cal_dd = list(C.CALD0); cal_dd[o] *= rd
    cal_dh = list(C.CALH0); cal_dh[o] *= rh
    ratios.append(dict(pid=p, origin="planted" if o else "natural", t1=t0, t2=t1, first_interval_yr=float(t1 - t0), proj_years=h1,
                       n_trees_init=len(S["ids0"]), n_dup_records_init=ndup0, n_trees_dbh=len(od), n_trees_ht=len(oh),
                       sum_obs_dDBH=float(od.sum()), sum_proj_dDBH=float(pdd.sum()), ratio_d_raw=rd_raw, ratio_d=rd,
                       ratio_d_capped=bool(np.isfinite(rd_raw) and rd != rd_raw),
                       sum_obs_dHT=float(oh.sum()) if len(oh) else np.nan, sum_proj_dHT=float(phh.sum()) if len(phh) else np.nan,
                       ratio_h_raw=rh_raw, ratio_h=rh if np.isfinite(rh_raw) else np.nan,
                       ratio_h_capped=bool(np.isfinite(rh_raw) and rh != rh_raw), ht_multiplier_local=np.isfinite(rh_raw),
                       cal_ddbh_pop=C.CALD0[o], cal_ddbh_local=cal_dd[o], cal_dht_pop=C.CALH0[o], cal_dht_local=cal_dh[o],
                       n_scored_points=sum(1 for m in S["meas"] if m > t1)))
    a = C.run_points(p, S=S); a["arm"] = "population"
    b = C.run_points(p, cal_dd=cal_dd, cal_dh=cal_dh if np.isfinite(rh_raw) else None, S=S); b["arm"] = "local"
    pts += [a, b]
C.KE.joint_assert_clean("b2 end")
R = pd.DataFrame(ratios); R.to_csv(os.path.join(OUT, "B2_plot_ratios.csv"), index=False)
print(R[["pid", "origin", "first_interval_yr", "n_trees_dbh", "n_trees_ht", "ratio_d_raw", "ratio_d", "ratio_h_raw", "ratio_h", "n_scored_points"]].round(4).to_string())
ALL = C.add_err(pd.concat(pts, ignore_index=True))
ALL["scored"] = ALL.tk > ALL.pid.map(dict(zip(R.pid, R.t2)))
ALL["origin"] = np.where(ALL.planted == 1, "planted", "natural")
ALL.assign(hc=ALL.hc.astype(str)).to_csv(os.path.join(OUT, "B2_points_all.csv"), index=False)
SC = ALL[ALL.scored].copy()
# gate: population arm equals the reference points
ref = pd.read_csv(os.path.join("/home/aaron/jobs/koa_v104_20261030", "a4", "lt", "LT_v104_points.csv"))
aa = ALL[ALL.arm == "population"].sort_values(["pid", "tk"]).reset_index(drop=True)
ref = ref.sort_values(["pid", "tk"]).reset_index(drop=True)
print("population arm vs LT_v98 max abs diff", max(abs(aa[c] - ref[c]).max() for c in ("pr_surv", "prQMD", "prBAPH")))

# paired wide table on scored points
W = SC[SC.arm == "population"][["pid", "origin", "tk", "h", "hc", "e_surv", "e_qmd", "e_ba"]].merge(
    SC[SC.arm == "local"][["pid", "tk", "e_surv", "e_qmd", "e_ba"]], on=["pid", "tk"], suffixes=("_pop", "_loc"))
W.assign(hc=W.hc.astype(str)).to_csv(os.path.join(OUT, "B2_points_scored_paired.csv"), index=False)
VARS = ("surv", "qmd", "ba")


def stats(d):
    o = {}
    for v in VARS:
        ep, el = d[f"e_{v}_pop"].to_numpy(float), d[f"e_{v}_loc"].to_numpy(float)
        o[f"{v}_bias_pop"] = ep.mean(); o[f"{v}_bias_loc"] = el.mean(); o[f"{v}_dbias"] = el.mean() - ep.mean()
        o[f"{v}_rmse_pop"] = np.sqrt((ep ** 2).mean()); o[f"{v}_rmse_loc"] = np.sqrt((el ** 2).mean())
        o[f"{v}_drmse"] = o[f"{v}_rmse_loc"] - o[f"{v}_rmse_pop"]
        o[f"{v}_dmae"] = np.abs(el).mean() - np.abs(ep).mean()
    return o


rng = np.random.default_rng(SEED)
cells = []
for org in ("natural", "planted"):
    for hc in C.HC_LAB + ["all"]:
        d = W[W.origin == org] if hc == "all" else W[(W.origin == org) & (W.hc.astype(str) == hc)]
        if len(d):
            cells.append((org, hc, d))
rows = []
for org, hc, d in cells:
    st = stats(d)
    plots = np.array(sorted(d.pid.unique())); grp = {p: d[d.pid == p] for p in plots}
    B = []
    for _ in range(NB):
        s = rng.choice(plots, len(plots), replace=True)
        B.append(stats(pd.concat([grp[q] for q in s], ignore_index=True)))
    B = pd.DataFrame(B)
    row = dict(origin=org, horizon=hc, n_points=len(d), n_plots=len(plots))
    for k, v in st.items():
        row[k] = v
        if k.endswith(("dbias", "drmse", "dmae", "bias_pop", "bias_loc")):
            row[k + "_lo95"] = float(np.percentile(B[k], 2.5)); row[k + "_hi95"] = float(np.percentile(B[k], 97.5))
    rows.append(row)
SUM = pd.DataFrame(rows)
SUM.to_csv(os.path.join(OUT, "B2_summary_boot.csv"), index=False)
pd.set_option("display.width", 250)
for v in VARS:
    cols = ["origin", "horizon", "n_points", "n_plots", f"{v}_bias_pop", f"{v}_bias_pop_lo95", f"{v}_bias_pop_hi95", f"{v}_bias_loc",
            f"{v}_bias_loc_lo95", f"{v}_bias_loc_hi95", f"{v}_dbias", f"{v}_dbias_lo95", f"{v}_dbias_hi95",
            f"{v}_rmse_pop", f"{v}_rmse_loc", f"{v}_drmse", f"{v}_drmse_lo95", f"{v}_drmse_hi95"]
    print(SUM[cols].round(4).to_string())
PP = []
for (p, org), d in W.groupby(["pid", "origin"]):
    o = dict(pid=p, origin=org, n_points=len(d)); o.update(stats(d)); PP.append(o)
pd.DataFrame(PP).to_csv(os.path.join(OUT, "B2_byplot.csv"), index=False)
print(pd.DataFrame(PP)[["pid", "n_points", "surv_rmse_pop", "surv_rmse_loc", "qmd_rmse_pop", "qmd_rmse_loc", "ba_rmse_pop", "ba_rmse_loc"]].round(3).to_string())
