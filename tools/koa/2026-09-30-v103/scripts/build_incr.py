#!/usr/bin/env python3
"""build_incr.py (koa v101). Rebuild the paired remeasurement table AK.TREE.incr.csv from a tree table.

The original builder of AK.TREE.incr.csv is not on firebreather. Its rule was recovered here and verified against
inputs/AK.TREE.incr_record.csv (see logs/build_incr_validate.log): for every tree (Data, Install, Plot, Tree) the
records at consecutive distinct Measure values are joined, every record at Measure m with every record at the next
Measure m', so a doubled visit yields two rows per tree interval and two consecutive doubled visits would yield four.
Columns are the record's 49 columns, .0 for the start record and .1 for the end record, t = Measure,
ID = Data-Install-Plot-Tree, dDBH = DBH.1 - DBH.0, dHT = HT.1 - HT.0. Only the four sources present in the record
table (PSP, DOFAW, KMR PSP, FIA) are kept, the other sources have one measurement and produce no pair.
Usage: python3 build_incr.py <tree_csv> <out_csv> [validate_against_csv]
"""
import pandas as pd, numpy as np, sys
tree_csv, out_csv = sys.argv[1], sys.argv[2]
val = sys.argv[3] if len(sys.argv) > 3 else None
t = pd.read_csv(tree_csv, low_memory=False)
t = t[[c for c in t.columns if c not in ("KeyDupFlag", "StatusConflictFlag")]]
TK = ["Data", "Install", "Plot", "Tree"]
all_src = t.Data.unique().tolist()
um = t[TK + ["Measure"]].drop_duplicates().sort_values(TK + ["Measure"])
um["Measure_next"] = um.groupby(TK).Measure.shift(-1)
um = um.dropna(subset=["Measure_next"]); um["Measure_next"] = um.Measure_next.astype(int)
print("sources with at least one tree interval", um.Data.value_counts().to_dict())
src = ["PSP", "DOFAW", "KMR PSP", "FIA"]
t = t[t.Data.isin(src)]; um = um[um.Data.isin(src)]
a = t.merge(um, on=TK + ["Measure"]); b = t.rename(columns={"Measure": "Measure_next"})
x = a.merge(b, on=TK + ["Measure_next"], suffixes=(".0", ".1"))
x = x.rename(columns={"Measure": "t.0", "Measure_next": "t.1"})
for c in TK:
    x[c + ".0"] = x[c]; x[c + ".1"] = x[c]
x["ID"] = x.Data.astype(str) + "-" + x.Install.astype(str) + "-" + x.Plot.astype(str) + "-" + x.Tree.astype(str)
x["dDBH"] = x["DBH.1"] - x["DBH.0"]; x["dHT"] = x["HT.1"] - x["HT.0"]
hdr = pd.read_csv("inputs/AK.TREE.incr_record.csv", nrows=0).columns.tolist()
x = x.sort_values(TK + ["t.0", "t.1"], kind="mergesort")[hdr]
x.to_csv(out_csv, index=False)
IK = ["Data.0", "Install.0", "Plot.0", "Tree.0", "t.0", "t.1"]
print("rows", len(x), "| by Data", x["Data.0"].value_counts().to_dict(), "| unique tree intervals", len(x.drop_duplicates(IK)))
dup = x.duplicated(IK, keep=False)
print("GATE one row per tree interval (Data, Install, Plot, Tree, t.0, t.1):", "PASS" if not dup.any() else "FAIL", "| offending keys", int(x[dup].groupby(IK).ngroups))
if val:
    r = pd.read_csv(val, low_memory=False)
    for d in (x, r):
        for c in ("Install.0", "Plot.0"): d[c] = d[c].astype(str)
    kx = x.groupby(IK).size().rename("recon"); kr = r.groupby(IK).size().rename("record")
    m = pd.concat([kx, kr], axis=1).fillna(0).astype(int)
    print("VALIDATION keys only in rebuilt", int((m.record == 0).sum()), "| only in record", int((m.recon == 0).sum()), "| multiplicity mismatch", int(((m.record > 0) & (m.recon > 0) & (m.record != m.recon)).sum()))
    mm = m[(m.record != m.recon)].reset_index(); print("  mismatches by Data, Install", mm.groupby(["Data.0", "Install.0"]).size().to_dict())
    one = m[(m.record == 1) & (m.recon == 1)].index
    xa = x.set_index(IK).loc[one]; ra = r.set_index(IK).loc[one]
    worst = 1.0
    for c in [c for c in hdr if c not in IK + ["ID"]]:
        if xa[c].dtype == object or ra[c].dtype == object: eq = (xa[c].astype(str) == ra[c].astype(str)).mean()
        else: eq = np.isclose(xa[c].astype(float).fillna(-9), ra[c].astype(float).fillna(-9)).mean()
        worst = min(worst, eq)
    print("  value agreement on", len(one), "single-multiplicity keys, minimum column agreement", round(worst, 6))
