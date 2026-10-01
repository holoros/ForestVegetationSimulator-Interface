#!/usr/bin/env python3
"""post_frames_v103.py. (A) builder reproduction gate on the v102 inputs; (B) v103 frames: BAL definition columns, deposited BAPH, removal screen,
static height frame and height tree_join, repaired plot_intervals (Stage 1), ingrowth frame, FIA crown (HCB) frame with HI_TREE covariates;
(C) uniqueness gates; (D) G4. No coordinate column is read or written (asserted)."""
import pandas as pd, numpy as np, os, json
os.chdir(os.path.expanduser("~/jobs/koa_v103_20260930")); os.makedirs("frames/final", exist_ok=True); os.makedirs("out/frames", exist_ok=True)
V2 = os.path.expanduser("~/jobs/koa_v102_20260918/")
log = open("logs/post_frames_v103.log", "w")
def P(*a):
    s = " ".join(str(x) for x in a); print(s, flush=True); log.write(s + "\n"); log.flush()
BAD = ("lat", "lon", "long", "latitude", "longitude", "x", "y")
def nc(d, n):
    b = [c for c in d.columns if c.strip().lower() in BAD]; assert not b, f"{n} has coordinate columns {b}"
def S(d, cols=("Install", "Plot")):
    for c in cols:
        if c in d.columns: d[c] = d[c].astype(str)
    return d
GATES = []
def gate(d, key, label):
    dup = d.duplicated(key, keep=False); ok = not dup.any(); GATES.append(dict(frame=label, rows=len(d), key=",".join(key), gate="PASS" if ok else "FAIL", offending=int(d[dup].groupby(key).ngroups) if not ok else 0))
    P(f"GATE {label} one row per ({', '.join(key)}): {'PASS' if ok else 'FAIL'} rows {len(d)}"); return ok
IK = ["Data", "Install", "Plot", "Tree", "t.0", "t.1"]; SK = ["source", "inst", "plot", "tree", "t0", "t1"]; V = ["Data", "Install", "Plot", "Measure"]; K = V[:3] + ["Tree", "Measure"]
# ---------------------------------------------------------------- (A) reproduction of the v102 frames by the builder chain
def same(a, b, key):
    a = a.sort_values(key).reset_index(drop=True); b = b.sort_values(key).reset_index(drop=True)
    if a.shape != b.shape or list(a.columns) != list(b.columns): return False, f"shape {a.shape} vs {b.shape}"
    bad = []
    for c in a.columns:
        x, y = a[c], b[c]
        if x.dtype == object or y.dtype == object: eq = (x.astype(str) == y.astype(str)).all()
        else: eq = np.allclose(x.astype(float).fillna(-9e9), y.astype(float).fillna(-9e9), rtol=1e-9, atol=1e-9)
        if not eq: bad.append(c)
    return len(bad) == 0, bad
rep = []
for mine, theirs, key in (("frames/v102/dDBH_v102.csv", V2 + "frames/dDBH_v102.csv", IK), ("frames/v102/dHT_v102.csv", V2 + "frames/dHT_v102.csv", IK), ("frames/v102/AK_SURV_v102.csv", V2 + "frames/AK_SURV_v102.csv", IK),
                          ("frames/v102/surv_baseline_rebuilt_origin_2026-09-16_DATA.csv", V2 + "frames/surv_baseline_rebuilt_v102.csv", SK), ("frames/v102/surv_recovered_ii_origin_2026-09-16_DATA.csv", V2 + "frames/surv_recovered_ii_v102.csv", SK),
                          ("frames/v102/surv_recovered_i_origin_2026-09-16_DATA.csv", V2 + "frames/surv_recovered_i_v102.csv", SK), ("frames/v102/plot_interval_pairs_DATA_v102.csv", V2 + "frames/plot_interval_pairs_DATA_v102.csv", ["key", "m0", "m1"])):
    a = S(pd.read_csv(mine, low_memory=False), ("Install", "Plot", "inst", "plot")); b = S(pd.read_csv(theirs, low_memory=False), ("Install", "Plot", "inst", "plot"))
    ok, why = same(a, b, key); rep.append(dict(frame=os.path.basename(theirs), rows_rebuilt=len(a), rows_v102=len(b), identical=ok, detail=str(why) if not ok else ""))
    P("REPRODUCTION", os.path.basename(theirs), "rebuilt", len(a), "v102", len(b), "identical on every cell:", "PASS" if ok else f"FAIL {why}")
