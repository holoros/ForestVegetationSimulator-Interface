"""years_grid_v104.py (A4-S): years for a tree to grow from the 2.5 cm recruitment size to the initial list QMD (9.6 cm natural, 7.2 cm planted)
under the calibrated Eq. 4 of the v104 engine, over BYI 100/264/450, CR 0.7/0.9, BAL 0/5 and BAPH 0/10 m2 ha-1 (supplement S5)."""
import os, sys, numpy as np, pandas as pd
J=os.path.expanduser('~/jobs/koa_v104_20261030'); ENG=J+'/engine_v103'; sys.path.insert(0,ENG); os.chdir(ENG); os.environ.setdefault('MPLCONFIGDIR','/tmp/mpl')
import koa_equations as KE, koa_params as KP, regen_m1 as RM; RM.set_params(None)
rows=[]
for planted,target in ((0,9.6),(1,7.2)):
    for byi in (100,264,450):
        for cr in (0.7,0.9):
            for bal in (0.0,5.0):
                for baph in (0.0,10.0):
                    dbh=2.5; n=0
                    while dbh<target and n<300:
                        dbh+=float(KE.LineageA.dDBH(np.array([dbh]),baph,np.array([bal]),np.array([cr]),byi,planted)[0]); n+=1
                    rows.append(dict(origin='planted' if planted else 'natural',target_cm=target,byi=byi,cr=cr,bal=bal,baph=baph,years=n))
d=pd.DataFrame(rows); d.to_csv(J+'/a4/sens/years_grid_v104.csv',index=False); print(d.groupby('origin').years.agg(['min','max']))
