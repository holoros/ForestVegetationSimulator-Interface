#!/bin/bash
cd ~/jobs/koa_brms_sdimax_20261102
for F in PRIMARY SENS_WEAK SENS_UNCENTERED; do
  Rscript 02_fit.R $F 0.8 2000 > logs_02_${F}_ad0.8.log 2>&1
done
echo ALLDONE > run02.done
