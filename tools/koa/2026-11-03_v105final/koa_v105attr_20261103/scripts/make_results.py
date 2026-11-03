#!/usr/bin/env python3
"""make_results.py: RESULTS.md from out/metrics_long.csv, out/attribution.csv, out/eichhorn_exact.csv. Every value is read from those files."""
import os, pandas as pd
J = os.path.expanduser("~/jobs/koa_v105attr_20261103"); L = pd.read_csv(f"{J}/out/metrics_long.csv"); A = pd.read_csv(f"{J}/out/attribution.csv")
S = pd.read_csv(f"{J}/prep/out/sdimax_pop.csv").iloc[0]
RUNS = [r for r in ("D742", "R_dHT", "R_HT", "R_HCB", "R_S3") if r in set(L.run)] + sorted(r for r in set(L.run) if r.startswith("P_")) + ["C742", "v105d@923", "v105c@923"]
W = L.pivot_table(index="metric", columns="run", values="value", aggfunc="first")
def tbl(metrics, title):
    out = [f"### {title}", "", "| metric | " + " | ".join(RUNS) + " |", "|---|" + "---|" * len(RUNS)]
    for m in metrics:
        if m in W.index: out.append(f"| {m} | " + " | ".join("" if pd.isna(W.loc[m].get(r)) else str(W.loc[m].get(r)) for r in RUNS) + " |")
    return out + [""]
P = ["# RESULTS: koa v105d component attribution under the brms SDImax of record (koa_v105attr_20261103)", "",
     f"Population SDImax at QMD 25.4 cm (brms RI_LONG, {int(S.n_draws)} posterior draws of exp(b0 + b1 log 25.4)): median {S['median']:.2f}, 95% interval {S['q2.5']:.2f} to {S['q97.5']:.2f} "
     f"(mean {S['mean']:.2f}; at posterior means {S.at_posterior_means:.2f}). RD = SDI / {S['median']:.6f} in every run (prep/out/sdimax_pop.csv).", "",
     "Runs: D742 = v105d all-RD forms refitted under the new divisor; R-x = D742 with component x at its v105c form (MORT_CAL re-solved); C742 = v105c with RD rescaled "
     "(dDBH K3c1 refitted). v105d@923 and v105c@923 are the read-only jobs (reference only, not part of the rule). All values from the run's own output files (out/metrics_long.csv lists the file of each value).", ""]
P += ["## Attribution verdicts (preregistered rule)", "", "| failure | metric | present in D742 | D742 | C742 | removed by single revert | movement toward C742 (D742 distance minus run distance) |", "|---|---|---|---|---|---|---|"]
for r in A.itertuples():
    P.append(f"| {r.failure} | {r.metric} | {getattr(r, 'present_in_D742', '')} | {getattr(r, 'D742', '')} | {getattr(r, 'C742', '')} | {getattr(r, 'removed_by_single_revert', '')} | {getattr(r, 'movement_toward_C742', '')} |")
P += [""]
key = ["MORT_CAL natural", "culmination pt | Even-aged natural|Low (142)", "culmination MC | Even-aged natural|Low (142)"] + \
      [f"Eichhorn median CV % unrounded | {g}" for g in ("Even-aged natural", "Uneven-aged natural", "Even-aged planted")] + \
      ["Bakuzis PASS", "Bakuzis FLAG", "Bakuzis info", "Bakuzis NOT EVALUATED", "Bakuzis evaluated", "Bakuzis Reineke step",
       "coverage plotlevel BA | pooled", "coverage plotlevel BA | natural", "coverage plotlevel BA | planted", "coverage plotlevel QMD | pooled",
       "realism suppressed positive | dht_d_density", "realism suppressed positive | ddbh_d_density", "realism suppressed positive | ddbh_d_share", "realism RD max in projections"]
P += tbl(key, "Key metrics")
P += tbl(sorted(m for m in W.index if m.startswith(("VOL40", "QMD40"))), "Volume (m3/ha) and QMD (cm) at 40 yr, 500-replicate MC median (95% range)")
P += tbl(sorted(m for m in W.index if m.startswith("culmination")), "MAI culmination age (yr), point path windowed 10-100 yr and MC median (95%)")
P += tbl(sorted(m for m in W.index if m.startswith(("plot-level", "trajectory"))), "Validation, predicted minus observed (bias / RMSE)")
P += tbl(sorted(m for m in W.index if m.startswith("Eichhorn")), "Eichhorn detail (Bakuzis script rounding and unrounded)")
P += tbl(sorted(m for m in W.index if m.startswith("coverage")), "Coverage of 95% MC intervals, plot level")
open(f"{J}/RESULTS_tables.md", "w").write("\n".join(P) + "\n"); print("\n".join(P))
