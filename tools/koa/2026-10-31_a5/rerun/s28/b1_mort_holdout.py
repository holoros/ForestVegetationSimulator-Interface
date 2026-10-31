#!/usr/bin/env python3
"""B1 (v100 track B, 2026-09-17): independent check of the natural mortality level factor.
(a) deployed factor, (b) factor solved without the plot's own installation (out_span/H_mort_loio_natural.csv, form mult),
(c) no factor (1.0). Long-term trajectory points for the natural plots, and the 23-plot first-to-last validation."""
# a5/rerun copy (2026-10-31): inputs switched to the v104 engine copy (./engine = cp of engine_v103 without out_m1*),
# v104 mortality files a2/mort/v104 and gate a4/lt/LT_v104_points.csv. Logic otherwise verbatim from koa_origin_20260916/v100/trackB.
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, pandas as pd
import lt_core as C
OUT = C.HERE
J = os.path.abspath(os.path.join(C.HERE, "..", ".."))
IV = pd.read_csv(os.path.join("/home/aaron/jobs/koa_v104_20261030", "a2", "mort", "v104", "H_mort_intervals_natural_mult.csv"))
LO = pd.read_csv(os.path.join("/home/aaron/jobs/koa_v104_20261030", "a2", "mort", "v104", "H_mort_loio_natural.csv"))
LO = LO[LO.form == "mult"]
HELD = dict(zip(LO.held, LO.level_train))
CONTRIB_INST = sorted(IV.inst.unique()); CONTRIB_PID = sorted(IV.pid.unique())
LEV = pd.read_csv(os.path.join("/home/aaron/jobs/koa_v104_20261030", "a2", "mort", "v104", "H_mort_level_natural.csv"))
lev_full = float(LEV[LEV.form == "mult"].level.iloc[0])
print("deployed MORT_CAL[0]", C.MORT0, "solved level", lev_full, "intervals", len(IV), "plots", len(CONTRIB_PID), "installations", CONTRIB_INST)
print("held-out levels", HELD)


def inst_of(pid):
    d, i, _ = pid.split("|")
    return f"{d}|{i}"


def heldout(pid):
    k = inst_of(pid)
    return (float(HELD[k]), True) if k in HELD else (C.MORT0, False)


# ---------------- long-term trajectories, natural plots
pids = [p for p in C.lt_pids() if C.setup(p)["planted"] == 0]
rows, info = [], []
for p in pids:
    S = C.setup(p)
    hk, contrib = heldout(p)
    info.append(dict(pid=p, installation=inst_of(p), installation_contributed=contrib,
                     plot_contributed=p in CONTRIB_PID, n_intervals_plot=int((IV.pid == p).sum()),
                     n_intervals_installation=int((IV.inst == inst_of(p)).sum()),
                     factor_deployed=C.MORT0, factor_heldout=hk, factor_none=1.0))
    for arm, k in (("a_deployed", None), ("b_heldout", hk), ("c_none", 1.0)):
        d = C.run_points(p, mort=k, S=S); d["arm"] = arm; d["factor"] = C.MORT0 if k is None else k
        rows.append(d)
C.KE.joint_assert_clean("b1 lt end")
PTS = C.add_err(pd.concat(rows, ignore_index=True))
INFO = pd.DataFrame(info)
PTS.drop(columns=["hc"]).assign(hc=PTS.hc.astype(str)).to_csv(os.path.join(OUT, "B1_lt_natural_points.csv"), index=False)
INFO.to_csv(os.path.join(OUT, "B1_natural_plot_factors.csv"), index=False)
# gate: arm a equals the reference points
ref = pd.read_csv(os.path.join("/home/aaron/jobs/koa_v104_20261030", "a4", "lt", "LT_v104_points.csv"))
ref = ref[ref.planted == 0].sort_values(["pid", "tk"]).reset_index(drop=True)
aa = PTS[PTS.arm == "a_deployed"].sort_values(["pid", "tk"]).reset_index(drop=True)
gd = max(abs(aa[c] - ref[c]).max() for c in ("pr_surv", "prQMD", "prBAPH", "obs_surv", "obsQMD", "obsBAPH"))
print("arm a vs LT_v98 natural max abs diff", gd); assert gd < 1e-9
S_ = []
for (arm, hc), d in PTS.groupby(["arm", "hc"], observed=True):
    S_.append(dict(arm=arm, horizon=hc, **C.summ(d)))
for arm, d in PTS.groupby("arm"):
    S_.append(dict(arm=arm, horizon="all", **C.summ(d)))
SUM = pd.DataFrame(S_)
SUM.to_csv(os.path.join(OUT, "B1_lt_natural_summary.csv"), index=False)
print(SUM.round(3).to_string())
PP = []
for (arm, p), d in PTS.groupby(["arm", "pid"]):
    PP.append(dict(arm=arm, pid=p, **C.summ(d)))
