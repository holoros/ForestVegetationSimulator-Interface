import pandas as pd, numpy as np
t=pd.read_csv('AK_TREE.csv', low_memory=False)
p=pd.read_csv('AK_PLT.csv')
k=['Data','Install','Plot','Measure']
for d in (t,p):
  for c in k: d[c]=d[c].astype(str)
live=t[t.Status=='live'].copy()
live['ba']=np.pi*(live.DBH/200)**2
g=live.groupby(k).agg(nstem=('DBH','size'),sumexpf=('EXPF','sum'),ba=('ba',lambda x: None)).reset_index() if False else None
g=live.assign(baex=live.ba*live.EXPF, d2ex=live.DBH**2*live.EXPF).groupby(k).agg(nstem=('DBH','size'),tph=('EXPF','sum'),baph_koa=('baex','sum'),d2=('d2ex','sum')).reset_index()
g['qmd_koa']=np.sqrt(g.d2/g.tph)
q=p.merge(g,on=k,how='left')
print('plot-years',len(q),'without live koa rows',q.nstem.isna().sum())
print('QMD vs recomputed koa QMD: max abs diff',np.nanmax(np.abs(q.QMD-q.qmd_koa)).round(3), ' BA.AK vs koa BA diff', np.nanmax(np.abs(q['BA.AK']-q.baph_koa)).round(3), 'TPH vs sum EXPF',np.nanmax(np.abs(q.TPH-q.tph)).round(2))
for o in ['Natural','Planted','All']:
  s=q if o=='All' else q[q.Origin==o]
  for m in [1,2,3,5,10]:
    ss=s[s.nstem>=m]; i=ss.QMD.idxmax()
    print(o,'>=',m,'stems: n plot-yrs',len(ss),' maxQMD',round(ss.QMD.max(),2),'nstem',int(ss.loc[i,'nstem']),'src',ss.loc[i,'Data'],'yr',ss.loc[i,'Measure'],'| maxBAPH',round(ss.BAPH.max(),2),'maxBA.AK',round(ss['BA.AK'].max(),2))
for v in [69.68,88.7,59.38]:
  d=(q.QMD-v).abs(); i=d.idxmin(); print('QMD target',v,'closest',round(q.loc[i,'QMD'],3),q.loc[i,['Data','Origin','Measure','nstem']].tolist())
for v in [76.06]:
  for c in ['BAPH','BA.AK']:
    d=(q[c]-v).abs(); i=d.idxmin(); print('BA target',v,c,'closest',round(q.loc[i,c],3),q.loc[i,['Data','Origin','Measure','nstem','QMD']].tolist())
# top natural QMD list
print(q.sort_values('QMD',ascending=False)[['Data','Origin','Measure','nstem','QMD','BAPH','TPH']].head(12).to_string())
print(q[q.Origin=='Planted'].sort_values('QMD',ascending=False)[['Data','Origin','Measure','nstem','QMD','BAPH','TPH']].head(5).to_string())
print(q.sort_values('BAPH',ascending=False)[['Data','Origin','Measure','nstem','QMD','BAPH','BA.AK','TPH']].head(8).to_string())
