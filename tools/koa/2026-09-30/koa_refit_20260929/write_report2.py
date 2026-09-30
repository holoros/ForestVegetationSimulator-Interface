import os, json, pandas as pd, numpy as np
H = os.path.dirname(os.path.abspath(__file__)); O = f"{H}/out"
T5 = pd.read_csv(f"{O}/table5_compare.csv"); C = pd.read_csv(f"{O}/culmination_compare.csv"); V = pd.read_csv(f"{O}/validation_compare.csv"); E = pd.read_csv(f"{O}/validation_equiv_compare.csv")
PV = pd.read_csv(f"{O}/patch_values_engine_refit2.csv"); MC = pd.read_csv(f"{O}/patch_values_mortcal_refit2.csv"); L = pd.read_csv(f"{H}/mort/refit2/H_mort_level_natural.csv"); CH = json.load(open(f"{O}/deployed_choice2.json"))
X = pd.read_csv(f"{O}/observed_repair_check.csv"); I = pd.read_csv(f"{O}/observed_repair_intervals.csv"); Y = pd.read_csv(f"{H}/fin/out/yield_grid_compare.csv")
def pipe(df, fmt):
    cols = list(df.columns); out = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for _, r in df.iterrows(): out.append("| " + " | ".join(fmt(c, r[c]) for c in cols) + " |")
    return "\n".join(out) + "\n"
