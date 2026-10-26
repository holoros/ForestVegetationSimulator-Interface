# compute_v106_addendum.py: task 6 by-source maxima and the 623 to 924 source; task 9d summary of the BYI error layer outputs. No coordinates read.
import json, pandas as pd
J='/home/aaron/jobs/koa_v103_20260930/'
S=pd.read_csv(J+'out/repair/plotyear_stand_before_after.csv',low_memory=False)
PL=pd.read_csv(J+'inputs/AK_PLT_v103.csv',low_memory=False).drop_duplicates(['Data','Install','Plot'])[['Data','Install','Plot','Origin']]
for c in ['Install','Plot']: S[c]=S[c].astype(str); PL[c]=PL[c].astype(str)
S=S.merge(PL,on=['Data','Install','Plot'],how='left')
n=S[(S.Origin=='Natural')&(S.nlive_all>=5)]
out={'natural_ge5_by_source':{}}
for s,g in n.groupby('Data'):
    a=g.loc[g.BAPH.idxmax()]; b=g.loc[g.QMD.idxmax()]; c=g.loc[g.SDI.idxmax()]
    out['natural_ge5_by_source'][s]=dict(n=len(g),BAPH_max=round(a.BAPH,2),BAPH_at=f'{a.Install} {a.Plot} {a.Measure}',QMD_max=round(b.QMD,2),QMD_at=f'{b.Install} {b.Plot} {b.Measure}',SDI_max=round(c.SDI,1),SDI_at=f'{c.Install} {c.Plot} {c.Measure}')
q=pd.read_csv(J+'frames/final/plot_intervals_v103.csv'); q=q[(q.Data=='DOFAW')&(q.planted==0)]
out['plot_intervals_v103_DOFAW_natural_max_sdi']=q.groupby(['Install','Plot']).sdi.max().round(1).reset_index().astype(str).values.tolist()
d=S[(S.Data=='DOFAW')&(S.Origin=='Natural')]
out['plotyear_DOFAW_natural_max_SDI']=d.groupby(['Install','Plot']).agg(SDI=('SDI','max'),SDI_dep=('SDI_dep','max')).round(1).reset_index().astype(str).values.tolist()
W='/home/aaron/jobs/koa_fig2unc_20260927/'
out['byi_error_layer']=dict(local_rmse_table=pd.read_csv(W+'out/local_rmse_table.csv').to_dict(orient='records'),
    u_quantiles=pd.read_csv(W+'out/u_quantiles.csv').to_dict(orient='records'),
    fig2u_log=[l.strip() for l in open(W+'fig2u.log') if l.startswith(('cells','arch','isl'))])
json.dump(out,open('compute_v106_addendum.json','w'),indent=1,default=str)
print(json.dumps(out,indent=0,default=str)[:3000])
