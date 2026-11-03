#!/bin/bash
## AMENDMENT 2: 04_env.R (Hawaii Island FIA only) on the fit of record, after RI_LONG + evaluation finish (keeps the job <= 4 cores).
cd ~/jobs/koa_brms_sdimax_20261102
while [ ! -f run06.done ]; do sleep 60; done
REC=$(Rscript -e 'library(data.table); r <- fread("out/record_amend2.csv"); cat(r[role == "of_record", fit])' 2>/dev/null)
echo "fit of record: ${REC} $(date)"
if [ "$REC" = "RI_LONG" ]; then Rscript 04_env.R out/plot_sdimax_rilong.csv SDImax_mean _rilong > logs_04_env_rilong.log 2>&1
elif [ "$REC" = "LQMM_tau0.95" ]; then Rscript 04_env.R out/plot_sdimax_lqmm.csv SDImax _lqmm > logs_04_env_lqmm.log 2>&1
else echo "no fit of record: 04_env.R not run"; fi
echo "env done $(date) exit $?"
touch run08.done
