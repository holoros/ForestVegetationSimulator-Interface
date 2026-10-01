import pandas as pd, numpy as np
V2="/home/aaron/jobs/koa_v102_20260918/"
pi=pd.read_csv(V2+"frames/plot_intervals_v102_keydedup.csv"); po=pd.read_csv(V2+"frames/plot_intervals_origin_v102_keydedup.csv")
print(len(pi),len(po)); print(pi.Data.value_counts().to_dict()); print(pi[pi.Data=="PSP"].head(3).T)
t=pd.read_csv(V2+"inputs/AK_TREE_v102.csv",low_memory=False)
# try reproduce Kulani 12 1966-1972 and a PSP row
for (d,i,p,m0,m1) in [("DOFAW","Kulani","12",1966,1972)]+[tuple(x) for x in pi[pi.Data=="PSP"][["Data","Install","Plot","m_from","m_to"]].head(2).astype(str).values]:
    g=t[(t.Data==d)&(t.Install.astype(str)==str(i))&(t.Plot.astype(str)==str(p))]
    a=g[g.Measure==int(m0)]; b=g[g.Measure==int(m1)]
    L=a[(a.Status=="live")&(a.DBH>0)]
    mm=L.merge(b[["Tree","Status","DBH"]],on="Tree",how="left",suffixes=("","_1"))
    died=mm.Status_1.ne("live")
    print(d,i,p,m0,m1,"live",len(L),"died",died.sum(),"expf",L.EXPF.sum(),"expf_died",L.EXPF[died.values].sum(),"ba", (0.00007854*L.DBH**2*L.EXPF).sum(), "depBAPH",a.BAPH.iloc[0],"TPH",a.TPH.iloc[0],"QMD",a.QMD.iloc[0], "sdi25", a.TPH.iloc[0]*(a.QMD.iloc[0]/25)**1.605)
    print(pi[(pi.Data==d)&(pi.Install.astype(str)==str(i))&(pi.Plot.astype(str)==str(p))&(pi.m_from==int(m0))].T)
ig=pd.read_csv(V2+"frames/koa_ingrowth_byi_obs_v102_keydedup.csv"); ii=pd.read_csv(V2+"out/ingrowth_inferred_intervals.csv")
print(len(ig),len(ii), ii.m_from.notna().sum()); print((ig.RD/ig.SDI).describe()); print(ig[ig.n_new>0].head(5)); print((ig.ing_tph/ig.n_new).describe())
print(ig.key.str.split("|").str[0].value_counts().to_dict())
h=pd.read_csv(V2+"frames/AK_HCB_v102_keydedup.csv"); print(h.shape); print(h.head(3).T)
