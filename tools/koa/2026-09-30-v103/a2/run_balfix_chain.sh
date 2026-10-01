#!/bin/bash
# v103 A2 rerun after the weighted BAL fix (red team A1A2 finding 1). Gate (switch False reproduces the pre-fix engine), MORT_CAL re-solve,
# point production, validation compare, Aviva grid, joint draws, 500 replicate MC, parity. Pre-fix outputs are kept with suffix _prebalfix.
set -u; cd ~/jobs/koa_v103_20260930/a2; L=logs/balfix_chain.log; echo "start $(date)" > $L
for f in traj val uneven; do cp -n out/${f}_v103.csv out/${f}_v103_prebalfix.csv; done
cp -n out/tables_v103.md out/tables_v103_prebalfix.md; cp -rn fin/out fin/out_prebalfix; cp -rn mc/out mc/out_prebalfix; cp -rn mort/v103 mort/v103_prebalfix
mkdir -p ../engine_v103/out_m1_prebalfix && cp -n ../engine_v103/out_m1/* ../engine_v103/out_m1_prebalfix/
# gate: switch off reproduces the pre-fix engine exactly
rm -rf ../engine_v103_wgate; cp -r ../engine_v103 ../engine_v103_wgate; sed -i 's/^BAL_PERCENTILE_WEIGHTED = True/BAL_PERCENTILE_WEIGHTED = False/' ../engine_v103_wgate/koa_params.py
python3 run_engine.py ../engine_v103_wgate wgate >> $L 2>&1; python3 compare_gate.py out/traj_wgate.csv out/traj_v103_prebalfix.csv | grep -E 'WORST' >> $L; python3 compare_gate.py out/val_wgate.csv out/val_v103_prebalfix.csv | grep WORST >> $L
# MORT_CAL
sed -i 's/^MORT_CAL = (.*$/MORT_CAL = (1.0, 1.0)   # placeholder, re-solved by patch_mortcal_v103.py/' ../engine_v103/koa_params.py
./run_mort_v103.sh; python3 patch_mortcal_v103.py >> $L 2>&1
./run_prod_v103.sh; python3 compare_v103.py > logs/compare_v103.out 2>&1; echo "compare $?" >> $L
python3 fin/run_yield_grid_v103.py > logs/yield_grid_v103.log 2>&1; python3 fin/compare_yield_grid_v103.py > logs/yield_compare_v103.log 2>&1; echo "grid $?" >> $L
cd ..; Rscript --vanilla a2/joint_draws_v103.R > a2/logs/joint_draws_v103.log 2>&1; echo "joint $?" >> a2/$L
rm -f engine_v103/driver.exit; ./a2/run_mc_v103.sh; echo "mc $(cat engine_v103/driver.exit)" >> a2/$L
cd engine_v103 && Rscript parity_r_050.R > ../a2/logs/parity_r.log 2>&1 && python3 parity_python_050.py > ../a2/logs/parity_py.log 2>&1 && python3 parity_compare_050.py > ../a2/parity/parity_compare_050_v103.txt 2>&1; echo "parity $?" >> ../a2/$L
echo "CHAIN DONE $(date)" >> ../a2/$L
