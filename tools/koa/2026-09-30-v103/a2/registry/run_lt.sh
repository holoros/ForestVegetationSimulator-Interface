#!/usr/bin/env bash
# run_lt.sh (v103 registry): longterm_valid.py, scenarios.py, diag_cr.py, clip_shares.py, joint_diag.py unchanged.
# Engines: registry copies of engine_v103 (engine) and engine_v103 without the natural level factor (engine_nocal). clip reads the
# final engine_v103/out_m1 read only. The before (v102) values are read from koa_v102_20260918/track3/lt/out, not rerun.
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; cd $R
echo "== LT v103 $(date)"
python3 lt/longterm_valid.py $R/engine v103 $R/lt/out > lt/out/lt_v103.log 2>&1
python3 lt/longterm_valid.py $R/engine_nocal u103 $R/lt/out > lt/out/lt_u103.log 2>&1
echo "== SC v103 $(date)"
python3 lt/scenarios.py $R/engine $R/lt/out > lt/out/sc_v103.log 2>&1
python3 lt/diag_cr.py $R/engine $R/lt/out > lt/out/diag_cr_v103.log 2>&1
echo "== clip $(date)"
python3 clip/clip_shares.py $J/engine_v103/out_m1 $R/clip/J_clip_ceiling_shares.csv > clip/clip_v103.log 2>&1
echo "== joint_diag $(date)"
python3 joint/joint_diag.py $R/engine $R/joint/K_reference_spread.csv > joint/joint_diag_v103.log 2>&1
echo "LT DONE $(date)"
