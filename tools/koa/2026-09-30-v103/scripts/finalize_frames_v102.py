#!/usr/bin/env python3
"""finalize_frames.py (koa v102). Static height frame rebuild, AK_HCB key check, ingrowth interval inference through
AK_PLT.csv, reproduction check of the M1 pair table, rebuilt versus key deduplicated comparison, conflict visit impact
per frame, and the frame table for TRACK1_REPORT.md. Writes out/frame_table.csv, out/conflict_impact.csv,
out/dup_check_more.csv, logs/finalize_frames.log."""
import pandas as pd, numpy as np, os
log = open("logs/finalize_frames.log", "w")
def P(*a):
    s = " ".join(str(x) for x in a); print(s); log.write(s + "\n")
def S(d):
    for c in ("Install", "Plot"):
        if c in d.columns: d[c] = d[c].astype(str)
    return d
K = ["Data", "Install", "Plot", "Tree", "Measure"]; V = ["Data", "Install", "Plot", "Measure"]
IK = ["Data", "Install", "Plot", "Tree", "t.0", "t.1"]
t0 = S(pd.read_csv("inputs/AK_TREE_record.csv", low_memory=False)); t1 = S(pd.read_csv("inputs/AK_TREE_v102.csv", low_memory=False))
dv = t0[t0.duplicated(K, keep=False)][V].drop_duplicates(); dv["_dbl"] = 1
conf = S(pd.read_csv("out/conflict_visits.csv"))[V].assign(_conf=1)
def gate(d, key, label):
    dup = d.duplicated(key, keep=False); ok = not dup.any()
    P(f"GATE {label} one row per ({', '.join(key)}):", "PASS" if ok else "FAIL", "| offending keys", int(d[dup].groupby(key).ngroups) if not ok else 0)
    return "PASS" if ok else f"FAIL ({int(d[dup].groupby(key).ngroups)} keys)"
# ---- static height frame, koa_modeling_subset_filter.R lines 7 to 12 (deposit builder), on record and v102 tree tables
def htframe(t): return t[(t.Status == "live") & (t.DBH > 0) & (t.HT > 0) & t.BAPH.notna()].drop(columns=[c for c in ("KeyDupFlag", "StatusConflictFlag") if c in t.columns])
h0, h1 = htframe(t0), htframe(t1)
h0.to_csv("out/reproduce/static_height_frame_record.csv", index=False); h1.to_csv("frames/static_height_frame_v102.csv", index=False)
P("static height frame: record tree table", len(h0), "| v102 tree table", len(h1), "| assembled (live, DBH > 0) record", int(((t0.Status == "live") & (t0.DBH > 0)).sum()), "v102", int(((t1.Status == "live") & (t1.DBH > 0)).sum()))
g_ht = gate(h1, K, "static_height_frame_v102")
# ---- AK_HCB, natural key includes Year and Month (Measure is 1 on every FIA crown record)
hcb = S(pd.read_csv("inputs/AK_HCB_record.csv", low_memory=False))
HK = ["Data", "Install", "Plot", "Tree", "Year", "Month"]
P("AK_HCB rows", len(hcb), "| Measure values", hcb.Measure.unique().tolist(), "| distinct (tree, Year, Month)", len(hcb.drop_duplicates(HK)), "| identical rows", int(hcb.duplicated(keep=False).sum()),
  "| trees with two crown years", int((hcb.groupby(K[:4]).Year.nunique() > 1).sum()), "| on doubled visits", int(hcb.merge(dv.rename(columns={"Measure": "Year"}), on=["Data", "Install", "Plot", "Year"], how="left")._dbl.notna().sum()))
