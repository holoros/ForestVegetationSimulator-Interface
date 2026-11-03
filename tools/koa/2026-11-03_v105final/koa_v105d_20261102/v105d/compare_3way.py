#!/usr/bin/env python3
"""v105d/compare_3way.py: three-way table v105b / v105c / v105d. Runs the v105c comparison core (compare_core_d.py = v105c/compare_v105b_v105c_core.py with
A, B from the environment) with A = koa_v105c_20261102 (read only), B = this job, and merges it with the v105c job's own v105b vs v105c table
(koa_v105c_20261102/v105c/out/compare_v105b_v105c.csv) on (section, item). Adds the v105d-specific rows: Eq. 2 H1a statistics (track3_s02/v105d),
Eq. 3 C2h vs HCB_P, Stage 3 M3a vs v105c, dHT strata ratios. Writes v105d/out/compare_3way.csv and .md."""
import os, runpy, json, pandas as pd, numpy as np
W = os.path.expanduser("~/jobs/koa_v105d_20261102"); VC = os.path.expanduser("~/jobs/koa_v105c_20261102"); VB = os.path.expanduser("~/jobs/koa_v105_20261102")
os.environ["KOA_A"] = VC; os.environ["KOA_B"] = W; os.environ["KOA_OUTP"] = f"{W}/v105d/out/compare_v105c_v105d"
runpy.run_path(f"{W}/v105d/compare_core_d.py", run_name="__main__")
CD = pd.read_csv(f"{W}/v105d/out/compare_v105c_v105d.csv").rename(columns={"v104": "v105c", "v105": "v105d", "source_v104": "source_v105c", "source_v105": "source_v105d"})
BC = pd.read_csv(f"{VC}/v105c/out/compare_v105b_v105c.csv")[["section", "item", "v105b", "v105c"]].rename(columns={"v105c": "v105c_in_v105c_table"})
M = CD.merge(BC, on=["section", "item"], how="left")
M = M[~M.section.str.startswith("Bakuzis")]   # the core's Bakuzis rows compare v104 with the B job inside one job file (not v105c); the three-way Bakuzis table is v105d/out/bakuzis_flags_3way.csv
extra = []
def add(sec, item, b, c, d, src): extra.append(dict(section=sec, item=item, v105b=b, v105c=c, v105d=d, source_v105d=src))
hs = pd.read_csv(f"{W}/track3_s02/v105d/02_height_fit_stats.csv").set_index("prediction"); he = pd.read_csv(f"{W}/track3_s02/v105d/02_height_equivalence.csv").set_index("vector")
for k, lab in (("rmse", "population-average RMSE (m)"), ("bias", "mean bias obs - pred (m)"), ("r2", "population-average R2")):
    add("Eq. 2 height (8,914 records)", lab, f"{hs.loc['v105c form (D), population-average', k]:.4f}", f"{hs.loc['v105c form (D), population-average', k]:.4f}", f"{hs.loc['v105d H1a, population-average', k]:.4f}", "track3_s02/v105d/02_height_fit_stats.csv (v105b = v105c form)")
for v, lab in (("v105c form (D), population-average", "D"), ("refit, population-average", "H1a")): pass
g = lambda r: f"bias {r.bias_obs_minus_pred:.3f} ({r.bias_lo:.3f} to {r.bias_hi:.3f}) {'pass' if r.pass_bias else 'fail'}; slope {r.slope:.3f} ({r.slope_lo:.3f} to {r.slope_hi:.3f}) {'pass' if r.pass_slope else 'fail'}"
add("Eq. 2 height (8,914 records)", "installation-bootstrap equivalence (25%)", g(he.loc["v105c form (D), population-average"]), g(he.loc["v105c form (D), population-average"]), g(he.loc["refit, population-average"]), "track3_s02/v105d/02_height_equivalence.csv")
cs = pd.read_csv(os.path.expanduser("~/jobs/koa_compscreen_20261102/out/height_results.csv")).set_index("cand")
add("Eq. 2 height (8,914 records)", "LOIO RMSE, level 0 (koa_compscreen_20261102)", f"{cs.loc['D','heldout_rmse']:.4f}", f"{cs.loc['D','heldout_rmse']:.4f}", f"{cs.loc['H1a','heldout_rmse']:.4f}", "koa_compscreen_20261102/out/height_results.csv")
add("Eq. 2 height (8,914 records)", "logLik (ML)", f"{cs.loc['D','logLik']:.2f}", f"{cs.loc['D','logLik']:.2f}", f"{cs.loc['H1a','logLik']:.2f} (dAIC {cs.loc['H1a','dAIC']:.2f})", "koa_compscreen_20261102/out/height_results.csv")
hc = pd.read_csv(os.path.expanduser("~/jobs/koa_compscreen_20261102/out/hcb_results.csv")).set_index("cand")
for k, lab in (("rmse", "RMSE (m), 360 FIA records"), ("loio_rmse", "LOIO RMSE (m)"), ("AIC", "AIC")):
    add("Eq. 3 HCB", lab, f"{hc.loc['D',k]:.4f}", f"{hc.loc['D',k]:.4f}", f"{hc.loc['C2h',k]:.4f}", "koa_compscreen_20261102/out/hcb_results.csv")
