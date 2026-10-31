# independent check of the joint draw multiplier spread on the v104 draws (a2/mc/out), mirrors a2/redteam2/mc.py first block
import pandas as pd, numpy as np, os
W=os.path.expanduser('~/jobs/koa_v104_20261030/')
K=pd.read_csv(W+'a2/mc/out/K_joint_draws.csv'); print(K.shape)
for c,vec in [('cal_dd_nat','d_'),('cal_dd_plt','d_'),('cal_dh_nat','h_'),('cal_dh_plt','h_')]:
    X=K[[x for x in K.columns if x.startswith(vec+'b')]].values; y=np.log(K[c].values)
    X1=np.c_[np.ones(len(X)),X]; b=np.linalg.lstsq(X1,y,rcond=None)[0]; r=y-X1@b
    print(c,'sd_log',round(y.std(),3),'R2 on vector',round(1-r.var()/y.var(),3),'resid sd_log',round(r.std(),3))
