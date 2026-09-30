#!/bin/bash
# Natural mortality level recalibration, exactly as track 2 (calib_mort.py + solve_mort.py, form mult), on the patched engines.
cd ~/jobs/koa_refit_20260929
for arm in refit2 refit2_live; do
  E=engine_$arm; J=mort/$arm
  KOA_OUTDIR=. python3 mort/calib_mort.py $E $J natural > logs/calib_$arm.log 2>&1
  KOA_OUTDIR=. python3 mort/solve_mort.py $J natural >> logs/calib_$arm.log 2>&1
  echo "$arm exit $?" >> logs/calib_$arm.log
done
echo ALLDONE > logs/calib_all2.done
