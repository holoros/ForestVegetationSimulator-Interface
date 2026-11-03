#!/bin/bash
# v105d master (after stage_b_d.sh): figure patches, dHT K3c1h full-refit bootstrap (400, 4 cores) and vector-fixed re-solve (400), phase 1, phase 2,
# realism (dDBH and dHT, three engines), Bakuzis three-way, comparison tables, build tarball.
set -u; cd ~/jobs/koa_v105d_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1; L=v105d/logs
echo "MASTER start $(date)"
grep -q "STAGE_B DONE" $L/stage_b.log || { echo "STOP: stage B not done"; exit 1; }
python3 v105d/patch_figs_v105d.py > $L/patch_figs.log 2>&1; echo "patch_figs $?"; cat $L/patch_figs.log
bash v105d/backup_d.sh out/inc/boot_v103_dHT.csv out/inc/boot_v103_dHT_summary.csv out/inc/boot_v103_dHT_resolveonly.csv
Rscript --vanilla track2/inc/boot_v103.R dHT 400 4 > $L/boot_dHT_v105d.log 2>&1; echo "boot dHT $? $(date)"; grep -v warn $L/boot_dHT_v105d.log | tail -1
grep -q "BOOT DONE dHT" $L/boot_dHT_v105d.log || { echo "STOP: dHT bootstrap"; exit 1; }
Rscript --vanilla stageB/boot_resolve_dht_v105.R 4 > $L/boot_resolve_dht_v105d.log 2>&1; echo "resolve dHT $?"; tail -1 $L/boot_resolve_dht_v105d.log
bash v105d/run_phase1_d.sh > $L/run_phase1_d.log 2>&1; echo "phase1 $?"; grep -E "GATE|DONE" $L/run_phase1_d.log
bash v105d/run_phase2_d.sh > $L/run_phase2_d.log 2>&1; echo "phase2 $?"; grep -E "DONE" $L/run_phase2_d.log
python3 v105d/realism_check_d.py > $L/realism_d.log 2>&1; echo "realism $?"; tail -12 $L/realism_d.log
python3 v105d/bakuzis_compare_d.py > $L/bakuzis_compare_d.log 2>&1; echo "bakuzis compare $?"
python3 v105d/compare_3way.py > $L/compare_3way.log 2>&1; echo "compare $?"
echo "MASTER DONE $(date)"
