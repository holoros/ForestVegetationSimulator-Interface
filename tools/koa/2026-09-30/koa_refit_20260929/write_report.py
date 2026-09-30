import os, pandas as pd, numpy as np, subprocess
H = os.path.dirname(os.path.abspath(__file__)); O = f"{H}/out"
T5 = pd.read_csv(f"{O}/table5_compare.csv"); C = pd.read_csv(f"{O}/culmination_compare.csv"); V = pd.read_csv(f"{O}/validation_compare.csv"); E = pd.read_csv(f"{O}/validation_equiv_compare.csv")
PV = pd.read_csv(f"{O}/patch_values_engine_refit.csv"); MC = pd.read_csv(f"{O}/patch_values_mortcal_refit.csv"); L = pd.read_csv(f"{H}/mort/refit/H_mort_level_natural.csv")
ST = pd.read_csv(f"{O}/fit_stats.csv"); boot_exists = os.path.exists(f"{O}/c_bootstrap.csv")
def pipe(df, fmt):
    cols = list(df.columns); out = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for _, r in df.iterrows(): out.append("| " + " | ".join(fmt(c, r[c]) for c in cols) + " |")
    return "\n".join(out) + "\n"
f1 = lambda c, x: (f"{x:+.1f}" if ("pct" in c and isinstance(x, float)) else f"{x:.1f}" if isinstance(x, float) else str(x))
f4 = lambda c, x: (f"{x:.4f}" if isinstance(x, float) else str(x))
md = []
md.append("# Koa engine refit deployment, 29 September 2026: conventional BAL increment equations in the v102 engine\n")
md.append("Job ~/jobs/koa_refit_20260929, engines engine_refit (deployed candidate) and engine_refit_live (sensitivity). Reference is engine_v102 of ~/jobs/koa_v102_20260918/track2 and its outputs traj_v102.csv, val_v102.csv, uneven_v102.csv. Nothing under koa_v102_20260918 was modified.\n")
md.append("## 1. What changed\n")
md.append("""1. A BAL_DEFINITION switch was added to koa_params.py ("percentile" is the 8 September 2026 concept of record that engine_v102 runs, "conventional" is the new definition) and to koa_equations.stand_bal. Under "conventional" the exact tree list path computes BAL_i as the sum over live trees j with DBH_j strictly greater than DBH_i of (pi / 40000) DBH_j^2 EXPF_j in m2 per hectare, equal diameters contributing nothing to each other (new function koa_equations.bal_conventional, checked against a brute force sum). The cohort path (project_cohort) uses fraction = a0 + a1 ln(QMD) with the conventional coefficients BAL_COHORT_LIN_B_CONVENTIONAL = (0.773485, -0.057097) from out/cohort_bal_fraction.csv row bal == c (mean fraction 0.622). Every exact path call site now passes expf so the switch can be taken: koa_projector.project_psp, run_candidates.project, regen_figS4S5. koa_longterm_validation, regenerate_uneven_aged, regen_m1 and calib_mort all project through project_psp or run_candidates.project and are therefore routed through the switch. The percentile arm is unchanged, and the retained PSP_BAL_MODE "cumsum" arm is untouched. run_candidates._finish, which builds the initial Weibull tree list and only uses BAL to set the initial crown ratio, already carried the conventional cumsum construction and was left alone (the Weibull classes have distinct diameters, so ties do not arise there).
2. The increment constants were replaced by the 29 September 2026 refit on all valid remeasurement intervals (frame AP, 15,728 dDBH rows and 13,761 dHT rows, 60 installations): LineageA.DDBH and DHT (b0 to b9, same functional form), CF_DDBH_MARGINAL, CF_DHT (which had stayed at 1.030 through v102 and now takes the fitted exp(0.5 (tau_source^2 + tau_inst^2)) of the dHT fit), CAL_DDBH and CAL_DHT as c_origin / CF so that CF x CAL equals the total per step multiplier c_origin, BAL_DEFINITION = "conventional".
3. HCB_P was NOT refit and is unchanged under both definitions (decision of the lead; the crown BAL term is small). The HCB equation therefore now receives conventional BAL where it was fitted on percentile BAL. This is stated as a known inconsistency.
4. The natural mortality level factor MORT_CAL was re-solved on the patched engine exactly as track 2 did (calib_mort.py and solve_mort.py, form mult, 23 natural non removal intervals, planted unscaled at 1.0).
5. The HiGy.R mirror was brought into step: ddbh.parm and dht.parm site rows carry the refit vectors with a new b9 column (planted level shift), the ddbh() and dht() functions read cf = KOA_CF_x times the origin multiplier KOA_CAL_x, the planted diameter term uses the 45 cm guard of koa_params.DDBH_PLANTED_GUARD_CM instead of pmin(dbh, 40), and the planted height term takes the fitted linear form planted * pmin(ht, 20) that koa_equations carries instead of sqrt(planted * pmin(ht, 20)). New constants KOA_CF_DDBH, KOA_CF_DHT, KOA_CAL_DDBH, KOA_CAL_DHT, KOA_DDBH_PLANTED_GUARD_CM, KOA_BAL_DEFINITION and KOA_BAL_COHORT_LIN_B sit beside KOA_S3_SURV. HiGy.R calc_bal was already the conventional cumsum(ba) - ba over descending dbh with expansion weighted ba, so its BAL needed no change (it differs from bal_conventional only on exact diameter ties). Note that engine_v102 had left the HiGy.R increment tribbles at the constants of record (not even v102), so this is the first time the mirror carries the deployed increment vectors. The stale Stage 1 constants flagged in TRACK_V102_REPORT.md DEVIATION V102-D2 were not touched. HiGy.R parses in R; the parity harness was not rerun.
""")
md.append("## 2. Regression gate\n")
md.append("engine_v102 was copied to engine_refit and run unmodified through a copy of track2/run_engine.py with tag gate. traj_gate.csv against track2/out/traj_v102.csv: 1,800 rows, every numeric column max absolute difference 0.000e+00, PASS. val_gate.csv against val_v102.csv: max absolute difference 0.000e+00, PASS. After the BAL_DEFINITION switch was installed the gate was rerun with the switch at percentile (tag gate2): again 0.000e+00 on both files, PASS (logs/gate2_compare.txt). The switch therefore reproduces engine_v102 exactly when set to percentile.\n")
md.append("## 3. Constants, old (engine_v102) against new (engine_refit)\n")
X = PV[["name", "old", "new", "note"]].copy(); X["note"] = X.note.fillna("")
md.append(pipe(X, lambda c, x: (f"{x:.7g}" if isinstance(x, float) else str(x))))
md.append(f"\nCF_DDBH_MARGINAL 1.36869 to {ST[ST.fit=='dDBH_c_AP'].cf_source_inst.iloc[0]:.5f}, CF_DHT 1.030 to {ST[ST.fit=='dHT_c_AP'].cf_source_inst.iloc[0]:.5f}. Total per step multipliers CF x CAL: dDBH natural {ST[ST.fit=='dDBH_c_AP'].c_natural.iloc[0]:.5f} (v102 0.55498), dDBH planted {ST[ST.fit=='dDBH_c_AP'].c_planted.iloc[0]:.5f} (v102 1.96553), dHT natural {ST[ST.fit=='dHT_c_AP'].c_natural.iloc[0]:.5f} (v102 0.53475), dHT planted {ST[ST.fit=='dHT_c_AP'].c_planted.iloc[0]:.5f} (v102 2.72681). The planted origin multipliers therefore collapse toward one, because the refit carries the origin difference in b9 and b7 on the full interval frame rather than in the calibration.\n")
md.append("CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG are PLACEHOLDERS carrying the v102 values (0.07956, 0.05225) and (0.14862, 0.04807): refit_addendum.R was still running its 2,000 draw installation bootstrap of c when this report was written (out/c_bootstrap.csv absent). Run python3 patch_selog_refit.py once that file exists; it rewrites both engines and both patch_values files. No trajectory or validation number depends on these two constants." if not boot_exists else "CAL_*_SE_LOG were taken from out/c_bootstrap.csv.")
md.append("\n## 4. Natural mortality level factor\n")
r = L[L.form == "mult"].iloc[0]
md.append(f"Solved exactly as track 2 (calib_mort.py, solve_mort.py, form mult, 23 of 23 natural non removal intervals, plot_intervals_origin.csv byte identical to track2/mort/v102, md5 d00f6159). MORT_CAL natural moves from 2.64629 (v102) to {r.level:.5f}, plot cluster bootstrap 95 percent {r.plot_lo95:.4f} to {r.plot_hi95:.4f}, SD of log k {r.plot_se_log:.5f} (v102 0.18172), installation cluster 95 percent {r.inst_lo95:.4f} to {r.inst_hi95:.4f}. Leave one installation out levels {r.loio_level_min:.4f} to {r.loio_level_max:.4f}. Uncalibrated the patched engine predicts {r.pred_deaths_uncal:.0f} deaths per hectare summed over the intervals against {r.obs_deaths:.0f} observed, so the engine now needs a smaller level factor than v102 did: the refit increments grow the natural stands faster early, which raises the gated stand rate. The floor form ({L[L.form=='floor'].level.iloc[0]:.5f}) is not deployed. Planted stays 1.0. The live list sensitivity engine solved to {MC[(MC.engine=='engine_refit_live')&(MC.name=='MORT_CAL_natural')].new.iloc[0]:.5f}.\n")
md.append("## 5. Table 5 comparison, v102 (reference) against refit, percent change refit minus v102 over v102\n")
md.append("Even aged M0 point path under the gated M1 set up, 300 year runs, six scenarios, plus the uneven aged natural ingrowth point path (uneven_point.py). MAI is standing VOL / age.\n")
for v in ["VOL", "QMD", "HT", "BAPH", "TPH", "MAI"]:
    X = T5[["scenario", "site", "age", f"{v}_v102", f"{v}_refit", f"{v}_pct_refit", f"{v}_refit_live", f"{v}_pct_refit_live"]].copy()
    X.columns = ["Scenario", "Site (BYI)", "Age", f"{v} v102", f"{v} refit", "pct refit", f"{v} refit_live", "pct refit_live"]
    md.append(f"### {v}\n"); md.append(pipe(X, lambda c, x: ("" if (isinstance(x, float) and np.isnan(x)) else f"{x:+.1f}" if c.startswith("pct") else f"{x:.1f}" if isinstance(x, float) else str(x))))
