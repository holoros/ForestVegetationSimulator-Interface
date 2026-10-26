# Stress test v106/s104, script 1: tree list, Table 1, Table 2, S1.1, S2.1, S33 counts, origin means, cap shares.
# Independent code. No coordinate columns are read (none exist in these files). Writes only to stress/.
import pandas as pd, numpy as np, json, os
J=os.path.expanduser('~/jobs/koa_v103_20260930'); O=J+'/a3/pending/v106/stress'
R={}
t=pd.read_csv(J+'/inputs/AK_TREE_v103.csv',low_memory=False)
tj=pd.read_csv(J+'/frames/final/tree_join_v103.csv',low_memory=False)
assert len(t)==len(tj) and (t.Data.values==tj.source.values).all() and (t.Tree.astype(str).values==tj.tree.astype(str).values).all()
t['byi']=tj.byi.values
live=t[(t.Status=='live')&(t.DBH>0)].copy()
R['n_live']=len(live); R['n_inst']=live.groupby(['Data','Install']).ngroups; R['n_plot']=live.groupby(['Data','Install','Plot']).ngroups
# Table 2 rows
def st(x): x=pd.Series(x).dropna(); return dict(n=int(len(x)),mean=round(x.mean(),3),sd=round(x.std(),3),min=round(x.min(),3),med=round(x.median(),3),max=round(x.max(),3))
T2={}
T2['DBH']=st(live.DBH); T2['HT']=st(live.HT[live.HT>0])
nk=live[live.Data!='Kualoa']
T2['BAPH_noKualoa']=st(nk.BAPH); T2['BAPH_all']=st(live.BAPH); T2['BALl_noKualoa']=st(nk.BALl); T2['BAL_old_noKualoa']=st(nk.BAL)
h=pd.read_csv(J+'/frames/final/AK_HCB_v103.csv'); T2['CR']=st(1-h.HCB/h.HT)
NO=pd.read_csv(J+'/frames/final/dDBH_NO_v103_model.csv'); NOh=pd.read_csv(J+'/frames/final/dHT_NO_v103_model.csv')
cal=NO[NO.Origin.notna()].copy(); calh=NOh[NOh.Origin.notna()].copy()
cal['a']=cal.dDBH/cal.YIP; calh['a']=calh.dHT/calh.YIP
T2['dDBH_cal']=st(cal.a); T2['dHT_cal']=st(calh.a); T2['dDBH_all']=st(NO.dDBH/NO.YIP); T2['dHT_all']=st(NOh.dHT/NOh.YIP)
T2['dDBH_n_lt_0.005']=int((cal.a<0.005).sum())
R['T2']=T2
# origin means
R['dDBH_mean_by_planted']=cal.groupby('Planted').a.agg(['mean','size']).round(3).reset_index().to_dict('records')
# Table 1: records, BYI, median interval
lb=live[live.byi.notna()]
R['T1_nbyi']=len(lb); R['T1_rec_mean_byi']=round(lb.byi.mean(),2); R['T1_rec_median_byi']=round(lb.byi.median(),1)
pl=lb.groupby(['Data','Install','Plot']).byi.first()
R['T1_plot_median_byi']=round(pl.median(),1); R['T1_nplots_byi']=len(pl)
R['T1_nobyi_by_source']=live[live.byi.isna()].Data.value_counts().to_dict()
R['T1_mean_byi_by_source']=lb.groupby('Data').byi.mean().round(1).to_dict()
R['T1_records_by_source']=live.Data.value_counts().to_dict()
CS=pd.read_csv(J+'/frames/final/dDBH_CS_v103_model.csv')
R['T1_medint_CS']=CS.groupby('Data').YIP.median().to_dict(); R['T1_medint_CS_total']=CS.YIP.median()
R['CS_YIP_range']=[CS.YIP.min(),CS.YIP.max()]; R['CS_YIP_max_by_source']=CS.groupby('Data').YIP.max().to_dict()
R['CS_n']=len(CS)
# installations with >=2 measurement years
yrs_all=t.groupby(['Data','Install']).Measure.nunique(); yrs_live=live.groupby(['Data','Install']).Measure.nunique()
R['inst_ge2_all']=int((yrs_all>=2).sum()); R['inst_ge2_live']=int((yrs_live>=2).sum())
R['sources_single_visit_plots']={s:bool((t[t.Data==s].groupby(['Install','Plot']).Measure.nunique()==1).all()) for s in t.Data.unique()}
# Kulani 42
k=live[(live.Install.astype(str).str.contains('Kulani'))]
R['kulani_plots_byi']=k.groupby('Plot').agg(n=('DBH','size'),byi=('byi','first')).reset_index().astype(str).to_dict('records')
R['live_byi_zero']=live[live.byi==0].groupby(['Data','Install','Plot']).size().astype(int).reset_index().astype(str).to_dict('records')
R['NO_byi_min']=float(NO.byi.min()) if 'byi' in NO else float(NO.BYI.min())
R['HCB_byi_min']=float(h.BYI.min())
sh=pd.read_csv(J+'/frames/final/static_height_frame_v103.csv',low_memory=False)
R['static_height_n']=len(sh)
# S33 reconstruction from the tree table
t2=t.sort_values(['Data','Install','Plot','Tree','Measure'])
g=t2.groupby(['Data','Install','Plot','Tree'],sort=False)
nx=g.shift(-1)
pr=t2.assign(DBH1=nx.DBH,HT1=nx.HT,St1=nx.Status,M1=nx.Measure)
pr=pr[pr.M1.notna()].copy(); pr['YIP']=pr.M1-pr.Measure
R['S33_all_consec']=len(pr)
ll=pr[(pr.Status=='live')&(pr.St1=='live')&(pr.DBH>0)&(pr.DBH1>0)].copy()
R['S33_live_live']=len(ll)
ll['ad']=(ll.DBH1-ll.DBH)/ll.YIP; ll['ah']=(ll.HT1-ll.HT)/ll.YIP
sd=ll[(ll.ad>0)&(ll.ad<10)]; R['S33_screened_d']=len(sd)
sh_=sd[(sd.ah>0)&(sd.ah<10)]; R['S33_screened_h_nested']=len(sh_)
R['S33_screened_h_independent']=int(((ll.ah>0)&(ll.ah<10)).sum())
R['S33_CS']= [len(CS), len(pd.read_csv(J+'/frames/final/dHT_CS_v103_model.csv'))]
R['S33_NO_all']=[len(NO),len(NOh)]; R['S33_NO_origin']=[len(cal),len(calh)]
R['S33_NO_consec_firstlast']={'d':NO.groupby(['consec','firstlast']).size().reset_index().astype(str).to_dict('records'),'h':NOh.groupby(['consec','firstlast']).size().reset_index().astype(str).to_dict('records')}
R['S33_NO_noorigin_sources']={'d':NO[NO.Origin.isna()].Data.value_counts().to_dict(),'h':NOh[NOh.Origin.isna()].Data.value_counts().to_dict(),'d_noorigin_byi_na':int(NO[NO.Origin.isna()].BYI.isna().sum())}
# screened intervals without a plot record: in sd but not in CS
key=['Data','Install','Plot','Tree']
cs=CS.copy(); cs['k']=cs.Data.astype(str)+'|'+cs.Install.astype(str)+'|'+cs.Plot.astype(str)+'|'+cs.Tree.astype(str)+'|'+cs['t.0'].astype(str)
sd=sd.copy(); sd['k']=sd.Data.astype(str)+'|'+sd.Install.astype(str)+'|'+sd.Plot.astype(str)+'|'+sd.Tree.astype(str)+'|'+sd.Measure.astype(int).astype(str)
R['S33_screened_d_notin_CS']=sd[~sd.k.isin(cs.k)].Data.value_counts().to_dict()
R['S33_CS_notin_screened']=int((~cs.k.isin(sd.k)).sum())
# Table 2 / cap: observed planted share > 2 m/yr on calibration frame
R['dHT_obs_planted_gt2']=round(float((calh[calh.Planted==1].a>2).mean()),4); R['dHT_obs_planted_ge2']=round(float((calh[calh.Planted==1].a>=2).mean()),4)
R['dHT_obs_natural_gt2']=round(float((calh[calh.Planted==0].a>2).mean()),4); R['n_planted_h']=int((calh.Planted==1).sum())
C=json.load(open(J+'/out/v103_constants.json'))['DHT']; b=C['coef']; c=C['c_planted'],C['c_natural']
H=calh.copy(); size=H['HT.0']; BAL=H['BALl.0']; CR=H['CRl.0']
xb=(b['b0']+b['b1']*np.log(size+1)+b['b2']*size+b['b3']*BAL**2/np.log(size+5)+b['b4']*np.log(BAL+1)+b['b5']*np.log(CR)
    +b['b6']*np.sqrt(H['BAPH.0']*size)+b['b7']*H.Planted*np.minimum(size,20)+b['b8']*np.log(H.BYI)+b['b9']*H.Planted)
H['pred']=np.exp(xb)*np.where(H.Planted==1,C['c_planted'],C['c_natural'])
R['cap_firstyear_planted_ge2']=round(float((H[H.Planted==1].pred>=2).mean()),4); R['cap_firstyear_natural_ge2']=round(float((H[H.Planted==0].pred>=2).mean()),4)
json.dump(R,open(O+'/s01_data.json','w'),indent=1,default=str)
print(json.dumps(R,indent=1,default=str))
