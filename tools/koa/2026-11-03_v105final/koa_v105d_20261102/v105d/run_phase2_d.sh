#!/bin/bash
# v105d phase 2: LOIO, Table S11, Bakuzis, containment, paired MC (1,000 joint draws + BOOT variants). Height bootstrap rerun for v105d in the H1a form
# (a5/rerun/h/h_boot_v105d.R, 500 draws, before this phase; the BOOT variants read its draws). At most 3 cores (other jobs hold 4 of 8).
set -u; cd ~/jobs/koa_v105d_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
B=v105d/backup_d.sh; L=v105d/logs
echo "start $(date)"
bash a5/loio/run_loio_v105.sh > $L/loio_v105d.log 2>&1; echo "loio $? $(date)"; tail -2 $L/loio_v105d.log
Rscript --vanilla a5/rerun/s11/s11_v104.R > $L/s11_v105d.log 2>&1; echo "s11 $?"
( cd a4/bakuzis && Rscript --vanilla bakuzis_v105_vs_v104.R > ../../$L/bakuzis_v105d.out 2>&1; echo "bakuzis $?"; Rscript --vanilla bakuzis_matrix_v105.R > ../../$L/bakuzis_matrix_v105d.out 2>&1; echo "bakuzis_matrix $?" )
( cd a5/rerun/qr && python3 03_contain_v104.py > ../../../$L/qr_contain_v105d.log 2>&1; echo "contain $?" )
tar -czf v105d/backup_pairmc_engine_a5_v105c.tgz a5/pairmc/engine_a5 a5/pairmc/boot_inputs a5/pairmc/logs 2>/dev/null; echo "engine_a5 backup $?"
bash a5/pairmc/run_pairmc_v105.sh > $L/pairmc_v105d.log 2>&1; echo "pairmc $?"; tail -3 $L/pairmc_v105d.log
( cd a5/pairmc && bash run_boot_a5.sh > logs/run_boot_v105d.out 2>&1; echo "pairmc boot $?" )
echo "PHASE2 DONE $(date)"
