"""compare_numbers.py (track 3): numbers_v99.json against numbers_v102.json. Writes numbers_v102_vs_v99.md (one pipe table row per key with the
record value, the v102 value and whether it moved), build/numbers_v102_vs_v99_leaves.csv (every scalar leaf with its relative change) and prints
the twenty leaves that moved most in relative terms among leaves whose record value is at least 0.01 in absolute value."""
import json, math, os, numpy as np, pandas as pd
H = os.path.expanduser("~"); J = f"{H}/jobs/koa_v102_20260918"; T = f"{J}/track3"
A = json.load(open(f"{J}/numbers_v99.json")); B = json.load(open(f"{T}/numbers_v102.json"))
assert list(A) == list(B)
def leaves(x, path=""):
    if isinstance(x, dict):
        for k, v in x.items(): yield from leaves(v, f"{path}.{k}" if path else str(k))
    elif isinstance(x, list):
        # list of records: key rows by their label columns when present so that added or reordered rows still align
        if x and all(isinstance(r, dict) for r in x):
            LAB = {"sample", "spec", "term", "resp", "origin", "source", "held_source", "held", "scenario", "site", "variant", "form", "label", "group", "quantity", "set", "by", "arm", "file", "var", "status", "prediction", "vector", "definition", "cluster", "fit", "table", "sources", "horizon", "byi", "planted", "n0"}
            labs = [k for k in x[0] if isinstance(x[0][k], str) and k in LAB]
            for i, r in enumerate(x):
                tag = "|".join(str(r.get(k)) for k in labs) if labs else str(i)
                yield from leaves({k: v for k, v in r.items() if k not in labs}, f"{path}[{tag}]")
        else:
            for i, v in enumerate(x): yield from leaves(v, f"{path}[{i}]")
    else:
        yield path, x
def isnum(v): return isinstance(v, (int, float)) and not isinstance(v, bool)
def short(v, n=70):
    s = json.dumps(v, default=float) if not isinstance(v, float) else f"{v:.6g}"
    return s if len(s) <= n else s[:n - 3] + "..."
rows = []; keyrows = []
for k in A:
    va, vb = A[k]["value"], B[k]["value"]
    if vb is None:
        keyrows.append(dict(key=k, record=short(va), v102="null", moved="NOT REGENERATED", note=B[k]["source"])); continue
    la = dict(leaves(va)); lb = dict(leaves(vb))
    common = [p for p in la if p in lb]; added = [p for p in lb if p not in la]; dropped = [p for p in la if p not in lb]
    nmoved = 0; worst = (0.0, None)
    for p in common:
        x, y = la[p], lb[p]
        if isnum(x) and isnum(y):
            if (math.isnan(x) if isinstance(x, float) else False) and (math.isnan(y) if isinstance(y, float) else False): rel = 0.0; d = 0.0
            else:
                d = y - x; rel = abs(d) / abs(x) if abs(x) > 0 else (0.0 if d == 0 else float("inf"))
            moved = not (abs(d) <= 1e-9 or (isinstance(d, float) and math.isnan(d)))
            rows.append(dict(key=k, path=p, record=x, v102=y, diff=d, rel_change=rel, moved=moved))
        else:
            moved = x != y; rows.append(dict(key=k, path=p, record=str(x), v102=str(y), diff=np.nan, rel_change=np.nan, moved=moved))
        if moved:
            nmoved += 1
            if isnum(x) and isnum(y) and abs(x) >= 0.01 and math.isfinite(rel) and rel > worst[0]: worst = (rel, p)
    if not isinstance(va, (dict, list)):
        keyrows.append(dict(key=k, record=short(va), v102=short(vb), moved="yes" if nmoved else "no", note=(f"relative change {worst[0]:.3g}" if worst[1] else "")))
    else:
        note = f"{len(common)} leaves, {nmoved} moved" + (f", {len(added)} added" if added else "") + (f", {len(dropped)} dropped" if dropped else "")
        if worst[1]: note += f", largest relative change {worst[0]:.3g} at {worst[1]}"
        keyrows.append(dict(key=k, record=short(va, 60), v102=short(vb, 60), moved="yes" if (nmoved or added or dropped) else "no", note=note))
L = pd.DataFrame(rows); L.to_csv(f"{T}/build/numbers_v102_vs_v99_leaves.csv", index=False)
K = pd.DataFrame(keyrows)
with open(f"{T}/numbers_v102_vs_v99.md", "w") as f:
    f.write("# numbers_v102 against numbers_v99, every key\n\nRecord is numbers_v99.json (v99, engine_joint of 2026-09-16). v102 is track3/numbers_v102.json. A key moved when any scalar leaf differs by more than 1e-9 or any label differs. Nested values are truncated, every leaf is in track3/build/numbers_v102_vs_v99_leaves.csv. Keys carrying the before comparison in v99 (suffix _record, _v97, _v98) carry the v99 engine in v102, so they read as moved.\n\n")
    f.write("| key | record value (v99) | v102 value | moved | note |\n|---|---|---|---|---|\n")
    for r in keyrows:
        f.write(f"| {r['key']} | {r['record'].replace('|', '/')} | {r['v102'].replace('|', '/')} | {r['moved']} | {r['note'].replace('|', '/')} |\n")
    n_moved = sum(r["moved"] == "yes" for r in keyrows); n_no = sum(r["moved"] == "no" for r in keyrows); n_nr = sum(r["moved"] == "NOT REGENERATED" for r in keyrows)
    f.write(f"\nKeys moved {n_moved}, unchanged {n_no}, not regenerated {n_nr}, total {len(keyrows)}.\n")
    num = L[L.moved & L.rel_change.notna() & np.isfinite(L.rel_change) & (L.record.apply(lambda v: isinstance(v, (int, float)) and abs(v) >= 0.01))].copy()
    num = num[~num.key.str.endswith(("_record", "_v97", "_v98"))]
    top = num.sort_values("rel_change", ascending=False).head(20)
    f.write("\n## Twenty leaves that moved most in relative terms\n\nAmong scalar leaves of regenerated keys other than the before keys, with a record value of at least 0.01 in absolute value.\n\n| key | leaf | record | v102 | relative change |\n|---|---|---|---|---|\n")
    for r in top.itertuples():
        f.write(f"| {r.key} | {r.path.replace('|', '/')} | {r.record:.6g} | {r.v102:.6g} | {r.rel_change:.3g} |\n")
print(K.moved.value_counts().to_string()); print(top.to_string())
