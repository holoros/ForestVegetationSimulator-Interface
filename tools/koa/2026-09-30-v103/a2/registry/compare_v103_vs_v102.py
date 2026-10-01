"""compare_v103_vs_v102.py: leaf by leaf comparison of numbers_v103.json against numbers_v102.json -> numbers_v103_vs_v102.md and
build/leaves_v103_vs_v102.csv. List elements that are records are labelled by their text fields, so rows match by content rather than position."""
import json, math, os, re, pandas as pd
R = os.path.expanduser("~/jobs/koa_v103_20260930/a2/registry")
A = json.load(open(f"{R}/ref_numbers_v102.json")); B = json.load(open(f"{R}/numbers_v103.json"))
def flat(v, p=""):
    out = {}
    if isinstance(v, dict):
        for k, x in v.items(): out.update(flat(x, f"{p}.{k}" if p else str(k)))
    elif isinstance(v, list):
        seen = {}
        for i, x in enumerate(v):
            if isinstance(x, dict):
                lab = "|".join(str(y) for kk, y in x.items() if isinstance(y, str) and kk not in ("note", "reasons", "size_ratios_NO", "calibration_by_interval")) or str(i)
            else: lab = str(i)
            seen[lab] = seen.get(lab, 0) + 1; lab = lab if seen[lab] == 1 else f"{lab}#{seen[lab]}"
            out.update(flat(x, f"{p}[{lab}]"))
    elif isinstance(v, bool) or v is None or isinstance(v, str): out[p] = v
    elif isinstance(v, (int, float)): out[p] = float(v)
    return out
def num(x): return isinstance(x, float) and math.isfinite(x)
def pct(a, b): return None if not (num(a) and num(b)) or a == 0 else 100 * (b - a) / abs(a)
rows, leaves = [], []
for k in list(A) + [k for k in B if k not in A]:
    a = flat(A[k]["value"]) if k in A else {}; b = flat(B[k]["value"]) if k in B else {}
    sh = [x for x in a if x in b]
    for x in sh: leaves.append(dict(key=k, leaf=x, v102=a[x], v103=b[x], pct=pct(a[x], b[x])))
    pc = [pct(a[x], b[x]) for x in sh if not re.search(r'(^|\.)(p|p_value)$', x)]; pc = [abs(z) for z in pc if z is not None]
    scalar = list(a) == [""] or list(b) == [""]
    fmt = lambda v, d: ("null" if v is None else f"{v:.6g}" if isinstance(v, float) else str(v)) if scalar else (f"{len(d)} leaves" if d else "null")
    status = "new" if k not in A else "dropped" if k not in B else "null in v103" if B[k]["value"] is None else "null in v102" if A[k]["value"] is None else ""
    rows.append(dict(key=k, v102=fmt(a.get(""), a), v103=fmt(b.get(""), b), shared=len(sh), pct=(f"{pct(a[''], b['']):+.2f}" if scalar and sh and pct(a[''], b['']) is not None else (f"median {pd.Series(pc).median():.2f}, max {max(pc):.1f}" if pc else "")),
                     flag="FLAG" if pc and max(pc) > 5 else "", status=status))
L = pd.DataFrame(leaves); os.makedirs(f"{R}/build", exist_ok=True); L.to_csv(f"{R}/build/leaves_v103_vs_v102.csv", index=False)
new = [k for k in B if k not in A]; dropped = [k for k in A if k not in B]
L["v102n"] = pd.to_numeric(L.v102, errors="coerce"); L["v103n"] = pd.to_numeric(L.v103, errors="coerce")
H = L[L.pct.notna() & (L.v102n.abs() >= 0.01) & ~L.leaf.str.contains(r"(^|\.)(p|se|se_log|se_new|lo|hi|lo95|hi95|p_value|boot_se|aic|logLik)$|_lo|_hi|\.se|ci\]", regex=True)].copy()
H = H[~H.leaf.str.contains(r"bias|(^|\.)d[sq]$|(^|\.)dba$|diff|deaths|_r$|r2|surv_r|cor|slope", regex=True) & ~H.key.str.contains(r"_record|_v97|_v98|loio|joint_source_sets|joint_cor|surv_coef|eq5_|inc_variants|proto_", regex=True)]
H["apct"] = H.pct.abs(); top = H.sort_values("apct", ascending=False).groupby("key").head(1).head(10)
with open(f"{R}/numbers_v103_vs_v102.md", "w") as f:
    f.write("# numbers_v103 vs numbers_v102\n\n")
    f.write(f"Keys: v102 {len(A)}, v103 {len(B)}, new {len(new)}, dropped {len(dropped)}. Nulls in v103: {sum(v['value'] is None for v in B.values())}. ")
    f.write("For a composite key the percent column gives the median and the maximum absolute percent change over the numeric leaves present in both versions (leaf detail in build/leaves_v103_vs_v102.csv). FLAG marks any shared numeric leaf (p values excluded) moving more than 5 percent. Keys whose meaning is the before engine (suffix _record, _v97, _v98, clip_shares_v98) now hold engine_v102, so their v102 to v103 change is v99 to v102.\n\n")
    f.write("| key | v102 | v103 | shared leaves | percent change | flag | status |\n|---|---|---|---|---|---|---|\n")
    for r in rows: f.write(f"| {r['key']} | {r['v102']} | {r['v103']} | {r['shared']} | {r['pct']} | {r['flag']} | {r['status']} |\n")
    f.write("\n## New keys\n\n" + "\n".join(f"- {k}: {B[k]['note'][:160]}" for k in new) + "\n\n## Dropped keys\n\n" + ("\n".join(f"- {k}" for k in dropped) if dropped else "None.") + "\n")
    f.write("\n## Ten largest changes (one leaf per key, |v102| >= 0.01, SEs, p values, interval bounds, bias and difference leaves, correlations, fold level rows, coefficient tables and before keys excluded)\n\n| key | leaf | v102 | v103 | percent |\n|---|---|---|---|---|\n")
    for r in top.itertuples(): f.write(f"| {r.key} | {r.leaf} | {r.v102n:.4g} | {r.v103n:.4g} | {r.pct:+.1f} |\n")
print("rows", len(rows), "flagged", sum(r["flag"] == "FLAG" for r in rows), "new", new, "dropped", dropped)
print(top[["key", "leaf", "v102", "v103", "pct"]].to_string())
