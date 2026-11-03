#!/bin/bash
cd ~/jobs/koa_rdcomp_20261102/constrained
printf "K0c\nK3c1\nK3c2\n" | xargs -P 3 -I{} sh -c 'Rscript 02c_fit.R {} > logs/02c_fit_{}.log 2>&1'
Rscript 02c_fit.R K3pc > logs/02c_fit_K3pc.log 2>&1
echo MAIN DONE $(date) >> logs/run_main_c.log
