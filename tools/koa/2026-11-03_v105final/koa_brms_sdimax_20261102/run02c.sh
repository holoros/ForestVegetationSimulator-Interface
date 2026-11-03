#!/bin/bash
## orchestrator (replaces run02.sh / run02b.sh): SENS_UNCENTERED on 2 cores now; SENS_WEAK on 4 cores once PRIMARY (pid 913792) ends. Max 6 cores.
cd ~/jobs/koa_brms_sdimax_20261102
Rscript 02_fit_c.R SENS_UNCENTERED 0.8 2000 2 > logs_02_SENS_UNCENTERED_ad0.8.log 2>&1 &
while kill -0 913792 2>/dev/null; do sleep 30; done
Rscript 02_fit_c.R SENS_WEAK 0.8 2000 4 > logs_02_SENS_WEAK_ad0.8.log 2>&1
wait
echo ALLDONE > run02.done
