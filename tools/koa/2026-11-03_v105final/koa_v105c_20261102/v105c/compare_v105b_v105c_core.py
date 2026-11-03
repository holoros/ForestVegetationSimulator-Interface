#!/usr/bin/env python3
"""repair_v105b/compare_v104_vB.py (copy of report/compare_v104_v105.py; B and output path from KOA_B, KOA_OUTP). Original docstring: compare_v104_v105.py: side-by-side v104 (koa_v104_20261030, read only) vs v105 (this job) of the headline quantities. Every value is read from the file
named in the 'source' column. Writes report/compare_v104_v105.csv and report/compare_v104_v105.md."""
import json, os, pandas as pd, numpy as np
A = "/home/aaron/jobs/koa_v105_20261102"; B = os.environ.get("KOA_B", "/home/aaron/jobs/koa_v105c_20261102"); OUTP = os.environ["KOA_OUTP"]   # v105b: B = job (v105b) or v105_snapshot (v105)
rows = []
def add(section, item, v4, v5, src4, src5, note=""):
    rows.append(dict(section=section, item=item, v104=v4, v105=v5, source_v104=src4, source_v105=src5, note=note))
f = lambda x, d=4: ("" if x is None or (isinstance(x, float) and not np.isfinite(x)) else (f"{x:.{d}f}" if isinstance(x, (float, np.floating)) else str(x)))
J4 = json.load(open(f"{A}/out/v105_constants.json")); J5 = json.load(open(f"{B}/out/v105_constants.json"))
# ---- increment coefficients, SE, bootstrap 95%
for fit, b4f, b5f in (("dDBH_L_NO", "boot_v103_dDBH_L_NO_summary.csv", "boot_v103_dDBH_summary.csv"), ("dHT_L_NO", "boot_v103_dHT_summary.csv", "boot_v103_dHT_summary.csv")):
    c4 = pd.read_csv(f"{A}/out/inc/coefficients_v103.csv"); c4 = c4[c4.fit == fit].set_index("term")
    c5 = pd.read_csv(f"{B}/out/inc/coefficients_v103.csv"); c5 = c5[c5.fit == fit].set_index("term")
    s4 = pd.read_csv(f"{A}/out/inc/{b4f}").set_index("term"); s5p = f"{B}/out/inc/{b5f}"; s5 = pd.read_csv(s5p).set_index("term") if os.path.exists(s5p) else None
    for t in [f"b{i}" for i in range(10)]:
        bi4 = f"{f(s4.loc[t,'lo95'])} to {f(s4.loc[t,'hi95'])} (n {int(s4.loc[t,'n_ok'])})"
        bi5 = f"{f(s5.loc[t,'lo95'])} to {f(s5.loc[t,'hi95'])} (n {int(s5.loc[t,'n_ok'])})" if s5 is not None else "not run"
        add(f"Eq. 4 {fit}", f"{t} estimate (model SE); bootstrap 95%", f"{f(c4.loc[t,'estimate'])} ({f(c4.loc[t,'se'])}); {bi4}", f"{f(c5.loc[t,'estimate'])} ({f(c5.loc[t,'se'])}); {bi5}",
            f"out/inc/coefficients_v103.csv; out/inc/{b4f}", f"out/inc/coefficients_v103.csv; out/inc/{b5f}", "b8 = ln(site index) term" if t == "b8" else "")
    st4 = pd.read_csv(f"{A}/out/inc/fit_stats_v103.csv").set_index("fit").loc[fit]; st5 = pd.read_csv(f"{B}/out/inc/fit_stats_v103.csv").set_index("fit").loc[fit]
    for k in ("logLik", "aic", "tau_source", "tau_inst", "cf_source_inst", "c_natural", "c_planted", "cal_natural", "cal_planted"):
        add(f"Eq. 4 {fit}", k, f(st4[k], 5), f(st5[k], 5), "out/inc/fit_stats_v103.csv", "out/inc/fit_stats_v103.csv")
    key = "DDBH" if fit.startswith("dDBH") else "DHT"
    add(f"Eq. 4 {fit}", "CAL_SE_LOG (natural, planted)", str([round(x, 5) for x in J4[key]["CAL_SE_LOG"]]), str([round(x, 5) for x in J5[key]["CAL_SE_LOG"]]) + (" " + J5[key].get("CAL_SE_LOG_status", "") if "carried" in J5[key].get("CAL_SE_LOG_status", "") else ""), "out/v105_constants.json (v105b job)", "out/v105_constants.json")
