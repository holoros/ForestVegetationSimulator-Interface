#!/usr/bin/env python3
"""a5/loio/make_results.py: writes RESULTS.md from loio_metrics.csv, loio_folds.csv, loio_plots.csv and gate_check.csv (all numbers read from those files)."""
import os, pandas as pd, numpy as np
L = os.path.expanduser("~/jobs/koa_v105c_20261102/a5/loio")
M = pd.read_csv(f"{L}/loio_metrics.csv"); F = pd.read_csv(f"{L}/loio_folds.csv"); P = pd.read_csv(f"{L}/loio_plots.csv"); G = pd.read_csv(f"{L}/gate_check.csv")
esc = lambda s: s.replace("|", chr(92) + "|")
f3 = lambda x, d=3: "" if pd.isna(x) else (f"{x:.{d}f}" if isinstance(x, (float, np.floating)) else str(x))
md = ["# koa v105c LOIO results (2 Nov 2026; v104 A5 scripts, v105c engine (K3c1 dDBH) and frames)", "",
      "Full-chain leave-one-installation-out evaluation of the 17 plot-level benchmark plots. Preregistration: PREREG.md (written 14:21:48 ADT, before any fold was fit).",
      "Error = projected minus observed at the final measurement (one comparison per plot; the validation script makes no per-measurement comparisons).",
      "Intervals: 90 percent, installation-cluster bootstrap, 2,000 draws, seed 20261031 (same cluster draws for both frames of a group). Bias region = 25 percent of mean observed; slope region 0.75 to 1.25.",
      "Published = Table C2 of a2/closeout/validation/tableC2_v104_plotlevel.csv (plot bootstrap, 5,000 draws, seed 20260917).", "",
      "## Preregistered outcome (pooled 17 plots, primary)", "",
      "| variable | in-sample bias | held-out bias | held-out 90% CI | region | decision |", "|---|---|---|---|---|---|"]
for v in ("survival", "QMD_cm", "BA_m2ha"):
    i = M[(M.group == "all") & (M.variable == v) & (M.frame == "in-sample v104")].iloc[0]; h = M[(M.group == "all") & (M.variable == v) & (M.frame == "held-out LOIO")].iloc[0]
    md.append(f"| {v} | {f3(i.bias,4)} | {f3(h.bias,4)} | {f3(h.bias_lo90,4)} to {f3(h.bias_hi90,4)} | +/- {f3(h.region,4)} | **{h.decision}** |")
md += ["", "## Table R1. Held-out vs in-sample, all groups", "",
       "| group | variable | frame | n plots | n inst | mean obs | bias | RMSE | bias 90% CI | TOST bias | slope | slope 90% CI | TOST slope | decision | published bias CI (plot boot) | published slope CI |",
       "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
for _, r in M.iterrows():
    pub = f"{f3(r.published_plotboot_bias_lo,4)} to {f3(r.published_plotboot_bias_hi,4)} ({'pass' if r.published_pass_bias else 'fail'})" if r.frame.startswith("in") else ""
    pubs = f"{f3(r.published_slope_lo)} to {f3(r.published_slope_hi)} ({'pass' if r.published_pass_slope else 'fail'})" if r.frame.startswith("in") else ""
    md.append(f"| {r.group} | {r.variable} | {r.frame} | {r.n_plots} | {r.n_inst} | {f3(r.mean_obs)} | {f3(r.bias,4)} | {f3(r.rmse,4)} | {f3(r.bias_lo90,4)} to {f3(r.bias_hi90,4)} | {'pass' if r.tost_bias_pass else 'fail'} | {f3(r.slope)} | {f3(r.slope_lo90)} to {f3(r.slope_hi90)} | {'pass' if r.tost_slope_pass else 'fail'} | {r.decision if isinstance(r.decision, str) else ''} | {pub} | {pubs} |")
md += ["", "## Table R2. Fold constants (refit dDBH_L_NO, re-solved c, CF, natural level)", "",
       "| fold | status | training rows | rows dropped | b8 (ln BYI) | CF | c natural | c planted | CAL natural | CAL planted | natural level | level intervals | plots scored |", "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
for _, r in F.iterrows():
    md.append(f"| {esc(r.fold)} | {r.status}/{r.chain_status} | {r.n_rows} | {r.n_dropped} | {f3(r.b8,4)} | {f3(r.CF,4)} | {f3(r.c_natural,4)} | {f3(r.c_planted,4)} | {f3(r.CAL_natural,4)} | {f3(r.CAL_planted,4)} | {f3(r.mort_level,4)} | {r.mort_n_intervals} | {r.n_plots} |")
ok = F[F.chain_status == "ok"]
md += ["", f"Failed folds: {int((F.chain_status != 'ok').sum())} of {len(F)}.", "",
       "Fold-to-fold range (v105c of record: b8 0.2872557, c natural 0.3718, c planted 1.2059, CF 1.58466, level 2.55705; out/v105_constants.json):", ""]
for k in ("b8", "c_natural", "c_planted", "CF", "mort_level"):
    md.append(f"- {k}: {f3(ok[k].min(),4)} to {f3(ok[k].max(),4)} (min fold {ok.fold[ok[k].idxmin()]}, max fold {ok.fold[ok[k].idxmax()]})")
md += ["", "## Table R3. Per-plot errors (projected minus observed)", "", "| plot | origin | surv in | surv held-out | QMD in | QMD held-out | BA in | BA held-out |", "|---|---|---|---|---|---|---|---|"]
for _, r in P.iterrows():
    e = lambda fr, v: r[f"pr_{fr}_{v}"] - r[f"obs_{v}"]
    md.append(f"| {esc(r.pid)} | {r.origin} | {f3(e('in','survival'))} | {f3(e('ho','survival'))} | {f3(e('in','QMD_cm'),2)} | {f3(e('ho','QMD_cm'),2)} | {f3(e('in','BA_m2ha'),2)} | {f3(e('ho','BA_m2ha'),2)} |")
md += ["", "## Sanity gate (gate_check.csv; max abs difference vs a2/closeout/validation/val_v104_plotlevel.csv over 18 units)", "", "| run | column | max abs diff | pass (< 1e-3) |", "|---|---|---|---|"]
for _, r in G.iterrows(): md.append(f"| {r.tag} | {r.col} | {r.max_abs_diff:.3e} | {r.pass_1e3} |")
md += ["", "V105EXACT = the pipeline (engine copy, patch, level re-solve, validation) with the v105 constants of record (see gate_check.csv for the reproduction).",
       "NONE = the pipeline with the dDBH refit on the full frame (fits/fit_NONE.csv); its differences from the vector of record are in gate_check.csv and fits/fit_NONE.csv.", ""]
open(f"{L}/RESULTS.md", "w").write("\n".join(md)); print("\n".join(md))
