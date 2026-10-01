# Stress test script 2: projection outputs (engine point runs) and observed density envelopes.
import pandas as pd, numpy as np, json, os
J=os.path.expanduser('~/jobs/koa_v103_20260930'); O=J+'/a3/pending/v106/stress'; M=J+'/engine_v103/out_m1'
R={}
tr=pd.read_csv(M+'/traj_M1.csv'); un=pd.read_csv(M+'/uneven_aged_traj_M1.csv')
tr['SDIq']=tr.TPH*(tr.QMD/25.4)**1.605; un['SDIq']=un.TPH*(un.QMD/25.4)**1.605
def slope(d,q,n): s=d[(d.y>=11)&(d.y<=100)]; return round(float(np.polyfit(np.log(s[q]),np.log(s[n]),1)[0]),3)
def cul(age,mai):
    a=np.asarray(age); m=np.asarray(mai)
    i=next((k for k in range(1,len(m)-1) if m[k]<=m[k-1] and m[k]<=m[k+1]),0)
    j=i+int(np.argmax(m[i:])); return int(a[j])
out={}
for (o,b),d in tr.groupby(['origin','byi']):
    d=d.sort_values('year').rename(columns={'year':'y'})
    g=(d.VOL+d.MORT_VOL.cumsum())/d.y
    out[f'{o}_{b}']=dict(reineke_11_100=slope(d,'QMD','TPH'),max_SDI_col=round(d.SDI.max(),1),max_SDIq=round(d.SDIq.max(),1),max_BA=round(d.BAPH.max(),2),
      vol40=round(float(d[d.y==40].VOL.iloc[0]),2),vol100=round(float(d[d.y==100].VOL.iloc[0]),2),C40=round(float(d[d.y==40].VOL.iloc[0])*0.510*0.47,2),
      net_cul=cul(d.y,d.VOL/d.y),gross_cul=cul(d.y,g),vol_peak_age=int(d.loc[d.VOL.idxmax(),'y']),
      mean_mrealised_100=round(float(d.m_realised.mean()),4),mean_mstand_100=round(float(d.m_stand.mean()),4),
      ann_stem_loss_geo=round(float(1-(d.TPH.iloc[-1]/d.TPH.iloc[0])**(1/(len(d)-1))),4),qmd40=round(float(d[d.y==40].QMD.iloc[0]),2))
R['even']=out
uo={}
for b,d in un.groupby('BYI'):
    d=d.sort_values('age').rename(columns={'age':'y'})
    g=(d.Vol+d.MORT_VOL.cumsum())/d.y
    uo[str(b)]=dict(reineke_11_100=slope(d,'QMD','TPH'),max_SDI=round(d.SDI.max(),1),max_BA=round(d.BAPH.max(),2),net_cul=cul(d.y,d.Vol/d.y),gross_cul=cul(d.y,g))
R['uneven']=uo
# SC behaviour scenarios
sc=pd.read_csv(J+'/a2/figs/data/SC_trajectories.csv')
s=[]
for (gp,o,l),d in sc.groupby(['group','origin','label']):
    d=d.sort_values('year').rename(columns={'year':'y'}); a40=d[d.y==40].iloc[0]; a100=d[d.y==100].iloc[0]
    s.append(dict(group=gp,origin=o,label=l,TPH40=round(a40.TPH,1),D100_40=round(a40.D100,2),DBHMAX40=round(a40.DBHMAX,2),QMD40=round(a40.QMD,2),QMD100=round(a100.QMD,2),
       TY40=round(a40.total_yield,2),reineke=slope(d,'QMD','TPH')))
R['SC']=s
# observed envelopes from the tree list (live, DBH>0, EXPF>0), stand columns per plot-year
t=pd.read_csv(J+'/inputs/AK_TREE_v103.csv',low_memory=False); tj=pd.read_csv(J+'/frames/final/tree_join_v103.csv',low_memory=False); t['planted']=tj.planted.values
py=t[(t.Status=='live')&(t.DBH>0)].groupby(['Data','Install','Plot','Measure']).agg(SDI=('SDI','first'),BAPH=('BAPH','first'),pl=('planted','max'),n=('DBH','size')).reset_index()
dn=py[(py.Data=='DOFAW')&(py.pl==0)]
R['DOFAW_nat_plot_maxSDI']=dn.groupby(['Install','Plot']).agg(maxSDI=('SDI','max'),nyrs=('Measure','nunique'),maxBA=('BAPH','max')).round(1).reset_index().astype(str).to_dict('records')
r=py[py.Data=='DOFAW'].sort_values('BAPH').iloc[-1]; R['DOFAW_maxBA']=[r.Install,str(r.Plot),int(r.Measure),round(r.BAPH,2)]
R['PSP_maxBA']=round(py[py.Data=='PSP'].BAPH.max(),2)
# SDI recomputed independently from live stems: sum EXPF*(DBH/25.4)^1.605 over all species
lv=t[(t.Status=='live')&(t.DBH>0)&(t.EXPF>0)]
sd=lv.assign(s=lv.EXPF*(lv.DBH/25.4)**1.605,ba=lv.EXPF*0.00007854*lv.DBH**2).groupby(['Data','Install','Plot','Measure']).agg(sdi=('s','sum'),ba=('ba','sum')).reset_index()
R['note_koa_only_recompute']='AK_TREE holds koa rows only; stand columns are all-species rebuilt values'
R['DOFAW_koa_only_maxSDI']=sd[sd.Data=='DOFAW'].groupby(['Install','Plot']).sdi.max().round(1).reset_index().astype(str).to_dict('records')
json.dump(R,open(O+'/s02_proj.json','w'),indent=1,default=str); print(json.dumps(R,indent=1,default=str))
