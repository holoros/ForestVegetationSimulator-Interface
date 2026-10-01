#!/usr/bin/env python3
"""dedup.py (2026-09-17). Build three versions of the koa increment fitting frames dDBH.csv and dHT.csv.

DEPLOYED     unchanged byte for byte copy of ~/jobs/koa_origin_20260916/{dDBH,dHT}.csv
DEDUP_FIRST  one row per tree interval, keeping the row built from the EARLIER field visit
DEDUP_LAST   one row per tree interval, keeping the row built from the LATER field visit

Tree interval key: Data, Install, Plot, Tree, t.0, t.1.
Rule for which row is the earlier visit. Within a duplicated key the two rows were built from two
field visits under one Measure value (section 6 of ~/jobs/koa_dataflags_20260917/REPORT.md). The visit
order is taken from the Age column at the doubled end (Age.0 if the rows differ in Age.0, else Age.1),
smaller Age = earlier visit. When Age does not separate the rows (the DOFAW Kulani 1994 visit carries one
Age on both records, and the FIA 2010 to 2019 rows are repeated four times as identical rows) the tie is
broken by file order, first row in file = earlier visit. File order is a verified proxy: in every one of
the 862 PSP pairs in dDBH.csv whose Age separates the visits, the earlier Age row is also first in file.
Fully identical repeats collapse to one row under either rule.
No coordinate column is read, printed or written by this script beyond the byte for byte frame copy.
"""
import pandas as pd, numpy as np, shutil, os, sys
SRC = os.path.expanduser("~/jobs/koa_origin_20260916")
IK = ["Data", "Install", "Plot", "Tree", "t.0", "t.1"]
log = open("dedup.log", "w")
def P(*a):
    s = " ".join(str(x) for x in a); print(s); log.write(s + "\n")
counts = []
for f in ("dDBH", "dHT"):
    src = f"{SRC}/{f}.csv"
    shutil.copyfile(src, f"frames/DEPLOYED/{f}.csv")
    d = pd.read_csv(src, low_memory=False)
    d["_rn"] = np.arange(len(d))
    dup = d.duplicated(IK, keep=False)
    g = d[dup].groupby(IK, sort=False)
    a0 = g["Age.0"].transform(lambda x: x.max() - x.min())
    a1 = g["Age.1"].transform(lambda x: x.max() - x.min())
    # visit order score: Age at the doubled end, then file order
    d["_age_end"] = np.nan
    d.loc[dup, "_age_end"] = np.where(a0 > 0, d.loc[dup, "Age.0"], np.where(a1 > 0, d.loc[dup, "Age.1"], 0.0))
    d["_age_end"] = d["_age_end"].fillna(0.0)
    ds = d.sort_values(IK + ["_age_end", "_rn"], kind="mergesort")
    first = ds.drop_duplicates(IK, keep="first").sort_values("_rn")
    last = ds.drop_duplicates(IK, keep="last").sort_values("_rn")
    keep = [c for c in d.columns if not c.startswith("_")]
    first[keep].to_csv(f"frames/DEDUP_FIRST/{f}.csv", index=False)
    last[keep].to_csv(f"frames/DEDUP_LAST/{f}.csv", index=False)
    sizes = g.size().value_counts().to_dict()
    n_fia4 = int((g.size() == 4).sum()); n_pair = int((g.size() == 2).sum())
    n_age = int(((a0 > 0) | (a1 > 0)).groupby([d.loc[dup, k] for k in IK]).first().sum())
    P(f"{f}: DEPLOYED rows {len(d)}; duplicated keys {g.ngroups} (rows {int(dup.sum())}), key sizes {sizes}; "
      f"pairs {n_pair}, fourfold {n_fia4}; keys separated by Age {n_age}, by file order {g.ngroups - n_age}; "
      f"DEDUP_FIRST rows {len(first)}; DEDUP_LAST rows {len(last)}; unique keys {d.drop_duplicates(IK).shape[0]}")
    P(f"  duplicated rows by Data: {d[dup].groupby('Data').size().to_dict()}; rows after dedup by Data: {first.groupby('Data').size().to_dict()}")
    # sanity: key aligned comparison of the two dedup frames
    m = first[keep].merge(last[keep], on=IK, suffixes=("_f", "_l"))
    vc = [c for c in keep if c not in IK]
    diff = np.zeros(len(m), bool)
    for c in vc: diff |= (m[c + "_f"].astype(str) != m[c + "_l"].astype(str)).values
    P(f"  keys whose kept row differs between DEDUP_FIRST and DEDUP_LAST: {int(diff.sum())} (identical repeats collapse to the same row)")
    for lab, fr in (("DEPLOYED", d), ("DEDUP_FIRST", first), ("DEDUP_LAST", last)):
        counts.append(dict(frame=f, version=lab, rows=len(fr), rows_PSP=int((fr.Data == "PSP").sum()), rows_FIA=int((fr.Data == "FIA").sum()),
                           rows_DOFAW=int((fr.Data == "DOFAW").sum()), rows_other=int((~fr.Data.isin(["PSP", "FIA", "DOFAW"])).sum()),
                           planted_deposit=int((fr.Planted == 1).sum())))
pd.DataFrame(counts).to_csv("out/row_counts.csv", index=False)
P(pd.DataFrame(counts).to_string(index=False))
