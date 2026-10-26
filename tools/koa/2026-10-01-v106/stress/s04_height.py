# Stress test script 4: static height frame rebuilt from the tree list, population-average prediction from the Table 3 vector,
# bias in both directions, R2/RMSE/slope, asymptote contrast BYI 450 vs 100. Writes the frame for the LOIO R job.
import pandas as pd, numpy as np, json, os
J=os.path.expanduser('~/jobs/koa_v103_20260930'); O=J+'/a3/pending/v106/stress'
t=pd.read_csv(J+'/inputs/AK_TREE_v103.csv',low_memory=False); tj=pd.read_csv(J+'/frames/final/tree_join_v103.csv',low_memory=False)
t['byi']=tj.byi.values
f=t[(t.Status=='live')&(t.DBH>0)&(t.HT>0)&(t.Data!='Kualoa')&t.byi.notna()].copy()
P=json.load(open(J+'/out/v103_constants.json'))['HT_P']
f['rDBH2']=f.DBH/f['DBH.max']
f['pred']=(P['a0']+P['a1']*f.byi/100)*(1-np.exp(-P['b']*f.DBH))**P['c']*np.exp(P['g1']*np.log(f.BAPH+1)+P['g2']*f.rDBH2)
e=f.pred-f.HT
R=dict(n=len(f),n_inst=f.groupby(['Data','Install']).ngroups,r2=1-((f.HT-f.pred)**2).sum()/((f.HT-f.HT.mean())**2).sum(),
 rmse=float(np.sqrt((e**2).mean())),bias_pred_minus_obs=float(e.mean()),bias_nat=float(e[f.Origin_x.eq('Natural')].mean()) if 'Origin_x' in f else None,
 mean_obs=float(f.HT.mean()),rdbh_maxdiff=float((f.rDBH2-f.rDBH).abs().max()))
pl=json.load(open(J+'/out/v103_constants.json'))
R['slope_obs_on_pred']=float(np.polyfit(f.pred,f.HT,1)[0])
A100=P['a0']+P['a1']*1.0; A450=P['a0']+P['a1']*4.5; R['asym100']=A100; R['asym450']=A450; R['asym_diff_m']=A450-A100; R['asym_pct']=100*(A450/A100-1)
# origin from tree_join
f['planted']=tj.loc[f.index,'planted']
R['bias_by_planted']=f.assign(e=e).groupby('planted').e.mean().round(4).to_dict()
f[['Data','Install','Plot','Measure','Tree','DBH','HT','BAPH','rDBH2','byi']].rename(columns={'rDBH2':'rDBH'}).to_csv(O+'/s04_height_frame.csv',index=False)
json.dump(R,open(O+'/s04_height.json','w'),indent=1,default=str); print(json.dumps(R,indent=1,default=str))
