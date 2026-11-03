#!/bin/bash
# v105c Stage B: Eq. 4 refit with the K3c1 dDBH form (inc_v103.R all), fit gate, engine deploy, downstream literals, natural level, registry engine sync.
set -u; cd ~/jobs/koa_v105c_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
B=v105c/backup_c.sh; L=v105c/logs; echo "start $(date)"
bash $B out/inc/*.csv out/inc/fits_v103.rda out/v105_constants.json engine_v103/koa_params.py engine_v103/koa_equations.py engine_v103/HiGy.R
KOA_DDBH_FORM=K3c1 Rscript --vanilla track2/inc/inc_v103.R all > $L/inc_v105c.log 2>&1; echo "inc $? $(date)"
Rscript --vanilla v105c/gate_k3c1_fit.R > $L/gate_k3c1_fit.log 2>&1; echo "gate_fit $?"; tail -1 $L/gate_k3c1_fit.log
grep -q "GATE_K3C1_FIT PASS" $L/gate_k3c1_fit.log || { echo "STOP: K3c1 fit gate failed"; exit 1; }
Rscript --vanilla v105c/set_dec_v105c.R > $L/set_dec_v105c.log 2>&1; echo "set_dec $?"; tail -4 $L/set_dec_v105c.log
python3 v105c/patch_engine_v105c.py deploy > $L/patch_engine_deploy.log 2>&1; echo "deploy $?"; tail -2 $L/patch_engine_deploy.log
bash $B a2/mort/v104/*.csv a4/logs/calib_v104.log
bash a4/run_mort_v104.sh; tail -3 a4/logs/calib_v104.log
python3 v105c/set_mortcal_v105c.py > $L/set_mortcal_v105c.log 2>&1; echo "set_mortcal $?"; cat $L/set_mortcal_v105c.log
python3 v105c/patch_post_v105c.py > $L/patch_post.log 2>&1; echo "post $?"; tail -1 $L/patch_post.log
for R in a2/registry/engine a2/registry/engine_nocal; do
  for f in engine_v103/*.py; do b=$(basename $f); case "$b" in *_PREV_20*) continue;; esac; bash $B $R/$b; cp -p $f $R/$b; done
done
python3 - <<'P'
import re, os
p = os.path.expanduser("~/jobs/koa_v105c_20261102/a2/registry/engine_nocal/koa_params.py"); t = open(p).read()
t, n = re.subn(r"^MORT_CAL = .*$", "MORT_CAL = (1.0, 1.0)   # registry engine_nocal: no natural level factor (A4; v105c sync 2026-11-02)", t, count=1, flags=re.M); assert n == 1
open(p, "w").write(t); print("nocal MORT_CAL set")
P
echo "STAGE_B DONE $(date)"
