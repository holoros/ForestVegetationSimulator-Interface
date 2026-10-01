#!/bin/bash
# Joint draws into engine_v103/out_joint, then the Monte Carlo driver regen_m1.py (500 replicates, out_m1, Bakuzis, figure set).
cd ~/jobs/koa_v103_20260930
mkdir -p engine_v103/out_m1_v102copy
cp a2/mc/out/* engine_v103/out_joint/
T0=$(date +%s)
cd engine_v103 && MPLCONFIGDIR=$PWD/.mpl python3 regen_m1.py > driver.log 2>&1; echo $? > driver.exit
echo "regen_m1 exit $(cat driver.exit) $(( $(date +%s) - T0 )) s" >> ../a2/logs/timings.txt
