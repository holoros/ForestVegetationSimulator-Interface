#!/bin/bash
## orchestrator replacing run02.sh after PRIMARY started: SENS_UNCENTERED now on 2 cores; SENS_WEAK on 4 cores after PRIMARY ends (max 6 cores).
cd ~/jobs/koa_brms_sdimax_20261102
Rscript 02_fit_c.R SENS_UNCENTERED 0.8 2000 2 > logs_02_SENS_UNCENTERED_ad0.8.log 2>&1 &
while pgrep -f "02_fit.R PRIMARY" > /dev/null; do sleep 30; done
Rscript 02_fit_c.R SENS_WEAK 0.8 2000 4 > logs_02_SENS_WEAK_ad0.8.log 2>&1
wait
echo ALLDONE > run02.done
