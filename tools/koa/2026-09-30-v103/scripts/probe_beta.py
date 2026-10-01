import pandas as pd, numpy as np
A=-0.16863070512157105; K=1.1719473700506686
t=pd.read_csv("/home/aaron/jobs/koa_v102_20260918/inputs/AK_TREE_record.csv",low_memory=False)
t["key"]=t.Data+"|"+t.Install.astype(str)+"|"+t.Plot.astype(str)+"|"+t.Measure.astype(str)
HQ=lambda q: np.exp((np.log(q)-A)/K)
def run(sub,lab,mode):
    L=sub
    g=L.groupby("key")
    out=[]
    for k,x in g:
        if len(x)<5: continue
        if mode=="list": N=x.EXPF.sum(); Q=np.sqrt((x.EXPF*x.DBH**2).sum()/N)
        elif mode=="plot": N=x.TPH.iloc[0]; Q=x.QMD.iloc[0]
        elif mode=="listnw": N=x.EXPF.sum(); Q=np.sqrt((x.DBH**2).mean())
        if N>0 and Q>0: out.append(N*HQ(Q)**2)
    z=np.array(out); print(lab,mode,len(z),np.quantile(z,0.99) if len(z) else None)
for kd in (True,False):
    b=t[t.KeyDupFlag==0] if kd else t
    for lab,sub in (("live_dbh_expf",b[(b.Status=="live")&(b.DBH>0)&(b.EXPF>0)]),("live_dbh",b[(b.Status=="live")&(b.DBH>0)]),("live",b[b.Status=="live"]),("all",b)):
        for mode in ("list","plot"):
            try: run(sub,f"kd{int(kd)} {lab}",mode)
            except Exception as e: print("err",lab,mode,e)