pd.DataFrame(rep).to_csv("out/frames/builder_reproduction_v102.csv", index=False)
assert all(r["identical"] for r in rep)
# ---------------------------------------------------------------- (B) v103
T = S(pd.read_csv("inputs/AK_TREE_v103.csv", low_memory=False)); nc(T, "AK_TREE_v103")
T["tkey"] = T.Data + "|" + T.Install + "|" + T.Plot + "|" + T.Tree.astype(str) + "|" + T.Measure.astype(str)
TI = T.set_index("tkey")
ORT = pd.read_csv("inputs/psp_origin_thinning_2026-09-16_DATA.csv")
rem = {}
for _, r in ORT.iterrows():
    ys = [r.Thin_Yr] + [float(x) for x in str(r.removal_t1_years).split(";") if x not in ("nan", "")]
    ys = sorted(set(int(y) for y in ys if pd.notna(y)))
    if ys: rem[str(r.Install)] = ys
P("removal years (Thin_Yr and removal_t1_years):", sum(len(v) for v in rem.values()), "install-years over", len(rem), "PSP installations")
def spans(d, i, t0, t1): return d == "PSP" and str(i) in rem and any(t0 < y < t1 for y in rem[str(i)])
def add_bal(d, dc, ic, pc, tc, t0c, t1c=None):
    for end, tcol in (("0", t0c), ("1", t1c)):
        if tcol is None: continue
        k = d[dc].astype(str) + "|" + d[ic].astype(str) + "|" + d[pc].astype(str) + "|" + d[tc].astype(str) + "|" + d[tcol].astype(int).astype(str)
        miss = ~k.isin(TI.index)
        assert not miss.any(), f"{miss.sum()} unmatched tree-visits"
        for c in ("BALd", "BALl", "BALc", "BAPH_depcol", "BAL_dep"): d[f"{c}.{end}"] = TI.loc[k, c].values
    return d
CS = {}
for resp in ("dDBH", "dHT"):
    d = S(pd.read_csv(f"frames/v103/{resp}_v103.csv", low_memory=False)); nc(d, resp)
    d = add_bal(d, "Data", "Install", "Plot", "Tree", "t.0", "t.1")
    d["spans_removal"] = [spans(a, b, c, e) for a, b, c, e in zip(d.Data, d.Install, d["t.0"], d["t.1"])]
    n0 = len(d); d = d[~d.spans_removal].copy()
    P(resp, "CS v103 rows from the builder", n0, "| dropped by the removal screen", n0 - len(d), "| kept", len(d))
    d.to_csv(f"frames/final/{resp}_CS_v103.csv", index=False); gate(d, IK, f"{resp}_CS_v103"); CS[resp] = d
S_OUT = {}
for nm in ("surv_baseline_rebuilt", "surv_recovered_ii", "surv_recovered_i"):
    d = S(pd.read_csv(f"frames/v103/{nm}_origin_2026-09-16_DATA.csv", low_memory=False), ("inst", "plot")); nc(d, nm)
    d = add_bal(d, "source", "inst", "plot", "tree", "t0", None)
    d["spans_removal"] = [spans(a, b, c, e) for a, b, c, e in zip(d.source, d.inst, d.t0, d.t1)]
    n0 = len(d); d = d[~d.spans_removal].copy()
    P(nm, "v103 rows", n0, "| removal screen dropped", n0 - len(d), "| kept", len(d), "deaths", int((d.alive == 0).sum()))
    d.to_csv(f"frames/final/{nm}_v103.csv", index=False); gate(d, SK, f"{nm}_v103"); S_OUT[nm] = d
