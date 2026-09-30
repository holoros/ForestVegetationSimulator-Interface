import pandas as pd, numpy as np
a=pd.read_csv('/home/aaron/jobs/koa_v102_20260918/inputs/AK.TREE.incr_v102.csv', low_memory=False)
g=pd.read_csv('/home/aaron/jobs/koa_v102_20260918/inputs/PLT.GEO.V2_v102.csv', low_memory=False, usecols=['Data','Install','Plot'])
a=a.rename(columns={'Data.0':'Data','Install.0':'Install','Plot.0':'Plot','Tree.0':'Tree'})
k=['Data','Install','Plot']
for c in k: a[c]=a[c].astype(str); g[c]=g[c].astype(str)
print('geo rows',len(g),'unique',len(g.drop_duplicates()))
m=a.merge(g,on=k)
print('merged',len(m))
m['YIP']=m['t.1']-m['t.0']; m['ann']=m.dDBH/m.YIP
base=(m['DBH.0']>0)&(m['Status.0']=='live')&(m['DBH.1']>0)&(m['Status.1']=='live')&(m.YIP>0)
print('dDBH: live-live YIP>0',base.sum(),' ann==0',(base&(m.ann==0)).sum(),' ann<0',(base&(m.ann<0)).sum(),' ann>=10',(base&(m.ann>=10)).sum(),' kept',(base&(m.ann>0)&(m.ann<10)).sum())
st=(m['DBH.0']>0)&(m['Status.0']=='live')&(m.YIP>0)
dead=m['Status.1']!='live'
print('SURV: live at t0 YIP>0',st.sum(),' dead at t1',(st&dead).sum(),'| ann<=0',(st&(m.ann<=0)).sum(),' dead',(st&(m.ann<=0)&dead).sum(),' live',(st&(m.ann<=0)&~dead).sum(),' ann>=10',(st&(m.ann>=10)).sum(),' dead',(st&(m.ann>=10)&dead).sum(),' kept',(st&(m.ann>0)&(m.ann<10)).sum(),' kept dead',(st&(m.ann>0)&(m.ann<10)&dead).sum())
print('Status.1 among dead:', m[st&dead]['Status.1'].value_counts().to_dict(), ' dead with DBH.1<=0 or NA', ((m[st&dead]['DBH.1'].fillna(0))<=0).sum())
