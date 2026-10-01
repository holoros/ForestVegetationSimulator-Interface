#!/usr/bin/env python3
"""make_report.py: assemble STAGE1_REPORT.md and out/v103_constants.json from the outputs of this job. No coordinates are read."""
import pandas as pd, numpy as np, json, os, re, glob
os.chdir(os.path.expanduser("~/jobs/koa_v103_20260930")); V2 = os.path.expanduser("~/jobs/koa_v102_20260918/")
def rd(p, **k): return pd.read_csv(p, **k)
def fmt(x, d=4):
    if isinstance(x, (float, np.floating)):
        if not np.isfinite(x): return "NA"
        return f"{x:.{d}g}" if (abs(x) >= 1e4 or (abs(x) < 1e-3 and x != 0)) else f"{x:.{d}f}"
    return str(x)
def table(df, d=4):
    cols = list(df.columns); out = ["| " + " | ".join(cols) + " |", "|" + "|".join(["---"] * len(cols)) + "|"]
    for _, r in df.iterrows(): out.append("| " + " | ".join(fmt(r[c], d) for c in cols) + " |")
    return "\n".join(out)
L = []; A = L.append
rlog = open("logs/repair_v103.log").read(); plog = open("logs/post_frames_v103.log").read(); ilog = open("logs/inc_v103.log").read(); slog = open("logs/stage1_garcia_v103.log").read()
summ = json.load(open("out/repair/summary.json"))
st = rd("out/repair/plotyear_stand_before_after.csv"); g3 = rd("out/repair/g3_before_after_by_source.csv"); comp = rd("out/repair/species_composition_by_source.csv")
top_a = rd("out/repair/g2_top10_after.csv"); top_b = rd("out/repair/g2_top10_before.csv"); d2 = rd("out/repair/d2_flagged_visits.csv"); d2all = rd("out/repair/d2_scan_all_visits.csv")
g4 = rd("out/frames/g4_covariate_change.csv"); ug = rd("out/frames/uniqueness_gates.csv"); brep = rd("out/frames/builder_reproduction_v102.csv")
A("# STAGE1_REPORT, koa v103 Stage A1: repair of the stand covariates (D1) and the carried forward Keauhou records (D2), frames and refits\n")
A("Job ~/jobs/koa_v103_20260930 on firebreather, 30 September 2026. R 4.5.1 (nlme), python3 (pandas, numpy). Only this directory was written. Every input is a copy with its md5 in logs/md5_inputs.txt, commands and timings are in RUN.md. No coordinate column was read into any frame, and the absence of lat, lon, long, latitude, longitude, x and y was asserted on every frame written.\n")
A("## 1. Repair rules (preregistered in RUN.md before any repair or fit)\n")
A("D1. For every plot-year of the koa tree table, BAPH, TPH, QMD and SDI (summation form, sum EXPF x (DBH/25.4)^1.605) are recomputed from live stems (Status live, DBH > 0, EXPF > 0) of all species in the deduplicated all species list; BA.AK and pBA.AK from the live koa stems. The all species list is TREE.ALL.csv deduplicated with the v102 rulings A3 and A1' (A2' is the same keep rule). FIA plot-years are rebuilt from HI_TREE.csv (STATUSCD 1, all species, per subplot expansion TPA_UNADJ x 4 x 2.47105 per ha). BAL is carried in three definitions: d, the deposited form recomputed on the repaired list, (1 - DBH rank percentile over every koa record of the plot-year) x repaired BAPH; l, the live list percentile, (1 - rank percentile over live koa stems) x repaired BAPH; c, conventional, expansion weighted basal area of live stems of all species strictly larger than the subject.\n")
A("D2. A visit whose live trees shared with the previous visit are at least 90 percent identical in DBH and HT is removed; a visit with 50 to 90 percent identical trees loses the identical tree-visits; under 50 percent everything is kept (real zero growth). Stand variables are computed on the full visit. The refit2 removal screen (Thin_Yr and removal_t1_years strictly inside the interval) is applied to every increment and survival frame.\n")
A("## 2. Gates\n")
def grab(pat, s=rlog):
    m = re.search(pat, s); return m.group(0) if m else "NOT FOUND"
