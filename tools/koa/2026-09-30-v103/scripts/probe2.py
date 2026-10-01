import pandas as pd, numpy as np
s=pd.read_csv("out/repair/plotyear_stand_before_after.csv")
f=s[s.repair_source!="all_species_live"].astype({"Install":str,"Plot":str})
print(f.groupby(["Data","Measure"]).size().to_dict())
t=pd.read_csv("inputs/AK_TREE_v102.csv",low_memory=False)
t["Install"]=t.Install.astype(str);t["Plot"]=t.Plot.astype(str)
m=t.merge(f[["Data","Install","Plot","Measure"]],on=["Data","Install","Plot","Measure"])
print(m.groupby("Status").agg(n=("DBH","size"),dbhpos=("DBH",lambda x:(x>0).sum()),expfpos=("EXPF",lambda x:(x>0).sum()),baph=("BAPH","max")))
print(m[m.Status=="live"].head(8)[["Data","Install","Plot","Measure","Tree","DBH","HT","EXPF","BAPH","TPH"]])
print(t[t.Data=="PSP"].groupby("Measure").EXPF.agg(["min","max",lambda x:(x==0).mean()]))
a=pd.read_csv("in/HI_TREE.csv",usecols=["INVYR","PLOT","SUBP","TREE","STATUSCD","SPCD","DIA","HT","TPA_UNADJ","COUNTYCD"])
x=a[(a.PLOT==2291)&(a.SUBP==2)&(a.INVYR==2019)&(a.STATUSCD==1)]
print(x.sort_values("DIA",ascending=False))
