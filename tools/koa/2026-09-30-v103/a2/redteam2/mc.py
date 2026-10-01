import pandas as pd, numpy as np, os
W=os.path.expanduser('~/jobs/koa_v103_20260930/'); J=W+'a2/closeout/jointmc/'
K=pd.read_csv(J+'out/K_joint_draws.csv'); print(K.shape, list(K.columns)[:8])
if 'n_inst_distinct' in K: print('n_inst_distinct', K.n_inst_distinct.describe().round(1).to_dict())
for c,vec in [('cal_dd_nat','d_'),('cal_dd_plt','d_'),('cal_dh_nat','h_'),('cal_dh_plt','h_')]:
    X=K[[x for x in K.columns if x.startswith(vec+'b')]].values; y=np.log(K[c].values)
    X1=np.c_[np.ones(len(X)),X]; b=np.linalg.lstsq(X1,y,rcond=None)[0]; r=y-X1@b
    print(c,'sd_log',round(y.std(),3),'R2 on vector',round(1-r.var()/y.var(),3),'resid sd_log',round(r.std(),3))
rows=[]
for tag,f in [("even","table8_evenaged_M1.csv"),("uneven","uneven_aged_table8_M1.csv")]:
    C=pd.read_csv(W+'engine_v103/out_m1/'+f); N=pd.read_csv(J+'engine/out_m1/'+f)
    pv=[c for c in C.columns if c+'_lo' in C.columns]
    pts=[c for c in pv]; print(tag,'max point diff',np.nanmax(np.abs(C[pts].values-N[pts].values)))
    for v in pv:
        wc=C[v+'_hi']-C[v+'_lo']; wn=N[v+'_hi']-N[v+'_lo']; r=wn/wc
        pos=(N[v]-N[v+'_lo'])/wn
        for s in C.Scenario.unique():
            m=C.Scenario==s
            rows.append((tag,s,v,round(r[m].min(),2),round(r[m].max(),2),round(pos[m].min(),2),round(pos[m].max(),2)))
print(pd.DataFrame(rows,columns=['t','scen','var','rmin','rmax','posmin','posmax']).to_string(index=False))
print(C.columns.tolist()); print(C.Scenario.unique(), C.Age.unique())
