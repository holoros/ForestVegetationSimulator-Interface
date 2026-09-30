# FIA damage/disturbance attribution for the six FIA validation subplots (R2 c7). Aggregate counts only; no identifiers printed.
import pandas as pd, numpy as np
P=pd.read_csv('/home/aaron/jobs/koa_rv_mort_20260928/out_a2/point_with_level.csv')
P=P[P.pid.str.startswith('FIA')].copy()
P['inst']=P.pid.str.split('|').str[1]; P['SUBP']=P.pid.str.split('|').str[2].astype(int)
k=P.inst.str.split('-',expand=True).astype(int); P['STATECD'],P['UNITCD'],P['COUNTYCD'],P['PLOT']=k[0],k[1],k[2],k[3]
P['group']=np.where(P.obs_surv<0.5,'heavy','other')
T=pd.read_csv('/home/aaron/jobs/koa_rv_byi_20260928/in/HI_TREE.csv',low_memory=False)
C=pd.read_csv('/home/aaron/jobs/koa_rv_byi_20260928/in/HI_COND.csv',low_memory=False)
key=['STATECD','UNITCD','COUNTYCD','PLOT']
T=T.merge(P[key+['SUBP','group']],on=key+['SUBP'])
print('plots per group', P.groupby('group')[key].apply(lambda g: g.drop_duplicates().shape[0]).to_dict(), 'subplots', P.group.value_counts().to_dict())
print('tree rows', len(T), 'INVYR', sorted(T.INVYR.unique()))
sp=T.SPCD.value_counts(); print('SPCD counts', sp.to_dict())
koa=sp.index[0]
for g,d in T.groupby('group'):
    print('\n== group',g)
    print('status by INVYR (all spp)'); print(pd.crosstab(d.INVYR,d.STATUSCD))
    dk=d[d.SPCD==koa]; print('status by INVYR (top SPCD)'); print(pd.crosstab(dk.INVYR,dk.STATUSCD))
    last=d[d.INVYR==d.INVYR.max()]; dead=last[last.STATUSCD==2]
    for col in ['AGENTCD','DAMAGE_AGENT_CD1','DAMAGE_AGENT_CD2','DAMAGE_AGENT_CD3','DMG_AGENT1_CD_PNWRS','DMG_AGENT2_CD_PNWRS','MORTYR','STANDING_DEAD_CD','MORTCD','DECAYCD','RECONCILECD']:
        if col in dead: print('dead at last visit',col, dead[col].value_counts(dropna=False).to_dict())
    print('dead koa AGENTCD', dead[dead.SPCD==koa].AGENTCD.value_counts(dropna=False).to_dict())
    livelast=last[last.STATUSCD==1]
    for col in ['DAMAGE_AGENT_CD1','DMG_AGENT1_CD_PNWRS','DAMTYP1']:
        if col in livelast: print('live at last visit',col, livelast[col].value_counts(dropna=False).to_dict())
Cm=C.merge(P[key+['group']].drop_duplicates(),on=key)
for g,d in Cm.groupby('group'):
    print('\n== COND group',g)
    print(d[['INVYR','CONDID','COND_STATUS_CD','DSTRBCD1','DSTRBYR1','DSTRBCD2','DSTRBYR2','DSTRBCD3','TRTCD1','TRTYR1','TRTCD2','TRTCD3','FIRE_SRS','GRAZING_SRS','STDORGCD','FORTYPCD']].sort_values(['INVYR','CONDID']).to_string(index=False))
print('\n== transitions')
for g,d in T[T.INVYR==2019].groupby('group'):
    dd=d[d.STATUSCD==2]
    print(g,'dead2019 by PREV_STATUS_CD', pd.crosstab(dd.PREV_STATUS_CD.fillna(-1), dd.AGENTCD.fillna(-1)).to_dict())
    print(g,'koa live2010', int(((T.group==g)&(T.INVYR==2010)&(T.STATUSCD==1)&(T.SPCD==koa)).sum()), 'koa live2019', int(((d.STATUSCD==1)&(d.SPCD==koa)).sum()), 'koa dead2019 prevlive', int(((dd.PREV_STATUS_CD==1)&(dd.SPCD==koa)).sum()))
