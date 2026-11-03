#!/bin/bash
# v105final master (koa_v105final_20261103 = copy of koa_v105attr_20261103/R_HT: v105d forms under SDImax 741.997 with Eq. 2 at the v105c form).
# bootstraps (dDBH K3c1, dHT K3c1h full refit; dHT vector-fixed re-solve), CAL SE, v105c height bootstrap draws for the BOOT variants, registry s02 = v105c,
# figure patches, phase 1 (chains, tables, figs, sens, registry), phase 2 (LOIO, S11, Bakuzis, containment, paired MC, BOOT), realism. Up to 6 cores.
set -u; F=~/jobs/koa_v105final_20261103; cd $F; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 KOA_DDBH_FORM=K3c1 KOA_DHT_FORM=K3c1h
L=$F/logs; echo "MASTER start $(date)"; date +%s > final/T0_master_epoch.txt
NB=4; pgrep -f "run_pipeline3.sh P_HT_HCB" > /dev/null && echo "pairwise info run active: bootstraps on 4 cores"
Rscript --vanilla track2/inc/boot_v103.R dDBH 400 $NB > $L/boot_dDBH.log 2>&1; echo "boot dDBH $? $(date)"; grep -v warn $L/boot_dDBH.log | tail -1
while pgrep -f "run_pipeline3.sh P_HT_HCB" > /dev/null; do sleep 30; done; echo "pairwise info run finished or absent $(date)"
Rscript --vanilla track2/inc/boot_v103.R dHT 400 6 > $L/boot_dHT.log 2>&1; echo "boot dHT $? $(date)"; grep -v warn $L/boot_dHT.log | tail -1
grep -q "BOOT DONE dDBH" $L/boot_dDBH.log && grep -q "BOOT DONE dHT" $L/boot_dHT.log || { echo "STOP bootstraps"; exit 1; }
Rscript --vanilla stageB/boot_resolve_dht_v105.R 6 > $L/boot_resolve_dht.log 2>&1; echo "resolve dHT $?"; tail -1 $L/boot_resolve_dht.log
# height bootstrap draws: Eq. 2 is the v105c form, data unchanged -> the v105c draws (392 of 500 converged, g1 fixed) are the valid ones
rm -rf a5/rerun/h/draws_v105d_unused; mv a5/rerun/h/draws a5/rerun/h/draws_v105d_unused; cp -rp a5/rerun/h/draws_v105c a5/rerun/h/draws
for f in h_boot_final h_boot_summary_final h_ref_final; do cp -p a5/rerun/h/${f}.csv a5/rerun/h/${f}_v105d_unused.csv; cp -p a5/rerun/h/${f}_v105c.csv a5/rerun/h/${f}.csv; done; echo "height draws -> v105c"
# registry s02 (height) = v105c files (Eq. 2 identical to v105c)
for f in ~/jobs/koa_v105c_20261102/a2/registry/s02/v105/*; do b=$(basename $f); case "$b" in *_PREV_*) continue;; esac; cp -p $f a2/registry/s02/v105/$b; done; echo "registry s02 -> v105c"
# core limits 6
sed -i 's/with Pool(2) as pool:   # koa_v105attr: 2 workers (core limit), results unchanged/with Pool(6) as pool:   # v105final: 6 workers (core limit), results unchanged/' a2/mort/calib_mort.py
sed -i 's/NC <- 2   # koa_v105attr core limit (2 per run)/NC <- 6   # v105final core limit/' a4/joint_draws_v104.R
grep -c "Pool(6)" a2/mort/calib_mort.py; grep -c "NC <- 6" a4/joint_draws_v104.R
sed -i 's/v105c full-refit installation bootstrap of the K3c1 fit, 400 resamples (files reused: dDBH unchanged in v105d)/v105final full-refit installation bootstrap of the K3c1 fit under SDImax 741.997, 400 resamples/; s/full refit of dDBH_L_NO K3c1, v105c (reused in v105d)/full refit of dDBH_L_NO K3c1, v105final/; s/dHT_L_NO K3c1h, v105d"/dHT_L_NO K3c1h, v105final"/' v105d/set_calse_v105d.py
python3 - <<'P'
import re, os, json
W = os.path.expanduser("~/jobs/koa_v105final_20261103"); J = json.load(open(f"{W}/out/v105_constants.json")); D = J["DDBH"]
p = f"{W}/a5/loio/make_results.py"; t = open(p).read()
t, n = re.subn(r'"Fold-to-fold range \(v105d of record: [^"]*"', '"Fold-to-fold range (v105final of record: b8 %.7f, c natural %.4f, c planted %.4f, CF %.5f, level %.5f; out/v105_constants.json):"' % (D["coef"]["b8"], D["c_natural"], D["c_planted"], D["CF"], J["MORT_CAL"]["value"][0]), t); assert n == 1
t = t.replace("# koa v105d LOIO results", "# koa v105final LOIO results"); open(p, "w").write(t); print("loio make_results of-record line set")
P
bash v105d/run_phase1_d.sh > $L/run_phase1.log 2>&1; echo "phase1 $?"; grep -E "GATE|DONE| [1-9][0-9]*$" $L/run_phase1.log | head -30
bash v105d/run_phase2_d.sh > $L/run_phase2.log 2>&1; echo "phase2 $?"; grep -E "DONE| [1-9][0-9]*$" $L/run_phase2.log
python3 v105d/realism_check_d.py $F/engine_v103 v105final > $L/realism.log 2>&1; echo "realism $?"; tail -6 $L/realism.log
python3 ~/jobs/koa_v105attr_20261103/scripts/check_literals_attr.py FINAL > $L/check_literals.log 2>&1; echo "literals $?"; tail -1 $L/check_literals.log
echo "MASTER DONE $(date)"