# site effect ratio at the projection levels
for fit, key in (("dDBH_L_NO", "DDBH"), ("dHT_L_NO", "DHT")):
    b84 = J4[key]["coef"]["b8"]; b85 = J5[key]["coef"]["b8"]
    add(f"Eq. 4 {fit}", "increment ratio high vs low level, exp(b8 ln(high/low))", f"{np.exp(b84*np.log(418/142)):.3f} (418 vs 142)", f"{np.exp(b85*np.log(418/142)):.3f} (418 vs 142)", "out/v105_constants.json (v105b job)", "out/v105_constants.json")
# ---- height Eq. 2
h4 = pd.read_csv(f"{A}/track2/out/height_coefficients.csv"); h4 = h4[h4.frame == "v103"].set_index("parameter")
h5 = pd.read_csv(f"{B}/track2/out/height_coefficients.csv"); h5 = h5[h5.frame == "v103"].set_index("parameter")
hb4 = pd.read_csv(f"{A}/a5/rerun/h/h_boot_summary_final.csv").set_index("term"); hb5 = pd.read_csv(f"{B}/a5/rerun/h/h_boot_summary_final.csv").set_index("term")
for p in ("a0", "a1", "b", "c", "g1", "g2"):
    n5 = " (fixed at v104)" if bool(h5.loc[p, "fixed_at_v104"]) else ""
    add("Eq. 2 height", f"{p} estimate (SE); installation bootstrap 95%", f"{f(h4.loc[p,'estimate'],6)} ({f(h4.loc[p,'se'],6)}); {f(hb4.loc[p,'lo'],4)} to {f(hb4.loc[p,'hi'],4)}",
        f"{f(h5.loc[p,'estimate'],6)} ({f(h5.loc[p,'se'],6)}){n5}; {f(hb5.loc[p,'lo'],4)} to {f(hb5.loc[p,'hi'],4)}", "track2/out/height_coefficients.csv; a5/rerun/h/h_boot_summary_final.csv", "same files (v105)",
        "a1 = site modifier" if p == "a1" else "")
hs4 = pd.read_csv(f"{A}/track2/out/height_stats.csv").set_index("frame").loc["v103"]; hs5 = pd.read_csv(f"{B}/track2/out/height_stats.csv").set_index("frame").loc["v103"]
for k in ("n", "n_inst", "logLik", "r2_pa", "rmse_pa"): add("Eq. 2 height", k, f(hs4[k], 4), f(hs5[k], 4), "track2/out/height_stats.csv", "track2/out/height_stats.csv")
add("Eq. 2 height", "bootstrap draws converged", f"{int(hb4['converged'].iloc[0])} of {int(hb4['draws_done'].iloc[0])}", f"{int(hb5['converged'].iloc[0])} of {int(hb5['draws_done'].iloc[0])}", "a5/rerun/h/h_boot_summary_final.csv", "same")
# ---- survival Eq. 5 / 5a site terms (frame "v103" = the current frame of each job)
s4 = pd.read_csv(f"{A}/track2/out/surv_coefficients.csv"); s5 = pd.read_csv(f"{B}/track2/out/surv_coefficients.csv")
for eq in ("Eq5", "Eq5a"):
    for term in ("log(byi/100)", "I(byi/1000)"):
        a = s4[(s4["eq"] == eq) & (s4.frame == "v103") & (s4.term == term)].iloc[0]; b = s5[(s5["eq"] == eq) & (s5.frame == "v103") & (s5.term == term)].iloc[0]
        g = lambda x: f"{x.estimate:.4g} (glm SE {x.se_glm:.4g}; boot {x.boot_lo:.4g} to {x.boot_hi:.4g})"
        add("Eq. 5 / 5a survival site terms (reported; not on the deployed mortality path)", f"{eq} {term}", g(a), g(b), "track2/out/surv_coefficients.csv", "track2/out/surv_coefficients.csv")
