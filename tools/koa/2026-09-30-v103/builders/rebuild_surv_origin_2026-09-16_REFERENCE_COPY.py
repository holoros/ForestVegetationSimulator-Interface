"""Rebuild the koa survival fitting table (AK_SURV.r, deposit 1.7.1) and the recovered variant (ii)
without the positive annualized increment filter, under the missing-increment guard.
Runs on the desktop only. Writes derived tables with NO coordinate columns (Lat, Long, LAT, LON
never read past the merge and never written)."""
import sys, numpy as np, pandas as pd
RAW = sys.argv[1]; OUT = sys.argv[2]; ORIG = sys.argv[3]
ort = pd.read_csv(ORIG)
geo = pd.read_csv(f"{RAW}/PLT.GEO.V2.csv", low_memory=False,
                  usecols=["Data", "Install", "Plot", "Origin", "OriginYR", "BYI", "rain", "temp"])
geo["Plot"] = geo["Plot"].astype(str); geo["Install"] = geo["Install"].astype(str)
g0 = len(geo); geo = geo.drop_duplicates(); print("geo rows", g0, "->", len(geo), "key dups left", geo.duplicated(["Data","Install","Plot"]).sum())
inc = pd.read_csv(f"{RAW}/AK.TREE.incr.csv", low_memory=False)
inc = inc.rename(columns={"Data.0": "Data", "Install.0": "Install", "Plot.0": "Plot", "Tree.0": "Tree"}).drop(columns=["Data.1", "Install.1", "Plot.1", "Tree.1"])
inc["Plot"] = inc["Plot"].astype(str); inc["Install"] = inc["Install"].astype(str)
m = inc.merge(geo, on=["Data", "Install", "Plot"], how="inner")
n0 = len(m); m = m.drop_duplicates(); print("merged", n0, "-> dedup", len(m))
m["HT.DBH.0"] = m["HT.0"] / (m["DBH.0"] / 100)
m["YIP"] = m["t.1"] - m["t.0"]
m["dDBH.ann"] = m["dDBH"] / m["YIP"]
def hcb(HT, DBH, BAL, BAPH, rain, temp):
    b0, b1, b2, b3, b4, b5, b6 = -0.507760, -1.565361, 0.434077, 0.039878, 0.295514, 0.284263, -0.379219
    sl = np.log(np.maximum(HT / DBH, 0.01))
    e = b0 + b1*np.sqrt(HT/100) + b2*sl + b3*np.log(BAL*BAPH + 1) + b4*np.log(BAPH + 1) + b5*np.log(rain + 1) + b6*np.log(temp + 1)
    return HT / (1 + np.exp(e))
m["HCB.0"] = hcb(m["HT.0"], m["DBH.0"], m["BAL.0"], m["BAPH.0"], m["rain"], m["temp"])
m["CR.0"] = (m["HT.0"] - m["HCB.0"]) / m["HT.0"]
psp_new = dict(zip(ort["Install"].astype(str), ort["Origin_new"]))
isp = m["Data"].eq("PSP")
m.loc[isp, "Origin"] = m.loc[isp, "Install"].map(psp_new).fillna(m.loc[isp, "Origin"])
m["Planted"] = np.where(m["Origin"] != "Natural", 1, 0)
rem = {str(k): [int(x) for x in str(v).split(";")] for k, v in zip(ort["Install"], ort["removal_t1_years"]) if str(v) not in ("nan", "")}
m["removal"] = [bool(d == "PSP" and i in rem and int(t1) in rem[i]) for d, i, t1 in zip(m["Data"], m["Install"], m["t.1"])]
print("PSP planted recode:", int((isp & (m["Planted"] == 1)).sum()), "of", int(isp.sum()), "PSP interval rows; removal-interval rows", int(m["removal"].sum()))
m["Alive"] = np.where(m["Status.1"] == "live", 1, 0)
base_ok = (m["DBH.0"] > 0) & (m["Status.0"] == "live") & (m["YIP"] > 0)
B = m[base_ok & (m["dDBH.ann"] > 0) & (m["dDBH.ann"] < 10)]
print("baseline", len(B), "deaths", int((B.Alive == 0).sum()), "inst", B.groupby(["Data","Install"]).ngroups, "plots", B.groupby(["Data","Install","Plot"]).ngroups, "tree-years", B.YIP.sum())
# recovered: missing-increment guard, then drop the positive-increment condition
R = m[base_ok & ~m["removal"]].copy()
sent = (R["DBH.1"] == 0) & (R["HT.1"].fillna(0) == 0) & (R["EXPF.1"] == 0)
for c in ["dDBH", "dHT", "DBH.1", "HT.1", "dDBH.ann"]:
    R.loc[sent, c] = np.nan
R = R[R["dDBH.ann"].isna() | (R["dDBH.ann"] < 10)]
print("recovered pre-absorb", len(R), "deaths", int((R.Alive == 0).sum()), "sentinel", int(sent.sum()))
# variant (ii): PSP status not absorbing -> truncate each PSP tree at the first measurement that
# records it dead (as initial or terminal status of any interval), keeping earlier intervals and
# the fatal one. Variant (i): drop every PSP tree with a dead -> live interval.
key = ["Data", "Install", "Plot", "Tree"]
P = m[m["Data"] == "PSP"]
dd = pd.concat([P.loc[P["Status.0"] == "dead", key + ["t.0"]].rename(columns={"t.0": "t"}),
                P.loc[P["Status.1"] == "dead", key + ["t.1"]].rename(columns={"t.1": "t"})])
td = dd.groupby(key)["t"].min().rename("td")
R2 = R.merge(td, left_on=key, right_index=True, how="left")
R2 = R2[(R2["Data"] != "PSP") | R2["td"].isna() | (R2["t.1"] <= R2["td"])].copy()
nonabs = P[(P["Status.0"] == "dead") & (P["Status.1"] == "live")][key].drop_duplicates()
R1 = R.merge(nonabs.assign(nab=1), on=key, how="left"); R1 = R1[R1["nab"].isna()].copy()
for lab, X in (("variant i", R1), ("variant ii", R2)):
    print(lab, len(X), "deaths", int((X.Alive == 0).sum()), "clusters", X.groupby(["Data", "Install"]).ngroups,
          "tree-years", X.YIP.sum(), "PSP deaths", int(((X.Data == "PSP") & (X.Alive == 0)).sum()), "planted rows", int(X.Planted.sum()))
keep = {"Data": "source", "Install": "inst", "Plot": "plot", "Tree": "tree", "t.0": "t0", "t.1": "t1", "YIP": "yip", "Alive": "alive",
        "DBH.0": "dbh", "HT.0": "ht", "rHT.0": "rht", "CR.0": "cr", "BYI": "byi", "Planted": "planted", "BAPH.0": "baph",
        "BAL.0": "bal", "SDI.0": "sdi", "QMD.0": "qmd", "removal": "removal_interval"}
for df, name in ((B, "surv_baseline_rebuilt"), (R1, "surv_recovered_i"), (R2, "surv_recovered_ii")):
    o = df[list(keep)].rename(columns=keep)
    assert not any(c.lower() in ("lat", "long", "lon") for c in o.columns)
    o.to_csv(f"{OUT}/{name}_origin_2026-09-16_DATA.csv", index=False)
