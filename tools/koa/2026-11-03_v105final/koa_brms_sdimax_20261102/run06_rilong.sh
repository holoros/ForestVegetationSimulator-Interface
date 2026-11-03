#!/bin/bash
## AMENDMENT 2a: RI_LONG (4 chains x 6000, 4 cores) started after LQMM finishes (job stays <= 4 cores), then evaluation and,
## if RI_LONG passes either tier, 03_post.R with suffix _rilong. Chained so it completes without this session.
cd ~/jobs/koa_brms_sdimax_20261102
while ! grep -q "LQMM done" run05.log; do sleep 30; done
echo "RI_LONG start $(date)"
Rscript 02_fit_long.R > logs_02_RI_LONG_ad0.99_td12.log 2>&1
echo "RI_LONG fit done $(date) exit $?"
Rscript 06_eval_long.R > logs_06_eval_long.log 2>&1
echo "eval done $(date) exit $?"
if [ -f out/fits_used_rilong.csv ]; then Rscript 03_post.R out/fits_used_rilong.csv _rilong > logs_03_post_rilong.log 2>&1; echo "post rilong done $(date) exit $?"; else echo "RI_LONG failed both tiers: no 03_post run"; fi
touch run06.done
