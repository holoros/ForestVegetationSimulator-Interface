"""v102 against v101 leaf diff over the 93 registry keys. Writes build/numbers_v102_vs_v101_leaves.csv."""
import json, os, numpy as np, pandas as pd
A=json.load(open("numbers_v102.json")); B=json.load(open(os.path.expanduser("~/jobs/koa_v101_20260917/track3/numbers_v101.json")))
def leaves(o, p=""):
    if isinstance(o, dict):
        for k,v in o.items(): yield from leaves(v, f"{p}.{k}" if p else str(k))
    elif isinstance(o, list):
        for i,v in enumerate(o): yield from leaves(v, f"{p}[{i}]")
    else: yield p, o
rows=[]; movedkeys=[]
for k in A:
    la=dict(leaves(A[k]["value"])); lb=dict(leaves(B.get(k,{}).get("value")))
    km=False
    for p in sorted(set(la)|set(lb)):
        a,b=la.get(p),lb.get(p)
        num = isinstance(a,(int,float)) and isinstance(b,(int,float)) and not isinstance(a,bool) and not isinstance(b,bool)
        if num:
            d=float(a)-float(b); ch=abs(d)>1e-12
            rel=abs(d)/abs(b) if abs(b)>1e-12 else np.nan
        else:
            d=np.nan; ch=(a!=b); rel=np.nan
        if ch: km=True
        rows.append(dict(key=k, leaf=p, v101=b, v102=a, diff=d, rel_change=rel, moved=ch))
    if km: movedkeys.append(k)
d=pd.DataFrame(rows); d.to_csv("build/numbers_v102_vs_v101_leaves.csv", index=False)
print("leaves", len(d), "moved", int(d.moved.sum()), "| keys moved", len(movedkeys), "of", len(A))
print("keys UNCHANGED v101->v102:", [k for k in A if k not in movedkeys])
n=d[d.moved & d.rel_change.notna() & (pd.to_numeric(d.v101, errors="coerce").abs()>0.01)].sort_values("rel_change", ascending=False)
print(n.head(25).to_string(index=False))
