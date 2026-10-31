#!/bin/bash
# A5 rerun of a5/pairmc on the Stage 3 fixed engine, plus BOOT variants (PREREG addendum A5). At most 3 cores.
cd ~/jobs/koa_v104_20261030/a5/pairmc
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
L=logs/timings_a5.txt; echo "start $(date)" > $L
mkdir -p engine_a5 out_a5 boot_inputs
cd ../../engine_v103 && for f in *; do case "$f" in out_m1*|AK_PLT_GEO.csv|__pycache__|koa_regen.tgz) ;; *) cp -rL "$f" ../a5/pairmc/engine_a5/ ;; esac; done; cd ../a5/pairmc
grep -c "STAGE3_COEF" engine_a5/run_candidates.py >> $L
python3 -c "
import glob, pandas as pd
fs = sorted(glob.glob('../rerun/h/draws/draw_*.csv')); d = pd.concat([pd.read_csv(f) for f in fs]).sort_values('draw')
d.to_csv('boot_inputs/h_draws_snapshot.csv', index=False); print('height draws', len(d), 'converged', int(d.ok.sum()))" >> $L 2>&1
T0=$(date +%s)
for w in 0 1 2; do python3 pairmc_a5.py gate $w 3 > logs/a5_gate_w$w.log 2>&1 & done; wait
echo "gate $(( $(date +%s) - T0 )) s" >> $L
python3 summarize_a5.py > logs/a5_gatecheck.log 2>&1
if grep -q "GATE FAILED" logs/a5_gatecheck.log || [ $(grep -c '"PASS": true' logs/a5_gatecheck.log) -lt 2 ]; then echo "STOP gate failed" >> $L; exit 1; fi
T1=$(date +%s)
for w in 0 1 2; do python3 pairmc_a5.py main $w 3 > logs/a5_main_w$w.log 2>&1 & done; wait
echo "main $(( $(date +%s) - T1 )) s" >> $L
python3 summarize_a5.py > logs/a5_summary.log 2>&1; echo "summary exit $?" >> $L
