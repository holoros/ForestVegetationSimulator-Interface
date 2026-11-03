#!/bin/bash
# rerun of the frame part of the parity gate after the CS keep-line fix (the first frames run dropped BAPH_depcol.* from the CS frames: a trailing comment hid the else branch)
set -u; cd ~/jobs/koa_v105c_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
KOA_DDBH_FORM=v105b Rscript --vanilla track2/inc/inc_v103.R frames > v105c/logs/frames_v105c.log 2>&1; echo "frames $?"
Rscript --vanilla v105c/parity_frames.R > v105c/logs/parity_frames.log 2>&1; echo "parity_frames $?"; tail -1 v105c/logs/parity_frames.log
echo DONE
