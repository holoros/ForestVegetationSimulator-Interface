#!/usr/bin/env python3
"""repair_v103.py (koa v103, 2026-09-30). Stage A1 data repair, preregistered rules D1 and D2 (RUN.md).
Inputs : in/TREE.ALL.csv (all species, koa_verify_20260906f), in/HI_TREE.csv (FIA, koa_rv_byi_20260928), inputs/AK_TREE_v102.csv, inputs/AK_PLT.csv
Outputs: inputs/AK_TREE_v103.csv (koa tree table, v102 column set, stand columns repaired, copied visits removed, BAL definitions added),
         inputs/AK_PLT_v103.csv, out/repair/*.csv, logs/repair_v103.log
Order  : (1) dedup TREE.ALL with the v102 rulings A3 and A1' (A2' is the same keep rule) and gate its koa subset against AK_TREE_v102;
         (2) FIA all species list from HI_TREE (STATUSCD 1, DIA > 0, EXPF = TPA_UNADJ x 4 x 2.47105 per ha per subplot);
         (3) D2 scan on every source, plot and visit; copied visits (>= 90 percent identical DBH and HT) removed from both lists;
         (4) D1 stand variables per plot-year from the live all species list (partial copy tree-visits still present, the stems exist);
         (5) BAL definitions per koa tree-visit; (6) partial copy tree-visits (50 to 90 percent visits, identical trees only) removed from the koa list.
No coordinate column is read or written (asserted)."""
import pandas as pd, numpy as np, os, json
os.makedirs("out/repair", exist_ok=True); os.makedirs("logs", exist_ok=True)
log = open("logs/repair_v103.log", "w")
def P(*a):
    s = " ".join(str(x) for x in a); print(s, flush=True); log.write(s + "\n"); log.flush()
BAD = ("lat", "lon", "long", "latitude", "longitude", "x", "y")
def nc(d, n):
    b = [c for c in d.columns if c.strip().lower() in BAD]; assert not b, f"{n} has coordinate columns {b}"
K = ["Data", "Install", "Plot", "Tree", "Measure"]; V = ["Data", "Install", "Plot", "Measure"]; PK = ["Data", "Install", "Plot"]
def S(d):
    for c in ("Install", "Plot"): d[c] = d[c].astype(str)
    return d
KBA = 0.00007854
# ---------------------------------------------------------------- (1) all species list, v102 dedup rulings
a = S(pd.read_csv("in/TREE.ALL.csv", low_memory=False)); nc(a, "TREE.ALL")
t102 = S(pd.read_csv("inputs/AK_TREE_v102.csv", low_memory=False)); nc(t102, "AK_TREE_v102")
a["_rn"] = np.arange(len(a)); cols = [c for c in a.columns if c != "_rn"]
ident = a.duplicated(cols, keep="first"); a1 = a[~ident].copy()
a1["_age"] = -a1.Age.fillna(-np.inf)
ts = a1.sort_values(K + ["_age", "_rn"], ascending=[True] * 5 + [True, False], kind="mergesort")
al = ts.drop_duplicates(K, keep="first").sort_values("_rn").drop(columns=["_age"])
P("TREE.ALL rows", len(a), "| A3 identical dropped", int(ident.sum()), "| A1' doubled keys resolved", len(a1) - len(al), "| after", len(al), "| duplicate keys left", int(al.duplicated(K).any()))
g = al[al.SPP == "AK"].merge(t102, on=K, how="outer", indicator=True, suffixes=("_a", ""))
ok = (g._merge == "both").all()
for c in ["DBH", "HT", "Age", "EXPF", "BAPH", "TPH", "BAL", "BA.perc"]:
    ok &= np.isclose(g[c + "_a"].astype(float).fillna(-9), g[c].astype(float).fillna(-9)).all()
ok &= (g.Status_a == g.Status).all()
P("GATE G0 deduplicated TREE.ALL koa subset equals AK_TREE_v102 on keys, DBH, HT, Age, EXPF, Status and deposited stand columns:", "PASS" if ok else "FAIL", "| koa rows", int((al.SPP == "AK").sum()), "v102", len(t102))
assert ok
comp = al.groupby("Data").apply(lambda d: pd.Series(dict(rows=len(d), koa_rows=int((d.SPP == "AK").sum()), other_rows=int((d.SPP != "AK").sum()), species=d.SPP.nunique(),
                                                      plotyears=len(d[V].drop_duplicates()), plotyears_with_other=int(d[d.SPP != "AK"][V].drop_duplicates().shape[0])))).reset_index()
