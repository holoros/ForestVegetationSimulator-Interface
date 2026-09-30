import pandas as pd, numpy as np
v=pd.read_csv('/home/aaron/jobs/koa_v102_20260918/inputs/AK_TREE_v102.csv', low_memory=False)
print(v.columns.tolist()); print(v.Status.value_counts().to_dict())
k=['Data','Install','Plot','Measure']
lv=v[v.Status=='live'].copy()
lv['ba']=np.pi*(lv.DBH/200)**2*lv.EXPF
g=lv.groupby(k).agg(n=('DBH','size'),tph=('EXPF','sum'),ba=('ba','sum'),d2=('DBH',lambda x: 0)).reset_index()
pl=lv.groupby(k)[['TPH','BAPH','BA.AK','pBA.AK','SDI','QMD']].first().reset_index()
g=g.merge(pl,on=k)
g['qmd_k']=np.sqrt(g.ba/g.tph/np.pi*4)*100
mix=g['pBA.AK']<0.999
print('plot-years',len(g),' mixed-species (pBA.AK<1)',mix.sum())
for nm,a,b in [('BA.AK vs koa sum',g['BA.AK'],g.ba),('BAPH vs koa sum',g.BAPH,g.ba),('TPH vs koa sumEXPF',g.TPH,g.tph),('QMD vs koa QMD',g.QMD,g.qmd_k)]:
  r=(a-b).abs()/b.abs().clip(lower=1e-9)
  print(nm,' pure-koa: share within 1%',round((r[~mix]<0.01).mean(),3),' mixed: share within 1%',round((r[mix]<0.01).mean(),3))
# SDI forms
for nm,s in [('Reineke TPH,QMD 25.4',g.TPH*(g.QMD/25.4)**1.605),('Reineke TPH,QMD 25',g.TPH*(g.QMD/25)**1.605)]:
  r=(g.SDI-s).abs()/g.SDI; print('SDI vs',nm,' share within 1%',round((r<0.01).mean(),3))
lv['sdi_i']=lv.EXPF*(lv.DBH/25.4)**1.605; lv['sdi_j']=lv.EXPF*(lv.DBH/25)**1.605
s=lv.groupby(k)[['sdi_i','sdi_j']].sum().reset_index(); g2=g.merge(s,on=k)
for c in ['sdi_i','sdi_j']:
  r=(g2.SDI-g2[c]).abs()/g2.SDI; print('SDI vs summation koa',c,' share within 1% pure',round((r[~mix.values]<0.01).mean(),3),' mixed',round((r[mix.values]<0.01).mean(),3))
# BAL: koa-only larger-tree BA per tree
lv=lv.sort_values(k+['DBH'],ascending=[True]*4+[False])
lv['bal_k']=lv.groupby(k).ba.cumsum()-lv.ba
# ties: trees with equal DBH
m=lv.merge(g[k+['pBA.AK']],on=k,suffixes=('','_p'))
mx=m['pBA.AK']<0.999
d=(m.BAL-m.bal_k).abs()
print('BAL vs koa-only cumulative: pure-koa within 0.01',round((d[~mx]<0.01).mean(),3),' mixed within 0.01',round((d[mx]<0.01).mean(),3))
# largest koa tree in mixed plots: BAL > 0 means other species counted
top=m[mx].groupby(k).head(1); print('mixed plot-years, largest koa tree BAL>0.01:',int((top.BAL>0.01).sum()),'of',len(top))
print('BAL/BAPH ratio for largest koa in mixed', (top.BAL/top.BAPH).describe().round(3).to_dict())
