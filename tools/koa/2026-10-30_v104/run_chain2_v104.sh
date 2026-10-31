#!/bin/bash
# A4 chain 2: derived tables from out_m1, registry stage reruns on the v104 engine copies, plot-level and trajectory validation, registry build.
set -u; cd ~/jobs/koa_v104_20261030; L=a4/logs/chain2.log; echo "start $(date)" > $L
R=a2/registry
cp a2/mc/out/* $R/engine/out_joint/ 2>/dev/null; cp a2/mc/out/* $R/engine_nocal/out_joint/ 2>/dev/null
python3 $R/make_traj_v102.py engine_v103 $R/derived/engine_v104_out_m1 > a4/logs/make_traj_v104.log 2>&1; echo "make_traj $?" >> $L
bash $R/run_s05_s07.sh > $R/logs/run_s05_s07_v104.log 2>&1; echo "s05s07 $?" >> $L
bash $R/run_lt.sh > $R/logs/run_lt_v104.log 2>&1; echo "lt $?" >> $L
bash $R/run_ceiling.sh > $R/logs/run_ceiling_v104.log 2>&1; echo "ceiling $?" >> $L
bash $R/run_mort_planted.sh > $R/logs/run_mort_planted_v104.log 2>&1; echo "mort_planted $?" >> $L
bash $R/run_proto.sh > $R/logs/run_proto_v104.log 2>&1; echo "proto $?" >> $L
cd a2/closeout/validation && python3 plotlevel_validation.py ../../../engine_v103 v104 > run_v104.log 2>&1; echo "plotlevel $?" >> ../../../$L; cd ../../..
mkdir -p a4/lt && python3 a2/figs/scripts/lt_v103.py engine_v103 v104 a4/lt > a4/logs/lt_fig_v104.log 2>&1; echo "lt_fig $?" >> $L
cd a4 && python3 compute_pending_v104.py > logs/compute_pending_v104.log 2>&1; echo "pending $?" >> ../$L; cd ..
bash $R/make_md.sh; echo "registry $?" >> $L
echo "CHAIN2 DONE $(date)" >> $L
