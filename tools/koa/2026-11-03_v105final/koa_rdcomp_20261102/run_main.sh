#!/bin/bash
cd ~/jobs/koa_rdcomp_20261102
Rscript 02_fit.R K0 > logs/02_fit_K0.log 2>&1
Rscript g1.R > logs/g1.log 2>&1
grep -q "TRUE" out/gate_G1.csv && ! grep -q "FALSE" out/gate_G1.csv || { echo "G1 FAILED; stop" >> logs/run_main.log; exit 1; }
printf "K1\nK2\nK3\nK1p\nK2p\nK3p\n" | xargs -P 3 -I{} sh -c 'Rscript 02_fit.R {} > logs/02_fit_{}.log 2>&1'
echo MAIN DONE $(date) >> logs/run_main.log
