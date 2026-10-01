"""koa_numbers_v103.py (a2/registry, 2026-09-30): the 93 keys of numbers_v102.json recomputed on v103, plus new v103 keys.
Adapted from track3/koa_numbers_v102.py of koa_v102_20260918. Every entry is {value, units, source, note}. 'Before' keys (suffix _record,
_v97, _v98 whose v102 meaning was the previous engine) now hold engine_v102, the before of v103. Stages rerun in this registry: s01, s02,
s05, s06, s07, lt, clip, joint_diag, ceiling, mort planted (and a natural gate), proto, make_traj. Keys whose v102 script has no v103
counterpart are computed directly from the v103 outputs and the note says so. No coordinate column is read anywhere."""
import json, os, re, numpy as np, pandas as pd
H = os.path.expanduser("~")
J = f"{H}/jobs/koa_v103_20260930"; R = f"{J}/a2/registry"; V2 = f"{H}/jobs/koa_v102_20260918"; T3 = f"{V2}/track3"
S01 = f"{R}/s01/v103"; S02 = f"{R}/s02/v103"; O5 = f"{R}/s05/v103"; O7 = f"{R}/s07/v103"; O7B = f"{T3}/s07/v102"
E = f"{J}/engine_v103/out_m1"; RB = f"{V2}/track2/engine_v102/out_m1"; KJ = f"{J}/a2/mc/out"
MN = f"{J}/a2/mort/v103"; MP = f"{R}/mort/v103_planted"; PRO = f"{R}/proto/v103"; LT = f"{R}/lt/out"; INC = f"{J}/out/inc"
V23 = f"{R}/derived/engine_v103_out_m1/validation_23.csv"; V23B = f"{T3}/derived/engine_v102_out_m1/validation_23.csv"
CONST = json.load(open(f"{J}/out/v103_constants.json"))
N = {}; NULLS = []
def rel(p): return p.replace(H + "/", "~/")
def put(k, v, src, units="", note=""): N[k] = dict(value=v, units=units, source=rel(src), note=note)
def miss(k, why, units=""): N[k] = dict(value=None, units=units, source="NOT REGENERATED", note=why); NULLS.append((k, why))
def rc(p, **kw):
    d = pd.read_csv(p, **kw)
    bad = [c for c in d.columns if str(c).lower() in ("lat", "lon", "latitude", "longitude")]
    assert not bad, ("coordinate column refused", p)
    return d
RERUN = "stage rerun in a2/registry on v103 inputs"
# ---------------- height (02_height_refit.R, registry s02; byte identical to track3_s02/v103 of Stage A1 except the base file timing)
c = rc(f"{S02}/02_height_coefficients.csv").set_index("parameter")
for p in c.index:
    put(f"ht_{p}", dict(est=c.loc[p, "estimate"], se=c.loc[p, "se"], lo=c.loc[p, "lo95"], hi=c.loc[p, "hi95"], p=c.loc[p, "p"]), f"{S02}/02_height_coefficients.csv", "m (a0); per BYI unit or dimensionless for the rest", RERUN + " (tree_join_v103, 02_height_refit.R unchanged)")
b = rc(f"{S02}/02_height_coefficients_base.csv").set_index("parameter")
put("ht_base", {p: dict(est=b.loc[p, "estimate"], se=b.loc[p, "se"]) for p in b.index} | {"r2_pa": b.r2_pa.iloc[0]}, f"{S02}/02_height_coefficients_base.csv", "as ht_*", RERUN)
put("ht_stats", rc(f"{S02}/02_height_fit_stats.csv").set_index("prediction").to_dict(orient="index"), f"{S02}/02_height_fit_stats.csv", "n, R2, RMSE m", RERUN)
put("ht_loio", rc(f"{S02}/02_height_loio.csv").iloc[0].to_dict(), f"{S02}/02_height_loio.csv", "RMSE m, R2", RERUN + " (KOA_LOIO TRUE)")
put("ht_equiv", rc(f"{S02}/02_height_equivalence.csv").set_index("vector").to_dict(orient="index"), f"{S02}/02_height_equivalence.csv", "equivalence regions, fraction", RERUN)
a0, a1 = c.loc["a0", "estimate"], c.loc["a1", "estimate"]
put("ht_site_pct_high_vs_low", 100 * ((a0 + 4.5 * a1) / (a0 + 1.0 * a1) - 1), f"{S02}/02_height_coefficients.csv", "percent", "derived: 100((a0+4.5a1)/(a0+a1)-1)")
put("ht_site_m_high_vs_low_asymptote", 3.5 * a1, f"{S02}/02_height_coefficients.csv", "m", "derived: 3.5 a1")
put("ht_site_pct_per100_at_medium", 100 * a1 / (a0 + 2.64 * a1), f"{S02}/02_height_coefficients.csv", "percent per 100 BYI", "derived: 100 a1/(a0+2.64 a1)")
# ---------------- projections
ev = rc(f"{E}/table8_evenaged_M1.csv"); ua = rc(f"{E}/uneven_aged_table8_M1.csv")
evr = rc(f"{RB}/table8_evenaged_M1.csv"); uar = rc(f"{RB}/uneven_aged_table8_M1.csv")
pts = rc(f"{O5}/05_refit_table6_points.csv"); ptr = rc(f"{O5}/05_engine_of_record_table6_points.csv")
sitecode = {"Low (100)": "Low", "Medium (264)": "Medium", "High (450)": "High"}
def grid(ev, ua, pts, IVR=None, RAW=False):
    rows = []
    for d in (ev, ua):
        for r in d.itertuples():
            sc, si, age = r.Scenario, sitecode[r.Site], int(r.Age)
            p = pts[(pts.scenario == sc) & (pts.site == si) & (pts.age == age)].iloc[0]
            ivr = IVR[(IVR.scenario == sc) & (IVR.site == si) & (IVR.age == age)] if IVR is not None else []
            q_lo, q_hi, v_lo, v_hi = (r.QMD_lo, r.QMD_hi, r.VOL_lo, r.VOL_hi) if len(ivr) != 1 else tuple(float(ivr.iloc[0][c_]) for c_ in ("qmd.2.5.", "qmd.97.5.", "vol.2.5.", "vol.97.5."))
            rows.append(dict(scenario=sc, site=r.Site, age=age, QMD=p.qmd if RAW else r.QMD, QMD_lo=q_lo, QMD_hi=q_hi, HT=getattr(r, "HT", p.ht), BAPH=r.BAPH, TPH=r.TPH,
                             VOL=p.vol if RAW else r.VOL, VOL_lo=v_lo, VOL_hi=v_hi, MAI_net=(p.vol if RAW else r.VOL) / age, MAI_gross=p.mai_gross,
                             SDI=p.sdi if "sdi" in p else np.nan, qmd_check=p.qmd, vol_check=p.vol, cap_bound=bool(p.cap_bound)))
    g = pd.DataFrame(rows)
    g["C"] = g.VOL * 0.510 * 0.47; g["C_lo"] = g.VOL_lo * 0.510 * 0.47; g["C_hi"] = g.VOL_hi * 0.510 * 0.47
    return g