# ---- mortality level
add("Mortality", "MORT_CAL natural level (plot SE log)", f"{J4['MORT_CAL']['value'][0]} ({J4['MORT_CAL']['se_log'][0]})", f"{J5['MORT_CAL']['value'][0]} ({J5['MORT_CAL']['se_log'][0]})", "out/v105_constants.json (v105b job)", "out/v105_constants.json")
add("Mortality", "plot / installation bootstrap 95%; LOIO range", f"{np.round(J4['MORT_CAL']['plot_ci95'],3).tolist()} / {np.round(J4['MORT_CAL']['inst_ci95'],3).tolist()}; {np.round(J4['MORT_CAL']['loio_range'],3).tolist()}",
    f"{np.round(J5['MORT_CAL']['plot_ci95'],3).tolist()} / {np.round(J5['MORT_CAL']['inst_ci95'],3).tolist()}; {np.round(J5['MORT_CAL']['loio_range'],3).tolist()}", "out/v105_constants.json (v105b job)", "out/v105_constants.json")
# ---- Table 4
for fn, scol, acol, vcol in (("table8_evenaged_M1.csv", "Site", "Age", "VOL"), ("uneven_aged_table8_M1.csv", "Site", "Age", "VOL")):
    p4 = f"{A}/engine_v103/out_m1/{fn}"; p5 = f"{B}/engine_v103/out_m1/{fn}"
    if not (os.path.exists(p4) and os.path.exists(p5)): continue
    t4 = pd.read_csv(p4); t5 = pd.read_csv(p5)
    vc = vcol if vcol in t4.columns else [c for c in t4.columns if c.lower().startswith("vol")][0]
    for sc in t5.Scenario.unique():
        for lev in ("Low", "Medium", "High"):
            for age in (40, 100):
                r4 = t4[(t4.Scenario == sc) & (t4[scol].str.startswith(lev)) & (t4[acol] == age)]; r5 = t5[(t5.Scenario == sc) & (t5[scol].str.startswith(lev)) & (t5[acol] == age)]
                if not len(r4) or not len(r5): continue
                g = lambda r: f"{r[vc].iloc[0]:.1f} ({r[vc + '_lo'].iloc[0]:.1f} to {r[vc + '_hi'].iloc[0]:.1f})" if vc + "_lo" in r.columns else f"{r[vc].iloc[0]:.1f}"
                q = lambda r: f"; QMD {r['QMD'].iloc[0]:.1f}" if "QMD" in r.columns else ""
                add("Table 4 volume m3 ha-1 (95% MC range)", f"{sc} | {lev} | {age} yr", f"{r4[scol].iloc[0]}: {g(r4)}{q(r4)}", f"{r5[scol].iloc[0]}: {g(r5)}{q(r5)}", f"engine_v103/out_m1/{fn}", f"engine_v103/out_m1/{fn}")
# ---- culmination
c4 = json.load(open(f"{A}/a4/culmination_mc_v104.json")); c5 = json.load(open(f"{B}/a4/culmination_mc_v104.json"))
k5 = list(c5.keys())
for k in c4:
    sc, site = k.split("|"); lev = site.split(" ")[0]; kk = [x for x in k5 if x.startswith(sc + "|" + lev)]
    if kk: add("MAI culmination age (yr): point; MC median (95%)", f"{sc} | {lev}", f"{site}: {c4[k]['pt_window']}; {c4[k]['med_window']}", f"{kk[0].split('|')[1]}: {c5[kk[0]]['pt_window']}; {c5[kk[0]]['med_window']}", "a4/culmination_mc_v104.json", "a4/culmination_mc_v104.json (v105 values, name kept)")
