"""a5/rerun/qr/03_contain_v104.py: containment of the v104 even-aged projections (engine_v103/out_m1 traj_M1.csv point runs and
reps_evenaged_M1.csv Monte Carlo replicates, ages 1 to 100) under the tau 0.99 and 0.95 ALL lines of qr_lines_v104.csv, as the
preliminary 02_fit_contain.R did for the v102 trajectories (point-line comparison only; pointwise bands not recomputed)."""
import pandas as pd, numpy as np
L = pd.read_csv("qr_lines_v104.csv"); E = "../../../engine_v103/out_m1/"
T = pd.read_csv(E + "traj_M1.csv"); T = T[T.year <= 100]
R = pd.read_csv(E + "reps_evenaged_M1.csv"); R = R[R.year <= 100]
out = []
for tau in (0.95, 0.99):
    l = L[(L.set == "ALL") & (L.tau == tau)].iloc[0]
    for lab, D, gcols in (("point", T, ["origin", "site"]), ("mc_reps", R, ["scen", "byi"])):
        D = D.copy(); D["Nlim"] = np.exp(l.b0 + l.b1 * np.log(D.QMD)); D["frac"] = D.TPH / D.Nlim
        for k, g in D.groupby(gcols):
            out.append(dict(tau=tau, runs=lab, group=" ".join(map(str, k)), n=len(g), n_above=int((g.TPH > g.Nlim).sum()),
                            max_frac_of_line=float(g.frac.max()), max_excess_N=float((g.TPH - g.Nlim).max())))
O = pd.DataFrame(out); O.to_csv("containment_v104.csv", index=False); pd.set_option("display.width", 200); print(O.round(3).to_string(index=False))