hcb1 = hcb[~hcb.duplicated(HK, keep="first")]; hcb1.to_csv("frames/AK_HCB_v102_keydedup.csv", index=False)
g_hcb = gate(hcb1, HK, "AK_HCB_v102_keydedup"); P("AK_HCB key dedup removed", len(hcb) - len(hcb1), "rows (none expected)")
# ---- ingrowth frame, infer the start Measure by matching (plot, BAPH, SDI) to AK_PLT.csv plot measure rows
ig = pd.read_csv("inputs/koa_ingrowth_byi_obs_record.csv"); kk = ig.key.str.split("|", expand=True); ig["Data"] = kk[0]; ig["Install"] = kk[1]; ig["Plot"] = kk[2]
plt = S(pd.read_csv("inputs/AK_PLT.csv", low_memory=False))
ig["_i"] = np.arange(len(ig))
m = ig.merge(plt[["Data", "Install", "Plot", "Measure", "BAPH", "SDI"]], on=["Data", "Install", "Plot"], suffixes=("", "_plt"))
m = m[np.isclose(m.BAPH, m.BAPH_plt, rtol=1e-6) & np.isclose(m.SDI, m.SDI_plt, rtol=1e-6)]
nmatch = m.groupby("_i").Measure.nunique()
P("ingrowth rows", len(ig), "| start Measure identified through AK_PLT (BAPH, SDI match): unique", int((nmatch == 1).sum()), "| ambiguous", int((nmatch > 1).sum()), "| unmatched", int(len(ig) - nmatch.shape[0]))
mm = m[m._i.isin(nmatch[nmatch == 1].index)].drop_duplicates("_i")[["_i", "Measure"]].rename(columns={"Measure": "m_from"})
ig = ig.merge(mm, on="_i", how="left"); ig["m_to"] = ig.m_from + ig.yrs
pmset = set(map(tuple, t0[V].drop_duplicates().itertuples(index=False)))
ig["_end_exists"] = [((d, i, p, int(e)) in pmset) if pd.notna(e) else False for d, i, p, e in zip(ig.Data, ig.Install, ig.Plot, ig.m_to)]
P("ingrowth inferred end Measure exists in AK_TREE for", int(ig._end_exists.sum()), "of", int(ig.m_from.notna().sum()), "identified rows")
s = ig.merge(dv.rename(columns={"Measure": "m_from", "_dbl": "_s"}), on=["Data", "Install", "Plot", "m_from"], how="left").merge(dv.rename(columns={"Measure": "m_to", "_dbl": "_e"}), on=["Data", "Install", "Plot", "m_to"], how="left")
a_s, a_e = s._s.notna(), s._e.notna(); aff = a_s | a_e
IGK = ["key", "m_from", "yrs"]
dupk = ig.duplicated(IGK, keep=False) & ig.m_from.notna(); ident = ig.drop(columns=["_i", "m_from", "m_to", "_end_exists", "Data", "Install", "Plot"]).duplicated(keep=False)
P("ingrowth: rows starting on a doubled visit", int(a_s.sum()), "| ending on one", int(a_e.sum()), "| affected", int(aff.sum()), f"({100*aff.sum()/len(ig):.1f}% of 363, {100*(aff & (s.Data=='PSP')).sum()/max((s.Data=='PSP').sum(),1):.1f}% of {int((s.Data=='PSP').sum())} PSP rows)",
  "| duplicated (key, m_from, yrs)", int(dupk.sum()), "rows in", int(ig[dupk].groupby(IGK).ngroups), "keys | literal identical rows on the 12 columns", int(ident.sum()), "| identical rows on doubled visits", int((ident & aff).sum()))
