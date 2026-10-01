#!/bin/bash
# Natural mortality level recalibration (calib_mort.py + solve_mort.py, form mult), exactly as track 2, on engine_v103 with MORT_CAL (1, 1).
cd ~/jobs/koa_v103_20260930/a2
T0=$(date +%s)
KOA_OUTDIR=. python3 mort/calib_mort.py ../engine_v103 mort/v103 natural > logs/calib_v103.log 2>&1
KOA_OUTDIR=. python3 mort/solve_mort.py mort/v103 natural >> logs/calib_v103.log 2>&1
echo "exit $? $(( $(date +%s) - T0 )) s" >> logs/calib_v103.log; echo ALLDONE >> logs/calib_v103.log