comp["single_species"] = comp.other_rows == 0
comp.to_csv("out/repair/species_composition_by_source.csv", index=False); P("species composition by source\n" + comp.to_string(index=False))
# ---------------------------------------------------------------- (2) FIA from HI_TREE
h = pd.read_csv("in/HI_TREE.csv", low_memory=False, usecols=["INVYR", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "SUBP", "TREE", "STATUSCD", "SPCD", "DIA", "HT", "TPA_UNADJ"]); nc(h, "HI_TREE")
h["Install"] = h.STATECD.astype(str) + "-" + h.UNITCD.astype(str) + "-" + h.COUNTYCD.astype(str) + "-" + h.PLOT.astype(str)
h["Plot"] = h.SUBP.astype(int).astype(str); h["Measure"] = h.INVYR.astype(int); h["Tree"] = h.TREE.astype(int)
fk = t102[t102.Data == "FIA"].copy(); fk["Tree"] = fk.Tree.astype(int)
mm = fk.merge(h, on=["Install", "Plot", "Tree", "Measure"], how="left")
map_ok = mm.SPCD.notna().all() and (mm.SPCD == 6006).all() and np.isclose(mm.DBH, mm.DIA * 2.54, atol=0.02).all() and ((mm.Status == "live") == (mm.STATUSCD == 1)).all()
P("GATE FIA mapping AK_TREE (Install = STATECD-UNITCD-COUNTYCD-PLOT, Plot = SUBP, Tree = TREE, Measure = INVYR) to HI_TREE:", "PASS" if map_ok else "FAIL",
  "| koa FIA records", len(fk), "matched", int(mm.SPCD.notna().sum()), "| SPCD", mm.SPCD.value_counts().to_dict(), "| EXPF / TPA_UNADJ", sorted((mm.EXPF / mm.TPA_UNADJ).round(3).unique().tolist()))
assert map_ok
fpy = fk[V].drop_duplicates()
hf = h.merge(fpy[["Install", "Plot", "Measure"]], on=["Install", "Plot", "Measure"])
P("FIA plot-years in AK_TREE", len(fpy), "| with HI_TREE records", len(hf[["Install", "Plot", "Measure"]].drop_duplicates()))
FIAX = 4 * 2.47105
fall = pd.DataFrame(dict(Data="FIA", Install=hf.Install, Plot=hf.Plot, Measure=hf.Measure, Tree=hf.Tree, DBH=hf.DIA * 2.54, HT=hf.HT * 0.3048,
                         SPP=np.where(hf.SPCD == 6006, "AK", "SP" + hf.SPCD.astype(int).astype(str)), EXPF=hf.TPA_UNADJ * FIAX,
                         Status=np.where(hf.STATUSCD == 1, "live", np.where(hf.STATUSCD == 2, "dead", "other"))))
# cross-check against TREE.ALL FIA (whole-plot expansion x 2.48)
tf = al[al.Data == "FIA"]; tlive = tf[(tf.Status == "live") & (tf.DBH > 0) & (tf.EXPF > 0)]
b1 = tlive.assign(ba=KBA * tlive.DBH ** 2 * tlive.EXPF * FIAX / 2.48).groupby(V[1:]).ba.sum()
fl = fall[(fall.Status == "live") & (fall.DBH > 0) & (fall.EXPF > 0)]
b2 = fl.assign(ba=KBA * fl.DBH ** 2 * fl.EXPF).groupby(V[1:]).ba.sum()
cc = pd.concat([b1.rename("treeall"), b2.rename("hitree")], axis=1)
P("FIA check: TREE.ALL live all species BAPH rescaled to the subplot expansion vs HI_TREE rebuild, plot-years", len(cc), "| max abs diff", round(float((cc.treeall - cc.hitree).abs().max()), 6))
nonfia = al[al.Data != "FIA"][["Data", "Install", "Plot", "Measure", "Tree", "DBH", "HT", "SPP", "EXPF", "Status"]]
ALL = pd.concat([nonfia, fall], ignore_index=True); ALL["Measure"] = ALL.Measure.astype(int)
# koa tree table to repair: v102, FIA EXPF set to the subplot expansion
T = t102.copy(); T["Measure"] = T.Measure.astype(int); T["EXPF_dep"] = T.EXPF
isf = T.Data == "FIA"; T.loc[isf, "EXPF"] = T.loc[isf, "EXPF"] / 2.48 * FIAX
P("FIA koa EXPF rescaled from TPA x 2.48 to TPA x 4 x 2.47105 on", int(isf.sum()), "records")
# ---------------------------------------------------------------- (3) D2 copied visit scan
def ident_eq(x, y):
    return (np.isclose(x, y, rtol=0, atol=1e-9)) | (pd.isna(x) & pd.isna(y))
