"""finalize_constants_v103.py (2026-09-30, Stage A1 close-out). Rewrite out/v103_constants.json with the deploy flags of Aaron's
30 September decisions: dDBH = the v102 vector of record with origin constants re-solved on the v103 NO frame under the live list
percentile BAL (a1close_v103.R gate: eligible under l, not under c), deviation from the preregistered rule; dHT = dHT_L_NO (A1-D1);
HT_P v103; HCB_P kept; Eq. 5 v102 (A1-D2); Eq. 5a v103; ingrowth v103; Stage 1/2 v103; Garcia allometry v103, beta 0.14803 (live koa);
GARCIA_ALPHA 2.96 kept; cohort fraction row v103/l; MORT_CAL solved on the patched engine. Backs up the A1 json first."""
import json, os, shutil, pandas as pd
W = os.path.expanduser("~/jobs/koa_v103_20260930"); P = f"{W}/out/v103_constants.json"; O = f"{W}/out/inc"
if not os.path.exists(f"{W}/out/v103_constants_A1_PREV_20260930.json"): shutil.copy(P, f"{W}/out/v103_constants_A1_PREV_20260930.json")
J = json.load(open(f"{W}/out/v103_constants_A1_PREV_20260930.json"))
bal = open(f"{O}/a1close_bal_choice.txt").read().strip(); assert bal == "l", bal
S = pd.read_csv(f"{O}/a1close_v102vector_by_bal.csv"); r = S[(S.resp == "dDBH") & (S.bal == "l")].iloc[0]; assert bool(r.eligible)
BD = pd.read_csv(f"{O}/boot_v103_dDBH_v102recal_summary.csv").set_index("term")
BH = pd.read_csv(f"{O}/boot_v103_dHT_summary.csv").set_index("term")
RH = pd.read_csv(f"{O}/boot_v103_dHT_resolveonly.csv")
import numpy as np
se_h_ro = (float(np.nanstd(np.log(RH.c_natural), ddof=1)), float(np.nanstd(np.log(RH.c_planted), ddof=1)))
CF_DD = 1.36869   # CF_DDBH_MARGINAL of the v102 vector (engine_v102 koa_params), kept with the vector
alt = J.pop("DDBH_ALTERNATE_V102_VECTOR_RECAL"); cand = J.pop("DDBH")
cn, cp = float(r.c_nat_NO), float(r.c_pl_NO)
J["DDBH"] = dict(fit="dDBH_V102recal_l_NO", deploy=True, bal_definition="live_list_percentile", frame="NO", coef=alt["coef"],
  CF=CF_DD, c_natural=cn, c_planted=cp, CAL=[cn / CF_DD, cp / CF_DD],
  CAL_SE_LOG=[float(BD.loc["c_natural", "se_log"]), float(BD.loc["c_planted", "se_log"])], CAL_SE_LOG_def="SD of log c over 400 installation-cluster resamples within source, vector fixed, c re-solved",
  c_boot_95=[[float(BD.loc["c_natural", "lo95"]), float(BD.loc["c_natural", "hi95"])], [float(BD.loc["c_planted", "lo95"]), float(BD.loc["c_planted", "hi95"])]],
  score_l=dict(eq_int_CS=float(r.eq_int_CS), eq_slope_CS=float(r.eq_slope_CS), eq_int_NO=float(r.eq_int_NO), eq_slope_NO=float(r.eq_slope_NO),
               size_max_dev_NO=float(r.size_max_dev_NO), size_worst=str(r.size_worst), rmse_CS=float(r.rmse_CS), rmse_NO=float(r.rmse_NO)),
  planted_guard=45.0, crown_equation="HCB_P",
  selection_rule_outcome="DEVIATION (Aaron, 30 September 2026): v102 vector of record deployed with origin constants re-solved on the v103 NO frame under the live list percentile BAL; not a preregistered candidate. Eligible under l on every preregistered criterion; not eligible under conventional BAL (equivalence intercept 0.264, 0.269).")
J["DDBH_CANDIDATE_L_NO"] = dict(cand, deploy=False, note="fallback of the preregistered rule (A1-D1), superseded by Aaron's decision")
J["DDBH_V102_VECTOR_BY_BAL"] = S[S.resp == "dDBH"].to_dict(orient="records")
J["DHT"].update(deploy=True, CAL_SE_LOG=[se_h_ro[0], se_h_ro[1]], CAL_SE_LOG_def="SD of log c, vector fixed, c re-solved (as dDBH)",
  CAL_SE_LOG_full_refit=[float(BH.loc["c_natural", "se_log"]), float(BH.loc["c_planted", "se_log"])],
  se_boot={t: float(BH.loc[t, "boot_se"]) for t in [f"b{j}" for j in range(10)]}, boot_n_ok=int(BH.loc["b0", "n_ok"]))
J["HT_P_deploy"] = "v103"; J["HCB_P_deploy"] = "v102 (kept)"
J["SURV_EQ5"]["deploy"] = "v102"; J["SURV_EQ5A"]["deploy"] = "v103"
J["ING_deploy"] = "v103"; J["STAGE1_deploy"] = "v103"
J["GARCIA"].update(deploy_beta="GARCIA_BETA_ANCHORED (live koa, 0.14803)", deploy_alpha="2.96 of record")
J["BAL_COHORT"]["deploy"] = True
J["BAL_DEFINITION_ENGINE"] = "percentile on the live simulated list (= l) for dDBH, dHT and HCB_P; engine BAL_DEFINITION switch not added"
J["meta"].update(stage="A1 close-out", finalized="2026-09-30", decisions="Aaron 2026-09-30: BYI index units, Option A, dDBH v102 vector re-solved, dHT_L_NO, Garcia beta 0.1480, HCB_P kept, Eq5 v102, Eq5a v103")
json.dump(J, open(P, "w"), indent=1)
print("dDBH c", round(cn, 5), round(cp, 5), "CAL", round(cn / CF_DD, 5), round(cp / CF_DD, 5), "SE_LOG", J["DDBH"]["CAL_SE_LOG"])
print("dHT CAL", J["DHT"]["CAL"], "SE_LOG re-solve", se_h_ro, "full refit", J["DHT"]["CAL_SE_LOG_full_refit"])
