# A3 pending tables for v105/s103: Table 2, Table S2 BAPH and mortality, gross MAI, Table S32 MC columns. 2026-09-30
import json, numpy as np, pandas as pd
J='/home/aaron/jobs/koa_v103_20260930/'
T=pd.read_csv(J+'inputs/AK_TREE_v103.csv',low_memory=False)
live=T[(T.Status=='live')&(T.DBH>0)]
def st(x,dec):
    x=pd.Series(x).dropna(); f=lambda v:f"{v:,.{dec}f}"
    return [f"{len(x):,}",f(x.mean()),f(x.std()),f(x.min()),f(x.median()),f(x.max())]
H=pd.read_csv(J+'frames/final/AK_HCB_v103.csv'); H=H[(H.HT>0)&H.HCB.notna()]; cr=((H.HT-H.HCB)/H.HT).clip(0,1)
_d=pd.read_csv(J+'frames/final/dDBH_NO_v103_model.csv',usecols=['DBH.0','DBH.1','YIP']); dd=(_d['DBH.1']-_d['DBH.0'])/_d.YIP   # annualized over the interval
_h=pd.read_csv(J+'frames/final/dHT_NO_v103_model.csv',usecols=['HT.0','HT.1','YIP']); dh=(_h['HT.1']-_h['HT.0'])/_h.YIP
M2='m^2^ ha^−1^'
rows=[['DBH (cm)']+st(live.DBH,1),['Height (m)']+st(live.HT[live.HT>0],1),['Crown ratio']+st(cr,2),
      [f'BAPH ({M2})']+st(live.BAPH,1),[f'BAL ({M2})']+st(live.BALl,1),
      ['ΔDBH (cm yr^−1^)']+st(dd,2),['ΔHT (m yr^−1^)']+st(dh,2)]
json.dump({'source':'inputs/AK_TREE_v103.csv live DBH>0 (BAPH repaired, BAL live-list percentile BALl); frames/final/AK_HCB_v103.csv; frames/final/d*_NO_v103_model.csv annualized over YIP','rows':rows},open('table2_v103.json','w'),ensure_ascii=False,indent=1)
# S2
S={}
Tn=T[T.Status.isin(['live','dead'])]
def fmt(v): return '<0.1' if 0<v<0.05 else f"{v:.1f}"
for src,d in live.groupby('Data'):
    a=Tn[Tn.Data==src]; S[src]={'baph':fmt(d.BAPH.mean()),'mort':f"{100*(a.Status=='dead').mean():.1f}"}
S['Total']={'dbh':f"{live.DBH.mean():.1f}",'ht':f"{live.HT[live.HT>0].mean():.1f}",'baph':fmt(live.BAPH.mean()),'mort':f"{100*(Tn.Status=='dead').mean():.1f}"}
json.dump(S,open('tableS2_v103.json','w'),indent=1)
# gross MAI
P=pd.read_csv(J+'a2/registry/s05/v103/05_refit_table6_points.csv'); lab={'Low':'Low (100)','Medium':'Medium (264)','High':'High (450)'}
G={f"{r.scenario}|{lab[r.site]}|{int(r.age)}":float(r.mai_gross) for r in P.itertuples()}
json.dump(G,open('gross_mai_v103.json','w'),indent=1)
# S32 MC culmination
E=pd.read_csv(J+'engine_v103/out_m1/reps_evenaged_M1.csv'); U=pd.read_csv(J+'engine_v103/out_m1/uneven_aged_reps_M1.csv'); U['scen']='Uneven-aged natural'
tj=pd.read_csv(J+'engine_v103/out_m1/traj_M1.csv'); ut=pd.read_csv(J+'engine_v103/out_m1/uneven_aged_traj_M1.csv')
bl={100:'Low (100)',264:'Medium (264)',450:'High (450)'}
def cul(age,vol):
    o=np.argsort(age); age=np.asarray(age)[o]; vol=np.asarray(vol)[o]; m=(age>=1)&(age<=100); age,vol=age[m],vol[m]; mai=vol/age
    w=(age>=10); win=int(age[w][np.argmax(mai[w])])
    mins=[i for i in range(1,len(mai)-1) if mai[i]<mai[i-1] and mai[i]<=mai[i+1]]
    start=mins[0] if mins else 0
    k=np.arange(start,len(mai)); j=k[np.argmax(mai[k])]
    inter=int(age[j]) if (mins and j<len(mai)-1 and j>start) else (None if mins else (int(age[j]) if 0<j<len(mai)-1 else None))
    return win,inter
def q(x): x=np.asarray(x,float); return f"{np.median(x):.0f} ({np.percentile(x,2.5):.0f} to {np.percentile(x,97.5):.0f})"
MC={}
sc_map={'nat':'Even-aged natural','plt':'Even-aged planted'}
print(E.scen.unique()[:5])
for (sc,b),d in pd.concat([E,U]).groupby(['scen','byi']):
    scn=sc if sc.startswith(('Even','Uneven')) else sc_map.get(sc, sc)
    res=[cul(g.year.values,g.VOL.values) for _,g in d.groupby('rep')]
    win=[r[0] for r in res]; it=[r[1] for r in res if r[1] is not None]
    if scn.startswith('Uneven'): p=ut[ut.BYI==b]; pw,_=cul(p.age.values,p.Vol.values)
    else:
        o='plt' if 'planted' in scn else 'nat'; p=tj[(tj.origin==o)&(tj.byi==b)]; pw,_=cul(p.year.values,p.VOL.values)
    MC[f"{scn}|{bl[int(b)]}"]={'pt_window':str(pw),'med_window':q(win),'share10':f"{np.mean(np.array(win)==10):.2f}".rstrip('0').rstrip('.') if np.mean(np.array(win)==10) not in (0,1) else str(int(np.mean(np.array(win)==10))),'med_int':q(it) if it else 'none','share_none':f"{1-len(it)/len(res):.3g}",'n_reps':len(res)}
json.dump(MC,open('culmination_mc_v103.json','w'),indent=1)
print(json.dumps(rows,ensure_ascii=False)); print(S); print({k:round(v,2) for k,v in G.items() if k.endswith(('|40','|100'))}); print(json.dumps(MC,indent=0))