# ---- plot-level validation
V4 = pd.read_csv(f"{A}/a2/closeout/validation/tableC2_v104_plotlevel.csv"); V5 = pd.read_csv(f"{B}/a2/closeout/validation/tableC2_v104_plotlevel.csv")
for _, r in V5.iterrows():
    if not str(r.frame).startswith("v104 plot level") or str(r.group).startswith(("natural excl", "planted excl", "2628")): continue
    m = V4[(V4.frame == r.frame) & (V4.group == r.group) & (V4.quantity == r.quantity)]
    if not len(m): continue
    m = m.iloc[0]; s = lambda x: f"bias {f(x.bias_pred_minus_obs,3)} ({f(x.bias_lo,3)} to {f(x.bias_hi,3)}), TOST bias {'pass' if x.pass_bias else 'fail'}; slope {f(x.slope,3)}, {'pass' if x.pass_slope else 'fail'}"
    add("Plot-level validation (Table C2, predicted minus observed)", f"{r.group} | {r.quantity} | n {int(r.n)}", s(m), s(r), "a2/closeout/validation/tableC2_v104_plotlevel.csv", "same file name (v105 values)")
R4 = pd.read_csv(f"{A}/a2/closeout/validation/tableC1_v104_plotlevel.csv"); R5 = pd.read_csv(f"{B}/a2/closeout/validation/tableC1_v104_plotlevel.csv")
for g in ("all (excl. 2628)", "natural (excl. 2628)", "planted (excl. 2628)"):
    a = R4[(R4.frame == "v104 plot level") & (R4.group == g)]; b = R5[(R5.frame == "v104 plot level") & (R5.group == g)]
    if len(a) and len(b):
        for q in ("survW", "QMD", "BA"): add("Plot-level validation RMSE (Table C1)", f"{g} | {q} RMSE", f(a[q + "_RMSE"].iloc[0], 3), f(b[q + "_RMSE"].iloc[0], 3), "a2/closeout/validation/tableC1_v104_plotlevel.csv", "same file name")
# ---- trajectory validation (a4/lt, lt_v103.py)
T4 = pd.read_csv(f"{A}/a4/lt/LT_v104_summary.csv"); T5 = pd.read_csv(f"{B}/a4/lt/LT_v104_summary.csv")
for _, r in T5.iterrows():
    m = T4[(T4.origin == r.origin) & (T4.horizon == r.horizon)]
    if not len(m): continue
    m = m.iloc[0]; s = lambda x: f"n {int(x.n_points)}; surv bias {x.surv_bias:.3f}; QMD bias {x.qmd_bias:.2f} (RMSE {x.qmd_rmse:.2f}); BA bias {x.ba_bias:.2f} (RMSE {x.ba_rmse:.2f})"
    add("Trajectory validation (a4/lt/LT_v104_summary.csv, predicted minus observed)", f"{r.origin} | {r.horizon} yr", s(m), s(r), "a4/lt/LT_v104_summary.csv", "same file name (v105 values)")
# ---- LOIO
L4 = pd.read_csv(f"{A}/a5/loio/loio_metrics.csv"); L5 = pd.read_csv(f"{B}/a5/loio/loio_metrics.csv")
for _, r in L5[L5.frame == "held-out LOIO"].iterrows():
    m = L4[(L4.frame == "held-out LOIO") & (L4.group == r.group) & (L4.variable == r.variable)].iloc[0]
    s = lambda x: f"{x.decision}; bias {f(x.bias,4)} (90% {f(x.bias_lo90,4)} to {f(x.bias_hi90,4)})"
    add("LOIO held-out (preregistered rule)", f"{r.group} | {r.variable}", s(m), s(r), "a5/loio/loio_metrics.csv", "a5/loio/loio_metrics.csv")