IVR = rc(f"{O5}/05_refit_table6_intervals.csv")
G = grid(ev, ua, pts, IVR=IVR, RAW=True); GR = grid(evr, uar, ptr)
GRID_DQ = float((G.QMD - G.qmd_check).abs().max()); GRID_DV = float((G.VOL - G.vol_check).abs().max())
assert GRID_DQ < 0.06 and GRID_DV < 0.06, (GRID_DQ, GRID_DV)
os.makedirs(f"{R}/build", exist_ok=True); G.to_csv(f"{R}/build/grid_v103.csv", index=False); GR.to_csv(f"{R}/build/grid_v102.csv", index=False)
t = rc(f"{O5}/05_refit_trajectories_with_mai_pai.csv")
put("uneven_sdi_age100", [float(x) for x in ua[ua.Age == 100].SDI], f"{E}/uneven_aged_table8_M1.csv", "SDI (metric, trees ha-1 at 25.4 cm)", "Low, Medium, High")
put("cross_cul", rc(f"{O5}/05_refit_crossover_culmination.csv").to_dict(orient="records"), f"{O5}/05_refit_crossover_culmination.csv", "years", RERUN + " (engine_v103 trajectories)")
put("cross_cul_record", rc(f"{O5}/05_engine_of_record_crossover_culmination.csv").to_dict(orient="records"), f"{O5}/05_engine_of_record_crossover_culmination.csv", "years", "before = engine_v102 (KOA_TRAJ_REF); in v102 this key held v99")
put("reineke_100", rc(f"{O5}/05_refit_bakuzis_slopes.csv").to_dict(orient="records"), f"{O5}/05_refit_bakuzis_slopes.csv", "log-log slope", RERUN + " (self thinning phase, ages 11 to 100)")
put("reineke_100_record", rc(f"{O5}/05_engine_of_record_bakuzis_slopes.csv").to_dict(orient="records"), f"{O5}/05_engine_of_record_bakuzis_slopes.csv", "log-log slope", "before = engine_v102")
put("reineke_200", rc(f"{E}/bakuzis_slopes_M1.csv").to_dict(orient="records"), f"{E}/bakuzis_slopes_M1.csv", "log-log slope", "ages 25 to 200, final MC out_m1")
put("reineke_200_record", rc(f"{RB}/bakuzis_slopes_M1.csv").to_dict(orient="records"), f"{RB}/bakuzis_slopes_M1.csv", "log-log slope", "before = engine_v102")
put("eichhorn_cv", rc(f"{O5}/05_refit_eichhorn_cv.csv").to_dict(orient="records"), f"{O5}/05_refit_eichhorn_cv.csv", "CV fraction", RERUN)
so = rc(f"{O5}/05_refit_site_ordering.csv"); bad = so[~so.ordered]
put("site_order_fail", {k: [int(v.age.min()), int(v.age.max()), int(len(v))] for k, v in bad.groupby("scenario")}, f"{O5}/05_refit_site_ordering.csv", "[first age, last age, n ages]", RERUN + "; empty dict means site order holds at every age")
mono = {f"{sc}|{si}": bool((np.diff(g.sort_values('age').qmd) >= -1e-9).all()) for (sc, si), g in t.groupby(["scenario", "site"])}
put("qmd_monotone", mono, f"{O5}/05_refit_trajectories_with_mai_pai.csv", "boolean", RERUN)
env = {sc: dict(qmd=float(g.qmd.max()), baph=float(g.baph.max()), sdi=float(g.sdi.max()), ht=float(g.ht.max()), vol=float(g.vol.max())) for sc, g in t.groupby("scenario")}
put("envelope_traj_max", env, f"{O5}/05_refit_trajectories_with_mai_pai.csv", "cm, m2 ha-1, SDI, m, m3 ha-1", RERUN)
for lab, D, nm in (("refit", E, "engine_v103"), ("record", RB, "engine_v102 (before)")):
    tr = rc(f"{D}/traj_M1.csv"); tr = tr[tr.year <= 100]; out = {}
    for (o, byi), g in tr.groupby(["origin", "byi"]):
        w = g.TPH.to_numpy(); m = g.m_realised.to_numpy()
        out[f"{o}{byi}"] = dict(mean=float(m.mean()), tph_weighted=float((m * w).sum() / w.sum()), cum=float(1 - np.prod(1 - m)), annualised=float(1 - np.prod(1 - m) ** (1 / 100)))
    put(f"mort_level_{lab}", out, f"{D}/traj_M1.csv", "annual mortality fraction", f"{nm}, m_realised over years 1 to 100")
