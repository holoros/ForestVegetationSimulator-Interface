#!/usr/bin/env python3
"""v105c/compare_v105b_v105c.py: repair_v105b/compare_v104_vB.py with A = koa_v105_20261102 (v105b, read only) and B = this job (v105c);
columns v104 -> v105b and v105 -> v105c in the output (renamed after the run); the site-ratio row uses 418 vs 142 for both."""
import os, runpy, pandas as pd
W = os.path.expanduser("~/jobs/koa_v105c_20261102"); os.environ["KOA_B"] = W; os.environ["KOA_OUTP"] = f"{W}/v105c/out/compare_v105b_v105c"
runpy.run_path(f"{W}/v105c/compare_v105b_v105c_core.py", run_name="__main__")
p = f"{W}/v105c/out/compare_v105b_v105c.csv"; D = pd.read_csv(p).rename(columns={"v104": "v105b", "v105": "v105c", "source_v104": "source_v105b", "source_v105": "source_v105c"}); D.to_csv(p, index=False)
print(len(D), "rows;", int((D.v105b.astype(str) != D.v105c.astype(str)).sum()), "differ")
