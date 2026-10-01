#!/bin/bash
cd ~/jobs/koa_v103_20260930/track2/inc
T0=$(date +%s); Rscript boot_v103.R dDBH 400 4 > ../../logs/boot_v103_dDBH.log 2>&1; echo "boot_v103.R dDBH exit $? $(( $(date +%s) - T0 )) s" >> ../../logs/timings.txt &
T1=$(date +%s); Rscript boot_v103.R dHT 400 4 > ../../logs/boot_v103_dHT.log 2>&1; echo "boot_v103.R dHT exit $? $(( $(date +%s) - T1 )) s" >> ../../logs/timings.txt
wait; echo done > ../../logs/boot.done
