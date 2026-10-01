"""report_a1close.py: append section 8 (A1 close-out) to STAGE1_REPORT.md from out/inc/a1close_* and out/v103_constants.json."""
import json, pandas as pd
S = pd.read_csv("out/inc/a1close_v102vector_by_bal.csv"); J = json.load(open("out/v103_constants.json")); D, H = J["DDBH"], J["DHT"]
L = ["\n## 8. Stage A1 close-out (Aaron's decisions of 30 September 2026)\n",
"Decision taken: deploy the v102 dDBH vector with origin constants re-solved on the v103 frame, as a stated deviation from the preregistered rule, provided it scores as reported under a BAL definition the engine can compute. The engine's percentile path runs on the live simulated list, so it computes the live list percentile (l); conventional BAL (c) is the other engine computable form. The dead inclusive percentile (d) is not engine computable. Script track2/inc/a1close_v103.R (md5 in RUN.md), seed 20260930.\n",
"The v102 vector of record scored on the v103 frames under each BAL definition, origin constants re-solved per frame (engine form recursion, HCB_P crown ratio under the same BAL). Eligibility as preregistered: signs, equivalence regions at most 0.25 on both frames, NO frame size max |obs/pred - 1| at most 0.25.\n",
"| resp | BAL | eq int CS | eq slope CS | eq int NO | eq slope NO | size max NO | worst class | RMSE CS | RMSE NO | c natural NO | c planted NO | eligible |", "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
for _, r in S.iterrows():
    L.append(f"| {r.resp} | {r.bal} | {r.eq_int_CS:.4f} | {r.eq_slope_CS:.4f} | {r.eq_int_NO:.4f} | {r.eq_slope_NO:.4f} | {r.size_max_dev_NO:.3f} | {r.size_worst} | {r.rmse_CS:.4f} | {r.rmse_NO:.4f} | {r.c_nat_NO:.4f} | {r.c_pl_NO:.4f} | {bool(r.eligible)} |")
d = S[(S.resp == "dDBH") & (S.bal == "d")].iloc[0]; l = S[(S.resp == "dDBH") & (S.bal == "l")].iloc[0]
L += ["",
f"Gate result: the v102 dDBH vector is eligible under the live list percentile (equivalence regions {l.eq_int_CS:.3f} and {l.eq_slope_CS:.3f} CS, {l.eq_int_NO:.3f} and {l.eq_slope_NO:.3f} NO; size max {l.size_max_dev_NO:.3f} at {l.size_worst} cm) and not under conventional BAL (intercept regions above 0.25). It is therefore deployed under l, the same definition as dHT_L_NO, so both increments and HCB_P see one BAL. Its NO frame RMSE under l, {l.rmse_NO:.4f}, is within 0.3 percent of the refit dDBH_L_NO (1.2607).",
f"Reproduction of the section 5.6 benchmark under d: origin constants {d.c_nat_NO:.4f} and {d.c_pl_NO:.4f} and size max {d.size_max_dev_NO:.3f} reproduce exactly; the equivalence regions ({d.eq_int_NO:.4f}, {d.eq_slope_NO:.4f} NO) differ from the reported 0.1811 and 0.1390 by about 0.01 because the 1,000 resample equivalence bootstrap draws from a different RNG stream in this run. That Monte Carlo spread (about 0.01 to 0.015) is the precision of every equivalence region in this report, and the l margins to 0.25 exceed it.",
"",
"Deployed constants (NO frame, l):",
"", "| quantity | dDBH (v102 vector) | dHT (dHT_L_NO) |", "|---|---|---|",
f"| c natural | {D['c_natural']:.5f} | {H['c_natural']:.5f} |", f"| c planted | {D['c_planted']:.5f} | {H['c_planted']:.5f} |",
f"| CF | {D['CF']:.5f} (v102 fit, kept with the vector) | {H['CF']:.5f} |", f"| CAL natural, planted | {D['CAL'][0]:.5f}, {D['CAL'][1]:.5f} | {H['CAL'][0]:.5f}, {H['CAL'][1]:.5f} |",
f"| SE of log c (natural, planted), vector fixed, 400 installation resamples within source | {D['CAL_SE_LOG'][0]:.4f}, {D['CAL_SE_LOG'][1]:.4f} | {H['CAL_SE_LOG'][0]:.4f}, {H['CAL_SE_LOG'][1]:.4f} |",
f"| SE of log c with the vector refit on every resample | not applicable (vector fixed by decision) | {H['CAL_SE_LOG_full_refit'][0]:.4f}, {H['CAL_SE_LOG_full_refit'][1]:.4f} |",
f"| c 95 percent bootstrap interval | natural {D['c_boot_95'][0][0]:.4f} to {D['c_boot_95'][0][1]:.4f}; planted {D['c_boot_95'][1][0]:.4f} to {D['c_boot_95'][1][1]:.4f} | see section 5.6 bootstrap summary |",
"",
"CAL_*_SE_LOG use the vector fixed definition for both responses, the definition the engine Monte Carlo applies to the origin multiplier alone (vector uncertainty enters through the joint draws). The full refit dHT values show that the natural dHT multiplier is weakly identified once the vector is free (95 percent interval of c natural 0.33 to 1.70); that is disclosed, not used as the engine SE.",
"",
"Both bootstraps: the dDBH_L_NO coefficient bootstrap finished (400 of 400) and is kept as out/inc/boot_v103_dDBH_summary.csv for the candidate table; the v102 vector constants bootstrap is out/inc/boot_v103_dDBH_v102recal_summary.csv.",
"",
"Deviations added: A1-D6, the deployed dDBH is not a preregistered candidate (Aaron's decision; full candidate table in section 5.6). A1-D1 now applies to dHT only. out/v103_constants.json carries deploy flags for every block; the A1 json is kept as out/v103_constants_A1_PREV_20260930.json.\n"]
open("STAGE1_REPORT.md", "a").write("\n".join(L).replace("—", ", ")); print("appended", len(L))
