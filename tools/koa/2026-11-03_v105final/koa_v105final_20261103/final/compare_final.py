#!/usr/bin/env python3
"""final/compare_final.py: v105b / v105c / v105d / v105final comparison from the output files of each job (named per value in the source column).
Writes final/out/compare_final_long.csv, compare_final_wide.csv, compare_final.md. Read only for the three earlier jobs."""
import os, re, json, numpy as np, pandas as pd
F = os.path.expanduser("~/jobs/koa_v105final_20261103"); O = f"{F}/final/out"; os.makedirs(O, exist_ok=True)
JOBS = {"v105b": "~/jobs/koa_v105_20261102", "v105c": "~/jobs/koa_v105c_20261102", "v105d": "~/jobs/koa_v105d_20261102", "v105final": F}
JOBS = {k: os.path.expanduser(v) for k, v in JOBS.items()}
COV = {"v105c": f"{JOBS['v105d']}/a5/rerun/cov_v105c/tableS26_coverage_v104.csv", "v105d": f"{JOBS['v105d']}/a5/rerun/cov/tableS26_coverage_v104.csv", "v105final": f"{F}/a5/rerun/cov/tableS26_coverage_v104.csv"}
RLZ = {"v105b": f"{JOBS['v105d']}/v105d/out/realism_v105b.csv", "v105c": f"{JOBS['v105d']}/v105d/out/realism_v105c.csv", "v105d": f"{JOBS['v105d']}/v105d/out/realism_v105d.csv", "v105final": f"{F}/v105d/out/realism_v105final.csv"}
rows = []
def add(j, m, v, s): rows.append(dict(job=j, metric=m, value=v, source=s))
for j, W in JOBS.items():
    def ok(p): return os.path.exists(p)
    p = f"{W}/out/v105_constants.json"
    if ok(p):
        C = json.load(open(p)); add(j, "MORT_CAL natural", C.get("MORT_CAL", {}).get("value", [""])[0], "out/v105_constants.json")
        for k in ("DDBH", "DHT"):
            s = C[k].get("CAL_SE_LOG"); add(j, f"CAL_SE_LOG {k} (nat, plt)", "" if s is None else "%.4f, %.4f" % tuple(s), "out/v105_constants.json")
    p = f"{W}/engine_v103/out_m1/table8_evenaged_M1.csv"
    if ok(p):
        T = pd.read_csv(p); T = T[T.Age == 40]
        for r in T.itertuples():
            for q in ("VOL", "QMD"): add(j, f"{q}40 | {r.Scenario} | {r.Site}", f"{getattr(r, q):.1f} ({getattr(r, q + '_lo'):.1f} to {getattr(r, q + '_hi'):.1f})", "engine_v103/out_m1/table8_evenaged_M1.csv")
    p = f"{W}/a4/culmination_mc_v104.json"
    if ok(p):
        for k, v in json.load(open(p)).items(): add(j, f"culmination | {k}", f"{v['pt_window']}; {v['med_window']}", "a4/culmination_mc_v104.json")
    p = f"{W}/a4/bakuzis/bakuzis_checks_v104_v105.csv"
    if ok(p):
        B = pd.read_csv(p); B = B[B.version == "v105"]; vc = B.result.value_counts().to_dict()
        add(j, "Bakuzis PASS / FLAG / info / NOT EVALUATED", f"{vc.get('PASS',0)} / {vc.get('FLAG',0)} / {vc.get('info',0)} / {vc.get('NOT EVALUATED',0)}", "a4/bakuzis/bakuzis_checks_v104_v105.csv")
        add(j, "Bakuzis Reineke step", ";".join(sorted(set(re.findall(r"step ([0-9.]+)", " ".join(B.value.astype(str)))))), "a4/bakuzis/bakuzis_checks_v104_v105.csv")
        for r in B[B.relation == "Eichhorn"].itertuples(): add(j, f"Eichhorn | {r.group}", f"{r.value} {r.result}", "a4/bakuzis/bakuzis_checks_v104_v105.csv")
    p = f"{W}/a2/closeout/validation/val_v104_plotlevel.csv"
    if ok(p):
        V = pd.read_csv(p); V = V[V.pid != "FIA|15-1-1-2628"]
        for s, g in list(V.groupby("source")) + [("all", V)]:
            for q, o, pr in (("QMD", "obsQMD", "prQMD"), ("BA", "obsBAPH", "prBAPH"), ("survW", "obs_surv_w", "pr_surv")):
                e = g[pr] - g[o]; add(j, f"plot-level {q} bias / RMSE | {s} (n {len(g)})", f"{e.mean():.3f} / {np.sqrt((e ** 2).mean()):.3f}", "a2/closeout/validation/val_v104_plotlevel.csv")
    p = f"{W}/a4/lt/LT_v104_points.csv"
    if ok(p):
        V = pd.read_csv(p)
        for s, g in list(V.groupby("source")) + [("all", V)]:
            for q, o, pr in (("QMD", "obsQMD", "prQMD"), ("BA", "obsBAPH", "prBAPH")):
                e = g[pr] - g[o]; add(j, f"trajectory {q} bias / RMSE | {s} (n {len(g)})", f"{e.mean():.3f} / {np.sqrt((e ** 2).mean()):.3f}", "a4/lt/LT_v104_points.csv")
    p = COV.get(j)
    if p and ok(p):
        C = pd.read_csv(p)
        for r in C[(C.unitset == "plotlevel") & C.group.isin(["pooled", "natural", "planted"])].itertuples(): add(j, f"coverage plotlevel {r.variable} | {r.group}", f"{r.coverage:.3f}", p.replace(os.path.expanduser("~/jobs/"), ""))
    p = f"{W}/a5/loio/loio_metrics.csv"
    if ok(p):
        M = pd.read_csv(p); M = M[M.frame == "held-out LOIO"]
        for r in M.itertuples(): add(j, f"LOIO | {r.group} | {r.variable}", f"{r.decision}; bias {r.bias:.4f} (90% {r.bias_lo90:.4f} to {r.bias_hi90:.4f})", "a5/loio/loio_metrics.csv")
    p = f"{W}/a5/loio/gate_check.csv"
    if ok(p):
        G = pd.read_csv(p)
        for t, g in G.groupby("tag"): add(j, f"LOIO gate {t} max abs diff", f"{g.max_abs_diff.max():.6g} ({'PASS' if g.pass_1e3.all() else 'FLAG'})", "a5/loio/gate_check.csv")
    p = f"{W}/a5/pairmc/out_a5/prob_ordering.csv"
    if ok(p):
        Pm = pd.read_csv(p); Pm = Pm[Pm.age == 40]
        for r in Pm.itertuples(): add(j, f"pairmc 40yr | {r.variant} | {r.origin} | {r.comparison}", f"{r.P:.3f} ({r.verdict})", "a5/pairmc/out_a5/prob_ordering.csv")
    p = RLZ.get(j)
    if p and ok(p):
        R = pd.read_csv(p); S = R[R.kind == "suppressed"]
        for c in ("dht_d_density", "dht_d_share", "ddbh_d_density", "ddbh_d_share"): add(j, f"realism suppressed positive | {c}", f"{int((S[c] > 1e-12).sum())} of {len(S)} (max {S[c].max():.3g})", p.replace(os.path.expanduser("~/jobs/"), ""))
L = pd.DataFrame(rows); L.to_csv(f"{O}/compare_final_long.csv", index=False)
Wd = L.pivot_table(index="metric", columns="job", values="value", aggfunc="first")[[k for k in JOBS if k in set(L.job)]]; Wd.to_csv(f"{O}/compare_final_wide.csv")
with open(f"{O}/compare_final.md", "w") as fh:
    fh.write("| metric | " + " | ".join(Wd.columns) + " |\n|---|" + "---|" * len(Wd.columns) + "\n")
    for m, r in Wd.iterrows(): fh.write(f"| {m} | " + " | ".join("" if pd.isna(v) else str(v) for v in r.values) + " |\n")
print(Wd.to_string())