P("ingrowth identical rows by plot (counts only)", ig[ident].groupby("key").size().to_dict())
ig1 = ig[~ident | ~ig.duplicated(keep="first")].copy()
ig1 = ig1[~ig1.drop(columns=["_i"]).duplicated(keep="first")]
ig1 = ig1[~(ig1.duplicated(IGK, keep="first") & ig1.m_from.notna())]
ig1[["key", "planted", "yrs", "n_new", "ing_tph", "BAPH", "SDI", "RD", "BYI", "pBA", "rb", "bb"]].to_csv("frames/koa_ingrowth_byi_obs_v102_keydedup.csv", index=False)
ig1[["key", "m_from", "m_to", "yrs"]].to_csv("out/ingrowth_inferred_intervals.csv", index=False)
g_ig = gate(ig1[ig1.m_from.notna()], IGK, "koa_ingrowth_byi_obs_v102_keydedup (rows with an identified interval)")
P("ingrowth v102 key dedup rows", len(ig1), "(record 363), this is a key based dedup, NOT a rebuild, the builder is not on firebreather")
# ---- M1 pair table reproduction and v102
pr = pd.read_csv("inputs/plot_interval_pairs_DATA_record.csv"); pa = pd.read_csv("out/reproduce/plot_interval_pairs_DATA_record_rebuilt.csv"); pv = pd.read_csv("frames/plot_interval_pairs_DATA_v102.csv")
PK = ["key", "m0", "m1"]
mm = pr.merge(pa, on=PK, suffixes=("_r", "_a")); num = [c for c in ("ntree", "N0", "N1", "ndead", "ndead_meas", "n_absent", "SDI0", "QMD0", "BAPH0", "planted", "mort_ann")]
P("M1 pair table reproduction: record", len(pr), "rebuilt", len(pa), "matched keys", len(mm), "| max abs diff over numeric columns", max(float((mm[c + "_r"].fillna(-9) - mm[c + "_a"].fillna(-9)).abs().max()) for c in num))
P("M1 pair table v102 rows", len(pv), "| ntree", int(pv.ntree.sum()), "record", int(pr.ntree.sum()), "| ndead", int(pv.ndead.sum()), "record", int(pr.ndead.sum()), "| intervals lost", sorted(set(map(tuple, pr[PK].itertuples(index=False))) - set(map(tuple, pv[PK].itertuples(index=False)))))
g_pairs = gate(pv, PK, "plot_interval_pairs_DATA_v102")
# ---- rebuilt increment and survival frames versus key based dedup of the record (dedup.py rule, DEDUP_FIRST)
def keydedup_first(d):
    d = d.copy(); d["_rn"] = np.arange(len(d)); dup = d.duplicated(IK, keep=False); g = d[dup].groupby(IK, sort=False)
    a0 = g["Age.0"].transform(lambda x: x.max() - x.min()); a1 = g["Age.1"].transform(lambda x: x.max() - x.min())
    d["_age_end"] = 0.0; d.loc[dup, "_age_end"] = np.where(a0 > 0, d.loc[dup, "Age.0"], np.where(a1 > 0, d.loc[dup, "Age.1"], 0.0))
    return d.sort_values(IK + ["_age_end", "_rn"], kind="mergesort").drop_duplicates(IK, keep="first").sort_values("_rn").drop(columns=["_rn", "_age_end"])
