#!/bin/bash
# a5/pairmc: gate 1 (3 workers), gate check, main paired MC (3 workers), summary. At most 3 cores.
cd ~/jobs/koa_v104_20261030/a5/pairmc
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
T0=$(date +%s)
for w in 0 1 2; do python3 pairmc.py gate $w 3 > logs/gate_w$w.log 2>&1 & done; wait
echo "gate $(( $(date +%s) - T0 )) s" >> logs/timings.txt
python3 summarize.py > logs/gatecheck.log 2>&1
if grep -q "GATE FAILED" logs/gatecheck.log || ! grep -q '"PASS": true' logs/gatecheck.log; then echo "STOP gate failed" >> logs/timings.txt; exit 1; fi
T1=$(date +%s)
for w in 0 1 2; do python3 pairmc.py main $w 3 > logs/main_w$w.log 2>&1 & done; wait
echo "main $(( $(date +%s) - T1 )) s" >> logs/timings.txt
python3 summarize.py > logs/summary.log 2>&1; echo "summary exit $?" >> logs/timings.txt
