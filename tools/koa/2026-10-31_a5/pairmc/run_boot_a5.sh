#!/bin/bash
# amendment A5-B: BOOT and BOOT_PPB rerun with the 386 complete bootstrap draws
cd ~/jobs/koa_v104_20261030/a5/pairmc; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 PAIRMC_VARS=BOOT,BOOT_PPB PAIRMC_PREFIX=raw_boot_w
L=logs/timings_a5.txt; T1=$(date +%s)
for w in 0 1 2; do python3 pairmc_a5.py main $w 3 > logs/a5_boot_w$w.log 2>&1 & done; wait
echo "boot rerun $(( $(date +%s) - T1 )) s" >> $L
python3 summarize_a5.py > logs/a5_summary.log 2>&1; echo "summary exit $?" >> $L
