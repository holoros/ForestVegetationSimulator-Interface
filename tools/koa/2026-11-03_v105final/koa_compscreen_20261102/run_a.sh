#!/bin/bash
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
cd ~/jobs/koa_compscreen_20261102
for s in 01_stage12 02_stage3 03_ingrowth 04_hcb; do [ -f $s.R ] && { echo "== $s $(date)"; Rscript $s.R > logs/$s.log 2>&1; echo "exit $? $s $(date)"; }; done
echo ALLDONE
