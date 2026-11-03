#!/bin/bash
# v105d Stage B: inc refit (K3c1 dDBH = v105c; K3c1h dHT), fit gate, decision, engine deploy (dHT, H1a, C2h, M3a), consumers, natural level re-solve,
# post patches, registry engine sync, literal check.
set -u; cd ~/jobs/koa_v105d_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
B=v105d/backup_d.sh; L=v105d/logs; echo "start $(date)"; date +%s > v105d/out/T0_stageB_epoch.txt
bash $B out/inc/*.csv out/inc/fits_v103.rda out/v105_constants.json engine_v103/koa_params.py engine_v103/koa_equations.py frames/final/*_v103_model.csv
KOA_DDBH_FORM=K3c1 KOA_DHT_FORM=K3c1h Rscript --vanilla track2/inc/inc_v103.R all > $L/inc_v105d.log 2>&1; echo "inc $? $(date)"
Rscript --vanilla v105d/gate_v105d_fit.R > $L/gate_v105d_fit.log 2>&1; echo "gate_fit $?"; tail -1 $L/gate_v105d_fit.log
grep -q "GATE_V105D_FIT PASS" $L/gate_v105d_fit.log || { echo "STOP: v105d fit gate failed"; exit 1; }
Rscript --vanilla v105d/set_dec_v105d.R > $L/set_dec_v105d.log 2>&1; echo "set_dec $?"
python3 v105d/patch_engine_v105d.py deploy > $L/patch_engine_deploy.log 2>&1; echo "deploy $?"; tail -3 $L/patch_engine_deploy.log
grep -q "forms K3c1 H1a C2h K3c1h M3a" $L/patch_engine_deploy.log || { echo "STOP: deploy"; exit 1; }
python3 v105d/patch_consumers_v105d.py > $L/patch_consumers.log 2>&1; echo "consumers $?"; cat $L/patch_consumers.log
bash $B a2/mort/v104/*.csv a4/logs/calib_v104.log
python3 v105d/patch_post_v105d.py > $L/patch_post_pre.log 2>&1   # core limit before the level re-solve (TAU/LOIO lines rewritten again below)
bash a4/run_mort_v104.sh; tail -3 a4/logs/calib_v104.log
python3 v105d/set_mortcal_v105d.py > $L/set_mortcal_v105d.log 2>&1; echo "set_mortcal $?"; cat $L/set_mortcal_v105d.log
python3 v105d/patch_post_v105d.py > $L/patch_post.log 2>&1; echo "post $?"; tail -1 $L/patch_post.log
for R in a2/registry/engine a2/registry/engine_nocal; do
  for f in engine_v103/*.py engine_v103/HiGy.R; do b=$(basename $f); case "$b" in *_PREV_20*) continue;; esac; bash $B $R/$b; cp -p $f $R/$b; done
done
python3 - <<'P'
import re, os
p = os.path.expanduser("~/jobs/koa_v105d_20261102/a2/registry/engine_nocal/koa_params.py"); t = open(p).read()
t, n = re.subn(r"^MORT_CAL = .*$", "MORT_CAL = (1.0, 1.0)   # registry engine_nocal: no natural level factor (A4; v105d sync 2026-11-02)", t, count=1, flags=re.M); assert n == 1
open(p, "w").write(t); print("nocal MORT_CAL set")
P
python3 v105d/check_literals_v105d.py > $L/check_literals.log 2>&1; echo "literals $?"; tail -1 $L/check_literals.log
grep -q "LITERALS PASS" $L/check_literals.log || { echo "STOP: literal check failed"; exit 1; }
echo "STAGE_B DONE $(date)"