gates = [("G0 deduplicated TREE.ALL koa subset equals AK_TREE_v102 (17,074 records, every key, DBH, HT, Age, EXPF, Status and deposited stand cell)", grab(r"GATE G0.*")),
         ("FIA mapping to HI_TREE (667 koa records, SPCD 6006, DBH to 0.02 cm, status)", grab(r"GATE FIA mapping.*")),
         ("FIA cross check, TREE.ALL rescaled vs HI_TREE rebuild", grab(r"FIA check.*")),
         ("G1 single species plot-years, rebuilt BAPH equals the live koa sum to 1e-6", grab(r"GATE G1.*")),
         ("Tree table uniqueness", grab(r"AK_TREE_v103 rows.*")),
         ("Builder reproduction on the v102 inputs (7 frames identical on every cell)", "; ".join(f"{r.frame} {r.rows_rebuilt} {'PASS' if r.identical else 'FAIL'}" for r in brep.itertuples())),
         ("Uniqueness gates on every v103 frame", "; ".join(f"{r.frame} {r.rows} {r.gate}" for r in ug.itertuples()))]
for g, v in gates: A(f"- {g}: {v}")
A("")
A(f"G2 physical credibility. Rebuilt BAPH over {len(st)} koa plot-years: " + grab(r"G2 rebuilt BAPH distribution.*") + ". The bound I can justify is 100 m2/ha for a stand level value: it is close to the 99th percentile of the rebuilt plot-years (94.2) and above every non FIA value (largest 91.4, a 7 stem Kap plot; largest PSP 68.9; largest DOFAW 47.0), and above the largest deposited value the engine documents as observed (76.06, which was itself a doubled Kulani 23 1994 value, now 38.2). Result: G2 FLAGS 5 FIA subplot-years above 100 (164.2, 147.3, 131.6, 125.0, 102.3). They are not data errors. Each is one 1/24 acre (0.0169 ha) subplot whose expansion puts a single large tree at 59.5 stems/ha (the 158 cm ohia on 15-1-1-2291 subplot 2 alone is 116 m2/ha); the tree lists were checked against HI_TREE. They are kept under the preregistered x4 rule, and their effect is counted in G4. All deposited FIA values were one quarter of the subplot value (whole plot TPA applied to one subplot), which is why FIA medians rise from 9.5 to 25.3 m2/ha.\n")
A("Top 10 plot-years after the repair\n"); A(table(top_a, 4)); A("\nTop 10 plot-years before the repair (deposited)\n"); A(table(top_b, 4)); A("")
A("G3 before and after by source (median and max)\n")
g3s = g3[["Data", "plotyears", "changed_gt1pct", "BAPH_med_before", "BAPH_med_after", "BAPH_max_before", "BAPH_max_after", "TPH_med_before", "TPH_med_after", "TPH_max_before", "TPH_max_after", "QMD_med_before", "QMD_med_after", "QMD_max_before", "QMD_max_after", "SDI_med_before", "SDI_med_after", "SDI_max_before", "SDI_max_after"]]
A(table(g3s, 4)); A("")
A(grab(r"plot-years whose BAPH or TPH changed.*") + ". " + grab(r"no live stem with EXPF > 0:.*") + " " + grab(r"live stems with DBH > 0 and EXPF 0.*") + ". Fallback count: " + str(summ["fallback"]) + " plot-years kept deposited (Kualoa, no expansion factor, deposited BAPH 0). Species composition by source (the single species sources are the only ones where G1 applies):\n")
A(table(comp, 4)); A("")
A("G4 fitting-frame rows whose covariates changed by more than 5 percent (common keys v103 vs v102)\n"); A(table(g4, 4)); A("")
A("## 3. Copied visits (D2)\n")
A(grab(r"D2 scan:.*") + ". " + grab(r"D2 copied visits removed:.*") + ". No visit fell in the 50 to 90 percent band, so no partial copy tree-visit was removed. The 2017 and 2019 partial copies named by the red team are below 50 percent and are kept by the rule (zero growth kept as real).\n")
A(table(d2[["Data", "Install", "Plot", "Measure", "prev", "n_common", "n_ident_dbh", "n_ident_dbh_ht", "share", "class"]], 4)); A("")
lo = d2all[(d2all.share > 0) & (d2all.share < 0.5)].sort_values("share", ascending=False).head(12)
A("Largest shares below the 50 percent threshold (kept)\n"); A(table(lo[["Data", "Install", "Plot", "Measure", "prev", "n_common", "n_ident_dbh_ht", "share"]], 3)); A("")
A("Effect on each frame: " + "; ".join(re.findall(r"(?:plot_intervals|plot_intervals_origin|ingrowth v103)[^\n]*rows touching a copied visit removed[^\n]*", plog)) + ". The M1 pair table goes from 415 to 407 intervals, the dDBH consecutive frame gains 2 rows (4,790 to 4,792) because the 2014 to 2015 zero growth rows were already screened out and each 2015 to 2016 row becomes a true 2014 to 2016 row, dHT stays at 3,857, the static height frame loses 145 records.\n")
A("## 4. Frames, v102 vs v103\n")
fr = [("dDBH consecutive (CS)", 4790, 4792), ("dHT consecutive (CS)", 3857, 3857), ("dDBH NO (consecutive plus first to last)", 4969, None), ("dHT NO", 4033, None), ("AK_SURV deposit table", 4869, 4871), ("Eq5 baseline survival", "4,869 (79 deaths)", None), ("Eq5a recovered ii", "4,298 (877 deaths)", None), ("recovered i", "4,114 (798)", None), ("static height frame", 9282, 9137), ("height fit records", 9059, 8914), ("M1 pair table", 415, 407), ("plot_intervals (Stage 1 input)", 326, 318), ("Stage 1 fitting intervals", 290, 282), ("ingrowth", 358, 357), ("FIA crown frame", 360, 360)]
m = re.search(r"NO dDBH rows (\d+)", ilog); fr[2] = (fr[2][0], "4,969 (refit2)", int(m.group(1)) if m else None); m = re.search(r"NO dHT rows (\d+)", ilog); fr[3] = (fr[3][0], "4,033 (refit2)", int(m.group(1)) if m else None)
ug_d = dict(zip(ug.frame, ug.rows))
sv = rd("track2/out/surv_stats.csv")
fr[5] = (fr[5][0], fr[5][1], f"{ug_d.get('surv_baseline_rebuilt_v103')} ({int(sv[(sv['eq']=='Eq5')&(sv.frame=='v103')].deaths.iloc[0])} deaths)")
fr[6] = (fr[6][0], fr[6][1], f"{ug_d.get('surv_recovered_ii_v103')} ({int(sv[(sv['eq']=='Eq5a')&(sv.frame=='v103')].deaths.iloc[0])} deaths)")
fr[7] = (fr[7][0], fr[7][1], f"{ug_d.get('surv_recovered_i_v103')}")
A(table(pd.DataFrame(fr, columns=["frame", "v102", "v103"]))); A("\nThe removal screen removed 0 rows from the consecutive and survival frames (no consecutive interval spans an interior removal year) and 78 candidate pairs from the NO frame.\n")
# ---------------- height
A("## 5. Component refits\n")
A("Reproduction gates, each run before the v103 fit: " + "; ".join([grab(r"HEIGHT REPRODUCTION.*", open("logs/height_refit_v103.log").read()), grab(r"SURVIVAL REPRODUCTION.*", open("logs/surv_refit_v103.log").read()), grab(r"INGROWTH REPRODUCTION.*", open("logs/ingrowth_refit_v103.log").read()), grab(r"STAGE 1 REPRODUCTION.*", slog), grab(r"ALLOMETRY REPRODUCTION.*", slog), grab(r"GARCIA CHECK REPRODUCTION.*", slog), grab(r"GATE beta anchor.*", open("logs/beta_anchor_v103.log").read())] + re.findall(r"REPRO R\d.*PASS[^\n]*|REPRO R\d.*FAIL[^\n]*", ilog) + [grab(r"COHORT REPRODUCTION.*", open("logs/cohort_v103.log").read())]) + ". R1 differs from the refit2 vector by 3.4e-5 at most (5.7e-5 SE, logLik 1.7e-5) because refit2 fitted its in-memory frame and this run reads it back from CSV; that is accepted as reproduction at 1e-3 SE and is stated here.\n")
hs = rd("track2/out/height_side_by_side.csv"); hst = rd("track2/out/height_stats.csv")
lo2 = rd("track3_s02/v102/02_height_loio.csv"); lo3 = rd("track3_s02/v103/02_height_loio.csv")
A("### 5.1 Eq. 2 static height (HT_P)\n"); A(table(hs.rename(columns={"dz_v102_se": "change in v102 SE"}), 5)); A("")
h2 = hst[["frame", "n", "n_inst", "logLik", "AIC", "tau_inst", "sigma", "r2_cond", "r2_pa", "rmse_pa", "bias_pa", "bias_pa_natural", "bias_pa_planted"]].copy()
h2["loio_r2"] = [lo2.r2.iloc[0], lo3.r2.iloc[0]]; h2["loio_rmse"] = [lo2.rmse.iloc[0], lo3.rmse.iloc[0]]; h2["loio_bias"] = [lo2.bias.iloc[0], lo3.bias.iloc[0]]
A(table(h2, 4)); A("\nThe asymptote falls (a0 -2.2 SE, a1 -1.6 SE) and the density term strengthens (g1 +2.7 SE), because the repaired BAPH halves the doubled PSP and DOFAW values and quadruples FIA. LOIO (143 folds) improves slightly.\n")
# ---------------- HCB
hf = rd("track2/hcb/hcb_fit_stats_v103.csv"); hc = rd("track2/hcb/hcb_coefficients_v103.csv")
A("### 5.2 Eq. 3 crown (HCB_P)\n")
A("The FIA crown frame (360 trees, 69 subplots, 36 plots) was matched to HI_TREE (all 360 matched by DBH, 203 at the same INVYR, the rest 1 to 5 yr earlier by measurement year) and BAPH and BAL rebuilt from the live all species subplot list with the x4 expansion.\n")
A(table(hf[hf.rmse.notna()], 4)); A("")
A(table(hc[["bal", "term", "HCB_P", "estimate", "se_nls", "boot_se", "lo95", "hi95", "sign_kept", "dz_boot"]], 4))
fl = "; ".join(f"{b}: " + ", ".join(hc[(hc.bal == b) & ~hc.sign_kept].term) for b in ("d", "l", "c")); sz = ", ".join(sorted(set(hc[(hc.lo95 < 0) & (hc.hi95 > 0)].term)))
A(f"\nDecision: HCB_P is KEPT. Every refit improves RMSE (2.09 to 2.11 m against 2.23 to 2.38 for HCB_P on the same covariates) but none keeps every sign (terms that flip, by definition: {fl}); the plot bootstrap intervals of {sz} span zero under at least one definition. The rule requires both."+" All increment and survival crown ratios in v103 therefore use HCB_P (increments) or the frame builder's koa.HCB (survival), exactly as in v102.\n")
# ---------------- survival
sc = rd("track2/out/surv_coefficients.csv"); A("### 5.3 Eq. 5 and Eq. 5a survival\n")
for eq in ("Eq5", "Eq5a"):
    a2 = sc[(sc['eq'] == eq) & (sc.frame == "v102")].set_index("term"); a3 = sc[(sc['eq'] == eq) & (sc.frame == "v103")].set_index("term")
    t = pd.DataFrame(dict(term=a2.index, v102=a2.estimate.values, v102_se_glm=a2.se_glm.values, v103=a3.estimate.reindex(a2.index).values, v103_se_glm=a3.se_glm.reindex(a2.index).values,
                          v103_boot_lo=a3.boot_lo.reindex(a2.index).values, v103_boot_hi=a3.boot_hi.reindex(a2.index).values))
    t["change in v102 SE"] = (t.v103 - t.v102) / t.v102_se_glm; A(f"{eq}\n"); A(table(t, 4)); A("")
