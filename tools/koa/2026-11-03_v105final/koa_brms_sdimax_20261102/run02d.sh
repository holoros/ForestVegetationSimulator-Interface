#!/bin/bash
## AMENDMENT 1: RI_UNCENTERED on 2 cores once SENS_WEAK or SENS_UNCENTERED ends (keeps this job at <= 6 cores).
cd ~/jobs/koa_brms_sdimax_20261102
while [ $(pgrep -fc "02_fit_c.R --args SENS_") -ge 2 ]; do sleep 30; done
echo "RI start $(date)"
Rscript 02_fit_c.R RI_UNCENTERED 0.95 2000 2 > logs_02_RI_UNCENTERED_ad0.95.log 2>&1
echo "RI done $(date)"
