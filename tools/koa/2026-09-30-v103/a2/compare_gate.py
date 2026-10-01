"""compare_gate.py A B: max abs difference on every numeric column shared by two csvs (same row order)."""
import sys, numpy as np, pandas as pd
a = pd.read_csv(sys.argv[1]); b = pd.read_csv(sys.argv[2])
print("rows", len(a), len(b), "cols", list(a.columns) == list(b.columns))
worst = 0.0
for c in a.columns:
    if pd.api.types.is_numeric_dtype(a[c]) and pd.api.types.is_numeric_dtype(b[c]):
        d = float(np.nanmax(np.abs(a[c].to_numpy(float) - b[c].to_numpy(float)))) if len(a) == len(b) else np.inf
        worst = max(worst, d); print(f"  {c:12s} max|diff| {d:.3e}")
    else:
        print(f"  {c:12s} non-numeric equal:", bool((a[c].astype(str) == b[c].astype(str)).all()))
print("WORST", f"{worst:.3e}", "PASS" if worst < 1e-9 and len(a) == len(b) else "FAIL")
