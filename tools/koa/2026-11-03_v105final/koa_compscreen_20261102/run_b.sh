#!/bin/bash
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
cd ~/jobs/koa_compscreen_20261102; echo "== 05_height $(date)"; Rscript 05_height.R > logs/05_height.log 2>&1; echo "exit $? $(date)"; echo ALLDONE
