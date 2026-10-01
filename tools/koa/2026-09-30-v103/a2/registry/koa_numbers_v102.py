"""koa_numbers_v102.py (track 3, 2026-09-18): the 93 keys of numbers_v99.json recomputed from the v102 engine (track2/engine_v102, its
Monte Carlo out_m1 and joint draws mc/out), the v102 frames and the track 3 reruns of every script of record. Same keys, same value
structure as koa_numbers_v99.py; the source string names the v102 file each value was read from.
Reference (before) = engine_joint (v99), so every key that in v99 held the v97 or v98 comparison (suffix _record, _v97, _v98) holds the v99
value here and its source says so. Keys whose script or independent draw file does not exist for v102 are written with value null and a
source beginning NOT REGENERATED. No coordinate column is read anywhere in this script."""
import json, os, sys, numpy as np, pandas as pd
H = os.path.expanduser("~")
J = f"{H}/jobs/koa_v102_20260918"; T = f"{J}/track3"; T2 = f"{J}/track2"; ORG = f"{H}/jobs/koa_origin_20260916"
S01 = f"{T}/s01/v102"; S02 = f"{T}/s02/v102"; O5 = f"{T}/s05/v102"; O7 = f"{T}/s07/v102"; O7B = f"{T}/s07/record"
E = f"{T2}/engine_v102/out_m1"; R = f"{ORG}/output/engine_joint/out_m1"; KJ = f"{T2}/mc/out"
INC = f"{T}/inc/out_V102"; MN = f"{T2}/mort/v102"; MP = f"{T}/mort/v102_planted"; PRO = f"{T}/proto/v102"; LT = f"{T}/lt/out"
V23 = f"{T}/derived/engine_v102_out_m1/validation_23.csv"; V23B = f"{R}/validation_23.csv"
N = {}; MISSING = []
def put(k, v, src): N[k] = dict(value=v, source=src)
def miss(k, why): N[k] = dict(value=None, source="NOT REGENERATED, " + why); MISSING.append((k, why))
def rc(p, **kw):
    d = pd.read_csv(p, **kw)
    bad = [c for c in d.columns if str(c).lower() in ("lat", "lon", "latitude", "longitude")]
    assert not bad, ("coordinate column refused", p)
    return d
# ---------------- height refit (02_height_refit.R on tree_join_v102, track3/s02/v102)
c = rc(f"{S02}/02_height_coefficients.csv").set_index("parameter")
for p in c.index:
    put(f"ht_{p}", dict(est=c.loc[p, "estimate"], se=c.loc[p, "se"], lo=c.loc[p, "lo95"], hi=c.loc[p, "hi95"], p=c.loc[p, "p"]), "track3/s02/v102/02_height_coefficients.csv (v102 tree join, 9,066 records)")
