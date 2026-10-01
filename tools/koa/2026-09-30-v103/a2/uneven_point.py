"""Point (no Monte Carlo) uneven-aged (gated M1 mortality as regen_m1.uneven_aged: import regen_m1, set_params(None), ua.stand_mortality = _gated) natural ingrowth scenario of regenerate_uneven_aged.py in one engine copy:
setp(None); project(byi, AGES); guarded_vol. Usage: python3 uneven_point.py <engine_dir> <tag>. Writes out/uneven_<tag>.csv."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); ENG = os.path.abspath(sys.argv[1]); TAG = sys.argv[2]
sys.path.insert(0, ENG); os.environ.setdefault("MPLCONFIGDIR", os.path.join(ENG, ".mplcache"))
os.chdir(ENG)
import numpy as np, pandas as pd
import regen_m1 as RM
RM.set_params(None)
import regenerate_uneven_aged as U
U.stand_mortality = RM._gated
rows = []
for byi, site in U.BYIS:
    RM.set_params(None); U.setp(None); pt, tj = U.project(byi, U.AGES)
    tj2 = tj.copy(); tj2["age"] = np.arange(1, len(tj2) + 1)
    vol, ht, hg, ht_raw = U.guarded_vol(byi, tj2)
    for a in U.AGES:
        r = tj2.iloc[a - 1]
        rows.append(dict(byi=byi, site=site, age=a, QMD=r.QMD, TPH=r.TPH, BAPH=r.BAPH, HT=float(ht[a - 1]), VOL=float(vol[a - 1])))
    print(TAG, byi, "done", flush=True)
pd.DataFrame(rows).to_csv(os.path.join(HERE, "out", f"uneven_{TAG}.csv"), index=False)
print(TAG, "done")
