#!/bin/bash
## bootstraps on 3 cores, order per PREREG: rule-relevant dDBH candidate (K3p: signs pass, 3 of 4 sources, dAIC <= -4) first, then K0, then the rest.
cd ~/jobs/koa_rdcomp_20261102
while ! grep -q "MAIN DONE" logs/run_main.log; do sleep 20; done
for rc in "dDBH K3p" "dDBH K0" "dDBH K1p" "dDBH K3" "dDBH K1" "dDBH K2p" "dDBH K2" "dHT K0" "dHT K3p" "dHT K1p" "dHT K2p" "dHT K3" "dHT K1" "dHT K2"; do
  set -- $rc; Rscript 03_boot.R $1 $2 3 > logs/03_boot_$1_$2.log 2>&1; echo "$(date) done $1 $2" >> logs/run_boot.log; done
