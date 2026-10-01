# Stress test script 3: validation numbers recomputed from engine point outputs; every error is projected minus observed.
import pandas as pd, numpy as np, json, os, glob
J=os.path.expanduser('~/jobs/koa_v103_20260930'); O=J+'/a3/pending/v106/stress'; R={}
v=pd.read_csv(J+'/a2/closeout/validation/val_v103_plotlevel.csv')
R['plots']=v[['pid','origin','obs_surv_w','pr_surv','obsQMD','prQMD','obsBAPH','prBAPH']].round(2).astype(str).to_dict('records')
fu=pd.read_csv(J+'/a2/closeout/validation/fia_plotunits_v103.csv')
two=fu[fu.pid.isin(['FIA|15-1-1-2647','FIA|15-1-1-4895'])]
R['fia15_n']=two.n_records0.tolist(); R['fia15_qmd_err_mean']=round(float((two.prQMD-two.obsQMD).mean()),3); R['fia15_surv_err_mean']=round(float((two.pr_surv-two.obs_surv_w).mean()),3)
R['fia15_each']=two.assign(eQ=two.prQMD-two.obsQMD,es=two.pr_surv-two.obs_surv_w)[['pid','n_records0','eQ','es']].round(3).astype(str).to_dict('records')
# trajectory points
p=pd.read_csv(J+'/a2/figs/data/LT_v103_points.csv')
p['es']=p.pr_surv-p.obs_surv_w; p['eQ']=p.prQMD-p.obsQMD; p['eb']=p.prBAPH-p.obsBAPH
R['LT_npts']=len(p); R['LT_nplots']=p.pid.nunique()
bins=[0,5,10,20,35,52]; lab=['1-5','6-10','11-20','21-35','36-52']; p['hz']=pd.cut(p.h,bins,labels=lab)
dead=(p.obs_surv_w<=1e-9)
R['alldead_visits']=p[dead][['pid','tk','h','es']].round(3).astype(str).to_dict('records')
def summ(d): return dict(n=len(d),plots=d.pid.nunique(),sb=round(d.es.mean(),3),sr=round(np.sqrt((d.es**2).mean()),3),qb=round(d.eQ.mean(),2),bb=round(d.eb.mean(),1))
R['S27_incl']={f'{o}_{h}':summ(d) for (o,h),d in p.groupby(['planted','hz'],observed=True)}
R['Fig5_excl']={f'{o}_{h}':summ(d) for (o,h),d in p[~dead].groupby(['planted','hz'],observed=True)}
k=p[p.pid=='DOFAW|Kulani|12']; k3=k[k.h>=36]
R['kulani_36_52']=dict(n=len(k3),h=k3.h.tolist(),surv=round(k3.es.mean(),3),ba=round(k3.eb.mean(),2))
# S28 held-out from the earlier-system points (each long natural plot from the run that excludes its own installation)
D=os.path.expanduser('~/jobs/koa_zenodo_180/work_v102arms/v102_arms/s24_heldout')
long={'Kulani':'DOFAW|Kulani|23','Laupahoehoe':'DOFAW|Laupahoehoe|41','Waiakea':'DOFAW|Waiakea|24','Waikamoi':'DOFAW|Waikamoi|25'}
hs=[]
for inst,pid in long.items():
    q=pd.read_csv(f'{D}/LT_lo{inst}_points.csv'); q=q[q.pid==pid]; hs.append(q)
h=pd.concat(hs); h['es']=h.pr_surv-h.obs_surv; h['eQ']=h.prQMD-h.obsQMD; h['eb']=h.prBAPH-h.obsBAPH; h['hz']=pd.cut(h.h,bins,labels=lab)
R['S28_heldout']={str(z):dict(n=len(d),sb=round(d.es.mean(),3),sr=round(np.sqrt((d.es**2).mean()),3),qb=round(d.eQ.mean(),2),bb=round(d.eb.mean(),2),br=round(np.sqrt((d.eb**2).mean()),2)) for z,d in h.groupby('hz',observed=True)}
R['S28_heldout_all']=dict(n=len(h),sb=round(h.es.mean(),3),sr=round(np.sqrt((h.es**2).mean()),3),qb=round(h.eQ.mean(),2),bb=round(h.eb.mean(),2),br=round(np.sqrt((h.eb**2).mean()),2))
c=pd.read_csv(f'{D}/LT_ctrl_summary.csv'); c=c[c.origin=='natural']
R['S28_ctrl_summary_raw_sign']=c[['horizon','n_points','surv_bias','qmd_bias','ba_bias']].round(3).astype(str).to_dict('records')
w=c.n_points; R['S28_ctrl_pooled_from_summary']=dict(sb=round(float((c.surv_bias*w).sum()/w.sum()),3),qb=round(float((c.qmd_bias*w).sum()/w.sum()),2),bb=round(float((c.ba_bias*w).sum()/w.sum()),2))
# 23-unit earlier-system set (deployed factor): natural survival bias pred minus obs
m=pd.read_csv(J+'/a2/closeout/validation/val_v102_subplot_mirror.csv')
R['u23_n']=len(m); R['u23_nat_surv_bias']=round(float((m[m.planted==0].pr_surv-m[m.planted==0].obs_surv_w).mean()),3)
R['u23_nat_surv_bias_count']=round(float((m[m.planted==0].pr_surv-m[m.planted==0].obs_surv_count).mean()),3)
# planted mortality level
L=pd.read_csv(J+'/a2/registry/mort/v103_planted/H_mort_level_planted.csv'); R['planted_level']=L.iloc[0][['level','plot_lo95','plot_hi95','n_intervals','n_plots','n_inst']].astype(str).to_dict()
I=pd.read_csv(J+'/a2/registry/mort/v103_planted/H_mort_intervals_planted_mult.csv')
yc=[x for x in I.columns if x.lower() in ('yip','yrs','len','years')]
if yc: R['planted_int_n']=len(I); R['planted_int_le2']=round(float((I[yc[0]]<=2).mean()),3); R['planted_int_median']=float(I[yc[0]].median())
else: R['planted_int_cols']=list(I.columns)
json.dump(R,open(O+'/s03_val.json','w'),indent=1,default=str); print(json.dumps(R,indent=1,default=str))