md.append("## 6. Net MAI culmination\n")
md.append("Two definitions. track2 is the compare_v102.py rule (argmax of VOL/age over years 10 to 300 for natural stands, 2 to 300 for planted, asterisk when the maximum sits at the window start so there is no interior culmination). afterMin is the rule requested for this job (maximum of net MAI after its first local minimum on the full 300 year path, none when MAI never falls first).\n")
X = C[["scenario", "site", "culm_track2_v102", "culm_track2_refit", "culm_track2_refit_live", "culm_afterMin_v102", "culm_afterMin_refit", "culm_afterMin_refit_live", "MAI_at_culm_track2_v102", "MAI_at_culm_track2_refit", "peakVOL_age_v102", "peakVOL_age_refit", "peakVOL_v102", "peakVOL_refit"]]
md.append(pipe(X, lambda c, x: (f"{x:.2f}" if isinstance(x, float) else str(x))))
md.append("\n## 7. Validation, 23 plots\n")
md.append("Aggregates, bias is projected minus observed (survival fraction, QMD cm, basal area m2 per ha). Observed columns and plot identities are identical between v102 and refit.\n")
md.append(pipe(V, f4))
md.append("\n25 percent equivalence on the mean (TOST, 90 percent plot bootstrap interval of mean observed minus mean predicted inside plus or minus 25 percent of the observed mean) and on the slope (0.75 to 1.25), as compare_v102.py.\n")
md.append(pipe(E, lambda c, x: (f"{x:.3f}" if isinstance(x, float) else str(x))))
md.append("\n## 8. Live list sensitivity (engine_refit_live)\n")
md.append("Coefficients dDBH_l_AP and dHT_l_AP (percentile BAL over the live list, which is what the current engine computes on a projected list), cohort fraction row bal == l written into BAL_COHORT_LIN_B, BAL_DEFINITION percentile, its own mortality level solve. The six even aged trajectories are in the tables of section 5 (refit_live columns) and its validation is included in section 7 for completeness. The refit_live arm moves in the same direction as the deployed conventional arm at every natural cell and is milder on the planted sites (planted volume at age 40 minus 5 to minus 15 percent against minus 11 to minus 20 percent).\n")
md.append("## 9. Not completed, caveats\n")
md.append("""1. CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG are v102 placeholders until out/c_bootstrap.csv exists (patch_selog_refit.py is staged). The trajectories and validation do not read them; the Monte Carlo drivers (regen_m1, joint draws) do.
2. The Monte Carlo (regen_m1 out_m1, joint draws, Table 8 intervals, figures) and the number registry were NOT rerun. Only the M0 point paths, the uneven aged point path and the 23 plot point validation were produced.
3. HCB_P keeps its percentile fitted coefficients while receiving conventional BAL (lead's decision).
4. The HiGy.R mirror edits go beyond what v102 did (v102 left the increment tribbles at the constants of record). They mirror the Python numbers and forms; the parity harness parity_r_050.R / parity_python_050.py was not rerun, and the Stage 1 constants in HiGy.R remain stale as in v102 (DEVIATION V102-D2).
5. The Garcia stand mortality constants, Stage 1 and Stage 2, the survival vector, the static height vector and ingrowth are carried from v102 unchanged.
6. The dHT fit form: the R refit used b7 x Planted x HT untruncated, while the engine (as since 16 September 2026) applies b7 x planted x min(HT, 20 m). The mirror follows the engine. This discrepancy predates this job and is unchanged.
7. bal_conventional uses pi / 40000 for per tree basal area while the projector's BAPH uses 0.00007854; the relative difference is 5e-6 and BAL can exceed BAPH by that amount on a single dominant. Stated for completeness.
8. Under the afterMin culmination rule the natural low site now culminates at year 23 (v102: 59) and the planted medium and high sites have no culmination under either engine because MAI declines monotonically from year 2.
""")
open(f"{H}/ENGINE_REPORT.md", "w").write("\n".join(md))
# RUN_ENGINE.md
tim = open(f"{H}/logs/timings.txt").read(); md5 = open(f"{H}/logs/md5s.txt").read()
open(f"{H}/RUN_ENGINE.md", "w").write(f"""# RUN_ENGINE.md, koa_refit_20260929 (29 to 30 September 2026)

Host firebreather, 8 cores, load average about 10 from other users' jobs during the run. All commands from ~/jobs/koa_refit_20260929.

| Step | Command | Wall time |
|---|---|---|
| copy engine | cp -r ~/jobs/koa_v102_20260918/track2/engine_v102 engine_refit; cp track2/run_engine.py, track2/uneven_point.py | seconds |
| gate | python3 run_engine.py engine_refit gate; python3 compare_gate.py out/traj_gate.csv .../traj_v102.csv | about 45 s, PASS 0.000e+00 |
| BAL switch | python3 patch_bal_switch.py engine_refit; cp -r engine_refit engine_refit_live | seconds |
| gate 2 (switch at percentile) | python3 run_engine.py engine_refit gate2; compare_gate.py | about 45 s, PASS 0.000e+00 |
| constants | python3 patch_engine_refit.py engine_refit c; python3 patch_engine_refit.py engine_refit_live l | seconds |
| mortality level | ./run_mort.sh (KOA_OUTDIR=. python3 mort/calib_mort.py engine_<arm> mort/<arm> natural; python3 mort/solve_mort.py mort/<arm> natural) | about 30 s both arms |
| write MORT_CAL | python3 patch_mortcal_refit.py | seconds |
| production | ./run_all.sh | {tim.strip().replace(chr(10), '; ')} |
| compare | python3 compare_refit.py | about 40 s (5,000 draw equivalence bootstraps) |
| report | python3 write_report.py | seconds |
| pending | python3 patch_selog_refit.py (after refit_addendum.R writes out/c_bootstrap.csv) | |

Outputs in out/: traj_gate.csv, val_gate.csv, traj_gate2.csv, val_gate2.csv, traj_refit.csv, val_refit.csv, uneven_refit.csv, traj_refit_live.csv, val_refit_live.csv, table5_compare.csv, culmination_compare.csv, validation_compare.csv, validation_equiv_compare.csv, patch_values_engine_refit.csv, patch_values_engine_refit_live.csv, patch_values_mortcal_refit.csv. Mortality solve outputs in mort/refit and mort/refit_live (H_mort_level_natural.csv and companions). Logs in logs/.

md5sums of the patched files and scripts:

```
{md5}```
""")
print("reports written")
