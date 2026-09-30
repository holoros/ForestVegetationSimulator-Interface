import pandas as pd, numpy as np
rng=np.random.default_rng(20260928)
p=pd.read_csv('/home/aaron/jobs/koa_fig2unc_20260927/out_oob_pairs_DATA.csv')
def st(o,f): r=o-f; return np.sqrt(np.mean(r**2)), 1-np.sum(r**2)/np.sum((o-o.mean())**2), np.mean(f-o)
for g in ['Kona','statewide']:
  q=p[p.model==g]
  for s in ['all','nonzero','zero']:
    r=q if s=='all' else (q[q.obs>0] if s=='nonzero' else q[q.obs==0])
    o=r.obs.values; f=r.oob.values; n=len(o); pt=st(o,f)
    B=np.array([st(o[i],f[i]) for i in (rng.integers(0,n,n) for _ in range(2000))])
    lo=np.nanpercentile(B,2.5,axis=0); hi=np.nanpercentile(B,97.5,axis=0)
    print(f"{g:9s} {s:7s} n={n} RMSE {pt[0]:.1f} ({lo[0]:.1f} to {hi[0]:.1f})  R2 {pt[1]:.3f} ({lo[1]:.3f} to {hi[1]:.3f})  mean bias pred-obs {pt[2]:+.1f} ({lo[2]:+.1f} to {hi[2]:+.1f})")
  nz=q[q.obs>0]; print('  nonzero cor(obs,oob)',round(np.corrcoef(nz.obs,nz.oob)[0,1],3), ' zero rows predicted >100:', int((q[q.obs==0].oob>100).sum()))
