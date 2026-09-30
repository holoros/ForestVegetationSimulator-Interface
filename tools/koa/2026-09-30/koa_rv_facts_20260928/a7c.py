import pandas as pd, numpy as np
v=pd.read_csv('/home/aaron/jobs/koa_v102_20260918/inputs/AK_TREE_v102.csv', low_memory=False)
k=['Data','Install','Plot','Measure']
v['ba']=np.pi*(v.DBH/200)**2*v.EXPF
lv=v[v.Status=='live'].copy()
print('BAL vs BAPH*(1-BA.perc): share within 0.01', round(((lv.BAL-lv.BAPH*(1-lv['BA.perc'])).abs()<0.01).mean(),3))
def chk(df):
    df=df.copy(); n=len(df)
    df['prank']=df.DBH.rank(method='max')/n
    tot=df.ba.sum(); df['cumba_le']=df.DBH.apply(lambda x: df.ba[df.DBH<=x].sum())/tot if tot>0 else np.nan
    df['n']=n; return df
for lab,sub in [('live only',lv),('all status',v)]:
  s=sub.groupby(k,group_keys=False).apply(chk)
  for c in ['prank','cumba_le']:
    print(lab,c,'BA.perc match within 0.005:', round(((s['BA.perc']-s[c]).abs()<0.005).mean(),3))
