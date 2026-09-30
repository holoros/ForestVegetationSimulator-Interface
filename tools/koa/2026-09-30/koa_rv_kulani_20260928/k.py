import os, sys
ENG = os.path.expanduser("~/jobs/koa_v102_20260918/track2/engine_v102"); sys.path.insert(0, ENG)
import numpy as np, pandas as pd
import regen_m1 as R, koa_longterm_validation as V
c = V.load()
print(type(c), (list(c.keys()) if isinstance(c, dict) else [type(x) for x in c]) )
for x in (c.values() if isinstance(c, dict) else c):
    if isinstance(x, pd.DataFrame): print(x.columns.tolist()[:30], len(x))