b = rc(f"{S02}/02_height_coefficients_base.csv").set_index("parameter")
put("ht_base", {p: dict(est=b.loc[p, "estimate"], se=b.loc[p, "se"]) for p in b.index} | {"r2_pa": b.r2_pa.iloc[0]}, "track3/s02/v102/02_height_coefficients_base.csv")
s = rc(f"{S02}/02_height_fit_stats.csv").set_index("prediction")
put("ht_stats", s.to_dict(orient="index"), "track3/s02/v102/02_height_fit_stats.csv")
put("ht_loio", rc(f"{S02}/02_height_loio.csv").iloc[0].to_dict(), "track3/s02/v102/02_height_loio.csv")
put("ht_equiv", rc(f"{S02}/02_height_equivalence.csv").set_index("vector").to_dict(orient="index"), "track3/s02/v102/02_height_equivalence.csv")
a0, a1 = c.loc["a0", "estimate"], c.loc["a1", "estimate"]
put("ht_site_pct_high_vs_low", 100 * ((a0 + 4.5 * a1) / (a0 + 1.0 * a1) - 1), "derived from track3/s02/v102 02 coefficients")
put("ht_site_m_high_vs_low_asymptote", 3.5 * a1, "derived from track3/s02/v102 02 coefficients")
put("ht_site_pct_per100_at_medium", 100 * a1 / (a0 + 2.64 * a1), "derived from track3/s02/v102 02 coefficients")
# ---------------- projections (engine_v102 out_m1 and 05_trajectory_metrics.R in track3/s05/v102; before = engine_joint, v99)
ev = rc(f"{E}/table8_evenaged_M1.csv"); ua = rc(f"{E}/uneven_aged_table8_M1.csv")
evr = rc(f"{R}/table8_evenaged_M1.csv"); uar = rc(f"{R}/uneven_aged_table8_M1.csv")
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
            rows.append(dict(scenario=sc, site=r.Site, age=age, QMD=p.qmd if RAW else r.QMD, QMD_lo=q_lo, QMD_hi=q_hi,
                             HT=getattr(r, "HT", p.ht), BAPH=r.BAPH, TPH=r.TPH, VOL=p.vol if RAW else r.VOL, VOL_lo=v_lo, VOL_hi=v_hi,
                             MAI_net=(p.vol if RAW else r.VOL) / age, MAI_gross=p.mai_gross, SDI=p.sdi if "sdi" in p else np.nan,
                             qmd_check=p.qmd, vol_check=p.vol, cap_bound=bool(p.cap_bound)))
    g = pd.DataFrame(rows)
    g["C"] = g.VOL * 0.510 * 0.47; g["C_lo"] = g.VOL_lo * 0.510 * 0.47; g["C_hi"] = g.VOL_hi * 0.510 * 0.47
    return g
IVR = rc(f"{O5}/05_refit_table6_intervals.csv")
G = grid(ev, ua, pts, IVR=IVR, RAW=True); GR = grid(evr, uar, ptr)
print("raw interval rows", len(IVR))
assert (G.QMD - G.qmd_check).abs().max() < 0.06 and (G.VOL - G.vol_check).abs().max() < 0.06, (G.QMD - G.qmd_check).abs().max()
G.to_csv(f"{T}/build/grid_v102.csv", index=False); GR.to_csv(f"{T}/build/grid_v99.csv", index=False)
t = rc(f"{O5}/05_refit_trajectories_with_mai_pai.csv")
put("uneven_sdi_age100", [float(x) for x in ua[ua.Age == 100].SDI], "engine_v102/out_m1/uneven_aged_table8_M1.csv")
cc = rc(f"{O5}/05_refit_crossover_culmination.csv"); put("cross_cul", cc.to_dict(orient="records"), "track3/s05/v102/05_refit_crossover_culmination.csv (engine_v102)")
put("cross_cul_record", rc(f"{O5}/05_engine_of_record_crossover_culmination.csv").to_dict(orient="records"), "track3/s05/v102/05_engine_of_record_crossover_culmination.csv (before = engine_joint, v99)")
bk = rc(f"{O5}/05_refit_bakuzis_slopes.csv"); put("reineke_100", bk.to_dict(orient="records"), "track3/s05/v102/05_refit_bakuzis_slopes.csv (self-thinning phase, ages 11 to 100, engine_v102)")
put("reineke_100_record", rc(f"{O5}/05_engine_of_record_bakuzis_slopes.csv").to_dict(orient="records"), "track3/s05/v102/05_engine_of_record_bakuzis_slopes.csv (before = engine_joint, v99)")
put("reineke_200", rc(f"{E}/bakuzis_slopes_M1.csv").to_dict(orient="records"), "engine_v102/out_m1/bakuzis_slopes_M1.csv (ages 25 to 200)")
put("reineke_200_record", rc(f"{R}/bakuzis_slopes_M1.csv").to_dict(orient="records"), "engine_joint/out_m1/bakuzis_slopes_M1.csv (before = v99)")
put("eichhorn_cv", rc(f"{O5}/05_refit_eichhorn_cv.csv").to_dict(orient="records"), "track3/s05/v102/05_refit_eichhorn_cv.csv")
so = rc(f"{O5}/05_refit_site_ordering.csv"); bad = so[~so.ordered]
put("site_order_fail", {k: [int(v.age.min()), int(v.age.max()), int(len(v))] for k, v in bad.groupby("scenario")}, "track3/s05/v102/05_refit_site_ordering.csv")
mono = {}
for (sc, si), g in t.groupby(["scenario", "site"]):
    g = g.sort_values("age"); mono[f"{sc}|{si}"] = bool((np.diff(g.qmd) >= -1e-9).all())
