#!/usr/bin/env bash
# run_mort_planted.sh (v103 registry, 2026-09-30): calib_mort.py and solve_mort.py unchanged. Planted level on the registry copy of
# engine_v103 (deployed constants, as v102 ran planted on engine_v102). Natural level gate on engine_nocal (MORT_CAL (1,1)),
# to be compared with a2/mort/v103/H_mort_level_natural.csv (MORT_CAL 2.54275, SE_LOG 0.24335).
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; cd $R
for w in planted natural; do mkdir -p mort/v103_$w; cp -p $J/frames/final/plot_intervals_origin_v103.csv mort/v103_$w/plot_intervals_origin.csv; done
echo "== v103 planted $(date)"
KOA_OUTDIR=mort/v103_planted python3 mort/calib_mort.py $R/engine $R planted
KOA_OUTDIR=mort/v103_planted python3 mort/solve_mort.py $R planted > mort/v103_planted/solve.log 2>&1
echo "== v103 natural gate $(date)"
KOA_OUTDIR=mort/v103_natural python3 mort/calib_mort.py $R/engine_nocal $R natural
KOA_OUTDIR=mort/v103_natural python3 mort/solve_mort.py $R natural > mort/v103_natural/solve.log 2>&1
echo "MORT DONE $(date)"
