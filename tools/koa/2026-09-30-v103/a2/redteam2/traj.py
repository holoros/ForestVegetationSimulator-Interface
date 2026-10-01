import pandas as pd, numpy as np, os
A=os.path.expanduser('~/jobs/koa_v103_20260930/a2/out/')
post=pd.read_csv(A+'traj_v103.csv'); pre=pd.read_csv(A+'traj_v103_prebalfix.csv'); g=pd.read_csv(A+'traj_gate.csv')
def summ(t,lab):
    rows=[]
    for (p,b),d in t.groupby(['planted','byi']):
        d=d.sort_values('year').reset_index(drop=True); y=d.year.values
        at=lambda c,a: float(d.loc[d.year==a,c].iloc[0])
        mai=d.VOL/d.year; r=d.year>=(2 if p else 10); i=mai[r].idxmax(); ip=d.SDI.idxmax()
        w=d[(d.year>=d.loc[ip,'year'])&(d.year<=d.loc[ip,'year']+100)]
        sl=np.polyfit(np.log(w.QMD),np.log(w.TPH),1)[0]
        rows.append(dict(v=lab,p=p,b=b,Q24=at('QMD',24),N24=at('TPH',24),B24=at('BAPH',24),Q40=at('QMD',40),V45=at('VOL',45),V52=at('VOL',52),
           Q100=at('QMD',100),N100=at('TPH',100),B100=at('BAPH',100),V100=at('VOL',100),H100=at('HT',100),pSDI=d.SDI.max(),pSDIy=int(d.loc[ip,'year']),
           MAIc=int(d.loc[i,'year']),MAIx=mai[i],rein=sl,pBAy=int(d.loc[d.BAPH.idxmax(),'year']),DMX40=at('DBHMAX',40)))
    return pd.DataFrame(rows)
S=pd.concat([summ(g,'v102'),summ(pre,'pre'),summ(post,'post')])
pd.set_option('display.width',300); pd.set_option('display.max_columns',40)
print(S.round(2).to_string(index=False))
for lab,t in [('pre',pre),('post',post)]:
  for p in (0,1):
    for c in ['QMD','BAPH','VOL','HT','TPH']:
        pv=t[t.planted==p].pivot(index='year',columns='byi',values=c)
        ok=(pv[264]>=pv[100])&(pv[450]>=pv[264]); bad=pv.index[~ok]
        print(lab,p,c,'inc share',round(ok.mean(),3),'first viol',(bad.min() if len(bad) else None),'n',len(bad))
  for b in (100,264,450):
    n=t[(t.planted==0)&(t.byi==b)].set_index('year').QMD; q=t[(t.planted==1)&(t.byi==b)].set_index('year').QMD
    x=n.index[n>q]; print(lab,'byi',b,'natQMD>plt from',x.min() if len(x) else None)
m=post.merge(pre,on=['planted','byi','year'],suffixes=('','_pre'))
for a in (40,52,100):
    s=m[m.year==a]
    print(a,[(int(r.planted),int(r.byi),round(100*(r.QMD/r.QMD_pre-1),1),round(100*(r.TPH/r.TPH_pre-1),1),round(100*(r.VOL/r.VOL_pre-1),1)) for r in s.itertuples()])
