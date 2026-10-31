"""a5/rerun/s28/to_pred_minus_obs.py: B1/B2 outputs carry errors as observed minus projected (lt_core.add_err); Tables S28/S29 report
projected minus observed. Biases (and bias changes, with their bounds swapped) are negated here; RMSEs are unchanged."""
import pandas as pd, numpy as np
b1 = pd.read_csv("B1_lt_natural_summary.csv")
for v in ("surv", "qmd", "ba"): b1[v + "_bias"] = -b1[v + "_bias"]
b1["arm"] = b1.arm.map({"a_deployed": "Applied (2.51588)", "b_heldout": "Held out", "c_none": "None (1.0)"})
b1.to_csv("tableS28_v104_pred_minus_obs.csv", index=False)
b2 = pd.read_csv("B2_summary_boot.csv"); out = b2[["origin", "horizon", "n_points", "n_plots"]].copy()
for v in ("surv", "qmd", "ba"):
    for k in ("bias_pop", "bias_loc", "dbias"):
        out[f"{v}_{k}"] = -b2[f"{v}_{k}"]
        if f"{v}_{k}_lo95" in b2: out[f"{v}_{k}_lo95"] = -b2[f"{v}_{k}_hi95"]; out[f"{v}_{k}_hi95"] = -b2[f"{v}_{k}_lo95"]
    for k in ("rmse_pop", "rmse_loc", "drmse"):
        out[f"{v}_{k}"] = b2[f"{v}_{k}"]
    out[f"{v}_drmse_lo95"] = b2[f"{v}_drmse_lo95"]; out[f"{v}_drmse_hi95"] = b2[f"{v}_drmse_hi95"]
out.to_csv("tableS29_v104_pred_minus_obs.csv", index=False)
pd.set_option("display.width", 250)
print(b1.round(3).to_string(index=False))
print(out[["origin", "horizon", "n_points", "n_plots", "surv_bias_pop", "surv_bias_loc", "qmd_bias_pop", "qmd_bias_loc", "qmd_dbias", "qmd_dbias_lo95", "qmd_dbias_hi95", "qmd_rmse_pop", "qmd_rmse_loc", "ba_bias_pop", "ba_bias_loc", "ba_rmse_pop", "ba_rmse_loc"]].round(2).to_string(index=False))
