import pandas as pd, numpy as np
F='../koa_v105final_20261103/frames/final/'
d=pd.read_csv(F+'tree_join_v103.csv')
o1=pd.read_csv(F+'plot_intervals_origin_v103.csv',usecols=['Data','Install','Plot','planted'])
o2=pd.read_csv(F+'dDBH_CS_v103_model.csv',usecols=['Data','Install','Plot','Planted']).rename(columns={'Planted':'planted'})
o=pd.concat([o1,o2]).dropna().astype({'Plot':str,'Install':str}).groupby(['Data','Install','Plot']).planted.agg(['min','max']).reset_index()
print('origin map plots',len(o),'conflicting',(o['min']!=o['max']).sum())
o=o.rename(columns={'Data':'source','Install':'inst','Plot':'plot','max':'porig'})[['source','inst','plot','porig']]
live=d[(d.status=='live')&(d.dbh>0)&(d.expf>0)].copy(); live['plot']=live['plot'].astype(str); live['inst']=live.inst.astype(str)
live['ba']=np.pi*(live.dbh/200)**2*live.expf; live['w2']=live.expf*live.dbh**2
g=live.groupby(['source','inst','plot','year']).agg(tph=('expf','sum'),ba=('ba','sum'),w2=('w2','sum'),tplant=('planted','max')).reset_index()
g=g.merge(o,on=['source','inst','plot'],how='left')
g['orig']=g.porig.fillna(g.tplant)
g['qmd']=np.sqrt(g.w2/g.tph)
print('plot-years',len(g),'origin from plot map',g.porig.notna().sum(),'fallback tree flag',(g.porig.isna()&g.tplant.notna()).sum(),'unknown',g.orig.isna().sum())
print(g.groupby(['source']).orig.agg(lambda x: f"{(x==1).sum()} planted/{(x==0).sum()} natural/{x.isna().sum()} na").to_string())
for v,s in g.groupby('orig'):
    s=s.sort_values('ba',ascending=False)
    print('orig',v,'n',len(s),'BA p95 %.1f max %.1f'%(s.ba.quantile(.95),s.ba.max()),'n>44.0:',(s.ba>44.0).sum(),'n>49.0:',(s.ba>49.0).sum())
    print(s.head(6)[['source','plot','year','tph','ba','qmd']].round(1).to_string(index=False))