PP = pd.DataFrame(PP); PP.to_csv(os.path.join(OUT, "B1_lt_natural_byplot.csv"), index=False)
print(PP.round(3).to_string())

# ---------------- 23-plot first-to-last validation
V = C.V
V.stand_mortality = C.RM._gated
levels = {"deployed": None, "none": 1.0}
for k, v in HELD.items():
    levels["held:" + k] = float(v)
VAL = {}
for lab, k in levels.items():
    C.apply(mort=k)
    try:
        r = V.validate()
    finally:
        C.RM.set_params(None)
    VAL[lab] = r
    print("validate", lab, len(r))
C.KE.joint_assert_clean("b1 val end")
base = VAL["deployed"].copy()
# gate against the deposited 23-plot validation of the deployed engine, if present
for cand in (os.path.join(C.E, "out_m1", "validation_M1.csv"),):
    if os.path.exists(cand):
        ref = pd.read_csv(cand)
        m = base.merge(ref, on="pid", suffixes=("", "_ref"))
        dd = max(abs(m[c] - m[c + "_ref"]).max() for c in ("pr_surv", "prQMD", "prBAPH"))
        print("validation deployed vs", cand, "n", len(m), "of", len(ref), "max abs diff", dd)
base["installation"] = base.pid.map(inst_of)
base["installation_contributed"] = base.installation.isin(HELD.keys())
base["plot_contributed"] = base.pid.isin(CONTRIB_PID)
base["n_intervals_plot"] = base.pid.map(lambda p: int((IV.pid == p).sum()))
out = []
for _, r in base.iterrows():
    p = r.pid
    for arm in ("a_deployed", "b_heldout", "c_none"):
        if arm == "a_deployed":
            src, fac = "deployed", C.MORT0
        elif arm == "c_none":
            src, fac = "none", 1.0
        else:
            k = inst_of(p)
            if r.planted == 0 and k in HELD:
                src, fac = "held:" + k, float(HELD[k])
            else:
                src, fac = "deployed", C.MORT0
        rr = VAL[src].set_index("pid").loc[p]
        out.append(dict(pid=p, planted=int(r.planted), ny=int(r.ny), installation=r.installation,
                        installation_contributed=bool(r.installation_contributed), plot_contributed=bool(r.plot_contributed),
                        n_intervals_plot=int(r.n_intervals_plot), arm=arm, factor=fac,
                        obs_surv=rr.obs_surv, pr_surv=rr.pr_surv, obsQMD=rr.obsQMD, prQMD=rr.prQMD, obsBAPH=rr.obsBAPH, prBAPH=rr.prBAPH))
VO = pd.DataFrame(out)
VO["e_surv"] = VO.obs_surv - VO.pr_surv; VO["e_qmd"] = VO.obsQMD - VO.prQMD; VO["e_ba"] = VO.obsBAPH - VO.prBAPH
VO.to_csv(os.path.join(OUT, "B1_val23_plots.csv"), index=False)
VS = []
for (arm, grp), d in VO.assign(grp=np.where(VO.planted == 1, "planted", "natural")).groupby(["arm", "grp"]):
    d = d.copy(); o = C.summ(d); o["arm"] = arm; o["group"] = grp
    for v, a, b in (("surv", "obs_surv", "pr_surv"), ("qmd", "obsQMD", "prQMD"), ("ba", "obsBAPH", "prBAPH")):
        o[v + "_r"] = float(np.corrcoef(d[a], d[b])[0, 1]) if len(d) > 2 else np.nan
    VS.append(o)
for arm, d in VO.groupby("arm"):
    o = C.summ(d); o["arm"] = arm; o["group"] = "all23"; VS.append(o)
d = VO[(VO.planted == 0) & VO.installation_contributed]
for arm, dd in d.groupby("arm"):
    o = C.summ(dd); o["arm"] = arm; o["group"] = "natural_contributing_installations"; VS.append(o)
d = VO[(VO.planted == 0) & ~VO.installation_contributed]
for arm, dd in d.groupby("arm"):
    o = C.summ(dd); o["arm"] = arm; o["group"] = "natural_noncontributing_installations"; VS.append(o)
VS = pd.DataFrame(VS)[["group", "arm", "n_points", "n_plots", "surv_bias", "surv_rmse", "qmd_bias", "qmd_rmse", "ba_bias", "ba_rmse", "surv_r", "qmd_r", "ba_r"]]
VS.to_csv(os.path.join(OUT, "B1_val23_summary.csv"), index=False)
print(VS.round(4).to_string())
print(VO[VO.arm == "a_deployed"][["pid", "planted", "ny", "installation_contributed", "plot_contributed", "n_intervals_plot"]].to_string())
