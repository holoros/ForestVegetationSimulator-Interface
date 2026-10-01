#!/usr/bin/env python3
"""dedup_tree.py (koa v101, 2026-09-17). Deduplicate the koa tree table and the deposited survival table.

Inputs   inputs/AK_TREE_record.csv  (byte copy of ~/jobs/koa_origin_20260916/output/engine_joint/AK_TREE.csv)
         inputs/AK_SURV_record.csv  (byte copy of ~/jobs/koa_origin_20260916/output/engine_joint/AK_SURV.csv)
         inputs/PLT.GEO.V2.csv      (byte copy of ~/jobs/koa_ooda_refit/PLT.GEO.V2.csv, plot covariate table)
Outputs  inputs/AK_TREE_v102.csv, inputs/AK_SURV_v102.csv, inputs/PLT.GEO.V2_v102.csv
         out/conflict_visits.csv, out/dedup_tree_by_source.csv, out/dedup_tree_by_visit.csv, out/dedup_surv_by_source.csv
         logs/dedup_tree.log

Rules (labeled assumptions, to be confirmed by the data owner on 2026-09-18)
 [RULING A1', data owner 2026-09-18, REVERSES assumption A1] A doubled tree visit, two AK_TREE records under one (Data, Install, Plot, Tree, Measure), keeps the
                 record with the LARGER Age (the LATER field visit). Ties (equal or missing Age) keep the LAST
                 record in file order. Fully identical records collapse to one first.
 [RULING A2', data owner 2026-09-18, REVERSES assumption A2] Where the two record sets of a plot visit disagree on live status (StatusConflictFlag 1) the LATER
                 record is kept as well, and the plot visit is listed in out/conflict_visits.csv for the data owner.
 [ASSUMPTION A3] Rows repeated as byte identical copies (the FIA fourfold in PLT.GEO.V2.csv and any identical copies
                 in AK_SURV.csv) collapse to one row.
 AK_SURV.csv rule (dedup.py of ~/jobs/koa_dedup_refit_20260917): key (Data, Install, Plot, Tree, t.0, t.1); within a
 duplicated key the visit order is the Age at the doubled end (Age.0 if the rows differ in Age.0, else Age.1), the
 LARGER Age row is kept, ties by file order (last).
No coordinate column exists in any input read here, and the script asserts that before writing.
"""
import pandas as pd, numpy as np, os, sys
os.makedirs("out", exist_ok=True); os.makedirs("logs", exist_ok=True)
log = open("logs/dedup_tree.log", "w")
def P(*a):
    s = " ".join(str(x) for x in a); print(s); log.write(s + "\n")
def no_coords(df, name):
    bad = [c for c in df.columns if c.strip().lower() in ("lat", "lon", "long", "latitude", "longitude", "x", "y")]
    assert not bad, f"{name} carries coordinate columns {bad}"

