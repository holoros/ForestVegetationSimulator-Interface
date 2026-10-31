#!/bin/bash
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
cd ~/jobs/koa_v104_20261030/a5/loio
T0=$(date +%s); Rscript fit_folds.R NONE; echo "exit $? $(( $(date +%s) - T0 )) s"; echo ALLDONE
