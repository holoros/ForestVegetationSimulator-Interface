"""compare_table8.py: new (installation-within-source joint draws, engine copy) vs current (engine_v103/out_m1) Table 8, even and uneven aged.
Point identity gate (max abs point difference < 1e-9), interval width ratio new/current, position of the point in the interval."""
import os, numpy as np, pandas as pd
W = os.path.expanduser("~/jobs/koa_v103_20260930"); J = os.path.join(W, "a2/closeout/jointmc")
pairs = [("even", "table8_evenaged_M1.csv"), ("uneven", "uneven_aged_table8_M1.csv")]
rows = []; gate = {}
for tag, f in pairs:
    C = pd.read_csv(os.path.join(W, "engine_v103/out_m1", f)); N = pd.read_csv(os.path.join(J, "engine/out_m1", f))
    key = ["Scenario", "Site", "Age"]; assert (C[key].values == N[key].values).all()
    pv = [c for c in C.columns if c + "_lo" in C.columns]
    pts = [c for c in C.columns if c not in key and not c.endswith("_lo") and not c.endswith("_hi") and c not in ("n_reps_ok", "n_cf_clipped", "cf_ddbh_mc_se_rel")]
    gate[tag] = float(np.nanmax(np.abs(C[pts].to_numpy(float) - N[pts].to_numpy(float))))
    for i in range(len(C)):
        for v in pv:
            wc = C[v + "_hi"][i] - C[v + "_lo"][i]; wn = N[v + "_hi"][i] - N[v + "_lo"][i]
            rows.append(dict(table=tag, Scenario=C.Scenario[i], Site=C.Site[i], Age=C.Age[i], var=v, point=N[v][i],
                             lo_cur=C[v + "_lo"][i], hi_cur=C[v + "_hi"][i], lo_new=N[v + "_lo"][i], hi_new=N[v + "_hi"][i],
                             width_cur=round(wc, 4), width_new=round(wn, 4), width_ratio=round(wn / wc, 4) if wc > 0 else np.nan,
                             pos_cur=round((C[v][i] - C[v + "_lo"][i]) / wc, 4) if wc > 0 else np.nan,
                             pos_new=round((N[v][i] - N[v + "_lo"][i]) / wn, 4) if wn > 0 else np.nan,
                             point_absdiff=abs(C[v][i] - N[v][i])))
R = pd.DataFrame(rows); R.to_csv(os.path.join(J, "compare_table8.csv"), index=False)
g = max(gate.values()); print("POINT GATE max abs point diff", gate, "->", "PASS" if g < 1e-9 else "FAIL")
print(R.groupby(["table", "Scenario", "var"]).agg(ratio_min=("width_ratio", "min"), ratio_max=("width_ratio", "max"),
      pos_cur_min=("pos_cur", "min"), pos_cur_max=("pos_cur", "max"), pos_new_min=("pos_new", "min"), pos_new_max=("pos_new", "max")).round(3).to_string())