# ------------------------------------------------------------------ AK_TREE
t = pd.read_csv("inputs/AK_TREE_record.csv", low_memory=False)
no_coords(t, "AK_TREE")
K = ["Data", "Install", "Plot", "Tree", "Measure"]
V = ["Data", "Install", "Plot", "Measure"]
n0 = len(t)
t["_rn"] = np.arange(n0)
flagcols = [c for c in ("KeyDupFlag", "StatusConflictFlag") if c in t.columns]
datacols = [c for c in t.columns if c not in flagcols + ["_rn"]]
P("AK_TREE records before", n0, "| KeyDupFlag 1", int((t.get("KeyDupFlag", 0) == 1).sum()), "| StatusConflictFlag 1", int((t.get("StatusConflictFlag", 0) == 1).sum()))
dup0 = t.duplicated(K, keep=False)
P("records in duplicated (Data, Install, Plot, Tree, Measure) keys", int(dup0.sum()), "| duplicated keys", int(t[dup0].groupby(K).ngroups), "| unique keys", len(t.drop_duplicates(K)))
P("key multiplicities", t.groupby(K).size().value_counts().sort_index().to_dict())
# A3 identical records
ident = t.duplicated(datacols, keep="first")
P("[A3] fully identical AK_TREE records dropped", int(ident.sum()))
t1 = t[~ident].copy()
# A1 earlier visit = smaller Age, tie file order
dup1 = t1.duplicated(K, keep=False)
g = t1[dup1].groupby(K)
age_sep = int((g["Age"].transform(lambda x: x.nunique(dropna=True)) > 1).groupby([t1.loc[dup1, k] for k in K]).first().sum())
P("[A1] duplicated keys after A3", int(g.ngroups), "| separated by Age", age_sep, "| tie broken by file order", int(g.ngroups) - age_sep)
t1["_age"] = -t1["Age"].fillna(-np.inf)   # V102 RULING: later visit = LARGER Age
ts = t1.sort_values(K + ["_age", "_rn"], ascending=[True]*len(K)+[True, False], kind="mergesort")
keep = ts.drop_duplicates(K, keep="first")
drop = ts[~ts.index.isin(keep.index)]
# per record set: earlier vs later within doubled keys
ts["_rank"] = ts.groupby(K).cumcount()
r0 = ts[ts._rank == 0].groupby(K)["_rn"].first(); r1 = ts[ts._rank == 1].groupby(K)["_rn"].first()
r0 = r0.reindex(r1.index); first_in_file = (r0 < r1)
P("[A1] kept record is also first in file order in", int(first_in_file.sum()), "of", len(first_in_file), "doubled keys")
out = keep.sort_values("_rn")[datacols + flagcols]
n1 = len(out)
P("AK_TREE records after", n1, "| dropped", n0 - n1)
gate = not out.duplicated(K).any()
P("GATE AK_TREE_v102 one record per (Data, Install, Plot, Tree, Measure):", "PASS" if gate else "FAIL", "| offending keys", int(out[out.duplicated(K, keep=False)].groupby(K).ngroups) if not gate else 0)
no_coords(out, "AK_TREE_v102")
out.to_csv("inputs/AK_TREE_v102.csv", index=False)
# rule log by source and by plot visit
bs = pd.DataFrame({"before": t.groupby("Data").size(), "after": out.groupby("Data").size()}).fillna(0).astype(int)
bs["dropped"] = bs.before - bs.after
bs.to_csv("out/dedup_tree_by_source.csv"); P("by Data source\n" + bs.to_string())
aff = t[dup0][V].drop_duplicates()
bv = t.merge(aff, on=V).groupby(V).size().rename("before").to_frame()
bv["after"] = out.merge(aff, on=V).groupby(V).size()
bv["dropped"] = bv.before - bv.after
bv = bv.reset_index()
bv.to_csv("out/dedup_tree_by_visit.csv", index=False)
P("doubled plot visits", len(bv), "| by Data", bv.groupby("Data").size().to_dict(), "| records dropped on them", int(bv.dropped.sum()))
# [A2] conflict table: earlier vs later record set, live status
d2 = ts[ts.duplicated(K, keep=False)].copy()
d2["_set"] = np.where(d2._rank == 0, "earlier", "later")
P("keys with three records (earlier set = smallest Age, later set = the next record)", int((ts.groupby(K).size() == 3).sum()))
st = d2.pivot_table(index=K, columns="_set", values="Status", aggfunc="first")
st = st.dropna(subset=["earlier", "later"]).reset_index()
st["conflict"] = st.earlier != st.later
cv = st.groupby(V).agg(n_trees_doubled=("Tree", "size"), n_status_conflict=("conflict", "sum"),
                       n_live_earlier=("earlier", lambda x: int((x == "live").sum())), n_dead_earlier=("earlier", lambda x: int((x == "dead").sum())),
                       n_live_later=("later", lambda x: int((x == "live").sum())), n_dead_later=("later", lambda x: int((x == "dead").sum()))).reset_index()
cv["n_status_conflict"] = cv.n_status_conflict.astype(int)
cv["kept_set"] = "later"
if "StatusConflictFlag" in t.columns:
    scf = t[t.StatusConflictFlag == 1].groupby(V).size().rename("StatusConflictFlag_records").reset_index()
    cv = cv.merge(scf, on=V, how="left").fillna({"StatusConflictFlag_records": 0})
    cv["StatusConflictFlag_records"] = cv.StatusConflictFlag_records.astype(int)
