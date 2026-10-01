"""gate_v103.py: re-derive headline numbers of numbers_v103.json two independent ways (different files, scripts or arithmetic) -> build/gate_v103.csv."""
import json, os, re, numpy as np, pandas as pd, importlib.util
H = os.path.expanduser("~"); J = f"{H}/jobs/koa_v103_20260930"; R = f"{J}/a2/registry"; E = f"{J}/engine_v103/out_m1"
N = json.load(open(f"{R}/numbers_v103.json")); C = json.load(open(f"{J}/out/v103_constants.json"))
sp = importlib.util.spec_from_file_location("kp", f"{J}/engine_v103/koa_params.py"); KP = importlib.util.module_from_spec(sp); sp.loader.exec_module(KP)
G = []
def g(q, a, sa, b, sb, tol=1e-4):
    rd = abs(a - b) / max(abs(a), 1e-12); G.append(dict(quantity=q, way_a=a, source_a=sa, way_b=b, source_b=sb, rel_diff=rd, tol=tol, agree=bool(rd <= tol)))
lv = pd.read_csv(f"{R}/mort/v103_natural/H_mort_level_natural.csv").set_index("form").loc["mult"]
g("MORT_CAL natural", N["MORT_CAL"]["value"], "engine_v103 koa_params.py", float(lv.level), "registry rerun calib_mort+solve_mort on engine_nocal", 1e-5)
g("MORT_CAL_SE_LOG", N["MORT_CAL_SE_LOG"]["value"], "engine_v103 koa_params.py", float(lv.plot_se_log), "registry rerun, plot bootstrap SD log k", 1e-4)
ba = json.load(open(f"{J}/track2/stage1/beta_anchor_v103.json"))["v103_koa_live"]
g("Garcia beta anchored", N["garcia_beta_deployed"]["value"], "engine koa_params GARCIA_BETA_ANCHORED", 100 / np.sqrt(ba["z99"]), "100/sqrt(z99) from beta_anchor_v103.json", 1e-9)
g("HT_P a0", N["ht_a0"]["value"]["est"], "registry s02 rerun (track3 02_height_refit.R)", C["HT_P"]["a0"], "v103_constants.json (track2/height_refit_v103.R)", 1e-4)
g("HT_P a1", N["ht_a1"]["value"]["est"], "registry s02 rerun", C["HT_P"]["a1"], "v103_constants.json", 1e-4)
dc = pd.read_csv(f"{J}/a2/out/diag_c_by_source.csv").query("resp == 'dDBH' and set == 'all'").iloc[0]
g("dDBH c natural", C["DDBH"]["c_natural"], "v103_constants.json (a1close_v103.R)", float(dc.c_natural), "a2/diag_c_by_source.R, all sources", 1e-6)
g("dDBH CAL natural = c/CF", KP.CAL_DDBH[0], "engine koa_params CAL_DDBH", C["DDBH"]["c_natural"] / C["DDBH"]["CF"], "c_natural / CF from constants json", 1e-4)
g("dHT CAL natural = c/CF", KP.CAL_DHT[0], "engine koa_params CAL_DHT", C["DHT"]["c_natural"] / C["DHT"]["CF"], "c_natural / CF from constants json", 1e-4)
s1 = json.load(open(f"{J}/track2/stage1/stage1_fit_v103.json")); b12 = pd.read_csv(f"{R}/stage12/B_stage12_summary_v103.csv").set_index("fit").loc["origin_recoded_removals_excluded"]
g("Stage 1 pbar", s1["stage1_mean_annual_p"], "track2/stage1/stage1_fit_v103.json", float(b12.pbar), "registry stage12_summary_v103.R refit", 1e-8)
g("Stage 1 intervals", s1["n_intervals"], "stage1_fit_v103.json", float(b12.n_intervals), "registry refit", 0)
sc = pd.read_csv(f"{J}/out/repair/d2_scan_all_visits.csv")
g("D2 copied visits", N["D2_copied_visits"]["value"]["copied"], "out/repair/summary.json", float((sc.share >= 0.9).sum()), "count share >= 0.90 in d2_scan_all_visits.csv", 0)
py = pd.read_csv(f"{J}/out/repair/plotyear_stand_before_after.csv")
chg = ((py.BAPH - py.BAPH_dep).abs() > 1e-6) | ((py.TPH - py.TPH_dep).abs() > 1e-6)
g("D1 plot-years changed", N["D1_repair"]["value"]["changed"], "out/repair/summary.json", float(chg.sum()), "recount BAPH or TPH change > 1e-6 in plotyear_stand_before_after.csv", 0)
g("FIA BAPH median after x4", N["FIA_x4_EXPF"]["value"]["fia_baph_median_after"], "g3_before_after_by_source.csv", float(py[py.Data == "FIA"].BAPH.median()), "median over FIA rows of plotyear_stand_before_after.csv", 1e-4)
vp = pd.read_csv(f"{J}/a2/closeout/validation/val_v103_plotlevel.csv"); nat = vp[(vp.origin == "natural") & (vp.role != "disturbance")]
c1 = pd.DataFrame(N["valid_plotlevel_C1"]["value"]).query("frame == 'v103 plot level' and group == 'natural (excl. 2628)'").iloc[0]
g("plot level natural QMD bias (pred - obs)", float(c1.QMD_bias), "tableC1_v103_plotlevel.csv", float((nat.prQMD - nat.obsQMD).mean()), "recomputed from val_v103_plotlevel.csv", 1e-3)
pl = vp[vp.origin == "planted"]
g("plot level planted BA bias (pred - obs)", float(pd.DataFrame(N["valid_plotlevel_C1"]["value"]).query("frame == 'v103 plot level' and group == 'planted'").iloc[0].BA_bias), "tableC1", float((pl.prBAPH - pl.obsBAPH).mean()), "recomputed from val_v103_plotlevel.csv", 1e-3)
kd = pd.read_csv(f"{J}/a2/mc/out/K_joint_draws.csv")
g("joint cal_dd_nat sd_log", N["joint_mult_sdlog"]["value"]["cal_dd_nat"]["sd_log_summary"], "K_joint_summary.csv", float(np.log(kd.cal_dd_nat).std(ddof=1)), "SD of log over K_joint_draws.csv (ddof 1)", 1e-3)
rt = open(f"{J}/a2/redteam2/mc.out").read(); m = float(re.search(r"cal_dd_nat sd_log [0-9.]+ R2 on vector [0-9.]+ resid sd_log ([0-9.]+)", rt).group(1))
g("joint cal_dd_nat residual sd_log", round(N["joint_mult_sdlog"]["value"]["cal_dd_nat"]["resid_sd_log"], 3), "registry OLS on d_b0..b9", m, "a2/redteam2/mc.py output (independent script, 3 dp)", 1e-9)
t8 = pd.read_csv(f"{E}/table8_evenaged_M1.csv").query("Scenario == 'Even-aged natural' and Site == 'Medium (264)' and Age == 100").iloc[0]
tr = pd.read_csv(f"{E}/traj_M1.csv").query("origin == 'nat' and byi == 264 and year == 100").iloc[0] if "nat" in set(pd.read_csv(f"{E}/traj_M1.csv", usecols=["origin"]).origin) else None
rp = pd.read_csv(f"{E}/reps_evenaged_M1.csv").query("scen == 'nat' and byi == 264 and year == 100")
g("Table 8 natural Medium 100 VOL_hi", float(t8.VOL_hi), "table8_evenaged_M1.csv", float(rp.VOL.quantile(0.975)), "97.5 percentile of reps_evenaged_M1.csv", 1e-3)
if tr is not None: g("Table 8 natural Medium 100 VOL", float(t8.VOL), "table8_evenaged_M1.csv", float(tr.VOL), "traj_M1.csv point projection", 1e-3)
grid = pd.read_csv(f"{R}/build/grid_v103.csv").query("scenario == 'Even-aged natural' and site == 'Medium (264)' and age == 100").iloc[0]
g("natural Medium 100 QMD (05 points vs table 8)", float(grid.QMD), "registry s05 rerun 05_refit_table6_points", float(t8.QMD), "table8_evenaged_M1.csv", 2e-3)
v = pd.read_csv(f"{R}/derived/engine_v103_out_m1/validation_23.csv"); vm = pd.read_csv(f"{E}/validation_M1.csv")
g("validation natural dq mean (obs - pred)", N["valid_bias_by_origin"]["value"]["natural"]["dq"], "registry make_traj validation_23", float((vm[vm.planted == 0].obsQMD - vm[vm.planted == 0].prQMD).mean()), "engine validation_M1.csv directly", 1e-9)
D = pd.DataFrame(G); D.to_csv(f"{R}/build/gate_v103.csv", index=False)
print(D[["quantity", "way_a", "way_b", "rel_diff", "agree"]].to_string()); print("agree", int(D.agree.sum()), "of", len(D))