a = S(pd.read_csv("frames/v103/AK_SURV_v103.csv", low_memory=False)); a["spans_removal"] = [spans(x, y, z, w) for x, y, z, w in zip(a.Data, a.Install, a["t.0"], a["t.1"])]
a = a[~a.spans_removal]; a.to_csv("frames/final/AK_SURV_v103.csv", index=False); gate(a, IK, "AK_SURV_v103")
pr = pd.read_csv("frames/v103/plot_interval_pairs_DATA_v103.csv"); pr.to_csv("frames/final/plot_interval_pairs_DATA_v103.csv", index=False); gate(pr, ["key", "m0", "m1"], "plot_interval_pairs_DATA_v103")
# static height frame and height fitting input
h1 = T[(T.Status == "live") & (T.DBH > 0) & (T.HT > 0) & T.BAPH.notna()]
h1 = h1.drop(columns=[c for c in ("KeyDupFlag", "StatusConflictFlag", "tkey") if c in h1.columns]); h1.to_csv("frames/final/static_height_frame_v103.csv", index=False); gate(h1, K, "static_height_frame_v103")
geo = pd.read_csv(os.path.expanduser("~/jobs/koa_origin_20260916/output/engine_joint/AK_PLT_GEO.csv"), usecols=["Data", "Install", "Plot", "BYI"]); nc(geo, "AK_PLT_GEO(usecols)")
geo = S(geo).drop_duplicates(["Data", "Install", "Plot"])
tj0 = pd.read_csv(os.path.expanduser("~/jobs/koa_redteam_20260916/derived/tree_join.csv"))
org = tj0[["source", "inst", "plot", "planted", "Origin"]].copy(); org.columns = ["Data", "Install", "Plot", "planted", "Origin"]; org = S(org).drop_duplicates(["Data", "Install", "Plot"])
m = T.merge(geo, on=["Data", "Install", "Plot"], how="left").merge(org, on=["Data", "Install", "Plot"], how="left"); assert len(m) == len(T)
tj = pd.DataFrame(dict(source=m.Data, inst=m.Install, plot=m.Plot, year=m.Measure, tree=m.Tree, dbh=m.DBH, ht=m.HT, expf=m.EXPF, status=m.Status, baph=m.BAPH, bal=m.BAL, baperc=m["BA.perc"],
                       byi=m.BYI, planted=m.planted, rht=m.rHT, KeyDupFlag=m.KeyDupFlag, StatusConflictFlag=m.StatusConflictFlag, Origin=m.Origin))
nc(tj, "tree_join_v103"); tj.to_csv("frames/final/tree_join_v103.csv", index=False)
P("height tree_join v103 rows", len(tj), "| byi missing", int(tj.byi.isna().sum()))
# ---------------------------------------------------------------- plot_intervals (Stage 1) repair
plt_new = S(pd.read_csv("inputs/AK_PLT_v103.csv")); plt_old = S(pd.read_csv("inputs/AK_PLT.csv"))
st = S(pd.read_csv("out/repair/plotyear_stand_before_after.csv"))
cp = S(pd.read_csv("out/repair/d2_flagged_visits.csv")); cp = cp[cp["class"] == "copied"]
cpset = set(zip(cp.Data, cp.Install, cp.Plot, cp.Measure))
def repair_pi(pi, name):
    pi = S(pi.copy()); n0 = len(pi)
    s = st.rename(columns={"Measure": "m_from"})[["Data", "Install", "Plot", "m_from", "BAPH", "BAPH_dep", "TPH", "TPH_dep", "QMD", "QMD_dep"]]
    pi = pi.merge(s, on=["Data", "Install", "Plot", "m_from"], how="left")
    # sdi of this table is TPH x (QMD/25)^1.605 at m_from (verified on the deposited values); recomputed on the repaired TPH, QMD where the
    # deposited table value matches that form, otherwise scaled by the repaired/deposited ratio of the same form
    f_dep = pi.TPH_dep * (pi.QMD_dep / 25) ** 1.605; f_new = pi.TPH * (pi.QMD.fillna(0) / 25) ** 1.605
    match = np.isclose(pi.sdi, f_dep, rtol=1e-6)
    pi["sdi_dep"] = pi.sdi; pi["baph_alive_dep"] = pi.baph_alive; pi["qmd_dep"] = pi.qmd
    pi.loc[match, "sdi"] = f_new[match]
    sc = np.where(f_dep > 0, f_new / f_dep, 1.0); pi.loc[~match & pi.BAPH.notna(), "sdi"] = (pi.sdi * sc)[~match & pi.BAPH.notna()]
    P(name, "sdi form TPH x (QMD/25)^1.605 matches the deposited column on", int(match.sum()), "of", n0, "rows; others scaled")
    # merge intervals around a copied visit
    drop = []; add = []
    for (d, i, p, mv) in cpset:
        a_ = pi[(pi.Data == d) & (pi.Install == i) & (pi.Plot == p) & (pi.m_to == mv)]; b_ = pi[(pi.Data == d) & (pi.Install == i) & (pi.Plot == p) & (pi.m_from == mv)]
        if len(a_) == 1 and len(b_) == 1:
            r = a_.iloc[0].copy(); rb = b_.iloc[0]
            r["m_to"] = rb.m_to; r["yip"] = r.yip + rb.yip; r["n_died"] = r.n_died + rb.n_died; r["expf_died"] = r.expf_died + rb.expf_died; r["ba_died"] = r.ba_died + rb.ba_died
            r["m_ann"] = 1 - (1 - r.expf_died / r.expf_alive) ** (1 / r.yip) if r.expf_alive > 0 else 0.0; r["ba_ann"] = r.ba_died / r.yip; r["any_mort"] = bool(r.n_died > 0)
            if "removal" in r.index: r["removal"] = bool(r.removal or rb.removal)
            drop += [a_.index[0], b_.index[0]]; add.append(r)
        elif len(a_) + len(b_) > 0:
            drop += list(a_.index) + list(b_.index)
    pi = pd.concat([pi.drop(index=drop), pd.DataFrame(add)], ignore_index=True)
    P(name, "rows", n0, "| rows touching a copied visit removed", len(drop), "| merged intervals added", len(add), "| rows now", len(pi),
      "| rows whose sdi changed by more than 5 percent", int((~np.isclose(pi.sdi, pi.sdi_dep, rtol=0.05)).sum()))
    return pi.drop(columns=["BAPH", "BAPH_dep", "TPH", "TPH_dep", "QMD", "QMD_dep"])