conf = cv[cv.n_status_conflict > 0].sort_values(V)
conf.to_csv("out/conflict_visits.csv", index=False)
cv.sort_values(V).to_csv("out/doubled_visits_all.csv", index=False)
P("[A2] plot visits where the two record sets disagree on live status:", len(conf), "| trees in conflict", int(conf.n_status_conflict.sum()))
P(conf.to_string(index=False))

# ------------------------------------------------------------------ PLT.GEO.V2
geo = pd.read_csv("inputs/PLT.GEO.V2.csv", low_memory=False)
no_coords(geo, "PLT.GEO.V2")
GK = ["Data", "Install", "Plot"]
g0 = len(geo); gi = geo.duplicated(keep="first")
geo1 = geo[~gi]
P("PLT.GEO.V2 rows before", g0, "| [A3] identical rows dropped", int(gi.sum()), "| after", len(geo1), "| identical rows by Data", geo[geo.duplicated(keep=False)].Data.value_counts().to_dict())
ggate = not geo1.duplicated(GK).any()
P("GATE PLT.GEO.V2_v102 one row per (Data, Install, Plot):", "PASS" if ggate else "FAIL", "| offending keys", int(geo1[geo1.duplicated(GK, keep=False)].groupby(GK).ngroups))
geo1.to_csv("inputs/PLT.GEO.V2_v102.csv", index=False)

# ------------------------------------------------------------------ AK_SURV (deposit table)
s = pd.read_csv("inputs/AK_SURV_record.csv", low_memory=False)
no_coords(s, "AK_SURV")
IK = ["Data", "Install", "Plot", "Tree", "t.0", "t.1"]
s0 = len(s); s["_rn"] = np.arange(s0)
sid = s.duplicated([c for c in s.columns if c != "_rn"], keep="first")
P("AK_SURV rows before", s0, "| [A3] identical rows dropped", int(sid.sum()))
s1 = s[~sid].copy()
dup = s1.duplicated(IK, keep=False)
gg = s1[dup].groupby(IK, sort=False)
a0 = gg["Age.0"].transform(lambda x: x.max() - x.min()); a1 = gg["Age.1"].transform(lambda x: x.max() - x.min())
s1["_age_end"] = 0.0
s1.loc[dup, "_age_end"] = np.where(a0 > 0, s1.loc[dup, "Age.0"], np.where(a1 > 0, s1.loc[dup, "Age.1"], 0.0))
n_by_age0 = int((a0 > 0).groupby([s1.loc[dup, k] for k in IK]).first().sum()); n_by_age1 = int(((a0 == 0) & (a1 > 0)).groupby([s1.loc[dup, k] for k in IK]).first().sum())
P("AK_SURV duplicated keys", int(gg.ngroups), "(rows", int(dup.sum()), ") | doubled start (Age.0 separates)", n_by_age0, "| doubled end (Age.1 separates)", n_by_age1, "| tie by file order", int(gg.ngroups) - n_by_age0 - n_by_age1)
P("AK_SURV duplicated rows by Data", s1[dup].Data.value_counts().to_dict())
s1["_age_end"] = -s1["_age_end"]   # V102 RULING: later record kept
ss = s1.sort_values(IK + ["_age_end", "_rn"], ascending=[True]*len(IK)+[True, False], kind="mergesort").drop_duplicates(IK, keep="first").sort_values("_rn")
sout = ss[[c for c in s.columns if c != "_rn"]]
P("AK_SURV rows after", len(sout), "| deaths before", int((s.Alive == 0).sum()), "after", int((sout.Alive == 0).sum()))
sgate = not sout.duplicated(IK).any()
P("GATE AK_SURV_v102 one row per (Data, Install, Plot, Tree, t.0, t.1):", "PASS" if sgate else "FAIL", "| offending keys", int(sout[sout.duplicated(IK, keep=False)].groupby(IK).ngroups))
sout.to_csv("inputs/AK_SURV_v102.csv", index=False)
bs2 = pd.DataFrame({"before": s.groupby("Data").size(), "after": sout.groupby("Data").size()}).fillna(0).astype(int); bs2["dropped"] = bs2.before - bs2.after
bs2.to_csv("out/dedup_surv_by_source.csv"); P("AK_SURV by Data source\n" + bs2.to_string())
P("DONE dedup_tree.py")
