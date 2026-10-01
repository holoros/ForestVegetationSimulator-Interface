#!/usr/bin/env bash
# run_s05_s07.sh (v103 registry, 2026-09-30): copy of track3/run_s05_s07.sh of koa_v102_20260918, scripts unchanged.
# KOA_TRAJ = engine_v103 out_m1 trajectories (registry/derived, made by make_traj_v102.py); KOA_TRAJ_REF = engine_v102 (the before).
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; RT=$HOME/jobs/koa_redteam_20260916; V2=$HOME/jobs/koa_v102_20260918/track3/derived/engine_v102_out_m1
cd $R/rt
export KOA_CAP_PLANTED=69.7 KOA_NBOOT=5000 KOA_DEPOSIT=$RT/deposit
echo "== v103 05 $(date)"
KOA_OUT=$R/s05/v103 KOA_TRAJ_REF=$V2/trajectories.csv KOA_TRAJ=$R/derived/engine_v103_out_m1/trajectories.csv Rscript 05_trajectory_metrics.R
echo "== v103 07 $(date)"
KOA_OUT=$R/s07/v103 KOA_VALID=$R/derived/engine_v103_out_m1/validation_23.csv Rscript 07_validation_equivalence.R
for o in natural planted; do
  mkdir -p $R/s07/v103_origin/$o
  python3 -c "import pandas as pd; d=pd.read_csv('$R/derived/engine_v103_out_m1/validation_23.csv'); d[d.origin=='$o'].to_csv('$R/s07/v103_origin/$o/validation_$o.csv', index=False)"
  KOA_OUT=$R/s07/v103_origin/$o KOA_VALID=$R/s07/v103_origin/$o/validation_$o.csv Rscript 07_validation_equivalence.R
done
echo "S05 S07 DONE $(date)"
