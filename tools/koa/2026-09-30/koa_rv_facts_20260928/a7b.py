import pandas as pd, numpy as np
v=pd.read_csv('/home/aaron/jobs/koa_v102_20260918/inputs/AK_TREE_v102.csv', low_memory=False)
k=['Data','Install','Plot','Measure']
lv=v[(v.Status=='live')].copy()
lv['ba']=np.pi*(lv.DBH/200)**2*lv.EXPF
def f(df, strict=True):
    d=df.DBH.values; b=df.ba.values
    return pd.Series([b[(d>x) if strict else (d>=x)].sum() for x in d], index=df.index)
lv['bal_s']=lv.groupby(k,group_keys=False).apply(lambda df: f(df,True))
lv['bal_ge']=lv.groupby(k,group_keys=False).apply(lambda df: f(df,False))
pure=lv['pBA.AK']>=0.999
for c in ['bal_s','bal_ge']:
  d=(lv.BAL-lv[c]).abs()
  print(c,'pure: within 0.01',round((d[pure]<0.01).mean(),3),' mixed: within 0.01',round((d[~pure]<0.01).mean(),3))
print(lv[pure][['DBH','EXPF','BAL','bal_s','bal_ge','BA.perc','BAPH']].head(10).round(3).to_string())
r=(lv.BAL/lv.bal_s)[pure & (lv.bal_s>0.5)]
print('pure BAL/bal_s quantiles', r.quantile([.05,.25,.5,.75,.95]).round(3).to_dict())
