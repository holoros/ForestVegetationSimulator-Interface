#!/bin/bash
# a5/loio/run_folds.sh: phase 1 refits (3 R processes, one core each), phase 2 chain per fold (sequential, calib uses 3 cores).
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
cd ~/jobs/koa_v104_20261030/a5/loio
T0=$(date +%s)
Rscript fit_folds.R "DOFAW|Kulani" "PSP|103" "PSP|106" "PSP|123" "PSP|204" > logs/fit_g1.log 2>&1 &
Rscript fit_folds.R "DOFAW|Laupahoehoe" "PSP|104" "PSP|107" "PSP|202" > logs/fit_g2.log 2>&1 &
Rscript fit_folds.R "DOFAW|Waiakea" "DOFAW|Waikamoi" "PSP|105" "PSP|108" "PSP|203" > logs/fit_g3.log 2>&1 &
wait; echo "fits done $(( $(date +%s) - T0 )) s"; grep FOLD logs/fit_g*.log
for f in "DOFAW|Kulani" "DOFAW|Laupahoehoe" "DOFAW|Waiakea" "DOFAW|Waikamoi" "PSP|103" "PSP|104" "PSP|105" "PSP|106" "PSP|107" "PSP|108" "PSP|123" "PSP|202" "PSP|203" "PSP|204"; do
  bash run_chain_fold.sh "$f" || echo "FOLD $f FAILED (chain)"; done
echo "all $(( $(date +%s) - T0 )) s"; echo ALLDONE