A(table(sv[["eq", "frame", "n", "deaths", "installations", "aic", "converged_both", "auc_apparent", "auc_loio_pooled", "auc_loio_annual", "auc_within_interval", "loio_folds_converged", "expected_deaths"]], 4))
A("\nEq. 5a (death response, recovered ii frame, 4,223 rows, 877 deaths) is refit cleanly: AIC 3,080.0 to 3,043.0, LOIO annual AUC 0.728 to 0.767, within interval AUC unchanged at 0.776; ln(cr) moves +5.4 SE (1.66 to 5.02) because crown ratio is the covariate the repaired BAL and BAPH feed. Eq. 5 (Table 6 vector, 79 deaths, most of them FIA: 67 of 79 in the record table) does NOT survive the repair: AIC rises from 866.4 to 1,110.1 on two more rows with the same deaths, LOIO annual AUC falls from 0.813 to 0.633, 7 of 62 LOIO folds fail to converge, ln(cr) changes sign (14.30 to -11.01, -35 SE) and the bootstrap is degenerate. The FIA crown ratios computed by koa.HCB with the quadrupled FIA BAPH no longer separate the FIA deaths. Decision: the v103 Eq. 5 vector is NOT deployable; Eq. 5 is off the production path (the M1 gated Garcia rate projects mortality), so the engine keeps the v102 Eq. 5 vector with this failure disclosed, and Eq. 5a v103 is reported as the replacement specification.\n")
# ---------------- ingrowth
ig = rd("track2/out/ingrowth_coefficients_v103.csv"); A("### 5.4 Eq. 6 ingrowth\n")
A(table(ig[["frame", "term", "estimate", "se", "lo95", "hi95", "n", "n_plots", "dispersion", "b_SDI_engine", "dz_record_se"]].rename(columns={"dz_record_se": "change in v102 SE"}), 5))
A("\nThe v103 frame repairs BAPH, SDI, RD (= SDI/500) and pBA at the inferred start visit for 347 of 357 rows (10 rows without an identified start visit keep the deposited values) and merges the 2014 to 2015 to 2016 Keauhou periods. The vector moves by at most 0.06 SE; the ingrowth frame is still the key deduplicated record, not a rebuild (v102 deviation D4 stands).\n")
# ---------------- stage 1, garcia
s1 = rd("track2/stage1/stage1_v103.csv"); al = rd("track2/stage1/garcia_allometry_v103.csv"); gc = rd("track2/stage1/garcia_check_v103.csv"); ba = json.load(open("track2/stage1/beta_anchor_v103.json"))
A("### 5.5 Stage 1 mortality gate, Stage 2, and the Garcia inputs\n")
A("Stage 1 and 2 are refit with fitB of origin_refit_span.R on plot_intervals with sdi (its own form TPH x (QMD/25)^1.605, reproduced on 288 of 326 deposited rows and scaled on the rest) recomputed from the repaired stand table and the 2015 Keauhou intervals merged; the refit2 Thin_Yr screen removed no further interval.\n")
A(table(s1, 4)); A("\n" + grab(r"Stage 1 n .*", slog) + ". Every Stage 1 and Stage 2 term moves by less than 0.26 SE.\n")
A("Garcia allometry ln QMD0 = A + k_HD ln H40_0 on the regular intervals of the M1 pair table\n"); A(table(al.rename(columns={"Unnamed: 0": "table"}), 4))
A(f"\nThe allometry moves materially: A from -0.1686 to {al.A.iloc[2]:.4f} (+{(al.A.iloc[2]-al.A.iloc[0])/al.se_A.iloc[0]:.1f} record SE) and k_HD from 1.1719 to {al.K_HD.iloc[2]:.4f} ({(al.K_HD.iloc[2]-al.K_HD.iloc[0])/al.se_K.iloc[0]:.1f} SE). Most of the move is already in v102 (the deduplicated pair table), and the rest is the repaired QMD0 plus the FIA H40 change (EXPF x4 means fewer FIA trees make up the top 40 per ha).\n")
A("Anchored beta (100 / sqrt(z99 of N x H_QMD^2))\n")
bt = pd.DataFrame([dict(version=k, z99=v["z99"], n=v["n"], beta=v["beta"], note=v.get("note", "")) for k, v in ba.items() if isinstance(v, dict) and "z99" in v]); A(table(bt, 5))
A("\nThe record anchor counted every record of the plot-measure, dead stems included (the gate reproduces 389,696.3 and n 471 only in that form). The v103 value deployed is the live koa form, 0.14803, because the Garcia step acts on the simulated koa stand; the all species form (0.11607, driven by the FIA subplot densities of up to 19,860 stems/ha) is given as a sensitivity and is a decision for Aaron.\n")
A("Garcia alpha check fit (H40 form), not deployed, as in v102 D6\n"); A(table(gc, 4)); A("\nGARCIA_ALPHA 2.96 of record stays deployed; the v103 check fit moves it to 3.86 (bootstrap 2.12 to 19.95), so the rate is still weakly identified.\n")
# ---------------- increments
A("### 5.6 Eq. 4 increments, preregistered selection\n")
sel = rd("out/inc/selection_v103.csv"); eq = rd("out/inc/equivalence_v103.csv"); ev = rd("out/inc/evaluation_strata_v103.csv"); fs = rd("out/inc/fit_stats_v103.csv"); co = rd("out/inc/coefficients_v103.csv"); dec = rd("out/inc/decision_v103.csv")
A(table(sel[["fit", "sign_pass", "sign_fail", "eq_int_CS", "eq_slope_CS", "eq_int_NO", "eq_slope_NO", "equiv_pass_both", "max_eq_region", "size_max_dev_NO", "size_worst_class", "rmse_CS", "rmse_NO", "slope_CS", "slope_NO", "eligible"]], 4)); A("")
A("Size class obs/pred on the NO frame\n"); A(table(sel[["fit", "size_ratios_NO"]])); A("")
bm = eq[eq.fit.str.contains("V102recal")][["fit", "eval_frame", "slope", "min_region_int", "min_region_slope", "pass_int_25", "pass_slope_25"]]
bs = ev[ev.fit.str.contains("V102recal") & (ev.strat.isin(["all", "size"]))][["fit", "eval_frame", "strat", "level", "n", "ratio", "rmse_ann"]]
A("Benchmark not in the candidate set (red team item 4): the v102 vector of record in engine form with BAL d, its origin constants re-solved on each v103 frame\n"); A(table(bm, 4)); A(""); A(table(bs[bs.eval_frame == "NO"], 3)); A("")
A("Decision\n"); A(table(dec)); A("")
A("No candidate is eligible for either response. Every dDBH candidate over-predicts the large tree classes on the NO frame (obs/pred 1.29 to 1.78 in 30 to 60 cm) and three of the four conventional and live list fits fail the b6 < 0 check (b6 +0.0015 to +0.0175, stand basal area raising growth); every dHT candidate under-predicts trees above 15 m by 24 to 40 percent. Under the fallback of the rule the candidate with the smallest maximum equivalence region is deployed: dDBH_L_NO (0.159; it passes signs and equivalence on both frames and fails only the size gate at 0.70) and dHT_L_NO (0.245, a tie with dHT_C_NO at 0.246). This is DEVIATION A1-D1 and it is recorded, not hidden. Two facts should weigh on it. First, the incumbent benchmark P_CS does not beat the deployed fits (RMSE 1.3118 vs 1.2981 CS and 1.2745 vs 1.2607 NO for dDBH, 1.0921 vs 1.0908 and 1.0766 vs 1.0751 for dHT), so the 1 percent override does not fire. Second, the v102 dDBH vector recalibrated on the v103 frame, which is not a candidate, would be eligible under every criterion (signs pass, equivalence passes on both frames at 0.18 and 0.14, size max deviation 0.18 at 40 to 60 cm, n 95) at an NO RMSE 2.6 percent above dDBH_L_NO; its re-solved constants are in the JSON as an alternate, and choosing it would be a rule change for Aaron to make. For dHT the recalibrated v102 vector fails the intercept at 0.34 and the size gate (1.63 at 20 to 30 m), so no alternate is offered.\n")
# coefficient movement, deployed vs v102
ic = rd(V2 + "track2/out/inc_coefficients.csv"); ic = ic[(ic.frame == "V102") & (ic.start == "deployed_solution")]
bsum = {r: (rd(f"out/inc/boot_v103_{r}_summary.csv") if os.path.exists(f"out/inc/boot_v103_{r}_summary.csv") else None) for r in ("dDBH", "dHT")}
for resp in ("dDBH", "dHT"):
    tag = dec.deployed[dec.resp == resp].iloc[0]; c3 = co[co.fit == tag].set_index("term"); c2 = ic[ic.resp == resp].set_index("term")
    t = pd.DataFrame(dict(term=c3.index, v102=c2.estimate.reindex(c3.index).values, v102_se=c2.se.reindex(c3.index).values, v103=c3.estimate.values, v103_model_se=c3.se.values))
    if bsum[resp] is not None:
        b = bsum[resp].set_index("term"); t["v103_boot_se"] = b.boot_se.reindex(c3.index).values; t["boot_lo95"] = b.lo95.reindex(c3.index).values; t["boot_hi95"] = b.hi95.reindex(c3.index).values
    t["change in v102 SE"] = (t.v103 - t.v102) / t.v102_se
    A(f"{resp} deployed vector {tag} against the v102 vector of record (v102 model SE)\n"); A(table(t, 5)); A("")
