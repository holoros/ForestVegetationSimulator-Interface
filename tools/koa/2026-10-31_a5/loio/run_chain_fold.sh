#!/bin/bash
# a5/loio/run_chain_fold.sh <fold> : engine copy -> patch fold constants -> natural level re-solve (held-out intervals removed) -> set MORT_CAL -> plot-level validation.
# Requires fits/fit_<tag>.csv (fit_folds.R). Uses at most 3 cores (calib_mort_loio.py Pool(3)).
set -e
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 PYTHONDONTWRITEBYTECODE=1
L=~/jobs/koa_v104_20261030/a5/loio; W=~/jobs/koa_v104_20261030
FOLD="$1"; TAG=$(echo "$FOLD" | tr '|' '_'); E=$L/engines/engine_$TAG; M=$L/mort/$TAG
T0=$(date +%s); echo "== $FOLD start $(date)"
rm -rf "$E"; mkdir -p $L/engines "$M"
cp -rL $W/engine_v103 "$E"; rm -rf "$E/__pycache__"
python3 $L/patch_fold.py "$E" $L/fits/fit_$TAG.csv
python3 - "$FOLD" "$M" <<'PY'
import sys, pandas as pd, os
f, M = sys.argv[1], sys.argv[2]
I = pd.read_csv(os.path.expanduser("~/jobs/koa_v104_20261030/a2/mort/v104/plot_intervals_origin.csv"))
k = I.Data.astype(str) + "|" + I.Install.astype(str)
keep = I[k != f] if f != "NONE" else I
nat = lambda d: int(((d.planted == 0) & (~d.removal.astype(bool))).sum())
print("intervals table rows", len(I), "->", len(keep), "; natural non-removal", nat(I), "->", nat(keep))
keep.to_csv(os.path.join(M, "plot_intervals_origin.csv"), index=False)
PY
cd $L; KOA_OUTDIR=. python3 $L/calib_mort_loio.py "$E" "$M" natural > "$M/calib.log" 2>&1
KOA_OUTDIR=. python3 $W/a2/mort/solve_mort.py "$M" natural >> "$M/calib.log" 2>&1
grep -E "intervals|CURVES DONE|SOLVE DONE|dropping" "$M/calib.log" || true
python3 $L/set_mortcal_fold.py "$E" "$M/H_mort_level_natural.csv"
cd $L; python3 $L/plotlevel_validation_loio.py "$E" "$TAG" > $L/val/run_$TAG.log 2>&1
grep -E "CHECK|units|MORT_CAL" $L/val/run_$TAG.log
echo "== $FOLD done $(( $(date +%s) - T0 )) s"
