#!/bin/bash
## AMENDMENT 1: RI_UNCENTERED restarted on 4 cores (all chains parallel) once SENS_UNCENTERED and SENS_WEAK ended; same seed 54321. Job stays <= 6 cores.
cd ~/jobs/koa_brms_sdimax_20261102
echo "RI start $(date)"
Rscript 02_fit_c.R RI_UNCENTERED 0.95 2000 4 > logs_02_RI_UNCENTERED_ad0.95.log 2>&1
echo "RI done $(date)"
