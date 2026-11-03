#!/bin/bash
# v105c master: Stage B (refit, deploy, natural level), dDBH CAL SE bootstrap (400, 3 cores), phase 1, phase 2, realism, Bakuzis compare, comparison table.
set -u; cd ~/jobs/koa_v105c_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1; L=v105c/logs
date +%s > v105c/out/T0_stageB_epoch.txt; echo "MASTER start $(date)"
bash v105c/stage_b.sh > $L/stage_b.log 2>&1; echo "stage_b $?"; tail -4 $L/stage_b.log
grep -q "STAGE_B DONE" $L/stage_b.log || { echo "STOP stage_b"; exit 1; }
bash v105c/backup_c.sh out/inc/boot_v103_dDBH.csv out/inc/boot_v103_dDBH_summary.csv out/inc/boot_v103_dDBH_L_NO.csv out/inc/boot_v103_dDBH_L_NO_summary.csv
Rscript --vanilla track2/inc/boot_v103.R dDBH 400 3 > $L/boot_dDBH_v105c.log 2>&1; echo "boot dDBH $? $(date)"; grep -v warn $L/boot_dDBH_v105c.log | tail -1
bash v105c/run_phase1_c.sh > $L/run_phase1_c.log 2>&1; echo "phase1 $?"; grep -E "GATE|DONE" $L/run_phase1_c.log
bash v105c/run_phase2_c.sh > $L/run_phase2_c.log 2>&1; echo "phase2 $?"; grep -E "DONE" $L/run_phase2_c.log
python3 v105c/realism_check.py engine_v103 v105c > $L/realism_v105c.log 2>&1; echo "realism v105c $?"
python3 v105c/realism_check.py ~/jobs/koa_v105_20261102/engine_v103 v105b > $L/realism_v105b.log 2>&1; echo "realism v105b $?"
python3 v105c/bakuzis_flags_compare.py > $L/bakuzis_flags_compare.log 2>&1; echo "bakuzis compare $?"
python3 v105c/compare_v105b_v105c.py > $L/compare_v105b_v105c.log 2>&1; echo "compare $?"
echo "MASTER DONE $(date)"
