# Stocking relative to the A-line of Baker and Scowcroft (2005): N_A = 10000 / (pi/4 * CW^2) * 0.9069, CW = a + b*QMD(m)
import pandas as pd, numpy as np
d=pd.read_csv('/home/aaron/jobs/koa_rv_mort_20260928/deliver/a5_tph_qmd_trajectories.csv')
lines={'Keauhou 1992 (windward)':(0.78,15.34),'Hakalau 2000 (windward)':(0.70,16.44),'Honomalino 2002 (leeward)':(-0.23,24.59)}
rows=[]
for (src,sc,site),g in d.groupby(['source','scenario','site']):
    g=g.sort_values('age')
    for nm,(a,b) in lines.items():
        cw=a+b*g.QMD/100.0; na=10000/(np.pi/4*cw**2)*0.9069; st=g.TPH/na*100
        above=g.age[st>=100]
        rows.append(dict(source=src,scenario=sc,site=site,line=nm,stock_age1=round(st.iloc[0],1),stock_age40=round(float(st[g.age==40].iloc[0]),1) if (g.age==40).any() else np.nan,
          stock_max=round(st.max(),1),age_max=int(g.age[st.idxmax()]),first_age_ge100=int(above.iloc[0]) if len(above) else None,
          first_age_ge80=int(g.age[st>=80].iloc[0]) if (st>=80).any() else None))
r=pd.DataFrame(rows); r.to_csv('stocking_summary.csv',index=False)
pd.set_option('display.width',250); print(r.to_string())
