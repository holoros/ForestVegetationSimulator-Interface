#!/bin/bash
# run_pipeline.sh RUN: deploy (fits under SDImax_pop; reverted components at v105c), MORT_CAL re-solve, registry engine sync, literal check,
# chain 1 (point, 500 joint draws, 500-replicate MC), chain 2 (validation, LT, culmination), Bakuzis (step aware), coverage (500 draws), realism.
# 2 cores per run (joint draws NC 2, calib_mort Pool 2); two runs at a time keeps the job at <= 4 cores.
set -u; RUN=$1; J=~/jobs/koa_v105attr_20261103; W=$J/$RUN; L=$J/logs/$RUN; mkdir -p $L $W/out_attr
cd $W; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
echo "start $RUN $(date)"
python3 $J/scripts/deploy_run.py $RUN > $L/deploy.log 2>&1; echo "deploy $?"; grep -E "GATE|forms|DEPLOY_RUN" $L/deploy.log
grep -q "DEPLOY_RUN DONE" $L/deploy.log || { echo "STOP deploy"; exit 1; }
sed -i 's/with Pool(6) as pool:   # v105d: 6 workers (core limit), results unchanged/with Pool(2) as pool:   # koa_v105attr: 2 workers (core limit), results unchanged/' a2/mort/calib_mort.py
sed -i 's/NC <- 6   # v105d core limit/NC <- 2   # koa_v105attr core limit (2 per run)/' a4/joint_draws_v104.R
grep -c "Pool(2)" a2/mort/calib_mort.py; grep -c "NC <- 2" a4/joint_draws_v104.R
sed -i 's#/ 923\.0, share=share#/ KP.DDBH_RD_SDIMAX, share=share#' v105d/realism_check_d.py
bash a4/run_mort_v104.sh; tail -2 a4/logs/calib_v104.log
python3 v105d/set_mortcal_v105d.py > $L/set_mortcal.log 2>&1; echo "set_mortcal $?"; cat $L/set_mortcal.log
for R in a2/registry/engine a2/registry/engine_nocal; do for f in engine_v103/*.py; do b=$(basename $f); case "$b" in *_PREV_20*) continue;; esac; cp -p $f $R/$b; done; done
python3 - <<'P'
import re, os, sys
p = os.path.join(os.getcwd(), "a2/registry/engine_nocal/koa_params.py"); t = open(p).read()
t, n = re.subn(r"^MORT_CAL = .*$", "MORT_CAL = (1.0, 1.0)   # registry engine_nocal: no natural level factor (koa_v105attr sync)", t, count=1, flags=re.M); assert n == 1
open(p, "w").write(t); print("nocal MORT_CAL set")
P
python3 $J/scripts/check_literals_attr.py $RUN > $L/check_literals.log 2>&1; echo "literals $?"; tail -1 $L/check_literals.log
grep -q "LITERALS PASS" $L/check_literals.log || { echo "STOP literals"; exit 1; }
bash a4/run_chain1_v104.sh; cat a4/logs/chain1.log | tail -6; grep -E "GATE|PASS|Error" a4/logs/joint_draws_v104.log | head -8
grep -q "CHAIN1 DONE" a4/logs/chain1.log || { echo "STOP chain1"; exit 1; }
bash a4/run_chain2_v104.sh; cat a4/logs/chain2.log | tail -13
( cd a4/bakuzis && Rscript --vanilla bakuzis_v105_vs_v104.R > $L/bakuzis.out 2>&1; echo "bakuzis $?" )
bash a5/rerun/cov/run_cov.sh > $L/cov.log 2>&1; echo "cov $?"; grep DONE $L/cov.log
python3 v105d/realism_check_d.py $W/engine_v103 $RUN > $L/realism.log 2>&1; echo "realism $?"; tail -6 $L/realism.log
echo "PIPELINE DONE $RUN $(date)"
