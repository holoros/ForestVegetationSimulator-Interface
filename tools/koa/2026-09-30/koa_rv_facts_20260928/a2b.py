import pandas as pd, numpy as np
t=pd.read_csv('AK_TREE.csv', low_memory=False); p=pd.read_csv('AK_PLT.csv')
k=['Data','Install','Plot','Measure']
for d in (t,p):
  for c in k: d[c]=d[c].astype(str)
def cnt(df,name): return df.groupby(k).size().rename(name).reset_index()
q=p.merge(cnt(t,'n_all'),on=k,how='left').merge(cnt(t[t.Status=='live'],'n_live'),on=k,how='left').merge(cnt(t[(t.Status=='live')&(t.KeyDupFlag==0)],'n_live_nodup'),on=k,how='left').merge(cnt(t[(t.Status=='live')].drop_duplicates(['Data','Install','Plot','Measure','Tree']),'n_live_uniq'),on=k,how='left')
q['n_tph']=q.TPH  # TPH
for c in ['n_all','n_live','n_live_nodup','n_live_uniq']:
  for o in ['Natural','Planted']:
    s=q[(q.Origin==o)&(q[c]>=5)]; i=s.QMD.idxmax(); print(c,o,'max QMD',round(s.QMD.max(),2), s.loc[i,['Data','Measure',c]].tolist())
# natural QMD values between 80 and 95
print(q[(q.QMD>80)&(q.QMD<95)][['Data','Origin','Measure','n_all','n_live','QMD','TPH']].to_string())
# QMD recomputed from live koa trees with unique key (larger Age kept as in v102)
v=pd.read_csv('/home/aaron/jobs/koa_v102_20260918/inputs/AK_TREE_v102.csv', low_memory=False)
for c in k: v[c]=v[c].astype(str)
lv=v[v.Status=='live'].copy(); lv['d2']=lv.DBH**2*lv.EXPF
r=lv.groupby(k).agg(n=('DBH','size'),tph=('EXPF','sum'),d2=('d2','sum')).reset_index(); r['qmd']=np.sqrt(r.d2/r.tph)
r=r.merge(p[k+['Origin','QMD','TPH','BAPH']],on=k,how='left')
print('v102 tree table: plot-years',len(r),' max|qmd-QMD|',round((r.qmd-r.QMD).abs().max(),3), ' n diff>0.01',((r.qmd-r.QMD).abs()>0.01).sum())
for o in ['Natural','Planted']:
  for mn in [1,5]:
    s=r[(r.Origin==o)&(r.n>=mn)]; i=s.qmd.idxmax(); print('v102 recomputed',o,'>=',mn,'max qmd',round(s.qmd.max(),2),s.loc[i,['Data','Measure','n']].tolist())