rows = []; idrows = []
for (d, i, p), gg in ALL.groupby(PK):
    ms = sorted(gg.Measure.unique())
    for j in range(1, len(ms)):
        a0 = gg[(gg.Measure == ms[j - 1]) & (gg.Status == "live") & (gg.DBH > 0)]; a1_ = gg[(gg.Measure == ms[j]) & (gg.Status == "live") & (gg.DBH > 0)]
        c = a0.merge(a1_, on="Tree", suffixes=("_0", "_1"))
        if len(c) == 0: continue
        idd = np.isclose(c.DBH_0, c.DBH_1, rtol=0, atol=1e-9); idh = ident_eq(c.HT_0.values, c.HT_1.values); both = idd & idh
        rows.append(dict(Data=d, Install=i, Plot=p, Measure=ms[j], prev=ms[j - 1], n_common=len(c), n_ident_dbh=int(idd.sum()), n_ident_dbh_ht=int(both.sum()),
                         share_dbh=idd.mean(), share=both.mean(), koa_common=int((c.SPP_1 == "AK").sum())))
        for tr in c.Tree[both]: idrows.append((d, i, p, tr, ms[j]))
sc = pd.DataFrame(rows)
sc["class"] = np.where(sc.share >= 0.9, "copied", np.where(sc.share >= 0.5, "partial", "kept"))
sc.to_csv("out/repair/d2_scan_all_visits.csv", index=False)
fl_ = sc[sc["class"] != "kept"].sort_values(PK + ["Measure"]); fl_.to_csv("out/repair/d2_flagged_visits.csv", index=False)
P("D2 scan: visits with a previous visit", len(sc), "| copied (>= 0.90)", int((sc["class"] == "copied").sum()), "| partial (0.50 to 0.90)", int((sc["class"] == "partial").sum()),
  "| visits with 0 < share < 0.50", int(((sc.share > 0) & (sc.share < 0.5)).sum()))
P("D2 flagged by source and year:", fl_.groupby(["Data", "Measure", "class"]).size().to_dict())
cp = fl_[fl_["class"] == "copied"][V]; pt = fl_[fl_["class"] == "partial"][V]
idt = pd.DataFrame(idrows, columns=["Data", "Install", "Plot", "Tree", "Measure"]).merge(pt, on=V)
def drop_visits(d, vv):
    m = d.merge(vv.assign(_x=1), on=V, how="left"); return d[m._x.isna().values].copy(), int(m._x.notna().sum())
