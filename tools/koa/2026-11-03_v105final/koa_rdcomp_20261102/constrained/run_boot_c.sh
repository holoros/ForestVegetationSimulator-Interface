#!/bin/bash
## K3c1 passes signs, monotonicity (b4 < 0 => d/dx = b4/(x+1) < 0), 4 of 4 sources, dAIC -43.5 -> its bootstrap first (PREREG compute order), 3 cores after main fits.
cd ~/jobs/koa_rdcomp_20261102/constrained
while ! grep -q "MAIN DONE" logs/run_main_c.log 2>/dev/null; do sleep 15; done
Rscript 03c_boot.R K3c1 3 > logs/03c_boot_K3c1.log 2>&1; echo "$(date) done K3c1" >> logs/run_boot_c.log
Rscript 03c_boot.R K3c2 3 > logs/03c_boot_K3c2.log 2>&1; echo "$(date) done K3c2" >> logs/run_boot_c.log