fsd = fs[fs.fit.isin(dec.deployed)][["fit", "n", "n_trees", "n_inst", "logLik", "aic", "sigma", "varpower", "tau_source", "tau_inst", "tau_tree", "cf_source_inst", "c_natural", "c_planted", "cal_natural", "cal_planted", "r2_cond_period"]]
A("Deployed fit statistics (c is the recursion consistent origin constant; the engine multiplier is c = CF x CAL)\n"); A(table(fsd, 5)); A("")
for resp in ("dDBH", "dHT"):
    if bsum[resp] is not None: A(f"Bootstrap summary {resp} (installation cluster, within source, B 400)\n"); A(table(bsum[resp], 5)); A("")
    else: A(f"Bootstrap {resp}: NOT FINISHED at report time (see logs/boot_v103_{resp}.log); CAL_*_SE_LOG in the JSON are null until it is.\n")
coh = rd("out/inc/cohort_bal_fraction_v103.csv"); A("### 5.7 Cohort BAL fraction (BAL_COHORT_LIN_B form)\n"); A(table(coh, 4))
A("\nUnder the selected live list definition the fraction is flat in QMD (a1 0.0003, SE 0.009, r2 0.00001), mean 0.448; the engine constant should be a0 0.44703, a1 0.00034 (or a constant 0.448).\n")
# ---------------- downstream
A("## 6. What changes downstream\n")
A("- The engine patch must switch the increment BAL input to the live list percentile (l) for both dDBH and dHT and use the vectors, CF and CAL of out/v103_constants.json; the conventional BAL (HiGy 0.4.0) path is not the deployed definition.\n- CF_DHT is now the fitted value (not 1.030), as in refit2; the per step multipliers are c_natural and c_planted.\n- HT_P moves (a0 28.93, a1 0.967, g1 0.0768); Table 3 and every height derived quantity move.\n- HCB_P unchanged.\n- Stage 1 and 2: tiny moves, patch the json and the HiGy.R mirror (the v102 parity deviation D2 still applies until HiGy.R is synchronised).\n- GARCIA_ALLOM_A, GARCIA_ALLOM_K_HD and GARCIA_BETA_ANCHORED change; GARCIA_ALPHA stays.\n- Eq. 5 stays v102 (v103 refit fails); Eq. 5a v103.\n- Ingrowth moves negligibly.\n- MORT_CAL (natural level) must be re-solved on the patched engine; it is not a Stage A1 output.\n- Everything in Table 5, Table 8, the validation and the MC registry must be regenerated on the patched engine; nothing downstream of the constants was run here.\n- The FIA subplot densities are now per subplot (x4); every FIA derived stand quantity (validation of FIA plots, the M1 H40 of FIA plots) moves with them.\n")
A("## 7. Deviations and open items\n")
A("- A1-D1 (increments): no candidate eligible; fallback deployed for both responses (above).\n- A1-D2 (Eq. 5): v103 refit fails and is not deployed.\n- A1-D3 (G2): 5 FIA subplot-years exceed the 100 m2/ha bound; kept (real single subplot expansions), flagged.\n- A1-D4 (reproduction tolerance): the refit2 R1 gate reproduces to 5.7e-5 SE rather than 1e-6 absolute (CSV round trip).\n- A1-D5 (beta anchor form): deployed on live koa stems; record form counted dead stems.\n- The ingrowth frame and plot_intervals remain repaired copies of the record tables, not rebuilds (builders not on firebreather); Stage 1 sdi on 38 plot_intervals rows was scaled rather than recomputed.\n- The engine simulates a koa only stand while the fitted BAPH and BAL are all species; for the single species sources (PSP, KMR PSP, Kualoa, Mauka) this is immaterial, for DOFAW, FIA and the mixed sources it is a known mismatch the engine patch should state.\n")
open("STAGE1_REPORT.md", "w").write("\n".join(L).replace("—", ", "))
# ---------------- constants
hc3 = rd("track2/out/height_coefficients.csv"); h3 = hc3[hc3.frame == "v103"].set_index("parameter")
def vec(resp):
    tag = dec.deployed[dec.resp == resp].iloc[0]; c3 = co[co.fit == tag].set_index("term"); f = fs[fs.fit == tag].iloc[0]; b = bsum[resp]
    out = dict(fit=tag, bal_definition={"l": "live_list_percentile", "c": "conventional_direct_sum", "d": "deposited_form_percentile"}[tag.split("_")[1].lower()], frame=tag.split("_")[2],
               coef={k: float(v) for k, v in c3.estimate.items()}, se_model={k: float(v) for k, v in c3.se.items()},
               CF=float(f.cf_source_inst), tau_source=float(f.tau_source), tau_inst=float(f.tau_inst), tau_tree=None if pd.isna(f.tau_tree) else float(f.tau_tree),
               c_natural=float(f.c_natural), c_planted=float(f.c_planted), CAL=[float(f.cal_natural), float(f.cal_planted)], planted_guard=45.0 if resp == "dDBH" else 20.0,
               crown_equation="HCB_P", selection_rule_outcome=dec.rule[dec.resp == resp].iloc[0])
    if b is not None:
        bb = b.set_index("term"); out["se_boot"] = {k: float(bb.boot_se[k]) for k in c3.index}; out["ci95_boot"] = {k: [float(bb.lo95[k]), float(bb.hi95[k])] for k in list(c3.index) + ["c_natural", "c_planted"]}
        out["CAL_SE_LOG"] = [float(bb.se_log["c_natural"]), float(bb.se_log["c_planted"])]; out["boot_n_ok"] = int(bb.n_ok.iloc[0])
    else: out["se_boot"] = None; out["CAL_SE_LOG"] = None
    return out
