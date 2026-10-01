import sys, numpy as np; sys.path.insert(0,'eng')
import koa_equations as KE, koa_params as KP
def hand(d,w):
    d=np.array(d,float); w=np.array(w,float); out=[]
    for i in range(len(d)):
        oth=[j for j in range(len(d)) if j!=i]
        num=sum(w[j] for j in oth if d[j]>=d[i]); den=sum(w[j] for j in oth)
        out.append(num/den if den>0 else 0)
    return np.array(out)
cases=[([30,20,10,10],[4,2,1,3]),([10,10,10],[1,2,3]),([5,40,40,12,12,12,33],[741,59.5,59.5,1e-5,59.5,741,59.5]),([10,20],[1e-5,50]),([10,20,30],[50,1e-5,1e-5])]
for d,w in cases:
    a=KE.bal_percentile_fraction_weighted(d,w); h=hand(d,w)
    print(np.round(a,5), np.round(h,5), np.abs(a-h).max())
rng=np.random.default_rng(1); mx=0; mxeq=0
for k in range(2000):
    n=rng.integers(2,40); d=rng.choice(np.arange(5,60,5),n).astype(float); w=rng.choice([1e-5,1,3,59.5,741],n)
    mx=max(mx,np.abs(KE.bal_percentile_fraction_weighted(d,w)-hand(d,w)).max())
    mxeq=max(mxeq,np.abs(KE.bal_percentile_fraction_weighted(d,np.full(n,7.0))-KE.bal_percentile_fraction(d)).max())
print('random max diff vs hand',mx,'equal-w vs unweighted rule',mxeq)
print('stand_bal switch', KP.BAL_PERCENTILE_WEIGHTED, KE.stand_bal(10.0,dbh=np.array([30,20,10.]),expf=np.array([1,1,100.])), KE.stand_bal(10.0,dbh=np.array([30,20,10.])))