ALL, n_all_cp = drop_visits(ALL, cp); T, n_koa_cp = drop_visits(T, cp)
P("D2 copied visits removed:", len(cp), "| all species records removed", n_all_cp, "| koa records removed", n_koa_cp)
# ---------------------------------------------------------------- (4) D1 stand variables from the live all species list
L = ALL[(ALL.Status == "live") & (ALL.DBH > 0) & (ALL.EXPF > 0)].copy()
L["ba"] = KBA * L.DBH ** 2 * L.EXPF; L["sdi"] = L.EXPF * (L.DBH / 25.4) ** 1.605; L["ak"] = L.SPP == "AK"
st = L.groupby(V).agg(BAPH=("ba", "sum"), TPH=("EXPF", "sum"), SDI=("sdi", "sum"), nlive_all=("ba", "size")).reset_index()
stk = L[L.ak].groupby(V).agg(BA_AK=("ba", "sum"), nlive_koa=("ba", "size")).reset_index()
st = st.merge(stk, on=V, how="left").fillna({"BA_AK": 0.0, "nlive_koa": 0})
st["QMD"] = np.sqrt(st.BAPH / st.TPH / KBA); st["pBA_AK"] = st.BA_AK / st.BAPH
# plot-years of the koa table
py = T[V].drop_duplicates()
st2 = py.merge(st, on=V, how="left")
single = set(comp.Data[comp.single_species])
st2["repair_source"] = np.where(st2.BAPH.notna(), "all_species_live", "none")
nolive = st2.BAPH.isna()
P("koa plot-years", len(py), "| rebuilt from the live all species list", int((~nolive).sum()), "| no live stem with EXPF > 0 in the all species list", int(nolive.sum()))
dep = T.groupby(V)[["BAPH", "TPH", "QMD", "SDI", "BA.AK", "pBA.AK"]].first().reset_index().rename(columns={"BAPH": "BAPH_dep", "TPH": "TPH_dep", "QMD": "QMD_dep", "SDI": "SDI_dep", "BA.AK": "BA.AK_dep", "pBA.AK": "pBA.AK_dep"})
st2 = st2.merge(dep, on=V, how="left")
# no live stem with EXPF > 0: (a) no live stem with DBH > 0 at all (seedlings below breast height or all dead): BAPH, TPH, SDI, BA.AK = 0, QMD NA,
# since the deposited value there counts dead stems; (b) live stems with DBH > 0 but EXPF missing or 0 on every one: deposited value kept, flagged
lvd = ALL[(ALL.Status == "live") & (ALL.DBH > 0)].groupby(V).size().rename("n_live_dbh").reset_index()
st2 = st2.merge(lvd, on=V, how="left").fillna({"n_live_dbh": 0})
za = nolive & (st2.n_live_dbh == 0); fb = nolive & (st2.n_live_dbh > 0)
for c in ("BAPH", "TPH", "SDI", "BA_AK", "pBA_AK"): st2.loc[za, c] = 0.0
st2.loc[za, "QMD"] = np.nan; st2.loc[za, "repair_source"] = "zero_no_live_stem_dbh_gt0"
for c, cd in (("BAPH", "BAPH_dep"), ("TPH", "TPH_dep"), ("QMD", "QMD_dep"), ("SDI", "SDI_dep"), ("BA_AK", "BA.AK_dep"), ("pBA_AK", "pBA.AK_dep")):
    st2.loc[fb, c] = st2.loc[fb, cd]
st2.loc[fb, "repair_source"] = "deposited_kept_expf_missing"
P("no live stem with EXPF > 0:", int(nolive.sum()), "| of which no live stem with DBH > 0 (set to 0):", int(za.sum()), "by source", st2[za].groupby("Data").size().to_dict(), "deposited BAPH max on them", round(float(st2[za].BAPH_dep.max()), 3),
  "| live stems with DBH > 0 but EXPF 0 on all (deposited kept, flagged):", int(fb.sum()), st2[fb].groupby("Data").size().to_dict(), "deposited BAPH max", round(float(st2[fb].BAPH_dep.max()), 3))