put("qmd_monotone", mono, "track3/s05/v102/05_refit_trajectories_with_mai_pai.csv")
env = {}
for sc, g in t.groupby("scenario"):
    env[sc] = dict(qmd=float(g.qmd.max()), baph=float(g.baph.max()), sdi=float(g.sdi.max()), ht=float(g.ht.max()), vol=float(g.vol.max()))
put("envelope_traj_max", env, "track3/s05/v102/05_refit_trajectories_with_mai_pai.csv; observed maxima QMD 69.7, BA 76.06, SDI 1,453")
for lab, D, nm in (("refit", E, "engine_v102"), ("record", R, "engine_joint (before = v99)")):
    tr = rc(f"{D}/traj_M1.csv"); tr = tr[tr.year <= 100]
    out = {}
    for (o, byi), g in tr.groupby(["origin", "byi"]):
        w = g.TPH.to_numpy(); m = g.m_realised.to_numpy()
        out[f"{o}{byi}"] = dict(mean=float(m.mean()), tph_weighted=float((m * w).sum() / w.sum()),
                                cum=float(1 - np.prod(1 - m)), annualised=float(1 - np.prod(1 - m) ** (1 / 100)))
    put(f"mort_level_{lab}", out, f"{nm}/out_m1/traj_M1.csv, m_realised over years 1 to 100")