for nm, f in (("plot_intervals", V2 + "frames/plot_intervals_v102_keydedup.csv"), ("plot_intervals_origin", V2 + "frames/plot_intervals_origin_v102_keydedup.csv")):
    pi = repair_pi(pd.read_csv(f), nm); nc(pi, nm); pi.to_csv(f"frames/final/{nm}_v103.csv", index=False); gate(pi, ["Data", "Install", "Plot", "m_from", "m_to"], f"{nm}_v103")
# ---------------------------------------------------------------- ingrowth frame
ig = pd.read_csv(V2 + "frames/koa_ingrowth_byi_obs_v102_keydedup.csv"); ii = pd.read_csv(V2 + "out/ingrowth_inferred_intervals.csv")
assert len(ig) == len(ii) and (ig.key.values == ii.key.values).all() and np.allclose(ig.yrs, ii.yrs)
ig["m_from"] = ii.m_from.values; ig["m_to"] = ii.m_to.values; kk = ig.key.str.split("|", expand=True); ig["Data"] = kk[0]; ig["Install"] = kk[1]; ig["Plot"] = kk[2]
ig["BAPH_dep"] = ig.BAPH; ig["SDI_dep"] = ig.SDI; ig["RD_dep"] = ig.RD; ig["pBA_dep"] = ig.pBA
pn = plt_new.rename(columns={"Measure": "m_from"})[["Data", "Install", "Plot", "m_from", "BAPH", "SDI", "pBA.AK"]].rename(columns={"BAPH": "BAPH_n", "SDI": "SDI_n", "pBA.AK": "pBA_n"})
ig = ig.merge(pn, on=["Data", "Install", "Plot", "m_from"], how="left")
okm = ig.BAPH_n.notna()
ig.loc[okm, "BAPH"] = ig.BAPH_n[okm]; ig.loc[okm, "SDI"] = ig.SDI_n[okm]; ig.loc[okm, "RD"] = ig.SDI_n[okm] / 500; ig.loc[okm, "pBA"] = ig.pBA_n[okm]
ig["covariates_repaired"] = okm
drop = []; add = []
for (d, i, p, mv) in cpset:
    a_ = ig[(ig.Data == d) & (ig.Install == i) & (ig.Plot == p) & (ig.m_to == mv)]; b_ = ig[(ig.Data == d) & (ig.Install == i) & (ig.Plot == p) & (ig.m_from == mv)]
    if len(a_) == 1 and len(b_) == 1:
        r = a_.iloc[0].copy(); rb = b_.iloc[0]; tot = r.ing_tph * r.yrs + rb.ing_tph * rb.yrs
        r["n_new"] = r.n_new + rb.n_new; r["yrs"] = r.yrs + rb.yrs; r["ing_tph"] = tot / r.yrs; r["m_to"] = rb.m_to; drop += [a_.index[0], b_.index[0]]; add.append(r)
    elif len(a_) + len(b_): drop += list(a_.index) + list(b_.index)