add("Eq. 3 HCB", "coefficients b0..b5", ", ".join(f"{hc.loc['D',f'b{i}']:.4g}" for i in range(6)), ", ".join(f"{hc.loc['D',f'b{i}']:.4g}" for i in range(6)), ", ".join(f"{hc.loc['C2h',f'b{i}']:.4g}" for i in range(6)) + f" (b5 plot bootstrap {hc.loc['C2h','b5_boot_lo']:.3f} to {hc.loc['C2h','b5_boot_hi']:.3f})", "koa_compscreen_20261102/out/hcb_results.csv")
s3 = pd.read_csv(os.path.expanduser("~/jobs/koa_compscreen_20261102/out/stage3_results.csv")).set_index("cand")
JD = json.load(open(f"{W}/out/v105_constants.json")); JCc = json.load(open(f"{VC}/out/v105_constants.json"))
add("Mortality Stage 3", "coefficients c0..c4", ", ".join(f"{v:.4g}" for v in JCc["STAGE3"]["coef"].values()), ", ".join(f"{v:.4g}" for v in JCc["STAGE3"]["coef"].values()), ", ".join(f"{v:.4g}" for v in JD["STAGE3"]["coef"].values()), "out/v105_constants.json STAGE3")
for k, lab in (("loio_auc_within", "LOIO within-interval AUC"), ("loio_brier", "LOIO Brier"), ("AIC", "AIC")):
    add("Mortality Stage 3", lab, f"{s3.loc['D',k]:.4f}", f"{s3.loc['D',k]:.4f}", f"{s3.loc['M3a',k]:.4f}", "koa_compscreen_20261102/out/stage3_results.csv")
for jj, lab in ((None, "v105b"),):
    pass
st = {n: pd.read_csv(f"{p}/out/inc/evaluation_strata_v103.csv") for n, p in (("v105b", VB), ("v105c", VC), ("v105d", W))}
def ratio(S, fit, strat, level):
    r = S[(S.fit == fit) & (S.eval_frame == "NO") & (S.strat == strat) & (S.level == level)] if "eval_frame" in S.columns else S[(S.fit == fit) & (S.strat == strat) & (S.level == level)]
    return f"{r.ratio.iloc[0]:.3f}" if len(r) else "n/a"
for fit, strat, level, lab in (("dDBH_L_NO", "size", "40-60", "dDBH obs/pred ratio, 40-60 cm"), ("dDBH_L_NO", "BALquintile", "Q5", "dDBH obs/pred ratio, top BAL quintile"),
                               ("dHT_L_NO", "size", "20-30", "dHT obs/pred ratio, 20-30 m"), ("dHT_L_NO", "BALquintile", "Q5", "dHT obs/pred ratio, top BAL quintile"), ("dHT_L_NO", "all", "all", "dHT obs/pred ratio, all")):
    add("Eq. 4 strata (NO frame, out/inc/evaluation_strata_v103.csv)", lab, ratio(st["v105b"], fit, strat, level), ratio(st["v105c"], fit, strat, level), ratio(st["v105d"], fit, strat, level), "out/inc/evaluation_strata_v103.csv of each job")
B3 = pd.read_csv(f"{W}/v105d/out/bakuzis_flags_3way.csv")
for res in ("PASS", "FLAG", "NOT EVALUATED", "info"):
    add("Bakuzis matrix (step-aware a4/bakuzis/bakuzis_v105_vs_v104.R, v105 rows of each job)", f"count {res}", int((B3.result_v105b == res).sum()), int((B3.result_v105c == res).sum()), int((B3.result_v105d == res).sum()), "v105d/out/bakuzis_flags_3way.csv")
X = pd.DataFrame(extra); M = pd.concat([M, X], ignore_index=True)
M = M[["section", "item", "v105b", "v105c", "v105d", "source_v105c", "source_v105d", "v105c_in_v105c_table"] + [c for c in M.columns if c not in ("section", "item", "v105b", "v105c", "v105d", "source_v105c", "source_v105d", "v105c_in_v105c_table")]]
M.to_csv(f"{W}/v105d/out/compare_3way.csv", index=False)
with open(f"{W}/v105d/out/compare_3way.md", "w") as fh:
    for sec, g_ in M.groupby("section", sort=False):
        fh.write(f"\n### {sec}\n\n| item | v105b | v105c | v105d |\n|---|---|---|---|\n")
        for _, r in g_.iterrows(): fh.write(f"| {r['item']} | {r.v105b if pd.notna(r.v105b) else ''} | {r.v105c} | {r.v105d} |\n")
print(len(M), "rows; v105c column consistent with the v105c job table:", int(((M.v105c.astype(str) == M.v105c_in_v105c_table.astype(str)) | M.v105c_in_v105c_table.isna()).sum()), "of", len(M))
