#!/bin/bash
# A4 chain 1: point production (grid, uneven), yield grid, joint draws, 500-replicate MC (regen_m1: out_m1, Bakuzis, figure set).
set -u; cd ~/jobs/koa_v104_20261030; L=a4/logs/chain1.log; echo "start $(date)" > $L
cp -rn a2/fin/out a2/fin/out_v103; cp -rn a2/mc/out a2/mc/out_v103; mkdir -p engine_v103/out_m1_v103 && cp -n engine_v103/out_m1/* engine_v103/out_m1_v103/ 2>/dev/null
cd a2
T0=$(date +%s); python3 run_engine.py ../engine_v103 v104 > ../a4/logs/run_v104.log 2>&1; echo "run_engine v104 exit $? $(( $(date +%s) - T0 )) s" >> ../$L
T1=$(date +%s); python3 uneven_point.py ../engine_v103 v104 > ../a4/logs/run_uneven_v104.log 2>&1; echo "uneven_point v104 exit $? $(( $(date +%s) - T1 )) s" >> ../$L
python3 fin/run_yield_grid_v103.py > ../a4/logs/yield_grid_v104.log 2>&1; echo "grid $?" >> ../$L
cd ..; T2=$(date +%s); Rscript --vanilla a4/joint_draws_v104.R > a4/logs/joint_draws_v104.log 2>&1; echo "joint $? $(( $(date +%s) - T2 )) s" >> $L
rm -f a2/mc/out/*; cp a4/jointmc/out/* a2/mc/out/
rm -f engine_v103/driver.exit; T3=$(date +%s); ./a2/run_mc_v103.sh; echo "mc $(cat engine_v103/driver.exit) $(( $(date +%s) - T3 )) s" >> $L
echo "CHAIN1 DONE $(date)" >> $L