fp = lambda c, x: ("" if (isinstance(x, float) and np.isnan(x)) else f"{x:+.1f}" if ("pct" in c) else f"{x:.1f}" if isinstance(x, float) else str(x))
md = ["\n\n# Second pass (refit2), 30 September 2026\n"]
md.append(f"The red team rejected the AP fits (size response and sign flips) and found the deposited plot-year BAPH and TPH doubled on 29 plot-years (out/plotyear_repair_log.csv). refit2.R repaired those covariates, fitted on the NO frame ({CH['frame']}), used HCB_P for CR and the 45 cm and 20 m planted guards inside the recursion, and conventional BAL as the direct expansion weighted sum. Deployed choice out/deployed_choice2.json: {CH['dDBH']['fit']} (n {CH['dDBH']['n']}) and {CH['dHT']['fit']} (n {CH['dHT']['n']}), cohort fraction row c a0 {CH['cohort_fraction']['a0']:.5f}, a1 {CH['cohort_fraction']['a1']:.5f} (mean fraction {CH['cohort_fraction']['mean_frac']:.4f}). Rule as recorded in the json: {CH['rule']}\n")
md.append("engine_refit and engine_refit_live from the first pass are left in place. The chain was repeated as engine_refit2 (deployed candidate) and engine_refit2_live (live list alternative dDBH_l_NO, dHT_l_NO, cohort row l).\n")
md.append("## S1. Gate\n\nengine_v102 copied fresh to engine_refit2, BAL_DEFINITION switch installed with the same patch_bal_switch.py, run_engine.py tag gate3 with the switch at percentile: traj_gate3.csv against traj_v102.csv 0.000e+00 on every numeric column, val_gate3.csv against val_v102.csv 0.000e+00, PASS (logs/gate3_compare.txt).\n")
md.append("## S2. Constants, old (engine_v102) against new (engine_refit2)\n")
md.append(pipe(PV[["name", "old", "new", "note"]].fillna(""), lambda c, x: (f"{x:.7g}" if isinstance(x, float) else str(x))))
d, h = CH["dDBH"], CH["dHT"]
md.append(f"\nCF_DDBH_MARGINAL 1.36869 to {d['cf_source_inst']:.5f}; CF_DHT 1.030 to {h['cf_source_inst']:.5f}. CAL_DDBH ({d['k_natural']:.5f}, {d['k_planted']:.5f}), CAL_DHT ({h['k_natural']:.5f}, {h['k_planted']:.5f}), so the total per step multipliers c are dDBH {d['c_natural']:.5f} natural and {d['c_planted']:.5f} planted (v102 0.55498 and 1.96553), dHT {h['c_natural']:.5f} and {h['c_planted']:.5f} (v102 0.53475 and 2.72681). Unlike the AP pass these sit close to the v102 pattern. CAL_DDBH_SE_LOG and CAL_DHT_SE_LOG keep the v102 PLACEHOLDERS (0.07956, 0.05225) and (0.14862, 0.04807); no c bootstrap exists for the NO fits. HiGy.R mirrored as in the first pass (tribbles, b9, cf times origin multiplier, 45 cm guard, linear planted height term, KOA_* constants); parses in R. HCB_P unchanged.\n")
md.append("## S3. Observed plot values and the 29 repaired plot-years\n")
md.append(f"Neither consumer reads the deposited plot-year BAPH or TPH. koa_longterm_validation.validate computes tph0 and baph0 at the interval start and obsQMD and obsBAPH at the end from the live tree records with EXPF (lines 121 to 125 and 142 to 145), and calib_mort.py computes tph0, baph0 and obs_surv the same way from the live list (lines 48 to 53); solve_mort.py reads only tph0 and obs_surv. The deposited TPH and BAPH columns of AK_TREE.csv (doubled, deposited over repaired TPH ratio {(X.TPH_deposited / X.TPH_repaired).min():.3f} to {(X.TPH_deposited / X.TPH_repaired).max():.3f}) are carried in the table but never read. check_observed_repair.py confirms that for all 29 plot-years the engine's live list values equal the repaired values of out/plotyear_repair_log.csv to 1e-6 (out/observed_repair_check.csv). The repaired plot-years touch {int((I.use == 'validation').sum())} of 23 validation intervals and {int((I.use == 'calibration').sum())} of 23 calibration intervals (out/observed_repair_intervals.csv, listed below), and on each of them the observed values used were already the live list values, so the repair changes nothing in either the calibration or the validation: the repaired and unrepaired runs are numerically identical. No separate refit2_unrepairedobs run was produced because there is no code path that would make it differ; the validation observed columns are identical across v102, refit, and refit2 (compare_refit.py check).\n")
md.append(pipe(I, lambda c, x: str(x)))
r = L[L.form == "mult"].iloc[0]
md.append(f"\n## S4. Natural mortality level factor\n\nMORT_CAL natural: v102 2.64629, refit (AP) 1.85561, refit2 {r.level:.5f}, plot cluster bootstrap 95 percent {r.plot_lo95:.4f} to {r.plot_hi95:.4f}, SD log k {r.plot_se_log:.5f}, installation cluster {r.inst_lo95:.4f} to {r.inst_hi95:.4f}, LOIO {r.loio_level_min:.4f} to {r.loio_level_max:.4f}; uncalibrated predicted deaths {r.pred_deaths_uncal:.0f} against {r.obs_deaths:.0f} observed per hectare summed. Planted 1.0. refit2_live solved to {MC[(MC.engine=='engine_refit2_live')&(MC.name=='MORT_CAL_natural')].new.iloc[0]:.5f}.\n")
md.append("## S5. Table 5, refit2 against v102 (and the first pass refit for reference)\n")
for v in ["VOL", "QMD", "HT", "BAPH", "TPH", "MAI"]:
    Z = T5[["scenario", "site", "age", f"{v}_v102", f"{v}_refit", f"{v}_refit2", f"{v}_pct_refit", f"{v}_pct_refit2", f"{v}_refit2_live", f"{v}_pct_refit2_live"]].copy()
    Z.columns = ["Scenario", "Site (BYI)", "Age", f"{v} v102", f"{v} refit", f"{v} refit2", "pct refit", "pct refit2", f"{v} refit2_live", "pct refit2_live"]
    md.append(f"### {v}\n"); md.append(pipe(Z, fp))
