#!/bin/bash
## AMENDMENT 2b: LQMM point fit + B=500 plot-cluster bootstrap, 4 cores
cd ~/jobs/koa_brms_sdimax_20261102
echo "LQMM start $(date)"
Rscript 05_lqmm.R ${1:-500} 4 > logs_05_lqmm.log 2>&1
echo "LQMM done $(date) exit $?"