# validation
put("valid_refit", json.load(open(f"{E}/validation_M1.json")), "engine_v102/out_m1/validation_M1.json")
put("valid_record", json.load(open(f"{R}/validation_M1.json")), "engine_joint/out_m1/validation_M1.json (before = v99)")
put("valid_equiv", rc(f"{O7}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), "track3/s07/v102/07_validation_equivalence.csv (engine_v102 validation_23, 5,000 plot bootstrap)")
vr = rc(f"{E}/validation_M1.csv")
vr["t"] = pd.qcut(vr.sdi0, 3, labels=["low", "mid", "high"])
obs = vr.groupby("t", observed=True).apply(lambda g: (1 - g.obs_surv).mean() / max(g.ny.mean(), 1)).to_dict()
pro = vr.groupby("t", observed=True).apply(lambda g: (1 - g.pr_surv).mean() / max(g.ny.mean(), 1)).to_dict()
put("valid_tertile_mort", dict(obs=obs, proj=pro), "engine_v102/out_m1/validation_M1.csv, as FigS6 panel (b)")
# survival respecification (06_survival_respec.R on the v102 frames, track3/s06/v102)
S06 = f"{T}/s06/v102"
if os.path.exists(f"{S06}/06_survival_respec_stats.csv"):
    ss = rc(f"{S06}/06_survival_respec_stats.csv"); put("surv_stats", ss.drop(columns=["calibration_by_interval"]).to_dict(orient="records"), "track3/s06/v102/06_survival_respec_stats.csv (surv_baseline_rebuilt_v102 4,919 rows, surv_recovered_ii_v102 5,146 rows)")
    put("surv_calib", ss[["sample", "spec", "calibration_by_interval"]].dropna().to_dict(orient="records"), "track3/s06/v102/06_survival_respec_stats.csv")
    put("surv_coef", rc(f"{S06}/06_survival_respec_coefficients.csv").to_dict(orient="records"), "track3/s06/v102/06_survival_respec_coefficients.csv (bootstrap columns are not seed reproducible, see report)")
    put("eq5_baseline", rc(f"{S06}/06_eq5_coefficients_baseline.csv").to_dict(orient="records"), "track3/s06/v102/06_eq5_coefficients_baseline.csv")
    put("eq5_recovered", rc(f"{S06}/06_eq5_coefficients_recovered.csv").to_dict(orient="records"), "track3/s06/v102/06_eq5_coefficients_recovered.csv")
else:
    for k in ("surv_stats", "surv_calib", "surv_coef", "eq5_baseline", "eq5_recovered"): miss(k, "06_survival_respec.R v102 run not finished")
put("accounting", rc(f"{S01}/01_sample_accounting.csv").to_dict(orient="records"), "track3/s01/v102/01_sample_accounting.csv (quoted_in_paper column unchanged from the script)")
put("by_source", rc(f"{S01}/01_by_source.csv").to_dict(orient="records"), "track3/s01/v102/01_by_source.csv")
put("byi_medians", rc(f"{S01}/01_byi_medians.csv").iloc[0].to_dict(), "track3/s01/v102/01_byi_medians.csv")
# origin refit components
if os.path.exists(f"{INC}/A_variants_stats.csv"):
    put("inc_variants", rc(f"{INC}/A_variants_stats.csv").to_dict(orient="records"), "track3/inc/out_V102/A_variants_stats.csv (V0 to V3 from the record starts plus V3_recoded_level_shift_deployed_start, the v102 vector of record)")
    put("inc_coef", rc(f"{INC}/A_variants_coefficients.csv").query("variant == 'V3_recoded_level_shift_deployed_start'").to_dict(orient="records"), "track3/inc/out_V102/A_variants_coefficients.csv (V3 from the deployed start, the engine_v102 vector)")
else:
    miss("inc_variants", "inc_variants_v102.R V102 run not finished"); miss("inc_coef", "inc_variants_v102.R V102 run not finished")
put("stage12", json.load(open(f"{ORG}/out_span/stage1_fit_origin.json")), "out_span/stage1_fit_origin.json, carried forward unchanged into engine_v102 (track 2 section 5, no doubled count in plot_intervals.csv)")
put("stage12_summary", rc(f"{ORG}/out_span/B_stage12_summary.csv").to_dict(orient="records"), "out_span/B_stage12_summary.csv, carried forward unchanged (track 2 section 5)")
put("background_by_origin", rc(f"{ORG}/out_span/B_background_by_origin.csv").to_dict(orient="records"), "out_span/B_background_by_origin.csv, carried forward unchanged (track 2 section 5)")
ig = rc(f"{T2}/out/ingrowth_coefficients.csv"); igr = ig[ig.frame == "record"].set_index("term"); igv = ig[ig.frame == "v102"].set_index("term")
tm = {"d0 (intercept)": "(Intercept)", "d1 (RD)": "RD", "d2 (planted)": "planted"}
REC99 = {"(Intercept)": 3.525983905394, "RD": -2.71915899508393, "planted": 1.55819188443153}
put("ingrowth", [dict(term=tm[k], old=float(igr.loc[k, "estimate"]), new=float(igv.loc[k, "estimate"]), se_new=float(igv.loc[k, "se"]), lo95=float(igv.loc[k, "lo95"]), hi95=float(igv.loc[k, "hi95"]),
                      gate=bool(abs(igr.loc[k, "estimate"] - REC99[tm[k]]) < 1e-4), n=int(igv.loc[k, "n"]), n_planted_new=int(igv.loc[k, "n_planted_new"])) for k in tm],
    "track2/out/ingrowth_coefficients.csv (old = v99 origin recoded vector, new = v102 refit on the key deduplicated 358 row frame, gate = record reproduction of the v99 vector)")
put("garcia", rc(f"{T}/garcia/D_garcia_check.csv").to_dict(orient="records"), "track3/garcia/D_garcia_check.csv (garcia_check on frames/plot_interval_pairs_DATA_v102.csv, 418 intervals)")
vv = rc(V23); put("valid_plots", dict(n=len(vv), planted=int((vv.origin == "planted").sum()), mean_int=float(vv.interval.mean()), max_int=int(vv.interval.max())), "track3/derived/engine_v102_out_m1/validation_23.csv")
put("valid_bias_by_origin", vv.assign(ds=vv.obs_surv - vv.pred_surv, dba=vv.obs_ba - vv.pred_ba, dq=vv.obs_qmd - vv.pred_qmd).groupby("origin")[["ds", "dba", "dq"]].mean().to_dict(orient="index"), "engine_v102 validation_23.csv, observed minus projected")
put("calibration", rc(f"{INC}/G_calibration.csv").to_dict(orient="records"), "track3/inc/out_V102/G_calibration.csv (k with CFX 1.36869 equals the engine multiplier CAL_DDBH)")
put("calibration_loio", rc(f"{INC}/G_calibration_loio.csv").to_dict(orient="records"), "track3/inc/out_V102/G_calibration_loio.csv (folds started from the v102 vector)")
put("calibration_diag", rc(f"{INC}/G_calibration_diagnostics.csv").to_dict(orient="records"), "track3/inc/out_V102/G_calibration_diagnostics.csv")
for o in ("natural", "planted"):
    put(f"valid_equiv_{o}", rc(f"{T}/s07/v102_origin/{o}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), f"track3/s07/v102_origin/{o}/07_validation_equivalence.csv (engine_v102)")
    put(f"valid_equiv_{o}_v97", rc(f"{T}/s07/record_origin/{o}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), f"track3/s07/record_origin/{o}/07_validation_equivalence.csv (before = engine_joint, v99, reproduces valid_origin_joint)")
put("valid_equiv_v97", rc(f"{O7B}/07_validation_equivalence.csv").set_index("quantity").to_dict(orient="index"), "track3/s07/record/07_validation_equivalence.csv (before = engine_joint, v99)")
# ---------------- natural and planted mortality level calibration and source checks
for w, D in (("natural", MN), ("planted", MP)):
    put(f"mortcal_{w}", rc(f"{D}/H_mort_level_{w}.csv").set_index("form").to_dict(orient="index"), f"{D.replace(J + '/', '')}/H_mort_level_{w}.csv (calib_mort and solve_mort on engine_v102 constants and the v102 tree table)")
    put(f"mortcal_loio_{w}", rc(f"{D}/H_mort_loio_{w}.csv").to_dict(orient="records"), f"{D.replace(J + '/', '')}/H_mort_loio_{w}.csv")
put("proto_metrics", rc(f"{PRO}/H_proto_metrics.csv").to_dict(orient="records"), "track3/proto/v102/H_proto_metrics.csv (proto_mort on engine_v102_nocal with the v102 levels, point trajectories, no Monte Carlo)")
put("proto_order", rc(f"{PRO}/H_proto_ordering.csv").to_dict(orient="records"), "track3/proto/v102/H_proto_ordering.csv")
put("proto_valid", json.load(open(f"{PRO}/H_proto_validation_summary.json")), "track3/proto/v102/H_proto_validation_summary.json (observed minus projected)")
put("loso", rc(f"{INC}/I_loso.csv").to_dict(orient="records"), "track3/inc/out_V102/I_loso.csv (refits started from the v102 vector, CFX 1.36869)")
put("k_source_boot", rc(f"{INC}/I_source_bootstrap.csv").to_dict(orient="records"), "track3/inc/out_V102/I_source_bootstrap.csv")
put("k_by_source", rc(f"{INC}/I_k_by_source.csv").to_dict(orient="records"), "track3/inc/out_V102/I_k_by_source.csv")
for w, D in (("natural", MN), ("planted", MP)):
    iv_ = rc(f"{D}/H_mort_intervals_{w}_mult.csv")
    put(f"mortcal_intervals_{w}", dict(n=len(iv_), plots=int(iv_["plot"].nunique()), inst=int(iv_["inst"].nunique()), yip_median=float(iv_.yip.median()), yip_mean=float(iv_.yip.mean()), share_le2=float((iv_.yip <= 2).mean())), f"{D.replace(J + '/', '')}/H_mort_intervals_{w}_mult.csv")
k12 = vv[vv.PLOT == "DOFAW|Kulani|12"].iloc[0]
put("valid_k12", dict(obs_surv=k12.obs_surv, pred_surv=k12.pred_surv, obs_ba=k12.obs_ba, pred_ba=k12.pred_ba, obs_qmd=k12.obs_qmd, pred_qmd=k12.pred_qmd), "engine_v102 validation_23.csv DOFAW|Kulani|12")
v10 = vv[(vv.origin == "planted") & (vv.PLOT != "DOFAW|Kulani|12")]
put("valid_planted_psp", dict(n=len(v10), ds=float((v10.obs_surv - v10.pred_surv).mean()), dba=float((v10.obs_ba - v10.pred_ba).mean()), dq=float((v10.obs_qmd - v10.pred_qmd).mean())), "engine_v102 validation_23.csv planted without Kulani 12")
vn = vv[vv.origin == "natural"]
for lab, sub in (("fia", vn[vn.PLOT.str.startswith("FIA")]), ("dofaw", vn[vn.PLOT.str.startswith("DOFAW")])):
    put(f"valid_nat_{lab}", dict(n=len(sub), ds=float((sub.obs_surv - sub.pred_surv).mean()), dba=float((sub.obs_ba - sub.pred_ba).mean()), dq=float((sub.obs_qmd - sub.pred_qmd).mean())), f"engine_v102 validation_23.csv natural {lab}")
vv7 = rc(V23B)
put("valid_bias_by_origin_v97", vv7.assign(ds=vv7.obs_surv - vv7.pred_surv, dba=vv7.obs_ba - vv7.pred_ba, dq=vv7.obs_qmd - vv7.pred_qmd).groupby("origin")[["ds", "dba", "dq"]].mean().to_dict(orient="index"), "engine_joint/out_m1/validation_23.csv (before = v99)")
for key, lab, nm in (("v98", "v102", "engine_v102"), ("v97", "v99", "engine_joint, the before"), ("u98", "u101", "engine_v102_nocal, v102 constants without the natural level factor")):
    put(f"lt_summary_{key}", rc(f"{LT}/LT_{lab}_summary.csv").to_dict(orient="records"), f"track3/lt/out/LT_{lab}_summary.csv ({nm}; key name kept from v99, label column reads {lab})")
lp = rc(f"{LT}/LT_v102_points.csv")
put("lt_plots", dict(n_plots=int(lp.pid.nunique()), n_points=len(lp), natural=int(lp[lp.planted == 0].pid.nunique()), planted=int(lp[lp.planted == 1].pid.nunique()),
                     nat_span=[int(lp[lp.planted == 0].groupby("pid").h.max().min()), int(lp[lp.planted == 0].groupby("pid").h.max().max())],
                     psp=int(lp.pid.str.startswith("PSP").sum() and lp[lp.pid.str.startswith("PSP")].pid.nunique()),
                     psp_span=[int(lp[lp.pid.str.startswith("PSP")].groupby("pid").h.max().min()), int(lp[lp.pid.str.startswith("PSP")].groupby("pid").h.max().max())]), "track3/lt/out/LT_v102_points.csv")
put("sc_summary", rc(f"{LT}/SC_summary.csv").to_dict(orient="records"), "track3/lt/out/SC_summary.csv (scenarios.py on engine_v102)")
sct = rc(f"{LT}/SC_trajectories.csv")
put("sc_dbhmax", {f"{r.origin}|{r.label}|{int(r.year)}": float(r.DBHMAX) for r in sct[sct.year.isin([40, 100])].itertuples()}, "track3/lt/out/SC_trajectories.csv DBHMAX")
put("sc_tph", {f"{r.origin}|{r.label}|{int(r.year)}": float(r.TPH) for r in sct[sct.year.isin([10, 20, 40, 100])].itertuples()}, "track3/lt/out/SC_trajectories.csv TPH")
put("sc_diag_cr", rc(f"{LT}/SC_diag_crown_ratio.csv").to_dict(orient="records"), "track3/lt/out/SC_diag_crown_ratio.csv")
put("sc_dbhmax20", {f"{r.origin}|{r.label}": float(r.DBHMAX) for r in sct[sct.year == 20].itertuples()}, "track3/lt/out/SC_trajectories.csv DBHMAX at 20")
put("sc_init", {f"{r.origin}|{r.label}": dict(qmd=float(r.QMD), vol=float(r.VOL)) for r in sct[sct.year == 1].itertuples()}, "track3/lt/out/SC_trajectories.csv year 1")
a0 = rc(f"{T}/engine_v102_nocal/out_proto_A0/traj_M1.csv"); m2 = rc(f"{E}/traj_M1.csv")
chg = {}
for (o, b), g_ in m2.groupby(["origin", "byi"]):
    h_ = a0[(a0.origin == o) & (a0.byi == b)].set_index("year"); g_ = g_.set_index("year")
    chg[f"{o}{b}"] = dict(vol40=100 * (g_.loc[40, "VOL"] / h_.loc[40, "VOL"] - 1), vol100=100 * (g_.loc[100, "VOL"] / h_.loc[100, "VOL"] - 1),
                          qmd100=g_.loc[100, "QMD"] - h_.loc[100, "QMD"], ht40=g_.loc[40, "HT"], ht100=g_.loc[100, "HT"])
put("a0_change", chg, "engine_v102 traj_M1 against track3/engine_v102_nocal out_proto_A0 traj_M1 (same engine without the natural level factor)")
put("clip_shares", rc(f"{T}/clip/J_clip_ceiling_shares.csv").to_dict(orient="records"), "track3/clip/J_clip_ceiling_shares.csv from engine_v102 out_m1 replicates")
# ---------------- joint Monte Carlo (track2/mc/out, 500 rows)
put("joint_summary", rc(f"{KJ}/K_joint_summary.csv").set_index("term").to_dict(orient="index"), "track2/mc/out/K_joint_summary.csv (500 joint rows)")
put("joint_cor", rc(f"{KJ}/K_joint_cor.csv", index_col=0).to_dict(orient="index"), "track2/mc/out/K_joint_cor.csv")
_ks = rc(f"{KJ}/K_joint_source_sets.csv"); put("joint_source_sets", dict(n_sets=len(_ks), all_four=int(_ks[_ks.sources.apply(lambda x: len(set(x.split("|")))) == 4].n.sum()), rows=_ks.to_dict(orient="records")), "track2/mc/out/K_joint_source_sets.csv")
_kd = rc(f"{KJ}/K_joint_draws.csv"); put("joint_n", len(_kd), "track2/mc/out/K_joint_draws.csv")
put("joint_distinct_sources", float(_kd.sources.apply(lambda x: len(set(x.split("|")))).mean()), "track2/mc/out/K_joint_draws.csv, mean number of distinct sources per row")
miss("width_ratio", "the v102 Monte Carlo has joint draws only (track2/mc/out); no independent draw run of engine_v102 exists to divide by (v99 divided the joint width by the v98 independent width)")
put("clip_shares_v98", rc(f"{ORG}/output/joint/J_clip_ceiling_shares.csv").to_dict(orient="records"), "output/joint/J_clip_ceiling_shares.csv (before = engine_joint, v99)")
put("ref_spread", rc(f"{T}/joint/K_reference_spread.csv").set_index("quantity").to_dict(orient="index"), "track3/joint/K_reference_spread.csv (joint_diag.py on engine_v102 with its out_joint rows)")
miss("width_ratio_all_ages", "no independent draw run of engine_v102 exists (K_interval_widths.csv of v99 divided engine_joint by engine_mort2 intervals)")
V99 = json.load(open(f"{J}/numbers_v99.json"))
assert list(N) == list(V99), (set(N) ^ set(V99), [(a, b) for a, b in zip(N, V99) if a != b][:5])
json.dump(N, open(f"{T}/numbers_v102.json", "w"), indent=1, default=float)
print("keys", len(N), "regenerated", len(N) - len(MISSING), "not regenerated", [k for k, _ in MISSING])
print(G[["scenario", "site", "age", "QMD", "QMD_lo", "QMD_hi", "HT", "VOL", "VOL_lo", "VOL_hi", "MAI_net", "MAI_gross", "SDI", "C", "C_lo", "C_hi", "cap_bound"]].round(2).to_string(index=False))
for k in ("ht_site_pct_high_vs_low", "ht_site_m_high_vs_low_asymptote", "ht_site_pct_per100_at_medium", "site_order_fail", "envelope_traj_max", "mort_level_refit", "mort_level_record", "valid_tertile_mort", "uneven_sdi_age100", "eichhorn_cv"):
    print(k, N[k]["value"])
