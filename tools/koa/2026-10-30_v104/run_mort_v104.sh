#!/bin/bash
# A4-D2: natural mortality level re-solve on the v104 engine (dDBH_L_NO, Stage 3 refit, MORT_CAL reset to 1), PSP 122 2019-2023 interval excluded (23 natural intervals).
cd ~/jobs/koa_v104_20261030/a2
T0=$(date +%s)
KOA_OUTDIR=. python3 mort/calib_mort.py ../engine_v103 mort/v104 natural > ../a4/logs/calib_v104.log 2>&1
KOA_OUTDIR=. python3 mort/solve_mort.py mort/v104 natural >> ../a4/logs/calib_v104.log 2>&1
echo "exit $? $(( $(date +%s) - T0 )) s" >> ../a4/logs/calib_v104.log; echo ALLDONE >> ../a4/logs/calib_v104.log