alt = {}
for r in ("dDBH",):
    for fr_ in ("NO", "CS"):
        m_ = re.search(rf"benchmark v102 vector recalibrated on {fr_} {r} c_nat ([\d.]+) c_pl ([\d.]+)", ilog)
        if m_: alt[f"{r}_{fr_}"] = dict(c_natural=float(m_.group(1)), c_planted=float(m_.group(2)))
e5 = sc[sc['eq'] == "Eq5"]; e5a = sc[sc['eq'] == "Eq5a"]; sm = lambda d: {t: float(v) for t, v in zip(d.term, d.estimate)}
C = dict(meta=dict(job="koa_v103_20260930", stage="A1", date="2026-09-30", note="engine multiplier per origin = CF x CAL = c; SE in se_model are nlme model SEs, se_boot the installation cluster bootstrap"),
         HT_P={k: float(h3.estimate[k]) for k in ("a0", "a1", "b", "c", "g1", "g2")}, HT_P_SE={k: float(h3.se[k]) for k in ("a0", "a1", "b", "c", "g1", "g2")},
         HCB_P=dict(b0=0.1684, b1=1.0146, b2=-0.376, b3=-0.0078, b4=-0.3734, b5=-0.221), HCB_P_decision="kept: every refit flips signs",
         DDBH=vec("dDBH"), DHT=vec("dHT"), DDBH_ALTERNATE_V102_VECTOR_RECAL=dict(coef=dict(b0=-1.15094113584424, b1=0.337116783134352, b2=-0.0143456480282451, b3=-0.00177215268764851, b4=-0.430651500423759, b5=1.28093519885364, b6=-0.0176012562326039, b7=-0.0176237502487828, b8=0.304524534930187, b9=0.410353392826353), bal_definition="deposited_form_percentile", c_by_frame=alt, deploy=False, note="eligible under every criterion but not a preregistered candidate; Aaron's call"),
         SURV_EQ5=dict(deploy="v102", v102=sm(e5[e5.frame == "v102"]), v103=sm(e5[e5.frame == "v103"]), reason="v103 refit fails: AIC 866 to 1110, LOIO annual AUC 0.813 to 0.633"),
         SURV_EQ5A=dict(deploy="v103", v103=sm(e5a[e5a.frame == "v103"]), v102=sm(e5a[e5a.frame == "v102"])),
         ING=dict(ING_B0=float(ig[(ig.frame == "v103") & ig.term.str.startswith("d0")].estimate.iloc[0]), ING_B_SDI=float(ig[(ig.frame == "v103") & ig.term.str.startswith("d1")].b_SDI_engine.iloc[0]), ING_B_PLANTED=float(ig[(ig.frame == "v103") & ig.term.str.startswith("d2")].estimate.iloc[0])),
         STAGE1=json.load(open("track2/stage1/stage1_fit_v103.json")),
         GARCIA=dict(GARCIA_ALLOM_A=float(al.A.iloc[2]), GARCIA_ALLOM_K_HD=float(al.K_HD.iloc[2]), GARCIA_ALLOM_SE=[float(al.se_A.iloc[2]), float(al.se_K.iloc[2])], GARCIA_BETA_ANCHORED=ba["v103_koa_live"]["beta"], GARCIA_BETA_ANCHORED_ALL_SPECIES=ba["v103_deployed"]["beta"], GARCIA_ALPHA=2.96, GARCIA_ALPHA_CHECK_V103=float(gc[(gc.frame == "v103") & (gc.set == "removals_excluded")].alpha.iloc[0])),
         BAL_COHORT=dict(definition="l", a0=float(coh[(coh.version == "v103") & (coh.bal == "l")].a0.iloc[0]), a1=float(coh[(coh.version == "v103") & (coh.bal == "l")].a1.iloc[0])),
         MORT_CAL=dict(value=None, note="re-solve on the patched engine (not an A1 output)"))
C["STAGE1"]["KOA_S1_INTERCEPT"] = C["STAGE1"]["stage1_beta"]["intercept"]; C["STAGE1"]["KOA_S1_LNSDI"] = C["STAGE1"]["stage1_beta"]["lnSDI"]; C["STAGE1"]["KOA_S1_PLANTED"] = C["STAGE1"]["stage1_beta"]["planted"]; C["STAGE1"]["KOA_S1_PBAR"] = C["STAGE1"]["stage1_mean_annual_p"]
json.dump(C, open("out/v103_constants.json", "w"), indent=1)
print("REPORT WRITTEN", len(L))