put("valid_refit", json.load(open(f"{E}/validation_M1.json")), f"{E}/validation_M1.json", "mixed", "engine_v103 out_m1, 23 validation units (FIA subplots); the plot level rebuild is key valid_plotlevel_C1")
put("valid_record", json.load(open(f"{RB}/validation_M1.json")), f"{RB}/validation_M1.json", "mixed", "before = engine_v102")
put("valid_equiv", rc(f"{O7}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), f"{O7}/07_validation_equivalence.csv", "equivalence regions", RERUN + " (5,000 plot bootstrap)")
vr = rc(f"{E}/validation_M1.csv"); vr["t"] = pd.qcut(vr.sdi0, 3, labels=["low", "mid", "high"])
obs = vr.groupby("t", observed=True).apply(lambda g: (1 - g.obs_surv).mean() / max(g.ny.mean(), 1)).to_dict()
pro = vr.groupby("t", observed=True).apply(lambda g: (1 - g.pr_surv).mean() / max(g.ny.mean(), 1)).to_dict()
put("valid_tertile_mort", dict(obs=obs, proj=pro), f"{E}/validation_M1.csv", "annual mortality fraction", "as FigS6 panel (b), SDI tertiles")
ss = rc(f"{R}/s06/v103/06_survival_respec_stats.csv")
S6N = "stage rerun (06_survival_respec.R unchanged) on the v103 frames; Eq. 5 deployed stays v102 (A1-D2), Eq. 5a is v103"
put("surv_stats", ss.drop(columns=["calibration_by_interval"]).to_dict(orient="records"), f"{R}/s06/v103/06_survival_respec_stats.csv", "AIC, AUC, Brier, fractions", S6N)
put("surv_calib", ss[["sample", "spec", "calibration_by_interval"]].dropna().to_dict(orient="records"), f"{R}/s06/v103/06_survival_respec_stats.csv", "observed / expected deaths", S6N)
put("surv_coef", rc(f"{R}/s06/v103/06_survival_respec_coefficients.csv").to_dict(orient="records"), f"{R}/s06/v103/06_survival_respec_coefficients.csv", "logit/cloglog coefficients", S6N + "; bootstrap columns not seed reproducible")
put("eq5_baseline", rc(f"{R}/s06/v103/06_eq5_coefficients_baseline.csv").to_dict(orient="records"), f"{R}/s06/v103/06_eq5_coefficients_baseline.csv", "coefficients", S6N)
put("eq5_recovered", rc(f"{R}/s06/v103/06_eq5_coefficients_recovered.csv").to_dict(orient="records"), f"{R}/s06/v103/06_eq5_coefficients_recovered.csv", "coefficients", S6N)
put("accounting", rc(f"{S01}/01_sample_accounting.csv").to_dict(orient="records"), f"{S01}/01_sample_accounting.csv", "counts", RERUN + " (01_accounting.R unchanged)")
put("by_source", rc(f"{S01}/01_by_source.csv").to_dict(orient="records"), f"{S01}/01_by_source.csv", "counts", RERUN)
put("byi_medians", rc(f"{S01}/01_byi_medians.csv").iloc[0].to_dict(), f"{S01}/01_byi_medians.csv", "BYI index units", RERUN)
# ---------------- increments: computed directly from the v103 Stage A1 outputs (the v102 inc chain fits the gr.hat2 V0 to V3 form, not the v103 engine form)
DIRECT_INC = "computed directly from the v103 Stage A1 increment outputs; the v102 inc chain (inc_variants/calib/loso_v102.R) fits the gr.hat2 V0 to V3 form with the deposited BAL, which is not the v103 engine form (HCB_P recursion, live list percentile BAL l, CF from tau), so rerunning it would not describe the deployed model"
fs = rc(f"{INC}/fit_stats_v103.csv"); sel = rc(f"{INC}/selection_v103.csv")
iv = fs.merge(sel[["fit", "sign_pass", "sign_fail", "eq_int_CS", "eq_slope_CS", "eq_int_NO", "eq_slope_NO", "max_eq_region", "size_max_dev_NO", "rmse_CS", "rmse_NO", "eligible"]], on="fit")
bb = rc(f"{INC}/a1close_v102vector_by_bal.csv"); bl = bb[(bb.resp == "dDBH") & (bb.bal == "l")].iloc[0]
rows = iv.to_dict(orient="records") + [dict(fit="dDBH_V102recal_l_NO (deployed)", resp="dDBH", bal="l", frame="NO", n=int(bl.n_NO), c_natural=bl.c_nat_NO, c_planted=bl.c_pl_NO,
            eq_int_CS=bl.eq_int_CS, eq_slope_CS=bl.eq_slope_CS, eq_int_NO=bl.eq_int_NO, eq_slope_NO=bl.eq_slope_NO, size_max_dev_NO=bl.size_max_dev_NO, rmse_CS=bl.rmse_CS, rmse_NO=bl.rmse_NO, eligible=bool(bl.eligible))]
put("inc_variants", rows, f"{INC}/fit_stats_v103.csv + selection_v103.csv + a1close_v102vector_by_bal.csv", "logLik, AIC, RMSE cm or m yr-1, regions", DIRECT_INC + ". Structure changed: v102 rows were V0 to V3 variants; v103 rows are the ten preregistered candidates plus the deployed dDBH v102 vector under l")
coef = []
for resp, blk in (("dDBH", "DDBH"), ("dHT", "DHT")):
    B = CONST[blk]
    for k_, v_ in B["coef"].items():
        coef.append(dict(resp=resp, fit=B["fit"], term=k_, estimate=v_, se=(B.get("se_model") or {}).get(k_), se_boot=(B.get("se_boot") or {}).get(k_)))
put("inc_coef", coef, f"{J}/out/v103_constants.json (DDBH, DHT)", "coefficients", DIRECT_INC + ". dDBH is the v102 vector (unchanged, A1-D6, se not re-estimated so se null); dHT is dHT_L_NO (A1-D1)")
cal = []
for resp, blk in (("dDBH", "DDBH"), ("dHT", "DHT")):
    B = CONST[blk]; se = B["CAL_SE_LOG"]
    ci = B.get("c_boot_95") or [B["ci95_boot"]["c_natural"], B["ci95_boot"]["c_planted"]]
    for i, o in enumerate(("natural", "planted")):
        cal.append(dict(resp=resp, origin=o, k=B[f"c_{o}"], CF=B["CF"], CAL=B["CAL"][i], lo95=ci[i][0], hi95=ci[i][1], se_log=se[i]))
put("calibration", cal, f"{J}/out/v103_constants.json", "multiplier (dimensionless)", DIRECT_INC + ". k = origin constant c; engine CAL = c / CF; se_log is SD of log c over 400 installation resamples within source with the vector fixed")
miss("calibration_loio", "no leave one installation out calibration was run for the v103 engine form fits (Stage A1 used a 400 resample installation bootstrap instead, key calibration); calib_v102.R fits the v102 form and cannot score the deployed v103 model", "R2, bias")
st1 = rc(f"{INC}/a1close_v102vector_strata.csv"); st2 = rc(f"{INC}/evaluation_strata_v103.csv")
cd_ = pd.concat([st1[(st1.fit == "dDBH_V102recal_l_NO") & (st1.eval_frame == "NO") & st1.strat.isin(["source", "origin"])].assign(resp="dDBH"),
                 st2[(st2.fit == "dHT_L_NO") & (st2.eval_frame == "NO") & st2.strat.isin(["source", "origin"])].assign(resp="dHT")])
put("calibration_diag", cd_[["resp", "fit", "strat", "level", "n", "ratio", "bias_ann", "rmse_ann"]].to_dict(orient="records"), f"{INC}/a1close_v102vector_strata.csv + evaluation_strata_v103.csv", "ratio obs/pred, cm or m yr-1", DIRECT_INC + ". by source and origin on the NO frame for the two deployed fits")
miss("loso", "no leave one source out refit exists for the v103 engine form fits; loso_v102.R refits the v102 gr.hat2 form. Source sensitivity of c is key k_by_source (a2/out/diag_c_by_source.csv)", "multiplier")
kb = []
for resp, f in (("dDBH", "boot_v103_dDBH_v102recal_summary.csv"), ("dHT", "boot_v103_dHT_summary.csv")):
    bs = rc(f"{INC}/{f}").set_index("term")
    for o in ("natural", "planted"):
        r_ = bs.loc[f"c_{o}"]; kb.append(dict(resp=resp, origin=o, k=r_.estimate, src_lo95=r_.lo95, src_hi95=r_.hi95, se_log=r_.se_log, n_ok=int(r_.n_ok)))
put("k_source_boot", kb, f"{INC}/boot_v103_dDBH_v102recal_summary.csv + boot_v103_dHT_summary.csv", "multiplier", DIRECT_INC + ". Definition changed: v102 resampled sources; v103 resamples installations within source (dDBH vector fixed, dHT full refit)")
put("k_by_source", rc(f"{J}/a2/out/diag_c_by_source.csv").to_dict(orient="records"), f"{J}/a2/out/diag_c_by_source.csv", "multiplier", "computed directly from the v103 output a2/diag_c_by_source.R (c re-solved within each source subset, deployed vectors)")
s1 = json.load(open(f"{J}/track2/stage1/stage1_fit_v103.json"))
auc = float(open(f"{J}/track2/stage1/stage1_auc_v103.txt").read().split()[0])
s1["stage1_auc"] = auc
put("stage12", s1, f"{J}/track2/stage1/stage1_fit_v103.json + stage1_auc_v103.txt", "logit coefficients, probabilities", "computed directly from the v103 Stage 1 and 2 refit (stage1_garcia_v103.R); in v102 carried forward from out_span")
B12 = rc(f"{R}/stage12/B_stage12_summary_v103.csv")
rec = B12[B12.fit == "origin_recoded_removals_excluded"].iloc[0]
STAGE12_CHECK = dict(n=(int(rec.n_intervals), s1["n_intervals"]), nmort=(int(rec.n_with_mortality), s1["n_with_mortality"]), pbar=(float(rec.pbar), s1["stage1_mean_annual_p"]), duan=(float(rec.duan), s1["stage2_duan"]), uncond=(float(rec.uncond_weighted), s1["obs_uncond_weighted"]), cond=(float(rec.cond_weighted), s1["stage2_obs_cond_mean_weighted"]))
put("stage12_summary", B12.to_dict(orient="records"), f"{R}/stage12/B_stage12_summary_v103.csv", "counts, annual fractions",
    "stage rerun: stage12/stage12_summary_v103.R (origin_refit_span.R summary rules, fitB and screens of stage1_garcia_v103.R) on plot_intervals_v103; recoded row reproduces stage1_fit_v103.json n, pbar, duan and uncond exactly; cond_weighted 0.10861 vs json 0.10961 (json field equals the v102 value, likely carried over)")
put("background_by_origin", rc(f"{R}/stage12/B_background_by_origin_v103.csv").to_dict(orient="records"), f"{R}/stage12/B_background_by_origin_v103.csv", "annual mortality fraction", "stage rerun, origin_refit_span.R rule (intervals below SDI 200, expf weighted)")
ig = rc(f"{J}/track2/out/ingrowth_coefficients_v103.csv"); igr = ig[ig.frame == "v102"].set_index("term"); igv = ig[ig.frame == "v103"].set_index("term")
tm = {"d0 (intercept)": "(Intercept)", "d1 (RD)": "RD", "d2 (planted)": "planted"}
put("ingrowth", [dict(term=tm[k], old=float(igr.loc[k, "estimate"]), new=float(igv.loc[k, "estimate"]), se_new=float(igv.loc[k, "se"]), lo95=float(igv.loc[k, "lo95"]), hi95=float(igv.loc[k, "hi95"]),
                      n=int(igv.loc[k, "n"]), n_planted_new=int(igv.loc[k, "n_planted_new"])) for k in tm], f"{J}/track2/out/ingrowth_coefficients_v103.csv",
    "log scale coefficients", "computed directly from the v103 Eq. 6 refit (ingrowth_refit_v103.R); old = v102 frame, new = v103 frame; v102 gate field dropped")
gc = rc(f"{J}/track2/stage1/garcia_check_v103.csv")
put("garcia", gc[gc.frame == "v103"].drop(columns="frame").to_dict(orient="records"), f"{J}/track2/stage1/garcia_check_v103.csv", "alpha, beta", "computed directly from the v103 garcia check (stage1_garcia_v103.R) on plot_interval_pairs_DATA_v103")
vv = rc(V23)
put("valid_plots", dict(n=len(vv), planted=int((vv.origin == "planted").sum()), mean_int=float(vv.interval.mean()), max_int=int(vv.interval.max())), V23, "counts, years", "engine_v103 validation_23 (make_traj rerun)")
bias = lambda d: d.assign(ds=d.obs_surv - d.pred_surv, dba=d.obs_ba - d.pred_ba, dq=d.obs_qmd - d.pred_qmd).groupby("origin")[["ds", "dba", "dq"]].mean().to_dict(orient="index")
put("valid_bias_by_origin", bias(vv), V23, "survival fraction, m2 ha-1, cm (observed minus projected)", "23 units as deployed (FIA subplots)")
for o in ("natural", "planted"):
    put(f"valid_equiv_{o}", rc(f"{R}/s07/v103_origin/{o}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), f"{R}/s07/v103_origin/{o}/07_validation_equivalence.csv", "equivalence regions", RERUN)
    put(f"valid_equiv_{o}_v97", rc(f"{T3}/s07/v102_origin/{o}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), f"{T3}/s07/v102_origin/{o}/07_validation_equivalence.csv", "equivalence regions", "before = engine_v102")
put("valid_equiv_v97", rc(f"{O7B}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), f"{O7B}/07_validation_equivalence.csv", "equivalence regions", "before = engine_v102")
for w, D, nt in (("natural", MN, "a2/run_mort_v103.sh output; registry gate mort/v103_natural reproduces it exactly"), ("planted", MP, RERUN + " (calib_mort, solve_mort on the registry engine copy)")):
    put(f"mortcal_{w}", rc(f"{D}/H_mort_level_{w}.csv").set_index("form").to_dict(orient="index"), f"{D}/H_mort_level_{w}.csv", "level multiplier, deaths, fractions", nt)
    put(f"mortcal_loio_{w}", rc(f"{D}/H_mort_loio_{w}.csv").to_dict(orient="records"), f"{D}/H_mort_loio_{w}.csv", "level multiplier", nt)
put("proto_metrics", rc(f"{PRO}/H_proto_metrics.csv").to_dict(orient="records"), f"{PRO}/H_proto_metrics.csv", "mixed", RERUN + " (proto_mort on engine_nocal, MORT_CAL (1,1), v103 levels, point trajectories)")
put("proto_order", rc(f"{PRO}/H_proto_ordering.csv").to_dict(orient="records"), f"{PRO}/H_proto_ordering.csv", "boolean / ordering", RERUN)
put("proto_valid", json.load(open(f"{PRO}/H_proto_validation_summary.json")), f"{PRO}/H_proto_validation_summary.json", "observed minus projected", RERUN)
for w, D in (("natural", MN), ("planted", MP)):
    iv_ = rc(f"{D}/H_mort_intervals_{w}_mult.csv")
    put(f"mortcal_intervals_{w}", dict(n=len(iv_), plots=int(iv_["plot"].nunique()), inst=int(iv_["inst"].nunique()), yip_median=float(iv_.yip.median()), yip_mean=float(iv_.yip.mean()), share_le2=float((iv_.yip <= 2).mean())), f"{D}/H_mort_intervals_{w}_mult.csv", "counts, years", "")
k12 = vv[vv.PLOT == "DOFAW|Kulani|12"].iloc[0]
put("valid_k12", dict(obs_surv=k12.obs_surv, pred_surv=k12.pred_surv, obs_ba=k12.obs_ba, pred_ba=k12.pred_ba, obs_qmd=k12.obs_qmd, pred_qmd=k12.pred_qmd), V23, "fraction, m2 ha-1, cm", "Kulani 12 is outside the planted domain (key planted_domain)")
v10 = vv[(vv.origin == "planted") & (vv.PLOT != "DOFAW|Kulani|12")]
put("valid_planted_psp", dict(n=len(v10), ds=float((v10.obs_surv - v10.pred_surv).mean()), dba=float((v10.obs_ba - v10.pred_ba).mean()), dq=float((v10.obs_qmd - v10.pred_qmd).mean())), V23, "observed minus projected", "planted without Kulani 12")
vn = vv[vv.origin == "natural"]
for lab, sub in (("fia", vn[vn.PLOT.str.startswith("FIA")]), ("dofaw", vn[vn.PLOT.str.startswith("DOFAW")])):
    put(f"valid_nat_{lab}", dict(n=len(sub), ds=float((sub.obs_surv - sub.pred_surv).mean()), dba=float((sub.obs_ba - sub.pred_ba).mean()), dq=float((sub.obs_qmd - sub.pred_qmd).mean())), V23, "observed minus projected",
        "FIA units are subplots at x4 expansion; see valid_plotlevel_C1" if lab == "fia" else "")
put("valid_bias_by_origin_v97", bias(rc(V23B)), V23B, "observed minus projected", "before = engine_v102")
for key, lab, src, nm in (("v98", "v103", LT, "engine_v103 registry copy"), ("v97", "v102", f"{T3}/lt/out", "before = engine_v102, not rerun"), ("u98", "u103", LT, "engine_v103 without the natural level factor (engine_nocal)")):
    put(f"lt_summary_{key}", rc(f"{src}/LT_{lab}_summary.csv").to_dict(orient="records"), f"{src}/LT_{lab}_summary.csv", "cm, m2 ha-1, fractions", f"{nm}; key name kept from v99" + ("; " + RERUN if src == LT else ""))
lp = rc(f"{LT}/LT_v103_points.csv"); psp = lp[lp.pid.str.startswith("PSP")]
put("lt_plots", dict(n_plots=int(lp.pid.nunique()), n_points=len(lp), natural=int(lp[lp.planted == 0].pid.nunique()), planted=int(lp[lp.planted == 1].pid.nunique()),
                     nat_span=[int(lp[lp.planted == 0].groupby("pid").h.max().min()), int(lp[lp.planted == 0].groupby("pid").h.max().max())],
                     psp=int(psp.pid.nunique()), psp_span=[int(psp.groupby("pid").h.max().min()), int(psp.groupby("pid").h.max().max())]), f"{LT}/LT_v103_points.csv", "counts, years", RERUN)
put("sc_summary", rc(f"{LT}/SC_summary.csv").to_dict(orient="records"), f"{LT}/SC_summary.csv", "mixed", RERUN + " (scenarios.py on engine_v103 copy)")
sct = rc(f"{LT}/SC_trajectories.csv")
put("sc_dbhmax", {f"{r.origin}|{r.label}|{int(r.year)}": float(r.DBHMAX) for r in sct[sct.year.isin([40, 100])].itertuples()}, f"{LT}/SC_trajectories.csv", "cm", RERUN)
put("sc_tph", {f"{r.origin}|{r.label}|{int(r.year)}": float(r.TPH) for r in sct[sct.year.isin([10, 20, 40, 100])].itertuples()}, f"{LT}/SC_trajectories.csv", "trees ha-1", RERUN)
put("sc_diag_cr", rc(f"{LT}/SC_diag_crown_ratio.csv").to_dict(orient="records"), f"{LT}/SC_diag_crown_ratio.csv", "crown ratio", RERUN)
put("sc_dbhmax20", {f"{r.origin}|{r.label}": float(r.DBHMAX) for r in sct[sct.year == 20].itertuples()}, f"{LT}/SC_trajectories.csv", "cm", RERUN)
put("sc_init", {f"{r.origin}|{r.label}": dict(qmd=float(r.QMD), vol=float(r.VOL)) for r in sct[sct.year == 1].itertuples()}, f"{LT}/SC_trajectories.csv", "cm, m3 ha-1", RERUN)
a0t = rc(f"{R}/engine_nocal/out_proto_A0/traj_M1.csv"); m2 = rc(f"{E}/traj_M1.csv"); chg = {}
for (o, b_), g_ in m2.groupby(["origin", "byi"]):
    h_ = a0t[(a0t.origin == o) & (a0t.byi == b_)].set_index("year"); g_ = g_.set_index("year")
    chg[f"{o}{b_}"] = dict(vol40=100 * (g_.loc[40, "VOL"] / h_.loc[40, "VOL"] - 1), vol100=100 * (g_.loc[100, "VOL"] / h_.loc[100, "VOL"] - 1), qmd100=g_.loc[100, "QMD"] - h_.loc[100, "QMD"], ht40=g_.loc[40, "HT"], ht100=g_.loc[100, "HT"])
put("a0_change", chg, f"{E}/traj_M1.csv vs {R}/engine_nocal/out_proto_A0/traj_M1.csv", "percent, cm, m", RERUN + " (same engine without the natural level factor)")
put("clip_shares", rc(f"{R}/clip/J_clip_ceiling_shares.csv").to_dict(orient="records"), f"{R}/clip/J_clip_ceiling_shares.csv", "share of replicates", RERUN + " (final engine_v103 out_m1 replicates)")
put("joint_summary", rc(f"{KJ}/K_joint_summary.csv").set_index("term").to_dict(orient="index"), f"{KJ}/K_joint_summary.csv", "coefficient units", "500 joint rows, installation design within source")
put("joint_cor", rc(f"{KJ}/K_joint_cor.csv", index_col=0).to_dict(orient="index"), f"{KJ}/K_joint_cor.csv", "correlation", "")
kd = rc(f"{KJ}/K_joint_draws.csv"); nsrc = kd.sources.apply(lambda x: len(set(x.split("|"))))
ks = rc(f"{KJ}/K_joint_source_sets.csv")
put("joint_source_sets", dict(n_sets=len(ks), all_four=int(ks[ks.sources.apply(lambda x: len(set(x.split("|")))) == 4].n.sum()), rows=ks.to_dict(orient="records")), f"{KJ}/K_joint_source_sets.csv", "counts", "installation design: every row draws installations within all four sources")
put("joint_n", len(kd), f"{KJ}/K_joint_draws.csv", "rows", "")
put("joint_distinct_sources", float(nsrc.mean()), f"{KJ}/K_joint_draws.csv", "sources per row", "")
miss("width_ratio", "the v103 Monte Carlo has joint draws only (installation design); no independent draw run of engine_v103 exists to divide by", "ratio")
put("clip_shares_v98", rc(f"{T3}/clip/J_clip_ceiling_shares.csv").to_dict(orient="records"), f"{T3}/clip/J_clip_ceiling_shares.csv", "share of replicates", "before = engine_v102")
put("ref_spread", rc(f"{R}/joint/K_reference_spread.csv").set_index("quantity").to_dict(orient="index"), f"{R}/joint/K_reference_spread.csv", "cm or m yr-1, sd of log", RERUN + " (joint_diag.py on engine_v103 copy with its out_joint rows)")
miss("width_ratio_all_ages", "no independent draw run of engine_v103 exists", "ratio")
V102 = json.load(open(f"{R}/ref_numbers_v102.json"))
assert set(N) == set(V102), (set(N) ^ set(V102))
N = {k: N[k] for k in V102}   # v102 key order
# ---------------- new keys (v103)
import importlib.util
sp = importlib.util.spec_from_file_location("kp", f"{J}/engine_v103/koa_params.py"); KP = importlib.util.module_from_spec(sp); sp.loader.exec_module(KP)
put("MORT_CAL", KP.MORT_CAL[0], f"{J}/engine_v103/koa_params.py", "multiplier on the natural mortality rate", "natural level, 24 natural intervals; solve_mort level 2.542751 in a2/mort/v103/H_mort_level_natural.csv, reproduced exactly by registry mort/v103_natural (planted factor 1.0)")
put("MORT_CAL_SE_LOG", KP.MORT_CAL_SE_LOG[0], f"{J}/engine_v103/koa_params.py", "SD of log k", "plot cluster bootstrap; plot_se_log 0.243353 in H_mort_level_natural.csv")
put("BAL_PERCENTILE_WEIGHTED", bool(KP.BAL_PERCENTILE_WEIGHTED), f"{J}/engine_v103/koa_params.py", "switch", "expf weighted exact path BAL percentile (a2/patch_bal_weighted_v103.py, red team A1A2 finding 1); equal expf reproduces the unweighted rule of record; False reproduces engine_v102 and the pre-fix v103 engine")
rs = json.load(open(f"{J}/out/repair/summary.json")); pyb = rc(f"{J}/out/repair/plotyear_stand_before_after.csv")
put("D1_repair", dict(plotyears=rs["plotyears"], changed=rs["n_changed"], fallback_kept_deposited=rs["fallback"], no_live_expf=100, set_to_zero=94, g2_flags_over100=5, tree_rows_v103=16914, tree_rows_v102=17074, plotyear_rows_file=len(pyb)),
    f"{J}/out/repair/summary.json; STAGE1_REPORT.md section 2", "plot-years, records", "plotyears, changed and fallback from summary.json; no_live_expf, set_to_zero, g2 flags and tree rows quoted from STAGE1_REPORT section 2")
d2 = rc(f"{J}/out/repair/d2_flagged_visits.csv"); d2s = rc(f"{J}/out/repair/d2_scan_all_visits.csv")
put("D2_copied_visits", dict(visits_scanned=len(d2s), copied=rs["copied"], partial=rs["partial"], flagged_rows=len(d2), records_removed=160, plot_intervals_rows=[326, 318], m1_pairs=[415, 407], static_height_lost=145),
    f"{J}/out/repair/d2_flagged_visits.csv, d2_scan_all_visits.csv; STAGE1_REPORT.md section 3", "visits, records", "the 8 copied visits are PSP 101 to 108, 2015 copies of 2014; records removed and frame effects quoted from STAGE1_REPORT section 3")
g3 = rc(f"{J}/out/repair/g3_before_after_by_source.csv").set_index("Data").loc["FIA"]
put("FIA_x4_EXPF", dict(expansion_factor=4, tpa_to_expf=2.47105 * 4, fia_baph_median_before=float(g3.BAPH_med_before), fia_baph_median_after=float(g3.BAPH_med_after), fia_plotyears=int(g3.plotyears), subplot_years_over_100=5),
    f"{J}/out/repair/g3_before_after_by_source.csv; STAGE1_REPORT.md section 2", "multiplier, m2 ha-1", "deposited FIA stand values used whole plot TPA on one subplot (one quarter of the subplot value); rebuilt per subplot (x4). Validation at subplot scale is outside the model domain, so FIA validation is rebuilt at plot level with x1 (valid_plotlevel_*)")
ba = json.load(open(f"{J}/track2/stage1/beta_anchor_v103.json"))
put("garcia_beta_deployed", KP.GARCIA_BETA_ANCHORED, f"{J}/engine_v103/koa_params.py; {J}/track2/stage1/beta_anchor_v103.json", "yr-1 scale beta", f"live koa stems >= 5, 100/sqrt(z99), n {ba['v103_koa_live']['n']}; all species form {ba['v103_deployed']['beta']:.4f} not deployed; v102 record {ba['record']['beta']:.4f}")
put("deviation_A1_D1", "no preregistered increment candidate eligible; fallback (smallest maximum equivalence region) deployed; after A1-D6 applies to dHT only (dHT_L_NO, max region 0.245)", f"{J}/STAGE1_REPORT.md section 7 and 8", "text", "")
put("deviation_A1_D6", "deployed dDBH is the v102 vector of record with origin constants re-solved on the v103 NO frame under live list percentile BAL (c 0.82034, 2.19349), not a preregistered candidate (Aaron, 30 September 2026)", f"{J}/STAGE1_REPORT.md section 8", "text", "")
c1 = rc(f"{J}/a2/closeout/validation/tableC1_v103_plotlevel.csv"); c2 = rc(f"{J}/a2/closeout/validation/tableC2_v103_plotlevel.csv")
put("valid_plotlevel_C1", c1.to_dict(orient="records"), f"{J}/a2/closeout/validation/tableC1_v103_plotlevel.csv (tableC_v103_plotlevel.md)", "bias PREDICTED minus OBSERVED: fraction, cm, m2 ha-1", "FIA whole plots x1, min 20 koa records, 15-1-1-2628 disturbance case excluded; sign convention opposite to valid_bias_by_origin")
put("valid_plotlevel_C2", c2.to_dict(orient="records"), f"{J}/a2/closeout/validation/tableC2_v103_plotlevel.csv (tableC_v103_plotlevel.md)", "TOST regions and slopes", "25 percent equivalence, 5,000 plot bootstrap")
kj = rc(f"{KJ}/K_joint_summary.csv").set_index("term"); mult = {}
for cc, vec in (("cal_dd_nat", "d_"), ("cal_dd_plt", "d_"), ("cal_dh_nat", "h_"), ("cal_dh_plt", "h_"), ("kmort", None)):
    y = np.log(kd[cc].to_numpy()); ent = dict(sd_log_summary=float(kj.loc[cc, "sd_log"]), sd_log_draws=float(y.std()))
    if vec:
        X = kd[[x for x in kd.columns if x.startswith(vec + "b")]].to_numpy(); X1 = np.c_[np.ones(len(X)), X]; bcoef = np.linalg.lstsq(X1, y, rcond=None)[0]; r_ = y - X1 @ bcoef
        ent |= dict(r2_on_vector=float(1 - r_.var() / y.var()), resid_sd_log=float(r_.std()))
    mult[cc] = ent
put("joint_mult_sdlog", mult, f"{KJ}/K_joint_summary.csv; {KJ}/K_joint_draws.csv", "SD of log multiplier", "installation design within source; residual = SD of log multiplier after OLS on the same equation's b0 to b9 draws (kmort has no vector)")
fr = rc(f"{J}/frames/final/dDBH_NO_v103_model.csv"); pl = fr[(fr.Planted == 1) & (fr.Data == "PSP")]; kmr = fr[(fr.Planted == 1) & (fr.Data == "KMR PSP")]
agecol = [c_ for c_ in fr.columns if c_.lower() in ("age", "age.0", "age0")]
put("planted_domain", dict(byi_min=float(pl.BYI.min()), byi_max=float(pl.BYI.max()), byi_stated=[158, 561], age_max_stated="under 18", kulani12_byi=float(fr[fr.Install == "Kulani"].query("Plot == '12' or Plot == 12").BYI.iloc[0]) if len(fr[fr.Install == "Kulani"].query("Plot == '12' or Plot == 12")) else None,
    kulani12_in_domain=False, kmr_psp_byi=[float(kmr.BYI.min()), float(kmr.BYI.max())]), f"{J}/frames/final/dDBH_NO_v103_model.csv; a2/redteam2 review R7", "BYI index units, years",
    "planted PSP increment data span BYI 158 to 561 (KMR PSP 109 to 191 also planted) and stand age under 18; Kulani 12 (BYI 25) is out of domain (pred BA 43.8 vs obs 13.6 m2 ha-1). Age not in the frame, stated value kept")
json.dump(N, open(f"{R}/numbers_v103.json", "w"), indent=1, default=lambda o: o.item() if hasattr(o, "item") else (None if o is pd.NaT else str(o)))
print("keys", len(N), "v102 keys", len(V102), "new", len(N) - len(V102), "nulls", [k for k, _ in NULLS])
print("grid check", GRID_DQ, GRID_DV, "stage12 check", STAGE12_CHECK)
print(json.dumps({k: N[k]["value"] for k in ("joint_mult_sdlog", "planted_domain", "D2_copied_visits")}, default=str)[:2000])