rows = []; impact = []
for nm, rec, v102, fkey in (("dDBH.csv", "inputs/dDBH_record.csv", "frames/dDBH_v102.csv", IK), ("dHT.csv", "inputs/dHT_record.csv", "frames/dHT_v102.csv", IK), ("AK_SURV.csv", "inputs/AK_SURV_record.csv", "frames/AK_SURV_v102.csv", IK)):
    r = S(pd.read_csv(rec, low_memory=False)); v = S(pd.read_csv(v102, low_memory=False)); kd = keydedup_first(r)
    kd.to_csv(f"out/{nm.replace('.csv','')}_record_keydedup_first.csv", index=False)
    kr, kv, kk_ = [set(map(tuple, x[IK].itertuples(index=False))) for x in (r, v, kd)]
    g = gate(v, IK, nm.replace(".csv", "_v102"))
    P(f"{nm}: record {len(r)} | key dedup of record (DEDUP_FIRST rule) {len(kd)} | rebuilt v102 {len(v)} | rebuilt keys not in record {len(kv - kr)} | record keys not in rebuilt {len(kr - kv)} | keys in key-dedup but not rebuilt {len(kk_ - kv)} | rebuilt not in key-dedup {len(kv - kk_)}")
    lost = kd[[tuple(x) in (kk_ - kv) for x in kd[IK].itertuples(index=False)]]
    ls = lost.merge(dv.rename(columns={"Measure": "t.0", "_dbl": "_s"}), on=["Data", "Install", "Plot", "t.0"], how="left").merge(dv.rename(columns={"Measure": "t.1", "_dbl": "_e"}), on=["Data", "Install", "Plot", "t.1"], how="left")
    P(f"  keys present after key dedup but absent from the rebuild: {len(lost)}, of which on a doubled visit {int((ls._s.notna() | ls._e.notna()).sum())} (these are rows whose earlier visit record fails the frame filter while the later visit record passed it)")
    # value agreement on common keys with the key dedup
    com = v.merge(kd, on=IK, suffixes=("_v", "_k")); numc = [c for c in ("DBH.0", "DBH.1", "HT.0", "HT.1", "Age.0", "Age.1", "dDBH", "dHT", "BAL.0", "BAPH.0", "CR.0", "Planted") if c in v.columns]
    dif = {c: int((~np.isclose(com[c + "_v"].astype(float).fillna(-9), com[c + "_k"].astype(float).fillna(-9), rtol=1e-6)).sum()) for c in numc}
    P(f"  common keys {len(com)}, cells differing between rebuilt and key dedup: {dif}")
    for lab, d in (("record", r), ("v102", v)):
        cs = d.merge(conf.rename(columns={"Measure": "t.0", "_conf": "_s"}), on=["Data", "Install", "Plot", "t.0"], how="left").merge(conf.rename(columns={"Measure": "t.1", "_conf": "_e"}), on=["Data", "Install", "Plot", "t.1"], how="left")
        impact.append(dict(frame=nm, version=lab, rows=len(d), start_on_conflict_visit=int(cs._s.notna().sum()), end_on_conflict_visit=int(cs._e.notna().sum()), affected=int((cs._s.notna() | cs._e.notna()).sum())))
    rows.append(dict(frame=nm, rows_of_record=len(r), rows_v102=len(v), builder_found="yes", gate=g, note="rebuilt from AK_TREE_v102 through AK.TREE.incr_v102 (build_incr.py) and builders/build_frames_incr.R"))
for nm, rec, v102 in (("surv_recovered_ii", "inputs/surv_recovered_ii_origin_2026-09-16_DATA.csv", "frames/surv_recovered_ii_v102.csv"), ("surv_recovered_i", "inputs/surv_recovered_i_origin_2026-09-16_DATA.csv", "frames/surv_recovered_i_v102.csv"), ("surv_baseline_rebuilt", "inputs/surv_baseline_rebuilt_origin_2026-09-16_DATA.csv", "frames/surv_baseline_rebuilt_v102.csv")):
    r = pd.read_csv(rec); v = pd.read_csv(v102); SK = ["source", "inst", "plot", "tree", "t0", "t1"]
    for d in (r, v): d["inst"] = d["inst"].astype(str); d["plot"] = d["plot"].astype(str)
    g = gate(v, SK, nm + "_v102")
    rows.append(dict(frame=nm, rows_of_record=len(r), rows_v102=len(v), builder_found="yes", gate=g, note="rebuilt by builders/rebuild_surv_origin_2026-09-16_REFERENCE_COPY.py on the v102 inputs"))
    for lab, d in (("record", r), ("v102", v)):
        dd = d.rename(columns={"source": "Data", "inst": "Install", "plot": "Plot", "t0": "t.0", "t1": "t.1"})
        cs = dd.merge(conf.rename(columns={"Measure": "t.0", "_conf": "_s"}), on=["Data", "Install", "Plot", "t.0"], how="left").merge(conf.rename(columns={"Measure": "t.1", "_conf": "_e"}), on=["Data", "Install", "Plot", "t.1"], how="left")
        impact.append(dict(frame=nm, version=lab, rows=len(d), start_on_conflict_visit=int(cs._s.notna().sum()), end_on_conflict_visit=int(cs._e.notna().sum()), affected=int((cs._s.notna() | cs._e.notna()).sum())))
    P(nm, "record", len(r), "deaths", int((r.alive == 0).sum()), "| v102", len(v), "deaths", int((v.alive == 0).sum()))