lz = ALL[(ALL.Status == "live") & (ALL.DBH > 0) & ~(ALL.EXPF > 0)]
P("live stems with DBH > 0 and EXPF 0 or missing (excluded from the stand sums):", len(lz), "by source", lz.groupby("Data").size().to_dict())
st2["single_species_source"] = st2.Data.isin(single)
st2.to_csv("out/repair/plotyear_stand_before_after.csv", index=False)
# G1
kl = T[(T.Status == "live") & (T.DBH > 0) & (T.EXPF > 0)].assign(ba=lambda d: KBA * d.DBH ** 2 * d.EXPF).groupby(V).ba.sum().rename("koa_live_ba").reset_index()
g1 = st2.merge(kl, on=V, how="left"); g1s = g1[g1.single_species_source & ~fb & ~za]
d1 = (g1s.BAPH - g1s.koa_live_ba).abs().max()
P("GATE G1 single species plot-years (sources", sorted(single), ") rebuilt BAPH equals the live koa sum to 1e-6: max abs diff", d1, "over", len(g1s), "plot-years:", "PASS" if d1 <= 1e-6 else "FAIL")
assert d1 <= 1e-6
# ---------------------------------------------------------------- (5) BAL definitions per koa tree-visit, on the full visit list
T = T.merge(st2[V + ["BAPH", "TPH", "QMD", "SDI", "BA_AK", "pBA_AK", "repair_source"]].rename(columns={"BAPH": "BAPH_n", "TPH": "TPH_n", "QMD": "QMD_n", "SDI": "SDI_n"}), on=V, how="left")
T["BAL_dep"] = T.BAL; T["BA.perc_dep"] = T["BA.perc"]
for c in ("BAPH", "TPH", "QMD", "SDI"): T[c + "_depcol"] = T[c]; T[c] = T[c + "_n"]
T["BA.AK"] = T.BA_AK; T["pBA.AK"] = T.pBA_AK
T["live"] = (T.Status == "live") & (T.DBH > 0)
T = T.sort_values(["Data", "Install", "Plot", "Measure", "Tree"]).reset_index(drop=True)
T["BAd"] = T.groupby(V).DBH.transform(lambda x: (x.rank(method="min") - 1) / (len(x) - 1) if len(x) > 1 else 0 * x)
T["BA.perc"] = T.BAd
T["BALd"] = (1 - T.BAd) * T.BAPH; T["BAL"] = T.BALd
T["BALl"] = np.nan; T["BALc"] = np.nan
lv = T[T.live].copy()
lv["pl"] = lv.groupby(V).DBH.transform(lambda x: (x.rank(method="min") - 1) / (len(x) - 1) if len(x) > 1 else 0 * x)
T.loc[lv.index, "BALl"] = (1 - lv.pl) * lv.BAPH
# conventional: live all species stems strictly larger, expansion weighted
Lg = {k: (v.DBH.values, v.ba.values) for k, v in L.groupby(V)}
balc = np.full(len(T), np.nan)
for k, idx in T[T.live].groupby(V).groups.items():
    if k not in Lg: continue
    dl, ba = Lg[k]; o = np.argsort(dl); ds = dl[o]; cs = np.concatenate([[0], np.cumsum(ba[o][::-1])])[::-1]   # cs[j] = sum ba of sorted index >= j
    x = T.loc[idx, "DBH"].values; pos = np.searchsorted(ds, x, side="right"); balc[idx] = cs[pos]
T["BALc"] = balc
P("BAL definitions: live koa tree-visits", int(T.live.sum()), "| BALc NA", int(T.loc[T.live, "BALc"].isna().sum()), "| BALc > BAPH", int((T.BALc > T.BAPH + 1e-9).sum()),
  "| deposited-form percentile reproduces the deposited BA.perc on", round(100 * np.mean(np.isclose(T.BAd, T["BA.perc_dep"].astype(float))), 2), "percent of rows")