md.append("## S6. Culmination\n")
Z = C[["scenario", "site", "culm_track2_v102", "culm_track2_refit", "culm_track2_refit2", "culm_track2_refit2_live", "culm_afterMin_v102", "culm_afterMin_refit2", "MAI_at_culm_track2_v102", "MAI_at_culm_track2_refit2", "peakVOL_age_v102", "peakVOL_age_refit2", "peakVOL_v102", "peakVOL_refit2"]]
md.append(pipe(Z, lambda c, x: (f"{x:.2f}" if isinstance(x, float) else str(x))))
md.append("\n## S7. Validation, 23 plots, all frames\n")
md.append(pipe(V, lambda c, x: (f"{x:.4f}" if isinstance(x, float) else str(x))))
md.append("\n25 percent equivalence (TOST), all frames.\n")
md.append(pipe(E, lambda c, x: (f"{x:.3f}" if isinstance(x, float) else str(x))))
md.append("\n## S8. Financial yield grid (fin/run_yield_grid_refit2.py against ~/jobs/koa_fin_20260924/out/koa_yield_grid_200yr.csv)\n")
md.append("Sixteen planted scenarios, four sites (BYI 450, 340, 230, 120) by four established densities (100 to 400 stems per acre), 200 years, M0 point path. Full table fin/out/yield_grid_compare.csv (ages 20, 40, 45, 52, 60, 100, 200). Ages 40, 45 and 52 below.\n")
Z = Y[Y.age.isin([40, 45, 52])][["site", "tpa0", "age", "BA_ft2ac_v102", "BA_ft2ac_refit2", "BA_ft2ac_pct", "QMD_in_v102", "QMD_in_refit2", "QMD_in_pct", "stems_ac_pct", "VOL_m3ha_pct", "peakBA_v102", "peakBA_refit2", "peakBA_age_v102", "peakBA_age_refit2"]]
md.append(pipe(Z, fp))
for age in (40, 45, 52):
    x = Y[Y.age == age].BA_ft2ac_pct; md.append(f"Age {age}: BA percent change min {x.min():+.1f}, median {x.median():+.1f}, max {x.max():+.1f}.\n")
md.append("\n## S9. Not completed, caveats (second pass)\n")
md.append("""1. CAL_*_SE_LOG are v102 placeholders (no bootstrap for the NO fits).
2. Monte Carlo, joint draws, Table 8 intervals, registry and parity harness not rerun.
3. HCB_P fitted on percentile BAL, fed conventional BAL.
4. dHT_c_NO was deployed by stated deviation from the preregistered intercept rule (see the rule text above).
5. The v102 yield grid of 24 September is taken as the reference as found; it was not regenerated.
""")
open(f"{H}/ENGINE_REPORT.md", "a").write("\n".join(md))
tim = open(f"{H}/logs/timings.txt").read().strip().splitlines(); md5 = open(f"{H}/logs/md5s.txt").read()
open(f"{H}/RUN_ENGINE.md", "a").write(f"""

## Second pass (refit2), 30 September 2026

| Step | Command | Wall time |
|---|---|---|
| copy and switch | cp -r .../engine_v102 engine_refit2; python3 patch_bal_switch.py engine_refit2 | seconds |
| gate 3 | python3 run_engine.py engine_refit2 gate3; compare_gate.py | about 45 s, PASS 0.000e+00 |
| constants | cp -r engine_refit2 engine_refit2_live; python3 patch_engine_refit2.py engine_refit2 c; python3 patch_engine_refit2.py engine_refit2_live l | seconds |
| observed value check | python3 check_observed_repair.py | seconds |
| mortality level | ./run_mort2.sh; python3 patch_mortcal_refit2.py | about 40 s |
| production | ./run_all2.sh | {'; '.join(tim[-3:])} |
| compare | python3 compare_refit.py | about 60 s |
| yield grid | python3 fin/run_yield_grid_refit2.py; python3 fin/compare_yield_grid.py | about 35 s |
| report | python3 write_report.py; python3 write_report2.py | seconds |

Outputs added: out/traj_gate3.csv, val_gate3.csv, traj_refit2.csv, val_refit2.csv, uneven_refit2.csv, traj_refit2_live.csv, val_refit2_live.csv, patch_values_engine_refit2.csv, patch_values_engine_refit2_live.csv, patch_values_mortcal_refit2.csv, observed_repair_check.csv, observed_repair_intervals.csv; fin/out/koa_yield_grid_200yr.csv, koa_yield_grid_diagnostics.csv, yield_grid_compare.csv; mort/refit2, mort/refit2_live. The four compare CSVs now carry refit2 and refit2_live columns or rows alongside v102, refit and refit_live.

md5sums (full list including second pass files):

```
{md5}```
""")
print("appended")