ig = pd.concat([ig.drop(index=drop), pd.DataFrame(add)], ignore_index=True)
rd_def = lambda x: np.where(x < 0.3, "RD<.3", np.where(x <= 0.6, "RD.3-.6", "RD>.6"))
P("ingrowth v103: rows", len(ig), "| covariates repaired at the inferred start visit", int(ig.covariates_repaired.sum()), "| kept deposited (no inferred start visit)", int((~ig.covariates_repaired).sum()),
  "| rows touching a copied visit removed", len(drop), "merged added", len(add), "| RD changed > 5 percent", int((~np.isclose(ig.RD, ig.RD_dep, rtol=0.05)).sum()))
igo = ig[["key", "planted", "yrs", "n_new", "ing_tph", "BAPH", "SDI", "RD", "BYI", "pBA", "rb", "bb", "m_from", "m_to", "BAPH_dep", "SDI_dep", "RD_dep", "covariates_repaired"]]
nc(igo, "ingrowth"); igo.to_csv("frames/final/koa_ingrowth_byi_obs_v103.csv", index=False)
gate(igo[igo.m_from.notna()], ["key", "m_from", "yrs"], "koa_ingrowth_byi_obs_v103 (rows with an inferred interval)")
# ---------------------------------------------------------------- FIA crown frame (Eq. 3) with covariates from HI_TREE
hc = S(pd.read_csv(V2 + "frames/AK_HCB_v102_keydedup.csv")); nc(hc, "AK_HCB")
hi = pd.read_csv("in/HI_TREE.csv", low_memory=False, usecols=["INVYR", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "SUBP", "TREE", "STATUSCD", "SPCD", "DIA", "HT", "TPA_UNADJ"])
hi["Install"] = hi.STATECD.astype(str) + "-" + hi.UNITCD.astype(str) + "-" + hi.COUNTYCD.astype(str) + "-" + hi.PLOT.astype(str); hi["Plot"] = hi.SUBP.astype(int).astype(str)
hi["DBH"] = hi.DIA * 2.54; hi["EXPF"] = hi.TPA_UNADJ * 4 * 2.47105; hi["ba"] = 0.00007854 * hi.DBH ** 2 * hi.EXPF
hl = hi[(hi.STATUSCD == 1) & (hi.DBH > 0) & (hi.EXPF > 0)]
hc["Tree_i"] = hc.Tree.astype(int)
cand = hc.merge(hl[["Install", "Plot", "TREE", "INVYR", "DBH", "SPCD"]].rename(columns={"TREE": "Tree_i", "DBH": "DBH_hi"}), on=["Install", "Plot", "Tree_i"], how="left")
cand["dd"] = (cand.DBH - cand.DBH_hi).abs(); cand["dy"] = (cand.Year - cand.INVYR).abs()
cand = cand.sort_values(["dd", "dy"]).drop_duplicates(["Data", "Install", "Plot", "Tree", "Year", "Month"])
good = cand.dd < 0.05
P("HCB frame rows", len(hc), "| matched to a live HI_TREE record with equal DBH (0.05 cm)", int(good.sum()), "| INVYR - Year", cand[good].assign(z=cand.INVYR - cand.Year).z.value_counts().to_dict(), "| SPCD", cand[good].SPCD.value_counts().to_dict())
hc2 = cand[good].copy()
stand = hl.groupby(["Install", "Plot", "INVYR"]).agg(BAPH_hi=("ba", "sum"), TPH_hi=("EXPF", "sum")).reset_index()
hc2 = hc2.merge(stand, on=["Install", "Plot", "INVYR"], how="left")
# BAL under the three definitions on the all species live subplot list (d and l from the koa list of the subplot, as the tree table defines them)
def bal3(r):
    g = hl[(hl.Install == r.Install) & (hl.Plot == r.Plot) & (hl.INVYR == r.INVYR)]
    c = g.ba[g.DBH > r.DBH_hi + 1e-9].sum()
    k = T[(T.Data == "FIA") & (T.Install == r.Install) & (T.Plot == r.Plot) & (T.Measure == r.INVYR)]
    kd = k.DBH.values; kl = k.DBH[(k.Status == "live") & (k.DBH > 0)].values
    pd_ = (np.sum(kd < r.DBH_hi - 1e-9)) / (len(kd) - 1) if len(kd) > 1 else 0.0
    pl_ = (np.sum(kl < r.DBH_hi - 1e-9)) / (len(kl) - 1) if len(kl) > 1 else 0.0
    return pd.Series(dict(BALc=c, BALd=(1 - pd_) * r.BAPH_hi, BALl=(1 - pl_) * r.BAPH_hi, n_koa_visit=len(kd)))