# ---------------------------------------------------------------- (6) partial copy tree-visits removed from the koa list
idt["_p"] = 1; idt["Tree"] = idt.Tree.astype(T.Tree.dtype)
m = T.merge(idt, on=K, how="left"); kp = m._p.isna().values
P("D2 partial copy visits", len(pt), "| identical tree-visits removed from the koa list", int((~kp).sum()), "of", len(idt), "flagged (all species)")
T["partial_copy_visit"] = T.merge(pt.assign(_q=1), on=V, how="left")._q.notna().values
T = T[kp].copy()
# flags
dep_cols = t102.columns.tolist()
T["stand_repaired"] = ~np.isclose(T.BAPH.astype(float), T.BAPH_depcol.astype(float), rtol=1e-6)
out = T[dep_cols + ["EXPF_dep", "BAPH_depcol", "TPH_depcol", "QMD_depcol", "SDI_depcol", "BAL_dep", "BA.perc_dep", "BALd", "BALl", "BALc", "repair_source", "partial_copy_visit", "stand_repaired"]].copy()
out = out.sort_values(["Data", "Install", "Plot", "Measure", "Tree"])
assert not out.duplicated(K).any(); nc(out, "AK_TREE_v103")
out.to_csv("inputs/AK_TREE_v103.csv", index=False)
P("AK_TREE_v103 rows", len(out), "(v102", len(t102), ") | GATE one record per (Data, Install, Plot, Tree, Measure): PASS")
# AK_PLT v103
plt = S(pd.read_csv("inputs/AK_PLT.csv", low_memory=False)); nc(plt, "AK_PLT")
p2 = plt.merge(st2[V + ["BAPH", "TPH", "QMD", "SDI", "BA_AK", "pBA_AK"]], on=V, how="left", suffixes=("_dep", ""))
cpk = p2.merge(cp.assign(_c=1), on=V, how="left")._c.notna().values
P("AK_PLT rows", len(plt), "| copied visits removed", int(cpk.sum()), "| rows without a koa tree plot-year (kept deposited)", int((p2.BAPH.isna() & ~cpk).sum()))
p2 = p2[~cpk].copy()
for c in ("BAPH", "TPH", "QMD", "SDI"): p2[c] = p2[c].fillna(p2[c + "_dep"])
p2["BA.AK"] = p2.BA_AK.fillna(p2["BA.AK"]); p2["pBA.AK"] = p2.pBA_AK.fillna(p2["pBA.AK"])
p2 = p2[plt.columns]; nc(p2, "AK_PLT_v103"); assert not p2.duplicated(V).any()
p2.to_csv("inputs/AK_PLT_v103.csv", index=False)
# ---------------------------------------------------------------- G2, G3 tables
s3 = st2[~st2.merge(cp.assign(_c=1), on=V, how="left")._c.notna().values].copy()
s3["BAPH_ratio_dep_new"] = s3.BAPH_dep / s3.BAPH
s3.to_csv("out/repair/plotyear_stand_before_after.csv", index=False)
q = s3.BAPH.quantile([0, .5, .9, .95, .99, 1]).round(3).to_dict()
P("G2 rebuilt BAPH distribution (plot-years", len(s3), "):", q, "| deposited:", s3.BAPH_dep.quantile([0, .5, .9, .95, .99, 1]).round(3).to_dict())
top = s3.sort_values("BAPH", ascending=False).head(10)[V + ["BAPH_dep", "BAPH", "TPH_dep", "TPH", "QMD", "nlive_all", "nlive_koa"]]
top.to_csv("out/repair/g2_top10_after.csv", index=False); P("G2 top 10 after\n" + top.to_string(index=False))
topd = s3.sort_values("BAPH_dep", ascending=False).head(10)[V + ["BAPH_dep", "BAPH", "TPH_dep", "TPH", "nlive_all"]]
topd.to_csv("out/repair/g2_top10_before.csv", index=False); P("G2 top 10 before\n" + topd.to_string(index=False))
g3 = []
for dsrc, d in s3.groupby("Data"):
    r = dict(Data=dsrc, plotyears=len(d), changed_gt1pct=int((~np.isclose(d.BAPH, d.BAPH_dep, rtol=0.01)).sum()))
    for c in ("BAPH", "TPH", "QMD", "SDI"):
        r[c + "_med_before"] = d[c + "_dep"].median(); r[c + "_med_after"] = d[c].median(); r[c + "_max_before"] = d[c + "_dep"].max(); r[c + "_max_after"] = d[c].max()
    g3.append(r)
g3 = pd.DataFrame(g3); g3.to_csv("out/repair/g3_before_after_by_source.csv", index=False); P("G3\n" + g3.round(2).to_string(index=False))
s3 = s3[s3.BAPH > 0].copy() if False else s3
nz = s3[(s3.BAPH > 0)]; rat = nz.BAPH_ratio_dep_new
P("deposited over rebuilt BAPH ratio: exactly 2 (1e-6)", int(np.isclose(rat, 2, atol=1e-6).sum()), "| within 1 percent of 1", int(np.isclose(rat, 1, rtol=0.01).sum()), "| off by more than 10 percent", int((~np.isclose(rat, 1, rtol=0.10)).sum()),
  "| by source (off > 10 pct)", nz[~np.isclose(rat, 1, rtol=0.10)].groupby("Data").size().to_dict(), "| plot-years with rebuilt BAPH 0", int((s3.BAPH == 0).sum()))
nrep = int((~np.isclose(s3.BAPH.fillna(-1), s3.BAPH_dep.fillna(-1), rtol=0, atol=1e-6) | ~np.isclose(s3.TPH.fillna(-1), s3.TPH_dep.fillna(-1), rtol=0, atol=1e-6)).sum())
P("plot-years whose BAPH or TPH changed (1e-6):", nrep, "of", len(s3), "| BAPH ratio deposited/rebuilt in 1.9 to 2.1:", int(((rat > 1.9) & (rat < 2.1)).sum()), "| above 1.1:", int((rat > 1.1).sum()), "| below 0.9:", int((rat < 0.9).sum()))
json.dump(dict(n_changed=nrep, copied=len(cp), partial=len(pt), plotyears=len(s3), fallback=int(fb.sum()), single_species=sorted(single)), open("out/repair/summary.json", "w"))
P("DONE repair_v103.py")
