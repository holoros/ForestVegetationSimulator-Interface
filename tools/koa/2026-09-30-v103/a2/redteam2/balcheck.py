import os, sys, numpy as np
sys.dont_write_bytecode=True
E=os.path.abspath('eng'); sys.path.insert(0,E); os.chdir(E)
import regen_m1 as RM, run_candidates as RC, koa_equations as KE, koa_params as P
RM.set_params(None)
log=[]
orig=KE.bal_percentile_fraction_weighted
def wrap(d,w):
    f=orig(d,w); w=np.asarray(w); u=KE.bal_percentile_fraction(d)
    log.append((float((f*w).sum()/w.sum()), float((u*w).sum()/w.sum()))); return f
KE.bal_percentile_fraction_weighted=wrap
for pl in (0,1):
    log.clear(); t=RC.project(RC.wlist(pl,264),264,bool(pl),100,"M0")
    L=np.array(log); print('planted',pl,'n calls',len(L),'weighted frac yr1/50/100',L[[0,49,99],0].round(3),'unweighted (pre-fix) same list',L[[0,49,99],1].round(3))