hc2 = pd.concat([hc2.reset_index(drop=True), hc2.apply(bal3, axis=1).reset_index(drop=True)], axis=1)
hc2["in_tree_table"] = hc2.n_koa_visit > 0
out = hc2[["Data", "Install", "Plot", "Tree", "Year", "Month", "INVYR", "DBH", "HT", "HCB", "BYI", "BAPH", "BAL", "BAPH_hi", "TPH_hi", "BALd", "BALl", "BALc", "in_tree_table", "Origin"]].rename(columns={"BAPH": "BAPH_dep", "BAL": "BAL_dep"})
nc(out, "AK_HCB_v103"); out.to_csv("frames/final/AK_HCB_v103.csv", index=False); gate(out, ["Data", "Install", "Plot", "Tree", "Year", "Month"], "AK_HCB_v103")
P("HCB v103: rows", len(out), "| trees whose subplot-year is in the koa tree table", int(out.in_tree_table.sum()), "| BAPH_hi vs deposited frame BAPH median ratio", round(float((out.BAPH_hi / out.BAPH_dep).median()), 3))
# ---------------------------------------------------------------- G4
def g4(new, old, key, cols, label):
    m = new.merge(old, on=key, suffixes=("", "_v102"))
    ch = np.zeros(len(m), bool); per = {}
    for c in cols:
        a, b = m[c].astype(float), m[c + "_v102"].astype(float)
        x = ~np.isclose(a, b, rtol=0.05, atol=1e-9) & (a.notna() | b.notna()); per[c] = int(x.sum()); ch |= x.values
    r = dict(frame=label, rows_v103=len(new), rows_v102=len(old), common_keys=len(m), rows_v103_not_in_v102=len(new) - len(m), changed_gt5pct_any=int(ch.sum()), share_changed=round(ch.mean(), 4), **{f"changed_{k}": v for k, v in per.items()})
    P("G4", label, r); return r
G = []
for resp in ("dDBH", "dHT"):
    o = S(pd.read_csv(V2 + f"frames/{resp}_v102.csv", low_memory=False))
    G.append(g4(CS[resp], o, IK, ["BAPH.0", "BAPH.1", "BAL.0", "BAL.1", "CR.0", "CR.1"], f"{resp} CS"))
o = S(pd.read_csv(V2 + "frames/surv_baseline_rebuilt_v102.csv"), ("inst", "plot")); G.append(g4(S_OUT["surv_baseline_rebuilt"], o, SK, ["baph", "bal", "cr", "sdi", "qmd"], "survival baseline (Eq5)"))
o = S(pd.read_csv(V2 + "frames/surv_recovered_ii_v102.csv"), ("inst", "plot")); G.append(g4(S_OUT["surv_recovered_ii"], o, SK, ["baph", "bal", "cr", "sdi", "qmd"], "survival recovered ii (Eq5a)"))
o = S(pd.read_csv(V2 + "frames/static_height_frame_v102.csv", low_memory=False)); G.append(g4(h1, o, K, ["BAPH"], "static height"))
o = pd.read_csv(V2 + "frames/plot_interval_pairs_DATA_v102.csv"); G.append(g4(pr, o, ["key", "m0", "m1"], ["SDI0", "QMD0", "BAPH0", "H40_0"], "M1 pairs"))
pd.DataFrame(G).to_csv("out/frames/g4_covariate_change.csv", index=False); pd.DataFrame(GATES).to_csv("out/frames/uniqueness_gates.csv", index=False)
P("ALL UNIQUENESS GATES", "PASS" if all(g["gate"] == "PASS" for g in GATES) else "FAIL", len(GATES))
P("DONE post_frames_v103.py")