for lab, d in (("record", pr), ("v102", pv)):
    dd = S(d.copy()); cs = dd.merge(conf.rename(columns={"Measure": "m0", "_conf": "_s"}), on=["Data", "Install", "Plot", "m0"], how="left").merge(conf.rename(columns={"Measure": "m1", "_conf": "_e"}), on=["Data", "Install", "Plot", "m1"], how="left")
    impact.append(dict(frame="plot_interval_pairs_DATA.csv", version=lab, rows=len(d), start_on_conflict_visit=int(cs._s.notna().sum()), end_on_conflict_visit=int(cs._e.notna().sum()), affected=int((cs._s.notna() | cs._e.notna()).sum())))
for lab, d in (("record", h0), ("v102", h1)):
    cs = d.merge(conf.rename(columns={"_conf": "_s"}), on=V, how="left"); impact.append(dict(frame="static height frame", version=lab, rows=len(d), start_on_conflict_visit=int(cs._s.notna().sum()), end_on_conflict_visit=0, affected=int(cs._s.notna().sum())))
rows.append(dict(frame="AK.TREE.incr.csv (paired remeasurements)", rows_of_record=16819, rows_v102=len(pd.read_csv("inputs/AK.TREE.incr_v102.csv", usecols=["ID"])), builder_found="recovered", gate="PASS", note="builder rule recovered and verified, build_incr.py"))
rows.append(dict(frame="static height frame", rows_of_record=len(h0), rows_v102=len(h1), builder_found="yes", gate=g_ht, note="koa_modeling_subset_filter.R filter on AK_TREE_v102, deposit targets 10,085 assembled and 10,060 height"))
rows.append(dict(frame="AK_HCB.csv", rows_of_record=len(hcb), rows_v102=len(hcb1), builder_found="no", gate=g_hcb, note="key dedup on (Data, Install, Plot, Tree, Year, Month), no row removed, FIA has no doubled visit"))
rows.append(dict(frame="koa_ingrowth_byi_obs.csv", rows_of_record=len(ig), rows_v102=len(ig1), builder_found="no", gate=g_ig, note="key dedup only, identical rows collapsed, builder not on firebreather"))
rows.append(dict(frame="plot_interval_pairs_DATA.csv (M1 gated)", rows_of_record=len(pr), rows_v102=len(pv), builder_found="yes", gate=g_pairs, note="builders/build_pairs_m1.R (koa_mort3 lines 26 to 81) on AK_TREE_v102 and AK_PLT.csv"))
for nm, f in (("plot_intervals.csv (three stage, 326)", "frames/plot_intervals_v102_keydedup.csv"), ("plot_intervals_origin.csv (three stage, 294)", "frames/plot_intervals_origin_v102_keydedup.csv")):
    d = pd.read_csv(f); rows.append(dict(frame=nm, rows_of_record=len(d), rows_v102=len(d), builder_found="no", gate=gate(d, ["Data", "Install", "Plot", "m_from", "m_to"], nm), note="key dedup, no duplicate present, table passes through unchanged"))
ft = pd.DataFrame(rows); ft.to_csv("out/frame_table.csv", index=False); P(ft.to_string(index=False))
im = pd.DataFrame(impact); im.to_csv("out/conflict_impact.csv", index=False); P(im.to_string(index=False))
P("DONE finalize_frames.py")
