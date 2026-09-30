import os, sys
ENG = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102"); sys.path.insert(0, ENG)
import numpy as np, pandas as pd
import regen_m1 as R, koa_longterm_validation as V
c = V.load(); V.stand_mortality = R._gated
R.set_params(None)
def run(cache):
    V.load = lambda: cache
    r = V.validate(); r = r[r.pid.str.contains('Kulani\\|12')]
    return r
base = run(c)
plt = c[1].copy(); i = plt.index[(plt.Data.astype(str).str.contains('DOFAW')) & (plt.Install.astype(str)=='Kulani') & (plt.Plot.astype(str)=='12')]
print('rows', len(i), plt.loc[i,'BYI'].values)
alt = plt.copy(); alt.loc[i,'BYI'] = 92.67
mod = run((c[0], alt, c[2]))
for nm, r in [('deployed', base), ('BYI 92.67', mod)]:
    r = r.iloc[0]
    print(nm, 'surv err %.3f QMD err %.2f BA err %.2f' % (r.obs_surv-r.pr_surv, r.obsQMD-r.prQMD, r.obsBAPH-r.prBAPH))
