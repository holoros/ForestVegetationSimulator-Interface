#!/usr/bin/env python3
"""attribute.py: applies the preregistered attribution rule to out/metrics_long.csv (collect.py). Writes out/attribution.csv and prints verdicts.
Failure present in D742 when: low-site natural culmination (pt_window) <= 10 or more than 5 yr from C742; Eichhorn median CV > 10% (per stratum);
Bakuzis FLAG count > C742; |pooled plot-level BA coverage - C742| > 0.02. A single revert R-x 'removes' a failure when its metric meets the same
condition that defines passing. 'Moved most' = largest change from D742 toward C742."""
import os, pandas as pd
J = os.path.expanduser("~/jobs/koa_v105attr_20261103"); L = pd.read_csv(f"{J}/out/metrics_long.csv")
def g(run, m):
    x = L[(L.run == run) & (L.metric == m)].value
    return None if x.empty else x.iloc[0]
REVS = [r for r in L.run.unique() if r.startswith(("R_", "P_"))]
F = {
 "low-site natural culmination": ("culmination pt | Even-aged natural|Low (142)", lambda v, c: v > 10 and abs(v - c) <= 5),
 "Eichhorn Even-aged natural": ("Eichhorn median CV % unrounded | Even-aged natural", lambda v, c: v <= 10),
 "Eichhorn Uneven-aged natural": ("Eichhorn median CV % unrounded | Uneven-aged natural", lambda v, c: v <= 10),
 "Eichhorn Even-aged planted": ("Eichhorn median CV % unrounded | Even-aged planted", lambda v, c: v <= 10),
 "Bakuzis flags": ("Bakuzis FLAG", lambda v, c: v <= c),
 "pooled BA coverage": ("coverage plotlevel BA | pooled", lambda v, c: abs(v - c) <= 0.02 + 1e-12),
}
rows = []
for name, (m, passes) in F.items():
    c = g("C742", m); d = g("D742", m)
    if c is None or d is None: rows.append(dict(failure=name, metric=m, verdict="metric missing")); continue
    c, d = float(c), float(d); present = not passes(d, c)
    r = dict(failure=name, metric=m, D742=d, C742=c, C742_passes=passes(c, c), present_in_D742=present)
    rem, mv = [], {}
    for R in REVS:
        v = g(R, m)
        if v is None: continue
        v = float(v); r[R] = v; mv[R] = (abs(d - c) - abs(v - c))   # movement toward C742
        if present and passes(v, c): rem.append(R)
    r["removed_by_single_revert"] = ";".join(rem) if present else "n/a (not present in D742)"
    if present and not rem:
        top = sorted(((k, x) for k, x in mv.items() if k.startswith("R_")), key=lambda kv: -kv[1])[:2]
        r["pairwise_needed"] = " + ".join(k for k, _ in top); r["movement_toward_C742"] = "; ".join(f"{k} {x:+.3g}" for k, x in sorted(mv.items(), key=lambda kv: -kv[1]))
    else:
        r["movement_toward_C742"] = "; ".join(f"{k} {x:+.3g}" for k, x in sorted(mv.items(), key=lambda kv: -kv[1]))
    rows.append(r)
A = pd.DataFrame(rows); A.to_csv(f"{J}/out/attribution.csv", index=False); print(A.to_string())
