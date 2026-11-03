#!/bin/bash
cd ~/jobs/koa_rdcomp_20261102/constrained/rev2; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
for c in K3c3 P05 P5; do Rscript --vanilla 02r_fit.R $c > logs/02r_fit_$c.log 2>&1; echo "$c $? $(date)"; done
echo RUN_R2 DONE
