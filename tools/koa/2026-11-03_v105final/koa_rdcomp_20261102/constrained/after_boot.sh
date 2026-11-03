#!/bin/bash
cd ~/jobs/koa_rdcomp_20261102/constrained
while ! grep -q "done K3c1" logs/run_boot_c.log 2>/dev/null; do sleep 15; done
Rscript 04c_mono.R > logs/04c_mono.log 2>&1; Rscript 05c_results.R > logs/05c_results.log 2>&1; echo "RESULTS DONE $(date)" >> logs/after_boot.log
