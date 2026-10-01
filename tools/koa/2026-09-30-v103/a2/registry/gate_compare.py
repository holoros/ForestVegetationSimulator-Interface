"""gate_compare.py A B [tol]: compare two csv files cell by cell (numeric columns by max abs difference, others by equality).
Prints one line PASS or FAIL. Coordinate columns are refused."""
import sys, pandas as pd, numpy as np
a, b = sys.argv[1], sys.argv[2]; tol = float(sys.argv[3]) if len(sys.argv) > 3 else 1e-6
A = pd.read_csv(a); B = pd.read_csv(b)
bad = [c for c in list(A.columns) + list(B.columns) if c.lower() in ("lat", "lon", "latitude", "longitude", "x", "y")]
assert not bad, "coordinate like column"
if A.shape != B.shape or list(A.columns) != list(B.columns):
    print("FAIL shape or columns", a, A.shape, b, B.shape); sys.exit(1)
worst = 0.0; mism = 0
for c in A.columns:
    if pd.api.types.is_numeric_dtype(A[c]) and pd.api.types.is_numeric_dtype(B[c]):
        x, y = A[c].to_numpy(float), B[c].to_numpy(float)
        both = np.isfinite(x) & np.isfinite(y); mism += int((np.isfinite(x) != np.isfinite(y)).sum())
        if both.any(): worst = max(worst, float(np.nanmax(np.abs(x[both] - y[both]))))
    else:
        mism += int((A[c].astype(str) != B[c].astype(str)).sum())
print(("PASS" if worst <= tol and mism == 0 else "FAIL"), "max abs diff", f"{worst:.3g}", "non numeric or NA mismatches", mism, "rows", len(A), a.split("/")[-1])