# ---- paired MC
for fn in ("prob_ordering.csv",):
    P4 = pd.read_csv(f"{A}/a5/pairmc/out_a5/{fn}"); p5 = f"{B}/a5/pairmc/out_a5/{fn}"
    if os.path.exists(p5):
        P5 = pd.read_csv(p5)
        for var in ("PPB", "BOOT_PPB", "P", "B", "BOOT"):
            for o in ("natural", "planted"):
                for cmp_ in ("high>low", "med>low", "high>med"):
                    a = P4[(P4.variant == var) & (P4.origin == o) & (P4.age == 40) & (P4.comparison == cmp_)]; b = P5[(P5.variant == var) & (P5.origin == o) & (P5.age == 40) & (P5.comparison == cmp_)]
                    if len(a) or len(b):
                        s = lambda x: f"P {x.P.iloc[0]:.3f} ({x.verdict.iloc[0]})" if len(x) else "not run"
                        add("Paired MC, 40 yr volume", f"{var} | {o} | {cmp_}", s(a), s(b), f"a5/pairmc/out_a5/{fn}", f"a5/pairmc/out_a5/{fn}")
# ---- Bakuzis
K = pd.read_csv(f"{B}/a4/bakuzis/bakuzis_checks_v104_v105.csv"); KC = pd.read_csv(f"{B}/a4/bakuzis/bakuzis_counts_v104_v105.csv")
for res in ("PASS", "FLAG", "NOT EVALUATED"):
    g = lambda v: int(KC[(KC.version == v) & (KC.result == res)].n.sum())
    add("Bakuzis matrix (a4/bakuzis/bakuzis_v105_vs_v104.R; v104 recomputed from the v104 job trajectories)", f"count {res}", g("v104"), g("v105"), "a4/bakuzis/bakuzis_counts_v104_v105.csv", "same")
for rel in ("Reineke (stem-loss window)", "site ordering", "magnitude to 100 yr", "culmination earlier on better sites", "Eichhorn"):
    for grp in K.group.unique():
        a = K[(K.version == "v104") & (K.group == grp) & (K.relation == rel)]; b = K[(K.version == "v105") & (K.group == grp) & (K.relation == rel)]
        if not len(b): continue
        if rel == "site ordering":
            add("Bakuzis matrix", f"{grp} | site ordering checks passed", f"{(a.result == 'PASS').sum()} of {len(a)}", f"{(b.result == 'PASS').sum()} of {len(b)}", "a4/bakuzis/bakuzis_checks_v104_v105.csv", "same")
        else:
            for it in b.item:
                aa = a[a.item == it]; bb = b[b.item == it]
                add("Bakuzis matrix", f"{grp} | {rel} | {it}", f"{aa.value.iloc[0]} {aa.result.iloc[0]}" if len(aa) else "", f"{bb.value.iloc[0]} {bb.result.iloc[0]}", "a4/bakuzis/bakuzis_checks_v104_v105.csv", "same")
# ---- containment / envelope
C4 = pd.read_csv(f"{A}/a5/rerun/qr/containment_v104.csv"); C5 = pd.read_csv(f"{B}/a5/rerun/qr/containment_v104.csv")
for tau in (0.99, 0.95):
    for runs in ("point", "mc_reps"):
        a = C4[(C4.tau == tau) & (C4.runs == runs)]; b = C5[(C5.tau == tau) & (C5.runs == runs)]
        add("Limiting-line containment (ages 1 to 100)", f"tau {tau} | {runs}: points above line; max fraction of line", f"{int(a.n_above.sum())} of {int(a.n.sum())}; {a.max_frac_of_line.max():.3f}", f"{int(b.n_above.sum())} of {int(b.n.sum())}; {b.max_frac_of_line.max():.3f}", "a5/rerun/qr/containment_v104.csv", "same file name")
D = pd.DataFrame(rows); D.to_csv(OUTP + ".csv", index=False)
with open(OUTP + ".md", "w") as fh:
    for sec, g in D.groupby("section", sort=False):
        fh.write(f"\n### {sec}\n\n| item | v104 | v105 | source (v104 job / v105 job) |\n|---|---|---|---|\n")
        for _, r in g.iterrows(): fh.write(f"| {r['item']} | {r.v104} | {r.v105} | {r.source_v104} / {r.source_v105} |\n")
print(len(D), "rows")
