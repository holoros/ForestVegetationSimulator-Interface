#!/bin/bash
cd ~/jobs/koa_v104_20261030
T0=$(date +%s); KOA_NJOINT=1000 Rscript --vanilla a5/pairmc/joint_draws_pairmc.R > a5/pairmc/logs/joint_draws_pairmc.log 2>&1; echo "joint exit $? $(( $(date +%s) - T0 )) s" >> a5/pairmc/logs/timings.txt
