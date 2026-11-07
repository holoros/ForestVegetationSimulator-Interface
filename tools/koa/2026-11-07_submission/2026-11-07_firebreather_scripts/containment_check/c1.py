import pandas as pd, numpy as np
d=pd.read_csv('../koa_v105final_20261103/frames/final/tree_join_v103.csv')
print(d.status.value_counts().head(), d.planted.value_counts(dropna=False).head(), d.Origin.value_counts(dropna=False).head())
live=d[(d.status.astype(str).str.lower().isin(['1','live','l','alive'])) & (d.dbh>0) & (d.expf>0)].copy()
live['ba']=np.pi*(live.dbh/200)**2*live.expf
g=live.groupby(['source','inst','plot','year']).agg(tph=('expf','sum'),ba=('ba','sum'),d2=('dbh',lambda x: 0),planted=('planted','max'),baph_col=('baph','first'),n=('dbh','size'))
q=live.assign(w2=live.expf*live.dbh**2).groupby(['source','inst','plot','year']).w2.sum()
g['qmd']=np.sqrt(q/g.tph); g['sdi']=g.tph*(g.qmd/25.4)**1.605
for o,s in g.groupby('planted'):
    print('planted',o,'n',len(s),'BA p95 %.1f max %.1f'%(s.ba.quantile(.95),s.ba.max()),'SDI p95 %.0f max %.0f'%(s.sdi.quantile(.95),s.sdi.max()),'BAcol p95 %.1f'%s.baph_col.quantile(.95))
    top=s.sort_values('ba',ascending=False).head(4); print(top[['tph','ba','qmd','sdi','n']].round(1).to_string())
# row-shuffle check (F14)
g2=live.sample(frac=1,random_state=7).groupby(['source','inst','plot','year']).ba.sum()
print('shuffle equal',np.allclose(g2.sort_index().values,g.ba.sort_index().values))
